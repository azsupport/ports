/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-pcre2 <text> [<scale>]: PCRE2 as PHP preg_* with /u uses it (UTF and UCP): every match
 * of ten patterns, by the interpreter and by the JIT (the default of PHP), and compiling
 */
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include "lb.h"

static const char *pats[] = { "ment", "ция", "(?i)vin", "[a-z]+ing\\b", "(?:ka|lo|mi)(?:ne|ro)+",
	"\\p{Cyrillic}+", "\\b\\w{6,}\\b", "\\d{3,}", "(\\w)\\1", "(?m)^[A-ZА-Я]\\w+" };
#define NP (int)(sizeof(pats) / sizeof(*pats))

static void
all(pcre2_code *re, PCRE2_SPTR s, size_t len, pcre2_match_data *md, int jit)
{
	size_t off = 0, *ov;
	int rc;

	while (off < len) {
		rc = jit ? pcre2_jit_match(re, s, len, off, 0, md, NULL) : pcre2_match(re, s, len, off,
		    PCRE2_NO_JIT | PCRE2_NO_UTF_CHECK, md, NULL);
		if (rc < 0)
			break;
		ov = pcre2_get_ovector_pointer(md);
		LB_KEEP(ov[0]);
		off = ov[1] > ov[0] ? ov[1] : ov[0] + 1;
		/* the next code point, not the middle of one */
		while (off < len && (s[off] & 0xc0) == 0x80)
			off++;
	}
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, k, ec;
	size_t len;
	PCRE2_SPTR txt = (PCRE2_SPTR)lb_read(argc > 1 ? argv[1] : "text.txt", &len);
	pcre2_code *re[NP];
	pcre2_match_data *md;
	PCRE2_SIZE eo;
	double t;

	for (k = 0; k < NP; k++) {
		re[k] = pcre2_compile((PCRE2_SPTR)pats[k], PCRE2_ZERO_TERMINATED, PCRE2_UTF | PCRE2_UCP, &ec, &eo, NULL);
		if (re[k] == NULL || pcre2_jit_compile(re[k], PCRE2_JIT_COMPLETE) != 0) {
			fprintf(stderr, "compile %s failed\n", pats[k]);
			return 1;
		}
	}
	md = pcre2_match_data_create(30, NULL);
	t = lb_now();
	for (i = 0; i < s; i++)
		for (k = 0; k < NP; k++)
			all(re[k], txt, len, md, 0);
	lb_out("match interpreter 10 patterns", t);
	t = lb_now();
	for (i = 0; i < 4 * s; i++)
		for (k = 0; k < NP; k++)
			all(re[k], txt, len, md, 1);
	lb_out("match JIT 10 patterns x4", t);
	t = lb_now();
	for (i = 0; i < 300000 * s; i++) {
		pcre2_code *c = pcre2_compile((PCRE2_SPTR)"(?i)^(?:[a-z0-9_-]+)@(?:[a-z0-9-]+\\.)+[a-z]{2,}$",
		    PCRE2_ZERO_TERMINATED, PCRE2_UTF | PCRE2_UCP, &ec, &eo, NULL);
		pcre2_code_free(c);
	}
	lb_out("compile 300k", t);
	t = lb_now();
	for (i = 0; i < 100000 * s; i++) {
		pcre2_code *c = pcre2_compile((PCRE2_SPTR)pats[i % NP], PCRE2_ZERO_TERMINATED, PCRE2_UTF | PCRE2_UCP,
		    &ec, &eo, NULL);
		pcre2_jit_compile(c, PCRE2_JIT_COMPLETE);
		pcre2_code_free(c);
	}
	lb_out("compile and JIT compile 100k", t);
	return 0;
}
