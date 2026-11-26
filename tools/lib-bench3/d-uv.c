/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-uv [<scale>]: libuv (Node.js, BIND tools): the event loop itself, without the network:
 * idle ticks, timers, many handles per iteration, synchronous file stat, and work of the
 * thread pool
 */
#include <uv.h>
#include "lb.h"

static uint64_t ticks, limit;
static void
on_idle(uv_idle_t *h)
{
	if (++ticks >= limit)
		uv_idle_stop(h);
}

static uint64_t fired;
static void
on_timer(uv_timer_t *t)
{
	(void)t;
	fired++;
}

static void
on_prepare(uv_prepare_t *h)
{
	(void)h;
	fired++;
}
static void
on_check(uv_check_t *h)
{
	(void)h;
	fired++;
}
static void
on_idle2(uv_idle_t *h)
{
	(void)h;
	fired++;
}
static void
work(uv_work_t *w)
{
	LB_KEEP(w->data);
}
static void
done(uv_work_t *w, int st)
{
	(void)w;
	(void)st;
	fired++;
}

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, n;
	uv_loop_t *l = uv_default_loop();
	uv_idle_t idle;
	uv_timer_t *tm;
	uv_prepare_t *pr;
	uv_check_t *ck;
	uv_idle_t *id;
	uv_fs_t req;
	uv_work_t *wk;
	double t;

	limit = 6000000ULL * (uint64_t)s;
	uv_idle_init(l, &idle);
	uv_idle_start(&idle, on_idle);
	t = lb_now();
	uv_run(l, UV_RUN_DEFAULT);
	lb_out("idle ticks 6M", t);
	n = 500000 * s;
	tm = malloc((size_t)n * sizeof(*tm));
	t = lb_now();
	for (i = 0; i < n; i++) {
		uv_timer_init(l, &tm[i]);
		uv_timer_start(&tm[i], on_timer, (uint64_t)(i % 50), 0);
	}
	uv_run(l, UV_RUN_DEFAULT);
	for (i = 0; i < n; i++)
		uv_close((uv_handle_t *)&tm[i], NULL);
	uv_run(l, UV_RUN_DEFAULT);
	lb_out("timers 500k (start, run, close)", t);
	pr = malloc(1000 * sizeof(*pr));
	ck = malloc(1000 * sizeof(*ck));
	id = malloc(1000 * sizeof(*id));
	for (i = 0; i < 1000; i++) {
		uv_prepare_init(l, &pr[i]);
		uv_prepare_start(&pr[i], on_prepare);
		uv_check_init(l, &ck[i]);
		uv_check_start(&ck[i], on_check);
		uv_idle_init(l, &id[i]);
		uv_idle_start(&id[i], on_idle2);
	}
	t = lb_now();
	for (i = 0; i < 100000 * s; i++)
		uv_run(l, UV_RUN_NOWAIT);
	lb_out("3000 handles per iteration x100k", t);
	for (i = 0; i < 1000; i++) {
		uv_close((uv_handle_t *)&pr[i], NULL);
		uv_close((uv_handle_t *)&ck[i], NULL);
		uv_close((uv_handle_t *)&id[i], NULL);
	}
	uv_run(l, UV_RUN_DEFAULT);
	t = lb_now();
	for (i = 0; i < 1500000 * s; i++) {
		uv_fs_stat(NULL, &req, argv[0], NULL);
		LB_KEEP(req.statbuf.st_size);
		uv_fs_req_cleanup(&req);
	}
	lb_out("fs stat (synchronous) 1.5M", t);
	n = 2000000 * s;
	wk = malloc((size_t)n * sizeof(*wk));
	t = lb_now();
	for (i = 0; i < n; i++) {
		wk[i].data = (void *)(uintptr_t)i;
		uv_queue_work(l, &wk[i], work, done);
	}
	uv_run(l, UV_RUN_DEFAULT);
	lb_out("thread pool work 2M", t);
	LB_KEEP(fired);
	uv_loop_close(l);
	return 0;
}
