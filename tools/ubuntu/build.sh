#!/bin/sh
# tools/ubuntu/build.sh - our FFmpeg and ImageMagick 7 for Ubuntu 24.04 and 22.04 and for
# Debian 13 and 12 (amd64): the
# versions, patches and configure lines of multimedia/ffmpeg (files/ffmpeg.conf,
# files/ffmpeg-nonfree.conf, files/ffmpeg/*.patch; tools/ffmpeg-build.sh) and of
# graphics/ImageMagick7 (files/imagemagick.conf, files/policy.xml,
# files/imagemagick7-*.patch; tools/imagemagick-build.sh) of this tree, with the
# libraries of the package azsupport they link built with the options of tools/azsupport-build.sh
# (and files/deps/<name>-<version>.patch of azsupport/azsupport), from the release files of
# tools/ubuntu/sources.conf, their SHA-256 checked. FFmpeg also with the NVIDIA codecs
# and the CUDA filters (tools/ubuntu/ffmpeg-nvidia.conf; aZ, 25.11.2026). Built on the
# release it is for (the glibc and libstdc++ of 24.04 are newer than those of 22.04, those
# of Debian 13 than those of Debian 12): the archive and the packages are named by it,
# azsupport-ubuntu24, azsupport-ubuntu22, azsupport-debian13 and azsupport-debian12 (aZ,
# 25.11.2026: «надо ешё для ubuntu 22, дополни к 24»; «на deb можно ещё варианты для дебияна
# положить вместе с вариантами для убунты?»). The same sources, patches and options on
# each; only the compilers and the libraries of the system differ.
#
# What is not as on FreeBSD, and why:
#   - the libraries are static archives of the work directory, inside the programs:
#     there is no /usr/local/azsupport here; ffmpeg, ffprobe and magick need only the
#     libraries of the system itself: glibc, libstdc++ and libgcc_s (libheif, libde265 and
#     fdk-aac are C++), zlib and bzip2 (as the FreeBSD builds take those of the base
#     system), and FFmpeg loads the NVIDIA driver when it opens a CUDA device (dlopen:
#     so it is linked with glibc dynamically; without the driver and a GPU it works as
#     without them)
#   - GCC of the system (13 on Ubuntu 24.04, 11 on 22.04, 14 on Debian 13, 12 on Debian 12)
#     instead of the clang of the FreeBSD base, with its gcc-ar for
#     the LTO of FFmpeg (-flto=auto: the GCC way of --enable-lto); x264 without LTO
#     (b_x264: why); clang (18 on Ubuntu 24.04, 14 on 22.04, 19 on Debian 13, 14 on Debian 12)
#     only for the CUDA kernels of the filters (cuda-llvm)
#   - RELRO and BIND_NOW of the programs (check_bins) asked of the linker here
#     (-Wl,-z,relro,-z,now): the GCC of Ubuntu passes them by itself, that of Debian does
#     not. So on Debian the other defaults of the GCC of Ubuntu 24.04 too:
#     -D_FORTIFY_SOURCE=3, -fstack-clash-protection, -fcf-protection
#   - of the FreeBSD ports what makes the same library here: the APNG patch of libpng
#     (its PATCHFILES: the patch lines of sources.conf), LONG_PCF_NAMES of FreeType,
#     the version of x264 in its meson.build (b_x264); not their patches for FreeBSD
#     (the linker scripts of libpng and FFmpeg, the exports of libde265, the CPU count
#     of x264, cmake 3.5 for mozjpeg: CMAKE_POLICY_VERSION_MINIMUM here, vwebp, the
#     place of fonts.dtd, av_stream_get_first_dts of Chromium); ours (files/ffmpeg/,
#     files/deps/, the imagemagick7-*.patch), and tools/ubuntu/ffmpeg/*.patch for NVENC
#   - fontconfig takes the configuration, fonts and cache of the system (/etc/fonts,
#     /usr/share/fonts, /var/cache/fontconfig: the same on Ubuntu and Debian): the packages
#     fontconfig-config and fonts-dejavu-core, as the port takes those of FreeBSD
#
# Usage (Ubuntu 24.04 or 22.04, Debian 13 or 12, amd64; the workflow .github/workflows/ubuntu.yml):
#   sh tools/ubuntu/build.sh --tools    install the build tools (apt-get; as root)
#   sh tools/ubuntu/build.sh            build; the archive azsupport-<system>-amd64-<v3|v2>.tar.xz
#                                       (ubuntu24, ubuntu22, debian13, debian12) and
#                                       the packages azsupport-ffmpeg and azsupport-imagemagick7 of the
#                                       same files (tools/ubuntu/deb.sh)
#
# The archive (tar -xJf azsupport-ubuntu24-amd64-v3.tar.xz -C /; azsupport-ubuntu22 on 22.04,
# azsupport-debian13 and azsupport-debian12 on Debian): /usr/local/bin/ffmpeg,
# ffprobe, magick and the names linked to it (convert, identify, mogrify, composite,
# montage, compare, stream, animate, display, import, magick-script; not conjure, which
# runs MSL scripts), /usr/local/etc/ImageMagick-7 (with our policy.xml),
# /usr/local/share/ImageMagick-7, /usr/local/lib/ImageMagick-7.1.2 (configure.xml),
# /usr/local/share/licenses/ (FFmpeg, ImageMagick and each library), and
# /usr/local/share/doc/azsupport-ubuntu24/VERSIONS (azsupport-ubuntu22 on 22.04, azsupport-debian13,
# azsupport-debian12: what was built from what).
#
# Environment:
#   AZSUPPORT_CPUTYPE   x86-64-v3 (default) or x86-64-v2: -march and the name of the archive
#   AZSUPPORT_CFLAGS    default -O3 -pipe (as CFLAGS of make.conf of the servers)
#   AZSUPPORT_WORK      the work directory (default /tmp/azsupport-ubuntu-<level>)
#   AZSUPPORT_RESULTS   the results (default ubuntu-results/ of the current directory):
#                summary.txt, a log per part, VERSIONS, bins.txt, ffmpeg.conf (the
#                configure lines of FFmpeg, for tests/ports/ffmpeg-test.sh)
#   AZSUPPORT_OUT       where the archive goes (default: the current directory)
#   AZSUPPORT_FFMPEG_LTO  the LTO of FFmpeg: auto (default, -flto=auto) or no (without --enable-lto)
#   AZSUPPORT_X264_LTO    the LTO of x264 (b_lto of meson): false (default; b_x264: why) or true
#
# Exit status: 0 built, 1 a part failed or a check of the programs, 2 usage.

