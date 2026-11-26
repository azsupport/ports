/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * gen - the inputs of tools/lib-bench3.sh, the same from a fixed seed on every run:
 *   gen text <MB>          UTF-8 lines of words, Latin and Cyrillic (and some German)
 *   gen xml <MB>           a catalog of items: elements, attributes, text, entities
 *   gen html <MB>          HTML as sites write it: tags not closed, upper case, tables
 *   gen yaml <MB>          a YAML sequence of mappings with nested sequences
 *   gen bidi <MB>          lines of Hebrew, Arabic and Latin words and numbers (fribidi)
 *   gen ppm <w> <h>        a picture (P6): gradients, waves, edges and a little noise
 *   gen y4m <w> <h> <n>    a video of n frames 4:2:0, the picture of ppm in motion
 *   gen domains <n>        host names, ASCII and IDN (UTF-8)
 *   gen urls <n>           URLs as the logs of sites have them
 *   gen http <n>           HTTP/1.1 requests one after another
 *   gen ips <n>            IPv4 and IPv6 addresses
 * The output goes to stdout.
 */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint64_t seed = 0x9e3779b97f4a7c15ULL;
static uint64_t
rnd(void)
{
	seed ^= seed >> 12;
	seed ^= seed << 25;
	seed ^= seed >> 27;
	return seed * 2685821657736338717ULL;
}
#define R(n) ((int)(rnd() % (uint64_t)(n)))

static const char *lat[] = { "ka", "lo", "mi", "ne", "ro", "sta", "ter", "vin", "pre", "con", "dis", "ment",
	"tion", "al", "er", "in", "ou", "an", "th", "ing", "ex", "per", "com", "ver", "a", "e", "i", "o", "u", "y" };
static const char *cyr[] = { "ка", "ло", "ми", "не", "ро", "ста", "тер", "вин", "пре", "кон", "раз", "мент",
	"ция", "ал", "ер", "ин", "ов", "ан", "ть", "ная", "ски", "пер", "ком", "вер", "а", "е", "и", "о", "у", "я",
	"ж", "щ", "ю", "ё", "ы", "э", "ш", "х" };
static const char *ger[] = { "ä", "ö", "ü", "ß", "ei", "sch", "ch", "au", "en", "er" };

static void
word(char *b, size_t cap)
{
	int k = R(10), n = 1 + R(4), i;
	size_t l = 0;
	const char *s;

	b[0] = '\0';
	for (i = 0; i < n; i++) {
		s = k < 5 ? lat[R(sizeof(lat) / sizeof(*lat))] : k < 9 ? cyr[R(sizeof(cyr) / sizeof(*cyr))] :
		    ger[R(sizeof(ger) / sizeof(*ger))];
		if (l + strlen(s) + 1 >= cap)
			break;
		memcpy(b + l, s, strlen(s) + 1);
		l += strlen(s);
	}
}

static void
asciiword(char *b, size_t cap)
{
	int n = 1 + R(4), i;
	size_t l = 0;
	const char *s;

	b[0] = '\0';
	for (i = 0; i < n; i++) {
		s = lat[R(sizeof(lat) / sizeof(*lat))];
		if (l + strlen(s) + 1 >= cap)
			break;
		memcpy(b + l, s, strlen(s) + 1);
		l += strlen(s);
	}
}

static void
text(long mb)
{
	long bytes = mb * 1048576L, out = 0;
	char w[64];
	int col = 0;

	while (out < bytes) {
		word(w, sizeof(w));
		if (R(12) == 0)
			w[0] = (char)(w[0] >= 'a' && w[0] <= 'z' ? w[0] - 32 : w[0]);
		out += printf("%s", w);
		col += (int)strlen(w);
		if (R(15) == 0)
			out += printf("%s", R(2) ? "," : ".");
		if (R(40) == 0)
			out += printf(" %d", R(100000));
		if (col > 70) {
			out += printf("\n");
			col = 0;
		} else {
			out += printf(" ");
			col++;
		}
	}
	printf("\n");
}

