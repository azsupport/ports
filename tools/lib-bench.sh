#!/bin/sh
# lib-bench.sh - would the C libraries of the package az make the PHP sites faster
# built with GCC of the ports (gcc16) instead of the base clang (clang 19)? aZ,
# 09.11.2026: a library goes to GCC 16 when it is at least 2% faster through what
# the PHP sites do. The workflow .github/workflows/lib-bench.yml runs it in a FreeBSD
# 15.1 VM; with --local it runs on another system (Linux), as a test of the script.
#
# Usage (from the top of a checkout of this tree):
#   sh tools/lib-bench.sh --tree <dir> [<cache> <distdir>]
#           the official ports of the libraries at the commit of az/az/files/deps.conf:
#           a sparse git checkout into <dir> (Mk, Templates, Keywords and those ports);
#           with <cache> (the distfiles of build.yml) the distfiles of those ports,
#           checked against their distinfo, copied from it into <distdir> (what is not
#           there, their make fetch gets). Any system with git: the workflow runs it on
#           the runner, before the VM
#   sh tools/lib-bench.sh --deps
#           FreeBSD, as root, in a VM of its own: the build tools of tools/az-build.sh
#           --tools, gcc16 (else the newest gcc<N>), the DejaVu fonts, and from the
#           repository az (README.md, "A server and the repository az") PHP 8.3 with
#           the modules dom, xml, simplexml, xmlreader, xsl, mbstring, sqlite3, pdo,
#           pdo_sqlite, gd and zip
#   sh tools/lib-bench.sh [-r <runs>] [--ports <dir>] [--distdir <dir>] [<library>...]
#           FreeBSD, as root, after --deps: the libraries (default all) built with
#           both compilers, the proof of what is loaded, the benchmarks, the report
#   sh tools/lib-bench.sh --local [-r <runs>] --src <library>=<dir>... [<library>...]
#           another system (Linux), a test of the script and not a measurement for
#           az: the source trees given (patched by hand), the clang and GCC found
#           there, its PHP and its libraries as the control
#
# The libraries: libxml2 and libxslt (PHP dom, simplexml, xml, xmlreader, xsl),
# oniguruma (mbstring, mb_ereg*), sqlite3 (sqlite3, pdo_sqlite), gd, freetype2 and
# png (gd), mozjpeg (gd JPEG; cjpeg, djpeg), libzip (zip), expat and lcms2 (PHP
# loads them only through imagick and gmagick: the shared ImageMagick 7 and
# GraphicsMagick of az, which stay with clang, take lcms2 for colour profiles and
# fontconfig, which reads its configuration once with expat; the static programs link
# them too; measured with the drivers of tools/lib-bench.c). Not measured, they stay
# with clang: the libraries with assembly or SIMD code of their own (zstd, brotli,
# lz4, webp, dav1d, x264, OpenSSL, libsodium, gmp), the C++ ones (ICU, libheif,
# libde265, libmemcached), ImageMagick and GraphicsMagick (their OpenMP would be
# libgomp of the ports with GCC).
#
# A library is built as tools/az-build.sh builds its shared kind: the source and
# patches of its port at the commit of deps.conf (make patch; the release of its take
# line, if deps.conf has one), its function s_<name> and those it calls, read out of
# az-build.sh at run time, the CFLAGS of the az installed (its VERSIONS: -O3 -pipe
# -march=x86-64-v3 -fstack-protector-strong -fno-strict-aliasing -fPIC), the prefix,
# run path and libraries of /usr/local/az. Twice, each in a copy of the patched tree:
# with the base cc (clang) and with gcc<N> of the packages, which gets -std=gnu17 too
# (the C of clang 19; GCC 15 and later default to C23) and -static-libgcc (no
# libgcc_s of the package); GCC links with its own linker (ld of binutils, as the
# port lang/gcc16 is configured), the base cc with lld. Both install with DESTDIR
# into lib-bench-work/stage/<compiler>/<library>, and /usr/local/az is immutable
# meanwhile (chflags uchg): nothing gets into the az of the system. A GCC build must
# need nothing of the gcc package (NEEDED, run path, ldd), and each of its libraries
# has a SONAME that /usr/local/az/lib has.
#
# The variants of a library: az (the file of the release in /usr/local/az/lib: the
# control, which the clang build should match), <clang> and <gcc>: the lib/ of that
# build in front by LD_LIBRARY_PATH, which rtld searches before the DT_RUNPATH
# /usr/local/az/lib of PHP, its modules and the libraries of az; one library at a
# time, the others stay those of az. The proof, before the runs: ldd of the module
# (or program) with that LD_LIBRARY_PATH, and the file a PHP process has mapped
# (procstat -v; the drivers: dladdr), with the compiler of its .comment; a variant
# whose library is not the one loaded is left out.
#
# The benchmarks: those of tools/lib-bench.php (php83 -n with the modules) and the
# programs: xmllint --repeat of the clang build of libxml2, cjpeg and djpeg of the
# clang build of mozjpeg, speedtest1 of the source of sqlite3, lb-expat and lb-lcms2
# of tools/lib-bench.c; their inputs made by lib-bench.php --gen from a fixed seed.
# The work of a run is set once: the az variant run once, n such that a run takes
# about LB_TARGET seconds (default 3); then <runs> rounds (default 9, at least 7 for
# a verdict): in each, every benchmark with each of its variants in turn, the order
# turning from round to round, pinned to the last CPU (cpuset -l, taskset -c).
#
# The report (lib-bench-results/report.txt, report.md for the job summary): per
# library and benchmark the median seconds of each variant, the change of gcc against
# clang (the median of the ratios of the runs of the same round, and its interval of
# about 95%: the order statistics of the sign test), the spread of the runs
# ((max - min) / median, the largest of the three variants) and whether the outputs
# are the same; per library, over its PHP benchmarks (expat and lcms2: their drivers),
# the geometric mean of the ratios of each round, its median and interval: ">= 2%
# faster" when the median is -2% or less and the whole interval is below 0. Every
# build, proof or run that fails is printed with its reason (and kept in
# failures.txt), and the rest goes on.
#
# Environment: LB_TARGET (seconds of a run, default 3), LB_GAIN (the gain asked in
# %, default 2), LB_GCC (the GCC, default the newest gcc<N>), LB_CLANG (--local: the
# clang), LB_PHP (the PHP, default php83; --local: php), LB_KEEP=1 (keep
# lib-bench-work).
# Exit status: 0 the report has results, 1 no result, 2 usage.

set -u
top="$(pwd)"
tools="$(cd "$(dirname "$0")" && pwd)"
azb="$tools/az-build.sh"
files="$(cd "$tools/../az/az/files" 2>/dev/null && pwd)"
conf="$files/deps.conf"
os="$(uname -s)"
res="$top/lib-bench-results"
work="$top/lib-bench-work"
logs="$res/logs"
libs_all="libxml2 libxslt oniguruma sqlite3 gd freetype2 png mozjpeg expat libzip lcms2"
php_mods="dom xml simplexml xmlreader xsl mbstring sqlite3 pdo pdo_sqlite gd zip"
php_ver="${LB_PHP_VERSION:-8.3}"
say() { printf '[lib-bench %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
usage() { sed -n 's/^# \{0,1\}//; 8,28p' "$0" >&2; exit 2; }

sha256_of() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else sha256 -q "$1"; fi
}
port_line() { awk -v n="$1" '$1 == "lib" && $2 == n { print $3 }' "$conf"; }

