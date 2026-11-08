#!/bin/sh
# build.sh - build the packages of the ports of this overlay (azsupport/ports) with
# the FreeBSD ports framework, each after the ports of this tree it needs (a queue,
# as poudriere builds), into the repository of pkg "az", signed.
#
# Usage (as root on FreeBSD; the tree is the one this script is in):
#   sh tools/build.sh [--force] [--repo <dir>] [<origin> ...]
#
#   <origin>      the ports to build (category/port of this tree) and the ports of
#                 this tree they need; none: every <category>/<port> with a Makefile
#   --force       build every port of the queue, also those whose package with the
#                 same az_hash is in the repository already
#   --repo <dir>  the repository: the files of the release az-fbsd<major>-amd64-<level>
#                 downloaded into <dir> (default: work/repo; empty or missing on the
#                 first run); the new packages take the place of those of the same
#                 origin there, and the catalog of pkg repo is written there, signed
#
# Environment:
#   AZ_CPUTYPE       the x86-64 level, CPUTYPE of make.conf (default x86-64-v3)
#   AZ_STAMP         the revision of the packages of the run (default: the hour of its
#                    start, yymmddhh UTC)
#   AZ_WORK          the work directory (default: work/ of the tree): the official
#                    ports tree (freebsd-ports/), WRKDIRPREFIX (wrk/), make.conf, the queue
#   AZ_PORTSDIR      an official ports tree to take as it is instead of the checkout of
#                    the pinned commit (a build server: its own tree; a warning when it is
#                    at another commit)
#   AZ_PKG_KEY_FILE  the signing key of the repository (see tools/pkg-repo-sign.sh)
#
# How (the logic of poudriere, with make and pkg of the host):
# - the official tree of freebsd-ports at the pinned commit below (git, depth 1, reused
#   when it is at that commit), this tree as OVERLAYS over it;
# - the make.conf of the run from tools/make.conf.in (CPUTYPE of the level, CFLAGS,
#   JPEG_PORT, OPTIONS_UNSET of aZ, the paths), as __MAKE_CONF: /etc/make.conf is not read;
# - the queue: the ports and those of this tree they need (FETCH_, EXTRACT_, PATCH_,
#   BUILD_, LIB_, RUN_ and PKG_DEPENDS of make -V, the origins that are ours), each
#   after those it needs;
# - the az_hash of each port: SHA-256 of its files (paths and contents; with those of
#   its MASTERDIR and the other files of this tree its Makefile reads, Mk/bsd.overlay.mk
#   and the other makefiles of Mk/ of this tree it reads: Mk/Uses/php.mk for the PHP
#   ports, not for az/az), of the official commit, the level and tools/make.conf.in,
#   and of the az_hash of each port of this tree it needs (so a change of az/az builds
#   again what needs it); it goes to make as AZ_HASH (the annotation az_hash of the package,
#   Mk/bsd.overlay.mk), the revision as AZ_STAMP (PORTREVISION= ${AZ_STAMP}: each
#   build is an upgrade for pkg);
# - a port whose origin has a package with the same az_hash in the repository is not
#   built again (an incremental build) unless --force; a port that fails stops those
#   that need it (skipped, with the reason);
# - each port: the official packages of its dependencies by pkg install (the FreeBSD
#   repository of the host), ours by pkg add of the packages built before (or of the
#   repository), then make clean package with USE_PACKAGE_DEPENDS_ONLY=yes (nothing is
#   built from source but the port itself); its log, its time, OK or FAIL;
# - a NEED_ROOT port (az/az builds into the real prefix and refuses files of a package
#   there): its installed package deleted before its build, the new one added after
#   it (the old one back when it fails);
# - the repository: one package per origin, the new ones in the place of the old ones
#   of the same name or origin, away with the packages of origins this tree has no
#   more, pkg repo, signed and checked (tools/pkg-repo-sign.sh).
#
# Results: results/ of the tree: summary.txt (a line per port, "result: OK" or
# "result: FAIL (...)" at the end), queue.txt, hashes.txt, logs/<category>_<port>.log,
# pkg-repo.log.
# Exit status: 0 every port of the queue built or kept and the repository signed (or
# unsigned without a key), 1 otherwise, 2 a wrong call.

set -u