static void
xml(long mb)
{
	static const char *types[] = { "book", "disk", "film", "game", "tool" };
	long bytes = mb * 1048576L, out = 0, id = 0;
	char w[64], w2[64];
	int i, n;

	out += printf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<catalog xmlns=\"urn:x-lb:catalog\" "
	    "xmlns:m=\"urn:x-lb:meta\" version=\"2\">\n");
	while (out < bytes) {
		id++;
		asciiword(w, sizeof(w));
		out += printf(" <item id=\"%ld\" type=\"%s\" price=\"%d.%02d\" m:stock=\"%d\">\n", id,
		    types[R(5)], R(500), R(100), R(1000));
		word(w, sizeof(w));
		word(w2, sizeof(w2));
		out += printf("  <name>%s %s</name>\n  <desc>", w, w2);
		n = 5 + R(25);
		for (i = 0; i < n; i++) {
			word(w, sizeof(w));
			out += printf("%s%s", w, R(20) == 0 ? " &amp; " : R(30) == 0 ? " &lt;b&gt; " : " ");
		}
		out += printf("</desc>\n  <tags>");
		n = R(5);
		for (i = 0; i < n; i++) {
			asciiword(w, sizeof(w));
			out += printf("<tag>%s</tag>", w);
		}
		out += printf("</tags>\n  <m:updated>2026-%02d-%02dT%02d:%02d:00Z</m:updated>\n </item>\n",
		    1 + R(12), 1 + R(28), R(24), R(60));
	}
	printf("</catalog>\n");
}

static void
html(long mb)
{
	long bytes = mb * 1048576L, out = 0;
	char w[64], w2[64];
	int i, n, k;

	out += printf("<!DOCTYPE html>\n<HTML><HEAD><TITLE>Lb page</TITLE>\n<meta charset=utf-8>\n"
	    "<STYLE>td {color: red}</STYLE></HEAD><BODY bgcolor=#ffffff>\n");
	while (out < bytes) {
		k = R(6);
		word(w, sizeof(w));
		word(w2, sizeof(w2));
		switch (k) {
		case 0:
			out += printf("<P>%s <b>%s <i>%s</i></b> &copy; &nbsp;%s\n", w, w2, w, w2);
			break;
		case 1:
			out += printf("<TABLE border=1 width=100%%><tr><td>%s<td>%s<tr><TD align=center>%d</TD></table>\n",
			    w, w2, R(1000));
			break;
		case 2:
			out += printf("<ul><li>%s<li><a href=/p/%d.php?id=%d&amp;q=%s>%s</a><li>%s</ul>\n", w, R(100),
			    R(10000), w2, w, w2);
			break;
		case 3:
			out += printf("<div class=\"c%d\" id=d%d><span>%s</span><img src=\"/i/%d.jpg\" alt=%s></div>\n",
			    R(20), R(100000), w, R(1000), w2);
			break;
		case 4:
			n = 3 + R(10);
			out += printf("<font face=Arial size=2>");
			for (i = 0; i < n; i++) {
				word(w, sizeof(w));
				out += printf("%s ", w);
			}
			out += printf("</font><br>\n");
			break;
		default:
			k = 1 + R(4);
			out += printf("<h%d>%s</h%d>\n<p>%s & %s <br>\n", k, w, k, w2, w);
			break;
		}
	}
	printf("</BODY></HTML>\n");
}

static void
yaml(long mb)
{
	long bytes = mb * 1048576L, out = 0, id = 0;
	char w[64], w2[64];
	int i, n;

	out += printf("%%YAML 1.1\n---\n");
	while (out < bytes) {
		id++;
		word(w, sizeof(w));
		word(w2, sizeof(w2));
		out += printf("- id: %ld\n  name: \"%s %s\"\n  enabled: %s\n  ratio: %d.%03d\n  tags:\n", id, w, w2,
		    R(2) ? "true" : "false", R(10), R(1000));
		n = 1 + R(4);
		for (i = 0; i < n; i++) {
			asciiword(w, sizeof(w));
			out += printf("    - %s\n", w);
		}
		word(w, sizeof(w));
		out += printf("  meta: {created: 2026-%02d-%02d, owner: %s, size: %d}\n", 1 + R(12), 1 + R(28), w,
		    R(1 << 20));
		if (R(4) == 0) {
			word(w, sizeof(w));
			word(w2, sizeof(w2));
			out += printf("  note: |\n    %s %s\n    %s\n", w, w2, w);
		}
	}
}

