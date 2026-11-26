#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench.sh <group> [<rounds>]: the speed of programs of this tree built by
# the base clang (clang19, as our ports built them until 26.11.2026), by clang 23
# (clang23, as Mk/bsd.overlay.mk builds them since: devel/llvm23) and by our GCC 16
# (gcc16, lang/gcc16 of this tree, as USES=azgcc builds the PHP of this tree), from the
# same sources with the same flags (aZ, 17.11.2026: which programs besides PHP are faster
# with GCC; 26.11.2026 20:49: «сделай замер всего для нашего гцц 16.2, для базового цланг
# и нашего цланг 23 … Все дерево портов наше проверь»). PB_VARIANTS: the variants (default
# "clang19 clang23 gcc16"; clang19 first, the base of the comparison). The workflow
# .github/workflows/prog-bench.yml runs it in a FreeBSD VM, a job per group.
#
# tools/prog-bench.sh <group> build <variant>: only the builds of the group by one
# variant, packed into results/prebuilt/<group>-<variant>.tar (zstd) for a later run of
# tools/prog-bench.sh <group> <rounds>, which unpacks them in the place of its builds:
# the programs whose three builds do not fit into the time of one VM (node24: 205
# minutes a build, tools/build-minutes.conf) are built in a VM each and measured in one
# (prog-bench.yml, the input split). The measurements of the three are always in one VM:
# two VMs differ more than the compilers do.
#
# The compilers:
#   clang19  cc and c++ of the base system, its ld (lld 19) and ar
#   clang23  clang23, clang++23 and clang-cpp23 of the package llvm23, and its ld.lld,
#            llvm-ar, llvm-nm and llvm-ranlib by the names ld, ar, nm and ranlib first in the
#            PATH, as the BINARY_ALIAS of Mk/bsd.overlay.mk
#   gcc16    gcc16 and g++16 of our package gcc16 (the repository azsupport), as
#            Mk/Uses/azgcc.mk: -static-libgcc (and -static-libstdc++ for C++), -std=gnu17
#            for C (GCC 15 and later default to C23), -fno-semantic-interposition (for C++ too:
#            with -fPIC GCC would not inline the exported functions); it assembles and links
#            with the binutils of the ports (USE_BINUTILS of bsd.gcc.mk)
# The flags: those of the make.conf of our builds (tools/make.conf.in) for the level
# x86-64-v3, with the protections of Mk/Features it turns on: -O3 -pipe
# -fno-strict-aliasing -march=x86-64-v3, SSP_CFLAGS -fstack-protector-strong
# -fstack-clash-protection, FORTIFY -D_FORTIFY_SOURCE=2, PIE -fPIE -fPIC and -pie, RELRO
# -Wl,-zrelro, BIND_NOW -Wl,-znow (until 26.11.2026 20:49 the flags of the benchmark had
# only -fstack-protector-strong of them). No PGO; no LTO but where the port has it
# (ffmpeg); no debug.
#
# The groups of this file, with the versions of our ports (their files of distinfo;
# SHA-256 checked):
#   compress  zstd 1.5.7 (zstd -b), lz4 1.11.1 (lz4 -b), xxHash 0.8.4 (xxhsum -b),
#             brotli 1.2.1 (brotli -q 5, 9, 11 and -d, timed); on 100 MB of the base
#             system (a tar of /usr/include, /usr/bin and /usr/lib)
#   redis     Redis 8.2.11: redis-server of each, redis-benchmark of clang19 (-P 16,
#             6000000 requests a test: 2000000 took 1 to 2 seconds, spread 13-70%)
#   postgresql PostgreSQL 18.7: pgbench -S and the TPC-B of pgbench (fsync off), and
#             a query of generate_series, against the server of each
#   python    Python 3.12.16 as lang/python312 (libpython3.12.so, LTO, no PIE,
#             _FORTIFY_SOURCE=1): benchmarks of pyperformance (pure Python, --fast)
#   magick    ImageMagick 7.1.2-35, ImageMagick 6.9.13-60, GraphicsMagick 1.3.49
#             (Q16, no OpenMP, no modules): resize, blur, sharpen, rotate and colour
#             operations on a picture of 4000x3000, timed
#   vips      libvips 8.18.7 (one thread): resize, blur, sharpen, rotate, timed
# The other groups are files of tools/prog-bench/ (<group>.sh, or <name>.sh for
# <name><digits>: node.sh for node24 and node18), each with its programs and benchmarks in
# its head; they define g_progs (the programs), g_need (the packages it needs), g_build
# <variant>, g_keep <variant> (the paths of its builds, for the split builds) and
# g_bench, with the functions below.
# Each benchmark <rounds> times (default 5), the variants interleaved (a run of each,
# the first one turning from round to round), the programs on the last CPU (cpuset), a
# load generator on the others; nothing else at the same time. The report:
# results/prog-bench/<group>.md, a table per program (the median of each variant, each
# against clang19 in %: a minus is faster than clang19, for times and for rates alike; the
# spread of each), and the raw values. A build that fails is in the report with the end of
# its log, and the others are measured without it (clang19 failing ends the group).

set -u
group="${1:?usage: $0 <group> [<rounds>] | $0 <group> build <variant>}"
mode=bench
rounds="${2:-5}"
bvariant=""
if [ "${2:-}" = build ]; then
    mode=build
    bvariant="${3:?usage: $0 <group> build <variant>}"
    rounds=0
fi
top="$(pwd)"
W="${PB_WORK:-/pb}"
R="$top/results/prog-bench"
P="$top/results/prebuilt"
if [ "$mode" = build ]; then name="$group-build-$bvariant"; else name="$group"; fi
mkdir -p "$W/dist" "$W/src" "$W/ok" "$W/fails" "$R" "$P"
raw="$W/raw-$name"
rm -rf "$raw"; mkdir -p "$raw"
out="$R/$name.md"
log="$R/$name.log"
: > "$out"
exec 3>> "$log"
say() { echo "== $(date -u +%H:%M:%S) $*"; echo "== $(date -u +%H:%M:%S) $*" >&3; }
die() { say "FAIL: $*"; echo "FAIL: $*" >> "$out"; exit 1; }
# bfail <what> <log>: a build failed: the end of its log into the report, the end
bfail() {
    { echo; echo "FAIL: $1, the last 40 lines of ${2##*/}:"; echo '```'; tail -n 40 "$2"; echo '```'; } >> "$out"
    tail -n 40 "$2" >&3
    die "$1 (${2##*/})"
}
ncpu="$(sysctl -n hw.ncpu)"
last=$((ncpu - 1))
others="0-$((last - 1))"

