#!/bin/sh
# node18-test.sh - test Node.js 18 of the repository az, installed from it (aZ,
# 11.11.2026: for a legacy project): node18 with npm-node18, yarn-node18 and
# corepack-node18, in the place of node24 and its npm, yarn and corepack
# (tools/test-programs.sh installs them after the test of node24: pkg takes node24
# away, one of the two). node loads only libraries of the base system, of az
# (/usr/local/az/lib) and llhttp of www/llhttp, and the versions it reports
# (process.versions) are those of az (pkg-config), of llhttp (pkg) and of the
# OpenSSL of the base system. And:
#   one       none of node24, npm-node24, yarn-node24, corepack-node24 installed
#   intl      the ICU of az with its data: a date of ru-RU in Cyrillic, a number of
#             de-DE, the ICU version
#   crypto    SHA-256, an Ed25519 signature; TLS 1.3 between a server and a client of
#             node on 127.0.0.1 with a certificate of the openssl of the base system
#   zlib      gzip (zlib of the base system) and brotli (of az) round trips (Node 18
#             has no zstd)
#   http      a server and fetch() on 127.0.0.1 (llhttp, undici); HTTP/2 without TLS
#             (nghttp2)
#   fixes     fixes of the security patches of SUSE (www/node18/files/suse) in work:
#             a request whose header block ends with \r\n\rX gets 400 and never
#             reaches the server (CVE-2025-23167: llhttp 9), a header __proto__ and
#             req.headersDistinct (CVE-2026-21710), dns.lookup() of a name with a
#             NUL byte refused (CVE-2026-48930)
#   upstream  fixes of the backports of Node.js 22 (www/node18/files/upstream) in
#             work, each failing on 18.20.8 without them: dns.resolve*() and
#             dns.reverse() refuse a name with a NUL byte (CVE-2026-105482); a free
#             kept-alive socket of http.Agent with data that came before its
#             request is destroyed, not reused (CVE-2026-105481);
#             tls.checkServerIdentity() matches an IPv6 host against its IP-Address
#             SAN and refuses hosts that are IPv4 addresses only in a non-canonical
#             form (CVE-2026-106069, CVE-2026-106072); randomUUID() and randomInt()
#             differ between two processes of one startup snapshot (CVE-2026-106074);
#             https.Agent keys of different TLS policies differ (CVE-2026-123877);
#             zlib params() then destroy() gives its callback the error
#             (CVE-2026-123862); undici 6.29.1: fetch() of a gzip body, more than 5
#             content-encodings refused
#   tls, http2  the fixes of the TLS and HTTP/2 code (Node.js 22.23.4, 22.23.5,
#             24.22.3), each failing on 18.20.8 without it, with certificates made
#             here by the openssl of the base system: a chain through a blocked
#             intermediate fails with CERT_REVOKED, with the ca of the connection
#             and with the default CA store, the base system's with the root of the
#             test by NODE_EXTRA_CA_CERTS (tls-spki-blocklist.patch; node with
#             --expose-internals for its test hooks); an SNI context with a ca only
#             verifies the client certificates of its host (CVE-2026-123867); a
#             session resumed only for its server name, none without a session id
#             context and with client certificates, a HelloRetryRequest and a
#             renegotiation keeping the SNI context (CVE-2026-123872); an HTTP/2
#             session ended by nghttp2 after a GOAWAY of the peer ends with an error
#             (CVE-2026-123865); the DATA of a reset stream in a pending socket write
#             is what it wrote (CVE-2026-123866; node with --expose-gc); undrained
#             streams bounded by maxSessionMemory (CVE-2026-123868); ALTSVC frames
#             over 1 KiB (CVE-2026-123828; plain 18.20.8 aborts with glibc, with the
#             jemalloc of FreeBSD the one byte past the buffer may go unseen). No
#             check for CVE-2026-123863, CVE-2026-123864, CVE-2026-123874 and
#             CVE-2026-123875: races or paths their upstream tests do not reach on
#             18.20.8 either
#   wasi      node:wasi: a WebAssembly module made here writes to stdout (the uvwasi
#             Node 18 bundles, on the libuv of az)
#   url       an IDN host in Punycode (the ada Node 18 bundles)
#   npm       npm and npx, npm pack of a package made here and npm install of it
#             offline; node-gyp; the brace-expansion 2.1.8 and ip-address 10.7.6 of
#             the registry in the place of those npm 10.9.10 bundles, at work through
#             its minimatch and socks (and an IPv4 address with a leading zero
#             refused, CVE-2026-69192); addGitSha() of both its pacote on the spec of
#             the upstream test of CVE-2026-9496 (100000 # and a newline: seconds,
#             and the committish kept, without the fix)
#   yarn      yarn init; corepack enable into a directory of its own
#
# Usage (FreeBSD, as root, the packages installed): sh tools/node18-test.sh
# Results: node18-results/tests.txt (one line per check, the summary at the end);
# exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/node18-results}"
T="${NODE_TEST_WORK:-/var/tmp/node18-test}"
P=/usr/local
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T/home"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
# the libraries of our ports that node may load from /usr/local/lib
ours="libllhttp"
# libs_of <file>: what it loads (ldd) when every library is found and is of the base
# system, of az or of our ports above, in libs_out; else why in libs_bad
libs_of() {
    libs_bad=""; libs_out=""
    _l="$(ldd "$1" 2>&1)" || { libs_bad="ldd failed: $(printf '%s\n' "$_l" | tail -n 1)"; return 1; }
    case "$_l" in *"not found"*) libs_bad="$(printf '%s\n' "$_l" | grep 'not found' | head -n 2 | tr '\n' ' ')"; return 1 ;; esac
    _all=""
    for _x in $(printf '%s\n' "$_l" | awk 'NF > 2 && $2 == "=>" { print $3 }'); do
        _all="$_all $_x"
        case "$_x" in
            /lib/* | /usr/lib/* | /usr/local/az/lib/*) continue ;;
            /usr/local/lib/*) for _a in $ours; do case "${_x##*/}" in "$_a".so*) continue 2 ;; esac; done ;;
        esac
        libs_bad="$libs_bad $_x"
    done
    [ -z "$libs_bad" ] || { libs_bad="not of the base system, az or our ports:$libs_bad"; return 1; }
    libs_out="${_all# }"
}
# js <name> <file of JavaScript> [options of node]: node runs it, with the variables
# of $jsenv in its environment when set; it prints "OK ..." or "FAIL ..."
jsenv=""
js() {
    _n="$1"; _f="$2"; shift 2
    # shellcheck disable=SC2086
    _o="$(cd "$T" && env HOME="$T/home" $jsenv "$P/bin/node" "$@" "$_f" 2> "$T/js.err" < /dev/null)"
    _rc=$?
    case "$_o" in
        "OK "*) pass "$_n: ${_o#OK }" ;;
        "FAIL "*) fail "$_n: ${_o#FAIL }" ;;
        *) _e="$(printf '%s\n' "$_o" "$(cat "$T/js.err")" | sed -n '/[^[:space:]]/{p;q;}')"
           fail "$_n: ${_e:-no output}; exit status $_rc" ;;
    esac
}
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
azv() { PKG_CONFIG_LIBDIR=/usr/local/az/lib/pkgconfig pkg-config --modversion "$1" 2>/dev/null; }
export LANG=C.UTF-8

if ! pkg info -e node18; then
    fail "node18 is not installed"
    echo "node18-test: $ok ok, $bad failed" >> "$out"
    exit 1
