The request body after an error and after it was discarded (pull request 1943 of
nginx/nginx; aZ, 23.11.2026: «бери»): see patch-src_http_ngx__http__request__body.c.

--- src/http/v2/ngx_http_v2.c.orig
+++ src/http/v2/ngx_http_v2.c
@@ -1087,13 +1087,6 @@ ngx_http_v2_state_read_data(ngx_http_v2_connection_t *h2c, u_char *pos,
     r = stream->request;
     fc = r->connection;
 
-    if (r->reading_body && !r->request_body_no_buffering) {
-        ngx_log_debug0(NGX_LOG_DEBUG_HTTP, h2c->connection->log, 0,
-                       "skipping http2 DATA frame");
-
-        return ngx_http_v2_state_skip_padded(h2c, pos, end);
-    }
-
     if (r->headers_in.content_length_n < 0 && !r->headers_in.chunked) {
         ngx_log_debug0(NGX_LOG_DEBUG_HTTP, h2c->connection->log, 0,
                        "skipping http2 DATA frame");
@@ -1115,7 +1108,11 @@ ngx_http_v2_state_read_data(ngx_http_v2_connection_t *h2c, u_char *pos,
                                               stream->in_closed, 0);
 
         if (rc != NGX_OK && rc != NGX_AGAIN) {
+
             stream->skip_data = 1;
+            r->discard_body = 1;
+            r->request_body->bufs = NULL;
+
             ngx_http_finalize_request(r, rc);
         }
 
@@ -4071,6 +4068,7 @@ ngx_http_v2_run_request(ngx_http_request_t *r)
                           "client prematurely closed stream");
 
             r->stream->skip_data = 1;
+            r->discard_body = 1;
 
             ngx_http_finalize_request(r, NGX_HTTP_BAD_REQUEST);
             goto failed;
@@ -4511,7 +4509,11 @@ ngx_http_v2_read_client_request_body_handler(ngx_http_request_t *r)
     rc = ngx_http_v2_process_request_body(r, NULL, 0, r->stream->in_closed, 1);
 
     if (rc != NGX_OK && rc != NGX_AGAIN) {
+
         r->stream->skip_data = 1;
+        r->discard_body = 1;
+        r->request_body->bufs = NULL;
+
         ngx_http_finalize_request(r, rc);
         return;
     }
@@ -4552,6 +4554,8 @@ ngx_http_v2_read_client_request_body_handler(ngx_http_request_t *r)
                           "http2 negative window update");
 
             stream->skip_data = 1;
+            r->discard_body = 1;
+            r->request_body->bufs = NULL;
 
             ngx_http_finalize_request(r, NGX_HTTP_INTERNAL_SERVER_ERROR);
             return;
@@ -4565,6 +4569,9 @@ ngx_http_v2_read_client_request_body_handler(ngx_http_request_t *r)
         == NGX_ERROR)
     {
         stream->skip_data = 1;
+        r->discard_body = 1;
+        r->request_body->bufs = NULL;
+
         ngx_http_finalize_request(r, NGX_HTTP_INTERNAL_SERVER_ERROR);
         return;
     }
@@ -4573,6 +4580,9 @@ ngx_http_v2_read_client_request_body_handler(ngx_http_request_t *r)
 
     if (ngx_http_v2_send_output_queue(h2c) == NGX_ERROR) {
         stream->skip_data = 1;
+        r->discard_body = 1;
+        r->request_body->bufs = NULL;
+
         ngx_http_finalize_request(r, NGX_HTTP_INTERNAL_SERVER_ERROR);
         return;
     }
