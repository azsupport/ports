#!/bin/sh
# check-php.sh - check the PHP packages of one version installed on this machine
# (the FreeBSD VM of tools/build.sh, as root, after pkg add of the packages): the
# core phpXY, mod_phpXY and the phpXY-<module> packages, with the checks of
# php-src tools/build-pkg.sh:
#   - php -v of the core, php -m with the ini files of the modules (no warning);
#   - per installed phpXY-<module> package: its ini in etc/phpXY/conf.d
#     (ext-<NN>-<module>.ini, from the @sample of the package: opcache 10 with
#     zend_extension, session 18, the others 20 or 30; the lines of openswoole and
#     gmagick off) and the module in php -m (gmagick in its CLI profile instead:
#     php74-profile gmagick -m lists gmagick and not imagick; openswoole loaded on
#     its own, with the modules of
#     conf.d but swoole: they define the same classes);
#   - per installed phpXY-<module> package, its module loaded with php -n and
#     only the modules of the packages it depends on (pkg query %dn, directly
#     or not, each after those it needs; opcache as zend_extension), under
#     LD_BIND_NOW=1 with the same files in LD_PRELOAD: a function that none of
#     the loaded files defines then fails the load (mysqlnd.so as phpize linked
#     it, without libcrypto and libz), not its first call in a request.
#     LD_PRELOAD for the rtld of FreeBSD: it binds at once only the files it
#     loads at the start, not those of dlopen (PHP's, with RTLD_LAZY), whatever
#     LD_BIND_NOW says (glibc applies it to dlopen too); PHP's dlopen then
#     finds the module loaded;
#   - intl (phpXY-intl), with php -n and only intl and the modules it depends
#     on, a line each: Normalizer::normalize (the NFC of a decomposed letter),
#     NumberFormatter, IntlDateFormatter (a fixed time, a pattern and UTC) and
#     Collator (a German list) of de_DE, each against the exact string of ICU
#     76 (the ICU of az);
#   - readelf -d of every module of lib/php/<API> and of php, php-cgi, php-fpm and
#     libphp of mod_phpXY: the libraries they name (NEEDED) in /lib, /usr/lib or
#     /usr/local/az/lib, the run path (RUNPATH) none or /usr/local/az/lib, which it
#     needs when it links a library there (no ldconfig hints); /usr/local/lib only
#     for a library of a package the package of the file depends on (libpcre2-8 of
#     devel/pcre2 for the core and mod_phpXY);
#   - the compiler of the same files (Mk/Uses/azgcc.mk), by the annotation az_cc
#     of the package of each, its section .comment (the compilers of its objects)
#     and its NEEDED: php, php-cgi, php-fpm and libphp of mod_phpXY GCC <N> (az_cc
#     gcc<N>; N is AZ_GCC of Mk/Uses/azgcc.mk), a module that of its az_cc; GCC:
#     "GCC: (...) <N>." in .comment and no libgcc_s.so.1 (-static-libgcc); clang
#     (intl, swoole, openswoole, imagick, gmagick): no GCC in .comment (which the
#     strip of the base system removes) and no libstdc++ of GCC (C++ with the
#     libc++ of the base system);
#   - php-fpm -t with the configs of the package (php-fpm.conf, php-fpm.d/www.conf);
#   - Apache with mod_phpXY: apachectl -t with its sample as
#     modules.d/280_mod_phpXY.conf (removed again), the module among those Apache
#     loads;
#   - a note (no check) with the time of Zend/bench.php without OPcache (php -n),
#     the script taken from the release tarball of the version in distfiles/php
#     of this tree (or DISTDIR/php).
#
# Usage: sh tools/check-php.sh <version>            (sh tools/check-php.sh 7.4)
#
# Every check prints one line: OK, FAIL with the reason, or SKIP with the reason;
# the same lines go to results/check-php-<version>.txt (RESULTS=<dir> for another
# directory). PREFIX (/usr/local), AZ_PREFIX (/usr/local/az), AZ_GCC (the version
# of GCC, else that of Mk/Uses/azgcc.mk) and DISTDIR (distfiles/ of this tree) can
# be set.
# Exit status: 0 no check failed, 1 a check failed, 2 usage.

