#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
# tools/lib-bench3.sh <group> [<rounds>]: the speed of the C and C++ libraries of this tree
# (those of the package azsupport, azsupport/azsupport/files/deps.conf and curl-deps.conf,
# and the library ports) built by three compilers from the same sources with the same
# flags, in one VM (aZ, 26.11.2026: «сделай замер всего для нашего гцц 16.2, для базового
# цланг и нашего цланг 23 … Все дерево портов наше проверь»):
#   clang19  the cc of the base system (clang 19 of FreeBSD 15.1)
#   clang23  clang 23.1.6 of the package llvm23 (the compiler of devel/llvm23 of this tree:
#            the same release), with the ar, nm, ranlib and ld of LLVM 23 first in the
#            PATH, as Mk/bsd.overlay.mk has them (BINARY_ALIAS)
#   gcc16    GCC 16.2.0 of the package gcc16 of the repository azsupport (lang/gcc16 of
#            this tree), as Mk/Uses/azgcc.mk builds: -std=gnu17 for C,
#            -fno-semantic-interposition, libgcc linked in (-static-libgcc)
# The flags of every variant, those of the libraries of azsupport (tools/azsupport-build.sh)
# and of the ports (tools/make.conf.in, CPUTYPE x86-64-v3): -O3 -pipe -march=x86-64-v3
# -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2
# -fno-strict-aliasing -fPIC. No PGO; LTO only where azsupport builds with it (x264).
# The sources: the release files of the versions of our ports and of deps.conf (the
# SHA-256 of their distinfo or take line), without the patches of the ports (they are
# for the build and for security, not for speed).
#
# Each library is built as a shared library (its benchmark program, built by the same
# variant, finds it by its run path: ldd and the .comment of the library in the report
# prove which one runs) into a prefix of its own per variant; what it needs besides
# (libxml2 for libxslt, glib for the programs of harfbuzz, the decoders of libheif...)
# comes from the packages of FreeBSD, the same for the three, so that only the library
# measured changes. Its benchmark: its own (zstd -b, lz4 -b, xxhsum -b, speedtest1 of
# sqlite, lowlevel-blt-bench of pixman, the benchmarks of libuv), its programs on
# fixed inputs (xmllint, xsltproc, xmlwf, tidy, iconv, cjpeg, djpeg, cwebp, dwebp, x264,
# SvtAv1EncApp, dav1d, dec265, hb-shape, fribidi, luajit, brotli, argon2), or a driver
# of tools/lib-bench3/ (d-<library>.c: what PHP, Apache, nginx, ImageMagick... call
# most), each result "<benchmark> <seconds>". The inputs are made by
# tools/lib-bench3/gen.c from a fixed seed.
#
# The measurement: the builds first, one after another; then <rounds> rounds (default
# 7): in each, every library, its benchmarks with each variant in turn, the first
# variant turning from round to round (clang19 clang23 gcc16, clang23 gcc16 clang19,
# ...), on the last CPU (cpuset -l), nothing else running. The report:
# results/lib-bench/<group>.md: per library the medians of each variant, the spread
# ((max - min) / median, the largest of the three), each against clang19 in % (a
# minus is faster than clang19, for times and for rates alike), the winner of each
# benchmark; per library the geometric mean of the ratios, the winner and its margin
# over the next; the libraries not measured, with the reason; the raw values.
# A library whose download, build or benchmark fails is reported with the end of its
# log, and the rest goes on.
#
# The groups (tools/lib-bench3.sh list): compress, crypto, text, image, video, net.
# Environment: LB_WORK (default /lb), LB_VARIANTS (default "clang19 clang23 gcc16"),
# LB_LIBS (only these libraries of the group).

set -u
group="${1:?usage: $0 <group> [<rounds>]}"
rounds="${2:-7}"
top="$(pwd)"
D="$top/tools/lib-bench3"
W="${LB_WORK:-/lb}"
R="$top/results/lib-bench"
mkdir -p "$W/dist" "$W/src" "$W/raw" "$W/i" "$W/in" "$W/log" "$R"
raw="$W/raw"
out="$R/$group.md"
log="$R/$group.log"
notes="$W/notes"
: > "$notes"
exec 3>> "$log"
say() { echo "== $(date -u +%H:%M:%S) $*"; echo "== $(date -u +%H:%M:%S) $*" >&3; }
ncpu="$(sysctl -n hw.ncpu)"
last=$((ncpu - 1))
variants="${LB_VARIANTS:-clang19 clang23 gcc16}"
F="-O3 -pipe -march=x86-64-v3 -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fno-strict-aliasing -fPIC"
PATH0="$PATH"

# --------------------------------------------------------------- the groups
groups="compress crypto text image video net"
libs_compress="zstd lz4 xxhash brotli libiconv libmcrypt luajit"
libs_crypto="libsodium argon2 gmp mpdecimal libffi fmt glib sqlite3"
libs_text="libxml2 libxslt expat tidy libyaml oniguruma pcre pcre2 icu"
libs_image="png mozjpeg webp gd lcms2 tiff freetype2 harfbuzz fontconfig pixman cairo fribidi"
libs_video="x264 dav1d svtav1 libde265 libheif"
libs_net="curl c-ares nghttp2 libidn2 libpsl libuv apr libmaxminddb libmemcached simdjson libada llhttp"
# what each group needs of the packages of FreeBSD (besides the compilers and the build tools)
pkgs_compress=""
pkgs_crypto="pcre2 libffi gettext-runtime"
pkgs_text="libxml2"
pkgs_image="dejavu freetype2 expat fontconfig pixman png glib gperf"
pkgs_video="x265 svt-av1 dav1d libde265 png jpeg-turbo"
pkgs_net="bison"
# not measured, and why (aZ: «без осмысленной нагрузки — строка почему»)
not_measured="readline|line editing of a terminal: no load of a server
gettext|gettext-runtime (libintl): looking up a message in a .mo catalog is a hash lookup, microseconds per page
slang|the screen of mc: no load of a server
liburcu|the RCU of BIND 9.20: its hot parts are inline functions and atomic operations compiled into BIND (the headers of urcu), the library only runs the grace periods in threads
libssh2|SCP and SFTP of curl: the time is that of the ciphers of OpenSSL of the base system and of the network; its own code parses packets
libzip|the zip of PHP: the time is that of zlib (base system), bzip2 and zstd; its own code reads and writes the directory of the archive
libevent|memcached and tmux: the time is that of kqueue and of the system calls; its benchmarks (test/bench) measure those
libmemcached:network|the network part of libmemcached (only the hashing and the server selection are measured: libmemcached)
psl-list|data (the public suffix list), no code
highway|devel/highway: its code is in its headers, compiled into libvips and libjxl (vips: tools/prog-bench.sh)
libimagequant|graphics/libimagequant 4.x is Rust (rustc, LLVM of Rust): no C compiler builds it
librsvg2-rust|Rust (rustc): no C compiler builds it
gcc16-libs|the run-time libraries of GCC, built only by GCC
libimagemagick6|ImageMagick: tools/prog-bench.sh (group magick)
libimagemagick7|ImageMagick: tools/prog-bench.sh (group magick)
vips|libvips: tools/prog-bench.sh (group vips)
pango|text layout of libvips (vips text): rare on our sites, the time is that of harfbuzz, freetype and cairo (measured)
cgif|the GIF writer of libvips: rare on our sites
libexif|the EXIF of libvips: microseconds per picture
hdr_histogram|histograms of the latency tools: no load of a server
libultrahdr|Ultra HDR JPEG: no program of ours uses it (ImageMagick 7 --without-uhdr)
t1lib|Type 1 fonts of php56-gd-t1lib only
uvwasi|WASI of Node.js: no load
nbytes|small byte helpers of Node.js (base64 and the like): no load of their own
libnghttp3|HTTP/3 of curl: the time is that of the network and of OpenSSL (QUIC)
libngtcp2|QUIC of curl: the time is that of the network and of OpenSSL
libgearman|the client of gearmand: the time is that of the network
libmilter|the milter protocol of Postfix and Sendmail: the time is that of the network
libtlsrpt|TLSRPT reports of Postfix: no load
fusefs-libs|FUSE: the time is that of the kernel and of the file systems
fusefs-libs3|FUSE: the time is that of the kernel and of the file systems
libtorrent|rtorrent: the time is that of the network and of the disks
fcgi|the FastCGI protocol of fcgiwrap: the time is that of the programs it runs"

# --------------------------------------------------------------- the variants
# bin-<variant>: cc, c++ (and for clang23 cpp, clang, clang++, ar, nm, ranlib, ld) of the
# variant, first in its PATH
mkdir -p "$W/bin-clang19" "$W/bin-clang23" "$W/bin-gcc16"
llvm23_tool() { for t in "/usr/local/bin/$1" "/usr/local/llvm23/bin/$2" "$(command -v "$1")"; do [ -n "$t" ] && [ -x "$t" ] && { echo "$t"; return 0; }; done; return 1; }
ln -sf /usr/bin/cc "$W/bin-clang19/cc"; ln -sf /usr/bin/c++ "$W/bin-clang19/c++"
if command -v clang23 > /dev/null; then
    for a in cc:clang23:clang c++:clang++23:clang++ cpp:clang-cpp23:clang-cpp clang:clang23:clang clang++:clang++23:clang++ \
        ar:llvm-ar23:llvm-ar nm:llvm-nm23:llvm-nm ranlib:llvm-ranlib23:llvm-ranlib ld:ld.lld23:ld.lld; do
        n="${a%%:*}"; r="${a#*:}"; t="$(llvm23_tool "${r%%:*}" "${r#*:}")" && ln -sf "$t" "$W/bin-clang23/$n"
    done
fi
gcc_bin="$(command -v gcc16 || :)"
if [ -n "$gcc_bin" ]; then
    printf '#!/bin/sh\nexec %s -static-libgcc "$@"\n' "$gcc_bin" > "$W/bin-gcc16/cc"
    printf '#!/bin/sh\nexec %s -static-libgcc "$@"\n' "$(command -v g++16)" > "$W/bin-gcc16/c++"
    chmod +x "$W/bin-gcc16/cc" "$W/bin-gcc16/c++"
    ln -sf "$W/bin-gcc16/cc" "$W/bin-gcc16/gcc"; ln -sf "$W/bin-gcc16/c++" "$W/bin-gcc16/g++"
fi
# set_cc <variant> <prefix>: the compilers, flags and PATH of the variant for a build into <prefix>
set_cc() {
    b="$W/bin-$1"
    export CC="$b/cc" CXX="$b/c++" PATH="$b:$PATH0"
    export CFLAGS="$F" CXXFLAGS="$F" CPPFLAGS="-I$2/include -I/usr/local/include"
    export LDFLAGS="-L$2/lib -Wl,-rpath,$2/lib -L/usr/local/lib"
    export PKG_CONFIG_PATH="$2/lib/pkgconfig:$2/libdata/pkgconfig"
    unset AR NM RANLIB
    case "$1" in
    clang23)
        # lld of LLVM 23 (ld.lld beside clang23), also for the LTO of x264
        export AR="$b/ar" NM="$b/nm" RANLIB="$b/ranlib" LDFLAGS="$LDFLAGS -fuse-ld=lld" ;;
    gcc16)
        export CFLAGS="$F -std=gnu17 -fno-semantic-interposition" CXXFLAGS="$F -fno-semantic-interposition"
        export LDFLAGS="$LDFLAGS -Wl,-rpath,/usr/local/lib/gcc16"
        # the archives of GCC LTO objects (x264) need its plugin: gcc-ar
        command -v gcc-ar16 > /dev/null && export AR=gcc-ar16 NM=gcc-nm16 RANLIB=gcc-ranlib16 ;;
    esac
}
# the compilers that a file was built with, from its .comment
cc_of() { readelf -p .comment "$1" 2> /dev/null | grep -o -E '(FreeBSD )?clang version [0-9.]+|GCC: \([^)]*\) [0-9.]+' | sort -u | tr '\n' ';' | sed 's/;$//; s/;/; /g'; }
note() { echo "$*" >> "$notes"; }

