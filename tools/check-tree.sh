#!/bin/sh
# check-tree.sh - check the ports of this overlay without building them, so that
# build.yml can run it before the FreeBSD VM: for every port of the tree
# (<category>/<port>/Makefile), make -V of PKGNAME, PKGORIGIN, BUILD_DEPENDS,
# LIB_DEPENDS, RUN_DEPENDS and IGNORE, with the official tree at the pinned commit
# as PORTSDIR and this tree as OVERLAYS. One line per port: OK (its package and the
# number of its dependencies), FAIL with the reason, IGNORE with the text of the
# port's IGNORE (shown, not a failure: it may come from the machine). FAIL:
#   - make fails (the error);
#   - PKGORIGIN is not the directory of the port (the builder and the dependencies
#     of the other ports name a port by its directory);
#   - a dependency names an origin that is neither a port of this tree nor one of
#     the official tree (<origin>/Makefile; a @flavor is left out);
#   - two ports have the same PKGNAME.
#
# Usage: sh tools/check-tree.sh <official tree>
#   <official tree>: a checkout of freebsd-ports at the pinned commit (Mk/ and the
#   Makefile of every port are enough). MAKE: make on FreeBSD, else bmake (Linux:
#   apt-get install bmake). MAKE_CONF=<file>: the make.conf of the builder (the
#   variables of aZ's servers: JPEG_PORT, OPTIONS_UNSET, ...), read on FreeBSD and
#   on Linux alike; without it the ports see none (FreeBSD: not /etc/make.conf).
#   On Linux the ports see a FreeBSD 15.1 amd64 machine (OPSYS, OSVERSION, ARCH
#   and the like given to make).
# Exit status: 0 no FAIL, 1 a FAIL, 2 usage or setup error.

set -u

