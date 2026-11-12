--- src/java.desktop/unix/native/common/awt/utility/rect.h.orig	2026-10-27 21:45:31 UTC
+++ src/java.desktop/unix/native/common/awt/utility/rect.h
@@ -28,7 +28,7 @@
 #ifndef _AWT_RECT_H
 #define _AWT_RECT_H
 
-#ifndef MACOSX
+#if !defined(HEADLESS) && !defined(MACOSX)
 #include <X11/Xlib.h>
 typedef XRectangle RECT_T;
 #else
@@ -39,7 +39,7 @@
     int width;
     int height;
 } RECT_T;
-#endif /* !MACOSX */
+#endif /* !HEADLESS && !MACOSX */
 
 #define RECT_EQ_X(r1,r2)        ((r1).x==(r2).x && (r1).width==(r2).width)
 
