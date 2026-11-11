#!/bin/sh
# python-test.sh - test Python 3.12 of the repository az, installed from it (aZ,
# 11.11.2026): python312 with py312-sqlite3, mpdecimal and python3 (the meta port:
# bin/python3), under the names of the official packages, so that the py312-*
# packages of the FreeBSD repository work with it. python3.12, libpython and the extension modules load only libraries of
# the base system, of az (/usr/local/az/lib) and of our ports (libpython, libmpdec
# of mpdecimal): libffi, expat, readline, libintl and SQLite of az, OpenSSL, zlib,
# bzip2, liblzma and ncurses of the base system. And:
#   version   python3.12 -V is the version of the package, python3 the same Python;
#             the options of aZ: LTO, PYMALLOC, IPV6, NLS, libmpdec of mpdecimal
#   ssl       the default context with the CA store of the base system, the OpenSSL
#             of the base system; TLS 1.3 between a server and a client of python on
#             127.0.0.1 with a certificate of the openssl of the base system, refused
#             by the default context (not of its CA store)
#   hashlib   SHA-256 and SHA3-256 (OpenSSL)
#   ctypes    strlen and getpid of libc, qsort with a callback of Python (libffi)
#   decimal   the C module on libmpdec: its version that of mpdecimal, 1/7 to 50 digits
#   expat     a document with an entity parsed by pyexpat and ElementTree (its C
#             accelerator); the version of expat that of az (the headers of az)
#   sqlite3   sqlite3.sqlite_version that of az, a table in memory, JSON and FTS5
#             (az builds SQLite with them), load_extension compiled in
#   gettext   the locale module (libintl of az): a catalog of its own in Russian
#             (ru_RU.UTF-8 by setlocale and in the environment, which GNU libintl
#             may read instead)
#   readline  the GNU readline of az, its version
#   compress  lzma, bz2 and zlib round trips (the libraries of the base system)
#   official  py312-six (pure Python) and py312-markupsafe (a C extension) from the
#             repository of FreeBSD installed over our python312, which stays ours,
#             and imported; removed after the test
#
# Usage (FreeBSD, as root, the packages installed): sh tools/python-test.sh
# Results: python-results/tests.txt (one line per check, the summary at the end);
# exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/python-results}"
T="${PYTHON_TEST_WORK:-/var/tmp/python-test}"
P=/usr/local
py="$P/bin/python3.12"
dyn="$P/lib/python3.12/lib-dynload"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
finish() {
    echo "python-test: $ok ok, $bad failed" >> "$out"
    [ "$bad" = 0 ]
    exit $?
}
# libs_of <file>: what it loads (ldd) when every library is found and is of the base
# system, of az or of our ports (libpython3.12, libmpdec), in libs_out; else why in
# libs_bad
libs_of() {
    libs_bad=""; libs_out=""
    _l="$(ldd "$1" 2>&1)" || { libs_bad="ldd failed: $(printf '%s\n' "$_l" | tail -n 1)"; return 1; }
    case "$_l" in *"not found"*) libs_bad="$(printf '%s\n' "$_l" | grep 'not found' | head -n 2 | tr '\n' ' ')"; return 1 ;; esac
    _all=""
    for _x in $(printf '%s\n' "$_l" | awk 'NF > 2 && $2 == "=>" { print $3 }'); do
        _all="$_all $_x"
        case "$_x" in
            /lib/* | /usr/lib/* | /usr/local/az/lib/* | "$P"/lib/libpython3.12.so* | "$P"/lib/libmpdec.so*) continue ;;
        esac
        libs_bad="$libs_bad $_x"
    done
    [ -z "$libs_bad" ] || { libs_bad="not of the base system, az or our ports:$libs_bad"; return 1; }
    libs_out="${_all# }"
}
# lib_in <file> <library> <az|base|ours>: the library the file loads is from there
lib_in() {
    _w="$(ldd "$1" 2>/dev/null | awk -v l="$2" 'index($1, l ".so") == 1 && $2 == "=>" { print $3; exit }')"
    case "$3:$_w" in
        az:/usr/local/az/lib/*) pass "${1##*/}: $2 of az ($_w)" ;;
        base:/lib/* | base:/usr/lib/*) pass "${1##*/}: $2 of the base system ($_w)" ;;
        ours:"$P"/lib/*) pass "${1##*/}: $2 of our ports ($_w)" ;;
        *) fail "${1##*/}: $2 is ${_w:-not linked}, not of $3" ;;
    esac
}
# pyrun <name> <file of Python> [<argument>...]: python3.12 runs it; it prints
# "OK ..." or "FAIL ..."
pyrun() {
    _n="$1"; _s="$2"; shift 2
    _o="$(cd "$T" && "$py" -I "$_s" "$@" 2> "$T/py.err" < /dev/null)"
    case "$_o" in
        "OK "*) pass "$_n: ${_o#OK }" ;;
        "FAIL "*) fail "$_n: ${_o#FAIL }" ;;
        *) fail "$_n: $(printf '%s\n' "$_o" "$(cat "$T/py.err")" | sed -n '/[^[:space:]]/{p;q;}')" ;;
    esac
}
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
# azh <header of az> <macro>...: the version of a library of az from its header: the
# values of the macros joined by dots (quotes away)
azh() {
    _h="/usr/local/az/include/$1"; shift
    for _m in "$@"; do
        awk -v m="$_m" '$1 == "#define" && $2 == m { gsub(/"/, "", $3); print $3; exit }' "$_h" 2>/dev/null
    done | paste -s -d . -
}
# ann <package> <annotation>: the value of an annotation of an installed package
ann() { pkg query '%At %Av' "$1" 2>/dev/null | awk -v a="$2" '$1 == a { print $2; exit }'; }
export LANG=C.UTF-8

