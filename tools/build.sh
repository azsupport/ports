#!/bin/sh
# build.sh - build the packages of the ports of this overlay (azsupport/ports) with
# the FreeBSD ports framework, each after the ports of this tree it needs (a queue,
# as poudriere builds), into the repository of pkg "az", signed.
#
# Usage (as root on FreeBSD; the tree is the one this script is in):
#   sh tools/build.sh [--force] [--repo <dir>] [<origin> ... [";" <origin> ...] ...]
#
#   <origin>      the ports to build (category/port of this tree) and the ports of
#                 this tree they need; none: every <category>/<port> with a Makefile
#   ";"           between groups of them: stages, each built after the one before it
#                 (with the ports it needs that no stage before it has); none, for
#                 every port: az, then PHP 5.6, 7.4, 8.1, 8.3, 8.2, 8.4 (each with
#                 mod_php and its modules), then the rest (the order of aZ, 11.11.2026)
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
#   AZ_JOBS          the ports built at once, in waves (default 4); 1: one after
#                    another in the order of the queue, as before AZ_JOBS
#   AZ_DRYRUN        1: the queue, the hashes and the waves of the run (what the
#                    repository has with the same az_hash left out), nothing installed
#                    or built, no repository (the ports that need az: decided after az
#                    is built, when it is to be built: AZ_PLAN)
#   AZ_PLAN          1: the plan of the run: az/az and the ports it needs built when
#                    they are to be (the hashes of the ports that need az are made with
#                    the interfaces of the new az), every other port only decided:
#                    kept from the repository or to be built, and why (results/plan.txt,
#                    the summary); the repository gets what was built
#   AZ_CONFIGURE_CHECK  1: the configure check of the PHP ports the run configures
#                    (tools/configure-check.sh; results/configure-check.txt)
#   AZ_CFLAGS, AZ_GCC_SO, AZ_GCC_BIN, MAKE_CONF  given to the builds (the scripts of
#                    tools/ read them); a build sees no other variable of the caller
#
# How (the logic of poudriere, with make and pkg of the host, each port in a chroot):
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
#   ports, not for az/az; the files of tools/ its makefiles name outside their
#   comments, and those these name: tools/az-build.sh of az/az; the files of this tree
#   its EXTRA_PATCHES name), of the official commit, the level and tools/make.conf.in,
#   and of the hash of each port of this tree it needs (so a change of a port builds
#   again what needs it), but of az/az the interface hashes of the libraries of az the
#   port uses and of those they need (aZ, 12.11.2026: the manifests of the package of
#   az, tools/az-interface.sh; the content hash of the libraries of AZ_STATIC_LIBS), so
#   a fix inside a library builds again only az and a change of its interface the
#   ports that use it; the hashes of the ports that need az are made once az/az is
#   done (built or kept): that hash leaves out the files the port lists in its
#   AZ_HASH_NOT_FOR_DEPENDENTS (run time only: lang/php74's php.ini block, profile
#   script, rc.d script, pkg-message), which count in its own az_hash only, not in
#   that of its slaves either; it goes to make as AZ_HASH (the annotation az_hash of the package,
#   Mk/bsd.overlay.mk), the revision as AZ_STAMP (PORTREVISION= ${AZ_STAMP}: each
#   build is an upgrade for pkg; pkg takes a dependency by its name, not its version);
#   the base of every az_hash: the official commit, the level, tools/make.conf.in and
#   the way the builder builds ("builder chroot": each port in a chroot of its own,
#   11.11.2026: every port built once that way);
# - after az/az is built in a run, the ABI check of the packages of the repository that
#   need az (tools/az-abi-check.sh: each SONAME of az they need is in the new az, each
#   symbol they bind from it is defined there): one that fails is built again (one not
#   in the queue goes from the repository); a package that links a library of az its
#   az_hash does not take (its SONAMEs, shlibs_required) fails the run (AZ_HASH_LIBS of
#   its Makefile is short); results/az-interface.txt: the interfaces that changed, the
#   ABI check, the ports kept by interface while az was built again;
# - a port that names no file of the static tree of az in its dependencies builds
#   without its archives (they go from its chroot): only a port that says AZ_STATIC_LIBS
#   (tools/check-tree.sh) can link them;
# - the build tools of AZ_TOOLS_OFFICIAL (below: Python, Perl, meson) come from the
#   official packages of FreeBSD also when this tree has the origin (aZ, 11.11.2026:
#   our python312 and perl5.42 link libraries of az, which needs them to build): for a
#   port that needs such an origin only to build it (FETCH_, EXTRACT_, PATCH_, BUILD_
#   or PKG_DEPENDS; not LIB_ or RUN_DEPENDS, and the port is no extension of Python, a
#   FLAVOR py*), the official package goes into its chroot, and the hash of our port
#   is not in its az_hash (the official commit is in the base); a port that runs with
#   it (LIB_ or RUN_DEPENDS) or builds an extension for it gets ours, whose hash counts
#   (results/hashes.txt names the tools a port gets official);
# - a port whose origin has a package with the same az_hash in the repository is not
#   built again (an incremental build) unless --force; a port that fails stops those
#   that need it (skipped, with the reason);
# - each port in a chroot of its own (work/ch/<key>), made for it in seconds and torn
#   down after it, whatever its result (unmounted, removed; rm -x): the base system
#   of the machine read only (nullfs), a copy of its /etc, devfs, an empty /usr/local,
#   /tmp and a pkg database of its own; the catalogs of the run (those of the machine,
#   updated once at the start: pkg -U, never during the run) and the cache of pkg of
#   the machine shared, so that an official package is downloaded once (the official
#   packages of the ports to build fetched at the start; then one chroot at a time
#   fetches, lockf); this tree, the official tree, packages/ and the repository read
#   only at their paths, the distfiles, WRKDIRPREFIX, the packages directory of the
#   port and results/az-results read-write (ch_up). In it the official packages of its
#   dependencies (and those our packages it gets need to run) by pkg -c <chroot>
#   install from the FreeBSD repositories of the machine (not ours: az, azbuild), ours
#   by pkg -c <chroot> add of the packages built before or of the repository (-f in the
#   place of an official package of the same name), in the order of the queue; then
#   make clean package in it (chroot(8), the environment of a login of root with the
#   make.conf of the run, AZ_CPUTYPE and the variables above) with
#   USE_PACKAGE_DEPENDS_ONLY=yes (nothing is built from source but the port itself);
#   its log, its time (with those of its chroot and of its dependencies), OK or FAIL.
#   The /usr/local of the machine is never touched by a build: the checks after the
#   run (tools/install-php.sh, test-programs.sh) see nothing a build installed;
# - AZ_JOBS above 1: waves, each of the ports whose ports of this tree they need are
#   done, up to AZ_JOBS ports at once, the biggest first (the size of the package in
#   the repository), each with its chroot, its log and its own PACKAGES directory (its
#   distfiles fetched under lockf(1), one build at a time); the summary in the order
#   of the queue, results/waves.txt;
# - a NEED_ROOT port (az/az builds into the real prefix and refuses files of a package
#   there): into the /usr/local/az of its own chroot, as any port;
# - the repository: one package per origin (of two in <dir> at the start, the newer
#   version), the new ones in the place of the old ones of the same name or origin,
#   away with the packages of origins this tree has no more, pkg repo, signed and
#   checked (tools/pkg-repo-sign.sh); <dir> keeps a signed catalog or none: without
#   the signature (no key, or the key fails) its catalog goes, the packages stay, and
#   an unsigned catalog of them in work/repo-unsigned serves the checks of the run
#   only (never published);
# - AZ_CONFIGURE_CHECK=1: after the build of a PHP port (lang/phpXY, www/mod_phpXY,
#   a module phpXY-<module>, PECL and clang ones too), whatever its result once its
#   configure ran, what that configure found is kept (config.log, main/php_config.h
#   or config.h, the generated Makefile), make configure runs once more in a
#   WRKDIRPREFIX of its own with the same compiler and the permissive flags of
#   tools/configure-check.sh (the errors of C of GCC 14+ and clang 16+ as warnings)
#   in CFLAGS_<arch>, which bsd.port.mk appends to the CFLAGS of the port (so these
#   stay, and nothing of Mk/ or of a hash changes), and tools/configure-check.sh
#   compares the two: a test of configure whose result depends on those errors.
#
# Results: results/ of the tree: summary.txt (a line per port, "result: OK" or
# "result: FAIL (...)" at the end, a line "chroots:" of their times), queue.txt,
# hashes.txt, az-interface.txt and abi-check.txt (az), plan.txt (AZ_PLAN), waves.txt
# (AZ_JOBS above 1, AZ_DRYRUN), progress.log
# (the screen lines as they come), logs/<category>_<port>.log, logs/chroots.log (the
# catalogs and the official packages fetched at the start), pkg-repo.log; with AZ_CONFIGURE_CHECK=1
# configure-check.txt (each port with differences, the checks with their diagnostic,
# then the others) and configure-check/ (a file per port, the two config.log files of
# a port with differences).
# Exit status: 0 every port of the queue built or kept (AZ_PLAN: or to be built) and the
# repository signed (or unsigned without a key), or a dry run; 1 otherwise, 2 a wrong
# call.

set -u

# the official tree the overlay is built over: freebsd-ports main of 10.11.2026 21:19,
# the commit of az/az/files/deps.conf too. The rule of aZ: the latest version of a
# port, or a newer release for its security or a serious bug (a take line of
# deps.conf), so before a build this goes to the latest commit of main (it had
# stayed at 04.11.2026: apache24 2.4.69 for 2.4.70 of 07.11.2026, aZ 10.11.2026)
ports_commit="6e4a386577aaa191a68b11865fcb18e02f98e525"
ports_url="https://github.com/freebsd/freebsd-ports"

# The build tools a port gets from the official packages of FreeBSD even when this
# tree has the origin (aZ, 11.11.2026): our Python and Perl link libraries of az, and
# az/az needs python3, meson and perl5 to build (a cycle, and every package built
# again with each update of them). For a port that needs one of these only to build
# it, the official package (see the head); for one that runs with it or builds an
# extension for it, ours. The origins as the dependencies name them (lang/python3 the
# meta port of the default Python, meson needs it); an origin this tree does not have
# is official anyway. Here only: not taken from the environment.
AZ_TOOLS_OFFICIAL="lang/python3 lang/python312 lang/perl5.42 devel/meson"

top="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n 's/^# \{0,1\}//; 6,16p' "$0" >&2; exit "${1:-2}"; }
# say: a line on the screen with the time, also into results/progress.log once it is
# there (the result of every port among them: tools/runs-progress.sh reads it in the
# VM while the build runs; a build job that runs at the same time writes there too)
say() {
    _sl="[build $(date '+%H:%M:%S')] $*"
    printf '%s\n' "$_sl"
    if [ -n "${res:-}" ] && [ -d "$res" ]; then printf '%s\n' "$_sl" >> "$res/progress.log" 2> /dev/null; fi
    return 0
}
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
jobs="${AZ_JOBS:-4}"
case "$jobs" in
    ''|*[!0-9]*|0*) die "AZ_JOBS=$jobs: not a number of 1 or more" ;;
