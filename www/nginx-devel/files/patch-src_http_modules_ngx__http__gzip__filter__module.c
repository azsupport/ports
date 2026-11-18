Gzip: fixed duplicate ngx_pfree() on ctx->preallocated (freenginx 4a31b253 of 20.06.2026,
released in freenginx 1.31.3; for nginx: pull request 1696 of nginx/nginx, 36b71d06, open,
18.11.2026): ngx_http_gzip_filter_deflate_end() freed ctx->preallocated and left the
pointer, and the error path of ngx_http_gzip_body_filter() could free it once more
(an error in the next body filters while the last part is sent). nginx 1.31.9 still has
it (aZ, 18.11.2026 22:39: «проверил фиксы? может висят в иссуес или в коммитах еще не
зааррувленых?»).

--- src/http/modules/ngx_http_gzip_filter_module.c.orig
+++ src/http/modules/ngx_http_gzip_filter_module.c
@@ -891,6 +891,7 @@ ngx_http_gzip_filter_deflate_end(ngx_http_request_t *r,
     }
 
     ngx_pfree(r->pool, ctx->preallocated);
+    ctx->preallocated = NULL;
 
     cl = ngx_alloc_chain_link(r->pool);
     if (cl == NULL) {