# --- --tree <dir> [<cache> <distdir>] ------------------------------------------------
tree() {
    d="$1"; cache="${2:-}"; dd="${3:-}"
    commit="$(awk '$1 == "ports" { print $2 }' "$conf")"
    [ -n "$commit" ] || { echo "lib-bench: no ports line in $conf" >&2; return 1; }
    # what the framework reads besides the ports: Mk, Templates, Keywords, the users and
    # groups, MOVED, the version of perl (USES=perl5)
    paths="/Mk/ /Templates/ /Keywords/ /UIDs /GIDs /MOVED /lang/perl5*/version.mk"
    for n in $libs_all; do
        p="$(port_line "$n")"
        case "$p" in
            ""|bundle) echo "lib-bench: $n: no port of its own in deps.conf (${p:-no lib line})"; continue ;;
        esac
        paths="$paths /$p/"
    done
    rm -rf "$d" && mkdir -p "$d" && git -C "$d" init -q &&
        git -C "$d" remote add origin https://github.com/freebsd/freebsd-ports || return 1
    ok=0
    for try in 1 2 3; do
        if git -C "$d" fetch -q --depth 1 --filter=blob:none origin "$commit"; then ok=1; break; fi
        echo "lib-bench: git fetch of freebsd-ports $commit failed (try $try of 3)"
        sleep $((try * 15))
    done
    [ "$ok" = 1 ] || return 1
    # shellcheck disable=SC2086
    git -C "$d" sparse-checkout set --no-cone $paths && git -C "$d" checkout -q FETCH_HEAD || return 1
    echo "lib-bench: $d: freebsd-ports $commit ($paths)"
    [ -n "$cache" ] || return 0
    mkdir -p "$dd" || return 1
    for n in $libs_all; do
        p="$(port_line "$n")"
        [ -f "$d/$p/distinfo" ] || continue
        sed -n 's/^SHA256 (\(.*\)) = \([0-9a-f]*\)$/\1 \2/p' "$d/$p/distinfo" | while read -r f sum; do
            if [ -f "$cache/$f" ] && [ "$(sha256_of "$cache/$f")" = "$sum" ]; then
                mkdir -p "$dd/$(dirname "$f")" && cp "$cache/$f" "$dd/$f" && echo "lib-bench: $f: from $cache"
            else
                echo "lib-bench: $f: not in $cache, or not as its distinfo has it (the make fetch of $p gets it)"
            fi
        done
        # the release of a take line: a distfile of the port az/az (DISTDIR/az)
        t="$(awk -v n="$n" '$1 == "take" && $2 == n { print $4 }' "$conf")"
        if [ -n "$t" ]; then
            tf="${t%%,*}"; tf="${tf##*/}"
            if [ -f "$cache/az/$tf" ]; then mkdir -p "$dd/az" && cp "$cache/az/$tf" "$dd/az/$tf" && echo "lib-bench: az/$tf: from $cache"
            else echo "lib-bench: az/$tf (take line of $n): not in $cache (fetched in the build)"; fi
        fi
    done
    return 0
}

# --- --deps ---------------------------------------------------------------------------
deps() {
    [ "$os" = FreeBSD ] || { echo "lib-bench: --deps is for FreeBSD (pkg)" >&2; return 2; }
    drc=0
    env ASSUME_ALWAYS_YES=yes pkg update || echo "lib-bench: pkg update failed"
    sh "$azb" --tools || { echo "lib-bench: not every build tool of tools/az-build.sh --tools installed"; drc=1; }
    # GCC: gcc16, else the newest gcc<N> of the repository (as tools/bench.sh of azsupport/php-src)
    want="${LB_GCC_PKG:-gcc16}"
    if pkg info -e "$want" || [ -n "$(pkg rquery '%n' "$want" 2>/dev/null)" ]; then name="$want"
    else
        name="gcc$(pkg rquery -x '%n' '^gcc[0-9]+$' 2>/dev/null | sed 's/^gcc//' | sort -n | tail -n 1)"
        echo "lib-bench: $want is not in the package repository; taking $name"
    fi
    if [ "$name" = gcc ] || ! env ASSUME_ALWAYS_YES=yes pkg install -y "$name"; then
        echo "lib-bench: pkg install $name failed"; drc=1
    fi
    env ASSUME_ALWAYS_YES=yes pkg install -y dejavu || { echo "lib-bench: pkg install dejavu failed (imagettftext)"; drc=1; }
    # the repository az, as on a server (README.md)
    major="$(uname -r | cut -d. -f1)"
    url="${LB_AZ_URL:-https://github.com/azsupport/ports/releases/download/az-fbsd$major-amd64-v3}"
    mkdir -p /usr/local/etc/pkg/repos /usr/local/etc/pkg/keys &&
        install -m 644 "$tools/../keys/az.pub" /usr/local/etc/pkg/keys/az.pub &&
        printf '%s\n' "az: { url: \"$url\", signature_type: \"pubkey\", pubkey: \"/usr/local/etc/pkg/keys/az.pub\", priority: 100, enabled: yes }" \
            > /usr/local/etc/pkg/repos/az.conf || { echo "lib-bench: cannot write the configuration of the repository az"; return 1; }
    if ! pkg update -f -r az; then echo "lib-bench: pkg update -r az failed ($url)"; return 1; fi
    pv="php$(echo "$php_ver" | tr -d .)"
    pk="$pv"
    for m in $php_mods; do pk="$pk $pv-$m"; done
    # shellcheck disable=SC2086
    env ASSUME_ALWAYS_YES=yes CONSERVATIVE_UPGRADE=no pkg install -y -r az $pk || { echo "lib-bench: pkg install -r az $pk failed"; drc=1; }
    # shellcheck disable=SC2086
    pkg query '%n-%v (%R)' az $pk "$name" dejavu 2>&1
    return $drc
}

case "${1:-}" in
    --tree) [ $# -ge 2 ] && [ $# -ne 3 ] && [ $# -le 4 ] || usage; tree "$2" "${3:-}" "${4:-}"; exit $? ;;
    --deps) deps; exit $? ;;
esac

local=0
runs=9
ports="$top/lib-bench-ports"
distdir="$top/lib-bench-distfiles"
srcs=""
while [ $# -gt 0 ]; do
    case "$1" in
        --local) local=1; shift ;;
        -r) [ $# -ge 2 ] || usage; runs="$2"; shift 2 ;;
        --ports) [ $# -ge 2 ] || usage; ports="$2"; shift 2 ;;
        --distdir) [ $# -ge 2 ] || usage; distdir="$2"; shift 2 ;;
        --src) [ $# -ge 2 ] || usage; srcs="$srcs $2"; shift 2 ;;
        -*) usage ;;
        *) break ;;
    esac
done
case "$runs" in ''|*[!0-9]*|0) echo "lib-bench: -r wants a number of runs, not $runs" >&2; exit 2 ;; esac
libs="${*:-$libs_all}"
for n in $libs; do
    case " $libs_all " in *" $n "*) ;; *) echo "lib-bench: $n is not one of: $libs_all" >&2; exit 2 ;; esac
done
if [ "$local" = 0 ] && [ "$os" != FreeBSD ]; then
    echo "lib-bench: not FreeBSD: --local (a test of the script) takes the compilers and the PHP found here" >&2; exit 2
fi
target="${LB_TARGET:-3}"
gain="${LB_GAIN:-2}"

rm -rf "$res" "$work"
mkdir -p "$res" "$logs" "$work/src" "$work/bin" "$work/data" "$work/tmp" || exit 1
stage="$work/stage"
info="$res/info.txt"
: > "$info"; : > "$res/failures.txt"; : > "$res/variants.txt"; : > "$res/runs.txt"; : > "$res/proof.txt"
# fail <what> <reason>: printed, and kept for the report and the annotations of the workflow
fail() { say "FAIL $1: $2"; printf '%s: %s\n' "$1" "$2" >> "$res/failures.txt"; }
first_errors() {
    grep -E ' error:|error: |Error [0-9]+|\*\*\* Error|undefined reference|undefined symbol|cannot find|not found|No such file|Killed|failed' "$1" |
        grep -v -E '^checking |^-- (Looking|Performing|Check)' | head -n 3 | cut -c1-240 | tr '\n' ' ' | grep . || tail -n 3 "$1" | cut -c1-240 | tr '\n' ' '
}

