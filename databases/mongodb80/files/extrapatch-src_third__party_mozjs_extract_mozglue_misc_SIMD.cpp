The AVX2 variants of memchr of SpiderMonkey by the x86-64 level of the build, not
by the CPU at run time (aZ, 18.11.2026: «а зачем нам делать автоматический вариант
если у нас и так две сборки будут v2 и v3?»): with -march=x86-64-v3 (__AVX2__)
always, without the check of cpuid; with x86-64-v2 never, SSE2 alone (as the NOAVX
option of the official port, which this patch replaces).

--- src/third_party/mozjs/extract/mozglue/misc/SIMD.cpp.orig	2024-11-07 09:56:02 UTC
+++ src/third_party/mozjs/extract/mozglue/misc/SIMD.cpp
@@ -448,9 +448,9 @@ const char* SIMD::memchr8SSE2(const char* ptr, char va
 // assertion failure. Accordingly, we just don't allow that to happen. We
 // are not particularly concerned about ensuring that newer 32 bit processors
 // get access to the AVX2 functions exposed here.
-#  if defined(MOZILLA_MAY_SUPPORT_AVX2) && defined(__x86_64__)
+#  if defined(MOZILLA_MAY_SUPPORT_AVX2) && defined(__x86_64__) && defined(__AVX2__)
 
-bool SupportsAVX2() { return supports_avx2(); }
+bool SupportsAVX2() { return true; }
 
 #  else
 
