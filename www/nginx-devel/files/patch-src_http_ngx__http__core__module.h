One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

--- src/http/ngx_http_core_module.h.orig
+++ src/http/ngx_http_core_module.h
@@ -518,6 +518,7 @@ u_char *ngx_http_map_uri_to_path(ngx_http_request_t *r, ngx_str_t *name,
 ngx_int_t ngx_http_auth_basic_user(ngx_http_request_t *r);
 #if (NGX_HTTP_GZIP)
 ngx_int_t ngx_http_gzip_ok(ngx_http_request_t *r);
+ngx_int_t ngx_http_gzip_vary_merge(ngx_http_request_t *r, ngx_flag_t vary);
 #endif
 
 
