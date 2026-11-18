Fixed positional captures with cloned subrequests after non-match (freenginx db50d2c0 of
14.08.2026, released in freenginx 1.31.4): r->realloc_captures only made a new r->captures,
which stayed uninitialized when the regular expression did not match, so a positional
capture used after that in a cloned subrequest (proxy_cache_background_update, the slice
module) could read it. nginx 1.31.9 still has it (aZ, 18.11.2026 22:39).

--- src/http/ngx_http_variables.c.orig
+++ src/http/ngx_http_variables.c
@@ -2673,6 +2673,7 @@ ngx_http_regex_compile(ngx_conf_t *cf, ngx_regex_compile_t *rc)
 ngx_int_t
 ngx_http_regex_exec(ngx_http_request_t *r, ngx_http_regex_t *re, ngx_str_t *s)
 {
+    int                        *captures;
     ngx_int_t                   rc, index;
     ngx_uint_t                  i, n, len;
     ngx_http_variable_value_t  *vv;
@@ -2687,10 +2688,16 @@ ngx_http_regex_exec(ngx_http_request_t *r, ngx_http_regex_t *re, ngx_str_t *s)
             r->realloc_captures = 0;
             r->ncaptures = 0;
 
-            r->captures = ngx_palloc(r->pool, len * sizeof(int));
-            if (r->captures == NULL) {
+            captures = ngx_pcalloc(r->pool, len * sizeof(int));
+            if (captures == NULL) {
                 return NGX_ERROR;
             }
+
+            if (r->captures) {
+                ngx_memcpy(captures, r->captures, len * sizeof(int));
+            }
+
+            r->captures = captures;
         }
 
     } else {
