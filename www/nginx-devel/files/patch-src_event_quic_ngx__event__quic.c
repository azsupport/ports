QUIC: ACK frames with ECN counts handled (aZ, 22.11.2026, on the open pull requests
of nginx that are needed: «бери разобрав их сам, вдруг там говно написали»; pull
requests 949 and 1005 of nginx/nginx, issue 945; the line is that of both).
ngx_quic_parse_frame() parses a frame of the type 0x03, an ACK with ECN counts
(RFC 9000, 19.3.2), into the same structure as the ACK 0x02, but
ngx_quic_handle_frames() had a case for 0x02 alone: an ACK with ECN counts went to
"quic missing frame handler" (a line at the debug level) and nothing of what it
acknowledges was acknowledged. A client that reports ECN in its ACK frames got no
response (checked 22.11.2026 with a client of aioquic that sends its ACK frames with
ECN counts: it times out on 1.31.9, and gets its responses with this line). The counts
themselves are read past, as before.

--- src/event/quic/ngx_event_quic.c.orig
+++ src/event/quic/ngx_event_quic.c
@@ -1233,6 +1233,7 @@ ngx_quic_handle_frames(ngx_connection_t *c, ngx_quic_header_t *pkt)
         switch (frame.type) {
 
         case NGX_QUIC_FT_ACK:
+        case NGX_QUIC_FT_ACK_ECN:
             if (ngx_quic_handle_ack_frame(c, pkt, &frame) != NGX_OK) {
                 return NGX_ERROR;
             }
