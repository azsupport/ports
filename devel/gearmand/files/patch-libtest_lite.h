FreeBSD has no alloca.h: alloca(3) is in stdlib.h (the patch of the official port
devel/gearmand, 8c48389f5dc9).

--- libtest/lite.h.orig
+++ libtest/lite.h
@@ -53,6 +53,8 @@
 
 #if defined(WIN32)
 # include <malloc.h>
+#elif defined(__FreeBSD__)
+# include <stdlib.h>
 #else
 # include <alloca.h>
 #endif