# the official tree the overlay is built over: freebsd-ports main of 04.11.2026, the
# commit of freebsd/deps.conf of azsupport/php-src
ports_commit="f16b6dd0f7c1c3a2e0447e192e39e72f21d85eb0"
ports_url="https://github.com/freebsd/freebsd-ports"

top="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n 's/^# \{0,1\}//; 6,16p' "$0" >&2; exit "${1:-2}"; }
say() { printf '[build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { say "$*" >&2; exit 2; }

force=0
repo=""
while [ $# -gt 0 ]; do
    case "$1" in
        --force) force=1; shift ;;
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --repo=*) repo="${1#--repo=}"; shift ;;
        -h|--help) usage 0 ;;
        -*) say "unknown option $1" >&2; usage ;;
        *) break ;;
    esac
done

[ "$(uname -s)" = FreeBSD ] || die "FreeBSD only (the ports framework and pkg)"
[ "$(id -u)" = 0 ] || die "as root (pkg install and pkg add of the dependencies)"
[ -f "$top/tools/make.conf.in" ] || die "no $top/tools/make.conf.in"

cputype="${AZ_CPUTYPE:-x86-64-v3}"
case "$cputype" in
    x86-64-v[234]) ;;
    *) die "AZ_CPUTYPE=$cputype: not x86-64-v2, x86-64-v3 or x86-64-v4" ;;
esac
az_stamp="${AZ_STAMP:-$(date -u +%y%m%d%H)}"
case "$az_stamp" in
    ''|*[!0-9]*) die "AZ_STAMP=$az_stamp: not a number (yymmddhh)" ;;
esac
work="${AZ_WORK:-$top/work}"
res="$top/results"
packages="$top/packages"
distdir="$top/distfiles"
repo="${repo:-$work/repo}"
q="$work/queue"
export ASSUME_ALWAYS_YES=yes

