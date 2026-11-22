One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

No "Server" line of nginx itself (aZ, 22.11.2026 21:10: «у меня во всех конфигах
нгингса есть more_clear_headers 'server'; и в 90% случаях только это. Можешь ли ты
вычистить то что делает more_clear_headers 'server'; в нашем nginx-devel чтобы модуль
more_clear_headers лишнюю работу не делал?»): with NGX_HTTP_AZ_SERVER 0
(src/http/ngx_http_core_module.h; the port builds with -DNGX_HTTP_AZ_SERVER=0, which
nginx -V shows) the header filters of HTTP/1.x, HTTP/2 and HTTP/3 add no "Server" of
their own, whatever server_tokens says (it still decides whether the error pages name
the version). A "Server" that is in the response goes out as before: that of a
backend that is passed (proxy_pass_header Server; a FastCGI backend, whose "Server"
nginx does not hide), one set by add_header or more_set_headers. Without the macro, or
with 1, nginx as it is. The headers-more module then has nothing to clear where
"more_clear_headers 'server'" is all it is asked (files/extra-patch-headers-more-server).

--- src/http/ngx_http_header_filter_module.c.orig
+++ src/http/ngx_http_header_filter_module.c
@@ -287,7 +287,7 @@ ngx_http_header_filter(ngx_http_request_t *r)
 
     clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
 
-    if (r->headers_out.server == NULL) {
+    if (NGX_HTTP_AZ_SERVER && r->headers_out.server == NULL) {
         if (clcf->server_tokens == NGX_HTTP_SERVER_TOKENS_ON) {
             len += sizeof(ngx_http_server_full_string) - 1;
 
@@ -406,6 +406,11 @@ ngx_http_header_filter(ngx_http_request_t *r)
     }
 
 #if (NGX_HTTP_GZIP)
+    /* one Vary line: those of the response and that of gzip_vary (az) */
+    if (ngx_http_gzip_vary_merge(r, clcf->gzip_vary) != NGX_OK) {
+        return NGX_ERROR;
+    }
+
     if (r->gzip_vary) {
         if (clcf->gzip_vary) {
             len += sizeof("Vary: Accept-Encoding" CRLF) - 1;
@@ -456,7 +461,7 @@ ngx_http_header_filter(ngx_http_request_t *r)
     }
     *b->last++ = CR; *b->last++ = LF;
 
-    if (r->headers_out.server == NULL) {
+    if (NGX_HTTP_AZ_SERVER && r->headers_out.server == NULL) {
         if (clcf->server_tokens == NGX_HTTP_SERVER_TOKENS_ON) {
             p = ngx_http_server_full_string;
             len = sizeof(ngx_http_server_full_string) - 1;