set -u
here="$(cd "$(dirname "$0")" && pwd)"
tree="$(cd "$here/../.." && pwd)"
sources="$here/sources.conf"
deps_conf="$tree/azsupport/azsupport/files/deps.conf"
ffconf="$tree/multimedia/ffmpeg/files/ffmpeg.conf"
ffnonfree="$tree/multimedia/ffmpeg/files/ffmpeg-nonfree.conf"
ffnvidia="$here/ffmpeg-nvidia.conf"
imconf="$tree/graphics/ImageMagick7/files/imagemagick.conf"
policy="$tree/graphics/ImageMagick7/files/policy.xml"
cputype="${AZSUPPORT_CPUTYPE:-x86-64-v3}"
case "$cputype" in x86-64-v2|x86-64-v3) ;; *) echo "ubuntu/build: AZSUPPORT_CPUTYPE is x86-64-v3 or x86-64-v2, not $cputype" >&2; exit 2 ;; esac
level="${cputype#x86-64-}"
work="${AZSUPPORT_WORK:-/tmp/azsupport-ubuntu-$level}"
res="${AZSUPPORT_RESULTS:-$(pwd)/ubuntu-results}"
out="${AZSUPPORT_OUT:-$(pwd)}"
# the static libraries, their headers and .pc files; the files of the archive
P="$work/prefix"
stage="$work/stage"
F=/usr/local
dist="$work/distfiles"
src="$work/src"
ncpu="$(nproc 2>/dev/null || echo 2)"
fflto="${AZSUPPORT_FFMPEG_LTO:-auto}"
# no: --enable-lto of ffmpeg.conf left out (FFmpeg has no --disable-lto)
case "$fflto" in auto) fflto_opt=--enable-lto=auto ;; no) fflto_opt="" ;; *) echo "ubuntu/build: AZSUPPORT_FFMPEG_LTO is auto or no, not $fflto" >&2; exit 2 ;; esac
x264lto="${AZSUPPORT_X264_LTO:-false}"
case "$x264lto" in true|false) ;; *) echo "ubuntu/build: AZSUPPORT_X264_LTO is true or false, not $x264lto" >&2; exit 2 ;; esac
# the system this runs on (/etc/os-release): Ubuntu 24.04 or 22.04, Debian 13 or 12. sys
# (ubuntu24.04, debian12: ID and VERSION_ID) ends the versions of the packages
# (~ubuntu24.04, ~debian12); rel names the archive, the packages and the directories of
# VERSIONS and of the licences (azsupport-ubuntu24, azsupport-ubuntu22, azsupport-debian13,
# azsupport-debian12)
os_id="$(. /etc/os-release 2>/dev/null && echo "${ID:-}")"
os_ver="$(. /etc/os-release 2>/dev/null && echo "${VERSION_ID:-}")"
case "$os_id $os_ver" in
    "ubuntu 24.04"|"ubuntu 22.04") os_name="Ubuntu $os_ver" ;;
    "debian 13"|"debian 12") os_name="Debian $os_ver" ;;
    *) echo "ubuntu/build: Ubuntu 24.04 or 22.04, Debian 13 or 12 (amd64), not $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-}")" >&2; exit 2 ;;
esac
sys="$os_id$os_ver"
rel="$os_id${os_ver%%.*}"
name="azsupport-$rel-amd64-$level"

if [ "${1:-}" = "--tools" ]; then
    # build-essential (gcc, g++, make), clang (the CUDA kernels of FFmpeg), nasm (the
    # assembly of x264, dav1d, SVT-AV1, mozjpeg, FFmpeg), cmake and ninja, python3 (meson
    # of sources.conf), pkgconf, gperf (fontconfig), zlib and bzip2 (the -dev packages:
    # headers and libz.so, libbz2.so); xz-utils, bzip2, curl and ca-certificates for the
    # release files (a container of Debian has none of them)
    pkgs="build-essential dpkg-dev clang nasm cmake ninja-build python3 pkgconf gperf zlib1g-dev libbz2-dev xz-utils bzip2 curl ca-certificates patch file"
    export DEBIAN_FRONTEND=noninteractive
    # shellcheck disable=SC2086
    apt-get update -q && apt-get install -y -q --no-install-recommends $pkgs
    rc=$?
    for t in $pkgs; do dpkg -s "$t" > /dev/null 2>&1 || echo "ubuntu/build: package $t is not installed"; done
    exit $rc
