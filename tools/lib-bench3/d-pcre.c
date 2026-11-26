/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-pcre <text> [<scale>]: PCRE 8.x (UTF-8 and UCP): every match of ten patterns, by the
 * interpreter and by the JIT, and compiling
 */
#include <pcre.h>
#include "lb.h"

static const char *pats[] = { "ment", "ция", "(?i)vin", "[a-z]+ing\\b", "(?:ka|lo|mi)(?:ne|ro)+",
	"\\p{Cyrillic}+", "\\b\\w{6,}\\b", "\\d{3,}", "(\\w)\\1", "(?m)^[A-ZА-Я]\\w+" };
#define NP (int)(sizeof(pats) / sizeof(*pats))

static void
all(pcre *re, pcre_extra *ex, const char *s, int len)
{
	int off = 0, ov[30], rc;

	while (off < len) {
		rc = pcre_exec(re, ex, s, len, off, PCRE_NO_UTF8_CHECK, ov, 30);
		if (rc < 0)
			break;
		LB_KEEP(ov[0]);
		off = ov[1] > ov[0] ? ov[1] : ov[0] + 1;
		while (off < len && (s[off] & 0xc0) == 0x80)
			off++;
	}
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, k, eo;
	size_t len;
	const char *txt = lb_read(argc > 1 ? argv[1] : "text.txt", &len), *err;
	pcre *re[NP];
	pcre_extra *nj[NP], *jit[NP];
	double t;

	for (k = 0; k < NP; k++) {
		re[k] = pcre_compile(pats[k], PCRE_UTF8 | PCRE_UCP, &err, &eo, NULL);
		if (re[k] == NULL) {
			fprintf(stderr, "compile %s: %s\n", pats[k], err);
			return 1;
		}
		nj[k] = pcre_study(re[k], 0, &err);
		jit[k] = pcre_study(re[k], PCRE_STUDY_JIT_COMPILE, &err);
	}
	t = lb_now();
	for (i = 0; i < s; i++)
		for (k = 0; k < NP; k++)
			all(re[k], nj[k], txt, (int)len);
	lb_out("match interpreter 10 patterns", t);
	t = lb_now();
	for (i = 0; i < 4 * s; i++)
		for (k = 0; k < NP; k++)
			all(re[k], jit[k], txt, (int)len);
	lb_out("match JIT 10 patterns x4", t);
	t = lb_now();
	for (i = 0; i < 300000 * s; i++) {
		pcre *c = pcre_compile("(?i)^(?:[a-z0-9_-]+)@(?:[a-z0-9-]+\\.)+[a-z]{2,}$", PCRE_UTF8 | PCRE_UCP,
		    &err, &eo, NULL);
		pcre_free(c);
	}
	lb_out("compile 300k", t);
	return 0;
}
