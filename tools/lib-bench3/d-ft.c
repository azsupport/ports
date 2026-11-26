/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-ft <font.ttf> [<scale>]: FreeType as GD (imagettftext), ImageMagick and cairo use it:
 * load and render every glyph of a font at the sizes of text on pictures, hinted by the
 * font, by the autohinter, and outlines only
 */
#include <ft2build.h>
#include FT_FREETYPE_H
#include "lb.h"

static void
pass(FT_Face f, int size, FT_Int32 flags, int render)
{
	FT_UInt g;

	FT_Set_Char_Size(f, 0, size * 64, 96, 96);
	for (g = 0; g < (FT_UInt)f->num_glyphs; g++) {
		if (FT_Load_Glyph(f, g, flags) != 0)
			continue;
		if (render && FT_Render_Glyph(f->glyph, FT_RENDER_MODE_NORMAL) == 0)
			LB_KEEP(f->glyph->bitmap.rows);
	}
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i;
	FT_Library lib;
	FT_Face f;
	double t;

	if (FT_Init_FreeType(&lib) != 0 || FT_New_Face(lib, argc > 1 ? argv[1] : "font.ttf", 0, &f) != 0) {
		fprintf(stderr, "cannot open the font\n");
		return 1;
	}
	t = lb_now();
	for (i = 0; i < 8 * s; i++) {
		pass(f, 12, FT_LOAD_DEFAULT, 1);
		pass(f, 24, FT_LOAD_DEFAULT, 1);
		pass(f, 48, FT_LOAD_DEFAULT, 1);
	}
	lb_out("render 12 24 48 pt hinted x8", t);
	t = lb_now();
	for (i = 0; i < 6 * s; i++) {
		pass(f, 16, FT_LOAD_FORCE_AUTOHINT, 1);
		pass(f, 32, FT_LOAD_FORCE_AUTOHINT, 1);
	}
	lb_out("render 16 32 pt autohinter x6", t);
	t = lb_now();
	for (i = 0; i < 10 * s; i++)
		pass(f, 100, FT_LOAD_NO_HINTING, 1);
	lb_out("render 100 pt unhinted x10", t);
	t = lb_now();
	for (i = 0; i < 100 * s; i++)
		pass(f, 20, FT_LOAD_NO_BITMAP | FT_LOAD_NO_HINTING, 0);
	lb_out("load outlines x100", t);
	FT_Done_Face(f);
	FT_Done_FreeType(lib);
	return 0;
}