[ $# -eq 1 ] || { echo "usage: sh tools/check-tree.sh <official tree (freebsd-ports at the pinned commit)>" >&2; exit 2; }
off="$(cd "$1" 2>/dev/null && pwd)" || { echo "check-tree: no directory $1" >&2; exit 2; }
[ -f "$off/Mk/bsd.port.mk" ] || { echo "check-tree: $off has no Mk/bsd.port.mk: not a ports tree" >&2; exit 2; }
top="$(cd "$(dirname "$0")/.." && pwd)"
os="$(uname -s)"
if [ -z "${MAKE:-}" ]; then
    if [ "$os" = FreeBSD ]; then MAKE=make; else MAKE=bmake; fi
fi
command -v "$MAKE" > /dev/null 2>&1 || { echo "check-tree: no $MAKE (Linux: apt-get install bmake)" >&2; exit 2; }
mc=/dev/null
if [ -n "${MAKE_CONF:-}" ]; then
    mc="$(cd "$(dirname "$MAKE_CONF")" 2>/dev/null && pwd)/${MAKE_CONF##*/}"
    [ -f "$mc" ] || { echo "check-tree: no make.conf $MAKE_CONF" >&2; exit 2; }
fi
tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-tree.XXXXXX")" || { echo "check-tree: no temporary directory" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' INT TERM
mkdir -p "$tmp/dbdir" "$tmp/wrk"

# The make of the ports: our tree as the overlay; no saved options of this machine
# (PORT_DBDIR empty), the work directories out of the trees. On Linux the include
# path of make has the Mk of the official tree (for <bsd.port.mk>), and the machine
# is the FreeBSD 15.1 amd64 of the VM; make.conf through __MAKE_CONF (FreeBSD's
# sys.mk reads it) and, on Linux, through a sys.mk of ours that reads it.
set -- PORTSDIR="$off" OVERLAYS="$top" PORT_DBDIR="$tmp/dbdir" WRKDIRPREFIX="$tmp/wrk" __MAKE_CONF="$mc"
if [ "$os" != FreeBSD ]; then
    mkdir -p "$tmp/mk"
    printf '%s\n' '# sys.mk of check-tree.sh: what the ports framework takes from the sys.mk of' \
        '# FreeBSD (the machine, the tools and their flags), then the make.conf of the builder' \
        'MACHINE=	amd64' 'MACHINE_ARCH=	amd64' 'MACHINE_CPUARCH=	amd64' \
        'AR?=	ar' 'CC?=	cc' 'CXX?=	c++' 'CPP?=	cpp' 'LD?=	ld' 'NM?=	nm' 'OBJCOPY?=	objcopy' 'RANLIB?=	ranlib' \
        'CFLAGS?=	-O2 -pipe' 'CXXFLAGS?=	${CFLAGS:N-std=*}' \
        '.if defined(__MAKE_CONF) && exists(${__MAKE_CONF})' '.include "${__MAKE_CONF}"' '.endif' > "$tmp/mk/sys.mk"
    set -- -m "$tmp/mk" -m "$off/Mk" "$@" OPSYS=FreeBSD OSVERSION=1501000 OSREL=15.1 _OSRELEASE=15.1-RELEASE \
        ARCH=amd64 UNAME_s=FreeBSD UNAME_r=15.1-RELEASE UNAME_p=amd64 UNAME_m=amd64 \
        CONFIGURE_MAX_CMD_LEN=262144 _SMP_CPUS=2
fi

nok=0; nfail=0; nign=0
say() { printf '%s\n' "$*"; }
: > "$tmp/names"
for mk in "$top"/*/*/Makefile; do
    [ -f "$mk" ] || continue
    d="${mk%/Makefile}"; o="${d#"$top"/}"
    case "$o" in Mk/* | Templates/* | Keywords/* | tools/* | .github/* | work/* | packages/* | distfiles/*) continue ;; esac
    if ! "$MAKE" -C "$d" "$@" -V PKGNAME -V PKGORIGIN -V BUILD_DEPENDS -V LIB_DEPENDS -V RUN_DEPENDS -V IGNORE \
        > "$tmp/out" 2> "$tmp/err" < /dev/null; then
        say "FAIL $o: make: $(grep -v '^[[:space:]]*$' "$tmp/err" | tail -n 3 | tr '\n' ' ' | sed 's/ *$//')"
        nfail=$((nfail + 1)); continue
    fi
    pn="$(sed -n 1p "$tmp/out")"; po="$(sed -n 2p "$tmp/out")"
    bd="$(sed -n 3p "$tmp/out")"; ld="$(sed -n 4p "$tmp/out")"; rd="$(sed -n 5p "$tmp/out")"
    ign="$(sed -n '6,$p' "$tmp/out" | tr '\n' ' ' | sed 's/ *$//')"
    why=""
    [ -n "$pn" ] || why="$why no PKGNAME;"
    [ "$po" = "$o" ] || why="$why PKGORIGIN is ${po:-empty}, not $o;"
    # the origins of the dependencies: <what>:<origin>[@<flavor>][:<target>]
    nd=0; unknown=""
    for kind in BUILD LIB RUN; do
        case "$kind" in BUILD) deps="$bd" ;; LIB) deps="$ld" ;; RUN) deps="$rd" ;; esac
        for dep in $deps; do
            org="$(printf '%s\n' "$dep" | awk -F: '{ print $2 }' | sed 's/@.*//')"
            if [ -z "$org" ]; then unknown="$unknown $dep (${kind}_DEPENDS: no origin);"; continue; fi
            nd=$((nd + 1))
            if [ -f "$top/$org/Makefile" ] || [ -f "$off/$org/Makefile" ]; then continue; fi
            case " $unknown " in *" $org ("*) ;; *) unknown="$unknown $org (${kind}_DEPENDS);" ;; esac
        done
    done
    [ -n "$unknown" ] && why="$why origins neither of this tree nor of the official one:$unknown"
    # stderr of a make that worked: warnings of the framework, shown with the port
    warn="$(grep -v '^[[:space:]]*$' "$tmp/err" | head -n 2 | tr '\n' ' ' | sed 's/ *$//')"
    if [ -n "$why" ]; then
        say "FAIL $o: $(printf '%s' "${why# }" | sed 's/;$//')"
        nfail=$((nfail + 1))
    elif [ -n "$ign" ]; then
        say "IGNORE $o: $pn: $ign"
        nign=$((nign + 1))
    else
        say "OK   $o: $pn, $nd dependencies${warn:+ (make said: $warn)}"
        nok=$((nok + 1))
    fi
    [ -n "$pn" ] && printf '%s %s\n' "$pn" "$o" >> "$tmp/names"
done
# the same PKGNAME for two ports
for pn in $(awk '{ print $1 }' "$tmp/names" | sort | uniq -d); do
    say "FAIL $pn: the PKGNAME of $(awk -v n="$pn" '$1 == n { print $2 }' "$tmp/names" | tr '\n' ' ' | sed 's/ *$//')"
    nfail=$((nfail + 1))
done
n="$(wc -l < "$tmp/names" | tr -d ' ')"
[ "$n" -gt 0 ] || [ "$nfail" -gt 0 ] || { say "FAIL no port in $top (<category>/<port>/Makefile)"; nfail=1; }
say "result: $nok ok, $nfail failed, $nign ignored ($MAKE, $os; the official tree $off)"
[ "$nfail" = 0 ] || exit 1
exit 0