esac
case "${AZ_DRYRUN:-}" in ''|0) dryrun=0 ;; *) dryrun=1 ;; esac
case "${AZ_PLAN:-}" in ''|0) plan=0 ;; *) plan=1 ;; esac
case "${AZ_CONFIGURE_CHECK:-}" in ''|0) ccheck=0 ;; *) ccheck=1 ;; esac
# one port after another as before AZ_JOBS: AZ_JOBS=1 (not a dry run)
serial=0
[ "$jobs" = 1 ] && [ "$dryrun" = 0 ] && serial=1
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
rm -rf "${q:?}"/* "${res:?}" "$work/pk" "$work/cc" "$work/ccw"
mkdir -p "$res/logs" "$res/az-results" "$q/info" "$q/deps" "$q/rdeps" "$q/odeps" "$q/orun" "$q/pkgbase" "$q/state" \
    "$q/file" "$q/hash" "$q/dl" "$q/ch" "$q/chtime" || die "cannot make $res and $q"
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

# --- the chroots ------------------------------------------------------------------------
# Each port builds in a chroot of its own, $chd/<key> (work/ch/<key>), made by ch_up and
# torn down by ch_down after the port, whatever its result (see the head). What the
# chroots of a run share is made once by ch_init: work/ch-etc (the /etc of the machine
# without /etc/ssh), work/ch-local (/usr/local/etc/pkg.conf and the repositories of
# /usr/local/etc/pkg/repos but ours), work/ch-repos (the catalogs of pkg). The base
# system: the directories of $ch_base, read only. pkg works in a chroot from the
# machine (pkg -c), a build in it by chroot(8) (ch_run).
chd="$workr/ch"
ch_base="/bin /sbin /lib /libexec /usr/bin /usr/sbin /usr/lib /usr/lib32 /usr/libexec /usr/include /usr/share /usr/libdata"
# the pkg database (each chroot its own, the catalogs in its repos/ those of the run)
# and the cache of the packages (shared) at the paths pkg of the machine has
pkgdb="$(pkg config PKG_DBDIR 2> /dev/null)"; pkgdb="${pkgdb:-/var/db/pkg}"
pkgcache="$(pkg config PKG_CACHEDIR 2> /dev/null)"; pkgcache="${pkgcache:-/var/cache/pkg}"
# fdescfs on /dev/fd and procfs on /proc in a chroot when the machine has them
ch_fdesc=0; ch_proc=0
mount -p | awk '$2 == "/dev/fd" && $3 == "fdescfs" { f = 1 } END { exit !f }' && ch_fdesc=1
mount -p | awk '$2 == "/proc" && $3 == "procfs" { f = 1 } END { exit !f }' && ch_proc=1

# ch_mounts <dir>: the mount points in a directory (and on it), the deepest first
ch_mounts() {
    mount -p | awk -v d="$1" '$2 == d || index($2, d "/") == 1 { print length($2), $2 }' | sort -rn | cut -d ' ' -f 2-
}
# ch_down <chroot>: a chroot of the run away: what is mounted in it unmounted (the
# deepest first, by force when busy), then its files, only when nothing is mounted
# there any more (and rm -x never crosses a mount point: the distfiles, the cache, the
# trees mounted in it stay whole); 1 when it stays (said)
ch_down() {
    case "$1" in "$chd"/?*) ;; *) say "  ch_down: $1 is no chroot of the run ($chd/<key>)"; return 1 ;; esac
    [ -e "$1" ] || [ -n "$(ch_mounts "$1")" ] || return 0
    for _m in $(ch_mounts "$1"); do
        umount "$_m" > /dev/null 2>&1 || umount -f "$_m" > /dev/null 2>&1 || say "  cannot unmount $_m"
    done
    _left="$(ch_mounts "$1" | tr '\n' ' ')"
    if [ -n "$_left" ]; then say "  the chroot $1 stays: still mounted there: $_left"; return 1; fi
    rm -rfx "$1" 2> /dev/null && return 0
    chflags -R 0 "$1" 2> /dev/null
    rm -rfx "$1" 2> /dev/null || { say "  cannot remove the chroot $1"; return 1; }
}
# ch_all_down: every chroot of the run away (at the start: those a run before left; at
# the end, also when the run is stopped)
ch_all_down() {
    [ -d "$chd" ] || return 0
    for _x in "$chd"/*; do
        [ -e "$_x" ] || continue
        ch_down "$_x" || :
    done
    return 0
}
# ch_dir <dir of the machine>: that directory at the same path in the chroot $c: the
# directories of its real path ($chr), and the symbolic links of its path the machine
# has (/home -> usr/home), so that the paths of make.conf and of the queue work there
ch_dir() {
    chr="$(realpath "$1" 2> /dev/null)" || { why="no directory $1"; return 1; }
    mkdir -p "$c$chr" 2> /dev/null || [ -d "$c$chr" ] || { why="cannot make $c$chr"; return 1; }
    _p=""
    for _s in $(printf '%s\n' "$1" | tr '/' ' '); do
        _p="$_p/$_s"
        [ -L "$_p" ] || continue
        [ -e "$c$_p" ] || [ -L "$c$_p" ] || ln -s "$(readlink "$_p")" "$c$_p" ||
            { why="cannot make the link $c$_p of $_p"; return 1; }
    done
    return 0
}
# ch_mount <ro|rw> <dir of the machine> [<path in the chroot>]: nullfs, at the same
# path (the real one) or at the path given
ch_mount() {
    if [ $# -ge 3 ]; then
        chr="$3"
        mkdir -p "$c$chr" 2> /dev/null || [ -d "$c$chr" ] || { why="cannot make $c$chr"; return 1; }
        _src="$(realpath "$2" 2> /dev/null)" || { why="no directory $2"; return 1; }
    else
        ch_dir "$2" || return 1
        _src="$chr"
    fi
    mount -t nullfs -o "$1" "$_src" "$c$chr" > "$cs/mount.out" 2>&1 ||
        { why="mount -t nullfs -o $1 $_src $c$chr failed: $(tail -n 1 "$cs/mount.out")"; return 1; }
}
# ch_fs <type> <path in the chroot>: devfs, fdescfs, procfs
ch_fs() {
    mkdir -p "$c$2" 2> /dev/null || [ -d "$c$2" ] || { why="cannot make $c$2"; return 1; }
    mount -t "$1" "$1" "$c$2" > "$cs/mount.out" 2>&1 || { why="mount -t $1 $c$2 failed: $(tail -n 1 "$cs/mount.out")"; return 1; }
}
# ch_under <real path> <real dir>...: the path is one of the dirs or in one of them
ch_under() {
    _u="$1"; shift
    for _ud in "$@"; do
        case "$_u" in "$_ud" | "$_ud"/*) return 0 ;; esac
    done
    return 1
}
# the directories of this tree a chroot gets read only: all but those of the run (the
# work directory, packages/, distfiles/, results/, the repository) and the hidden ones
ch_ovl=""
for _d in "$topr"/*/; do
    _d="${_d%/}"
    [ -d "$_d" ] || continue
    _rd="$(realpath "$_d")"
    case " $workr $(realpath "$packages") $(realpath "$distdir") $(realpath "$res") $(realpath "$repo") " in
        *" $_rd "*) continue ;;
    esac
    ch_ovl="$ch_ovl ${_d##*/}"
done
# ch_up <key>: the chroot $c of a port ($chd/<key>; its files of the run in $cs,
# $q/ch/<key>); 1 with $why when it could not be made
ch_up() {
    c="$chd/$1"; cs="$q/ch/$1"
    rm -rf "$cs" && mkdir -p "$cs" || { why="cannot make $cs"; return 1; }
    ch_down "$c" > /dev/null || { why="what a chroot before left in $c is still mounted there"; return 1; }
    mkdir -p "$c" || { why="cannot make $c"; return 1; }
    for _d in $ch_base; do
        [ -d "$_d" ] || continue
        ch_mount ro "$_d" || return 1
    done
    mkdir -p "$c/etc" "$c/tmp" "$c/var/tmp" "$c/var/run" "$c/var/log" "$c/root" "$c/usr/local/etc" \
        "$c/usr/local/lib" "$c$pkgdb/repos" && chmod 1777 "$c/tmp" "$c/var/tmp" ||
        { why="cannot make the directories of $c"; return 1; }
    (cd "$work/ch-etc" && tar -cf - .) | (cd "$c/etc" && tar -xpf -)
    [ -f "$c/etc/rc.subr" ] || { why="cannot copy work/ch-etc into $c/etc"; return 1; }
    if [ -d "$work/ch-local" ]; then
        (cd "$work/ch-local" && tar -cf - .) | (cd "$c/usr/local/etc" && tar -xpf -) ||
            { why="cannot copy work/ch-local into $c/usr/local/etc"; return 1; }
    fi
    ch_fs devfs /dev || return 1
    if [ "$ch_fdesc" = 1 ]; then ch_fs fdescfs /dev/fd || return 1; fi
    if [ "$ch_proc" = 1 ]; then ch_fs procfs /proc || return 1; fi
    # the catalogs of the run and the cache of pkg, shared
    ch_mount rw "$work/ch-repos" "$pkgdb/repos" || return 1
    ch_mount rw "$pkgcache" || return 1
    # this tree read only: its directories but those of the run (each its own mount:
    # nullfs refuses a directory over a view of itself, so that distfiles/ could not
    # be read-write in a read-only tree), the official tree, packages/ and the
    # repository read only
    _ro=""
    for _d in $ch_ovl; do
        ch_mount ro "$top/$_d" || return 1
        _ro="$_ro $chr"
    done
    for _d in "$ports" "$packages" "$repo"; do
        # shellcheck disable=SC2086
        ch_under "$(realpath "$_d")" $_ro && continue
        ch_mount ro "$_d" || return 1
        _ro="$_ro $chr"
    done
    # the make.conf of the run and its PORT_DBDIR (empty: no saved options)
    ch_dir "$work" && mkdir -p "$c$chr/db" && cp -p "$work/make.conf" "$c$chr/make.conf" ||
        { why="${why:-cannot copy make.conf into $c}"; return 1; }
    # what the builds write: the distfiles (shared), WRKDIRPREFIX, the packages
    # directory of the port, the results of the scripts of tools/, the work
    # directories of the configure check
    for _d in "$distdir" "$work/wrk" "$work/pk/$1" "$res/az-results" $( [ "$ccheck" = 1 ] && echo "$work/ccw"); do
        mkdir -p "$_d" || { why="cannot make $_d"; return 1; }
        # shellcheck disable=SC2086
        if ch_under "$(realpath "$_d")" $_ro; then why="$_d is in a directory mounted read only in the chroot"; return 1; fi
        ch_mount rw "$_d" || return 1
    done
    # the hints of the run-time linker (/usr/local/lib; the packages add theirs)
    chroot "$c" /usr/sbin/service ldconfig start > /dev/null 2>&1 || :
    return 0
}
# ch_run [-l <lock file>] <command>...: a command in the chroot $c (under lockf(1) of
# the machine with -l), with the environment of a login of root, the make.conf of the
# run, the level, and AZ_CFLAGS, AZ_GCC_SO, AZ_GCC_BIN and MAKE_CONF of the caller
# when set (nothing else of the caller: no key, no token). NOCLEANDEPENDS: make clean
# of a port leaves the ports it depends on alone: they may build at that moment in
# another chroot of the wave, with the same WRKDIRPREFIX (11.11.2026: make clean of
# ftp/curl, which takes the official perl5 to build, removed the work directory of
# lang/perl5.42 under its Configure; that of www/node18 the one of lang/python312)
ch_run() {
    _lk=""
    if [ "$1" = -l ]; then _lk="$2"; shift 2; fi
    set -- chroot "$c" /usr/bin/env -i HOME=/root USER=root LOGNAME=root SHELL=/bin/sh \
        PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin \
        __MAKE_CONF="$__MAKE_CONF" ASSUME_ALWAYS_YES=yes NOCLEANDEPENDS=yes AZ_CPUTYPE="$cputype" \
        ${AZ_CFLAGS+"AZ_CFLAGS=$AZ_CFLAGS"} ${AZ_GCC_SO+"AZ_GCC_SO=$AZ_GCC_SO"} \
        ${AZ_GCC_BIN+"AZ_GCC_BIN=$AZ_GCC_BIN"} ${MAKE_CONF+"MAKE_CONF=$MAKE_CONF"} "$@"
    if [ -n "$_lk" ]; then lockf -k "$_lk" "$@"; else "$@"; fi
}
# the chroots a run before left (stopped), and those of this run at its end, whatever ends it
c=""; cs="$q/ch"
ch_all_down
trap 'ch_all_down' EXIT
trap 'exit 2' HUP INT TERM

# tool_official <origin> <key>: a build tool of AZ_TOOLS_OFFICIAL that the port of the
# key needs only to build (not among its LIB_ and RUN_DEPENDS), and the port is no
# extension of Python (its FLAVOR, line 19 of its info, not py*): it gets the official
# package of the origin, even when this tree has it
tool_official() {
    case " $AZ_TOOLS_OFFICIAL " in *" ${1%%@*} "*) ;; *) return 1 ;; esac
    sed 's/@.*//' "$q/info/$2.run" | grep -qxF "${1%%@*}" && return 1
    case "$(sed -n 19p "$q/info/$2")" in py[0-9]*) return 1 ;; esac
    return 0
}

# port_info <origin>: what make -V says of a port of this tree into $q/info/<key>
# (lines: 1 PKGNAME, 2 IGNORE, 3-9 FETCH_ EXTRACT_ PATCH_ BUILD_ LIB_ RUN_ PKG_DEPENDS,
# 10 NEED_ROOT, 11 MASTERDIR, 12 FILESDIR, 13 PATCHDIR, 14 PKGDIR, 15 DISTINFO_FILE,
# 16 .MAKE.MAKEFILES, 17 AZ_HASH_NOT_FOR_DEPENDENTS, 18 AZ_HASH_LIBS, 19 FLAVOR,
# 20 AZ_STATIC_LIBS, 21 EXTRA_PATCHES, 22 AZ_PREFIX, 23 AZ_STATIC); our
# dependencies into $q/deps/<key> (all kinds) and
# $q/rdeps/<key> (LIB_ and RUN_DEPENDS: what pkg add of its package needs), the
# official ones into $q/odeps/<key> and $q/orun/<key>; the origins of this tree it gets
# official (tool_official) are among the official ones, and in $q/info/<key>.tools;
# $q/info/<key>.static when a dependency names a file of the static tree of az
# (AZ_STATIC: the port builds against it)
port_info() {
    _k="$(key "$1")"
    [ -f "$q/info/$_k" ] && return 0
    : > "$q/deps/$_k"; : > "$q/rdeps/$_k"; : > "$q/odeps/$_k"; : > "$q/orun/$_k"; : > "$q/info/$_k.tools"
    if ! make -C "$top/$1" AZ_STAMP="$az_stamp" -V PKGNAME -V IGNORE -V FETCH_DEPENDS -V EXTRACT_DEPENDS \
            -V PATCH_DEPENDS -V BUILD_DEPENDS -V LIB_DEPENDS -V RUN_DEPENDS -V PKG_DEPENDS -V NEED_ROOT \
            -V MASTERDIR -V FILESDIR -V PATCHDIR -V PKGDIR -V DISTINFO_FILE -V .MAKE.MAKEFILES \
            -V AZ_HASH_NOT_FOR_DEPENDENTS -V AZ_HASH_LIBS -V FLAVOR -V AZ_STATIC_LIBS -V EXTRA_PATCHES \
            -V AZ_PREFIX -V AZ_STATIC > "$q/info/$_k" 2> "$q/info/$_k.err" || [ -z "$(sed -n 1p "$q/info/$_k")" ]; then
        echo "make -V failed: $(grep . "$q/info/$_k.err" | head -n 1)" > "$q/info/$_k.bad"
        return 1
    fi
    _st="$(sed -n 23p "$q/info/$_k")"
    if [ -n "$_st" ] && sed -n '3,9p' "$q/info/$_k" | tr -s ' \t' '\n\n' | grep -q -e "^$_st/[^:]*:az/az\$" -e "^$_st/[^:]*:az/az[:@]"; then
        : > "$q/info/$_k.static"
    fi
    sed -n '3,9p' "$q/info/$_k" | dep_origins > "$q/info/$_k.all"
    sed -n '7,8p' "$q/info/$_k" | dep_origins > "$q/info/$_k.run"
    for _d in $(cat "$q/info/$_k.all"); do
        [ "${_d%%@*}" = "$1" ] && continue
        if ! ours "$_d"; then
            echo "$_d" >> "$q/odeps/$_k"
        elif tool_official "$_d" "$_k"; then
            echo "$_d" >> "$q/odeps/$_k"
            echo "${_d%%@*}" >> "$q/info/$_k.tools"
        else
            echo "${_d%%@*}" >> "$q/deps/$_k"
        fi
    done
    for _d in $(cat "$q/info/$_k.run"); do
        [ "${_d%%@*}" = "$1" ] && continue
        if ours "$_d"; then echo "${_d%%@*}" >> "$q/rdeps/$_k"; else echo "$_d" >> "$q/orun/$_k"; fi
    done
    return 0
}

