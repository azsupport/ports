/*
 * lib-bench.c - the drivers of tools/lib-bench.sh for two libraries of the package
 * az that PHP loads only through imagick and gmagick: expat (fontconfig reads its
 * configuration with it, once per process) and lcms2 (the colour profiles of
 * ImageMagick and GraphicsMagick, also in their static programs). Built once, with
 * the base cc, against the libraries of az; the variants of a library are then put
 * in front of it with LD_LIBRARY_PATH, as for PHP.
 *
 *   cc -O2 -DLB_EXPAT -o lb-expat lib-bench.c -lexpat          lb-expat <n> <file.xml>
 *   cc -O2 -DLB_LCMS2 -o lb-lcms2 lib-bench.c -llcms2 -lm      lb-lcms2 <n>
 *
 * The work is done once, not timed, then <n> times; printed: "time <seconds>" of
 * those, "check <value>" (a digest of the result) and "lib <path>" (the file of the
 * library the work ran in, dladdr(3) of one of its functions).
 */
#define _GNU_SOURCE	/* dladdr of glibc (--local); FreeBSD has it anyway */
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double now(void)
{
	struct timespec ts;

	clock_gettime(CLOCK_MONOTONIC, &ts);
	return ts.tv_sec + ts.tv_nsec / 1e9;
}

static void lib_of(void *fn)
{
	Dl_info di;

	if (dladdr(fn, &di) != 0 && di.dli_fname != NULL)
		printf("lib %s\n", di.dli_fname);
	else
		printf("lib ?\n");
}

static int iterations(int argc, char **argv, int need)
{
	int n;

	if (argc != need || (n = atoi(argv[1])) < 1) {
		fprintf(stderr, "usage: %s <n>%s\n", argv[0], need == 3 ? " <file.xml>" : "");
		exit(2);
	}
	return n;
}

#if defined(LB_EXPAT)
#include <expat.h>

struct count {
	unsigned long elems, attrs, chars;
};

static void XMLCALL on_start(void *ud, const XML_Char *name, const XML_Char **atts)
{
	struct count *c = ud;

	(void)name;
	c->elems++;
	for (; *atts != NULL; atts += 2)
		c->attrs++;
}

static void XMLCALL on_end(void *ud, const XML_Char *name)
{
	(void)ud;
	(void)name;
}

static void XMLCALL on_text(void *ud, const XML_Char *s, int len)
{
	(void)s;
	((struct count *)ud)->chars += (unsigned long)len;
}

static void parse(const char *buf, size_t len, struct count *c)
{
	XML_Parser p = XML_ParserCreate("UTF-8");

	memset(c, 0, sizeof(*c));
	XML_SetUserData(p, c);
	XML_SetElementHandler(p, on_start, on_end);
	XML_SetCharacterDataHandler(p, on_text);
	if (XML_Parse(p, buf, (int)len, 1) != XML_STATUS_OK) {
		fprintf(stderr, "lb-expat: line %lu: %s\n", (unsigned long)XML_GetCurrentLineNumber(p),
		    XML_ErrorString(XML_GetErrorCode(p)));
		exit(1);
	}
	XML_ParserFree(p);
}

int main(int argc, char **argv)
{
	int n = iterations(argc, argv, 3);
	FILE *f = fopen(argv[2], "rb");
	char *buf;
	long len;
	struct count c;
	double t;

	if (f == NULL || fseek(f, 0, SEEK_END) != 0 || (len = ftell(f)) <= 0 || fseek(f, 0, SEEK_SET) != 0 ||
	    (buf = malloc((size_t)len)) == NULL || fread(buf, 1, (size_t)len, f) != (size_t)len) {
		fprintf(stderr, "lb-expat: cannot read %s\n", argv[2]);
		return 1;
	}
	fclose(f);
	parse(buf, (size_t)len, &c);
	t = now();
	for (int i = 0; i < n; i++)
		parse(buf, (size_t)len, &c);
	printf("time %.6f\ncheck %lu-%lu-%lu\n", now() - t, c.elems, c.attrs, c.chars);
	lib_of((void *)XML_ParserCreate);
	free(buf);
	return 0;
}

#elif defined(LB_LCMS2)
#include <lcms2.h>

#define W 1600
#define H 1200

