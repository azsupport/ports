#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
#
# dep-cycles.sh - the cycles among the ports of this tree, as tools/build.sh takes their
# dependencies: a port needs the packages of the ports of this tree that its FETCH_,
# EXTRACT_, PATCH_, BUILD_, LIB_, RUN_ and PKG_DEPENDS name (make -V), but not a build tool of
# AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh it needs only to build (not among its LIB_ and
# RUN_DEPENDS, the port no extension of Python: tool_official of tools/build.sh), which comes
# official; the ports of this tree a dependency runs with are among the dependencies of that
# one, so these edges are all there is to its chroot. A cycle never builds: each of its ports
# waits for the package of the next ("our dependencies: no package of ...": devel/llvm23,
# lang/perl5.42 and lang/gcc16 in the run of 72f1c83 of the branch llvm23, 27.11.2026).
#
# Usage: sh tools/dep-cycles.sh <official tree> [<origin>...]
#   <official tree>: freebsd-ports at the pinned commit, as for tools/check-tree.sh; the
#   origins: the ports to start from, with those of this tree they need, and those these
#   need... (default: every port of this tree). MAKE and MAKE_CONF as for tools/check-tree.sh
#   (make on FreeBSD; bmake on Linux, where the ports see a FreeBSD 15.1 amd64 machine).
# Output: a line a port ("<origin>: <dependency> (<kinds>) ...", "official: <tools>" for the
#   tools of AZSUPPORT_TOOLS_OFFICIAL it gets official), "FAIL <origin>: <error of make>",
#   then each cycle ("CYCLE <a> -> <b> (BUILD) -> ... -> <a> (RUN)", one for each set of
#   ports that need each other) or "no cycle among <n> ports".
#   --test: its cases on a graph of its own ("ok" or "FAIL" a line).
# Exit status: 0 no cycle, 1 a cycle, a make that failed or a case of --test, 2 usage or setup.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"

# cycles: the edges "<from> <to> <kinds>" on the input, the cycles (Tarjan's strongly
# connected components; in each of more than one port, the shortest way back from its first
# port, by breadth) on the output; the exit status of awk 1 when there is one
cycles() {
    awk '
    function strong(v,   i, w) {
        idx[v] = ++counter; low[v] = idx[v]; st[++sp] = v; onst[v] = 1
        for (i = 1; i <= nout[v]; i++) {
            w = out[v, i]
            if (!(w in idx)) { strong(w); if (low[w] < low[v]) low[v] = low[w] }
            else if (onst[w] && idx[w] < low[v]) low[v] = idx[w]
        }
        if (low[v] == idx[v]) {
            nc++; size[nc] = 0
            do { w = st[sp--]; onst[w] = 0; comp[w] = nc; size[nc]++; if (!(nc in first) || w < first[nc]) first[nc] = w } while (w != v)
        }
    }
    {
        if (!($1 in seen)) { seen[$1] = 1; nodes[++nn] = $1 }
        if ($2 == "-") next
        if (!($2 in seen)) { seen[$2] = 1; nodes[++nn] = $2 }
        if (($1, $2) in kind) next
        kind[$1, $2] = $3; out[$1, ++nout[$1]] = $2
    }
    END {
        for (i = 1; i <= nn; i++) if (!(nodes[i] in idx)) strong(nodes[i])
        found = 0
        for (c = 1; c <= nc; c++) {
            if (size[c] < 2) continue
            found++
            s = first[c]; split("", par); split("", q); h = 1; t = 0; q[++t] = s; par[s] = ""; back = ""
            while (h <= t && back == "") {
                u = q[h++]
                for (i = 1; i <= nout[u]; i++) {
                    w = out[u, i]
                    if (comp[w] != c) continue
                    if (w == s) { back = u; break }
                    if (!(w in par)) { par[w] = u; q[++t] = w }
                }
            }
            line = s " (" kind[back, s] ")"; v = back
            while (v != s) { line = v " (" kind[par[v], v] ") -> " line; v = par[v] }
            cl[found] = sprintf("CYCLE %s -> %s (%d ports need each other)", s, line, size[c])
        }
        if (!found) { printf "no cycle among %d ports\n", nn; exit 0 }
        # in the order of their first ports
        for (i = 2; i <= found; i++) { x = cl[i]; for (j = i - 1; j >= 1 && cl[j] > x; j--) cl[j + 1] = cl[j]; cl[j + 1] = x }
        for (i = 1; i <= found; i++) print cl[i]
        exit 1
    }'
}

