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

--- src/http/modules/ngx_http_gzip_filter_module.c.orig
+++ src/http/modules/ngx_http_gzip_filter_module.c
@@ -263,6 +263,18 @@ ngx_http_gzip_header_filter(ngx_http_request_t *r)
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
@@ -891,6 +903,7 @@ ngx_http_gzip_filter_deflate_end(ngx_http_request_t *r,
     }
 
     ngx_pfree(r->pool, ctx->preallocated);
+    ctx->preallocated = NULL;
 
     cl = ngx_alloc_chain_link(r->pool);
     if (cl == NULL) {
