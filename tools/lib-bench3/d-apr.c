/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-apr [<scale>]: APR as Apache httpd uses it for every request: pools, tables (the
 * headers), hashes, strings and formatting
 */
#include <apr_general.h>
#include <apr_hash.h>
#include <apr_pools.h>
#include <apr_strings.h>
#include <apr_tables.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, j;
	apr_pool_t *root, *p;
	apr_table_t *tb;
	apr_hash_t *h;
	char **keys;
	double t;
	static const char *hn[] = { "Host", "User-Agent", "Accept", "Accept-Language", "Accept-Encoding", "Cookie",
		"Connection", "Referer", "X-Forwarded-For", "Cache-Control", "If-Modified-Since", "Content-Type" };

	apr_initialize();
	apr_pool_create(&root, NULL);
	t = lb_now();
	for (i = 0; i < 300000 * s; i++) {
		apr_pool_create(&p, root);
		for (j = 0; j < 40; j++)
			LB_KEEP(((char *)apr_palloc(p, 24 + (size_t)(j * 37 % 500)))[0] = 1);
		apr_pool_destroy(p);
	}
	lb_out("pool create palloc destroy 300k", t);
	apr_pool_create(&p, root);
	t = lb_now();
	for (i = 0; i < 300000 * s; i++) {
		tb = apr_table_make(p, 16);
		for (j = 0; j < 12; j++)
			apr_table_add(tb, hn[j], "value of the header, some text");
		for (j = 0; j < 24; j++)
			LB_KEEP(apr_table_get(tb, hn[(j * 5) % 12]) != NULL);
		apr_table_set(tb, "Cookie", "a=b");
		apr_table_unset(tb, "Referer");
		if ((i & 1023) == 0)
			apr_pool_clear(p);
	}
	lb_out("table add get set unset 300k", t);
	apr_pool_clear(p);
	keys = malloc(100000 * sizeof(*keys));
	for (j = 0; j < 100000; j++)
		keys[j] = apr_psprintf(root, "/var/www/site%d/htdocs/index-%d.php", j % 97, j);
	t = lb_now();
	for (i = 0; i < 10 * s; i++) {
		h = apr_hash_make(p);
		for (j = 0; j < 100000; j++)
			apr_hash_set(h, keys[j], APR_HASH_KEY_STRING, keys[j]);
		for (j = 0; j < 200000; j++)
			LB_KEEP(apr_hash_get(h, keys[(j * 7) % 100000], APR_HASH_KEY_STRING) != NULL);
		apr_pool_clear(p);
	}
	lb_out("hash set get 10x100k", t);
	t = lb_now();
	for (i = 0; i < 1000000 * s; i++) {
		char *x = apr_psprintf(p, "%s %d %" APR_INT64_T_FMT " %pp %.3f", hn[i % 12], i, (apr_int64_t)i * 3, (void *)p,
		    i * 0.5);

		LB_KEEP(strlen(apr_pstrcat(p, x, "/", hn[(i + 1) % 12], NULL)));
		if ((i & 4095) == 0)
			apr_pool_clear(p);
	}
	lb_out("psprintf pstrcat 1M", t);
	apr_pool_destroy(root);
	apr_terminate();
	return 0;
}
