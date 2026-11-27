/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * heifbench - an AVIF of a PNG, written through libheif the way heifsave of libvips 8.18
 * (libvips/foreign/heifsave.c) writes it, timed in the process:
 *
 *   heifbench <in.png> <out.avif> <svt|aom> <Q 0-100 | lossless> <rounds> [<name>=<value> ...]
 *
 * Each round, as one save of heifsave: a new context; the encoder of that id
 * (heif_context_get_encoder_descriptors with the name, as heifsave with "encoder"); the lossy
 * quality and the lossless flag; the parameters of the command line in their order, one the
 * encoder does not have skipped, as heifsave skips it (the "chroma", "auto-tiles" and
 * "enable-intrabc" of heifsave are no parameters of the encoder of SVT-AV1); an RGB image of
 * 8 bits, interleaved; heif_context_encode_image() with the default options (lossless: the
 * nclx profile of heifsave, matrix coefficients 0, identity); the file written into memory.
 * The file of the last round goes to <out.avif>. A line per round on stdout:
 *   <round>\t<bytes>\t<wall microseconds>\t<cpu microseconds>
 * cpu: user and system time of the process (all its threads) over the round.
 */
#include <sys/types.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <libheif/heif.h>

struct buf {
	unsigned char *p;
	size_t n, cap;
};

static struct heif_error
buf_write(struct heif_context *ctx, const void *data, size_t size, void *user)
{
	struct buf *b = user;
	struct heif_error ok = { heif_error_Ok, heif_suberror_Unspecified, "ok" };
	struct heif_error bad = { heif_error_Encoding_error, heif_suberror_Cannot_write_output_data, "out of memory" };

	(void)ctx;
	if (b->n + size > b->cap) {
		size_t cap = (b->n + size) * 2;
		unsigned char *p = realloc(b->p, cap);

		if (p == NULL)
			return bad;
		b->p = p;
		b->cap = cap;
	}
	memcpy(b->p + b->n, data, size);
	b->n += size;
	return ok;
}

static long long
usec_wall(void)
{
	struct timespec t;

	clock_gettime(CLOCK_MONOTONIC, &t);
	return (long long)t.tv_sec * 1000000 + t.tv_nsec / 1000;
}

static long long
usec_cpu(void)
{
	struct rusage r;

	getrusage(RUSAGE_SELF, &r);
	return ((long long)r.ru_utime.tv_sec + r.ru_stime.tv_sec) * 1000000 +
	    r.ru_utime.tv_usec + r.ru_stime.tv_usec;
}

static int
fail(const char *what, struct heif_error e)
{
	fprintf(stderr, "heifbench: %s: %s (%d/%d)\n", what, e.message, e.code, e.subcode);
	return 1;
}

