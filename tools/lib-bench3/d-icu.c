/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-icu <text> [<scale>]: ICU (C API) as PHP intl and the programs use it: conversion,
 * collation, normalization, word breaks, case mapping, transliteration, number and date
 * formatting
 */
#include <unicode/ubrk.h>
#include <unicode/ucnv.h>
#include <unicode/ucol.h>
#include <unicode/udat.h>
#include <unicode/unorm2.h>
#include <unicode/unum.h>
#include <unicode/ustring.h>
#include <unicode/utrans.h>
#include "lb.h"

static UCollator *coll;
static int
cmp(const void *a, const void *b)
{
	UErrorCode e = U_ZERO_ERROR;

	return ucol_strcollUTF8(coll, *(const char *const *)a, -1, *(const char *const *)b, -1, &e);
}

#define CHK(what) do { if (U_FAILURE(e)) { fprintf(stderr, "%s: %s\n", what, u_errorName(e)); return 1; } } while (0)

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, j, n16, nb;
	size_t len, nl;
	char *txt = lb_read(argc > 1 ? argv[1] : "text.txt", &len), *copy = strdup(txt), **lines, *bytes;
	UErrorCode e = U_ZERO_ERROR;
	UChar *u, *u2;
	int32_t cap;
	UConverter *cv;
	const UNormalizer2 *nfc, *nfkc;
	UBreakIterator *bi;
	UTransliterator *tr;
	UNumberFormat *nf;
	UDateFormat *df;
	UChar buf[256];
	uint8_t key[512];
	double t;
	static const char *cs[] = { "windows-1251", "ISO-8859-5", "KOI8-R", "GB18030", "Shift_JIS", "UTF-16LE" };

	lines = lb_lines(copy, &nl);
	cap = (int32_t)len + 16;
	u = malloc((size_t)cap * 2 * sizeof(UChar));
	u2 = malloc((size_t)cap * 2 * sizeof(UChar));
	bytes = malloc((size_t)cap * 4);
	u_strFromUTF8(u, cap, &n16, txt, (int32_t)len, &e);
	CHK("u_strFromUTF8");

	t = lb_now();
	for (i = 0; i < 16 * s; i++) {
		u_strFromUTF8(u2, cap, &j, txt, (int32_t)len, &e);
		u_strToUTF8(bytes, cap * 4, &nb, u2, j, &e);
	}
	CHK("utf8");
	lb_out("UTF-8 to UTF-16 and back x16", t);
	for (j = 0; j < (int)(sizeof(cs) / sizeof(*cs)); j++) {
		char name[80];

		cv = ucnv_open(cs[j], &e);
		CHK(cs[j]);
		t = lb_now();
		for (i = 0; i < 16 * s; i++) {
			int32_t k = ucnv_fromUChars(cv, bytes, cap * 4, u, n16, &e);

			ucnv_toUChars(cv, u2, cap, bytes, k, &e);
			e = U_ZERO_ERROR;
		}
		snprintf(name, sizeof(name), "convert %s and back x16", cs[j]);
		lb_out(name, t);
		ucnv_close(cv);
	}
	coll = ucol_open("ru", &e);
	CHK("ucol_open");
	t = lb_now();
	for (i = 0; i < 12 * s; i++) {
		char **v = malloc(nl * sizeof(*v));

		memcpy(v, lines, nl * sizeof(*v));
		qsort(v, nl < 60000 ? nl : 60000, sizeof(*v), cmp);
		LB_KEEP(v[0][0]);
		free(v);
	}
	lb_out("collate ru: sort 60k lines x12", t);
	t = lb_now();
	for (i = 0; i < 6 * s; i++)
		for (j = 0; j < (int)nl && j < 100000; j++) {
			UChar l16[512];
			int32_t ln;

			u_strFromUTF8(l16, 512, &ln, lines[j], -1, &e);
			e = U_ZERO_ERROR;
			LB_KEEP(ucol_getSortKey(coll, l16, ln, key, sizeof(key)));
		}
	lb_out("collate ru: sort keys 100k lines x6", t);
	ucol_close(coll);
	nfc = unorm2_getNFCInstance(&e);
	nfkc = unorm2_getNFKCCasefoldInstance(&e);
	CHK("unorm2");
	t = lb_now();
	for (i = 0; i < 12 * s; i++) {
		LB_KEEP(unorm2_normalize(nfc, u, n16, u2, cap * 2, &e));
		LB_KEEP(unorm2_isNormalized(nfc, u, n16, &e));
		LB_KEEP(unorm2_normalize(nfkc, u, n16, u2, cap * 2, &e));
	}
	CHK("normalize");
	lb_out("normalize NFC, NFKC_Casefold x12", t);
	bi = ubrk_open(UBRK_WORD, "ru", u, n16, &e);
	CHK("ubrk_open");
	t = lb_now();
	for (i = 0; i < 6 * s; i++) {
		int32_t p, c = 0;

		for (p = ubrk_first(bi); p != UBRK_DONE; p = ubrk_next(bi))
			c++;
		LB_KEEP(c);
	}
	lb_out("word breaks x6", t);
	ubrk_close(bi);
	t = lb_now();
	for (i = 0; i < 6 * s; i++) {
		LB_KEEP(u_strToUpper(u2, cap * 2, u, n16, "ru", &e));
		LB_KEEP(u_strToLower(u2, cap * 2, u, n16, "tr", &e));
	}
	CHK("case");
	lb_out("upper ru, lower tr x6", t);
	u_uastrcpy(buf, "Any-Latin; Latin-ASCII; Lower");
	tr = utrans_openU(buf, -1, UTRANS_FORWARD, NULL, 0, NULL, &e);
	CHK("utrans_openU");
	t = lb_now();
	for (i = 0; i < 30000 * s; i++) {
		int32_t l, lim;
		UChar w[600];

		u_strFromUTF8(w, 200, &l, lines[i % nl], -1, &e);
		e = U_ZERO_ERROR;
		lim = l;
		utrans_transUChars(tr, w, &l, 600, 0, &lim, &e);
		e = U_ZERO_ERROR;
		LB_KEEP(l);
	}
	lb_out("transliterate Any-Latin; Latin-ASCII 30k lines", t);
	utrans_close(tr);
	nf = unum_open(UNUM_DECIMAL, NULL, 0, "ru_RU", NULL, &e);
	CHK("unum_open");
	t = lb_now();
	for (i = 0; i < 1500000 * s; i++)
		LB_KEEP(unum_formatDouble(nf, i * 1.375, buf, 256, NULL, &e));
	lb_out("number format ru 1.5M", t);
	unum_close(nf);
	df = udat_open(UDAT_LONG, UDAT_MEDIUM, "ru_RU", u"Europe/Prague", -1, NULL, 0, &e);
	CHK("udat_open");
	t = lb_now();
	for (i = 0; i < 300000 * s; i++)
		LB_KEEP(udat_format(df, 1.7e12 + i * 3600e3, buf, 256, NULL, &e));
	lb_out("date format ru 300k", t);
	udat_close(df);
	return 0;
}
