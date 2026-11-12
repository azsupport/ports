#!/bin/sh
# mc-build.sh - build the Midnight Commander for the servers: the package mc of the
# port misc/mc, in the place of that of the ports (/usr/local/bin/mc and its links
# mcedit, mcview and mcdiff, etc/mc, libexec/mc, share/mc), from the official FreeBSD
# port of misc/mc/files/mc.conf with the configure lines there (what is on and off,
# and why), against the shared GLib of our port devel/glib20.
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
# misc/mc (files/*.patch, in the order of their names), then autoreconf -fi (a patch
# changes configure.ac: file cloning by copy_file_range of FreeBSD, whose defines the
# build checks in config.h); this script then builds mc
# (prefix /usr/local) against the shared libraries of our ports (aZ, 10.11.2026: our
# ports link each other's shared libraries): GLib of devel/glib20 (libglib-2.0.so of
# /usr/local/lib, itself on libintl, libiconv and libffi of az and PCRE2 of
# devel/pcre2; mc had a static GLib of its own before 11.11.2026), seen through a .pc
# of its own in the work (AZ_WORK/mc/deps: glib-2.0 with the include directories of
# GLib and libglib-2.0.so alone in a directory, nothing else of /usr/local), and
# libssh2 of az (with the OpenSSL of the base system, which it was built with), with
# the run path /usr/local/az/lib, into the stage AZ_STAGEDIR (default
# AZ_WORK/stage/mc) and runs the unit test of upstream for file cloning
# (tests/lib/vfs/vfs_clone_file.c, with check of devel/check, in a build of its own),
# with files/ubsdtar in libexec/mc/extfs.d, its VERSIONS in
# share/doc/mc and its licence in share/licenses/mc. So mc needs the packages az and
# glib (with pcre2) and libraries of the base system (ncursesw, libutil, libz,
# libthr, libc). The work directory is AZ_WORK/mc (default
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
work="${AZ_WORK:-/var/tmp/az-work}/mc"
# the .pc of GLib and the link of its library, for the build of mc only
W="$work/deps"
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
# The build sees W (GLib of devel/glib20: glib_dir below) and the shared tree of az,
# nothing else of /usr/local (the base compiler does not search it; pkg-config only
# these and the base system)
export PKG_CONFIG=pkgconf
export PKG_CONFIG_LIBDIR="$W/lib/pkgconfig:$A/lib/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH
export CPPFLAGS="-I$A/include"
export LDFLAGS="-L$A/lib -Wl,-rpath,$A/lib"
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