fi
# one of node18 and node24, with their npm, yarn and corepack
two=""
for p in node24 npm-node24 yarn-node24 corepack-node24; do pkg info -e "$p" && two="$two $p"; done
if [ -z "$two" ]; then pass "one Node.js: none of node24, npm-node24, yarn-node24, corepack-node24 next to node18"
else fail "installed next to node18:$two"; fi
node="$P/bin/node"
v="$("$node" --version 2>&1)"
if [ "$v" = "v$(pkgv node18)" ]; then pass "node --version: $v"; else fail "node --version: $v, the package is $(pkgv node18)"; fi
if libs_of "$node"; then pass "node: $libs_out"; else fail "node: $libs_bad"; fi
for l in libuv libcares libnghttp2 libbrotlidec libicui18n; do
    w="$(ldd "$node" 2>/dev/null | awk -v l="$l" 'index($1, l ".so") == 1 { print $3; exit }')"
    case "$w" in /usr/local/az/lib/*) pass "node: $l of az ($w)" ;; *) fail "node: $l is ${w:-not linked}, not of az" ;; esac
done
w="$(ldd "$node" 2>/dev/null | awk 'index($1, "libllhttp.so") == 1 { print $3; exit }')"
case "$w" in /usr/local/lib/libllhttp.so*) pass "node: libllhttp of www/llhttp ($w)" ;; *) fail "node: libllhttp is ${w:-not linked}, not of www/llhttp" ;; esac
for l in libssl libcrypto libz; do
    w="$(ldd "$node" 2>/dev/null | awk -v l="$l" 'index($1, l ".so") == 1 { print $3; exit }')"
    case "$w" in /lib/* | /usr/lib/*) pass "node: $l of the base system ($w)" ;; *) fail "node: $l is ${w:-not linked}, not of the base system" ;; esac
done
for f in $(pkg query '%Fp' llhttp 2>/dev/null | grep -E '/lib/libllhttp\.so\.[0-9.]+$' | head -n 1); do
    if libs_of "$f"; then pass "llhttp: ${f##*/}: $libs_out"; else fail "llhttp: ${f##*/}: $libs_bad"; fi
done

# the versions node reports: of az, of www/llhttp, of the base system
want="uv=$(azv libuv) ares=$(azv libcares) nghttp2=$(azv libnghttp2) brotli=$(azv libbrotlidec)"
want="$want icu=$(azv icu-i18n) llhttp=$(pkgv llhttp)"
want="$want openssl=$(openssl version 2>/dev/null | awk '{ print $2 }' | sed 's/[a-z-].*//')"
cat > "$T/versions.js" <<'EOF'
'use strict';
const want = process.argv.slice(2).map((s) => s.split('='));
const bad = [], good = [], none = [];
for (const [k, w] of want) {
  const h = process.versions[k];
  if (h === undefined || h === '') { none.push(k); continue; }
  // ICU of az: 76.1 as process.versions has it ("76.1")
  if (w && (h === w || h.startsWith(w + '.') || h.startsWith(w + '-') || h.startsWith(w + '+'))) good.push(`${k} ${h}`);
  else bad.push(`${k} ${h}, not ${w || 'known'}`);
}
if (none.length) bad.push(`not in process.versions: ${none.join(' ')}`);
console.log((bad.length ? 'FAIL ' + bad.join(', ') : 'OK ' + good.join(', ')) +
  `; bundled: ada ${process.versions.ada}, uvwasi ${process.versions.uvwasi}, undici ${process.versions.undici}`);
EOF
# shellcheck disable=SC2086
o="$(HOME="$T/home" "$node" "$T/versions.js" $want 2>&1)"
case "$o" in "OK "*) pass "process.versions: ${o#OK }" ;; *) fail "process.versions: ${o#FAIL }" ;; esac

