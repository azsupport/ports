socks: a host name with a control byte or a space refused (SOCKS4a, SOCKS5), and
a SOCKS4a request is not a connect to the null address (it names its host after
it). From the 0.9 branch of upstream after 0.9.9.3 (18.11.2026):
https://github.com/3proxy/3proxy/commit/4f4862e
https://github.com/3proxy/3proxy/commit/4f7a611

--- src/socks.c.orig	2026-11-07 09:14:32 UTC
+++ src/socks.c
@@ -119,7 +119,10 @@
 		}
 		res = socks5_setaddr(param->srv->family, c, buf, &param->req);
 		if(res == 1) {RETURN(997);}
-		if(res == 2 && command == 1) {RETURN(431);}
+		/* The null address is no destination to connect to, except in
+		   SOCKS4a, where it says that the destination is the name which
+		   follows it. */
+		if(res == 2 && ver == 5 && command == 1) {RETURN(431);}
 		param->sinsr = param->req;
 		myinet_ntop(*SAFAMILY(&param->sinsr), SAADDR(&param->sinsr), (char *)buf, 64);
 		break;
@@ -137,6 +140,7 @@
 	default:
 		RETURN(997);
  }
+ if(badhostname((char *)buf)) {RETURN(21);}
  if(param->hostname)free(param->hostname);
  param->hostname = (unsigned char *)strdup((char *)buf);
  if(!param->hostname){RETURN(21);}
@@ -159,6 +163,7 @@
 		param->service = S_SOCKS45;
 		if(sockgetlinebuf(param, CLIENT, buf, BUFSIZE - 1, 0, conf.timeouts[STRING_S]) < 0) {RETURN(441);}
 		buf[127] = 0;
+		if(badhostname((char *)buf)) {RETURN(21);}
 		if(param->hostname)free(param->hostname);
 		param->hostname = (unsigned char *)strdup((char *)buf);
 		if(!param->hostname){RETURN(21);}