set -u

usage() { echo "usage: sh tools/check-php.sh <version>  (7.4, 8.4, ...)" >&2; exit 2; }
[ $# -eq 1 ] || usage
ver="$1"
case "$ver" in [0-9].[0-9]) ;; *) usage ;; esac
short="$(echo "$ver" | tr -d .)"
P="${PREFIX:-/usr/local}"
AZ="${AZ_PREFIX:-/usr/local/az}"
etc="$P/etc/php$short"
php="$P/bin/php$short"
fpm="$P/sbin/php-fpm$short"
modso="$P/libexec/apache24/libphp$short.so"
modsample="$P/etc/apache24/modules.d/280_mod_php$short.conf.sample"
case "$ver" in 5.*) apmod=php5_module ;; 7.*) apmod=php7_module ;; *) apmod=php_module ;; esac
libdirs="/lib /usr/lib $AZ/lib"
# this tree: the version of GCC of the PHP ports (AZ_GCC of Mk/Uses/azgcc.mk), the
# release tarballs of PHP (distfiles/php, as tools/build.sh fetches them)
top="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
gccv="${AZ_GCC:-$(sed -n 's/^AZ_GCC?=[[:space:]]*\([0-9][0-9]*\).*$/\1/p' "$top/Mk/Uses/azgcc.mk" 2>/dev/null | head -n 1)}"
distphp="${DISTDIR:-$top/distfiles}/php"

