mysqlnd of PHP 5.6 includes this header of its own by its path in the source
tree (ext/mysqlnd/), which a build of the module alone (phpize in ext/mysqlnd)
does not have: the header next to it, as mysqlnd of PHP 7.0 and later includes
it.

--- mysqlnd_ps_codec.c.orig
+++ mysqlnd_ps_codec.c
@@ -24,7 +24,7 @@
 #include "mysqlnd_wireprotocol.h"
 #include "mysqlnd_priv.h"
 #include "mysqlnd_debug.h"
-#include "ext/mysqlnd/mysql_float_to_double.h"
+#include "mysql_float_to_double.h"
 
 #define MYSQLND_SILENT
 