# --- the system, the compilers, PHP -------------------------------------------------
if [ "$os" = FreeBSD ]; then
    ncpu="$(sysctl -n hw.ncpu)"
    cpu="$(sysctl -n hw.model)"
    mem="$(( $(sysctl -n hw.physmem) / 1048576 )) MB"
else
    ncpu="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN)"
    cpu="$(sed -n 's/^model name[^:]*: *//p' /proc/cpuinfo 2>/dev/null | head -n 1)"
    mem="$(( $(sed -n 's/^MemTotal: *\([0-9]*\).*/\1/p' /proc/meminfo) / 1024 )) MB"
fi
first_line() { "$@" 2>&1 | grep -v '^ *$' | head -n 1; }
is_clang() { "$1" --version 2>/dev/null | head -n 1 | grep -q clang; }
cc_major() { "$1" -dumpversion 2>/dev/null | cut -d. -f1; }
if [ "$local" = 0 ]; then
    cc1=cc; cxx1=c++
    S=/usr/local/az
    php="${LB_PHP:-/usr/local/bin/php$(echo "$php_ver" | tr -d .)}"
    gl="/usr/local/bin/gcc[0-9]*"
else
    cc1="${LB_CLANG:-$(for c in /usr/bin/clang-[0-9]*; do [ -x "$c" ] && echo "${c##*-} $c"; done | sort -n | tail -n 1 | cut -d' ' -f2-)}"
    [ -n "$cc1" ] || cc1="$(command -v clang 2>/dev/null)"
    cxx1="$(echo "$cc1" | sed 's/clang/clang++/')"
    # the prefix of the builds: empty, so that what installs outside DESTDIR harms nothing
    S="$work/sysroot"
    php="${LB_PHP:-$(command -v php 2>/dev/null)}"
    gl="/usr/bin/gcc-[0-9]*"
fi
P="$S/static"
cc2="${LB_GCC:-}"
if [ -z "$cc2" ]; then
    # shellcheck disable=SC2086
    cc2="$(for c in $gl; do
        case "${c##*/}" in gcc[0-9]|gcc[0-9][0-9]|gcc-[0-9]|gcc-[0-9][0-9]) ;; *) continue ;; esac
        [ -x "$c" ] && echo "$(echo "${c##*/}" | tr -dc 0-9) $c"
    done | sort -n | tail -n 1 | cut -d' ' -f2-)"
fi
cxx2="$(echo "$cc2" | sed 's#gcc\([^/]*\)$#g++\1#')"
c1=""; c2=""
[ -n "$cc1" ] && is_clang "$cc1" && c1="clang$(cc_major "$cc1")"
[ -n "$cc2" ] && ! is_clang "$cc2" && c2="gcc$(cc_major "$cc2")"
[ -n "$c1" ] || { echo "lib-bench: no clang (${cc1:-none found}; LB_CLANG)" >&2; exit 1; }
[ -n "$c2" ] || { echo "lib-bench: no GCC (${cc2:-none found}; --deps, LB_GCC)" >&2; exit 1; }
[ -x "$php" ] || { echo "lib-bench: no PHP $php (--deps, LB_PHP)" >&2; exit 1; }
ctl=az; [ "$local" = 1 ] && ctl=system

# the CFLAGS of the libraries of az (its VERSIONS), else those of az-build.sh
cflags=""
[ -f "$S/share/doc/az/VERSIONS" ] && cflags="$(sed -n 's/^.*; CFLAGS: //p' "$S/share/doc/az/VERSIONS" | head -n 1)"
cflags_from="the VERSIONS of az ($S/share/doc/az/VERSIONS)"
if [ -z "$cflags" ]; then
    cflags="-O3 -pipe -march=x86-64-v3 -fstack-protector-strong -fno-strict-aliasing -fPIC"
    cflags_from="those of tools/az-build.sh (no VERSIONS of az)"
fi
# this CPU has to run code of that level (the PHP of the release has it too)
march="$(printf '%s\n' $cflags | sed -n 's/^-march=//p' | tail -n 1)"
cpu_feats() {
    "$cc1" "-march=$1" -dM -E - < /dev/null 2>/dev/null |
        sed -n -E 's/^#define __(SSE4_2|POPCNT|AVX|AVX2|BMI|BMI2|FMA|F16C|LZCNT|MOVBE)__ 1$/\1/p' | LC_ALL=C sort -u
}
if [ -n "$march" ]; then
    cpu_feats "$march" > "$work/cpu-need"
    cpu_feats native > "$work/cpu-have"
    lacks="$(LC_ALL=C comm -23 "$work/cpu-need" "$work/cpu-have" | tr '\n' ' ' | sed 's/ *$//')"
    if [ -n "$lacks" ]; then
        if [ "$local" = 0 ]; then echo "lib-bench: this CPU ($cpu) lacks $lacks of -march=$march: it cannot run the libraries" >&2; exit 1; fi
        cflags="$(echo "$cflags" | sed 's/-march=[^ ]*/-march=x86-64-v2/')"
        say "WARNING: this CPU lacks $lacks of -march=$march: the builds are for x86-64-v2"
    fi
fi
cflags1="$cflags"
cflags2="$cflags -std=gnu17 -static-libgcc"
ld2="$("$cc2" -print-prog-name=ld 2>/dev/null)"

# PHP: -n and the modules that are not built in, each loaded after those it needs; one
# that does not load is left out (the benchmarks that need it fail with the reason)
extdir="$("$php" -n -r 'echo ini_get("extension_dir");' 2>/dev/null)"
php_args="-n -d memory_limit=2G"
for m in $php_mods; do
    "$php" -n -r "exit(extension_loaded('$m') ? 0 : 1);" 2>/dev/null && continue
    # shellcheck disable=SC2086
    if o="$("$php" $php_args -d "extension=$m" -r "exit(extension_loaded('$m') ? 0 : 1);" 2>&1)"; then
        php_args="$php_args -d extension=$m"
    else
        fail "PHP module $m" "does not load: $(echo "$o" | grep -v '^ *$' | head -n 2 | tr '\n' ' ' | cut -c1-240)"
    fi
done
phpv="$(first_line "$php" -n -v)"
lb_php() { "$php" $php_args "$tools/lib-bench.php" "$@"; }

# the runs on the last CPU
pincpu=$((ncpu - 1))
pin=""
if command -v cpuset > /dev/null 2>&1 && cpuset -l "$pincpu" true 2>/dev/null; then pin="cpuset -l $pincpu"
elif command -v taskset > /dev/null 2>&1 && taskset -c "$pincpu" true > /dev/null 2>&1; then pin="taskset -c $pincpu"; fi

{
    echo "system: $(uname -srm); CPU: $cpu; $ncpu CPUs, $mem"
    if [ "$local" = 0 ]; then
        echo "az: $(pkg query '%n-%v (%R)' az 2>/dev/null); $(sed -n 2p "$S/share/doc/az/VERSIONS" 2>/dev/null | cut -d';' -f1)"
        echo "deps.conf: freebsd-ports $(awk '$1 == "ports" { print $2 }' "$conf")"
    else
        echo "--local: a test of the script, not a measurement for az; the control ($ctl) is the library of this system"
    fi
    echo "PHP: $php ($phpv), $php_args"
    echo "$c1: $cc1 ($(first_line "$cc1" --version)), linker $(first_line "$cc1" -Wl,--version -x c /dev/null -o /dev/null 2>&1 | cut -c1-80)"
    echo "$c2: $cc2 ($(first_line "$cc2" --version)), linker ${ld2:-?} ($(first_line "${ld2:-ld}" --version | cut -c1-80))"
    echo "CFLAGS of $c1: $cflags1 ($cflags_from)"
    echo "CFLAGS of $c2: $cflags2"
    echo "runs: $runs rounds of about ${target}s per run, the variants interleaved${pin:+, pinned to CPU $pincpu ($pin)}"
} > "$info"
cat "$info"

