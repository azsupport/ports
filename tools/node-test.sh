#!/bin/sh
# node-test.sh - test Node.js of the repository az, installed from it (aZ,
# 11.11.2026): node24 with npm-node24, yarn-node24 and corepack-node24, on the libraries of
# az and those that Node.js bundles as ports of this tree. node loads only libraries
# of the base system, of az (/usr/local/az/lib) and of our ports (ada, llhttp,
# nbytes, nghttp3, ngtcp2, simdjson, uvwasi, hdr_histogram), and the versions it
# reports (process.versions) are those of az (pkg-config), of our ports (pkg) and of
# the OpenSSL of the base system. And:
#   intl      the ICU of az with its data: a date of ru-RU in Cyrillic, a number of
#             de-DE, the ICU version
#   crypto    SHA-256, an Ed25519 signature; TLS 1.3 between a server and a client of
#             node on 127.0.0.1 with a certificate of the openssl of the base system
#   zlib      gzip (zlib of the base system), brotli and zstd (of az) round trips
#   http      a server and fetch() on 127.0.0.1 (llhttp, undici); HTTP/2 without TLS
#             (nghttp2)
#   sqlite    node:sqlite: a table in memory, sqlite_version() that of az, a session
#             and its changeset (the session extension of the SQLite of az)
#   wasi      node:wasi: a WebAssembly module made here writes to stdout (uvwasi)
#   url       an IDN host in Punycode (ada)
#   fixes     the fixes of the security release of 11.11.2026 (24.22.3) in work, each
#             failing on 24.22.2 (the official builds of Linux; certificates made
#             here by the openssl of the base system): TLS: the ca of an SNI context
#             with no certificate (CVE-2026-123867), a session resumed only for its
#             server name and none without a session id context and with client
#             certificates, a HelloRetryRequest and a renegotiation keeping the SNI
#             context (CVE-2026-123872), server sockets destroyed before the
#             deferred onclienthello and oncertcb (CVE-2026-126051), an empty write
#             in the on_body of the HTTP parser of an https server (CVE-2026-123864),
#             https.Agent keys per TLS policy (CVE-2026-123877); the credentials of a
#             proxy URL out of the messages of ERR_PROXY_INVALID_CONFIG
#             (CVE-2026-123871); zlib params() then destroy() (CVE-2026-123862);
#             HTTP/2: a session ended by nghttp2 after a GOAWAY of the peer
#             (CVE-2026-123865), the DATA of a reset stream in a pending write
#             (CVE-2026-123866), undrained streams bounded by maxSessionMemory
#             (CVE-2026-123868), ALTSVC over 1 KiB (CVE-2026-123828), streams reset
#             for too many trailers that outlive their session (CVE-2026-123863),
#             file responses reset with a write pending (CVE-2026-123874; node with
#             --expose-gc where the check collects), cancelled file downloads
#             (CVE-2026-123875). No check of CVE-2026-123829 and CVE-2026-123873:
#             the Permission Model, which none of our uses turns on
#   npm       npm and npx, npm pack of a package made here and npm install of it
#             offline; node-gyp
#   yarn      yarn init; corepack enable into a directory of its own
#
# Usage (FreeBSD, as root, the packages installed): sh tools/node-test.sh
# Results: node-results/tests.txt (one line per check, the summary at the end);
# exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/node-results}"
T="${NODE_TEST_WORK:-/var/tmp/node-test}"
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
ours="libada libllhttp libnbytes libnghttp3 libngtcp2 libsimdjson libuvwasi libhdr_histogram"
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
# js <name> <file of JavaScript> [options of node]: node runs it; it prints "OK ..."
# or "FAIL ..."
js() {
    _n="$1"; _f="$2"; shift 2
    _o="$(cd "$T" && HOME="$T/home" "$P/bin/node" "$@" "$_f" 2> "$T/js.err" < /dev/null)"
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

if ! pkg info -e node24; then
    fail "node24 is not installed"
    echo "node-test: $ok ok, $bad failed" >> "$out"
    exit 1
fi
node="$P/bin/node"
v="$("$node" --version 2>&1)"
if [ "$v" = "v$(pkgv node24)" ]; then pass "node --version: $v"; else fail "node --version: $v, the package is $(pkgv node24)"; fi
if libs_of "$node"; then pass "node: $libs_out"; else fail "node: $libs_bad"; fi
for l in libuv libcares libnghttp2 libbrotlidec libzstd libsqlite3 libicui18n; do
    w="$(ldd "$node" 2>/dev/null | awk -v l="$l" 'index($1, l ".so") == 1 { print $3; exit }')"
    case "$w" in /usr/local/az/lib/*) pass "node: $l of az ($w)" ;; *) fail "node: $l is ${w:-not linked}, not of az" ;; esac
done
for l in libssl libcrypto libz; do
    w="$(ldd "$node" 2>/dev/null | awk -v l="$l" 'index($1, l ".so") == 1 { print $3; exit }')"
    case "$w" in /lib/* | /usr/lib/*) pass "node: $l of the base system ($w)" ;; *) fail "node: $l is ${w:-not linked}, not of the base system" ;; esac
done
for d in libada llhttp nbytes libnghttp3 libngtcp2 simdjson uvwasi hdr_histogram; do
    for f in $(pkg query '%Fp' "$d" 2>/dev/null | grep -E '/lib/lib[^/]*\.so\.[0-9.]+$|/lib/libuvwasi\.so$' | head -n 1); do
        if libs_of "$f"; then pass "$d: ${f##*/}: $libs_out"; else fail "$d: ${f##*/}: $libs_bad"; fi
    done
done

# the versions node reports: of az, of our ports, of the base system
want="uv=$(azv libuv) ares=$(azv libcares) nghttp2=$(azv libnghttp2) brotli=$(azv libbrotlidec)"
want="$want zstd=$(azv libzstd) sqlite=$(azv sqlite3) icu=$(azv icu-i18n)"
want="$want ada=$(pkgv libada) llhttp=$(pkgv llhttp) nbytes=$(pkgv nbytes) nghttp3=$(pkgv libnghttp3)"
want="$want ngtcp2=$(pkgv libngtcp2) simdjson=$(pkgv simdjson) uvwasi=$(pkgv uvwasi)"
want="$want openssl=$(openssl version 2>/dev/null | awk '{ print $2 }' | sed 's/[a-z-].*//')"
cat > "$T/versions.js" <<'EOF'
'use strict';
const want = process.argv.slice(2).map((s) => s.split('='));
const bad = [], good = [], none = [];
for (const [k, w] of want) {
  const h = process.versions[k];
  // nghttp3 and ngtcp2 are empty without QUIC (not built)
  if (h === undefined || h === '') { none.push(k); continue; }
  // ICU of az: 76.1 as process.versions has it ("76.1")
  if (w && (h === w || h.startsWith(w + '.') || h.startsWith(w + '-') || h.startsWith(w + '+'))) good.push(`${k} ${h}`);
  else bad.push(`${k} ${h}, not ${w || 'known'}`);
}
console.log((bad.length ? 'FAIL ' + bad.join(', ') : 'OK ' + good.join(', ')) +
  (none.length ? `; not in process.versions: ${none.join(' ')}` : ''));
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
let ok = t('gzip', z.gzipSync, z.gunzipSync) && t('brotli', z.brotliCompressSync, z.brotliDecompressSync);
if (typeof z.zstdCompressSync === 'function') ok = t('zstd', z.zstdCompressSync, z.zstdDecompressSync) && ok;
else { ok = false; r.push('no zlib.zstdCompressSync'); }
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

cat > "$T/sqlite.js" <<'EOF'
'use strict';
const { DatabaseSync } = require('node:sqlite');
const db = new DatabaseSync(':memory:');
const v = db.prepare('SELECT sqlite_version() AS v').get().v;
db.exec('CREATE TABLE t (id INTEGER PRIMARY KEY, a TEXT)');
const s = db.createSession();
db.prepare('INSERT INTO t (a) VALUES (?)').run('az');
const ch = s.changeset();
const n = db.prepare('SELECT count(*) AS n FROM t').get().n;
const ok = v === process.versions.sqlite && n === 1 && ch.length > 0;
console.log(`${ok ? 'OK' : 'FAIL'} SQLite ${v}, a row, a changeset of ${ch.length} bytes`);
EOF
js sqlite "$T/sqlite.js"

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
const wasi = new WASI({ version: 'preview1', args: [], env: {}, returnOnExit: true });
wasi.start(new WebAssembly.Instance(new WebAssembly.Module(b), wasi.getImportObject()));
EOF
w="$(HOME="$T/home" "$node" "$T/wasi.js" 2> "$T/wasi.err")"
if [ "$w" = hi ]; then pass "wasi: a module wrote \"hi\" through fd_write"; else fail "wasi: \"$w\" $(head -n 1 "$T/wasi.err")"; fi

cat > "$T/url.js" <<'EOF'
'use strict';
const u = new URL('https://пример.рф/путь?x=1#y');
const ok = u.hostname === 'xn--e1afmkfd.xn--p1ai' && u.pathname === '/%D0%BF%D1%83%D1%82%D1%8C';
console.log(`${ok ? 'OK' : 'FAIL'} ${u.href}`);
EOF
js url "$T/url.js"

# the fixes of the security release of 11.11.2026 (24.22.3): the certificates of the
# TLS checks, made by the openssl of the base system (P-256): a server certificate for
# localhost, two CAs with a client certificate each
tlsc=ok
(
    cd "$T" || exit 1
    ec() { openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$1.key"; }
    ca() { ec "$1" && openssl req -new -x509 -key "$1.key" -subj "/CN=$1" -days 2 -out "$1.pem" \
        -addext basicConstraints=critical,CA:TRUE -addext keyUsage=critical,keyCertSign,cRLSign; }
    sign() { ec "$1" && openssl req -new -key "$1.key" -subj "/CN=$1" -out "$1.csr" &&
        openssl x509 -req -in "$1.csr" -CA "$2.pem" -CAkey "$2.key" -CAcreateserial -days 2 -extfile "$3" -out "$1.pem"; }
    printf 'basicConstraints=CA:FALSE\nextendedKeyUsage=clientAuth\n' > cli.ext
    ca az-ca1 && ca az-ca2 && sign client1 az-ca1 cli.ext && sign client2 az-ca2 cli.ext &&
        ec server && openssl req -new -x509 -key server.key -subj /CN=localhost -days 2 -out server.pem \
            -addext subjectAltName=DNS:localhost
) > "$T/tls-certs.log" 2>&1 || tlsc=""

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
cat > "$T/tls-destroyed.js" <<'EOF'
'use strict';
// CVE-2026-126051: a TLS server socket destroyed after its ClientHello was read and
// before the deferred onclienthello and oncertcb callbacks ran is ignored by them
// (both paths: OCSP stapling asked for, and the session callbacks of 'newSession')
const tls = require('node:tls'), fs = require('node:fs'), { once } = require('node:events');
const { Duplex } = require('node:stream');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 10000).unref();
process.on('uncaughtException', (e) => fail(`${e.name}: ${e.message}`));
const key = fs.readFileSync('server.key'), cert = fs.readFileSync('server.pem');
// a ClientHello with no SNI that asks for OCSP stapling
const getClientHello = async () => {
  let resolve;
  const written = new Promise((r) => { resolve = r; });
  const client = tls.connect({ host: '127.0.0.1', requestOCSP: true,
    socket: new Duplex({ read() {}, write: resolve }) });
  client.on('error', () => {});
  const hello = await written;
  client.destroy();
  return hello;
};
// the hello and its end in one tick: the socket goes before the deferred callbacks
const sendHelloThenClose = async (server, hello) => {
  server.on('secureConnection', () => fail('a secure connection'));
  const connection = new Duplex({ allowHalfOpen: false, autoDestroy: false, read() {},
    write(chunk, encoding, callback) { callback(); } });
  server.emit('connection', connection);
  connection.push(hello);
  connection.push(null);
  const [err] = await once(server, 'tlsClientError');
  return err.code;
};
(async () => {
  const hello = await getClientHello();
  const a = await sendHelloThenClose(tls.createServer({ key, cert, SNICallback: () => fail('SNICallback') }), hello);
  const sessionServer = tls.createServer({ key, cert });
  sessionServer.on('newSession', () => fail('newSession'));
  const b = await sendHelloThenClose(sessionServer, hello);
  setImmediate(() => console.log(a === 'ECONNRESET' && b === 'ECONNRESET'
    ? 'OK two server sockets destroyed before their deferred callbacks: ECONNRESET, no crash'
    : `FAIL the errors of the destroyed sockets: ${a}, ${b}`));
})();
EOF
cat > "$T/https-nested.js" <<'EOF'
'use strict';
// CVE-2026-123864: an empty write on a TLS socket from the on_body of the HTTP parser
// (res.end() of a HEAD request with early headers) no longer runs the parser inside
// itself: the body of the next request is what the client sent
const https = require('node:https'), net = require('node:net'), tls = require('node:tls');
const fs = require('node:fs'), { Duplex } = require('node:stream');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out: the connections of the test did not end'), 15000).unref();
// holds back writes, so that several TLS records reach the server in one TCP write
class Batch extends Duplex {
  constructor(socket) {
    super();
    this.socket = socket; this.hold = false; this.queue = [];
    socket.on('data', (c) => this.push(c));
    socket.on('end', () => this.push(null));
    socket.on('close', () => this.destroy());
  }
  _read() {}
  _write(chunk, encoding, callback) { if (this.hold) this.queue.push(chunk); else this.socket.write(chunk); callback(); }
  _final(callback) { this.socket.end(callback); }
  _destroy(err, callback) { this.socket.destroy(); callback(err); }
  flush() { this.hold = false; this.socket.write(Buffer.concat(this.queue)); this.queue = []; }
}
const options = { key: fs.readFileSync('server.key'), cert: fs.readFileSync('server.pem') };
const run = (record, tail) => new Promise((resolve) => {
  const bodies = [];
  const server = https.createServer(options, (req, res) => {
    res.flushHeaders();
    const chunks = [];
    bodies.push(chunks);
    req.on('data', (c) => chunks.push(c));
    req.on('error', () => {});
    req.on('end', () => res.end('done'));
  });
  server.listen(0, '127.0.0.1', () => {
    const batch = new Batch(net.connect(server.address().port, '127.0.0.1'));
    const socket = tls.connect({ socket: batch, rejectUnauthorized: false }, () => {
      socket.write('HEAD / HTTP/1.1\r\nHost: x\r\nTransfer-Encoding: chunked\r\n\r\n');
    });
    let response = '';
    socket.setEncoding('utf8');
    socket.on('data', (c) => { response += c; if (response.endsWith('\r\n4\r\ndone\r\n0\r\n\r\n')) socket.end(); });
    socket.on('error', () => {});
    socket.once('data', () => {
      batch.hold = true;
      socket.write('0\r\n\r\nPOST / HTTP/1.1\r\nHost: x\r\nTransfer-Encoding: chunked\r\n\r\n1\r\nZ', () => {
        socket.write(record, () => { batch.flush(); if (tail) socket.write(tail); });
      });
    });
    socket.on('close', () => {
      server.close();
      resolve({ bodies: bodies.map((c) => Buffer.concat(c).toString('latin1')), response });
    });
  });
});
(async () => {
  const a = await run('\r\n5\r\nHE', 'LLO\r\n0\r\n\r\n');
  const okA = JSON.stringify(a.bodies) === JSON.stringify(['', 'ZHELLO']) &&
    a.response.split('HTTP/1.1 200 OK\r\n').length === 3 && a.response.split('done').length === 2;
  const b = await run('5\r\nHE', null);
  const okB = JSON.stringify(b.bodies) === JSON.stringify(['', 'Z']) && /^HTTP\/1\.1 200 OK\r\n/.test(b.response);
  console.log(okA && okB ? 'OK the bodies of the second requests are "ZHELLO" and "Z", as sent'
    : `FAIL the bodies of the second requests: ${JSON.stringify(a.bodies[1] || '').slice(0, 60)}, ${JSON.stringify(b.bodies[1] || '').slice(0, 60)} (not "ZHELLO", "Z")`);
  process.exit(0);
})();
EOF
if [ -n "$tlsc" ]; then
    js "tls: the ca of an SNI context (CVE-2026-123867)" "$T/sni-ca.js"
    js "tls: resumption (CVE-2026-123872)" "$T/tls-resume.js"
    js "tls: HelloRetryRequest and renegotiation (CVE-2026-123872)" "$T/tls-reneg.js"
    js "tls: sockets destroyed before the deferred callbacks (CVE-2026-126051)" "$T/tls-destroyed.js"
    js "https: an empty write in the on_body of the parser (CVE-2026-123864)" "$T/https-nested.js"
else
    fail "tls: the certificates of the checks of the TLS fixes: $(grep -v '^[[:space:]]*$' "$T/tls-certs.log" | tail -n 1)"
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

cat > "$T/proxy-redact.js" <<'EOF'
'use strict';
// CVE-2026-123871: the credentials of a proxy URL that does not parse (or has a CR or
// LF) are not in the message of ERR_PROXY_INVALID_CONFIG
const http = require('node:http');
const SECRET = 'S3cr3t-Pr0xy-P@ssw0rd';
const r = [], bad = [];
const tryit = (name, f) => {
  let m;
  try { f(); m = '(no error)'; } catch (e) { m = `${e.code}: ${e.message}`; }
  if (/S3cr3t|Pr0xy|ssw0rd/.test(m)) bad.push(`${name}: ${m.replace(/\s+/g, ' ').slice(0, 120)}`);
  else if (m === '(no error)') bad.push(`${name}: no error`);
  else r.push(name);
};
if (typeof http.setGlobalProxyFromEnv !== 'function') {
  console.log('FAIL no http.setGlobalProxyFromEnv()'); process.exit(0);
}
tryit('http_proxy that does not parse', () => http.setGlobalProxyFromEnv({ http_proxy: `http://alice:${SECRET}@ ` }));
tryit('https_proxy that does not parse', () => http.setGlobalProxyFromEnv({ https_proxy: `http://alice:${SECRET}@::bad` }));
tryit('the proxyEnv of an Agent', () => new http.Agent({ proxyEnv: { HTTP_PROXY: `http://alice:${SECRET}@::bad` } }));
tryit('a proxy URL with an LF', () => http.setGlobalProxyFromEnv({ http_proxy: `http://alice:${SECRET}@\nhost` }));
console.log(bad.length ? `FAIL ${bad.join('; ')}` : `OK the credentials redacted: ${r.join(', ')}`);
EOF
js "http: the credentials of a proxy URL (CVE-2026-123871)" "$T/proxy-redact.js"

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
js "zlib: params() then destroy() (CVE-2026-123862)" "$T/zlib-params.js"

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
// buffers allocated after its write was cancelled; the client resets the stream
// (RST_STREAM) while that write is pending (node runs with --expose-gc)
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
    // reset stream 3 while its slices are still queued in the pending write
    const code = Buffer.alloc(4);
    code.writeUInt32BE(http2.constants.NGHTTP2_CANCEL);
    socket.write(frame(3, 0, 3, code));
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

cat > "$T/h2-removed.js" <<'EOF'
'use strict';
// CVE-2026-123863: the headers a stream accepted before it was reset for too many of
// them are released when it is removed; streams outliving their session (writes still
// on the socket) no longer abort the process in the destructor of the session (node
// runs with --expose-gc)
const http2 = require('node:http2'), net = require('node:net');
const { setTimeout: sleep } = require('node:timers/promises');
const kStreams = 80;
const frame = (type, flags, id, payload = Buffer.alloc(0)) => {
  const h = Buffer.alloc(9);
  h.writeUIntBE(payload.length, 0, 3); h[3] = type; h[4] = flags; h.writeUInt32BE(id, 5);
  return Buffer.concat([h, payload]);
};
const requestHeaders = Buffer.from([0x83, 0x86, 0x84, 0x01, 0x09, ...Buffer.from('localhost')]);
// more trailer fields than the default maxHeaderListPairs (128)
const trailers = Buffer.concat(Array.from({ length: 200 }, (_, i) => {
  const name = `x-${i}`;
  return Buffer.from([0x00, name.length, ...Buffer.from(name), 0x01, 0x76]);
}));
let answered = 0;
const server = http2.createServer((req, res) => {
  answered++;
  req.on('error', () => {});
  res.on('error', () => {});
  res.end(Buffer.alloc(100 * 1024));
});
server.on('session', (session) => {
  session.on('error', () => {});
  session.on('close', async () => {
    server.close();
    for (let i = 0; i < 10; i++) { globalThis.gc(); await sleep(10); }
    // the session collected before the streams its pending writes keep: no abort
    setTimeout(() => console.log(`OK ${answered} streams reset for too many trailers, the session collected before them`), 200);
  });
});
server.listen(0, '127.0.0.1', async () => {
  const client = net.connect(server.address().port, '127.0.0.1');
  client.on('error', () => {});
  client.pause();
  const settings = Buffer.from([0x00, 0x04, 0x7f, 0xff, 0xff, 0xff]);
  const wu = Buffer.alloc(4);
  wu.writeUInt32BE(0x7fffffff - 65535);
  const requests = [];
  for (let i = 0; i < kStreams; i++) requests.push(frame(1, 0x4, 1 + 2 * i, requestHeaders));
  client.write(Buffer.concat([Buffer.from('PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n'), frame(4, 0, 0, settings),
    frame(8, 0, 0, wu), ...requests]));
  await sleep(500);
  const blocks = [];
  for (let i = 0; i < kStreams; i++) blocks.push(frame(1, 0x5, 1 + 2 * i, trailers));
  client.write(Buffer.concat(blocks));
  await sleep(200);
  client.resetAndDestroy();
});
EOF
js "http2: streams reset for too many trailers outliving their session (CVE-2026-123863)" "$T/h2-removed.js" --expose-gc

cat > "$T/h2-file-reset.js" <<'EOF'
'use strict';
// CVE-2026-123874: a stream of a file response (respondWithFile(), respondWithFD())
// reset while its write is pending on the socket is not collected before that write
// completes (node runs with --expose-gc)
const fs = require('node:fs'), http2 = require('node:http2');
const { duplexPair } = require('node:stream');
const { setImmediate: tick } = require('node:timers/promises');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 20000).unref();
const filename = `${process.cwd()}/h2-file`;
fs.writeFileSync(filename, Buffer.alloc(1024 * 1024));
async function test(useFD) {
  const [clientSide, serverSide] = duplexPair();
  let reset = false, pendingWrite;
  const originalWrite = serverSide._write;
  serverSide._write = function(buf, enc, cb) {
    originalWrite.call(this, buf, enc, async () => {
      // deliver the data, but let the client reset the stream before the native
      // write completes
      await tick();
      if (reset) pendingWrite = cb; else cb();
    });
  };
  const server = http2.createServer();
  const fd = useFD ? fs.openSync(filename, 'r') : undefined;
  let streamClosed;
  const closed = new Promise((resolve) => { streamClosed = resolve; });
  server.on('stream', (stream) => {
    stream.on('close', streamClosed);
    if (useFD) stream.respondWithFD(fd); else stream.respondWithFile(filename);
  });
  server.emit('connection', serverSide);
  const client = http2.connect('http://localhost', {
    createConnection: () => clientSide, settings: { initialWindowSize: 1024 * 1024 } });
  client.on('connect', () => client.setLocalWindowSize(1024 * 1024));
  const req = client.request();
  req.once('data', () => { reset = true; req.close(http2.constants.NGHTTP2_CANCEL); });
  req.resume();
  await closed;
  // collect the stream while its file write still waits for completion
  for (let i = 0; i < 10; i++) { await tick(); globalThis.gc(); }
  if (typeof pendingWrite !== 'function') fail(`${useFD ? 'respondWithFD' : 'respondWithFile'}: no pending write`);
  reset = false;
  pendingWrite();
  pendingWrite = undefined;
  await tick();
  client.destroy();
  server.close();
  if (useFD) fs.closeSync(fd);
}
(async () => {
  // a use after free does not crash every time: several rounds
  for (let i = 0; i < 8; i++) {
    await test(false);
    await test(true);
  }
  console.log('OK respondWithFile() and respondWithFD() reset with a write pending (8 rounds), each write completed after a collection');
  process.exit(0);
})();
EOF
js "http2: file responses reset with a write pending (CVE-2026-123874)" "$T/h2-file-reset.js" --expose-gc