for p in python312 py312-sqlite3 mpdecimal python3; do
    pkg info -e "$p" || fail "$p is not installed"
done
[ -x "$py" ] || finish

# --- the version, the libraries -------------------------------------------------------
v="$("$py" -V 2>&1)"
if [ "$v" = "Python $(pkgv python312)" ]; then pass "python3.12 -V: $v"; else fail "python3.12 -V: $v, the package is $(pkgv python312)"; fi
v3="$("$P/bin/python3" -V 2>&1)"
l3="$(readlink "$P/bin/python3")"
if [ "$v3" = "$v" ] && [ "$l3" = python3.12 ]; then pass "python3 -> $l3: $v3"; else fail "python3 -> ${l3:-?}: $v3, not $v"; fi
[ -n "$(ann python312 az_hash)" ] && pass "python312: the package of az (az_hash $(ann python312 az_hash | cut -c1-12))" ||
    fail "python312: no az_hash, not the package of az"
lp="$P/lib/libpython3.12.so.1.0"
sq="$P/lib/python3.12/site-packages/_sqlite3.cpython-312.so"
for f in "$py" "$lp" "$dyn"/_ssl.cpython-312.so "$dyn"/_hashlib.cpython-312.so "$dyn"/_ctypes.cpython-312.so \
        "$dyn"/_decimal.cpython-312.so "$dyn"/pyexpat.cpython-312.so "$dyn"/readline.cpython-312.so \
        "$dyn"/_lzma.cpython-312.so "$dyn"/_bz2.cpython-312.so "$dyn"/zlib.cpython-312.so "$sq"; do
    if [ ! -f "$f" ]; then fail "${f##*/}: not installed"; continue; fi
    if libs_of "$f"; then pass "${f##*/}: $libs_out"; else fail "${f##*/}: $libs_bad"; fi
done
lib_in "$py" libpython3.12 ours
lib_in "$lp" libintl az
lib_in "$dyn"/_ssl.cpython-312.so libssl base
lib_in "$dyn"/_ssl.cpython-312.so libcrypto base
lib_in "$dyn"/_hashlib.cpython-312.so libcrypto base
lib_in "$dyn"/_ctypes.cpython-312.so libffi az
lib_in "$dyn"/_decimal.cpython-312.so libmpdec ours
lib_in "$dyn"/pyexpat.cpython-312.so libexpat az
lib_in "$dyn"/readline.cpython-312.so libreadline az
lib_in "$dyn"/readline.cpython-312.so libncursesw base
lib_in "$dyn"/_lzma.cpython-312.so liblzma base
lib_in "$dyn"/_bz2.cpython-312.so libbz2 base
lib_in "$dyn"/zlib.cpython-312.so libz base
lib_in "$sq" libsqlite3 az

# --- the options of the build ---------------------------------------------------------
cat > "$T/t_options.py" <<'EOF'
import locale, socket, sys, sysconfig
args = sysconfig.get_config_var('CONFIG_ARGS') or ''
want = {
    'LTO': '--with-lto' in args,
    'PYMALLOC': sysconfig.get_config_var('WITH_PYMALLOC') == 1,
    'IPV6': socket.has_ipv6,
    'NLS': hasattr(locale, 'bindtextdomain'),
    'LIBMPDEC': '--with-system-libmpdec' in args,
    'no DEBUG': not hasattr(sys, 'gettotalrefcount'),
}
bad = [k for k, v in want.items() if not v]
print(('FAIL not: ' + ', '.join(bad)) if bad else 'OK ' + ', '.join(want))
EOF
pyrun options "$T/t_options.py"

