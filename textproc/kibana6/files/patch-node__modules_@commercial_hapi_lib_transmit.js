--- node_modules/@commercial/hapi/lib/transmit.js.orig	2026-11-11 12:00:00 UTC
+++ node_modules/@commercial/hapi/lib/transmit.js
@@ -240,12 +240,19 @@
 
     const env = { stream, request, team };
 
+    if (request._closed) {
+        // No more events will be fired, so we proactively close-up shop
+        request.raw.res.end(); // Ensure res is finished so internals.end() doesn't think we're responding
+        internals.end(env, 'close');
+        return team.work;
+    }
+
     const aborted = internals.end.bind(null, env, 'aborted');
     const close = internals.end.bind(null, env, 'close');
     const end = internals.end.bind(null, env, null);
 
     request.raw.req.on('aborted', aborted);
-    request.raw.req.on('close', close);
+
     request.raw.res.on('close', close);
     request.raw.res.on('error', end);
     request.raw.res.on('finish', end);
@@ -271,6 +278,13 @@
 
     env.team = null;
 
+    if (event === 'close' &&
+        request.raw.res.finished) {
+
+        team.attend();
+        return;
+    }
+
     if (err) {
         request.raw.res.destroy();
 