fi
[ $# -eq 0 ] || { echo "usage: sh tools/ubuntu/build.sh [--tools]" >&2; exit 2; }
for f in "$sources" "$deps_conf" "$ffconf" "$ffnonfree" "$ffnvidia" "$imconf" "$policy"; do
    [ -f "$f" ] || { echo "ubuntu/build: no $f" >&2; exit 2; }
done

say() { printf '[ubuntu/build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

opt="${AZSUPPORT_CFLAGS:--O3 -pipe}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' $opt | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
# as tools/azsupport-build.sh and tools/ffmpeg-build.sh: the level, the two protections, and
# position independent code (FFmpeg adds -fPIC itself: --enable-pic)
ffcflags="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing"
# RELRO and BIND_NOW of ffmpeg, ffprobe and magick (the GCC of Debian does not pass them)
ldhard="-Wl,-z,relro,-z,now"
# on Debian also the other defaults of the GCC of Ubuntu 24.04, which that of Debian does
# not have (aZ, 25.11.2026 20:03: «да»): _FORTIFY_SOURCE=3, -fstack-clash-protection,
# -fcf-protection
if [ "$os_id" = debian ]; then
    ffcflags="$ffcflags -D_FORTIFY_SOURCE=3 -fstack-clash-protection -fcf-protection"
fi
export CC=gcc CXX=g++
export CFLAGS="$ffcflags -fPIC"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$P/include"
export LDFLAGS="-L$P/lib"
# pkg-config with --static (there are only static libraries here): ours first, then
# those of the system (zlib)
mkdir -p "$work/bin" "$res" "$dist" "$src" || exit 1
printf '%s\n' '#!/bin/sh' 'exec pkgconf --static "$@"' > "$work/bin/pkg-config-static"
chmod +x "$work/bin/pkg-config-static"
export PKG_CONFIG="$work/bin/pkg-config-static"
export PKG_CONFIG_LIBDIR="$P/lib/pkgconfig:$P/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
unset PKG_CONFIG_PATH
export PATH="$work/bin:$PATH"

# --- sources.conf, and that it has the versions of this tree --------------------------
names="$(awk '!/^#/ && NF >= 5 && $1 != "patch" { print $1 }' "$sources")"
src_ver() { awk -v n="$1" '$1 == n { print $2 }' "$sources"; }
src_file() { awk -v n="$1" '$1 == n { print $3 }' "$sources"; }
src_sha() { awk -v n="$1" '$1 == n { print $4 }' "$sources"; }
src_urls() { awk -v n="$1" '$1 == n { print $5 }' "$sources"; }
# the version this tree builds: the upstream line of deps.conf, ffmpeg.conf or
# imagemagick.conf ("the version built now": that of the port or of its take line)
tree_ver() {
    case "$1" in
        ffmpeg) c="$ffconf"; n=ffmpeg ;;
        imagemagick7) c="$imconf"; n=imagemagick7 ;;
        *) c="$deps_conf"; n="$1" ;;
    esac
    awk -v n="$n" '$1 == "upstream" && $2 == n { print $3 }' "$c"
}

rm -f "$res"/*.tail "$res/bins-bad.txt"
: > "$res/summary.txt"
cpu_model="$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n 1)"
printf 'flags:    %s\ncpu:      %s (%s cores)\nsystem:   %s\ncompiler: %s\n' "$ffcflags" "${cpu_model:-?}" "$ncpu" \
    "$(. /etc/os-release && echo "$PRETTY_NAME"), $(uname -sr)" "$(gcc --version | head -n 1); $(clang --version 2>/dev/null | head -n 1)" >> "$res/summary.txt"
bad=""
for n in $names; do
    tv="$(tree_ver "$n")"
    [ -n "$tv" ] || continue
    [ "$tv" = "$(src_ver "$n")" ] || bad="$bad $n (sources.conf $(src_ver "$n"), this tree $tv)"
done
if [ -n "$bad" ]; then
    echo "versions FAIL  sources.conf is not at the versions of this tree:$bad" >> "$res/summary.txt"
    cat "$res/summary.txt"
    exit 1
fi
# a fix of files/deps of azsupport for another version of a library here stops the build, as
# in tools/azsupport-build.sh: it is to be reviewed
for n in $names; do
    for p in "$tree/azsupport/azsupport/files/deps/$n"-*.patch; do
        [ -f "$p" ] || continue
        [ "${p##*/}" = "$n-$(src_ver "$n").patch" ] && continue
        echo "patches FAIL  ${p#"$tree/"} is for another version than $n $(src_ver "$n") of sources.conf" >> "$res/summary.txt"
        cat "$res/summary.txt"
        exit 1
    done
done

# This CPU has to run the code of the level (the checks after the build run it).
cpu_feats() {
    gcc "-march=$1" -dM -E - < /dev/null 2>/dev/null |
        sed -n -E 's/^#define __(SSE4_2|POPCNT|AVX|AVX2|BMI|BMI2|FMA|F16C|LZCNT|MOVBE|AVX512F|AVX512BW|AVX512CD|AVX512DQ|AVX512VL)__ 1$/\1/p' |
        LC_ALL=C sort -u
}
cpu_feats "$cputype" > "$work/cpu-need"
cpu_feats native > "$work/cpu-have"
lacks="$(LC_ALL=C comm -23 "$work/cpu-need" "$work/cpu-have" | tr '\n' ' ' | sed 's/ *$//')"
if [ ! -s "$work/cpu-need" ] || [ -n "$lacks" ]; then
    printf 'cpu      FAIL  this CPU (%s) %s -march=%s\n' "${cpu_model:-?}" "${lacks:+lacks $lacks of}" "$cputype" >> "$res/summary.txt"
    cat "$res/summary.txt"
    exit 1
fi

# fetch_file <file> <sha256> <addresses>: a file into $dist, by its addresses in turn,
# three times; its SHA-256 checked
fetch_file() {
    f="$dist/$1"; want="$2"
    if [ -f "$f" ] && [ "$(sha256sum "$f" | cut -d ' ' -f 1)" = "$want" ]; then return 0; fi
    rm -f "$f"
    for try in 1 2 3; do
        for u in $(echo "$3" | tr ',' ' '); do
            if curl -fsSL --connect-timeout 30 --max-time 900 -o "$f.part" "$u"; then mv "$f.part" "$f"; break 2; fi
            echo "== ${f##*/}: $u failed (try $try of 3)"
            rm -f "$f.part"
        done
        [ "$try" = 3 ] || sleep $((try * 15))
    done
    [ -f "$f" ] || { echo "== ${f##*/}: no address gave it"; return 1; }
    h="$(sha256sum "$f" | cut -d ' ' -f 1)"
    [ "$h" = "$want" ] || { echo "== ${f##*/}: SHA-256 $h, not $want of sources.conf"; return 1; }
    echo "== ${f##*/}: $h"
}
# fetch_one <name>: its release file
fetch_one() { fetch_file "$(src_file "$1")" "$(src_sha "$1")" "$(src_urls "$1")"; }
# port_patches <name>: "file sha256 addresses" of its patch lines (the patch files of the
# FreeBSD port that its default options apply: PATCHFILES)
port_patches() { awk -v n="$1" '$1 == "patch" && $2 == n { print $3, $4, $5 }' "$sources"; }
# extract <name>: its release file into $src/<name> (one directory on top in each)
extract() {
    rm -rf "${src:?}/$1" && mkdir -p "$src/$1" &&
        tar -xf "$dist/$(src_file "$1")" -C "$src/$1" --strip-components=1 --no-same-owner
}

