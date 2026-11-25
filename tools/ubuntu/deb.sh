#!/bin/sh
# tools/ubuntu/deb.sh - the Debian packages azsupport-ffmpeg and azsupport-imagemagick7 for Ubuntu
# 24.04 or 22.04 or Debian 13 or 12 (amd64) from the stage of tools/ubuntu/build.sh, with the
# same files as its archive (aZ, 25.11.2026: «насчет ффмпег и имеджмегик для убунту сделай и деб»):
#
#   azsupport-ffmpeg        /usr/local/bin/ffmpeg, ffprobe, /usr/local/share/licenses/ffmpeg/
#   azsupport-imagemagick7  /usr/local/bin/magick and the names linked to it,
#                    /usr/local/etc/ImageMagick-7 (our policy.xml),
#                    /usr/local/share/ImageMagick-7, /usr/local/lib/ImageMagick-<version>,
#                    /usr/local/share/licenses/ImageMagick7/
#
# each with /usr/local/share/doc/<package>/ (VERSIONS of the build, copyright, and the
# licences of the libraries inside its programs). The names are not those of the system
# (ffmpeg has the epoch 7 in Ubuntu and Debian: apt would take its 7:6.1.1 for newer than
# our 9.1 and replace ours), the files are in /usr/local as in the archive, so the packages
# ffmpeg and imagemagick of the system can stay. Depends: what dpkg-shlibdeps finds the programs
# link (glibc, zlib; libstdc++, libgcc_s and bzip2 for magick), fontconfig-config and
# fonts-dejavu-core for the text of magick (aZ, 25.11.2026: «ну давай раз рекомендуется»:
# Depends, not Recommends, which apt --no-install-recommends leaves out). preinst refuses a CPU that cannot
# run the level (x86-64-v3: AVX2 and the rest; the package of x86-64-v2 for others).
# Version: that of the program (ImageMagick 7.1.2-36 as 7.1.2.36, as its FreeBSD
# package) and the UTC time of the build, yymmddHHMM, as revision (newer builds upgrade),
# with ~<system> (9.1-2511251200~ubuntu22.04, 9.1-2511251200~debian12): which build dpkg -s
# shows.
#
# Usage: sh tools/ubuntu/deb.sh <stage> <x86-64-v3|x86-64-v2> <out> <results> <system>
#   <system>: ubuntu24.04, ubuntu22.04, debian13 or debian12 (ID and VERSION_ID of os-release)
# Files: <out>/azsupport-ffmpeg-<rel>-amd64-<v3|v2>.deb, azsupport-imagemagick7-<rel>-amd64-<v3|v2>.deb
# (rel: ubuntu24, ubuntu22, debian13, debian12) and a .sha256 of each; <results>/debs.txt
# (dpkg-deb --info of each).
# Exit status: 0 built, 1 a package failed, 2 usage.

set -u
here="$(cd "$(dirname "$0")" && pwd)"
sources="$here/sources.conf"
u="usage: sh tools/ubuntu/deb.sh <stage> <level> <out> <results> <ubuntu24.04|ubuntu22.04|debian13|debian12>"
stage="${1:?$u}"
cputype="${2:?$u}"
out="${3:?$u}"
res="${4:?$u}"
sys="${5:?$u}"
case "$cputype" in x86-64-v2|x86-64-v3) ;; *) echo "ubuntu/deb: the level is x86-64-v3 or x86-64-v2, not $cputype" >&2; exit 2 ;; esac
level="${cputype#x86-64-}"
case "$sys" in
    ubuntu24.04|ubuntu22.04) os_name="Ubuntu ${sys#ubuntu}" ;;
    debian13|debian12) os_name="Debian ${sys#debian}" ;;
    *) echo "ubuntu/deb: the system is ubuntu24.04, ubuntu22.04, debian13 or debian12, not $sys" >&2; exit 2 ;;
esac
rel="${sys%%.*}"
F=/usr/local
L="$stage$F"
[ -x "$L/bin/ffmpeg" ] && [ -x "$L/bin/magick" ] || { echo "ubuntu/deb: no $L/bin/ffmpeg or $L/bin/magick (tools/ubuntu/build.sh first)" >&2; exit 2; }
work="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-deb.XXXXXX")" || exit 1
rev="${AZSUPPORT_DEB_REVISION:-$(date -u +%y%m%d%H%M)}"
src_ver() { awk -v n="$1" '$1 == n { print $2 }' "$sources"; }
ffver="$(src_ver ffmpeg)"
imver="$(src_ver imagemagick7 | tr '-' '.')"
imdir="$(cd "$L/lib" && ls -d ImageMagick-7.* 2>/dev/null | head -n 1)"
[ -n "$ffver" ] && [ -n "$imver" ] && [ -n "$imdir" ] || { echo "ubuntu/deb: no version of ffmpeg or imagemagick7 in sources.conf, or no $L/lib/ImageMagick-7.*" >&2; exit 1; }