res="${RESULTS:-results}"
mkdir -p "$res" || { echo "check-php: cannot make the directory $res" >&2; exit 2; }
sum="$res/check-php-$ver.txt"
: > "$sum" || { echo "check-php: cannot write $sum" >&2; exit 2; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-php.XXXXXX")" || { echo "check-php: no temporary directory" >&2; exit 2; }
apconf=""
cleanup() {
    [ -n "$apconf" ] && rm -f "$apconf"
    rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 1' INT TERM

nok=0; nfail=0; nskip=0
say() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$sum"; }
ok() { say "OK   $1${2:+: $2}"; nok=$((nok + 1)); }
fail() { say "FAIL $1: $2"; nfail=$((nfail + 1)); }
skip() { say "SKIP $1: $2"; nskip=$((nskip + 1)); }
first() { printf '%s\n' "$1" | sed -n '/[^[:space:]]/{p;q;}'; }
last3() { printf '%s\n' "$1" | sed '/^[[:space:]]*$/d' | tail -n 3 | tr '\n' ' ' | sed 's/ *$//'; }

say "check-php $ver: $(uname -sr), $(date '+%d.%m.%Y %H:%M:%S')"
[ "$(id -u)" = 0 ] || say "note: not root; the Apache check needs root (it copies the sample into modules.d)"

# runs <name> <program> [arguments]: the program runs and exits 0; its first line
runs() {
    _n="$1"; shift
    if [ ! -x "$1" ]; then fail "$_n" "no $1"; return 1; fi
    if _o="$("$@" 2>&1 < /dev/null)"; then
        ok "$_n" "$(first "$_o")"
    else
        fail "$_n" "exit $?: $(last3 "$_o")"; return 1
    fi
}

# elf_libs <file>: the libraries readelf -d names (the value texts "Shared library:
# [...]", which the readelf of the base system and that of binutils both print)
# are each in one of $libdirs, or in $P/lib when the package that has it there is
# a dependency of the package of the file (dep_lib); the run path (RUNPATH or RPATH)
# is none or $AZ/lib, and that one when a library of $AZ/lib is linked
# dep_lib <library> <file>: $P/lib/<library> belongs to a package that the package
# of <file> depends on
dep_lib() {
    _o="$(pkg which -q "$P/lib/$1" 2>/dev/null)"; [ -n "$_o" ] || return 1
    _p="$(pkg which -q "$2" 2>/dev/null)"; [ -n "$_p" ] || return 1
    pkg query '%dn' "$_p" | grep -qx "${_o%-*}"
}
elf_libs() {
    _f="$1"; _n="libraries of ${1#"$P"/}"
    [ -f "$_f" ] || { fail "$_n" "no $_f"; return; }
    if ! _d="$(readelf -d "$_f" 2>&1)"; then fail "$_n" "readelf -d: $(last3 "$_d")"; return; fi
    _bad=""; _libs=""; _inaz=""
    for _l in $(printf '%s\n' "$_d" | sed -n 's/.*[Ss]hared library: \[\(.*\)\].*/\1/p'); do
        _w=""
        for _dir in $libdirs; do
            if [ -e "$_dir/$_l" ]; then _w="$_dir"; break; fi
        done
        if [ -z "$_w" ] && [ -e "$P/lib/$_l" ] && dep_lib "$_l" "$_f"; then
            _libs="$_libs $_l ($P/lib, of $(pkg which -q "$P/lib/$_l"))"
            continue
        fi
        if [ -z "$_w" ]; then
            _where="found nowhere"
            [ -e "$P/lib/$_l" ] && _where="it is in $P/lib"
            _bad="$_bad $_l is not in $(echo $libdirs | sed 's/ /, /g') ($_where);"
            continue
        fi
        _libs="$_libs $_l"
        [ "$_w" = "$AZ/lib" ] && _inaz=1
    done
    # each directory once: a module of phpize gets -rpath of az from LDFLAGS and again
    # from its libtool (curl.so: /usr/local/az/lib:/usr/local/az/lib), the same path
    _rp="$(printf '%s\n' "$_d" | sed -n 's/.*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1/p' | tr ':' '\n' |
        awk 'NF && !s[$0]++ { printf "%s%s", (n++ ? ":" : ""), $0 }')"
    if [ -n "$_rp" ] && [ "$_rp" != "$AZ/lib" ]; then
        _bad="$_bad the run path is $_rp, not $AZ/lib;"
    fi
    if [ -n "$_inaz" ] && [ "$_rp" != "$AZ/lib" ]; then
        _bad="$_bad it links a library of $AZ/lib without the run path $AZ/lib;"
    fi
    if [ -n "$_bad" ]; then
        fail "$_n" "$(printf '%s' "${_bad# }" | sed 's/;$//')"
    else
        ok "$_n" "${_libs# }${_rp:+ (run path $_rp)}"
    fi
}

# cc_check <file> [gcc]: the compiler of a file against the annotation az_cc of
# its package (Mk/Uses/azgcc.mk: gcc<N> or clang; "gcc": the file must be of GCC).
# gcc<N> (N: $gccv, AZ_GCC of Mk/Uses/azgcc.mk): the strings "GCC: (...) <N>.<...>"
# in its section .comment (each object leaves its compiler there; the start files
# of the base system name clang too) and no NEEDED libgcc_s.so.1 (-static-libgcc);
# clang: no GCC in .comment (which the strip of the base system removes) and no
# NEEDED libstdc++ (its C++ with the libc++ of the base system)
cc_check() {
    _f="$1"; _n="compiler of ${1#"$P"/}"
    [ -f "$_f" ] || { fail "$_n" "no $_f"; return; }
    _p="$(pkg which -q "$_f" 2>/dev/null)"
    [ -n "$_p" ] || { fail "$_n" "no package has $_f"; return; }
    _a="$(pkg query '%At %Av' "$_p" 2>/dev/null | awk '$1 == "az_cc" { print $2; exit }')"
    _c="$(readelf -p .comment "$_f" 2>/dev/null | sed -n 's/^ *\[ *[0-9a-fA-F]*\] *//p' | sort -u)"
    _d="$(readelf -d "$_f" 2>/dev/null | sed -n 's/.*[Ss]hared library: \[\(.*\)\].*/\1/p')"
    _g="$(printf '%s\n' "$_c" | sed -n 's/^GCC: (.*) \([0-9][0-9.]*\).*$/\1/p' | sort -u | tr '\n' ' ' | sed 's/ *$//')"
    _l="$(printf '%s\n' "$_c" | sed -n 's/^.*clang version \([0-9][0-9.]*\).*$/\1/p' | sort -u | tr '\n' ' ' | sed 's/ *$//')"
    _why=""
    # what the file must be: the az_cc of its package, GCC of Mk/Uses/azgcc.mk for "gcc"
    _w="$_a"
    case "$_a" in
        gcc[0-9]*|clang) ;;
        '') _why=" $_p has no annotation az_cc (Mk/Uses/azgcc.mk);" ;;
        *) _why=" $_p has az_cc $_a, neither gcc<N> nor clang;" ;;
    esac
    case "${2:-}:$_a" in
        gcc:gcc[0-9]*) ;;
        gcc:*) _w="gcc$gccv"; [ -n "$_a" ] && _why="$_why $_p has az_cc $_a, not GCC;" ;;
    esac
    case "$_w" in
        gcc*)
            if [ -n "$gccv" ] && [ "$_w" != "gcc$gccv" ]; then
                _why="$_why $_p has az_cc $_w, not gcc$gccv (Mk/Uses/azgcc.mk);"
            fi
            if [ -z "$_c" ]; then
                _why="$_why no section .comment (a strip that removes it: not the strip of the binutils of the ports, STRIPBIN);"
            elif [ -z "$_g" ]; then
                _why="$_why .comment names no GCC: $(printf '%s\n' "$_c" | head -n 2 | tr '\n' ';' | cut -c1-160);"
            else
                for _v in $_g; do
                    case "$_v" in "${_w#gcc}".*) ;; *) _why="$_why .comment names GCC $_v, not ${_w#gcc}.x;" ;; esac
                done
            fi
            if printf '%s\n' "$_d" | grep -qx 'libgcc_s\.so\.1'; then
                _why="$_why NEEDED libgcc_s.so.1 (not linked with -static-libgcc);"
            fi
            _got="GCC $_g, no libgcc_s.so.1" ;;
        clang)
            [ -z "$_g" ] || _why="$_why .comment names GCC $_g;"
            _s="$(printf '%s\n' "$_d" | grep '^libstdc++' | head -n 1)"
            [ -z "$_s" ] || _why="$_why NEEDED $_s, the C++ library of GCC;"
            _got="clang ${_l:-(no .comment: the strip of the base system removes it)}"
            if printf '%s\n' "$_d" | grep -qx 'libc++\.so\.1'; then _got="$_got, C++ with libc++.so.1"; fi ;;
    esac
    if [ -n "$_why" ]; then
        fail "$_n" "$(printf '%s' "${_why# }" | sed 's/;$//')"
    else
        ok "$_n" "$_got ($_p: az_cc $_a)"
    fi
}

