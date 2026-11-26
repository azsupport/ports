// SPDX-License-Identifier: BSD-2-Clause
// d-ada <urls> [<scale>]: ada (the WHATWG URL parser of Node.js): parse, the parts, changes
#include <ada.h>
#include <cstdlib>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 2 ? std::atoi(argv[2]) : 1;
	size_t len, nl;
	char *buf = lb_read(argc > 1 ? argv[1] : "urls.txt", &len), **u = lb_lines(buf, &nl);
	double t;

	t = lb_now();
	for (int i = 0; i < 16 * s; i++)
		for (size_t j = 0; j < nl; j++) {
			auto url = ada::parse<ada::url_aggregator>(u[j]);
			if (!url)
				continue;
			LB_KEEP(url->get_hostname().size() + url->get_pathname().size() + url->get_search().size());
		}
	lb_out("parse url_aggregator and parts x16", t);
	t = lb_now();
	for (int i = 0; i < 10 * s; i++)
		for (size_t j = 0; j < nl; j++) {
			auto url = ada::parse<ada::url>(u[j]);
			if (!url)
				continue;
			LB_KEEP(url->get_href().size());
		}
	lb_out("parse url and href x10", t);
	t = lb_now();
	for (int i = 0; i < 6 * s; i++)
		for (size_t j = 0; j < nl; j++) {
			auto url = ada::parse<ada::url_aggregator>(u[j]);
			if (!url)
				continue;
			url->set_pathname("/new/path/index.php");
			url->set_search("?id=42&q=%D0%BF");
			url->set_hash("#top");
			LB_KEEP(url->get_href().size());
		}
	lb_out("parse and set path query hash x6", t);
	t = lb_now();
	for (int i = 0; i < 16 * s; i++)
		for (size_t j = 0; j < nl; j++)
			LB_KEEP(ada::can_parse(u[j]));
	lb_out("can_parse x16", t);
	return 0;
}