mkdir -p "$work" "$q" "$packages/All" "$distdir" "$repo" "$work/db" || die "cannot make the work directories"
work="$(cd "$work" && pwd)"
repo="$(cd "$repo" && pwd)"
# the real path of the tree: the files of the hashes are named relative to it
topr="$(cd "$top" && pwd -P)"
rm -rf "${q:?}"/* "${res:?}"
mkdir -p "$res/logs" "$q/info" "$q/deps" "$q/rdeps" "$q/odeps" "$q/orun" "$q/pkgbase" "$q/state" "$q/file" "$q/hash" ||
    die "cannot make $res and $q"
# make package writes packages/All/<pkgname>.pkg (the directory must exist, else
# the package goes into the directory of the port); those of an earlier run go
rm -f "$packages"/All/*.pkg
sum="$res/summary.txt"

# the tools: git for the official tree (pkg itself bootstraps with ASSUME_ALWAYS_YES)
if ! command -v git > /dev/null 2>&1; then
    say "no git: pkg install git-lite"
    pkg install -y git-lite > "$res/logs/tools.log" 2>&1 || die "cannot install git-lite (results/logs/tools.log)"
fi

# --- the official ports tree ---------------------------------------------------------
if [ -n "${AZ_PORTSDIR:-}" ]; then
    ports="$(cd "$AZ_PORTSDIR" 2>/dev/null && pwd)"
    [ -n "$ports" ] && [ -f "$ports/Mk/bsd.port.mk" ] || die "AZ_PORTSDIR=$AZ_PORTSDIR: no Mk/bsd.port.mk there"
    c="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    [ "$c" = "$ports_commit" ] ||
        say "warning: the ports tree $ports (AZ_PORTSDIR) is at ${c:-an unknown commit}, not at $ports_commit: taken as it is"
else
    ports="$work/freebsd-ports"
    if [ "$(git -C "$ports" rev-parse HEAD 2>/dev/null)" = "$ports_commit" ]; then
        say "the official ports tree at $ports_commit: $ports (reused)"
    else
        say "the official ports tree at $ports_commit into $ports (git, depth 1)"
        ok=0
        for i in 1 2 3; do
            rm -rf "$ports" && mkdir -p "$ports" &&
                git -C "$ports" init -q &&
                git -C "$ports" remote add origin "$ports_url" &&
                git -C "$ports" fetch -q --depth 1 origin "$ports_commit" >> "$res/logs/ports-tree.log" 2>&1 &&
                git -C "$ports" checkout -q FETCH_HEAD >> "$res/logs/ports-tree.log" 2>&1 && { ok=1; break; }
            say "the checkout of freebsd-ports failed (try $i of 3): $(tail -n 1 "$res/logs/ports-tree.log" 2>/dev/null)"
            sleep $((i * 20))
        done
        [ "$ok" = 1 ] || die "no official ports tree at $ports_commit (results/logs/ports-tree.log)"
    fi
fi
ports_head="$(git -C "$ports" rev-parse HEAD 2>/dev/null || echo unknown)"
# the real paths of the work and of the official tree: their files are not of a port
workr="$(cd "$work" && pwd -P)"
portsr="$(cd "$ports" && pwd -P)"

# --- the make.conf of the run --------------------------------------------------------
sed -e "s|@CPUTYPE@|$cputype|" -e "s|@PORTSDIR@|$ports|" -e "s|@OVERLAYS@|$top|" \
    -e "s|@WRKDIRPREFIX@|$work/wrk|" -e "s|@PACKAGES@|$packages|" -e "s|@DISTDIR@|$distdir|" \
    -e "s|@PORT_DBDIR@|$work/db|" "$top/tools/make.conf.in" > "$work/make.conf" ||
    die "cannot write $work/make.conf"
__MAKE_CONF="$work/make.conf"
export __MAKE_CONF
cp "$work/make.conf" "$res/make.conf"

# --- helpers ---------------------------------------------------------------------------
# key <origin>: the origin as a file name (lang/php74 -> lang_php74)
key() { printf '%s' "$1" | tr '/@' '__'; }
# ours <origin>: a port of this tree (not a directory of the tools or the work)
ours() {
    case "${1%%/*}" in Mk|Templates|Keywords|Tools|tools|work|packages|distfiles|results|repo|keys|docs) return 1 ;; esac
    [ -f "$top/${1%%@*}/Makefile" ]
}
all_ports() {
    for m in "$top"/*/*/Makefile; do
        [ -f "$m" ] || continue
        o="${m%/Makefile}"; o="${o#"$top"/}"
        ours "$o" && echo "$o"
    done
}
# catalog <file name>: a file of the catalog of pkg repo, not a package
catalog() {
    case "$1" in meta|meta.*|packagesite.*|data.*|digests.*|filesite.*) return 0 ;; esac
    return 1
}
st() { cat "$q/state/$(key "$1")" 2>/dev/null; }
# npkg <dir>: the number of packages in a directory (not the files of the catalog)
npkg() { ls "$1" | grep '\.pkg$' | while read -r _f; do catalog "$_f" || echo "$_f"; done | wc -l | tr -d ' '; }
# SHA-256 of a file, of the standard input (sha256 of the base system; sha256sum elsewhere)
if command -v sha256 > /dev/null 2>&1; then
    hfile() { sha256 -q "$1"; }
    hin() { sha256; }
else
    hfile() { sha256sum "$1" | cut -d ' ' -f 1; }
    hin() { sha256sum | cut -d ' ' -f 1; }
fi
# the az_hash of a package file (its annotation), or nothing
pkg_hash() { pkg query -F "$1" '%At %Av' 2>/dev/null | awk '$1 == "az_hash" { print $2; exit }'; }
# the origins of a list of dependencies (target:origin[:what] each, as make -V prints)
dep_origins() {
    tr -s ' \t' '\n\n' | sed -n 's/^[^:]*:\([^:]*\).*$/\1/p' | sed -e "s|^$ports/||" -e "s|^$top/||" | LC_ALL=C sort -u
}