static void
bidi(long mb)
{
	static const char *heb[] = { "של", "ום", "עו", "לם", "תו", "דה", "בי", "ת", "ספר", "אני" };
	static const char *ara[] = { "مر", "حبا", "بال", "عا", "لم", "كتا", "ب", "شك", "را", "الس" };
	long bytes = mb * 1048576L, out = 0;
	char w[64];
	int col = 0, k, n, i;

	while (out < bytes) {
		k = R(3);
		if (k == 2) {
			asciiword(w, sizeof(w));
			out += printf("%s", w);
		} else {
			n = 1 + R(3);
			for (i = 0; i < n; i++)
				out += printf("%s", k ? ara[R(10)] : heb[R(10)]);
		}
		if (R(10) == 0)
			out += printf(" %d", R(10000));
		if (R(14) == 0)
			out += printf(R(2) ? "." : ",");
		col += 6;
		if (col > 70) {
			out += printf("\n");
			col = 0;
		} else
			out += printf(" ");
	}
	printf("\n");
}

static unsigned char
clamp(double v)
{
	return v < 0 ? 0 : v > 255 ? 255 : (unsigned char)v;
}

/* the picture at time t: gradients, waves, rectangles with hard edges, noise */
static void
pixel(int x, int y, int w, int h, double t, unsigned char *p)
{
	double fx = (double)x / w, fy = (double)y / h, s;
	int bx = (int)((x + t * 40) / 97), by = (int)((y + t * 15) / 61);

	s = sin(fx * 23 + t * 0.3) * cos(fy * 17 - t * 0.2);
	p[0] = clamp(120 + 100 * fx + 30 * s + ((bx + by) % 7 == 0 ? 60 : 0) + R(9) - 4);
	p[1] = clamp(60 + 140 * fy + 40 * sin(fx * 40 + fy * 9 + t * 0.5) + R(9) - 4);
	p[2] = clamp(200 - 120 * fx * fy + 50 * s + ((bx * 3 + by) % 5 == 0 ? -80 : 0) + R(9) - 4);
}

static void
ppm(int w, int h)
{
	unsigned char *row = malloc((size_t)w * 3);
	int x, y;

	printf("P6\n%d %d\n255\n", w, h);
	for (y = 0; y < h; y++) {
		for (x = 0; x < w; x++)
			pixel(x, y, w, h, 0, row + 3 * x);
		fwrite(row, 3, (size_t)w, stdout);
	}
	free(row);
}

static void
y4m(int w, int h, int n)
{
	unsigned char *Y = malloc((size_t)w * h), *U = malloc((size_t)w * h / 4), *V = malloc((size_t)w * h / 4);
	unsigned char p[3];
	int f, x, y;

	printf("YUV4MPEG2 W%d H%d F30:1 Ip A1:1 C420jpeg\n", w, h);
	for (f = 0; f < n; f++) {
		for (y = 0; y < h; y++)
			for (x = 0; x < w; x++) {
				pixel(x, y, w, h, f, p);
				Y[y * w + x] = clamp(0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]);
				if ((x & 1) == 0 && (y & 1) == 0) {
					U[(y / 2) * (w / 2) + x / 2] = clamp(128 - 0.169 * p[0] - 0.331 * p[1] + 0.5 * p[2]);
					V[(y / 2) * (w / 2) + x / 2] = clamp(128 + 0.5 * p[0] - 0.419 * p[1] - 0.081 * p[2]);
				}
			}
		printf("FRAME\n");
		fwrite(Y, 1, (size_t)w * h, stdout);
		fwrite(U, 1, (size_t)w * h / 4, stdout);
		fwrite(V, 1, (size_t)w * h / 4, stdout);
	}
}

static const char *tlds[] = { "com", "net", "org", "ru", "de", "cz", "co.uk", "com.au", "github.io", "рф",
	"рус", "москва", "info", "io", "blogspot.com", "s3.amazonaws.com", "uk", "jp", "ac.jp", "kyoto.jp" };

static void
host(char *b, size_t cap, int idn)
{
	char w[64], w2[64];
	int t = R(sizeof(tlds) / sizeof(*tlds));

	if (idn)
		word(w, sizeof(w));
	else
		asciiword(w, sizeof(w));
	asciiword(w2, sizeof(w2));
	switch (R(4)) {
	case 0: snprintf(b, cap, "%s.%s", w, tlds[t]); break;
	case 1: snprintf(b, cap, "www.%s-%d.%s", w, R(1000), tlds[t]); break;
	case 2: snprintf(b, cap, "%s.%s.%s", w2, w, tlds[t]); break;
	default: snprintf(b, cap, "cdn%d.%s.%s.%s", R(10), w2, w, tlds[t]); break;
	}
}

static void
domains(int n)
{
	char b[256];
	int i;

	for (i = 0; i < n; i++) {
		host(b, sizeof(b), R(3) == 0);
		printf("%s\n", b);
	}
}

