Two fixes of freenginx for the reading of a request body that nginx 1.31.9 has not (the
open pull request 1696 of nginx/nginx, the backport of Elijah Zupancic of F5, 27.08.2026;
aZ, 22.11.2026: «бери»):
- a limit on chunk extensions and trailer headers (the two hunks of
  ngx_http_request_body_chunked_filter()): see patch-src_http_ngx__http__parse.c;
- reading blocked when an error is returned (freenginx 43fe0edddba1 of Maxim Dounin,
  27.04.2024; commit ae9fb8161 of the pull request, also its pull request 1874): after an
  error of the reading of the body the read event handler stayed, and "additional client
  activity can result in undefined behaviour, including segfaults", as with a chunked body
  and an error_page 400 or 413 that is proxied with proxy_ignore_client_abort; the handler
  is ngx_http_block_reading now (the hunks at "done:" and in
  ngx_http_read_client_request_body_handler()).

--- src/http/ngx_http_request_body.c.orig
+++ src/http/ngx_http_request_body.c
@@ -222,6 +222,7 @@ done:
 
     if (rc >= NGX_HTTP_SPECIAL_RESPONSE) {
         r->main->count--;
+        r->read_event_handler = ngx_http_block_reading;
     }
 
     return rc;
@@ -286,6 +287,7 @@ ngx_http_read_client_request_body_handler(ngx_http_request_t *r)
     rc = ngx_http_do_read_client_request_body(r);
 
     if (rc >= NGX_HTTP_SPECIAL_RESPONSE) {
+        r->read_event_handler = ngx_http_block_reading;
         ngx_http_finalize_request(r, rc);
     }
 }
@@ -1144,6 +1146,17 @@ ngx_http_request_body_chunked_filter(ngx_http_request_t *r, ngx_chain_t *in)
 
                 clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
 
+                if (clcf->client_max_body_size
+                    && clcf->client_max_body_size < rb->chunked->skipped)
+                {
+                    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                                  "client sent too many chunk extensions");
+
+                    r->lingering_close = 1;
+
+                    return NGX_HTTP_REQUEST_ENTITY_TOO_LARGE;
+                }
+
                 if (clcf->client_max_body_size
                     && clcf->client_max_body_size
                        - r->headers_in.content_length_n < rb->chunked->size)
@@ -1245,6 +1258,20 @@ ngx_http_request_body_chunked_filter(ngx_http_request_t *r, ngx_chain_t *in)
 
             if (rc == NGX_AGAIN) {
 
+                clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
+
+                if (clcf->client_max_body_size
+                    && clcf->client_max_body_size < rb->chunked->skipped)
+                {
+                    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                                  "client sent too many chunk extensions "
+                                  "or trailer headers");
+
+                    r->lingering_close = 1;
+
+                    return NGX_HTTP_REQUEST_ENTITY_TOO_LARGE;
+                }
+
                 /* set rb->rest, amount of data we want to see next time */
 
                 cscf = ngx_http_get_module_srv_conf(r, ngx_http_core_module);
