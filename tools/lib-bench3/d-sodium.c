/* SPDX-License-Identifier: BSD-2-Clause */
/* d-sodium [<scale>]: libsodium, what PHP sodium_* and password_hash(ARGON2ID) do */
#include <sodium.h>
#include "lb.h"

int
main(int argc, char **argv)
{
	int s = argc > 1 ? atoi(argv[1]) : 1, i;
	size_t n = 64u << 20, chunk = 16384, off;
	unsigned char *m = malloc(n + 64), *c = malloc(n + 64), k[32], nonce[24], h[64], pk[32], sk[64],
	    sig[64], q[32], out[32];
	unsigned long long cl;
	char hash[crypto_pwhash_STRBYTES];
	double t;

	if (sodium_init() < 0 || m == NULL || c == NULL)
		return 2;
	for (off = 0; off < n; off++)
		m[off] = (unsigned char)(lb_rand() >> 56);
	memset(k, 7, sizeof(k));
	memset(nonce, 3, sizeof(nonce));

	t = lb_now();
	for (i = 0; i < 8 * s; i++)
		for (off = 0; off < n; off += chunk)
			crypto_aead_chacha20poly1305_ietf_encrypt(c + off, &cl, m + off, chunk, NULL, 0, NULL, nonce, k);
	lb_out("chacha20poly1305-ietf encrypt 8x64MB", t);
	t = lb_now();
	for (i = 0; i < 10 * s; i++)
		for (off = 0; off < n; off += chunk)
			crypto_aead_xchacha20poly1305_ietf_encrypt(c + off, &cl, m + off, chunk, NULL, 0, NULL, nonce, k);
	lb_out("xchacha20poly1305-ietf encrypt 10x64MB", t);
	t = lb_now();
	for (i = 0; i < 10 * s; i++)
		for (off = 0; off + chunk <= n; off += chunk)
			crypto_secretbox_easy(c + off, m + off, chunk - crypto_secretbox_MACBYTES, nonce, k);
	lb_out("secretbox xsalsa20poly1305 10x64MB", t);
	if (crypto_aead_aes256gcm_is_available()) {
		t = lb_now();
		for (i = 0; i < 16 * s; i++)
			for (off = 0; off < n; off += chunk)
				crypto_aead_aes256gcm_encrypt(c + off, &cl, m + off, chunk, NULL, 0, NULL, nonce, k);
		lb_out("aes256gcm encrypt 16x64MB", t);
	}
	t = lb_now();
	for (i = 0; i < 8 * s; i++)
		crypto_generichash(h, 32, m, n, NULL, 0);
	lb_out("generichash blake2b 8x64MB", t);
	t = lb_now();
	for (i = 0; i < 3 * s; i++)
		crypto_hash_sha256(h, m, n);
	lb_out("sha256 3x64MB", t);
	t = lb_now();
	for (i = 0; i < 5 * s; i++)
		crypto_hash_sha512(h, m, n);
	lb_out("sha512 5x64MB", t);
	crypto_sign_keypair(pk, sk);
	t = lb_now();
	for (i = 0; i < 50000 * s; i++) {
		crypto_sign_detached(sig, NULL, m + i, 256, sk);
		LB_KEEP(sig[0]);
	}
	lb_out("ed25519 sign 50k", t);
	t = lb_now();
	for (i = 0; i < 15000 * s; i++)
		LB_KEEP(crypto_sign_verify_detached(sig, m + 50000 * s - 1, 256, pk));
	lb_out("ed25519 verify 15k", t);
	memset(q, 9, sizeof(q));
	t = lb_now();
	for (i = 0; i < 20000 * s; i++) {
		q[0] = (unsigned char)i;
		LB_KEEP(crypto_scalarmult(out, q, pk));
	}
	lb_out("x25519 scalarmult 20k", t);
	t = lb_now();
	for (i = 0; i < 12 * s; i++)
		if (crypto_pwhash_str(hash, "correct horse battery", 21, 2, 64u << 20) != 0)
			return 1;
	lb_out("pwhash argon2id t2 64MB x12", t);
	return 0;
}
