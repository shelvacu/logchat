# Logchat

Communicate through HTTP server request logs.

### What??

Situation: You and a buddy want to chat, and you both have read access to a server's request logs and the ability to make requests to the other server.

Solution: Logchat. Every message is sent as a HTTP GET request, and the receiving party constantly scans the request log for new messages.

### Why??

TODO

### How??

To use:

    shards install
    crystal build main.cr
    ./main /var/log/nginx/access.log http://the-server-of-the-person-you-want-to-talk-to.example.com/

### Security?

The extremely secure Base64 encryption algorithm is used for end-to-point-to-point-to-end encryption.