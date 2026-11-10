#!/bin/sh
# curl-build.sh - build the curl program and libcurl.so.4 of the package curl (the
# port ftp/curl), which takes the place of the curl of the ports: the libcurl of
# every package (the PHP module curl, git, swoole: aZ, 10.11.2026, one libcurl). A
# build of its own, apart from the curl of PHP built on a server (the static
# libcurl.a of the package az in /usr/local/az/static, with only what PHP needs):
# the same release, with the options of the port ftp/curl (its CONFIGURE_ARGS and
# its default options: the protocols DICT, FTP, GOPHER, HTTP, HTTP/2, IMAP, IPFS,
# MQTT, POP3, RTSP, SMTP, TELNET, TFTP, WebSocket, NTLM, IDN, PSL, brotli, zstd, the
# threaded resolver) and SCP and SFTP with libssh2 (its option LIBSSH2, off in the
# port: aZ, 10.11.2026), without GSSAPI, which the libraries of /usr/local/az do not
# have; against the shared libraries of the package az (AZ_PREFIX/lib, installed:
# nghttp2, brotli, zstd, libidn2, libpsl, libssh2), which libcurl.so.4 links with
# the run path AZ_PREFIX/lib (our ports link each other's shared libraries: aZ,
# 10.11.2026), and OpenSSL and zlib of the base system. Into the stage AZ_STAGEDIR
# (default AZ_WORK/stage/curl) as files of /usr/local: bin/curl (PIE, RELRO,
# BIND_NOW, stripped, linking lib/libcurl.so.4), lib/libcurl.so.4 (only curl_*
# exported), include/curl/, libdata/pkgconfig/libcurl.pc, curl-config,
# libcurl.m4, the licence, share/doc/curl/VERSIONS (this build and
# AZ_PREFIX/share/doc/az/VERSIONS, the libraries). Moved from build_curl_program
# of tools/build-deps.sh of https://github.com/azsupport/php-src (08.11.2026),
# where it ran in the build of the libraries; here it runs after it, against the
# installed package az.
#
# Usage (FreeBSD; the port ftp/curl runs it in its do-build):
#   sh tools/curl-build.sh <source>   <source>: the release of files/curl.conf of
#                                     az/az, extracted, with files/curl/curl-<version>.patch
#
# Compiler flags as for the libraries: CPUTYPE and CFLAGS of /etc/make.conf with
# -fstack-protector-strong, -fno-strict-aliasing and -fPIC; AZ_CPUTYPE and
# AZ_CFLAGS win over make.conf (MAKE_CONF, default /etc/make.conf); without
# either: x86-64-v3 and -O3 -pipe. Results go to AZ_RESULTS (default
# curl-results/ of the current directory: summary.txt, curl-program.log,
# curl-version.txt, curl-bins.txt); the summary is printed at the end.
#
# Exit status: 0 built and checked, 1 the build or a check failed, 2 usage.

set -u
# A build as from a shell. The make of the port that runs this script leaves its
# MAKEFLAGS in the environment: its command line and the variables the framework
# hands to sub-makes (.MAKEFLAGS of bsd.port.mk: ARCH=amd64, OPSYS, OSVERSION, ...),
# which every gmake here would take as variables of its own command line, above
# those of the Makefiles: FFmpeg's ARCH=x86 became ARCH=amd64, so no x86 object
# was built (ld: undefined symbol ff_bwdif_init_x86 ..., 08.11.2026).
unset MAKEFLAGS MFLAGS MAKELEVEL __MKLVL__
[ $# -eq 1 ] || { echo "usage: sh tools/curl-build.sh <source of curl>" >&2; exit 2; }
cs="$(cd "$1" 2>/dev/null && pwd)" || { echo "curl-build: no directory $1" >&2; exit 2; }
A="${AZ_PREFIX:-/usr/local/az}"
work="${AZ_WORK:-/var/tmp/az-work}/curl"
stage="${AZ_STAGEDIR:-${AZ_WORK:-/var/tmp/az-work}/stage/curl}"
r="$stage/usr/local"
res="${AZ_RESULTS:-$(pwd)/curl-results}"
ncpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 2)"
major="$(uname -r | cut -d. -f1)"

