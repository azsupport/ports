#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
# tools/avif-bench.sh <part>: the encoders of AVIF for the AVIF of our resize script of nginx
# (lua-vips: libvips 8.18 heifsave, Q 75 and 80, effort 4, subsample_mode auto, keep none;
# libheif 1.23.7 with SVT-AV1: speed 9 - effort = 5, the tune of libheif, PSNR) against
# other settings of SVT-AV1 and against libaom, with losses (quality, bytes, time), and the
# lossless formats (exactness, bytes, time): AVIF of SVT-AV1 and of libaom, WebP, PNG and
# JPEG XL. The workflow .github/workflows/avif-bench.yml runs it in a FreeBSD VM, a job per
# part:
#   lossy-360   the photos made 360 px wide as the script makes them (vips resize, lanczos3)
#   lossy-full  the photos as they are (768x512 and 512x768)
#   lossless    both sizes
# The report: results/avif-bench/<part>.md (the tables of tools/avif-bench/analyze.py, then
# the raw TSV files), for the branch runs of azsupport/azsupport (tools/runs-report.sh); the
# log of the job gets the progress and OK or FAIL only.
#
# The reference point of a later run (all in the head of the report): the photos (sha256
# of each, tools/avif-bench/kodak.sha256), the versions of the packages, the archives of
# the sources with their sha256, the commit of this script.
#   photos   Kodak Lossless True Color Image Suite, 24 PNGs of 768x512 and 512x768,
#            "released by the Eastman Kodak Company for unrestricted usage" (the page of the
#            suite, r0k.us/graphics/kodak); from r0k.us, else from the GitHub copy
#            MohamedBakrAli/Kodak-Lossless-True-Color-Image-Suite at KODAK_MIRROR (the same
#            files, fetched from r0k.us by its script); either checked against kodak.sha256
#   packages FreeBSD-ports latest: aom (libaom), svt-av1 (4.3.0), dav1d, libheif (for vips),
#            vips, webp (cwebp, dwebp), libjxl (cjxl, djxl), highway, brotli, lcms2, png
#   built    SVT-AV1 4.3.1 (the version of our azsupport; deps.conf: its stills bit-identical
#            to 4.3.0, checked here) with the flags of tools/azsupport-build.sh for x86-64-v3;
#            libheif 1.23.7 with heif-enc and heif-dec, the encoders of SVT-AV1 and libaom and
#            the decoder dav1d built in, against the packages; ssimulacra2 and
#            butteraugli_main of libjxl 0.13.0 (its devtools, against the packages);
#            tools/avif-bench/heifbench.c, imgcmp.c, tm.c
# How each is measured:
#   AVIF with losses  heifbench (an AVIF through libheif as heifsave writes it, timed in the
#                     process), the configurations of cfg() below, threads 1, Q of AB_QS;
#                     decoded by heif-dec (dav1d); SSIMULACRA2 (the main metric), Butteraugli
#                     (max and 3-norm), PSNR (RGB and Y) and SSIM (Y) of imgcmp. Time: AB_ROUNDS
#                     rounds at Q 75 and 80, the configurations interleaved, on the last CPU,
#                     nothing else running; and threads 4 at Q 75. Checks: heifbench against
#                     vips heifsave (the files the same), SVT-AV1 4.3.0 against 4.3.1, threads
#                     1 against 4.
#   lossless          the commands of lossless_cmd() below, timed as processes (tm, one CPU,
#                     the rounds interleaved), decoded (heif-dec, dwebp, djxl) and compared
#                     sample by sample with the PNG (imgcmp).
#
# Environment: AB_IMAGES (photos, default 24), AB_QS (default "30 40 50 60 70 75 80 85 90"),
# AB_CONFIGS (default all of cfg()), AB_LOSSLESS (default all of lossless_cmd()), AB_ROUNDS
# (default 3), AB_JOBS (parallel encodes of the sweep, default the CPUs), AB_WORK (default /ab),
# AB_COMMIT (the commit, for the report), AB_BUILD (no: take the builds of AB_OPT as they are,
# for a test outside the VM), AB_OPT (default /opt/ab), AB_LDP (the library path of SVT-AV1
# 4.3.0, default that of libheif alone). The lists: words separated by spaces or commas.

