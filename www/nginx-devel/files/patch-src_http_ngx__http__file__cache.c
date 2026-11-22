Cache: HTAB as whitespace in the Vary of a response and in the request header lines it
names (pull request 1948 of nginx/nginx, 614cb95 of Vadim Zhestikov, 06.11.2026, open; not
in nginx 1.31.9 nor in master 2e8440b of 18.11.2026; "Reported by CERT Polska"; aZ,
22.11.2026): the value was split into members on commas and spaces only, a member after a
tab kept the tab in its name, never matched a request header and did not take part in the
key of the cache variant, so a response that varies on it was served to requests that
differ in that header. Since 1.7.7.

--- src/http/ngx_http_file_cache.c.orig
+++ src/http/ngx_http_file_cache.c
@@ -1143,11 +1143,11 @@ ngx_http_file_cache_vary(ngx_http_request_t *r, u_char *vary, size_t len,
 
     while (p < last) {
 
-        while (p < last && (*p == ' ' || *p == ',')) { p++; }
+        while (p < last && (*p == ' ' || *p == '\t' || *p == ',')) { p++; }
 
         name.data = p;
 
-        while (p < last && *p != ',' && *p != ' ') { p++; }
+        while (p < last && *p != ',' && *p != ' ' && *p != '\t') { p++; }
 
         name.len = p - name.data;
 
@@ -1249,11 +1249,11 @@ ngx_http_file_cache_vary_header(ngx_http_request_t *r, ngx_md5_t *md5,
 
         while (p < last) {
 
-            while (p < last && (*p == ' ' || *p == ',')) { p++; }
+            while (p < last && (*p == ' ' || *p == '\t' || *p == ',')) { p++; }
 
             start = p;
 
-            while (p < last && *p != ',' && *p != ' ') { p++; }
+            while (p < last && *p != ',' && *p != ' ' && *p != '\t') { p++; }
 
             len = p - start;
 
