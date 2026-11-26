/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * lb.h - the helpers of the drivers of tools/lib-bench3.sh: a clock, the lines of
 * the results ("<benchmark> <seconds>", one a line, what the script records) and a
 * sink the compiler cannot drop.
 */
#ifndef LB_H
#define LB_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static inline double lb_now(void)
{
	struct timespec t;

	clock_gettime(CLOCK_MONOTONIC, &t);
	return (double)t.tv_sec + (double)t.tv_nsec * 1e-9;
}

/* the result of a benchmark: its name and the seconds since t0 */
static inline void lb_out(const char *name, double t0)
{
	printf("%s %.6f\n", name, lb_now() - t0);
	fflush(stdout);
}

static volatile uint64_t lb_sink;
#define LB_KEEP(x) (lb_sink += (uint64_t)(x))

/* lb_read <file> <size out>: the whole file, NUL-terminated */
static inline char *lb_read(const char *path, size_t *len)
{
	FILE *f = fopen(path, "rb");
	char *b;
	long n;

	if (f == NULL || fseek(f, 0, SEEK_END) != 0 || (n = ftell(f)) < 0) {
		fprintf(stderr, "cannot read %s\n", path);
		exit(2);
	}
	rewind(f);
	b = (char *)malloc((size_t)n + 1);
	if (b == NULL || fread(b, 1, (size_t)n, f) != (size_t)n) {
		fprintf(stderr, "cannot read %s\n", path);
		exit(2);
	}
	b[n] = '\0';
	fclose(f);
	if (len != NULL)
		*len = (size_t)n;
	return b;
}

/* lb_lines <buffer>: the lines of the buffer (it is changed: NUL for each \n) */
static inline char **lb_lines(char *b, size_t *count)
{
	size_t n = 0, cap = 1024;
	char **v = (char **)malloc(cap * sizeof(*v)), *p = b, *e;

	while (*p != '\0') {
		e = strchr(p, '\n');
		if (e != NULL)
			*e = '\0';
		if (*p != '\0') {
			if (n == cap)
				v = (char **)realloc(v, (cap *= 2) * sizeof(*v));
			v[n++] = p;
		}
		if (e == NULL)
			break;
		p = e + 1;
	}
	*count = n;
	return v;
}

/* a fixed pseudo-random sequence (xorshift64*) */
static uint64_t lb_seed = 88172645463325252ULL;
static inline uint64_t lb_rand(void)
{
	lb_seed ^= lb_seed >> 12;
	lb_seed ^= lb_seed << 25;
	lb_seed ^= lb_seed >> 27;
	return lb_seed * 2685821657736338717ULL;
}
#endif