# --- ssl, hashlib ---------------------------------------------------------------------
ov="$(/usr/bin/openssl version 2>/dev/null)"
if /usr/bin/openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 1 -subj /CN=localhost \
        -addext subjectAltName=DNS:localhost -keyout "$T/key.pem" -out "$T/cert.pem" > "$T/openssl.log" 2>&1; then
    cat > "$T/t_ssl.py" <<'EOF'
import os, socket, ssl, sys, threading
base = sys.argv[1]
p = ssl.get_default_verify_paths()
d = ssl.create_default_context()
n = len(d.get_ca_certs())
store = p.openssl_cafile if os.path.isfile(p.openssl_cafile) else None
nd = len([f for f in os.listdir(p.openssl_capath) if f.endswith('.0')]) if os.path.isdir(p.openssl_capath) else 0
if not (p.openssl_cafile.startswith('/etc/ssl/') and p.openssl_capath.startswith('/etc/ssl/')):
    print(f'FAIL the paths of the CA store: {p.openssl_cafile}, {p.openssl_capath}'); sys.exit()
if not (n or nd):
    print(f'FAIL no CA certificate in {p.openssl_cafile} or {p.openssl_capath}'); sys.exit()
if d.verify_mode != ssl.CERT_REQUIRED or not d.check_hostname:
    print('FAIL the default context does not verify'); sys.exit()
if ssl.OPENSSL_VERSION.split()[:2] != base.split()[:2]:
    print(f'FAIL {ssl.OPENSSL_VERSION}, the base system: {base}'); sys.exit()
srv = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
srv.load_cert_chain('cert.pem', 'key.pem')
ls = socket.create_server(('127.0.0.1', 0))
port = ls.getsockname()[1]
def serve(k):
    for _ in range(k):
        c, _a = ls.accept()
        try:
            with srv.wrap_socket(c, server_side=True) as s:
                s.sendall(b'tls of python')
        except (ssl.SSLError, OSError):
            pass
t = threading.Thread(target=serve, args=(2,), daemon=True)
t.start()
cl = ssl.create_default_context(cafile='cert.pem')
with socket.create_connection(('127.0.0.1', port)) as c, cl.wrap_socket(c, server_hostname='localhost') as s:
    got, ver, ciph = s.recv(64), s.version(), s.cipher()[0]
refused = ''
try:
    with socket.create_connection(('127.0.0.1', port)) as c, d.wrap_socket(c, server_hostname='localhost') as s:
        s.recv(64)
except ssl.SSLCertVerificationError as e:
    refused = e.verify_message
t.join(5)
ok = got == b'tls of python' and ver == 'TLSv1.3' and refused
print(f"{'OK' if ok else 'FAIL'} {ssl.OPENSSL_VERSION}; the CA store {store or p.openssl_capath} "
      f"({n} in the file, {nd} in {p.openssl_capath}); {ver} {ciph}, \"{got.decode()}\"; "
      f"the default context: {refused or 'not refused'}")
EOF
    pyrun ssl "$T/t_ssl.py" "$ov"
else
    fail "ssl: openssl req (the certificate of the test): $(tail -n 1 "$T/openssl.log")"
fi
cat > "$T/t_hashlib.py" <<'EOF'
import hashlib
a = hashlib.sha256(b'abc').hexdigest()
b = hashlib.sha3_256(b'abc').hexdigest()
ok = (a == 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' and
      b == '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532' and
      hashlib.sha256.__name__.startswith('openssl_'))
print(f"{'OK' if ok else 'FAIL'} sha256 {a[:16]}... ({hashlib.sha256.__name__}), "
      f"sha3_256 {b[:16]}... ({hashlib.sha3_256.__name__})")
EOF
pyrun hashlib "$T/t_hashlib.py"

