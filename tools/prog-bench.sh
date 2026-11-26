#!/bin/sh
# tools/prog-bench.sh <group> [<rounds>]: the speed of programs of this tree built by
# the base clang (clang19, as our ports built them until 26.11.2026), by clang 23 of the
# packages (clang23, as Mk/bsd.overlay.mk builds them since: devel/llvm23) and by GCC 16
# of the packages (gcc16, as USES=azgcc builds the PHP of this tree), from the same
# sources with the same flags (aZ, 17.11.2026: which programs besides PHP are faster with
# GCC; 26.11.2026: clang 23 in the place of clang 19). PB_VARIANTS: the variants (default
# "clang19 clang23 gcc16"; clang19 first, the base of the comparison). The
# workflow .github/workflows/prog-bench.yml runs it in a FreeBSD VM, a job per group.
#
# The flags: those of the make.conf of our builds (tools/make.conf.in) for the level
# x86-64-v3, -O3 -pipe -fno-strict-aliasing -march=x86-64-v3 -fstack-protector-strong;
# for gcc16 also what Mk/Uses/azgcc.mk adds: -std=gnu17 to C (GCC 15 and later
# default to C23), -fno-semantic-interposition, libgcc (and libstdc++) linked in. No
# PGO, no LTO; no debug.
#
# The groups, with the versions of our ports (their files of distinfo; SHA-256
# checked):
#   compress  zstd 1.5.7 (zstd -b), lz4 1.11.1 (lz4 -b), xxHash 0.8.4 (xxhsum -b),
#             brotli 1.2.1 (brotli -q 5, 9, 11 and -d, timed); on 100 MB of the base
#             system (a tar of /usr/include, /usr/bin and /usr/lib)
#   redis     Redis 8.2.11: redis-server of each, redis-benchmark of clang19 (-P 16)
#   postgresql PostgreSQL 18.7: pgbench -S and the TPC-B of pgbench (fsync off), and
#             a query of generate_series, against the server of each
#   python    Python 3.12.16: benchmarks of pyperformance (pure Python, --fast)
#   magick    ImageMagick 7.1.2-35, ImageMagick 6.9.13-60, GraphicsMagick 1.3.49
#             (Q16, no OpenMP, no modules): resize, blur, sharpen, rotate and colour
#             operations on a picture of 4000x3000, timed
#   vips      libvips 8.18.7 (one thread): resize, blur, sharpen, rotate, timed
# Each benchmark <rounds> times (default 5), the variants interleaved (a run of each,
# the first one turning from round to round), single-threaded ones on the last CPU
# (cpuset); the median of each. The report: results/prog-bench/<group>.md, a table
# per program (the medians of each variant, and each against clang19 in %: a minus is
# faster than clang19, for times and for rates alike), and the raw values.

set -u
group="${1:?usage: $0 <group> [<rounds>]}"
rounds="${2:-5}"
top="$(pwd)"
W="${PB_WORK:-/pb}"
R="$top/results/prog-bench"
mkdir -p "$W/dist" "$W/src" "$W/raw" "$R"
raw="$W/raw"
out="$R/$group.md"
log="$R/$group.log"
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

F="-O3 -pipe -fno-strict-aliasing -march=x86-64-v3 -fstack-protector-strong"
variants="${PB_VARIANTS:-clang19 clang23 gcc16}"
case "$variants" in clang19\ *) ;; *) die "PB_VARIANTS: clang19 first ($variants)" ;; esac
gcc_bin="$(command -v gcc16 || :)"
gxx_bin="$(command -v g++16 || :)"
case " $variants " in *" gcc16 "*) [ -n "$gcc_bin" ] || die "no gcc16 (pkg install gcc16)" ;; esac
case " $variants " in *" clang23 "*) command -v clang23 > /dev/null || die "no clang23 (pkg install llvm23)" ;; esac
# set_cc <variant>: CC, CXX and the flags of the variant in the environment
set_cc() {
    case "$1" in
    clang19)
        export CC=cc CXX=c++ CFLAGS="$F" CXXFLAGS="$F" LDFLAGS="" ;;
    clang23)
        export CC=clang23 CXX=clang++23 CFLAGS="$F" CXXFLAGS="$F" LDFLAGS="" ;;
    gcc16)
        export CC="$gcc_bin -static-libgcc" CXX="$gxx_bin -static-libgcc -static-libstdc++"
        export CFLAGS="$F -std=gnu17 -fno-semantic-interposition"
        export CXXFLAGS="$F -fno-semantic-interposition" LDFLAGS="" ;;
    esac
}
# the compiler a file was built with, from its .comment
cc_of() { readelf -p .comment "$1" 2> /dev/null | grep -o -E '(FreeBSD clang version|GCC: \([^)]*\)) [0-9.]+' | sort -u | tr '\n' ' '; }

