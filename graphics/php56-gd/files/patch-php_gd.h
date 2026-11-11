imageantialias() with the libgd of az too (files/patch-gd.c).

--- php_gd.h.orig
+++ php_gd.h
@@ -123,9 +123,7 @@
 
 PHP_FUNCTION(imageflip);
 
-#ifdef HAVE_GD_BUNDLED
 PHP_FUNCTION(imageantialias);
-#endif
 
 PHP_FUNCTION(imagecrop);
 PHP_FUNCTION(imagecropauto);