# port_info <origin>: what make -V says of a port of this tree into $q/info/<key>
# (lines: 1 PKGNAME, 2 IGNORE, 3-9 FETCH_ EXTRACT_ PATCH_ BUILD_ LIB_ RUN_ PKG_DEPENDS,
# 10 NEED_ROOT, 11 MASTERDIR, 12 FILESDIR, 13 PATCHDIR, 14 PKGDIR, 15 DISTINFO_FILE,
# 16 .MAKE.MAKEFILES); our dependencies into $q/deps/<key> (all kinds) and
# $q/rdeps/<key> (LIB_ and RUN_DEPENDS: what pkg add of its package needs), the
# official ones into $q/odeps/<key> and $q/orun/<key>
port_info() {
    _k="$(key "$1")"
    [ -f "$q/info/$_k" ] && return 0
    : > "$q/deps/$_k"; : > "$q/rdeps/$_k"; : > "$q/odeps/$_k"; : > "$q/orun/$_k"
    if ! make -C "$top/$1" AZ_STAMP="$az_stamp" -V PKGNAME -V IGNORE -V FETCH_DEPENDS -V EXTRACT_DEPENDS \
            -V PATCH_DEPENDS -V BUILD_DEPENDS -V LIB_DEPENDS -V RUN_DEPENDS -V PKG_DEPENDS -V NEED_ROOT \
            -V MASTERDIR -V FILESDIR -V PATCHDIR -V PKGDIR -V DISTINFO_FILE -V .MAKE.MAKEFILES \
            > "$q/info/$_k" 2> "$q/info/$_k.err" || [ -z "$(sed -n 1p "$q/info/$_k")" ]; then
        echo "make -V failed: $(grep . "$q/info/$_k.err" | head -n 1)" > "$q/info/$_k.bad"
        return 1
    fi
    sed -n '3,9p' "$q/info/$_k" | dep_origins > "$q/info/$_k.all"
    sed -n '7,8p' "$q/info/$_k" | dep_origins > "$q/info/$_k.run"
    for _d in $(cat "$q/info/$_k.all"); do
        [ "${_d%%@*}" = "$1" ] && continue
        if ours "$_d"; then echo "${_d%%@*}" >> "$q/deps/$_k"; else echo "$_d" >> "$q/odeps/$_k"; fi
    done
    for _d in $(cat "$q/info/$_k.run"); do
        [ "${_d%%@*}" = "$1" ] && continue
        if ours "$_d"; then echo "${_d%%@*}" >> "$q/rdeps/$_k"; else echo "$_d" >> "$q/orun/$_k"; fi
    done
    return 0
}

# port_files <origin>: the files of this tree a port is built from, "f <path relative
# to the tree> <sha256>" a line each: those of its directory, of its MASTERDIR,
# FILESDIR, PATCHDIR, PKGDIR and DISTINFO_FILE, and the makefiles of this tree it reads
# (.MAKE.MAKEFILES: Mk/bsd.overlay.mk, which every port reads, taken also when make
# does not say; Mk/Uses/php.mk only by the ports that read it)
port_files() {
    _k="$(key "$1")"
    {
        find "$topr/$1" -type f ! -path '*/work/*'
        [ -f "$topr/Mk/bsd.overlay.mk" ] && echo "$topr/Mk/bsd.overlay.mk"
        for _p in $(sed -n '11,16p' "$q/info/$_k"); do
            if [ -d "$_p" ]; then find "$_p" -type f ! -path '*/work/*'; elif [ -f "$_p" ]; then echo "$_p"; fi
        done
    } 2> /dev/null | while read -r _f; do realpath "$_f" 2> /dev/null; done | LC_ALL=C sort -u |
        while read -r _f; do
            # not the work, the official tree, the packages and the results under the
            # tree (the make.conf of the run names the paths of the machine)
            case "$_f" in
                "$workr"/*|"$portsr"/*|"$topr"/work/*|"$topr"/packages/*|"$topr"/distfiles/*|"$topr"/results/*|"$topr"/repo/*|"$topr"/.git/*) continue ;;
                "$topr"/*) ;;
                *) continue ;;
            esac
            printf 'f %s %s\n' "${_f#"$topr"/}" "$(hfile "$_f")"
        done
}

# pkgbase <origin[@flavor]>: the name of the package of an official port (PKGBASE of
# make -V in the official tree, with its flavour), cached
pkgbase() {
    _f="$q/pkgbase/$(key "$1")"
    if [ ! -s "$_f" ]; then
        _o="${1%%@*}"; _fl=""
        case "$1" in *@*) _fl="${1#*@}" ;; esac
        [ -f "$ports/$_o/Makefile" ] || { why="no port $_o in the official tree"; return 1; }
        make -C "$ports/$_o" ${_fl:+FLAVOR=$_fl} -V PKGBASE > "$_f" 2> "$_f.err" && [ -s "$_f" ] ||
            { why="make -V PKGBASE of $1 failed: $(grep . "$_f.err" | head -n 1)"; rm -f "$_f"; return 1; }
    fi
    cat "$_f"
}

# our installed packages: origin name version file, one per line (put back when pkg
# install of an official package replaced one by the official package of the same name)
: > "$q/installed"
ours_back() {
    while read -r _io _n _v _f; do
        [ "$(pkg query %v "$_n" 2>/dev/null)" = "$_v" ] && continue
        say "pkg install put another $_n in the place of ours ($_v): pkg add -f ${_f##*/}"
        pkg add -f "$_f" >> "$log" 2>&1 || { why="pkg add -f ${_f##*/} failed"; return 1; }
    done < "$q/installed"
    return 0
}
# gone: our packages that pkg delete removed are no longer installed for the ports after
gone() {
    : > "$q/installed.new"
    while read -r _io _n _v _f; do
        if pkg info -e "$_n"; then echo "$_io $_n $_v $_f" >> "$q/installed.new"; else rm -f "$q/inst-$(key "$_io")"; fi
    done < "$q/installed"
    mv "$q/installed.new" "$q/installed"
}

