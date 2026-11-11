#!/bin/sh
# ffmpeg-build.sh - build ffmpeg and ffprobe for the video sites (the package
# ffmpeg of the port multimedia/ffmpeg, in the place of that of the ports:
# /usr/local/bin/ffmpeg, /usr/local/bin/ffprobe) from the official FreeBSD port of
# multimedia/ffmpeg/files/ffmpeg.conf, with only the formats, codecs and protocols
# listed there (see the head of that file for why), against the shared libraries of
# the package az, /usr/local/az/lib (installed). Moved from
# tools/build-ffmpeg.sh of https://github.com/azsupport/php-src (08.11.2026).
#
# Usage (FreeBSD; the port multimedia/ffmpeg runs it in its post-fetch and do-build):
#   sh tools/ffmpeg-build.sh --tools    install the build tools (pkg)
#   sh tools/ffmpeg-build.sh --fetch    fetch the distfiles of the official port
#                                       into AZ_DISTDIR (its make fetch)
#   sh tools/ffmpeg-build.sh            build FFmpeg
#
# As tools/az-build.sh: the ports framework fetches the distfiles of the port at
# the ports commit of az/az/files/deps.conf (the official tree PORTSDIR, at that
# commit), checks them against its distinfo, extracts them and applies the port's
# patches (make patch), then those of files/ffmpeg/; this script then builds the
# source tree with its own options. A take line gives a new upstream release
# instead (from AZ_TAKE_DISTFILES, else fetched; with the port's patches, or those
# of files/deps/<name>-<version>/). FFmpeg links x264, dav1d, SVT-AV1 and libwebp, the
# shared libraries of AZ_PREFIX/lib (AZ_PREFIX: default /usr/local/az), with that
# run path (our ports link each other's shared libraries: aZ, 10.11.2026); its own
# libraries (libavcodec, libavformat ...) are in its two programs, which need
# nothing else of /usr/local (libc, libm, libthr and libz of the base system), and
# is installed (prefix /usr/local) into the stage AZ_STAGE/ffmpeg (default
# AZ_WORK/stage/ffmpeg): usr/local/bin/ffmpeg, usr/local/bin/ffprobe,
# usr/local/share/licenses/ffmpeg/, usr/local/share/doc/ffmpeg/VERSIONS
# (AZ_STAGEDIR: the stage itself). Its work directory is AZ_WORK/ffmpeg (default
# /var/tmp/az-work/ffmpeg). Results go to AZ_RESULTS (default ffmpeg-results/ of
# the current directory: summary.txt, the log, VERSIONS); the summary is printed at
# the end. tools/ffmpeg-test.sh tests it, once installed.
#
# Compiler flags as for PHP and the libraries: CPUTYPE and CFLAGS of
# /etc/make.conf with -fstack-protector-strong and -fno-strict-aliasing;
# AZ_CPUTYPE and AZ_CFLAGS win over make.conf
# (MAKE_CONF, default /etc/make.conf); without either: x86-64-v3 and -O3 -pipe.
# FFmpeg: LTO, PIE, RELRO and BIND_NOW (configure lines of ffmpeg.conf); its own
# assembly picks the instructions of the CPU at run time.
#
# Exit status: 0 built, 1 FFmpeg failed, the libraries are not there, or this CPU
# cannot run the level, 2 usage.