set -u
self="$0"
part="${1:?usage: sh tools/avif-bench.sh lossy-360|lossy-full|lossless}"
top="$(pwd)"
here="$top/tools/avif-bench"
W="${AB_WORK:-/ab}"
O="${AB_OPT:-/opt/ab}"
R="$top/results/avif-bench"
QS="$(echo "${AB_QS:-30 40 50 60 70 75 80 85 90}" | tr ',' ' ')"
NIMG="${AB_IMAGES:-24}"
ROUNDS="${AB_ROUNDS:-3}"
ALLCFG="svt-p5-psnr svt-p5-iq svt-p3-iq svt-p2-iq svt-p5-psnr-t1 svt-p5-iq-t1 svt-p3-iq-t1 aom-s6-iq aom-s5-iq aom-s5-ssim aom-s2-iq"
CONFIGS="$(echo "${AB_CONFIGS:-$ALLCFG}" | tr ',' ' ')"
KODAK_MIRROR=dd2e1105fe8d9afe1120cd7e4c0e5e41f509a81b
HEIF_URL=https://github.com/strukturag/libheif/releases/download/v1.23.7/libheif-1.23.7.tar.gz
HEIF_SHA=f7483e818503ea6224c8863e4a56ac02c7089021a98472c811c12aa19faf2475
SVT_URL=https://github.com/AOMediaCodec/SVT-AV1/archive/v4.3.1/SVT-AV1-4.3.1.tar.gz
SVT_SHA=ad94f481cb74821af183f37f4533fc52324b76ffbd98ec7723e282bab0cf9fc4
JXL_URL=https://codeload.github.com/libjxl/libjxl/tar.gz/v0.13.0
JXL_SHA=24d18c9af2d1f5a17730b3f8d3f70a5c16e5ac303f5d9d5fe9dc00cf7ca82af2
HB="$O/bin/heifbench"
IMGCMP="$O/bin/imgcmp"
TM="$O/bin/tm"
HEIFDEC="$O/heif/bin/heif-dec"
S2="$O/jxl/tools/ssimulacra2"
BA="$O/jxl/tools/butteraugli_main"
# libheif of the build first; SVT-AV1 4.3.1 with LDP431, 4.3.0 (the package) without it
LDP="${AB_LDP:-$O/heif/lib}"
LDP431="$O/heif/lib:$O/svt/lib"
export W O R QS HB IMGCMP TM HEIFDEC S2 BA LDP LDP431

case "$(uname -s)" in
FreeBSD)
    ncpu="$(sysctl -n hw.ncpu)"
    cpuname="$(sysctl -n hw.model)"
    sha() { sha256 -q "$1"; }
    ;;
*)
    ncpu="$(nproc)"
    cpuname="$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n 1)"
    sha() { sha256sum "$1" | cut -d ' ' -f 1; }
    ;;
esac
last=$((ncpu - 1))
pin() {
    if command -v cpuset > /dev/null 2>&1; then cpuset -l "$last" "$@"; else taskset -c "$last" "$@"; fi
}
JOBS="${AB_JOBS:-$ncpu}"

say() { echo "== $(date -u +%H:%M:%S) $*"; [ -d "$R" ] && echo "== $(date -u +%H:%M:%S) $*" >> "$R/$part.log"; return 0; }
die() { say "FAIL: $*"; echo "FAIL: $*" >> "$W/fails"; exit 1; }
bytes() { wc -c < "$1" | tr -d ' '; }

# cfg <config> <Q> [<threads>]: the encoder and its parameters, in the order heifsave sets them
# (speed = 9 - effort, chroma, threads, auto-tiles, enable-intrabc, tune); chroma 444 from Q 90
# as subsample_mode auto (the encoder of SVT-AV1 has no chroma parameter and writes 4:2:0)
cfg() {
    c="$1" q="$2" t="${3:-1}"
    if [ "$q" -ge 90 ]; then ch=444; else ch=420; fi
    k="chroma=$ch threads=$t auto-tiles=true enable-intrabc=false"
    case "$c" in
    svt-p5-psnr|svt430-p5-psnr) echo "svt speed=5 $k" ;;
    svt-p5-iq)      echo "svt speed=5 $k tune=iq" ;;
    svt-p3-iq)      echo "svt speed=3 $k tune=iq" ;;
    svt-p2-iq)      echo "svt speed=2 $k tune=iq" ;;
    svt-p5-psnr-t1) echo "svt speed=5 $k tile-rows=1 tile-cols=1" ;;
    svt-p5-iq-t1)   echo "svt speed=5 $k tune=iq tile-rows=1 tile-cols=1" ;;
    svt-p3-iq-t1)   echo "svt speed=3 $k tune=iq tile-rows=1 tile-cols=1" ;;
    aom-s6-iq)      echo "aom speed=6 $k tune=iq" ;;
    aom-s5-iq)      echo "aom speed=5 $k tune=iq" ;;
    aom-s5-ssim)    echo "aom speed=5 $k tune=ssim" ;;
    aom-s2-iq)      echo "aom speed=2 $k tune=iq" ;;
    *) return 1 ;;
    esac
}
# the library path of a configuration: svt430-* with the SVT-AV1 of the package
ldp_of() { case "$1" in svt430-*) echo "$LDP" ;; *) echo "$LDP431" ;; esac; }

