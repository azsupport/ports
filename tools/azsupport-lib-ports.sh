#!/bin/sh
# azsupport-lib-ports.sh - the ports of the libraries of the shared tree of
# /usr/local/azsupport: azsupport/<name>, the package azsupport-<name>, one for every
# library of the kind shared in deps.conf (aZ, 26.11.2026: «да», «ну так чего потом уж,
# делай сразу»), made from the confs in files/ of the port of the static tree (the
# directory of azsupport/ that has files/deps.conf):
#   Makefile    PORTNAME and PORTVERSION (the version of its take line, of the bundled
#               curl in curl-deps.conf, else of its official port), CATEGORIES (azsupport
#               and that of the port), the release file of its take line or of
#               curl-deps.conf as a distfile of its own (MASTER_SITES and DISTFILES with
#               DIST_SUBDIR azsupport of Makefile.common; a GitHub archive without the
#               name of the file gets ?dummy=/), COMMENT, LICENSE (and LICENSE_COMB, and
#               the name and permissions of a licence of its port that the framework
#               does not know) of its official port, the dependencies of the extras below,
#               AZSUPPORT_LIB (its name), AZSUPPORT_LIB_PORT (its port, or bundle),
#               AZSUPPORT_LIB_CONF and AZSUPPORT_LIB_FILES (conf_lines_of and lib_files_of
#               of tools/azsupport-build.sh, taken from it: its lines of the confs and its
#               files of files/, which its --lib checks against the confs),
#               AZSUPPORT_LIB_NEEDS (its needs line), AZSUPPORT_HASH_OFFICIAL (its
#               official port and the directories of the official tree its MASTERDIR,
#               DISTINFO_FILE, FILESDIR and PATCHDIR are in; none for the bundled curl,
#               which takes nothing of a port), then Makefile.lib of the port of the static
#               tree and bsd.port.mk
#   pkg-descr
#   distinfo    with a take line or of the bundled curl: SHA-256 of the confs, the size as
#               the distinfo files of this tree have it for the same SHA-256 (or of the
#               file in AZSUPPORT_DISTDIR/azsupport, default /usr/ports/distfiles)
# and, for the port of the static tree, Makefile.distfiles (the MASTER_SITES and
# DISTFILES of the bundled curl, curl.conf and curl-deps.conf, and of the take lines
# of the libraries of the kind static) and its distinfo. The extras: GCC 16 to build
# the libraries of gcc_so of tools/azsupport-build.sh (AZSUPPORT_GCC_SO), libimagequant
# for gd (LIQ). A take line or a line of curl-deps.conf with $ # or \ in it is refused
# (they are values of make).
#
# Usage: sh tools/azsupport-lib-ports.sh [--check|--write] <official tree> [<make args>]
#   --check (default): every file as this script would write it, every take and
#     bundled file with its SHA-256 and size in the distinfo, x11-fonts/fontconfig (a
#     library of the kind static whose shared one is a port of this tree: its
#     DISTVERSION that of its take line, its AZSUPPORT_LIBS the libraries of its needs
#     line), no port made here of a library that is no longer of the kind shared, the
#     needs lines (libraries of deps.conf, of the kind shared, no cycle); prints every
#     difference (diff -u) and every skip with the reason
#   --write: writes what differs (a distinfo keeps its TIMESTAMP when nothing else
#     changes), removes the files it made of a port of a library that is no longer of
#     the kind shared; then the same checks
#   <official tree>: freebsd-ports at the commit of deps.conf (Mk/ and the Makefile,
#     the makefiles and the distinfo of the ports of the libraries are enough)
#   <make args>: those tools/check-tree.sh gives make (on Linux bmake with -m of its
#     sys.mk and of the official Mk/, the variables of a FreeBSD 15.1 amd64 machine);
#     none: make on FreeBSD, bmake elsewhere with such arguments of its own
#     (MAKE_CONF: the make.conf to read, as for check-tree.sh)
# Exit status: 0 the ports are those of the confs (--check) or were written; 1 a
# difference (--check), something missing (a version, a licence, a size, a port) or
# a make that failed; 2 usage or setup.

set -u
mode=check
case "${1:-}" in
    --check) shift ;;
    --write) mode=write; shift ;;
