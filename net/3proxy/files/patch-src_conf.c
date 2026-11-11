Users with NT passwords (NT:, of mycrypt without a salt) without TLS too, as in
0.9.5 of the official port: without TLS 0.9.7 and later skip them when reading
the config and do not check them, though the NT hash is the MD4 of src/libs,
built in always (src/mdhash.c).

--- src/conf.c.orig	2026-11-07 09:14:32 UTC
+++ src/conf.c
@@ -542,11 +542,7 @@
         if (arg[1] && arg[2] && arg[3] == ':') {
             pw[1] = (char *)(arg + 4);
             if (arg[1] == 'N' && arg[2] == 'T') {
-#ifdef WITH_SSL
 		*pass = NT;
-#else
-                continue;
-#endif
             }
             else if (arg[1] == 'C' && arg[2] == 'R') {
 		*pass = CR;