set -u
# A build as from a shell. The make of the port that runs this script leaves its
# MAKEFLAGS in the environment: its command line and the variables the framework
# hands to sub-makes (.MAKEFLAGS of bsd.port.mk: ARCH=amd64, OPSYS, OSVERSION, ...),
# which every gmake here would take as variables of its own command line, above
# those of the Makefiles: FFmpeg's ARCH=x86 became ARCH=amd64, so no x86 object
# was built (ld: undefined symbol ff_bwdif_init_x86 ..., 08.11.2026).
unset MAKEFLAGS MFLAGS MAKELEVEL __MKLVL__
tools="$(cd "$(dirname "$0")" && pwd)"
# the conf and patches: files/ of the port multimedia/ffmpeg; the ports commit: deps.conf of az/az
files="${AZ_FILESDIR:-$tools/../multimedia/ffmpeg/files}"
conf="$files/ffmpeg.conf"
# AZ_FFMPEG_NONFREE=yes (the port multimedia/ffmpeg-nonfree, nonfree/ffmpeg/Makefile.in):
# the lines of files/ffmpeg-nonfree.conf too, its programs before FFmpeg and its
# configure lines after those of ffmpeg.conf (after --disable-everything). FFmpeg with
# libfdk_aac and libx264 needs --enable-nonfree: its programs may not be given to anyone.
nonfree="${AZ_FFMPEG_NONFREE:-}"
case "$nonfree" in yes) ;; ""|no) nonfree="" ;; *) echo "ffmpeg-build: AZ_FFMPEG_NONFREE is yes or empty, not $nonfree" >&2; exit 2 ;; esac
deps_conf="${AZ_DEPS_CONF:-$tools/../az/az/files/deps.conf}"
# the shared tree of az (its libraries, .pc files and headers)
A="${AZ_PREFIX:-/usr/local/az}"
work="${AZ_WORK:-/var/tmp/az-work}/ffmpeg"
F=/usr/local
stage="${AZ_STAGEDIR:-${AZ_WORK:-/var/tmp/az-work}/stage/ffmpeg}"
res="${AZ_RESULTS:-$(pwd)/ffmpeg-results}"
ports="${PORTSDIR:-/usr/ports}"
distdir="${AZ_DISTDIR:-$work/distfiles}"
takedist="${AZ_TAKE_DISTFILES:-$(pwd)/distfiles}"
ncpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 2)"
major="$(uname -r | cut -d. -f1)"

if [ "${1:-}" = "--tools" ]; then
    pkgs="git meson ninja nasm gmake perl5 pkgconf python3"
    # fdk-aac of the nonfree build: cmake
    [ -z "$nonfree" ] || pkgs="$pkgs cmake"
    # shellcheck disable=SC2086
    env ASSUME_ALWAYS_YES=yes pkg install -y $pkgs
    rc=$?
    for t in $pkgs; do pkg info -e "$t" || echo "ffmpeg-build: package $t is not installed"; done
    exit $rc
fi
[ -f "$conf" ] || { echo "ffmpeg-build: no $conf (AZ_FILESDIR: files/ of the port multimedia/ffmpeg)" >&2; exit 2; }
if [ -n "$nonfree" ]; then
    nfc="$files/ffmpeg-nonfree.conf"
    [ -f "$nfc" ] || { echo "ffmpeg-build: AZ_FFMPEG_NONFREE=yes, but no $nfc" >&2; exit 2; }
    mkdir -p "$work" || exit 2
    { awk '$1 == "program"' "$nfc"; cat "$conf"; awk '$1 == "configure"' "$nfc"; } > "$work/ffmpeg-nonfree.conf"
    conf="$work/ffmpeg-nonfree.conf"
fi
[ -f "$deps_conf" ] || { echo "ffmpeg-build: no $deps_conf (AZ_DEPS_CONF: deps.conf of the port az/az)" >&2; exit 2; }

