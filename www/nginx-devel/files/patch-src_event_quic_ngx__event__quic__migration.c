QUIC: no use of a path retired while its packet is handled (aZ, 22.11.2026, on the
open pull requests of nginx: «бери разобрав их сам»; pull request 1634 of nginx/nginx
of Vadim Zhestikov of F5, 10.08.2026, the three changes of it as they are; read in the
code of 1.31.9, the QUIC and HTTP/3 tests of nginx-tests pass with it, not reproduced
with a client). A NEW_CONNECTION_ID frame that retires the client id of the path its
packet came on frees that path (ngx_quic_retire_client_id() ->
ngx_quic_free_path()), and pkt->path still points at it, on the list of free paths
with its client id freed too, for the rest of the packet: a PATH_CHALLENGE after it
in the same packet was answered over the freed path with the retired client id
(against RFC 9000, 5.1.2), and ngx_quic_handle_migration() could make the freed path
the active one of the connection. Now a freed path has no client id, and the two
readers of pkt->path pass a path without one by.

--- src/event/quic/ngx_event_quic_migration.c.orig
+++ src/event/quic/ngx_event_quic_migration.c
@@ -40,7 +40,9 @@ ngx_quic_handle_path_challenge_frame(ngx_connection_t *c,
     ngx_quic_frame_t       *fp;
     ngx_quic_connection_t  *qc;
 
-    if (pkt->level != NGX_QUIC_ENCRYPTION_APPLICATION || pkt->path_challenged) {
+    if (pkt->level != NGX_QUIC_ENCRYPTION_APPLICATION || pkt->path_challenged
+        || pkt->path->cid == NULL)
+    {
         ngx_log_debug0(NGX_LOG_DEBUG_EVENT, c->log, 0,
                        "quic ignoring PATH_CHALLENGE");
         return NGX_OK;
@@ -424,6 +426,9 @@ ngx_quic_free_path(ngx_connection_t *c, ngx_quic_path_t *path)
         }
     }
 
+    /* a freed path has no client id; pkt->path may still reference it */
+    path->cid = NULL;
+
     ngx_log_debug2(NGX_LOG_DEBUG_EVENT, c->log, 0,
                    "quic path seq:%uL addr:%V retired",
                    path->seqnum, &path->addr_text);
@@ -459,6 +464,11 @@ ngx_quic_handle_migration(ngx_connection_t *c, ngx_quic_header_t *pkt)
 
     /* got non-probing packet via non-active path */
 
+    if (pkt->path->cid == NULL) {
+        /* the path was retired while handling the packet */
+        return NGX_OK;
+    }
+
     qc = ngx_quic_get_connection(c);
 
     ctx = ngx_quic_get_send_ctx(qc, pkt->level);
