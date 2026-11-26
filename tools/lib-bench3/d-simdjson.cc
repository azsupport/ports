// SPDX-License-Identifier: BSD-2-Clause
// d-simdjson <file.json>... [-n <times>]: simdjson (Node.js), DOM parsing and On-Demand
// iteration of every value
#include <simdjson.h>
#include <cstring>
#include "lb.h"

using namespace simdjson;

static uint64_t
walk(dom::element e)
{
	uint64_t n = 1;

	switch (e.type()) {
	case dom::element_type::ARRAY:
		for (dom::element c : dom::array(e))
			n += walk(c);
		break;
	case dom::element_type::OBJECT:
		for (dom::key_value_pair kv : dom::object(e))
			n += kv.key.size() + walk(kv.value);
		break;
	default:
		break;
	}
	return n;
}

static uint64_t
od(ondemand::value v)
{
	uint64_t n = 1;

	switch (v.type()) {
	case ondemand::json_type::array:
		for (auto c : v.get_array())
			n += od(c.value());
		break;
	case ondemand::json_type::object:
		for (auto f : v.get_object())
			n += od(f.value());
		break;
	case ondemand::json_type::string:
		n += std::string_view(v.get_string()).size();
		break;
	case ondemand::json_type::number:
		n += (uint64_t)double(v.get_double());
		break;
	default:
		break;
	}
	return n;
}

int
main(int argc, char **argv)
{
	int times = 3000;

	for (int a = 1; a < argc; a++)
		if (std::strcmp(argv[a], "-n") == 0 && a + 1 < argc)
			times = std::atoi(argv[a + 1]);
	for (int a = 1; a < argc; a++) {
		if (std::strcmp(argv[a], "-n") == 0) {
			a++;
			continue;
		}
		const char *base = std::strrchr(argv[a], '/') ? std::strrchr(argv[a], '/') + 1 : argv[a];
		padded_string json = padded_string::load(argv[a]);
		dom::parser p;
		ondemand::parser op;
		char name[160];
		double t = lb_now();

		for (int i = 0; i < times; i++) {
			dom::element doc = p.parse(json);
			LB_KEEP(walk(doc));
		}
		std::snprintf(name, sizeof(name), "dom parse and walk %s x%d", base, times);
		lb_out(name, t);
		t = lb_now();
		for (int i = 0; i < times; i++) {
			ondemand::document d = op.iterate(json);
			LB_KEEP(od(d.get_value()));
		}
		std::snprintf(name, sizeof(name), "on-demand every value %s x%d", base, times);
		lb_out(name, t);
	}
	return 0;
}