# --- the functions of tools/az-build.sh ---------------------------------------------
# fn <name>...: their definitions as they are in az-build.sh (a one-line function, or
# up to the first "}" at the start of a line)
fn() {
    for f; do
        awk -v n="$f" '
            !on && index($0, n "() {") == 1 { on = 1; print; if ($0 ~ /}[ \t]*$/) exit; next }
            on { print; if ($0 == "}") exit }
        ' "$azb"
    done
}
helpers="so_env at_so cm_so_in cm_so fix_guess pmake take_of take_args"
for f in $helpers; do
    [ -n "$(fn "$f")" ] || { echo "lib-bench: no function $f in $azb" >&2; exit 1; }
done
eval "$(fn $helpers)"
for n in $libs; do
    if [ -n "$(fn "s_$n")" ]; then eval "$(fn "s_$n")"
    else fail "$n" "no function s_$n in tools/az-build.sh"; libs="$(echo " $libs " | sed "s/ $n / /; s/^ *//; s/ *$//")"; fi
done
ncpu_build="$ncpu"
path0="$PATH"
if [ "$local" = 1 ]; then
    # no ports tree: the sources are patched already
    fix_guess() { :; }
    pcx="$(pkgconf --variable pc_path pkg-config 2>/dev/null || pkg-config --variable pc_path pkg-config 2>/dev/null)"
else
    pcx=""
fi

# --- the sources ----------------------------------------------------------------------
# $work/src/<name>: "<dir> <source>": the patched tree of a library (the work directory
# of its port, or the tree given to --local) and its source tree inside it; each
# compiler builds in a copy of <dir> (copy_of)
copy_of() {
    if [ "$local" = 0 ]; then echo "$1.$2"; else echo "$work/build/$2/$3"; fi
}
ok_libs=""
if [ "$local" = 0 ]; then
    if [ ! -f "$ports/Mk/bsd.port.mk" ]; then
        say "no ports tree in $ports: a sparse checkout"
        tree "$ports" > "$logs/tree.log" 2>&1 || { cat "$logs/tree.log"; echo "lib-bench: no ports tree" >&2; exit 1; }
    fi
    commit="$(awk '$1 == "ports" { print $2 }' "$conf")"
    h="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    [ -z "$h" ] || [ "$h" = "$commit" ] || { echo "lib-bench: $ports is at $h, deps.conf has $commit" >&2; exit 1; }
    vc="$(sed -n 's/^freebsd-ports \([0-9a-f]*\);.*/\1/p' "$S/share/doc/az/VERSIONS" 2>/dev/null)"
    if [ -n "$vc" ] && [ "$vc" != "$commit" ]; then
        say "WARNING: az was built from freebsd-ports $vc, deps.conf has $commit: the control may be other versions"
        echo "WARNING: az of freebsd-ports $vc, deps.conf $commit" >> "$info"
    fi
    mkdir -p "$distdir"
    ports="$(cd "$ports" && pwd)"; distdir="$(cd "$distdir" && pwd)"
    # what pmake and take_args of az-build.sh read: their make, the distfiles, the
    # releases of take lines
    takedist="$distdir/az"
    for n in $libs; do
        port="$(port_line "$n")"
        say "$n: make patch of $port"
        if (
            targs="$(take_args "$n" "$port")" || { echo "== the release of the take line of $n could not be had"; exit 1; }
            # shellcheck disable=SC2086
            wd="$(pmake "$port" $targs -V WRKDIR)"; sd="$(pmake "$port" $targs -V WRKSRC)"
            [ -n "$wd" ] && [ -n "$sd" ] || { echo "== no WRKDIR or WRKSRC of $port"; exit 1; }
            # shellcheck disable=SC2086
            pmake "$port" $targs clean > /dev/null 2>&1
            # shellcheck disable=SC2086
            pmake "$port" $targs patch || { echo "== make patch of $port failed"; exit 1; }
            # as build_one of az-build.sh: what the configure stage would fix before configure
            for fx in run-autotools-fixup patch-libtool; do
                # shellcheck disable=SC2086
                pmake "$port" $targs "$fx" 2> /dev/null || true
            done
            echo "$wd $sd" > "$work/src/$n"
        ) > "$logs/patch-$n.log" 2>&1; then
            ok_libs="$ok_libs $n"
        else
            fail "$n" "make patch of $port: $(first_errors "$logs/patch-$n.log") (logs/patch-$n.log)"
        fi
    done
else
    for n in $libs; do
        d="$(printf '%s\n' $srcs | sed -n "s/^$n=//p" | head -n 1)"
        if [ -z "$d" ] || [ ! -d "$d" ]; then fail "$n" "--local: no source tree (--src $n=<dir>)"; continue; fi
        d="$(cd "$d" && pwd)"
        echo "$d $d" > "$work/src/$n"
        ok_libs="$ok_libs $n"
    done
fi

# --- the builds -------------------------------------------------------------------------
# vdir <cc> <name>: the lib/ of that build
vdir() { echo "$stage/$1/$2$S/lib"; }
# so_files <dir>: the libraries of a build (files, not links)
so_files() { find "$1" -maxdepth 1 -type f -name '*.so*' 2>/dev/null | sort; }
dyn() { readelf -d "$1" 2>/dev/null; }
soname_of() { dyn "$1" | sed -n 's/.*[Ll]ibrary soname: \[\(.*\)\].*/\1/p'; }
needed_of() { dyn "$1" | sed -n 's/.*[Ss]hared library: \[\(.*\)\].*/\1/p' | sort | tr '\n' ' ' | sed 's/ *$//'; }
rpath_of() { dyn "$1" | sed -n 's/.*\(R[A-Z]*PATH\).*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1 \2/p' | tr '\n' ' ' | sed 's/ *$//'; }
comment_of() { readelf -p .comment "$1" 2>/dev/null | sed -n 's/^ *\[ *[0-9a-fA-F]*\] *//p' | sort -u | head -n 3 | tr '\n' ';' | sed 's/;$//; s/;/; /g'; }
size_kb() { echo $(( $(wc -c < "$1") / 1024 )); }

# the az of the system immutable while the builds run (FreeBSD): an install outside
# DESTDIR fails instead of changing it. Where the file system has no file flags (the
# disk of the VM of vmactions: "Operation not supported"), the builds run without the
# lock and pkg check -s az after them is what proves az unchanged.
locked=0
unlock() { if [ "$locked" = 1 ]; then chflags -R nouchg "$S"; locked=0; fi; }
trap 'unlock' EXIT
trap 'unlock; exit 1' INT TERM HUP
if [ "$local" = 0 ]; then
    if chflags -R uchg "$S" 2> "$logs/chflags.log"; then
        locked=1
    else
        chflags -R nouchg "$S" 2>/dev/null || true
        echo "lib-bench: chflags -R uchg $S failed ($(sort -u "$logs/chflags.log" | sed 's/^chflags: [^:]*: //' | sort -u | head -n 1)): the builds run without the lock, pkg check -s az after them" >&2
    fi
