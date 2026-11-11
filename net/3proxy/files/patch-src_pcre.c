A pcre rule without an ACL was given to the filters as the match data of the
connection, which they freed: a pointer into the configuration given to free().
From the 0.9 branch of upstream after 0.9.9.3:
https://github.com/3proxy/3proxy/commit/15012177aa4537c641f5b0a07ef6c757b2265e26

--- src/pcre.c.orig	2026-11-07 09:14:32 UTC
+++ src/pcre.c
@@ -264,13 +264,14 @@
 	struct pcre_filter_data *rule = (struct pcre_filter_data *)fo;
 	struct pcre_client_data *pcd;
 
-	*fc = fo;
+	*fc = NULL;
 	if(!fo) return PASS;
-	if(!rule->acl) return CONTINUE;
-	memset (&tmpace, 0, sizeof(struct ace));
-	tmpace.src = rule->acl->src;
-	res = pl->ACLMatches(&tmpace, param);
-	if(!res) return PASS;
+	if(rule->acl){
+		memset (&tmpace, 0, sizeof(struct ace));
+		tmpace.src = rule->acl->src;
+		res = pl->ACLMatches(&tmpace, param);
+		if(!res) return PASS;
+	}
 	/* the connection goes on with a match data of its own */
 	if(!(pcd = pl->mallocfunc(sizeof(struct pcre_client_data)))){
 		*fc = NULL;
