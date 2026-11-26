/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-cairo [<scale>]: cairo drawing into an image surface (what librsvg and pango have
 * it do): filled polygons, stroked curves, gradient arcs; the compositing is pixman's
 */
#include <cairo.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, j;
	cairo_surface_t *sf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1600, 1200);
	cairo_t *cr = cairo_create(sf);
	cairo_pattern_t *g;
	double t;

	cairo_set_antialias(cr, CAIRO_ANTIALIAS_DEFAULT);
	t = lb_now();
	for (i = 0; i < 15000 * s; i++) {
		double cx = lb_rand() % 1400, cy = lb_rand() % 1000;

		cairo_new_path(cr);
		cairo_move_to(cr, cx + lb_rand() % 200, cy + lb_rand() % 200);
		for (j = 0; j < 8; j++)
			cairo_line_to(cr, cx + lb_rand() % 200, cy + lb_rand() % 200);
		cairo_close_path(cr);
		cairo_set_source_rgba(cr, (i & 255) / 255.0, 0.5, 0.25, 0.7);
		cairo_fill(cr);
	}
	lb_out("fill polygons of 9 points in 200x200 15k", t);
	cairo_set_line_width(cr, 3);
	cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);
	cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
	t = lb_now();
	for (i = 0; i < 15000 * s; i++) {
		double x = lb_rand() % 1600, y = lb_rand() % 1200;

		cairo_new_path(cr);
		cairo_move_to(cr, x, y);
		cairo_curve_to(cr, x + 80, y - 60, x + 120, y + 90, x + 200, y + 10);
		cairo_curve_to(cr, x + 260, y - 40, x + 300, y + 70, x + 340, y);
		cairo_set_source_rgba(cr, 0.1, (i & 255) / 255.0, 0.6, 0.8);
		cairo_stroke(cr);
	}
	lb_out("stroke curves 15k", t);
	g = cairo_pattern_create_linear(0, 0, 1600, 1200);
	cairo_pattern_add_color_stop_rgba(g, 0, 1, 0, 0, 0.8);
	cairo_pattern_add_color_stop_rgba(g, 0.5, 0, 1, 0, 0.5);
	cairo_pattern_add_color_stop_rgba(g, 1, 0, 0, 1, 0.8);
	t = lb_now();
	for (i = 0; i < 10000 * s; i++) {
		cairo_new_path(cr);
		cairo_arc(cr, lb_rand() % 1600, lb_rand() % 1200, 10 + lb_rand() % 60, 0, 6.2831853);
		cairo_set_source(cr, g);
		cairo_fill(cr);
	}
	lb_out("gradient arcs 10k", t);
	cairo_pattern_destroy(g);
	cairo_surface_flush(sf);
	LB_KEEP(cairo_image_surface_get_data(sf)[1000]);
	cairo_destroy(cr);
	cairo_surface_destroy(sf);
	return 0;
}
