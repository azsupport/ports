A 101 of a backend taken only where an upgrade is under way (pull request 1941 of
nginx/nginx): see patch-src_http_modules_ngx__http__proxy__module.c.

--- src/http/modules/ngx_http_scgi_module.c.orig
+++ src/http/modules/ngx_http_scgi_module.c
@@ -1224,6 +1224,18 @@ ngx_http_scgi_process_header(ngx_http_request_t *r)
                 && r->headers_in.upgrade)
             {
                 u->upgrade = 1;
+
+            } else if (u->headers_in.status_n == NGX_HTTP_SWITCHING_PROTOCOLS) {
+
+                /* reject unexpected connection upgrades */
+
+                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                              "upstream sent unexpected status \"%V\"",
+                              u->headers_in.status_line.len
+                              ? &u->headers_in.status_line
+                              : &u->headers_in.status->value);
+
+                return NGX_HTTP_UPSTREAM_INVALID_HEADER;
             }
 
             return NGX_OK;
