One Vary line (aZ, 22.11.2026: «объединить все vary комбинации которые приходят и которые
надо ставить в один», «все там фильтровать в плане символов и длинны хеадера и буферов»):
the Vary lines of a response (of an upstream, of add_header) and the "Accept-Encoding" of
gzip_vary (set by gzip, gzip_static, gunzip, brotli, zstd) go out as a single line, each
member once; before, the header filters of HTTP/1.1, HTTP/2 and HTTP/3 added
"Vary: Accept-Encoding" without a look at the lines of the response, and a response of an
upstream with its own "Vary: Accept-Encoding" had it twice (tickets 875, 919, 1204 of
trac.nginx.org: closed, "worksforme"; no patch in nginx 1.31.9, freenginx, Angie, Tengine,
OpenResty, nor in Debian, Ubuntu, Fedora, RHEL, openSUSE, Arch, Alpine, Gentoo, Void,
NixOS, pkgsrc, OpenBSD, FreeBSD, 22.11.2026).
ngx_http_gzip_vary_merge() of ngx_http_core_module.c, called by the three header filters
before they count the lines. Only what is understood is rewritten: every Vary line has to
be a list of tokens (RFC 9110, 5.6.1 and 5.6.2; "*" is one), of 32 members and 1024 bytes
at most in all; with anything else in a line, or more of it, nothing is changed and the
filters go on as nginx without the patch (the lines as they came, and their own). The new
line is made of the bytes of the tokens alone (no byte of a value is copied but those of
a token), in a buffer of the length counted for it; a tab between members is not kept
(caches split the members on spaces: pull request 1948 of nginx); a single line with
nothing to add, no member twice and no tab stays as it came. "Accept-Encoding" is not
added to a line that has it or "*".
Checked under ASan and UBSan (44 sets of Vary lines of an upstream, well-formed, broken
and large, three kinds of locations, HTTP/1.1 and HTTP/2: 440 requests against a model),
and by tests/ports/servers-test.sh of azsupport/azsupport in the build (HTTP/3 too).

--- src/http/ngx_http_core_module.c.orig
+++ src/http/ngx_http_core_module.c
@@ -2293,6 +2293,258 @@ ok:
 }
 
 