cat > "$T/h2-cancelled.js" <<'EOF'
'use strict';
// CVE-2026-123875: HTTP/2 downloads of a file (respondWithFile()) cancelled while a
// read of the file is pending: no null write request reaches the stream listener
const http2 = require('node:http2');
const fail = (m) => { console.log(`FAIL ${m}`); process.exit(0); };
setTimeout(() => fail('timed out'), 60000).unref();
const server = http2.createServer();
server.on('stream', (stream) => {
  stream.on('error', () => {});
  // a file large enough that a read is still in flight when the client goes
  stream.respondWithFile(process.execPath);
});
server.on('sessionError', () => {});
server.listen(0, '127.0.0.1', () => {
  const port = server.address().port, rounds = 50;
  let i = 0;
  const cancelOne = () => {
    if (i >= rounds) {
      server.close();
      console.log(`OK ${rounds} downloads of a file cancelled while being read`);
      return;
    }
    i++;
    const client = http2.connect(`http://127.0.0.1:${port}`);
    client.on('error', () => {});
    const req = client.request({ ':path': '/' });
    req.on('error', () => {});
    req.resume();
    // destroy the session shortly after the request, at varied delays
    setTimeout(() => { client.destroy(); setTimeout(cancelOne, 1); }, 3 + (i * 7) % 40);
  };
  cancelOne();
});
EOF
js "http2: cancelled downloads of a file (CVE-2026-123875)" "$T/h2-cancelled.js"

