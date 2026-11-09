#!/bin/sh
# ytdlp-test.sh - test the package yt-dlp of this tree (www/yt-dlp, installed:
# /usr/local/bin/yt-dlp) with our ffmpeg as the grabbers of KVS use them
# (admin/plugins/grabbers/classes/KvsGrabber.php of 6.4.0): the version of the
# port, the information of a video (--dump-json) and its download (-o file.tmp,
# -f best[height>=Q-15][height<=Q+15] and best) of an HLS stream from a local HTTP
# server: MPEG-TS segments with H.264 and AAC, as the video sites serve them, which
# yt-dlp downloads itself and fixes with our ffmpeg into MP4 (FFmpegFixupM3u8PP:
# ffprobe without -f, then -c copy -f mp4 -bsf:a aac_adtstoasc). The file must be
# an MP4 with h264 and aac of the length of the stream.
#
# Usage (FreeBSD, as root):
#   sh tools/ytdlp-test.sh --samples   only make the stream, with the ffmpeg package
#                                      of the ports (installed here; ours has no
#                                      HLS and MPEG-TS muxers)
#   sh tools/ytdlp-test.sh             the tests (with the stream made before)
#
# Results: ytdlp-results/tests.txt (one line per check, the summary at the end);
# exit status 0 when every check passed.
set -u
tools="$(cd "$(dirname "$0")" && pwd)"
res="${AZ_RESULTS:-$(pwd)/ytdlp-results}"
T="${YTDLP_TEST_WORK:-/var/tmp/ytdlp-test}"
yd=/usr/local/bin/yt-dlp
fp=/usr/local/bin/ffprobe
ref=/usr/local/bin/ffmpeg
samples_only=""; [ "${1:-}" = --samples ] && samples_only=1
mkdir -p "$res"
out="$res/tests.txt"
[ -n "$samples_only" ] && out="$res/samples.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
srv=""
finish() {
    [ -n "$srv" ] && kill "$srv" 2>/dev/null
    echo "tests: $ok ok, $bad failed" >> "$out"
    cat "$out"
    [ "$bad" = 0 ]
    exit $?
}

# --- the stream: 6 s, 640x360, H.264 and AAC, segments of 2 s, a master playlist
# with RESOLUTION (the height the grabber asks for) --------------------------------
if [ -n "$samples_only" ]; then
    rm -rf "$T"; mkdir -p "$T/hls"
    # the package of the ports, never ours: a repository of ours (priority 100, as
    # in the VM) would give its ffmpeg to pkg install ffmpeg
    if [ ! -x "$ref" ]; then
        : > "$res/pkg-ffmpeg.log"
        for r in FreeBSD-ports FreeBSD; do
            env ASSUME_ALWAYS_YES=yes pkg install -y -r "$r" ffmpeg-nox11 >> "$res/pkg-ffmpeg.log" 2>&1 && break
            env ASSUME_ALWAYS_YES=yes pkg install -y -r "$r" ffmpeg >> "$res/pkg-ffmpeg.log" 2>&1 && break
        done
    fi
    [ -x "$ref" ] || { fail "the ffmpeg package (for the stream) could not be installed: $(tail -n 2 "$res/pkg-ffmpeg.log" | tr '\n' ' ')"; finish; }
    note "the stream made with $("$ref" -hide_banner -version | head -n 1)"
    if (cd "$T/hls" && "$ref" -hide_banner -loglevel error -nostdin -y \
        -f lavfi -i testsrc2=size=640x360:rate=25:duration=6 -f lavfi -i sine=frequency=440:sample_rate=48000:duration=6 \
        -c:v libx264 -preset veryfast -pix_fmt yuv420p -g 25 -c:a aac -b:a 96k \
        -f hls -hls_time 2 -hls_playlist_type vod -hls_segment_filename 'v_%02d.ts' -master_pl_name master.m3u8 v.m3u8) \
        > "$res/samples.log" 2>&1 && [ -s "$T/hls/master.m3u8" ]; then
        pass "the stream: $(ls "$T/hls" | grep -c '\.ts$') segments, $(grep -o 'RESOLUTION=[0-9x]*' "$T/hls/master.m3u8")"
        touch "$T/.samples"
    else
        fail "the stream: $(tail -n 2 "$res/samples.log" | tr '\n' ' ')"
    fi
    finish
fi

[ -x "$yd" ] || { fail "no $yd (the package yt-dlp of the repository first)"; finish; }
[ -x "$fp" ] || { fail "no $fp (the package ffmpeg of the repository first)"; finish; }
[ -f "$T/.samples" ] || { fail "no stream in $T (sh tools/ytdlp-test.sh --samples first)"; finish; }

