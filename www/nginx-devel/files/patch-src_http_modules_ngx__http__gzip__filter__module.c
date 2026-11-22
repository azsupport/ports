Gzip: fixed duplicate ngx_pfree() on ctx->preallocated (freenginx 4a31b253 of 20.06.2026,
released in freenginx 1.31.3; for nginx: pull request 1696 of nginx/nginx, 36b71d06, open,
18.11.2026): ngx_http_gzip_filter_deflate_end() freed ctx->preallocated and left the
pointer, and the error path of ngx_http_gzip_body_filter() could free it once more
(an error in the next body filters while the last part is sent). nginx 1.31.9 still has
it (aZ, 18.11.2026 22:39: «проверил фиксы? может висят в иссуес или в коммитах еще не
зааррувленых?»).

A response the slice filter puts together for a request with a Range is not
compressed (aZ, 22.11.2026: «делай»; found by the review of that day, and so in nginx
1.31.9 with its own gzip alone). A compression filter turns the ranges off for the
response of the main request, the range filter after it passes that response by, and
it goes out as a 200 with the whole slice the range begins in; the subrequests of the
next slices are not compressed apart, and they still cut their slices to the Range of
the client. So "Range: bytes=0-99" for an object of 3.3 MB of a compressed type in
slices of 1 MB got a 200 with the first megabyte for the whole object, and nginx
fetched every slice to the end of the object for it. Not compressed, such a response
is the 206 the client asked for, made of the slices its range needs; a response
without a Range is compressed whole, as before. The same in the gzip filter of nginx
(files/patch-src_http_modules_ngx__http__gzip__filter__module.c), ngx_brotli
(files/extra-patch-brotli-slice-range) and nginx-zstd-module
(files/extra-patch-zstd-slice-range).

No more than sendfile_max_chunk bytes of input compressed in one iteration of the
event loop (aZ, 23.11.2026 00:11, on pull request 1808 of nginx/nginx, which is of the
gzip filter alone: «ну значит надо брать и делать для zstd и brotli»). A large response
that the client reads fast enough never blocks, and the worker compressed all of it
before it turned to its other connections; a file is read and compressed in such a loop
(a proxied response is not: the reading of the backend goes through the event loop).
Now, after sendfile_max_chunk bytes of input (2m unless set; 0 turns it off), the filter
posts the write event for the next iteration and compresses on when it is handled, as
the write filter of nginx does with what it sends. Checked 23.11.2026, a file of 33 MB,
one worker, small requests beside it (a build with ASan and UBSan): the slowest of them
waited 258 ms with zstd, 645 with brotli and 938 with gzip before; 41 to 46, 80 to 123
and 116 to 141 with the patches (two runs); 30 such responses, from a file, proxied, in
slices and with limit_rate, over HTTP/1.1, HTTP/2 and HTTP/3, by the three encodings,
the same as the file.
Here: pull request 1808 of Vadim Zhestikov of F5 (its commit of 13.11.2026), as it is. The same
in ngx_brotli (files/extra-patch-brotli-yield) and nginx-zstd-module
(files/extra-patch-zstd-yield), which this port serves before gzip.

--- src/http/modules/ngx_http_gzip_filter_module.c.orig
+++ src/http/modules/ngx_http_gzip_filter_module.c
@@ -55,6 +55,7 @@ typedef struct {
     unsigned             redo:1;
     unsigned             done:1;
     unsigned             nomem:1;
+    unsigned             yield:1;
     unsigned             buffering:1;
     unsigned             zlib_ng:1;
     unsigned             state_allocated:1;
@@ -62,6 +63,8 @@ typedef struct {
     size_t               zin;
     size_t               zout;
 
+    size_t               limit;
+
     z_stream             zstream;
     ngx_http_request_t  *request;
 } ngx_http_gzip_ctx_t;
@@ -263,6 +266,18 @@ ngx_http_gzip_header_filter(ngx_http_request_t *r)
         return ngx_http_next_header_filter(r);
     }
 
+    /*
+     * A response the slice filter puts together for a request with a Range
+     * stays one with ranges (az): compressed, it would be a 200 with the
+     * ranges off for the main request alone, while the subrequests of the
+     * next slices still cut theirs to the Range of the client, a whole
+     * slice and pieces of the others in the place of the response
+     */
+
+    if (r->subrequest_ranges && r->headers_in.range) {
+        return ngx_http_next_header_filter(r);
+    }
+
     ctx = ngx_pcalloc(r->pool, sizeof(ngx_http_gzip_ctx_t));
     if (ctx == NULL) {
         return NGX_ERROR;
@@ -299,10 +314,11 @@ ngx_http_gzip_header_filter(ngx_http_request_t *r)
 static ngx_int_t
 ngx_http_gzip_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
 {
-    int                   rc;
-    ngx_uint_t            flush;
-    ngx_chain_t          *cl;
-    ngx_http_gzip_ctx_t  *ctx;
+    int                        rc;
+    ngx_uint_t                 flush;
+    ngx_chain_t               *cl;
+    ngx_http_gzip_ctx_t       *ctx;
+    ngx_http_core_loc_conf_t  *clcf;
 
     ctx = ngx_http_get_module_ctx(r, ngx_http_gzip_filter_module);
 
@@ -357,6 +373,15 @@ ngx_http_gzip_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
         r->connection->buffered |= NGX_HTTP_GZIP_BUFFERED;
     }
 
+    if (ctx->yield) {
+
+        if (r->connection->write->posted) {
+            return NGX_AGAIN;
+        }
+
+        ctx->yield = 0;
+    }
+
     if (ctx->nomem) {
 
         /* flush busy buffers */
@@ -376,6 +401,8 @@ ngx_http_gzip_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
         flush = ctx->busy ? 1 : 0;
     }
 
+    clcf = ngx_http_get_module_loc_conf(r, ngx_http_core_module);
+
     for ( ;; ) {
 
         /* cycle while we can write to a client */
@@ -445,6 +472,23 @@ ngx_http_gzip_body_filter(ngx_http_request_t *r, ngx_chain_t *in)
         if (ctx->done) {
             return rc;
         }
+
+        /*
+         * compressing a large response which the client reads fast enough
+         * never blocks, so limit the input compressed in one iteration
+         * of the event loop, similarly to sendfile_max_chunk
+         */
+
+        if (clcf->sendfile_max_chunk
+            && ctx->zstream.total_in - ctx->limit >= clcf->sendfile_max_chunk
+            && r->connection->write->ready
+            && !r->connection->write->delayed)
+        {
+            ctx->limit = ctx->zstream.total_in;
+            ctx->yield = 1;
+            ngx_post_event(r->connection->write, &ngx_posted_next_events);
+            return NGX_AGAIN;
+        }
     }
 
     /* unreachable */
@@ -891,6 +935,7 @@ ngx_http_gzip_filter_deflate_end(ngx_http_request_t *r,
     }
 
     ngx_pfree(r->pool, ctx->preallocated);
+    ctx->preallocated = NULL;
 
     cl = ngx_alloc_chain_link(r->pool);
     if (cl == NULL) {