# the flags of /proc/cpuinfo each level needs (x86-64-v2: the psABI level; v3 also AVX,
# AVX2, BMI1, BMI2, F16C, FMA, LZCNT (abm), MOVBE, XSAVE)
v2flags="cx16 lahf_lm popcnt sse4_1 sse4_2 ssse3"
v3flags="$v2flags avx avx2 bmi1 bmi2 f16c fma abm movbe xsave"
if [ "$level" = v3 ]; then need="$v3flags"; else need="$v2flags"; fi

# shdeps <file>...: the Depends of what the programs link, by dpkg-shlibdeps (it reads
# debian/control: a directory of its own), with the libraries of the packages of the system
# first (LD_LIBRARY_PATH): ld.so.conf has /usr/local/lib before them, where a library
# of no package (a libz.so.1 of its own) leaves dpkg-shlibdeps without its package
shdeps() {
    d="$work/shlibdeps"
    rm -rf "$d" && mkdir -p "$d/debian" &&
        printf 'Source: azsupport\n\nPackage: azsupport\nArchitecture: amd64\n' > "$d/debian/control" &&
        (cd "$d" && LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu dpkg-shlibdeps -O "$@" 2>> "$res/shlibdeps.log") |
        sed -n 's/^shlibs:Depends=//p'
}

# pkg <name> <version> <section> <depends add> <recommends> <libraries> <summary>
#     <description file> <files...>: one package from the stage
pkg() {
    n="$1" v="$2" sec="$3" dadd="$4" rec="$5" libs="$6" sum="$7" desc="$8"; shift 8
    r="$work/$n"
    rm -rf "$r" && mkdir -p "$r/DEBIAN" "$r$F/share/doc/$n/licenses" || return 1
    # the files, with their links, as in the stage
    (cd "$stage" && tar -cf - "$@") | (cd "$r" && tar -xpf -) || { echo "== $n: the files of the stage"; return 1; }
    cp "$L/share/doc/azsupport-$rel/VERSIONS" "$r$F/share/doc/$n/VERSIONS" || return 1
    for l in $libs; do
        [ -d "$L/share/licenses/azsupport-$rel/$l" ] || { echo "== $n: no licence of $l in the stage"; return 1; }
        cp -R "$L/share/licenses/azsupport-$rel/$l" "$r$F/share/doc/$n/licenses/$l" || return 1
    done
    {
        echo "$sum, of azsupport/ports (tools/ubuntu/build.sh, https://github.com/azsupport/ports)"
        echo
        echo "The licence of the program: in $F/share/licenses (its directory); those of the"
        echo "libraries inside it: in $F/share/doc/$n/licenses/<library>. What it was built from:"
        echo "$F/share/doc/$n/VERSIONS."
    } > "$r$F/share/doc/$n/copyright"
    bins="$(cd "$r" && find usr -type f -perm -u+x | sed "s|^|$r/|")"
    # shellcheck disable=SC2086
    dep="$(shdeps $bins)"
    [ -n "$dep" ] || { echo "== $n: dpkg-shlibdeps gave no Depends ($(tail -n 3 "$res/shlibdeps.log" | tr '\n' ' '))"; return 1; }
    [ -z "$dadd" ] || dep="$dep, $dadd"
    {
        printf '%s\n' "Package: $n" "Version: $v-$rev~$sys" "Architecture: amd64" \
            "Maintainer: aZ <github@azsupport.com>" "Installed-Size: $(du -sk "$r/usr" | cut -f 1)" \
            "Depends: $dep"
        [ -z "$rec" ] || echo "Recommends: $rec"
        printf '%s\n' "Section: $sec" "Priority: optional" "Homepage: https://github.com/azsupport/ports" \
            "Description: $sum ($cputype, $os_name)"
        sed -e 's/^$/./' -e 's/^/ /' "$desc"
    } > "$r/DEBIAN/control"
    cat > "$r/DEBIAN/preinst" <<EOF
#!/bin/sh
# $n of $cputype: a CPU without $cputype would die on the first instruction of it
set -e
case "\$1" in
    install|upgrade)
        have=" \$(grep -m 1 '^flags' /proc/cpuinfo 2>/dev/null) "
        miss=""
        for f in $need; do
            case "\$have" in *" \$f "*) ;; *) miss="\$miss \$f" ;; esac
        done
        if [ -n "\$miss" ]; then
            echo "$n: this CPU lacks\$miss of $cputype: take the package of x86-64-v2" >&2
            exit 1
        fi
        ;;