# official <file of origins>: their official packages installed (pkg install), what is
# not installed afterwards said in $why
official() {
    _want=""
    for _o in $(cat "$1"); do
        _p="$(pkgbase "$_o")" || return 1
        pkg info -e "$_p" || _want="$_want $_p"
    done
    [ -z "$_want" ] && return 0
    say "  pkg install$_want"
    # shellcheck disable=SC2086
    pkg install -y $_want >> "$log" 2>&1
    _miss=""
    for _p in $_want; do pkg info -e "$_p" || _miss="$_miss $_p"; done
    [ -z "$_miss" ] || { why="pkg install did not install$_miss"; return 1; }
    ours_back
}

# inst_port <origin>: the package of a port of this tree installed with what it needs to
# run: our packages it needs first (in the order of the queue), the official ones by
# pkg install, then pkg add of its own file (-f when a package of that name is there)
inst_port() {
    printf '%s\n' "$1" > "$q/cl.all"
    cp "$q/cl.all" "$q/cl.new"
    while [ -s "$q/cl.new" ]; do
        for _c in $(cat "$q/cl.new"); do cat "$q/rdeps/$(key "$_c")"; done | LC_ALL=C sort -u |
            grep -vxF -f "$q/cl.all" > "$q/cl.next"
        cat "$q/cl.next" >> "$q/cl.all"
        mv "$q/cl.next" "$q/cl.new"
    done
    for _c in $(grep -xF -f "$q/cl.all" "$q/queue.txt"); do
        _ck="$(key "$_c")"
        [ -f "$q/inst-$_ck" ] && continue
        _f="$(cat "$q/file/$_ck" 2>/dev/null)"
        [ -n "$_f" ] && [ -f "$_f" ] || { why="no package of $_c ($(st "$_c"))"; return 1; }
        official "$q/orun/$_ck" || return 1
        _n="$(pkg query -F "$_f" %n)"; _v="$(pkg query -F "$_f" %v)"
        _af=""
        pkg info -e "$_n" && _af=-f
        say "  pkg add ${_af:+$_af }${_f##*/}"
        # shellcheck disable=SC2086
        if ! pkg add $_af "$_f" >> "$log" 2>&1 || [ "$(pkg query %v "$_n" 2>/dev/null)" != "$_v" ]; then
            why="pkg add ${_f##*/} failed: $(tail -n 1 "$log")"
            return 1
        fi
        echo "$_c $_n $_v $_f" >> "$q/installed"
        : > "$q/inst-$_ck"
    done
    return 0
}

# --- the queue -----------------------------------------------------------------------
for o in "$@"; do
    ours "${o%/}" || die "not a port of this tree: $o (no $top/${o%/}/Makefile)"
