--- node_modules/@commercial/hapi/lib/request.js.orig	2026-11-11 12:00:00 UTC
+++ node_modules/@commercial/hapi/lib/request.js
@@ -23,6 +23,7 @@
     constructor(server, req, res, options) {
 
         this._allowInternals = !!options.allowInternals;
+        this._closed = false;                                                                               // true once the response has closed (esp. early) and will not emit any more events
         this._core = server._core;
         this._entity = null;                                                                                // Entity information set via h.entity()
         this._eventContext = { request: this };
@@ -197,9 +198,10 @@
             this.raw.req.on('end', internals.event.bind(this.raw.req, this._eventContext, 'end'));
         }
 
-        this.raw.req.on('close', internals.event.bind(this.raw.req, this._eventContext, 'close'));
+        this.raw.res.on('close', internals.event.bind(this.raw.res, this._eventContext, 'close'));
         this.raw.req.on('error', internals.event.bind(this.raw.req, this._eventContext, 'error'));
         this.raw.req.on('aborted', internals.event.bind(this.raw.req, this._eventContext, 'abort'));
+        this.raw.res.once('close', internals.closed.bind(this.raw.res, this));
     }
 
     _lookup() {
@@ -529,6 +531,11 @@
 };
 
 
+internals.closed = function (request) {
+
+    request._closed = true;
+};
+
 internals.event = function ({ request }, event, err) {
 
     if (!request) {
@@ -537,6 +544,12 @@
 
     request._isPayloadPending = false;
 
+    if (event === 'close' &&
+        request.raw.res.finished) {
+
+        return;
+    }
+
     if (event === 'end') {
         return;
     }
