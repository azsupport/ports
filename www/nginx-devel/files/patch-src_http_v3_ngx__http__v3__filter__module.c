One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

--- src/http/v3/ngx_http_v3_filter_module.c.orig
+++ src/http/v3/ngx_http_v3_filter_module.c
@@ -283,6 +283,11 @@ ngx_http_v3_header_filter(ngx_http_request_t *r)
     }
 
 #if (NGX_HTTP_GZIP)
+    /* one Vary line: those of the response and that of gzip_vary (az) */
+    if (ngx_http_gzip_vary_merge(r, clcf->gzip_vary) != NGX_OK) {
+        return NGX_ERROR;
+    }
+
     if (r->gzip_vary) {
         if (clcf->gzip_vary) {
             len += ngx_http_v3_encode_field_ri(NULL, 0,