done
if [ $# -gt 0 ]; then
    for o in "$@"; do echo "${o%/}"; done
else
    all_ports
fi | LC_ALL=C sort -u > "$q/want.txt"
[ -s "$q/want.txt" ] || die "no ports to build (no <category>/<port>/Makefile in $top)"
# the closure: the ports asked for and the ports of this tree they need
cp "$q/want.txt" "$q/set.txt"
cp "$q/want.txt" "$q/new.txt"
while [ -s "$q/new.txt" ]; do
    : > "$q/found.txt"
    for o in $(cat "$q/new.txt"); do
        port_info "$o" || say "$o: $(cat "$q/info/$(key "$o").bad")"
        cat "$q/deps/$(key "$o")" >> "$q/found.txt"
    done
    LC_ALL=C sort -u "$q/found.txt" | grep -vxF -f "$q/set.txt" > "$q/next.txt"
    for o in $(cat "$q/next.txt"); do say "$o: in the queue (a port asked for needs it)"; done
    cat "$q/next.txt" >> "$q/set.txt"
    mv "$q/next.txt" "$q/new.txt"
done
# the order: each port after the ports of this tree it needs (a loop: the rest in the
# order of their names, said)
: > "$q/queue.txt"
LC_ALL=C sort -u "$q/set.txt" > "$q/left.txt"
while [ -s "$q/left.txt" ]; do
    placed=0
    for o in $(cat "$q/left.txt"); do
        ready=1
        for d in $(cat "$q/deps/$(key "$o")"); do
            grep -qxF "$d" "$q/queue.txt" || { ready=0; break; }
        done
        if [ "$ready" = 1 ]; then echo "$o" >> "$q/queue.txt"; placed=1; fi
    done
    grep -vxF -f "$q/queue.txt" "$q/left.txt" > "$q/left.new"
    mv "$q/left.new" "$q/left.txt"
    if [ "$placed" = 0 ] && [ -s "$q/left.txt" ]; then
        say "a loop in the dependencies of: $(tr '\n' ' ' < "$q/left.txt")- they go last, in the order of their names"
        cat "$q/left.txt" >> "$q/queue.txt"
        break
    fi
done
cp "$q/queue.txt" "$res/queue.txt"
say "the queue: $(wc -l < "$q/queue.txt" | tr -d ' ') ports (results/queue.txt)"

# --- the az_hash of each port, in the order of the queue -------------------------------
base_hash="$({ echo "freebsd-ports $ports_head"; echo "cputype $cputype"; cat "$top/tools/make.conf.in"; } | hin)"
: > "$res/hashes.txt"
for o in $(cat "$q/queue.txt"); do
    k="$(key "$o")"
    [ -f "$q/info/$k.bad" ] && continue
    {
        echo "base $base_hash"
        port_files "$o"
        for d in $(LC_ALL=C sort -u "$q/deps/$k"); do echo "dep $d $(cat "$q/hash/$(key "$d")" 2>/dev/null || echo none)"; done
    } > "$q/hash/$k.in"
    hin < "$q/hash/$k.in" > "$q/hash/$k"
    echo "$o $(cat "$q/hash/$k")" >> "$res/hashes.txt"
done

# the packages of the repository before: name origin az_hash file
: > "$q/repo-had"
for f in "$repo"/*.pkg; do
    [ -f "$f" ] || continue
    catalog "${f##*/}" && continue
    nm="$(pkg query -F "$f" '%n %o' 2>/dev/null)"
    if [ -z "$nm" ]; then say "the repository: ${f##*/} is not a package: removed"; rm -f "$f"; continue; fi
    h="$(pkg_hash "$f")"
    echo "$nm ${h:--} ${f##*/}" >> "$q/repo-had"
done

overlay_rev="$(git -C "$top" log -1 --format='%h %s' 2>/dev/null)"
{
    echo "ports:    freebsd-ports $ports_head${AZ_PORTSDIR:+ (AZ_PORTSDIR $ports)}"
    echo "overlay:  ${overlay_rev:-?}"
    echo "host:     $(uname -sr), $(cc --version 2>/dev/null | head -n 1)"
    echo "cputype:  $cputype; CFLAGS: $(sed -n 's/^CFLAGS=//p' "$work/make.conf")"
    echo "stamp:    $az_stamp (AZ_STAMP: the revision of the packages built in this run)"
    echo "pkg:      $(pkg -v 2>/dev/null); the official packages from: $(pkg -vv 2>/dev/null | awk '
        /^Repositories:/ { r = 1; next }
        r && /^[^ ]/ { r = 0 }
        r && /^  [^ ].*: *\{/ { n = $1; sub(/:$/, "", n); u = "" }
        r && /^ *url *:/ { u = $0; sub(/^ *url *: *"?/, "", u); sub(/"?,? *$/, "", u) }
        r && /^ *enabled *: *(yes|true)/ && n != "" { printf "%s%s %s", s, n, u; s = ", " }')"
    echo "repo:     $repo ($(npkg "$repo") packages before the run)"
    echo "queue:    $(wc -l < "$q/queue.txt" | tr -d ' ') ports$( [ "$force" = 1 ] && echo ', --force')"
} > "$sum"

# --- the builds ------------------------------------------------------------------------
# a line of the summary and the state of a port: ok (built), repo (in the repository
# already), fail, skip (needs a port that failed)
record() {
    _o="$1"; _s="$2"; shift 2
    echo "$_s" > "$q/state/$(key "$_o")"
    case "$_s" in
        ok) _w=OK ;;
        fail) _w=FAIL ;;
        *) _w=SKIP ;;
    esac
    printf '%-34s %-4s %s\n' "$_o" "$_w" "$*" >> "$sum"
    say "$_o: $_w $*"
}

