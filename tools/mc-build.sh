#!/bin/sh
# mc-build.sh - build the Midnight Commander for the servers: the package mc of the
# port misc/mc, in the place of that of the ports (/usr/local/bin/mc and its links
# mcedit, mcview and mcdiff, etc/mc, libexec/mc, share/mc), from the official FreeBSD
# port of misc/mc/files/mc.conf with the configure lines there (what is on and off,
# and why), with GLib and libssh2 linked in.
#
# Usage (FreeBSD; the port misc/mc runs it in its post-fetch and do-build):
#   sh tools/mc-build.sh --fetch    fetch the distfiles of the official ports of
#                                   mc.conf into AZ_DISTDIR (their make fetch)
#   sh tools/mc-build.sh            build mc
#
# The ports framework fetches the distfiles of each port of the program lines at the
# ports commit of az/az/files/deps.conf (the official tree PORTSDIR, at that commit),
# checks them against its distinfo, extracts them and applies the port's patches
# (make patch; those of misc/mc make mcdiff run gdiff), then those of files/ of
# misc/mc (files/*.patch, in the order of their names); this script then builds each
# source tree with its own options: libffi (the build of GLib needs it for GObject,
# which mc does not link) and GLib static and position independent into the work
# directory (AZ_WORK/mc/static; nothing of them is installed), GLib against PCRE2,
# libintl and libiconv of the static tree of the package az, /usr/local/az/static
# (installed), and mc (prefix /usr/local) against them and libssh2 of that tree (with
# the OpenSSL of that tree, which it was built with) into the stage AZ_STAGEDIR
# (default AZ_WORK/stage/mc), with files/ubsdtar in libexec/mc/extfs.d, its VERSIONS
# in share/doc/mc and the licences of mc and of the libraries in it in
# share/licenses/mc. So mc needs no package, only libraries of the base system
# (ncursesw, libutil, libz, libthr, libc). The work directory is AZ_WORK/mc (default
# /var/tmp/az-work/mc). Results go to AZ_RESULTS (default mc-results/ of the current
# directory: summary.txt, a log per port, bins.txt, version.txt, VERSIONS); the
# summary is printed at the end.
#
# Compiler flags as for the other programs: CPUTYPE and CFLAGS of /etc/make.conf with
# -fstack-protector-strong and -fno-strict-aliasing; AZ_CPUTYPE and AZ_CFLAGS win over
# make.conf (MAKE_CONF, default /etc/make.conf); without either: x86-64-v3 and -O3
# -pipe. mc: PIE, RELRO and BIND_NOW. AZ_MC_VERSION (the port misc/mc gives its
# DISTVERSION): the version the official port has to have, so that the package has
# the version of what it builds.
#
# Exit status: 0 built, 1 a port failed, the libraries of az are not there, the
# official port has another version, or this CPU cannot run the level, 2 usage.

set -u
# A build as from a shell: the make of the port that runs this script leaves its
# MAKEFLAGS in the environment, which every gmake here would take as variables of its
# own command line (as tools/az-build.sh says).
unset MAKEFLAGS MFLAGS MAKELEVEL __MKLVL__
tools="$(cd "$(dirname "$0")" && pwd)"
files="${AZ_FILESDIR:-$tools/../misc/mc/files}"
conf="$files/mc.conf"
deps_conf="${AZ_DEPS_CONF:-$tools/../az/az/files/deps.conf}"
A="${AZ_PREFIX:-/usr/local/az}"
L="$A/static"
work="${AZ_WORK:-/var/tmp/az-work}/mc"
# the libraries built here, static, for the link of mc only
W="$work/static"
F=/usr/local
stage="${AZ_STAGEDIR:-${AZ_WORK:-/var/tmp/az-work}/stage/mc}"
res="${AZ_RESULTS:-$(pwd)/mc-results}"
ports="${PORTSDIR:-/usr/ports}"
distdir="${AZ_DISTDIR:-$work/distfiles}"
ncpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 2)"
major="$(uname -r | cut -d. -f1)"

[ -f "$conf" ] || { echo "mc-build: no $conf (AZ_FILESDIR: files/ of the port misc/mc)" >&2; exit 2; }
[ -f "$deps_conf" ] || { echo "mc-build: no $deps_conf (AZ_DEPS_CONF: deps.conf of the port az/az)" >&2; exit 2; }

