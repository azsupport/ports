One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

No "Server" line of nginx itself (aZ, 22.11.2026): see
patch-src_http_ngx__http__header__filter__module.c.

--- src/http/v2/ngx_http_v2_filter_module.c.orig
+++ src/http/v2/ngx_http_v2_filter_module.c
@@ -223,7 +223,7 @@ ngx_http_v2_header_filter(ngx_http_request_t *r)
 
     clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
 
-    if (r->headers_out.server == NULL) {
+    if (NGX_HTTP_AZ_SERVER && r->headers_out.server == NULL) {
 
         if (clcf->server_tokens == NGX_HTTP_SERVER_TOKENS_ON) {
             len += 1 + nginx_ver_len;
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
@@ -442,7 +447,7 @@ ngx_http_v2_header_filter(ngx_http_request_t *r)
         pos = ngx_sprintf(pos, "%03ui", r->headers_out.status);
     }
 
-    if (r->headers_out.server == NULL) {
+    if (NGX_HTTP_AZ_SERVER && r->headers_out.server == NULL) {
 
         if (clcf->server_tokens == NGX_HTTP_SERVER_TOKENS_ON) {
             ngx_log_debug1(NGX_LOG_DEBUG_HTTP, fc->log, 0,