# has_module <file of php -m> <module>: the module in it (any case)
has_module() { grep -qix "$2" "$1"; }

# mod_of <package>: the module of a phpXY-<module> package, by the name of its
# ini (ext-<NN>-<module>.ini.sample in etc/phpXY/conf.d)
mod_of() {
    pkg query '%Fp' "$1" 2>/dev/null |
        sed -n "s#^$etc/conf.d/ext-[0-9][0-9]-\([^/]*\)\.ini\.sample\$#\1#p" | head -n 1
}

# dep_order <package> [<the packages on the way to it>]: the module packages
# (those of $tmp/pkgs) it depends on (pkg query %dn), directly or through
# another, each after those it depends on, and last itself; one that two of them
# depend on comes twice (the caller keeps the first). A subshell: each call has
# its own variables.
dep_order() (
    for _d in $(pkg query '%dn' "$1" 2>/dev/null | sort); do
        grep -qx "$_d" "$tmp/pkgs" || continue
        case " $* " in *" $_d "*) continue ;; esac
        dep_order "$_d" "$@"
    done
    printf '%s\n' "$1"
)

# intl_check <name> <PHP code> [<arguments of php>]: the code with php -n, the
# extension directory and the arguments (-d lines of intl and the modules it
# depends on); the code prints one line, "OK <what it got>" or "FAIL <what it
# got, what it should be>"; any other output (a warning, an error) fails with
# its first line that is not that of OK
intl_check() {
    _n="$1"; _c="$2"; shift 2
    _o="$("$php" -n -d "extension_dir=$extdir" -d date.timezone=UTC "$@" -r "$_c" 2>&1 < /dev/null)"
    case "$_o" in
        *"
"*) ;;
        "OK "*) ok "$_n" "${_o#OK }"; return ;;
        "FAIL "*) fail "$_n" "${_o#FAIL }"; return ;;
    esac
    fail "$_n" "$(printf '%s\n' "$_o" | sed -n '/^OK /d; /[^[:space:]]/{p;q;}')"
}