int
main(int argc, char **argv)
{
	png_image png;
	unsigned char *rgb;
	struct buf b = { NULL, 0, 0 };
	const char *in, *out, *codec;
	int q, lossless, rounds, r, i, skipped_told = 0;
	FILE *f;

	if (argc < 6) {
		fprintf(stderr, "usage: heifbench <in.png> <out.avif> <svt|aom> <Q|lossless> <rounds> [name=value ...]\n");
		return 2;
	}
	in = argv[1];
	out = argv[2];
	codec = argv[3];
	lossless = strcmp(argv[4], "lossless") == 0;
	q = lossless ? 100 : atoi(argv[4]);
	rounds = atoi(argv[5]);
	if (rounds < 1 || q < 0 || q > 100) {
		fprintf(stderr, "heifbench: bad Q or rounds\n");
		return 2;
	}

	memset(&png, 0, sizeof(png));
	png.version = PNG_IMAGE_VERSION;
	if (!png_image_begin_read_from_file(&png, in)) {
		fprintf(stderr, "heifbench: %s: %s\n", in, png.message);
		return 1;
	}
	png.format = PNG_FORMAT_RGB;
	rgb = malloc(PNG_IMAGE_SIZE(png));
	if (rgb == NULL || !png_image_finish_read(&png, NULL, rgb, 0, NULL)) {
		fprintf(stderr, "heifbench: %s: %s\n", in, png.message);
		return 1;
	}

	heif_init(NULL);
	for (r = 1; r <= rounds; r++) {
		struct heif_context *ctx;
		const struct heif_encoder_descriptor *d[1];
		struct heif_encoder *enc;
		struct heif_image *img;
		struct heif_image_handle *h;
		struct heif_encoding_options *opt;
		struct heif_color_profile_nclx *nclx = NULL;
		struct heif_writer w;
		struct heif_error e;
		unsigned char *plane;
		int stride, y;
		long long w0, c0, w1, c1;

		b.n = 0;
		w0 = usec_wall();
		c0 = usec_cpu();
		ctx = heif_context_alloc();
		if (heif_context_get_encoder_descriptors(ctx, heif_compression_AV1, codec, d, 1) < 1) {
			fprintf(stderr, "heifbench: no AV1 encoder %s in this libheif\n", codec);
			return 1;
		}
		e = heif_context_get_encoder(ctx, d[0], &enc);
		if (e.code)
			return fail("encoder", e);
		e = heif_encoder_set_lossy_quality(enc, q);
		if (e.code)
			return fail("quality", e);
		e = heif_encoder_set_lossless(enc, lossless);
		if (e.code)
			return fail("lossless", e);
		for (i = 6; i < argc; i++) {
			char name[64];
			const char *eq = strchr(argv[i], '=');

			if (eq == NULL || (size_t)(eq - argv[i]) >= sizeof(name)) {
				fprintf(stderr, "heifbench: bad parameter %s\n", argv[i]);
				return 2;
			}
			memcpy(name, argv[i], eq - argv[i]);
			name[eq - argv[i]] = '\0';
			e = heif_encoder_set_parameter(enc, name, eq + 1);
			if (e.code && e.subcode == heif_suberror_Unsupported_parameter) {
				if (!skipped_told)
					fprintf(stderr, "heifbench: %s: no parameter %s, skipped (as heifsave)\n", codec, name);
				continue;
			}
			if (e.code)
				return fail(argv[i], e);
		}
		skipped_told = 1;

		e = heif_image_create((int)png.width, (int)png.height, heif_colorspace_RGB,
		    heif_chroma_interleaved_RGB, &img);
		if (e.code)
			return fail("image", e);
		e = heif_image_add_plane(img, heif_channel_interleaved, (int)png.width, (int)png.height, 8);
		if (e.code)
			return fail("plane", e);
		plane = heif_image_get_plane(img, heif_channel_interleaved, &stride);
		for (y = 0; y < (int)png.height; y++)
			memcpy(plane + (size_t)y * stride, rgb + (size_t)y * png.width * 3, (size_t)png.width * 3);

		opt = heif_encoding_options_alloc();
		opt->save_alpha_channel = 0;
		if (lossless) {
			nclx = heif_nclx_color_profile_alloc();
			nclx->matrix_coefficients = heif_matrix_coefficients_RGB_GBR;
			opt->output_nclx_profile = nclx;
			opt->macOS_compatibility_workaround_no_nclx_profile = 0;
		}
		opt->image_orientation = heif_orientation_normal;
		e = heif_context_encode_image(ctx, img, enc, opt, &h);
		if (e.code)
			return fail("encode", e);
		w.writer_api_version = 1;
		w.write = buf_write;
		e = heif_context_write(ctx, &w, &b);
		if (e.code)
			return fail("write", e);
		heif_image_handle_release(h);
		heif_encoding_options_free(opt);
		if (nclx != NULL)
			heif_nclx_color_profile_free(nclx);
		heif_image_release(img);
		heif_encoder_release(enc);
		heif_context_free(ctx);
		w1 = usec_wall();
		c1 = usec_cpu();
		printf("%d\t%zu\t%lld\t%lld\n", r, b.n, w1 - w0, c1 - c0);
	}
	heif_deinit();

	f = fopen(out, "wb");
	if (f == NULL || fwrite(b.p, 1, b.n, f) != b.n || fclose(f) != 0) {
		perror(out);
		return 1;
	}
	return 0;
}
