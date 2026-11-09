--- php_xsl.c.orig
+++ php_xsl.c
@@ -274,8 +274,6 @@
 	xsltUnregisterExtModuleFunction ((const xmlChar *) "function",
 				   (const xmlChar *) "http://php.net/xsl");
 
-	xsltCleanupGlobals();
-
 	UNREGISTER_INI_ENTRIES();
 
 	return SUCCESS;
