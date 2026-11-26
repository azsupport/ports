/* SPDX-License-Identifier: BSD-2-Clause */
/* d-fc [<scale>]: fontconfig as ImageMagick, cairo and pango look fonts up: match, sort, list */
#include <fontconfig/fontconfig.h>
#include "lb.h"

static const char *names[] = { "DejaVu Sans:bold", "serif:italic", "monospace:size=12", "Arial",
	"sans-serif:lang=ru", "DejaVu Serif:weight=200", "Helvetica:slant=100", "sans:lang=ar" };

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i;
	FcPattern *p, *m;
	FcFontSet *fs;
	FcObjectSet *os;
	FcResult r;
	double t;

	t = lb_now();
	if (!FcInit())
		return 1;
	lb_out("init (configuration and cache)", t);
	t = lb_now();
	for (i = 0; i < 10000 * s; i++) {
		p = FcNameParse((const FcChar8 *)names[i % 8]);
		FcConfigSubstitute(NULL, p, FcMatchPattern);
		FcDefaultSubstitute(p);
		m = FcFontMatch(NULL, p, &r);
		LB_KEEP(m != NULL);
		FcPatternDestroy(m);
		FcPatternDestroy(p);
	}
	lb_out("match 10k", t);
	t = lb_now();
	for (i = 0; i < 2000 * s; i++) {
		p = FcNameParse((const FcChar8 *)names[i % 8]);
		FcConfigSubstitute(NULL, p, FcMatchPattern);
		FcDefaultSubstitute(p);
		fs = FcFontSort(NULL, p, FcTrue, NULL, &r);
		LB_KEEP(fs != NULL ? fs->nfont : 0);
		FcFontSetDestroy(fs);
		FcPatternDestroy(p);
	}
	lb_out("sort 2k", t);
	os = FcObjectSetBuild(FC_FAMILY, FC_STYLE, FC_FILE, FC_LANG, (char *)0);
	t = lb_now();
	for (i = 0; i < 2000 * s; i++) {
		p = FcPatternCreate();
		fs = FcFontList(NULL, p, os);
		LB_KEEP(fs->nfont);
		FcFontSetDestroy(fs);
		FcPatternDestroy(p);
	}
	lb_out("list 2k", t);
	return 0;
}
