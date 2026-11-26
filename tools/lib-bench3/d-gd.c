/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-gd <in.ppm> [<scale>]: libgd as PHP imagecopyresampled, imagescale, imagerotate,
 * imagefilter and imagetruecolortopalette use it, on a picture in memory (the codecs
 * are those of libpng and libjpeg, not of gd)
 */
#include <gd.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, w, h, mx, off, x, y;
	size_t len;
	char *ppm = lb_read(argc > 1 ? argv[1] : "in.ppm", &len);
	unsigned char *p;
	gdImagePtr src, d;
	double t;
	float blur[3][3] = { { 1, 2, 1 }, { 2, 4, 2 }, { 1, 2, 1 } };

	if (sscanf(ppm, "P6 %d %d %d%n", &w, &h, &mx, &off) != 3)
		return 2;
	p = (unsigned char *)ppm + off + 1;
	src = gdImageCreateTrueColor(w, h);
	for (y = 0; y < h; y++)
		for (x = 0; x < w; x++, p += 3)
			src->tpixels[y][x] = gdTrueColor(p[0], p[1], p[2]);

	t = lb_now();
	for (i = 0; i < 6 * s; i++) {
		d = gdImageCreateTrueColor(w / 4, h / 4);
		gdImageCopyResampled(d, src, 0, 0, 0, 0, w / 4, h / 4, w, h);
		LB_KEEP(d->tpixels[1][1]);
		gdImageDestroy(d);
	}
	lb_out("copyresampled to a quarter x6", t);
	gdImageSetInterpolationMethod(src, GD_BILINEAR_FIXED);
	t = lb_now();
	for (i = 0; i < 10 * s; i++) {
		d = gdImageScale(src, w / 2, h / 2);
		gdImageDestroy(d);
	}
	lb_out("scale bilinear to a half x10", t);
	gdImageSetInterpolationMethod(src, GD_BICUBIC);
	t = lb_now();
	for (i = 0; i < 3 * s; i++) {
		d = gdImageScale(src, w / 2, h / 2);
		gdImageDestroy(d);
	}
	lb_out("scale bicubic to a half x3", t);
	gdImageSetInterpolationMethod(src, GD_BILINEAR_FIXED);
	t = lb_now();
	for (i = 0; i < s; i++) {
		d = gdImageRotateInterpolated(src, 33.0f, 0);
		gdImageDestroy(d);
	}
	lb_out("rotate 33 bilinear", t);
	d = gdImageClone(src);
	t = lb_now();
	for (i = 0; i < s; i++)
		gdImageGaussianBlur(d);
	lb_out("filter gaussian blur", t);
	t = lb_now();
	for (i = 0; i < s; i++)
		gdImageConvolution(d, blur, 16, 0);
	lb_out("convolution 3x3", t);
	t = lb_now();
	for (i = 0; i < 2 * s; i++) {
		gdImageGrayScale(d);
		gdImageBrightness(d, 10);
		gdImageContrast(d, -10);
	}
	lb_out("grayscale brightness contrast x2", t);
	gdImageDestroy(d);
	t = lb_now();
	for (i = 0; i < 3 * s; i++) {
		d = gdImageCreateTrueColor(w / 2, h / 2);
		gdImageCopyResampled(d, src, 0, 0, 0, 0, w / 2, h / 2, w, h);
		gdImageTrueColorToPalette(d, 1, 256);
		LB_KEEP(gdImageColorsTotal(d));
		gdImageDestroy(d);
	}
	lb_out("truecolor to palette (dither, a half) x3", t);
	d = gdImageCreateTrueColor(1600, 1200);
	t = lb_now();
	for (i = 0; i < 5000 * s; i++) {
		int c = gdTrueColorAlpha(i & 255, (i * 7) & 255, (i * 13) & 255, i & 127);

		gdImageFilledRectangle(d, (i * 37) % 1500, (i * 91) % 1100, (i * 37) % 1500 + 100,
		    (i * 91) % 1100 + 80, c);
		gdImageFilledEllipse(d, (i * 53) % 1600, (i * 29) % 1200, 120, 90, c);
		gdImageLine(d, 0, (i * 11) % 1200, 1599, (i * 17) % 1200, c);
	}
	lb_out("draw rectangles ellipses lines 5k", t);
	gdImageDestroy(d);
	return 0;
}
