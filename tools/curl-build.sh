#!/bin/sh
# curl-build.sh - build the curl program and libcurl.so of the package curl (the
# port ftp/curl), which takes the place of the curl of the ports (git and the other
# packages that link libcurl.so get this one). A build of its own, apart from the
# curl of PHP (the static libcurl.a of the package az in /usr/local/az/static, with
# only what PHP needs): the same release, with the options of the port
# ftp/curl (its CONFIGURE_ARGS and its default options: the protocols DICT, FTP,
# GOPHER, HTTP, HTTP/2, IMAP, IPFS, MQTT, POP3, RTSP, SMTP, TELNET, TFTP,
# WebSocket, NTLM, IDN, PSL, brotli, zstd, the threaded resolver), without SCP and
# SFTP (libssh2) and GSSAPI, which the libraries of /usr/local/az do not have;
# against the static libraries of the package az (AZ_PREFIX/static, installed).
# Into the stage AZ_STAGEDIR (default AZ_WORK/stage/curl) as files of /usr/local:
# bin/curl, static, PIE, RELRO, BIND_NOW, stripped; lib/libcurl.so.4 of the
# libcurl.a of this build (curl_* made visible by tools/curl-elf-export.py and
# exported, the libraries inside hidden), so that both need only libz and libthr
# of the base system; include/curl/, libdata/pkgconfig/libcurl.pc, curl-config,
# libcurl.m4, the manual pages, the licence, share/doc/curl/VERSIONS (this build
# and AZ_PREFIX/share/doc/az/VERSIONS, the libraries). Moved from
# build_curl_program of tools/build-deps.sh of https://github.com/azsupport/php-src
# (08.11.2026), where it ran in the build of the libraries; here it runs after
# it, against the installed package az, which has no .la files any more: libtool
# links the libraries with the -l of configure and pkg-config.
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
tools="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 1 ] || { echo "usage: sh tools/curl-build.sh <source of curl>" >&2; exit 2; }
cs="$(cd "$1" 2>/dev/null && pwd)" || { echo "curl-build: no directory $1" >&2; exit 2; }
A="${AZ_PREFIX:-/usr/local/az}"
P="$A/static"
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
# the flags and the environment of the libraries (tools/az-build.sh): the static
# tree only, pkg-config with --static
cputype="${AZ_CPUTYPE:-$(mc_get CPUTYPE)}"
cputype="${cputype:-x86-64-v3}"
opt="${AZ_CFLAGS:-$(mc_get CFLAGS)}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' ${opt:--O3 -pipe} | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
export CC=cc CXX=c++
export CFLAGS="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing -fPIC"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$P/include"
export LDFLAGS="-L$P/lib"
mkdir -p "$work/bin" "$res"
printf '%s\n' '#!/bin/sh' 'exec pkgconf --static "$@"' > "$work/bin/pkg-config-static"
chmod +x "$work/bin/pkg-config-static"
export PKG_CONFIG="$work/bin/pkg-config-static"
export PKG_CONFIG_LIBDIR="$P/lib/pkgconfig:$P/libdata/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH
export PATH="$P/bin:$PATH"
unset AR RANLIB NM
if ! ar --version 2>/dev/null | grep -q LLVM && command -v llvm-ar >/dev/null 2>&1; then
    export AR=llvm-ar RANLIB=llvm-ranlib NM=llvm-nm
fi

