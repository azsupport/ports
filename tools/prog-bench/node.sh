# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/node.sh: the groups node24 and node18 of tools/prog-bench.sh (sourced by
# it). Node.js 24.22.3 (www/node24) and 18.20.8 (www/node18), the tarballs of nodejs.org of
# their distinfo, built by each variant as `out/Release/node`: the OpenSSL (with the CA store)
# and the zlib of the base system, as our ports; the other libraries those the tarball bundles
# (our ports link the shared ones of azsupport: their compiler is that of the libraries,
# not of node), so the V8, ICU, libuv, llhttp, ada, simdutf, nghttp2 and the rest of the
# program here are of the variant; no npm, no corepack. A build takes up to 205 minutes
# (tools/build-minutes.conf): prog-bench.yml builds each variant in a VM of its own (the
# input split) and measures the three in one.
# The benchmarks, each in a node of its own on the last CPU (the seconds its script measures,
# without the start of node): JSON.stringify and JSON.parse (the C++ of V8), regular
# expressions over 20 MB of log lines, string operations, binary trees (the GC), the
# parsing of 1M URLs (ada), Buffer to and from base64 and hex, TextDecoder of UTF-8, the
# compilation of a script of 8 MB (the parser and the bytecode of V8); the start of node
# (node -e 0, 20 times); an HTTP server (http.createServer) under wrk.

case "$group" in
node24) nv=24.22.3; nsum=48ca3aa8a9b02133356922ef4fc80200e00598c80a4ef446f7c39a459222593d ;;
node18) nv=18.20.8; nsum=36a7bf1a76d62ce4badd881ee5974a323c70e1d8d19165732684e145632460d9 ;;
*) die "node.sh: no version for $group" ;;
esac
g_progs="$group"

g_need() {
    if [ "$mode" = bench ]; then need wrk; fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch "node-v$nv.tar.xz" "$nsum" "https://nodejs.org/dist/v$nv/node-v$nv.tar.xz"
    unpack "node-v$nv.tar.xz" "$W/src/$group-$_v"
    _b="$W/b-$group-$_v.log"
    if (cd "$W/src/$group-$_v" && ./configure --prefix="$W/$group-$_v" --shared-openssl \
        --shared-openssl-includes=/usr/include --shared-openssl-libpath=/usr/lib --openssl-use-def-ca-store \
        --shared-zlib --shared-zlib-includes=/usr/include --shared-zlib-libpath=/usr/lib &&
        gmake -j"$ncpu" &&
        mkdir -p "$W/$group-$_v/bin" && cp out/Release/node "$W/$group-$_v/bin/node") > "$_b" 2>&1 &&
        "$W/$group-$_v/bin/node" -e 'process.exit(0)' >> "$_b" 2>&1; then
        bok "$group" "$_v" "$W/$group-$_v/bin/node"
    else
        bno "$group" "$_v" "$_b"
    fi
    rm -rf "$W/src/$group-$_v"
}

g_keep() { echo "$W/$group-$1"; }

