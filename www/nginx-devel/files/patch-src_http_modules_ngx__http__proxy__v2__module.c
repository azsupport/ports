The request body after an error and after it was discarded (pull request 1943 of
nginx/nginx; aZ, 23.11.2026: «бери»): see patch-src_http_ngx__http__request__body.c.

--- src/http/modules/ngx_http_proxy_v2_module.c.orig
+++ src/http/modules/ngx_http_proxy_v2_module.c
@@ -497,7 +497,7 @@ ngx_http_proxy_v2_create_request(ngx_http_request_t *r)
         ctx->ctx.internal_body_length = -1;
 
     } else if (r->discard_body) {
-        ctx->ctx.internal_body_length = 0;
+        ctx->ctx.internal_body_length = -1;
 
     } else {
         ctx->ctx.internal_body_length = r->headers_in.content_length_n;
