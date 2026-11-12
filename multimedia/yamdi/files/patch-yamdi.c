Origin (azsupport/ports): Debian yamdi 1.9-1 (sid, trixie), https://sources.debian.org/src/yamdi/1.9-1/debian/patches/1010-strn-buffer-overflow.patch/
 -c <creator> of 256 bytes or more: strncpy() left the field without its final NUL, and
 strlen() then read past it (bytes of what follows went into the file); flv is zeroed by
 initFLV() before the options, so the last byte stays NUL.
Description: Avoid potential buffer overflow in strncpy.
 The strncpy() method do not write a null byte at the end if the buffer is
 to small for the entire string, so ensure there is a null byte present using other means.
 This avoid the following compiler warning:

yamdi.c:320:33: warning: ‘__builtin_strncpy’ specified bound 256 equals destination size [-Wstringop-truncation]
  320 |                                 strncpy(flv.options.creator, optarg, sizeof(flv.options.creator));
      |                                 ^

Author: Petter Reinholdtsen
Author: xiao sheng wen <atzlinux@debian.org>
Forwarded: no-need
Reviewed-by: xiao sheng wen <atzlinux@debian.org>
Last-Update: 2025-04-21
---
diff --git a/yamdi.c b/yamdi.c
index ac9e0e6..665acc2 100644
--- a/yamdi.c
+++ b/yamdi.c
@@ -317,7 +317,7 @@ int main(int argc, char **argv) {
 				tempfile = optarg;
 				break;
 			case 'c':
-				strncpy(flv.options.creator, optarg, sizeof(flv.options.creator));
+				strncpy(flv.options.creator, optarg, sizeof(flv.options.creator)-1);
 				break;
 			case 'l':
 			case 's':