# fetch <file> <sha256> <url>...: into $W/dist, the first URL that gives it, checked
fetch() {
    f="$W/dist/$1"; sum="$2"; shift 2
    if [ ! -f "$f" ] || [ "$(sha256 -q "$f")" != "$sum" ]; then
        for u in "$@"; do
            curl -fsSL --retry 3 -o "$f.part" "$u" 2>> "$log" && mv -f "$f.part" "$f" && break
        done
    fi
    [ -f "$f" ] || die "cannot download $1 ($*)"
    [ "$(sha256 -q "$f")" = "$sum" ] || die "$1: SHA-256 $(sha256 -q "$f"), not $sum"
}
# unpack <file> <dir>: the tarball into <dir> (its top directory stripped)
unpack() { rm -rf "$2"; mkdir -p "$2" && tar -xf "$W/dist/$1" -C "$2" --strip-components 1 || die "cannot unpack $1"; }

# record <program> <bench> <unit> <lower|higher> <variant> <value>: a value of a round
record() {
    case "$6" in ''|*[!0-9.]*) say "$1 $2 $5: no number ('$6')"; return 0 ;; esac
    echo "$6" >> "$raw/$1|$2|$3|$4|$5"
}
median() { sort -n "$1" | awk '{ v[NR] = $1 } END { if (NR == 0) exit; if (NR % 2) print v[(NR + 1) / 2]; else print (v[NR / 2] + v[NR / 2 + 1]) / 2 }'; }
# timed <variant> <program> <bench> <command>...: the seconds of the command (real);
# a command that fails is said, not recorded
timed() {
    _v="$1" _p="$2" _b="$3"; shift 3
    if /usr/bin/time -p -o "$W/time.out" "$@" > /dev/null 2> "$W/cmd.err"; then
        record "$_p" "$_b" s lower "$_v" "$(awk '$1 == "real" { print $2 }' "$W/time.out")"
    else
        say "$_p $_b $_v: failed: $(tail -n 2 "$W/cmd.err" | tr '\n' ' ')"
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
        say "$_p $_b $_v: failed: $(tail -n 2 "$W/cmd.err" | tr '\n' ' ')"
    fi
}
# order <round>: the variants, the first one turning from round to round
order() { if [ $(( $1 % 2 )) = 1 ]; then echo "$variants"; else echo "$variants" | awk '{ for (i = NF; i > 0; i--) printf "%s ", $i }'; fi; }

