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

The request body after an error and after it was discarded (aZ, 23.11.2026 00:21:
«бери»; pull request 1943 of nginx/nginx as of 13.11.2026: the commits of Maxim Dounin
in freenginx of 2024 as Vadim Zhestikov of F5 brought them to nginx, 55a5a40dccde,
81082b5521dd, ac5635650bc6, f798ecafec05, 106b3832e7ef, 388a801e9bb9, 75794cb1f5ea, as
they are; 43fe0edddba1 of the series is here already, above). What a request that is
redirected to an error page carried of its body was not consistent after an error of
the reading of the body, or after the body was discarded, which matters where the error
page is proxied (error_page with proxy_pass, fastcgi_pass and the like):
- Content-Length and Transfer-Encoding together are refused before
  r->headers_in.content_length_n is set;
- after an error the body is cleared (r->request_body->bufs) and the connection
  lingers; a body that was read without buffering is cleared when it is to be read
  again;
- error_page 413 over HTTP/2 and HTTP/3: a discarded body counts as discarded there
  too, so the page is served also where the limit holds in its own location;
- a discarded body is no body: no Content-Length to a proxied backend, where it was
  "Content-Length: 0", and an empty $content_length, where it was the header of the
  client;
- no segfault on an error before the structure of the request body is there.
r->discard_body now stays set once the body is discarded (r->discarding_body, new, says
that it is being discarded), and ngx_http_request_t and ngx_http_request_body_t have a
bit field more each: a dynamic module is one built from this tree, as the module
packages of this port are.
What changes for a configuration:
- $content_length (also CONTENT_LENGTH of fastcgi_params) of a request whose body nginx
  discarded (answered by return, by a file, by an error page of nginx) is empty, "-" in
  a log, where it was the Content-Length of the client; the test '$content_length' of
  http_headers_multi.t of nginx-tests expects the old value;
- lua-nginx-module reads r->discard_body: after a discard ngx.req.set_body_data(),
  ngx.req.set_body_file(), ngx.req.init_body() and ngx.req.socket() fail and
  ngx.req.get_post_args() gives an empty table, always now and not only while the
  discard is under way (its documentation wants no discard before them). No other
  module of this port reads it (the sources of passenger, vts, testcookie, dav-ext,
  vod, ndk, geoip2, brotli, zstd, headers-more and ngx_cache_purge 3.0.4, 23.11.2026);
  the default branch of ngx_cache_purge (4c85729, 04.11.2026) does, for a discard under
  way: that is r->discarding_body here, to be looked at when the port takes it.
The two limits on chunk extensions above keep their lingering close.
Checked 23.11.2026 (before: this tree without the series): a POST of 5 bytes answered
by "return 204", $content_length "5" before and empty now; error_page 413 that is
proxied, client_max_body_size also in its location: over HTTP/1.1 the page of the
backend, which got "Content-Length: 0" before and no Content-Length now; over HTTP/2
and HTTP/3 the 413 page of nginx itself before, the page of the backend now, and
$content_length the same there; nginx-tests (512 files, 6296 tests, ASan and UBSan):
that one test apart, as before the series, and no report of UBSan in a line of a patch.

--- src/http/ngx_http_request_body.c.orig
+++ src/http/ngx_http_request_body.c
@@ -44,6 +44,18 @@ ngx_http_read_client_request_body(ngx_http_request_t *r,
 
     if (r != r->main || r->request_body || r->discard_body) {
         r->request_body_no_buffering = 0;
+
+        if (r->request_body && r->request_body->no_buffering) {
+            r->discard_body = 1;
+            r->request_body->bufs = NULL;
+
+            if (r->reading_body) {
+                r->reading_body = 0;
+                r->keepalive = 0;
+                r->lingering_close = 1;
+            }
+        }
+
         post_handler(r);
         return NGX_OK;
     }
@@ -69,6 +81,7 @@ ngx_http_read_client_request_body(ngx_http_request_t *r,
      *     rb->busy = NULL;
      *     rb->chunked = NULL;
      *     rb->received = 0;
+     *     rb->no_buffering = 0;
      *     rb->filter_need_buffering = 0;
      *     rb->last_sent = 0;
      *     rb->last_saved = 0;
@@ -214,6 +227,7 @@ done:
         } else {
             /* rc == NGX_AGAIN */
             r->reading_body = 1;
+            r->request_body->no_buffering = 1;
         }
 
         r->read_event_handler = ngx_http_block_reading;
@@ -221,7 +235,16 @@ done:
     }
 
     if (rc >= NGX_HTTP_SPECIAL_RESPONSE) {
+
+        r->lingering_close = 1;
+        r->discard_body = 1;
+
+        if (r->request_body) {
+            r->request_body->bufs = NULL;
+        }
+
         r->main->count--;
+        r->read_event_handler = ngx_http_block_reading;
     }
 
     return rc;
@@ -286,6 +309,12 @@ ngx_http_read_client_request_body_handler(ngx_http_request_t *r)
     rc = ngx_http_do_read_client_request_body(r);
 
     if (rc >= NGX_HTTP_SPECIAL_RESPONSE) {
+
+        r->lingering_close = 1;
+        r->discard_body = 1;
+        r->request_body->bufs = NULL;
+
+        r->read_event_handler = ngx_http_block_reading;
         ngx_http_finalize_request(r, rc);
     }
 }
@@ -640,6 +669,8 @@ ngx_http_discard_request_body(ngx_http_request_t *r)
         return NGX_OK;
     }
 
+    r->discard_body = 1;
+
 #if (NGX_HTTP_V2)
     if (r->stream) {
         r->stream->skip_data = 1;
@@ -703,7 +734,7 @@ ngx_http_discard_request_body(ngx_http_request_t *r)
     }
 
     r->count++;
-    r->discard_body = 1;
+    r->discarding_body = 1;
 
     return NGX_OK;
 }
@@ -732,7 +763,7 @@ ngx_http_discarded_request_body_handler(ngx_http_request_t *r)
         timer = (ngx_msec_t) r->lingering_time - (ngx_msec_t) ngx_time();
 
         if ((ngx_msec_int_t) timer <= 0) {
-            r->discard_body = 0;
+            r->discarding_body = 0;
             r->lingering_close = 0;
             ngx_http_finalize_request(r, NGX_ERROR);
             return;
@@ -745,7 +776,7 @@ ngx_http_discarded_request_body_handler(ngx_http_request_t *r)
     rc = ngx_http_read_discarded_request_body(r);
 
     if (rc == NGX_OK) {
-        r->discard_body = 0;
+        r->discarding_body = 0;
         r->lingering_close = 0;
         r->lingering_time = 0;
         ngx_http_finalize_request(r, NGX_DONE);
@@ -1144,6 +1175,17 @@ ngx_http_request_body_chunked_filter(ngx_http_request_t *r, ngx_chain_t *in)
 
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
@@ -1154,8 +1196,6 @@ ngx_http_request_body_chunked_filter(ngx_http_request_t *r, ngx_chain_t *in)
                                   r->headers_in.content_length_n,
                                   rb->chunked->size);
 
-                    r->lingering_close = 1;
-
                     return NGX_HTTP_REQUEST_ENTITY_TOO_LARGE;
                 }
 
@@ -1245,6 +1285,20 @@ ngx_http_request_body_chunked_filter(ngx_http_request_t *r, ngx_chain_t *in)
 
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