if [ "${1:-}" = --test ]; then
    rc=0
    t() {
        _w="$1"; shift
        _g="$(printf '%s\n' "$@" | cycles)"
        if [ "$_g" = "$_w" ]; then echo "ok   $_w"; else echo "FAIL want: $_w"; echo "     got:  $_g"; rc=1; fi
    }
    t "no cycle among 3 ports" "a b BUILD" "b c RUN" "a c LIB"
    t "no cycle among 1 ports" "a - -"
    t "CYCLE a -> b (BUILD) -> a (RUN) (2 ports need each other)" "a b BUILD" "b a RUN"
    # the run of 72f1c83 of the branch llvm23 (27.11.2026)
    t "CYCLE devel/binutils -> devel/llvm23 (BUILD) -> lang/perl5.42 (BUILD,RUN) -> lang/gcc16 (BUILD) -> devel/binutils (RUN) (4 ports need each other)" \
        "devel/llvm23 lang/perl5.42 BUILD,RUN" "lang/perl5.42 lang/gcc16 BUILD" "lang/gcc16 devel/llvm23 BUILD" \
        "lang/gcc16 devel/binutils RUN" "devel/binutils devel/llvm23 BUILD" "x/y devel/llvm23 BUILD"
    t "no cycle among 5 ports" "devel/llvm23 - -" "lang/perl5.42 lang/gcc16 BUILD" "lang/gcc16 devel/llvm23 BUILD" \
        "lang/gcc16 devel/binutils RUN" "devel/binutils devel/llvm23 BUILD" "x/y devel/llvm23 BUILD"
    # two sets: each said once, the shortest way back from its first port
    t "$(printf '%s\n' "CYCLE a -> b (BUILD) -> a (BUILD) (3 ports need each other)" "CYCLE x -> y (RUN) -> x (LIB) (2 ports need each other)")" \
        "a b BUILD" "b c BUILD" "c a BUILD" "b a BUILD" "x y RUN" "y x LIB" "c x BUILD"
    exit "$rc"
fi

