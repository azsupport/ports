/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-nghttp2 [<scale>]: nghttp2 without the network: HPACK, the header compression of every
 * HTTP/2 request and response of curl (and nginx-less programs), deflate and inflate
 */
#include <nghttp2/nghttp2.h>
#include "lb.h"

#define NV(n, v) { (uint8_t *)(n), (uint8_t *)(v), sizeof(n) - 1, sizeof(v) - 1, NGHTTP2_NV_FLAG_NONE }

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, fl;
	char path[64], cookie[96], len[16];
	nghttp2_nv req[] = { NV(":method", "GET"), NV(":scheme", "https"), NV(":authority", "www.example-shop.com"),
		NV(":path", "/index.php?route=product/category&path=20_27&page=2"),
		NV("user-agent", "Mozilla/5.0 (X11; FreeBSD amd64; rv:132.0) Gecko/20100101 Firefox/132.0"),
		NV("accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"),
		NV("accept-language", "ru,en-US;q=0.7,en;q=0.3"), NV("accept-encoding", "gzip, deflate, br, zstd"),
		NV("cookie", "PHPSESSID=0123456789abcdef0123456789abcdef; language=ru-ru; currency=RUB") };
	nghttp2_nv resp[] = { NV(":status", "200"), NV("server", "nginx"), NV("date", "Thu, 26 Nov 2026 20:30:00 GMT"),
		NV("content-type", "text/html; charset=utf-8"), NV("content-length", "34567"),
		NV("cache-control", "no-store, no-cache, must-revalidate"), NV("x-powered-by", "PHP/8.3.37"),
		NV("set-cookie", "PHPSESSID=0123456789abcdef0123456789abcdef; path=/; HttpOnly"),
		NV("strict-transport-security", "max-age=31536000; includeSubDomains"), NV("vary", "Accept-Encoding") };
	size_t nreq = sizeof(req) / sizeof(*req), nresp = sizeof(resp) / sizeof(*resp);
	nghttp2_hd_deflater *d;
	nghttp2_hd_inflater *in;
	uint8_t buf[4096], *blocks;
	size_t *blen, k;
	nghttp2_ssize r;
	nghttp2_nv nv;
	double t;

	nghttp2_hd_deflate_new(&d, 4096);
	blocks = malloc(20000 * sizeof(buf));
	blen = malloc(20000 * sizeof(*blen));
	t = lb_now();
	for (i = 0; i < 1000000 * s; i++) {
		snprintf(path, sizeof(path), "/catalog/item-%d.html?ref=%d", i % 5000, i % 17);
		snprintf(cookie, sizeof(cookie), "PHPSESSID=%08x%08x; language=ru-ru", (unsigned)i * 2654435761u, (unsigned)i);
		req[3].value = (uint8_t *)path;
		req[3].valuelen = strlen(path);
		req[8].value = (uint8_t *)cookie;
		req[8].valuelen = strlen(cookie);
		r = nghttp2_hd_deflate_hd(d, buf, sizeof(buf), req, nreq);
		if (r < 0)
			return 1;
		LB_KEEP(r);
	}
	lb_out("deflate requests (9 fields) 1M", t);
	nghttp2_hd_deflate_del(d);
	nghttp2_hd_deflate_new(&d, 4096);
	for (k = 0; k < 20000; k++) {
		snprintf(len, sizeof(len), "%zu", 1000 + k * 7);
		resp[4].value = (uint8_t *)len;
		resp[4].valuelen = strlen(len);
		r = nghttp2_hd_deflate_hd(d, blocks + k * sizeof(buf), sizeof(buf), resp, nresp);
		if (r < 0)
			return 1;
		blen[k] = (size_t)r;
	}
	t = lb_now();
	for (i = 0; i < 50 * s; i++) {
		nghttp2_hd_inflate_new(&in);
		for (k = 0; k < 20000; k++) {
			uint8_t *p = blocks + k * sizeof(buf);
			size_t left = blen[k];

			for (;;) {
				fl = 0;
				r = nghttp2_hd_inflate_hd3(in, &nv, &fl, p, left, 1);
				if (r < 0)
					return 1;
				p += r;
				left -= (size_t)r;
				if (fl & NGHTTP2_HD_INFLATE_EMIT)
					LB_KEEP(nv.valuelen);
				if (fl & NGHTTP2_HD_INFLATE_FINAL) {
					nghttp2_hd_inflate_end_headers(in);
					break;
				}
				if (left == 0 && !(fl & NGHTTP2_HD_INFLATE_EMIT))
					break;
			}
		}
		nghttp2_hd_inflate_del(in);
	}
	lb_out("inflate responses (10 fields) 1M", t);
	nghttp2_hd_deflate_del(d);
	return 0;
}