# --------------------------------------------------------------- helpers
# fetch <file> <sha256> <url>...: into $W/dist, the first URL that gives it, checked
fetch() {
    f="$W/dist/$1"; sum="$2"; shift 2
    if [ ! -f "$f" ] || [ "$(sha256 -q "$f")" != "$sum" ]; then
        for u in "$@"; do
            curl -fsSL --retry 3 --connect-timeout 30 -o "$f.part" "$u" 2>> "$W/log/fetch.log" && mv -f "$f.part" "$f" && break
        done
    fi
    [ -f "$f" ] || { echo "cannot download $1 ($*)"; return 1; }
    [ "$(sha256 -q "$f")" = "$sum" ] || { echo "$1: SHA-256 $(sha256 -q "$f"), not $sum"; return 1; }
}
# the distfile cache of FreeBSD (the same files and SHA-256 as the distinfo of the ports)
DC=https://distcache.FreeBSD.org/ports-distfiles
# unpack <file> <dir>: the release file into <dir>, its top directory stripped
unpack() { rm -rf "$2"; mkdir -p "$2" && tar -xf "$W/dist/$1" -C "$2" --strip-components 1; }
# ac <src> <prefix> [<configure arguments>]: an autotools build
ac() { s_="$1" p_="$2"; shift 2; (cd "$s_" && ./configure --prefix="$p_" --libdir="$p_/lib" --disable-static --enable-shared "$@" && gmake -j"$ncpu" && gmake install); }
# cm <src> <prefix> [<cmake arguments>]: a cmake build (flags of the environment, Release only adds -DNDEBUG)
cm() {
    s_="$1" p_="$2"; shift 2
    cmake -S "$s_" -B "$s_/_lb" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG \
        -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG -DCMAKE_INSTALL_PREFIX="$p_" -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_INSTALL_RPATH="$p_/lib" -DBUILD_SHARED_LIBS=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "$@" &&
        ninja -C "$s_/_lb" -j "$ncpu" && ninja -C "$s_/_lb" install
}
# ms <src> <prefix> [<meson arguments>]: a meson build (flags of the environment)
ms() {
    s_="$1" p_="$2"; shift 2
    (cd "$s_" && meson setup _lb --prefix="$p_" --libdir=lib --buildtype=release -Doptimization=plain \
        --default-library=shared --wrap-mode=nodownload "$@" && ninja -C _lb -j "$ncpu" && ninja -C _lb install)
}
# drv <variant> <prefix> <driver> [<compiler and linker arguments>]: tools/lib-bench3/<driver> built
# by the variant into <prefix>/bin
drv() {
    v_="$1" p_="$2" d_="$3"; shift 3
    case "$d_" in
    *.cc) $CXX $CXXFLAGS -I"$D" -I"$p_/include" -o "$p_/bin/${d_%.cc}" "$D/$d_" $LDFLAGS "$@" ;;
    *) $CC $CFLAGS -I"$D" -I"$p_/include" -o "$p_/bin/${d_%.c}" "$D/$d_" $LDFLAGS "$@" -lm ;;
    esac
}

# record <library> <benchmark> <unit> <lower|higher> <variant> <value>: a value of a round
record() {
    case "$6" in ''|*[!0-9.e+-]*) say "$1 $2 $5: no number ('$6')"; return 0 ;; esac
    # a / of the name of a benchmark would be a directory: the division slash
    echo "$6" >> "$raw/$1|$(printf '%s' "$2" | sed 's#/#∕#g')|$3|$4|$5"
}
# T <library> <benchmark> <variant> [tm options] <command>...: its seconds (tm: the clock),
# on the last CPU; a command that fails is said, not recorded
T() {
    l_="$1" b_="$2" v_="$3"; shift 3
    if x_="$(cpuset -l "$last" "$W/tm" -e "$W/cmd.err" "$@" 2> "$W/tm.err")"; then
        record "$l_" "$b_" s lower "$v_" "$x_"
    else
        say "$l_ $b_ $v_: failed: $(cat "$W/tm.err" "$W/cmd.err" 2> /dev/null | tail -n 3 | tr '\n' ' ' | cut -c1-300)"
    fi
}
# TN <n> <library> <benchmark> <variant> <command>...: as T, the command <n> times in one
# measurement (a command of a few hundredths of a second); the name gets " x<n>"
TN() {
    n_="$1" l_="$2" b_="$3" v_="$4"; shift 4
    if x_="$(cpuset -l "$last" "$W/tm" -e "$W/cmd.err" sh -c 'n=$1; shift; i=0; while [ $i -lt $n ]; do "$@" > /dev/null || exit 1; i=$((i + 1)); done' sh "$n_" "$@" 2> "$W/tm.err")"; then
        record "$l_" "$b_ x$n_" s lower "$v_" "$x_"
    else
        say "$l_ $b_ $v_: failed: $(cat "$W/tm.err" "$W/cmd.err" 2> /dev/null | tail -n 3 | tr '\n' ' ' | cut -c1-300)"
    fi
}
# DRV <library> <variant> <program> [<arguments>]: a driver on the last CPU, each line of its
# output "<benchmark> <seconds>" recorded
DRV() {
    l_="$1" v_="$2"; shift 2
    cpuset -l "$last" "$@" > "$W/drv.out" 2> "$W/drv.err"
    rc_=$?
    [ "$rc_" = 0 ] || say "$l_ $v_: $1 failed (exit status $rc_): $(tail -n 3 "$W/drv.err" | tr '\n' ' ' | cut -c1-300)"
    while read -r line; do
        val="${line##* }"; nm="${line% *}"
        record "$l_" "$nm" s lower "$v_" "$val"
    done < "$W/drv.out"
}
median() { sort -n "$1" | awk '{ v[NR] = $1 } END { if (NR == 0) exit; if (NR % 2) print v[(NR + 1) / 2]; else print (v[NR / 2] + v[NR / 2 + 1]) / 2 }'; }
spread() { sort -n "$1" | awk '{ v[NR] = $1 } END { if (NR < 2) { print 0; exit } m = (NR % 2) ? v[(NR + 1) / 2] : (v[NR / 2] + v[NR / 2 + 1]) / 2; if (m == 0) print 0; else printf "%.1f\n", (v[NR] - v[1]) / m * 100 }'; }
# order <round>: the variants, the first one turning from round to round
order() { echo "$variants" | awk -v r="$1" '{ n = NF; s = (r - 1) % n; for (i = 0; i < n; i++) printf "%s ", $((s + i) % n + 1) }'; }

# --------------------------------------------------------------- the libraries
# Each library <l>: f_<l> (fetch; prints the version), b_<l> <variant> <src> <prefix> (the
# build, the driver), m_<l> <variant> <prefix> (one round of its benchmarks), so_<l> (the
# library file, for the proof).

