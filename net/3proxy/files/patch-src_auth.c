Users with NT passwords (NT:, of mycrypt without a salt) without TLS too, as in
0.9.5 of the official port: without TLS 0.9.7 and later skip them when reading
the config and do not check them, though the NT hash is the MD4 of src/libs,
built in always (src/mdhash.c).

--- src/auth.c.orig	2026-11-07 09:14:32 UTC
+++ src/auth.c
@@ -271,11 +271,9 @@
 			        !ctstrcmp(pass + 1, (char *)buf, sizeof(pass) - 1))
 				return 0;
 			    else return 7;
-#ifdef WITH_SSL
 			    case NT:
 			    if(ntpwdhash(buf, param->password, 1) && !ctstrcmp(pass + 1, (char *)buf, sizeof(pass) - 1)) return 0;
 			    else return 8;
-#endif
 			    default:
 			    break;
 			}