say() { printf '[ffmpeg-build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

mk_conf="${MAKE_CONF:-/etc/make.conf}"
mc_get() {
    [ -r "$mk_conf" ] || return 0
    awk -v v="$1" '
        { sub(/#.*/, "") }
        $0 ~ "^[ \t]*" v "[ \t]*[?:]?=" { s = $0; sub("^[ \t]*" v "[ \t]*[?:]?=[ \t]*", "", s); val = s; have = 1; next }
        $0 ~ "^[ \t]*" v "[ \t]*\\+=" { s = $0; sub("^[ \t]*" v "[ \t]*\\+=[ \t]*", "", s); val = val " " s; have = 1 }
        END { if (have) { sub(/[ \t]+$/, "", val); print val } }
    ' "$mk_conf"
}

cputype="${AZ_CPUTYPE:-$(mc_get CPUTYPE)}"
cputype="${cputype:-x86-64-v3}"
opt="${AZ_CFLAGS:-$(mc_get CFLAGS)}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' ${opt:--O3 -pipe} | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
level="${cputype#x86-64-}"
# FFmpeg adds -fPIC itself (--enable-pic).
ffcflags="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing"
export CC=cc CXX=c++
export CFLAGS="$ffcflags -fPIC"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$A/include"
export LDFLAGS="-L$A/lib -Wl,-rpath,$A/lib"
export PKG_CONFIG_LIBDIR="$A/lib/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH
# LTO (FFmpeg) puts LLVM bitcode into its static archives: their index needs the ar
# of LLVM, taken by name when ar of the base system is another one.
unset AR RANLIB NM
if ! ar --version 2>/dev/null | grep -q LLVM && command -v llvm-ar >/dev/null 2>&1; then
    export AR=llvm-ar RANLIB=llvm-ranlib NM=llvm-nm
fi

ports_commit="$(awk '$1 == "ports" { print $2 }' "$deps_conf")"
libs_all="$(awk '$1 == "program" { print $2 }' "$conf")"
port_of() { awk -v n="$1" '$1 == "program" && $2 == n { print $3 }' "$conf"; }
take_of() { awk -v n="$1" '$1 == "take" && $2 == n { print $3, $4, $5, $6 }' "$conf"; }
conf_opts() { awk '$1 == "configure" { for (i = 2; i <= NF; i++) print $i }' "$conf"; }

# The official tree PORTSDIR has to be at the commit of deps.conf (as in
# tools/az-build.sh); it is only read here, never changed.
ports_check() {
    [ -f "$ports/Mk/bsd.port.mk" ] || { echo "ffmpeg-build: no ports tree in $ports (PORTSDIR)" >&2; return 1; }
    h="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    if [ -z "$h" ]; then
        echo "ffmpeg-build: $ports is not a git checkout: taken for freebsd-ports $ports_commit of deps.conf" >&2
        return 0
    fi
    [ "$h" = "$ports_commit" ] && return 0
    echo "ffmpeg-build: $ports is at $h, deps.conf has $ports_commit: build with the tree at that commit" >&2
    return 1
}
# JPEG_PORT as in make.conf of the servers: the ports with USES=jpeg (gd, ImageMagick) take mozjpeg.
# A make of its own, as from a shell: nothing of the make of the port that runs this
# script (MAKEFLAGS: its command line, its job server) reaches the official port.
pmake() {
    p="$1"; shift
    env -u MAKEFLAGS -u MFLAGS -u __MKLVL__ make -C "$ports/$p" BATCH=yes NO_DEPENDS=yes \
        DISABLE_VULNERABILITIES=yes JPEG_PORT=graphics/mozjpeg \
        PORTSDIR="$ports" WRKDIRPREFIX="$work/wrk" DISTDIR="$distdir" "$@"
}

fix_guess() {
    find "$1" \( -name config.guess -o -name config.sub \) -type f | while IFS= read -r f; do
        cp "$ports/Templates/${f##*/}" "$f" && chmod a+rx "$f"
    done
}
# fdk-aac (the nonfree build): the static library only, with the flags of FFmpeg, into
# the work directory; its .pc there comes first for the configure of FFmpeg
fdk="$work/fdk-aac"
b_fdkaac() {
    rm -rf "$fdk" "$1/az-build"
    cmake -S "$1" -B "$1/az-build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$fdk" \
        -DBUILD_SHARED_LIBS=OFF -DBUILD_PROGRAMS=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_C_FLAGS="$ffcflags" -DCMAKE_CXX_FLAGS="$ffcflags" &&
        cmake --build "$1/az-build" -j "$ncpu" && cmake --install "$1/az-build" || return 1
    [ -f "$fdk/lib/libfdk-aac.a" ] && [ -f "$fdk/lib/pkgconfig/fdk-aac.pc" ] || { echo "== no $fdk/lib/libfdk-aac.a or its .pc"; return 1; }
    mkdir -p "$work/licenses" && cp "$1/NOTICE" "$work/licenses/fdk-aac-NOTICE"
}
# FFmpeg: after the port's patches those of files/ffmpeg/ (in the order of their
# names), then configure with the options of the script and the configure lines
# of ffmpeg.conf (the nonfree build: with those of ffmpeg-nonfree.conf, and fdk-aac)
b_ffmpeg() {
    rm -rf "$stage"
    for p in "$files"/ffmpeg/*.patch; do
        [ -f "$p" ] || continue
        echo "== files/ffmpeg/${p##*/}"
        patch -p1 -N -s -d "$1" < "$p" || { echo "== ${p##*/} does not apply"; return 1; }
    done
    (
        cd "$1" || exit 1
        set -- --prefix="$F" --cc=cc --cxx=c++ --pkg-config=pkgconf --pkg-config-flags=--static \
            --extra-cflags="$ffcflags -I$A/include" --extra-cxxflags="$ffcflags -I$A/include" \
            --extra-ldflags="-L$A/lib -Wl,-rpath,$A/lib"
        if [ -n "${AR:-}" ]; then set -- "$@" --ar="$AR" --ranlib="$RANLIB" --nm="$NM -g"; fi
        [ -z "$nonfree" ] || export PKG_CONFIG_LIBDIR="$fdk/lib/pkgconfig:$PKG_CONFIG_LIBDIR"
        # shellcheck disable=SC2046
        ./configure "$@" $(conf_opts) && gmake -j"$ncpu" && gmake install-progs DESTDIR="$stage"
    ) || { cp "$1/ffbuild/config.log" "$res/ffmpeg-config.log" 2>/dev/null; return 1; }
    cp "$1/ffbuild/config.log" "$res/ffmpeg-config.log" 2>/dev/null
    mkdir -p "$stage$F/share/licenses/ffmpeg"
    for f in COPYING.GPLv2 COPYING.LGPLv2.1 LICENSE.md; do cp "$1/$f" "$stage$F/share/licenses/ffmpeg/$f"; done
    [ -z "$nonfree" ] || cp "$work/licenses/fdk-aac-NOTICE" "$stage$F/share/licenses/ffmpeg/fdk-aac-NOTICE"
}

take_args() {
    take_ver=""
    t="$(take_of "$1")"
    [ -n "$t" ] || return 0
    # shellcheck disable=SC2086
    set -- $t "$2"
    take_ver="$1"
    tf="${2%%,*}"; tf="${tf##*/}"
    mkdir -p "$work/distfiles"
    if [ ! -f "$work/distfiles/$tf" ] || [ "$(sha256 -q "$work/distfiles/$tf")" != "$3" ]; then
        rm -f "$work/distfiles/$tf"
        if [ -f "$takedist/$tf" ] && [ "$(sha256 -q "$takedist/$tf")" = "$3" ]; then
            # a distfile of the port (its fetch phase, checked against its distinfo)
            cp "$takedist/$tf" "$work/distfiles/$tf"
            echo "== $tf: from $takedist" >&2
        else
            # every address up to three times: a release file of GitHub sometimes stalls
            echo "== $tf: not in $takedist, fetched here" >&2
            for try in 1 2 3; do
                for u in $(echo "$2" | tr ',' ' '); do
                    fetch -q -T 60 -o "$work/distfiles/$tf" "$u" && break 2
                    echo "== fetch $u failed (try $try of 3)" >&2
                    rm -f "$work/distfiles/$tf"
                done
                [ "$try" = 3 ] || sleep $((try * 15))
            done
        fi
        [ -f "$work/distfiles/$tf" ] || return 1
    fi
    if [ "$(sha256 -q "$work/distfiles/$tf")" != "$3" ]; then
        echo "== $tf: SHA-256 $(sha256 -q "$work/distfiles/$tf"), not $3 as in ffmpeg.conf" >&2
        return 1
    fi
    printf 'TIMESTAMP = %s\nSHA256 (%s) = %s\nSIZE (%s) = %s\n' "$(date +%s)" "$tf" "$3" "$tf" \
        "$(stat -f %z "$work/distfiles/$tf")" > "$work/distinfo-take-$n"
    wd="$(pmake "$5" -V WRKDIR)"
    pd="$files/deps/$n-$take_ver"
    # its own DISTDIR: the ports' one (AZ_DISTDIR) may not be writable
    printf '%s\n' "DISTDIR=$work/distfiles" "DISTFILES=$tf" "PATCHFILES=" "DISTINFO_FILE=$work/distinfo-take-$n" "WRKSRC=$wd/$4"
    if [ -d "$pd" ]; then printf '%s\n' "PATCHDIR=$pd"; fi
}

# The patches the framework applies to a port: files/patch-* and EXTRA_PATCHES.
port_patches() {
    fd="$(pmake "$1" -V FILESDIR 2>/dev/null)"
    np="$(ls "$fd" 2>/dev/null | grep -c '^patch-')"
    ne="$(pmake "$1" -V EXTRA_PATCHES 2>/dev/null | wc -w | tr -d ' ')"
    echo $(( np + ne ))
}

build_one() {
    n="$1"
    port="$(port_of "$n")"
    log="$res/$n.log"
    start=$(date +%s)
    targs="$(take_args "$n" "$port" 2>"$res/$n.take")"
    trc=$?
    take_of "$n" | grep -q . && take_ver="$(take_of "$n" | awk '{ print $1 }')" || take_ver=""
    (
        if [ "$trc" != 0 ]; then cat "$res/$n.take"; echo "== $n: the release of the take line could not be had"; exit 1; fi
        if [ -n "$take_ver" ]; then
            echo "== $n: $port at $ports_commit with the release $take_ver of the take line in ffmpeg.conf:"
            # the failed tries before the one that worked
            [ ! -s "$res/$n.take" ] || cat "$res/$n.take"
            printf '   %s\n' $targs
        else
            echo "== $n: $port at $ports_commit"
        fi
        # shellcheck disable=SC2086
        pmake "$port" $targs clean >/dev/null 2>&1
        # shellcheck disable=SC2086
        pmake "$port" $targs patch || { echo "make patch failed"; exit 1; }
        # shellcheck disable=SC2086
        src="$(pmake "$port" $targs -V WRKSRC)"
        echo "== source: $src"
        "b_$n" "$src" || exit 1
    ) > "$log" 2>&1
    rc=$?
    ver="$(pmake "$port" -V PKGVERSION 2>/dev/null)"
    pkgname="$(pmake "$port" -V PKGNAME 2>/dev/null)"
    if [ -n "$take_ver" ]; then
        epoch="$(pmake "$port" -V PORTEPOCH 2>/dev/null)"
        case "$epoch" in ""|0) epoch="" ;; *) epoch=",$epoch" ;; esac
        pkgname="${pkgname%-*}-$take_ver$epoch"
        ver="$take_ver (port: $ver)"
    fi
    if [ "$rc" = 0 ]; then
        printf '%-8s OK    %-22s %-22s %4ss\n' "$n" "$ver" "$port" "$(( $(date +%s) - start ))" >> "$res/summary.txt"
        printf '%s %s %s\n' "$n" "$pkgname" "$port" >> "$res/built.txt"
    else
        printf '%-8s FAIL  %-22s %-22s %4ss (%s.log)\n' "$n" "$ver" "$port" "$(( $(date +%s) - start ))" "$n" >> "$res/summary.txt"
        tail -n 40 "$log" > "$res/$n.tail"
    fi
    say "$n: $(tail -n 1 "$res/summary.txt" | awk '{ print $2 }')"
    return "$rc"
}