say() { printf '[curl-build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

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
# the flags of the libraries (tools/az-build.sh); the environment of their shared
# builds: the shared tree only (nothing of the static tree), its pkg-config files and
# those of the base system, the run path of the tree
cputype="${AZ_CPUTYPE:-$(mc_get CPUTYPE)}"
cputype="${cputype:-x86-64-v3}"
opt="${AZ_CFLAGS:-$(mc_get CFLAGS)}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' ${opt:--O3 -pipe} | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
export CC=cc CXX=c++
export CFLAGS="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing -fPIC"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$A/include"
export LDFLAGS="-L$A/lib -Wl,-rpath,$A/lib -Wl,--as-needed -Wl,-z,relro,-z,now"
mkdir -p "$res"
export PKG_CONFIG=pkgconf
export PKG_CONFIG_LIBDIR="$A/lib/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH

rm -f "$res"/*.tail "$res/bins-bad.txt"
: > "$res/summary.txt"
printf 'flags:    %s\n' "$CFLAGS" >> "$res/summary.txt"
for f in libnghttp2.so libbrotlidec.so libzstd.so libidn2.so libpsl.so libssh2.so; do
    if [ ! -f "$A/lib/$f" ]; then
        printf '%-14s FAIL  no %s in %s/lib: the package az first (the port az/az)\n' libs "$f" "$A" >> "$res/summary.txt"
        cat "$res/summary.txt"
        echo "curl-build: no $A/lib/$f; install the package az first" >&2
        exit 1
    fi
done

say "curl $(sed -n 's/^#define LIBCURL_VERSION "\(.*\)"$/\1/p' "$cs/include/curl/curlver.h") from $cs into $stage"
ob="$work/obj-curl-sys"
log="$res/curl-program.log"
start=$(date +%s)
cv="$(sed -n 's/^#define LIBCURL_VERSION "\(.*\)"$/\1/p' "$cs/include/curl/curlver.h")"
(
    [ -x "$cs/configure" ] || { echo "== no source of curl in $cs"; exit 1; }
    rm -rf "$ob" "$stage" "$work/curl-sys-dest"
    mkdir -p "$ob" "$r/bin" "$r/lib" "$r/libdata/pkgconfig" "$r/share/licenses/curl" || exit 1
    echo "== configure (the options of the port ftp/curl)"
    (cd "$ob" && LDFLAGS="$LDFLAGS -pie" "$cs/configure" \
        --prefix=/usr/local --enable-shared --disable-static --with-pic --disable-dependency-tracking \
        --with-openssl=/usr --enable-openssl-auto-load-config --with-ca-path=/etc/ssl/certs --without-ca-bundle \
        --enable-threaded-resolver --disable-ares \
        --with-nghttp2="$A" --with-brotli="$A" --with-zstd="$A" --with-libidn2="$A" --with-libpsl="$A" \
        --with-libssh2="$A" \
        --enable-alt-svc --enable-cookies --enable-dict --enable-ftp --enable-file --enable-gopher \
        --enable-http --enable-imap --enable-ipfs --enable-ipv6 --enable-mqtt --enable-ntlm \
        --enable-pop3 --enable-proxy --enable-rtsp --enable-smtp --enable-telnet --enable-tftp \
        --enable-websockets --disable-ldap --disable-ldaps \
        --without-libssh --without-gssapi \
        --disable-httpsig --disable-unity --disable-werror --enable-aws --enable-dateparse \
        --enable-dnsshuffle --enable-headers-api --enable-hsts --enable-http-auth --enable-manual \
        --enable-mime --enable-netrc --enable-progress-meter --enable-ssls-export --enable-typecheck \
        --enable-symbol-hiding --without-zsh-functions-dir --without-fish-functions-dir) || exit 1
    echo "== build"
    gmake -C "$ob" -j"$ncpu" || exit 1
    gmake -C "$ob" install-strip DESTDIR="$work/curl-sys-dest" || exit 1
    d="$work/curl-sys-dest/usr/local"
    install -s -m 755 "$d/bin/curl" "$r/bin/curl" || exit 1
    cp -R "$d/include" "$r/" || exit 1
    # no manual pages: the servers have MAN3 and MANPAGES unset (OPTIONS_UNSET of
    # make.conf), and none of the packages of this tree has them
    [ -d "$d/share/aclocal" ] && { mkdir -p "$r/share" && cp -R "$d/share/aclocal" "$r/share/"; }
    # libcurl.so.4 and its names, as libtool installed them (libcurl.so.4.8.0, as the port)
    full="$(cd "$d/lib" && ls libcurl.so.*.*.* 2>/dev/null | head -n 1)"
    [ -n "$full" ] || { echo "== no libcurl.so.*.*.* in $d/lib"; exit 1; }
    so="${full%.*.*}"
    cp -p "$d/lib/$full" "$r/lib/$full" && ln -sf "$full" "$r/lib/$so" && ln -sf "$full" "$r/lib/libcurl.so" || exit 1
    bad="$(nm -D --defined-only "$r/lib/$full" | awk 'NF >= 3 && $3 !~ /^(curl_|_init$|_fini$|_edata$|_end$|__bss_start$)/ { print $3 }' | head -n 5 | tr '\n' ' ')"
    [ -z "$bad" ] || { echo "== $full exports more than curl_*: $bad"; exit 1; }
    n="$(nm -D --defined-only "$r/lib/$full" | grep -c ' curl_')"
    for f in curl_global_init curl_easy_init curl_easy_setopt curl_easy_perform curl_multi_perform curl_version_info; do
        nm -D --defined-only "$r/lib/$full" | grep -q " $f\$" || { echo "== $full does not export $f ($n curl_* functions)"; exit 1; }
    done
    echo "== $full exports $n curl_* functions"
    # libcurl.pc for libcurl.so: its libraries are those of libcurl.so itself (the
    # modules that build against it need no .pc of the tree of az)
    pcf="$(ls "$d"/lib/pkgconfig/libcurl.pc "$d"/libdata/pkgconfig/libcurl.pc 2>/dev/null | head -n 1)"
    [ -n "$pcf" ] || { echo "== no libcurl.pc in $d"; exit 1; }
    sed -e 's|^Libs:.*|Libs: -L${libdir} -lcurl|' -e '/^Libs.private:/d' -e '/^Requires.private:/d' \
        "$pcf" > "$r/libdata/pkgconfig/libcurl.pc" || exit 1
    awk '/^ *--static-libs\)/ { print; print "    echo \"curl-config: the libcurl of this package is libcurl.so only\" >&2"; print "    exit 1"; skip = 1; next }
        skip && /;;/ { skip = 0 }
        !skip { print }' "$d/bin/curl-config" > "$r/bin/curl-config" && chmod 755 "$r/bin/curl-config" || exit 1
    cp "$cs/COPYING" "$r/share/licenses/curl/COPYING" || exit 1
    # the program and libcurl.so as they are: libcurl.so.4 of the stage, the libraries of
    # az by its run path, the base system
    LD_LIBRARY_PATH="$r/lib" "$r/bin/curl" --version > "$res/curl-version.txt" 2>&1 || exit 1
    cat "$res/curl-version.txt"
) > "$log" 2>&1
rc=$?
: > "$res/curl-bins.txt"
if [ "$rc" = 0 ]; then
    for f in "$r/bin/curl" "$r/lib/$(cd "$r/lib" && ls libcurl.so.*.*.* | head -n 1)"; do
        b="${f##*/}"
        type="$(readelf -h "$f" | awk '/Type:/ { print $2 }')"
        relro="$(readelf -l "$f" | grep -c GNU_RELRO)"
        now="$(readelf -d "$f" | grep -c -E 'BIND_NOW|FLAGS_1.*NOW')"
        libs="$(LD_LIBRARY_PATH="$r/lib" ldd "$f" 2>/dev/null | awk 'NF > 2 && $2 == "=>" { print $3 }' | tr '\n' ' ' | sed 's/ *$//')"
        rp="$(readelf -d "$f" | sed -n 's/.*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1/p')"
        printf '%s: %s KB, ELF type %s, RELRO %s, BIND_NOW %s, run path %s; libraries: %s\n' "$b" \
            "$(du -Ak "$f" | cut -f1)" "$type" "$relro" "$now" "${rp:-none}" "$libs" >> "$res/curl-bins.txt"
        # the base system, the shared tree of az (by the run path) and libcurl.so.4
        # (of the stage here, of /usr/local/lib once installed); nothing else
        for l in $libs; do
            case "$l" in
                /lib/* | /usr/lib/* | "$r"/lib/libcurl.so.*) ;;
                "$A"/static/*) echo "$b: $l of the static tree" ;;
                "$A"/lib/*) case ":$rp:" in *":$A/lib:"*) ;; *) echo "$b: $l without the run path $A/lib" ;; esac ;;
                *) echo "$b: $l, not of the base system or of az" ;;
            esac
        done >> "$res/bins-bad.txt"
        [ "$type" = DYN ] || echo "$b: not position independent (ELF type $type)" >> "$res/bins-bad.txt"
        [ "$relro" -gt 0 ] || echo "$b: no RELRO" >> "$res/bins-bad.txt"
        [ "$now" -gt 0 ] || echo "$b: no BIND_NOW" >> "$res/bins-bad.txt"
    done
    printf '%-14s OK    %-22s %-24s %4ss\n' "curl program" "$cv" "bin/curl, libcurl.so" "$(( $(date +%s) - start ))" >> "$res/summary.txt"
else
    printf '%-14s FAIL  %-22s %-24s %4ss (curl-program.log)\n' "curl program" "$cv" "bin/curl, libcurl.so" "$(( $(date +%s) - start ))" >> "$res/summary.txt"
    tail -n 25 "$log" > "$res/curl-program.tail"
fi

# share/doc/curl/VERSIONS: this build and the libraries it links (those of the package az)
if [ "$rc" = 0 ]; then
    mkdir -p "$r/share/doc/curl"
    {
        echo "curl $cv for FreeBSD $major (amd64, $cputype): bin/curl and lib/libcurl.so.4, the release of the"
        echo "bundled curl of the package az (az/az/files/curl.conf of azsupport/ports) with the options of the"
        echo "port ftp/curl (tools/curl-build.sh), against the shared libraries of the package az; the libcurl"
        echo "of every package. The build of the libraries:"
        echo
        cat "$A/share/doc/az/VERSIONS" 2>/dev/null || echo "($A/share/doc/az/VERSIONS is not there)"
        echo
        cat "$res/curl-version.txt"
    } > "$r/share/doc/curl/VERSIONS"
fi
[ ! -s "$res/bins-bad.txt" ] || rc=1
echo "== $res/summary.txt"
cat "$res/summary.txt" "$res/curl-bins.txt"
for f in "$res"/*.tail "$res/bins-bad.txt"; do
    [ -s "$f" ] || continue
    echo "== $f"
    cat "$f"
done
exit "$rc"