# The builds: $1 is the source tree. As in tools/azsupport-build.sh (at, cm, ms), static and
# position independent, into $P.
at() {
    s="$1"; shift
    (cd "$s" && ./configure --prefix="$P" --libdir="$P/lib" --includedir="$P/include" \
        --enable-static --disable-shared --with-pic "$@" && make -j"$ncpu" && make install)
}
# CMAKE_POLICY_VERSION_MINIMUM: cmake 4 refuses a cmake_minimum_required() below 3.5
# (mozjpeg has 2.8.12; the port patches it)
cm() {
    s="$1"; shift
    cmake -S "$s" -B "$s/_az" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$P" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_PREFIX_PATH="$P" \
        -DCMAKE_IGNORE_PREFIX_PATH=/usr/local -DBUILD_SHARED_LIBS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" "$@" &&
        cmake --build "$s/_az" -j "$ncpu" && cmake --install "$s/_az"
}
ms() {
    s="$1"; shift
    (cd "$s" && meson setup _az --prefix="$P" --libdir=lib --buildtype=release -Doptimization=plain \
        --default-library=static -Db_staticpic=true --wrap-mode=nodownload "$@" &&
        ninja -C _az -j "$ncpu" && ninja -C _az install)
}

# meson of sources.conf, run from its release file
b_meson() {
    printf '%s\n' '#!/bin/sh' "exec python3 '$1/meson.py' \"\$@\"" > "$work/bin/meson" && chmod +x "$work/bin/meson" &&
        [ "$(meson --version)" = "$(src_ver meson)" ] || { echo "== meson --version: $(meson --version 2>&1)"; return 1; }
}
b_png() { cm "$1" -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_DEBUG_POSTFIX=""; }
b_mozjpeg() {
    # JPEG8 API, SIMD; without the tools' PNG input and TurboJPEG (tools/azsupport-build.sh)
    cm "$1" -DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DWITH_JPEG8=ON -DWITH_SIMD=ON -DREQUIRE_SIMD=OFF \
        -DWITH_ARITH_DEC=OFF -DWITH_ARITH_ENC=OFF -DWITH_12BIT=OFF -DWITH_JAVA=OFF -DWITH_JPEG7=OFF \
        -DWITH_TURBOJPEG=OFF -DPNG_SUPPORTED=OFF -DWITH_MEM_SRCDST=ON -DFORCE_INLINE=ON \
        -DCMAKE_INSTALL_LIBDIR="$P/lib" -DCMAKE_INSTALL_INCLUDEDIR="$P/include" \
        -DCMAKE_INSTALL_BINDIR="$P/bin" -DCMAKE_INSTALL_MANDIR="$P/share/man" \
        -DCMAKE_INSTALL_DOCDIR="$P/share/doc/mozjpeg" || return 1
    # the SIMD of mozjpeg needs nasm; without it (REQUIRE_SIMD off) it would be built without
    nm "$P/lib/libjpeg.a" 2>/dev/null | grep -q ' T jsimd_.*_avx2' ||
        { echo "== mozjpeg: built without its SIMD (no AVX2 code in libjpeg.a: no nasm?)"; return 1; }
}
b_webp() {
    at "$1" --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --disable-gl --disable-sdl \
        --disable-png --disable-jpeg --disable-tiff --disable-gif --disable-wic
}
# FreeType with the option LONG_PCF_NAMES of the port on (its post-patch: the long family
# names of PCF fonts), as tools/azsupport-build.sh gets it from make patch
b_freetype2() {
    sed -i 's|.*\(#define PCF_CONFIG_OPTION_LONG_FAMILY_NAMES\).*|\1|' "$1/include/freetype/config/ftoption.h" &&
        grep -q '^#define PCF_CONFIG_OPTION_LONG_FAMILY_NAMES' "$1/include/freetype/config/ftoption.h" ||
        { echo "== freetype2: no PCF_CONFIG_OPTION_LONG_FAMILY_NAMES in ftoption.h"; return 1; }
    cm "$1" -DFT_REQUIRE_ZLIB=ON -DFT_DISABLE_BZIP2=OFF -DFT_DISABLE_PNG=ON -DFT_DISABLE_HARFBUZZ=ON \
        -DFT_DISABLE_BROTLI=ON
}
b_expat() { at "$1" --without-docbook --without-examples --without-tests --without-xmlwf; }
# fontconfig with the paths of Ubuntu and Debian (as the port with those of FreeBSD), so that it
# reads the configuration, fonts and cache of the system; expat as its XML parser (the
# libxml2 of a -dev package of the system would be linked else); installed through a
# stage directory (nothing into /etc here)
b_fontconfig() {
    st="$work/stage-fontconfig"
    rm -rf "$st"
    xb=""
    grep -q "'xml-backend'" "$1/meson.options" 2>/dev/null && xb="-Dxml-backend=expat"
    # shellcheck disable=SC2086
    (cd "$1" && meson setup _az --prefix="$P" --libdir=lib --sysconfdir=/etc --localstatedir=/var \
        --buildtype=release -Doptimization=plain --default-library=static -Db_staticpic=true \
        --wrap-mode=nodownload -Ddoc=disabled -Dtests=disabled -Dtools=disabled -Dnls=disabled \
        -Dcache-build=disabled -Dcache-dir=/var/cache/fontconfig -Ddefault-fonts-dirs=/usr/share/fonts \
        -Dadditional-fonts-dirs=/usr/local/share/fonts -Dtemplate-dir=/usr/share/fontconfig/conf.avail \
        -Dxml-dir=/etc/fonts $xb &&
        ninja -C _az -j "$ncpu" && DESTDIR="$st" ninja -C _az install) &&
        cp -R "$st$P/." "$P/" || return 1
    grep -q '^Requires.*expat' "$P/lib/pkgconfig/fontconfig.pc" ||
        { echo "== fontconfig: not with expat: $(grep '^Requires' "$P/lib/pkgconfig/fontconfig.pc")"; return 1; }
}
b_lcms2() { at "$1" --with-fastfloat --with-threaded --without-jpeg --without-tiff; }
# x264 as the port (options ASM and OPTIMIZED_CFLAGS on: -O3 of CFLAGS), the library
# only. Its version and commit into meson.build, as the port does
# (files/patch-meson.build and the post-patch of multimedia/x264): version.py of the
# release file finds no git; without optimization=2 in its default options. Without
# the LTO of the port here (AZSUPPORT_X264_LTO): its meson.build compiles it with
# -mpreferred-stack-boundary=6 (a stack of 64 bytes for its assembly), which went
# with its LTO objects into the LTO of FFmpeg, so that FFmpeg's own code took its
# stack for 64-byte aligned: x86-64-v3 stored AVX registers with vmovdqa where the
# threads of glibc have 16 bytes (SIGSEGV in frame_pool_video_init and
# h264_field_start, run 45561254382; 76 of 172 checks of the test). On FreeBSD x264
# is a shared library, its LTO stays inside it.
b_x264() {
    c="$(src_urls x264 | sed -n 's|.*/-/archive/\([0-9a-f]\{40\}\)\.tar\.gz.*|\1|p')"
    [ -n "$c" ] || { echo "== x264: no commit in its address in sources.conf"; return 1; }
    sed -i -e "s|version: run_command(find_program('version.py'), '--package-version', check: true).stdout().strip(),|version: '$(src_ver x264)',|" \
        -e "s|default_options: \['optimization=2', 'c_std=c11'\],|default_options: ['c_std=c11'],|" \
        -e "s|^x264_commit = run_command(find_program('version.py'), '--commit-hash', check: true).stdout().strip()|x264_commit = '$c'|" \
        "$1/meson.build" &&
        grep -q "version: '$(src_ver x264)'," "$1/meson.build" && grep -q "^x264_commit = '$c'" "$1/meson.build" &&
        grep -q "default_options: \['c_std=c11'\]," "$1/meson.build" ||
        { echo "== x264: meson.build is not as the patch of the port expects"; return 1; }
    ms "$1" -Dcli=false -Dasm=enabled -Db_lto="$x264lto"
}
b_dav1d() { ms "$1" -Denable_tools=false -Denable_tests=false -Denable_examples=false; }
b_libde265() {
    cm "$1" -DENABLE_ENCODER=OFF -DENABLE_DECODER=OFF -DENABLE_SDL=OFF -DENABLE_INTERNAL_DEVELOPMENT_TOOLS=OFF
}
b_svtav1() { cm "$1" -DBUILD_APPS=OFF -DBUILD_TESTING=OFF -DNATIVE=OFF -DEXCLUDE_HASH=ON -DSVT_AV1_LTO=OFF; }
b_libheif() {
    cm "$1" -DBUILD_TESTING=OFF -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON \
        -DBUILD_DOCUMENTATION=OFF -DWITH_EXAMPLES=OFF -DWITH_GDK_PIXBUF=OFF -DENABLE_PLUGIN_LOADING=OFF \
        -DWITH_LIBSHARPYUV=OFF -DWITH_FUZZERS=OFF -DBUILD_DEVELOPMENT_TOOLS=OFF \
        -DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF -DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF \
        -DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF -DWITH_X265=OFF -DWITH_X264=OFF -DWITH_RAV1E=OFF \
        -DWITH_SvtEnc=ON -DWITH_SvtEnc_PLUGIN=OFF -DWITH_FFMPEG_DECODER=OFF -DWITH_OpenH264_DECODER=OFF -DWITH_OpenH264_ENCODER=OFF \
        -DWITH_JPEG_DECODER=OFF -DWITH_JPEG_ENCODER=OFF -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF \
        -DWITH_OPENJPH_DECODER=OFF -DWITH_OPENJPH_ENCODER=OFF -DWITH_KVAZAAR=OFF -DWITH_UVG266=OFF \
        -DWITH_VVDEC=OFF -DWITH_VVENC=OFF -DWITH_UNCOMPRESSED_CODEC=OFF || return 1
    # the three codecs built in: HEIC (libde265), AVIF read (dav1d) and written (SVT-AV1)
    grep -q 'de265' "$P/lib/pkgconfig/libheif.pc" && grep -q 'dav1d' "$P/lib/pkgconfig/libheif.pc" &&
        grep -q 'SvtAv1Enc' "$P/lib/pkgconfig/libheif.pc" ||
        { echo "== libheif.pc without libde265, dav1d or SvtAv1Enc: $(grep -E '^(Requires|Libs)' "$P/lib/pkgconfig/libheif.pc" | tr '\n' ' ')"; return 1; }
}
# fdk-aac of the nonfree build (tools/ffmpeg-build.sh, b_fdkaac): the static library
# only, with the flags of FFmpeg
b_fdkaac() {
    cmake -S "$1" -B "$1/_az" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$P" \
        -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DBUILD_SHARED_LIBS=OFF -DBUILD_PROGRAMS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_C_FLAGS="$ffcflags" -DCMAKE_CXX_FLAGS="$ffcflags" &&
        cmake --build "$1/_az" -j "$ncpu" && cmake --install "$1/_az" || return 1
    [ -f "$P/lib/libfdk-aac.a" ] && [ -f "$P/lib/pkgconfig/fdk-aac.pc" ] || { echo "== no $P/lib/libfdk-aac.a or its .pc"; return 1; }
}
b_nvcodec() { make -C "$1" PREFIX="$P" install; }