esac
usage() { echo "usage: sh tools/azsupport-lib-ports.sh [--check|--write] <official tree> [<make args>]" >&2; exit 2; }
[ $# -ge 1 ] || usage
case "$1" in -*) usage ;; esac
off="$(cd "$1" 2> /dev/null && pwd)" || { echo "azsupport-lib-ports: no directory $1" >&2; exit 2; }
shift
[ -f "$off/Mk/bsd.port.mk" ] || { echo "azsupport-lib-ports: $off has no Mk/bsd.port.mk: not a ports tree" >&2; exit 2; }
top="$(cd "$(dirname "$0")/.." && pwd)"
bs="$top/tools/azsupport-build.sh"
[ -f "$bs" ] || { echo "azsupport-lib-ports: no $bs" >&2; exit 2; }

# the port of the static tree: the directory of azsupport/ with files/deps.conf
sp=""
for f in "$top"/azsupport/*/files/deps.conf; do
    [ -f "$f" ] || continue
    [ -z "$sp" ] || { echo "azsupport-lib-ports: two ports with files/deps.conf: $sp and ${f%/files/deps.conf}" >&2; exit 2; }
    sp="${f%/files/deps.conf}"
done
[ -n "$sp" ] || { echo "azsupport-lib-ports: no azsupport/*/files/deps.conf in $top" >&2; exit 2; }
spn="${sp##*/}"
files="$sp/files"
conf="$files/deps.conf"

os="$(uname -s)"
if [ -z "${MAKE:-}" ]; then
    if [ "$os" = FreeBSD ]; then MAKE=make; else MAKE=bmake; fi
