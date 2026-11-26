/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-lcms2 <in.ppm> [<scale>]: Little CMS as ImageMagick and GraphicsMagick use it for the
 * colour profiles of pictures: transforms of a picture between profiles, 8 and 16 bits and
 * floating point, and making the transforms
 */
#include <lcms2.h>
#include "lb.h"

static cmsHPROFILE
adobe(void)
{
	cmsCIExyY wp = { 0.3127, 0.3290, 1.0 };
	cmsCIExyYTRIPLE pr = { { 0.64, 0.33, 1.0 }, { 0.21, 0.71, 1.0 }, { 0.15, 0.06, 1.0 } };
	cmsToneCurve *g = cmsBuildGamma(NULL, 2.19921875), *c[3] = { g, g, g };
	cmsHPROFILE p = cmsCreateRGBProfile(&wp, &pr, c);

	cmsFreeToneCurve(g);
	return p;
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, w, h, mx, off;
	size_t len, np, k;
	char *ppm = lb_read(argc > 1 ? argv[1] : "in.ppm", &len);
	unsigned char *rgb, *o8;
	unsigned short *i16, *o16;
	float *f;
	cmsHPROFILE srgb = cmsCreate_sRGBProfile(), ad = adobe(), lab = cmsCreateLab4Profile(NULL);
	cmsHTRANSFORM x;
	double t;

	if (sscanf(ppm, "P6 %d %d %d%n", &w, &h, &mx, &off) != 3)
		return 2;
	rgb = (unsigned char *)ppm + off + 1;
	np = (size_t)w * h;
	o8 = malloc(np * 3);
	i16 = malloc(np * 6);
	o16 = malloc(np * 6);
	f = malloc(np * 3 * sizeof(float));
	for (k = 0; k < np * 3; k++)
		i16[k] = (unsigned short)(rgb[k] * 257);

	x = cmsCreateTransform(srgb, TYPE_RGB_8, ad, TYPE_RGB_8, INTENT_PERCEPTUAL, 0);
	t = lb_now();
	for (i = 0; i < 8 * s; i++)
		cmsDoTransform(x, rgb, o8, (cmsUInt32Number)np);
	lb_out("sRGB to AdobeRGB 8 bits x8", t);
	cmsDeleteTransform(x);
	x = cmsCreateTransform(srgb, TYPE_RGB_16, ad, TYPE_RGB_16, INTENT_RELATIVE_COLORIMETRIC, 0);
	t = lb_now();
	for (i = 0; i < 2 * s; i++)
		cmsDoTransform(x, i16, o16, (cmsUInt32Number)np);
	lb_out("sRGB to AdobeRGB 16 bits x2", t);
	cmsDeleteTransform(x);
	x = cmsCreateTransform(srgb, TYPE_RGB_8, lab, TYPE_Lab_FLT, INTENT_PERCEPTUAL, 0);
	t = lb_now();
	for (i = 0; i < s; i++)
		cmsDoTransform(x, rgb, f, (cmsUInt32Number)(np / 3));
	lb_out("sRGB 8 bits to Lab float 1/3", t);
	cmsDeleteTransform(x);
	x = cmsCreateTransform(lab, TYPE_Lab_FLT, srgb, TYPE_RGB_16, INTENT_PERCEPTUAL, cmsFLAGS_NOOPTIMIZE);
	t = lb_now();
	for (i = 0; i < s; i++)
		cmsDoTransform(x, f, o16, (cmsUInt32Number)(np / 4));
	lb_out("Lab float to sRGB 16 bits unoptimized 1/4", t);
	cmsDeleteTransform(x);
	t = lb_now();
	for (i = 0; i < 300 * s; i++) {
		x = cmsCreateTransform(ad, TYPE_RGB_8, srgb, TYPE_RGB_8, INTENT_PERCEPTUAL, cmsFLAGS_HIGHRESPRECALC);
		cmsDeleteTransform(x);
	}
	lb_out("create transform high resolution x300", t);
	LB_KEEP(o8[3] + o16[3]);
	return 0;
}
