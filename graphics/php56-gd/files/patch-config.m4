T1LIB: libt1 needs libm. XPM: with the libgd of az (--with-gd=DIR) only with
--with-xpm-dir (the option X11): libgd has gdImageCreateFromXpm even without libXpm
(it fails), and HAVE_GD_XPM makes gd.c include X11/xpm.h and call XpmLibraryVersion().

--- config.m4.orig
+++ config.m4
@@ -236,7 +236,7 @@
     ],[
       AC_MSG_ERROR([Problem with libt1.(a|so). Please check config.log for more information.])
     ],[
-      -L$GD_T1_DIR/$PHP_LIBDIR
+      -L$GD_T1_DIR/$PHP_LIBDIR -lm
     ])
   fi
 ])
@@ -257,7 +257,9 @@
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromPng,   [AC_DEFINE(HAVE_GD_PNG,              1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromWebp,  [AC_DEFINE(HAVE_GD_WEBP,             1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromJpeg,  [AC_DEFINE(HAVE_GD_JPG,              1, [ ])], [], [ $GD_SHARED_LIBADD ])
+  if test "$PHP_XPM_DIR" != "no"; then
   PHP_CHECK_LIBRARY(gd, gdImageCreateFromXpm,   [AC_DEFINE(HAVE_GD_XPM,              1, [ ])], [], [ $GD_SHARED_LIBADD ])
+  fi
   PHP_CHECK_LIBRARY(gd, gdImageStringFT,        [AC_DEFINE(HAVE_GD_FREETYPE,         1, [ ])], [], [ $GD_SHARED_LIBADD ])
   PHP_CHECK_LIBRARY(gd, gdVersionString,        [AC_DEFINE(HAVE_GD_LIBVERSION,       1, [ ])], [], [ $GD_SHARED_LIBADD ])
 ])