fi
command -v "$MAKE" > /dev/null 2>&1 || { echo "azsupport-lib-ports: no $MAKE (Linux: bmake)" >&2; exit 2; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-lib-ports.XXXXXX")" || { echo "azsupport-lib-ports: no temporary directory" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' INT TERM
# no make arguments: those of tools/check-tree.sh (the official tree, this tree as the
# overlay, no saved options; on Linux a sys.mk and the machine of the VM)
if [ $# -eq 0 ]; then
    mc=/dev/null
    if [ -n "${MAKE_CONF:-}" ]; then
        mc="$(cd "$(dirname "$MAKE_CONF")" 2> /dev/null && pwd)/${MAKE_CONF##*/}"
        [ -f "$mc" ] || { echo "azsupport-lib-ports: no make.conf $MAKE_CONF" >&2; exit 2; }
    fi
    mkdir -p "$tmp/dbdir" "$tmp/wrk"
    set -- PORTSDIR="$off" OVERLAYS="$top" PORT_DBDIR="$tmp/dbdir" WRKDIRPREFIX="$tmp/wrk" __MAKE_CONF="$mc"
    if [ "$os" != FreeBSD ]; then
        mkdir -p "$tmp/mk"
        printf '%s\n' '# sys.mk of azsupport-lib-ports.sh, as that of check-tree.sh' \
            'MACHINE=	amd64' 'MACHINE_ARCH=	amd64' 'MACHINE_CPUARCH=	amd64' \
            'AR?=	ar' 'CC?=	cc' 'CXX?=	c++' 'CPP?=	cpp' 'LD?=	ld' 'NM?=	nm' 'OBJCOPY?=	objcopy' 'RANLIB?=	ranlib' \
            'CFLAGS?=	-O2 -pipe' 'CXXFLAGS?=	${CFLAGS:N-std=*}' \
            '.if defined(__MAKE_CONF) && exists(${__MAKE_CONF})' '.include "${__MAKE_CONF}"' '.endif' > "$tmp/mk/sys.mk"
        set -- -m "$tmp/mk" -m "$off/Mk" "$@" OPSYS=FreeBSD OSVERSION=1501000 OSREL=15.1 _OSRELEASE=15.1-RELEASE \
            ARCH=amd64 UNAME_s=FreeBSD UNAME_r=15.1-RELEASE UNAME_p=amd64 UNAME_m=amd64 \
            CONFIGURE_MAX_CMD_LEN=262144 _SMP_CPUS=2
    fi
fi

# The functions of the confs of tools/azsupport-build.sh, taken from it, so that the
# lines and files written here are those its --lib checks
fns="$(awk -v names=" port_of has_kind take_of libs_of_kind needs_of needs_closure conf_lines_of lib_files_of " '
    !inf && /^[a-z_]+\(\) *\{/ {
        fn = substr($0, 1, index($0, "(") - 1)
        if (index(names, " " fn " ") == 0) next
        print; if ($0 !~ /\}[ \t]*$/) inf = 1; next
    }
    inf { print; if ($0 ~ /^\}/) inf = 0 }' "$bs")"
eval "$fns"
for f in port_of has_kind take_of libs_of_kind needs_of needs_closure conf_lines_of lib_files_of; do
    command -v "$f" > /dev/null 2>&1 || { echo "azsupport-lib-ports: no function $f in $bs" >&2; exit 2; }
done
libs_all="$(awk '$1 == "lib" { print $2 }' "$conf")"
gcc_so="$(sed -n 's/^gcc_so="\${AZSUPPORT_GCC_SO-\(.*\)}"$/\1/p' "$bs")"
[ -n "$gcc_so" ] || { echo "azsupport-lib-ports: no gcc_so in $bs" >&2; exit 2; }
libs="$(libs_of_kind shared)"

rc=0
nok=0; nnew=0; ndiff=0; nmiss=0
say() { printf '%s\n' "$*"; }
miss() { say "MISSING $*"; nmiss=$((nmiss + 1)); rc=1; }

sha_of() { if command -v sha256 > /dev/null 2>&1; then sha256 -q "$1"; else sha256sum < "$1" | cut -c1-64; fi; }
size_of() { wc -c < "$1" | tr -d ' '; }
# normpath <path>: without . and .. parts
normpath() {
    printf '%s\n' "$1" | awk -F/ '{ n = 0
        for (i = 1; i <= NF; i++) { if ($i == "" || $i == ".") continue; if ($i == "..") { if (n > 0) n--; continue } p[++n] = $i }
        s = ""; for (i = 1; i <= n; i++) s = s "/" p[i]; print (s == "" ? "/" : s) }'
}

# offinfo <origin>: make -V of an official port into $tmp/off/<origin with _>: lines 1
# PORTVERSION, 2 LICENSE, 3 LICENSE_COMB, 4 MASTERDIR, 5 DISTINFO_FILE, 6 FILESDIR, 7
# PATCHDIR. The regular expressions of BSD that the regex of another system lacks
# ([[:>:]] in the DISTNAME of databases/sqlite3): once more with DISTNAME given, which
# none of these values comes from.
offinfo() {
    _oo="$1"; shift
    _of="$tmp/off/$(printf '%s' "$_oo" | tr / _)"
    [ -f "$_of" ] && return 0
    mkdir -p "$tmp/off"
    if [ ! -f "$off/$_oo/Makefile" ]; then
        echo "no port $_oo in $off" > "$_of.err"
        return 1
    fi
    if ! "$MAKE" -C "$off/$_oo" "$@" -V PORTVERSION -V LICENSE -V LICENSE_COMB -V MASTERDIR -V DISTINFO_FILE \
            -V FILESDIR -V PATCHDIR > "$_of.tmp" 2> "$_of.err" < /dev/null; then
        say "SKIP    make -V of $_oo failed ($(grep -v '^[[:space:]]*$' "$_of.err" | head -n 1)): again with DISTNAME on the command line"
        "$MAKE" -C "$off/$_oo" "$@" DISTNAME=azsupport-lib-ports -V PORTVERSION -V LICENSE -V LICENSE_COMB -V MASTERDIR \
            -V DISTINFO_FILE -V FILESDIR -V PATCHDIR > "$_of.tmp" 2> "$_of.err" < /dev/null || return 1
    fi
    mv "$_of.tmp" "$_of"
}
# offv <origin> <line>: a value of offinfo
offv() { sed -n "${2}p" "$tmp/off/$(printf '%s' "$1" | tr / _)"; }
# offvar <origin> <variable> <make args>: one variable of an official port (again with
# DISTNAME given, as offinfo); "?" and 1 when make fails
offvar() {
    _o="$1" _v="$2"; shift 2
    if _r="$("$MAKE" -C "$off/$_o" "$@" -V "$_v" 2> /dev/null < /dev/null)" ||
        _r="$("$MAKE" -C "$off/$_o" "$@" DISTNAME=azsupport-lib-ports -V "$_v" 2> /dev/null < /dev/null)"; then
        printf '%s\n' "$_r"
        return 0
    fi
    echo "?"
    return 1
}

# The sizes of the distfiles of this tree: the distinfo of the port of the static tree
# and of the ports of the libraries ("<file> <SHA-256> <size>", file under azsupport/)
for d in "$top"/azsupport/*/distinfo; do
    [ -f "$d" ] || continue
    awk '$1 == "SHA256" { f = $2; gsub(/[()]/, "", f); s[f] = $4 } $1 == "SIZE" { f = $2; gsub(/[()]/, "", f); z[f] = $4 }
        END { for (f in s) if (f in z) print f, s[f], z[f] }' "$d"
done | LC_ALL=C sort -u > "$tmp/sizes"
ddir="${AZSUPPORT_DISTDIR:-/usr/ports/distfiles}/azsupport"
# size <file> <SHA-256>: its size, from the distinfo files or the file in ddir; nothing
size() {
    _z="$(awk -v f="azsupport/$1" -v s="$2" '$1 == f && $2 == s { print $3; exit }' "$tmp/sizes")"
    if [ -z "$_z" ] && [ -f "$ddir/$1" ] && [ "$(sha_of "$ddir/$1")" = "$2" ]; then _z="$(size_of "$ddir/$1")"; fi
    printf '%s' "$_z"
}

# makeval <text>: refused when make would take it for something else
makeval() {
    case "$1" in *'$'* | *'#'* | *'\'*) return 1 ;; esac
    return 0
}

# site <url> <distfile>: the MASTER_SITES entry that gives <url> for <distfile>: its
# directory; the URL with ?dummy=/ when its last part is not the name of the file (a
# tarball of codeload.github.com); GNU/<dir> for ftp.gnu.org (its mirrors)
site() {
    case "$1" in
        */"$2")
            _d="${1%"$2"}"
            case "$_d" in https://ftp.gnu.org/gnu/*) _d="GNU/${_d#https://ftp.gnu.org/gnu/}"; _d="${_d%/}" ;; esac
            printf '%s' "$_d" ;;
        *) printf '%s?dummy=/' "$1" ;;
    esac
}
# group <name>: the group of a distfile of MASTER_SITES (letters and digits)
group() { printf '%s' "$1" | tr -c -d 'A-Za-z0-9_'; }

