azsupport/ports: the confinement check of @hapi/inert 7.1.1 (GHSA-rcvq-m9j9-6f4g:
a sibling directory with the same prefix was taken as inside the confined one).
--- node_modules/@hapi/inert/lib/file.js.orig	2026-11-12 12:00:00 UTC
+++ node_modules/@hapi/inert/lib/file.js
@@ -70,8 +70,13 @@
         const confineDir = Path.resolve(request.route.settings.files.relativeTo, options.confine);
         path = Path.isAbsolute(path) ? Path.normalize(path) : Path.join(confineDir, path);
 
-        // Verify that resolved path is within confineDir
-        if (path.lastIndexOf(confineDir, 0) !== 0) {
+        // Verify that the resolved path is the confine dir itself or a path
+        // inside it. Comparing against `confineDir + Path.sep` prevents a sibling
+        // directory with the same string prefix (e.g. confineDir + '-secret')
+        // from being treated as confined.
+        if (path !== confineDir &&
+            !path.startsWith(confineDir + Path.sep)) {
+
             path = null;
         }
     }
