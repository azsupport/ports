--- php_xsl.c.orig	2026-11-08 20:46:51 UTC
+++ php_xsl.c
@@ -226,7 +226,6 @@ PHP_MSHUTDOWN_FUNCTION(xsl)
 	xsltUnregisterExtModuleFunction ((const xmlChar *) "function",
 				   (const xmlChar *) "http://php.net/xsl");
 	xsltSetGenericErrorFunc(NULL, NULL);
-	xsltCleanupGlobals();
 
 	return SUCCESS;
 }