# one photo, one configuration, every Q: encode, decode, the metrics; a row per Q
sweep_one() {
    s="$1" im="$2" c="$3"
    ref="$W/img/$s/$im.png"
    o="$W/enc/$s/$c"
    d="$W/dec/$s/$c"
    mkdir -p "$o" "$d"
    rows="$W/rows/$s-$im-$c.tsv"
    : > "$rows"
    for q in $QS; do
        # shellcheck disable=SC2046
        set -- $(cfg "$c" "$q")
        enc="$1"; shift
        f="$o/$im-q$q.avif"
        if ! env LD_LIBRARY_PATH="$(ldp_of "$c")" "$HB" "$ref" "$f" "$enc" "$q" 1 "$@" > /dev/null 2> "$f.err"; then
            echo "$s $im $c Q$q: heifbench: $(grep -v '^Svt\[' "$f.err" | tail -n 2 | tr '\n' ' ')" >> "$W/fails"
            continue
        fi
        p="$d/$im-q$q.png"
        if ! env LD_LIBRARY_PATH="$LDP" "$HEIFDEC" "$f" "$p" > /dev/null 2>&1; then
            echo "$s $im $c Q$q: heif-dec failed" >> "$W/fails"
            continue
        fi
        s2="$("$S2" "$ref" "$p" 2> /dev/null)" || s2=""
        ba="$("$BA" "$ref" "$p" --pnorm 3 2> /dev/null)" || ba=""
        bmax="$(echo "$ba" | sed -n 1p)"
        bp3="$(echo "$ba" | sed -n 's/^3-norm: //p')"
        ic="$("$IMGCMP" "$ref" "$p" 2> /dev/null)" || ic="-	-	-	-	-"
        wh="$(sed -n 1p "$W/img/$s/$im.wh")"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$s" "$im" "$c" "$q" "$(bytes "$f")" "$wh" \
            "${s2:--}" "${bmax:--}" "${bp3:--}" "$ic" >> "$rows"
        rm -f "$p" "$f.err"
    done
}

if [ "$part" = _sweep ]; then
    sweep_one "$2" "$3" "$4"
    exit 0
fi

# ---- the start: the work, the report, the system

mkdir -p "$W" "$R" "$W/src" "$W/rows" || exit 1
: > "$R/$part.log"
: > "$W/fails"
head="$W/head.md"
{
    echo "# avif-bench: $part"
    echo
    echo "$(uname -sr) $(uname -m), $cpuname, $ncpu CPUs; rounds $ROUNDS"
    echo "flags: -O3 -pipe -march=x86-64-v3 -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fno-strict-aliasing -fPIC (SVT-AV1 4.3.1, libheif 1.23.7: tools/azsupport-build.sh); the packages as FreeBSD builds them"
    echo
    echo "- the commit of the script: ${AB_COMMIT:-$(git -C "$top" rev-parse HEAD 2> /dev/null || echo '?')}"
    echo "- memory: $(sysctl -n hw.physmem 2> /dev/null || sed -n 's/^MemTotal: *//p' /proc/meminfo)"
    echo "- Q: $QS; configurations: $CONFIGS; photos: $NIMG; rounds of the time: $ROUNDS; parallel encodes of the sweep: $JOBS"
} > "$head"
say "avif-bench $part: $cpuname, $ncpu CPUs"

if command -v pkg > /dev/null 2>&1; then
    echo "- packages: $(pkg query '%n-%v' aom svt-av1 dav1d libheif vips webp libjxl highway brotli lcms2 png python3 2> /dev/null | tr '\n' ' ')" >> "$head"
    echo "- cc: $(cc --version | head -n 1)" >> "$head"
fi

# ---- the sources and the builds

fetch_ok() { # <url> <sha256> <file>
    [ -s "$3" ] && [ "$(sha "$3")" = "$2" ] && return 0
    curl -fsSL -m 600 -o "$3" "$1" || return 1
    [ "$(sha "$3")" = "$2" ] || { echo "sha256 of $3: $(sha "$3"), not $2" >> "$W/fails"; return 1; }
}