say() { printf '[mc-build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

# A variable of make.conf (VAR=, ?=, := and += lines; comments dropped)
mk_conf="${MAKE_CONF:-/etc/make.conf}"
mkconf_get() {
    [ -r "$mk_conf" ] || return 0
    awk -v v="$1" '
        { sub(/#.*/, "") }
        $0 ~ "^[ \t]*" v "[ \t]*[?:]?=" { s = $0; sub("^[ \t]*" v "[ \t]*[?:]?=[ \t]*", "", s); val = s; have = 1; next }
        $0 ~ "^[ \t]*" v "[ \t]*\\+=" { s = $0; sub("^[ \t]*" v "[ \t]*\\+=[ \t]*", "", s); val = val " " s; have = 1 }
        END { if (have) { sub(/[ \t]+$/, "", val); print val } }
    ' "$mk_conf"
}

cputype="${AZ_CPUTYPE:-$(mkconf_get CPUTYPE)}"
cputype="${cputype:-x86-64-v3}"
opt="${AZ_CFLAGS:-$(mkconf_get CFLAGS)}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' ${opt:--O3 -pipe} | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
cflags="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing"
export CC=cc CXX=c++
# The builds see the work tree W and the static tree of az, nothing of /usr/local (the
# base compiler does not search it; pkg-config only these and the base system), with
# pkg-config --static: there are only static libraries, so the link of a library
# needs those behind it (GLib: libintl, libiconv, PCRE2; libssh2: libcrypto, libz).
mkdir -p "$work/bin"
printf '%s\n' '#!/bin/sh' 'exec pkgconf --static "$@"' > "$work/bin/pkg-config-static"
chmod +x "$work/bin/pkg-config-static"
export PKG_CONFIG="$work/bin/pkg-config-static"
export PKG_CONFIG_LIBDIR="$W/lib/pkgconfig:$L/lib/pkgconfig:$L/libdata/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH
export CPPFLAGS="-I$W/include -I$L/include"
export LDFLAGS="-L$W/lib -L$L/lib"
unset AR RANLIB NM

ports_commit="$(awk '$1 == "ports" { print $2 }' "$deps_conf")"
progs="$(awk '$1 == "program" { print $2 }' "$conf")"
port_of() { awk -v n="$1" '$1 == "program" && $2 == n { print $3 }' "$conf"; }
# pm <origin[@flavor]> <arguments of make>: pmake of the port, with FLAVOR when the
# program line names one
pm() {
    _o="$1"; shift
    case "$_o" in
        *@*) pmake "${_o%@*}" FLAVOR="${_o#*@}" "$@" ;;
        *) pmake "$_o" "$@" ;;
    esac
}
conf_opts() { awk '$1 == "configure" { for (i = 2; i <= NF; i++) print $i }' "$conf"; }

# The official tree PORTSDIR has to be at the commit of deps.conf (as in
# tools/az-build.sh); it is only read here, never changed.
ports_check() {
    [ -f "$ports/Mk/bsd.port.mk" ] || { echo "mc-build: no ports tree in $ports (PORTSDIR)" >&2; return 1; }
    h="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    if [ -z "$h" ]; then
        echo "mc-build: $ports is not a git checkout: taken for freebsd-ports $ports_commit of deps.conf" >&2
        return 0
    fi
    [ "$h" = "$ports_commit" ] && return 0
    echo "mc-build: $ports is at $h, deps.conf has $ports_commit: build with the tree at that commit" >&2
    return 1
}
# A make of its own, as from a shell: nothing of the make of the port that runs this
# script (MAKEFLAGS: its command line, its job server) reaches the official ports.
pmake() {
    p="$1"; shift
    env -u MAKEFLAGS -u MFLAGS -u __MKLVL__ make -C "$ports/$p" BATCH=yes NO_DEPENDS=yes \
        DISABLE_VULNERABILITIES=yes PORTSDIR="$ports" WRKDIRPREFIX="$work/wrk" DISTDIR="$distdir" "$@"
}
# For GNU configure the ports framework puts its own config.guess and config.sub into
# the tree (old ones do not know FreeBSD 15); so does this.
fix_guess() {
    find "$1" \( -name config.guess -o -name config.sub \) -type f | while IFS= read -r f; do
        cp "$ports/Templates/${f##*/}" "$f" && chmod a+rx "$f"
    done
}

# libffi: the options of the port (CONFIGURE_ARGS), static, for the build of GLib
b_libffi() {
    fix_guess "$1"
    (cd "$1" && CFLAGS="$cflags -fPIC" ./configure --prefix="$W" --libdir="$W/lib" --includedir="$W/include" \
        --enable-static --disable-shared --with-pic --disable-multi-os-directory --disable-docs &&
        gmake -j"$ncpu" && gmake install)
}
# GLib: the meson options of the port devel/glib20 in its flavor bootstrap (MESON_ARGS:
# no introspection, translations, documents and manual pages), static and position
# independent, without the tests, libelf (of the gresource tool) and the probes
# (dtrace, systemtap, sysprof); as tools/az-build.sh runs meson (release, the
# optimization of CFLAGS)
b_glib() {
    # the file monitor of GIO as the port has it: inotify of the base system where it
    # has one (FreeBSD 15), else kqueue (the port: libinotify-kqueue, a package)
    if [ -f /usr/include/sys/inotify.h ]; then fmon=inotify; else fmon=kqueue; fi
    (cd "$1" && CFLAGS="$cflags -fPIC" meson setup _az --prefix="$W" --libdir=lib --buildtype=release \
        -Doptimization=plain --default-library=static -Db_staticpic=true --wrap-mode=nodownload \
        -Db_lundef=false -Dinstalled_tests=false -Dlibmount=disabled -Druntime_dir=/var/run \
        -Dselinux=disabled -Dsysprof=disabled -Dsystemtap=disabled -Ddtrace=disabled -Dxattr=false \
        -Dtests=false -Dnls=disabled -Dintrospection=disabled -Dman-pages=disabled -Ddocumentation=false \
        -Dlibelf=disabled -Dfile_monitor_backend="$fmon" &&
        ninja -C _az -j "$ncpu" && ninja -C _az install)
}
# mc: after the port's patches those of files/ (the archives through ubsdtar), then
# configure with the paths of the port and the configure lines of mc.conf; the
# programs its scripts run at the paths of the servers, not those the build machine
# happens to have (configure takes them from PATH): Perl and zip of the packages,
# unzip of the base system, Python and Ruby from PATH; ncursesw of the base system
# with its wide characters (NCURSES_WIDECHAR, as the port); PIE, RELRO, BIND_NOW
b_mc() {
    rm -rf "$stage"
    for p in "$files"/*.patch; do
        [ -f "$p" ] || continue
        echo "== files/${p##*/}"
        patch -p0 -N -s -d "$1" < "$p" || { echo "== ${p##*/} does not apply"; return 1; }
    done
    fix_guess "$1"
    (
        cd "$1" || exit 1
        # shellcheck disable=SC2046
        CFLAGS="$cflags -fPIE -DNCURSES_WIDECHAR" LDFLAGS="$LDFLAGS -pie -Wl,-z,relro,-z,now" \
            ./configure --prefix="$F" --localstatedir=/var --mandir="$F/share/man" --disable-silent-rules \
            PERL=/usr/local/bin/perl PERL_FOR_BUILD=/usr/local/bin/perl "PYTHON=/usr/bin/env python3" \
            "RUBY=/usr/bin/env ruby" ZIP=/usr/local/bin/zip UNZIP=/usr/bin/unzip $(conf_opts) &&
            gmake -j"$ncpu" && gmake install-strip DESTDIR="$stage"
    ) || { cp "$1/config.log" "$res/mc-config.log" 2>/dev/null; return 1; }
    cp "$1/config.log" "$res/mc-config.log" 2>/dev/null
    # no manual pages, as in the other packages of this tree (MANPAGES is in the
    # OPTIONS_UNSET of the make.conf of the servers); the help of mc (F1) stays
    rm -rf "$stage$F/share/man"
    install -m 755 "$files/ubsdtar" "$stage$F/libexec/mc/extfs.d/ubsdtar" || return 1
    # the licences of mc and of what is linked in: GLib and libffi from their sources,
    # libssh2, OpenSSL, PCRE2, libintl and libiconv from LICENSES/ of the package az
    lic="$stage$F/share/licenses/mc"
    mkdir -p "$lic" && cp "$1/COPYING" "$lic/mc-COPYING" || return 1
    for n in glib libffi; do
        s="$(cat "$work/src-$n")"
        for f in "$s"/COPYING* "$s"/LICENSE "$s"/LICENSE.*; do
            [ -f "$f" ] && cp "$f" "$lic/$n-${f##*/}"
        done
    done
    for n in libssh2 openssl pcre2 gettext libiconv; do
        for f in "$A/LICENSES/$n"-*; do
            [ -e "$f" ] && cp -R "$f" "$lic/"
        done
    done
    return 0
}

