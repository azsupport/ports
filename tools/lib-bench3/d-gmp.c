/* SPDX-License-Identifier: BSD-2-Clause */
/* d-gmp [<scale>]: GMP, the operations of PHP gmp_* and bcmath-sized arithmetic */
#include <gmp.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i;
	mpz_t a, b, c, d, e, m;
	gmp_randstate_t st;
	char *str;
	double t;

	gmp_randinit_default(st);
	gmp_randseed_ui(st, 12345);
	mpz_inits(a, b, c, d, e, m, NULL);

	mpz_urandomb(a, st, 64);
	mpz_urandomb(b, st, 64);
	t = lb_now();
	for (i = 0; i < 80000000 * s; i++) {
		mpz_mul(c, a, b);
		mpz_add(a, a, c);
		mpz_tdiv_r_2exp(a, a, 128);
		mpz_add_ui(b, b, (unsigned long)i);
	}
	lb_out("small mul add 80M", t);
	mpz_urandomb(a, st, 1000000);
	mpz_urandomb(b, st, 1000000);
	t = lb_now();
	for (i = 0; i < 300 * s; i++)
		mpz_mul(c, a, b);
	lb_out("mul 1Mbit x300", t);
	mpz_urandomb(d, st, 500000);
	t = lb_now();
	for (i = 0; i < 120 * s; i++)
		mpz_tdiv_qr(e, m, c, d);
	lb_out("div 2Mbit/500kbit x120", t);
	mpz_urandomb(a, st, 100000);
	mpz_urandomb(b, st, 100000);
	t = lb_now();
	for (i = 0; i < 150 * s; i++)
		mpz_gcdext(c, d, e, a, b);
	lb_out("gcdext 100kbit x150", t);
	mpz_urandomb(m, st, 2048);
	mpz_setbit(m, 2047);
	mpz_setbit(m, 0);
	mpz_urandomb(a, st, 2040);
	mpz_urandomb(b, st, 2048);
	t = lb_now();
	for (i = 0; i < 400 * s; i++) {
		mpz_powm(c, a, b, m);
		mpz_add_ui(a, a, 1);
	}
	lb_out("powm 2048bit x400", t);
	t = lb_now();
	for (i = 0; i < 20 * s; i++)
		mpz_fac_ui(c, 300000);
	lb_out("fac 300000 x20", t);
	mpz_urandomb(a, st, 2000000);
	t = lb_now();
	for (i = 0; i < 100 * s; i++)
		mpz_sqrt(c, a);
	lb_out("sqrt 2Mbit x100", t);
	mpz_urandomb(d, st, 300000);
	str = malloc(mpz_sizeinbase(d, 10) + 2);
	t = lb_now();
	for (i = 0; i < 300 * s; i++)
		LB_KEEP(mpz_get_str(str, 10, d)[0]);
	lb_out("get_str 300kbit x300", t);
	return 0;
}