cat > "$T/intl.js" <<'EOF'
'use strict';
const d = new Intl.DateTimeFormat('ru-RU', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' })
  .format(new Date(Date.UTC(2026, 10, 11)));
const n = new Intl.NumberFormat('de-DE').format(1234567.891);
const ok = d === '11 ноября 2026 г.' && n === '1.234.567,891';
console.log(`${ok ? 'OK' : 'FAIL'} ru-RU "${d}", de-DE "${n}", ICU ${process.versions.icu}, Unicode ${process.versions.unicode}`);
EOF
js intl "$T/intl.js"

if openssl req -x509 -newkey ed25519 -nodes -days 1 -subj /CN=localhost -addext subjectAltName=DNS:localhost \
        -keyout "$T/key.pem" -out "$T/cert.pem" > "$T/openssl.log" 2>&1; then
    cat > "$T/crypto.js" <<'EOF'
'use strict';
const crypto = require('node:crypto'), tls = require('node:tls'), fs = require('node:fs');
const h = crypto.createHash('sha256').update('abc').digest('hex');
const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
const sig = crypto.sign(null, Buffer.from('az'), privateKey);
const v = crypto.verify(null, Buffer.from('az'), publicKey, sig);
if (h !== 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' || !v) {
  console.log(`FAIL sha256 ${h}, ed25519 ${v}`); process.exit(0);
}
const key = fs.readFileSync('key.pem'), cert = fs.readFileSync('cert.pem');
const srv = tls.createServer({ key, cert }, (s) => { s.end('tls of node'); });
srv.listen(0, '127.0.0.1', () => {
  const c = tls.connect({ host: '127.0.0.1', port: srv.address().port, servername: 'localhost', ca: cert }, () => {
    let got = '';
    c.on('data', (b) => { got += b; });
    c.on('end', () => {
      console.log(got === 'tls of node' && c.authorized
        ? `OK sha256, ed25519; TLS ${c.getProtocol()} ${c.getCipher().name}, the certificate verified`
        : `FAIL TLS: "${got}", authorized ${c.authorized} ${c.authorizationError || ''}`);
      srv.close();
    });
  });
  c.on('error', (e) => { console.log(`FAIL TLS: ${e.message}`); srv.close(); });
});
EOF
    js crypto "$T/crypto.js"
else
    fail "crypto: openssl req (the certificate of the test): $(tail -n 1 "$T/openssl.log")"
fi

cat > "$T/zlib.js" <<'EOF'
'use strict';
const z = require('node:zlib');
const s = Buffer.from('the compression of node of azsupport '.repeat(200));
const r = [];
const t = (n, c, d) => { const x = c(s); r.push(`${n} ${s.length} -> ${x.length}`); return d(x).equals(s) && x.length < s.length; };
const ok = t('gzip', z.gzipSync, z.gunzipSync) && t('brotli', z.brotliCompressSync, z.brotliDecompressSync);
console.log(`${ok ? 'OK' : 'FAIL'} ${r.join(', ')}`);
EOF
js zlib "$T/zlib.js"

cat > "$T/http.js" <<'EOF'
'use strict';
const http = require('node:http'), http2 = require('node:http2');
const srv = http.createServer((q, s) => { s.setHeader('content-type', 'text/plain'); s.end(`http ${q.method} ${q.url}`); });
srv.listen(0, '127.0.0.1', async () => {
  let r1;
  try {
    const f = await fetch(`http://127.0.0.1:${srv.address().port}/az?x=1`);
    r1 = `${f.status} "${await f.text()}"`;
  } catch (e) { r1 = `fetch failed: ${e.message}`; }
  srv.close();
  const h2 = http2.createServer((q, s) => { s.end(`h2 ${q.httpVersion}`); });
  h2.listen(0, '127.0.0.1', () => {
    const c = http2.connect(`http://127.0.0.1:${h2.address().port}`);
    const q = c.request({ ':path': '/' });
    let b = '';
    q.setEncoding('utf8');
    q.on('data', (d) => { b += d; });
    q.on('end', () => {
      c.close(); h2.close();
      const ok = r1 === '200 "http GET /az?x=1"' && b === 'h2 2.0';
      console.log(`${ok ? 'OK' : 'FAIL'} fetch: ${r1}; HTTP/2: "${b}"`);
    });
    q.on('error', (e) => { console.log(`FAIL HTTP/2: ${e.message}`); c.close(); h2.close(); });
    q.end();
  });
});
EOF
js http "$T/http.js"

# raw requests to a server of node: the header block ended by \r\n\rX (CVE-2025-23167),
# then a header __proto__ read through req.headersDistinct (CVE-2026-21710); and
# dns.lookup() of a name with a NUL byte (CVE-2026-48930)
cat > "$T/fixes.js" <<'EOF'
'use strict';
const http = require('node:http'), net = require('node:net'), dns = require('node:dns');
const seen = [];
const srv = http.createServer((q, s) => {
  seen.push(q.url);
  let d;
  try { d = q.headersDistinct; } catch (e) { s.end(`threw ${e.code || e.message}`); return; }
  s.end(`own __proto__: ${Object.prototype.hasOwnProperty.call(d, '__proto__') ? d.__proto__.join(',') : 'none'}`);
});
const raw = (port, req) => new Promise((done) => {
  let got = '';
  const c = net.connect(port, '127.0.0.1', () => c.end(req));
  c.on('data', (b) => { got += b; });
  c.on('close', () => done(got));
  c.on('error', () => done(got));
});
srv.listen(0, '127.0.0.1', async () => {
  const port = srv.address().port, r = [];
  let ok = true;
  const a = await raw(port, 'GET /smuggled HTTP/1.1\r\nHost: localhost\r\n\rX\r\n\r\n');
  const a1 = a.split('\r\n')[0];
  if (a1.startsWith('HTTP/1.1 400') && !seen.includes('/smuggled')) r.push(`\\r\\n\\rX: ${a1}`);
  else { ok = false; r.push(`\\r\\n\\rX: "${a1}", the server saw ${seen.join(' ') || 'nothing'}`); }
  const b = await raw(port, 'GET /proto HTTP/1.1\r\nHost: localhost\r\n__proto__: az\r\nConnection: close\r\n\r\n');
  const body = b.split('\r\n\r\n').slice(1).join('');
  if (b.startsWith('HTTP/1.1 200') && body === 'own __proto__: az') r.push(`headersDistinct: "${body}"`);
  else { ok = false; r.push(`headersDistinct: "${b.split('\r\n')[0]}" "${body}"`); }
  srv.close();
  try {
    dns.lookup('localhost\u0000.example.com', () => {});
    ok = false; r.push('dns.lookup with a NUL byte: accepted');
  } catch (e) {
    if (e.code === 'ERR_INVALID_ARG_VALUE') r.push(`dns.lookup with a NUL byte: ${e.code}`);
    else { ok = false; r.push(`dns.lookup with a NUL byte: ${e.code || e.message}`); }
  }
  console.log(`${ok ? 'OK' : 'FAIL'} ${r.join('; ')}`);
});
EOF
js fixes "$T/fixes.js"

# the fixes of www/node18/files/upstream (Node.js 22.23.4 and 22.23.5), each against
# what the vulnerable node does (these checks fail on 18.20.8 without them)
cat > "$T/dns-nul.js" <<'EOF'
'use strict';
// CVE-2026-105482: the resolver methods refuse a name with a NUL byte
const dns = require('node:dns');
const r = [], bad = [];
const name = 'example.com\u0000.trusted.corp';
const tries = [
  ['resolve4', () => dns.resolve4(name, () => {})],
  ['resolve(MX)', () => dns.resolve(name, 'MX', () => {})],
  ['reverse', () => dns.reverse('127.0.0.1\u0000.trusted.corp', () => {})],
  ['Resolver#resolveTxt', () => new dns.Resolver().resolveTxt(name, () => {})],
  ['promises.resolveAny', () => dns.promises.resolveAny(name)],
  ['setLocalAddress', () => new dns.Resolver().setLocalAddress('127.0.0.1\u0000')],
];
for (const [n, f] of tries) {
  try {
    const p = f();
    if (p && typeof p.catch === 'function') p.catch(() => {});
    bad.push(`${n} accepted`);
  } catch (e) {
    if (e.code === 'ERR_INVALID_ARG_VALUE') r.push(n); else bad.push(`${n}: ${e.code || e.message}`);
  }
}
console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK a NUL byte refused (ERR_INVALID_ARG_VALUE) by ${r.join(', ')}`);
setTimeout(() => process.exit(0), 100);
EOF
js "dns (CVE-2026-105482)" "$T/dns-nul.js"

cat > "$T/agent-pending.js" <<'EOF'
'use strict';
// CVE-2026-105481: a free kept-alive socket with data that came before its request
// (not seen yet by the data guard: no poll of the loop since) is not reused
const http = require('node:http');
const poison = 'HTTP/1.1 200 OK\r\nX-Poisoned: true\r\nConnection: keep-alive\r\nContent-Length: 0\r\n\r\n';
let serverSocket;
const srv = http.createServer((q, s) => { serverSocket = serverSocket || q.socket; s.end(q.url); });
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 10000).unref();
srv.listen(0, '127.0.0.1', () => {
  const agent = new http.Agent({ keepAlive: true });
  const options = { host: '127.0.0.1', port: srv.address().port, agent };
  const name = agent.getName(options);
  const r1 = http.request({ ...options, path: '/request1' });
  r1.on('response', (res) => res.resume());
  r1.end();
  r1.on('close', () => process.nextTick(() => {
    const free = agent.freeSockets[name] && agent.freeSockets[name][0];
    if (!free) fail('no free socket after the first request');
    if (typeof free._handle.hasPendingRead !== 'function') fail('no hasPendingRead() on the handle');
    serverSocket.write(poison);
    const deadline = Date.now() + 5000;
    while (!free._handle.hasPendingRead()) if (Date.now() > deadline) fail('the data never arrived');
    const r2 = http.request({ ...options, path: '/request2' });
    r2.end();
    const destroyed = free.destroyed;
    r2.on('response', (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (c) => { body += c; });
      res.on('end', () => {
        agent.destroy(); srv.close();
        const ok = destroyed && body === '/request2' && res.headers['x-poisoned'] === undefined && r2.reusedSocket === false;
        console.log(`${ok ? 'OK' : 'FAIL'} the free socket with data ${destroyed ? 'destroyed' : 'kept'}, the second request got "${body}"${res.headers['x-poisoned'] ? ' and the response sent before it' : ''}${r2.reusedSocket ? ' on the old socket' : ' on a new socket'}`);
      });
    });
    r2.on('error', (e) => fail(`the second request: ${e.message}`));
  }));
});
EOF
js "http.Agent (CVE-2026-105481)" "$T/agent-pending.js"

cat > "$T/tls-identity.js" <<'EOF'
'use strict';
// tls.checkServerIdentity(): an IPv6 host against its IP-Address SAN (which the fix
// of CVE-2026-48618 broke); CVE-2026-106069 and CVE-2026-106072: hosts that are IPv4
// addresses only in a non-canonical form refused
const tls = require('node:tls');
const r = [], bad = [];
const chk = (host, san) => tls.checkServerIdentity(host, { subject: {}, subjectaltname: san });
let e = chk('::1', 'IP Address:0:0:0:0:0:0:0:1');
if (e === undefined) r.push('::1 matches its IP-Address SAN'); else bad.push(`::1: ${e.reason || e.message}`);
for (const [host, san] of [['0127.0.0.1', 'IP Address:87.0.0.1'], ['0177.0.0.1', 'DNS:127.0.0.1'],
  ['0x7f.0.0.1', 'DNS:127.0.0.1'], ['2130706433', 'DNS:127.0.0.1'], ['127.1', 'DNS:127.0.0.1']]) {
  e = chk(host, san);
  if (e && e.code === 'ERR_TLS_CERT_ALTNAME_INVALID' && /non-canonical/.test(e.reason)) r.push(`${host} refused`);
  else bad.push(`${host} (${san}): ${e ? e.reason : 'accepted'}`);
}
e = chk('1.2.3.example', 'DNS:1.2.3.example');
if (e === undefined) r.push('1.2.3.example matches'); else bad.push(`1.2.3.example: ${e.reason}`);
console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK ${r.join(', ')}`);
EOF
js "tls.checkServerIdentity (CVE-2026-106069, CVE-2026-106072)" "$T/tls-identity.js"

