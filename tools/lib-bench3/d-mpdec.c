/* SPDX-License-Identifier: BSD-2-Clause */
/* d-mpdec [<scale>]: libmpdec, the decimal module of Python (28 digits) and big precision */
#include <mpdecimal.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i;
	mpd_context_t ctx;
	mpd_t *a, *b, *c, *d;
	char *str, num[64];
	double t;

	mpd_init(&ctx, 28);
	a = mpd_new(&ctx);
	b = mpd_new(&ctx);
	c = mpd_new(&ctx);
	d = mpd_new(&ctx);
	mpd_set_string(a, "1234.5678", &ctx);
	mpd_set_string(b, "1.0000001", &ctx);
	mpd_set_string(d, "0.07", &ctx);
	t = lb_now();
	for (i = 0; i < 3000000 * s; i++) {
		mpd_mul(c, a, b, &ctx);
		mpd_add(a, c, d, &ctx);
		mpd_div(c, a, b, &ctx);
		mpd_sub(a, c, d, &ctx);
	}
	lb_out("prec 28: mul add div sub 3M", t);
	t = lb_now();
	for (i = 0; i < 3000000 * s; i++) {
		snprintf(num, sizeof(num), "%d.%04d", i, i % 9973);
		mpd_set_string(c, num, &ctx);
		mpd_quantize(a, c, d, &ctx);
		str = mpd_to_sci(a, 0);
		LB_KEEP(str[0]);
		mpd_free(str);
	}
	lb_out("prec 28: parse quantize format 3M", t);
	t = lb_now();
	for (i = 0; i < 300000 * s; i++) {
		mpd_set_i32(c, i + 2, &ctx);
		mpd_sqrt(a, c, &ctx);
		mpd_ln(b, c, &ctx);
		LB_KEEP(mpd_isfinite(b));
	}
	lb_out("prec 28: sqrt ln 300k", t);
	mpd_set_string(b, "1.0000001", &ctx);
	ctx.prec = 20000;
	mpd_set_i32(a, 2, &ctx);
	mpd_sqrt(a, a, &ctx);
	mpd_set_i32(d, 3, &ctx);
	mpd_sqrt(d, d, &ctx);
	t = lb_now();
	for (i = 0; i < 400 * s; i++)
		mpd_mul(c, a, d, &ctx);
	lb_out("prec 20000: mul x400", t);
	t = lb_now();
	for (i = 0; i < 40 * s; i++)
		mpd_div(c, a, d, &ctx);
	lb_out("prec 20000: div x40", t);
	return 0;
}