for o in $(cat "$q/queue.txt"); do
    k="$(key "$o")"
    log="$res/logs/$k.log"
    : > "$log"
    if [ -f "$q/info/$k.bad" ]; then record "$o" fail "$(cat "$q/info/$k.bad")"; continue; fi
    pn="$(sed -n 1p "$q/info/$k")"
    ign="$(sed -n 2p "$q/info/$k")"
    h="$(cat "$q/hash/$k")"
    hs="$(printf '%s' "$h" | cut -c1-12)"
    # the ports of this tree it needs: failed, or skipped for that
    bad=""
    for d in $(cat "$q/deps/$k"); do
        case "$(st "$d")" in fail|skip) bad="$bad $d" ;; esac
    done
    if [ -n "$bad" ]; then record "$o" skip "$pn: needs$bad, which failed or was skipped"; continue; fi
    if [ -n "$ign" ]; then record "$o" fail "$pn: the port says IGNORE: $ign"; continue; fi
    # its package in the repository: the same az_hash, another one, none
    had="$(awk -v o="$o" '$2 == o { print $3, $4; exit }' "$q/repo-had")"
    if [ -n "$had" ] && [ "${had%% *}" = "$h" ] && [ "$force" = 0 ]; then
        echo "$repo/${had#* }" > "$q/file/$k"
        record "$o" repo "${had#* }: in the repository already with the same az_hash $hs"
        continue
    fi
    if [ "$force" = 1 ]; then why="--force"
    elif [ -z "$had" ]; then why="no package of $o in the repository"
    elif [ "${had%% *}" = - ]; then why="${had#* } in the repository has no az_hash"
    else why="az_hash $hs, not $(printf '%s' "${had%% *}" | cut -c1-12) of ${had#* } in the repository"
    fi
    say "$o: $pn ($why)"
    why=""
    if ! official "$q/odeps/$k"; then record "$o" fail "$pn: the official dependencies: $why"; continue; fi
    okd=1
    for d in $(cat "$q/deps/$k"); do
        inst_port "$d" || { okd=0; break; }
    done
    if [ "$okd" = 0 ]; then record "$o" fail "$pn: our dependencies: $why"; continue; fi
    # NEED_ROOT (az/az: it installs into the real prefix while it builds, and refuses
    # files there of a package): its installed package deleted first (pkg delete -f,
    # those that need it stay), the new one added after the build, the old one back
    # when the build fails
    old=""
    nr="$(sed -n 10p "$q/info/$k")"
    case "$nr" in ''|no|NO) nr="" ;; esac
    if [ -n "$nr" ] && pkg info -e "${pn%-*}"; then
        old="$(awk -v n="${pn%-*}" '$2 == n { print $4 }' "$q/installed" | tail -n 1)"
        [ -z "$old" ] && [ -n "$had" ] && old="$repo/${had#* }"
        say "  pkg delete -f ${pn%-*} (NEED_ROOT: it builds into the real prefix)"
        pkg delete -y -f "${pn%-*}" >> "$log" 2>&1 || say "  pkg delete -f ${pn%-*} failed (logs/$k.log)"
        gone
    fi
    mark="$q/mark-$k"
    : > "$mark"
    rm -f "$packages/All/$pn.pkg"
    start="$(date +%s)"
    make -C "$top/$o" clean package USE_PACKAGE_DEPENDS_ONLY=yes AZ_STAMP="$az_stamp" AZ_HASH="$h" >> "$log" 2>&1
    rc=$?
    secs=$(( $(date +%s) - start ))
    # the config.log files of a failed build next to its log, then the work directory away
    if [ "$rc" != 0 ]; then
        wd="$(make -C "$top/$o" -V WRKDIR 2>/dev/null)"
        n=0
        for c in $(find "$wd" -maxdepth 3 -name config.log 2>/dev/null); do
            n=$((n + 1)); cp "$c" "$res/logs/$k.config-$n.log"
        done
    fi
    make -C "$top/$o" clean > /dev/null 2>&1
    if [ "$rc" != 0 ] || [ ! -f "$packages/All/$pn.pkg" ]; then
        e="$(grep -E ' error:|Error code|^\*\*\*|^===>.*(IGNORE|not found|failed)' "$log" | tail -n 1 | cut -c1-200)"
        [ "$rc" = 0 ] && e="make package made no $pn.pkg"
        record "$o" fail "$pn: ${secs}s, ${e:-make package failed} (logs/$k.log)"
        if [ -n "$old" ] && [ -f "$old" ]; then
            say "  pkg add ${old##*/}: the package of before back"
            pkg add -f "$old" >> "$log" 2>&1 || say "  pkg add ${old##*/} failed"
        fi
        continue
    fi
    f="$packages/All/$pn.pkg"
    echo "$f" > "$q/file/$k"
    rm -f "$q/inst-$k"
    # every package the build made (a port with subpackages makes more than one)
    find "$packages/All" -name '*.pkg' -newer "$mark" > "$q/made-$k"
    grep -qxF "$f" "$q/made-$k" || echo "$f" >> "$q/made-$k"
    note=""
    [ "$(pkg_hash "$f")" = "$h" ] ||
        note="; warning: no annotation az_hash $hs in the package (PKG_NOTES of Mk/bsd.overlay.mk): the next run builds it again"
    case "$pn" in
        *_"$az_stamp"|*_"$az_stamp",*) ;;
        *) note="$note; warning: the version has not the revision $az_stamp (PORTREVISION= \${AZ_STAMP}): no upgrade for pkg" ;;
    esac
    record "$o" ok "$pn: ${secs}s, $(( $(wc -c < "$f") / 1024 )) KB, az_hash $hs$note"
    if [ -n "$nr" ]; then
        why=""
        inst_port "$o" || say "  the new package of $o did not install: $why"
    fi
