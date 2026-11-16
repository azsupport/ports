FreeBSD has no alloca.h: alloca(3) is in stdlib.h (the patch of the official port
devel/gearmand, 8c48389f5dc9).

--- libgearman-server/log.cc.orig
+++ libgearman-server/log.cc
@@ -56,6 +56,8 @@
 
 #ifdef _WIN32
 # include <malloc.h>
+#elif defined(__FreeBSD__)
+# include <stdlib.h>
 #else
 # include <alloca.h>
 #endif
