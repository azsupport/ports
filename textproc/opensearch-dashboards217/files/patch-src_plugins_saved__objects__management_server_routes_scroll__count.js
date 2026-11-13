--- src/plugins/saved_objects_management/server/routes/scroll_count.js.orig	2026-11-13 12:00:00 UTC
+++ src/plugins/saved_objects_management/server/routes/scroll_count.js
@@ -36,16 +36,27 @@
  * under the License.
  */
 
+// azsupport/ports: OpenSearch-Dashboards 23a4a157 (#12191, 3.x): at most 100 entries in
+// each array, where a request of less than 1 MiB with 40000 of them ran the heap of
+// the process out (no authentication without the security plugin)
 const registerScrollForCountRoute = router => {
   router.post({
     path: '/api/opensearch-dashboards/management/saved_objects/scroll/counts',
     validate: {
       body: _configSchema.schema.object({
-        typesToInclude: _configSchema.schema.arrayOf(_configSchema.schema.string()),
-        namespacesToInclude: _configSchema.schema.maybe(_configSchema.schema.arrayOf(_configSchema.schema.string())),
+        typesToInclude: _configSchema.schema.arrayOf(_configSchema.schema.string(), {
+          maxSize: 100
+        }),
+        namespacesToInclude: _configSchema.schema.maybe(_configSchema.schema.arrayOf(_configSchema.schema.string(), {
+          maxSize: 100
+        })),
         searchString: _configSchema.schema.maybe(_configSchema.schema.string()),
-        workspaces: _configSchema.schema.maybe(_configSchema.schema.arrayOf(_configSchema.schema.string())),
-        availableWorkspaces: _configSchema.schema.maybe(_configSchema.schema.arrayOf(_configSchema.schema.string()))
+        workspaces: _configSchema.schema.maybe(_configSchema.schema.arrayOf(_configSchema.schema.string(), {
+          maxSize: 100
+        })),
+        availableWorkspaces: _configSchema.schema.maybe(_configSchema.schema.arrayOf(_configSchema.schema.string(), {
+          maxSize: 100
+        }))
       })
     }
   }, router.handleLegacyErrors(async (context, req, res) => {
