/* SPDX-License-Identifier: BSD-2-Clause */
/* d-glib <text> [<scale>]: GLib and GObject, what libvips and the programs on GLib do most */
#include <glib.h>
#include <glib-object.h>
#include "lb.h"

static guint hits;
static void
on_sig(GObject *o, GParamSpec *p, gpointer d)
{
	(void)o;
	(void)p;
	(void)d;
	hits++;
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i, j;
	size_t len, nl;
	char *txt = lb_read(argc > 1 ? argv[1] : "text.txt", &len), *copy = g_strdup(txt), **lines;
	GHashTable *h;
	GString *gs;
	GVariantBuilder vb;
	GVariant *v;
	GBytes *bytes;
	GObject *o;
	gchar *x, **keys;
	double t;

	lines = lb_lines(copy, &nl);
	keys = g_new(gchar *, 200000);
	for (i = 0; i < 200000; i++)
		keys[i] = g_strdup_printf("key-%d-%s", i, lines[i % nl]);
	t = lb_now();
	for (j = 0; j < 4 * s; j++) {
		h = g_hash_table_new_full(g_str_hash, g_str_equal, NULL, NULL);
		for (i = 0; i < 200000; i++)
			g_hash_table_insert(h, keys[i], GINT_TO_POINTER(i));
		for (i = 0; i < 400000; i++)
			LB_KEEP(GPOINTER_TO_INT(g_hash_table_lookup(h, keys[(i * 7) % 200000])));
		for (i = 0; i < 200000; i += 2)
			g_hash_table_remove(h, keys[i]);
		g_hash_table_destroy(h);
	}
	lb_out("hash table insert lookup remove 4x200k", t);
	t = lb_now();
	for (j = 0; j < 20 * s; j++) {
		gs = g_string_sized_new(64);
		for (i = 0; i < 100000; i++) {
			g_string_append(gs, lines[i % nl]);
			g_string_append_printf(gs, " %d:%.2f;", i, i * 0.5);
		}
		LB_KEEP(gs->len);
		g_string_free(gs, TRUE);
	}
	lb_out("GString append printf 20x100k", t);
	t = lb_now();
	for (j = 0; j < 3 * s; j++) {
		LB_KEEP(g_utf8_validate(txt, (gssize)len, NULL));
		x = g_utf8_strdown(txt, (gssize)len);
		LB_KEEP(x[0]);
		g_free(x);
		x = g_utf8_casefold(txt, (gssize)len);
		g_free(x);
		LB_KEEP(g_utf8_strlen(txt, (gssize)len));
	}
	lb_out("utf8 validate strdown casefold strlen 3x", t);
	t = lb_now();
	for (j = 0; j < 300000 * s; j++) {
		x = g_utf8_normalize(lines[j % nl], -1, (j & 1) ? G_NORMALIZE_NFKC : G_NORMALIZE_NFC);
		LB_KEEP(x[0]);
		g_free(x);
	}
	lb_out("utf8 normalize NFC NFKC 300k lines", t);
	t = lb_now();
	for (j = 0; j < 2 * s; j++) {
		g_variant_builder_init(&vb, G_VARIANT_TYPE("a(sisd)"));
		for (i = 0; i < 50000; i++)
			g_variant_builder_add(&vb, "(sisd)", keys[i], i, "value", i * 0.25);
		v = g_variant_ref_sink(g_variant_builder_end(&vb));
		bytes = g_variant_get_data_as_bytes(v);
		g_variant_unref(v);
		v = g_variant_new_from_bytes(G_VARIANT_TYPE("a(sisd)"), bytes, FALSE);
		x = g_variant_print(v, FALSE);
		LB_KEEP(strlen(x));
		g_free(x);
		g_variant_unref(v);
		g_bytes_unref(bytes);
	}
	lb_out("GVariant build serialize print 2x50k", t);
	t = lb_now();
	for (j = 0; j < 24 * s; j++) {
		x = g_compute_checksum_for_data(G_CHECKSUM_SHA256, (const guchar *)txt, len);
		g_free(x);
	}
	lb_out("checksum sha256 24x", t);
	t = lb_now();
	for (i = 0; i < 1000000 * s; i++) {
		o = g_object_new(G_TYPE_BINDING_GROUP, NULL);
		g_signal_connect(o, "notify::source", G_CALLBACK(on_sig), NULL);
		g_object_notify(o, "source");
		g_object_unref(o);
	}
	LB_KEEP(hits);
	lb_out("GObject new connect notify unref 1M", t);
	t = lb_now();
	for (j = 0; j < 10 * s; j++) {
		gchar **parts = g_strsplit(txt, " ", -1);
		x = g_strjoinv(",", parts);
		LB_KEEP(strlen(x));
		g_free(x);
		g_strfreev(parts);
	}
	lb_out("strsplit strjoinv 10x", t);
	return 0;
}