# port_files <origin>: the files of this tree a port is built from, "f <path relative
# to the tree> <sha256>" a line each: those of its directory, of its MASTERDIR,
# FILESDIR, PATCHDIR, PKGDIR and DISTINFO_FILE, the files of this tree its EXTRA_PATCHES
# name, and the makefiles of this tree it reads
# (.MAKE.MAKEFILES: Mk/bsd.overlay.mk, which every port reads, taken also when make
# does not say; Mk/Uses/php.mk only by the ports that read it); and the files of
# tools/ that the lines of those makefiles name outside their comments
# (tools/<name> or ${AZ_TOOLS}/<name>: the wrapper ports run the builds of tools/,
# az/az ${AZ_TOOLS}/az-build.sh; the design comment of az/az/Makefile names the
# scripts of all the wrapper ports and does not count), with the files of tools/
# those scripts name in turn (comments too: az-build.sh names az-check-links.py)
tree_file() {
    case "$1" in
        "$workr"/*|"$portsr"/*|"$topr"/work/*|"$topr"/packages/*|"$topr"/distfiles/*|"$topr"/results/*|"$topr"/repo/*|"$topr"/.git/*) return 1 ;;
        "$topr"/*) return 0 ;;
    esac
    return 1
}
# tools_named <file>...: the files of tools/ of this tree that the files name
# (tools/<name>, ${AZ_TOOLS}/<name>; a dot that ends a sentence is not of the name);
# tools_named_mk the same for makefiles, their comments (from # to the end of the
# line) left out
tools_names() {
    grep -o -E '(tools|AZ_TOOLS[})]?)/[A-Za-z0-9_.-]+' | sed -E 's#^[^/]*/#tools/#; s/\.+$//' | LC_ALL=C sort -u |
        while read -r _n; do [ -f "$topr/$_n" ] && echo "$topr/$_n"; done
}
tools_named() {
    [ $# -gt 0 ] || return 0
    cat "$@" 2> /dev/null | tools_names
}
tools_named_mk() {
    [ $# -gt 0 ] || return 0
    sed 's/#.*//' "$@" 2> /dev/null | tools_names
}
# files_in <dir>: the files under a directory but those of a work/ in it (a WRKDIR
# without WRKDIRPREFIX); a /work/ in the path of the directory itself (the tree in
# /home/runner/work/...) does not count
files_in() {
    find "$1" -type f 2> /dev/null | awk -v d="$1" 'index(substr($0, length(d) + 1), "/work/") == 0'
}
port_files() {
    _k="$(key "$1")"
    {
        files_in "$topr/$1"
        [ -f "$topr/Mk/bsd.overlay.mk" ] && echo "$topr/Mk/bsd.overlay.mk"
        for _p in $(sed -n '11,16p' "$q/info/$_k"); do
            if [ -d "$_p" ]; then files_in "$_p"; elif [ -f "$_p" ]; then echo "$_p"; fi
        done
        # EXTRA_PATCHES (<file>[:-p<n>]) of this tree: ftp/curl applies the patch of curl of az/az
        for _p in $(sed -n 21p "$q/info/$_k"); do
            _p="${_p%%:*}"
            [ -f "$_p" ] && echo "$_p"
        done
    } 2> /dev/null | while read -r _f; do realpath "$_f" 2> /dev/null; done | LC_ALL=C sort -u |
        while read -r _f; do tree_file "$_f" && echo "$_f"; done > "$q/files-$_k"
    # the makefiles among them (Makefile*, *.mk), the files of tools/ they name, and
    # those these name (one level more)
    # shellcheck disable=SC2046
    set -- $(grep -E '/(Makefile[^/]*|[^/]*\.mk)$' "$q/files-$_k")
    tools_named_mk "$@" > "$q/tools1-$_k"
    # shellcheck disable=SC2046
    set -- $(cat "$q/tools1-$_k")
    tools_named "$@" > "$q/tools2-$_k"
    LC_ALL=C sort -u "$q/files-$_k" "$q/tools1-$_k" "$q/tools2-$_k" | while read -r _f; do
        printf 'f %s %s\n' "${_f#"$topr"/}" "$(hfile "$_f")"
    done
}

# pkgbase <origin[@flavor]>: the name of the package of an official port (PKGBASE of
# make -V in the official tree, with its flavour), cached; why not in <cache>.why (the
# callers take the name by $(...), where $why does not reach them)
pkgbase() {
    _f="$q/pkgbase/$(key "$1")"
    if [ ! -s "$_f" ]; then
        _o="${1%%@*}"; _fl=""
        case "$1" in *@*) _fl="${1#*@}" ;; esac
        if [ ! -f "$ports/$_o/Makefile" ]; then
            why="no port $_o in the official tree"; echo "$why" > "$_f.why"; return 1
        fi
        if ! make -C "$ports/$_o" ${_fl:+FLAVOR=$_fl} -V PKGBASE > "$_f" 2> "$_f.err" || [ ! -s "$_f" ]; then
            why="make -V PKGBASE of $1 failed: $(grep . "$_f.err" | head -n 1)"; echo "$why" > "$_f.why"
            rm -f "$_f"; return 1
        fi
    fi
    cat "$_f"
}

# pkg_said <file of the output of pkg> <what failed>: all the lines of a pkg command
# that failed on the screen (the job log) and in the log of the port; $why gets the
# first line that says something
pkg_said() {
    cat "$1" >> "$log"
    say "  $2; what pkg said:"
    sed 's/^/    | /' "$1"
    why="$2: $(grep -v -E '^(Updating|Installing|Extracting|Checking|Processing|All repositories|The following|New packages|Number of packages|\[)' "$1" |
        grep . | head -n 1 | cut -c1-200)"
}

# dep_lists <origin>: what a port gets in its chroot, worked out once (by the run, not by
# its build, which may run beside others): $q/dl/<key>.ours, the ports of this tree it
# needs and those they need to run (in the order of the queue: pkg add, each after
# what it needs), and $q/dl/<key>.off, the official packages of its dependencies and
# those our packages it gets need to run (the names of pkg, on one line); a name that
# could not be worked out into $q/dl/<key>.bad
dep_lists() {
    _k="$(key "$1")"
    [ -f "$q/dl/$_k.off" ] && return 0
    LC_ALL=C sort -u "$q/deps/$_k" > "$q/dl/$_k.cl"
    cp "$q/dl/$_k.cl" "$q/dl/$_k.new"
    while [ -s "$q/dl/$_k.new" ]; do
        for _c in $(cat "$q/dl/$_k.new"); do cat "$q/rdeps/$(key "$_c")"; done | LC_ALL=C sort -u |
            grep -vxF -f "$q/dl/$_k.cl" > "$q/dl/$_k.next"
        cat "$q/dl/$_k.next" >> "$q/dl/$_k.cl"
        mv "$q/dl/$_k.next" "$q/dl/$_k.new"
    done
    if [ -s "$q/dl/$_k.cl" ]; then grep -xF -f "$q/dl/$_k.cl" "$q/queue.txt" > "$q/dl/$_k.ours"; else : > "$q/dl/$_k.ours"; fi
    { cat "$q/odeps/$_k"; for _c in $(cat "$q/dl/$_k.ours"); do cat "$q/orun/$(key "$_c")"; done; } |
        LC_ALL=C sort -u > "$q/dl/$_k.oo"
    : > "$q/dl/$_k.names"
    rm -f "$q/dl/$_k.bad"
    for _o in $(cat "$q/dl/$_k.oo"); do
        if ! _p="$(pkgbase "$_o")"; then
            cat "$q/pkgbase/$(key "$_o").why" > "$q/dl/$_k.bad" 2> /dev/null || echo "no package name of $_o" > "$q/dl/$_k.bad"
            break
        fi
        echo "$_p" >> "$q/dl/$_k.names"
    done
    LC_ALL=C sort -u "$q/dl/$_k.names" | tr '\n' ' ' | sed 's/ $//' > "$q/dl/$_k.off"
}