# dists <name>: the distfiles of a library, "<file> <SHA-256> <site>..." a line each:
# its take line (the file of its first address, every address a site), or its line of
# curl-deps.conf (the distfile with / made _, as tools/azsupport-curl-sources.sh keeps it;
# libpsl: with psl-list), or of curl.conf (curl); nothing for a port without them
dists() {
    _n="$1"
    if [ "$_n" = curl ]; then
        awk '!/^#/ && NF >= 4 { u = $3; s = $4 } END { if (u != "") { n = split(u, p, "/"); print p[n], s, u } }' "$files/curl.conf" |
            while read -r _f _s _u; do printf '%s %s %s\n' "$_f" "$_s" "$(site "$_u" "$_f")"; done
        return 0
    fi
    if [ "$(port_of "$_n")" = bundle ]; then
        for _r in "$_n" psl-list; do
            [ "$_r" = "$_n" ] || [ "$_n" = libpsl ] || continue
            awk -v n="$_r" '!/^#/ && NF >= 7 && $1 == n { print $5, $6, $7 }' "$files/curl-deps.conf" |
                while read -r _df _s _u; do
                    _f="$(printf '%s' "$_df" | tr / _)"
                    printf '%s %s %s\n' "$_f" "$_s" "$(site "$_u" "$_f")"
                done
        done
        return 0
    fi
    _t="$(take_of "$_n")"
    [ -n "$_t" ] || return 0
    # shellcheck disable=SC2086
    set -- $_t
    _f="${2%%,*}"; _f="${_f##*/}"
    _l="$_f $3"
    for _u in $(printf '%s' "$2" | tr ',' ' '); do
        if [ "${_u##*/}" != "$_f" ]; then
            say "SKIP    the address $_u of the take line of $_n: not the file $_f of its first address" >&2
            continue
        fi
        _l="$_l $(site "$_u" "$_f")"
    done
    printf '%s\n' "$_l"
}
# groups of a library's distfiles: take (a take line), bundle and psllist (curl-deps.conf)
dgroup() {
    if [ "$(port_of "$1")" != bundle ]; then echo take
    elif [ "$2" = 1 ]; then echo bundle
    else echo psllist
    fi
}