manifest() {
    {
        echo "FFmpeg for FreeBSD $major (amd64, $cputype), built $(date '+%Y-%m-%d %H:%M %Z') on $(uname -sr)"
        echo "freebsd-ports $ports_commit; CFLAGS: $ffcflags"
        echo "x264, dav1d, SVT-AV1 and libwebp: the shared libraries of $A/lib (the package az, with that run path)"
        [ -z "$nonfree" ] || echo "fdk-aac: its static library, built here (the nonfree build, files/ffmpeg-nonfree.conf)"
        echo
        while read -r n pkgname port; do
            printf '%-8s %-24s %s\n' "$n" "$pkgname" "$port"
            t="$(take_of "$n")"
            if [ -n "$t" ]; then
                # shellcheck disable=SC2086
                set -- $t
                echo "    ${2##*/} sha256 $3 (upstream release $1, ahead of the port: take line of ffmpeg.conf)"
            else
                # the distfiles of the port (not those of options it has off, such as the
                # test data of dav1d), as distinfo has them (libx264: that of multimedia/x264)
                di="$(pmake "$port" -V DISTINFO_FILE 2>/dev/null)"
                for d in $(pmake "$port" -V DISTFILES 2>/dev/null); do
                    d="${d%%:*}"
                    awk -v d="$d" '$1 == "SHA256" { f = $2; gsub(/[()]/, "", f); b = f; sub(/.*\//, "", b)
                        if (b == d) print "    " f " sha256 " $4 }' "$di"
                done
            fi
            np="$(port_patches "$port")"
            [ "$np" -gt 0 ] && echo "    $np patches of the port"
            if [ "$n" = ffmpeg ]; then
                for p in "$files"/ffmpeg/*.patch; do
                    [ -f "$p" ] && echo "    files/ffmpeg/${p##*/}: $(head -n 1 "$p")"
                done
            fi
        done < "$res/built.txt"
        echo
        echo "configure (after --prefix=$F, the compiler and the flags):"
        conf_opts | sed 's/^/    /'
        echo
        if [ -n "$nonfree" ]; then
            echo "Licence: nonfree and unredistributable (FFmpeg with --enable-gpl and --enable-nonfree:"
            echo "x264 under the GPL and libfdk_aac under the licence of the Fraunhofer FDK AAC library);"
            echo "this package may not be given to anyone. The licences are in share/licenses/ffmpeg/"
            echo "(fdk-aac-NOTICE; x264, dav1d, SVT-AV1 and webp, shared libraries: LICENSES/ of /usr/local/az, the package az)."
        else
            echo "Licence: GPL version 2 or later (FFmpeg with --enable-gpl, x264); the licences are in"
            echo "share/licenses/ffmpeg/ (x264, dav1d, SVT-AV1 and webp, shared libraries: LICENSES/ of /usr/local/az, the package az)."
        fi
        echo "Sources: the distfiles above (their SHA-256), the patches of the port at the commit above,"
        echo "files/ffmpeg/ and tools/ffmpeg-build.sh of https://github.com/azsupport/ports (multimedia/ffmpeg/files/ffmpeg.conf)."
    } > "$res/VERSIONS"
}

