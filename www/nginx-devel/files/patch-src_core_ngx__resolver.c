Resolver: the lengths of names limited (aZ, 22.11.2026: «бери разобрав их сам»;
pull request 1858 of nginx/nginx, its three commits of Sergey Kandaurov, 06.10.2026 and
08.10.2026, as they are). A label of a name to resolve only had to fit the length
octet (up to 255, where 64 and above is a compression pointer to a DNS server), and a
name in a response was limited by the number of its labels and pointers alone, about
8 kilobytes expanded. Now a label over 63 octets or a name over 253 characters is not
asked for (the name is not found), and a name over 255 octets in a response is an
error of the response (RFC 1035, 2.3.4 and 3.1). The test "long name" of nginx-tests,
a name of 255 characters, expects what was before.

--- src/core/ngx_resolver.c.orig
+++ src/core/ngx_resolver.c
@@ -848,7 +848,10 @@ ngx_resolve_name_locked(ngx_resolver_t *r, ngx_resolver_ctx_t *ctx,
     if (rc == NGX_DECLINED) {
         ngx_rbtree_delete(tree, &rn->node);
 
-        ngx_resolver_free(r, rn->query);
+        if (rn->query) {
+            ngx_resolver_free(r, rn->query);
+        }
+
         ngx_resolver_free(r, rn->name);
         ngx_resolver_free(r, rn);
 
@@ -3718,7 +3721,11 @@ ngx_resolver_create_name_query(ngx_resolver_t *r, ngx_resolver_node_t *rn,
     ngx_resolver_qs_t   *qs;
     ngx_resolver_hdr_t  *query;
 
-    nlen = name->len ? (1 + name->len + 1) : 1;
+    if (name->len == 0 || name->len > 253) {
+        return NGX_DECLINED;
+    }
+
+    nlen = 1 + name->len + 1;
 
     len = sizeof(ngx_resolver_hdr_t) + nlen + sizeof(ngx_resolver_qs_t);
 
@@ -3777,17 +3784,13 @@ ngx_resolver_create_name_query(ngx_resolver_t *r, ngx_resolver_node_t *rn,
     p--;
     *p-- = '\0';
 
-    if (name->len == 0)  {
-        return NGX_DECLINED;
-    }
-
     for (s = name->data + name->len - 1; s >= name->data; s--) {
         if (*s != '.') {
             *p = *s;
             len++;
 
         } else {
-            if (len == 0 || len > 255) {
+            if (len == 0 || len > 63) {
                 return NGX_DECLINED;
             }
 
@@ -3798,7 +3801,7 @@ ngx_resolver_create_name_query(ngx_resolver_t *r, ngx_resolver_node_t *rn,
         p--;
     }
 
-    if (len == 0 || len > 255) {
+    if (len == 0 || len > 63) {
         return NGX_DECLINED;
     }
 
@@ -3846,7 +3849,11 @@ ngx_resolver_create_srv_query(ngx_resolver_t *r, ngx_resolver_node_t *rn,
     ngx_resolver_qs_t   *qs;
     ngx_resolver_hdr_t  *query;
 
-    nlen = name->len ? (1 + name->len + 1) : 1;
+    if (name->len == 0 || name->len > 253) {
+        return NGX_DECLINED;
+    }
+
+    nlen = 1 + name->len + 1;
 
     len = sizeof(ngx_resolver_hdr_t) + nlen + sizeof(ngx_resolver_qs_t);
 
@@ -3893,17 +3900,13 @@ ngx_resolver_create_srv_query(ngx_resolver_t *r, ngx_resolver_node_t *rn,
     p--;
     *p-- = '\0';
 
-    if (name->len == 0)  {
-        return NGX_DECLINED;
-    }
-
     for (s = name->data + name->len - 1; s >= name->data; s--) {
         if (*s != '.') {
             *p = *s;
             len++;
 
         } else {
-            if (len == 0 || len > 255) {
+            if (len == 0 || len > 63) {
                 return NGX_DECLINED;
             }
 
@@ -3914,7 +3917,7 @@ ngx_resolver_create_srv_query(ngx_resolver_t *r, ngx_resolver_node_t *rn,
         p--;
     }
 
-    if (len == 0 || len > 255) {
+    if (len == 0 || len > 63) {
         return NGX_DECLINED;
     }
 
@@ -4041,6 +4044,11 @@ ngx_resolver_copy(ngx_resolver_t *r, ngx_str_t *name, u_char *buf, u_char *src,
         n = *p++;
 
         if (n == 0) {
+            if (len > 254) {
+                err = "too long name in DNS response";
+                goto invalid;
+            }
+
             goto done;
         }
 