F="-O3 -pipe -fno-strict-aliasing -march=x86-64-v3 -fstack-protector-strong -fstack-clash-protection -fPIE -fPIC -D_FORTIFY_SOURCE=2"
LF="-pie -Wl,-zrelro -Wl,-znow"
if [ "$mode" = build ]; then
    variants_all="$bvariant"
else
    variants_all="${PB_VARIANTS:-clang19 clang23 gcc16}"
    case "$variants_all" in clang19|clang19\ *) ;; *) die "PB_VARIANTS: clang19 first ($variants_all)" ;; esac
fi
variants="$variants_all"
PATH0="$PATH"
LLVM23=/usr/local/llvm23/bin
gcc_bin="$(command -v gcc16 || :)"
gxx_bin="$(command -v g++16 || :)"
case " $variants " in *" gcc16 "*)
    [ -n "$gcc_bin" ] || die "no gcc16 (pkg install -r azsupport gcc16)"
    "$gcc_bin" --version | head -n 1 | grep -q ' 16\.2\.0' || die "gcc16 is not our 16.2.0: $("$gcc_bin" --version | head -n 1)" ;;
esac
case " $variants " in *" gcc16 "*)
    # -pie for programs only: GCC takes the -pie of LDFLAGS after -shared and links a shared
    # object as a program (lang/python312: "Scrt1.o: undefined reference to `main'"); clang
    # leaves it out with -shared (IsPIE of its FreeBSD.cpp), and the libtool of PHP does not
    # pass it to a shared library: a wrapper of gcc16 and g++16 drops it there
    mkdir -p "$W/bin-gcc16"
    for t in gcc16 g++16; do
        printf '%s\n' '#!/bin/sh' 'case " $* " in *" -shared "*)' '    for a do shift; [ "$a" = -pie ] || set -- "$@" "$a"; done ;;' 'esac' \
            "exec $(command -v "$t") \"\$@\"" > "$W/bin-gcc16/$t"
        chmod 755 "$W/bin-gcc16/$t"
    done
    gcc_bin="$W/bin-gcc16/gcc16" gxx_bin="$W/bin-gcc16/g++16" ;;
esac
case " $variants " in *" clang23 "*)
    [ -x "$LLVM23/clang" ] || die "no clang23 (pkg install llvm23)"
    # the BINARY_ALIAS of Mk/bsd.overlay.mk
    mkdir -p "$W/bin-clang23"
    for t in cc:clang c++:clang++ cpp:clang-cpp clang:clang clang++:clang++ ar:llvm-ar nm:llvm-nm ranlib:llvm-ranlib ld:ld.lld; do
        ln -sf "$LLVM23/${t#*:}" "$W/bin-clang23/${t%%:*}"
    done ;;
esac
# set_cc <variant>: CC, CXX, CPP, the flags and the PATH of the variant in the environment
set_cc() {
    case "$1" in
    clang19)
        unset AR NM RANLIB
        export PATH="$PATH0" CC=cc CXX=c++ CPP=cpp CFLAGS="$F" CXXFLAGS="$F" LDFLAGS="$LF" ;;
    clang23)
        export PATH="$W/bin-clang23:$PATH0" CC=/usr/local/bin/clang23 CXX=/usr/local/bin/clang++23 \
            CPP=/usr/local/bin/clang-cpp23 CFLAGS="$F" CXXFLAGS="$F" LDFLAGS="$LF"
        export AR="$LLVM23/llvm-ar" NM="$LLVM23/llvm-nm" RANLIB="$LLVM23/llvm-ranlib" ;;
    gcc16)
        # the archiver of GCC for the LTO of a build that has it (unbound, ffmpeg)
        export AR=gcc-ar16 NM=gcc-nm16 RANLIB=gcc-ranlib16
        export PATH="$PATH0" CC="$gcc_bin -static-libgcc" CXX="$gxx_bin -static-libgcc -static-libstdc++" CPP=cpp16
        export CFLAGS="$F -std=gnu17 -fno-semantic-interposition"
        export CXXFLAGS="$F -fno-semantic-interposition" LDFLAGS="$LF" ;;
    *) die "unknown variant $1" ;;
    esac
}
# the compilers a file was built with, from its .comment (the C runtime of the base
# system, crt1.o and the like, adds the base clang to every program), and lld (it writes
# "Linker: LLD <version>" there; GNU ld nothing)
cc_of() { readelf -p .comment "$1" 2> /dev/null | grep -o -E '((FreeBSD )?clang version|GCC: \([^)]*\)|Linker: LLD) [0-9.]+' | sort -u | tr '\n' ' '; }

# need <package>...: packages of FreeBSD (the repository FreeBSD-ports) the group needs
need() {
    env ASSUME_ALWAYS_YES=yes pkg install -y "$@" > "$W/pkg-$name.log" 2>&1 || {
        tail -n 20 "$W/pkg-$name.log" >&3; die "pkg install $*: $(tail -n 3 "$W/pkg-$name.log" | tr '\n' ' ')"; }
}

# fetch_try <file> <sha256> <url>...: into $W/dist, the first URL that gives it with that
# SHA-256; false when none does
fetch_try() {
    f="$W/dist/$1"; sum="$2"; shift 2
    if [ ! -f "$f" ] || [ "$(sha256 -q "$f")" != "$sum" ]; then
        rm -f "$f"
        for u in "$@"; do
            if curl -fsSL --connect-timeout 20 --retry 2 -o "$f.part" "$u" 2>> "$log"; then
                if [ "$(sha256 -q "$f.part")" = "$sum" ]; then mv -f "$f.part" "$f"; break; fi
                echo "$u: SHA-256 $(sha256 -q "$f.part"), not $sum" >> "$log"
            fi
        done
    fi
    [ -f "$f" ]
}
# fetch <file> <sha256> <url>...: as fetch_try, the end when none gives it
fetch() { fetch_try "$@" || die "cannot download $1 with the SHA-256 $2 ($(shift 2; echo "$*"))"; }
# unpack <file> <dir>: the tarball into <dir> (its top directory stripped)
unpack() { rm -rf "$2"; mkdir -p "$2" && tar -xf "$W/dist/$1" -C "$2" --strip-components 1 || die "cannot unpack $1"; }