# npm and npx: a package made here, packed and installed offline
if pkg info -e npm-node24; then
    v="$(HOME="$T/home" "$P/bin/npm" --version 2>&1)"
    if [ "$v" = "$(pkgv npm-node24)" ]; then pass "npm --version: $v"; else fail "npm --version: $v, the package is $(pkgv npm-node24)"; fi
    v="$(HOME="$T/home" "$P/bin/npx" --version 2>&1)"
    [ "$v" = "$(pkgv npm-node24)" ] && pass "npx --version: $v" || fail "npx --version: $v"
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
else
    note "npm-node24 is not installed: not tested"
fi
if pkg info -e yarn-node24; then
    v="$(HOME="$T/home" "$P/bin/yarn" --version 2>&1)"
    if [ "$v" = "$(pkgv yarn-node24)" ]; then pass "yarn --version: $v"; else fail "yarn --version: $v, the package is $(pkgv yarn-node24)"; fi
    mkdir -p "$T/yarn"
    if (cd "$T/yarn" && HOME="$T/home" "$P/bin/yarn" init -y > "$T/yarn.log" 2>&1) && [ -f "$T/yarn/package.json" ]; then
        pass "yarn init -y: package.json"
    else
        fail "yarn init -y: $(tail -n 1 "$T/yarn.log")"
    fi
else
    note "yarn-node24 is not installed: not tested"
fi
if pkg info -e corepack-node24; then
    v="$(HOME="$T/home" "$P/bin/corepack" --version 2>&1)"
    if [ "$v" = "$(pkgv corepack-node24)" ]; then pass "corepack --version: $v"; else fail "corepack --version: $v, the package is $(pkgv corepack-node24)"; fi
    mkdir -p "$T/shims"
    if HOME="$T/home" "$P/bin/corepack" enable --install-directory "$T/shims" pnpm > "$T/corepack.log" 2>&1 &&
            [ -e "$T/shims/pnpm" ]; then
        pass "corepack enable: the shim pnpm"
    else
        fail "corepack enable: $(tail -n 1 "$T/corepack.log")"
    fi
else
    fail "corepack-node24 is not installed (a dependency of node24)"
fi

echo "node-test: $ok ok, $bad failed" >> "$out"
[ "$bad" = 0 ]