# ch_deps <origin>: the dependencies of a port installed in its chroot $c: the official
# packages ($q/dl/<key>.off) fetched into the cache, one chroot at a time (lockf: two
# fetches of one file would break it; those of the run are there already from the
# start), and installed (pkg install -U: the catalogs of the run, not updated); then
# ours ($q/dl/<key>.ours) by pkg add of their files (-f in the place of an official
# package of the same name that an official one brought). No official package comes
# after ours, so none takes the place of one of ours. 1 when they did not install
# (the line of the summary said)
ch_deps() {
    if [ -s "$q/dl/$k.bad" ]; then record "$1" fail "$pn: the official dependencies: $(cat "$q/dl/$k.bad")"; return 1; fi
    _want="$(cat "$q/dl/$k.off" 2> /dev/null)"
    if [ -n "$_want" ]; then
        say "  $1: pkg install $_want"
        # shellcheck disable=SC2086
        if ! lockf -k "$q/pkg-fetch.lock" pkg -c "$c" fetch -y -d -U $_want > "$cs/pkg.out" 2>&1; then
            pkg_said "$cs/pkg.out" "pkg fetch failed"
            record "$1" fail "$pn: the official dependencies: $why"
            return 1
        fi
        cat "$cs/pkg.out" >> "$log"
        # shellcheck disable=SC2086
        pkg -c "$c" install -y -U $_want > "$cs/pkg.out" 2>&1
        pkg -c "$c" query -a %n > "$cs/have" 2> /dev/null
        _miss=""
        for _p in $_want; do grep -qxF "$_p" "$cs/have" || _miss="$_miss $_p"; done
        if [ -n "$_miss" ]; then
            pkg_said "$cs/pkg.out" "pkg install did not install$_miss"
            record "$1" fail "$pn: the official dependencies: $why"
            return 1
        fi
        cat "$cs/pkg.out" >> "$log"
    fi
    for _c in $(cat "$q/dl/$k.ours"); do
        _ck="$(key "$_c")"
        _f="$(cat "$q/file/$_ck" 2>/dev/null)"
        if [ -z "$_f" ] || [ ! -f "$_f" ]; then
            record "$1" fail "$pn: our dependencies: no package of $_c ($(st "$_c"))"
            return 1
        fi
        _n="$(pkg query -F "$_f" %n)"; _v="$(pkg query -F "$_f" %v)"
        _af=""
        pkg -c "$c" info -e "$_n" && _af=-f
        say "  $1: pkg add ${_af:+$_af }${_f##*/}"
        # shellcheck disable=SC2086
        pkg -c "$c" add $_af "$_f" > "$cs/pkg.out" 2>&1
        _r=$?
        # a package of ours with the same files there (the other one of a pair:
        # phpXY-mysqlnd and phpXY-mysqlnd-openssl, which the ports on mysqlnd need one
        # or the other of; both only when the port needs both): pkg add refuses it
        # before it installs anything ("<name> conflicts with <name>-<version> (installs
        # files into the same place)"), so that one goes with the packages that depend
        # on it, and pkg add runs once more
        _cf="$(sed -n 's/.* conflicts with \([^ ]*\) (installs files into the same place).*/\1/p' "$cs/pkg.out" | LC_ALL=C sort -u)"
        if [ "$_r" != 0 ] && [ -n "$_cf" ]; then
            cat "$cs/pkg.out" >> "$log"
            for _x in $_cf; do
                say "  $1: pkg delete ${_x%-*} and what depends on it (the same files as $_n)"
                pkg -c "$c" delete -y "${_x%-*}" >> "$log" 2>&1 || say "  $1: pkg delete ${_x%-*} failed"
            done
            say "  $1: pkg add ${_af:+$_af }${_f##*/}"
            # shellcheck disable=SC2086
            pkg -c "$c" add $_af "$_f" > "$cs/pkg.out" 2>&1
            _r=$?
        fi
        if [ "$_r" != 0 ] || [ "$(pkg -c "$c" query %v "$_n" 2>/dev/null)" != "$_v" ]; then
            pkg_said "$cs/pkg.out" "pkg add ${_f##*/} failed"
            record "$1" fail "$pn: our dependencies: $why"
            return 1
        fi
        cat "$cs/pkg.out" >> "$log"
    done
    # the archives of the static tree of az only for a port that names a file of that
    # tree in its dependencies (and so says AZ_STATIC_LIBS, tools/check-tree.sh): no
    # other can link them into its package, which its az_hash would not know
    _st="$(sed -n 23p "$q/info/$k")"
    if [ -n "$_st" ] && [ ! -f "$q/info/$k.static" ] && grep -qxF az/az "$q/dl/$k.ours" && [ -d "$c$_st/lib" ]; then
        rm -f "$c$_st"/lib/*.a
        echo "== the archives of $_st/lib away from the chroot: $1 names no file of the static tree of az in its dependencies (AZ_STATIC_LIBS)" >> "$log"
    fi
    # the hints of the run-time linker with the libraries of the packages
    chroot "$c" /usr/sbin/service ldconfig start > /dev/null 2>&1 || :
    return 0
}

# --- the queue -----------------------------------------------------------------------
# the stages: the ports asked for in groups separated by ";", each group (with the
# ports of this tree it needs that no group before it has) built after the one before
# it; without ports the order of aZ (11.11.2026: "Первым делом ... az, на php 5.6, 7.4,
# 8.1, 8.3, 8.2, 8.4 - в таком порядке"): az, then each PHP version (its core, mod_php
# and modules), then the other ports. $q/groups: "<group> <origin>"
: > "$q/groups"
g=1
for o in "$@"; do
    if [ "$o" = ";" ]; then g=$((g + 1)); continue; fi
    ours "${o%/}" || die "not a port of this tree: $o (no $top/${o%/}/Makefile)"
    echo "$g ${o%/}" >> "$q/groups"
done
if [ $# -eq 0 ]; then
    all_ports > "$q/all.txt"
    g=1
    grep -qxF az/az "$q/all.txt" && { echo "1 az/az" >> "$q/groups"; g=2; }
    for v in 56 74 81 83 82 84; do
        grep -E "^(lang/php$v|www/mod_php$v|[^/]+/php$v-.*)\$" "$q/all.txt" | sed "s#^#$g #" > "$q/g.txt"
        [ -s "$q/g.txt" ] || continue
        cat "$q/g.txt" >> "$q/groups"; g=$((g + 1))
    done
    awk '{ print $2 }' "$q/groups" > "$q/g.txt"
    grep -vxF -f "$q/g.txt" "$q/all.txt" | sed "s#^#$g #" >> "$q/groups" || :
fi
awk '{ print $2 }' "$q/groups" | LC_ALL=C sort -u > "$q/want.txt"
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
# the stages: each group with the ports of this tree it needs, less those of the
# groups before it, in the order of the queue ($q/stage-<n>.txt); the queue then
# stage after stage (each port still after the ports it needs)
: > "$q/staged"
nst=0
for g in $(awk '{ print $1 }' "$q/groups" | sort -un); do
    awk -v g="$g" '$1 == g { print $2 }' "$q/groups" | LC_ALL=C sort -u > "$q/cl"
    cp "$q/cl" "$q/cl.new"
    while [ -s "$q/cl.new" ]; do
        for o in $(cat "$q/cl.new"); do cat "$q/deps/$(key "$o")"; done | LC_ALL=C sort -u | grep -vxF -f "$q/cl" > "$q/cl.next" || :
        cat "$q/cl.next" >> "$q/cl"
        mv "$q/cl.next" "$q/cl.new"
    done
    grep -xF -f "$q/cl" "$q/queue.txt" | grep -vxF -f "$q/staged" > "$q/st.txt" || :
    [ -s "$q/st.txt" ] || continue
    nst=$((nst + 1))
    mv "$q/st.txt" "$q/stage-$nst.txt"
    cat "$q/stage-$nst.txt" >> "$q/staged"
done
# what no group has (none, unless a loop above): a last stage
grep -vxF -f "$q/staged" "$q/queue.txt" > "$q/st.txt" || :
if [ -s "$q/st.txt" ]; then nst=$((nst + 1)); mv "$q/st.txt" "$q/stage-$nst.txt"; fi
i=1; while [ "$i" -le "$nst" ]; do cat "$q/stage-$i.txt"; i=$((i + 1)); done > "$q/queue.txt"
cp "$q/queue.txt" "$res/queue.txt"
say "the queue: $(wc -l < "$q/queue.txt" | tr -d ' ') ports (results/queue.txt), $nst stage$( [ "$nst" = 1 ] || echo s)"
: > "$res/stages.txt"
i=1
while [ "$i" -le "$nst" ]; do
    echo "stage $i: $(wc -l < "$q/stage-$i.txt" | tr -d ' ') ports: $(head -n 3 "$q/stage-$i.txt" | tr '\n' ' ')$( [ "$(wc -l < "$q/stage-$i.txt")" -gt 3 ] && echo '...')" >> "$res/stages.txt"
    i=$((i + 1))
done
while read -r l; do say "$l"; done < "$res/stages.txt"

# --- the az_hash of each port, in the order of the queue -------------------------------
# Two hashes a port: its az_hash ($q/hash/<key>), and the one the ports that need it
# fold in ($q/dhash/<key>), the same without the files of AZ_HASH_NOT_FOR_DEPENDENTS
# (a variable of its Makefile: files it installs and uses at run time only, never
# read by the build of another port; lang/php74: its php.ini block, the profile
# script, the rc.d script, pkg-message). A file of that list counts in the az_hash
# of the port whose directory holds it, and in no other: not in the hash its
# dependents fold in, nor in the az_hash of its slaves (their MASTERDIR is its
# directory: the modules php74-*). Without the variable both hashes are the same.
#
# az/az (aZ, 12.11.2026: no build again of what needs az for a fix inside a library of
# it, as FreeBSD and Debian do not build again the dependents of a shared library for
# one): az/az itself is built again when anything of it changes; a port that needs it
# folds in, instead of its hash, the interface hash of each library of az it uses and
# of those these need (their closure), and the hash of the files of az of no library
# (common.txt: bin/pkg-config). The interface of a library comes out of the build of
# az: the manifest tools/az-build.sh writes into the package
# (AZ_PREFIX/share/az/interface/<library>.txt: its headers, .pc files, *-config
# scripts and other files with their SHA-256, the SONAMEs of its shared libraries, the
# names of its archives, its version, the hash of its build functions, the libraries
# of az it requires by the NEEDED of its shared libraries, its .pc files and the
# #include lines of its headers), read by tools/az-interface.sh. So a fix inside the
# code of a library (the same headers, .pc files, SONAMEs, version and options) builds
# again az alone; a new version, a changed header or .pc, a new SONAME or a changed
# option builds again the ports that use that library. The libraries a port uses: those
# of the files of az its dependencies name (${AZ_PREFIX}/lib/libxml2.so:az/az: the
# library whose manifest has that path) and those its AZ_HASH_LIBS names (the names of
# deps.conf: a program that links more than its dependencies name, ftp/curl,
# multimedia/ffmpeg, ImageMagick); a port that links the archives of a library into its
# package names it in AZ_STATIC_LIBS ("none": it builds against the static tree, its
# package has no code of az): the content hash of that library (its archives too) and
# of its closure. A file of az a dependency names that no manifest has, or a name of
# those variables that is no library of az: the hash of all of az, as before (said in
# results/hashes.txt). The manifests are those of the package of az of the run: of the
# repository when az/az is kept (its package has the same az_hash and manifests), at
# once; of its new package when it is built, so the hashes of the ports that need it
# (and of those that need these) are made after az/az is built (az_resolve; az is the
# first stage), and no port that needs it is ready before. A package of az of the
# repository without manifests (built before 12.11.2026) is built again.
#
# The base of every hash: the official commit, the level, tools/make.conf.in and the
# way the builder builds ("builder chroot": each port in a chroot of its own, with
# only its dependencies; a change of that way that can change the packages changes
# this line, and every port is built again). The build tools a port gets official
# (AZ_TOOLS_OFFICIAL) are not among its dependencies of this tree: their hash is not
# in its own.
base_hash="$({ echo "freebsd-ports $ports_head"; echo "cputype $cputype"; echo "builder chroot"; cat "$top/tools/make.conf.in"; } | hin)"
mkdir -p "$q/dhash" "$q/azcov" "$q/uncov" "$q/abifail"
: > "$res/hashes.txt"
: > "$q/deferred"
# the manifests of az: $q/azif (the files), azif.hashes (tools/az-interface.sh hashes),
# azif.paths, azif.sonames; none until they are read (az_load)
: > "$q/azif.hashes"; : > "$q/azif.paths"; : > "$q/azif.sonames"
# az_load <package of az>: its manifests read; 1 when it has none
az_load() {
    rm -rf "$q/azif"
    sh "$top/tools/az-interface.sh" extract "$1" "$q/azif" "$(sed -n 22p "$q/info/az_az" 2>/dev/null)" 2> "$q/azif.err" &&
        sh "$top/tools/az-interface.sh" hashes "$q/azif" > "$q/azif.hashes" 2>> "$q/azif.err" &&
        sh "$top/tools/az-interface.sh" paths "$q/azif" > "$q/azif.paths" 2>> "$q/azif.err" &&
        sh "$top/tools/az-interface.sh" sonames "$q/azif" > "$q/azif.sonames" 2>> "$q/azif.err" &&
        [ -s "$q/azif.hashes" ] && awk '{ print $1 }' "$q/azif.sonames" > "$q/azif.sonames.names" && return 0
    : > "$q/azif.hashes"; : > "$q/azif.paths"; : > "$q/azif.sonames"
    return 1
}
# az_dep <key>: the lines of az/az for the hash of a port that needs it: "dep az/az
# common <hash>", "dep az/az interface <library> <hash>" for each library of the
# closure of those it uses, "dep az/az static <library> <hash>" (the content hash) for
# the closure of its AZ_STATIC_LIBS; "dep az/az <hash of az>" when a file of az its
# dependencies name is in no manifest or a name is no library of az. The libraries its
# hash covers into $q/azlibs-<key>, what it says into $q/azdep-<key>
az_dep() {
    _libs="$(sed -n 18p "$q/info/$1")"
    _st="$(sed -n 20p "$q/info/$1")"
    [ "$_st" = none ] && _st=""
    _pre="$(sed -n 22p "$q/info/$1")"
    _bad=""
    for _e in $(sed -n '3,9p' "$q/info/$1"); do
        case "$_e" in *:az/az | *:az/az:* | *:az/az@*) ;; *) continue ;; esac
        _p="${_e%%:*}"
        _l="$(awk -v p="${_p#"$_pre"/}" '$1 == p { print $2; exit }' "$q/azif.paths")"
        # a file of no library (bin/pkg-config): common, in the hash of every port that needs az
        [ "$_l" = common ] && continue
        if [ -n "$_l" ]; then _libs="$_libs $_l"; else _bad="$_bad $_p"; fi
    done
    for _l in $_libs $_st; do
        awk -v n="$_l" '$1 == n && n != "common" { f = 1 } END { exit !f }' "$q/azif.hashes" || _bad="$_bad $_l"
    done
    if [ -n "$_bad" ] || [ ! -s "$q/azif.hashes" ]; then
        echo "dep az/az $(cat "$q/dhash/az_az" 2>/dev/null || echo none)"
        awk '$1 != "common" { print $1 }' "$q/azif.hashes" > "$q/azlibs-$1"
        if [ -s "$q/azif.hashes" ]; then
            echo "all of az: no library of az for$_bad" > "$q/azdep-$1"
        else
            echo "all of az: no manifests of its libraries" > "$q/azdep-$1"
        fi
        return 0
    fi
    awk -v libs="$_libs" -v st="$_st" -v out="$q/azlibs-$1" -v note="$q/azdep-$1" '
        { ih[$1] = $2; ch[$1] = $3; cl[$1] = $4 }
        function close_of(list, w,   n, i, m, j, L, C) {
            n = split(list, L, " ")
            for (i = 1; i <= n; i++) { m = split(cl[L[i]], C, ","); for (j = 1; j <= m; j++) w[C[j]] = 1 }
        }
        function sorted(w, s,   n, x, i, j, t) {
            n = 0; for (x in w) s[++n] = x
            for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (s[j] < s[i]) { t = s[i]; s[i] = s[j]; s[j] = t }
            return n
        }
        END {
            close_of(libs, want); close_of(st, swant)
            print "dep az/az common " ih["common"]
            n = sorted(want, a); l = ""
            for (i = 1; i <= n; i++) { print "dep az/az interface " a[i] " " ih[a[i]]; print a[i] > out; l = l " " a[i] }
            m = sorted(swant, b); sl = ""
            for (i = 1; i <= m; i++) { print "dep az/az static " b[i] " " ch[b[i]]; print b[i] > out; sl = sl " " b[i] }
            printf "the interfaces of %d libraries of az:%s%s\n", n, l, (m ? "; the archives of" sl : "") > note
        }' "$q/azif.hashes"
}
# hash_port <origin>: the two hashes of a port (its files in $q/pf-<key> and
# $q/nfd-<key>), its line of results/hashes.txt; the libraries of az its hash covers,
# its own and those of the ports of this tree it needs, into $q/azcov/<key>
hash_port() {
    h_o="$1"; h_k="$(key "$1")"
    for h_d in $(LC_ALL=C sort -u "$q/deps/$h_k"); do
        if [ "$h_d" = az/az ]; then az_dep "$h_k"; continue; fi
        echo "dep $h_d $(cat "$q/dhash/$(key "$h_d")" 2>/dev/null || echo none)"
    done > "$q/dl-$h_k"
    {
        cat "$q/azlibs-$h_k" 2> /dev/null
        for h_d in $(cat "$q/deps/$h_k"); do cat "$q/azcov/$(key "$h_d")" 2> /dev/null; done
    } | LC_ALL=C sort -u > "$q/azcov/$h_k"
    {
        echo "base $base_hash"
        awk -v d="$h_o/" 'FILENAME == ARGV[1] { x[$1] = 1; next }
            ($2 in x) && substr($2, 1, length(d)) != d { next } { print }' "$q/nfd-$h_k" "$q/pf-$h_k"
        cat "$q/dl-$h_k"
    } > "$q/hash/$h_k.in"
    {
        echo "base $base_hash"
        awk 'FILENAME == ARGV[1] { x[$1] = 1; next } !($2 in x) { print }' "$q/nfd-$h_k" "$q/pf-$h_k"
        cat "$q/dl-$h_k"
    } > "$q/dhash/$h_k.in"
    hin < "$q/hash/$h_k.in" > "$q/hash/$h_k"
    hin < "$q/dhash/$h_k.in" > "$q/dhash/$h_k"
    h_n=""
    [ -f "$q/azdep-$h_k" ] && h_n=" ($(cat "$q/azdep-$h_k"))"
    if [ -s "$q/info/$h_k.tools" ]; then
        h_n="$h_n (the official packages of $(LC_ALL=C sort -u "$q/info/$h_k.tools" | tr '\n' ' ' | sed 's/ $//') to build it: AZ_TOOLS_OFFICIAL, not in its hash)"
    fi
    echo "$h_o $(cat "$q/hash/$h_k")$h_n" >> "$res/hashes.txt"
}
# the files of each port, its hash when it needs no az; those that need az (or a port
# that needs it) wait for its manifests ($q/deferred, in the order of the queue)
for o in $(cat "$q/queue.txt"); do
    k="$(key "$o")"
    [ -f "$q/info/$k.bad" ] && continue
    port_files "$o" > "$q/pf-$k"
    # the files of AZ_HASH_NOT_FOR_DEPENDENTS, relative to the tree
    for f in $(sed -n 17p "$q/info/$k"); do
        f="$(realpath "$f" 2> /dev/null)" && tree_file "$f" && echo "${f#"$topr"/}"
    done | LC_ALL=C sort -u > "$q/nfd-$k"
    nfd="$(awk -v d="$o/" 'substr($0, 1, length(d)) == d' "$q/nfd-$k" | tr '\n' ' ')"
    [ -n "$nfd" ] && say "$o: AZ_HASH_NOT_FOR_DEPENDENTS, not in the hash of the ports that need it: $nfd"
    [ -s "$q/info/$k.tools" ] &&
        say "$o: the official packages of $(LC_ALL=C sort -u "$q/info/$k.tools" | tr '\n' ' ' | sed 's/ $//') to build it, not ours (AZ_TOOLS_OFFICIAL)"
    wait_az=0
    for d in $(cat "$q/deps/$k"); do
        if [ "$d" = az/az ] || grep -qxF "$d" "$q/deferred"; then wait_az=1; break; fi
    done
    if [ "$wait_az" = 1 ]; then echo "$o" >> "$q/deferred"; else hash_port "$o"; fi
done

# the packages of the repository before: name origin az_hash file, one per origin: of
# two packages of an origin (the repository of the last run and the files of the
# release, restored together) the newer version stays
: > "$q/repo-all"
for f in "$repo"/*.pkg; do
    [ -f "$f" ] || continue
    catalog "${f##*/}" && continue
    nm="$(pkg query -F "$f" '%n %o %v' 2>/dev/null)"
    if [ -z "$nm" ]; then say "the repository: ${f##*/} is not a package: removed"; rm -f "$f"; continue; fi
    echo "$nm ${f##*/}" >> "$q/repo-all"
