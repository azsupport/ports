libfuse #571 (Andrew Gaul, 14.12.2020; as Fedora carries it on 2.9.9,
fuse2-0006-Correct-errno-comparison-571.patch; aZ, 16.11.2026): the poll() of
fuse_session_loop_remember() (-o remember) compared errno with -EINTR, so a signal
ended the loop of the file system in the place of polling again.

--- lib/fuse.c.orig
+++ lib/fuse.c
@@ -4350,7 +4350,7 @@
 
 		res = poll(&fds, 1, timeout * 1000);
 		if (res == -1) {
-			if (errno == -EINTR)
+			if (errno == EINTR)
 				continue;
 			else
 				break;
