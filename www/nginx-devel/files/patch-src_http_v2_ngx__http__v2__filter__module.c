One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

--- src/http/v2/ngx_http_v2_filter_module.c.orig
+++ src/http/v2/ngx_http_v2_filter_module.c
@@ -358,6 +358,11 @@ ngx_http_v2_header_filter(ngx_http_request_t *r)
     tmp_len = len;
 
 #if (NGX_HTTP_GZIP)
+    /* one Vary line: those of the response and that of gzip_vary (az) */
+    if (ngx_http_gzip_vary_merge(r, clcf->gzip_vary) != NGX_OK) {
+        return NGX_ERROR;
+    }
+
     if (r->gzip_vary) {
         if (clcf->gzip_vary) {
             len += 1 + sizeof(accept_encoding);