# the version: the DISTVERSION of the port
want="$(awk '$1 == "DISTVERSION=" { print $2; exit }' "$tools/../www/yt-dlp/Makefile" 2>/dev/null)"
v="$("$yd" --version 2>&1 | head -n 1)"
if [ -n "$want" ] && [ "$v" = "$want" ]; then pass "yt-dlp --version: $v (www/yt-dlp)"
else fail "yt-dlp --version: ${v:-nothing}, www/yt-dlp has ${want:-no DISTVERSION}"; fi
note "ffmpeg: $(/usr/local/bin/ffmpeg -hide_banner -version 2>&1 | head -n 1)"

# the HTTP server: the python of yt-dlp (its first line), on a free port of 127.0.0.1
py="$(head -n 1 "$yd" | sed -n 's/^#! *//p' | awk '{ print $1 }')"
[ -x "$py" ] || py="$(command -v python3 2>/dev/null || true)"
[ -n "$py" ] && [ -x "$py" ] || { fail "no python for the HTTP server (the first line of $yd: $(head -n 1 "$yd"))"; finish; }
port=""
for p in 18731 18732 18733 18734; do
    "$py" -m http.server --bind 127.0.0.1 --directory "$T/hls" "$p" > "$res/http.log" 2>&1 &
    srv=$!
    sleep 2
    if kill -0 "$srv" 2>/dev/null && fetch -q -o /dev/null "http://127.0.0.1:$p/master.m3u8" 2>/dev/null; then port="$p"; break; fi
    kill "$srv" 2>/dev/null; srv=""
done
[ -n "$port" ] || { fail "the HTTP server ($py -m http.server): $(tail -n 2 "$res/http.log" | tr '\n' ' ')"; finish; }
url="http://127.0.0.1:$port/master.m3u8"

# the information, as KvsGrabber asks for it (no proxy, user agent, account or cookies)
if "$yd" --socket-timeout 30 --no-check-certificates --dump-json "$url" > "$T/info.json" 2> "$res/info.log"; then
    h="$("$py" -c 'import json, sys; d = json.load(open(sys.argv[1])); print(d.get("height"), d.get("protocol"), d.get("ext"))' "$T/info.json" 2>/dev/null)"
    case "$h" in
        "360 m3u8_native mp4") pass "--dump-json: height, protocol, ext $h" ;;
        *) fail "--dump-json: height, protocol, ext ${h:-not read} (360 m3u8_native mp4)" ;;
    esac
else
    fail "--dump-json: $(tail -n 2 "$res/info.log" | tr '\n' ' ')"
fi

# the download into file.tmp, with the format of a quality of the grabber (360,
# +-15) and with best; the fixup of yt-dlp with our ffprobe and ffmpeg
probe() {
    "$fp" -v error -show_entries format=format_name,duration:stream=codec_name -of default=nw=1 "$1" 2>/dev/null |
        awk -F= '$1 == "format_name" { f = $2 } $1 == "duration" { d = int($2 + 0.5) } $1 == "codec_name" { c = c (c ? "," : "") $2 } END { print f, c, d "s" }'
}
for f in 'best[height>=345][height<=375]' best; do
    d="$T/dl-$(echo "$f" | tr -c 'a-z0-9\n' '_')"
    rm -rf "$d"; mkdir -p "$d"
    if "$yd" --socket-timeout 30 --no-check-certificates -o "$d/file.tmp" -f "$f" "$url" > "$res/dl.log" 2>&1; then
        v="$(probe "$d/file.tmp")"
        case "$v" in
            "mov,mp4,m4a,3gp,3g2,mj2 h264,aac 6s") pass "-f $f -o file.tmp: $v" ;;
            *) fail "-f $f -o file.tmp: ${v:-no file} (an MP4 with h264,aac of 6 s); $(grep -i -E 'fixup|ffmpeg|error' "$res/dl.log" | tail -n 2 | tr '\n' ' ')" ;;
        esac
        grep -q 'Fixing MPEG-TS in MP4 container' "$res/dl.log" && pass "-f $f: yt-dlp fixed the MPEG-TS with ffmpeg" ||
            fail "-f $f: no fixup of the MPEG-TS in the log of yt-dlp: $(tail -n 2 "$res/dl.log" | tr '\n' ' ')"
    else
        fail "-f $f -o file.tmp: $(tail -n 2 "$res/dl.log" | tr '\n' ' ')"
    fi
done
finish
