Cache: a response with "*" among the members of its Vary is not cached (pull request 1948
of nginx/nginx, 341b475 of Vadim Zhestikov, 06.11.2026, open; not in nginx 1.31.9 nor in
master 2e8440b of 18.11.2026; "Reported by CERT Polska"; aZ, 22.11.2026): only a Vary
that is "*" alone made a response uncacheable; with "*" among other members it was stored
and served to later requests selected on the other members, while such a response never
matches (RFC 9111, 4.1). The members are checked, across several Vary lines too. Since
1.7.7.

--- src/http/ngx_http_upstream.c.orig
+++ src/http/ngx_http_upstream.c
@@ -5547,7 +5547,7 @@ ngx_http_upstream_process_vary(ngx_http_request_t *r,
 
 #if (NGX_HTTP_CACHE)
     {
-    u_char     *p;
+    u_char     *p, *last;
     size_t      len;
     ngx_str_t   vary;
 
@@ -5559,11 +5559,6 @@ ngx_http_upstream_process_vary(ngx_http_request_t *r,
         return NGX_OK;
     }
 
-    if (h->value.len == 1 && h->value.data[0] == '*') {
-        u->cacheable = 0;
-        return NGX_OK;
-    }
-
     if (u->headers_in.vary->next) {
 
         len = 0;
@@ -5600,6 +5595,25 @@ ngx_http_upstream_process_vary(ngx_http_request_t *r,
         u->cacheable = 0;
     }
 
+    /* a response with "*" among the Vary members never matches */
+
+    p = vary.data;
+    last = p + vary.len;
+
+    while (p < last) {
+
+        while (p < last && (*p == ' ' || *p == '\t' || *p == ',')) { p++; }
+
+        if (p < last && *p == '*'
+            && (p + 1 == last || p[1] == ' ' || p[1] == '\t' || p[1] == ','))
+        {
+            u->cacheable = 0;
+            break;
+        }
+
+        while (p < last && *p != ',' && *p != ' ' && *p != '\t') { p++; }
+    }
+
     r->cache->vary = vary;
     }
 #endif
