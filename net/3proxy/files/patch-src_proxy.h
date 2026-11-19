The declaration of badhostname() (src/common.c). From the 0.9 branch of upstream
after 0.9.9.3 (18.11.2026):
https://github.com/3proxy/3proxy/commit/4f4862e

--- src/proxy.h.orig	2026-11-07 09:14:32 UTC
+++ src/proxy.h
@@ -335,6 +335,7 @@
 int hashresolv(struct hashtable *ht, void* name, void* value, uint32_t *ttl);
 
 int parsehost(int family, unsigned char *host, struct sockaddr *sa);
+int badhostname(const char *hostname);
 int parsehostname(char *hostname, struct clientparam *param, uint16_t port);
 int parseusername(char *username, struct clientparam *param, int extpasswd);
 int parseconnusername(char *username, struct clientparam *param, int extpasswd, uint16_t port);