done
: > "$q/repo-had"
for og in $(awk '{ print $2 }' "$q/repo-all" | LC_ALL=C sort -u); do
    best=""; bv=""; bn=""
    while read -r n o v f; do
        [ "$o" = "$og" ] || continue
        if [ -z "$best" ]; then best="$f"; bv="$v"; bn="$n"; continue; fi
        if [ "$(pkg version -t "$v" "$bv")" = ">" ]; then
            say "the repository: $best away ($f of $og is newer)"
            rm -f "$repo/$best"; best="$f"; bv="$v"; bn="$n"
        else
            say "the repository: $f away ($best of $og is newer or the same version)"
            rm -f "$repo/$f"
        fi
    done < "$q/repo-all"
    h="$(pkg_hash "$repo/$best")"
    echo "$bn $og ${h:--} $best" >> "$q/repo-had"
done

# the az of the repository (the one the packages kept were built or checked with):
# its manifests in $q/azold, for what changed (az_report)
azold=""
azhad="$(awk '$2 == "az/az" { print $4; exit }' "$q/repo-had")"
if [ -n "$azhad" ] && sh "$top/tools/az-interface.sh" extract "$repo/$azhad" "$q/azold" "$(sed -n 22p "$q/info/az_az" 2>/dev/null)" 2> /dev/null; then
    azold="$repo/$azhad"
fi
# az/az kept: the hashes of the ports that need it with the manifests of its package;
# built in this run: after its build (az_resolve, with the ABI check). A package
# without them (built before 12.11.2026) is built again ($q/nomani-az_az)
azstate=none
azbuilt=0
if grep -qxF az/az "$q/queue.txt" && [ ! -f "$q/info/az_az.bad" ]; then
    azstate=waiting
    hh="$(awk '$2 == "az/az" { print $3; exit }' "$q/repo-had")"
    if [ "$force" = 0 ] && [ -n "$hh" ] && [ "$hh" = "$(cat "$q/hash/az_az" 2>/dev/null)" ]; then
        if [ -n "$azold" ] && az_load "$repo/$azhad"; then
            say "az/az: kept from the repository ($azhad): the interfaces of its $(grep -c -v '^common ' "$q/azif.hashes") libraries for the ports that need it"
        else
            : > "$q/nomani-az_az"
            say "az/az: $azhad of the repository has no manifests of the interfaces of its libraries: built again"
        fi
    fi
fi
# az_resolve: once az/az is done (built, kept, or failed), the manifests of its package,
# the ABI check of the packages kept from the repository that need it (when it was
# built in this run), then the hashes of the ports that wait for it; their official
# packages fetched (a run that builds them)
az_resolve() {
    [ "$azstate" = waiting ] || return 0
    [ -n "$(st az/az)" ] || return 0
    azstate=resolved
    _af="$(cat "$q/file/az_az" 2>/dev/null)"
    case "$(st az/az)" in
        ok|repo) ;;
        *) say "az/az did not build: the ports that need it are not built either"; return 0 ;;
    esac
    if [ -z "$_af" ] || [ ! -f "$_af" ]; then
        # a dry run that would build az: its new interfaces are not known
        say "az/az: no package of this run: the az_hash of the $(wc -l < "$q/deferred" | tr -d ' ') ports that need it is made after its build"
        return 0
    fi
    if [ ! -s "$q/azif.hashes" ] && ! az_load "$_af"; then
        say "warning: $_af has no manifests of the interfaces of its libraries ($(head -n 1 "$q/azif.err")): the ports that need az take the hash of all of az"
    fi
    [ "$(st az/az)" = ok ] && azbuilt=1
    [ "$azbuilt" = 1 ] && az_abi "$_af"
    for _ro in $(cat "$q/deferred"); do hash_port "$_ro"; done
    say "the az_hash of the $(wc -l < "$q/deferred" | tr -d ' ') ports that need az: made with the interfaces of $(grep -c -v '^common ' "$q/azif.hashes") libraries (results/hashes.txt)"
    if [ "$dryrun" = 0 ] && [ "$plan" = 0 ]; then
        # shellcheck disable=SC2046
        prefetch $(cat "$q/deferred")
    fi
    return 0
}
# az_abi <new package of az>: the packages of the repository (but az) checked against
# it (tools/az-abi-check.sh: each SONAME of az they need is there, each symbol they bind
# from az is defined there); one that fails is built again in this run when it is in
# the queue ($q/abifail/<key>, its why), and goes from the repository at the end when it
# is not built (results/abi-check.txt). No az in the repository before: nothing to
# compare with, so every package kept that needs az is built again
az_abi() {
    awk '$2 != "az/az" { print $2, $4 }' "$q/repo-had" > "$q/abi-pkgs"
    if [ -z "$azhad" ] || [ ! -f "$repo/$azhad" ]; then
        echo "no az in the repository before this run: the packages kept that need az are built again" > "$res/abi-check.txt"
        while read -r _ao _af; do
            pkg query -F "$repo/$_af" '%B' 2> /dev/null | grep -qxF -f "$q/azif.sonames.names" 2> /dev/null || continue
            echo "no az in the repository before this run to compare with" > "$q/abifail/$(key "$_ao")"
        done < "$q/abi-pkgs"
        say "the ABI check: no az in the repository before this run: $(ls "$q/abifail" | wc -l | tr -d ' ') packages kept that need az are built again"
        return 0
    fi
    _t0="$(date +%s)"
    # shellcheck disable=SC2046
    AZ_PREFIX="$(sed -n 22p "$q/info/az_az")" sh "$top/tools/az-abi-check.sh" "$repo/$azhad" "$1" "$work/abi" \
        $(awk -v r="$repo" '{ print r "/" $2 }' "$q/abi-pkgs") > "$res/abi-check.txt" 2>&1
    _arc=$?
    _nf=0
    while read -r _w _p _why; do
        [ "$_w" = fail ] || continue
        _ao="$(awk -v f="${_p##*/}" '$2 == f { print $1; exit }' "$q/abi-pkgs")"
        [ -n "$_ao" ] || continue
        echo "$_why" > "$q/abifail/$(key "$_ao")"
        _nf=$((_nf + 1))
    done < "$res/abi-check.txt"
    _nc="$(grep -c -E '^(ok|fail) ' "$res/abi-check.txt")"
    if [ "$_arc" = 2 ]; then
        say "warning: the ABI check could not compare the two builds of az ($(tail -n 1 "$res/abi-check.txt")): the packages kept that need az are built again"
        while read -r _ao _af; do
            pkg query -F "$repo/$_af" '%B' 2> /dev/null | grep -qxF -f "$q/azif.sonames.names" 2> /dev/null || continue
            echo "the ABI check could not compare the two builds of az" > "$q/abifail/$(key "$_ao")"
        done < "$q/abi-pkgs"
    else
        say "the ABI check: $_nc packages of the repository that need az against the new az in $(( $(date +%s) - _t0 ))s, $_nf failed (results/abi-check.txt; $(head -n 1 "$res/abi-check.txt" | cut -c1-160))"
    fi
}
# az_cover_check <origin> <package>: the libraries of az the package needs (the
# SONAMEs pkg recorded, shlibs_required) that its az_hash does not cover
# ($q/azcov/<key>): said (the text for the line of the summary), into $q/uncov/<key>;
# the run fails on them (AZ_HASH_LIBS of the port is short)
az_cover_check() {
    [ -s "$q/azif.sonames" ] || return 0
    _ck="$(key "$1")"
    _m="$(pkg query -F "$2" '%B' 2> /dev/null | awk 'NR == FNR { s[$1] = $2; next } ($1 in s) { print s[$1] }' "$q/azif.sonames" - |
        LC_ALL=C sort -u | while read -r _cl; do grep -qxF "$_cl" "$q/azcov/$_ck" 2> /dev/null || echo "$_cl"; done | tr '\n' ' ' | sed 's/ $//')"
    [ -n "$_m" ] || return 0
    echo "$1: its package links $_m of az, which its az_hash does not take: AZ_HASH_LIBS of its Makefile" > "$q/uncov/$_ck"
    printf '; warning: links %s of az, not in its az_hash (AZ_HASH_LIBS)' "$_m"
}

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
    echo "queue:    $(wc -l < "$q/queue.txt" | tr -d ' ') ports$( [ "$force" = 1 ] && echo ', --force')$( [ "$serial" = 0 ] && echo ", AZ_JOBS=$jobs")$( [ "$dryrun" = 1 ] && echo ', AZ_DRYRUN')$( [ "$plan" = 1 ] && echo ', AZ_PLAN: az/az and the ports it needs built, the others only decided')$( [ "$ccheck" = 1 ] && echo ', AZ_CONFIGURE_CHECK')"
} > "$sum"

# --- the builds ------------------------------------------------------------------------
# a line of the summary and the state of a port: ok (built), repo (in the repository
# already), fail, skip (needs a port that failed), plan (AZ_PLAN: to be built, not
# built); with AZ_JOBS above 1 the line goes
# into $q/sum/<key> first and the summary takes the lines in the order of the queue
record() {
    _o="$1"; _s="$2"; shift 2
    echo "$_s" > "$q/state/$(key "$_o")"
    case "$_s" in
        ok) _w=OK ;;
        fail) _w=FAIL ;;
        plan) _w=PLAN ;;
        *) _w=SKIP ;;
    esac
    if [ "$serial" = 1 ]; then
        printf '%-34s %-4s %s\n' "$_o" "$_w" "$*" >> "$sum"
    else
        printf '%-34s %-4s %s\n' "$_o" "$_w" "$*" > "$q/sum/$(key "$_o")"
    fi
    say "$_o: $_w $*"
}

