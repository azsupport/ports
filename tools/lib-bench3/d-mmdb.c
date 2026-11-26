/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-mmdb <db.mmdb> <ips> [<scale>]: libmaxminddb as mod_maxminddb uses it for every request:
 * lookup of the address and the values of the record (country, city)
 */
#include <maxminddb.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 3 ? atoi(argv[3]) : 1, i, gai, err;
	size_t len, nl, j;
	char *buf, **ip;
	MMDB_s db;
	MMDB_lookup_result_s r;
	MMDB_entry_data_s ed;
	MMDB_entry_data_list_s *dl;
	double t;

	if (argc < 3 || MMDB_open(argv[1], MMDB_MODE_MMAP, &db) != MMDB_SUCCESS)
		return 1;
	buf = lb_read(argv[2], &len);
	ip = lb_lines(buf, &nl);
	t = lb_now();
	for (i = 0; i < 40 * s; i++)
		for (j = 0; j < nl; j++) {
			r = MMDB_lookup_string(&db, ip[j], &gai, &err);
			LB_KEEP(r.found_entry);
		}
	lb_out("lookup x40", t);
	t = lb_now();
	for (i = 0; i < 20 * s; i++)
		for (j = 0; j < nl; j++) {
			r = MMDB_lookup_string(&db, ip[j], &gai, &err);
			if (!r.found_entry)
				continue;
			if (MMDB_get_value(&r.entry, &ed, "country", "iso_code", NULL) == MMDB_SUCCESS && ed.has_data)
				LB_KEEP(ed.data_size);
			if (MMDB_get_value(&r.entry, &ed, "city", "names", "en", NULL) == MMDB_SUCCESS && ed.has_data)
				LB_KEEP(ed.data_size);
			if (MMDB_get_value(&r.entry, &ed, "location", "latitude", NULL) == MMDB_SUCCESS && ed.has_data)
				LB_KEEP(ed.double_value);
		}
	lb_out("lookup and get country city location x20", t);
	t = lb_now();
	for (i = 0; i < 10 * s; i++)
		for (j = 0; j < nl; j++) {
			r = MMDB_lookup_string(&db, ip[j], &gai, &err);
			if (r.found_entry && MMDB_get_entry_data_list(&r.entry, &dl) == MMDB_SUCCESS) {
				LB_KEEP(dl != NULL);
				MMDB_free_entry_data_list(dl);
			}
		}
	lb_out("lookup and the whole record x10", t);
	MMDB_close(&db);
	return 0;
}
