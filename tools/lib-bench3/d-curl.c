/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-curl <urls> [<scale>]: libcurl without the network: the URL API (what curl and PHP
 * curl do with every URL), escaping, dates of HTTP and cookies, and a transfer of file://
 */
#include <curl/curl.h>
#include "lb.h"

static size_t
sink(char *p, size_t sz, size_t n, void *u)
{
	(void)p;
	*(size_t *)u += sz * n;
	return sz * n;
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i;
	size_t len, nl, j, got = 0;
	char *buf = lb_read(argc > 1 ? argv[1] : "urls.txt", &len), **u = lb_lines(buf, &nl), *x, *y;
	static const char *dates[] = { "Sun, 06 Nov 1994 08:49:37 GMT", "Sunday, 06-Nov-94 08:49:37 GMT",
		"Sun Nov  6 08:49:37 1994", "Thu, 26 Nov 2026 21:30:00 +0100", "2026-11-26 21:30:00" };
	CURLU *h = curl_url();
	CURL *e;
	double t;

	curl_global_init(CURL_GLOBAL_DEFAULT);
	t = lb_now();
	for (i = 0; i < 4 * s; i++)
		for (j = 0; j < nl; j++) {
			if (curl_url_set(h, CURLUPART_URL, u[j], CURLU_GUESS_SCHEME | CURLU_NON_SUPPORT_SCHEME) != CURLUE_OK)
				continue;
			if (curl_url_get(h, CURLUPART_HOST, &x, 0) == CURLUE_OK)
				curl_free(x);
			if (curl_url_get(h, CURLUPART_QUERY, &x, 0) == CURLUE_OK)
				curl_free(x);
			if (curl_url_get(h, CURLUPART_URL, &x, CURLU_URLDECODE) == CURLUE_OK) {
				LB_KEEP(x[0]);
				curl_free(x);
			}
		}
	lb_out("URL parse and get parts x4", t);
	t = lb_now();
	for (i = 0; i < 4 * s; i++)
		for (j = 0; j < nl; j++) {
			curl_url_set(h, CURLUPART_URL, "https://example.com/a/b/c.php?x=1", 0);
			curl_url_set(h, CURLUPART_URL, u[j] + (j % 3), 0);
			curl_url_set(h, CURLUPART_QUERY, "id=5&q=%D0%BF", CURLU_APPENDQUERY);
			if (curl_url_get(h, CURLUPART_URL, &x, 0) == CURLUE_OK)
				curl_free(x);
		}
	lb_out("URL relative set and append query x4", t);
	e = curl_easy_init();
	t = lb_now();
	for (i = 0; i < 8 * s; i++)
		for (j = 0; j < nl; j++) {
			x = curl_easy_escape(e, u[j], 0);
			y = curl_easy_unescape(e, x, 0, NULL);
			LB_KEEP(y[0]);
			curl_free(y);
			curl_free(x);
		}
	lb_out("escape and unescape x8", t);
	t = lb_now();
	for (i = 0; i < 8000000 * s; i++)
		LB_KEEP(curl_getdate(dates[i % 5], NULL));
	lb_out("getdate 8M", t);
	curl_easy_setopt(e, CURLOPT_WRITEFUNCTION, sink);
	curl_easy_setopt(e, CURLOPT_WRITEDATA, &got);
	t = lb_now();
	for (i = 0; i < 1000 * s; i++) {
		char url[512];

		snprintf(url, sizeof(url), "file://%s", argv[1][0] == '/' ? argv[1] : "/dev/null");
		curl_easy_setopt(e, CURLOPT_URL, url);
		curl_easy_perform(e);
	}
	LB_KEEP(got);
	lb_out("file:// transfers of the URL list 1000", t);
	curl_easy_cleanup(e);
	curl_url_cleanup(h);
	return 0;
}
