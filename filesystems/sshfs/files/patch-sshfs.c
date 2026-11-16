Two fixes of sshfs after 3.7.7, from master of libfuse/sshfs (aZ, 16.11.2026: «так
сделай»; not in a release yet):
- 8bec61fa94e5 (#407), reject malformed bracketed mount sources: a bracketed IPv6
  source without a colon after its closing bracket made find_base_path() go past the
  end of the source; the base path out of bounds could disclose heap contents to the
  remote server;
- ed3c55569d90 (#408), reject oversized readlink targets: with contain_symlinks a
  target longer than the FUSE buffer was cut after the containment check, so a target
  ending in "..x" past the boundary came out as "..".

--- sshfs.c.orig
+++ sshfs.c
@@ -2294,19 +2294,22 @@
 		err = -EIO;
 		if(buf_get_uint32(&name, &count) != -1 && count == 1 &&
 		   buf_get_string(&name, &link) != -1) {
+			size_t linklen;
+
 			if (sshfs.transform_symlinks)
 				transform_symlink(path, &link);
+			linklen = strlen(link);
 			if (sshfs.contain_symlinks &&
 			    !symlink_target_is_contained(link)) {
-				free(link);
-				buf_free(&name);
-				buf_free(&buf);
-				return -EPERM;
+				err = -EPERM;
+			/* Truncation can change a component such as "..x" to "..". */
+			} else if (linklen >= size) {
+				err = -ENAMETOOLONG;
+			} else {
+				memcpy(linkbuf, link, linklen + 1);
+				err = 0;
 			}
-			strncpy(linkbuf, link, size - 1);
-			linkbuf[size - 1] = '\0';
 			free(link);
-			err = 0;
 		}
 		buf_free(&name);
 	}
@@ -4215,6 +4218,10 @@
 				}
 				*d++ = *s;
 			}
+			if (s[1] != ':') {
+				fprintf(stderr, "missing ':' after hostname\n");
+				exit(1);
+			}
 		} else {
 			*d++ = *s;
 		}
