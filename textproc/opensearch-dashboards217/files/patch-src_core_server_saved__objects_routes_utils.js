--- src/core/server/saved_objects/routes/utils.js.orig	2026-11-12 12:00:00 UTC
+++ src/core/server/saved_objects/routes/utils.js
@@ -7,6 +7,7 @@
 exports.validateObjects = validateObjects;
 exports.validateTypes = validateTypes;
 var _streams = require("../../utils/streams");
+var _validate_object = require("../../http/prototype_pollution/validate_object");
 /*
  * SPDX-License-Identifier: Apache-2.0
  *
@@ -40,7 +41,15 @@
 async function createSavedObjectsStreamFromNdJson(ndJsonStream) {
   const savedObjects = await (0, _streams.createPromiseFromStreams)([ndJsonStream, (0, _streams.createSplitStream)('\n'), (0, _streams.createMapStream)(str => {
     if (str && str.trim() !== '') {
-      return JSON.parse(str);
+      // azsupport/ports: OpenSearch-Dashboards e4d78b4 (#12085, 2.19.6): no __proto__
+      // or constructor.prototype keys in an imported object (400)
+      const parsed = JSON.parse(str);
+      try {
+        (0, _validate_object.validateObject)(parsed);
+      } catch (e) {
+        throw new Error(`Invalid object in import stream: ${e instanceof Error ? e.message : String(e)}`);
+      }
+      return parsed;
     }
   }), (0, _streams.createFilterStream)(obj => !!obj && !obj.exportedCount), (0, _streams.createConcatStream)([])]);
   return (0, _streams.createListStream)(savedObjects);
