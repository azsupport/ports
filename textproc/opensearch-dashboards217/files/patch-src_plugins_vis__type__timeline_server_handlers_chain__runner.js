--- src/plugins/vis_type_timeline/server/handlers/chain_runner.js.orig	2026-11-13 12:00:00 UTC
+++ src/plugins/vis_type_timeline/server/handlers/chain_runner.js
@@ -123,8 +123,17 @@
     } else if (!result) {
       promise = invoke('first', [link]);
     } else {
-      const args = link.arguments ? result.concat(link.arguments) : result;
-      promise = invoke(link.function, args);
+      // azsupport/ports: OpenSearch-Dashboards 1a09720a (#12217, 3.x): a datasource
+      // function (.es(), .graphite() ...) chained after another one starts a series of
+      // its own, as at the start of a chain, and is not given the series before it
+      // (a DoS of chained datasource functions)
+      const functionDef = tlConfig.getFunction(link.function);
+      if (functionDef.datasource) {
+        promise = invoke('first', [link]);
+      } else {
+        const args = link.arguments ? result.concat(link.arguments) : result;
+        promise = invoke(link.function, args);
+      }
     }
     return promise.then(function (result) {
       return invokeChain({
