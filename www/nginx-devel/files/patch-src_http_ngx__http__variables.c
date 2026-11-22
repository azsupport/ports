Fixed positional captures with cloned subrequests after non-match (freenginx db50d2c0 of
14.08.2026, released in freenginx 1.31.4): r->realloc_captures only made a new r->captures,
which stayed uninitialized when the regular expression did not match, so a positional
capture used after that in a cloned subrequest (proxy_cache_background_update, the slice
module) could read it. nginx 1.31.9 still has it (aZ, 18.11.2026 22:39).

The request body after an error and after it was discarded (pull request 1943 of
nginx/nginx; aZ, 23.11.2026: «бери»): see patch-src_http_ngx__http__request__body.c.

--- src/http/ngx_http_variables.c.orig
+++ src/http/ngx_http_variables.c
@@ -1194,17 +1194,20 @@ ngx_http_variable_content_length(ngx_http_request_t *r,
 {
     u_char  *p;
 
-    if (r->headers_in.content_length) {
+    if (r->reading_body && r->headers_in.content_length) {
         v->len = r->headers_in.content_length->value.len;
         v->data = r->headers_in.content_length->value.data;
         v->valid = 1;
-        v->no_cacheable = 0;
+        v->no_cacheable = 1;
         v->not_found = 0;
 
     } else if (r->reading_body) {
         v->not_found = 1;
         v->no_cacheable = 1;
 
+    } else if (r->discard_body) {
+        v->not_found = 1;
+
     } else if (r->headers_in.content_length_n >= 0) {
         p = ngx_pnalloc(r->pool, NGX_OFF_T_LEN);
         if (p == NULL) {
@@ -1214,7 +1217,7 @@ ngx_http_variable_content_length(ngx_http_request_t *r,
         v->len = ngx_sprintf(p, "%O", r->headers_in.content_length_n) - p;
         v->data = p;
         v->valid = 1;
-        v->no_cacheable = 0;
+        v->no_cacheable = 1;
         v->not_found = 0;
 
     } else if (r->headers_in.chunked) {
@@ -2673,6 +2676,7 @@ ngx_http_regex_compile(ngx_conf_t *cf, ngx_regex_compile_t *rc)
 ngx_int_t
 ngx_http_regex_exec(ngx_http_request_t *r, ngx_http_regex_t *re, ngx_str_t *s)
 {
+    int                        *captures;
     ngx_int_t                   rc, index;
     ngx_uint_t                  i, n, len;
     ngx_http_variable_value_t  *vv;
@@ -2687,10 +2691,16 @@ ngx_http_regex_exec(ngx_http_request_t *r, ngx_http_regex_t *re, ngx_str_t *s)
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