# bok <program> <variant> <file>: the build of the program by the variant is there
bok() { : > "$W/ok/$group-$1-$2"; say "$1 $2: built: $(cc_of "$3")"; }
# have <program> <variant>: it was built
have() { [ -f "$W/ok/$group-$1-$2" ]; }
# bno <program> <variant> <log>: its build failed: the end of its log into the report
# (and into the log of the job); the others go on without it, clang19 (the base of the
# comparison) failing ends the group
bno() {
    { echo; echo "FAIL: the build of $1 by $2, the last 40 lines of ${3##*/}:"; echo; echo '```'
        tail -n 40 "$3"; echo '```'; } >> "$W/fails/$group-$2.md"
    tail -n 40 "$3" >&3
    say "FAIL: the build of $1 by $2 (${3##*/})"
    if [ "$2" = clang19 ] && [ "$mode" = bench ]; then report; die "the build of $1 by clang19, the base of the comparison"; fi
}

# record <program> <bench> <unit> <lower|higher> <variant> <value>: a value of a round
record() {
    case "$6" in ''|*[!0-9.]*) say "$1 $2 $5: no number ('$6')"; return 0 ;; esac
    echo "$6" >> "$raw/$1|$2|$3|$4|$5"
}
median() { sort -n "$1" | awk '{ v[NR] = $1 } END { if (NR == 0) exit; if (NR % 2) print v[(NR + 1) / 2]; else print (v[NR / 2] + v[NR / 2 + 1]) / 2 }'; }
# spread <file>: (max - min) / median of the values, in %
spread() { sort -n "$1" | awk '{ v[NR] = $1 } END { if (NR < 2) { print "-"; exit }
    m = (NR % 2) ? v[(NR + 1) / 2] : (v[NR / 2] + v[NR / 2 + 1]) / 2
    if (m == 0) { print "-"; exit }; printf "%.1f%%\n", (v[NR] - v[1]) / m * 100 }'; }
# timed <variant> <program> <bench> <command>...: the seconds of the command (real);
# a command that fails is said, not recorded
timed() {
    _v="$1" _p="$2" _b="$3"; shift 3
    if /usr/bin/time -p -o "$W/time.out" "$@" > /dev/null 2> "$W/cmd.err"; then
        record "$_p" "$_b" s lower "$_v" "$(awk '$1 == "real" { print $2 }' "$W/time.out")"
    else
        say "$_p $_b $_v: failed: $(tail -n 2 "$W/cmd.err" | tr '\n' ' ' | cut -c1-300)"
    fi
}
# timed5 <variant> <program> <bench> <command>...: as timed, five runs of the command
# in one time (time -p has 10 ms: too coarse for the operations of a fraction of a
# second)
timed5() {
    _v="$1" _p="$2" _b="$3"; shift 3
    if /usr/bin/time -p -o "$W/time.out" sh -c 'for i in 1 2 3 4 5; do "$@" > /dev/null || exit 1; done' sh "$@" 2> "$W/cmd.err"; then
        record "$_p" "$_b" s5 lower "$_v" "$(awk '$1 == "real" { print $2 }' "$W/time.out")"
    else
        say "$_p $_b $_v: failed: $(tail -n 2 "$W/cmd.err" | tr '\n' ' ' | cut -c1-300)"
    fi
}
# timedin <variant> <program> <bench> <input> <command>...: as timed, the file <input> on
# the standard input of the command
timedin() {
    _v="$1" _p="$2" _b="$3" _i="$4"; shift 4
    if /usr/bin/time -p -o "$W/time.out" "$@" < "$_i" > /dev/null 2> "$W/cmd.err"; then
        record "$_p" "$_b" s lower "$_v" "$(awk '$1 == "real" { print $2 }' "$W/time.out")"
    else
        say "$_p $_b $_v: failed: $(tail -n 2 "$W/cmd.err" | tr '\n' ' ' | cut -c1-300)"
    fi
}
# wrkrate <variant> <program> <bench> <url> [<wrk option>...]: the requests per second of
# wrk (3 threads, 64 connections, 8 seconds) on the other CPUs, against a server on the last
# one; a run with errors of sockets or non-2xx/3xx answers is said, not recorded
wrkrate() {
    _v="$1" _p="$2" _b="$3" _u="$4"; shift 4
    cpuset -l "$others" wrk -t 3 -c "${PB_WRK_CONN:-64}" -d "${PB_WRK_TIME:-8}s" "$@" "$_u" > "$W/wrk.out" 2>&1
    if grep -q -E 'Non-2xx or 3xx responses|Socket errors' "$W/wrk.out"; then
        say "$_p $_b $_v: wrk: $(grep -E 'Non-2xx|Socket errors|Requests/sec' "$W/wrk.out" | tr '\n' ' ')"
        return 0
    fi
    record "$_p" "$_b" rps higher "$_v" "$(awk '$1 == "Requests/sec:" { print $2 }' "$W/wrk.out")"
}
# order <round>: the variants, the first one turning from round to round
order() { if [ $(( $1 % 2 )) = 1 ]; then echo "$variants"; else echo "$variants" | awk '{ for (i = NF; i > 0; i--) printf "%s ", $i }'; fi; }
# waitport <port>: until something listens on 127.0.0.1:<port> (20 s at most)
waitport() {
    _n=0
    while ! sockstat -4 -l -P tcp -p "$1" 2> /dev/null | grep -q ":$1 "; do
        _n=$((_n + 1)); [ "$_n" -le 200 ] || return 1; sleep 0.1
    done
}

