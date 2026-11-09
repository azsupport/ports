GNU readline of az, as php74-readline. phpize makes every option of config.m4
yes (PHP_ALWAYS_SHARED of scripts/phpize.m4: no becomes yes), so --with-libedit
won and --with-readline was never asked for (configure: Package requirements
(libedit) were not met; build.yml 42526293332): --with-readline is asked for
whatever libedit says, as in the patch of php74-readline. ext/readline/config.m4
of 8.2 checks rl_completion_matches itself.

--- config.m4.orig
+++ config.m4
@@ -3,16 +3,10 @@
   [AS_HELP_STRING([--with-libedit],
     [Include libedit readline replacement (CLI/CGI only)])])
 
-if test "$PHP_LIBEDIT" = "no"; then
   PHP_ARG_WITH([readline],
     [for readline support],
     [AS_HELP_STRING([[--with-readline[=DIR]]],
       [Include readline support (CLI/CGI only)])])
-else
-  dnl "register" the --with-readline option to prevent invalid "unknown
-  dnl configure option" warning
-  php_with_readline=no
-fi
 
 if test "$PHP_READLINE" && test "$PHP_READLINE" != "no"; then
   for i in $PHP_READLINE /usr/local /usr; do
