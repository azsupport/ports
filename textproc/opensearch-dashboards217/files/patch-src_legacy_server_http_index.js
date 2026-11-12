--- src/legacy/server/http/index.js.orig	2026-11-12 12:00:00 UTC
+++ src/legacy/server/http/index.js
@@ -51,6 +51,13 @@
       if (path === '/' || path.charAt(path.length - 1) !== '/') {
         throw _boom.default.notFound();
       }
+
+      // azsupport/ports: OpenSearch-Dashboards 05be93b (#12193, 2.19.6): reject
+      // protocol-relative paths (//attacker.com/... or /\attacker.com/...), which the
+      // redirect below would send the browser to
+      if (path.charAt(1) === '/' || path.charAt(1) === '\\') {
+        throw _boom.default.notFound();
+      }
       const pathPrefix = req.getBasePath() ? `${req.getBasePath()}/` : '';
       return h.redirect((0, _url.format)({
         search: req.url.search,