# --- ctypes, decimal, expat -------------------------------------------------------------
cat > "$T/t_ctypes.py" <<'EOF'
import ctypes, ctypes.util, os
name = ctypes.util.find_library('c')
libc = ctypes.CDLL(name)
n = libc.strlen(b'azsupport')
pid = libc.getpid()
arr = (ctypes.c_int * 6)(5, 3, 9, 1, 7, 2)
CMP = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int))
libc.qsort(arr, len(arr), ctypes.sizeof(ctypes.c_int), CMP(lambda a, b: a[0] - b[0]))
ok = n == 9 and pid == os.getpid() and list(arr) == [1, 2, 3, 5, 7, 9]
print(f"{'OK' if ok else 'FAIL'} {name}: strlen {n}, getpid {pid}, qsort with a callback {list(arr)}")
EOF
pyrun ctypes "$T/t_ctypes.py"
cat > "$T/t_decimal.py" <<'EOF'
import sys, decimal, _decimal
want = sys.argv[1]
decimal.getcontext().prec = 50
q = str(decimal.Decimal(1) / decimal.Decimal(7))
ok = (decimal.Decimal is _decimal.Decimal and decimal.__libmpdec_version__ == want and
      q == '0.14285714285714285714285714285714285714285714285714')
print(f"{'OK' if ok else 'FAIL'} the C module, libmpdec {decimal.__libmpdec_version__} "
      f"(mpdecimal {want}), 1/7 = {q}")
EOF
pyrun decimal "$T/t_decimal.py" "$(pkgv mpdecimal)"
cat > "$T/t_expat.py" <<'EOF'
import sys, pyexpat, _elementtree
import xml.etree.ElementTree as ET
want = sys.argv[1]
doc = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE r [<!ENTITY az "azsupport">]><r a="1"><t>&az; привет</t></r>'
seen = []
p = pyexpat.ParserCreate()
p.StartElementHandler = lambda n, a: seen.append(n)
p.Parse(doc.encode(), True)
e = ET.fromstring(doc.encode())
ok = (seen == ['r', 't'] and e.find('t').text == 'azsupport привет' and
      pyexpat.EXPAT_VERSION == 'expat_' + want and ET.XMLParser is _elementtree.XMLParser)
print(f"{'OK' if ok else 'FAIL'} {pyexpat.EXPAT_VERSION} (az {want}); pyexpat {seen}, "
      f"ElementTree (_elementtree) \"{e.find('t').text}\"")
EOF
pyrun expat "$T/t_expat.py" "$(azh expat.h XML_MAJOR_VERSION XML_MINOR_VERSION XML_MICRO_VERSION)"

# --- sqlite3 ----------------------------------------------------------------------------
cat > "$T/t_sqlite.py" <<'EOF'
import sys, sqlite3
want = sys.argv[1]
db = sqlite3.connect(':memory:')
db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, a TEXT)')
db.executemany('INSERT INTO t (a) VALUES (?)', [('az',), ('python',)])
n = db.execute('SELECT count(*) FROM t').fetchone()[0]
j = db.execute("SELECT json_extract('{\"x\": [1, 2, 3]}', '$.x[2]')").fetchone()[0]
db.execute('CREATE VIRTUAL TABLE f USING fts5(body)')
db.execute("INSERT INTO f VALUES ('the packages of azsupport')")
m = db.execute("SELECT count(*) FROM f WHERE f MATCH 'azsupport'").fetchone()[0]
ok = (sqlite3.sqlite_version == want and n == 2 and j == 3 and m == 1 and
      hasattr(db, 'enable_load_extension'))
print(f"{'OK' if ok else 'FAIL'} SQLite {sqlite3.sqlite_version} (az {want}), {n} rows, JSON {j}, FTS5 {m}, "
      f"load_extension {'compiled in' if hasattr(db, 'enable_load_extension') else 'absent'}")
EOF
pyrun sqlite3 "$T/t_sqlite.py" "$(azh sqlite3.h SQLITE_VERSION)"

# --- gettext through the locale module (libintl of az) ---------------------------------
mkdir -p "$T/locale/ru/LC_MESSAGES"
cat > "$T/t_gettext.py" <<'EOF'
import locale, os, struct
# GNU libintl may take the locale of LC_MESSAGES from the environment rather than
# from setlocale: both the same
os.environ.pop('LANGUAGE', None)
os.environ['LC_ALL'] = 'ru_RU.UTF-8'
# a catalog of GNU gettext (.mo) of one message, written here
orig, tr = b'the packages of az', 'пакеты az'.encode()
k = [b'', orig]
v = [b'Content-Type: text/plain; charset=UTF-8\n', tr]
off = 7 * 4 + 16 * len(k)
ko, vo, data = [], [], b''
for s in k:
    ko.append((len(s), off + len(data))); data += s + b'\0'
for s in v:
    vo.append((len(s), off + len(data))); data += s + b'\0'