+/*
+ * One Vary line (az): the Vary lines of the response (of an upstream, of
+ * add_header) and the "Accept-Encoding" of gzip_vary in a single line, each
+ * member once.  Before, the header filters added "Vary: Accept-Encoding"
+ * without a look at the lines of the response, so that a response of an
+ * upstream with its own "Vary: Accept-Encoding" had it twice (ticket 875).
+ *
+ * Only what is understood is rewritten: every Vary line of the response has
+ * to be a list of tokens (RFC 9110, 5.6.1 and 5.6.2; "*" is one), of
+ * NGX_HTTP_VARY_MEMBERS members and NGX_HTTP_VARY_LEN bytes at most in all.
+ * With anything else in a line, or more of it, nothing is changed and the
+ * header filter goes on as before (the lines as they came, and its own).
+ * A single line with nothing to add, no member twice and no tab stays as
+ * it came.
+ * The new line is made of the bytes of the tokens alone, in a buffer of the
+ * length counted for it; r->gzip_vary is cleared when the line has
+ * "Accept-Encoding" or "*", for the filter not to add its own.
+ */
+
+#define NGX_HTTP_VARY_MEMBERS  32
+#define NGX_HTTP_VARY_LEN      1024
+
+
+static ngx_inline ngx_uint_t
+ngx_http_vary_tchar(u_char ch)
+{
+    if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
+        || (ch >= '0' && ch <= '9'))
+    {
+        return 1;
+    }
+
+    switch (ch) {
+    case '!': case '#': case '$': case '%': case '&': case '\'': case '*':
+    case '+': case '-': case '.': case '^': case '_': case '`': case '|':
+    case '~':
+        return 1;
+    }
+
+    return 0;
+}
+
+
+ngx_int_t
+ngx_http_gzip_vary_merge(ngx_http_request_t *r, ngx_flag_t vary)
+{
+    u_char           *p, *last, *start, *value;
+    size_t            len;
+    ngx_str_t         m[NGX_HTTP_VARY_MEMBERS];
+    ngx_uint_t        i, k, n, lines, add, listed, untidy;
+    ngx_list_part_t  *part;
+    ngx_table_elt_t  *h, *first;
+
+    static u_char  ae[] = "Accept-Encoding";
+
+    add = (r->gzip_vary && vary) ? 1 : 0;
+
+    n = 0;
+    lines = 0;
+    listed = 0;
+    untidy = 0;
+    first = NULL;
+
+    part = &r->headers_out.headers.part;
+    h = part->elts;
+
+    for (i = 0; /* void */ ; i++) {
+
+        if (i >= part->nelts) {
+            if (part->next == NULL) {
+                break;
+            }
+
+            part = part->next;
+            h = part->elts;
+            i = 0;
+        }
+
+        if (h[i].hash == 0
+            || h[i].key.len != sizeof("Vary") - 1
+            || ngx_strncasecmp(h[i].key.data, (u_char *) "Vary",
+                               sizeof("Vary") - 1)
+               != 0)
+        {
+            continue;
+        }
+
+        if (first == NULL) {
+            first = &h[i];
+        }
+
+        lines++;
+
+        p = h[i].value.data;
+        last = p + h[i].value.len;
+
+        while (p < last) {
+
+            if (*p == ',' || *p == ' ') {
+                p++;
+                continue;
+            }
+
+            if (*p == '\t') {
+
+                /* a tab is not kept: caches split the members on spaces */
+
+                untidy = 1;
+                p++;
+                continue;
+            }
+
+            start = p;
+
+            while (p < last && ngx_http_vary_tchar(*p)) {
+                p++;
+            }
+
+            len = p - start;
+
+            while (p < last && (*p == ' ' || *p == '\t')) {
+                if (*p == '\t') {
+                    untidy = 1;
+                }
+
+                p++;
+            }
+
+            /* a member is a token, with spaces only up to its comma */
+
+            if (len == 0 || (p < last && *p != ',')) {
+                return NGX_OK;
+            }
+
+            for (k = 0; k < n; k++) {
+                if (m[k].len == len
+                    && ngx_strncasecmp(m[k].data, start, len) == 0)
+                {
+                    break;
+                }
+            }
+
+            if (k < n) {
+                untidy = 1;
+                continue;
+            }
+
+            if (n == NGX_HTTP_VARY_MEMBERS) {
+                return NGX_OK;
+            }
+
+            m[n].len = len;
+            m[n].data = start;
+            n++;
+
+            if ((len == 1 && *start == '*')
+                || (len == sizeof(ae) - 1
+                    && ngx_strncasecmp(start, ae, sizeof(ae) - 1) == 0))
+            {
+                listed = 1;
+            }
+        }
+    }
+
+    if (lines == 0) {
+        return NGX_OK;
+    }
+
+    if (add && listed) {
+        r->gzip_vary = 0;
+        add = 0;
+    }
+
+    if ((lines == 1 && !untidy && !add) || n + add == 0) {
+        return NGX_OK;
+    }
+
+    len = add ? sizeof(ae) - 1 : 0;
+
+    for (k = 0; k < n; k++) {
+        len += m[k].len;
+    }
+
+    len += (n + add - 1) * (sizeof(", ") - 1);
+
+    if (len > NGX_HTTP_VARY_LEN) {
+        return NGX_OK;
+    }
+
+    value = ngx_pnalloc(r->pool, len);
+    if (value == NULL) {
+        return NGX_ERROR;
+    }
+
+    p = value;
+
+    for (k = 0; k < n; k++) {
+        if (k) {
+            *p++ = ','; *p++ = ' ';
+        }
+
+        p = ngx_cpymem(p, m[k].data, m[k].len);
+    }
+
+    if (add) {
+        if (n) {
+            *p++ = ','; *p++ = ' ';
+        }
+
+        p = ngx_cpymem(p, ae, sizeof(ae) - 1);
+
+        r->gzip_vary = 0;
+    }
+
+    /* the first Vary line takes the list, the others go */
+
+    part = &r->headers_out.headers.part;
+    h = part->elts;
+
+    for (i = 0; /* void */ ; i++) {
+
+        if (i >= part->nelts) {
+            if (part->next == NULL) {
+                break;
+            }
+
+            part = part->next;
+            h = part->elts;
+            i = 0;
+        }
+
+        if (h[i].hash == 0
+            || h[i].key.len != sizeof("Vary") - 1
+            || ngx_strncasecmp(h[i].key.data, (u_char *) "Vary",
+                               sizeof("Vary") - 1)
+               != 0)
+        {
+            continue;
+        }
+
+        if (&h[i] != first) {
+            h[i].hash = 0;
+        }
+    }
+
+    first->value.len = len;
+    first->value.data = value;
+
+    return NGX_OK;
+}
+
+
 /*
  * gzip is enabled for the following quantities:
  *     "gzip; q=0.001" ... "gzip; q=1.000"
