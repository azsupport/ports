One Vary line (aZ, 22.11.2026): see patch-src_http_ngx__http__core__module.c.

No "Server" line of nginx itself (aZ, 22.11.2026): NGX_HTTP_AZ_SERVER, 1 unless the
build sets it: see patch-src_http_ngx__http__header__filter__module.c.

--- src/http/ngx_http_core_module.h.orig
+++ src/http/ngx_http_core_module.h
@@ -55,6 +55,15 @@ typedef struct ngx_thread_pool_s  ngx_thread_pool_t;
 #define NGX_HTTP_KEEPALIVE_DISABLE_SAFARI  0x0008
 
 
+/*
+ * az: the "Server" line of nginx itself in a response (HTTP/1.x, HTTP/2,
+ * HTTP/3): built with -DNGX_HTTP_AZ_SERVER=0 nginx adds none; a line of a
+ * backend that is passed, or one set by a module, goes out either way
+ */
+#ifndef NGX_HTTP_AZ_SERVER
+#define NGX_HTTP_AZ_SERVER              1
+#endif
+
 #define NGX_HTTP_SERVER_TOKENS_OFF      0
 #define NGX_HTTP_SERVER_TOKENS_ON       1
 #define NGX_HTTP_SERVER_TOKENS_BUILD    2
@@ -518,6 +527,7 @@ u_char *ngx_http_map_uri_to_path(ngx_http_request_t *r, ngx_str_t *name,
 ngx_int_t ngx_http_auth_basic_user(ngx_http_request_t *r);
 #if (NGX_HTTP_GZIP)
 ngx_int_t ngx_http_gzip_ok(ngx_http_request_t *r);
+ngx_int_t ngx_http_gzip_vary_merge(ngx_http_request_t *r, ngx_flag_t vary);
 #endif
 
 