fi
built=""
for c in "$c1" "$c2"; do
    for n in $ok_libs; do
        read -r wd sd < "$work/src/$n"
        cp_="$(copy_of "$wd" "$c" "$n")"
        dest="$stage/$c/$n"
        log="$logs/build-$c-$n.log"
        rm -rf "$cp_" "$dest"
        if ! mkdir -p "$(dirname "$cp_")" || ! cp -Rp "$wd" "$cp_"; then fail "$c $n" "cannot copy $wd to $cp_"; rm -rf "$cp_"; continue; fi
        say "$n: build with $c"
        t0=$(date +%s)
        (
            if [ "$c" = "$c1" ]; then CC="$cc1"; CXX="$cxx1"; CFLAGS="$cflags1"; CXXFLAGS="$cflags1"; ldx=""
            else CC="$cc2"; CXX="$cxx2"; CFLAGS="$cflags2"; CXXFLAGS="$cflags -static-libgcc"; ldx="-static-libgcc"; fi
            ncpu="$ncpu_build"
            export CC CXX CFLAGS CXXFLAGS
            unset MAKEFLAGS MFLAGS MAKELEVEL __MKLVL__
            so_env
            [ -z "$pcx" ] || PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR:$pcx"
            LDFLAGS="$LDFLAGS${ldx:+ $ldx}"
            DESTDIR="$dest"
            export PKG_CONFIG_LIBDIR LDFLAGS DESTDIR
            echo "== $n with $c: CC=$CC CFLAGS=$CFLAGS CPPFLAGS=$CPPFLAGS LDFLAGS=$LDFLAGS DESTDIR=$DESTDIR"
            echo "== s_$n of tools/az-build.sh:"
            fn "s_$n"
            "s_$n" "$cp_${sd#"$wd"}"
        ) > "$log" 2>&1
        brc=$?
        dt=$(( $(date +%s) - t0 ))
        vd="$(vdir "$c" "$n")"
        if [ $brc -ne 0 ]; then fail "$c $n" "build: $(first_errors "$log") (logs/build-$c-$n.log)"; continue; fi
        if [ -z "$(so_files "$vd")" ]; then fail "$c $n" "no library in $vd (logs/build-$c-$n.log)"; continue; fi
        say "$n: built with $c in ${dt}s"
        echo "$n $c ${dt}s" >> "$work/built"
        built="$built $c:$n"
    done
done
unlock
if [ "$local" = 0 ]; then
    # the az of the system is still the release
    pkg check -s az > "$logs/pkg-check-az.log" 2>&1 || { fail az "pkg check -s az: $(head -n 3 "$logs/pkg-check-az.log" | tr '\n' ' ')"; exit 1; }
fi

# the checks of a build: its libraries have the SONAMEs of az; one of GCC needs
# nothing of the gcc package; what each needs, its run path and compiler
good=""
for v in $built; do
    c="${v%%:*}"; n="${v#*:}"
    vd="$(vdir "$c" "$n")"
    bad=""
    for f in $(so_files "$vd"); do
        sn="$(soname_of "$f")"
        nd="$(needed_of "$f")"
        rp="$(rpath_of "$f")"
        if [ -z "$sn" ]; then bad="$bad ${f##*/}: no SONAME;"; continue; fi
        az_f=""
        if [ "$local" = 0 ]; then
            if [ -e "$S/lib/$sn" ]; then az_f="$(realpath "$S/lib/$sn")"
            else bad="$bad $sn: az has no such library (the variant would not be loaded);"; fi
        fi
        if [ "$c" = "$c2" ]; then
            # the runtime libraries of GCC, by name or in its directory (/usr/local/lib/gcc16)
            gb="$( (echo "$nd" | tr ' ' '\n' | grep -E '^lib(gcc_s|stdc\+\+|gomp|atomic|quadmath|ssp)\.'
                echo "$rp" | tr ' :' '\n\n' | grep -E '/lib/gcc') | tr '\n' ' ')"
            [ -z "$gb" ] || bad="$bad $sn: needs the gcc package ($gb);"
            if ldd "$f" > "$work/ldd.txt" 2>&1; then
                gl="$(awk '$2 == "=>" && ($3 ~ /\/lib\/gcc/ || $1 ~ /^lib(gcc_s|stdc\+\+|gomp|atomic|quadmath|ssp)\./) { print $1 " => " $3 }' "$work/ldd.txt" | tr '\n' ' ')"
                [ -z "$gl" ] || bad="$bad $sn: ldd: $gl;"
            fi
        fi
        line="$v: ${f##*/}: SONAME $sn, $(size_kb "$f") KB, NEEDED $nd${rp:+, $rp}; $(comment_of "$f")"
        if [ -n "$az_f" ]; then
            an="$(needed_of "$az_f")"
            line="$line; az: ${az_f##*/} $(size_kb "$az_f") KB"
            [ "$an" = "$nd" ] || line="$line, NEEDED $an (other than this build)"
        fi
        echo "$line" >> "$res/builds.txt"
    done
    if [ -n "$bad" ]; then fail "$c $n" "$bad"; continue; fi
    good="$good $v"
done
[ -s "$res/builds.txt" ] && sed 's/^/  /' "$res/builds.txt"

# --- the programs, the inputs ---------------------------------------------------------
bin="$work/bin"
prog_of() {  # prog_of <name> <program>: a program of the clang build of a library
    p="$stage/$c1/$1$S/bin/$2"
    [ -x "$p" ] && echo "$p"
}
xmllint="$(prog_of libxml2 xmllint)"
cjpeg="$(prog_of mozjpeg cjpeg)"
djpeg="$(prog_of mozjpeg djpeg)"
speedtest1=""
if [ -f "$work/src/sqlite3" ] && [ -d "$stage/$c1/sqlite3$S/lib" ]; then
    read -r wd sd < "$work/src/sqlite3"
    # shellcheck disable=SC2086
    if "$cc1" $cflags1 -I"$stage/$c1/sqlite3$S/include" -o "$bin/speedtest1" "$sd/test/speedtest1.c" \
            -L"$stage/$c1/sqlite3$S/lib" -lsqlite3 -Wl,-rpath,"$S/lib" -lm -lpthread > "$logs/speedtest1.log" 2>&1; then
        speedtest1="$bin/speedtest1"
    else
        fail speedtest1 "build: $(first_errors "$logs/speedtest1.log")"
    fi
fi
drv() {  # drv <name> <define> <lib>: a driver of tools/lib-bench.c, against the library of az
    # shellcheck disable=SC2086
    if "$cc1" $cflags1 "-D$2" -I"$S/include" -o "$bin/lb-$1" "$tools/lib-bench.c" -L"$S/lib" "-l$3" -Wl,-rpath,"$S/lib" -lm \
            > "$logs/lb-$1.log" 2>&1; then echo "$bin/lb-$1"
    else fail "lb-$1" "build: $(first_errors "$logs/lb-$1.log")"; fi
}
lb_expat=""; lb_lcms2=""
case " $libs " in *" expat "*) lb_expat="$(drv expat LB_EXPAT expat)" ;; esac
case " $libs " in *" lcms2 "*) lb_lcms2="$(drv lcms2 LB_LCMS2 lcms2)" ;; esac
data="$work/data"
say "the inputs (lib-bench.php --gen${cjpeg:+, the JPEG files with cjpeg})"
# with the libraries of az; --local: cjpeg wants the mozjpeg it was built with, not the
# libjpeg of the system
if [ "$local" = 1 ] && [ -n "$cjpeg" ]; then set -- env LD_LIBRARY_PATH="$(vdir "$c1" mozjpeg)"; else set -- env -u LD_LIBRARY_PATH; fi
if ! "$@" "$php" $php_args "$tools/lib-bench.php" --gen "$data" "$cjpeg" > "$logs/gen.log" 2>&1; then
    cat "$logs/gen.log"; echo "lib-bench: no inputs" >&2; exit 1
fi
sed 's/^/  /' "$logs/gen.log"
cp "$logs/gen.log" "$res/inputs.txt"

