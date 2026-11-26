/* SPDX-License-Identifier: BSD-2-Clause */
/* d-idn2 <domains> [<scale>]: libidn2 (curl, PHP idn_to_ascii without intl): to ASCII and back */
#include <idn2.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i;
	size_t len, nl, j;
	char *buf = lb_read(argc > 1 ? argv[1] : "domains.txt", &len), **d = lb_lines(buf, &nl), **ascii;
	uint8_t *out;
	char *u8;
	double t;

	ascii = calloc(nl, sizeof(*ascii));
	t = lb_now();
	for (i = 0; i < 4 * s; i++)
		for (j = 0; j < nl; j++) {
			if (idn2_lookup_u8((const uint8_t *)d[j], &out, IDN2_NFC_INPUT | IDN2_NONTRANSITIONAL) != IDN2_OK)
				continue;
			if (i == 0)
				ascii[j] = (char *)out;
			else
				idn2_free(out);
		}
	lb_out("lookup (to ASCII) x4", t);
	t = lb_now();
	for (i = 0; i < 20 * s; i++)
		for (j = 0; j < nl; j++) {
			if (ascii[j] == NULL || idn2_to_unicode_8z8z(ascii[j], &u8, 0) != IDN2_OK)
				continue;
			LB_KEEP(u8[0]);
			idn2_free(u8);
		}
	lb_out("to unicode x20", t);
	t = lb_now();
	for (i = 0; i < 20 * s; i++)
		for (j = 0; j < nl; j++) {
			if (idn2_register_u8((const uint8_t *)d[j], NULL, &out, IDN2_NFC_INPUT) == IDN2_OK)
				idn2_free(out);
		}
	lb_out("register (strict) x20", t);
	return 0;
}