# pre_port <origin>: what is to be done with a port, before its dependencies: 1 when
# that is said already (the line of the summary: it failed, is skipped, its package
# with the same az_hash is in the repository, or AZ_PLAN: it is to be built, not
# built), 0 when it is to be built (k, log, pn, ign, h, hs, had set; asked again it
# says nothing more). A package with the same az_hash that failed the ABI check against
# the az built in this run ($q/abifail/<key>) is built again; one kept has its
# libraries of az checked against its hash (az_cover_check)
pre_port() {
    k="$(key "$1")"
    log="$res/logs/$k.log"
    pn="$(sed -n 1p "$q/info/$k" 2>/dev/null)"
    ign="$(sed -n 2p "$q/info/$k" 2>/dev/null)"
    h="$(cat "$q/hash/$k" 2>/dev/null)"
    hs="$(printf '%s' "$h" | cut -c1-12)"
    had="$(awk -v o="$1" '$2 == o { print $3, $4; exit }' "$q/repo-had")"
    [ -f "$q/tobuild-$k" ] && return 0
    # az/az done: the hashes of the ports that need it first (once; never in a job)
    if [ "$azstate" = waiting ]; then
        az_resolve
        h="$(cat "$q/hash/$k" 2>/dev/null)"
        hs="$(printf '%s' "$h" | cut -c1-12)"
    fi
    : > "$log"
    if [ -f "$q/info/$k.bad" ]; then record "$1" fail "$(cat "$q/info/$k.bad")"; return 1; fi
    # the ports of this tree it needs: failed, or skipped for that
    bad=""
    for d in $(cat "$q/deps/$k"); do
        case "$(st "$d")" in fail|skip) bad="$bad $d" ;; esac
    done
    if [ -n "$bad" ]; then record "$1" skip "$pn: needs$bad, which failed or was skipped"; return 1; fi
    if [ -n "$ign" ]; then record "$1" fail "$pn: the port says IGNORE: $ign"; return 1; fi
    # no az_hash: it needs az, and az is not built in this dry run (its interfaces decide)
    if [ -z "$h" ]; then
        if [ "$dryrun" = 1 ]; then
            record "$1" ok "$pn: dry run: its az_hash is made after az/az is built (the interfaces of the new az; AZ_PLAN builds az and decides)"
        else
            record "$1" fail "$pn: no az_hash (it needs az/az, and the interfaces of az are not there)"
        fi
        return 1
    fi
    abi="$(cat "$q/abifail/$k" 2>/dev/null)"
    # its package in the repository: the same az_hash, another one, none
    if [ -n "$had" ] && [ "${had%% *}" = "$h" ] && [ "$force" = 0 ] && [ -z "$abi" ] && [ ! -f "$q/nomani-$k" ]; then
        echo "$repo/${had#* }" > "$q/file/$k"
        ki=""
        [ "$azbuilt" = 1 ] && [ -s "$q/azcov/$k" ] && ki="; kept by the interfaces of az, which this run built again" && echo "$1" >> "$q/kept-if"
        record "$1" repo "${had#* }: in the repository already with the same az_hash $hs$ki$(az_cover_check "$1" "$repo/${had#* }")"
        return 1
    fi
    if [ "$force" = 1 ]; then why="--force"
    elif [ -n "$abi" ]; then why="${had#* } fails the ABI check against the new az: $abi"
    elif [ -f "$q/nomani-$k" ]; then why="${had#* } in the repository has no manifests of the interfaces of its libraries"
    elif [ -z "$had" ]; then why="no package of $1 in the repository"
    elif [ "${had%% *}" = - ]; then why="${had#* } in the repository has no az_hash"
    else why="az_hash $hs, not $(printf '%s' "${had%% *}" | cut -c1-12) of ${had#* } in the repository"
    fi
    # AZ_PLAN: only az/az and the ports it needs are built; the libraries of az the
    # package of the repository links checked against the new hash (the same build)
    if [ "$plan" = 1 ] && ! grep -qxF "$1" "$q/azpre"; then
        record "$1" plan "$pn: to be built, az_hash $hs ($why)$( [ -n "$had" ] && az_cover_check "$1" "$repo/${had#* }")"
        return 1
    fi
    say "$1: $pn ($why)"
    : > "$q/tobuild-$k"
    return 0
}

# ch_init: what the chroots of the run share (not for a dry run): the copy of /etc
# (without /etc/ssh: the host keys of the machine are of no build), pkg.conf and the
# repositories of /usr/local/etc/pkg/repos but ours (az, azbuild: in a chroot pkg
# install takes the official packages only), the catalogs of the machine updated once
# in a chroot (work/ch-repos: the chroots of the run read them, pkg -U), and the
# official packages of the ports the run may build fetched into the cache of pkg, so
# that the builds download nothing of pkg (results/logs/chroots.log)
ch_init() {
    case "$(pkg -v 2>/dev/null)" in
        [2-9].* | [1-9][0-9].*) ;;
        *) die "pkg $(pkg -v 2>/dev/null): the chroots need pkg 2 or later (the catalogs in $pkgdb/repos)" ;;
    esac
    _cl="$res/logs/chroots.log"
    : > "$_cl"
    rm -rf "$work/ch-etc" "$work/ch-local" "$work/ch-repos" "$work/pk"
    mkdir -p "$chd" "$work/ch-etc" "$work/ch-repos" "$pkgcache" || die "cannot make the directories of the chroots in $work"
    (cd /etc && tar -cf - --exclude ./ssh .) | (cd "$work/ch-etc" && tar -xpf -)
    [ -f "$work/ch-etc/rc.subr" ] || die "cannot copy /etc into $work/ch-etc"
    if [ -f /usr/local/etc/pkg.conf ] || [ -d /usr/local/etc/pkg/repos ]; then
        mkdir -p "$work/ch-local/pkg/repos"
        [ -f /usr/local/etc/pkg.conf ] && cp -p /usr/local/etc/pkg.conf "$work/ch-local/"
        for _f in /usr/local/etc/pkg/repos/*.conf; do
            [ -f "$_f" ] || continue
            if grep -q -E '^[[:space:]]*"?(az|azbuild)"?[[:space:]]*:|azsupport/ports' "$_f"; then
                say "the chroots: without $_f (a repository of ours: the official packages only)"
                continue
            fi
            cp -p "$_f" "$work/ch-local/pkg/repos/"
        done
    fi
    if [ -d "$pkgdb/repos" ]; then (cd "$pkgdb/repos" && tar -cf - .) | (cd "$work/ch-repos" && tar -xpf -); fi
    _t0="$(date +%s)"
    ch_up _setup || die "no chroot for the run: $why"
    say "a chroot in $(( $(date +%s) - _t0 ))s: $ch_base read only, a copy of /etc, devfs$( [ "$ch_fdesc" = 1 ] && echo ', fdescfs')$( [ "$ch_proc" = 1 ] && echo ', procfs'), this tree, the official tree, packages/ and the repository read only (the chroot of each port the same)"
    {
        echo "== the mounts of a chroot ($c):"
        ch_mounts "$c" | sort
        echo "== pkg update (the catalogs of the run, work/ch-repos)"
    } >> "$_cl"
    if pkg -c "$c" update >> "$_cl" 2>&1; then
        say "the catalogs of the run: pkg update in a chroot ($(tail -n 1 "$_cl" | cut -c1-120))"
    else
        say "warning: pkg update in a chroot failed (results/logs/chroots.log): the catalogs of the machine as they are"
    fi
    # the official packages of the ports the run may build (those whose az_hash is made:
    # the ports that need az when az is built in this run come after its build)
    # shellcheck disable=SC2046
    pf_fetch $(cat "$q/queue.txt")
    ch_down "$c" || die "the chroot $c could not be torn down"
    rm -rf "$q/ch/_setup" "$work/pk/_setup"
}
# pf_fetch <origin>...: the official packages of those of the ports the run may build
# (no package with the same az_hash in the repository, or --force, or the ABI check
# failed; make -V worked, no IGNORE, its az_hash made; AZ_PLAN: az/az and the ports it
# needs) fetched into the cache of pkg in the chroot $c (results/logs/chroots.log)
pf_fetch() {
    _cl="$res/logs/chroots.log"
    : > "$q/prefetch"
    _np=0
    for _o in "$@"; do
        _k="$(key "$_o")"
        [ -f "$q/info/$_k.bad" ] && continue
        [ -n "$(sed -n 2p "$q/info/$_k")" ] && continue
        [ -s "$q/hash/$_k" ] || continue
        if [ "$plan" = 1 ] && ! grep -qxF "$_o" "$q/azpre"; then continue; fi
        _hh="$(awk -v o="$_o" '$2 == o { print $3; exit }' "$q/repo-had")"
        [ "$force" = 0 ] && [ "$_hh" = "$(cat "$q/hash/$_k")" ] && [ ! -f "$q/abifail/$_k" ] && [ ! -f "$q/nomani-$_k" ] && continue
        dep_lists "$_o"
        _np=$((_np + 1))
        for _p in $(cat "$q/dl/$_k.off"); do echo "$_p"; done >> "$q/prefetch"
    done
    _want="$(grep . "$q/prefetch" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
    [ -n "$_want" ] || return 0
    _t0="$(date +%s)"
    echo "== pkg fetch -d of the official packages of the $_np ports the run may build: $_want" >> "$_cl"
    # shellcheck disable=SC2086
    if pkg -c "$c" fetch -y -d -U $_want >> "$_cl" 2>&1; then
        say "the official packages of the $_np ports the run may build ($(echo $_want | wc -w | tr -d ' ') and their dependencies): in the cache of pkg in $(( $(date +%s) - _t0 ))s"
    else
        say "warning: pkg fetch of the official packages of the run failed (results/logs/chroots.log: $(grep -i -E 'error|fail|no packages' "$_cl" | tail -n 1 | cut -c1-160)): each chroot fetches its own"
    fi
}
# prefetch <origin>...: pf_fetch in a chroot of its own (the ports that need az, after
# the build of az: their hashes are made then)
prefetch() {
    [ $# -gt 0 ] || return 0
    c="$chd/_pf"; cs="$q/ch/_pf"
    if ! ch_up _pf; then
        say "warning: no chroot to fetch the official packages of the ports that need az ($why): each chroot fetches its own"
    else
        pf_fetch "$@"
    fi
    ch_down "$c" || say "warning: the chroot $c could not be torn down"
    rm -rf "$q/ch/_pf" "$work/pk/_pf"
}

# job_port <origin>: a port built in a chroot of its own, after pre_port said it is to be
# built: its chroot (ch_up), its dependencies there (ch_deps), make package (make_port),
# then the chroot away (ch_down), whatever the result; the times of the chroot ($chs),
# of the dependencies ($dps) in the line of the summary, with that of the teardown in
# $q/chtime/<key>
job_port() {
    pre_port "$1"
    chs=0; dps=0
    _jt0="$(date +%s)"
    why=""; c="$chd/$k"; cs="$q/ch/$k"
    if ! { rm -rf "$work/pk/$k" && mkdir -p "$work/pk/$k/All"; } || ! ch_up "$k"; then
        record "$1" fail "$pn: no chroot ($chd/$k): ${why:-cannot make $work/pk/$k}"
    else
        _jt1="$(date +%s)"; chs=$((_jt1 - _jt0))
        echo "== the chroot $c in ${chs}s" >> "$log"
        if ch_deps "$1"; then
            dps=$(( $(date +%s) - _jt1 ))
            echo "== the dependencies in the chroot in ${dps}s" >> "$log"
            make_port "$1" "$work/pk/$k"
        fi
    fi
    _jt2="$(date +%s)"
    if [ -n "$c" ] && ! ch_down "$c" >> "$log" 2>&1; then
        say "$1: its chroot $c could not be torn down (logs/$k.log)"
    fi
    echo "$chs $dps $(( $(date +%s) - _jt2 ))" > "$q/chtime/$k"
    echo "== the chroot away in $(( $(date +%s) - _jt2 ))s" >> "$log"
    rm -rf "$q/ch/$k" "$work/pk/$k"
}

# --- the configure check (AZ_CONFIGURE_CHECK=1) -----------------------------------------
# php_port <origin>: a port of PHP: a core lang/phpXY, mod_phpXY, a module phpXY-*
php_port() {
    case "$1" in lang/php[0-9][0-9]|www/mod_php[0-9][0-9]|*/php[0-9][0-9]-*) return 0 ;; esac
    return 1
}
# cc_flags <cc>: the permissive flags the compiler takes (tools/configure-check.sh
# probe in the chroot of the port: the compiler may be one of its packages), once for
# each compiler of the run ($q/ccflags-*, written whole: the builds of a wave ask at
# once; none, a compiler not there, is not kept)
cc_flags() {
    _cf="$q/ccflags-$(printf '%s' "$1" | tr -c 'A-Za-z0-9' '_')"
    if [ ! -s "$_cf" ]; then
        ch_run sh "$top/tools/configure-check.sh" probe "$1" 2> /dev/null | grep . > "$_cf.$k"
        if [ -s "$_cf.$k" ]; then
            printf '%s\n' "$1" > "$_cf.cc.$k" && mv -f "$_cf.cc.$k" "$_cf.cc"
            mv -f "$_cf.$k" "$_cf"
        else
            rm -f "$_cf.$k"
            return 0
        fi
    fi
    cat "$_cf"
}
# cc_check <origin>: after the build of a PHP port and its make clean (the results
# of its configure saved before by make_port into $work/cc/<key>/strict): make
# configure once more in its chroot, in the WRKDIRPREFIX $work/ccw/<key> (read-write
# there), with the permissive flags of its compiler in CFLAGS_<arch> (appended to its
# CFLAGS by bsd.port.mk; what the port has in that variable stays first), the results
# saved, compared (results/configure-check/<key>.txt, its exit status in <key>.rc; the
# two config.log files there too when they differ), then away with both
cc_check() {
    _cd="$work/cc/$k"; _pw="$work/ccw/$k"
    mkdir -p "$res/configure-check"
    if [ -f "$_cd/strict/config.log" ]; then
        rm -rf "$_pw"
        # (the last one an expression of make, not of the shell)
        # shellcheck disable=SC2016
        ch_run make -C "$top/$1" WRKDIRPREFIX="$_pw" -V WRKDIR -V CONFIGURE_WRKSRC -V CC -V ARCH \
            -V '${CFLAGS_${ARCH}}' > "$_cd/vars" 2> /dev/null
        _pwd="$(sed -n 1p "$_cd/vars")"; _pcw="$(sed -n 2p "$_cd/vars")"; _cc="$(sed -n 3p "$_cd/vars")"
        _arch="$(sed -n 4p "$_cd/vars")"; _own="$(sed -n 5p "$_cd/vars")"
        _fl=""
        [ -n "$_cc" ] && _fl="$(cc_flags "$_cc")"
        if [ -z "$_pwd" ] || [ -z "$_arch" ] || [ -z "$_fl" ]; then
            mkdir -p "$_cd/permissive"
            echo "no permissive configure: make -V WRKDIR, CC, ARCH gave '${_pwd}', '${_cc}', '${_arch}'; the flags $_cc takes: '${_fl}'" > "$_cd/permissive/none"
        else
            say "$1: the configure check: make configure again, permissive ($_cc: $_fl)"
            ch_run make -C "$top/$1" configure USE_PACKAGE_DEPENDS_ONLY=yes AZ_STAMP="$az_stamp" AZ_HASH="$h" \
                WRKDIRPREFIX="$_pw" "CFLAGS_$_arch=${_own:+$_own }$_fl" > "$_cd/permissive.log" 2>&1
            _prc=$?
            # the work directories of the chroot are those of the machine at the same paths
            sh "$top/tools/configure-check.sh" save "$_cd/permissive" "$_pwd" "$_pcw" "$_cc" "$_fl"
            # make configure failed before configure ran: its last lines say why
            if [ -f "$_cd/permissive/none" ]; then
                echo "make configure: exit $_prc: $(grep . "$_cd/permissive.log" | tail -n 2 | tr '\n' ' ' | cut -c1-300)" >> "$_cd/permissive/none"
            fi
            ch_run make -C "$top/$1" WRKDIRPREFIX="$_pw" clean > /dev/null 2>&1
            rm -rf "$_pw"
        fi
    fi
    sh "$top/tools/configure-check.sh" compare "$1 ($pn)" "$_cd/strict" "$_cd/permissive" > "$res/configure-check/$k.txt"
    _crc=$?
    echo "$_crc" > "$res/configure-check/$k.rc"
    if [ "$_crc" = 1 ]; then
        cp "$_cd/strict/config.log" "$res/configure-check/$k.strict.config.log" 2> /dev/null
        cp "$_cd/permissive/config.log" "$res/configure-check/$k.permissive.config.log" 2> /dev/null
    fi
    rm -rf "$_cd"
    case "$_crc" in
        0) _cw="the same" ;;
        1) _cw="$(sed -n '1s/^== [^:]*: //p' "$res/configure-check/$k.txt" | cut -c1-120)" ;;
        *) _cw="not compared" ;;
    esac
    say "$1: the configure check: $_cw (results/configure-check/$k.txt)"
    echo "configure check: $_cw" >> "$log"
}

