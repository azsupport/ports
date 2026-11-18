SSL: the callback of SSL_CTX_set_cert_cb() may yield (the patch of OpenResty for
nginx 1.31.8, patches/nginx/1.31.8/nginx-1.31.8-ssl_cert_cb_yield.patch of
https://github.com/openresty/openresty at 1779c93, 07.11.2026; Debian and Ubuntu carry
it too, nginx-ssl_cert_cb_yield.patch): SSL_ERROR_WANT_X509_LOOKUP of the handshake
and of the early data waits for the next event instead of failing, so that
ssl_certificate_by_lua* of www/nginx-devel-lua can do non-blocking I/O (cosockets,
ngx.sleep) while it gives the certificate (aZ, 18.11.2026: «давай»). Without such a
handler nothing changes.

--- src/event/ngx_event_openssl.c.orig
+++ src/event/ngx_event_openssl.c
@@ -2317,6 +2317,23 @@
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
@@ -2464,6 +2481,21 @@
         c->read->handler = ngx_ssl_handshake_handler;
         c->write->handler = ngx_ssl_handshake_handler;
 
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
+    if (sslerr == SSL_ERROR_WANT_X509_LOOKUP) {
+        c->read->handler = ngx_ssl_handshake_handler;
+        c->write->handler = ngx_ssl_handshake_handler;
+
         if (ngx_handle_read_event(c->read, 0) != NGX_OK) {
             return NGX_ERROR;
         }