# pbrd: a tmpfs of 4 GB on /mnt/pbrd (the files of a benchmark off the disk)
pbrd() { mkdir -p /mnt/pbrd && { mount | grep -q ' /mnt/pbrd ' || mount -t tmpfs -o size=4g tmpfs /mnt/pbrd; }; }

# the report: the compilers, the builds that failed, a table per program of the medians
report() {
    _ld19="$(ld --version 2> /dev/null | head -n 1)"
    {
        echo "# prog-bench: $group"
        echo
        echo "FreeBSD $(uname -r), $(sysctl -n hw.model), $ncpu CPUs; rounds $rounds, medians;"
        echo "variants: $variants_all; the base of the comparison: clang19."
        echo "flags: $F; LDFLAGS $LF (gcc16: and -std=gnu17 for C, -fno-semantic-interposition, -static-libgcc, -static-libstdc++ for C++; -pie left out of a link with -shared, as clang does); a group or a program with flags of its own (as its port) says so"
        echo
        echo "compiler clang19: $(cc --version | head -n 1) — the cc of the base system; its linker: ${_ld19:-?}"
        case " $variants_all " in *" clang23 "*)
            echo "compiler clang23: $("$LLVM23/clang" --version | head -n 1) — the official package of FreeBSD $(pkg query %n-%v llvm23 2> /dev/null) (our devel/llvm23, the same release 23.1.6, is not built yet), as Mk/bsd.overlay.mk: its ld.lld ($("$LLVM23/ld.lld" --version | head -n 1)), llvm-ar, llvm-nm and llvm-ranlib by the names ld, ar, nm and ranlib" ;;
        esac
        case " $variants_all " in *" gcc16 "*)
            _gld="$("$gcc_bin" -print-prog-name=ld)"
            echo "compiler gcc16: $("$gcc_bin" --version | head -n 1) — ours: the package $(pkg query %n-%v gcc16 2> /dev/null) of the repository azsupport ($(pkg query %R gcc16 2> /dev/null); the release azsupport-fbsd15-amd64-v3 of azsupport/ports), as Mk/Uses/azgcc.mk; its linker: $_gld ($("$_gld" --version 2> /dev/null | head -n 1))" ;;
        esac
        echo
        echo "<variant> against clang19: a minus is faster than clang19 (for times and for rates); spread <variant>: (max - min) / median of its rounds;"
        echo "units: s (seconds, lower is better), s5 (seconds of five runs), MBps (MB/s), MiBps (MiB/s), rps (requests/s),"
        echo "tps (transactions/s), qps (queries/s), ops (operations/s)."
        if [ -n "$(ls "$W/fails" 2> /dev/null | grep "^$group-")" ]; then
            echo
            echo "## The builds that failed, notes"
            cat "$W/fails/$group"-*.md
        fi
        ls "$raw" | cut -d '|' -f 1 | sort -u | while IFS= read -r p; do
            echo
            echo "## $p"
            echo
            rest_v="${variants_all#clang19}"
            h="| benchmark | unit |"; l="|---|---|"
            for v in $variants_all; do h="$h $v |"; l="$l--:|"; done
            for v in $rest_v; do h="$h $v against clang19 |"; l="$l--:|"; done
            for v in $variants_all; do h="$h spread $v |"; l="$l--:|"; done
            echo "$h"; echo "$l"
            ls "$raw" | awk -F '|' -v p="$p" '$1 == p { print $2 "|" $3 "|" $4 }' | sort -u | while IFS= read -r b; do
                n="${b%%|*}"; rest="${b#*|}"; u="${rest%%|*}"; d="${rest#*|}"
                a="$(median "$raw/$p|$n|$u|$d|clang19" 2> /dev/null)"
                row="| $n | $u | ${a:--} |"; pcts=""; sps="$(spread "$raw/$p|$n|$u|$d|clang19" 2> /dev/null) |"
                for v in $rest_v; do
                    g="$(median "$raw/$p|$n|$u|$d|$v" 2> /dev/null)"
                    pct="$(awk -v a="${a:-0}" -v g="${g:-0}" -v d="$d" 'BEGIN {
                        if (a == 0 || g == 0) { print "-"; exit }
                        if (d == "lower") x = (g / a - 1) * 100; else x = (a / g - 1) * 100
                        printf "%+.1f%%\n", x }')"
                    row="$row ${g:--} |"; pcts="$pcts $pct |"
                    sps="$sps $(spread "$raw/$p|$n|$u|$d|$v" 2> /dev/null || echo -) |"
                done
                echo "$row$pcts $sps"
            done
        done
        echo
        echo "## The raw values (a line per round)"
        echo
        echo '```'
        for f in "$raw"/*; do [ -f "$f" ] && echo "${f##*/}: $(tr '\n' ' ' < "$f")"; done
        echo '```'
    } >> "$out"
}