g_bench() {
    cat > "$W/nb.js" << 'EOF'
'use strict';
const name = process.argv[2];
let sink = 0;
const B = {
  json() {
    const a = [];
    for (let i = 0; i < 200000; i++)
      a.push({ id: i, name: 'item ' + i, price: i * 1.25, tags: ['a' + (i % 7), 'b' + (i % 13)], nested: { x: i % 100, y: 'v' + i, ok: (i & 1) === 0 } });
    for (let k = 0; k < 4; k++) { const s = JSON.stringify(a); sink += JSON.parse(s).length + s.length; }
  },
  regex() {
    const lines = [];
    for (let i = 0; i < 200000; i++)
      lines.push(`10.${i % 256}.${(i >> 8) % 256}.${i % 97} - - [26/Nov/2026:20:${i % 60}:${i % 60} +0100] "GET /videos/${i}/clip_${i % 1000}.mp4?start=${i % 300} HTTP/1.1" 200 ${i * 13 % 100000} "-" "Mozilla/5.0"`);
    const text = lines.join('\n');
    const re = /^(\d+\.\d+\.\d+\.\d+) - - \[([^\]]+)\] "(GET|POST) ([^ ?]+)(\?[^ ]*)? HTTP\/1\.[01]" (\d{3}) (\d+)/gm;
    for (let k = 0; k < 8; k++) { let m; re.lastIndex = 0; while ((m = re.exec(text)) !== null) sink += m[4].length; }
    sink += text.replace(/clip_(\d+)/g, 'c$1').length;
  },
  strings() {
    for (let k = 0; k < 50; k++) {
      let s = '';
      for (let i = 0; i < 100000; i++) s += 'word' + (i % 100) + ' ';
      const w = s.split(' ');
      sink += w.join(',').toUpperCase().indexOf('WORD99') + w.map((x) => x.padStart(8, '-')).join('').length;
    }
  },
  binarytrees() {
    function make(d) { return d === 0 ? { l: null, r: null } : { l: make(d - 1), r: make(d - 1) }; }
    function check(t) { return t.l === null ? 1 : 1 + check(t.l) + check(t.r); }
    const max = 19;
    const long = make(max);
    for (let d = 4; d <= max; d += 2) {
      const n = 1 << (max - d + 4);
      for (let i = 0; i < n; i++) sink += check(make(d));
    }
    sink += check(long);
  },
  url() {
    for (let i = 0; i < 1000000; i++) {
      const u = new URL(`https://user:pw@sub${i % 50}.example.com:8443/a/b/${i}/../c/./d.mp4?start=${i}&x=%20y#frag${i % 9}`);
      sink += u.pathname.length + u.searchParams.get('start').length;
    }
  },
  buffer() {
    const b = Buffer.alloc(64 << 20);
    for (let i = 0; i < b.length; i++) b[i] = (i * 2654435761) >>> 24;
    for (let k = 0; k < 3; k++) {
      const s64 = b.toString('base64'); sink += Buffer.from(s64, 'base64').length;
      const hex = b.toString('hex'); sink += Buffer.from(hex, 'hex').length;
    }
  },
  textdecoder() {
    const s = 'Привет, мир! Hello, world! こんにちは 🌍 '.repeat(1 << 20);
    const enc = new TextEncoder().encode(s);
    const dec = new TextDecoder('utf-8');
    for (let k = 0; k < 5; k++) sink += dec.decode(enc).length + new TextEncoder().encode(s).length;
  },
  compile() {
    const vm = require('vm');
    const parts = [];
    for (let i = 0; i < 40000; i++)
      parts.push(`function f${i}(a, b) { const o = { k: a + ${i}, s: 'str${i}' }; if (a > b) { return o.k * 2; } for (let j = 0; j < b; j++) { o.k += j; } return o; }`);
    const src = parts.join('\n');
    for (let k = 0; k < 6; k++) { const sc = new vm.Script(src + '\n// ' + k, { filename: 'gen' + k + '.js' }); sc.runInThisContext(); sink += k; }
  },
};
const t0 = process.hrtime.bigint();
B[name]();
const t1 = process.hrtime.bigint();
console.log((Number(t1 - t0) / 1e9).toFixed(4));
if (sink === -1) console.log(sink);
EOF
    cat > "$W/nhttp.js" << 'EOF'
'use strict';
const body = 'x'.repeat(1024);
require('http').createServer((q, s) => {
  s.writeHead(200, { 'Content-Type': 'text/plain', 'Content-Length': body.length });
  s.end(body);
}).listen(8124, '127.0.0.1');
EOF
    benches="json regex strings binarytrees url buffer textdecoder compile"
    for r in $(seq 1 "$rounds"); do
        say "$group: round $r of $rounds"
        for v in $(order "$r"); do
            have "$group" "$v" || continue
            n="$W/$group-$v/bin/node"
            for b in $benches; do
                t="$(cpuset -l "$last" "$n" "$W/nb.js" "$b" 2> "$W/cmd.err" | head -n 1)"
                [ -n "$t" ] || say "$group $b $v: failed: $(tail -n 3 "$W/cmd.err" | tr '\n' ' ' | cut -c1-300)"
                record "$group" "$b" s lower "$v" "$t"
            done
            /usr/bin/time -p -o "$W/time.out" sh -c 'for i in $(seq 1 20); do cpuset -l "$1" "$2" -e 0 || exit 1; done' sh "$last" "$n" 2> "$W/cmd.err" &&
                record "$group" "start (node -e 0, 20 times)" s lower "$v" "$(awk '$1 == "real" { print $2 }' "$W/time.out")"
            cpuset -l "$last" "$n" "$W/nhttp.js" > "$W/nhttp-$v.log" 2>&1 &
            pid=$!
            if waitport 8124; then
                cpuset -l "$others" wrk -t 3 -c 64 -d 2s http://127.0.0.1:8124/ > /dev/null 2>&1
                wrkrate "$v" "$group" "http server, 1 KB (wrk, 64 connections)" http://127.0.0.1:8124/
            else
                say "$group http $v: the server did not start: $(tail -n 3 "$W/nhttp-$v.log" | tr '\n' ' ')"
            fi
            kill "$pid"; wait "$pid" 2> /dev/null
        done
    done
}
