One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

No "Server" line of nginx itself (aZ, 22.11.2026): see
patch-src_http_ngx__http__header__filter__module.c.

--- src/http/v3/ngx_http_v3_filter_module.c.orig
+++ src/http/v3/ngx_http_v3_filter_module.c
@@ -161,7 +161,7 @@ ngx_http_v3_header_filter(ngx_http_request_t *r)
 
     clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
 
-    if (r->headers_out.server == NULL) {
+    if (NGX_HTTP_AZ_SERVER && r->headers_out.server == NULL) {
         if (clcf->server_tokens == NGX_HTTP_SERVER_TOKENS_ON) {
             n = sizeof(NGINX_VER) - 1;
 
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
@@ -342,7 +347,7 @@ ngx_http_v3_header_filter(ngx_http_request_t *r)
         b->last = ngx_sprintf(b->last, "%03ui", r->headers_out.status);
     }
 
-    if (r->headers_out.server == NULL) {
+    if (NGX_HTTP_AZ_SERVER && r->headers_out.server == NULL) {
         if (clcf->server_tokens == NGX_HTTP_SERVER_TOKENS_ON) {
             p = (u_char *) NGINX_VER;
             n = sizeof(NGINX_VER) - 1;
