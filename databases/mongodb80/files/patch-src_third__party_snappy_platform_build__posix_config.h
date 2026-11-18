--- src/third_party/snappy/platform/build_posix/config.h.orig
+++ src/third_party/snappy/platform/build_posix/config.h
@@ -44,13 +44,25 @@
 #define HAVE_WINDOWS_H 0
 
 /* Define to 1 if you target processors with SSSE3+ and have <tmmintrin.h>. */
+#if defined(__SSSE3__)
 #define SNAPPY_HAVE_SSSE3 1
+#else
+#define SNAPPY_HAVE_SSSE3 0
+#endif
 
 /* Define to 1 if you target processors with SSE4.2 and have <crc32intrin.h>. */
+#if defined(__SSE4_2__)
+#define SNAPPY_HAVE_X86_CRC32 1
+#else
 #define SNAPPY_HAVE_X86_CRC32 0
+#endif
 
 /* Define to 1 if you target processors with BMI2+ and have <bmi2intrin.h>. */
+#if defined(__BMI2__)
+#define SNAPPY_HAVE_BMI2 1
+#else
 #define SNAPPY_HAVE_BMI2 0
+#endif
 
 /* Define to 1 if you target processors with NEON and have <arm_neon.h>. */
 #define SNAPPY_HAVE_NEON 0