# ---------------------------------------------------------------- compress
g_compress() {
    fetch zstd-1.5.7.tar.zst 5b331d961d6989dc21bb03397fc7a2a4d86bc65a14adc5ffbbce050354e30fd2 \
        https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.zst
    fetch lz4-1.11.1.tar.gz 683fed08a844ad012196381e40badf80c0bbe4962959761416d41c9e67d77ec7 \
        https://github.com/lz4/lz4/releases/download/v1.11.1/lz4-1.11.1.tar.gz
    fetch xxHash-0.8.4.tar.gz 5738270935e7c3d38a79b3adf7c9692566ce7895a25f67de43ad52ab504acd32 \
        https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.4.tar.gz
    fetch brotli-1.2.1.tar.gz 98d35d11a78dc453aebb7d10c3748f3f73ff78c8267c0dc697b8631f67bf7e8f \
        https://github.com/google/brotli/archive/refs/tags/v1.2.1.tar.gz
    for v in $variants; do
        set_cc "$v"
        # LDFLAGS of the command line in the place of its own: its -pthread with them
        unpack zstd-1.5.7.tar.zst "$W/src/zstd-$v" && gmake -C "$W/src/zstd-$v/programs" -j"$ncpu" zstd \
            CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="-pthread $LDFLAGS" > "$W/b-zstd-$v.log" 2>&1 || bfail "zstd $v" "$W/b-zstd-$v.log"
        unpack lz4-1.11.1.tar.gz "$W/src/lz4-$v" && gmake -C "$W/src/lz4-$v/programs" -j"$ncpu" lz4 \
            CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" > "$W/b-lz4-$v.log" 2>&1 || bfail "lz4 $v" "$W/b-lz4-$v.log"
        unpack xxHash-0.8.4.tar.gz "$W/src/xxhash-$v" && gmake -C "$W/src/xxhash-$v" -j"$ncpu" xxhsum \
            CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" > "$W/b-xxhash-$v.log" 2>&1 || bfail "xxhash $v" "$W/b-xxhash-$v.log"
        unpack brotli-1.2.1.tar.gz "$W/src/brotli-$v" && cmake -S "$W/src/brotli-$v" -B "$W/src/brotli-$v/_b" \
            -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="$CFLAGS -DNDEBUG" \
            -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
            -DBUILD_SHARED_LIBS=OFF -DBROTLI_DISABLE_TESTS=ON > "$W/b-brotli-$v.log" 2>&1 &&
            ninja -C "$W/src/brotli-$v/_b" brotli >> "$W/b-brotli-$v.log" 2>&1 || bfail "brotli $v" "$W/b-brotli-$v.log"
        say "compress $v: zstd $(cc_of "$W/src/zstd-$v/programs/zstd"); brotli $(cc_of "$W/src/brotli-$v/_b/brotli")"
    done
    export PATH="$PATH0"
    tar -cf - -C / usr/include usr/bin usr/lib 2> /dev/null | head -c 104857600 > "$W/corpus"
    head -c 20971520 "$W/corpus" > "$W/corpus20"
    for v in $variants; do "$W/src/brotli-$v/_b/brotli" -q 9 -c "$W/corpus" > "$W/corpus.br" && break; done
    for r in $(seq 1 "$rounds"); do
        say "compress: round $r of $rounds"
        for v in $(order "$r"); do
            z="$W/src/zstd-$v/programs/zstd"
            for l in 1 3 9 19; do
                # the last line of its progress (\r) is the result: "... (x2.887), 517.3 MB/s, 1902.4 MB/s"
                cpuset -l "$last" "$z" -b"$l" -e"$l" -T1 "$W/corpus" 2>&1 | tr '\r' '\n' | grep -E 'MB/s *, *[0-9.]+ MB/s' | tail -n 1 > "$W/zb"
                record zstd "-$l compress" MBps higher "$v" "$(sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\1/p' "$W/zb")"
                record zstd "-$l decompress" MBps higher "$v" "$(sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\2/p' "$W/zb")"
            done
            z="$W/src/lz4-$v/programs/lz4"
            for l in 1 9; do
                cpuset -l "$last" "$z" -b"$l" -e"$l" "$W/corpus" 2>&1 | tr '\r' '\n' | grep -E 'MB/s *, *[0-9.]+ MB/s' | tail -n 1 > "$W/zb"
                record lz4 "-$l compress" MBps higher "$v" "$(sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\1/p' "$W/zb")"
                record lz4 "-$l decompress" MBps higher "$v" "$(sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\2/p' "$W/zb")"
            done
            cpuset -l "$last" "$W/src/xxhash-$v/xxhsum" -b1,3,5,11 2>&1 | tr '\r' '\n' > "$W/xb"
            for a in XXH32 XXH64 XXH3_64b XXH128; do
                # the result of each: "11#XXH128   :   102400 ->   368844 it/s (36019.9 MiB/s)"
                # (its progress: "1-XXH128 ...")
                record xxhash "$a" MiBps higher "$v" "$(grep -E "#$a +:" "$W/xb" | tail -n 1 | sed -n -E 's/.*\( *([0-9.]+) MiB\/s\).*/\1/p')"
            done
            b="$W/src/brotli-$v/_b/brotli"
            timed "$v" brotli "-q 5 (100 MB)" cpuset -l "$last" "$b" -q 5 -c "$W/corpus"
            timed "$v" brotli "-q 9 (100 MB)" cpuset -l "$last" "$b" -q 9 -c "$W/corpus"
            timed "$v" brotli "-q 11 (20 MB)" cpuset -l "$last" "$b" -q 11 -c "$W/corpus20"
            timed "$v" brotli "-d (100 MB)" cpuset -l "$last" "$b" -d -c "$W/corpus.br"
        done
    done
}

# ---------------------------------------------------------------- redis
g_redis() {
    fetch redis-8.2.11.tar.gz fba14b77c4bdcb2d5418b6741fc0cdaac4b78bc73eab9b2e5f3c255d597f16fa \
        https://download.redis.io/releases/redis-8.2.11.tar.gz
    for v in $variants; do
        set_cc "$v"
        unpack redis-8.2.11.tar.gz "$W/src/redis-$v"
        # no debug (DEBUG of its Makefile is -g -ggdb), the malloc of libc (jemalloc)
        gmake -C "$W/src/redis-$v/src" -j"$ncpu" redis-server redis-benchmark MALLOC=libc \
            CC="$CC" CXX="$CXX" OPTIMIZATION=-O3 DEBUG= CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" \
            > "$W/b-redis-$v.log" 2>&1 || bfail "redis $v" "$W/b-redis-$v.log"
        say "redis $v: $(cc_of "$W/src/redis-$v/src/redis-server")"
    done
    export PATH="$PATH0"
    rb="$W/src/redis-clang19/src/redis-benchmark"
    tests="set,get,incr,lpush,rpush,lpop,rpop,sadd,hset,spop,zadd,lrange_100,mset"
    for r in $(seq 1 "$rounds"); do
        say "redis: round $r of $rounds"
        for v in $(order "$r"); do
            cpuset -l "$last" "$W/src/redis-$v/src/redis-server" --port 6390 --save '' --appendonly no \
                --daemonize no > "$W/redis-$v.log" 2>&1 &
            pid=$!
            sleep 2
            cpuset -l "$others" "$rb" -p 6390 -q -n 6000000 -P 16 -c 50 -t "$tests" --csv 2> /dev/null > "$W/rb.csv"
            kill "$pid"; wait "$pid" 2> /dev/null
            # "test","rps",...: a test has spaces in its name ("LRANGE_100 (first 100 elements)")
            tr -d '"' < "$W/rb.csv" | awk -F ',' 'NR > 1 { print $2 "|" $1 }' | while IFS='|' read -r rps t; do
                record redis "$t" rps higher "$v" "$rps"
            done
        done
    done
}

