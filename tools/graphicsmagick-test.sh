#!/bin/sh
# graphicsmagick-test.sh - test GraphicsMagick of tools/graphicsmagick-build.sh
# (the package GraphicsMagick of the port graphics/GraphicsMagick, installed:
# /usr/local/bin/gm) as the video sites use it, and that what
# graphics/GraphicsMagick/files/graphicsmagick.conf leaves out is refused.
#
# Usage (FreeBSD, the package GraphicsMagick installed): sh tools/graphicsmagick-test.sh
#
# The samples are those of tools/imagemagick-test.sh --samples (made with the
# official ImageMagick7 package before ours is installed, in IM_TEST_WORK, default
# /var/tmp/imagemagick-test; it keeps them): JPEG (also a 4032x3024 photo and
# CMYK), PNG with alpha, WebP (lossy, lossless, animated), animated GIF, HEIC,
# AVIF, and the files made only to be refused. Without them this test stops and
# says so. Checked: the features of gm version (those of the conf, nothing else);
# the formats (gm convert -list format: only those of the format lines of the
# conf); gm identify of every sample; the conversions of a site (thumbnail to
# JPEG, resize to WebP, HEIC and AVIF to JPEG, the first frame of an animation,
# all frames, the BMP intermediate the sites write and read back, a PNG watermark
# with gm composite, text with -draw and label: with a font of the system, CMYK to
# RGB); refused, by content whatever the name: TIFF, MNG, SVG, MVG, MSL,
# PostScript, EPS, PDF, also as photo.jpg, and the coders of text, PostScript, MVG,
# MSL and MIFF by name; no delegate in delegates.mgk (of /usr/local/lib and of
# /usr/local/az/lib). label:@file reads the file (GraphicsMagick has no policy):
# a note, not a failure (graphicsmagick.conf).
#
# Results: AZ_RESULTS (default graphicsmagick-results/ of the current directory):
# tests.txt (one line per check, the summary at the end); exit status 0 when every
# check passed.

set -u
tools="$(cd "$(dirname "$0")" && pwd)"
conf="${AZ_GM_CONF:-$tools/../graphics/GraphicsMagick/files/graphicsmagick.conf}"
res="${AZ_RESULTS:-$(pwd)/graphicsmagick-results}"
T="${IM_TEST_WORK:-/var/tmp/imagemagick-test}"
W="${GM_TEST_WORK:-/var/tmp/graphicsmagick-test}"
A="${AZ_PREFIX:-/usr/local/az}"
pfx="${GM_PREFIX:-/usr/local}"
gm="$pfx/bin/gm"
mkdir -p "$res"
rm -rf "$W"; mkdir -p "$W"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
finish() {
    echo "tests: $ok ok, $bad failed" >> "$out"
    cat "$out"
    [ "$bad" = 0 ]
    exit $?
}
last() { tail -n 2 "$1" | tr '\n' ' ' | sed -e "s#$T/##g" -e "s#$W/##g"; }
conf_opts() { awk -v k="$1" '$1 == k { for (i = 2; i <= NF; i++) print $i }' "$conf"; }

[ -x "$gm" ] || { fail "no $gm (the port graphics/GraphicsMagick first)"; finish; }
[ -f "$conf" ] || { fail "no $conf (AZ_GM_CONF)"; finish; }
[ -f "$T/.samples" ] || { fail "no samples in $T: sh tools/imagemagick-test.sh --samples first (with the official ImageMagick7 package)"; finish; }

# --- the program -----------------------------------------------------------------
"$gm" version > "$W/version.txt" 2>&1 || { fail "gm version: $(last "$W/version.txt")"; finish; }
pass "$(head -n 1 "$W/version.txt" | cut -c1-80)"
# the lines of "Feature Support:", "  <name, 26 columns> yes|no [(text)]"; a name
# ending in * is the beginning of one ("HEIF/HVEC ("HEIC")" of 1.3.42)
feat() {
    awk -v f="$1" '
        p { n = substr($0, 3, 26); sub(/ +$/, "", n)
            if (n == f || (substr(f, length(f)) == "*" && index(n, substr(f, 1, length(f) - 1)) == 1)) {
                s = substr($0, 30); sub(/ .*/, "", s); print s; exit } }
        /^Feature Support:/ { p = 1 }' "$W/version.txt"
}
for f in FreeType "HEIF*" JPEG "Little CMS" PNG WebP ZLIB; do
    v="$(feat "$f")"
    [ "$v" = yes ] && pass "feature $f" || fail "feature $f: ${v:-not in gm version}"
