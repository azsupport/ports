/* SPDX-License-Identifier: BSD-2-Clause */
/* d-llhttp <requests> [<scale>]: llhttp (the HTTP parser of Node.js): pipelined requests */
#include <llhttp.h>
#include "lb.h"

static uint64_t cnt;
static int
on_data(llhttp_t *p, const char *at, size_t len)
{
	(void)p;
	(void)at;
	cnt += len;
	return 0;
}
static int
on_done(llhttp_t *p)
{
	(void)p;
	cnt++;
	return 0;
}

int
main(int argc, char **argv)
{
	int s = argc > 2 ? atoi(argv[2]) : 1, i;
	size_t len;
	char *buf = lb_read(argc > 1 ? argv[1] : "requests.txt", &len);
	llhttp_t p;
	llhttp_settings_t st, st0;
	double t;

	llhttp_settings_init(&st);
	st.on_url = on_data;
	st.on_header_field = on_data;
	st.on_header_value = on_data;
	st.on_body = on_data;
	st.on_message_complete = on_done;
	llhttp_settings_init(&st0);
	t = lb_now();
	for (i = 0; i < 40 * s; i++) {
		llhttp_init(&p, HTTP_REQUEST, &st);
		if (llhttp_execute(&p, buf, len) != HPE_OK) {
			fprintf(stderr, "parse error: %s\n", llhttp_errno_name(llhttp_get_errno(&p)));
			return 1;
		}
	}
	LB_KEEP(cnt);
	lb_out("parse with callbacks x40", t);
	t = lb_now();
	for (i = 0; i < 40 * s; i++) {
		llhttp_init(&p, HTTP_REQUEST, &st0);
		if (llhttp_execute(&p, buf, len) != HPE_OK)
			return 1;
	}
	lb_out("parse without callbacks x40", t);
	return 0;
}