# conf_opts <file>...: the options of the configure lines
conf_opts() { awk '$1 == "configure" { for (i = 2; i <= NF; i++) print $i }' "$@"; }
# FFmpeg: our patches (files/ffmpeg/, then tools/ubuntu/ffmpeg/, each in the order of
# their names), configure with the options of tools/ffmpeg-build.sh and the configure
# lines of ffmpeg.conf, ffmpeg-nonfree.conf and ffmpeg-nvidia.conf (in that order, all
# in $res/ffmpeg.conf), its programs into the stage
b_ffmpeg() {
    for p in "$tree"/multimedia/ffmpeg/files/ffmpeg/*.patch "$here"/ffmpeg/*.patch; do
        [ -f "$p" ] || continue
        echo "== ${p#"$tree/"}"
        patch -p1 -N -s -d "$1" < "$p" || { echo "== ${p##*/} does not apply"; return 1; }
    done
    {
        cat "$ffconf"
        echo "# multimedia/ffmpeg/files/ffmpeg-nonfree.conf"
        grep '^configure' "$ffnonfree"
        echo "# tools/ubuntu/ffmpeg-nvidia.conf"
        grep '^configure' "$ffnvidia"
    } > "$res/ffmpeg.conf"
    (
        cd "$1" || exit 1
        # shellcheck disable=SC2046
        ./configure --prefix="$F" --cc=gcc --cxx=g++ --ar=gcc-ar --ranlib=gcc-ranlib --nm="gcc-nm -g" \
            --pkg-config=pkgconf --pkg-config-flags=--static \
            --extra-cflags="$ffcflags -I$P/include" --extra-cxxflags="$ffcflags -I$P/include" \
            --extra-ldflags="-L$P/lib $ldhard" $(conf_opts "$res/ffmpeg.conf" | if [ -z "$fflto_opt" ]; then grep -v -x -e --enable-lto; else cat; fi) $fflto_opt &&
            make -j"$ncpu" && make install-progs DESTDIR="$stage"
    ) || { cp "$1/ffbuild/config.log" "$res/ffmpeg-config.log" 2>/dev/null; return 1; }
    cp "$1/ffbuild/config.log" "$res/ffmpeg-config.log" 2>/dev/null
    mkdir -p "$stage$F/share/licenses/ffmpeg" || return 1
    for f in COPYING.GPLv2 COPYING.LGPLv2.1 LICENSE.md; do cp "$1/$f" "$stage$F/share/licenses/ffmpeg/$f" || return 1; done
}
# ImageMagick 7: our patches, configure with the lines configure and configure7 of
# imagemagick.conf (static, the coders built in) as tools/imagemagick-build.sh
# (b_im7_static), the C++ runtime of libheif and libde265 at the end of the link;
# installed into a stage of its own, and from there into the stage of the archive: the
# programs (PIE, RELRO, BIND_NOW; magick and the names linked to it, not conjure and the
# config scripts), etc/ImageMagick-7 with our policy, share/ImageMagick-7,
# lib/ImageMagick-<version> (configure.xml) and the licence
b_imagemagick7() {
    for p in "$tree"/graphics/ImageMagick7/files/imagemagick7-*.patch; do
        [ -f "$p" ] || continue
        echo "== ${p#"$tree/"}"
        patch -p1 -N -s -d "$1" < "$p" || { echo "== ${p##*/} does not apply"; return 1; }
    done
    st="$work/stage-imagemagick7"
    rm -rf "$st"
    (
        cd "$1" || exit 1
        LDFLAGS="-L$P/lib -pie $ldhard"
        export LDFLAGS
        # shellcheck disable=SC2046
        ./configure --prefix="$F" LIBS="-lstdc++ -lpthread -lm" PTHREAD_LIBS=-lpthread \
            $(awk '$1 == "configure" || $1 == "configure7" { for (i = 2; i <= NF; i++) print $i }' "$imconf") &&
            make -j"$ncpu" && make install-strip DESTDIR="$st"
    ) || { cp "$1/config.log" "$res/imagemagick7-config.log" 2>/dev/null; return 1; }
    cp "$1/config.log" "$res/imagemagick7-config.log" 2>/dev/null
    s="$st$F"
    progs="$(cd "$s/bin" && ls | grep -v -e '-config$' -e '^conjure$')"
    printf '%s\n' "$progs" | grep -q -x magick || { echo "== no magick in $s/bin: $(ls "$s/bin" | tr '\n' ' ')"; return 1; }
    keep="$(for p in $progs; do echo "bin/$p"; done) $(cd "$s" && ls -d etc/ImageMagick-7 share/ImageMagick-7 lib/ImageMagick-7.* 2>/dev/null)"
    echo "== into the stage:" $keep
    mkdir -p "$stage$F" || return 1
    # shellcheck disable=SC2086
    (cd "$s" && tar -cf - $keep) | (cd "$stage$F" && tar -xpf -) || return 1
    cp "$policy" "$stage$F/etc/ImageMagick-7/policy.xml" || return 1
    mkdir -p "$stage$F/share/licenses/ImageMagick7" || return 1
    for f in LICENSE NOTICE; do [ -f "$1/$f" ] && cp "$1/$f" "$stage$F/share/licenses/ImageMagick7/$f"; done
    rm -rf "$st"
    return 0
}