build_one() {
    n="$1"
    port="$(port_of "$n")"
    log="$res/$n.log"
    start=$(date +%s)
    (
        echo "== $n: $port at $ports_commit"
        pm "$port" clean >/dev/null 2>&1
        pm "$port" patch || { echo "make patch failed"; exit 1; }
        src="$(pm "$port" -V WRKSRC)"
        echo "== source: $src"
        printf '%s\n' "$src" > "$work/src-$n"
        "b_$n" "$src" || exit 1
    ) > "$log" 2>&1
    rc=$?
    ver="$(pm "$port" -V PKGVERSION 2>/dev/null)"
    pkgname="$(pm "$port" -V PKGNAME 2>/dev/null)"
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

# The patches the framework applies to a port: files/patch-* and EXTRA_PATCHES.
port_patches() {
    fd="$(pm "$1" -V FILESDIR 2>/dev/null)"
    np="$(ls "$fd" 2>/dev/null | grep -c '^patch-')"
    ne="$(pm "$1" -V EXTRA_PATCHES 2>/dev/null | wc -w | tr -d ' ')"
    echo $(( np + ne ))
}

manifest() {
    {
        echo "Midnight Commander for FreeBSD $major (amd64, $cputype), built $(date '+%Y-%m-%d %H:%M %Z') on $(uname -sr)"
        echo "freebsd-ports $ports_commit; CFLAGS: $cflags"
        echo "GLib and libffi: static, built here; libssh2 (with OpenSSL), PCRE2, libintl and libiconv:"
        echo "the static libraries of $L (the package az, the static tree):"
        awk '$1 == "libssh2" || $1 == "openssl" || $1 == "pcre2" || $1 == "gettext" || $1 == "libiconv" { print "    " $0 }' \
            "$A/share/doc/az/VERSIONS" 2>/dev/null
        echo
        while read -r n pkgname port; do
            printf '%-8s %-24s %s\n' "$n" "$pkgname" "$port"
            di="$(pm "$port" -V DISTINFO_FILE 2>/dev/null)"
            for d in $(pm "$port" -V DISTFILES 2>/dev/null); do
                d="${d%%:*}"
                awk -v d="$d" '$1 == "SHA256" { f = $2; gsub(/[()]/, "", f); b = f; sub(/.*\//, "", b)
                    if (b == d) print "    " f " sha256 " $4 }' "$di"
            done
            np="$(port_patches "$port")"
            [ "$np" -gt 0 ] && echo "    $np patches of the port"
            if [ "$n" = mc ]; then
                for p in "$files"/*.patch; do
                    [ -f "$p" ] && echo "    files/${p##*/}: $(sed -n 's/^Description: //p' "$p" | head -n 1)"
                done
                echo "    files/ubsdtar: libexec/mc/extfs.d/ubsdtar"
            fi
        done < "$res/built.txt"
        echo
        echo "configure of mc (after --prefix=$F, the paths and the flags):"
        conf_opts | sed 's/^/    /'
        echo
        echo "Licence: GPL version 3 or later (mc); GLib, libintl and libiconv LGPL, libssh2 BSD 3-clause,"
        echo "libffi MIT, PCRE2 BSD, OpenSSL Apache 2.0: the licences are in share/licenses/mc/."
        echo "Sources: the distfiles above (their SHA-256), the patches of the ports at the commit above,"
        echo "files/ of misc/mc and tools/mc-build.sh of https://github.com/azsupport/ports (misc/mc/files/mc.conf)."
    } > "$res/VERSIONS"
}

