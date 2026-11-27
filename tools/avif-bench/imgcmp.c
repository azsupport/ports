/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * imgcmp - two PNGs of the same size, 8-bit RGB after decoding (libpng, the simplified
 * API; the PNGs of tools/avif-bench.sh carry no gAMA, cHRM, sRGB or iCCP chunk, so it
 * converts nothing): imgcmp <reference.png> <test.png>. One line on stdout:
 *   <max abs diff>\t<differing samples>\t<PSNR RGB dB>\t<PSNR Y dB>\t<SSIM Y>
 * PSNR RGB: the mean squared error of all samples of R, G and B; Y: the luma of BT.601
 * (0.299 R + 0.587 G + 0.114 B), unrounded; SSIM: of Y, Wang et al. 2004, an 11x11
 * Gaussian window of sigma 1.5, K1 0.01, K2 0.03, L 255, the mean over the window positions
 * inside the image. "inf" for the PSNR of the same pixels.
 */
#include <math.h>
#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned char *
load(const char *path, png_uint_32 *w, png_uint_32 *h)
{
	png_image p;
	unsigned char *b;

	memset(&p, 0, sizeof(p));
	p.version = PNG_IMAGE_VERSION;
	if (!png_image_begin_read_from_file(&p, path)) {
		fprintf(stderr, "imgcmp: %s: %s\n", path, p.message);
		return NULL;
	}
	p.format = PNG_FORMAT_RGB;
	b = malloc(PNG_IMAGE_SIZE(p));
	if (b == NULL || !png_image_finish_read(&p, NULL, b, 0, NULL)) {
		fprintf(stderr, "imgcmp: %s: %s\n", path, p.message);
		return NULL;
	}
	*w = p.width;
	*h = p.height;
	return b;
}

/* a separable Gaussian blur of src (w x h) into dst, the valid part only ((w-10) x (h-10)) */
static void
blur(const double *src, double *tmp, double *dst, int w, int h, const double *k)
{
	int x, y, i, ow = w - 10, oh = h - 10;

	for (y = 0; y < h; y++)
		for (x = 0; x < ow; x++) {
			double s = 0;

			for (i = 0; i < 11; i++)
				s += k[i] * src[(size_t)y * w + x + i];
			tmp[(size_t)y * ow + x] = s;
		}
	for (y = 0; y < oh; y++)
		for (x = 0; x < ow; x++) {
			double s = 0;

			for (i = 0; i < 11; i++)
				s += k[i] * tmp[(size_t)(y + i) * ow + x];
			dst[(size_t)y * ow + x] = s;
		}
}

int
main(int argc, char **argv)
{
	png_uint_32 w1, h1, w2, h2;
	unsigned char *a, *b;
	size_t n, i, ndiff = 0;
	int maxd = 0;
	double se = 0, sey = 0, k[11], ks = 0, ssim = 0;

	if (argc != 3) {
		fprintf(stderr, "usage: imgcmp <reference.png> <test.png>\n");
		return 2;
	}
	if ((a = load(argv[1], &w1, &h1)) == NULL || (b = load(argv[2], &w2, &h2)) == NULL)
		return 1;
	if (w1 != w2 || h1 != h2) {
		fprintf(stderr, "imgcmp: %ux%u against %ux%u\n", w1, h1, w2, h2);
		return 1;
	}
	n = (size_t)w1 * h1;
	{
		double *ya = malloc(n * sizeof(double)), *yb = malloc(n * sizeof(double));
		double *t = malloc(n * sizeof(double)), *p = malloc(n * sizeof(double));
		double *ma, *mb, *saa, *sbb, *sab;
		int W = (int)w1, H = (int)h1, ow = W - 10, oh = H - 10;
		size_t on;

		if (ya == NULL || yb == NULL || t == NULL || p == NULL)
			return 1;
		for (i = 0; i < n; i++) {
			int c;

			for (c = 0; c < 3; c++) {
				int d = (int)a[i * 3 + c] - (int)b[i * 3 + c];

				if (d < 0)
					d = -d;
				if (d > maxd)
					maxd = d;
				if (d)
					ndiff++;
				se += (double)d * d;
			}
			ya[i] = 0.299 * a[i * 3] + 0.587 * a[i * 3 + 1] + 0.114 * a[i * 3 + 2];
			yb[i] = 0.299 * b[i * 3] + 0.587 * b[i * 3 + 1] + 0.114 * b[i * 3 + 2];
			sey += (ya[i] - yb[i]) * (ya[i] - yb[i]);
		}
		if (ow < 1 || oh < 1) {
			fprintf(stderr, "imgcmp: smaller than the SSIM window\n");
			return 1;
		}
		for (i = 0; i < 11; i++) {
			double x = (double)i - 5;

			k[i] = exp(-x * x / (2 * 1.5 * 1.5));
			ks += k[i];
		}
		for (i = 0; i < 11; i++)
			k[i] /= ks;
		on = (size_t)ow * oh;
		ma = malloc(on * sizeof(double));
		mb = malloc(on * sizeof(double));
		saa = malloc(on * sizeof(double));
		sbb = malloc(on * sizeof(double));
		sab = malloc(on * sizeof(double));
		if (ma == NULL || mb == NULL || saa == NULL || sbb == NULL || sab == NULL)
			return 1;
		blur(ya, t, ma, W, H, k);
		blur(yb, t, mb, W, H, k);
		for (i = 0; i < n; i++)
			p[i] = ya[i] * ya[i];
		blur(p, t, saa, W, H, k);
		for (i = 0; i < n; i++)
			p[i] = yb[i] * yb[i];
		blur(p, t, sbb, W, H, k);
		for (i = 0; i < n; i++)
			p[i] = ya[i] * yb[i];
		blur(p, t, sab, W, H, k);
		{
			const double c1 = (0.01 * 255) * (0.01 * 255), c2 = (0.03 * 255) * (0.03 * 255);

			for (i = 0; i < on; i++) {
				double va = saa[i] - ma[i] * ma[i], vb = sbb[i] - mb[i] * mb[i];
				double cov = sab[i] - ma[i] * mb[i];

				ssim += ((2 * ma[i] * mb[i] + c1) * (2 * cov + c2)) /
				    ((ma[i] * ma[i] + mb[i] * mb[i] + c1) * (va + vb + c2));
			}
			ssim /= (double)on;
		}
	}
	printf("%d\t%zu\t", maxd, ndiff);
	if (se == 0)
		printf("inf\t");
	else
		printf("%.4f\t", 10 * log10(255.0 * 255.0 * 3 * (double)n / se));
	if (sey == 0)
		printf("inf\t");
	else
		printf("%.4f\t", 10 * log10(255.0 * 255.0 * (double)n / sey));
	printf("%.6f\n", ssim);
	return 0;
}