/*
 * What a colour conversion of an image does: a transform made for the pair of
 * profiles (ImageMagick makes one per image), then the pixels. sRGB to an RGB space
 * of other primaries and gamma (as an embedded Adobe RGB profile) in 8 and 16
 * bits, and to Lab in floating point.
 */
static unsigned long work(cmsHPROFILE srgb, cmsHPROFILE wide, cmsHPROFILE lab, const uint8_t *in8,
    uint8_t *out8, const uint16_t *in16, uint16_t *out16, float *outlab)
{
	cmsHTRANSFORM t;
	unsigned long sum = 0;
	size_t i;

	t = cmsCreateTransform(srgb, TYPE_RGB_8, wide, TYPE_RGB_8, INTENT_PERCEPTUAL, 0);
	cmsDoTransform(t, in8, out8, W * H);
	cmsDeleteTransform(t);
	t = cmsCreateTransform(wide, TYPE_RGB_16, srgb, TYPE_RGB_16, INTENT_RELATIVE_COLORIMETRIC,
	    cmsFLAGS_BLACKPOINTCOMPENSATION);
	cmsDoTransform(t, in16, out16, W * H);
	cmsDeleteTransform(t);
	t = cmsCreateTransform(srgb, TYPE_RGB_8, lab, TYPE_Lab_FLT, INTENT_PERCEPTUAL, 0);
	cmsDoTransform(t, in8, outlab, W * H / 4);
	cmsDeleteTransform(t);
	for (i = 0; i < (size_t)W * H * 3; i += 97)
		sum += out8[i] + out16[i] / 256;
	for (i = 0; i < (size_t)W * H / 4 * 3; i += 101)
		sum += (unsigned long)(outlab[i] + 200.0f);
	return sum;
}

int main(int argc, char **argv)
{
	int n = iterations(argc, argv, 2);
	cmsCIExyY d65 = { 0.3127, 0.3290, 1.0 };
	cmsCIExyYTRIPLE adobe = { { 0.64, 0.33, 1.0 }, { 0.21, 0.71, 1.0 }, { 0.15, 0.06, 1.0 } };
	cmsToneCurve *g, *curves[3];
	cmsHPROFILE srgb, wide, lab;
	uint8_t *in8 = malloc((size_t)W * H * 3), *out8 = malloc((size_t)W * H * 3);
	uint16_t *in16 = malloc((size_t)W * H * 3 * 2), *out16 = malloc((size_t)W * H * 3 * 2);
	float *outlab = malloc((size_t)W * H / 4 * 3 * sizeof(float));
	uint32_t x = 20261109;
	unsigned long sum = 0;
	double t;

	if (in8 == NULL || out8 == NULL || in16 == NULL || out16 == NULL || outlab == NULL) {
		fprintf(stderr, "lb-lcms2: out of memory\n");
		return 1;
	}
	/* an image of smooth gradients with some noise, the same every time */
	for (size_t y = 0; y < H; y++)
		for (size_t i = 0; i < W * 3; i++) {
			x = x * 1103515245u + 12345u;
			in8[y * W * 3 + i] = (uint8_t)((i * 255 / (W * 3) + y * 255 / H) / 2 + (x >> 28));
			in16[y * W * 3 + i] = (uint16_t)(in8[y * W * 3 + i] * 257 + (x >> 24));
		}
	g = cmsBuildGamma(NULL, 2.19921875);
	curves[0] = curves[1] = curves[2] = g;
	srgb = cmsCreate_sRGBProfile();
	wide = cmsCreateRGBProfile(&d65, &adobe, curves);
	lab = cmsCreateLab4Profile(NULL);
	if (g == NULL || srgb == NULL || wide == NULL || lab == NULL) {
		fprintf(stderr, "lb-lcms2: cannot make the profiles\n");
		return 1;
	}
	work(srgb, wide, lab, in8, out8, in16, out16, outlab);
	t = now();
	for (int i = 0; i < n; i++)
		sum = work(srgb, wide, lab, in8, out8, in16, out16, outlab);
	printf("time %.6f\ncheck %lu\n", now() - t, sum);
	lib_of((void *)cmsCreateTransform);
	return 0;
}

#else
#error "build with -DLB_EXPAT or -DLB_LCMS2"
#endif