# mk_sites, mk_files <file of distfiles>: the lines of MASTER_SITES= and DISTFILES= of
# the distfiles ("<file> <SHA-256> <site>... <group>" a line each), continued with
# backslashes
mk_sites() {
    awk '{ for (i = 3; i < NF; i++) { ns++; ms[ns] = $i ":" $NF } }
        END { for (i = 1; i <= ns; i++) printf "%s%s%s\n", (i == 1 ? "MASTER_SITES=\t" : "\t\t"), ms[i], (i < ns ? " \\" : "") }' "$1"
}
mk_files() {
    awk '{ nd++; df[nd] = $1 ":" $NF }
        END { for (i = 1; i <= nd; i++) printf "%s%s%s\n", (i == 1 ? "DISTFILES=\t" : "\t\t"), df[i], (i < nd ? " \\" : "") }' "$1"
}
# mk_distinfo <file of dists> <out>: a distinfo of these distfiles (no TIMESTAMP)
mk_distinfo() {
    : > "$2"
    while read -r _f _s _rest; do
        printf 'SHA256 (azsupport/%s) = %s\n' "$_f" "$_s" >> "$2"
        _z="$(size "$_f" "$_s")"
        if [ -n "$_z" ]; then
            printf 'SIZE (azsupport/%s) = %s\n' "$_f" "$_z" >> "$2"
        else
            miss "SIZE of azsupport/$_f (SHA-256 $_s): in no distinfo of this tree; put the file into $ddir (AZSUPPORT_DISTDIR) and write again"
        fi
    done < "$1"
}

# put <new file> <path in the tree>: compare (distinfo: without its TIMESTAMP), and with
# --write write it
put() {
    _new="$1" _p="$2" _t="$top/$2" _was=""
    [ ! -f "$_t" ] || _was=1
    case "$_p" in */distinfo) _cmp="$tmp/cmp.old"; grep -v '^TIMESTAMP' "$_t" > "$_cmp" 2> /dev/null ;; *) _cmp="$_t" ;; esac
    if [ -f "$_t" ] && cmp -s "$_new" "$_cmp"; then
        return 0
    fi
    if [ "$mode" = write ]; then
        mkdir -p "${_t%/*}"
        case "$_p" in
            */distinfo) { echo "TIMESTAMP = $(date +%s)"; cat "$_new"; } > "$_t" ;;
            *) cp "$_new" "$_t" ;;
        esac
        if [ -n "$_was" ]; then say "WROTE   $_p"; else say "WROTE   $_p (new)"; fi
        nnew=$((nnew + 1))
    else
        if [ -f "$_t" ]; then
            say "DIFF    $_p:"
            diff -u "$_cmp" "$_new" | sed -e '1,2d' -e 's/^/        /'
        else
            say "DIFF    $_p: not there"
        fi
        ndiff=$((ndiff + 1)); rc=1
    fi
}

# --- the needs lines -----------------------------------------------------------------
awk '$1 == "needs" { print $2 }' "$conf" | LC_ALL=C sort | uniq -d | while read -r n; do
    say "FAIL    two needs lines of $n in deps.conf"
done | grep . && rc=1
for n in $(awk '$1 == "needs" { print $2 }' "$conf"); do
    if [ -z "$(port_of "$n")" ]; then say "FAIL    needs $n: no lib line of $n in deps.conf"; rc=1; continue; fi
    if ! has_kind "$n" shared && [ ! -f "$top/$(port_of "$n")/Makefile" ]; then
        say "FAIL    needs $n: $n is not of the kind shared and its port $(port_of "$n") is not in this tree"; rc=1
    fi
    for l in $(needs_of "$n"); do
        if [ -z "$(port_of "$l")" ]; then say "FAIL    needs $n: $l has no lib line in deps.conf"; rc=1
        elif ! has_kind "$l" shared; then say "FAIL    needs $n: $l is not of the kind shared (no port azsupport/$l)"; rc=1
        fi
    done
    case " $(needs_closure "$n") " in *" $n "*) say "FAIL    needs $n: a cycle ($n needs itself through $(needs_closure "$n"))"; rc=1 ;; esac
done

