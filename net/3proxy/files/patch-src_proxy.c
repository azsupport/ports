proxy took the credentials of an earlier request on a keep-alive connection for
the next request, which brought none of its own. From the 0.9 branch of upstream
after 0.9.9.3:
https://github.com/3proxy/3proxy/commit/d82b780dda557f1fa9b3fb79faab2ced548f0396

--- src/proxy.c.orig	2026-11-07 09:14:32 UTC
+++ src/proxy.c
@@ -314,6 +314,27 @@
  clhdrofs_req = -1;
  param->nolongdatfilter = 0;
 
+ /* What the request brought belongs to it alone. A connection can carry
+    a request after another's, so the credentials of an earlier request
+    decide nothing for this one. */
+ if(param->username){
+	free(param->username);
+	param->username = NULL;
+ }
+ if(param->password){
+	free(param->password);
+	param->password = NULL;
+ }
+ param->pwtype = 0;
+ if(param->extusername){
+	free(param->extusername);
+	param->extusername = NULL;
+ }
+ if(param->extpassword){
+	free(param->extpassword);
+	param->extpassword = NULL;
+ }
+
 
  if(keepalive && (param->cliinbuf == param->clioffset) && (param->remsock != INVALID_SOCKET)){
 	memset(fds, 0, sizeof(fds));
