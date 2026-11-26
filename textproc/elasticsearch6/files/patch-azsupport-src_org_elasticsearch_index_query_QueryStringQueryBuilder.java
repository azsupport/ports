Description: a query string nested too deeply is a request error (400), not the end of the node: the parser of Lucene 7.7.3 descends one level per bracket, and query_string with 3000 nested brackets took it past the end of the stack; the StackOverflowError reached the handler of uncaught errors, which ends the node.
Origin: azsupport; Elasticsearch 8.19.19 does the same (https://github.com/elastic/elasticsearch/pull/152385), its code is not under the Apache License 2.0 of 6.8.23, so this one is ours

--- azsupport-src/org/elasticsearch/index/query/QueryStringQueryBuilder.java.orig
+++ azsupport-src/org/elasticsearch/index/query/QueryStringQueryBuilder.java
@@ -26,6 +26,7 @@
 import org.elasticsearch.Version;
 import org.elasticsearch.common.ParseField;
 import org.elasticsearch.common.ParsingException;
+import org.elasticsearch.common.Strings;
 import org.elasticsearch.common.io.stream.StreamInput;
 import org.elasticsearch.common.io.stream.StreamOutput;
 import org.elasticsearch.common.lucene.search.Queries;
@@ -1049,6 +1050,12 @@
             query = queryParser.parse(rewrittenQueryString);
         } catch (org.apache.lucene.queryparser.classic.ParseException e) {
             throw new QueryShardException(context, "Failed to parse query [" + this.queryString + "]", e);
+        } catch (StackOverflowError e) {
+            // azsupport/ports: the parser of Lucene descends one level per bracket; a query
+            // string of some thousands of them took it past the end of the stack, and the
+            // node exits on the error. A request error (400) instead.
+            throw new QueryShardException(context, "Failed to parse query [{}]: the query is nested too deeply",
+                Strings.cleanTruncate(this.queryString, 1024));
         }
 
         if (query == null) {