# CVE-2026-106074: two processes started from one user-land startup snapshot
cat > "$T/snap-entry.js" <<'EOF'
'use strict';
// built into the snapshot: the random caches filled while it is built
const { randomUUID, randomInt } = require('node:crypto');
const { setDeserializeMainFunction } = require('node:v8').startupSnapshot;
const built = [randomUUID(), randomInt(2 ** 48 - 1)];
setDeserializeMainFunction(() => {
  console.log(JSON.stringify({ built, uuid: [randomUUID(), randomUUID()], int: [randomInt(2 ** 48 - 1), randomInt(2 ** 48 - 1)] }));
});
EOF
cat > "$T/snap-cmp.js" <<'EOF'
'use strict';
let a, b;
try { [a, b] = process.argv.slice(2).map((s) => JSON.parse(s)); } catch (e) {
  console.log(`FAIL the output of the processes: ${JSON.stringify(process.argv.slice(2)).slice(0, 160)}`); process.exit(0);
}
const same = (k) => JSON.stringify(a[k]) === JSON.stringify(b[k]);
const bad = ['uuid', 'int'].filter(same);
console.log(bad.length ? `FAIL the same ${bad.join(' and ')} from both processes of the snapshot`
  : 'OK randomUUID() and randomInt() differ between two processes of one startup snapshot');
EOF
if (cd "$T" && HOME="$T/home" "$node" --snapshot-blob "$T/snap.blob" --build-snapshot "$T/snap-entry.js" > "$T/snap.log" 2>&1 < /dev/null); then
    a="$(cd "$T" && HOME="$T/home" "$node" --snapshot-blob "$T/snap.blob" 2>> "$T/snap.log" < /dev/null)"
    b="$(cd "$T" && HOME="$T/home" "$node" --snapshot-blob "$T/snap.blob" 2>> "$T/snap.log" < /dev/null)"
    o="$(HOME="$T/home" "$node" "$T/snap-cmp.js" "$a" "$b" 2>&1)"
    case "$o" in "OK "*) pass "snapshot (CVE-2026-106074): ${o#OK }" ;; *) fail "snapshot (CVE-2026-106074): ${o#FAIL } $(grep -v '^[[:space:]]*$' "$T/snap.log" | tail -n 1)" ;; esac
else
    fail "snapshot (CVE-2026-106074): node --build-snapshot: $(grep -v '^[[:space:]]*$' "$T/snap.log" | tail -n 1)"
fi

