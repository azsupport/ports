#!/bin/sh
# check-variants.sh - the packages of a module with the same files, each in turn
# in the place of the others (tools/install-php.sh puts in only the first of each):
#   - redis (aZ, 11.11.2026): phpXY-redis without compression, phpXY-redis-lz4,
#     phpXY-redis-zstd and phpXY-redis-lz4-zstd (with liblz4 and libzstd of az);
#     5.6 has only the first (phpredis 4.3.0 knows neither lz4 nor zstd);
#   - gd of 5.6 (aZ, 11.11.2026): php56-gd, and php56-gd-t1lib with T1lib (libt1 of
#     devel/t1lib);
#   - swoole of 8.1 to 8.4 (aZ, 11.11.2026): phpXY-swoole, and phpXY-swoole-sqlite with
#     the coroutine PDO SQLite (libsqlite3 of az); 8.1 also both with OpenSSL.
# Each goes in by pkg install -f from the repository azbuild that tools/install-php.sh
# wrote (the others of its group out first: pkg refuses the same files), then:
#   - php -n with the module and those of the packages it depends on: redis the
#     constants Redis::COMPRESSION_LZ4 and Redis::COMPRESSION_ZSTD there or not as
#     the name of the package says, and with each compression it has a round trip of
#     Redis::_compress() and Redis::_uncompress() (no server needed); gd
#     imagepstext() and "T1Lib Support" of gd_info() there or not; swoole the row
#     coroutine_sqlite of phpinfo() there or not, and with it a query of PDO SQLite
#     (the driver of swoole: no pdo_sqlite) and, in coroutines with SWOOLE_HOOK_ALL,
#     a long query that holds its coroutine only (a timer of 5 ms in another one
#     ends first); then the same as a server runs it, with every module of conf.d
#     (pdo_sqlite started before swoole, which takes its place), and the functions
#     of SQL of PHP (sqliteCreateFunction(), Pdo\Sqlite::createFunction() of 8.4);
#   - readelf -d of the module: liblz4, libzstd, libsqlite3 (of az) or libt1 named
#     (NEEDED) or not, as the package says.
# The first of each group goes in again at the end.
#
# Usage (as root on FreeBSD, after sh tools/install-php.sh <version>):
#   sh tools/check-variants.sh <version>
#
# Every check prints one line, OK, FAIL with the reason or SKIP with the reason, also
# into results/check-variants-<version>.txt (RESULTS=<dir> for another directory);
# the log of pkg: results/check-variants-<version>.log. PREFIX (/usr/local) can be
# set.
# Exit status: 0 no check failed, 1 a check failed, 2 usage.

set -u
usage() { echo "usage: sh tools/check-variants.sh <version>  (7.4, 8.4, ...)" >&2; exit 2; }
[ $# -eq 1 ] || usage
ver="$1"
case "$ver" in [0-9].[0-9]) ;; *) usage ;; esac
short="$(echo "$ver" | tr -d .)"
P="${PREFIX:-/usr/local}"
etc="$P/etc/php$short"
php="$P/bin/php$short"
res="${RESULTS:-results}"
mkdir -p "$res" || { echo "check-variants: cannot make the directory $res" >&2; exit 2; }
sum="$res/check-variants-$ver.txt"
log="$res/check-variants-$ver.log"
: > "$sum" && : > "$log" || { echo "check-variants: cannot write $sum" >&2; exit 2; }
export ASSUME_ALWAYS_YES=yes

nok=0; nfail=0; nskip=0
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$sum"; }
ok() { say "OK   $1${2:+: $2}"; nok=$((nok + 1)); }
fail() { say "FAIL $1: $2"; nfail=$((nfail + 1)); }
skip() { say "SKIP $1: $2"; nskip=$((nskip + 1)); }

