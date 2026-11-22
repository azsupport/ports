The request body after an error and after it was discarded (pull request 1943 of
nginx/nginx; aZ, 23.11.2026: «бери»): see patch-src_http_ngx__http__request__body.c.

--- src/http/ngx_http_request.c.orig
+++ src/http/ngx_http_request.c
@@ -2040,6 +2040,15 @@ ngx_http_process_request_header(ngx_http_request_t *r)
     }
 
     if (r->headers_in.content_length) {
+        if (r->headers_in.transfer_encoding) {
+            ngx_log_error(NGX_LOG_INFO, r->connection->log, 0,
+                          "client sent \"Content-Length\" and "
+                          "\"Transfer-Encoding\" headers "
+                          "at the same time");
+            ngx_http_finalize_request(r, NGX_HTTP_BAD_REQUEST);
+            return NGX_ERROR;
+        }
+
         r->headers_in.content_length_n =
                             ngx_atoof(r->headers_in.content_length->value.data,
                                       r->headers_in.content_length->value.len);
@@ -2065,15 +2074,6 @@ ngx_http_process_request_header(ngx_http_request_t *r)
             && ngx_strncasecmp(r->headers_in.transfer_encoding->value.data,
                                (u_char *) "chunked", 7) == 0)
         {
-            if (r->headers_in.content_length) {
-                ngx_log_error(NGX_LOG_INFO, r->connection->log, 0,
-                              "client sent \"Content-Length\" and "
-                              "\"Transfer-Encoding\" headers "
-                              "at the same time");
-                ngx_http_finalize_request(r, NGX_HTTP_BAD_REQUEST);
-                return NGX_ERROR;
-            }
-
             r->headers_in.chunked = 1;
 
         } else {
@@ -3018,7 +3018,7 @@ ngx_http_finalize_connection(ngx_http_request_t *r)
 
     if (r->main->count != 1) {
 
-        if (r->discard_body) {
+        if (r->discarding_body) {
             r->read_event_handler = ngx_http_discarded_request_body_handler;
             ngx_add_timer(r->connection->read, clcf->lingering_timeout);
 
@@ -3083,7 +3083,7 @@ ngx_http_set_write_handler(ngx_http_request_t *r)
 
     r->http_state = NGX_HTTP_WRITING_REQUEST_STATE;
 
-    r->read_event_handler = r->discard_body ?
+    r->read_event_handler = r->discarding_body ?
                                 ngx_http_discarded_request_body_handler:
                                 ngx_http_test_reading;
     r->write_event_handler = ngx_http_writer;