cat > "$T/agent-key.js" <<'EOF'
'use strict';
// CVE-2026-123877: https.Agent keys of different TLS policies differ
const https = require('node:https');
const a = new https.Agent();
const base = { host: 'example.com', port: 443 };
const pairs = [
  ['ca array and ca string', { ca: ['a', 'b'] }, { ca: 'a,b' }],
  ['two secureContext objects', { secureContext: {} }, { secureContext: {} }],
  ['ca string and Buffer', { ca: 'pem' }, { ca: Buffer.from('pem') }],
];
const bad = [], r = [];
for (const [n, x, y] of pairs) {
  if (a.getName({ ...base, ...x }) === a.getName({ ...base, ...y })) bad.push(`${n}: the same key`);
  else r.push(n);
}
const sc = {};
if (a.getName({ ...base, secureContext: sc }) !== a.getName({ ...base, secureContext: sc })) bad.push('one secureContext: two keys');
console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK distinct keys: ${r.join(', ')}; the same policy keeps its key`);
EOF
js "https.Agent (CVE-2026-123877)" "$T/agent-key.js"

cat > "$T/zlib-params.js" <<'EOF'
'use strict';
// CVE-2026-123862: params() then destroy() before its flush: the callback gets the
// error, no internal assertion
const zlib = require('node:zlib');
process.on('uncaughtException', (e) => { console.log(`FAIL ${e.code || ''} ${e.message.split('\n')[0]}`); process.exit(0); });
const d = zlib.createDeflate();
d.write('x');
let done = false;
d.params(9, zlib.constants.Z_DEFAULT_STRATEGY, (err) => {
  done = true;
  console.log(err && err.code === 'ERR_STREAM_DESTROYED'
    ? `OK params() then destroy(): ${err.code}` : `FAIL the callback of params(): ${err ? err.code || err.message : 'no error'}`);
});
d.destroy();
setTimeout(() => { if (!done) console.log('FAIL the callback of params() never came'); }, 2000).unref();
EOF
js "zlib (CVE-2026-123862)" "$T/zlib-params.js"

cat > "$T/undici.js" <<'EOF'
'use strict';
// the undici of Node.js 22.23.4 (UNDICI_NODE of www/node18) in the place of 5.29.0:
// fetch() of a gzip body, a response with more than 5 content-encodings refused
const http = require('node:http'), zlib = require('node:zlib');
const want = '6.29.1';
const srv = http.createServer((q, s) => {
  if (q.url === '/gzip') { s.setHeader('content-encoding', 'gzip'); s.end(zlib.gzipSync('undici of az')); return; }
  s.setHeader('content-encoding', 'gzip, gzip, gzip, gzip, gzip, gzip');
  s.end('x');
});
srv.listen(0, '127.0.0.1', async () => {
  const base = `http://127.0.0.1:${srv.address().port}`;
  const r = [], bad = [];
  if (process.versions.undici === want) r.push(`undici ${want}`); else bad.push(`undici ${process.versions.undici}, not ${want}`);
  try {
    const t = await (await fetch(`${base}/gzip`)).text();
    if (t === 'undici of az') r.push('a gzip body'); else bad.push(`the gzip body "${t}"`);
  } catch (e) { bad.push(`gzip: ${e.message}`); }
  try {
    const res = await fetch(`${base}/six`);
    await res.text();
    bad.push('six content-encodings accepted');
  } catch (e) {
    const m = String(e.cause && e.cause.message || e.message);
    if (/content-encodings/.test(m)) r.push('six content-encodings refused'); else bad.push(`six content-encodings: ${m}`);
  }
  srv.close();
  console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK ${r.join(', ')}`);
});
EOF
js undici "$T/undici.js"

# the fixes of the TLS and HTTP/2 code: the certificates of their checks, made by the
# openssl of the base system (P-256): a root and an intermediate CA with the chain of a
# server for localhost, two CAs with a client certificate each, a server certificate
tlsc=ok
(
    cd "$T" || exit 1
    ec() { openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$1.key"; }
    ca() { ec "$1" && openssl req -new -x509 -key "$1.key" -subj "/CN=$1" -days 2 -out "$1.pem" \
        -addext basicConstraints=critical,CA:TRUE -addext keyUsage=critical,keyCertSign,cRLSign; }
    sign() { ec "$1" && openssl req -new -key "$1.key" -subj "/CN=$1" -out "$1.csr" &&
        openssl x509 -req -in "$1.csr" -CA "$2.pem" -CAkey "$2.key" -CAcreateserial -days 2 -extfile "$3" -out "$1.pem"; }
    printf 'basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\n' > int.ext
    printf 'basicConstraints=CA:FALSE\nsubjectAltName=DNS:localhost\nextendedKeyUsage=serverAuth\n' > srv.ext
    printf 'basicConstraints=CA:FALSE\nextendedKeyUsage=clientAuth\n' > cli.ext
    ca az-root && sign az-intermediate az-root int.ext && sign localhost az-intermediate srv.ext &&
        cat localhost.pem az-intermediate.pem > chain.pem &&
        ca az-ca1 && ca az-ca2 && sign client1 az-ca1 cli.ext && sign client2 az-ca2 cli.ext &&
        ec server && openssl req -new -x509 -key server.key -subj /CN=localhost -days 2 -out server.pem \
            -addext subjectAltName=DNS:localhost
) > "$T/tls-certs.log" 2>&1 || tlsc=""

cat > "$T/spki.js" <<'EOF'
'use strict';
// tls-spki-blocklist.patch: a chain through a blocked intermediate fails with
// CERT_REVOKED, with the ca of the connection and with the default CA store (that of
// the base system, which NODE_EXTRA_CA_CERTS gives the root of the test); node runs
// with --expose-internals for the hooks of the test
const tls = require('node:tls'), fs = require('node:fs'), crypto = require('node:crypto');
let hooks;
try {
  hooks = require('internal/test/binding').internalBinding('crypto');
} catch (e) {
  console.log(`FAIL internalBinding: ${e.message}`); process.exit(0);
}
if (typeof hooks.addBlockedSPKIForTesting !== 'function') {
  console.log('FAIL no addBlockedSPKIForTesting() in the crypto binding'); process.exit(0);
}
const root = fs.readFileSync('az-root.pem');
const spki = crypto.createHash('sha256').update(new crypto.X509Certificate(fs.readFileSync('az-intermediate.pem'))
  .publicKey.export({ type: 'spki', format: 'der' })).digest();
const server = tls.createServer({ key: fs.readFileSync('localhost.key'), cert: fs.readFileSync('chain.pem') },
  (s) => { s.on('error', () => {}); s.end('ok'); });
server.on('tlsClientError', () => {});
const connect = (opts) => new Promise((resolve) => {
  const c = tls.connect({ host: '127.0.0.1', port: server.address().port, servername: 'localhost', ...opts }, () => {
    resolve(c.authorized ? 'authorized' : `unauthorized ${c.authorizationError}`);
    c.destroy();
  });
  c.on('error', (e) => resolve(`error ${e.code}`));
});
server.listen(0, '127.0.0.1', async () => {
  const r = [], bad = [];
  const want = async (name, opts, w) => {
    const g = await connect(opts);
    (g === w ? r : bad).push(`${name}: ${g}`);
  };
  await want('the ca of the connection', { ca: root }, 'authorized');
  await want('the default CA store', {}, 'authorized');
  hooks.addBlockedSPKIForTesting(spki);
  await want('blocked, the ca of the connection', { ca: root }, 'error CERT_REVOKED');
  await want('blocked, the default CA store', {}, 'error CERT_REVOKED');
  await want('blocked, rejectUnauthorized false', { ca: root, rejectUnauthorized: false }, 'unauthorized CERT_REVOKED');
  hooks.clearBlockedSPKIsForTesting();
  await want('cleared', { ca: root }, 'authorized');
  server.close();
  console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK ${r.join('; ')}`);
});
EOF
cat > "$T/sni-ca.js" <<'EOF'
'use strict';
// CVE-2026-123867: an SNI context with a ca and no certificate verifies the client
// certificates of its host against that ca, not against the ca of the server
const tls = require('node:tls'), fs = require('node:fs');
const rd = (f) => fs.readFileSync(f);
const server = tls.createServer({
  key: rd('server.key'), cert: rd('server.pem'), ca: rd('az-ca1.pem'), requestCert: true, rejectUnauthorized: true,
}, (s) => { s.on('error', () => {}); s.end(s.getPeerCertificate().subject.CN); });
server.on('tlsClientError', () => {});
server.addContext('protected.example', { ca: rd('az-ca2.pem') });
const connect = (client, version) => new Promise((resolve) => {
  const c = tls.connect({
    host: '127.0.0.1', port: server.address().port, servername: 'protected.example',
    key: rd(`${client}.key`), cert: rd(`${client}.pem`), rejectUnauthorized: false, minVersion: version, maxVersion: version,
  });
  let d = '';
  c.setEncoding('utf8');
  c.on('data', (x) => { d += x; });
  c.on('error', () => {});
  c.on('close', () => resolve(d));
});
server.listen(0, '127.0.0.1', async () => {
  const r = [], bad = [];
  for (const v of ['TLSv1.2', 'TLSv1.3']) {
    const a = await connect('client1', v), b = await connect('client2', v);
    if (a === '' && b === 'client2') r.push(`${v}: client1 (the ca of the server) refused, client2 (the ca of the context) accepted`);
    else bad.push(`${v}: client1 (the ca of the server) "${a}", client2 (the ca of the context) "${b}"`);
  }
  server.close();
  console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK ${r.join('; ')}`);
});
EOF
cat > "$T/tls-resume.js" <<'EOF'
'use strict';
// CVE-2026-123872: a session is resumed only for the server name it was made for, and a
// TLSSocket with no session id context that verifies client certificates resumes none
const tls = require('node:tls'), net = require('node:net'), fs = require('node:fs');
const key = fs.readFileSync('server.key'), cert = fs.readFileSync('server.pem');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 30000).unref();
// the first raw session the client gets, once the connection is closed
const connect = (port, options) => new Promise((resolve) => {
  let session;
  const s = tls.connect({ host: '127.0.0.1', port, rejectUnauthorized: false, ...options });
  const { onnewsession } = s._handle;
  s._handle.onnewsession = function(id, raw) { session ??= raw; return onnewsession.call(this, id, raw); };
  s.on('session', () => {});
  s.on('error', () => {});
  s.on('close', () => resolve(session));
  s.resume();
});
const listen = (server) => new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(server.address().port)));
(async () => {
  const r = [], bad = [];
  const seen = [];
  const named = tls.createServer({ key, cert }, (s) => {
    seen.push(`${s.servername || '-'} ${s.isSessionReused() ? 'resumed' : 'full'}`);
    setImmediate(() => s.end());
  });
  const port = await listen(named);
  for (const maxVersion of ['TLSv1.2', 'TLSv1.3']) {
    seen.length = 0;
    const a = await connect(port, { servername: 'a.example', maxVersion });
    await connect(port, { servername: 'a.example', maxVersion, session: a });
    await connect(port, { servername: 'b.example', maxVersion, session: a });
    const want = ['a.example full', 'a.example resumed', 'b.example full'];
    if (JSON.stringify(seen) === JSON.stringify(want)) r.push(`${maxVersion}: a session of a.example resumed for a.example, not for b.example`);
    else bad.push(`${maxVersion}: ${seen.join(', ')} (not ${want.join(', ')})`);
  }
  named.close();
  // no session id context: a TLSSocket on a net server
  const reused = [];
  const ctx = tls.createSecureContext({ key, cert });
  const plain = (requestCert) => net.createServer((socket) => {
    const t = new tls.TLSSocket(socket, { isServer: true, secureContext: ctx, requestCert });
    t.on('error', () => {});
    t.on('secure', () => { reused.push(t.isSessionReused()); setImmediate(() => t.end()); });
  });
  const open = plain(false), verifying = plain(true);
  const po = await listen(open), pv = await listen(verifying);
  for (const maxVersion of ['TLSv1.2', 'TLSv1.3']) {
    reused.length = 0;
    const s = await connect(po, { maxVersion });
    await connect(po, { maxVersion, session: s });
    await connect(pv, { maxVersion, session: s });
    if (JSON.stringify(reused) === '[false,true,false]') r.push(`${maxVersion}: no session id context and client certificates: a full handshake`);
    else bad.push(`${maxVersion}: no session id context, resumed ${JSON.stringify(reused)} (not [false,true,false])`);
  }
  open.close(); verifying.close();
  console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK ${r.join('; ')}`);
  process.exit(0);
})();
EOF
cat > "$T/tls-reneg.js" <<'EOF'
'use strict';
// CVE-2026-123872: the second ClientHello of a TLS 1.3 HelloRetryRequest and a TLS 1.2
// renegotiation keep the SNI context chosen for the connection (here one with a ca and
// no certificate, which keeps the certificate of the server)
const tls = require('node:tls'), fs = require('node:fs');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 30000).unref();
const names = [];
const server = tls.createServer({
  key: fs.readFileSync('server.key'), cert: fs.readFileSync('server.pem'), ecdhCurve: 'P-521',
}, (s) => { names.push(s.servername); s.on('error', () => {}); s.resume(); });
server.on('tlsClientError', () => {});
server.addContext('certless.example', { ca: fs.readFileSync('az-ca1.pem') });
const connect = (maxVersion) => new Promise((resolve, reject) => {
  const s = tls.connect({ host: '127.0.0.1', port: server.address().port, servername: 'certless.example',
    rejectUnauthorized: false, maxVersion, ecdhCurve: 'P-256:P-521' }, () => resolve(s));
  s.on('error', reject);
});
server.listen(0, '127.0.0.1', async () => {
  try {
    const retried = await connect('TLSv1.3');
    retried.end();
    const reneg = await connect('TLSv1.2');
    await new Promise((resolve, reject) => reneg.renegotiate({}, (e) => (e ? reject(e) : resolve())));
    reneg.end();
  } catch (e) {
    fail(`${e.code || ''} ${e.message.split('\n')[0]}`);
  }
  server.close();
  const ok = names.length === 2 && names.every((n) => n === 'certless.example');
  console.log(ok ? 'OK a HelloRetryRequest (TLS 1.3) and a renegotiation (TLS 1.2) for certless.example, a context with a ca only'
    : `FAIL the server saw ${JSON.stringify(names)}`);
  process.exit(0);
});
EOF
if [ -n "$tlsc" ]; then
    jsenv="NODE_EXTRA_CA_CERTS=$T/az-root.pem"
    js "tls: the SPKI blocklist (nodejs/node 4342503)" "$T/spki.js" --expose-internals --no-warnings
    jsenv=""
    js "tls: the ca of an SNI context (CVE-2026-123867)" "$T/sni-ca.js"
    js "tls: resumption (CVE-2026-123872)" "$T/tls-resume.js"
    js "tls: HelloRetryRequest and renegotiation (CVE-2026-123872)" "$T/tls-reneg.js"
