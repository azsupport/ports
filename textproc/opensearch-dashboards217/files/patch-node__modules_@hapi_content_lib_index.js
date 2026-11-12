azsupport/ports: the parser of @hapi/content 6.0.3 (hapijs/content v6.0.3, 06f8c9f8) on
its 5.0.2, with the @hapi/boom 9 of the bundle (the tests of 6.0.3 pass with it):
GHSA-36hh-x5p5-jgc8 (parameter smuggling), GHSA-8494-f6mr-cjpv (quadratic
Content-Disposition), GHSA-jg4p-7fhp-p32p (ReDoS of the headers).
--- node_modules/@hapi/content/lib/index.js.orig	2026-11-12 12:00:00 UTC
+++ node_modules/@hapi/content/lib/index.js
@@ -15,11 +15,14 @@
     parameter  = token "=" ( token / quoted-string )
 */
 
-//                             1: type/subtype    2: params
-internals.contentTypeRegex = /^([^\/\s]+\/[^\s;]+)(.*)?$/;
+//                             1: type/subtype                                           2: params
+internals.contentTypeRegex = /^([A-Za-z0-9!#$%&'*+.^_`|~-]+\/[A-Za-z0-9!#$%&'*+.^_`|~-]+)([ \t;][^\r\n]*)?$/;
 
-//                                        1: "b"   2: b
-internals.paramsRegex = /;\s*boundary=(?:"([^"]+)"|([^;"\s]+))/i;
+//                                             1: "b"   2: b
+internals.charsetParamRegex = /;\s*charset=(?:"([^"]+)"|([^;"\s]+))/i;
+
+//                                               1: "b"   2: b
+internals.boundaryParamRegex = /;\s*boundary=(?:"([^"]+)"|([^;"\s]+))/i;
 
 
 exports.type = function (header) {
@@ -37,12 +40,27 @@
         mime: match[1].toLowerCase()
     };
 
+    const params = match[2];
+    if (params) {
+        const param = params.match(internals.charsetParamRegex);
+        if (param) {
+            result.charset = (param[1] || param[2]).toLowerCase();
+
+            if (internals.charsetParamRegex.test(params.slice(param.index + param[0].length))) {
+                throw Boom.badRequest('Invalid content-type header: duplicate parameter');
+            }
+        }
+    }
+
     if (result.mime.indexOf('multipart/') === 0) {
-        const params = match[2];
         if (params) {
-            const param = params.match(internals.paramsRegex);
+            const param = params.match(internals.boundaryParamRegex);
             if (param) {
                 result.boundary = param[1] || param[2];
+
+                if (internals.boundaryParamRegex.test(params.slice(param.index + param[0].length))) {
+                    throw Boom.badRequest('Invalid content-type header: duplicate parameter');
+                }
             }
         }
 
@@ -72,10 +90,13 @@
 */
 
 
-internals.contentDispositionRegex = /^\s*form-data\s*(?:;\s*(.+))?$/i;
+internals.contentDispositionRegex = /^\s*form-data\s*(?:;\s*(\S.*))?$/i;
+
+// The trailing alternative consumes a name that isn't followed by "=", otherwise the global scan retries from every
+// character of it and backtracks quadratically, any later start in the same run would fail the same way anyway.
 
-//                                        1: name     2: *            3: ext-value                      4: quoted  5: token
-internals.contentDispositionParamRegex = /([^\=\*\s]+)(\*)?\s*\=\s*(?:([^;'"\s]+\'[\w-]*\'[^;\s]+)|(?:\"([^"]*)\")|([^;\s]*))(?:\s*(?:;\s*)|$)/g;
+//                                        1: name     2: *            3: ext-value                      4: quoted  5: token     skipped
+internals.contentDispositionParamRegex = /([^\=\*\s]+)(\*)?\s*\=\s*(?:([^;'"\s]+\'[\w-]*\'[^;\s]+)|(?:\"([^"]*)\")|([^;\s]*))|[^\=\*\s]+/g;
 
 exports.disposition = function (header) {
 
@@ -94,12 +115,34 @@
     }
 
     const result = {};
+    const extKeys = new Set();
     parameters.replace(internals.contentDispositionParamRegex, ($0, $1, $2, $3, $4, $5) => {
 
+        if ($1 === undefined) {
+            return;
+        }
+
         if ($1 === '__proto__') {
             throw Boom.badRequest('Invalid content-disposition header format includes invalid parameters');
         }
 
+        if (result[$1] !== undefined) {
+            if ($2 && !extKeys.has($1)) {
+                // ext-value overriding regular value - allowed per RFC 6266 Section 4.3
+            }
+            else if (!$2 && extKeys.has($1)) {
+                // Regular value after ext-value - ignore (keep ext-value)
+                return;
+            }
+            else {
+                throw Boom.badRequest('Invalid content-disposition header format includes invalid parameters');
+            }
+        }
+
+        if ($2) {
+            extKeys.add($1);
+        }
+
         let value;
 
         if ($2) {
@@ -108,7 +151,7 @@
             }
 
             try {
-                value = decodeURIComponent($3.split('\'')[2]);
+                value = decodeURIComponent($3.slice($3.indexOf('\'', $3.indexOf('\'') + 1) + 1));
             }
             catch (err) {
                 throw Boom.badRequest('Invalid content-disposition header format includes invalid parameters');
