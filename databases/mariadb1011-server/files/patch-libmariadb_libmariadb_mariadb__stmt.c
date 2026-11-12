CONC-821, the regression of MariaDB Connector/C in MariaDB 10.11.19:
mysql_stmt_bind_result() set *length of each string and BLOB column to 0, so the
programs that bind the buffers again after a fetch and before they copy the data
(Perl DBD::MariaDB, Python, Qt) got strings of length 0. The length of the
variable-length types is left as it is again. PHP is not affected (mysqlnd, not
libmariadb). The fix of Connector/C 3.4, upstream ead038d
(https://github.com/mariadb-corporation/mariadb-connector-c/commit/ead038dc8a2b3d7819f87af33e14f105325f8cf9),
its part in mariadb_stmt.c (not the unit test), as Debian carries it on 10.11.19
(bookworm-security 1:10.11.19-0+deb12u1,
debian/patches/CONC-821-Avoid-resetting-length-pointer-for-variable-leng.patch; sid
11.8.9+ds-4), on the libmariadb that 10.11.19 bundles (35c41cd). MariaDB drops it
with the next release; the client (databases/mariadb1011-client) is built from this
port, so libmariadb.so.3 of both has it.

--- libmariadb/libmariadb/mariadb_stmt.c.orig
+++ libmariadb/libmariadb/mariadb_stmt.c
@@ -1491,11 +1491,11 @@
                buffer_type == MYSQL_TYPE_DATE ||
                buffer_type == MYSQL_TYPE_DATETIME) {
       *stmt->bind[i].length= stmt->bind[i].length_value= sizeof(MYSQL_TIME);
-    } else
-    /* string, blob, .... */
-    {
-      *stmt->bind[i].length= stmt->bind[i].length_value= 0;
-    }
+    };
+
+    /* CONC-821: We don't initialize length for variable length types to avoid
+                 problems with applications which rebind before storing/copying retrieved
+                 values from bind buffer */
   }
 
   stmt->bind_result_done= 1;
