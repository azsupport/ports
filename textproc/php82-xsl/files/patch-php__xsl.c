--- php_xsl.c.orig	2026-11-09 05:59:59 UTC
+++ php_xsl.c
@@ -208,7 +208,6 @@ PHP_MSHUTDOWN_FUNCTION(xsl)
 	xsltUnregisterExtModuleFunction ((const xmlChar *) "function",
 				   (const xmlChar *) "http://php.net/xsl");
 	xsltSetGenericErrorFunc(NULL, NULL);
-	xsltCleanupGlobals();
 
 	return SUCCESS;
 }