# intl_checks [<arguments of php>]: intl on the data of its ICU, each against
# the exact string of ICU 76: the NFC of a decomposed letter, a number, a date
# and an order of de_DE
intl_checks() {
    intl_check "intl: Normalizer::normalize" '
        $s = Normalizer::normalize("Cafe\xCC\x81", Normalizer::FORM_C);
        $h = is_string($s) ? bin2hex($s) : var_export($s, true);
        echo $h === "436166c3a9" ? "OK \"Cafe\" U+0301 -> \"$s\" (NFC, 436166c3a9), ICU " . INTL_ICU_VERSION
            : "FAIL \"Cafe\" U+0301 -> $h, not 436166c3a9";' "$@"
    intl_check "intl: NumberFormatter de_DE" '
        $f = new NumberFormatter("de_DE", NumberFormatter::DECIMAL);
        $s = $f->format(1234567.891);
        $w = "1.234.567,891";
        echo $s === $w ? "OK 1234567.891 -> \"$s\"" : "FAIL 1234567.891 -> " . var_export($s, true) . ", not \"$w\"";' "$@"
    intl_check "intl: IntlDateFormatter de_DE" '
        $p = "EEEE, d. MMMM yyyy, HH:mm:ss";
        $f = new IntlDateFormatter("de_DE", IntlDateFormatter::NONE, IntlDateFormatter::NONE, "UTC",
            IntlDateFormatter::GREGORIAN, $p);
        $s = $f->format(1234567890);
        $w = "Freitag, 13. Februar 2009, 23:31:30";
        echo $s === $w ? "OK 1234567890, UTC, \"$p\" -> \"$s\""
            : "FAIL 1234567890, UTC, \"$p\" -> " . var_export($s, true) . ", not \"$w\"";' "$@"
    intl_check "intl: Collator de_DE" '
        $c = new Collator("de_DE");
        $a = array("Zebra", "\xC3\x84pfel", "Ofen", "B\xC3\xA4r", "Apfel", "\xC3\x96sterreich", "Bar");
        $c->sort($a);
        $s = implode(" ", $a);
        $w = "Apfel \xC3\x84pfel Bar B\xC3\xA4r Ofen \xC3\x96sterreich Zebra";
        echo $s === $w ? "OK $s" : "FAIL $s, not $w";' "$@"
}

# the packages: the core, not the static PHP of az-menu.sh in its place
pkg info -e "php$short" || fail "package php$short" "not installed"
if pkg info -e "php$short-static"; then
    fail "package php$short-static" "installed (the static PHP of az-menu.sh has the files of php$short)"
fi
if ! runs "php$short -v" "$php" -v; then
    say "result: $nok ok, $nfail failed, $nskip skipped ($sum)"
    exit 1
fi
"$php" -m > "$tmp/m" 2> "$tmp/m.err" < /dev/null
if [ -s "$tmp/m.err" ]; then
    fail "php$short -m prints no warning" "$(last3 "$(cat "$tmp/m.err")")"
else
    ok "php$short -m prints no warning" "$(grep -c -v -e '^\[' -e '^$' "$tmp/m") modules"
fi
extdir="$("$P/bin/php-config$short" --extension-dir 2>/dev/null)"
if [ -z "$extdir" ]; then
    fail "php-config$short --extension-dir" "no answer"
    extdir="$P/lib/php/none"