[ $# -ge 1 ] || { echo "usage: sh tools/dep-cycles.sh <official tree (freebsd-ports at the pinned commit)> [<origin>...] | --test" >&2; exit 2; }
off="$(cd "$1" 2>/dev/null && pwd)" || { echo "dep-cycles: no directory $1" >&2; exit 2; }
shift
[ -f "$off/Mk/bsd.port.mk" ] || { echo "dep-cycles: $off has no Mk/bsd.port.mk: not a ports tree" >&2; exit 2; }
tools_off="$(sed -n 's/^AZSUPPORT_TOOLS_OFFICIAL="\(.*\)"$/\1/p' "$top/tools/build.sh")"
[ -n "$tools_off" ] || { echo "dep-cycles: no AZSUPPORT_TOOLS_OFFICIAL in tools/build.sh" >&2; exit 2; }
os="$(uname -s)"
if [ -z "${MAKE:-}" ]; then
    if [ "$os" = FreeBSD ]; then MAKE='make'; else MAKE='bmake'; fi
fi
command -v "$MAKE" > /dev/null 2>&1 || { echo "dep-cycles: no $MAKE (Linux: apt-get install bmake)" >&2; exit 2; }
mc=/dev/null
if [ -n "${MAKE_CONF:-}" ]; then
    mc="$(cd "$(dirname "$MAKE_CONF")" 2>/dev/null && pwd)/${MAKE_CONF##*/}"
    [ -f "$mc" ] || { echo "dep-cycles: no make.conf $MAKE_CONF" >&2; exit 2; }
fi
tmp="$(mktemp -d "${TMPDIR:-/tmp}/dep-cycles.XXXXXX")" || { echo "dep-cycles: no temporary directory" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
trap 'exit 2' INT TERM
mkdir -p "$tmp/dbdir" "$tmp/wrk"
# the make of tools/check-tree.sh
mk_args() {
    set -- PORTSDIR="$off" OVERLAYS="$top" PORT_DBDIR="$tmp/dbdir" WRKDIRPREFIX="$tmp/wrk" __MAKE_CONF="$mc"
    if [ "$os" != FreeBSD ]; then
        set -- -m "$tmp/mk" -m "$off/Mk" "$@" OPSYS=FreeBSD OSVERSION=1501000 OSREL=15.1 _OSRELEASE=15.1-RELEASE \
            ARCH=amd64 UNAME_s=FreeBSD UNAME_r=15.1-RELEASE UNAME_p=amd64 UNAME_m=amd64 \
            CONFIGURE_MAX_CMD_LEN=262144 _SMP_CPUS=2
    fi
    printf '%s\n' "$@"
}
if [ "$os" != FreeBSD ]; then
    mkdir -p "$tmp/mk"
    # shellcheck disable=SC2016
    printf '%s\n' 'MACHINE=	amd64' 'MACHINE_ARCH=	amd64' 'MACHINE_CPUARCH=	amd64' \
        'AR?=	ar' 'CC?=	cc' 'CXX?=	c++' 'CPP?=	cpp' 'LD?=	ld' 'NM?=	nm' 'OBJCOPY?=	objcopy' 'RANLIB?=	ranlib' \
        'CFLAGS?=	-O2 -pipe' 'CXXFLAGS?=	${CFLAGS:N-std=*}' \
        '.if defined(__MAKE_CONF) && exists(${__MAKE_CONF})' '.include "${__MAKE_CONF}"' '.endif' > "$tmp/mk/sys.mk"
fi
mk_args > "$tmp/args"

# ours <origin>: a port of this tree (as ours of tools/build.sh)
ours() {
    case "${1%%/*}" in Mk|Templates|Keywords|Tools|tools|work|packages|distfiles|results|repo|keys|docs|portcache) return 1 ;; esac
    [ -f "$top/${1%%@*}/Makefile" ]
}
if [ $# -eq 0 ]; then
    for m in "$top"/*/*/Makefile; do o="${m%/Makefile}"; o="${o#"$top"/}"; ours "$o" && echo "$o"; done
else
    for o in "$@"; do ours "$o" || { echo "dep-cycles: $o is no port of this tree" >&2; exit 2; }; echo "${o%%@*}"; done
fi | LC_ALL=C sort -u > "$tmp/todo"
: > "$tmp/done"; : > "$tmp/edges"
rc=0
while [ -s "$tmp/todo" ]; do
    o="$(head -n 1 "$tmp/todo")"
    sed 1d "$tmp/todo" > "$tmp/todo.n"; mv "$tmp/todo.n" "$tmp/todo"
    echo "$o" >> "$tmp/done"
    # shellcheck disable=SC2046
    if ! (IFS='
'; set -f; "$MAKE" -C "$top/$o" $(cat "$tmp/args") -V FETCH_DEPENDS -V EXTRACT_DEPENDS -V PATCH_DEPENDS \
            -V BUILD_DEPENDS -V LIB_DEPENDS -V RUN_DEPENDS -V PKG_DEPENDS -V FLAVOR) > "$tmp/out" 2> "$tmp/err" < /dev/null; then
        echo "FAIL $o: make: $(grep -v '^[[:space:]]*$' "$tmp/err" | tail -n 3 | tr '\n' ' ' | sed 's/ *$//')"
        rc=1; echo "$o - -" >> "$tmp/edges"; continue
    fi
    fl="$(sed -n 8p "$tmp/out")"
    # <kind> <origin> a line, the origins of this tree but the port itself
    n=0
    for kind in FETCH EXTRACT PATCH BUILD LIB RUN PKG; do
        n=$((n + 1))
        sed -n "${n}p" "$tmp/out" | tr -s ' \t' '\n' | sed -n 's/^[^:]*:\([^:]*\).*$/\1/p' | sed -e "s|^$off/||" -e "s|^$top/||" -e 's/@.*//' |
            while read -r d; do [ "$d" != "$o" ] && ours "$d" && echo "$kind $d"; done
    done | LC_ALL=C sort -u > "$tmp/kd"
    awk '$1 == "LIB" || $1 == "RUN" { print $2 }' "$tmp/kd" | LC_ALL=C sort -u > "$tmp/run"
    line="$o:"; offl=""
    awk '{ print $2 }' "$tmp/kd" | LC_ALL=C sort -u > "$tmp/ds"
    while read -r d; do
        k="$(awk -v d="$d" '$2 == d { printf "%s%s", s, $1; s = "," }' "$tmp/kd")"
        # tool_official of tools/build.sh
        case " $tools_off " in
        *" $d "*)
            if ! grep -qxF "$d" "$tmp/run"; then
                case "$fl" in py[0-9]*) ;; *) offl="$offl $d"; continue ;; esac
            fi ;;
        esac
        line="$line $d ($k)"
        echo "$o $d $k" >> "$tmp/edges"
        grep -qxF "$d" "$tmp/done" || grep -qxF "$d" "$tmp/todo" || echo "$d" >> "$tmp/todo"
    done < "$tmp/ds"
    [ "$line" != "$o:" ] || { echo "$o - -" >> "$tmp/edges"; line="$o: none"; }
    echo "$line${offl:+; official:$offl}"
done
cycles < "$tmp/edges" || rc=1
exit "$rc"