else
    fail "tls: the certificates of the checks of the TLS fixes: $(grep -v '^[[:space:]]*$' "$T/tls-certs.log" | tail -n 1)"
fi

cat > "$T/h2-abandoned.js" <<'EOF'
'use strict';
// CVE-2026-123865: after GOAWAY(NO_ERROR) from the peer, a protocol error that makes
// nghttp2 end the session internally (an oversized DATA frame) on an open stream:
// the session ends with the error, the stream closes
const http2 = require('node:http2'), net = require('node:net');
const got = [];
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
const t = setTimeout(() => fail(`the session did not end (seen: ${got.join(', ') || 'nothing'})`), 5000);
const server = http2.createServer();
server.on('stream', (stream) => {
  stream.on('error', (e) => got.push(`stream error ${e.code}`));
  stream.on('close', () => got.push('stream close'));
});
server.on('session', (session) => {
  session.on('goaway', () => got.push('goaway'));
  session.on('error', (e) => got.push(`session error ${e.code}`));
  session.on('close', () => {
    got.push('session close');
    clearTimeout(t);
    server.close();
    const ok = got.includes('session error ERR_HTTP2_ERROR') && got.includes('stream close');
    console.log(`${ok ? 'OK' : 'FAIL'} ${got.join(', ')}`);
  });
});
server.listen(0, '127.0.0.1', () => {
  const conn = net.connect({ port: server.address().port, host: '127.0.0.1', allowHalfOpen: true });
  conn.on('error', () => {});
  conn.write('PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n');
  const settings = Buffer.alloc(9); settings[3] = 0x04; conn.write(settings);
  let inbuf = Buffer.alloc(0), state = 'h', len;
  conn.on('data', (chunk) => {
    inbuf = Buffer.concat([inbuf, chunk]);
    if (state === 'h') { if (inbuf.length < 9) return; len = inbuf.readUIntBE(0, 3); inbuf = inbuf.slice(9); state = 's'; }
    if (state === 's') {
      if (inbuf.length < len) return;
      state = 'done';
      const ack = Buffer.alloc(9); ack[3] = 0x04; ack[4] = 0x01; conn.write(ack);
      const block = Buffer.from([0x82, 0x86, 0x84, 0x41, 0x09, ...Buffer.from('localhost')]);
      const headers = Buffer.alloc(9); headers.writeUIntBE(block.length, 0, 3); headers[3] = 0x01; headers[4] = 0x04; headers.writeUInt32BE(1, 5);
      conn.write(Buffer.concat([headers, block]));
      const goaway = Buffer.alloc(17); goaway.writeUIntBE(8, 0, 3); goaway[3] = 0x07; conn.write(goaway);
      const big = Buffer.alloc(9); big.writeUIntBE(16385, 0, 3); big[3] = 0x00; big.writeUInt32BE(1, 5); conn.write(big);
    }
  });
  conn.on('end', () => conn.end());
});
EOF
js "http2: a session ended by nghttp2 after a GOAWAY of the peer (CVE-2026-123865)" "$T/h2-abandoned.js"

cat > "$T/h2-retain.js" <<'EOF'
'use strict';
// CVE-2026-123866: the slices of a destroyed HTTP/2 stream left in a pending socket
// write keep their memory: the DATA the client gets is what the stream wrote, not
// buffers allocated after its write was cancelled (node runs with --expose-gc)
const http2 = require('node:http2'), net = require('node:net');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 30000).unref();
const FIRST_WINDOW = 3000000, SECOND_INCREMENT = 20000000, LARGE = 30000000;
const FIRST_BUF = 80 * 1024, SECOND_BUF = 20 * 1024, SMALL = FIRST_BUF + SECOND_BUF, EXPECTED = 65535;
const frame = (type, flags, id, payload = Buffer.alloc(0)) => {
  const h = Buffer.alloc(9);
  h.writeUIntBE(payload.length, 0, 3); h[3] = type; h[4] = flags; h.writeUInt32BE(id, 5);
  return Buffer.concat([h, payload]);
};
const windowUpdate = (id, inc) => { const p = Buffer.alloc(4); p.writeUInt32BE(inc); return frame(8, 0, id, p); };
const request = (path, id, priority = false) => {
  const authority = Buffer.from('127.0.0.1');
  let payload = Buffer.concat([Buffer.from([0x82, 0x86, 0x01, authority.length]), authority,
    Buffer.from([0x04, path.length]), Buffer.from(path)]);
  let flags = 1 | 4;
  if (priority) {
    const pr = Buffer.alloc(5); pr.writeUInt32BE(0x80000001); pr[4] = 15;
    payload = Buffer.concat([pr, payload]); flags |= 0x20;
  }
  return frame(1, flags, id, payload);
};
const replacement = [];
let resumeClient;
const server = http2.createServer({ maxSessionMemory: 64 });
server.on('stream', (stream, headers) => {
  stream.on('error', () => {});
  stream.respond();
  if (headers[':path'] === '/A') { stream.end(Buffer.alloc(LARGE, 0x41)); return; }
  stream.on('close', () => setImmediate(() => {
    globalThis.gc();
    replacement.push(...Array.from({ length: 32 }, () => Buffer.alloc(FIRST_BUF, 0x56)));
    resumeClient();
  }));
  stream.setTimeout(1500, () => stream.destroy());
  stream.cork();
  stream.write(Buffer.alloc(FIRST_BUF, 0x53));
  stream.end(Buffer.alloc(SECOND_BUF, 0x53));
});
server.listen(0, '127.0.0.1', () => {
  const socket = net.connect(server.address().port, '127.0.0.1');
  socket.on('error', () => {});
  let received = Buffer.alloc(0), s1 = 0, second = false, paused = false, done = false;
  const s3 = [];
  resumeClient = () => socket.resume();
  const onS1 = () => {
    if (!second) {
      if (s1 < FIRST_WINDOW) return;
      second = true;
      socket.write(Buffer.concat([request('/S', 3, true), windowUpdate(0, SECOND_INCREMENT + SMALL),
        windowUpdate(1, SECOND_INCREMENT)]));
      return;
    }
    if (paused || s1 <= FIRST_WINDOW) return;
    paused = true;
    socket.pause();
  };
  socket.on('connect', () => socket.write(Buffer.concat([Buffer.from('PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n'),
    frame(4, 0, 0), request('/A', 1), windowUpdate(0, FIRST_WINDOW - 65535), windowUpdate(1, FIRST_WINDOW - 65535)])));
  socket.on('data', (chunk) => {
    if (done) return;
    received = Buffer.concat([received, chunk]);
    let off = 0;
    while (off + 9 <= received.length) {
      const len = received.readUIntBE(off, 3);
      if (off + 9 + len > received.length) break;
      const type = received[off + 3], id = received.readUInt32BE(off + 5) & 0x7fffffff;
      if (type === 0 && id === 3) s3.push(received.subarray(off + 9, off + 9 + len));
      else if (type === 0 && id === 1) { s1 += len; onS1(); }
      off += 9 + len;
    }
    received = received.subarray(off);
    const payload = Buffer.concat(s3);
    if (payload.length < EXPECTED) return;
    done = true;
    socket.destroy(); server.close();
    const ok = payload.length === EXPECTED && payload.equals(Buffer.alloc(EXPECTED, 0x53));
    console.log(ok ? `OK the ${EXPECTED} bytes of DATA of the reset stream are those it wrote`
      : `FAIL the DATA of the reset stream came from other memory (${payload.indexOf(0x56) >= 0 ? 'the buffers made after the reset' : 'not what it wrote'})`);
    process.exit(0);
  });
});
EOF
js "http2: the DATA of a reset stream in a pending write (CVE-2026-123866)" "$T/h2-retain.js" --expose-gc