fi

# The active lines of the ini files of conf.d, without that of swoole: openswoole
# is loaded with them, on its own
: > "$tmp/lines"
for i in "$etc"/conf.d/*.ini; do
    [ -f "$i" ] || continue
    case "${i##*/}" in ext-[0-9][0-9]-swoole.ini) continue ;; esac
    sed -n -E 's/^[[:space:]]*((zend_)?extension)[[:space:]]*=[[:space:]]*"?([^";[:space:]]*)"?.*$/\1=\3/p' "$i" >> "$tmp/lines"
done

# Per module package: its ini, the module in php -m
# the glob matches name-version too: php74-7.4.33_... is the core, not a module
pkg query -g '%n' "php$short-*" 2>/dev/null | grep -v -x -e "php$short" -e "php$short-static" | sort -u > "$tmp/pkgs"
[ -s "$tmp/pkgs" ] || skip "modules" "no package php$short-<module> installed"
intl_done=""
while read -r p; do
    s="$(pkg query '%Fp' "$p" | sed -n "s#^$etc/conf.d/\(ext-[0-9][0-9]-[^/]*\.ini\)\.sample\$#\1#p" | head -n 1)"
    if [ -z "$s" ]; then
        fail "ini of $p" "no $etc/conf.d/ext-<NN>-<module>.ini.sample among its files"
        continue
    fi
    nn="$(echo "$s" | sed 's/^ext-\([0-9][0-9]\)-.*/\1/')"
    mod="$(echo "$s" | sed 's/^ext-[0-9][0-9]-\(.*\)\.ini$/\1/')"
    ini="$etc/conf.d/$s"
    if [ ! -f "$ini" ]; then
        fail "ini of $p" "no $ini (the @sample of the package)"
        continue
    fi
    act="$(grep -E '^[[:space:]]*(zend_)?extension[[:space:]]*=' "$ini" | sed 's/[[:space:]]//g; s/"//g')"
    want="extension=$mod.so"; nnok="20 30"
    case "$mod" in
        opcache) want="zend_extension=opcache.so"; nnok=10 ;;
        session) nnok=18 ;;
        openswoole|gmagick) want="" ;;
    esac
    why=""
    case " $nnok " in *" $nn "*) ;; *) why="priority $nn, not $(echo "$nnok" | sed 's/ / or /');" ;; esac
    if [ -z "$want" ]; then
        case "$mod" in
            gmagick) because="imagick and gmagick must not be loaded into one PHP" ;;
            *) because="swoole and openswoole define the same classes" ;;
        esac
        [ -z "$act" ] || why="$why its line is on ($act), it must be off ($because);"
        grep -q "^;[[:space:]]*extension[[:space:]]*=[[:space:]]*\"\{0,1\}$mod\.so" "$ini" || why="$why no line ;extension=$mod.so;"
    else
        [ "$act" = "$want" ] || why="$why the line is '${act:-none}', not '$want';"
    fi
    if [ -n "$why" ]; then
        fail "ini of $p" "$s: $(printf '%s' "${why# }" | sed 's/;$//')"
    else
        ok "ini of $p" "$s: ${act:-;extension=$mod.so (off)}"
    fi
    mn="$mod"
    [ "$mod" = opcache ] && mn="Zend OPcache"
    if [ "$mod" = openswoole ]; then
        set --
        while read -r l; do set -- "$@" -d "$l"; done < "$tmp/lines"
        "$php" -n -d "extension_dir=$extdir" "$@" -d extension=openswoole.so -m > "$tmp/m-os" 2>&1 < /dev/null
        if has_module "$tmp/m-os" openswoole; then
            ok "openswoole in php$short -m" "with the modules of conf.d but swoole, and extension=openswoole.so"
        else
            fail "openswoole in php$short -m" "with the modules of conf.d but swoole: $(last3 "$(grep -v '^\[' "$tmp/m-os")")"
        fi
    elif [ "$mod" = gmagick ]; then
        # off in conf.d, on in its CLI profile (etc/php74-gmagick, made when the package
        # is installed), with imagick off there
        has_module "$tmp/m" gmagick && fail "gmagick off in php$short -m" "php$short -m lists gmagick: its ini in conf.d must be off"
        pf="$P/bin/php$short-profile"
        if [ ! -x "$pf" ]; then
            fail "gmagick in php$short-profile gmagick -m" "no $pf"
        elif [ ! -d "$P/etc/php$short-gmagick" ]; then
            fail "gmagick in php$short-profile gmagick -m" "no profile $P/etc/php$short-gmagick (the install of $p makes it)"
        else
            "$pf" gmagick -m > "$tmp/m-gm" 2>&1 < /dev/null
            if has_module "$tmp/m-gm" gmagick && ! has_module "$tmp/m-gm" imagick; then
                ok "gmagick in php$short-profile gmagick -m" "gmagick on, imagick off ($P/etc/php$short-gmagick)"
            elif has_module "$tmp/m-gm" gmagick; then
                fail "gmagick in php$short-profile gmagick -m" "imagick is on there too"
            else
                fail "gmagick in php$short-profile gmagick -m" "no gmagick: $(last3 "$(grep -v '^\[' "$tmp/m-gm")")"
            fi
        fi
    elif has_module "$tmp/m" "$mn"; then
        ok "$mod in php$short -m" "$p"
    else
        fail "$mod in php$short -m" "$p is installed, php$short -m has no $mn"
    fi
    # The module with php -n and only the modules of the packages it depends on,
    # theirs first, under LD_BIND_NOW=1 with the same files in LD_PRELOAD
    set --; pre=""; with=""
    for q in $(dep_order "$p" | awk '!s[$0]++'); do
        qm="$mod"
        [ "$q" = "$p" ] || qm="$(mod_of "$q")"
        [ -n "$qm" ] || continue
        case "$qm" in
            opcache) set -- "$@" -d zend_extension=opcache.so ;;
            *) set -- "$@" -d "extension=$qm.so" ;;
        esac
        pre="$pre${pre:+ }$extdir/$qm.so"; with="$with${with:+, }$qm.so"
    done
    bn="$mod.so with LD_BIND_NOW=1"
    LD_BIND_NOW=1 LD_PRELOAD="$pre" "$php" -n -d "extension_dir=$extdir" "$@" -m \
        > "$tmp/m-b" 2> "$tmp/m-b.err" < /dev/null
    st=$?
    e="$(cat "$tmp/m-b.err")"
    if [ "$st" != 0 ]; then
        fail "$bn" "exit $st: $(last3 "${e:-$(cat "$tmp/m-b")}")"
    elif [ -n "$e" ]; then
        fail "$bn" "$(last3 "$e")"
    elif ! has_module "$tmp/m-b" "$mn"; then
        fail "$bn" "php$short -n with $with lists no $mn"
    else
        ok "$bn" "php$short -n with $with"
    fi
    # intl: its functions on the data of ICU, with php -n and the same modules
    if [ "$mod" = intl ]; then
        intl_checks "$@"; intl_done=1
    fi
