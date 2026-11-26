- the default JavaScript runtime of the API (YoutubeDL without js_runtimes) is node
  (www/node24, which www/py-yt-dlp-ejs runs with), not deno, as on the command line

--- yt_dlp/YoutubeDL.py.orig	2026-11-23 23:32:54 UTC
+++ yt_dlp/YoutubeDL.py
@@ -544,7 +544,7 @@ class YoutubeDL:
     js_runtimes:       A dictionary of JavaScript runtime keys (in lower case) to enable
                        and a dictionary of additional configuration for the runtime.
                        Currently supported runtimes are 'deno', 'node', 'bun', and 'quickjs'.
-                       If None, the default runtime of "deno" will be enabled.
+                       If None, the default runtime of "node" will be enabled.
                        The runtime configuration dictionary can have the following keys:
                         - path: Path to the executable (optional)
                        E.g. {'deno': {'path': '/path/to/deno'}
@@ -737,7 +737,7 @@ class YoutubeDL:
                     raise
 
         # Note: this must be after plugins are loaded
-        self.params['js_runtimes'] = self.params.get('js_runtimes', {'deno': {}})
+        self.params['js_runtimes'] = self.params.get('js_runtimes', {'node': {}})
         self._clean_js_runtimes(self.params['js_runtimes'])
 
         self.params['remote_components'] = set(self.params.get('remote_components', ()))
