smtpp: a login has to name a host to connect to (a login of a port alone named
none). From the 0.9 branch of upstream after 0.9.9.3 (18.11.2026):
https://github.com/3proxy/3proxy/commit/f105a27

--- src/smtpp.c.orig	2026-11-07 09:14:32 UTC
+++ src/smtpp.c
@@ -195,6 +195,10 @@
 	}
  }
 
+ /* A login has to end with a host to connect to: what follows reads the
+    host name, and without one there is nowhere to go. */
+ if(!param->hostname || !param->extusername){RETURN(669);}
+
 #ifndef WITHMAIN
  {
 	int action, reqbufsize, reqsize;