# the report: a table per program of the medians
report() {
    {
        echo "# prog-bench: $group"
        echo
        echo "FreeBSD $(uname -r), $(sysctl -n hw.model), $ncpu CPUs; rounds $rounds, medians;"
        echo "variants: $variants; flags: $F (gcc16: and -std=gnu17 for C, -fno-semantic-interposition, libgcc linked in)."
        echo "<variant> against clang19: a minus is faster than clang19 (for times and for rates);"
        echo "units: s (seconds, lower is better), s5 (seconds of five runs), MBps (MB/s), MiBps (MiB/s), rps (requests/s),"
        echo "tps (transactions/s)."
        ls "$raw" | cut -d '|' -f 1 | sort -u | while IFS= read -r p; do
            echo
            echo "## $p"
            echo
            others="${variants#clang19}"
            h="| benchmark | unit |"; l="|---|---|"
            for v in $variants; do h="$h $v |"; l="$l--:|"; done
            for v in $others; do h="$h $v against clang19 |"; l="$l--:|"; done
            echo "$h"; echo "$l"
            ls "$raw" | awk -F '|' -v p="$p" '$1 == p { print $2 "|" $3 "|" $4 }' | sort -u | while IFS= read -r b; do
                n="${b%%|*}"; rest="${b#*|}"; u="${rest%%|*}"; d="${rest#*|}"
                a="$(median "$raw/$p|$n|$u|$d|clang19" 2> /dev/null)"
                row="| $n | $u | ${a:--} |"; pcts=""
                for v in $others; do
                    g="$(median "$raw/$p|$n|$u|$d|$v" 2> /dev/null)"
                    pct="$(awk -v a="${a:-0}" -v g="${g:-0}" -v d="$d" 'BEGIN {
                        if (a == 0 || g == 0) { print "-"; exit }
                        if (d == "lower") x = (g / a - 1) * 100; else x = (a / g - 1) * 100
                        printf "%+.1f%%\n", x }')"
                    row="$row ${g:--} |"; pcts="$pcts $pct |"
                done
                echo "$row$pcts"
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
        unpack zstd-1.5.7.tar.zst "$W/src/zstd-$v" && gmake -C "$W/src/zstd-$v/programs" -j"$ncpu" zstd \
            CC="$CC" CFLAGS="$CFLAGS" > "$W/b-zstd-$v.log" 2>&1 || bfail "zstd $v" "$W/b-zstd-$v.log"
        unpack lz4-1.11.1.tar.gz "$W/src/lz4-$v" && gmake -C "$W/src/lz4-$v/programs" -j"$ncpu" lz4 \
            CC="$CC" CFLAGS="$CFLAGS" > "$W/b-lz4-$v.log" 2>&1 || bfail "lz4 $v" "$W/b-lz4-$v.log"
        unpack xxHash-0.8.4.tar.gz "$W/src/xxhash-$v" && gmake -C "$W/src/xxhash-$v" -j"$ncpu" xxhsum \
            CC="$CC" CFLAGS="$CFLAGS" > "$W/b-xxhash-$v.log" 2>&1 || bfail "xxhash $v" "$W/b-xxhash-$v.log"
        unpack brotli-1.2.1.tar.gz "$W/src/brotli-$v" && cmake -S "$W/src/brotli-$v" -B "$W/src/brotli-$v/_b" \
            -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="$CFLAGS -DNDEBUG" \
            -DBUILD_SHARED_LIBS=OFF -DBROTLI_DISABLE_TESTS=ON > "$W/b-brotli-$v.log" 2>&1 &&
            ninja -C "$W/src/brotli-$v/_b" brotli >> "$W/b-brotli-$v.log" 2>&1 || bfail "brotli $v" "$W/b-brotli-$v.log"
        say "compress $v: zstd $(cc_of "$W/src/zstd-$v/programs/zstd"); brotli $(cc_of "$W/src/brotli-$v/_b/brotli")"
    done
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
            CC="$CC" CXX="$CXX" OPTIMIZATION=-O3 DEBUG= CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" > "$W/b-redis-$v.log" 2>&1 || bfail "redis $v" "$W/b-redis-$v.log"
        say "redis $v: $(cc_of "$W/src/redis-$v/src/redis-server")"
    done
    rb="$W/src/redis-clang19/src/redis-benchmark"
    tests="set,get,incr,lpush,rpush,lpop,rpop,sadd,hset,spop,zadd,lrange_100,mset"
    for r in $(seq 1 "$rounds"); do
        say "redis: round $r of $rounds"
        for v in $(order "$r"); do
            cpuset -l "$last" "$W/src/redis-$v/src/redis-server" --port 6390 --save '' --appendonly no \
                --daemonize no > "$W/redis-$v.log" 2>&1 &
            pid=$!
            sleep 2
            cpuset -l 0-$((last - 1)) "$rb" -p 6390 -q -n 2000000 -P 16 -c 50 -t "$tests" --csv 2> /dev/null > "$W/rb.csv"
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
    pw ls pb > /dev/null 2>&1 || pw useradd pb -m -s /bin/sh
    for v in $variants; do
        set_cc "$v"
        unpack postgresql-18.7.tar.bz2 "$W/src/pg-$v"
        (cd "$W/src/pg-$v" && ./configure --prefix="$W/pg-$v" --without-icu --without-readline \
            --without-zlib --without-zstd --without-lz4 --without-openssl CC="$CC" CFLAGS="$CFLAGS" &&
            gmake -j"$ncpu" && gmake install) > "$W/b-pg-$v.log" 2>&1 || bfail "postgresql $v" "$W/b-pg-$v.log"
        say "postgresql $v: $(cc_of "$W/pg-$v/bin/postgres")"
        rm -rf "$W/pgdata-$v"; mkdir -p "$W/pgdata-$v" "$W/pgrun"; chown pb "$W/pgdata-$v" "$W/pgrun"; chmod 755 "$W"
        su -m pb -c "$W/pg-$v/bin/initdb -D $W/pgdata-$v -E UTF8 --no-locale" > "$W/initdb-$v.log" 2>&1 ||
            bfail "initdb $v" "$W/initdb-$v.log"
    done
    pgb="$W/pg-clang19/bin/pgbench"
    psql="$W/pg-clang19/bin/psql"
    q="SELECT count(*), sum(i % 7), avg(i::numeric) FROM generate_series(1, 20000000) AS i"
    for r in $(seq 1 "$rounds"); do
        say "postgresql: round $r of $rounds"
        for v in $(order "$r"); do
            su -m pb -c "$W/pg-$v/bin/pg_ctl -D $W/pgdata-$v -l $W/pgrun/pg-$v.log -w -o '-p 5440 -c fsync=off \
                -c synchronous_commit=off -c full_page_writes=off -c shared_buffers=1GB -c max_connections=60' start" > /dev/null ||
                die "start postgresql $v"
            if [ "$r" = 1 ]; then su -m pb -c "$pgb -p 5440 -i -s 20 -q postgres" > /dev/null 2>&1; fi
            t="$(su -m pb -c "$pgb -p 5440 -S -M prepared -c 4 -j 4 -T 30 postgres" 2>/dev/null | sed -n -E 's/^tps = ([0-9.]+).*/\1/p')"
            record postgresql "pgbench -S (4 clients)" tps higher "$v" "$t"
            t="$(su -m pb -c "$pgb -p 5440 -M prepared -c 4 -j 4 -T 30 postgres" 2>/dev/null | sed -n -E 's/^tps = ([0-9.]+).*/\1/p')"
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
        unpack Python-3.12.16.tar.xz "$W/src/py-$v"
        (cd "$W/src/py-$v" && ./configure --prefix="$W/py-$v" --with-ensurepip=install CC="$CC" CFLAGS="$CFLAGS" \
            CPPFLAGS=-I/usr/local/include LDFLAGS=-L/usr/local/lib && gmake -j"$ncpu" && gmake install) \
            > "$W/b-py-$v.log" 2>&1 || bfail "python $v" "$W/b-py-$v.log"
        say "python $v: $(cc_of "$W/py-$v/bin/python3.12")"
    done
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
    fetch ImageMagick-7.1.2-35.tar.xz fce4636c81a3a4670ece47927f7ff924b94f09f8c7a92e6443579899713fd564 \
        https://download.imagemagick.org/archive/releases/ImageMagick-7.1.2-35.tar.xz \
        https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ImageMagick-7.1.2-35.tar.xz
    fetch ImageMagick-6.9.13-60.tar.xz 8e25148ca3c0bc66bb5aa78c7e7a272b61d0d4a00f337e82dfbfeda28c845239 \
        https://download.imagemagick.org/archive/releases/ImageMagick-6.9.13-60.tar.xz \
        https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ImageMagick-6.9.13-60.tar.xz
    fetch GraphicsMagick-1.3.49.tar.xz 7efa070dc31116b4315061b39f84bc7181e8b060bf61214ec9af851131af9c81 \
        https://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.49/GraphicsMagick-1.3.49.tar.xz
    for v in $variants; do
        set_cc "$v"
        for m in im7:ImageMagick-7.1.2-35 im6:ImageMagick-6.9.13-60 gm:GraphicsMagick-1.3.49; do
            k="${m%%:*}"; d="${m#*:}"
            unpack "$d.tar.xz" "$W/src/$k-$v"
            (cd "$W/src/$k-$v" && ./configure --prefix="$W/$k-$v" --disable-shared --enable-static --without-modules \
                --disable-openmp --without-magick-plus-plus --without-perl --without-x --disable-docs \
                CC="$CC" CXX="$CXX" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" && gmake -j"$ncpu" && gmake install) \
                > "$W/b-$k-$v.log" 2>&1 || bfail "$k $v" "$W/b-$k-$v.log"
        done
        say "magick $v: $(cc_of "$W/im7-$v/bin/magick")"
    done
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
    mkdir -p /mnt/pbrd && { mount | grep -q ' /mnt/pbrd ' || mount -t tmpfs -o size=4g tmpfs /mnt/pbrd; }
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

case "$group" in
compress|redis|postgresql|python|magick|vips) ;;
*) die "unknown group $group (compress redis postgresql python magick vips)" ;;
esac
say "group $group, $rounds rounds, $ncpu CPUs, variants: $variants; cc: $(cc --version | head -n 1)${gcc_bin:+; gcc16: $("$gcc_bin" --version | head -n 1)}$(command -v clang23 > /dev/null && printf '; clang23: %s' "$(clang23 --version | head -n 1)")"
"g_$group"
report
say "the report: $out"
