The request body after an error and after it was discarded (pull request 1943 of
nginx/nginx; aZ, 23.11.2026: «бери»): see patch-src_http_ngx__http__request__body.c.

--- src/http/ngx_http_request.h.orig
+++ src/http/ngx_http_request.h
@@ -311,6 +311,7 @@ typedef struct {
     ngx_chain_t                      *busy;
     ngx_http_chunked_t               *chunked;
     ngx_http_client_body_handler_pt   post_handler;
+    unsigned                          no_buffering:1;
     unsigned                          filter_need_buffering:1;
     unsigned                          last_sent:1;
     unsigned                          last_saved:1;
@@ -547,6 +548,7 @@ struct ngx_http_request_s {
     unsigned                          keepalive:1;
     unsigned                          lingering_close:1;
     unsigned                          discard_body:1;
+    unsigned                          discarding_body:1;
     unsigned                          reading_body:1;
     unsigned                          internal:1;
     unsigned                          error_page:1;