if [ "${AB_BUILD:-yes}" != no ]; then
    mkdir -p "$O/bin" "$W/build"
    b="$W/build"
    F="-O3 -pipe -march=x86-64-v3 -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fno-strict-aliasing -fPIC"
    say "SVT-AV1 4.3.1"
    fetch_ok "$SVT_URL" "$SVT_SHA" "$W/src/svt.tar.gz" || die "SVT-AV1 4.3.1: the archive"
    (cd "$b" && tar xzf "$W/src/svt.tar.gz") || die "SVT-AV1: tar"
    # as s_svtav1 of tools/azsupport-build.sh: the library, no apps, no tests, no -march=native
    cmake -S "$b/SVT-AV1-4.3.1" -B "$b/svt" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$O/svt" \
        -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=ON -DBUILD_APPS=OFF -DBUILD_TESTING=OFF -DNATIVE=OFF \
        -DEXCLUDE_HASH=ON -DCMAKE_SKIP_RPATH=ON -DCMAKE_C_FLAGS="$F" -DCMAKE_CXX_FLAGS="$F" > "$R/build-svt.log" 2>&1 &&
        cmake --build "$b/svt" -j "$ncpu" >> "$R/build-svt.log" 2>&1 && cmake --install "$b/svt" >> "$R/build-svt.log" 2>&1 ||
        { tail -n 30 "$R/build-svt.log"; die "SVT-AV1 4.3.1: the build"; }
    echo "- SVT-AV1 4.3.1: $SVT_URL sha256 $SVT_SHA; $(ls "$O/svt/lib" | grep '^libSvtAv1Enc.so' | tr '\n' ' ')" >> "$head"

    say "libheif 1.23.7"
    fetch_ok "$HEIF_URL" "$HEIF_SHA" "$W/src/libheif.tar.gz" || die "libheif: the archive"
    (cd "$b" && tar xzf "$W/src/libheif.tar.gz") || die "libheif: tar"
    # as b_libheif of tools/azsupport-build.sh, with the examples and the encoder and decoder of
    # libaom; against the packages (SVT-AV1 4.3.0 at the link, 4.3.1 by LD_LIBRARY_PATH)
    cmake -S "$b/libheif-1.23.7" -B "$b/heif" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$O/heif" \
        -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_SKIP_RPATH=ON -DCMAKE_C_FLAGS="$F" -DCMAKE_CXX_FLAGS="$F" \
        -DBUILD_TESTING=OFF -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON \
        -DBUILD_DOCUMENTATION=OFF -DWITH_EXAMPLES=ON -DWITH_GDK_PIXBUF=OFF -DENABLE_PLUGIN_LOADING=OFF \
        -DWITH_LIBSHARPYUV=OFF -DWITH_FUZZERS=OFF -DBUILD_DEVELOPMENT_TOOLS=OFF \
        -DWITH_LIBDE265=OFF -DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF \
        -DWITH_AOM_DECODER=ON -DWITH_AOM_DECODER_PLUGIN=OFF -DWITH_AOM_ENCODER=ON -DWITH_AOM_ENCODER_PLUGIN=OFF \
        -DWITH_X265=OFF -DWITH_X264=OFF -DWITH_RAV1E=OFF \
        -DWITH_SvtEnc=ON -DWITH_SvtEnc_PLUGIN=OFF -DWITH_FFMPEG_DECODER=OFF -DWITH_OpenH264_DECODER=OFF -DWITH_OpenH264_ENCODER=OFF \
        -DWITH_JPEG_DECODER=OFF -DWITH_JPEG_ENCODER=OFF -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF \
        -DWITH_OPENJPH_DECODER=OFF -DWITH_OPENJPH_ENCODER=OFF -DWITH_KVAZAAR=OFF -DWITH_UVG266=OFF \
        -DWITH_VVDEC=OFF -DWITH_VVENC=OFF -DWITH_UNCOMPRESSED_CODEC=OFF > "$R/build-heif.log" 2>&1 &&
        cmake --build "$b/heif" -j "$ncpu" >> "$R/build-heif.log" 2>&1 && cmake --install "$b/heif" >> "$R/build-heif.log" 2>&1 ||
        { tail -n 30 "$R/build-heif.log"; die "libheif: the build"; }
    echo "- libheif 1.23.7: $HEIF_URL sha256 $HEIF_SHA; heif-enc, heif-dec; svt, aom, dav1d built in" >> "$head"

    if [ "$part" != lossless ]; then
        say "libjxl 0.13.0: ssimulacra2, butteraugli_main"
        fetch_ok "$JXL_URL" "$JXL_SHA" "$W/src/libjxl.tar.gz" || echo "libjxl: the sha256 of the archive is not that of the port; built anyway" >> "$W/fails"
        [ -s "$W/src/libjxl.tar.gz" ] || die "libjxl: the archive"
        (cd "$b" && tar xzf "$W/src/libjxl.tar.gz") || die "libjxl: tar"
        cmake -S "$b/libjxl-0.13.0" -B "$O/jxl" -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
            -DJPEGXL_ENABLE_DEVTOOLS=ON -DJPEGXL_ENABLE_TOOLS=ON -DJPEGXL_ENABLE_BENCHMARK=OFF -DJPEGXL_ENABLE_EXAMPLES=OFF \
            -DJPEGXL_ENABLE_JNI=OFF -DJPEGXL_ENABLE_SJPEG=OFF -DJPEGXL_ENABLE_OPENEXR=OFF -DJPEGXL_ENABLE_MANPAGES=OFF \
            -DJPEGXL_ENABLE_PLUGINS=OFF -DJPEGXL_ENABLE_DOXYGEN=OFF -DJPEGXL_ENABLE_SKCMS=OFF -DJPEGXL_ENABLE_JPEGLI=OFF \
            -DJPEGXL_FORCE_SYSTEM_HWY=ON -DJPEGXL_FORCE_SYSTEM_BROTLI=ON -DJPEGXL_FORCE_SYSTEM_LCMS2=ON \
            -DJPEGXL_ENABLE_FUZZERS=OFF -DJPEGXL_ENABLE_TCMALLOC=OFF -DCMAKE_DISABLE_FIND_PACKAGE_GIF=ON \
            -DCMAKE_DISABLE_FIND_PACKAGE_JPEG=ON > "$R/build-jxl.log" 2>&1 &&
            cmake --build "$O/jxl" -j "$ncpu" --target ssimulacra2 butteraugli_main >> "$R/build-jxl.log" 2>&1 ||
            { tail -n 30 "$R/build-jxl.log"; die "libjxl: the build"; }
        echo "- libjxl 0.13.0 devtools ssimulacra2, butteraugli_main: $JXL_URL sha256 $(sha "$W/src/libjxl.tar.gz") (the port: $JXL_SHA); lcms2, highway, brotli, png of the packages" >> "$head"
    fi

    say "heifbench, imgcmp, tm"
    cc -O2 -Wall -o "$HB" "$here/heifbench.c" -I"$O/heif/include" -I/usr/local/include -L"$O/heif/lib" -L/usr/local/lib -lheif -lpng16 > "$R/build-tools.log" 2>&1 &&
        cc -O2 -Wall -o "$IMGCMP" "$here/imgcmp.c" -I/usr/local/include -L/usr/local/lib -lpng16 -lm >> "$R/build-tools.log" 2>&1 &&
        cc -O2 -Wall -o "$TM" "$here/tm.c" >> "$R/build-tools.log" 2>&1 || { cat "$R/build-tools.log"; die "the tools"; }
