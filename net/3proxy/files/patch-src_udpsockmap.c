udpsockmap: a host name with a control byte or a space in a UDP datagram skipped,
and a UDP association whose authorization fails, or whose parent proxy of the
rules does not answer, ends instead of being relayed direct. From the 0.9 branch
of upstream after 0.9.9.3 (18.11.2026):
https://github.com/3proxy/3proxy/commit/4f4862e
https://github.com/3proxy/3proxy/commit/1772ded

--- src/udpsockmap.c.orig	2026-11-07 09:14:32 UTC
+++ src/udpsockmap.c
@@ -158,8 +158,10 @@
 /*
  * Authorize param->req and (re)build the server side of the association:
  * a parent proxy chain and/or an external address may be selected by the ACL.
- * Returns the authorization result. param->remsock is INVALID_SOCKET if the
- * socket can not be created, in this case the association can not continue.
+ * Returns the authorization result. param->remsock is INVALID_SOCKET when
+ * the authorization refused the association or the socket can not be
+ * created; the association can not continue then, so that a parent the
+ * rules demand is never quietly replaced by a direct relay.
  */
 static int udpreconnect(struct clientparam *param)
 {
@@ -185,9 +187,10 @@
 			param->remsock = INVALID_SOCKET;
 		}
 		udpreset(param);
+		return res;
 	}
-	if (udpbind(param)) return res? res : 11;
-	return res;
+	if (udpbind(param)) return 11;
+	return 0;
 }
 
 int udpsockmap(struct clientparam *param, int timeo)
@@ -277,6 +280,7 @@
 				if (len < 7 + sz) return 485;
 				memcpy(dstnamebuf, base + 5, sz);
 				dstnamebuf[sz] = 0;
+				if (badhostname(dstnamebuf)) continue;
 				dstname = dstnamebuf;
 				i = 5 + sz;
 				if (!getip46(param->srv->family, (unsigned char *)dstnamebuf,
