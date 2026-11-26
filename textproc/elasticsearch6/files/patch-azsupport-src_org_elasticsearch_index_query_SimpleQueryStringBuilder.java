Description: a simple query string nested too deeply is a request error (400), not the end of the node: simple_query_string with 15000 nested brackets took its parser past the end of the stack; the StackOverflowError reached the handler of uncaught errors, which ends the node.
Origin: azsupport; Elasticsearch 8.19.19 does the same (https://github.com/elastic/elasticsearch/pull/152385), its code is not under the Apache License 2.0 of 6.8.23, so this one is ours

--- azsupport-src/org/elasticsearch/index/query/SimpleQueryStringBuilder.java.orig
+++ azsupport-src/org/elasticsearch/index/query/SimpleQueryStringBuilder.java
@@ -484,7 +484,16 @@
             sqp = new SimpleQueryStringQueryParser(luceneAnalyzer, resolvedFieldsAndWeights, flags, newSettings, context);
         }
         sqp.setDefaultOperator(defaultOperator.toBooleanClauseOccur());
-        Query query = sqp.parse(queryText);
+        Query query;
+        try {
+            query = sqp.parse(queryText);
+        } catch (StackOverflowError e) {
+            // azsupport/ports: the parser descends one level per bracket; a query of some
+            // thousands of them took it past the end of the stack, and the node exits on the
+            // error. A request error (400) instead.
+            throw new QueryShardException(context, "Failed to parse query [{}]: the query is nested too deeply",
+                Strings.cleanTruncate(queryText, 1024));
+        }
         return Queries.maybeApplyMinimumShouldMatch(query, minimumShouldMatch);
     }
 
