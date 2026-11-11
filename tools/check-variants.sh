#!/bin/sh
# check-variants.sh - the packages of a module with the same files, each in turn
# in the place of the others (tools/install-php.sh puts in only the first of each):
#   - redis (aZ, 11.11.2026): phpXY-redis without compression, phpXY-redis-lz4,
#     phpXY-redis-zstd and phpXY-redis-lz4-zstd (with liblz4 and libzstd of az);
#     5.6 has only the first (phpredis 4.3.0 knows neither lz4 nor zstd);
#   - gd of 5.6 (aZ, 11.11.2026): php56-gd, and php56-gd-t1lib with T1lib (libt1 of
#     devel/t1lib).
# Each goes in by pkg install -f from the repository azbuild that tools/install-php.sh
# wrote (the others of its group out first: pkg refuses the same files), then:
#   - php -n with the module and those of the packages it depends on: redis the
#     constants Redis::COMPRESSION_LZ4 and Redis::COMPRESSION_ZSTD there or not as
#     the name of the package says, and with each compression it has a round trip of
#     Redis::_compress() and Redis::_uncompress() (no server needed); gd
#     imagepstext() and "T1Lib Support" of gd_info() there or not;
#   - readelf -d of the module: liblz4, libzstd or libt1 named (NEEDED) or not, as
#     the package says.
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
# verdict <name> <exit status> <output>: the one line "OK ..." or "FAIL ..." of the
# code, else a failure with the first line it printed, or with its exit status (and
# signal) when it printed nothing
verdict() {
    case "$3" in
        *"
"*) ;;
        "OK "*) ok "$1" "${3#OK }"; return ;;
        "FAIL "*) fail "$1" "${3#FAIL }"; return ;;
    esac
    _l="$(printf '%s\n' "$3" | sed -n '/[^[:space:]]/{p;q;}')"
    if [ -z "$_l" ]; then
        _l="no output, exit status $2"
        [ "$2" -gt 128 ] 2> /dev/null && _l="$_l (signal $(($2 - 128)))"
    elif [ "$2" != 0 ]; then
        _l="$_l (exit status $2)"
    fi
    fail "$1" "$_l"
}
# phpcheck <name> <package> <code>: php -n with the modules of the package; the code
# echoes "OK ..." or "FAIL ..."
phpcheck() {
    # shellcheck disable=SC2046
    _o="$("$php" -n -d "extension_dir=$extdir" $(phpargs "$2") -r "$3" 2>&1 < /dev/null)"
    verdict "$1" "$?" "$_o"
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