fi
{
    echo "- libraries of heifbench (SVT-AV1 4.3.1): $(env LD_LIBRARY_PATH="$LDP431" ldd "$HB" 2> /dev/null | grep -E 'heif|Svt|aom|dav1d' | sed 's/^[[:space:]]*//; s/ (0x[0-9a-f]*)//' | tr '\n' ' ')"
    echo "- libraries of heifbench (SVT-AV1 4.3.0): $(env LD_LIBRARY_PATH="$LDP" ldd "$HB" 2> /dev/null | grep -E 'Svt' | sed 's/^[[:space:]]*//; s/ (0x[0-9a-f]*)//' | tr '\n' ' ')"
    echo "- vips: $(vips --version 2> /dev/null); cwebp $(cwebp -version 2> /dev/null); cjxl: $(cjxl --version 2> /dev/null | head -n 1)"
} >> "$head"
# the encoders of libheif as libheif reports them
env LD_LIBRARY_PATH="$LDP431" "$O/heif/bin/heif-enc" --list-encoders > "$W/encoders.txt" 2>&1 || true
echo "- encoders of our libheif: $(grep -E 'svt|aom' "$W/encoders.txt" | sed 's/^[[:space:]]*//' | tr '\n' ' ')" >> "$head"

# ---- the photos

say "the photos"
mkdir -p "$W/img/full" "$W/img/360"
n=0
src_used=""
for i in $(seq -w 1 24); do
    [ "$n" -ge "$NIMG" ] && break
    n=$((n + 1))
    want="$(awk -v f="kodim$i.png" '$2 == f { print $1 }' "$here/kodak.sha256")"
    f="$W/src/kodim$i.png"
    if [ ! -s "$f" ] || [ "$(sha "$f")" != "$want" ]; then
        curl -fsS -m 120 -o "$f" "http://r0k.us/graphics/kodak/kodak/kodim$i.png" 2> /dev/null && [ "$(sha "$f")" = "$want" ] &&
            src_used="$src_used r0k" ||
            { curl -fsS -m 120 -o "$f" "https://raw.githubusercontent.com/MohamedBakrAli/Kodak-Lossless-True-Color-Image-Suite/$KODAK_MIRROR/PhotoCD_PCD0992/$i.png" &&
                src_used="$src_used mirror"; }
    fi
    [ "$(sha "$f")" = "$want" ] || die "kodim$i.png: sha256 $(sha "$f"), not $want"
    # the reference: the pixels of the PNG without its chunks (gAMA, sRGB, tEXt)
    vips copy "$f" "$W/img/full/k$i.png[keep=none]" || die "vips copy kodim$i.png"
    w="$(vipsheader -f width "$W/img/full/k$i.png")"
    h="$(vipsheader -f height "$W/img/full/k$i.png")"
    echo "$w	$h" > "$W/img/full/k$i.wh"
    # as the script: one width, a resize by width / 360, lanczos3
    sc="$(awk -v w="$w" 'BEGIN { printf "%.10f", 360 / w }')"
    vips resize "$W/img/full/k$i.png" "$W/img/360/k$i.png[keep=none]" "$sc" --kernel lanczos3 || die "vips resize kodim$i.png"
    echo "$(vipsheader -f width "$W/img/360/k$i.png")	$(vipsheader -f height "$W/img/360/k$i.png")" > "$W/img/360/k$i.wh"
done
IMAGES="$(cd "$W/img/full" && ls k*.png | sed 's/\.png$//' | head -n "$NIMG" | tr '\n' ' ')"
echo "- photos ($n): kodim01..kodim$(printf '%02d' "$n").png of Kodak Lossless True Color Image Suite, sha256 as tools/avif-bench/kodak.sha256 (from:$(echo "$src_used" | tr ' ' '\n' | sort | uniq -c | tr '\n' ' ' | sed 's/  */ /g')); 360 px: vips resize <360/width> --kernel lanczos3 (the script, one width)" >> "$head"
echo "- 360 px sizes: $(cat "$W"/img/360/*.wh | sort | uniq -c | tr '\t\n' 'x;' )" >> "$head"

case "$part" in
lossy-360) SETS=360 ;;
lossy-full) SETS=full ;;
lossless) SETS="360 full" ;;
*) die "no part $part" ;;
esac

# rotate <n> <words>: the words turned n times, so that the order changes from round to round
rotate() {
    n="$1"; shift
    i=0
    while [ "$i" -lt "$n" ]; do
        f="$1"; shift; set -- "$@" "$f"; i=$((i + 1))
    done
    echo "$@"
}

# ---- with losses