# --- the ports of the libraries --------------------------------------------------------
mkdir -p "$tmp/new"
for n in $libs; do
    port="$(port_of "$n")"
    if [ "$port" = bundle ]; then
        row="$(awk -v n="$n" '!/^#/ && NF >= 7 && $1 == n { print $2, $3; exit }' "$files/curl-deps.conf")"
        [ -n "$row" ] || { miss "$n: a library of the bundled curl without its line in curl-deps.conf"; continue; }
        ver="${row%% *}" origin="${row#* }"
    else
        origin="$port" ver="$(take_of "$n" | awk '{ print $1 }')"
    fi
    if ! offinfo "$origin" "$@"; then
        say "FAIL    $n: make -V of $origin: $(grep -v '^[[:space:]]*$' "$tmp/off/$(printf '%s' "$origin" | tr / _).err" | head -n 2 | tr '\n' ' ')"
        rc=1; continue
    fi
    hoff=""
    if [ "$port" != bundle ]; then
        [ -n "$ver" ] || ver="$(offv "$origin" 1)"
        # the official ports it is built from: its own and those of its MASTERDIR,
        # DISTINFO_FILE, FILESDIR and PATCHDIR
        hoff="$(for i in 4 5 6 7; do
                p="$(normpath "$(offv "$origin" "$i")")"
                case "$p" in "$off"/*/*) p="${p#"$off"/}"; echo "$p" | cut -d/ -f1-2 ;; esac
            done | grep -v -F -x "$origin" | grep -v '^Mk/' | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
        hoff="$origin${hoff:+ $hoff}"
    fi
    lic="$(offv "$origin" 2)" lcomb="$(offv "$origin" 3)"
    [ -n "$ver" ] || { miss "$n: no version (its take line, curl-deps.conf or PORTVERSION of $origin)"; continue; }
    # a make too old for the official tree gives no error for what it cannot evaluate
    # (bmake 20200710 and the :On of devel/readline: 8.3.:[-1]})
    case "$ver" in
        *[!0-9A-Za-z._+-]*) say "FAIL    $n: the version $ver ($origin): not a version, a make too old for the official tree? ($MAKE)"; rc=1; continue ;;
    esac
    [ -n "$lic" ] || { miss "$n: no LICENSE of $origin"; continue; }
    cl="$(conf_lines_of "$n")" fl="$(lib_files_of "$n")"
    nd="$(needs_of "$n" | tr '\n' ' ' | sed 's/ $//')"
    if ! makeval "$cl"; then say "FAIL    $n: its lines of the confs have \$, # or \\ (values of make): $cl"; rc=1; continue; fi
    d="$tmp/new/$n"
    mkdir -p "$d"
    dists "$n" > "$d/dists.txt"
    i=0
    while read -r f s rest; do
        i=$((i + 1))
        printf '%s %s %s %s\n' "$f" "$s" "$rest" "$(dgroup "$n" "$i")"
    done < "$d/dists.txt" > "$d/dists2.txt"
    if [ "$port" = bundle ]; then via="bundle, $origin"; else via="$origin"; fi
    {
        echo "# azsupport/$n: made by tools/azsupport-lib-ports.sh from its lines of"
        echo "# ${sp#"$top"/}/files/deps.conf$( [ "$port" = bundle ] && echo ' and curl-deps.conf'): do not edit; --write makes it again."
        echo
        printf 'PORTNAME=\t%s\n' "$n"
        printf 'PORTVERSION=\t%s\n' "$ver"
        printf 'CATEGORIES=\tazsupport %s\n' "${origin%%/*}"
        if [ -s "$d/dists2.txt" ]; then mk_sites "$d/dists2.txt"; fi
        printf 'PKGNAMEPREFIX=\tazsupport-\n'
        if [ -s "$d/dists2.txt" ]; then mk_files "$d/dists2.txt"; fi
        echo
        printf 'COMMENT=\t%s of /usr/local/azsupport (shared; %s)\n' "$n" "$via"
        printf 'WWW=\t\thttps://github.com/azsupport/ports\n'
        echo
        printf 'LICENSE=\t%s\n' "$lic"
        [ -z "$lcomb" ] || printf 'LICENSE_COMB=\t%s\n' "$lcomb"
        for l in $lic; do
            # a licence the framework does not know: its name and permissions as its port has them
            ln="$(offvar "$origin" "LICENSE_NAME_$l" "$@")" || { say "FAIL    $n: make -V LICENSE_NAME_$l of $origin failed" >&2; rc=1; continue; }
            [ -n "$ln" ] || continue
            printf 'LICENSE_NAME_%s=\t%s\n' "$l" "$ln"
            lp="$(offvar "$origin" "LICENSE_PERMS_$l" "$@")"; [ -z "$lp" ] || printf 'LICENSE_PERMS_%s=\t%s\n' "$l" "$lp"
            lg="$(offvar "$origin" "LICENSE_GROUPS_$l" "$@")"; [ -z "$lg" ] || printf 'LICENSE_GROUPS_%s=\t%s\n' "$l" "$lg"
            printf 'LICENSE_TEXT_%s=\tthe licence files of %s are in /usr/local/azsupport/LICENSES\n' "$l" "$n"
        done
        case " $gcc_so " in *" $n "*) echo; printf 'BUILD_DEPENDS=\tgcc16:lang/gcc16\n' ;; esac
        [ "$n" != gd ] || { echo; printf 'LIB_DEPENDS=\tlibimagequant.so:graphics/libimagequant\n'; }
        echo
        printf 'AZSUPPORT_LIB=\t\t%s\n' "$n"
        printf 'AZSUPPORT_LIB_PORT=\t%s\n' "$port"
        printf 'AZSUPPORT_LIB_CONF=\t%s\n' "$cl"
        printf 'AZSUPPORT_LIB_NEEDS=\t%s\n' "$nd"
        printf 'AZSUPPORT_LIB_FILES=\t%s\n' "$fl"
        printf 'AZSUPPORT_HASH_OFFICIAL=\t%s\n' "$hoff"
        echo
        printf '.include "${.CURDIR:H}/%s/Makefile.lib"\n' "$spn"
        echo '.include <bsd.port.mk>'
    } | sed 's/[ \t]*$//' > "$d/Makefile"
    {
        echo "$n of /usr/local/azsupport: its shared library, headers, pkg-config files and"
        if [ "$port" = bundle ]; then
            echo "*-config scripts, built from its release of the bundled curl ($origin; the line of"
            echo "curl-deps.conf), with the options of the static one,"
        else
            echo "*-config scripts, built from the FreeBSD port $origin (its version, distfiles and"
            echo "patches at the commit of deps.conf) with the options of the static one,"
        fi
        echo "with the run path /usr/local/azsupport/lib and the OpenSSL of the base system, for"
        echo "the packages of azsupport/ports; its licences in /usr/local/azsupport/LICENSES and its"
        echo "manifest share/azsupport/interface/$n.txt (the interface the ports that link it take"
        echo "into their hash)."
    } > "$d/pkg-descr"
    put "$d/Makefile" "azsupport/$n/Makefile"
    put "$d/pkg-descr" "azsupport/$n/pkg-descr"
    if [ -s "$d/dists.txt" ]; then
        mk_distinfo "$d/dists.txt" "$d/distinfo"
        put "$d/distinfo" "azsupport/$n/distinfo"
    elif [ -f "$top/azsupport/$n/distinfo" ]; then
        if [ "$mode" = write ]; then rm -f "$top/azsupport/$n/distinfo"; say "REMOVED azsupport/$n/distinfo (no distfiles)"
        else say "DIFF    azsupport/$n/distinfo: there, but the port has no distfiles"; ndiff=$((ndiff + 1)); rc=1; fi
    fi
    nok=$((nok + 1))
    dl="$(awk '{ printf "%s%s", (NR > 1 ? " " : ""), $1 }' "$d/dists.txt")"
    say "PORT    azsupport/$n $ver ($via; needs: ${nd:-none}; files: ${fl:-none}; distfiles: ${dl:-none})"
done

# --- the port of the static tree: Makefile.distfiles and distinfo -----------------------
{
    dists curl | awk '{ print $0, "curl" }'
    awk '!/^#/ && NF >= 7 { print $1 }' "$files/curl-deps.conf" | while read -r r; do
        awk -v n="$r" '!/^#/ && NF >= 7 && $1 == n { print $5, $6, $7 }' "$files/curl-deps.conf" | while read -r df s u; do
            f="$(printf '%s' "$df" | tr / _)"
            printf '%s %s %s %s\n' "$f" "$s" "$(site "$u" "$f")" "$(group "$r")"
        done
    done
    for n in $(libs_of_kind static); do
        [ "$(port_of "$n")" != bundle ] || continue
        dists "$n" | awk -v g="$(group "$n")" '{ print $0, g }'
    done
} > "$tmp/static-dists.txt"
{
    echo "# ${sp#"$top"/}/Makefile.distfiles: made by tools/azsupport-lib-ports.sh (--write) from"
    echo "# files/curl.conf, files/curl-deps.conf and the take lines of files/deps.conf of the"
    echo "# libraries of the kind static: do not edit. The names are those"
    echo "# tools/azsupport-curl-sources.sh keeps them under (the distfile of curl-deps.conf, /"
    echo "# made _) and the take lines give (the file of their first address)."
    mk_sites "$tmp/static-dists.txt"
    mk_files "$tmp/static-dists.txt"
} | sed 's/[ \t]*$//' > "$tmp/Makefile.distfiles"
put "$tmp/Makefile.distfiles" "${sp#"$top"/}/Makefile.distfiles"
awk '{ print $1, $2 }' "$tmp/static-dists.txt" > "$tmp/static-dists2.txt"
mk_distinfo "$tmp/static-dists2.txt" "$tmp/static-distinfo"
put "$tmp/static-distinfo" "${sp#"$top"/}/distinfo"

# --- a library of the kind static whose shared library is a port of this tree ----------
for n in $libs_all; do
    has_kind "$n" shared && continue
    [ -n "$(needs_of "$n")" ] || continue
    o="$(port_of "$n")"
    if [ ! -f "$top/$o/Makefile" ]; then miss "$o: the port of the shared $n (its needs line in deps.conf)"; continue; fi
    if ! "$MAKE" -C "$top/$o" "$@" -V DISTVERSION -V AZSUPPORT_LIBS -V AZSUPPORT_LIB > "$tmp/fc.out" 2> "$tmp/fc.err" < /dev/null; then
        say "FAIL    $o: make -V: $(grep -v '^[[:space:]]*$' "$tmp/fc.err" | head -n 1)"; rc=1; continue
    fi
    tv="$(take_of "$n" | awk '{ print $1 }')"
    dv="$(sed -n 1p "$tmp/fc.out")"
    al="$(sed -n 2p "$tmp/fc.out" | tr ' ' '\n' | sed 's/:.*//' | grep . | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"
    nl="$(needs_of "$n" | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"
    w=""
    if [ -n "$tv" ] && [ "$dv" != "$tv" ]; then w="$w DISTVERSION $dv, the take line of $n $tv;"; fi
    [ "$al" = "$nl" ] || w="$w AZSUPPORT_LIBS names $al, the needs line of $n $nl;"
    [ "$(sed -n 3p "$tmp/fc.out")" = "$n" ] || w="$w AZSUPPORT_LIB is $(sed -n 3p "$tmp/fc.out"), not $n;"
    # its distinfo: the SHA-256 of the take line for the file of its first address
    if [ -n "$tv" ]; then
        # shellcheck disable=SC2046
        set -- $(take_of "$n") "$@"
        tf="${2%%,*}"; tf="${tf##*/}"; ts="$3"
        shift 4
        ds="$(awk -v f="($tf)" '$1 == "SHA256" && ($2 == f || $2 ~ ("/" tf "\\)$")) { print $4; exit }' "$top/$o/distinfo" 2> /dev/null)"
        [ "$ds" = "$ts" ] || w="$w its distinfo has SHA-256 ${ds:-none} for $tf, the take line of $n $ts;"
    fi
    if [ -n "$w" ]; then say "DIFF    $o:$w"; ndiff=$((ndiff + 1)); rc=1; else say "OK      $o $dv (the shared $n; AZSUPPORT_LIBS $al)"; fi