# Hardening and links of mc, for the report and the test; its version and what it
# was built with
check_bins() {
    : > "$res/bins.txt"
    f="$stage$F/bin/mc"
    [ -x "$f" ] || { echo "mc: missing" >> "$res/bins-bad.txt"; return; }
    type="$(readelf -h "$f" | awk '/Type:/ { print $2 }')"
    relro="$(readelf -l "$f" | grep -c GNU_RELRO)"
    now="$(readelf -d "$f" | grep -c -E 'BIND_NOW|FLAGS_1.*NOW')"
    libs="$(ldd "$f" | awk 'NR > 1 { print $3 }' | tr '\n' ' ' | sed 's/ *$//')"
    printf 'mc: %s KB, ELF type %s, RELRO %s, BIND_NOW %s; libraries: %s\n' \
        "$(du -Ak "$f" | cut -f1)" "$type" "$relro" "$now" "$libs" >> "$res/bins.txt"
    case "$libs" in *"/usr/local/"*) echo "mc: links a library of /usr/local" >> "$res/bins-bad.txt" ;; esac
    [ "$type" = DYN ] || echo "mc: not a PIE (ELF type $type)" >> "$res/bins-bad.txt"
    [ "$relro" -gt 0 ] || echo "mc: no RELRO" >> "$res/bins-bad.txt"
    [ "$now" -gt 0 ] || echo "mc: no BIND_NOW" >> "$res/bins-bad.txt"
    for l in mcedit mcview mcdiff; do
        [ -L "$stage$F/bin/$l" ] || echo "mc: no link bin/$l" >> "$res/bins-bad.txt"
    done
    "$f" --version > "$res/version.txt" 2>&1
    for w in "Built with GLib" "Built with libssh2" "With builtin editor" "With subshell support as default" \
            "With multiple codepages support" sftpfs; do
        grep -q "$w" "$res/version.txt" || echo "mc --version: no \"$w\"" >> "$res/bins-bad.txt"
    done
    for w in "X11 events" "internationalization"; do
        grep -q "$w" "$res/version.txt" && echo "mc --version: \"$w\", which is off in mc.conf" >> "$res/bins-bad.txt"
    done
    return 0
}

