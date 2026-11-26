// SPDX-License-Identifier: BSD-2-Clause
// d-fmt [<scale>]: {fmt}, the formatting of integers, floats and strings
#include <fmt/format.h>
#include <cstdio>
#include <cstdlib>
#include <iterator>
#include <string>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? std::atoi(argv[1]) : 1;
	double t;
	std::string name = "user", out;
	fmt::memory_buffer buf;

	t = lb_now();
	for (int i = 0; i < 5000000 * s; i++) {
		out = fmt::format("{} {} {:x} {:>8} {}", i, i * 7919LL, (unsigned)i, name, -i);
		LB_KEEP(out.size());
	}
	lb_out("format ints and strings 5M", t);
	t = lb_now();
	for (int i = 0; i < 3000000 * s; i++) {
		buf.clear();
		fmt::format_to(std::back_inserter(buf), "{} {:.3f} {:e} {:g}", i * 0.731, i / 7.0, i * 1e-7, 1.0 / (i + 1));
		LB_KEEP(buf.size());
	}
	lb_out("format doubles 3M", t);
	t = lb_now();
	for (int i = 0; i < 10000000 * s; i++) {
		buf.clear();
		fmt::format_to(std::back_inserter(buf), "{}", i * 1234567LL);
		LB_KEEP(buf.size());
	}
	lb_out("format_to int 10M", t);
	t = lb_now();
	for (int i = 0; i < 3000000 * s; i++) {
		out = fmt::format("[{:<10}|{:^10}|{:>10}] {:08.2f} {:#b}", name, i % 1000, "x", i * 0.01, i & 255);
		LB_KEEP(out.size());
	}
	lb_out("format widths 3M", t);
	return 0;
}
