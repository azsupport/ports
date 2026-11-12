--- src/core/server/capabilities/resolve_capabilities.js.orig	2026-11-12 12:00:00 UTC
+++ src/core/server/capabilities/resolve_capabilities.js
@@ -39,34 +39,36 @@
   return resolveCapabilities(capabilities(), switchers(), request, applications);
 };
 exports.getCapabilitiesResolver = getCapabilitiesResolver;
+// azsupport/ports: OpenSearch-Dashboards cf92fa6d (#12292, 3.8.0; CVE-2026-75897): one
+// linear pass each, where reduce() with spreads was quadratic in the applications of
+// POST /api/core/capabilities (no authentication) and blocked the event loop
 const resolveCapabilities = async (capabilities, switchers, request, applications) => {
-  const mergedCaps = (0, _lodash.cloneDeep)({
-    ...capabilities,
-    navLinks: applications.reduce((acc, app) => ({
-      ...acc,
-      [app]: true
-    }), capabilities.navLinks)
-  });
-  return switchers.reduce(async (caps, switcher) => {
-    const resolvedCaps = await caps;
-    const changes = await switcher(request, resolvedCaps);
-    return recursiveApplyChanges(resolvedCaps, changes);
-  }, Promise.resolve(mergedCaps));
+  const mergedCaps = (0, _lodash.cloneDeep)(capabilities);
+  for (const app of applications) {
+    mergedCaps.navLinks[app] = true;
+  }
+  let resolved = mergedCaps;
+  for (const switcher of switchers) {
+    const changes = await switcher(request, resolved);
+    resolved = recursiveApplyChanges(resolved, changes);
+  }
+  return resolved;
 };
 exports.resolveCapabilities = resolveCapabilities;
 function recursiveApplyChanges(destination, source) {
-  return Object.keys(destination).map(key => {
+  const result = {};
+  for (const key of Object.keys(destination)) {
     const orig = destination[key];
     const changed = source[key];
     if (changed == null) {
-      return [key, orig];
+      result[key] = orig;
+      continue;
     }
     if (typeof orig === 'object' && typeof changed === 'object') {
-      return [key, recursiveApplyChanges(orig, changed)];
+      result[key] = recursiveApplyChanges(orig, changed);
+      continue;
     }
-    return [key, typeof orig === typeof changed ? changed : orig];
-  }).reduce((acc, [key, value]) => ({
-    ...acc,
-    [key]: value
-  }), {});
+    result[key] = typeof orig === typeof changed ? changed : orig;
+  }
+  return result;
 }
\ No newline at end of file
