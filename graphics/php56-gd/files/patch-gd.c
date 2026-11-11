imageantialias() with the libgd of az (--with-gd=DIR): PHP 5.6 has it only with the
bundled libgd; this is what PHP 7.2 made of it for a system libgd (its UPGRADING:
"imageantialias() is now also available if compiled with a system libgd"): the AA
flag of a true colour image, which imageline() turns into gdAntiAliased.

--- gd.c.orig
+++ gd.c
@@ -835,12 +835,10 @@
 	ZEND_ARG_INFO(0, mode)
 ZEND_END_ARG_INFO()
 
-#ifdef HAVE_GD_BUNDLED
 ZEND_BEGIN_ARG_INFO(arginfo_imageantialias, 0)
 	ZEND_ARG_INFO(0, im)
 	ZEND_ARG_INFO(0, on)
 ZEND_END_ARG_INFO()
-#endif
 
 ZEND_BEGIN_ARG_INFO(arginfo_imagecrop, 0)
 	ZEND_ARG_INFO(0, im)
@@ -933,9 +931,7 @@
 	PHP_FE(imagerotate,     						arginfo_imagerotate)
 	PHP_FE(imageflip,								arginfo_imageflip)
 
-#ifdef HAVE_GD_BUNDLED
 	PHP_FE(imageantialias,							arginfo_imageantialias)
-#endif
 	PHP_FE(imagecrop,								arginfo_imagecrop)
 	PHP_FE(imagecropauto,							arginfo_imagecropauto)
 	PHP_FE(imagescale,								arginfo_imagescale)
@@ -3154,6 +3150,11 @@
 	if (im->antialias) {
 		gdImageAALine(im, x1, y1, x2, y2, col);
 	} else
+#else
+	if (im->AA) {
+		gdImageSetAntiAliased(im, col);
+		gdImageLine(im, x1, y1, x2, y2, gdAntiAliased);
+	} else
 #endif
 	{
 		gdImageLine(im, x1, y1, x2, y2, col);
@@ -5011,7 +5012,6 @@
 }
 /* }}} */
 
-#ifdef HAVE_GD_BUNDLED
 /* {{{ proto bool imageantialias(resource im, bool on)
    Should antialiased functions used or not*/
 PHP_FUNCTION(imageantialias)
@@ -5025,11 +5025,16 @@
 	}
 
 	ZEND_FETCH_RESOURCE(im, gdImagePtr, &IM, -1, "Image", le_gd);
+#ifdef HAVE_GD_BUNDLED
 	gdImageAntialias(im, alias);
+#else
+	if (im->trueColor) {
+		im->AA = alias;
+	}
+#endif
 	RETURN_TRUE;
 }
 /* }}} */
-#endif
 
 /* {{{ proto void imagecrop(resource im, array rect)
    Crop an image using the given coordinates and size, x, y, width and height. */
