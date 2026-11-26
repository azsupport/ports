/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-tiff <in.ppm> [<scale>]: libtiff, writing and reading a picture with the codecs of
 * libtiff itself (LZW, with and without the horizontal predictor, PackBits) and with
 * Deflate (zlib of the base system: its predictor and strips are libtiff's)
 */
#include <tiffio.h>
#include "lb.h"

static int
put(const char *path, unsigned char *rgb, int w, int h, int comp, int pred)
{
	TIFF *t = TIFFOpen(path, "w");
	int y;

	if (t == NULL)
		return 1;
	TIFFSetField(t, TIFFTAG_IMAGEWIDTH, w);
	TIFFSetField(t, TIFFTAG_IMAGELENGTH, h);
	TIFFSetField(t, TIFFTAG_BITSPERSAMPLE, 8);
	TIFFSetField(t, TIFFTAG_SAMPLESPERPIXEL, 3);
	TIFFSetField(t, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
	TIFFSetField(t, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFSetField(t, TIFFTAG_COMPRESSION, comp);
	if (pred)
		TIFFSetField(t, TIFFTAG_PREDICTOR, PREDICTOR_HORIZONTAL);
	if (comp == COMPRESSION_ADOBE_DEFLATE)
		TIFFSetField(t, TIFFTAG_ZIPQUALITY, 1);
	TIFFSetField(t, TIFFTAG_ROWSPERSTRIP, 16);
	for (y = 0; y < h; y++)
		if (TIFFWriteScanline(t, rgb + (size_t)y * w * 3, (uint32_t)y, 0) < 0)
			return 1;
	TIFFClose(t);
	return 0;
}

static int
get(const char *path, unsigned char *buf)
{
	TIFF *t = TIFFOpen(path, "r");
	uint32_t h, y;
	tsize_t sl;

	if (t == NULL)
		return 1;
	TIFFGetField(t, TIFFTAG_IMAGELENGTH, &h);
	sl = TIFFScanlineSize(t);
	for (y = 0; y < h; y++)
		if (TIFFReadScanline(t, buf + (size_t)y * sl, y, 0) < 0)
			return 1;
	LB_KEEP(buf[1000]);
	TIFFClose(t);
	return 0;
}

int
main(int argc, char **argv)
{
	static const struct { const char *n; int c, p, wr, rd; } cs[] = { { "lzw", COMPRESSION_LZW, 0, 1, 2 },
		{ "lzw predictor", COMPRESSION_LZW, 1, 1, 2 }, { "packbits", COMPRESSION_PACKBITS, 0, 4, 20 },
		{ "deflate predictor (zlib 1)", COMPRESSION_ADOBE_DEFLATE, 1, 1, 2 } };
	int s = argc > 2 ? atoi(argv[2]) : 1, i, k, w, h, mx, off;
	size_t len;
	char *ppm = lb_read(argc > 1 ? argv[1] : "in.ppm", &len), name[96], path[64];
	unsigned char *rgb, *buf;
	double t;

	if (sscanf(ppm, "P6 %d %d %d%n", &w, &h, &mx, &off) != 3)
		return 2;
	rgb = (unsigned char *)ppm + off + 1;
	buf = malloc((size_t)w * h * 3 + 4096);
	TIFFSetWarningHandler(NULL);
	for (k = 0; k < 4; k++) {
		snprintf(path, sizeof(path), "lb-%d.tif", k);
		t = lb_now();
		for (i = 0; i < cs[k].wr * s; i++)
			if (put(path, rgb, w, h, cs[k].c, cs[k].p) != 0)
				return 1;
		snprintf(name, sizeof(name), "write %s (12 MP) x%d", cs[k].n, cs[k].wr);
		lb_out(name, t);
	}
	for (k = 0; k < 4; k++) {
		snprintf(path, sizeof(path), "lb-%d.tif", k);
		t = lb_now();
		for (i = 0; i < cs[k].rd * s; i++)
			if (get(path, buf) != 0)
				return 1;
		snprintf(name, sizeof(name), "read %s (12 MP) x%d", cs[k].n, cs[k].rd);
		lb_out(name, t);
	}
	return 0;
}