if [ "$part" != lossless ]; then
    echo "set	image	config	q	bytes	width	height	ssimulacra2	butteraugli_max	butteraugli_p3	maxdiff	ndiff	psnr_rgb	psnr_y	ssim_y" > "$W/sweep.tsv"
    echo "set	image	config	q	threads	round	bytes	wall_us	cpu_us" > "$W/timing.tsv"
    echo "check	set	config	q	image	same	note" > "$W/checks.tsv"
    for s in $SETS; do
        # the sweep: the slow configurations first, so that the parallel encodes end together
        say "sweep $s: $(echo "$CONFIGS" | wc -w | tr -d ' ') configurations x $(echo "$IMAGES" | wc -w | tr -d ' ') photos x $(echo "$QS" | wc -w | tr -d ' ') Q, $JOBS at a time"
        for c in aom-s2-iq svt-p2-iq svt-p3-iq svt-p3-iq-t1 aom-s5-iq aom-s5-ssim aom-s6-iq $CONFIGS; do
            case " $CONFIGS " in *" $c "*) ;; *) continue ;; esac
            for im in $IMAGES; do echo "$s $im $c"; done
        done | awk '!seen[$0]++' | xargs -n 3 -P "$JOBS" sh "$self" _sweep
        cat "$W"/rows/"$s"-*.tsv >> "$W/sweep.tsv"
        say "sweep $s: $(grep -c "^$s	" "$W/sweep.tsv") rows, $(grep -c . "$W/fails") failures so far"

        # SVT-AV1 4.3.0 (the package) against 4.3.1: the same files?
        say "checks $s: SVT-AV1 4.3.0 against 4.3.1, heifbench against vips heifsave"
        for c in svt-p5-psnr svt-p5-iq svt-p2-iq; do
            case " $CONFIGS " in *" $c "*) ;; *) continue ;; esac
            for q in $QS; do
                [ "$c" != svt-p5-psnr ] && [ "$q" != 75 ] && continue
                for im in $IMAGES; do
                    a="$W/enc/$s/$c/$im-q$q.avif"
                    [ -s "$a" ] || continue
                    # shellcheck disable=SC2046
                    set -- $(cfg "$c" "$q"); enc="$1"; shift
                    o="$W/enc430/$s/$c"; mkdir -p "$o"
                    env LD_LIBRARY_PATH="$LDP" "$HB" "$W/img/$s/$im.png" "$o/$im-q$q.avif" "$enc" "$q" 1 "$@" > /dev/null 2>&1 || true
                    if cmp -s "$a" "$o/$im-q$q.avif"; then same=yes; else same=no; fi
                    echo "svt 4.3.0 = 4.3.1	$s	$c	$q	$im	$same	" >> "$W/checks.tsv"
                done
            done
        done
        # heifbench against vips heifsave (the packages: libheif 1.23.7 with SVT-AV1 4.3.0, libaom),
        # VIPS_CONCURRENCY=1 (threads 1)
        for q in 75 80; do
            for im in $IMAGES; do
                v="$W/vips/$s"; mkdir -p "$v"
                if [ -s "$W/enc430/$s/svt-p5-psnr/$im-q$q.avif" ]; then
                    env VIPS_CONCURRENCY=1 vips heifsave "$W/img/$s/$im.png" "$v/$im-svt-q$q.avif" --Q "$q" --effort 4 \
                        --compression av1 --encoder svt --keep none > /dev/null 2>&1 || true
                    if cmp -s "$v/$im-svt-q$q.avif" "$W/enc430/$s/svt-p5-psnr/$im-q$q.avif"; then same=yes; note=""; else
                        same=no; note="$(bytes "$v/$im-svt-q$q.avif" 2> /dev/null) against $(bytes "$W/enc430/$s/svt-p5-psnr/$im-q$q.avif") B"; fi
                    echo "heifbench = vips heifsave	$s	svt-p5-psnr	$q	$im	$same	$note" >> "$W/checks.tsv"
                fi
                # the same with the libheif of the build (-march=x86-64-v3, as ours) in the place of that of the package
                if [ -s "$W/enc430/$s/svt-p5-psnr/$im-q$q.avif" ]; then
                    env LD_LIBRARY_PATH="$LDP" VIPS_CONCURRENCY=1 vips heifsave "$W/img/$s/$im.png" "$v/$im-svt-ours-q$q.avif" --Q "$q" --effort 4 \
                        --compression av1 --encoder svt --keep none > /dev/null 2>&1 || true
                    if cmp -s "$v/$im-svt-ours-q$q.avif" "$W/enc430/$s/svt-p5-psnr/$im-q$q.avif"; then same=yes; note=""; else
                        same=no; note="$(bytes "$v/$im-svt-ours-q$q.avif" 2> /dev/null) against $(bytes "$W/enc430/$s/svt-p5-psnr/$im-q$q.avif") B"; fi
                    echo "heifbench = vips heifsave, libheif of the build	$s	svt-p5-psnr	$q	$im	$same	$note" >> "$W/checks.tsv"
                fi
                if [ -s "$W/enc/$s/aom-s5-iq/$im-q$q.avif" ]; then
                    env LD_LIBRARY_PATH="$LDP" VIPS_CONCURRENCY=1 vips heifsave "$W/img/$s/$im.png" "$v/$im-aom-ours-q$q.avif" --Q "$q" --effort 4 \
                        --compression av1 --encoder aom --tune iq --keep none > /dev/null 2>&1 || true
                    if cmp -s "$v/$im-aom-ours-q$q.avif" "$W/enc/$s/aom-s5-iq/$im-q$q.avif"; then same=yes; note=""; else
                        same=no; note="$(bytes "$v/$im-aom-ours-q$q.avif" 2> /dev/null) against $(bytes "$W/enc/$s/aom-s5-iq/$im-q$q.avif") B"; fi
                    echo "heifbench = vips heifsave, libheif of the build	$s	aom-s5-iq	$q	$im	$same	$note" >> "$W/checks.tsv"
                fi
                for c in aom-s5-iq; do
                    [ -s "$W/enc/$s/$c/$im-q$q.avif" ] || continue
                    env VIPS_CONCURRENCY=1 vips heifsave "$W/img/$s/$im.png" "$v/$im-$c-q$q.avif" --Q "$q" --effort 4 \
                        --compression av1 --encoder aom --tune iq --keep none > /dev/null 2>&1 || true
                    if cmp -s "$v/$im-$c-q$q.avif" "$W/enc/$s/$c/$im-q$q.avif"; then same=yes; note=""; else
                        same=no; note="$(bytes "$v/$im-$c-q$q.avif" 2> /dev/null) against $(bytes "$W/enc/$s/$c/$im-q$q.avif") B"; fi
                    echo "heifbench = vips heifsave	$s	$c	$q	$im	$same	$note" >> "$W/checks.tsv"
                done
            done
        done

        # the time: threads 1 on the last CPU, the rounds interleaved; SVT-AV1 4.3.0 of the package too
        tcfg="$CONFIGS svt430-p5-psnr"
        r=1
        while [ "$r" -le "$ROUNDS" ]; do
            say "time $s: round $r of $ROUNDS (threads 1, Q 75 and 80)"
            for c in $(rotate $((r - 1)) $tcfg); do
                for q in 75 80; do
                    # shellcheck disable=SC2046
                    set -- $(cfg "$c" "$q" 1); enc="$1"; shift
                    for im in $IMAGES; do
                        l="$(pin env LD_LIBRARY_PATH="$(ldp_of "$c")" "$HB" "$W/img/$s/$im.png" "$W/t.avif" "$enc" "$q" 1 "$@" 2> /dev/null)" ||
                            { echo "$s $im $c Q$q: the time, round $r: heifbench failed" >> "$W/fails"; continue; }
                        printf '%s\t%s\t%s\t%s\t1\t%s\t%s\n' "$s" "$im" "$c" "$q" "$r" "$(echo "$l" | cut -f 2-4)" >> "$W/timing.tsv"
                    done
                done
            done
            r=$((r + 1))
        done
        # threads 4 (the wall time of one photo on 4 CPUs), Q 75, one round; the same file as threads 1?
        say "time $s: threads 4"
        for c in $CONFIGS; do
            # shellcheck disable=SC2046
            set -- $(cfg "$c" 75 4); enc="$1"; shift
            for im in $IMAGES; do
                l="$(env LD_LIBRARY_PATH="$(ldp_of "$c")" "$HB" "$W/img/$s/$im.png" "$W/t4.avif" "$enc" 75 1 "$@" 2> /dev/null)" || continue
                printf '%s\t%s\t%s\t75\t4\t1\t%s\n' "$s" "$im" "$c" "$(echo "$l" | cut -f 2-4)" >> "$W/timing.tsv"
                if cmp -s "$W/t4.avif" "$W/enc/$s/$c/$im-q75.avif"; then same=yes; else same=no; fi
                echo "threads 4 = threads 1	$s	$c	75	$im	$same	" >> "$W/checks.tsv"
            done
        done
    done
