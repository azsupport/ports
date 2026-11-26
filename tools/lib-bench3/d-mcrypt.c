/* SPDX-License-Identifier: BSD-2-Clause */
/* d-mcrypt [<scale>]: libmcrypt, the ciphers of PHP mcrypt_* (5.6 to 7.1 sites) */
#include <mcrypt.h>
#include "lb.h"

static int
run(const char *alg, const char *mode, unsigned char *buf, size_t n, int s)
{
	char name[96];
	unsigned char key[32], iv[64];
	MCRYPT td = mcrypt_module_open((char *)alg, NULL, (char *)mode, NULL);
	int ks, i;
	double t;

	if (td == MCRYPT_FAILED) {
		fprintf(stderr, "no %s %s\n", alg, mode);
		return 1;
	}
	ks = mcrypt_enc_get_key_size(td);
	memset(key, 5, sizeof(key));
	memset(iv, 1, sizeof(iv));
	if (mcrypt_generic_init(td, key, ks > 32 ? 32 : ks, iv) < 0)
		return 1;
	t = lb_now();
	for (i = 0; i < s; i++)
		mcrypt_generic(td, buf, (int)n);
	snprintf(name, sizeof(name), "%s-%s encrypt %dx%zuMB", alg, mode, s, n >> 20);
	lb_out(name, t);
	mcrypt_generic_deinit(td);
	mcrypt_module_close(td);
	LB_KEEP(buf[7]);
	return 0;
}

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, r = 0;
	size_t n = 32u << 20, i;
	unsigned char *b = malloc(n);

	for (i = 0; i < n; i++)
		b[i] = (unsigned char)(lb_rand() >> 56);
	r |= run("rijndael-128", "cbc", b, n, 2 * s);
	r |= run("rijndael-256", "cbc", b, n, 3 * s);
	r |= run("blowfish", "cbc", b, n, 2 * s);
	r |= run("tripledes", "cbc", b, n, s);
	r |= run("twofish", "cfb", b, n >> 2, s);
	return r;
}