cat > "$T/h2-memory.js" <<'EOF'
'use strict';
// CVE-2026-123868: 1-byte DATA frames on HTTP/2 streams the application does not read
// count against maxSessionMemory (1 MB here): the session stops reading instead of
// buffering every frame (4 streams of 65535 frames, each within the window of its
// stream: 262140 chunks buffered without the fix)
const http2 = require('node:http2'), net = require('node:net');
const kStreams = 4, kFrames = 65535;
const streams = new Set();
let peak = 0, probe = null;
const frame = (type, flags, id, payload) => {
  const h = Buffer.alloc(9);
  h.writeUIntBE(payload.length, 0, 3); h[3] = type; h[4] = flags; h.writeUInt32BE(id, 5);
  return Buffer.concat([h, payload]);
};
const server = http2.createServer({ maxSessionMemory: 1 });
server.on('session', (s) => s.on('error', () => {}));
server.on('stream', (stream) => {
  stream.on('error', () => {});
  streams.add(stream);
  probe ??= setInterval(() => {
    let total = 0;
    for (const s of streams) total += s.readableLength;
    peak = Math.max(peak, total);
  }, 10);
});
server.listen(0, '127.0.0.1', () => {
  const sock = net.connect(server.address().port, '127.0.0.1');
  sock.on('error', () => {});
  sock.on('connect', () => {
    sock.write(Buffer.from('PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n'));
    sock.write(frame(4, 0, 0, Buffer.alloc(0)));
  });
  let acked = false;
  sock.on('data', (chunk) => {
    if (acked || chunk.length < 9 || chunk[3] !== 4) return;
    acked = true;
    sock.write(Buffer.from([0, 0, 0, 4, 1, 0, 0, 0, 0]));
    const hpack = Buffer.from([0x83, 0x86, 0x84, 0x01, 0x01, 0x61]);
    const one = Buffer.alloc(1, 0x61);
    for (let s = 0; s < kStreams; s++) {
      const id = 1 + 2 * s;
      const parts = [frame(1, 4, id, hpack)];
      for (let i = 0; i < kFrames; i++) parts.push(frame(0, 0, id, one));
      sock.write(Buffer.concat(parts));
    }
  });
  setTimeout(() => {
    clearInterval(probe);
    sock.destroy();
    server.close();
    console.log(peak > 0 && peak < kFrames
      ? `OK at most ${peak} chunks buffered by the undrained streams (maxSessionMemory 1 MB)`
      : `FAIL ${peak} chunks buffered by the undrained streams, not bounded by maxSessionMemory (1 MB)`);
    process.exit(0);
  }, 4000);
});
EOF
js "http2: undrained streams and maxSessionMemory (CVE-2026-123868)" "$T/h2-memory.js"

cat > "$T/h2-altsvc.js" <<'EOF'
'use strict';
// CVE-2026-123828: ALTSVC frames with an origin and a value over 1 KiB (the buffers of
// Http2Session::AltSvc() on the heap): sent and received whole
const http2 = require('node:http2');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 10000).unref();
const longOrigin = `https://${'a'.repeat(1040)}`;
const longAlt = `h2=":${'8'.repeat(1042)}"`;
const server = http2.createServer();
server.on('session', (session) => {
  session.altsvc('h2=":8001"', longOrigin);
  session.altsvc(longAlt, 'https://example.org:8112');
});
server.listen(0, '127.0.0.1', () => {
  const client = http2.connect(`http://127.0.0.1:${server.address().port}`);
  client.on('error', (e) => fail(e.message));
  const got = [];
  client.on('altsvc', (alt, origin, stream) => {
    got.push([alt, origin, stream]);
    if (got.length < 2) return;
    client.close(); server.close();
    const ok = got.some(([a, o, s]) => a === 'h2=":8001"' && o === longOrigin && s === 0) &&
      got.some(([a, o, s]) => a === longAlt && o === 'https://example.org:8112' && s === 0);
    console.log(ok ? `OK an origin of ${longOrigin.length} bytes and a value of ${longAlt.length} bytes received whole`
      : `FAIL ${got.map(([a, o]) => `${a.length}/${o.length}`).join(' ')}`);
  });
});
EOF
js "http2: ALTSVC over 1 KiB (CVE-2026-123828)" "$T/h2-altsvc.js"

cat > "$T/wasi.js" <<'EOF'
'use strict';
const { WASI } = require('node:wasi');
const b = Uint8Array.from([
  0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
  0x01, 0x0c, 0x02, 0x60, 0x04, 0x7f, 0x7f, 0x7f, 0x7f, 0x01, 0x7f, 0x60, 0x00, 0x00,
  0x02, 0x23, 0x01, 0x16, ...Buffer.from('wasi_snapshot_preview1'), 0x08, ...Buffer.from('fd_write'), 0x00, 0x00,
  0x03, 0x02, 0x01, 0x01,
  0x05, 0x03, 0x01, 0x00, 0x01,
  0x07, 0x13, 0x02, 0x06, ...Buffer.from('memory'), 0x02, 0x00, 0x06, ...Buffer.from('_start'), 0x00, 0x01,
  0x0a, 0x1d, 0x01, 0x1b, 0x00, 0x41, 0x00, 0x41, 0x08, 0x36, 0x02, 0x00, 0x41, 0x04, 0x41, 0x03,
  0x36, 0x02, 0x00, 0x41, 0x01, 0x41, 0x00, 0x41, 0x01, 0x41, 0x14, 0x10, 0x00, 0x1a, 0x0b,
  0x0b, 0x09, 0x01, 0x00, 0x41, 0x08, 0x0b, 0x03, 0x68, 0x69, 0x0a,
]);
// Node 18: no options.version and no getImportObject(); the imports of preview1
const wasi = new WASI({ args: [], env: {}, returnOnExit: true });
wasi.start(new WebAssembly.Instance(new WebAssembly.Module(b), { wasi_snapshot_preview1: wasi.wasiImport }));
EOF
w="$(HOME="$T/home" "$node" "$T/wasi.js" 2> "$T/wasi.err")"
if [ "$w" = hi ]; then pass "wasi: a module wrote \"hi\" through fd_write"; else fail "wasi: \"$w\" $(grep -v -i 'experimental' "$T/wasi.err" | head -n 1)"; fi

cat > "$T/url.js" <<'EOF'
'use strict';
const u = new URL('https://пример.рф/путь?x=1#y');
const ok = u.hostname === 'xn--e1afmkfd.xn--p1ai' && u.pathname === '/%D0%BF%D1%83%D1%82%D1%8C';
console.log(`${ok ? 'OK' : 'FAIL'} ${u.href}`);
EOF
js url "$T/url.js"

