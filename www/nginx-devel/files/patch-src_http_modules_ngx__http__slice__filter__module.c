Slice filter: the length of a slice response checked (aZ, 22.11.2026, on the open
pull requests of nginx: «бери разобрав их сам, вдруг там говно написали»; pull request
1966 of nginx/nginx of Vadim Zhestikov of F5, 11.11.2026, as it is). The filter took a
slice whose body is not of the length its Content-Range says, and later slices that
report another complete length: with such an origin the response had bytes too many or
too few among those of the object, under the Content-Length sent already, and nothing
in the log. Checked 23.11.2026 with an origin that sends 10 bytes more, 10 fewer and a
Content-Length 5 short: nginx 1.31.9 sent 3300040, 3299960 and 3299980 bytes for an
object of 3300000 without a line in the log; with the patch each is logged and the
response ends there, and so a second slice of another complete length. The same origin
answering right: 96 and 55 requests through slices, with the cache and without, over
HTTP/1.1, HTTP/2 and HTTP/3, as before.

--- src/http/modules/ngx_http_slice_filter_module.c.orig
+++ src/http/modules/ngx_http_slice_filter_module.c
@@ -18,6 +18,8 @@ typedef struct {
 typedef struct {
     off_t                start;
     off_t                end;
+    off_t                rest;
+    off_t                complete_length;
     ngx_str_t            range;
     ngx_str_t            etag;
     unsigned             last:1;
@@ -170,7 +172,29 @@ ngx_http_slice_header_filter(ngx_http_request_t *r)
         return NGX_ERROR;
     }
 
+    if (r == r->main) {
+        ctx->complete_length = cr.complete_length;
+
+    } else if (cr.complete_length != ctx->complete_length) {
+        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                      "unexpected complete length in slice response: "
+                      "%O bytes, expected: %O bytes",
+                      cr.complete_length, ctx->complete_length);
+        return NGX_ERROR;
+    }
+
+    if (r->headers_out.content_length_n != -1
+        && r->headers_out.content_length_n != cr.end - cr.start)
+    {
+        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                      "unexpected content length in slice response: "
+                      "%O bytes, expected: %O bytes",
+                      r->headers_out.content_length_n, cr.end - cr.start);
+        return NGX_ERROR;
+    }
+
     ctx->start = end;
+    ctx->rest = cr.end - cr.start;
     ctx->active = 1;
 
     r->headers_out.status = NGX_HTTP_OK;
@@ -217,6 +241,7 @@ ngx_http_slice_header_filter(ngx_http_request_t *r)
 static ngx_int_t
 ngx_http_slice_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
 {
+    off_t                       size;
     ngx_int_t                   rc;
     ngx_chain_t                *cl;
     ngx_http_slice_ctx_t       *ctx;
@@ -224,7 +249,30 @@ ngx_http_slice_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
 
     ctx = ngx_http_get_module_ctx(r, ngx_http_slice_filter_module);
 
-    if (ctx == NULL || r != r->main) {
+    if (ctx == NULL) {
+        return ngx_http_next_body_filter(r, in);
+    }
+
+    for (cl = in; cl; cl = cl->next) {
+        size = ngx_buf_size(cl->buf);
+
+        if (size > ctx->rest) {
+            ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                          "slice response body is longer than its range");
+            return NGX_ERROR;
+        }
+
+        ctx->rest -= size;
+
+        if ((cl->buf->last_buf || cl->buf->last_in_chain) && ctx->rest) {
+            ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                          "slice response body is shorter than its range, "
+                          "missing: %O bytes", ctx->rest);
+            return NGX_ERROR;
+        }
+    }
+
+    if (r != r->main) {
         return ngx_http_next_body_filter(r, in);
     }
 
