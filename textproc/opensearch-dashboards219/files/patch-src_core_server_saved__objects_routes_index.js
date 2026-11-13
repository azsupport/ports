--- src/core/server/saved_objects/routes/index.js.orig	2026-11-13 12:00:00 UTC
+++ src/core/server/saved_objects/routes/index.js
@@ -54,6 +54,17 @@
   migratorPromise
 }) {
   const router = http.createRouter('/api/saved_objects/');
+  // azsupport/ports: OpenSearch-Dashboards 50c470c0 (#12189, 3.x): no Content-Encoding
+  // on the import routes, whose body hapi decompresses before the maxBytes of the
+  // multipart parser applies (a gzip of a few MiB took the memory of the process)
+  http.registerOnPreAuth((request, response, toolkit) => {
+    if (request.headers['content-encoding'] && (request.url.pathname === '/api/saved_objects/_import' || request.url.pathname === '/api/saved_objects/_resolve_import_errors')) {
+      return response.badRequest({
+        body: 'Content-Encoding is not supported for this endpoint'
+      });
+    }
+    return toolkit.next();
+  });
   (0, _get.registerGetRoute)(router);
   (0, _create.registerCreateRoute)(router);
   (0, _delete.registerDeleteRoute)(router);