done
for f in BZIP DPS FlashPix "Ghostscript (Library)" JBIG JPEG-2000 "JPEG XL" "Loadable Modules" OpenMP TIFF WMF X11 XML; do
    v="$(feat "$f")"
    case "$v" in
        no) pass "no feature $f" ;;
        "") note "feature $f is not in gm version" ;;
        *) fail "feature $f: $v (graphicsmagick.conf leaves it out)" ;;
    esac
done
# the formats: only those of the format lines
"$gm" convert -list format > "$W/formats.txt" 2>&1 || { fail "gm convert -list format: $(last "$W/formats.txt")"; finish; }
have="$(awk '$2 ~ /^[PSUB]$/ && $3 ~ /^[r-][w-][+-]$/ { print $1 }' "$W/formats.txt" | tr '\n' ' ')"
allowed=" $(conf_opts format | tr '\n' ' ') "
other=""
for x in $have; do case "$allowed" in *" $x "*) ;; *) other="$other $x" ;; esac; done
[ -z "$other" ] && pass "formats: $have" || fail "formats not in graphicsmagick.conf:$other"
for x in JPEG PNG GIF WEBP BMP HEIC AVIF XC LABEL; do
    case " $have " in *" $x "*) ;; *) fail "no format $x" ;; esac
done
# no delegate program
for d in "$pfx/lib/GraphicsMagick/config/delegates.mgk" "$A/lib/GraphicsMagick/config/delegates.mgk"; do
    if [ ! -f "$d" ]; then fail "no $d"
    elif grep -q '<delegate ' "$d"; then fail "$d has delegates: $(grep -c '<delegate ' "$d")"
    else pass "no delegate in $d"; fi
done

# --- the samples -----------------------------------------------------------------
for s in $(cat "$T/samples"); do
    if "$gm" identify "$T/$s" > "$W/i.log" 2>&1; then
        pass "identify $s: $(head -n 1 "$W/i.log" | sed "s#$T/##" | cut -c1-90)"
    else
        case "$s" in
            # libwebp's WebPDecode of GraphicsMagick reads no animation
            anim.webp) note "identify $s: $(last "$W/i.log")" ;;
            *) fail "identify $s: $(last "$W/i.log")" ;;
        esac
    fi
done
has() { grep -q -x -F "$1" "$T/samples"; }
# conv <name> <check: geometry WxH, frames N, or ok> <gm arguments...>
conv() {
    n="$1"; c="$2"; shift 2
    if "$gm" "$@" > "$W/c.log" 2>&1; then
        o="$(eval "printf '%s' \"\${$#}\"")"
        case "$c" in
            ok) pass "$n" ;;
            frames*)
                k="$("$gm" identify "$o" 2>/dev/null | wc -l | tr -d ' ')"
                [ "$k" = "${c#frames }" ] && pass "$n: $k frames" || fail "$n: $k frames, not ${c#frames }" ;;
            *)
                g="$("$gm" identify -format '%wx%h' "$o" 2>/dev/null | head -n 1)"
                [ "$g" = "$c" ] && pass "$n: $g" || fail "$n: $g, not $c" ;;
        esac
    else
        fail "$n: $(last "$W/c.log")"
    fi
}
has photo.jpg && conv "thumbnail JPEG" 320x240 convert "$T/photo.jpg" -thumbnail 320x240 -quality 85 "$W/thumb.jpg"
has big.jpg && conv "resize a 4032x3024 photo to WebP" 1024x768 convert "$T/big.jpg" -resize 1024x768 "$W/big.webp"
has photo.heic && conv "HEIC to JPEG" 640x480 convert "$T/photo.heic" "$W/heic.jpg"
has photo.avif && conv "AVIF to JPEG" 640x480 convert "$T/photo.avif" "$W/avif.jpg"
has photo.webp && conv "WebP to JPEG" 640x480 convert "$T/photo.webp" "$W/webp.jpg"
has anim.gif && conv "the first frame of a GIF" "frames 1" convert "$T/anim.gif[0]" "$W/first.png"
has anim.gif && conv "all frames of a GIF" "frames 3" convert "$T/anim.gif" -resize 60x40 "$W/all.gif"
if has photo.jpg; then
    conv "BMP intermediate (written)" 800x600 convert "$T/photo.jpg" "$W/shot.bmp"
    conv "BMP intermediate (read back)" 400x300 convert "$W/shot.bmp" -resize 400x300 "$W/shot.jpg"