# make_port <origin> <packages>: make clean package of a port in its chroot $c, its
# result said (the line of the summary, with the times of its chroot and of its
# dependencies, $chs and $dps); the build writes its packages into <packages>/All
# (read-write in the chroot), moved into packages/All after it (each build its own:
# the files a build made are those, whatever builds at the same time). The work
# directory of the build is that of the machine at the same path (WRKDIRPREFIX is
# mounted there), its files read from the machine
make_port() {
    _pk="$2"
    rm -f "$packages/All/$pn.pkg"
    # the distfiles one build at a time (lockf on the machine): the ports of a wave may
    # share one (the tarball of PHP of the modules), and two fetches of it at once
    # break it; what fails here make package says again
    ch_run -l "$q/fetch.lock" make -C "$top/$1" checksum USE_PACKAGE_DEPENDS_ONLY=yes \
        AZ_STAMP="$az_stamp" AZ_HASH="$h" >> "$log" 2>&1
    start="$(date +%s)"
    # AZ_RESULTS: the results of the scripts of tools/ (az/az: the line of each library)
    # in results/az-results/<key>, where they stay after make clean
    ch_run make -C "$top/$1" clean package USE_PACKAGE_DEPENDS_ONLY=yes AZ_STAMP="$az_stamp" AZ_HASH="$h" \
        AZ_RESULTS="$res/az-results/$k" PACKAGES="$_pk" >> "$log" 2>&1
    rc=$?
    secs=$(( $(date +%s) - start ))
    cht="(chroot ${chs}s, dependencies ${dps}s)"
    cck=0
    [ "$ccheck" = 1 ] && php_port "$1" && cck=1
    wd=""
    if [ "$rc" != 0 ] || [ "$cck" = 1 ]; then
        ch_run make -C "$top/$1" -V WRKDIR -V CONFIGURE_WRKSRC -V CC > "$q/wd-$k" 2> /dev/null
        wd="$(sed -n 1p "$q/wd-$k")"
    fi
    # the config.log files of a failed build next to its log (that of a module is in
    # <WRKDIR>/<distname>/ext/<module>), then the work directory away
    if [ "$rc" != 0 ] && [ -n "$wd" ]; then
        n=0
        for cl in $(find "$wd" -maxdepth 4 -name config.log 2>/dev/null); do
            n=$((n + 1)); cp "$cl" "$res/logs/$k.config-$n.log"
        done
    fi
    # the configure check: what the configure of the build found, before make clean
    if [ "$cck" = 1 ]; then
        sh "$top/tools/configure-check.sh" save "$work/cc/$k/strict" "$wd" "$(sed -n 2p "$q/wd-$k")" "$(sed -n 3p "$q/wd-$k")"
    fi
    ch_run make -C "$top/$1" clean > /dev/null 2>&1
    [ "$cck" = 1 ] && cc_check "$1"
    # the packages of the build into packages/All
    if [ "$rc" = 0 ] && [ -f "$_pk/All/$pn.pkg" ]; then
        : > "$q/made-$k"
        for f in "$_pk"/All/*.pkg; do
            [ -f "$f" ] || continue
            mv -f "$f" "$packages/All/" && echo "$packages/All/${f##*/}" >> "$q/made-$k"
        done
    fi
    if [ "$rc" != 0 ] || [ ! -f "$packages/All/$pn.pkg" ]; then
        rm -f "$q/made-$k"
        e="$(grep -E ' error:|Error code|^\*\*\*|^===>.*(IGNORE|not found|failed)' "$log" | head -n 1 | cut -c1-200)"
        [ "$rc" = 0 ] && e="make package made no $pn.pkg"
        # a file of a dependency that is not there: the files of its directory by that
        # name in the chroot, and the package there that says it has it (at the end of
        # the log, so that the report shows it)
        grep -o 'depends on file: [^ ]* - not found' "$log" | awk '{ print $4 }' | sort -u |
            while read -r nf; do
                {
                    echo "== $nf is not there; in ${nf%/*} of the chroot:"
                    _b="${nf##*/}"
                    ls -la "$c${nf%/*}" 2>&1 | grep -F "${_b%.so}" | head -n 10
                    echo "== pkg which $nf in the chroot: $(pkg -c "$c" which "$nf" 2>&1 | head -n 1)"
                } >> "$log"
            done
        say "$1: make package failed, the last 40 lines of logs/$k.log:"
        tail -n 40 "$log" | sed 's/^/    | /'
        record "$1" fail "$pn: ${secs}s $cht, ${e:-make package failed} (logs/$k.log)"
        return 1
    fi
    f="$packages/All/$pn.pkg"
    echo "$f" > "$q/file/$k"
    grep -qxF "$f" "$q/made-$k" || echo "$f" >> "$q/made-$k"
    note=""
    [ "$(pkg_hash "$f")" = "$h" ] ||
        note="; warning: no annotation az_hash $hs in the package (PKG_NOTES of Mk/bsd.overlay.mk): the next run builds it again"
    note="$note$(az_cover_check "$1" "$f")"
    case "$pn" in
        *_"$az_stamp"|*_"$az_stamp",*) ;;
        *) note="$note; warning: the version has not the revision $az_stamp (PORTREVISION= \${AZ_STAMP}): no upgrade for pkg" ;;
    esac
    record "$1" ok "$pn: ${secs}s $cht, $(( $(wc -c < "$f") / 1024 )) KB, az_hash $hs$note"
    return 0
}

# AZ_PLAN: az/az and the ports of this tree it needs, the ports it builds
: > "$q/azpre"
if [ "$plan" = 1 ] && grep -qxF az/az "$q/queue.txt"; then
    echo az/az > "$q/azpre"
    cp "$q/azpre" "$q/azpre.new"
    while [ -s "$q/azpre.new" ]; do
        for o in $(cat "$q/azpre.new"); do cat "$q/deps/$(key "$o")"; done | LC_ALL=C sort -u | grep -vxF -f "$q/azpre" > "$q/azpre.next" || :
        cat "$q/azpre.next" >> "$q/azpre"
        mv "$q/azpre.next" "$q/azpre.new"
    done
    say "AZ_PLAN: built when they are to be: $(tr '\n' ' ' < "$q/azpre" | sed 's/ $//'); the other ports only decided"
fi
: > "$q/kept-if"
# the chroots share what ch_init makes (not for a dry run)
[ "$dryrun" = 1 ] || ch_init
if [ "$serial" = 1 ]; then
    # one port after another, in the order of the queue, each in its chroot (the ports
    # that need az have their az_hash once az/az is done: az_resolve)
    for o in $(cat "$q/queue.txt"); do
        az_resolve
        pre_port "$o" || continue
        dep_lists "$o"
        say "$o: make package (logs/$k.log)"
        job_port "$o"
    done
else
    # Waves (AZ_JOBS above 1, or AZ_DRYRUN): the ports whose ports of this tree they
    # need are done (built, kept, failed or skipped) form a wave, in the order of
    # the queue; up to AZ_JOBS of them at once, each in a chroot of its own with only
    # its own dependencies (so that the ports of a wave never take each other's
    # packages away: one of a pair with the same files, phpXY-mysqlnd and
    # phpXY-mysqlnd-openssl, goes beside the other; az/az, NEED_ROOT, as any port, into
    # the /usr/local/az of its chroot), each with its log and its own packages
    # directory; its screen output said when it ends.
    mkdir -p "$q/sum" "$q/jobs"
    : > "$res/waves.txt"
    wave=0
    # the waves of a stage only, the stages one after another
    stage=1
    cp "$q/stage-1.txt" "$q/stage.txt"
    [ "$nst" = 1 ] || say "stage 1 of $nst: $(wc -l < "$q/stage.txt" | tr -d ' ') ports"
    while :; do
        # az/az done: the hashes of the ports that need it (none of them is ready before)
        az_resolve
        # the ports that are ready, those that need no build said at once (the next
        # ones may be ready then)
        : > "$q/cand"
        more=1
        while [ "$more" = 1 ]; do
            more=0
            : > "$q/cand"
            for o in $(cat "$q/stage.txt"); do
                [ -n "$(st "$o")" ] && continue
                ready=1
                for d in $(cat "$q/deps/$(key "$o")"); do
                    [ -n "$(st "$d")" ] || { ready=0; break; }
                done
                [ "$ready" = 1 ] || continue
                if pre_port "$o"; then echo "$o" >> "$q/cand"; else more=1; fi
            done
        done
        if [ ! -s "$q/cand" ]; then
            # nothing ready: the stage is done (the next one), or a loop in the
            # dependencies (the first port left in the order of the queue, as with
            # AZ_JOBS=1)
            o="$(for o in $(cat "$q/stage.txt"); do [ -z "$(st "$o")" ] && { echo "$o"; break; }; done)"
            if [ -z "$o" ]; then
                stage=$((stage + 1))
                [ "$stage" -le "$nst" ] || break
                cp "$q/stage-$stage.txt" "$q/stage.txt"
                say "stage $stage of $nst: $(wc -l < "$q/stage.txt" | tr -d ' ') ports"
                continue
            fi
            pre_port "$o" || continue
            echo "$o" > "$q/cand"
        fi
        wave=$((wave + 1))
        cp "$q/cand" "$q/wave"
        say "wave $wave: $(wc -l < "$q/wave" | tr -d ' ') ports, up to $jobs at once: $(tr '\n' ' ' < "$q/wave")"
        echo "wave $wave: $(tr '\n' ' ' < "$q/wave" | sed 's/ $//')" >> "$res/waves.txt"
        if [ "$dryrun" = 1 ]; then
            for o in $(cat "$q/wave"); do pre_port "$o"; record "$o" ok "$pn: dry run, not built"; done
            continue
        fi
        # up to $jobs builds at once, the biggest first (by the size of its package in
        # the repository: the longer builds; those without one after them, in the
        # order of the queue); each writes $q/jobs/<key>.done when it ends
        for o in $(cat "$q/wave"); do
            pre_port "$o"
            sz=0
            [ -n "$had" ] && [ -f "$repo/${had#* }" ] && sz="$(wc -c < "$repo/${had#* }" | tr -d ' ')"
            echo "$sz $o"
        done | sort -s -k1,1nr | awk '{ print $2 }' > "$q/wave.order"
        running=0
        for o in $(cat "$q/wave.order") ''; do
            while [ "$running" -ge "$jobs" ] || { [ -z "$o" ] && [ "$running" -gt 0 ]; }; do
                for dn in "$q"/jobs/*.done; do
                    [ -f "$dn" ] || continue
                    jk="${dn##*/}"; jk="${jk%.done}"
                    wait "$(cat "$q/jobs/$jk.pid")" 2> /dev/null
                    cat "$q/jobs/$jk.out"
                    rm -f "$dn" "$q/jobs/$jk.pid" "$q/jobs/$jk.out"
                    running=$((running - 1))
                done
                [ "$running" -ge "$jobs" ] || { [ -z "$o" ] && [ "$running" -gt 0 ]; } || break
                sleep 1
            done
            [ -n "$o" ] || break
            pre_port "$o"
            # what it gets in its chroot, worked out here (not in the jobs beside it)
            dep_lists "$o"
            say "$o: make package (logs/$k.log)"
            # .done after the subshell of the build, also if it ends early: the loop
            # above would otherwise wait for it until the timeout of the job; the traps
            # of the run (all chroots away) are not those of a job
            ( trap - EXIT HUP INT TERM; ( job_port "$o" ) > "$q/jobs/$k.out" 2>&1; : > "$q/jobs/$k.done" ) &
            echo $! > "$q/jobs/$k.pid"
            running=$((running + 1))
        done
    done
    # the summary in the order of the queue
    for o in $(cat "$q/queue.txt"); do cat "$q/sum/$(key "$o")" 2> /dev/null; done >> "$sum"