done

# --- ports made here of a library that is no longer of the kind shared ------------------
for d in "$top"/azsupport/*/; do
    d="${d%/}"; x="${d##*/}"
    [ "$d" = "$sp" ] && continue
    case " $(echo $libs) " in *" $x "*) continue ;; esac
    if [ -f "$d/Makefile" ] && grep -q '^# azsupport/[^ ]*: made by tools/azsupport-lib-ports.sh' "$d/Makefile"; then
        if [ "$mode" = write ]; then
            rm -f "$d/Makefile" "$d/pkg-descr" "$d/distinfo"
            rmdir "$d" 2> /dev/null || say "SKIP    azsupport/$x: other files in it, left there"
            say "REMOVED azsupport/$x: no library $x of the kind shared in deps.conf"
            nnew=$((nnew + 1))
        else
            say "DIFF    azsupport/$x: a port made here, but deps.conf has no library $x of the kind shared"
            ndiff=$((ndiff + 1)); rc=1
        fi
    else
        say "SKIP    azsupport/$x: not made by this script (no line \"made by tools/azsupport-lib-ports.sh\" in its Makefile)"
    fi
done

case "$mode" in
    write) say "result: $nok ports of libraries, $nnew files written or removed, $nmiss missing (${sp#"$top"/}/files)" ;;
    *) say "result: $nok ports of libraries, $ndiff differences, $nmiss missing (${sp#"$top"/}/files)" ;;
esac
exit "$rc"