fi
has photo.jpg && has logo.png && conv "PNG watermark (gm composite)" 800x600 composite -gravity SouthEast "$T/logo.png" "$T/photo.jpg" "$W/wm.jpg"
font="$(ls /usr/local/share/fonts/dejavu/DejaVuSans.ttf 2>/dev/null || find /usr/local/share/fonts -name '*.ttf' 2>/dev/null | head -n 1)"
if [ -n "$font" ]; then
    conv "text with -draw (FreeType, ${font##*/})" 300x80 convert -size 300x80 xc:white -font "$font" -pointsize 24 -fill black -draw "text 10,40 'GraphicsMagick'" "$W/text.png"
    conv "label: (${font##*/})" ok convert -font "$font" -pointsize 24 label:GraphicsMagick "$W/label.png"
    # GraphicsMagick has no policy for @file (graphicsmagick.conf): a note, not a failure
    if "$gm" convert -font "$font" "label:@$T/secret.txt" "$W/at.png" > "$W/c.log" 2>&1; then
        note "label:@file reads the file (no policy in GraphicsMagick; the sites must not pass a user's text beginning with @)"
    else
        note "label:@file refused: $(last "$W/c.log")"
    fi
else
    fail "text: no TrueType font in /usr/local/share/fonts (the package dejavu of imagemagick-test.sh --samples)"
fi
if has cmyk.jpg; then
    if "$gm" convert "$T/cmyk.jpg" -colorspace RGB "$W/rgb.jpg" > "$W/c.log" 2>&1; then
        # the image type: ColorSeparation for CMYK, TrueColor for RGB
        o="$("$gm" identify -format '%r' "$W/rgb.jpg" 2>/dev/null | head -n 1)"
        case "$o" in
            ""|ColorSeparation*) fail "CMYK -> RGB: the image type is ${o:-not known}" ;;
            *) pass "CMYK -> RGB: $o" ;;
        esac
    else
        fail "CMYK -> RGB: $(last "$W/c.log")"
    fi
fi

# --- refused ---------------------------------------------------------------------
# refuse <what> <file or coder:file>: gm identify must fail
refuse() {
    if "$gm" identify "$2" > "$W/r.log" 2>&1; then
        fail "$1 was read: $(head -n 1 "$W/r.log" | sed -e "s#$T/##g" -e "s#$W/##g" | cut -c1-100)"
    else
        pass "refused $1: $(last "$W/r.log" | cut -c1-100)"
    fi
}
for f in no.tiff no.mng no.svg no.mvg no.msl no.ps no.eps no.pdf; do
    [ -f "$T/$f" ] && refuse "$f" "$T/$f"
done
# by content, whatever the name
for f in no.mvg no.svg no.ps no.pdf no.msl; do
    [ -f "$T/$f" ] || continue
    cp "$T/$f" "$W/as-${f#no.}.jpg" && refuse "$f named as-${f#no.}.jpg" "$W/as-${f#no.}.jpg"
done
# by the name of the coder
[ -f "$T/secret.txt" ] && refuse "txt:secret.txt" "txt:$T/secret.txt"
[ -f "$T/no.mvg" ] && refuse "mvg:no.mvg" "mvg:$T/no.mvg"
[ -f "$T/no.msl" ] && refuse "msl:no.msl" "msl:$T/no.msl"
[ -f "$T/no.ps" ] && refuse "ps:no.ps" "ps:$T/no.ps"
has photo.jpg && refuse "miff:photo.jpg" "miff:$T/photo.jpg"
finish
