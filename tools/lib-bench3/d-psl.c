/* SPDX-License-Identifier: BSD-2-Clause */
/* d-psl <domains> [<scale>]: libpsl with its built-in list (the cookies of curl) */
#include <libpsl.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i;
	size_t len, nl, j;
	char *buf = lb_read(argc > 1 ? argv[1] : "domains.txt", &len), **d = lb_lines(buf, &nl);
	const psl_ctx_t *p = psl_builtin();
	double t;

	if (p == NULL)
		return 1;
	t = lb_now();
	for (i = 0; i < 16 * s; i++)
		for (j = 0; j < nl; j++) {
			const char *r = psl_registrable_domain(p, d[j]);

			LB_KEEP(r != NULL ? r[0] : 0);
		}
	lb_out("registrable domain x16", t);
	t = lb_now();
	for (i = 0; i < 40 * s; i++)
		for (j = 0; j < nl; j++)
			LB_KEEP(psl_is_public_suffix2(p, d[j] + (j % 4), PSL_TYPE_ANY));
	lb_out("is public suffix x40", t);
	t = lb_now();
	for (i = 0; i < 200 * s; i++)
		for (j = 0; j + 1 < nl; j++)
			LB_KEEP(psl_is_cookie_domain_acceptable(p, d[j], d[j + 1]));
	lb_out("cookie domain acceptable x200", t);
	return 0;
}
