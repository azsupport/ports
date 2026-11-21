--- ZendAccelerator.c.orig	2026-11-21 07:20:00 UTC
+++ ZendAccelerator.c
@@ -1035,6 +1035,18 @@
 				php_stream *stream = (php_stream *)file_handle->handle.stream.handle;
 				php_stream_statbuf sb;
 				int ret, er;
+
+				/* a zend_stream with no php_stream in it (the ionCube Loader gives
+				 * the file one of its own, phar one over its archive): the time of
+				 * the file by its path, as for a file name */
+				if (file_handle->handle.stream.reader != (zend_stream_reader_t)_php_stream_read) {
+					zend_string *path = file_handle->opened_path ? file_handle->opened_path : file_handle->filename;
+
+					if (!path || zend_get_stream_timestamp(ZSTR_VAL(path), &statbuf) != SUCCESS) {
+						return 0;
+					}
+					break;
+				}
 
 				if (!stream ||
 				    !stream->ops ||