mkdir -p "$res" "$work"
# --fetch: the distfiles of the ports, by their own make fetch into AZ_DISTDIR (the
# post-fetch of the port misc/mc), so that the build needs no network
if [ "${1:-}" = "--fetch" ]; then
    ports_check || exit 1
    rc=0
    for n in $progs; do
        say "fetch $n ($(port_of "$n"))"
        pm "$(port_of "$n")" fetch || { echo "mc-build: $n: make fetch of $(port_of "$n") failed" >&2; rc=1; }
    done
    exit "$rc"
fi
[ $# -eq 0 ] || { echo "usage: sh tools/mc-build.sh [--fetch]" >&2; exit 2; }
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
printf 'flags:    %s\ncpu:      %s\n' "$cflags" "${cpu_model:-?}" >> "$res/summary.txt"
# The build runs what it compiles (the tests of configure and meson), so this CPU has
# to run code of the level
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
    echo "mc-build: this CPU ${why:-cannot tell the features of} -march=$cputype" >&2
    exit 1
fi
for f in lib/libssh2.a lib/libcrypto.a lib/libpcre2-8.a lib/libintl.a lib/libiconv.a \
        lib/pkgconfig/libssh2.pc lib/pkgconfig/libpcre2-8.pc include/libintl.h include/iconv.h; do
    if [ ! -f "$L/$f" ]; then
        printf '%-8s FAIL  no %s of the static libraries in %s: install the package az first (az/az)\n' libs "$f" "$L" >> "$res/summary.txt"
        echo "mc-build: no $L/$f; install the package az first (the port az/az)" >&2
        exit 1
    fi
done
ports_check || { echo "ports    FAIL  $ports is not freebsd-ports $ports_commit of deps.conf" >> "$res/summary.txt"; report; exit 1; }
if [ -n "${AZ_MC_VERSION:-}" ]; then
    pv="$(pmake misc/mc -V PORTVERSION 2>/dev/null)"
    if [ "$pv" != "$AZ_MC_VERSION" ]; then
        printf 'mc       FAIL  the official misc/mc is %s, the port misc/mc of this tree %s: set its DISTVERSION\n' \
            "${pv:-?}" "$AZ_MC_VERSION" >> "$res/summary.txt"
        report
        exit 1
    fi
fi
rm -rf "$W"
rc=0
for n in $progs; do
    say "$n ($(port_of "$n"))"
    if ! build_one "$n"; then rc=1; break; fi
done
if [ "$rc" = 0 ]; then
    manifest
    check_bins
    mkdir -p "$stage$F/share/doc/mc" && cp "$res/VERSIONS" "$stage$F/share/doc/mc/VERSIONS" ||
        echo "mc: VERSIONS not into the stage" >> "$res/bins-bad.txt"
    if [ ! -s "$res/bins-bad.txt" ]; then
        echo "installed: bin/mc and the rest of mc of $F into the stage $stage ($(du -Ak "$stage$F/bin/mc" | cut -f1) KB)" >> "$res/summary.txt"
    else
        rc=1
    fi
    rm -rf "$work/wrk"
fi
report
exit "$rc"