say "check-variants $ver: $(uname -sr), $(date '+%d.%m.%Y %H:%M:%S')"
[ -x "$php" ] || { fail "php$short" "no $php (sh tools/install-php.sh $ver first)"; exit 1; }
extdir="$("$P/bin/php-config$short" --extension-dir 2>/dev/null)"
[ -d "$extdir" ] || { fail "php$short" "no extension directory (php-config$short --extension-dir: ${extdir:-nothing})"; exit 1; }

# mod_of <package>: its module, by the name of its ini (ext-<NN>-<module>.ini.sample)
mod_of() {
    pkg query '%Fp' "$1" 2>/dev/null |
        sed -n "s#^$etc/conf.d/ext-[0-9][0-9]-\([^/]*\)\.ini\.sample\$#\1#p" | head -n 1
}
# in_repo <package>: the repository azbuild has it
in_repo() { [ -n "$(pkg rquery -r azbuild '%n' "$1" 2>/dev/null)" ]; }
# put <package> <the others of its group>: it in their place, from azbuild
put() {
    _p="$1"; shift
    _del=""
    for _o in "$@"; do pkg info -e "$_o" && _del="$_del $_o"; done
    if [ -n "$_del" ]; then
        # shellcheck disable=SC2086
        pkg delete -y $_del >> "$log" 2>&1 || return 1
    fi
    CONSERVATIVE_UPGRADE=no pkg install -y -f -r azbuild "$_p" >> "$log" 2>&1 && pkg info -e "$_p"
}
# needed <file>: the libraries readelf -d names, one a line
needed() { readelf -d "$1" 2>/dev/null | sed -n 's/.*Shared library: *\[\(.*\)\].*/\1/p'; }
# phpargs <package>: -d extension= of the modules of the packages it depends on, then its own
phpargs() {
    _a=""
    for _d in $(pkg query '%dn' "$1" 2>/dev/null | grep "^php$short-" | sort); do
        _m="$(mod_of "$_d")"
        [ -n "$_m" ] && _a="$_a -d extension=$_m.so"
    done
    printf '%s -d extension=%s.so' "$_a" "$(mod_of "$1")"
}
# phpcheck <name> <package> <code>: php -n with the modules of the package; the code
# echoes "OK ..." or "FAIL ..."
phpcheck() {
    # shellcheck disable=SC2046
    _o="$("$php" -n -d "extension_dir=$extdir" $(phpargs "$2") -r "$3" 2>&1 < /dev/null)"
    case "$_o" in
        *"
"*) ;;
        "OK "*) ok "$1" "${_o#OK }"; return ;;
        "FAIL "*) fail "$1" "${_o#FAIL }"; return ;;
    esac
    fail "$1" "$(printf '%s\n' "$_o" | sed -n '/[^[:space:]]/{p;q;}')"
}
# libs <name> <module file> <library: yes|no> ...: the libraries it names (NEEDED)
libs() {
    _n="$1"; _f="$2"; shift 2
    _l="$(needed "$_f" | tr '\n' ' ')"
    _bad=""
    while [ $# -ge 2 ]; do
        case " $_l" in *" $1".*) _has=yes ;; *) _has=no ;; esac
        [ "$_has" = "$2" ] || _bad="$_bad $1 $([ "$2" = yes ] && echo missing || echo there)"
        shift 2
    done
    if [ -n "$_bad" ]; then fail "$_n" "readelf -d of ${_f##*/}:$_bad (NEEDED: $_l)"; else ok "$_n" "NEEDED: $_l"; fi
}

# --- redis ---
group="php$short-redis php$short-redis-lz4 php$short-redis-zstd php$short-redis-lz4-zstd"
first="php$short-redis"
done_any=""
for p in $group; do
    in_repo "$p" || continue
    [ "$p" = "$first" ] || done_any=1
done
if [ -z "$done_any" ]; then
    skip "redis: the packages with compression" "the repository has none for $ver (phpredis of 5.6 has no lz4 or zstd)"
