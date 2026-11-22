Upstream: a 101 (Switching Protocols) of a backend taken only where an upgrade is
under way (aZ, 22.11.2026: «бери разобрав их сам»; pull request 1941 of nginx/nginx,
its two commits of Vadim Zhestikov of F5, 05.11.2026, after freenginx ee7201216801 of
Maxim Dounin and the one before it, as they are). nginx took a 101 of a backend for an
upgrade whenever the client had sent an Upgrade header, also where the configuration
sent no Upgrade to the backend (proxy_set_header Upgrade ...), and passed it on as an
ordinary response where the client had not asked: now such a 101 is an invalid
response of the backend (502, or the next upstream), by proxy, fastcgi, scgi and uwsgi
alike. A WebSocket location with "proxy_set_header Upgrade $http_upgrade" is as
before: the tests of nginx-tests for it pass.

--- src/http/modules/ngx_http_proxy_module.c.orig
+++ src/http/modules/ngx_http_proxy_module.c
@@ -1183,6 +1183,7 @@ ngx_http_proxy_create_key(ngx_http_request_t *r)
 static ngx_int_t
 ngx_http_proxy_create_request(ngx_http_request_t *r)
 {
+    u_char                       *key;
     size_t                        len, uri_len, loc_len, body_len, headers_len,
                                   key_len, val_len;
     uintptr_t                     escape;
@@ -1468,6 +1469,8 @@ ngx_http_proxy_create_request(ngx_http_request_t *r)
             continue;
         }
 
+        key = e.pos;
+
         code = *(ngx_http_script_code_pt *) e.ip;
         code((ngx_http_script_engine_t *) &e);
 
@@ -1475,6 +1478,12 @@ ngx_http_proxy_create_request(ngx_http_request_t *r)
             return NGX_ERROR;
         }
 
+        if (e.pos - key == 7
+            && ngx_strncasecmp(key, (u_char *) "Upgrade", 7) == 0)
+        {
+            ctx->upgrade = 1;
+        }
+
         if (ngx_http_script_check_length(&e, 2) != NGX_OK) {
             return NGX_ERROR;
         }
@@ -2039,12 +2048,22 @@ ngx_http_proxy_process_header(ngx_http_request_t *r)
                 u->keepalive = !u->headers_in.connection_close;
             }
 
-            if (u->headers_in.status_n == NGX_HTTP_SWITCHING_PROTOCOLS) {
+            if (u->headers_in.status_n == NGX_HTTP_SWITCHING_PROTOCOLS
+                && r->headers_in.upgrade
+                && ctx->upgrade)
+            {
                 u->keepalive = 0;
+                u->upgrade = 1;
 
-                if (r->headers_in.upgrade) {
-                    u->upgrade = 1;
-                }
+            } else if (u->headers_in.status_n == NGX_HTTP_SWITCHING_PROTOCOLS) {
+
+                /* reject unexpected connection upgrades */
+
+                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                              "upstream sent unexpected status \"%V\"",
+                              &u->headers_in.status_line);
+
+                return NGX_HTTP_UPSTREAM_INVALID_HEADER;
             }
 
             return NGX_OK;