# ---------------------------------------------------------------- postgresql
g_postgresql() {
    fetch postgresql-18.7.tar.bz2 441dfae4280cae3e0425e5f876f80559fb0731c140f1aae22b3e5a54d0411bfd \
        https://ftp.postgresql.org/pub/source/v18.7/postgresql-18.7.tar.bz2
    pw usershow pb > /dev/null 2>&1 || pw useradd pb -m -s /bin/sh
    for v in $variants; do
        set_cc "$v"
        unpack postgresql-18.7.tar.bz2 "$W/src/pg-$v"
        (cd "$W/src/pg-$v" && ./configure --prefix="$W/pg-$v" --without-icu --without-readline \
            --without-zlib --without-zstd --without-lz4 --without-openssl CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" &&
            gmake -j"$ncpu" && gmake install) > "$W/b-pg-$v.log" 2>&1 || bfail "postgresql $v" "$W/b-pg-$v.log"
        say "postgresql $v: $(cc_of "$W/pg-$v/bin/postgres")"
        rm -rf "$W/pgdata-$v"; mkdir -p "$W/pgdata-$v" "$W/pgrun"; chown pb "$W/pgdata-$v" "$W/pgrun"; chmod 755 "$W"
        su -m pb -c "$W/pg-$v/bin/initdb -D $W/pgdata-$v -E UTF8 --no-locale" > "$W/initdb-$v.log" 2>&1 ||
            bfail "initdb $v" "$W/initdb-$v.log"
    done
    export PATH="$PATH0"
    pgb="$W/pg-clang19/bin/pgbench"
    psql="$W/pg-clang19/bin/psql"
    q="SELECT count(*), sum(i % 7), avg(i::numeric) FROM generate_series(1, 20000000) AS i"
    for r in $(seq 1 "$rounds"); do
        say "postgresql: round $r of $rounds"
        for v in $(order "$r"); do
            su -m pb -c "cpuset -l $last $W/pg-$v/bin/pg_ctl -D $W/pgdata-$v -l $W/pgrun/pg-$v.log -w -o '-p 5440 -c fsync=off \
                -c synchronous_commit=off -c full_page_writes=off -c shared_buffers=1GB -c max_connections=60' start" > /dev/null ||
                die "start postgresql $v"
            if [ "$r" = 1 ]; then su -m pb -c "$pgb -p 5440 -i -s 20 -q postgres" > /dev/null 2>&1; fi
            t="$(su -m pb -c "cpuset -l $others $pgb -p 5440 -S -M prepared -c 4 -j 3 -T 30 postgres" 2>/dev/null | sed -n -E 's/^tps = ([0-9.]+).*/\1/p')"
            record postgresql "pgbench -S (4 clients)" tps higher "$v" "$t"
            t="$(su -m pb -c "cpuset -l $others $pgb -p 5440 -M prepared -c 4 -j 3 -T 30 postgres" 2>/dev/null | sed -n -E 's/^tps = ([0-9.]+).*/\1/p')"
            record postgresql "pgbench TPC-B (4 clients, fsync off)" tps higher "$v" "$t"
            timed "$v" postgresql "generate_series 20M: count, sum, avg" su -m pb -c "$psql -p 5440 -X -q -d postgres -c '$q'"
            su -m pb -c "$W/pg-$v/bin/pg_ctl -D $W/pgdata-$v -w stop" > /dev/null
        done
    done
}

# ---------------------------------------------------------------- python
g_python() {
    fetch Python-3.12.16.tar.xz b5796915dc45ff745cfb4e990a7e7c93d6f546328a102ce31448d69ebc37575c \
        https://www.python.org/ftp/python/3.12.16/Python-3.12.16.tar.xz
    for v in $variants; do
        set_cc "$v"
        # as lang/python312: libpython3.12.so (--enable-shared) and LTO (the options of the
        # official package), no PIE (PIE_UNSAFE: GCC links the modules as programs with
        # -shared -pie), _FORTIFY_SOURCE=1 (level 2: __chk_fail of the getsockname of
        # <ssp/socket.h> with GCC, the port)
        _cf="$(echo "$CFLAGS" | sed -e 's/ -fPIE//' -e 's/ -fPIC//' -e 's/-D_FORTIFY_SOURCE=2/-D_FORTIFY_SOURCE=1/')"
        _lf="$(echo "$LDFLAGS" | sed -e 's/-pie //')"
        unpack Python-3.12.16.tar.xz "$W/src/py-$v"
        (cd "$W/src/py-$v" && ./configure --prefix="$W/py-$v" --enable-shared --with-lto --with-ensurepip=install \
            CC="$CC" CFLAGS="$_cf" CPPFLAGS=-I/usr/local/include \
            LDFLAGS="-L/usr/local/lib -Wl,-rpath,$W/py-$v/lib $_lf" && gmake -j"$ncpu" && gmake install) \
            > "$W/b-py-$v.log" 2>&1 || bfail "python $v" "$W/b-py-$v.log"
        say "python $v: $(cc_of "$W/py-$v/lib/libpython3.12.so.1.0")"
    done
    export PATH="$PATH0"
    python3 -m venv "$W/pt" && "$W/pt/bin/pip" -q install pyperformance > "$W/pip.log" 2>&1 || bfail "pip install pyperformance" "$W/pip.log"
    benches="chaos deltablue fannkuch float go hexiom json_dumps json_loads nbody nqueens pickle_pure_python \
        raytrace regex_compile regex_v8 richards scimark spectral_norm unpack_sequence unpickle_pure_python \
        deepcopy generators coroutines pyflate logging"
    for r in $(seq 1 "$rounds"); do
        say "python: round $r of $rounds"
        for v in $(order "$r"); do
            for b in $benches; do
                rm -f "$W/pp.json"
                cpuset -l "$last" "$W/pt/bin/pyperformance" run --fast --python="$W/py-$v/bin/python3.12" -b "$b" \
                    -o "$W/pp.json" > "$W/pp-$v-$b.log" 2>&1 || {
                    say "python $v: $b failed: $(tail -n 3 "$W/pp-$v-$b.log" | tr '\n' ' ' | cut -c1-300)"; continue; }
                "$W/pt/bin/python" -c '
import json, sys, statistics
d = json.load(open(sys.argv[1]))
for b in d["benchmarks"]:
    vals = [v for run in b["runs"] for v in run.get("values", [])]
    if vals:
        print(b.get("metadata", {}).get("name", d["metadata"].get("name", "?")), statistics.mean(vals))
' "$W/pp.json" | while read -r n t; do record python "$n" s lower "$v" "$t"; done
            done
        done
    done
}