# npm and npx: a package made here, packed and installed offline
if pkg info -e npm-node18; then
    v="$(HOME="$T/home" "$P/bin/npm" --version 2>&1)"
    if [ "$v" = "$(pkgv npm-node18)" ]; then pass "npm --version: $v"; else fail "npm --version: $v, the package is $(pkgv npm-node18)"; fi
    v="$(HOME="$T/home" "$P/bin/npx" --version 2>&1)"
    [ "$v" = "$(pkgv npm-node18)" ] && pass "npx --version: $v" || fail "npx --version: $v"
    v="$(HOME="$T/home" "$P/bin/node-gyp" --version 2>&1)"
    case "$v" in v[0-9]*) pass "node-gyp --version: $v" ;; *) fail "node-gyp --version: $v" ;; esac
    mkdir -p "$T/pkg" "$T/app"
    printf '{ "name": "az-test", "version": "1.0.0", "main": "index.js" }\n' > "$T/pkg/package.json"
    echo 'module.exports = () => "az-test of npm";' > "$T/pkg/index.js"
    printf '{ "name": "az-app", "version": "1.0.0", "private": true }\n' > "$T/app/package.json"
    if (cd "$T/pkg" && HOME="$T/home" "$P/bin/npm" pack --pack-destination "$T" > "$T/npm.log" 2>&1) &&
            [ -f "$T/az-test-1.0.0.tgz" ] &&
            (cd "$T/app" && HOME="$T/home" "$P/bin/npm" install --offline --no-audit --no-fund "$T/az-test-1.0.0.tgz" >> "$T/npm.log" 2>&1); then
        r="$(cd "$T/app" && "$node" -e 'console.log(require("az-test")())' 2>&1)"
        [ "$r" = "az-test of npm" ] && pass "npm pack and npm install --offline: $r" || fail "npm install: require gives \"$r\""
    else
        fail "npm pack and install: $(tail -n 2 "$T/npm.log" | tr '\n' ' ')"
    fi
    cat > "$T/npm-deps.js" <<'EOF'
'use strict';
// brace-expansion and ip-address of www/npm-node18 (BRACE_EXPANSION_VERSION and
// IP_ADDRESS_VERSION) in the place of the 2.0.2 and 10.1.0 of npm 10.9.10, at work
// through what takes them in npm (minimatch, socks); ip-address refuses an IPv4
// address with a leading zero, which 10.1.0 took as decimal (CVE-2026-69192)
const m = `${process.env.NPM_ROOT}/node_modules/`;
const want = { 'brace-expansion': '2.1.8', 'ip-address': '10.7.6' };
const r = [], bad = [];
for (const [n, v] of Object.entries(want)) {
  let h;
  try { h = require(`${m}${n}/package.json`).version; } catch (e) { h = e.code || e.message; }
  if (h === v) r.push(`${n} ${h}`); else bad.push(`${n} ${h}, not ${v}`);
}
try {
  const { minimatch } = require(`${m}minimatch`);
  if (minimatch('lib/b.js', 'lib/{a,b}.js') && !minimatch('lib/c.js', 'lib/{a,b}.js')) r.push('minimatch lib/{a,b}.js');
  else bad.push('minimatch lib/{a,b}.js: not as it should match');
} catch (e) { bad.push(`minimatch: ${e.message}`); }
try {
  const { ipToBuffer } = require(`${m}socks/build/common/helpers.js`);
  const a = ipToBuffer('127.0.0.1').toString('hex'), b = ipToBuffer('::1').toString('hex');
  if (a === '7f000001' && b === `${'0'.repeat(31)}1`) r.push('socks 127.0.0.1 and ::1');
  else bad.push(`socks: 127.0.0.1 ${a}, ::1 ${b}`);
} catch (e) { bad.push(`socks: ${e.message}`); }
try {
  const { Address4 } = require(`${m}ip-address`);
  let x;
  try { x = new Address4('010.0.0.1').correctForm(); } catch (e) { x = e.name; }
  if (x === 'AddressError') r.push('010.0.0.1 refused'); else bad.push(`010.0.0.1 taken as ${x} (CVE-2026-69192)`);
} catch (e) { bad.push(`ip-address: ${e.message}`); }
console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK ${r.join(', ')}`);
EOF
    cat > "$T/npm-gitsha.js" <<'EOF'
'use strict';
// CVE-2026-9496 (files/patch-CVE-2026-9496 of www/npm-node18): addGitSha() of both
// pacote of npm on the spec of the upstream test, a git URL of a host hosted-git-info
// does not know with 100000 # and a newline after them, which /#.*$/ took seconds
// over and kept whole; and a spec of npm-package-arg with two committishes, which
// both strip as before
const m = `${process.env.NPM_ROOT}/node_modules/`;
const base = 'git+ssh://git@some-host/user/repo';
const evil = { hosted: null, rawSpec: `${base}${'#'.repeat(1e5)}\nx` };
const plain = 'git+ssh://git@some-host:user/repo';
const r = [], bad = [];
let npa;
try { npa = require(`${m}npm-package-arg`); } catch (e) { console.log(`FAIL npm-package-arg: ${e.message}`); process.exit(0); }
for (const p of ['pacote', '@npmcli/metavuln-calculator/node_modules/pacote']) {
  let v, addGitSha;
  try {
    v = require(`${m}${p}/package.json`).version;
    addGitSha = require(`${m}${p}/lib/util/add-git-sha.js`);
  } catch (e) { bad.push(`${p}: ${e.message}`); continue; }
  const t = process.hrtime.bigint();
  const got = addGitSha(evil, 'sha');
  const ms = Number(process.hrtime.bigint() - t) / 1e6;
  const two = addGitSha(npa(`${plain}#othersha#otherothersha`), 'sha');
  if (got === `${base}#sha` && ms < 1000 && two === `${plain}#sha`) r.push(`pacote ${v} in ${ms.toFixed(2)} ms`);
  else bad.push(`pacote ${v}: ${got === `${base}#sha` ? 'stripped' : `${got.length - base.length - 4} characters of the committish kept`} in ${ms.toFixed(0)} ms, two committishes: ${two}`);
}
console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK the spec of 100000 # and a newline stripped by ${r.join(', ')}; two committishes stripped`);
EOF
    jsenv="NPM_ROOT=$P/lib/node_modules/npm"
    js "npm: brace-expansion and ip-address of the registry" "$T/npm-deps.js"
    js "npm: addGitSha() of both pacote (CVE-2026-9496)" "$T/npm-gitsha.js"
    jsenv=""
else
    note "npm-node18 is not installed: not tested"
fi
if pkg info -e yarn-node18; then
    v="$(HOME="$T/home" "$P/bin/yarn" --version 2>&1)"
    if [ "$v" = "$(pkgv yarn-node18)" ]; then pass "yarn --version: $v"; else fail "yarn --version: $v, the package is $(pkgv yarn-node18)"; fi
    mkdir -p "$T/yarn"
    if (cd "$T/yarn" && HOME="$T/home" "$P/bin/yarn" init -y > "$T/yarn.log" 2>&1) && [ -f "$T/yarn/package.json" ]; then
        pass "yarn init -y: package.json"
    else
        fail "yarn init -y: $(tail -n 1 "$T/yarn.log")"
    fi
else
    note "yarn-node18 is not installed: not tested"
fi
if pkg info -e corepack-node18; then
    v="$(HOME="$T/home" "$P/bin/corepack" --version 2>&1)"
    if [ "$v" = "$(pkgv corepack-node18)" ]; then pass "corepack --version: $v"; else fail "corepack --version: $v, the package is $(pkgv corepack-node18)"; fi
    mkdir -p "$T/shims"
    if HOME="$T/home" "$P/bin/corepack" enable --install-directory "$T/shims" pnpm > "$T/corepack.log" 2>&1 &&
            [ -e "$T/shims/pnpm" ]; then
        pass "corepack enable: the shim pnpm"
    else
        fail "corepack enable: $(tail -n 1 "$T/corepack.log")"
    fi
else
    fail "corepack-node18 is not installed (a dependency of node18)"
fi

echo "node18-test: $ok ok, $bad failed" >> "$out"
[ "$bad" = 0 ]