static void
urls(int n)
{
	static const char *ext[] = { "php", "html", "jpg", "mp4", "css", "js", "" };
	char h[256], w[64], w2[64];
	int i;

	for (i = 0; i < n; i++) {
		host(h, sizeof(h), 0);
		asciiword(w, sizeof(w));
		asciiword(w2, sizeof(w2));
		switch (R(5)) {
		case 0:
			printf("https://%s/%s/%s.%s\n", h, w, w2, ext[R(7)]);
			break;
		case 1:
			printf("https://%s/index.php?route=%s/%s&id=%d&sort=p.price&order=ASC&page=%d\n", h, w, w2,
			    R(100000), R(50));
			break;
		case 2:
			printf("http://user%d:p%%40ss@%s:%d/%s/%%D0%%BF%%D1%%80%%D0%%B8/%s?q=%s+%s#top\n", R(100), h,
			    8000 + R(1000), w, w2, w, w2);
			break;
		case 3:
			printf("https://%s/videos/%d/%s-%s/?utm_source=x&utm_medium=%s\n", h, R(1000000), w, w2, w);
			break;
		default:
			printf("HTTPS://%s/a/./b/../%s//%s.%s?x=%d\n", h, w, w2, ext[R(7)], R(10));
			break;
		}
	}
}

static void
http(int n)
{
	char h[256], w[64];
	int i;

	for (i = 0; i < n; i++) {
		host(h, sizeof(h), 0);
		asciiword(w, sizeof(w));
		if (R(4) == 0)
			printf("POST /api/%s HTTP/1.1\r\nHost: %s\r\nContent-Type: application/json\r\n"
			    "Content-Length: 21\r\nUser-Agent: Mozilla/5.0 (X11; FreeBSD amd64)\r\n\r\n{\"id\":%08d,\"x\":1}",
			    w, h, R(100000000));
		else
			printf("GET /%s/%d.php?id=%d HTTP/1.1\r\nHost: %s\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; "
			    "Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36\r\n"
			    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
			    "Accept-Language: ru,en;q=0.9\r\nAccept-Encoding: gzip, deflate, br, zstd\r\n"
			    "Cookie: PHPSESSID=%08x%08x; lang=ru\r\nConnection: keep-alive\r\n\r\n",
			    w, R(1000), R(100000), h, (unsigned)rnd(), (unsigned)rnd());
	}
}

static void
ips(int n)
{
	static const char *v4[] = { "81.2.69.", "216.160.83.", "89.160.20.", "175.16.199.", "67.43.156.",
		"2.125.160.", "202.196.224." };
	int i;

	for (i = 0; i < n; i++) {
		switch (R(4)) {
		case 0:
			printf("%d.%d.%d.%d\n", 1 + R(223), R(256), R(256), R(256));
			break;
		case 1:
			printf("2a02:cf40:%x:%x::%x\n", R(65536), R(65536), R(65536));
			break;
		default:
			printf("%s%d\n", v4[R(7)], R(256));
			break;
		}
	}
}

int
main(int argc, char **argv)
{
	const char *m = argc > 1 ? argv[1] : "";
	long a = argc > 2 ? atol(argv[2]) : 0;

	if (strcmp(m, "text") == 0)
		text(a);
	else if (strcmp(m, "xml") == 0)
		xml(a);
	else if (strcmp(m, "html") == 0)
		html(a);
	else if (strcmp(m, "yaml") == 0)
		yaml(a);
	else if (strcmp(m, "bidi") == 0)
		bidi(a);
	else if (strcmp(m, "ppm") == 0 && argc > 3)
		ppm((int)a, atoi(argv[3]));
	else if (strcmp(m, "y4m") == 0 && argc > 4)
		y4m((int)a, atoi(argv[3]), atoi(argv[4]));
	else if (strcmp(m, "domains") == 0)
		domains((int)a);
	else if (strcmp(m, "urls") == 0)
		urls((int)a);
	else if (strcmp(m, "http") == 0)
		http((int)a);
	else if (strcmp(m, "ips") == 0)
		ips((int)a);
	else {
		fprintf(stderr, "usage: gen text|xml|html|yaml|bidi <MB> | ppm <w> <h> | y4m <w> <h> <n> | "
		    "domains|urls|http|ips <n>\n");
		return 2;
	}
	return ferror(stdout) ? 1 : 0;
}
