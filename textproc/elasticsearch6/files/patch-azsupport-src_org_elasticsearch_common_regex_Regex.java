Description: Regex.simpleMatch without recursion (CVE-2023-31419, CVE-2026-72636): one level of recursion per part of the pattern between two '*' took a pattern of some thousands of '*' (a field name of query_string with 5000 escaped \* in it) past the end of the stack, and the node exited on the StackOverflowError; a loop over those parts now, which matches the same strings (3 million random patterns and strings compared with the recursion of 6.8.23: no difference).
Origin: azsupport; Elasticsearch 7.17.13 and 8.9.1 skip a run of '*' in one step (https://github.com/elastic/elasticsearch/commit/6f66c75c991f6dceb98a3d5ef9ce6ac3aecff71c), and 8.19.20 matches with a loop, Glob.globMatch (https://github.com/elastic/elasticsearch/pull/153025); their code is not under the Apache License 2.0 of 6.8.23 (the Elastic License 2.0, the SSPL, the AGPL v3), so this one is ours
Bug: https://discuss.elastic.co/t/elasticsearch-8-9-1-7-17-13-security-update/343297

--- azsupport-src/org/elasticsearch/common/regex/Regex.java.orig
+++ azsupport-src/org/elasticsearch/common/regex/Regex.java
@@ -88,34 +88,42 @@
         if (pattern == null || str == null) {
             return false;
         }
-        int firstIndex = pattern.indexOf('*');
-        if (firstIndex == -1) {
+        int star = pattern.indexOf('*');
+        if (star == -1) {
             return pattern.equals(str);
         }
-        if (firstIndex == 0) {
-            if (pattern.length() == 1) {
+        // azsupport/ports: a loop instead of the recursion, one level per '*', that a
+        // pattern of some thousands of '*' (a field name of query_string) took past the
+        // end of the stack: StackOverflowError, and the node exits (CVE-2023-31419,
+        // CVE-2026-72636). The text before the first '*' starts the string; each part
+        // between two '*' is taken where it first occurs after the part before it (with
+        // '*' as the only wildcard the leftmost match is never worse than another); the
+        // part after the last '*' ends the string, after the parts before it.
+        if (str.regionMatches(0, pattern, 0, star) == false) {
+            return false;
+        }
+        int p = star;
+        int s = star;
+        while (true) {
+            while (p < pattern.length() && pattern.charAt(p) == '*') {
+                p++;
+            }
+            if (p == pattern.length()) {
                 return true;
             }
-            int nextIndex = pattern.indexOf('*', firstIndex + 1);
-            if (nextIndex == -1) {
-                return str.endsWith(pattern.substring(1));
-            } else if (nextIndex == 1) {
-                // Double wildcard "**" - skipping the first "*"
-                return simpleMatch(pattern.substring(1), str);
+            final int next = pattern.indexOf('*', p);
+            if (next == -1) {
+                final int length = pattern.length() - p;
+                final int from = str.length() - length;
+                return from >= s && str.regionMatches(from, pattern, p, length);
             }
-            String part = pattern.substring(1, nextIndex);
-            int partIndex = str.indexOf(part);
-            while (partIndex != -1) {
-                if (simpleMatch(pattern.substring(nextIndex), str.substring(partIndex + part.length()))) {
-                    return true;
-                }
-                partIndex = str.indexOf(part, partIndex + 1);
+            final int at = str.indexOf(pattern.substring(p, next), s);
+            if (at == -1) {
+                return false;
             }
-            return false;
+            s = at + (next - p);
+            p = next;
         }
-        return (str.length() >= firstIndex &&
-                pattern.substring(0, firstIndex).equals(str.substring(0, firstIndex)) &&
-                simpleMatch(pattern.substring(firstIndex), str.substring(firstIndex)));
     }
 
     /**
