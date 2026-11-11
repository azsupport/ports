tlspr read the length of the extensions of a ServerHello past its end when the
hello was too short for it. From the 0.9 branch of upstream after 0.9.9.3 (#1286):
https://github.com/3proxy/3proxy/commit/5aa3886eb8b62ae778cc8147df9bbb1e65504203

--- src/tlspr.c.orig	2026-11-07 09:14:32 UTC
+++ src/tlspr.c
@@ -224,6 +224,7 @@
     else if(type == 2){
 	offset += 3;
     }
+    if((offset + 2) > len) return -6;
     elen = size16(hello+offset);
     offset += 2;
     if(elen+offset != len) return -9;
