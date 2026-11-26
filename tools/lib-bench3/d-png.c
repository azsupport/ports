/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-png <in.ppm> [<scale>]: libpng, encoding with each filter (zlib level 1, zlib is that
 * of the base system: the filters are what libpng does) and decoding them
 */
#include <png.h>
#include "lb.h"

struct mem { unsigned char *b; size_t n, cap; };
static void
wr(png_structp p, png_bytep d, png_size_t n)
{
	struct mem *m = png_get_io_ptr(p);

	if (m->n + n > m->cap) {
		m->cap = (m->n + n) * 2;
		m->b = realloc(m->b, m->cap);
	}
	memcpy(m->b + m->n, d, n);
	m->n += n;
}
static void
fl(png_structp p)
{
	(void)p;
}

static void
encode(struct mem *m, unsigned char *rgb, int w, int h, int filter, int level)
{
	png_structp p = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	png_infop i = png_create_info_struct(p);
	int y;

	m->n = 0;
	if (setjmp(png_jmpbuf(p)))
		exit(1);
	png_set_write_fn(p, m, wr, fl);
	png_set_IHDR(p, i, (png_uint_32)w, (png_uint_32)h, 8, PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE,
	    PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
	png_set_filter(p, 0, filter);
	png_set_compression_level(p, level);
	png_write_info(p, i);
	for (y = 0; y < h; y++)
		png_write_row(p, rgb + (size_t)y * w * 3);
	png_write_end(p, i);
	png_destroy_write_struct(&p, &i);
}

static void
decode(struct mem *m, unsigned char *out)
{
	png_image im;

	memset(&im, 0, sizeof(im));
	im.version = PNG_IMAGE_VERSION;
	if (!png_image_begin_read_from_memory(&im, m->b, m->n))
		exit(1);
	im.format = PNG_FORMAT_RGBA;
	if (!png_image_finish_read(&im, NULL, out, 0, NULL))
		exit(1);
	LB_KEEP(out[100]);
}

int
main(int argc, char **argv)
{
	static const struct { const char *n; int f; } fs[] = { { "none", PNG_FILTER_NONE }, { "sub", PNG_FILTER_SUB },
		{ "up", PNG_FILTER_UP }, { "avg", PNG_FILTER_AVG }, { "paeth", PNG_FILTER_PAETH },
		{ "all (adaptive)", PNG_ALL_FILTERS } };
	int s = argc > 2 ? atoi(argv[2]) : 1, i, k, w, h, mx, off;
	size_t len;
	char *ppm = lb_read(argc > 1 ? argv[1] : "in.ppm", &len), name[80];
	unsigned char *rgb, *out;
	struct mem m[6];
	double t;

	if (sscanf(ppm, "P6 %d %d %d%n", &w, &h, &mx, &off) != 3)
		return 2;
	rgb = (unsigned char *)ppm + off + 1;
	out = malloc((size_t)w * h * 4);
	for (k = 0; k < 6; k++) {
		memset(&m[k], 0, sizeof(m[k]));
		t = lb_now();
		for (i = 0; i < s; i++)
			encode(&m[k], rgb, w, h, fs[k].f, k == 5 ? 6 : 1);
		snprintf(name, sizeof(name), "encode filter %s%s", fs[k].n, k == 5 ? " zlib 6" : "");
		lb_out(name, t);
	}
	for (k = 0; k < 6; k++) {
		t = lb_now();
		for (i = 0; i < 2 * s; i++)
			decode(&m[k], out);
		snprintf(name, sizeof(name), "decode filter %s x2", fs[k].n);
		lb_out(name, t);
	}
	return 0;
}