# ---- compress
f_zstd() { fetch zstd-1.6.0.tar.zst 2ca30d45c7a61f255e17024373f7fe75b6403b2ade6b21220c1472964d8a466a \
    https://github.com/facebook/zstd/releases/download/v1.6.0/zstd-1.6.0.tar.zst && V=1.6.0 A=zstd-1.6.0.tar.zst; }
b_zstd() {
    gmake -C "$2/lib" -j"$ncpu" libzstd CC="$CC" CFLAGS="$CFLAGS" && gmake -C "$2/lib" install PREFIX="$3" LIBDIR="$3/lib" &&
        gmake -C "$2/programs" -j"$ncpu" zstd CC="$CC" CFLAGS="$CFLAGS" &&
        mkdir -p "$3/bin" && cp "$2/programs/zstd" "$3/bin/zstd"
}
so_zstd() { echo "lib/libzstd.so.1"; }
zb() { cpuset -l "$last" "$@" 2>&1 | tr '\r' '\n' | grep -E 'MB/s *, *[0-9.]+ MB/s' | tail -n 1; }
m_zstd() {
    for l in 1 3 9 19; do
        c="$W/in/corpus"; [ "$l" = 19 ] && c="$W/in/corpus5"
        x="$(zb "$2/bin/zstd" -b"$l" -e"$l" -i2 -T1 "$c")"
        record zstd "-$l compress" MBps higher "$1" "$(echo "$x" | sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\1/p')"
        record zstd "-$l decompress" MBps higher "$1" "$(echo "$x" | sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\2/p')"
    done
}
f_lz4() { fetch lz4-1.11.1.tar.gz 683fed08a844ad012196381e40badf80c0bbe4962959761416d41c9e67d77ec7 \
    https://github.com/lz4/lz4/releases/download/v1.11.1/lz4-1.11.1.tar.gz "$DC/lz4-1.11.1.tar.gz" && V=1.11.1 A=lz4-1.11.1.tar.gz; }
b_lz4() {
    gmake -C "$2/lib" -j"$ncpu" liblz4 CC="$CC" CFLAGS="$CFLAGS" BUILD_STATIC=no &&
        gmake -C "$2/lib" install PREFIX="$3" LIBDIR="$3/lib" BUILD_STATIC=no &&
        gmake -C "$2/programs" -j"$ncpu" lz4 CC="$CC" CFLAGS="$CFLAGS" && mkdir -p "$3/bin" && cp "$2/programs/lz4" "$3/bin/lz4"
}
so_lz4() { echo "lib/liblz4.so.1"; }
m_lz4() {
    for l in 1 9; do
        x="$(zb "$2/bin/lz4" -b"$l" -e"$l" -i2 "$W/in/corpus")"
        record lz4 "-$l compress" MBps higher "$1" "$(echo "$x" | sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\1/p')"
        record lz4 "-$l decompress" MBps higher "$1" "$(echo "$x" | sed -n -E 's/.*[ ,] *([0-9.]+) MB\/s *, *([0-9.]+) MB\/s.*/\2/p')"
    done
}
f_xxhash() { fetch xxHash-0.8.4.tar.gz 5738270935e7c3d38a79b3adf7c9692566ce7895a25f67de43ad52ab504acd32 \
    https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.4.tar.gz "$DC/Cyan4973-xxHash-v0.8.4_GH0.tar.gz" && V=0.8.4 A=xxHash-0.8.4.tar.gz; }
b_xxhash() {
    gmake -C "$2" -j"$ncpu" libxxhash CC="$CC" CFLAGS="$CFLAGS" && gmake -C "$2" install_libxxhash install_libxxhash.includes PREFIX="$3" LIBDIR="$3/lib" &&
        gmake -C "$2" -j"$ncpu" xxhsum CC="$CC" CFLAGS="$CFLAGS" && mkdir -p "$3/bin" && cp "$2/xxhsum" "$3/bin/xxhsum"
}
so_xxhash() { echo "lib/libxxhash.so.0"; }
m_xxhash() {
    cpuset -l "$last" "$2/bin/xxhsum" -b1,3,5,11 2>&1 | tr '\r' '\n' > "$W/xb"
    for a in XXH32 XXH64 XXH3_64b XXH128; do
        record xxhash "$a" MiBps higher "$1" "$(grep -E "#$a +:" "$W/xb" | tail -n 1 | sed -n -E 's/.*\( *([0-9.]+) MiB\/s\).*/\1/p')"
    done
}
f_brotli() { fetch brotli-1.2.1.tar.gz 98d35d11a78dc453aebb7d10c3748f3f73ff78c8267c0dc697b8631f67bf7e8f \
    https://github.com/google/brotli/archive/refs/tags/v1.2.1.tar.gz "$DC/brotli/1.2.1/google-brotli-v1.2.1_GH0.tar.gz" && V=1.2.1 A=brotli-1.2.1.tar.gz; }
b_brotli() { cm "$2" "$3" -DBROTLI_DISABLE_TESTS=ON -DBROTLI_BUILD_TOOLS=ON; }
so_brotli() { echo "lib/libbrotlienc.so.1"; }
m_brotli() {
    T brotli "-q 5 (30 MB)" "$1" "$2/bin/brotli" -q 5 -c "$W/in/corpus"
    T brotli "-q 9 (30 MB)" "$1" "$2/bin/brotli" -q 9 -c "$W/in/corpus"
    T brotli "-q 11 (5 MB)" "$1" "$2/bin/brotli" -q 11 -c "$W/in/corpus5"
    TN 10 brotli "-d (30 MB)" "$1" "$2/bin/brotli" -d -c "$W/in/corpus.br"
}
f_libiconv() { fetch libiconv-1.18.tar.gz 3b08f5f4f9b4eb82f151a7040bfd6fe6c6fb922efe4b1659c66ea933276965e8 \
    https://ftp.gnu.org/gnu/libiconv/libiconv-1.18.tar.gz https://ftpmirror.gnu.org/libiconv/libiconv-1.18.tar.gz "$DC/libiconv-1.18.tar.gz" && V=1.18 A=libiconv-1.18.tar.gz; }
b_libiconv() { ac "$2" "$3" --disable-nls --enable-extra-encodings am_cv_func_iconv=no; }
so_libiconv() { echo "lib/libiconv.so.2"; }
m_libiconv() {
    for c in UTF-16LE UTF-32 CP1251//TRANSLIT KOI8-R//TRANSLIT ISO-8859-5//TRANSLIT GB18030; do
        TN 10 libiconv "UTF-8 to $c" "$1" "$2/bin/iconv" -f UTF-8 -t "$c" "$W/in/text.txt"
    done
    TN 10 libiconv "UTF-16LE to UTF-8" "$1" "$2/bin/iconv" -f UTF-16LE -t UTF-8 "$W/in/text.utf16"
    TN 10 libiconv "CP1251 to UTF-8" "$1" "$2/bin/iconv" -f CP1251 -t UTF-8 "$W/in/text.cp1251"
}
f_libmcrypt() { fetch libmcrypt-2.5.8.tar.gz e4eb6c074bbab168ac47b947c195ff8cef9d51a211cdd18ca9c9ef34d27a373e \
    "$DC/libmcrypt-2.5.8.tar.gz" https://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz && V=2.5.8 A=libmcrypt-2.5.8.tar.gz; }
b_libmcrypt() {
    # C of 2007: what newer compilers refuse by default, the same for the three
    # its libtool 1.5 takes freebsd15 for FreeBSD 1: no shared library, the static one (compiled by the
    # variant) goes into the driver (the replacement of freebsd1* in its configure left no library at
    # all, run 45901157597)
    (CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration -Wno-error=implicit-int -Wno-error=int-conversion -Wno-error=incompatible-pointer-types"
        export CFLAGS; ac "$2" "$3" --disable-posix-threads) && drv "$1" "$3" d-mcrypt.c -lmcrypt
}
so_libmcrypt() { echo "lib/libmcrypt.so.4"; }
m_libmcrypt() { DRV libmcrypt "$1" "$2/bin/d-mcrypt"; }
f_luajit() { fetch luajit2-2.1-20261107.tar.gz c79b8f08ddcdcfa06961c416efa1455f9f2b7f4cba6b0fd814239f36e7557f74 \
    "$DC/openresty-luajit2-v2.1-20261107_GH0.tar.gz" https://codeload.github.com/openresty/luajit2/tar.gz/v2.1-20261107 && V=2.1-20261107 A=luajit2-2.1-20261107.tar.gz; }
b_luajit() {
    gmake -C "$2" -j"$ncpu" BUILDMODE=dynamic PREFIX="$3" CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" TARGET_STRIP=: &&
        gmake -C "$2" install PREFIX="$3" && { [ -e "$3/bin/luajit" ] || ln -sf "$(ls "$3"/bin/luajit-2.1* | head -n 1)" "$3/bin/luajit"; }
}
so_luajit() { echo "lib/libluajit-5.1.so.2"; }
m_luajit() {
    for b in strings:1 patterns:3 tables:1 gc:1 numbers:6; do
        T luajit "${b%:*} x${b#*:}" "$1" "$2/bin/luajit" "$D/lua-bench.lua" "${b%:*}" "${b#*:}"
    done
}

# ---- crypto
f_libsodium() { fetch libsodium-1.0.22.tar.bz2 51b93737bf62e8549b0e94dce0fba92169e31c8ecc160883460a9bdaa6d2c298 \
    "$DC/libsodium-1.0.22.tar.bz2" https://download.libsodium.org/libsodium/releases/libsodium-1.0.22.tar.bz2 && V=1.0.22 A=libsodium-1.0.22.tar.bz2; }
b_libsodium() { ac "$2" "$3" && drv "$1" "$3" d-sodium.c -lsodium; }
so_libsodium() { echo "lib/libsodium.so.26"; }
m_libsodium() { DRV libsodium "$1" "$2/bin/d-sodium"; }
f_argon2() { fetch argon2-20190702.tar.gz daf972a89577f8772602bf2eb38b6a3dd3d922bf5724d45e7f9589b5e830442c \
    "$DC/P-H-C-phc-winner-argon2-20190702_GH0.tar.gz" https://codeload.github.com/P-H-C/phc-winner-argon2/tar.gz/20190702 && V=20190702 A=argon2-20190702.tar.gz; }
b_argon2() {
    # its Makefile with our flags in the place of its -O3 -g (and the -march of OPTTARGET)
    gmake -C "$2" -j"$ncpu" CC="$CC" OPTTARGET=x86-64-v3 CFLAGS="$CFLAGS -std=c89 -Iinclude -Isrc -pthread" \
        LIBRARY_REL=lib PREFIX="$3" SO_LDFLAGS="-shared -Wl,-soname=libargon2.so.1 $LDFLAGS" libargon2.so argon2 &&
        mkdir -p "$3/bin" "$3/lib" && cp "$2/argon2" "$3/bin/" && cp "$2/libargon2.so"* "$3/lib/"
}
so_argon2() { echo "bin/argon2"; }
m_argon2() {
    for t in id i d; do T argon2 "-$t -t 8 -m 17 (128 MB) -p 1" "$1" -i "$W/in/pw" "$2/bin/argon2" saltsalt12345678 "-$t" -t 8 -m 17 -p 1; done
}
f_gmp() { fetch gmp-6.3.0.tar.xz a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898 \
    https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz "$DC/gmp-6.3.0.tar.xz" && V=6.3.0 A=gmp-6.3.0.tar.xz; }
b_gmp() {
    # no doc/ (its info pages), as tools/azsupport-build.sh
    sed -i '' -e '/^SUBDIRS/ s|doc||' "$2/Makefile.in" && ac "$2" "$3" --disable-cxx --enable-fat && drv "$1" "$3" d-gmp.c -lgmp
}
so_gmp() { echo "lib/libgmp.so.10"; }
m_gmp() { DRV gmp "$1" "$2/bin/d-gmp"; }
f_mpdecimal() { fetch mpdecimal-4.0.1.tar.gz 96d33abb4bb0070c7be0fed4246cd38416188325f820468214471938545b1ac8 \
    "$DC/mpdecimal-4.0.1.tar.gz" https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz && V=4.0.1 A=mpdecimal-4.0.1.tar.gz; }
b_mpdecimal() { ac "$2" "$3" --disable-cxx && drv "$1" "$3" d-mpdec.c -lmpdec; }
so_mpdecimal() { echo "lib/libmpdec.so.4"; }
m_mpdecimal() { DRV mpdecimal "$1" "$2/bin/d-mpdec"; }
f_libffi() { fetch libffi-3.8.2.tar.gz a699fda2b090c4b46cb79cf60c4dacfce480eb05742c0de66acf3af174a47f92 \
    https://github.com/libffi/libffi/releases/download/v3.8.2/libffi-3.8.2.tar.gz "$DC/libffi-3.8.2.tar.gz" && V=3.8.2 A=libffi-3.8.2.tar.gz; }
b_libffi() {
    (case "$1" in clang*) LDFLAGS="$LDFLAGS -Wl,--undefined-version"; export LDFLAGS ;; esac
        ac "$2" "$3" --disable-multi-os-directory --disable-docs) && drv "$1" "$3" d-ffi.c -lffi
}
so_libffi() { echo "lib/libffi.so.8"; }
m_libffi() { DRV libffi "$1" "$2/bin/d-ffi"; }
f_fmt() { fetch fmt-12.2.1.zip 870a49acec5bcdab236aeea834ebd7f0b8548a7d8cea33c996b6873a37f2d50c \
    https://github.com/fmtlib/fmt/releases/download/12.2.1/fmt-12.2.1.zip && V=12.2.1 A=fmt-12.2.1.zip; }
b_fmt() { cm "$2" "$3" -DFMT_TEST=OFF -DFMT_DOC=OFF -DFMT_OS=ON && drv "$1" "$3" d-fmt.cc -std=c++17 -lfmt; }
so_fmt() { echo "lib/libfmt.so.12"; }
m_fmt() { DRV fmt "$1" "$2/bin/d-fmt"; }
f_glib() { fetch glib-2.90.2.tar.xz edf473b4f5ee70a31d2410622ee605dc4a2c8c46dbc0ec53c9abbaf3960232fd \
    "$DC/gnome/glib-2.90.2.tar.xz" https://download.gnome.org/sources/glib/2.90/glib-2.90.2.tar.xz && V=2.90.2 A=glib-2.90.2.tar.xz; }
b_glib() {
    ms "$2" "$3" -Dtests=false -Dintrospection=disabled -Dman-pages=disabled -Ddocumentation=false -Dnls=disabled \
        -Dselinux=disabled -Dxattr=false -Dlibmount=disabled -Dsysprof=disabled -Ddtrace=disabled -Dsystemtap=disabled &&
        drv "$1" "$3" d-glib.c $(PKG_CONFIG_PATH="$3/lib/pkgconfig" pkgconf --cflags --libs gobject-2.0)
}
so_glib() { echo "lib/libglib-2.0.so.0"; }
m_glib() { DRV glib "$1" "$2/bin/d-glib" "$W/in/text.txt"; }
f_sqlite3() { fetch sqlite-src-3540100.zip 387e7f6cad4797b17848c07d453dc6606917bb356a6cfe5a3abafd38c240c71b \
    "$DC/sqlite-src-3540100.zip" https://www.sqlite.org/2026/sqlite-src-3540100.zip && V=3.54.1 A=sqlite-src-3540100.zip; }
b_sqlite3() {
    (cd "$2" && ./configure --prefix="$3" --libdir="$3/lib" --soname=legacy --fts5 --rtree --disable-tcl --disable-static \
        OPTIONS='-lm -lpthread' && gmake -j"$ncpu" so && gmake install-dll install-headers) &&
        $CC $CFLAGS -I"$3/include" -o "$3/bin/speedtest1" "$2/test/speedtest1.c" $LDFLAGS -lsqlite3 -lm -lpthread
}
so_sqlite3() { echo "lib/libsqlite3.so.0"; }
m_sqlite3() {
    if cpuset -l "$last" "$2/bin/speedtest1" --size 40 --memdb > "$W/st1.out" 2>&1; then
        record sqlite3 "speedtest1 --size 40 --memdb: TOTAL" s lower "$1" "$(sed -n -E 's/^ *TOTAL\.+ *([0-9.]+)s.*/\1/p' "$W/st1.out" | tail -n 1)"
    else say "sqlite3 $1: speedtest1 failed: $(tail -n 3 "$W/st1.out" | tr '\n' ' ')"; fi
    rm -f "$W/st1.db"*
    T sqlite3 "speedtest1 --size 20 (a file, no sync)" "$1" "$2/bin/speedtest1" --size 20 --nosync "$W/st1.db"
}

# ---- text
f_libxml2() { fetch libxml2-2.15.4.tar.xz 98087fd181d9070724f3fbc65c7377db03038eb92bd882374daff44940138821 \
    "$DC/gnome/libxml2-2.15.4.tar.xz" https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.4.tar.xz && V=2.15.4 A=libxml2-2.15.4.tar.xz; }
b_libxml2() { ac "$2" "$3" --without-python --without-icu --without-lzma --without-zlib --without-readline --without-history; }
so_libxml2() { echo "lib/libxml2.so.16"; }
m_libxml2() {
    x="$2/bin/xmllint"
    T libxml2 "xmllint --noout (parse, 40 MB)" "$1" "$x" --noout "$W/in/big.xml"
    T libxml2 "xmllint --stream (reader)" "$1" "$x" --stream --noout "$W/in/big.xml"
    T libxml2 "xmllint --format (parse, serialize)" "$1" "$x" --format "$W/in/big.xml"
    T libxml2 "xmllint --xpath (count of a predicate)" "$1" "$x" --noout --xpath 'count(//*[local-name()="item"][@price > 250])' "$W/in/big.xml"
    T libxml2 "xmllint --html (parse, 10 MB)" "$1" "$x" --html --noout "$W/in/big.html"
}
f_libxslt() { fetch libxslt-1.1.45.tar.xz 9acfe68419c4d06a45c550321b3212762d92f41465062ca4ea19e632ee5d216e \
    "$DC/gnome/libxslt-1.1.45.tar.xz" https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.45.tar.xz && V=1.1.45 A=libxslt-1.1.45.tar.xz; }
b_libxslt() { ac "$2" "$3" --without-python --without-crypto --without-plugins --with-libxml-prefix=/usr/local; }
so_libxslt() { echo "lib/libxslt.so.1"; }
m_libxslt() { T libxslt "xsltproc lb.xsl (keys, sort, strings; 20 MB)" "$1" "$2/bin/xsltproc" "$D/lb.xsl" "$W/in/mid.xml"; }
f_expat() { fetch expat-2.11.0.tar.xz 61e7614b602201c28a189dafee78f5bceaee192bbde46a930752ff09cf5542fa \
    https://github.com/libexpat/libexpat/releases/download/R_2_11_0/expat-2.11.0.tar.xz "$DC/expat-2.11.0.tar.xz" && V=2.11.0 A=expat-2.11.0.tar.xz; }
b_expat() { ac "$2" "$3" --without-docbook --without-examples --without-tests; }
so_expat() { echo "lib/libexpat.so.1"; }
m_expat() {
    TN 4 expat "xmlwf (parse, 40 MB)" "$1" "$2/bin/xmlwf" "$W/in/big.xml"
    TN 4 expat "xmlwf -n (namespaces)" "$1" "$2/bin/xmlwf" -n "$W/in/big.xml"
}
f_tidy() { fetch tidy-html5-5.8.0.tar.gz 59c86d5b2e452f63c5cdb29c866a12a4c55b1741d7025cf2f3ce0cde99b0660e \
    "$DC/htacg-tidy-html5-5.8.0_GH0.tar.gz" https://codeload.github.com/htacg/tidy-html5/tar.gz/5.8.0 && V=5.8.0 A=tidy-html5-5.8.0.tar.gz; }
b_tidy() { cm "$2" "$3" -DBUILD_SHARED_LIB=ON -DSUPPORT_CONSOLE_APP=ON -DTIDY_CONSOLE_SHARED=ON -DSUPPORT_LOCALIZATIONS=OFF; }
so_tidy() { echo "lib/libtidy.so.5"; }
m_tidy() {
    T tidy "tidy -asxhtml (3 MB)" "$1" -x 2 "$2/bin/tidy" -q -asxhtml --show-warnings no "$W/in/tidy.html"
    T tidy "tidy -indent --wrap 80 (3 MB)" "$1" -x 2 "$2/bin/tidy" -q -indent --wrap 80 --show-warnings no "$W/in/tidy.html"
}
f_libyaml() { fetch yaml-0.2.7.tar.gz 0c39256b8be0fc689f5c7bfdea1bc9f3fb1fd648468fd3cc6fd375e09ffb6f13 \
    https://github.com/yaml/libyaml/releases/download/0.2.7/yaml-0.2.7.tar.gz "$DC/yaml-0.2.7.tar.gz" && V=0.2.7 A=yaml-0.2.7.tar.gz; }
b_libyaml() { ac "$2" "$3" && drv "$1" "$3" d-yaml.c -lyaml; }
so_libyaml() { echo "lib/libyaml-0.so.2"; }
m_libyaml() { DRV libyaml "$1" "$2/bin/d-yaml" "$W/in/in.yaml"; }
f_oniguruma() { fetch onig-6.9.10.tar.gz 2a5cfc5ae259e4e97f86b68dfffc152cdaffe94e2060b770cb827238d769fc05 \
    https://github.com/kkos/oniguruma/releases/download/v6.9.10/onig-6.9.10.tar.gz "$DC/onig-6.9.10.tar.gz" && V=6.9.10 A=onig-6.9.10.tar.gz; }
b_oniguruma() { cm "$2" "$3" -DBUILD_TEST=OFF -DENABLE_POSIX_API=ON && drv "$1" "$3" d-onig.c -lonig; }
so_oniguruma() { echo "lib/libonig.so.5"; }
m_oniguruma() { DRV oniguruma "$1" "$2/bin/d-onig" "$W/in/text.txt"; }
f_pcre() { fetch pcre-8.45.tar.bz2 4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8 \
    "$DC/pcre-8.45.tar.bz2" https://downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.bz2 && V=8.45 A=pcre-8.45.tar.bz2; }
b_pcre() { ac "$2" "$3" --enable-utf --enable-unicode-properties --enable-jit --disable-cpp && drv "$1" "$3" d-pcre.c -lpcre; }
so_pcre() { echo "lib/libpcre.so.1"; }
m_pcre() { DRV pcre "$1" "$2/bin/d-pcre" "$W/in/text.txt"; }
f_pcre2() { fetch pcre2-10.49.tar.bz2 53c156e1ba416a20da8e65395daa132da0d80e76910424caca3fcdae7831d384 \
    https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2 "$DC/pcre2-10.49.tar.bz2" && V=10.49 A=pcre2-10.49.tar.bz2; }
b_pcre2() { ac "$2" "$3" --enable-jit && drv "$1" "$3" d-pcre2.c -lpcre2-8; }
so_pcre2() { echo "lib/libpcre2-8.so.0"; }
m_pcre2() { DRV pcre2 "$1" "$2/bin/d-pcre2" "$W/in/text.txt"; }
f_icu() { fetch icu4c-76_1-src.tgz dfacb46bfe4747410472ce3e1144bf28a102feeaa4e3875bac9b4c6cf30f4f3e \
    https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz "$DC/icu4c-76_1-src.tgz" && V=76.1 A=icu4c-76_1-src.tgz; }
b_icu() {
    ac "$2/source" "$3" --with-data-packaging=library --disable-layoutex --disable-tests --disable-samples --disable-extras &&
        drv "$1" "$3" d-icu.c -licui18n -licuuc -licudata
}
so_icu() { echo "lib/libicui18n.so.76"; }
m_icu() { DRV icu "$1" "$2/bin/d-icu" "$W/in/text.txt"; }

# ---- image
f_png() { fetch libpng-1.6.59.tar.xz d80dd2a38a37f803cb9b6ac7b14bd6e74ddc3b654780a8380bdf93523fdb4389 \
    "$DC/libpng-1.6.59.tar.xz" https://downloads.sourceforge.net/project/libpng/libpng16/1.6.59/libpng-1.6.59.tar.xz && V=1.6.59 A=libpng-1.6.59.tar.xz; }
b_png() { cm "$2" "$3" -DPNG_SHARED=ON -DPNG_STATIC=OFF -DPNG_TESTS=OFF -DPNG_TOOLS=OFF && drv "$1" "$3" d-png.c -lpng16 -lz; }
so_png() { echo "lib/libpng16.so.16"; }
m_png() { DRV png "$1" "$2/bin/d-png" "$W/in/in.ppm"; }
f_mozjpeg() { fetch mozjpeg-4.1.5.tar.gz 9fcbb7171f6ac383f5b391175d6fb3acde5e64c4c4727274eade84ed0998fcc1 \
    "$DC/mozilla-mozjpeg-v4.1.5_GH0.tar.gz" https://codeload.github.com/mozilla/mozjpeg/tar.gz/v4.1.5 && V=4.1.5 A=mozjpeg-4.1.5.tar.gz; }
b_mozjpeg() {
    cm "$2" "$3" -DENABLE_SHARED=ON -DENABLE_STATIC=OFF -DWITH_JPEG8=ON -DWITH_SIMD=ON -DREQUIRE_SIMD=ON \
        -DWITH_ARITH_DEC=OFF -DWITH_ARITH_ENC=OFF -DWITH_12BIT=OFF -DWITH_JAVA=OFF -DWITH_TURBOJPEG=OFF -DPNG_SUPPORTED=OFF \
        -DWITH_MEM_SRCDST=ON -DFORCE_INLINE=ON -DCMAKE_INSTALL_LIBDIR="$3/lib" -DCMAKE_INSTALL_INCLUDEDIR="$3/include" \
        -DCMAKE_INSTALL_BINDIR="$3/bin" -DCMAKE_INSTALL_MANDIR="$3/share/man" -DCMAKE_INSTALL_DOCDIR="$3/share/doc/mozjpeg"
}
so_mozjpeg() { echo "lib/libjpeg.so.8"; }
m_mozjpeg() {
    TN 4 mozjpeg "cjpeg -quality 85 (mozjpeg: progressive, trellis; 3 MP)" "$1" "$2/bin/cjpeg" -quality 85 -outfile "$W/o.jpg" "$W/in/small.ppm"
    TN 10 mozjpeg "cjpeg -quality 85 -revert (baseline, libjpeg-turbo; 12 MP)" "$1" "$2/bin/cjpeg" -quality 85 -revert -outfile "$W/o.jpg" "$W/in/in.ppm"
    TN 10 mozjpeg "djpeg progressive (12 MP)" "$1" "$2/bin/djpeg" -outfile /dev/null "$W/in/prog.jpg"
    TN 10 mozjpeg "djpeg baseline (12 MP)" "$1" "$2/bin/djpeg" -outfile /dev/null "$W/in/base.jpg"
    TN 20 mozjpeg "djpeg -scale 1/4 (12 MP)" "$1" "$2/bin/djpeg" -scale 1/4 -outfile /dev/null "$W/in/base.jpg"
}
f_webp() { fetch libwebp-1.6.0.tar.gz e4ab7009bf0629fd11982d4c2aa83964cf244cffba7347ecd39019a9e38c4564 \
    https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.6.0.tar.gz "$DC/libwebp-1.6.0.tar.gz" && V=1.6.0 A=libwebp-1.6.0.tar.gz; }
b_webp() {
    ac "$2" "$3" --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --disable-gl --disable-sdl \
        --disable-png --disable-jpeg --disable-tiff --disable-gif --disable-wic
}
so_webp() { echo "lib/libwebp.so.7"; }
m_webp() {
    TN 4 webp "cwebp -q 75 -m 4 (3 MP)" "$1" "$2/bin/cwebp" -quiet -q 75 -m 4 "$W/in/small.ppm" -o "$W/o.webp"
    TN 3 webp "cwebp -q 75 -m 6 (3 MP)" "$1" "$2/bin/cwebp" -quiet -q 75 -m 6 "$W/in/small.ppm" -o "$W/o.webp"
    T webp "cwebp -lossless -q 50 -m 3 (3 MP)" "$1" "$2/bin/cwebp" -quiet -lossless -q 50 -m 3 "$W/in/small.ppm" -o "$W/o.webp"
    TN 10 webp "dwebp lossy (12 MP)" "$1" "$2/bin/dwebp" -quiet "$W/in/lossy.webp" -ppm -o /dev/null
    TN 10 webp "dwebp lossless (3 MP)" "$1" "$2/bin/dwebp" -quiet "$W/in/lossless.webp" -ppm -o /dev/null
}
f_gd() { fetch libgd-2.3.3.tar.xz 3fe822ece20796060af63b7c60acb151e5844204d289da0ce08f8fdf131e5a61 \
    https://github.com/libgd/libgd/releases/download/gd-2.3.3/libgd-2.3.3.tar.xz "$DC/libgd-2.3.3.tar.xz" && V=2.3.3 A=libgd-2.3.3.tar.xz; }
b_gd() {
    ac "$2" "$3" --with-zlib --without-png --without-jpeg --without-webp --without-freetype --without-fontconfig \
        --without-xpm --without-x --without-tiff --without-avif --without-heif --without-raqm --without-liq &&
        drv "$1" "$3" d-gd.c -lgd
}
so_gd() { echo "lib/libgd.so.3"; }
m_gd() { DRV gd "$1" "$2/bin/d-gd" "$W/in/in.ppm"; }
f_lcms2() { fetch lcms2-2.20.tar.gz 18ff5504fa9cc8a2b1f3591180d90ead16c8a2ea78e530523b46eab70e1ca6b9 \
    https://github.com/mm2/Little-CMS/releases/download/lcms2.20/lcms2-2.20.tar.gz "$DC/lcms2-2.20.tar.gz" && V=2.20 A=lcms2-2.20.tar.gz; }
b_lcms2() { ac "$2" "$3" --without-jpeg --without-tiff && drv "$1" "$3" d-lcms2.c -llcms2; }
so_lcms2() { echo "lib/liblcms2.so.2"; }
m_lcms2() { DRV lcms2 "$1" "$2/bin/d-lcms2" "$W/in/in.ppm"; }
f_tiff() { fetch tiff-4.7.2.tar.xz 4996f0c4f93094719b1ca5c6279b20e588773ba8a247533e486416fb662ddb88 \
    "$DC/tiff-4.7.2.tar.xz" https://download.osgeo.org/libtiff/tiff-4.7.2.tar.xz && V=4.7.2 A=tiff-4.7.2.tar.xz; }
b_tiff() {
    ac "$2" "$3" --disable-jpeg --disable-old-jpeg --disable-webp --disable-zstd --disable-lzma --disable-jbig --disable-lerc \
        --disable-libdeflate --disable-docs --disable-tests --disable-cxx --disable-contrib &&
        drv "$1" "$3" d-tiff.c -ltiff
}
so_tiff() { echo "lib/libtiff.so.6"; }
m_tiff() { (cd "$W" && DRV tiff "$1" "$2/bin/d-tiff" "$W/in/in.ppm"); }
f_freetype2() { fetch freetype-2.15.0.tar.xz 93cd47eb719c325107f2d3cf087d06299e944c3b48a40b55537302304dea1dd5 \
    https://download.savannah.gnu.org/releases/freetype/freetype-2.15.0.tar.xz https://downloads.sourceforge.net/project/freetype/freetype2/2.15.0/freetype-2.15.0.tar.xz && V=2.15.0 A=freetype-2.15.0.tar.xz; }
b_freetype2() {
    cm "$2" "$3" -DFT_REQUIRE_ZLIB=ON -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_PNG=ON -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BROTLI=ON &&
        drv "$1" "$3" d-ft.c -I"$3/include/freetype2" -lfreetype
}
so_freetype2() { echo "lib/libfreetype.so.6"; }
m_freetype2() { DRV freetype2 "$1" "$2/bin/d-ft" "$FONT"; }
f_harfbuzz() { fetch harfbuzz-15.0.0.tar.xz 968536e9abd782f07f7954044c0c4020199fcdd39b41d221ec42d2a3be4a44df \
    https://github.com/harfbuzz/harfbuzz/releases/download/15.0.0/harfbuzz-15.0.0.tar.xz "$DC/harfbuzz-15.0.0.tar.xz" && V=15.0.0 A=harfbuzz-15.0.0.tar.xz; }
b_harfbuzz() {
    ms "$2" "$3" -Dglib=enabled -Dgobject=disabled -Dcairo=disabled -Dchafa=disabled -Dicu=disabled -Dgraphite2=disabled \
        -Dfreetype=enabled -Dtests=disabled -Ddocs=disabled -Dintrospection=disabled -Dutilities=enabled -Dbenchmark=disabled \
        -Dsubset=disabled -Draster=disabled -Dvector=disabled -Dgpu=disabled -Dpng=disabled -Dzlib=disabled
}
so_harfbuzz() { echo "lib/libharfbuzz.so.0"; }
m_harfbuzz() {
    T harfbuzz "hb-shape (ot funcs), 2 MB of Latin and Cyrillic lines" "$1" "$2/bin/hb-shape" --font-file="$FONT" --font-funcs=ot \
        --text-file="$W/in/shape.txt" --output-file=/dev/null --no-glyph-names
    T harfbuzz "hb-shape (ft funcs), 2 MB of Latin and Cyrillic lines" "$1" "$2/bin/hb-shape" --font-file="$FONT" --font-funcs=ft \
        --text-file="$W/in/shape.txt" --output-file=/dev/null --no-glyph-names
}
f_fontconfig() { fetch fontconfig-2.18.4.tar.xz 95013637eff5f81d4871dd16cd098c273264c16d0f9f0b27cc43b81b2794bee3 \
    https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/2.18.4/fontconfig-2.18.4.tar.xz && V=2.18.4 A=fontconfig-2.18.4.tar.xz; }
b_fontconfig() {
    ms "$2" "$3" --sysconfdir="$3/etc" --localstatedir=/var -Ddoc=disabled -Dtests=disabled -Dtools=disabled \
        -Dnls=disabled -Dcache-build=disabled -Dcache-dir=/var/db/fontconfig -Ddefault-fonts-dirs=/usr/local/share/fonts &&
        drv "$1" "$3" d-fc.c -lfontconfig
}
so_fontconfig() { echo "lib/libfontconfig.so.1"; }
m_fontconfig() { FONTCONFIG_FILE=/usr/local/etc/fonts/fonts.conf; export FONTCONFIG_FILE; DRV fontconfig "$1" "$2/bin/d-fc"; unset FONTCONFIG_FILE; }
f_pixman() { fetch pixman-0.46.4.tar.xz a098c33924754ad43f981b740f6d576c70f9ed1006e12221b1845431ebce1239 \
    "$DC/pixman-0.46.4.tar.xz" https://www.cairographics.org/releases/pixman-0.46.4.tar.xz && V=0.46.4 A=pixman-0.46.4.tar.xz; }
b_pixman() {
    ms "$2" "$3" -Dtests=enabled -Ddemos=disabled -Dgtk=disabled -Dlibpng=disabled -Dopenmp=disabled &&
        ninja -C "$2/_lb" test/lowlevel-blt-bench && mkdir -p "$3/bin" && cp "$2/_lb/test/lowlevel-blt-bench" "$3/bin/"
}
so_pixman() { echo "lib/libpixman-1.so.0"; }
m_pixman() {
    for op in over_8888_8888 add_8888_8888 over_n_8_8888 src_8888_0565 over_n_8888_8888_ca over_8888_8_8888; do
        cpuset -l "$last" "$2/bin/lowlevel-blt-bench" -m 10000 "$op" > "$W/llbb.out" 2>&1 || { say "pixman $op $1: failed"; continue; }
        for k in L1 M R; do
            record pixman "$op $k" Mpixps higher "$1" "$(sed -n -E "s/.* $k: *([0-9.]+).*/\1/p" "$W/llbb.out" | head -n 1)"
        done
    done
}
f_cairo() { fetch cairo-1.18.6.tar.xz 1c767308174337a74694da0f3ec069c271452163a1ef4540964c50c301f157d4 \
    "$DC/cairo-1.18.6.tar.xz" https://www.cairographics.org/releases/cairo-1.18.6.tar.xz && V=1.18.6 A=cairo-1.18.6.tar.xz; }
b_cairo() {
    ms "$2" "$3" -Dtests=disabled -Dxlib=disabled -Dxcb=disabled -Dpng=disabled -Dfreetype=disabled -Dfontconfig=disabled \
        -Dglib=disabled -Dspectre=disabled -Dsymbol-lookup=disabled -Dzlib=disabled -Dgtk_doc=false &&
        drv "$1" "$3" d-cairo.c -I"$3/include/cairo" -lcairo
}
so_cairo() { echo "lib/libcairo.so.2"; }
m_cairo() { DRV cairo "$1" "$2/bin/d-cairo"; }
f_fribidi() { fetch fribidi-1.0.18.tar.xz 1de5e8073d035388b71d0b2d452b1da1f8caeea8a7702997b401fe1b6250727f \
    https://github.com/fribidi/fribidi/releases/download/v1.0.18/fribidi-1.0.18.tar.xz "$DC/fribidi-1.0.18.tar.xz" && V=1.0.18 A=fribidi-1.0.18.tar.xz; }
b_fribidi() { ms "$2" "$3" -Ddocs=false -Dtests=false -Dbin=true; }
so_fribidi() { echo "lib/libfribidi.so.0"; }
m_fribidi() {
    T fribidi "fribidi --nopad (Hebrew, Arabic, Latin; 8 MB)" "$1" "$2/bin/fribidi" --nopad --nobreak "$W/in/bidi.txt"
    T fribidi "fribidi --charset UTF-8 --rtl --levels" "$1" "$2/bin/fribidi" --nopad --nobreak --rtl --levels "$W/in/bidi.txt"
}

# ---- video
f_x264() { fetch x264-00852f599572.tar.gz b50a394f63fa9d59bb3cb2344444d91ab5d2571a83ee2a17a550f6346a6b3612 \
    "$DC/meson-ports-x264-00852f599572d10798b2dafd2c5286213d0ce795_GL0.tar.gz" \
    https://gitlab.freedesktop.org/gstreamer/meson-ports/x264/-/archive/00852f599572d10798b2dafd2c5286213d0ce795/x264-00852f599572d10798b2dafd2c5286213d0ce795.tar.gz &&
    V=0.165.3223 A=x264-00852f599572.tar.gz; }
b_x264() {
    # the version and the commit, not version.py of git (as multimedia/x264/files/patch-meson.build)
    sed -i '' -e "s|run_command(find_program('version.py'), '--package-version', check: true).stdout().strip()|'0.165.3223'|" \
        -e "s|run_command(find_program('version.py'), '--commit-hash', check: true).stdout().strip()|'00852f599572d10798b2dafd2c5286213d0ce795'|" \
        "$2/meson.build" && ! grep -q "version.py" "$2/meson.build" && ms "$2" "$3" -Dcli=true -Dasm=enabled -Db_lto=true
}
so_x264() { echo "lib/libx264.so.165"; }
m_x264() {
    T x264 "--preset medium --threads 1 (720p, 60 frames)" "$1" "$2/bin/x264" --preset medium --threads 1 --no-progress -o /dev/null "$W/in/v720.y4m"
    T x264 "--preset veryfast --threads 1 (720p, 60 frames)" "$1" "$2/bin/x264" --preset veryfast --threads 1 --no-progress -o /dev/null "$W/in/v720.y4m"
    T x264 "--preset slow --crf 20 --threads 1 (720p, 20 frames)" "$1" "$2/bin/x264" --preset slow --crf 20 --frames 20 --threads 1 --no-progress -o /dev/null "$W/in/v720.y4m"
}
f_dav1d() { fetch dav1d-1.5.5.tar.bz2 afc5378daba30eafd11d7b4f0ec863270d7b175f38393a2e1e0ff76f3a45c8b9 \
    https://code.videolan.org/videolan/dav1d/-/archive/1.5.5/dav1d-1.5.5.tar.bz2 "$DC/dav1d-1.5.5.tar.bz2" \
    https://downloads.videolan.org/pub/videolan/dav1d/1.5.5/dav1d-1.5.5.tar.bz2 && V=1.5.5 A=dav1d-1.5.5.tar.bz2; }
b_dav1d() { ms "$2" "$3" -Denable_tools=true -Denable_tests=false -Denable_examples=false; }
so_dav1d() { echo "lib/libdav1d.so.7"; }
m_dav1d() {
    T dav1d "dav1d --threads 1 (720p, 120 frames)" "$1" "$2/bin/dav1d" -q --threads 1 -i "$W/in/v720.ivf" --muxer null -o /dev/null
    T dav1d "dav1d --threads 1 --filmgrain 0" "$1" "$2/bin/dav1d" -q --threads 1 --filmgrain 0 -i "$W/in/v720.ivf" --muxer null -o /dev/null
}
f_svtav1() { fetch SVT-AV1-4.3.1.tar.gz ad94f481cb74821af183f37f4533fc52324b76ffbd98ec7723e282bab0cf9fc4 \
    https://github.com/AOMediaCodec/SVT-AV1/archive/v4.3.1/SVT-AV1-4.3.1.tar.gz && V=4.3.1 A=SVT-AV1-4.3.1.tar.gz; }
b_svtav1() { cm "$2" "$3" -DBUILD_APPS=ON -DBUILD_DEC=OFF -DBUILD_TESTING=OFF -DNATIVE=OFF -DEXCLUDE_HASH=ON -DENABLE_NASM=ON; }
so_svtav1() { echo "lib/libSvtAv1Enc.so.4"; }
m_svtav1() {
    T svtav1 "--preset 8 --lp 1 (720p, 30 frames)" "$1" "$2/bin/SvtAv1EncApp" --preset 8 --lp 1 -n 30 --progress 0 -i "$W/in/v720.y4m" -b /dev/null
    T svtav1 "--preset 10 --lp 1 (720p, 60 frames)" "$1" "$2/bin/SvtAv1EncApp" --preset 10 --lp 1 --progress 0 -i "$W/in/v720.y4m" -b /dev/null
    T svtav1 "--preset 12 --lp 1 (720p, 60 frames)" "$1" "$2/bin/SvtAv1EncApp" --preset 12 --lp 1 --progress 0 -i "$W/in/v720.y4m" -b /dev/null
}
f_libde265() { fetch libde265-1.1.3.tar.gz 554228bd17788c99a7e63b37ab5634722190e6e2bf60c1dcb01cef328e133905 \
    https://github.com/strukturag/libde265/releases/download/v1.1.3/libde265-1.1.3.tar.gz && V=1.1.3 A=libde265-1.1.3.tar.gz; }
b_libde265() { cm "$2" "$3" -DENABLE_ENCODER=OFF -DENABLE_DECODER=ON -DENABLE_SDL=OFF -DENABLE_INTERNAL_DEVELOPMENT_TOOLS=OFF; }
so_libde265() { echo "lib/libde265.so.0"; }
m_libde265() {
    T libde265 "dec265 (720p HEVC, 120 frames, no threads)" "$1" "$2/bin/dec265" -q -t 0 "$W/in/v720.hevc"
    T libde265 "dec265 --disable-deblocking --disable-sao" "$1" "$2/bin/dec265" -q -t 0 --disable-deblocking --disable-sao "$W/in/v720.hevc"
}
f_libheif() { fetch libheif-1.23.7.tar.gz f7483e818503ea6224c8863e4a56ac02c7089021a98472c811c12aa19faf2475 \
    https://github.com/strukturag/libheif/releases/download/v1.23.7/libheif-1.23.7.tar.gz "$DC/libheif-1.23.7.tar.gz" && V=1.23.7 A=libheif-1.23.7.tar.gz; }
b_libheif() {
    cm "$2" "$3" -DBUILD_TESTING=OFF -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON \
        -DBUILD_DOCUMENTATION=OFF -DWITH_EXAMPLES=ON -DWITH_GDK_PIXBUF=OFF -DENABLE_PLUGIN_LOADING=OFF \
        -DWITH_LIBSHARPYUV=OFF -DWITH_FUZZERS=OFF -DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF -DWITH_DAV1D=ON \
        -DWITH_DAV1D_PLUGIN=OFF -DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF -DWITH_X265=ON -DWITH_X265_PLUGIN=OFF \
        -DWITH_X264=OFF -DWITH_RAV1E=OFF -DWITH_SvtEnc=ON -DWITH_SvtEnc_PLUGIN=OFF -DWITH_FFMPEG_DECODER=OFF \
        -DWITH_OpenH264_DECODER=OFF -DWITH_OpenH264_ENCODER=OFF -DWITH_JPEG_DECODER=OFF -DWITH_JPEG_ENCODER=OFF \
        -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF -DWITH_OPENJPH_DECODER=OFF -DWITH_OPENJPH_ENCODER=OFF \
        -DWITH_KVAZAAR=OFF -DWITH_UVG266=OFF -DWITH_VVDEC=OFF -DWITH_VVENC=OFF -DWITH_UNCOMPRESSED_CODEC=OFF &&
        drv "$1" "$3" d-heif.c -lheif
}
so_libheif() { echo "lib/libheif.so.1"; }
m_libheif() { DRV libheif "$1" "$2/bin/d-heif" -n 4 "$W/in/still.heic"; DRV libheif "$1" "$2/bin/d-heif" -n 24 "$W/in/still.avif"; }

# ---- net
f_curl() { fetch curl-8.23.0.tar.xz 8dadd7d2536a314f982ad05a651b713f426bf7d02cc2c76cffb9796f2218e6c5 \
    https://curl.se/download/curl-8.23.0.tar.xz https://github.com/curl/curl/releases/download/curl-8_23_0/curl-8.23.0.tar.xz \
    "$DC/azsupport/curl-8.23.0.tar.xz" && V=8.23.0 A=curl-8.23.0.tar.xz; }
b_curl() {
    ac "$2" "$3" --with-openssl --without-libpsl --without-libidn2 --without-nghttp2 --without-brotli --without-zstd \
        --without-libssh2 --disable-ldap --disable-docs --disable-manual --without-ca-bundle && drv "$1" "$3" d-curl.c -lcurl
}
so_curl() { echo "lib/libcurl.so.4"; }
m_curl() { DRV curl "$1" "$2/bin/d-curl" "$W/in/urls.txt"; }
f_c_ares() { fetch c-ares-1.34.9.tar.gz 9364b70a12eb59a06830fb488d9357f90100dff0d98b23ea3593a183d43e6f2f \
    https://github.com/c-ares/c-ares/releases/download/v1.34.9/c-ares-1.34.9.tar.gz && V=1.34.9 A=c-ares-1.34.9.tar.gz; }
b_c_ares() { cm "$2" "$3" -DCARES_STATIC=OFF -DCARES_SHARED=ON -DCARES_BUILD_TOOLS=OFF -DCARES_BUILD_TESTS=OFF && drv "$1" "$3" d-ares.c -lcares; }
so_c_ares() { echo "lib/libcares.so.2"; }
m_c_ares() { DRV c-ares "$1" "$2/bin/d-ares"; }
f_nghttp2() { fetch nghttp2-1.71.0.tar.xz c0f55121d88650e4b9227aec28cebaf664d2417ca60fe70be0f8d38829f52116 \
    https://github.com/nghttp2/nghttp2/releases/download/v1.71.0/nghttp2-1.71.0.tar.xz && V=1.71.0 A=nghttp2-1.71.0.tar.xz; }
b_nghttp2() { cm "$2" "$3" -DENABLE_LIB_ONLY=ON -DBUILD_STATIC_LIBS=OFF -DBUILD_TESTING=OFF && drv "$1" "$3" d-nghttp2.c -lnghttp2; }
so_nghttp2() { echo "lib/libnghttp2.so.14"; }
m_nghttp2() { DRV nghttp2 "$1" "$2/bin/d-nghttp2"; }
f_libidn2() { fetch libidn2-2.3.8.tar.gz f557911bf6171621e1f72ff35f5b1825bb35b52ed45325dcdee931e5d3c0787a \
    https://ftp.gnu.org/gnu/libidn/libidn2-2.3.8.tar.gz https://ftpmirror.gnu.org/libidn/libidn2-2.3.8.tar.gz "$DC/libidn2-2.3.8.tar.gz" && V=2.3.8 A=libidn2-2.3.8.tar.gz; }
b_libidn2() { ac "$2" "$3" --disable-doc --disable-nls --with-included-libunistring --disable-valgrind-tests && drv "$1" "$3" d-idn2.c -lidn2; }
so_libidn2() { echo "lib/libidn2.so.0"; }
m_libidn2() { DRV libidn2 "$1" "$2/bin/d-idn2" "$W/in/domains.txt"; }
f_libpsl() { fetch libpsl-0.23.3.tar.lz 9e60f70c9806f5e3f36581e9c05e9d817767953da3428c08e0ed9b9ad321d444 \
    https://github.com/rockdaboot/libpsl/releases/download/0.23.3/libpsl-0.23.3.tar.lz && V=0.23.3 A=libpsl-0.23.3.tar.lz; }
b_libpsl() { ac "$2" "$3" --enable-builtin --disable-runtime --disable-man --disable-gtk-doc && drv "$1" "$3" d-psl.c -lpsl; }
so_libpsl() { echo "lib/libpsl.so.5"; }
m_libpsl() { DRV libpsl "$1" "$2/bin/d-psl" "$W/in/domains.txt"; }
f_libuv() { fetch libuv-v1.53.0-dist.tar.gz 21425fa398be98b51181a1885df31428092d5435c4373a396351e427322e5f1b \
    https://dist.libuv.org/dist/v1.53.0/libuv-v1.53.0-dist.tar.gz && V=1.53.0 A=libuv-v1.53.0-dist.tar.gz; }
b_libuv() { ac "$2" "$3" --disable-maintainer-mode cc_cv_cflags_werror__g=no && drv "$1" "$3" d-uv.c -luv; }
so_libuv() { echo "lib/libuv.so.1"; }
m_libuv() { DRV libuv "$1" "$2/bin/d-uv"; }
f_apr() { fetch apr-1.7.6.tar.bz2 49030d92d2575da735791b496dc322f3ce5cff9494779ba8cc28c7f46c5deb32 \
    "$DC/apr-1.7.6.tar.bz2" https://archive.apache.org/dist/apr/apr-1.7.6.tar.bz2 && V=1.7.6 A=apr-1.7.6.tar.bz2; }
b_apr() { ac "$2" "$3" --enable-threads && drv "$1" "$3" d-apr.c -I"$3/include/apr-1" -lapr-1; }
so_apr() { echo "lib/libapr-1.so.0"; }
m_apr() { DRV apr "$1" "$2/bin/d-apr"; }
f_libmaxminddb() { fetch libmaxminddb-1.14.1.tar.gz ca5c87d41339f8bc4daabb53e8a9356b3c995f2d2419b85d7bff823b2ecc252d \
    https://github.com/maxmind/libmaxminddb/releases/download/1.14.1/libmaxminddb-1.14.1.tar.gz && V=1.14.1 A=libmaxminddb-1.14.1.tar.gz; }
b_libmaxminddb() { ac "$2" "$3" --disable-tests && drv "$1" "$3" d-mmdb.c -lmaxminddb && cp "$2/t/maxmind-db/test-data/GeoLite2-City-Test.mmdb" "$W/in/city.mmdb"; }
so_libmaxminddb() { echo "lib/libmaxminddb.so.0"; }
m_libmaxminddb() { DRV libmaxminddb "$1" "$2/bin/d-mmdb" "$W/in/city.mmdb" "$W/in/ips.txt"; }
f_libmemcached() { fetch libmemcached-1.2.0.tar.gz c42a29e9898ae2827b83d81e9a58ae9fa2889d9e72da79886920ba2d7e67df08 \
    "$DC/awesomized-libmemcached-1.2.0_GH0.tar.gz" https://codeload.github.com/awesomized/libmemcached/tar.gz/1.2.0 && V=1.2.0 A=libmemcached-1.2.0.tar.gz; }
b_libmemcached() {
    cm "$2" "$3" -DENABLE_SASL=OFF -DBUILD_TESTING=OFF -DBUILD_DOCS=OFF -DBUILD_DOCSONLY=OFF -DENABLE_HASH_FNV64=ON \
        -DENABLE_HASH_HSIEH=ON -DENABLE_HASH_MURMUR=ON -DENABLE_MEMASLAP=OFF && drv "$1" "$3" d-hashkit.c -lmemcached -lhashkit
}
so_libmemcached() { echo "lib/libhashkit.so.2"; }
m_libmemcached() { DRV libmemcached "$1" "$2/bin/d-hashkit"; }
f_simdjson() { fetch simdjson-5.3.0.tar.gz 5e59df8bd3fa760937e6a2ca68193399c85b52b5042716700b149a734737dced \
    "$DC/simdjson-simdjson-v5.3.0_GH0.tar.gz" https://codeload.github.com/simdjson/simdjson/tar.gz/v5.3.0 && V=5.3.0 A=simdjson-5.3.0.tar.gz; }
b_simdjson() {
    cm "$2" "$3" -DSIMDJSON_DEVELOPER_MODE=OFF -DSIMDJSON_BUILD_STATIC_LIB=OFF && drv "$1" "$3" d-simdjson.cc -std=c++17 -lsimdjson &&
        cp "$2/jsonexamples/twitter.json" "$2/jsonexamples/citm_catalog.json" "$W/in/"
}
so_simdjson() { echo "lib/libsimdjson.so.30"; }
m_simdjson() { DRV simdjson "$1" "$2/bin/d-simdjson" -n 3000 "$W/in/twitter.json" "$W/in/citm_catalog.json"; }
f_libada() { fetch ada-4.1.1.tar.gz ed818cfe260ec063e1f1d93fdafca4d158162ba515369bef085adc366a03a41c \
    "$DC/ada-url-ada-v4.1.1_GH0.tar.gz" https://codeload.github.com/ada-url/ada/tar.gz/v4.1.1 && V=4.1.1 A=ada-4.1.1.tar.gz; }
b_libada() { cm "$2" "$3" -DADA_TESTING=OFF -DADA_TOOLS=OFF -DADA_BENCHMARKS=OFF && drv "$1" "$3" d-ada.cc -std=c++20 -lada; }
so_libada() { echo "lib/libada.so.4"; }
m_libada() { DRV libada "$1" "$2/bin/d-ada" "$W/in/urls.txt"; }
f_llhttp() { fetch llhttp-9.4.4.tar.gz 5600adb1498f82a9c719b8eb19310021737388e0d92362a6d47be532710d3c96 \
    "$DC/nodejs-llhttp-release-v9.4.4_GH0.tar.gz" https://codeload.github.com/nodejs/llhttp/tar.gz/release/v9.4.4 && V=9.4.4 A=llhttp-9.4.4.tar.gz; }
b_llhttp() { cm "$2" "$3" -DBUILD_STATIC_LIBS=OFF && drv "$1" "$3" d-llhttp.c -lllhttp; }
so_llhttp() { echo "lib/libllhttp.so.9.4"; }
m_llhttp() { DRV llhttp "$1" "$2/bin/d-llhttp" "$W/in/http.txt"; }

# --------------------------------------------------------------- inputs of the groups
FONT=/usr/local/share/fonts/dejavu/DejaVuSans.ttf
inputs() {
    G="$W/gen"
    cc -O2 -o "$G" "$D/gen.c" -lm && cc -O2 -o "$W/tm" "$D/tm.c" || return 1
    "$G" text 8 > "$W/in/text.txt"
    case "$group" in
    compress)
        tar -cf - -C / usr/include usr/bin usr/lib 2> /dev/null | head -c 31457280 > "$W/in/corpus"
        head -c 5242880 "$W/in/corpus" > "$W/in/corpus5"
        for v in $variants; do p="$W/i/brotli/$v"; [ -x "$p/bin/brotli" ] && "$p/bin/brotli" -q 9 -c "$W/in/corpus" > "$W/in/corpus.br" && break; done
        for v in $variants; do p="$W/i/libiconv/$v"; [ -x "$p/bin/iconv" ] || continue
            "$p/bin/iconv" -f UTF-8 -t UTF-16LE "$W/in/text.txt" > "$W/in/text.utf16"
            "$p/bin/iconv" -f UTF-8 -t CP1251//TRANSLIT "$W/in/text.txt" > "$W/in/text.cp1251"; break; done ;;
    crypto) printf 'correct horse battery staple' > "$W/in/pw" ;;
    text)
        "$G" xml 40 > "$W/in/big.xml"; "$G" xml 20 > "$W/in/mid.xml"; "$G" html 10 > "$W/in/big.html"
        "$G" html 3 > "$W/in/tidy.html"; "$G" yaml 8 > "$W/in/in.yaml" ;;
    image)
        "$G" ppm 4000 3000 > "$W/in/in.ppm"; "$G" ppm 2000 1500 > "$W/in/small.ppm"
        "$G" text 2 > "$W/in/shape.txt"; "$G" bidi 8 > "$W/in/bidi.txt"
        fc-cache -f > /dev/null 2>&1
        for v in $variants; do p="$W/i/mozjpeg/$v"; [ -x "$p/bin/cjpeg" ] || continue
            "$p/bin/cjpeg" -quality 85 -outfile "$W/in/prog.jpg" "$W/in/in.ppm"
            "$p/bin/cjpeg" -quality 85 -revert -outfile "$W/in/base.jpg" "$W/in/in.ppm"; break; done
        for v in $variants; do p="$W/i/webp/$v"; [ -x "$p/bin/cwebp" ] || continue
            "$p/bin/cwebp" -quiet -q 75 "$W/in/in.ppm" -o "$W/in/lossy.webp"
            "$p/bin/cwebp" -quiet -lossless -q 50 -m 3 "$W/in/small.ppm" -o "$W/in/lossless.webp"; break; done ;;
    video)
        "$G" y4m 1280 720 120 > "$W/in/v720-120.y4m"
        head -c $(( $(head -n 1 "$W/in/v720-120.y4m" | wc -c) + 60 * (1280 * 720 * 3 / 2 + 6) )) "$W/in/v720-120.y4m" > "$W/in/v720.y4m"
        "$G" y4m 2000 1500 1 > "$W/in/still.y4m"
        x265 --preset fast --input "$W/in/v720-120.y4m" --output "$W/in/v720.hevc" > "$W/log/x265.log" 2>&1 || say "x265: $(tail -n 2 "$W/log/x265.log")"
        SvtAv1EncApp --preset 8 -i "$W/in/v720-120.y4m" -b "$W/in/v720.ivf" > "$W/log/svt.log" 2>&1 || say "SvtAv1EncApp: $(tail -n 2 "$W/log/svt.log")"
        for v in $variants; do p="$W/i/libheif/$v"; [ -x "$p/bin/heif-enc" ] || continue
            "$p/bin/heif-enc" -q 60 "$W/in/still.y4m" -o "$W/in/still.heic" > "$W/log/heif-enc.log" 2>&1
            "$p/bin/heif-enc" -A -q 60 "$W/in/still.y4m" -o "$W/in/still.avif" >> "$W/log/heif-enc.log" 2>&1; break; done
        ls -l "$W/in" >&3 ;;
    net)
        "$G" urls 100000 > "$W/in/urls.txt"; "$G" domains 50000 > "$W/in/domains.txt"
        "$G" http 50000 > "$W/in/http.txt"; "$G" ips 100000 > "$W/in/ips.txt" ;;
    esac
}

# --------------------------------------------------------------- the report
report() {
    {
        echo "# lib-bench3: $group"
        echo
        echo "FreeBSD $(uname -r), $(sysctl -n hw.model | sed 's/  */ /g; s/ *$//'), $ncpu CPUs; rounds $rounds, medians;"
        echo "variants: $variants; flags: $F (gcc16: and -std=gnu17 for C, -fno-semantic-interposition, libgcc linked in)."
        echo "<variant> against clang19: a minus is faster than clang19 (for times and for rates);"
        echo "units: s (seconds, lower is better), MBps (MB/s), MiBps (MiB/s), Mpixps (megapixels/s); spread: (max - min) / median of the runs, the largest of the variants."
        echo
        echo "- compiler clang19: $(cc --version | head -n 1)"
        echo "- compiler clang23: $(clang23 --version 2> /dev/null | head -n 1) (the package llvm23 of FreeBSD: the release of devel/llvm23 of this tree, 23.1.6)"
        echo "- compiler gcc16: $("$gcc_bin" --version 2> /dev/null | head -n 1) (the package $(pkg query '%n-%v (%R)' gcc16 2> /dev/null))"
        echo "- linker of clang23: $("$W/bin-clang23/ld" --version 2> /dev/null | head -n 1); of gcc16: $(/usr/local/bin/ld --version 2> /dev/null | head -n 1)"
        echo
        echo "## Summary"
        echo
        echo "Per library the geometric mean of the ratios of the medians of its benchmarks against clang19 (a minus is faster), the winner and its margin over the next."
        echo
        h="| library | version | benchmarks |"; l="|---|---|--:|"
        for v in ${variants#clang19}; do h="$h $v against clang19 |"; l="$l--:|"; done
        echo "$h the winner | margin | spread max |"; echo "$l---|--:|--:|"
        cat "$W/summary" 2> /dev/null
        echo
        echo "## Not measured"
        echo
        echo "| library | why |"; echo "|---|---|"
        cat "$notes"
        # the libraries of no group, in the report of the first group only
        [ "$group" = compress ] && echo "$not_measured" | while IFS='|' read -r a b; do echo "| $a | $b |"; done
        cat "$W/details" 2> /dev/null
        echo
        echo "## The raw values (a line per benchmark and variant, a value per round)"
        echo
        echo '```'
        for f in "$raw"/*; do [ -f "$f" ] && echo "${f##*/}: $(tr '\n' ' ' < "$f")"; done
        echo '```'
    } > "$out"
}
# tables <library>: the table of the library (into $W/details) and its line of the summary
tables() {
    lib="$1"
    [ -n "$(ls "$raw" | awk -F '|' -v l="$lib" '$1 == l' | head -n 1)" ] || { echo "| $lib | no value: its benchmarks failed (the log) |" >> "$notes"; return; }
    others="${variants#clang19}"
    {
        echo
        echo "## $lib"
        echo
        cat "$W/proof-$lib" 2> /dev/null
        echo
        h="| benchmark | unit |"; l="|---|---|"
        for v in $variants; do h="$h $v |"; l="$l--:|"; done
        for v in $others; do h="$h $v against clang19 |"; l="$l--:|"; done
        echo "$h spread max | the winner |"; echo "$l--:|---|"
    } >> "$W/details"
    : > "$W/ratios"
    ls "$raw" | awk -F '|' -v l="$lib" '$1 == l { print $2 "|" $3 "|" $4 }' | sort -u | while IFS= read -r b; do
        n="${b%%|*}"; rest="${b#*|}"; u="${rest%%|*}"; d="${rest#*|}"
        a="$(median "$raw/$lib|$n|$u|$d|clang19" 2> /dev/null)"
        row="| $n | $u | ${a:--} |"; pcts=""; sp=0; best=clang19; bestv=0
        for v in $variants; do
            sv="$(spread "$raw/$lib|$n|$u|$d|$v" 2> /dev/null)"
            sp="$(awk -v a="$sp" -v b="${sv:-0}" 'BEGIN { print (b > a) ? b : a }')"
        done
        for v in $others; do
            g="$(median "$raw/$lib|$n|$u|$d|$v" 2> /dev/null)"
            pct="$(awk -v a="${a:-0}" -v g="${g:-0}" -v d="$d" 'BEGIN {
                if (a == 0 || g == 0) { print "-"; exit }
                if (d == "lower") x = (g / a - 1) * 100; else x = (a / g - 1) * 100
                printf "%+.1f%%\n", x }')"
            row="$row ${g:--} |"; pcts="$pcts $pct |"
            case "$pct" in -) ;; *) x="${pct%\%}"
                if awk -v x="$x" -v b="$bestv" 'BEGIN { exit !(x < b) }'; then best="$v"; bestv="$x"; fi
                echo "$v $x" >> "$W/ratios" ;;
            esac
        done
        echo "$row$pcts ${sp}% | $best |" >> "$W/details"
    done
    # the geometric mean per variant of (1 + x/100), the winner and its margin over the next
    line="$(awk -v vs="$others" '
        { s[$1] += log(1 + $2 / 100); n[$1]++ }
        END {
            k = split(vs, v, " "); m["clang19"] = 0
            for (i = 1; i <= k; i++) m[v[i]] = n[v[i]] ? (exp(s[v[i]] / n[v[i]]) - 1) * 100 : 0
            best = "clang19"; for (x in m) if (m[x] < m[best]) best = x
            second = 1e9; for (x in m) if (x != best && m[x] < second) second = m[x]
            out = ""; for (i = 1; i <= k; i++) out = out sprintf(" %+.1f%% |", m[v[i]])
            printf "%s %s | %.1f%% |", out, best, second - m[best]
        }' "$W/ratios")"
    nb="$(ls "$raw" | awk -F '|' -v l="$lib" '$1 == l { print $2 }' | sort -u | wc -l | tr -d ' ')"
    echo "| $lib | $(cat "$W/ver-$lib" 2> /dev/null) | $nb |$line $(cat "$W/spmax-$lib" 2> /dev/null || echo -) |" >> "$W/summary"
}

# --------------------------------------------------------------- main
case "$group" in
list) for g in $groups; do eval "echo \"$g: \$libs_$g\""; done; exit 0 ;;
compress|crypto|text|image|video|net) ;;
*) echo "unknown group $group ($groups)"; exit 0 ;;
esac
eval "libs=\"\$libs_$group\""
# LB_LIBS: only those of them (the others of LB_LIBS are of other groups)
if [ -n "${LB_LIBS:-}" ]; then
    l0="$libs"; libs=""
    for l in $l0; do case " $LB_LIBS " in *" $l "*) libs="$libs $l" ;; esac; done
    libs="${libs# }"
    [ -n "$libs" ] || { echo "no library of the group $group in LB_LIBS ($LB_LIBS)"; mkdir -p "$R"; echo "# lib-bench3: $group (no library of LB_LIBS)" > "$out"; exit 0; }
fi
eval "pk=\"\$pkgs_$group\""
say "group $group: $libs; $rounds rounds, $ncpu CPUs, variants: $variants"
say "cc: $(cc --version | head -n 1); clang23: $(clang23 --version 2> /dev/null | head -n 1); gcc16: $("$gcc_bin" --version 2> /dev/null | head -n 1)"
for v in $variants; do [ -x "$W/bin-$v/cc" ] || { echo "| (all) | no compiler $v ($W/bin-$v/cc) |" >> "$notes"; variants="$(echo " $variants " | sed "s/ $v / /; s/^ //; s/ $//")"; }; done
# one at a time: a package that is not there stops only itself
for q in $pk; do
    env ASSUME_ALWAYS_YES=yes pkg install -y -r FreeBSD-ports "$q" >> "$W/log/pkg.log" 2>&1 ||
        say "pkg install $q: $(tail -n 2 "$W/log/pkg.log" | tr '\n' ' ')"
done
: > "$W/summary"; : > "$W/details"
built=""
for lib in $libs; do
    fn="$(echo "$lib" | tr '-' '_')"
    V="" A=""
    if ! msg="$(f_$fn 2>&1)"; then note "| $lib | download failed: $(echo "$msg" | tail -n 1 | cut -c1-300) |"; say "$lib: $msg"; continue; fi
    f_$fn > /dev/null 2>&1
    echo "$V" > "$W/ver-$lib"
    ok=1
    : > "$W/proof-$lib"
    for v in $variants; do
        p="$W/i/$lib/$v"; s="$W/src/$lib-$v"; bl="$W/log/b-$lib-$v.log"
        rm -rf "$p"; mkdir -p "$p/bin" "$p/lib"
        say "build $lib $V $v"
        t0="$(date +%s)"
        if ! { unpack "$A" "$s" && set_cc "$v" "$p" && "b_$fn" "$v" "$s" "$p"; } > "$bl" 2>&1; then
            note "| $lib | the build with $v failed: $(tail -n 5 "$bl" | tr '\n|' ' /' | cut -c1-400) |"
            { echo "FAIL: $lib $v"; tail -n 40 "$bl"; } >&3
            ok=0; break
        fi
        PATH="$PATH0"
        f="$p/$(so_$fn)"
        [ -e "$f" ] || f="$(ls "$p"/lib/*.so* 2> /dev/null | head -n 1)"
        pl=""
        for b in "$p"/bin/*; do
            [ -f "$b" ] || continue
            x="$(ldd "$b" 2> /dev/null | grep -F "$p/lib" | awk '{ print $3 }' | head -n 3 | tr '\n' ' ' | sed "s#$W/##g; s/ *$//")"
            [ -n "$x" ] && { pl="${b##*/} loads $x"; break; }
        done
        [ -n "$pl" ] || pl="its programs have the library compiled in ($(ls "$p/bin" 2> /dev/null | head -n 3 | tr '\n' ' ' | sed 's/ *$//'): $(cc_of "$(ls "$p"/bin/* 2> /dev/null | head -n 1)"))"
        printf -- '- %s: built in %s s; %s: %s; %s\n' "$v" "$(( $(date +%s) - t0 ))" "${f#$p/}" "$(cc_of "$f")" "$pl" >> "$W/proof-$lib"
        # what the variant needs no more
        find "$s" -name '*.o' -delete 2> /dev/null
    done
    PATH="$PATH0"
    [ "$ok" = 1 ] && built="$built $lib"
done
say "built:$built"
inputs || say "the inputs failed"
for r in $(seq 1 "$rounds"); do
    say "round $r of $rounds"
    for lib in $built; do
        fn="$(echo "$lib" | tr '-' '_')"
        for v in $(order "$r"); do
            "m_$fn" "$v" "$W/i/$lib/$v" >> "$log" 2>&1
        done
    done
done
for lib in $built; do
    # the largest spread of the library, for its line of the summary
    m=0
    for f in "$raw/$lib|"*; do [ -f "$f" ] || continue; s="$(spread "$f")"; m="$(awk -v a="$m" -v b="$s" 'BEGIN { print (b > a) ? b : a }')"; done
    echo "${m}%" > "$W/spmax-$lib"
    tables "$lib"
done
report
say "the report: $out"
exit 0
