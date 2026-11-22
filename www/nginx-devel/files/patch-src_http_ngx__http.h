Request body: a limit on chunk extensions and trailer headers (aZ, 22.11.2026): see
patch-src_http_ngx__http__parse.c.

--- src/http/ngx_http.h.orig
+++ src/http/ngx_http.h
@@ -66,6 +66,7 @@ struct ngx_http_chunked_s {
     ngx_uint_t           state;
     off_t                size;
     off_t                length;
+    off_t                skipped;
 };
 
 