# --- the benchmarks -------------------------------------------------------------------
# <name> <kind> <libraries> [<what>]: php (tools/lib-bench.php), prog (a program, timed
# by lib-bench.php --time), drv (a driver of tools/lib-bench.c)
cat > "$work/benchmarks" <<EOF
php-dom php libxml2
php-simplexml php libxml2
php-xmlreader php libxml2
php-xml php libxml2
php-xsl php libxml2,libxslt
php-mb-replace php oniguruma
php-mb-search php oniguruma
php-sqlite3 php sqlite3
php-pdo-sqlite php sqlite3
php-gd-jpeg-read php gd,mozjpeg
php-gd-resize php gd
php-gd-jpeg php gd,mozjpeg
php-gd-png php gd,png
php-gd-png-read php gd,png
php-gd-ttf php gd,freetype2
php-zip php libzip
xmllint prog libxml2 xmllint --noout --timing --repeat (100 times) of catalog.xml
speedtest1 prog sqlite3 speedtest1 --memdb --size 25 (the test set main)
cjpeg prog mozjpeg cjpeg of photo.ppm (3000x2000; the mozjpeg defaults: progressive, trellis)
djpeg prog mozjpeg djpeg of photo-moz.jpg (3000x2000, progressive)
expat drv expat XML_Parse of catalog.xml (lb-expat)
lcms2 drv lcms2 cmsCreateTransform, cmsDoTransform: sRGB to a wide RGB in 8 and 16 bits, to Lab in float (lb-lcms2)
EOF
lb_php --list > "$work/php-list" 2>&1 || { cat "$work/php-list"; exit 1; }
# cmd_of <benchmark> <n>: the command of one run
cmd_of() {
    case "$1" in
        php-*) echo "$php $php_args $tools/lib-bench.php $1 $2 $data" ;;
        xmllint) echo "$php $php_args $tools/lib-bench.php --time $2 - $xmllint --noout --timing --repeat $data/catalog.xml" ;;
        speedtest1) echo "$php $php_args $tools/lib-bench.php --time $2 none $speedtest1 --memdb --size 25 --testset main" ;;
        cjpeg) echo "$php $php_args $tools/lib-bench.php --time $2 $work/tmp/cjpeg.jpg $cjpeg -outfile $work/tmp/cjpeg.jpg $data/photo.ppm" ;;
        djpeg) echo "$php $php_args $tools/lib-bench.php --time $2 $work/tmp/djpeg.ppm $djpeg -outfile $work/tmp/djpeg.ppm $data/photo-moz.jpg" ;;
        expat) echo "$lb_expat $2 $data/catalog.xml" ;;
        lcms2) echo "$lb_lcms2 $2" ;;
    esac
}
# what a program benchmark needs
need_of() {
    case "$1" in
        xmllint) echo "$xmllint" ;; speedtest1) echo "$speedtest1" ;; cjpeg) echo "$cjpeg" ;; djpeg) echo "$djpeg" ;;
        expat) echo "$lb_expat" ;; lcms2) echo "$lb_lcms2" ;; *) echo ok ;;
    esac
}
# the module whose loading the proof of a library looks at
module_of() {
    case "$1" in
        libxml2) echo dom ;; libxslt) echo xsl ;; oniguruma) echo mbstring ;; sqlite3) echo sqlite3 ;;
        gd|freetype2|png|mozjpeg) echo gd ;; libzip) echo zip ;; *) echo "" ;;
    esac
}

