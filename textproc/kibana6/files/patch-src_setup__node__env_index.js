--- src/setup_node_env/index.js.orig	2026-11-11 12:00:00 UTC
+++ src/setup_node_env/index.js
@@ -19,5 +19,6 @@
  * under the License.
  */

-require('./node_version_validator');
-require('./babel_register');
\ No newline at end of file
+// azsupport/ports: on the Node.js 24 of the ports, not the Node.js 10.24.1 it checks for
+require('./node_compat');
+require('./babel_register');