done

# --- the repository --------------------------------------------------------------------
cat "$q"/made-* 2> /dev/null > "$q/made"
: > "$q/made-names"
for f in $(cat "$q/made"); do pkg query -F "$f" '%n %o' >> "$q/made-names"; done
while read -r n og hh f; do
    if awk -v n="$n" -v o="$og" '$1 == n || $2 == o { f = 1 } END { exit !f }' "$q/made-names"; then
        say "the repository: $f gives way to the package built now"
        rm -f "$repo/$f"
    elif ! ours "$og"; then
        say "the repository: $f away (this tree has no port $og any more)"
        rm -f "$repo/$f"
    fi
done < "$q/repo-had"
for f in $(cat "$q/made"); do cp -p "$f" "$repo/" || say "cannot copy ${f##*/} into $repo"; done
nrepo="$(npkg "$repo")"
if sh "$top/tools/pkg-repo-sign.sh" "$repo" "$res/pkg-repo.log"; then
    repo_ok=1
else
    repo_ok=0
fi
echo "repository: $nrepo packages; $(tail -n 1 "$res/pkg-repo.log" 2>/dev/null)" >> "$sum"

# --- the result ------------------------------------------------------------------------
nok=0; nkept=0; failed=""; skipped=""
for o in $(cat "$q/queue.txt"); do
    case "$(st "$o")" in
        ok) nok=$((nok + 1)) ;;
        repo) nkept=$((nkept + 1)) ;;
        fail) failed="$failed $o" ;;
        *) skipped="$skipped $o" ;;
    esac
done
echo "built:    $nok, kept from the repository: $nkept${failed:+, failed:$failed}${skipped:+, not built:$skipped}" >> "$sum"
if [ -z "$failed" ] && [ -z "$skipped" ] && [ "$repo_ok" = 1 ]; then
    echo "result:   OK" >> "$sum"
    say "OK: $nok built, $nkept kept from the repository ($repo)"
    exit 0
fi
r=""
[ -n "$failed" ] && r="failed:$failed"
[ -n "$skipped" ] && r="${r:+$r; }not built:$skipped"
[ "$repo_ok" = 1 ] || r="${r:+$r; }pkg repo failed"
echo "result:   FAIL ($r)" >> "$sum"
say "FAIL ($r)"
exit 1