else
    for p in php$short-redis-lz4 php$short-redis-zstd php$short-redis-lz4-zstd $first; do
        in_repo "$p" || { fail "redis: $p" "not in the repository azbuild"; continue; }
        # shellcheck disable=SC2046
        if ! put "$p" $(printf '%s\n' $group | grep -v -x "$p"); then
            fail "redis: $p" "did not install ($log)"
            continue
        fi
        lz=false; zs=false
        case "$p" in *-lz4*) lz=true ;; esac
        case "$p" in *-zstd) zs=true ;; esac
        phpcheck "redis: $p, the compression" "$p" '
            $want = array("lz4" => '"$lz"', "zstd" => '"$zs"');
            $bad = array(); $done = array();
            foreach ($want as $k => $w) {
                $h = defined("Redis::COMPRESSION_" . strtoupper($k));
                if ($h !== $w) { $bad[] = "Redis::COMPRESSION_" . strtoupper($k) . ($h ? " there" : " not there"); continue; }
                if (!$w) continue;
                $r = new Redis();
                $r->setOption(Redis::OPT_COMPRESSION, constant("Redis::COMPRESSION_" . strtoupper($k)));
                $s = str_repeat("the compression of the module redis ", 64);
                $c = $r->_compress($s);
                if ($r->_uncompress($c) !== $s || strlen($c) >= strlen($s)) { $bad[] = "$k: no round trip"; continue; }
                $done[] = "$k " . strlen($s) . " -> " . strlen($c) . " bytes";
            }
            echo $bad ? "FAIL " . implode(", ", $bad)
                : "OK phpredis " . phpversion("redis") . ", " . ($done ? implode(", ", $done) : "no compression");'
        libs "redis: $p, the libraries" "$extdir/redis.so" liblz4.so "$([ "$lz" = true ] && echo yes || echo no)" \
            libzstd.so "$([ "$zs" = true ] && echo yes || echo no)"
    done
fi