done < "$tmp/pkgs"
[ -n "$intl_done" ] || skip "intl" "the package php$short-intl is not installed"

# The libraries of the modules and of the programs
n=0
for so in "$extdir"/*.so; do
    [ -f "$so" ] || continue
    elf_libs "$so"; n=$((n + 1))
done
[ "$n" -gt 0 ] || skip "libraries of the modules" "no module in $extdir"
for f in "$php" "$P/bin/php-cgi$short" "$fpm"; do
    [ -f "$f" ] && elf_libs "$f"
done

# The compiler of the programs (GCC) and of the modules (that of the az_cc of
# their packages)
for f in "$php" "$P/bin/php-cgi$short" "$fpm"; do
    [ -f "$f" ] && cc_check "$f" gcc
done
for so in "$extdir"/*.so; do
    [ -f "$so" ] && cc_check "$so"
done

# php-fpm -t with the configs of the package (their @sample lines)
if [ ! -x "$fpm" ]; then
    skip "php-fpm$short -t" "no $fpm (php$short without FPM)"
elif [ ! -f "$etc/php-fpm.conf" ]; then
    fail "php-fpm$short -t" "no $etc/php-fpm.conf (the @sample of the package)"
else
    [ -f "$etc/php-fpm.d/www.conf" ] || say "note: no $etc/php-fpm.d/www.conf (the @sample of the package)"
    runs "php-fpm$short -t" "$fpm" -t
fi

# Apache with mod_phpXY: its sample as modules.d/280_mod_phpXY.conf (removed again),
# apachectl -t and the module among those Apache loads (-D DUMP_MODULES)
an="apachectl -t with libphp$short.so"
ac="$P/sbin/apachectl"
if ! pkg info -e "mod_php$short"; then
    skip "$an" "the package mod_php$short is not installed"
elif [ ! -x "$ac" ]; then
    fail "$an" "no $ac (the package apache24)"
elif [ ! -f "$modso" ] || [ ! -f "$modsample" ]; then
    fail "$an" "mod_php$short is installed without $modso or $modsample"
else
    elf_libs "$modso"
    cc_check "$modso" gcc
    c="${modsample%.sample}"
    go=1
    if [ -f "$c" ]; then
        say "note: $c is there already: checked as it is, not removed"
    elif [ "$(id -u)" != 0 ]; then
        skip "$an" "not root: cannot copy the sample into ${c%/*}"; go=""
    elif cp "$modsample" "$c"; then
        apconf="$c"
    else
        fail "$an" "cannot copy $modsample to $c"; go=""
    fi
    if [ -n "$go" ]; then
        if o="$("$ac" -t -D DUMP_MODULES 2>&1 < /dev/null)"; then
            if printf '%s\n' "$o" | grep -q "^ *$apmod "; then
                ok "$an" "$apmod among $(printf '%s\n' "$o" | grep -c '_module ') modules, $(printf '%s\n' "$o" | grep 'Syntax' | head -n 1)"
            else
                fail "$an" "Syntax OK, but $apmod is not among the modules Apache loads (does httpd.conf include modules.d/[0-9][0-9][0-9]_*.conf?)"
            fi
        else
            fail "$an" "$(last3 "$o")"
        fi
    fi
    if [ -n "$apconf" ]; then rm -f "$apconf"; apconf=""; fi
fi

# The time of Zend/bench.php without OPcache, a note (no check): the script of
# the release tarball of the version (the newest of distfiles/php), with php -n
pv="$("$php" -n -r 'echo PHP_VERSION;' 2> /dev/null < /dev/null)"
tb="$(ls "$distphp"/php-"$pv"-fbsd-*.tar.xz 2> /dev/null | sort | tail -n 1)"
bm=""
[ -n "$tb" ] && bm="$(tar -tf "$tb" 2> /dev/null | grep -m 1 '^[^/]*/Zend/bench\.php$')"
if [ -z "$tb" ]; then
    say "note: no time of Zend/bench.php: no php-${pv:-?}-fbsd-*.tar.xz in $distphp"
elif [ -z "$bm" ]; then
    say "note: no time of Zend/bench.php: ${tb##*/} has no Zend/bench.php"
elif ! tar -xOf "$tb" "$bm" > "$tmp/bench.php" 2> /dev/null; then
    say "note: no time of Zend/bench.php: it does not unpack from ${tb##*/}"
else
    o="$("$php" -n "$tmp/bench.php" 2>&1 < /dev/null)"
    t="$(printf '%s\n' "$o" | sed -n 's/^Total[[:space:]]*\([0-9][0-9.]*\).*$/\1/p' | tail -n 1)"
    if [ -n "$t" ]; then
        say "note: Zend/bench.php without OPcache (php$short -n): Total $t s (the script of ${tb##*/})"
    else
        say "note: no time of Zend/bench.php: php$short -n $bm printed no Total: $(last3 "$o")"
    fi
fi

say "result: $nok ok, $nfail failed, $nskip skipped ($sum)"
[ "$nfail" = 0 ] || exit 1
exit 0
