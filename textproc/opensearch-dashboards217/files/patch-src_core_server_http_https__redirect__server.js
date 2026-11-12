--- src/core/server/http/https_redirect_server.js.orig	2026-11-12 12:00:00 UTC
+++ src/core/server/http/https_redirect_server.js
@@ -56,6 +56,11 @@
       port: config.ssl.redirectHttpFromPort
     }, (0, _http_tools.getListenerOptions)(config));
     this.server.ext('onRequest', (request, responseToolkit) => {
+      // azsupport/ports: OpenSearch-Dashboards 05be93b (#12193, 2.19.6): reject
+      // protocol-relative paths (//attacker.com/...)
+      if (request.url.pathname.startsWith('//')) {
+        return responseToolkit.response('Not Found').code(404).takeover();
+      }
       return responseToolkit.redirect((0, _url.format)({
         hostname: config.host,
         pathname: request.url.pathname,
