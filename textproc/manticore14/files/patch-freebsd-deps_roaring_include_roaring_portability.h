CRoaring 4.3.2 (both lines: textproc/manticore32 takes the files/ of this port): on FreeBSD
croaring_htobe64() is bswap64(), which <sys/endian.h> declares, but portability.h includes
<byteswap.h> alone (bswap_64): roaring64.c (which searchd does not link) called bswap64 without
a declaration, an error of clang 23 and of GCC 14 and later (the base clang 19 of FreeBSD 15.1
keeps it a warning; prog-bench runs 45918013549 and 45919701720). The fix of upstream after
4.3.2 (CRoaring abb34b5, "armv7 FreeBSD fixes", #879, 11.09.2026): <sys/endian.h> on FreeBSD.

--- freebsd-deps/roaring/include/roaring/portability.h.orig
+++ freebsd-deps/roaring/include/roaring/portability.h
@@ -429,6 +429,7 @@
 #if defined(__linux__)
 #define croaring_htobe64(x) bswap_64(x)
 #elif defined(__FreeBSD__)
+#include <sys/endian.h>
 #define croaring_htobe64(x) bswap64(x)
 #else
 #warning "Unknown platform, report as an error"