# GLib of devel/glib20 (/usr/local): a glib-2.0.pc of its own in W with the include
# directories of GLib (glib-2.0 and lib/glib-2.0/include: only its headers) and
# libglib-2.0.so alone in W/glib, so that no other header or library of /usr/local
# is seen; the link takes the SONAME of the library (libglib-2.0.so.0 of
# /usr/local/lib, one of ldconfig), no run path for it. No gmodule: mc takes it only
# for Aspell, which is off.
glib_dir() {
    _pc=/usr/local/libdata/pkgconfig/glib-2.0.pc
    for _f in "$_pc" /usr/local/include/glib-2.0/glib.h /usr/local/lib/glib-2.0/include/glibconfig.h \
            /usr/local/lib/libglib-2.0.so; do
        [ -e "$_f" ] || { echo "mc-build: no $_f (the package glib of devel/glib20)" >&2; return 1; }
    done
    v="$(pkgconf --modversion "$_pc" 2>/dev/null)"
    [ -n "$v" ] || { echo "mc-build: no version of GLib in $_pc (pkgconf --modversion)" >&2; return 1; }
    mkdir -p "$W/glib" "$W/lib/pkgconfig" &&
        ln -sf /usr/local/lib/libglib-2.0.so "$W/glib/libglib-2.0.so" &&
        printf '%s\n' 'Name: GLib' 'Description: GLib of devel/glib20' "Version: $v" \
            "Libs: -L$W/glib -lglib-2.0" \
            'Cflags: -I/usr/local/include/glib-2.0 -I/usr/local/lib/glib-2.0/include' > "$W/lib/pkgconfig/glib-2.0.pc"
}
# mc: after the port's patches those of files/ (the archives through ubsdtar), then
# configure with the paths of the port and the configure lines of mc.conf; the
# programs its scripts run at the paths of the servers, not those the build machine
# happens to have (configure takes them from PATH): Perl and zip of the packages,
# unzip of the base system, Python and Ruby from PATH; ncursesw of the base system
# with its wide characters (NCURSES_WIDECHAR, as the port); PIE, RELRO, BIND_NOW
# need_defines <config.h> <macro>...: each macro defined there (by configure)
need_defines() {
    _h="$1"; shift
    for _d in "$@"; do
        grep -q "^#define $_d 1" "$_h" || { echo "== configure: no $_d in config.h"; return 1; }
    done
    echo "== config.h: $*"
}
# the unit test of upstream for file cloning (tests/lib/vfs/vfs_clone_file.c of
# files/copy-clone-1.patch) in a copy of the source of its own, configured with
# --enable-tests and check of devel/check (its .pc is not among those of PKG_CONFIG_LIBDIR):
# vfs_clone_file() has to call copy_file_range() with COPY_FILE_RANGE_CLONE
clone_unit_test() {
    (
        cd "$1" || exit 1
        # shellcheck disable=SC2046
        CFLAGS="$cflags -DNCURSES_WIDECHAR" CHECK_CFLAGS="-I/usr/local/include" \
            CHECK_LIBS="-L/usr/local/lib -lcheck" ./configure --disable-silent-rules --enable-tests \
            PERL=/usr/local/bin/perl PERL_FOR_BUILD=/usr/local/bin/perl $(conf_opts) &&
            grep -q "^#define HAVE_TESTS 1" config.h &&
            gmake -j"$ncpu" -C lib && gmake -C tests/lib/vfs check TESTS=vfs_clone_file
    ) > "$res/mc-unit-test.log" 2>&1
    _rc=$?
    cp "$1/tests/lib/vfs/vfs_clone_file.log" "$res/mc-unit-test-vfs_clone_file.log" 2>/dev/null
    if [ "$_rc" = 0 ] && grep -q "^PASS: vfs_clone_file" "$res/mc-unit-test.log"; then
        _c="$(grep -m 1 'Checks:' "$1/tests/lib/vfs/vfs_clone_file.log" 2>/dev/null)"
        echo "== unit test vfs_clone_file: PASS ($_c)"
        printf '%-8s PASS  the unit test vfs_clone_file of upstream (%s)\n' unit "$_c" >> "$res/summary.txt"
        return 0
    fi
    echo "== unit test vfs_clone_file: FAIL (exit $_rc; mc-unit-test.log):"
    tail -n 20 "$res/mc-unit-test.log"
    return 1
}
b_mc() {
    rm -rf "$stage"
    for p in "$files"/*.patch; do
        [ -f "$p" ] || continue
        echo "== files/${p##*/}"
        patch -p0 -N -s -d "$1" < "$p" || { echo "== ${p##*/} does not apply"; return 1; }
    done
    # files/copy-clone-1.patch changes configure.ac (copy_file_range of FreeBSD) and a
    # Makefile.am: configure, config.h.in and the Makefile.in files anew with the
    # autotools of the build dependencies of the port (autoconf, automake, libtool,
    # autopoint of gettext-tools)
    echo "== autoreconf -fi"
    (cd "$1" && autoreconf -fi) || { echo "== autoreconf -fi failed"; return 1; }
    fix_guess "$1"
    rm -rf "$1.tests"
    cp -Rp "$1" "$1.tests" || { echo "== no copy of the source for the unit test"; return 1; }
    (
        cd "$1" || exit 1
        # shellcheck disable=SC2046
        CFLAGS="$cflags -fPIE -DNCURSES_WIDECHAR" LDFLAGS="$LDFLAGS -pie -Wl,-z,relro,-z,now" \
            ./configure --prefix="$F" --localstatedir=/var --mandir="$F/share/man" --disable-silent-rules \
            PERL=/usr/local/bin/perl PERL_FOR_BUILD=/usr/local/bin/perl "PYTHON=/usr/bin/env python3" \
            "RUBY=/usr/bin/env ruby" ZIP=/usr/local/bin/zip UNZIP=/usr/bin/unzip $(conf_opts) &&
            need_defines config.h HAVE_COPY_FILE_RANGE HAVE_FILE_CLONING_BY_RANGE &&
            gmake -j"$ncpu" && gmake install-strip DESTDIR="$stage"
    ) || { cp "$1/config.log" "$res/mc-config.log" 2>/dev/null; return 1; }
    cp "$1/config.log" "$res/mc-config.log" 2>/dev/null
    clone_unit_test "$1.tests" || return 1
    # no manual pages, as in the other packages of this tree (MANPAGES is in the
    # OPTIONS_UNSET of the make.conf of the servers); the help of mc (F1) stays
    rm -rf "$stage$F/share/man"
    install -m 755 "$files/ubsdtar" "$stage$F/libexec/mc/extfs.d/ubsdtar" || return 1
    # the licence of mc (the shared libraries it links are those of the packages az
    # and glib, with their licences, and of the base system)
    lic="$stage$F/share/licenses/mc"
    mkdir -p "$lic" && cp "$1/COPYING" "$lic/mc-COPYING" || return 1
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
        echo "GLib: libglib-2.0.so of devel/glib20 ($(pkgconf --modversion /usr/local/libdata/pkgconfig/glib-2.0.pc 2>/dev/null));"
        echo "libssh2: the shared library of $A/lib (the package az, with that run path), with the"
        echo "OpenSSL of the base system:"
        awk '$1 == "libssh2" { print "    " $0 }' \
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
        echo "Licence: GPL version 3 or later (mc), in share/licenses/mc/ (those of the shared"
        echo "libraries in their packages)."
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
    rp="$(readelf -d "$f" | sed -n 's/.*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1/p')"
    printf 'mc: %s KB, ELF type %s, RELRO %s, BIND_NOW %s, run path %s; libraries: %s\n' \
        "$(du -Ak "$f" | cut -f1)" "$type" "$relro" "$now" "${rp:-none}" "$libs" >> "$res/bins.txt"
    # the base system, the shared tree of az (by the run path), GLib of devel/glib20
    # and PCRE2 of devel/pcre2 (which GLib links)
    for l in $libs; do
        case "$l" in
            /lib/* | /usr/lib/* | /usr/local/lib/libglib-2.0.so.* | /usr/local/lib/libpcre2-8.so.*) ;;
            "$A"/static/*) echo "mc: $l of the static tree" ;;
            "$A"/lib/*) case ":$rp:" in *":$A/lib:"*) ;; *) echo "mc: $l without the run path $A/lib (${rp:-none})" ;; esac ;;
            *) echo "mc: $l, not of the base system, az, glib or pcre2" ;;
        esac
    done >> "$res/bins-bad.txt"
    [ "$type" = DYN ] || echo "mc: not a PIE (ELF type $type)" >> "$res/bins-bad.txt"
    [ "$relro" -gt 0 ] || echo "mc: no RELRO" >> "$res/bins-bad.txt"
    [ "$now" -gt 0 ] || echo "mc: no BIND_NOW" >> "$res/bins-bad.txt"
    for l in mcedit mcview mcdiff; do
        [ -L "$stage$F/bin/$l" ] || echo "mc: no link bin/$l" >> "$res/bins-bad.txt"
    done
    # mc wants TERM even for --version: without it, only "The TERM environment variable
    # is unset!" and exit status 1 (the chroot of tools/build.sh has no TERM: the first
    # build there, 11.11.2026)
    TERM=dumb "$f" --version > "$res/version.txt" 2>&1
    vrc=$?
    miss=""
    for w in "Built with GLib" "Built with libssh2" "With builtin editor" "With subshell support as default" \
            "With multiple codepages support" sftpfs; do
        grep -q "$w" "$res/version.txt" || miss="$miss, \"$w\""
    done
    if [ "$vrc" != 0 ] || [ -n "$miss" ]; then
        {
            echo "mc --version: exit status $vrc${miss:+, no ${miss#, }}; its output (TERM=dumb):"
            sed -n '1,15s/^/    /p' "$res/version.txt"
        } >> "$res/bins-bad.txt"
    fi
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
for f in lib/libssh2.so lib/pkgconfig/libssh2.pc include/libssh2.h; do
    if [ ! -e "$A/$f" ]; then
        printf '%-8s FAIL  no %s of the shared libraries in %s: install the package az first (az/az)\n' libs "$f" "$A" >> "$res/summary.txt"
        echo "mc-build: no $A/$f; install the package az first (the port az/az)" >&2
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
glib_dir 2> "$res/glib.err" || { echo "glib     FAIL  $(cat "$res/glib.err")" >> "$res/summary.txt"; cat "$res/glib.err" >&2; report; exit 1; }
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
