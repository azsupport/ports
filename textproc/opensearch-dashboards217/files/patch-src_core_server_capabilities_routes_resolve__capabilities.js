--- src/core/server/capabilities/routes/resolve_capabilities.js.orig	2026-11-12 12:00:00 UTC
+++ src/core/server/capabilities/routes/resolve_capabilities.js
@@ -35,6 +35,9 @@
  * under the License.
  */
 
+// azsupport/ports: OpenSearch-Dashboards cf92fa6d (#12292, 3.8.0; CVE-2026-75897)
+const MAX_APPLICATIONS = 1000;
+const MAX_APPLICATION_ID_LENGTH = 256;
 function registerCapabilitiesRoutes(router, resolver) {
   router.post({
     path: '/api/core/capabilities',
@@ -43,7 +46,11 @@
     },
     validate: {
       body: _configSchema.schema.object({
-        applications: _configSchema.schema.arrayOf(_configSchema.schema.string())
+        applications: _configSchema.schema.arrayOf(_configSchema.schema.string({
+          maxLength: MAX_APPLICATION_ID_LENGTH
+        }), {
+          maxSize: MAX_APPLICATIONS
+        })
       })
     }
   }, async (ctx, req, res) => {