rm -f "$res"/*.tail "$res/bins-bad.txt"
: > "$res/summary.txt"
printf 'flags:    %s\n' "$CFLAGS" >> "$res/summary.txt"
for f in libssl.a libcrypto.a libnghttp2.a libbrotlidec.a libzstd.a libidn2.a libpsl.a libiconv.a; do
    if [ ! -f "$P/lib/$f" ]; then
        printf '%-14s FAIL  no %s in %s/lib: the package az first (the port az/az)\n' libs "$f" "$P" >> "$res/summary.txt"
        cat "$res/summary.txt"
        echo "curl-build: no $P/lib/$f; install the package az first" >&2
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
    # LIBS: libidn2 of the tree uses the libiconv of the tree
    (cd "$ob" && LIBS="-liconv" LDFLAGS="-L$P/lib -pie -Wl,-z,relro,-z,now" "$cs/configure" \
        --prefix=/usr/local --disable-shared --enable-static --with-pic --disable-dependency-tracking \
        --with-openssl="$P" --enable-openssl-auto-load-config --with-ca-path=/etc/ssl/certs --without-ca-bundle \
        --enable-threaded-resolver --disable-ares \
        --with-nghttp2="$P" --with-brotli="$P" --with-zstd="$P" --with-libidn2="$P" --with-libpsl="$P" \
        --enable-alt-svc --enable-cookies --enable-dict --enable-ftp --enable-file --enable-gopher \
        --enable-http --enable-imap --enable-ipfs --enable-ipv6 --enable-mqtt --enable-ntlm \
        --enable-pop3 --enable-proxy --enable-rtsp --enable-smtp --enable-telnet --enable-tftp \
        --enable-websockets --disable-ldap --disable-ldaps \
        --without-libssh2 --without-libssh --without-gssapi \
        --disable-httpsig --disable-unity --disable-werror --enable-aws --enable-dateparse \
        --enable-dnsshuffle --enable-headers-api --enable-hsts --enable-http-auth --enable-manual \
        --enable-mime --enable-netrc --enable-progress-meter --enable-ssls-export --enable-typecheck \
        --without-zsh-functions-dir --without-fish-functions-dir) || exit 1
    echo "== build"
    gmake -C "$ob" -j"$ncpu" || exit 1
    gmake -C "$ob" install-strip DESTDIR="$work/curl-sys-dest" || exit 1
    d="$work/curl-sys-dest/usr/local"
    install -s -m 755 "$d/bin/curl" "$r/bin/curl" || exit 1
    cp -R "$d/include" "$r/" || exit 1
    [ -d "$d/share/man" ] && { mkdir -p "$r/share" && cp -R "$d/share/man" "$r/share/"; }
    [ -d "$d/share/aclocal" ] && { mkdir -p "$r/share" && cp -R "$d/share/aclocal" "$r/share/"; }
    # the name of libcurl.so of curl's libtool numbers (lib/Makefile.soname):
    # libcurl.so.<change - del>.<del>.<add>, as the port has it (libcurl.so.4.8.0)
    eval "$(sed -n -E 's/^(VERSIONCHANGE|VERSIONADD|VERSIONDEL)=([0-9]+).*/\1=\2/p' "$cs/lib/Makefile.soname")"
    so="libcurl.so.$((VERSIONCHANGE - VERSIONDEL))"
    full="$so.$VERSIONDEL.$VERSIONADD"
    echo "== $full of the libcurl.a of this build"
    # libcurl.a is built with its functions hidden (CURL_STATICLIB, -fvisibility=hidden):
    # one object of it with curl_* visible again (tools/curl-elf-export.py), exported by
    # the version script, the libraries inside hidden (--exclude-libs)
    lo="$work/libcurl-so"
    rm -rf "$lo" && mkdir -p "$lo" || exit 1
    ld -r --whole-archive "$ob/lib/.libs/libcurl.a" -o "$lo/libcurl.o" || exit 1
    nv="$(python3 -I "$tools/curl-elf-export.py" "$lo/libcurl.o" curl_)" || { echo "== tools/curl-elf-export.py: no curl_* in libcurl.a"; exit 1; }
    echo "== curl_* made visible: $nv"
    printf '%s\n' '{' '  global: curl_*;' '  local: *;' '};' > "$lo/libcurl.vers"
    # the static link line of libcurl, without its first word (libcurl.a) and the
    # flags of programs (-pie, -z relro, -z now)
    deps="$(sh "$ob/curl-config" --static-libs | tr ' ' '\n' | sed '1d' | grep -v -E '^(-pie|-Wl,-z,.*)$' | tr '\n' ' ')"
    echo "== the libraries inside: $deps"
    # shellcheck disable=SC2086
    cc -shared -o "$r/lib/$full" -Wl,-soname,"$so" "$lo/libcurl.o" $deps -lm -lpthread \
        -Wl,--exclude-libs,ALL -Wl,--version-script="$lo/libcurl.vers" \
        -Wl,-z,relro,-z,now -Wl,--no-undefined || exit 1
    strip --strip-unneeded "$r/lib/$full" || exit 1
    ln -sf "$full" "$r/lib/$so" && ln -sf "$full" "$r/lib/libcurl.so" || exit 1
    bad="$(nm -D --defined-only "$r/lib/$full" | awk 'NF >= 3 && $3 !~ /^(curl_|_init$|_fini$|_edata$|_end$|__bss_start$)/ { print $3 }' | head -n 5 | tr '\n' ' ')"
    [ -z "$bad" ] || { echo "== $full exports more than curl_*: $bad"; exit 1; }
    n="$(nm -D --defined-only "$r/lib/$full" | grep -c ' curl_')"
    for f in curl_global_init curl_easy_init curl_easy_setopt curl_easy_perform curl_multi_perform curl_version_info; do
        nm -D --defined-only "$r/lib/$full" | grep -q " $f\$" || { echo "== $full does not export $f ($n curl_* functions)"; exit 1; }
    done
    echo "== $full exports $n curl_* functions"
    # libcurl.pc and curl-config for libcurl.so: no static libraries in this package
    pcf="$(ls "$d"/lib/pkgconfig/libcurl.pc "$d"/libdata/pkgconfig/libcurl.pc 2>/dev/null | head -n 1)"
    [ -n "$pcf" ] || { echo "== no libcurl.pc in $d"; exit 1; }
    sed -e 's|^Libs:.*|Libs: -L${libdir} -lcurl|' -e '/^Libs.private:/d' -e '/^Requires.private:/d' \
        "$pcf" > "$r/libdata/pkgconfig/libcurl.pc" || exit 1
    awk '/^ *--static-libs\)/ { print; print "    echo \"curl-config: the libcurl of this package is libcurl.so only\" >&2"; print "    exit 1"; skip = 1; next }
        skip && /;;/ { skip = 0 }
        !skip { print }' "$d/bin/curl-config" > "$r/bin/curl-config" && chmod 755 "$r/bin/curl-config" || exit 1
    cp "$cs/COPYING" "$r/share/licenses/curl/COPYING" || exit 1
    # the program and libcurl.so as they are, with the libraries of the base system only
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
        libs="$(ldd "$f" 2>/dev/null | awk 'NF > 2 && $2 == "=>" { print $3 }' | tr '\n' ' ' | sed 's/ *$//')"
        printf '%s: %s KB, ELF type %s, RELRO %s, BIND_NOW %s; libraries: %s\n' "$b" \
            "$(du -Ak "$f" | cut -f1)" "$type" "$relro" "$now" "$libs" >> "$res/curl-bins.txt"
        case "$libs" in *"/usr/local/"*) echo "$b: links a library of /usr/local" >> "$res/bins-bad.txt" ;; esac
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
        echo "port ftp/curl (tools/curl-build.sh), against the static libraries of the package az; the curl of"
        echo "PHP is the static libcurl of az. The build of the libraries:"
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
