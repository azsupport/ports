A 101 of a backend taken only where an upgrade is under way (pull request 1941 of
nginx/nginx): see patch-src_http_modules_ngx__http__proxy__module.c.

--- src/http/modules/ngx_http_proxy_module.h.orig
+++ src/http/modules/ngx_http_proxy_module.h
@@ -100,6 +100,7 @@ typedef struct {
     ngx_buf_t                     *trailers;
 
     unsigned                       head:1;
+    unsigned                       upgrade:1;
     unsigned                       internal_chunked:1;
     unsigned                       header_sent:1;
 } ngx_http_proxy_ctx_t;
