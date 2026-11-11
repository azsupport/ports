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
#   wasi      node:wasi: a WebAssembly module made here writes to stdout (the uvwasi
#             Node 18 bundles, on the libuv of az)
#   url       an IDN host in Punycode (the ada Node 18 bundles)
#   npm       npm and npx, npm pack of a package made here and npm install of it
#             offline; node-gyp
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
# js <name> <file of JavaScript>: node runs it; it prints "OK ..." or "FAIL ..."
js() {
    _o="$(cd "$T" && HOME="$T/home" "$P/bin/node" "$2" 2> "$T/js.err" < /dev/null)"
    case "$_o" in
        "OK "*) pass "$1: ${_o#OK }" ;;
        "FAIL "*) fail "$1: ${_o#FAIL }" ;;
        *) fail "$1: $(printf '%s\n' "$_o" "$(cat "$T/js.err")" | sed -n '/[^[:space:]]/{p;q;}')" ;;
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