mo = struct.pack('<7I', 0x950412de, 0, len(k), 7 * 4, 7 * 4 + 8 * len(k), 0, 0)
mo += b''.join(struct.pack('<2I', *x) for x in ko) + b''.join(struct.pack('<2I', *x) for x in vo) + data
open('locale/ru/LC_MESSAGES/aztest.mo', 'wb').write(mo)
loc = locale.setlocale(locale.LC_ALL, 'ru_RU.UTF-8')
locale.bindtextdomain('aztest', os.path.abspath('locale'))
locale.textdomain('aztest')
got = locale.gettext('the packages of az')
got2 = locale.dgettext('aztest', 'the packages of az')
ok = got == 'пакеты az' and got2 == got
print(f"{'OK' if ok else 'FAIL'} {loc}: \"{got}\" (gettext), \"{got2}\" (dgettext)")
EOF
pyrun gettext "$T/t_gettext.py"

# --- readline, compression ----------------------------------------------------------------
cat > "$T/t_readline.py" <<'EOF'
import sys, readline
want = sys.argv[1]
v = readline._READLINE_LIBRARY_VERSION
gnu = 'libedit' not in (readline.__doc__ or '')
readline.add_history('az')
ok = gnu and v == want and readline.get_history_item(readline.get_current_history_length()) == 'az'
print(f"{'OK' if ok else 'FAIL'} GNU readline {v} (az {want}), the history")
EOF
pyrun readline "$T/t_readline.py" "$(azh readline/readline.h RL_VERSION_MAJOR RL_VERSION_MINOR)"
cat > "$T/t_compress.py" <<'EOF'
import bz2, lzma, zlib
s = b'the compression of python of azsupport ' * 200
r = []
ok = True
for n, c, d in (('zlib', zlib.compress, zlib.decompress), ('bz2', bz2.compress, bz2.decompress),
                ('lzma', lzma.compress, lzma.decompress)):
    x = c(s)
    ok = ok and d(x) == s and len(x) < len(s)
    r.append(f'{n} {len(s)} -> {len(x)}')
print(f"{'OK' if ok else 'FAIL'} {', '.join(r)}; zlib {zlib.ZLIB_RUNTIME_VERSION}")
EOF
pyrun compress "$T/t_compress.py"

# --- the official py312-* packages over our python312 ------------------------------------
off="py312-six py312-markupsafe"
pv="$(pkg query %v python312)"
# those that are installed already stay after the test
had=""
for p in $off; do pkg info -e "$p" && had="$had $p"; done
: > "$res/pkg-official.log"
for r in FreeBSD-ports FreeBSD; do
    # shellcheck disable=SC2086
    env ASSUME_ALWAYS_YES=yes pkg install -y -r "$r" $off >> "$res/pkg-official.log" 2>&1 && break
done
miss=""
for p in $off; do pkg info -e "$p" || miss="$miss $p"; done
if [ -n "$miss" ]; then
    fail "official packages: not installed:$miss ($(grep -v '^\[' "$res/pkg-official.log" | grep . | tail -n 2 | tr '\n' ' '))"
else
    for p in $off; do
        r="$(ann "$p" repository)"
        case "$r" in FreeBSD*) pass "$p $(pkg query %v "$p"): of the repository $r" ;; *) fail "$p: of the repository ${r:-unknown}, not of FreeBSD" ;; esac
    done
    if [ "$(pkg query %v python312)" = "$pv" ] && [ -n "$(ann python312 az_hash)" ]; then
        pass "python312 $pv: still ours after pkg install of$(printf ' %s' $off)"
    else
        fail "python312: $(pkg query %v python312) ($(ann python312 repository)), not ours $pv any more"
    fi
    cat > "$T/t_official.py" <<'EOF'
import importlib.metadata as md
import six, markupsafe
from markupsafe import _speedups
e = markupsafe.escape('<a href="x">az</a>')
ok = (_speedups.__file__.endswith('.so') and str(e) == '&lt;a href=&#34;x&#34;&gt;az&lt;/a&gt;' and
      six.PY3 and six.ensure_str(b'az') == 'az')
print(f"{'OK' if ok else 'FAIL'} six {six.__version__}, markupsafe {md.version('markupsafe')} "
      f"with its C extension {_speedups.__file__.rsplit('/', 1)[-1]}: {e}")
EOF
    pyrun official "$T/t_official.py"
fi
for p in $off; do
    case " $had " in *" $p "*) continue ;; esac
    pkg info -e "$p" && { pkg delete -y "$p" >> "$res/pkg-official.log" 2>&1 || note "pkg delete $p failed (pkg-official.log)"; }
done

finish
