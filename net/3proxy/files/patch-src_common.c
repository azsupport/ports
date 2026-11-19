Two fixes of the 0.9 branch of upstream after 0.9.9.3 (18.11.2026): a host name
with a control byte or a space refused where it is read (badhostname(), for the
request lines of parent proxies and the rules), and a login name of a port alone
names no destination (parsehostname()):
https://github.com/3proxy/3proxy/commit/4f4862e
https://github.com/3proxy/3proxy/commit/f105a27

--- src/common.c.orig	2026-11-07 09:14:32 UTC
+++ src/common.c
@@ -569,11 +569,26 @@
 	return ret;
 }
 
+/* A host name is written into the request lines of parent protocols and
+   matched against rules, so a control byte or a space in it could end a
+   line early or pose as another destination. A name carrying one is
+   refused where it is read, and every name a client sends is read on
+   its way to the field. */
+int badhostname(const char *hostname){
+	const unsigned char *c;
+
+	if(!hostname) return 1;
+	for(c = (const unsigned char *)hostname; *c; c++)
+		if(*c <= ' ' || *c == 0x7f) return 1;
+	return 0;
+}
+
 int parsehostname(char *hostname, struct clientparam *param, uint16_t port){
 	char *sp=NULL,*se=NULL;
 	int ret = 0;
 
 	if(!hostname || !*hostname)return 2;
+	if(badhostname(hostname)) return 1;
 	if(*hostname == '[') se=strchr(hostname, ']');
 	if ((sp = strchr(se?se:hostname, ':'))) {
 		if(strchr(sp+1, ':'))sp = NULL;
@@ -587,6 +602,9 @@
 			port = atoi(sp+1);
 			*sp = ':';
 		}
+		/* A port alone overrides the port of a host already set; without
+		   one it names no destination to connect to. */
+		if(!param->hostname || !*param->hostname) return 1;
 		*SAPORT(&param->req) = htons(port);
 		return 0;
 	}
