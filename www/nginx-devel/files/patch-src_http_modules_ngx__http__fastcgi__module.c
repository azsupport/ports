A 101 of a backend taken only where an upgrade is under way (pull request 1941 of
nginx/nginx): see patch-src_http_modules_ngx__http__proxy__module.c.

--- src/http/modules/ngx_http_fastcgi_module.c.orig
+++ src/http/modules/ngx_http_fastcgi_module.c
@@ -2117,6 +2117,19 @@ ngx_http_fastcgi_process_header(ngx_http_request_t *r)
                     ngx_str_set(&u->headers_in.status_line, "200 OK");
                 }
 
+                if (u->headers_in.status_n == NGX_HTTP_SWITCHING_PROTOCOLS) {
+
+                    /* reject unexpected connection upgrades */
+
+                    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                                  "upstream sent unexpected status \"%V\"",
+                                  u->headers_in.status_line.len
+                                  ? &u->headers_in.status_line
+                                  : &u->headers_in.status->value);
+
+                    return NGX_HTTP_UPSTREAM_INVALID_HEADER;
+                }
+
                 if (u->state && u->state->status == 0) {
                     u->state->status = u->headers_in.status_n;
                 }