# the licence files of each library, as they are in its source tree
lic_files() {
    case "$1" in
        png) echo LICENSE ;;
        mozjpeg) echo LICENSE.md README.ijg ;;
        webp) echo COPYING PATENTS ;;
        freetype2) echo LICENSE.TXT docs/FTL.TXT docs/GPLv2.TXT ;;
        expat) echo COPYING ;;
        fontconfig) echo COPYING ;;
        lcms2) echo LICENSE COPYING ;;
        x264) echo COPYING ;;
        dav1d) echo COPYING doc/PATENTS ;;
        libde265) echo COPYING ;;
        svtav1) echo LICENSE.md PATENTS.md ;;
        libheif) echo COPYING ;;
        fdkaac) echo NOTICE ;;
        nvcodec) echo README ;;
    esac
}
lic() {
    d="$stage$F/share/licenses/azsupport-$rel/$1"
    for f in $(lic_files "$1"); do
        [ -f "$2/$f" ] || continue
        mkdir -p "$d" && cp "$2/$f" "$d/${f##*/}"
    done
    # nv-codec-headers: the MIT licence is the head of its headers
    if [ "$1" = nvcodec ]; then mkdir -p "$d" && sed -n '1,/\*\//p' "$2/include/ffnvcodec/nvEncodeAPI.h" > "$d/LICENSE"; fi
    return 0
}