fi
# the chroots of the run: the time of their set-up, of the dependencies in them and of
# their teardown, in all and at most
if [ -n "$(ls "$q/chtime" 2> /dev/null)" ]; then
    cat "$q"/chtime/* | awk '{ n++; s += $1; d += $2; t += $3; if ($1 > ms) ms = $1; if ($2 > md) md = $2; if ($3 > mt) mt = $3 }
        END { printf "chroots:  %d ports, each in a chroot of its own: set up in %ds in all (at most %ds), their dependencies installed in %ds (at most %ds), torn down in %ds (at most %ds)\n", n, s, ms, d, md, t, mt }' >> "$sum"
fi

# the configure check: results/configure-check.txt, the PHP ports of the queue in
# its order: those with differences (each with its checks and their diagnostics),
# those not compared, those the same, those not configured in this run (kept from
# the repository, failed or skipped before their configure); a line in the summary
if [ "$ccheck" = 1 ] && [ "$dryrun" = 0 ]; then
    cr="$res/configure-check"
    mkdir -p "$cr"
    : > "$q/cc.diff"; : > "$q/cc.not"; : > "$q/cc.same"; : > "$q/cc.none"
    while read -r o; do
        php_port "$o" || continue
        k="$(key "$o")"
        case "$(cat "$cr/$k.rc" 2> /dev/null)" in
            0) echo "$o" >> "$q/cc.same" ;;
            1) echo "$o" >> "$q/cc.diff" ;;
            2) echo "$o" >> "$q/cc.not" ;;
            *)
                case "$(st "$o")" in
                    repo) w="kept from the repository" ;;
                    skip) w="not built: it needs a port that failed" ;;
                    fail) w="failed before its build" ;;
                    *) w="no result of the check" ;;
                esac
                echo "$o ($w)" >> "$q/cc.none" ;;
        esac
    done < "$q/queue.txt"
    ndiff="$(grep -c . "$q/cc.diff")"; nnot="$(grep -c . "$q/cc.not")"
    nsame="$(grep -c . "$q/cc.same")"; nnone="$(grep -c . "$q/cc.none")"
    {
        echo "The configure check (AZ_CONFIGURE_CHECK=1, tools/configure-check.sh): each PHP port"
        echo "configured in this run configured once more after its build, with the same compiler"
        echo "and the errors of C of GCC 14+ and clang 16+ as warnings (permissive), and compared"
        echo "with the configure of its build (strict): the result of each \"checking\" of config.log,"
        echo "the header (main/php_config.h, config.h of a module), the variables of the Makefile."
        echo "A difference is a test whose result depends on those errors; the package has the"
        echo "strict one. The diagnostic: the errors in the config.log of the failed test."
        echo
        for f in "$q"/ccflags-*; do
            case "$f" in *.cc|*.cc.*) continue ;; esac
            [ -f "$f" ] && echo "permissive flags of $(cat "$f.cc" 2> /dev/null): $(cat "$f")"
        done
        echo "PHP ports: $((ndiff + nnot + nsame)) configured, $ndiff with differences, $nsame the same, $nnot not compared; $nnone not configured in this run"
        [ "$ndiff" -gt 0 ] && echo "with differences: $(tr '\n' ' ' < "$q/cc.diff" | sed 's/ $//')"
        while read -r o; do
            echo
            cat "$cr/$(key "$o").txt"
        done < "$q/cc.diff"
        if [ "$nnot" -gt 0 ]; then
            echo
            echo "not compared:"
            while read -r o; do sed 's/^== /  /' "$cr/$(key "$o").txt"; done < "$q/cc.not"
        fi
        if [ "$nsame" -gt 0 ]; then
            echo
            echo "the same:"
            tr '\n' ' ' < "$q/cc.same" | sed 's/ $//' | fold -s -w 100 | sed 's/^/  /; s/ *$//'
        fi
        if [ "$nnone" -gt 0 ]; then
            echo
            echo "not configured in this run (kept from the repository, or failed or skipped before configure; force: every port):"
            sed 's/^/  /' "$q/cc.none"
        fi
    } > "$res/configure-check.txt"
    # the ports with differences in the summary, ten at most
    dl=""
    if [ "$ndiff" -gt 0 ]; then
        dl=" ($(head -n 10 "$q/cc.diff" | tr '\n' ' ' | sed 's/ $//')$( [ "$ndiff" -gt 10 ] && echo " and $((ndiff - 10)) more"))"
    fi
    echo "configure check: $((ndiff + nnot + nsame)) PHP ports configured, $ndiff with differences$dl, $nnot not compared (results/configure-check.txt)" >> "$sum"
    say "the configure check: $ndiff PHP ports with differences, $nsame the same, $nnot not compared, $nnone not configured (results/configure-check.txt)"
fi

# results/az-interface.txt: az/az in this run, the interfaces of its libraries, those
# that changed against the az of the repository before, the ABI check, the ports that
# take interfaces of az (and those kept by them while az was built again), and the
# packages that link libraries of az their az_hash does not take (the run fails)
if [ -s "$q/azif.hashes" ]; then
    {
        case "$(st az/az)" in
            ok) echo "az/az: built in this run ($(basename "$(cat "$q/file/az_az" 2>/dev/null)"))" ;;
            repo) echo "az/az: kept from the repository ($azhad)" ;;
            *) echo "az/az: $(st az/az)" ;;
        esac
        echo "the interfaces of its libraries (tools/az-interface.sh: the interface hash, the closure):"
        awk '{ printf "  %-14s %s %s\n", $1, substr($2, 1, 12), $4 }' "$q/azif.hashes"
        if [ "$azbuilt" = 1 ]; then
            if [ -n "$azold" ]; then
                sh "$top/tools/az-interface.sh" diff "$q/azold" "$q/azif" > "$q/azdiff" 2>&1
                if [ -s "$q/azdiff" ]; then
                    echo "the interfaces that changed against the az of the repository before this run ($azhad):"
                    sed 's/^/  /' "$q/azdiff"
                else
                    echo "against the az of the repository before this run ($azhad): no interface changed"
                fi
            elif [ -n "$azhad" ]; then
                echo "the az of the repository before this run ($azhad) has no manifests: no interfaces to compare"
            else
                echo "no az in the repository before this run"
            fi
            echo "the ABI check of the packages of the repository that need az (tools/az-abi-check.sh, results/abi-check.txt):"
            sed -n '1p' "$res/abi-check.txt" 2> /dev/null | sed 's/^/  /'
            echo "  $(grep -c '^ok ' "$res/abi-check.txt" 2> /dev/null) passed, $(grep -c '^fail ' "$res/abi-check.txt" 2> /dev/null) failed"
            grep '^fail ' "$res/abi-check.txt" 2> /dev/null | sed 's/^/  /'
        fi
        ntake=0
        for o in $(cat "$q/queue.txt"); do [ -s "$q/azcov/$(key "$o")" ] && ntake=$((ntake + 1)); done
        echo "ports of the queue whose az_hash takes interfaces of az: $ntake; kept by them while az was built again in this run: $(grep -c . "$q/kept-if")"
        [ -s "$q/kept-if" ] && tr '\n' ' ' < "$q/kept-if" | fold -s -w 100 | sed 's/^/  /; s/ *$//'
        if [ -n "$(ls "$q/uncov")" ]; then
            echo "packages that link libraries of az their az_hash does not take (AZ_HASH_LIBS of their Makefiles):"
            cat "$q"/uncov/* | sed 's/^/  /'
        fi
    } > "$res/az-interface.txt"
    nki="$(grep -c . "$q/kept-if")"
    if [ "$azbuilt" = 1 ]; then
        if [ -z "$azold" ]; then azw="the interfaces not compared (the az of the repository before has no manifests)"
        elif [ -s "$q/azdiff" ]; then azw="interfaces changed: $(cut -d: -f1 "$q/azdiff" | tr '\n' ' ' | sed 's/ $//')"
        else azw="no interface changed"
        fi
        echo "az:       built again; $azw; $nki ports kept by interface; ABI check: $(grep -c '^fail ' "$res/abi-check.txt" 2> /dev/null) of $(grep -c -E '^(ok|fail) ' "$res/abi-check.txt" 2> /dev/null) packages failed (results/az-interface.txt)" >> "$sum"
    fi
fi
# AZ_PLAN: results/plan.txt, the ports to be built (and why) and the counts
if [ "$plan" = 1 ]; then
    npl="$(awk '$2 == "PLAN"' "$sum" | grep -c .)"
    nkp="$(for o in $(cat "$q/queue.txt"); do [ "$(st "$o")" = repo ] && echo "$o"; done | grep -c .)"
    nbu="$(for o in $(cat "$q/queue.txt"); do [ "$(st "$o")" = ok ] && echo "$o"; done | grep -c .)"
    {
        echo "The plan of the run (AZ_PLAN): $npl ports to be built, $nkp kept from the repository, $nbu built in this run (az/az and the ports it needs, when they were to be built)"
        awk '$2 == "PLAN" || ($1 ~ /\// && $2 == "OK") { print }' "$sum"
    } > "$res/plan.txt"
    echo "plan:     $npl to be built, $nkp kept from the repository, $nbu built (results/plan.txt)" >> "$sum"
    say "the plan (AZ_PLAN): $npl ports to be built, $nkp kept, $nbu built (results/plan.txt)"
fi

if [ "$dryrun" = 1 ]; then
    echo "dry run: the waves in results/waves.txt, nothing built, no repository" >> "$sum"
    say "dry run (AZ_DRYRUN): $wave waves (results/waves.txt), nothing built"
    cat "$res/waves.txt"
    exit 0
fi

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
    elif [ -f "$q/abifail/$(key "$og")" ]; then
        # broken with the new az, and not built again in this run: the next run builds it
        say "the repository: $f away: it fails the ABI check against the new az ($(cat "$q/abifail/$(key "$og")"))"
        rm -f "$repo/$f"
    fi
done < "$q/repo-had"
for f in $(cat "$q/made"); do cp -p "$f" "$repo/" || say "cannot copy ${f##*/} into $repo"; done
# no comma in the file names: GitHub renames an asset whose name has one (the epoch of
# a version: ffmpeg-9.0.2_1,1.pkg), so the release would not have the file the catalog
# names. A dot instead: pkg takes the name and the version from the package, and the
# catalog takes the file name as the path of the package
for f in "$repo"/*,*.pkg; do
    [ -f "$f" ] || continue
    t="$(printf '%s' "${f##*/}" | tr ',' '.')"
    mv -f "$f" "$repo/$t" && say "the repository: ${f##*/} as $t (a comma does not reach the release)"
done
nrepo="$(npkg "$repo")"
sh "$top/tools/pkg-repo-sign.sh" "$repo" "$res/pkg-repo.log"
src=$?
signed=0
case "$(tail -n 1 "$res/pkg-repo.log" 2>/dev/null)" in "pkg repo: signed"*) signed=1 ;; esac
# no key: unsigned, as before (the build can pass, nothing is published); the key
# failing: pkg repo failed
if [ "$src" = 0 ]; then repo_ok=1; else repo_ok=0; fi
# the repository (repo/) has a signed catalog or none: an unsigned one, or one not
# whole, goes; the packages stay (the cache of the workflow keeps them) and the next
# run writes the catalog. For the checks of this run an unsigned catalog of the same
# packages in work/repo-unsigned (hard links), never in the repository and never
# published: the checks read it as the file:// repository azbuild
unsigned=""
if [ "$signed" = 0 ]; then
    for f in "$repo"/*; do
        [ -f "$f" ] && catalog "${f##*/}" && rm -f "$f"
    done
    say "the repository: no catalog (results/pkg-repo.log: $(tail -n 1 "$res/pkg-repo.log" 2>/dev/null)); its $nrepo packages stay for the next run"
    ur="$work/repo-unsigned"
    rm -rf "$ur" && mkdir -p "$ur"
    for f in "$repo"/*.pkg; do
        [ -f "$f" ] || continue
        catalog "${f##*/}" && continue
        ln "$f" "$ur/" 2> /dev/null || cp -p "$f" "$ur/"
    done
    if pkg repo "$ur" > "$res/pkg-repo-unsigned.log" 2>&1 && [ -f "$ur/meta.conf" ]; then
        unsigned="$ur"
        say "an unsigned catalog for the checks of this run only (not published): $ur"
    else
        say "no unsigned catalog for the checks either: pkg repo $ur failed (results/pkg-repo-unsigned.log)"
    fi
fi
# the files of the repository now, for the runner: vmactions copies repo/ back without
# deleting, so what this run removed here would stay there (build.yml removes it)
ls "$repo" > "$res/repo-files.txt"
[ -n "$unsigned" ] && echo "checks:   an unsigned catalog of these packages in $unsigned: checks only, not published" >> "$sum"
echo "repository: $nrepo packages; $(tail -n 1 "$res/pkg-repo.log" 2>/dev/null)" >> "$sum"

# --- the result ------------------------------------------------------------------------
nok=0; nkept=0; nplan=0; failed=""; skipped=""
for o in $(cat "$q/queue.txt"); do
    case "$(st "$o")" in
        ok) nok=$((nok + 1)) ;;
        repo) nkept=$((nkept + 1)) ;;
        plan) nplan=$((nplan + 1)) ;;
        fail) failed="$failed $o" ;;
        *) skipped="$skipped $o" ;;
    esac
done
# the packages that link libraries of az their az_hash does not take (az_cover_check)
uncov="$(cd "$q/uncov" && ls | sed 's/_/\//' | tr '\n' ' ' | sed 's/ $//')"
echo "built:    $nok, kept from the repository: $nkept$( [ "$plan" = 1 ] && echo ", to be built (AZ_PLAN): $nplan")${failed:+, failed:$failed}${skipped:+, not built:$skipped}" >> "$sum"
if [ -z "$failed" ] && [ -z "$skipped" ] && [ "$repo_ok" = 1 ] && [ -z "$uncov" ]; then
    echo "result:   OK" >> "$sum"
    say "OK: $nok built, $nkept kept from the repository ($repo)"
    exit 0
fi
r=""
[ -n "$failed" ] && r="failed:$failed"
[ -n "$skipped" ] && r="${r:+$r; }not built:$skipped"
[ "$repo_ok" = 1 ] || r="${r:+$r; }pkg repo failed"
[ -n "$uncov" ] && r="${r:+$r; }libraries of az not in the az_hash (AZ_HASH_LIBS, results/az-interface.txt): $uncov"
echo "result:   FAIL ($r)" >> "$sum"
say "FAIL ($r)"
exit 1
