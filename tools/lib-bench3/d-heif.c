/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-heif <file.heic|avif>... [-n <times>]: libheif decoding to interleaved RGB (what
 * ImageMagick and vips ask of it): the container, the decoder plugin (libde265, dav1d: those
 * of the packages, the same for every variant) and the colour conversion of libheif
 */
#include <libheif/heif.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int n = 4, a, i;
	double t;

	for (a = 1; a < argc; a++)
		if (strcmp(argv[a], "-n") == 0 && a + 1 < argc)
			n = atoi(argv[a + 1]);
	for (a = 1; a < argc; a++) {
		char name[160];

		if (strcmp(argv[a], "-n") == 0) {
			a++;
			continue;
		}
		t = lb_now();
		for (i = 0; i < n; i++) {
			struct heif_context *c = heif_context_alloc();
			struct heif_image_handle *h;
			struct heif_image *im;
			struct heif_error e = heif_context_read_from_file(c, argv[a], NULL);
			int stride;

			if (e.code != heif_error_Ok || heif_context_get_primary_image_handle(c, &h).code != heif_error_Ok ||
			    heif_decode_image(h, &im, heif_colorspace_RGB, heif_chroma_interleaved_RGB, NULL).code !=
			    heif_error_Ok) {
				fprintf(stderr, "%s: cannot decode\n", argv[a]);
				return 1;
			}
			LB_KEEP(heif_image_get_plane_readonly(im, heif_channel_interleaved, &stride)[0]);
			heif_image_release(im);
			heif_image_handle_release(h);
			heif_context_free(c);
		}
		snprintf(name, sizeof(name), "decode to RGB %s x%d", strrchr(argv[a], '/') ? strrchr(argv[a], '/') + 1 :
		    argv[a], n);
		lb_out(name, t);
	}
	return 0;
}
