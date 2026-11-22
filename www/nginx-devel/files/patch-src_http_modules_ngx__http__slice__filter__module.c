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

Slice filter: the context of a slice subrequest that went to a named location (aZ,
23.11.2026 00:21: «бери»; pull request 1611 of nginx/nginx of Gabriel Clima of Gcore,
28.07.2026, as it is). A slice subrequest that an error_page sends to a named location
(with proxy_intercept_errors in the location of the slices) lost its slice context
there: $slice_range was empty, the request went to the origin without a Range, and the
whole 200 response of the origin went into the response at the offset of the slice (and
into the cache under a key without the range). Now $slice_range takes the context back
from the main request, when the subrequest is the one the main request waits for.
Checked 23.11.2026, an origin that has the first slice alone and a second one behind
"error_page 404 = @named", an object of 3300000 bytes: nginx 1.31.9 sent 4348576 bytes
under Content-Length: 3300000 (the first slice and the whole object; one request to the
second origin, without a Range; "missing slice response" in the log after that); with
the patch the object, three requests to the second origin, each with its Range.

Slice filter: no signed overflow with a Content-Range near the largest offset
(aZ, 23.11.2026 00:21: «бери»; pull request 1942 of nginx/nginx of freedom-winds,
06.11.2026, as it is). "bytes 0-9223372036854775807/9223372036854775807" of an origin
overflowed the end offset, and a start near that the sum with the slice size:
undefined behaviour before the comparison that refuses such a response anyway (UBSan,
23.11.2026: "signed integer overflow" at both; the log had the wrapped numbers). Now
both are refused before the arithmetic.

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
@@ -161,6 +163,13 @@ ngx_http_slice_header_filter(ngx_http_request_t *r)
 
     slcf = ngx_http_get_module_loc_conf(r, ngx_http_slice_filter_module);
 
+    if (cr.start > NGX_MAX_OFF_T_VALUE - (off_t) slcf->size) {
+        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
+                      "unexpected range in slice response: %O-%O",
+                      cr.start, cr.end);
+        return NGX_ERROR;
+    }
+
     end = ngx_min(cr.start + (off_t) slcf->size, cr.complete_length);
 
     if (cr.start != ctx->start || cr.end != end) {
@@ -170,7 +179,29 @@ ngx_http_slice_header_filter(ngx_http_request_t *r)
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
@@ -217,6 +248,7 @@ ngx_http_slice_header_filter(ngx_http_request_t *r)
 static ngx_int_t
 ngx_http_slice_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
 {
+    off_t                       size;
     ngx_int_t                   rc;
     ngx_chain_t                *cl;
     ngx_http_slice_ctx_t       *ctx;
@@ -224,7 +256,30 @@ ngx_http_slice_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
 
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
 
@@ -347,6 +402,10 @@ ngx_http_slice_parse_content_range(ngx_http_request_t *r,
         end = end * 10 + (*p++ - '0');
     }
 
+    if (end == NGX_MAX_OFF_T_VALUE) {
+        return NGX_ERROR;
+    }
+
     end++;
 
     while (*p == ' ') { p++; }
@@ -401,6 +460,23 @@ ngx_http_slice_range_variable(ngx_http_request_t *r,
 
     ctx = ngx_http_get_module_ctx(r, ngx_http_slice_filter_module);
 
+    if (ctx == NULL && r != r->main) {
+
+        /*
+         * a named location redirect zeroes the subrequest's module
+         * contexts; restore the slice context from the main request
+         */
+
+        ctx = ngx_http_get_module_ctx(r->main, ngx_http_slice_filter_module);
+
+        if (ctx != NULL && ctx->sr == r) {
+            ngx_http_set_ctx(r, ctx, ngx_http_slice_filter_module);
+
+        } else {
+            ctx = NULL;
+        }
+    }
+
     if (ctx == NULL) {
         if (r != r->main || r->headers_out.status) {
             v->not_found = 1;
