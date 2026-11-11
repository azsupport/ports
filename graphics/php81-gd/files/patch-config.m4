XPM only with --with-xpm: libgd has gdImageCreateFromXpm also when it is built
without libXpm (it fails then; 8.2 and later check that it works), and the libgd
of az has no XPM (aZ 11.11.2026): no imagecreatefromxpm() that cannot work, and
gd_info() does not claim XPM support.

--- config.m4.orig
+++ config.m4
@@ -143,7 +143,9 @@
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromAvif,         [AC_DEFINE(HAVE_GD_AVIF,              1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromWebp,         [AC_DEFINE(HAVE_GD_WEBP,              1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromJpeg,         [AC_DEFINE(HAVE_GD_JPG,               1, [ ])], [], [ $GD_SHARED_LIBADD ])
-  PHP_CHECK_LIBRARY(gd, gdImageCreateFromXpm,          [AC_DEFINE(HAVE_GD_XPM,               1, [ ])], [], [ $GD_SHARED_LIBADD ])
+  if test "$PHP_XPM" != "no"; then
+    PHP_CHECK_LIBRARY(gd, gdImageCreateFromXpm,        [AC_DEFINE(HAVE_GD_XPM,               1, [ ])], [], [ $GD_SHARED_LIBADD ])
+  fi
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromBmp,          [AC_DEFINE(HAVE_GD_BMP,               1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromTga,          [AC_DEFINE(HAVE_GD_TGA,               1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdImageStringFT,               [AC_DEFINE(HAVE_GD_FREETYPE,          1, [ ])], [], [ $GD_SHARED_LIBADD ])