fi

# ---- lossless

# lossless_cmd <format> <in.png> <out>: the command (the processes are timed whole)
lossless_cmd() {
    case "$1" in
    avif-aom-s5)  echo "env VIPS_CONCURRENCY=1 vips heifsave $2 $3 --lossless --compression av1 --encoder aom --effort 4 --keep none" ;;
    avif-aom-s2)  echo "env VIPS_CONCURRENCY=1 vips heifsave $2 $3 --lossless --compression av1 --encoder aom --effort 7 --keep none" ;;
    avif-svt-s5)  echo "env VIPS_CONCURRENCY=1 vips heifsave $2 $3 --lossless --compression av1 --encoder svt --effort 4 --keep none" ;;
    avif-aom-s5-hb) echo "env LD_LIBRARY_PATH=$LDP431 $HB $2 $3 aom lossless 1 speed=5 chroma=444 threads=1 auto-tiles=true enable-intrabc=false" ;;
    avif-svt-s5-hb) echo "env LD_LIBRARY_PATH=$LDP431 $HB $2 $3 svt lossless 1 speed=5 chroma=444 threads=1 auto-tiles=true enable-intrabc=false" ;;
    webp-vips-e4) echo "env VIPS_CONCURRENCY=1 vips webpsave $2 $3 --lossless --effort 4 --Q 75 --keep none" ;;
    webp-cwebp-z9) echo "cwebp -quiet -lossless -z 9 -metadata none $2 -o $3" ;;
    png-vips-c9)  echo "env VIPS_CONCURRENCY=1 vips pngsave $2 $3 --compression 9 --keep none" ;;
    png-vips-c9-all) echo "env VIPS_CONCURRENCY=1 vips pngsave $2 $3 --compression 9 --filter all --keep none" ;;
    jxl-e7)       echo "cjxl $2 $3 -d 0 -e 7 --num_threads=0 --quiet" ;;
    vips-load)    echo "env VIPS_CONCURRENCY=1 vips copy $2 $3" ;;
    esac
}
lossless_ext() { case "$1" in avif-*) echo avif ;; webp-*) echo webp ;; png-*) echo png ;; jxl-*) echo jxl ;; *) echo v ;; esac; }

