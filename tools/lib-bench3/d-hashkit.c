/* SPDX-License-Identifier: BSD-2-Clause */
/*
 * d-hashkit [<scale>]: libmemcached without the network: the hashes of keys (libhashkit) and
 * the server of a key with the ketama continuum of 8 servers, what PHP memcached does for
 * every get and set
 */
#include <libmemcached/memcached.h>
#include <libhashkit-1.0/hashkit.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i, k;
	static const struct { const char *n; hashkit_hash_algorithm_t a; } al[] = {
		{ "one_at_a_time", HASHKIT_HASH_DEFAULT }, { "md5", HASHKIT_HASH_MD5 }, { "crc", HASHKIT_HASH_CRC },
		{ "fnv1a_32", HASHKIT_HASH_FNV1A_32 }, { "fnv1_64", HASHKIT_HASH_FNV1_64 },
		{ "jenkins", HASHKIT_HASH_JENKINS }, { "murmur", HASHKIT_HASH_MURMUR } };
	char key[96];
	size_t kl;
	hashkit_st *hk = hashkit_create(NULL);
	memcached_st *m;
	double t;
	char name[64];

	for (k = 0; k < (int)(sizeof(al) / sizeof(*al)); k++) {
		if (hashkit_set_function(hk, al[k].a) != HASHKIT_SUCCESS) {
			fprintf(stderr, "no %s\n", al[k].n);
			continue;
		}
		t = lb_now();
		for (i = 0; i < 4000000 * s; i++) {
			kl = (size_t)snprintf(key, sizeof(key), "site:%d:session:%08x", i % 1000, (unsigned)i * 2654435761u);
			LB_KEEP(hashkit_digest(hk, key, kl));
		}
		snprintf(name, sizeof(name), "hash %s 4M keys", al[k].n);
		lb_out(name, t);
	}
	m = memcached_create(NULL);
	memcached_behavior_set(m, MEMCACHED_BEHAVIOR_DISTRIBUTION, MEMCACHED_DISTRIBUTION_CONSISTENT_KETAMA);
	memcached_behavior_set(m, MEMCACHED_BEHAVIOR_KETAMA_WEIGHTED, 1);
	for (k = 0; k < 8; k++) {
		char h[32];

		snprintf(h, sizeof(h), "10.0.0.%d", 10 + k);
		memcached_server_add_with_weight(m, h, 11211, (uint32_t)(1 + k % 3));
	}
	t = lb_now();
	for (i = 0; i < 4000000 * s; i++) {
		kl = (size_t)snprintf(key, sizeof(key), "cache:page:/catalog/%d?sort=%d", i, i % 7);
		LB_KEEP(memcached_generate_hash(m, key, kl));
	}
	lb_out("ketama server of a key 4M", t);
	t = lb_now();
	for (i = 0; i < 2000 * s; i++) {
		memcached_st *c = memcached_clone(NULL, m);

		memcached_free(c);
	}
	lb_out("clone with continuum 2k", t);
	memcached_free(m);
	hashkit_free(hk);
	return 0;
}