# Hardening and links of the programs, for the report and the tests.
check_bins() {
    : > "$res/bins.txt"
    for b in ffmpeg ffprobe; do
        f="$stage$F/bin/$b"
        [ -x "$f" ] || { echo "$b: missing" >> "$res/bins.txt"; continue; }
        type="$(readelf -h "$f" | awk '/Type:/ { print $2 }')"
        relro="$(readelf -l "$f" | grep -c GNU_RELRO)"
        now="$(readelf -d "$f" | grep -c -E 'BIND_NOW|FLAGS_1.*NOW')"
        libs="$(ldd "$f" | awk 'NR > 1 { print $3 }' | tr '\n' ' ' | sed 's/ *$//')"
        rp="$(readelf -d "$f" | sed -n 's/.*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1/p')"
        printf '%s: %s KB, ELF type %s, RELRO %s, BIND_NOW %s, run path %s; libraries: %s\n' "$b" \
            "$(du -Ak "$f" | cut -f1)" "$type" "$relro" "$now" "${rp:-none}" "$libs" >> "$res/bins.txt"
        # the base system and the shared tree of az (by the run path), nothing else
        for l in $libs; do
            case "$l" in
                /lib/* | /usr/lib/*) ;;
                "$A"/static/*) echo "$b: $l of the static tree" ;;
                "$A"/lib/*) case ":$rp:" in *":$A/lib:"*) ;; *) echo "$b: $l without the run path $A/lib (${rp:-none})" ;; esac ;;
                *) echo "$b: $l, not of the base system or of az" ;;
            esac
        done >> "$res/bins-bad.txt"
        [ "$type" = DYN ] || echo "$b: not a PIE (ELF type $type)" >> "$res/bins-bad.txt"
        [ "$relro" -gt 0 ] || echo "$b: no RELRO" >> "$res/bins-bad.txt"
        [ "$now" -gt 0 ] || echo "$b: no BIND_NOW" >> "$res/bins-bad.txt"
    done
    "$stage$F/bin/ffmpeg" -hide_banner -version > "$res/version.txt" 2>&1
}

mkdir -p "$res" "$work"
# --fetch: the distfiles of the port, by its own make fetch into AZ_DISTDIR (the
# post-fetch of the port multimedia/ffmpeg), so that the build needs no network;
# not for a program with a take line (its release file is a distfile of our port)
if [ "${1:-}" = "--fetch" ]; then
    ports_check || exit 1
    rc=0
    for n in $libs_all; do
        if [ -n "$(take_of "$n")" ]; then echo "ffmpeg-build: $n: the release of its take line is a distfile of the port"; continue; fi
        say "fetch $n ($(port_of "$n"))"
        pmake "$(port_of "$n")" fetch || { echo "ffmpeg-build: $n: make fetch of $(port_of "$n") failed" >&2; rc=1; }
    done
    exit "$rc"
fi
[ $# -eq 0 ] || { echo "usage: sh tools/ffmpeg-build.sh [--tools | --fetch]" >&2; exit 2; }
report() {
    echo "== $res/summary.txt"
    cat "$res/summary.txt" "$res/bins.txt" 2>/dev/null
    for f in "$res"/*.tail "$res/bins-bad.txt"; do
        [ -s "$f" ] || continue
        echo "== $f"
        cat "$f"
    done
}
rm -f "$res"/*.tail "$res/bins-bad.txt"
: > "$res/summary.txt"; : > "$res/built.txt"
cpu_model="$(sysctl -n hw.model 2>/dev/null)"
printf 'flags:    %s\ncpu:      %s\n' "$ffcflags" "${cpu_model:-?}" >> "$res/summary.txt"
cpu_feats() {
    cc "-march=$1" -dM -E - < /dev/null 2>/dev/null |
        sed -n -E 's/^#define __(SSE4_2|POPCNT|AVX|AVX2|BMI|BMI2|FMA|F16C|LZCNT|MOVBE|AVX512F|AVX512BW|AVX512CD|AVX512DQ|AVX512VL)__ 1$/\1/p' |
        LC_ALL=C sort -u
}
cpu_feats "$cputype" > "$work/cpu-need"
cpu_feats native > "$work/cpu-have"
lacks="$(LC_ALL=C comm -23 "$work/cpu-need" "$work/cpu-have" | tr '\n' ' ' | sed 's/ *$//')"
if [ ! -s "$work/cpu-need" ] || [ -n "$lacks" ]; then
    why="${lacks:+lacks $lacks of}"
    printf '%-8s FAIL  this CPU (%s) %s -march=%s: code built for it cannot run here\n' \
        cpu "${cpu_model:-?}" "${why:-cannot tell the features of}" "$cputype" >> "$res/summary.txt"
    echo "ffmpeg-build: this CPU ${why:-cannot tell the features of} -march=$cputype" >&2
    exit 1
fi
for pc in x264 dav1d SvtAv1Enc libwebp; do
    if [ ! -f "$A/lib/pkgconfig/$pc.pc" ]; then
        printf '%-8s FAIL  no %s of the shared libraries in %s/lib/pkgconfig: install the package az first (az/az)\n' libs "$pc" "$A" >> "$res/summary.txt"
        echo "ffmpeg-build: no $A/lib/pkgconfig/$pc.pc; install the package az first (the port az/az)" >&2
        exit 1
    fi
done
ports_check || { echo "ports    FAIL  $ports is not freebsd-ports $ports_commit of deps.conf" >> "$res/summary.txt"; report; exit 1; }
rc=0
for n in $libs_all; do
    say "$n ($(port_of "$n"))"
    if ! build_one "$n"; then rc=1; break; fi
done
if [ "$rc" = 0 ]; then
    manifest
    check_bins
    mkdir -p "$stage$F/share/doc/ffmpeg" && cp "$res/VERSIONS" "$stage$F/share/doc/ffmpeg/VERSIONS" ||
        echo "ffmpeg: VERSIONS not into the stage" >> "$res/bins-bad.txt"
    if [ ! -s "$res/bins-bad.txt" ]; then
        echo "installed: bin/ffmpeg, bin/ffprobe of $F into the stage $stage ($(du -Ak "$stage$F/bin/ffmpeg" | cut -f1) KB, $(du -Ak "$stage$F/bin/ffprobe" | cut -f1) KB)" >> "$res/summary.txt"
    else
        rc=1
    fi
    rm -rf "$work/wrk"
fi
report
exit "$rc"
