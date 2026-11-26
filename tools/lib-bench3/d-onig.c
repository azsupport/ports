/* SPDX-License-Identifier: BSD-2-Clause */
/* d-onig <text> [<scale>]: Oniguruma as PHP mb_ereg* uses it (UTF-8, Ruby syntax): every match */
#include <oniguruma.h>
#include "lb.h"

static const char *pats[][2] = {
	{ "literal", "ment" },
	{ "literal cyrillic", "ция" },
	{ "ignore case", "(?i)vin" },
	{ "class quantifier", "[a-z]+ing\\b" },
	{ "alternation", "(?:ka|lo|mi)(?:ne|ro)+" },
	{ "unicode property", "\\p{Cyrillic}+" },
	{ "word boundary", "\\b\\w{6,}\\b" },
	{ "digits", "\\d{3,}" },
	{ "backreference", "(\\w)\\1" },
	{ "line start", "^[A-ZА-Я]\\w+" },
};

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, k;
	size_t len;
	UChar *txt = (UChar *)lb_read(argc > 1 ? argv[1] : "text.txt", &len), *end = txt + len, *p;
	OnigEncoding enc = ONIG_ENCODING_UTF8;
	OnigRegion *rg = onig_region_new();
	OnigErrorInfo ei;
	regex_t *re;
	int r;
	double t;
	char name[96];

	onig_initialize(&enc, 1);
	for (k = 0; k < (int)(sizeof(pats) / sizeof(*pats)); k++) {
		const UChar *pat = (const UChar *)pats[k][1];

		if (onig_new(&re, pat, pat + strlen((const char *)pat), ONIG_OPTION_NONE, enc, ONIG_SYNTAX_RUBY,
		    &ei) != ONIG_NORMAL) {
			fprintf(stderr, "onig_new %s failed\n", pats[k][1]);
			return 1;
		}
		t = lb_now();
		for (i = 0; i < 12 * s; i++) {
			p = txt;
			while (p < end) {
				r = onig_search(re, txt, end, p, end, rg, ONIG_OPTION_NONE);
				if (r < 0)
					break;
				LB_KEEP(r);
				p = txt + (rg->end[0] > rg->beg[0] ? rg->end[0] : rg->beg[0] + 1);
			}
		}
		snprintf(name, sizeof(name), "%s (%s) x12", pats[k][0], pats[k][1]);
		lb_out(name, t);
		onig_free(re);
	}
	t = lb_now();
	for (i = 0; i < 10000 * s; i++) {
		const UChar *pat = (const UChar *)"(?i)^(?:[a-z0-9_-]+)@(?:[a-z0-9-]+\\.)+[a-z]{2,}$";

		onig_new(&re, pat, pat + strlen((const char *)pat), ONIG_OPTION_NONE, enc, ONIG_SYNTAX_RUBY, &ei);
		onig_free(re);
	}
	lb_out("compile 10k", t);
	onig_region_free(rg, 1);
	onig_end();
	return 0;
}
