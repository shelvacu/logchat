require "uri"
require "http/client"
require "crt"

if ARGV.size != 2
  STDERR.puts "Usage: #{$0} <log file name> <full base uri>
EG: #{$0} /var/log/nginx/access.log http://example.com"
  exit 1
end

log_fn = ARGV[0]
other_uri = URI.parse(ARGV[1])

if other_uri.scheme != "http" && other_uri.scheme != "https"
  STDERR.puts "Unsupported scheme #{other_uri.scheme}"
  exit 1
end


lib LibNcursesw
  fun scrollok(win : WindowPtr, bf : LibC::Int) : LibC::Int
end
  
class Crt::Window
  getter winp
end
  
Crt.init
chat_window = Crt::Window.new(Crt.y-1)
text_window = Crt::Window.new(1,0,Crt.y-1)
text_window.print(0, 0, ">")
text_window.refresh

chat_lines = Channel(String).new(16)
to_send = Channel(String).new(16)

typing_line = ""
spawn do
  loop do
    c = text_window.getch
    if c > 0
      case c
      when 13 # enter
        # submit text
        chat_lines.send("<you> #{typing_line}")
        to_send.send(typing_line.dup)
        typing_line = ""
      when 263 # backspace
        typing_line = typing_line[0...-1]
      when (32..126)
        typing_line += c.chr.to_s
      else
        chat_lines.send("Unrecognized key code #{c}")
      end
      text_window.clear
      text_window.print(0, 0, ">")
      text_window.print(0, 2, typing_line)
      text_window.refresh
    end
    Fiber.yield
  end
end

LibNcursesw.scrollok(chat_window.winp, 1)

spawn do
  loop do
    cline = chat_lines.receive
    chat_window.puts cline
    chat_window.refresh
  end
end

spawn do
  loop do
    msg_to_send = to_send.receive
    full_uri = other_uri.dup
    full_uri.path = "/.not-very-well-known/logchat/#{Base64.urlsafe_encode(msg_to_send)}/"
    HTTP::Client.get full_uri
  end
end

log_fh = File.open log_fn
log_fh.seek(log_fh.size)

spawn do
  loop do
    while !(log_line = log_fh.gets).nil?
      if !(m = /\/.not-very-well-known\/logchat\/([a-zA-Z0-9_=-]+)\//.match(log_line)).nil?
        chat_lines.send("<them> " + Base64.decode_string(m[1]))
      end
    end
    if File.exists?(log_fn) && log_fh.stat.ino != File.stat(log_fn).ino
      log_fh = File.open log_fn
    end
    sleep(0.01)
  end
end

loop do
  sleep(1)
end

Crt.done
