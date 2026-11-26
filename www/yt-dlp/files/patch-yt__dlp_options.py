- the default JavaScript runtime of the command line is node (www/node24, which
  www/py-yt-dlp-ejs runs with), not deno, which the repository azsupport does not have:
  --js-runtimes adds a runtime to it, --no-js-runtimes clears it

--- yt_dlp/options.py.orig	2026-11-23 23:32:54 UTC
+++ yt_dlp/options.py
@@ -464,14 +464,14 @@ def create_parser():
         callback=_list_from_options_callback,
         type='str',
         callback_kwargs={'delim': None},
-        default=['deno'],
+        default=['node'],
         help=(
             'Additional JavaScript runtime to enable, with an optional location for the runtime '
             '(either the path to the binary or its containing directory). '
             'This option can be used multiple times to enable multiple runtimes. '
             'Supported runtimes are (in order of priority, from highest to lowest): deno, node, quickjs, bun. '
-            'Only "deno" is enabled by default. The highest priority runtime that is both enabled and '
-            'available will be used. In order to use a lower priority runtime when "deno" is available, '
+            'Only "node" is enabled by default. The highest priority runtime that is both enabled and '
+            'available will be used. In order to use a lower priority runtime when "node" is available, '
             '--no-js-runtimes needs to be passed before enabling other runtimes'))
     general.add_option(
         '--no-js-runtimes',
