/* SPDX-License-Identifier: BSD-2-Clause */
/* d-ffi [<scale>]: libffi, the calls of PHP FFI and of Python ctypes */
#include <ffi.h>
#include "lb.h"

static double
f6(int a, double b, const char *c, long d, float e, int f)
{
	return a + b + c[0] + d + e + f;
}

static void
handler(ffi_cif *cif, void *ret, void **args, void *ud)
{
	(void)cif;
	(void)ud;
	*(ffi_arg *)ret = (ffi_arg)(*(int *)args[0] + *(int *)args[1]);
}

typedef struct { double x, y, z; int n; } vec;
static vec
fs(vec a, vec b)
{
	vec r = { a.x + b.x, a.y + b.y, a.z + b.z, a.n + b.n };
	return r;
}

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, ia = 1, ifl = 6, x, y;
	ffi_cif cif, cif2, cif3;
	ffi_type *at[6] = { &ffi_type_sint, &ffi_type_double, &ffi_type_pointer, &ffi_type_slong,
		&ffi_type_float, &ffi_type_sint };
	ffi_type *at2[2] = { &ffi_type_sint, &ffi_type_sint };
	ffi_type *el[5] = { &ffi_type_double, &ffi_type_double, &ffi_type_double, &ffi_type_sint, NULL };
	ffi_type st = { 0, 0, FFI_TYPE_STRUCT, el };
	ffi_type *at3[2] = { &st, &st };
	double b = 2.5, rv;
	const char *c = "x";
	long d = 4;
	float e = 0.5f;
	void *av[6] = { &ia, &b, &c, &d, &e, &ifl };
	void *code, *av2[2] = { &x, &y };
	ffi_closure *cl;
	ffi_arg r2;
	int (*fp)(int, int);
	vec va = { 1, 2, 3, 4 }, vb = { 5, 6, 7, 8 }, vr;
	void *av3[2] = { &va, &vb };
	double t;

	if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 6, &ffi_type_double, at) != FFI_OK)
		return 1;
	t = lb_now();
	for (i = 0; i < 10000000 * s; i++) {
		ia = i;
		ffi_call(&cif, FFI_FN(f6), &rv, av);
		LB_KEEP(rv);
	}
	lb_out("ffi_call 6 args 10M", t);
	if (ffi_prep_cif(&cif3, FFI_DEFAULT_ABI, 2, &st, at3) != FFI_OK)
		return 1;
	t = lb_now();
	for (i = 0; i < 10000000 * s; i++) {
		va.n = i;
		ffi_call(&cif3, FFI_FN(fs), &vr, av3);
		LB_KEEP(vr.n);
	}
	lb_out("ffi_call struct by value 10M", t);
	cl = ffi_closure_alloc(sizeof(ffi_closure), &code);
	if (cl == NULL || ffi_prep_cif(&cif2, FFI_DEFAULT_ABI, 2, &ffi_type_sint, at2) != FFI_OK ||
	    ffi_prep_closure_loc(cl, &cif2, handler, NULL, code) != FFI_OK)
		return 1;
	fp = (int (*)(int, int))code;
	t = lb_now();
	for (i = 0; i < 20000000 * s; i++)
		LB_KEEP(fp(i, 3));
	lb_out("closure call 20M", t);
	t = lb_now();
	for (i = 0; i < 15000000 * s; i++) {
		x = i;
		y = 2;
		ffi_call(&cif2, code, &r2, av2);
		LB_KEEP(r2);
	}
	lb_out("ffi_call of a closure 15M", t);
	t = lb_now();
	for (i = 0; i < 15000000 * s; i++)
		LB_KEEP(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 6, &ffi_type_double, at));
	lb_out("ffi_prep_cif 15M", t);
	ffi_closure_free(cl);
	return 0;
}
