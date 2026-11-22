SSL: the callback of SSL_CTX_set_cert_cb() may yield (the patch of OpenResty for
nginx 1.31.8, patches/nginx/1.31.8/nginx-1.31.8-ssl_cert_cb_yield.patch of
https://github.com/openresty/openresty at 1779c93, 07.11.2026; Debian and Ubuntu carry
it too, nginx-ssl_cert_cb_yield.patch): SSL_ERROR_WANT_X509_LOOKUP of the handshake
and of the early data waits for the next event instead of failing, so that
ssl_certificate_by_lua* of www/nginx-devel-lua can do non-blocking I/O (cosockets,
ngx.sleep) while it gives the certificate (aZ, 18.11.2026: «давай»). Without such a
handler nothing changes.

SSL: no busy loop when SSL_write() wants to read (aZ, 22.11.2026, on the open pull
requests of nginx: «бери разобрав их сам»; pull request 2004 of nginx/nginx of Elías
Martín, 18.11.2026, issue 1969, its four changes as they are; read in the code of
1.31.9, the tests of nginx-tests pass with it, not reproduced). With ssl_early_data on
a response can be ready before the Finished of the client has come (the early data
read to its end, the handshake not complete): SSL_write() returns
SSL_ERROR_WANT_READ, ngx_ssl_write() puts ngx_ssl_read_handler on the read event and
returns NGX_AGAIN, with c->write->ready left set. For the connection of a client
ngx_http_write_filter() then posts the write event again on every pass of the event
loop (a chain not sent, the event ready): the worker spins for as long as the client
holds its Finished back, and send_timeout does not fire, its timer set again on each
pass. Now c->write->ready is cleared where a write waits for a read (ngx_ssl_write(),
ngx_ssl_write_early(), ngx_ssl_sendfile()) and set again by ngx_ssl_read_handler()
before it calls the write handler: without that the write would wait for a write
event that does not come, the socket writable all along, and HTTP/2, whose
ngx_http_v2_send_output_queue() returns at once while the write event is not ready,
would send nothing.

--- src/event/ngx_event_openssl.c.orig
+++ src/event/ngx_event_openssl.c
@@ -2317,6 +2317,23 @@ ngx_ssl_handshake(ngx_connection_t *c)
         return NGX_AGAIN;
     }
 
+#if OPENSSL_VERSION_NUMBER >= 0x10002000L
+    if (sslerr == SSL_ERROR_WANT_X509_LOOKUP) {
+        c->read->handler = ngx_ssl_handshake_handler;
+        c->write->handler = ngx_ssl_handshake_handler;
+
+        if (ngx_handle_read_event(c->read, 0) != NGX_OK) {
+            return NGX_ERROR;
+        }
+
+        if (ngx_handle_write_event(c->write, 0) != NGX_OK) {
+            return NGX_ERROR;
+        }
+
+        return NGX_AGAIN;
+    }
+#endif
+
     err = (sslerr == SSL_ERROR_SYSCALL) ? ngx_errno : 0;
 
     if (sslerr == SSL_ERROR_SYSCALL && ERR_peek_error() == 0 && err == 0) {
@@ -2475,6 +2492,21 @@ ngx_ssl_try_early_data(ngx_connection_t *c)
         return NGX_AGAIN;
     }
 
+    if (sslerr == SSL_ERROR_WANT_X509_LOOKUP) {
+        c->read->handler = ngx_ssl_handshake_handler;
+        c->write->handler = ngx_ssl_handshake_handler;
+
+        if (ngx_handle_read_event(c->read, 0) != NGX_OK) {
+            return NGX_ERROR;
+        }
+
+        if (ngx_handle_write_event(c->write, 0) != NGX_OK) {
+            return NGX_ERROR;
+        }
+
+        return NGX_AGAIN;
+    }
+
     err = (sslerr == SSL_ERROR_SYSCALL) ? ngx_errno : 0;
 
     if (sslerr == SSL_ERROR_SYSCALL && ERR_peek_error() == 0 && err == 0) {
@@ -3324,6 +3356,7 @@ ngx_ssl_write(ngx_connection_t *c, u_char *data, size_t size)
         ngx_log_debug0(NGX_LOG_DEBUG_EVENT, c->log, 0,
                        "SSL_write: want read");
 
+        c->write->ready = 0;
         c->read->ready = 0;
 
         if (ngx_handle_read_event(c->read, 0) != NGX_OK) {
@@ -3439,6 +3472,7 @@ ngx_ssl_write_early(ngx_connection_t *c, u_char *data, size_t size)
         ngx_log_debug0(NGX_LOG_DEBUG_EVENT, c->log, 0,
                        "SSL_write_early_data: want read");
 
+        c->write->ready = 0;
         c->read->ready = 0;
 
         if (ngx_handle_read_event(c->read, 0) != NGX_OK) {
@@ -3619,6 +3653,7 @@ ngx_ssl_sendfile(ngx_connection_t *c, ngx_buf_t *file, size_t size)
         ngx_log_debug0(NGX_LOG_DEBUG_EVENT, c->log, 0,
                        "SSL_sendfile: want read");
 
+        c->write->ready = 0;
         c->read->ready = 0;
 
         if (ngx_handle_read_event(c->read, 0) != NGX_OK) {
@@ -3662,6 +3697,8 @@ ngx_ssl_read_handler(ngx_event_t *rev)
 
     ngx_log_debug0(NGX_LOG_DEBUG_EVENT, c->log, 0, "SSL read handler");
 
+    c->write->ready = 1;
+
     c->write->handler(c->write);
 }
 
