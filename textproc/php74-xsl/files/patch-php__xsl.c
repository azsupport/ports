--- php_xsl.c.orig	2026-11-09 11:56:51 UTC
+++ php_xsl.c
@@ -239,7 +239,6 @@ PHP_MSHUTDOWN_FUNCTION(xsl)
 	xsltUnregisterExtModuleFunction ((const xmlChar *) "function",
 				   (const xmlChar *) "http://php.net/xsl");
 	xsltSetGenericErrorFunc(NULL, NULL);
-	xsltCleanupGlobals();
 
 	return SUCCESS;
 }