# ---------------------------------------------------------------- magick
g_magick() {
    # download.imagemagick.org did not answer the runners (26.11.2026 20:46 and 21:20), the mirrors have
    # no older releases: then the tarballs of the releases of ImageMagick on GitHub (other bytes than
    # those of distinfo, the same release; their SHA-256 here, said in the report)
    fetch_try ImageMagick-7.1.2-35.tar.xz fce4636c81a3a4670ece47927f7ff924b94f09f8c7a92e6443579899713fd564 \
        https://download.imagemagick.org/archive/releases/ImageMagick-7.1.2-35.tar.xz ||
        { fetch ImageMagick-7.1.2-35.tar.xz 9554556c8cbf7d347cbd6bedae931ccf323a2bd5e0f08d4834856568ee19f080 \
            https://github.com/ImageMagick/ImageMagick/releases/download/7.1.2-35/ImageMagick-7.1.2-35.tar.xz
          echo "ImageMagick 7.1.2-35: the tarball of its release on GitHub (SHA-256 9554556c…), not that of distinfo (fce4636c…): download.imagemagick.org did not answer" >> "$out"; }
    fetch_try ImageMagick-6.9.13-60.tar.xz 8e25148ca3c0bc66bb5aa78c7e7a272b61d0d4a00f337e82dfbfeda28c845239 \
        https://download.imagemagick.org/archive/releases/ImageMagick-6.9.13-60.tar.xz ||
        { fetch ImageMagick-6.9.13-60.tar.xz 2a1367ecd77c73660c1c0e62660ff3c3c89f1ca686595de2d71be4229ad504ba \
            https://github.com/ImageMagick/ImageMagick6/releases/download/6.9.13-60/ImageMagick-6.9.13-60.tar.xz
          echo "ImageMagick 6.9.13-60: the tarball of its release on GitHub (SHA-256 2a1367ec…), not that of distinfo (8e25148c…): download.imagemagick.org did not answer" >> "$out"; }
    fetch GraphicsMagick-1.3.49.tar.xz 7efa070dc31116b4315061b39f84bc7181e8b060bf61214ec9af851131af9c81 \
        https://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.49/GraphicsMagick-1.3.49.tar.xz
    for v in $variants; do
        set_cc "$v"
        for m in im7:ImageMagick-7.1.2-35 im6:ImageMagick-6.9.13-60 gm:GraphicsMagick-1.3.49; do
            k="${m%%:*}"; d="${m#*:}"
            unpack "$d.tar.xz" "$W/src/$k-$v"
            (cd "$W/src/$k-$v" && ./configure --prefix="$W/$k-$v" --disable-shared --enable-static --without-modules \
                --disable-openmp --without-magick-plus-plus --without-perl --without-x --disable-docs \
                CC="$CC" CXX="$CXX" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" && gmake -j"$ncpu" && gmake install) \
                > "$W/b-$k-$v.log" 2>&1 || bfail "$k $v" "$W/b-$k-$v.log"
        done
        say "magick $v: $(cc_of "$W/im7-$v/bin/magick")"
    done
    export PATH="$PATH0"
    "$W/im7-clang19/bin/magick" -seed 1 -size 4000x3000 plasma:fractal "$W/in.miff" || die "the picture"
    ops="resize50:-resize 50%
resize200:-resize 200%
blur:-blur 0x3
sharpen:-unsharp 0x2+1+0
rotate:-rotate 33
gray:-colorspace Gray
modulate:-modulate 110,120,90"
    for r in $(seq 1 "$rounds"); do
        say "magick: round $r of $rounds"
        for v in $(order "$r"); do
            printf '%s\n' "$ops" | while IFS=: read -r n op; do
                # shellcheck disable=SC2086
                timed5 "$v" ImageMagick7 "$n ($op)" cpuset -l "$last" "$W/im7-$v/bin/magick" "$W/in.miff" $op null:
                # shellcheck disable=SC2086
                timed5 "$v" ImageMagick6 "$n ($op)" cpuset -l "$last" "$W/im6-$v/bin/convert" "$W/in.miff" $op null:
                # shellcheck disable=SC2086
                timed5 "$v" GraphicsMagick "$n ($op)" cpuset -l "$last" "$W/gm-$v/bin/gm" convert "$W/in.miff" $op null:
            done
        done
    done
}

# ---------------------------------------------------------------- vips
g_vips() {
    fetch vips-8.18.7.tar.xz 5baaead3b0bb20ffdb9e9ff09aa9fda08620923df77b63b436654cb5e0b3bf94 \
        https://github.com/libvips/libvips/releases/download/v8.18.7/vips-8.18.7.tar.xz
    for v in $variants; do
        set_cc "$v"
        unpack vips-8.18.7.tar.xz "$W/src/vips-$v"
        # the flags of the environment (-Doptimization=plain); every automatic feature off
        # (the loaders of the formats: the benchmarks read and write the format of vips)
        (cd "$W/src/vips-$v" && meson setup _b --prefix="$W/vips-$v" --libdir=lib --buildtype=release \
            -Doptimization=plain --auto-features=disabled -Ddeprecated=false -Dexamples=false \
            -Dcplusplus=false && ninja -C _b && ninja -C _b install) > "$W/b-vips-$v.log" 2>&1 || bfail "vips $v" "$W/b-vips-$v.log"
        say "vips $v: $(cc_of "$W/vips-$v/lib/libvips.so.42")"
    done
    export PATH="$PATH0"
    pbrd
    V="$W/vips-clang19/bin/vips"
    # a picture of 4000x3000, three bands of 8 bits, sRGB
    L="$W/vips-clang19/lib"
    LD_LIBRARY_PATH="$L" "$V" gaussnoise /mnt/pbrd/n.v 4000 3000 --mean 128 --sigma 40 &&
        LD_LIBRARY_PATH="$L" "$V" bandjoin "/mnt/pbrd/n.v /mnt/pbrd/n.v /mnt/pbrd/n.v" /mnt/pbrd/n3.v &&
        LD_LIBRARY_PATH="$L" "$V" cast /mnt/pbrd/n3.v /mnt/pbrd/u.v uchar &&
        LD_LIBRARY_PATH="$L" "$V" copy /mnt/pbrd/u.v /mnt/pbrd/in.v --interpretation srgb || die "the picture of vips"
    export VIPS_CONCURRENCY=1
    for r in $(seq 1 "$rounds"); do
        say "vips: round $r of $rounds"
        for v in $(order "$r"); do
            x="$W/vips-$v/bin/vips"; l="$W/vips-$v/lib"
            timed5 "$v" vips "resize 0.5 (lanczos3)" env LD_LIBRARY_PATH="$l" cpuset -l "$last" "$x" resize /mnt/pbrd/in.v /mnt/pbrd/o.v 0.5
            timed5 "$v" vips "resize 2.0 (lanczos3)" env LD_LIBRARY_PATH="$l" cpuset -l "$last" "$x" resize /mnt/pbrd/in.v /mnt/pbrd/o.v 2.0
            timed5 "$v" vips "gaussblur 3" env LD_LIBRARY_PATH="$l" cpuset -l "$last" "$x" gaussblur /mnt/pbrd/in.v /mnt/pbrd/o.v 3
            timed5 "$v" vips "sharpen" env LD_LIBRARY_PATH="$l" cpuset -l "$last" "$x" sharpen /mnt/pbrd/in.v /mnt/pbrd/o.v
            timed5 "$v" vips "rotate 33" env LD_LIBRARY_PATH="$l" cpuset -l "$last" "$x" rotate /mnt/pbrd/in.v /mnt/pbrd/o.v 33
            timed5 "$v" vips "colourspace lab" env LD_LIBRARY_PATH="$l" cpuset -l "$last" "$x" colourspace /mnt/pbrd/in.v /mnt/pbrd/o.v lab
        done
    done
}

# ---------------------------------------------------------------- the groups of tools/prog-bench/
# run_group: the builds (or those of the split builds unpacked), the benchmarks, the report;
# with build <variant>, the builds of the variant packed for the job of the measurements
run_group() {
    g_need
    if [ "$mode" = build ]; then
        g_build "$bvariant"
        export PATH="$PATH0"
        keep=""
        if [ -n "$(ls "$W/ok" | grep "^$group-.*-$bvariant\$")" ]; then
            for f in $(g_keep "$bvariant"); do keep="$keep ${f#/}"; done
        fi
        # the markers of the builds and the failures go too: the job of the measurements
        # reports them
        # shellcheck disable=SC2086
        tar -c --zstd -f "$P/$group-$bvariant.tar" -C / $keep "${W#/}/ok" "${W#/}/fails" ||
            die "cannot pack the builds of $group by $bvariant"
        say "packed: $(ls -l "$P/$group-$bvariant.tar" | awk '{ print $5 }') bytes ($keep)"
        {
            echo "# prog-bench: the builds of $group by $bvariant"
            echo
            echo "FreeBSD $(uname -r), $(sysctl -n hw.model), $ncpu CPUs; flags: $F; LDFLAGS $LF"
            echo
            for p in $g_progs; do
                if have "$p" "$bvariant"; then echo "- $p: built"; else echo "- $p: FAIL"; fi
            done
            [ ! -f "$W/fails/$group-$bvariant.md" ] || cat "$W/fails/$group-$bvariant.md"
        } >> "$out"
        return 0
    fi
    if [ -n "${PB_SPLIT:-}" ] || ls "$P/$group"-*.tar > /dev/null 2>&1; then
        # the split builds: each variant from its own job
        for v in $variants; do
            if [ -f "$P/$group-$v.tar" ]; then
                tar -x --zstd -f "$P/$group-$v.tar" -C / || die "cannot unpack the builds of $group by $v"
                say "the builds of $v unpacked ($group-$v.tar)"
            else
                { echo; echo "FAIL: no builds of $group by $v: see the report of its job of builds ($group-build-$v)"; } >> "$W/fails/$group-$v.md"
            fi
        done
    else
        for v in $variants; do g_build "$v"; done
    fi
    export PATH="$PATH0"
    for p in $g_progs; do
        have "$p" clang19 || { report; die "no build of $p by clang19, the base of the comparison"; }
    done
    g_bench
    report
}

say "group $group ($mode), $rounds rounds, $ncpu CPUs, variants: $variants; cc: $(cc --version | head -n 1)${gcc_bin:+; gcc16: $("$gcc_bin" --version | head -n 1)}$( [ -x "$LLVM23/clang" ] && printf '; clang23: %s' "$("$LLVM23/clang" --version | head -n 1)")"
case "$group" in
compress|redis|postgresql|python|magick|vips)
    [ "$mode" = bench ] || die "the group $group has no split builds"
    "g_$group"
    report ;;
*)
    gf="$top/tools/prog-bench/$group.sh"
    [ -f "$gf" ] || gf="$top/tools/prog-bench/$(echo "$group" | sed -E 's/[0-9]+$//').sh"
    [ -f "$gf" ] || die "unknown group $group (compress redis postgresql python magick vips, or tools/prog-bench/<group>.sh)"
    # shellcheck disable=SC1090
    . "$gf"
    run_group ;;
esac
say "the report: $out"