build_one() {
    n="$1"
    log="$res/$n.log"
    start=$(date +%s)
    (
        fetch_one "$n" || exit 1
        extract "$n" || { echo "== $n: the release file does not extract"; exit 1; }
        s="$src/$n"
        echo "== $n $(src_ver "$n"): $s"
        port_patches "$n" | while read -r pf psha purls; do
            fetch_file "$pf" "$psha" "$purls" || exit 1
            echo "== $pf (the FreeBSD port)"
            case "$pf" in *.gz) gzip -dc "$dist/$pf" ;; *) cat "$dist/$pf" ;; esac | patch -p1 -N -s -d "$s" ||
                { echo "== $pf does not apply"; exit 1; }
        done || exit 1
        p="$tree/azsupport/azsupport/files/deps/$n-$(src_ver "$n").patch"
        if [ -f "$p" ]; then
            echo "== ${p#"$tree/"}"
            patch -p0 -N -s -d "$s" < "$p" || { echo "== ${p##*/} does not apply"; exit 1; }
        fi
        "b_$n" "$s" || exit 1
        [ "$n" = meson ] || lic "$n" "$s"
    ) > "$log" 2>&1
    rc=$?
    if [ "$rc" = 0 ]; then
        printf '%-12s OK    %-12s %5ss\n' "$n" "$(src_ver "$n")" "$(( $(date +%s) - start ))" >> "$res/summary.txt"
    else
        printf '%-12s FAIL  %-12s %5ss (%s.log)\n' "$n" "$(src_ver "$n")" "$(( $(date +%s) - start ))" "$n" >> "$res/summary.txt"
        {
            tail -n 60 "$log"
            echo "== disk: $(df -h "$work" | awk 'NR == 2 { print $4 " free of " $2 }')"
            echo "== errors in the log:"
            grep -n -E '\*\*\*|Error [0-9]+|No space|[Ee]rror:|undefined reference|CMake Error|ERROR:' "$log" | tail -n 20
        } > "$res/$n.tail"
    fi
    say "$n: $(tail -n 1 "$res/summary.txt" | awk '{ print $2 }')"
    return "$rc"
}

# The programs: PIE, RELRO, BIND_NOW, no run path, and nothing linked but the
# libraries of the system named above (the same on Ubuntu and Debian).
ok_libs="linux-vdso.so.1 ld-linux-x86-64.so.2 libc.so.6 libm.so.6 libmvec.so.1 libpthread.so.0 libdl.so.2 librt.so.1 libstdc++.so.6 libgcc_s.so.1 libz.so.1 libbz2.so.1.0"
check_bins() {
    : > "$res/bins.txt"
    for b in ffmpeg ffprobe magick; do
        f="$stage$F/bin/$b"
        [ -x "$f" ] || { echo "$b: missing" >> "$res/bins-bad.txt"; continue; }
        type="$(readelf -h "$f" | awk '/Type:/ { print $2 }')"
        relro="$(readelf -l "$f" | grep -c GNU_RELRO)"
        now="$(readelf -d "$f" | grep -c -E 'BIND_NOW|FLAGS_1.*NOW')"
        rp="$(readelf -d "$f" | sed -n 's/.*(R[UN]*PATH).*\[\(.*\)\].*/\1/p')"
        need="$(readelf -d "$f" | sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p' | tr '\n' ' ' | sed 's/ *$//')"
        printf '%s: %s KB, ELF type %s, RELRO %s, BIND_NOW %s, run path %s; NEEDED: %s\n' "$b" \
            "$(du -k "$f" | cut -f 1)" "$type" "$relro" "$now" "${rp:-none}" "$need" >> "$res/bins.txt"
        for l in $need; do
            case " $ok_libs " in *" $l "*) ;; *) echo "$b: NEEDED $l, not a library of the system named in build.sh" >> "$res/bins-bad.txt" ;; esac
        done
        [ "$type" = DYN ] || echo "$b: not a PIE (ELF type $type)" >> "$res/bins-bad.txt"
        [ "$relro" -gt 0 ] || echo "$b: no RELRO" >> "$res/bins-bad.txt"
        [ "$now" -gt 0 ] || echo "$b: no BIND_NOW" >> "$res/bins-bad.txt"
        [ -z "$rp" ] || echo "$b: a run path ($rp)" >> "$res/bins-bad.txt"
    done
    # what the programs say of themselves (they run on this CPU: the check above)
    "$stage$F/bin/ffmpeg" -hide_banner -version > "$res/ffmpeg-version.txt" 2>&1 || echo "ffmpeg -version failed" >> "$res/bins-bad.txt"
    "$stage$F/bin/ffmpeg" -hide_banner -hwaccels > "$res/ffmpeg-hwaccels.txt" 2>&1
    "$stage$F/bin/ffmpeg" -hide_banner -encoders > "$res/ffmpeg-encoders.txt" 2>&1
    for e in h264_nvenc hevc_nvenc av1_nvenc libx264 libsvtav1 libfdk_aac; do
        grep -q " $e " "$res/ffmpeg-encoders.txt" || echo "ffmpeg: no encoder $e" >> "$res/bins-bad.txt"
    done
    grep -q '^cuda$' "$res/ffmpeg-hwaccels.txt" || echo "ffmpeg: no hwaccel cuda" >> "$res/bins-bad.txt"
    for x in scale_cuda hwupload_cuda; do
        "$stage$F/bin/ffmpeg" -hide_banner -filters 2>/dev/null | grep -q " $x " || echo "ffmpeg: no filter $x" >> "$res/bins-bad.txt"
    done
    # h264_nvenc in 8-bit 4:2:0 only (tools/ubuntu/ffmpeg/h264-nvenc-8bit-420.patch; the
    # NVENC 12.1 of nv-codec-headers has no CUDA arrays)
    pf="$("$stage$F/bin/ffmpeg" -hide_banner -h encoder=h264_nvenc 2>/dev/null | sed -n 's/^ *Supported pixel formats: *//p' | sed 's/ *$//')"
    [ "$pf" = "yuv420p nv12 cuda" ] ||
        echo "ffmpeg: h264_nvenc takes ${pf:-?}, not yuv420p nv12 cuda (h264-nvenc-8bit-420.patch)" >> "$res/bins-bad.txt"
    # a CUDA device without the driver: FFmpeg looks for libcuda.so.1 and says so (here,
    # on a machine without NVIDIA), and does not crash
    "$stage$F/bin/ffmpeg" -hide_banner -init_hw_device cuda=gpu -f lavfi -i nullsrc=s=64x64:d=0.1 -f null - \
        > "$res/ffmpeg-cuda.txt" 2>&1
    c=$?
    echo "ffmpeg -init_hw_device cuda: exit $c, $(grep -i -m 1 -e 'libcuda' -e 'cuda' "$res/ffmpeg-cuda.txt" | cut -c 1-160)" >> "$res/bins.txt"
    # 255: the error of ffmpeg; 129 to 192: a signal (128 and its number)
    if [ "$c" -gt 128 ] && [ "$c" -le 192 ]; then echo "ffmpeg -init_hw_device cuda: exit $c (signal $((c - 128)))" >> "$res/bins-bad.txt"; fi
    MAGICK_CONFIGURE_PATH="$stage$F/etc/ImageMagick-7" "$stage$F/bin/magick" -version > "$res/magick-version.txt" 2>&1 ||
        echo "magick -version failed" >> "$res/bins-bad.txt"
}