# one_run <benchmark> <variant> <n> <file>: the output of one run (time, check, lib)
# into <file>; the variant: az, or <cc>:<name> with that lib/ in LD_LIBRARY_PATH
one_run() {
    # shellcheck disable=SC2046
    if [ "$2" = "$ctl" ]; then
        env -u LD_LIBRARY_PATH $pin timeout 900 $(cmd_of "$1" "$3") > "$4" 2>&1 < /dev/null
    else
        env LD_LIBRARY_PATH="$(vdir "${2%%:*}" "${2#*:}")" $pin timeout 900 $(cmd_of "$1" "$3") > "$4" 2>&1 < /dev/null
    fi
}

# --- the proof: which file each variant loads -------------------------------------------
real() { realpath "$1" 2>/dev/null || echo "$1"; }
proved=""
azlib="$(real "$S/lib")"
for v in $good; do
    c="${v%%:*}"; n="${v#*:}"
    vd="$(vdir "$c" "$n")"; rvd="$(real "$vd")"
    names=""; for f in $(so_files "$vd"); do sn="$(soname_of "$f")"; names="$names ${sn%%.so*}.so"; done
    m="$(module_of "$n")"
    if [ -n "$m" ]; then lt="$extdir/$m.so"
    elif [ "$n" = expat ]; then lt="$lb_expat"
    else lt="$lb_lcms2"; fi
    : > "$work/ldd.txt"
    [ -n "$lt" ] && [ -e "$lt" ] && env LD_LIBRARY_PATH="$vd" ldd "$lt" > "$work/ldd.txt" 2>&1
    {
        echo "== $v: LD_LIBRARY_PATH=$vd"
        if [ -s "$work/ldd.txt" ]; then
            echo "ldd $lt:"
            grep -F "$(printf '%s\n' $names | sed 's/\.so$//')" "$work/ldd.txt" | sed 's/^[[:space:]]*/  /'
        fi
    } >> "$res/proof.txt"
    # what is loaded in fact: the files a PHP process maps, or the dladdr of the driver
    if [ -n "$m" ]; then
        # shellcheck disable=SC2086
        env LD_LIBRARY_PATH="$vd" "$php" $php_args "$tools/lib-bench.php" --maps $names > "$work/maps.txt" 2>&1
        loaded="$(sed -n 's/^map //p' "$work/maps.txt")"
    else
        # shellcheck disable=SC2046
        env LD_LIBRARY_PATH="$vd" $(cmd_of "$n" 1) > "$work/maps.txt" 2>&1 < /dev/null
        loaded="$(sed -n 's/^lib //p' "$work/maps.txt")"
    fi
    if [ -z "$loaded" ] && [ -n "$m" ]; then
        # procstat showed no path of them (a file not in the name cache): what rtld
        # resolves for the module, by ldd
        loaded="$(for nm in $names; do awk -v p="$nm" '$2 == "=>" && index($1, p) == 1 { print $3 }' "$work/ldd.txt"; done)"
        [ -z "$loaded" ] || echo "  (no path in procstat -v: the files of ldd)" >> "$res/proof.txt"
    fi
    pok=1
    if [ -z "$loaded" ]; then pok=0; why="no file of $names among those loaded: $(head -n 2 "$work/maps.txt" | tr '\n' ' ')"; fi
    for l in $loaded; do
        rl="$(real "$l")"
        case "$rl" in
            "$rvd"/*) echo "  loaded: $rl ($(comment_of "$rl"))" >> "$res/proof.txt" ;;
            *) pok=0; why="$l is loaded, not the library of $vd"; echo "  loaded: $rl: NOT the variant" >> "$res/proof.txt" ;;
        esac
    done
    if [ "$pok" = 1 ]; then proved="$proved $v"; echo "$v ok" >> "$res/variants.txt"
    else fail "$v" "proof: $why"; echo "$v failed" >> "$res/variants.txt"; fi
done
# the control: the libraries of az (or of the system) are those loaded without LD_LIBRARY_PATH
names=""
for v in $proved; do
    for f in $(so_files "$(vdir "${v%%:*}" "${v#*:}")"); do sn="$(soname_of "$f")"; names="$names ${sn%%.so*}.so"; done
done
names="$(printf '%s\n' $names | sort -u | tr '\n' ' ')"
# shellcheck disable=SC2086
loaded="$(env -u LD_LIBRARY_PATH "$php" $php_args "$tools/lib-bench.php" --maps $names 2>&1 | sed -n 's/^map //p')"
for b in expat lcms2; do
    [ -n "$(need_of "$b")" ] || continue
    # shellcheck disable=SC2046
    loaded="$loaded $(env -u LD_LIBRARY_PATH $(cmd_of "$b" 1) 2>&1 < /dev/null | sed -n 's/^lib //p')"
done
echo "== $ctl (no LD_LIBRARY_PATH):" >> "$res/proof.txt"
for rl in $(for l in $loaded; do real "$l"; done | sort -u); do
    case "$rl" in
        "$(real "$stage")"/*) fail "$ctl" "without LD_LIBRARY_PATH $rl is loaded"; echo "  loaded: $rl: NOT the control" >> "$res/proof.txt" ;;
        *) echo "  loaded: $rl ($(comment_of "$rl"))" >> "$res/proof.txt"
           if [ "$local" = 0 ]; then case "$rl" in "$azlib"/*) ;; *) fail "$ctl" "$rl is not of $S/lib" ;; esac; fi ;;
    esac
done
cat "$res/proof.txt"

# --- the plan: benchmarks, their variants, the work of a run ---------------------------
: > "$work/plan"
while read -r b kind bl what; do
    sel=""
    for n in $(echo "$bl" | tr ',' ' '); do
        case " $libs " in *" $n "*) sel="$sel $n" ;; esac
    done
    [ -n "$sel" ] || continue
    vs="$ctl"; have=0
    for n in $sel; do
        for c in "$c1" "$c2"; do
            case " $proved " in *" $c:$n "*) vs="$vs $c:$n"; have=1 ;; esac
        done
    done
    if [ "$have" = 0 ]; then fail "$b" "no variant of$sel was built and proved"; continue; fi
    nd="$(need_of "$b")"
    if [ -z "$nd" ]; then fail "$b" "its program was not built"; continue; fi
    [ "$kind" = php ] && what="$(awk -F '\t' -v b="$b" '$1 == b { print $2 }' "$work/php-list")"
    # the work of a run: the control once with n=1, then n for about LB_TARGET seconds;
    # a control that does not run is left out of the benchmark, and the first variant
    # that runs sets the work
    t1=""
    for v in $vs; do
        if one_run "$b" "$v" 1 "$work/out.txt"; then t1="$(sed -n 's/^time //p' "$work/out.txt")"; fi
        [ -z "$t1" ] || break
        fail "$b $v" "the first run: $(grep -v '^ *$' "$work/out.txt" | tail -n 2 | tr '\n' ' ' | cut -c1-300)"
        vs="$(echo " $vs " | sed "s# $v # #; s/^ *//; s/ *$//")"
    done
    if [ -z "$t1" ]; then fail "$b" "no variant ran"; continue; fi
    it="$(awk -v t="$t1" -v g="$target" 'BEGIN { n = (t > 0) ? int(g / t + 0.5) : 1; print (n < 1) ? 1 : n }')"
    printf '%s %s %s %s %s\n' "$b" "$kind" "$(echo $sel | tr ' ' ',')" "$it" "$vs" >> "$work/plan"
    printf '%s\t%s\t%s\t%s\n' "$b" "$kind" "$it" "$what" >> "$res/plan.txt"
    say "$b: n=$it ($(printf '%.3f' "$t1")s for n=1), variants: $vs"
done < "$work/benchmarks"
[ -s "$work/plan" ] || { echo "lib-bench: nothing to run" >&2; exit 1; }

# --- the rounds -------------------------------------------------------------------------
r=1
t0=$(date +%s)
while [ $r -le "$runs" ]; do
    say "round $r of $runs ($(( $(date +%s) - t0 ))s so far)"
    while read -r b kind sel it vs; do
        nv="$(echo $vs | wc -w | tr -d ' ')"
        order="$(echo $vs | tr ' ' '\n' | awk -v s=$(( (r - 1) % nv )) '{ a[NR] = $0 } END { for (i = 0; i < NR; i++) printf "%s ", a[(i + s) % NR + 1] }')"
        for v in $order; do
            if one_run "$b" "$v" "$it" "$work/out.txt"; then
                t="$(sed -n 's/^time //p' "$work/out.txt")"
                k="$(sed -n 's/^check //p' "$work/out.txt" | tr -d ' ')"
                l="$(sed -n 's/^lib //p' "$work/out.txt")"
                if [ -n "$l" ] && [ "$v" != "$ctl" ]; then
                    # the drivers name the library they ran in, every run
                    case "$(real "$l")" in "$(real "$(vdir "${v%%:*}" "${v#*:}")")"/*) ;; *) t="" ; echo "not the library of the variant: $l" >> "$work/out.txt" ;; esac
                fi
            else
                t=""
            fi
            if [ -n "$t" ]; then
                echo "$b $v $r $t ${k:--}" >> "$res/runs.txt"
            else
                echo "$b $v $r fail -" >> "$res/runs.txt"
                fail "$b $v (round $r)" "$(grep -v '^ *$' "$work/out.txt" | tail -n 2 | tr '\n' ' ' | cut -c1-300)"
            fi
        done
    done < "$work/plan"
    r=$((r + 1))
done
say "the runs took $(( $(date +%s) - t0 ))s"

# --- the report ---------------------------------------------------------------------------
# table <txt|md>: per library and benchmark, then the verdict per library
table() {
    awk -v fmt="$1" -v planf="$work/plan" -v c1="$c1" -v c2="$c2" -v ctl="$ctl" -v R="$runs" -v gain="$gain" \
        -v order="$libs" '
        function isort(a, m,   i, j, t) { for (i = 2; i <= m; i++) { t = a[i]; for (j = i - 1; j >= 1 && a[j] > t; j--) a[j + 1] = a[j]; a[j + 1] = t } }
        # the index k of the interval [x(k), x(n+1-k)] of a median, about 95% (sign test)
        function cik(n,   j, p, c, k) { c = 1; p = 0; k = 1; for (j = 0; j < n; j++) { p += c / (2 ^ n); if (p > 0.025) break; k = j + 1; c = c * (n - j) / (j + 1) } return k }
        # stats of A[1..m]: M the median, LO and HI its interval
        function stats(m,   k) { isort(A, m); M = (m % 2) ? A[(m + 1) / 2] : (A[m / 2] + A[m / 2 + 1]) / 2; k = cik(m); LO = A[k]; HI = A[m + 1 - k] }
        function cell(k,   i, m) { m = cnt[k]; if (!m) return ""; delete A; for (i = 1; i <= m; i++) A[i] = val[k, i]; stats(m); SP = (M > 0) ? (A[m] - A[1]) / M * 100 : 0; return M }
        function pct(x) { return sprintf("%+.1f%%", (x - 1) * 100) }
        # a median, or why there is none: every run failed, or the variant did not run
        function fmtm(m, k) { return (m != "") ? sprintf("%.3f", m) : (k in nfail) ? "failed" : "-" }
        function verdict(m, lo, hi) {
            if (m <= 1 - gain / 100 && hi < 1) return ">= " gain "% faster"
            if (hi < 1) return "faster, < " gain "%"
            if (lo > 1) return "slower"
            return "no difference"
        }
        # ratios of the runs of the same round of variants a and b of a benchmark into A
        function ratios(b, va, vb,   r, m) { delete A; m = 0; for (r = 1; r <= R; r++) if (((b, va, r) in byr) && ((b, vb, r) in byr) && byr[b, vb, r] > 0) A[++m] = byr[b, va, r] / byr[b, vb, r]; return m }
        BEGIN {
            while ((getline line < planf) > 0) {
                split(line, f, " "); nb++; B[nb] = f[1]; kind[f[1]] = f[2]; nit[f[1]] = f[4]; nl = split(f[3], L, ",")
                for (i = 1; i <= nl; i++) { has[f[1], L[i]] = 1; if (f[2] == "php") nphp[L[i]]++; else ntool[L[i]]++ }
            }
            nlib = split(order, LIB, " ")
            if (fmt == "md") {
                printf "| library | benchmark | n | %s | %s | %s | %s vs %s (95%%) | verdict | %s vs %s | spread | output |\n", ctl, c1, c2, c2, c1, ctl, c1
                printf "|---|---|--:|--:|--:|--:|--:|---|--:|--:|---|\n"
            } else {
                printf "%-10s %-17s %5s %8s %8s %8s  %-28s %-14s %17s %7s  %s\n", "library", "benchmark", "n", ctl, c1, c2, c2 " vs " c1 " (95%)", "verdict", ctl " vs " c1, "spread", "output"
            }
        }
        $4 != "fail" { k = $1 SUBSEP $2; cnt[k]++; val[k, cnt[k]] = $4 + 0; byr[$1, $2, $3] = $4 + 0; if (!((k) in chk)) chk[k] = $5; else if (chk[k] != $5) chkv[k] = 1 }
        $4 == "fail" { nfail[$1 SUBSEP $2]++ }
        END {
            for (li = 1; li <= nlib; li++) {
                lib = LIB[li]; rows = 0
                for (bi = 1; bi <= nb; bi++) {
                    b = B[bi]; if (!((b, lib) in has)) continue
                    vc = c1 ":" lib; vg = c2 ":" lib
                    mz = cell(b SUBSEP ctl); sz = SP; mc = cell(b SUBSEP vc); sc = SP; mg = cell(b SUBSEP vg); sg = SP
                    if (mc == "" && mg == "") continue
                    rows++
                    sp = sz; if (sc > sp) sp = sc; if (sg > sp) sp = sg
                    ch = "-"; vd = "-"
                    if ((m = ratios(b, vg, vc))) { stats(m); ch = sprintf("%s (%s .. %s)", pct(M), pct(LO), pct(HI)); vd = verdict(M, LO, HI); if (m < R) ch = ch " [" m "/" R "]" }
                    cz = "-"; if ((m = ratios(b, ctl, vc))) { stats(m); cz = pct(M) }
                    oz = chk[b SUBSEP ctl]; oc = chk[b SUBSEP vc]; og = chk[b SUBSEP vg]
                    if (oz == "") out = (og == oc) ? "same, no " ctl : c2 " differs from " c1
                    else if (oc == oz && og == oz) out = "same"
                    else if (oc == oz) out = c2 " differs"
                    else if (og == oz) out = c1 " differs"
                    else out = (oc == og) ? c1 " and " c2 " differ from " ctl : "all differ"
                    if ((b SUBSEP ctl) in chkv || (b SUBSEP vc) in chkv || (b SUBSEP vg) in chkv) out = out ", varies"
                    fz = fmtm(mz, b SUBSEP ctl); fc = fmtm(mc, b SUBSEP vc); fg = fmtm(mg, b SUBSEP vg)
                    if (fmt == "md") printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %.1f%% | %s |\n", lib, b, nit[b], fz, fc, fg, ch, vd, cz, sp, out
                    else printf "%-10s %-17s %5s %8s %8s %8s  %-28s %-14s %17s %6.1f%%  %s\n", lib, b, nit[b], fz, fc, fg, ch, vd, cz, sp, out
                }
                # the verdict of the library: its PHP benchmarks (else its programs), the
                # geometric mean of the ratios of each round
                if (!rows) continue
                for (pass = 1; pass <= 2; pass++) {
                    want = (pass == 1) ? "php" : "tool"
                    if (pass == 1 && !nphp[lib]) want = "tool"
                    if (pass == 2 && (!nphp[lib] || !ntool[lib])) break
                    delete G; m = 0; nbx = 0
                    for (r = 1; r <= R; r++) {
                        s = 0; k = 0; okr = 1
                        for (bi = 1; bi <= nb; bi++) {
                            b = B[bi]; if (!((b, lib) in has)) continue
                            if ((want == "php") != (kind[b] == "php")) continue
                            if (((b, c2 ":" lib, r) in byr) && ((b, c1 ":" lib, r) in byr) && byr[b, c1 ":" lib, r] > 0) { s += log(byr[b, c2 ":" lib, r] / byr[b, c1 ":" lib, r]); k++ }
                            else okr = 0
                        }
                        if (okr && k) G[++m] = exp(s / k)
                        nbx = k
                    }
                    if (!m) { VL[lib, pass] = "no complete round"; continue }
                    delete A; for (i = 1; i <= m; i++) A[i] = G[i]; stats(m)
                    VL[lib, pass] = sprintf("%s (%s .. %s) over %d %s, %d rounds", pct(M), pct(LO), pct(HI), nbx, (want == "php") ? (nbx == 1 ? "PHP benchmark" : "PHP benchmarks") : (nbx == 1 ? "program" : "programs"), m)
                    if (pass == 1) { VM[lib] = verdict(M, LO, HI); if (m < 7) VM[lib] = "no verdict: " m " rounds, 7 needed (" VM[lib] ")" }
                }
            }
            printf "\n"
            if (fmt == "md") printf "**Per library** (%s against %s; the geometric mean of a round over its PHP benchmarks, expat and lcms2 their drivers; median and interval of about 95%%):\n\n| library | change | verdict | its programs |\n|---|---|---|---|\n", c2, c1
            else printf "Per library, %s against %s: the geometric mean of a round over its PHP benchmarks (expat, lcms2: their drivers), the median and interval of about 95%% of the rounds:\n", c2, c1
            yes = ""; no = ""
            for (li = 1; li <= nlib; li++) {
                lib = LIB[li]; if (!((lib, 1) in VL)) continue
                v = (lib in VM) ? VM[lib] : "-"; t2 = ((lib, 2) in VL) ? VL[lib, 2] : ""
                if (fmt == "md") printf "| %s | %s | %s | %s |\n", lib, VL[lib, 1], v, t2
                else printf "  %-10s %s: %s%s\n", lib, VL[lib, 1], v, (t2 != "") ? "; its programs: " t2 : ""
                if (v ~ /^>=/) yes = yes " " lib; else no = no " " lib
            }
            printf "\n%s%s: %s\n", (fmt == "md") ? "**" : "", "GCC (" c2 ", >= " gain "% faster)" ((fmt == "md") ? "**" : ""), (yes == "") ? "none" : substr(yes, 2)
            printf "%s%s: %s\n", (fmt == "md") ? "\n**" : "", "clang (" c1 ")" ((fmt == "md") ? "**" : ""), (no == "") ? "none" : substr(no, 2)
        }' "$res/runs.txt"
}
rw=runs; [ "$runs" = 1 ] && rw=run
{
    echo "=== C libraries of az: $c1 (the base cc) against $c2 (tools/lib-bench.sh)"
    cat "$info"
    echo
    echo "The median of $runs $rw in seconds (n: the work of a run, the times of the benchmark's loop); the change of $c2 against $c1:"
    echo "the median of the ratios of the runs of one round, with its interval of about 95% (negative: $c2 faster); $ctl vs $c1:"
    echo "the release against our $c1 build (about 0 when the build is the same); spread: (max - min) / median, the largest of"
    echo "the three variants; output: the checks of the runs against those of $ctl."
    echo
    table txt
    echo
    echo "benchmarks:"
    awk -F '\t' '{ printf "  %-17s %s\n", $1, $4 }' "$res/plan.txt"
    echo
    echo "builds:"
    sed 's/^/  /' "$res/builds.txt" 2>/dev/null
    echo
    echo "proof of the libraries loaded:"
    sed 's/^/  /' "$res/proof.txt"
    if [ -s "$res/failures.txt" ]; then
        echo
        echo "failures:"
        sed 's/^/  /' "$res/failures.txt"
    fi
    echo
    echo "The runs, seconds, in the order of the rounds:"
    awk '{ k = $1 " " $2; if (!(k in s)) o[++n] = k; s[k] = s[k] " " $4 } END { for (i = 1; i <= n; i++) printf "  %-40s%s\n", o[i], s[o[i]] }' "$res/runs.txt"
} > "$res/report.txt"
{
    echo "### C libraries of az: $c1 against $c2"
    echo
    sed 's/^/- /' "$info"
    echo
    echo "The median of $runs $rw in seconds; the change of \`$c2\` against \`$c1\` (median of the ratios of a round, interval of about 95%, negative: faster); \`$ctl\` against \`$c1\`: the release against our build (about 0); spread: (max - min) / median."
    echo
    table md
    echo
    echo '<details><summary>the benchmarks, builds, proof, failures and every run</summary>'
    echo
    echo '```text'
    sed -n '/^benchmarks:$/,$p' "$res/report.txt"
    echo '```'
    echo
    echo '</details>'
} > "$res/report.md"
echo
cat "$res/report.txt"
[ "${LB_KEEP:-0}" = 1 ] || rm -rf "$work"
grep -q -v ' fail ' "$res/runs.txt" || exit 1
exit 0
