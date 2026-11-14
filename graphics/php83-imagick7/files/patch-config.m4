The tarball of azsupport/php-src bundles imagick in ext/imagick and includes its
imagemagick.m4 from the top of the tree; the port runs phpize in ext/imagick, where
that path is not there (gm4: cannot open ext/imagick/imagemagick.m4, build.yml
42519391339): the file next to config.m4, as the PECL release has it.

--- config.m4.orig
+++ config.m4
@@ -11,8 +11,8 @@
   define('PHP_IMAGICK_STATIC', 1)
   PHP_IMAGICK_STATIC=yes
 fi
-dnl inside php-src (bundled by azsupport/php-src), relative to the top of the tree
-m4_include([ext/imagick/imagemagick.m4])
+dnl phpize in ext/imagick (the port): next to config.m4, as in the PECL release
+m4_include([imagemagick.m4])
 
 # This line checks that ImageMagick is available, and
 # meets our minimum supported version. TODO change to 6.7.0
