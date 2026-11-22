HTTP/3: no reuse of the connection of a stream while the stream is reset (freenginx
d9fe808c1841 of Maxim Dounin, 02.06.2024; for nginx: commit e9abcb601 of the open pull
request 1696 of nginx/nginx, the backport of Elijah Zupancic of F5; aZ, 22.11.2026: «бери»).
When a worker out of free connections drains an idle one that is a request stream of
HTTP/3, ngx_http_v3_reset_stream() may send a stream cancellation, and what that calls
must not take the very same connection for reuse again (in freenginx: a recursion to a
stack overflow, or a use after free). In nginx 1.31.9 the cancellation is sent only when
the decoder stream exists already, so no connection is asked for there (read in the code,
22.11.2026); the line is a guard that keeps it so whatever the functions called do: nginx
1.31.9 itself fixed a reuse of this kind in ngx_quic_create_stream() (b5252dae1).

--- src/http/v3/ngx_http_v3_request.c.orig
+++ src/http/v3/ngx_http_v3_request.c
@@ -410,6 +410,8 @@ ngx_http_v3_reset_stream(ngx_connection_t *c)
 {
     ngx_http_v3_session_t  *h3c;
 
+    ngx_reusable_connection(c, 0);
+
     h3c = ngx_http_v3_get_session(c);
 
     if (!c->read->eof && !h3c->hq
