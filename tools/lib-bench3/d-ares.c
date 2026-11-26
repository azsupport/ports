/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-ares [<scale>]: c-ares without the network: what it does with every answer of a name
 * server for curl (the DNS messages: parse, write, and the replies of the old API)
 */
#include <arpa/inet.h>
#include <netinet/in.h>
#include <ares.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, k, na;
	ares_dns_record_t *rec, *r2;
	ares_dns_rr_t *rr;
	unsigned char *buf, *b2;
	size_t blen, l2;
	struct in_addr a;
	struct ares_in6_addr a6;
	struct hostent *he;
	struct ares_addrttl ttls[16];
	double t;

	ares_library_init(ARES_LIB_INIT_ALL);
	if (ares_dns_record_create(&rec, 0x1234, ARES_FLAG_QR | ARES_FLAG_RD | ARES_FLAG_RA, ARES_OPCODE_QUERY,
	    ARES_RCODE_NOERROR) != ARES_SUCCESS)
		return 1;
	ares_dns_record_query_add(rec, "www.example-shop.com", ARES_REC_TYPE_A, ARES_CLASS_IN);
	ares_dns_record_rr_add(&rr, rec, ARES_SECTION_ANSWER, "www.example-shop.com", ARES_REC_TYPE_CNAME,
	    ARES_CLASS_IN, 300);
	ares_dns_rr_set_str(rr, ARES_RR_CNAME_CNAME, "shop.cdn.example-cdn.net");
	for (k = 0; k < 6; k++) {
		ares_dns_record_rr_add(&rr, rec, ARES_SECTION_ANSWER, "shop.cdn.example-cdn.net", ARES_REC_TYPE_A,
		    ARES_CLASS_IN, 60);
		a.s_addr = htonl(0x5db8d822u + (unsigned)k);
		ares_dns_rr_set_addr(rr, ARES_RR_A_ADDR, &a);
	}
	for (k = 0; k < 2; k++) {
		ares_dns_record_rr_add(&rr, rec, ARES_SECTION_AUTHORITY, "example-cdn.net", ARES_REC_TYPE_NS,
		    ARES_CLASS_IN, 3600);
		ares_dns_rr_set_str(rr, ARES_RR_NS_NSDNAME, k ? "ns2.example-cdn.net" : "ns1.example-cdn.net");
		ares_dns_record_rr_add(&rr, rec, ARES_SECTION_ADDITIONAL, k ? "ns2.example-cdn.net" :
		    "ns1.example-cdn.net", ARES_REC_TYPE_AAAA, ARES_CLASS_IN, 3600);
		memset(&a6, 0, sizeof(a6));
		a6._S6_un._S6_u8[0] = 0x2a;
		a6._S6_un._S6_u8[15] = (unsigned char)k;
		ares_dns_rr_set_addr6(rr, ARES_RR_AAAA_ADDR, &a6);
	}
	if (ares_dns_write(rec, &buf, &blen) != ARES_SUCCESS)
		return 1;
	t = lb_now();
	for (i = 0; i < 150000 * s; i++) {
		if (ares_dns_parse(buf, blen, 0, &r2) != ARES_SUCCESS)
			return 1;
		LB_KEEP(ares_dns_record_rr_cnt(r2, ARES_SECTION_ANSWER));
		ares_dns_record_destroy(r2);
	}
	lb_out("parse an answer of 11 records 150k", t);
	t = lb_now();
	for (i = 0; i < 150000 * s; i++) {
		if (ares_dns_write(rec, &b2, &l2) != ARES_SUCCESS)
			return 1;
		LB_KEEP(l2);
		ares_free_string(b2);
	}
	lb_out("write an answer of 11 records 150k", t);
	t = lb_now();
	for (i = 0; i < 150000 * s; i++) {
		na = 16;
		if (ares_parse_a_reply(buf, (int)blen, &he, ttls, &na) != ARES_SUCCESS)
			return 1;
		LB_KEEP(na);
		ares_free_hostent(he);
	}
	lb_out("parse_a_reply 150k", t);
	ares_free_string(buf);
	ares_dns_record_destroy(rec);
	ares_library_cleanup();
	return 0;
}