manifest() {
    {
        echo "FFmpeg and ImageMagick 7 of azsupport/ports for $os_name (amd64, $cputype), built $(date -u '+%Y-%m-%d %H:%M UTC')"
        echo "on $(. /etc/os-release && echo "$PRETTY_NAME"), $(gcc --version | head -n 1); clang for CUDA: $(clang --version 2>/dev/null | head -n 1)"
        echo "commit: $(git -C "$tree" rev-parse HEAD 2>/dev/null || echo '?') of https://github.com/azsupport/ports (tools/ubuntu/build.sh)"
        echo "CFLAGS: $CFLAGS (FFmpeg: $ffcflags, ${fflto_opt:-no LTO}; x264: b_lto=$x264lto); the programs linked with $ldhard"
        echo "The libraries are in the programs (static); they need the libraries of $os_name: $ok_libs"
        echo
        echo "Sources (tools/ubuntu/sources.conf; the versions of azsupport/azsupport/files/deps.conf, ffmpeg.conf and imagemagick.conf):"
        for n in $names; do
            printf '  %-12s %-12s %s sha256 %s\n' "$n" "$(src_ver "$n")" "$(src_file "$n")" "$(src_sha "$n")"
        done
        echo
        echo "Patches:"
        awk '$1 == "patch" { printf "  %s of the FreeBSD port, to %s: sha256 %s\n", $3, $2, $4 }' "$sources"
        echo "  the version of x264 in its meson.build and LONG_PCF_NAMES of FreeType, as their ports"
        for p in "$tree"/azsupport/azsupport/files/deps/*.patch; do
            b="${p##*/}"
            for n in $names; do [ "$b" = "$n-$(src_ver "$n").patch" ] && echo "  azsupport/azsupport/files/deps/$b: $(head -n 1 "$p" | cut -c 1-150)"; done
        done
        for p in "$tree"/multimedia/ffmpeg/files/ffmpeg/*.patch "$here"/ffmpeg/*.patch "$tree"/graphics/ImageMagick7/files/imagemagick7-*.patch; do
            [ -f "$p" ] && echo "  ${p#"$tree/"}: $(head -n 1 "$p" | cut -c 1-150)"
        done
        echo
        echo "FFmpeg configure (after --prefix=$F, the compilers and the flags):"
        conf_opts "$res/ffmpeg.conf" | if [ -z "$fflto_opt" ]; then grep -v -x -e --enable-lto; else cat; fi | sed 's/^/    /'
        [ -z "$fflto_opt" ] || echo "    $fflto_opt"
        echo
        echo "ImageMagick 7 configure (after --prefix=$F):"
        awk '$1 == "configure" || $1 == "configure7" { for (i = 2; i <= NF; i++) print "    " $i }' "$imconf"
        echo
        echo "Licence: FFmpeg is nonfree and unredistributable (--enable-gpl and --enable-nonfree:"
        echo "x264 under the GPL and libfdk_aac under the licence of the Fraunhofer FDK AAC library),"
        echo "published by aZ on his responsibility, as the package ffmpeg of FreeBSD; ImageMagick under"
        echo "the ImageMagick License; the licences are in share/licenses/ (ffmpeg, ImageMagick7, and"
        echo "azsupport-$rel/<library>)."
    } > "$res/VERSIONS"
}

rm -rf "$stage" "$P"
mkdir -p "$stage" "$P" || exit 1
rc=0
for n in $names; do
    say "$n $(src_ver "$n")"
    if ! build_one "$n"; then rc=1; break; fi
done
if [ "$rc" = 0 ]; then
    manifest
    mkdir -p "$stage$F/share/doc/azsupport-$rel" && cp "$res/VERSIONS" "$stage$F/share/doc/azsupport-$rel/VERSIONS" ||
        echo "VERSIONS not into the stage" >> "$res/bins-bad.txt"
    check_bins
    if [ -s "$res/bins-bad.txt" ]; then
        rc=1
    else
        mkdir -p "$out" &&
            tar -C "$stage" --owner=0 --group=0 --numeric-owner -cJf "$out/$name.tar.xz" usr &&
            (cd "$out" && sha256sum "$name.tar.xz" > "$name.tar.xz.sha256") || rc=1
        [ "$rc" = 0 ] && echo "archive: $name.tar.xz, $(du -k "$out/$name.tar.xz" | cut -f 1) KB, sha256 $(cut -d ' ' -f 1 "$out/$name.tar.xz.sha256")" >> "$res/summary.txt"
        # the Debian packages azsupport-ffmpeg and azsupport-imagemagick7 of the same files
        # (tools/ubuntu/deb.sh), their files and Depends into the summary
        if [ "$rc" = 0 ]; then
            if sh "$here/deb.sh" "$stage" "$cputype" "$out" "$res" "$sys" > "$res/deb.log" 2>&1; then
                sed -n -e 's/^== /deb: /p' -e 's/^ Depends: /     Depends: /p' "$res/debs.txt" >> "$res/summary.txt"
            else
                rc=1
                echo "deb      FAIL  tools/ubuntu/deb.sh (deb.log)" >> "$res/summary.txt"
                tail -n 40 "$res/deb.log" > "$res/deb.tail"
            fi
        fi
    fi
fi
echo "== $res/summary.txt"
cat "$res/summary.txt" "$res/bins.txt" 2>/dev/null
for f in "$res"/*.tail "$res/bins-bad.txt"; do
    [ -s "$f" ] || continue
    echo "== $f"
    cat "$f"
done
exit "$rc"