# --- swoole with the coroutine PDO SQLite (8.1 to 8.4) ---
# sw_php: the code of the checks after "$q = true|false; $ini = true|false;"
sw_php=$(cat <<'PHP'
ob_start(); phpinfo(INFO_MODULES); $i = ob_get_clean();
$c = strpos($i, "coroutine_sqlite") !== false;
$r = "";
if ($c !== $q) {
    $r = "FAIL coroutine_sqlite of phpinfo() " . ($c ? "there" : "not there") . ", " . ($q ? "there" : "not there") . " wanted";
} elseif (!$q) {
    $r = "OK swoole " . phpversion("swoole") . ", no coroutine_sqlite";
} elseif ($ini && !extension_loaded("pdo_sqlite")) {
    $r = "FAIL the modules of conf.d: no pdo_sqlite";
} else {
    $p = new PDO("sqlite::memory:");
    $v = $p->query("SELECT sqlite_version()")->fetchColumn();
    $f = "";
    if ($ini) {
        if (PHP_VERSION_ID >= 80400) {
            $d = PDO::connect("sqlite::memory:");
            $d->createFunction("twice", function ($x) { return 2 * $x; }, 1);
            $f = get_class($d) . "::createFunction(): " . $d->query("SELECT twice(21)")->fetchColumn();
        } else {
            $p->sqliteCreateFunction("twice", function ($x) { return 2 * $x; }, 1);
            $f = "PDO::sqliteCreateFunction(): " . $p->query("SELECT twice(21)")->fetchColumn();
        }
    }
    Swoole\Runtime::enableCoroutine(SWOOLE_HOOK_ALL);
    $o = array();
    Swoole\Coroutine\run(function () use (&$o) {
        Swoole\Coroutine::create(function () use (&$o) {
            $d = new PDO("sqlite::memory:");
            $o[] = "query " . $d->query("WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM c WHERE x < 3000000) SELECT count(*) FROM c")->fetchColumn();
        });
        Swoole\Coroutine::create(function () use (&$o) { Swoole\Coroutine::sleep(0.005); $o[] = "timer"; });
    });
    if ($ini && substr($f, -4) !== ": 42") {
        $r = "FAIL $f, not 42";
    } elseif (count($o) == 2 && $o[0] === "timer") {
        $r = "OK SQLite $v" . ($f ? ", $f" : "") . "; in coroutines with SWOOLE_HOOK_ALL: " . implode(", ", $o) . " (the query held its coroutine only)";
    } else {
        $r = "FAIL in coroutines with SWOOLE_HOOK_ALL: " . implode(", ", $o) . " (the query held the worker)";
    }
}
echo $r;
PHP
)
# inicheck <name> <code>: php with its ini files (every module of conf.d), as a
# server runs it; the code echoes "OK ..." or "FAIL ..."
inicheck() {
    _o="$("$php" -d date.timezone=UTC -r "$2" 2>&1 < /dev/null)"
    case "$_o" in
        *"
"*) ;;
        "OK "*) ok "$1" "${_o#OK }"; return ;;
        "FAIL "*) fail "$1" "${_o#FAIL }"; return ;;
    esac
    fail "$1" "$(printf '%s\n' "$_o" | sed -n '/[^[:space:]]/{p;q;}')"
}
if in_repo "php$short-swoole-sqlite"; then
    group=""
    for p in php$short-swoole php$short-swoole-openssl php$short-swoole-sqlite php$short-swoole-sqlite-openssl; do
        in_repo "$p" && group="$group $p"
    done
    # the one tools/install-php.sh put in goes last, so that it is there again at the end
    first=""
    for p in $group; do pkg info -e "$p" && { first="$p"; break; }; done
    [ -n "$first" ] || first="php$short-swoole"
    for p in $(printf '%s\n' $group | grep -v -x "$first") "$first"; do
        # shellcheck disable=SC2046
        if ! put "$p" $(printf '%s\n' $group | grep -v -x "$p"); then
            fail "swoole: $p" "did not install ($log)"
            continue
        fi
        q=false; case "$p" in *-sqlite*) q=true ;; esac
        phpcheck "swoole: $p, SQLite" "$p" "\$q = $q; \$ini = false; $sw_php"
        [ "$q" = true ] && inicheck "swoole: $p, with the modules of conf.d" "\$q = true; \$ini = true; $sw_php"
        libs "swoole: $p, the libraries" "$extdir/swoole.so" libsqlite3.so "$([ "$q" = true ] && echo yes || echo no)"
    done
fi

# --- gd of 5.6 with T1lib ---
if in_repo "php$short-gd-t1lib"; then
    for p in "php$short-gd-t1lib" "php$short-gd"; do
        o="php$short-gd"; [ "$p" = "php$short-gd" ] && o="php$short-gd-t1lib"
        if ! put "$p" "$o"; then
            fail "gd: $p" "did not install ($log)"
            continue
        fi
        t=false; [ "$p" = "php$short-gd-t1lib" ] && t=true
        phpcheck "gd: $p, T1lib" "$p" '
            $i = gd_info();
            $f = function_exists("imagepstext");
            $s = !empty($i["T1Lib Support"]);
            echo ($f === '"$t"' && $s === '"$t"')
                ? "OK imagepstext " . ($f ? "there" : "not there") . ", T1Lib Support " . ($s ? "yes" : "no") . ", GD " . $i["GD Version"]
                : "FAIL imagepstext " . ($f ? "there" : "not there") . ", T1Lib Support " . ($s ? "yes" : "no") . ", T1lib '"$t"' wanted";'
        libs "gd: $p, the libraries" "$extdir/gd.so" libt1.so "$([ "$t" = true ] && echo yes || echo no)"
    done
fi

say "check-variants $ver: $nok OK, $nfail FAIL, $nskip SKIP"
[ "$nfail" = 0 ]
