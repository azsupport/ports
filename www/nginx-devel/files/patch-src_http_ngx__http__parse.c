Request body: a limit on chunk extensions and trailer headers (freenginx f3df785649ae of
Maxim Dounin, 30.03.2024; for nginx: commit c0df646b1 of the
open pull request 1696 of nginx/nginx, the backport of Elijah Zupancic of F5, 27.08.2026;
"Reported by Bartek Nowotarski"; aZ, 22.11.2026: «бери»): any amount of chunk extensions
and trailer headers of a chunked request body was read and skipped, past
client_max_body_size, for as long as the client sent them (a connection and the CPU of a
worker taken, with nothing of it counted). Their bytes are counted now
(ngx_http_chunked_t.skipped) and the request ends with 413 once they are more than
client_max_body_size; checked where a chunk header is parsed and where the parser asks for
more data, so what comes in one read with the end of the body is not counted against it.
nginx 1.31.9 has no such limit (checked 22.11.2026: 300 KB of extensions or of trailer
headers pass with client_max_body_size 1k; with the patch 413, and a body within the
limits as before).

--- src/http/ngx_http_parse.c.orig
+++ src/http/ngx_http_parse.c
@@ -2313,6 +2313,8 @@ ngx_http_parse_chunked(ngx_http_request_t *r, ngx_buf_t *b,
                 break;
             case LF:
                 goto invalid;
+            default:
+                ctx->skipped++;
             }
             break;
 
@@ -2351,6 +2353,8 @@ ngx_http_parse_chunked(ngx_http_request_t *r, ngx_buf_t *b,
                 break;
             case LF:
                 goto invalid;
+            default:
+                ctx->skipped++;
             }
             break;
 
@@ -2372,6 +2376,7 @@ ngx_http_parse_chunked(ngx_http_request_t *r, ngx_buf_t *b,
             case LF:
                 goto invalid;
             default:
+                ctx->skipped++;
                 state = sw_trailer_header;
             }
             break;
@@ -2389,6 +2394,8 @@ ngx_http_parse_chunked(ngx_http_request_t *r, ngx_buf_t *b,
                 break;
             case LF:
                 goto invalid;
+            default:
+                ctx->skipped++;
             }
             break;
 
