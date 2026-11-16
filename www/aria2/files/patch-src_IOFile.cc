IOFile::getLine() read buf[len - 1] of a line that begins with a NUL byte (len 0):
a read before the buffer on the stack (stack-buffer-underflow). From openSUSE
(aria2-Fix-stack-buffer-underflow-in-IOFile-getLine.patch, cc516929944 of Zhai
Liangliang, 07.08.2026; not in aria2 yet; aZ, 16.11.2026).

--- src/IOFile.cc.orig
+++ src/IOFile.cc
@@ -87,7 +87,7 @@
   while (gets(buf.data(), buf.size())) {
     size_t len = strlen(buf.data());
     bool lineBreak = false;
-    if (buf[len - 1] == '\n') {
+    if (len > 0 && buf[len - 1] == '\n') {
       --len;
       lineBreak = true;
     }