esac
exit 0
EOF
    chmod 755 "$r/DEBIAN/preinst"
    (cd "$r" && find usr -type f -exec md5sum {} + | LC_ALL=C sort -k 2) > "$r/DEBIAN/md5sums" || return 1
    f="$n-$rel-amd64-$level.deb"
    dpkg-deb --root-owner-group -Zxz --build "$r" "$out/$f" > /dev/null || { echo "== $n: dpkg-deb --build failed"; return 1; }
    (cd "$out" && sha256sum "$f" > "$f.sha256") || return 1
    {
        echo "== $f: $(du -k "$out/$f" | cut -f 1) KB, sha256 $(cut -d ' ' -f 1 "$out/$f.sha256")"
        dpkg-deb --info "$out/$f" | sed -n '/^ Package:/,$p'
        echo "   files: $(dpkg-deb --contents "$out/$f" | wc -l | tr -d ' ')"
    } >> "$res/debs.txt"
}

mkdir -p "$out" "$res" || exit 1
: > "$res/debs.txt"
: > "$res/shlibdeps.log"

cat > "$work/ffmpeg.desc" <<EOF
ffmpeg and ffprobe in $F/bin with only what the video sites need
(multimedia/ffmpeg/files/ffmpeg.conf of azsupport/ports): the containers MP4, MOV,
Matroska and WebM, MPEG-TS, JPEG, PNG and WebP pictures; H.264 written by libx264 in
8-bit 4:2:0, what browsers play; AV1 by SVT-AV1 (and AVIF), read by dav1d; HEVC, VP9 and
VP8 read; AAC (and libfdk_aac); no network, only the protocols file and pipe.

The NVIDIA codecs and filters (tools/ubuntu/ffmpeg-nvidia.conf): h264_nvenc (8-bit
4:2:0), hevc_nvenc, av1_nvenc, the CUVID decoders, NVDEC (-hwaccel cuda), scale_cuda
and the other CUDA filters; they need the NVIDIA driver 530.41 or later at run time
(libcuda, libnvcuvid, libnvidia-encode). Without it ffmpeg works as without them.

Its libraries (x264, dav1d, SVT-AV1, libwebp, fdk-aac) are inside the programs; built
for $cputype. Nonfree: FFmpeg with libfdk_aac and libx264 is unredistributable
(configure); published by aZ on his responsibility, as the package ffmpeg of FreeBSD.
EOF
cat > "$work/imagemagick7.desc" <<EOF
magick in $F/bin, and the names linked to it (convert, identify, mogrify, composite,
montage, compare, stream, animate, display, import, magick-script; not conjure), with
only what the video sites need (graphics/ImageMagick7/files/imagemagick.conf of
azsupport/ports): JPEG (mozjpeg), PNG, WebP, GIF and BMP, HEIC and AVIF (libheif with
libde265, dav1d and SVT-AV1: AVIF in 8 or 10 bits), text (FreeType, fontconfig: the
fonts of the system), colour profiles (lcms2); Q16 HDRI, no modules.

Its policy, $F/etc/ImageMagick-7/policy.xml, allows only those formats: no SVG, MVG,
MSL, PDF, PostScript, TIFF, URL or delegates, no paths of /etc, ../ or @files.

Its libraries are inside it; built for $cputype.
EOF

rc=0
ffbins="usr/local/bin/ffmpeg usr/local/bin/ffprobe"
imbins="$(cd "$stage" && for b in usr/local/bin/*; do case "${b##*/}" in ffmpeg|ffprobe) ;; *) echo "$b" ;; esac; done)"
pkg azsupport-ffmpeg "$ffver" video "" "" "x264 dav1d svtav1 webp fdkaac nvcodec" \
    "FFmpeg $ffver for the video sites, with NVIDIA" "$work/ffmpeg.desc" \
    $ffbins usr/local/share/licenses/ffmpeg || rc=1
# shellcheck disable=SC2086
pkg azsupport-imagemagick7 "$imver" graphics "fontconfig-config, fonts-dejavu-core" "" \
    "png mozjpeg webp freetype2 expat fontconfig lcms2 libde265 dav1d svtav1 libheif" \
    "ImageMagick $(src_ver imagemagick7) for the video sites" "$work/imagemagick7.desc" \
    $imbins usr/local/etc/ImageMagick-7 usr/local/share/ImageMagick-7 "usr/local/lib/$imdir" \
    usr/local/share/licenses/ImageMagick7 || rc=1
cat "$res/debs.txt"
rm -rf "$work"
exit "$rc"
