Charset: fixed handling of invalid UTF-8 characters (freenginx a25f0e75 of 20.06.2026,
released in freenginx 1.31.3; CVE-2026-48142): an invalid UTF-8 character split between
two buffers made ngx_decode_utf8() return an error and a position within the bytes saved
from the first buffer, and the code after it could read a byte before the second buffer.
nginx 1.31.9 still has it (aZ, 18.11.2026 22:39).

--- src/http/modules/ngx_http_charset_filter_module.c.orig
+++ src/http/modules/ngx_http_charset_filter_module.c
@@ -859,6 +859,10 @@ ngx_http_charset_recode_from_utf8(ngx_pool_t *pool, ngx_buf_t *buf,
             saved = &ctx->saved[ctx->saved_len];
         }
 
+        while (saved < ctx->saved + ctx->saved_len) {
+            *dst++ = *saved++;
+        }
+
     } else {
         dst = ngx_sprintf(dst, "&#%uD;", n);
     }