if [ "$part" = lossless ]; then
    LFORMATS="$(echo "${AB_LOSSLESS:-avif-aom-s5 avif-aom-s5-hb avif-aom-s2 avif-svt-s5 avif-svt-s5-hb webp-vips-e4 webp-cwebp-z9 png-vips-c9 png-vips-c9-all jxl-e7 vips-load}" | tr ',' ' ')"
    echo "set	image	format	bytes	width	height	maxdiff	ndiff	psnr_rgb	psnr_y	ssim_y	round	wall_s	cpu_s" > "$W/lossless.tsv"
    echo "- lossless commands (<in> <out>): $(for f in $LFORMATS; do printf '%s: `%s`; ' "$f" "$(lossless_cmd "$f" '<in>' '<out>')"; done)" >> "$head"
    for s in $SETS; do
        mkdir -p "$W/ll/$s"
        r=1
        while [ "$r" -le "$ROUNDS" ]; do
            say "lossless $s: round $r of $ROUNDS"
            for f in $(rotate $((r - 1)) $LFORMATS); do
                for im in $IMAGES; do
                    # what failed in round 1 is not tried again
                    [ "$r" -gt 1 ] && grep -q "^$s $im $f, round 1:" "$W/fails" && continue
                    out="$W/ll/$s/$im-$f.$(lossless_ext "$f")"
                    rm -f "$out"
                    # shellcheck disable=SC2046
                    t="$(pin "$TM" -e "$W/ll.err" $(lossless_cmd "$f" "$W/img/$s/$im.png" "$out"))" ||
                        { echo "$s $im $f, round $r: $(grep -v -e '^Svt\[info' -e '^Svt\[warn' "$W/ll.err" | tail -n 3 | tr '\n' ' ')" >> "$W/fails"; continue; }
                    echo "$s	$im	$f	$t	$r" >> "$W/ll-times.tsv"
                done
            done
            r=$((r + 1))
        done
        say "lossless $s: decoding and comparing"
        for f in $LFORMATS; do
            for im in $IMAGES; do
                out="$W/ll/$s/$im-$f.$(lossless_ext "$f")"
                [ -s "$out" ] || continue
                ref="$W/img/$s/$im.png"
                p="$W/ll/d.png"
                rm -f "$p"
                case "$f" in
                avif-*) env LD_LIBRARY_PATH="$LDP" "$HEIFDEC" "$out" "$p" > /dev/null 2>&1 ;;
                webp-*) dwebp -quiet "$out" -o "$p" > /dev/null 2>&1 ;;
                png-*) cp "$out" "$p" ;;
                jxl-*) djxl "$out" "$p" --quiet > /dev/null 2>&1 || djxl "$out" "$p" > /dev/null 2>&1 ;;
                esac
                if [ "$f" = vips-load ]; then ic="-	-	-	-	-"
                elif [ -s "$p" ]; then ic="$("$IMGCMP" "$ref" "$p" 2> /dev/null)" || ic="-	-	-	-	-"
                else ic="-	-	-	-	-"; echo "$s $im $f: not decoded" >> "$W/fails"; fi
                wh="$(sed -n 1p "$W/img/$s/$im.wh")"
                awk -F '\t' -v s="$s" -v im="$im" -v f="$f" -v b="$(bytes "$out")" -v wh="$wh" -v ic="$ic" \
                    '$1 == s && $2 == im && $3 == f { print s "\t" im "\t" f "\t" b "\t" wh "\t" ic "\t" $6 "\t" $4 "\t" $5 }' \
                    "$W/ll-times.tsv" >> "$W/lossless.tsv"
            done
        done
    done
fi

# ---- the report

mkdir -p "$R/$part"
for t in sweep timing checks lossless; do
    [ -s "$W/$t.tsv" ] && cp "$W/$t.tsv" "$R/$part/$t.tsv"
done
if [ -s "$W/fails" ]; then
    { echo; echo "## failures ($(grep -c . "$W/fails"))"; echo; echo '```'; head -n 200 "$W/fails"; echo '```'; } >> "$head"
fi
python3 -I "$here/analyze.py" "$R/$part" "$R/$part.md" "$head" || die "analyze.py"
say "avif-bench $part: OK ($(cat "$R/$part"/*.tsv 2> /dev/null | wc -l | tr -d ' ') rows, $(grep -c . "$W/fails") failures; the report goes to the branch runs of azsupport/azsupport)"
exit 0
