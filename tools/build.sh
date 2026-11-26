#!/bin/sh
# build.sh - build the packages of the ports of this overlay (azsupport/ports) with
# the FreeBSD ports framework, each after the ports of this tree it needs (a queue,
# as poudriere builds), into the repository of pkg "azsupport", signed.
#
# Usage (as root on FreeBSD; the tree is the one this script is in):
#   sh tools/build.sh [--force] [--repo <dir>] [<origin> ... [";" <origin> ...] ...]
#
#   <origin>      the ports to build (category/port of this tree) and the ports of
#                 this tree they need; none: every <category>/<port> with a Makefile
#   ";"           between groups of them: stages, each built after the one before it
#                 (with the ports it needs that no stage before it has); none, for every
#                 port: azsupport (azsupport/*, x11-fonts/fontconfig), then PHP 5.6, 7.4, 8.1,
#                 8.3, 8.2, 8.4 (each with mod_php and its modules), then the rest (aZ, 11.11.2026)
#   --force       build every port of the queue, also those whose package with the
#                 same azsupport_hash is in the repository already
#   --repo <dir>  the repository: the files of the release azsupport-fbsd<major>-amd64-<level>
#                 downloaded into <dir> (default: work/repo; empty or missing on the
#                 first run); the new packages take the place of those of the same
#                 origin there, and the catalog of pkg repo is written there, signed
#
# Environment:
#   AZSUPPORT_CPUTYPE       the x86-64 level, CPUTYPE of make.conf (default x86-64-v3)
#   AZSUPPORT_STAMP         the revision of the packages of the run (default: the hour of its
#                    start, yymmddhh UTC)
#   AZSUPPORT_WORK          the work directory (default: work/ of the tree): the official
#                    ports tree (freebsd-ports/), WRKDIRPREFIX (wrk/), make.conf, the queue
#   AZSUPPORT_PORTSDIR      an official ports tree to take as it is instead of the checkout of
#                    the pinned commit (a build server: its own tree; a warning when it is
#                    at another commit)
#   AZSUPPORT_PKG_KEY_FILE  the signing key of the repository (see tools/pkg-repo-sign.sh)
#   AZSUPPORT_WORLD         the base system of the chroots: a world installed in that directory
#                    (installworld, distribution) for the level of the run, whose
#                    crt1.o, crti.o, crtbegin.o, crtend.o and libcompiler_rt.a go into
#                    every package (build-jail.yml: a world of each level next to the
#                    jail of a build server); its directories of the base below
#                    ($ch_base but /usr/src, which stays that of the machine) at the same
#                    paths in each chroot, read only. None: those of the machine (the VM
#                    of build.yml)
#   AZSUPPORT_JOBS          the ports built at once (default 4); 1: one after
#                    another in the order of the queue, as before AZSUPPORT_JOBS
#   AZSUPPORT_TIME_SOFT, AZSUPPORT_TIME_HARD
#                    seconds from the start of this script: after AZSUPPORT_TIME_SOFT no port
#                    starts its build (it is "not built: the time of this run is
#                    over", the next run builds it); at AZSUPPORT_TIME_HARD the builds still
#                    going are stopped and not built either (one after another too);
#                    a port of tools/build-minutes.conf does not start when less time
#                    than its usual build is left until AZSUPPORT_TIME_HARD (the same);
#                    results/time-limit says so, and the result is FAIL. The packages
#                    built until then go into the repository as always (build.yml of
#                    azsupport/ports: its job has 350 minutes, and a run that reached
#                    them lost all it had built). A port with AZSUPPORT_PORT_CACHE in its
#                    Makefile (databases/mongodb80: the disk cache of Bazel) builds with
#                    AZSUPPORT_PORT_CACHE_DIR, portcache/<key> of this tree read-write in its
#                    chroot, which build.yml keeps between the runs (a draft release):
#                    one stopped at AZSUPPORT_TIME_HARD goes on from there in the next run
#                    (cached= of results/time-limit); results/portcache.txt: the keys of
#                    the ports built with theirs in this run
#   AZSUPPORT_DRYRUN        1: the queue, the hashes and the waves of the run (what the
#                    repository has with the same azsupport_hash left out), nothing installed
#                    or built, no repository (the ports that build against a library port of
#                    azsupport or azsupport/static to be built: decided once it is built,
#                    AZSUPPORT_PLAN)
#   AZSUPPORT_PLAN          1: the plan of the run: the library ports of azsupport (azsupport/<lib>,
#                    x11-fonts/fontconfig), azsupport/static and the ports they need built when
#                    they are to be (the hashes of the ports that build against them are made
#                    with the interfaces of the new packages), every other port only decided:
#                    kept from the repository or to be built, and why (results/plan.txt,
#                    the summary); the repository gets what was built
#   AZSUPPORT_CONFIGURE_CHECK  1: the configure check of the PHP ports the run configures
#                    (tools/configure-check.sh; results/configure-check.txt)
#   AZSUPPORT_CFLAGS, AZSUPPORT_GCC_SO, AZSUPPORT_GCC_BIN, MAKE_CONF  given to the builds (the scripts of
#                    tools/ read them); a build sees no other variable of the caller
#   MAKE_JOBS_NUMBER given to the builds too: the make -j of each port (bsd.port.mk;
#                    none: kern.smp.cpus, all the CPUs of the machine), so that AZSUPPORT_JOBS
#                    ports at once take AZSUPPORT_JOBS times it (build-jail.yml: the cores and
#                    the memory of the jail; the VM of build.yml sets none)
#
# How (the logic of poudriere, with make and pkg of the host, each port in a chroot):
# - the official tree of freebsd-ports at the pinned commit below (git, depth 1, reused
#   when it is at that commit), this tree as OVERLAYS over it;
# - the make.conf of the run from tools/make.conf.in (CPUTYPE of the level, CFLAGS,
#   JPEG_PORT, OPTIONS_UNSET of aZ, the paths), as __MAKE_CONF: /etc/make.conf is not read;
# - the queue: the ports and those of this tree they need (FETCH_, EXTRACT_, PATCH_,
#   BUILD_, LIB_, RUN_ and PKG_DEPENDS of make -V, the origins that are ours), each
#   after those it needs;
# - the azsupport_hash of each port: SHA-256 of its files (paths and contents; with those of
#   its MASTERDIR and the other files of this tree its Makefile reads, Mk/bsd.overlay.mk
#   and the other makefiles of Mk/ of this tree it reads: Mk/Uses/php.mk for the PHP
#   ports, not for the ports of azsupport; the files of tools/ its makefiles name outside
#   their comments, and those these name: tools/azsupport-build.sh of azsupport/static and
#   of the library ports; the files of this tree its EXTRA_PATCHES and AZSUPPORT_HASH_FILES
#   name: files of the directory of another port its build reads, tools/check-tree.sh),
#   of the files of the official tree it reads (its makefiles there, Mk/Uses/*.mk of its
#   USES, a MASTERDIR there; not Mk/bsd.sites.mk, where distfiles are fetched from, nor
#   Mk/bsd.licenses.db.mk: its own licenses instead, as make -V has them; the files of
#   the official ports of its AZSUPPORT_HASH_OFFICIAL, which its build makes: a library
#   port, its official port), the level and tools/make.conf.in,
#   and of the hash of each port of this tree it needs to build (so a change of a port
#   builds again what needs it to build), of one it takes only to run the name of its
#   package (aZ, 24.11.2026 15:47: "чтобы по каждому чиху все не пересобиралось":
#   azsupport/azsupport, the pkg-config of the shared tree and the trigger of the
#   services, for the library ports), but of a library port of azsupport (AZSUPPORT_LIB of
#   its Makefile: azsupport/<lib>, package azsupport-<lib>, and x11-fonts/fontconfig) the
#   interface hashes of its library and of those it needs, and of azsupport/static (the
#   static tree, package azsupport-static) those of the static libraries the port builds
#   against (aZ, 12.11.2026: the manifests of their packages,
#   tools/azsupport-interface.sh; the content hash of the libraries of
#   AZSUPPORT_STATIC_LIBS), so a fix inside a library builds again only its port and a
#   change of its interface the ports that use it, and the hashes of the ports that build
#   against them are made once these are done (built or kept); the hash of a port the
#   ports that need it take leaves out the files the port lists in its
#   AZSUPPORT_HASH_NOT_FOR_DEPENDENTS (run time only: lang/php74's php.ini block, profile
#   script, rc.d script, pkg-message), which count in its own azsupport_hash only, not in
#   that of its slaves either; it goes to make as AZSUPPORT_HASH (the annotation azsupport_hash of the package,
#   Mk/bsd.overlay.mk), the revision as AZSUPPORT_STAMP (PORTREVISION= ${AZSUPPORT_STAMP}: each
#   build is an upgrade for pkg; pkg takes a dependency by its name, not its version);
#   the base of every azsupport_hash: the files of the official tree every build takes
#   (Mk/Scripts, Keywords, Templates; not its commit: a new pin builds again only the
#   ports whose files of it changed), the level, tools/make.conf.in and
#   the way the builder builds ("builder chroot": each port in a chroot of its own,
#   11.11.2026: every port built once that way);
# - after a library port is built in a run, the ABI check of the packages of the
#   repository that need its library (tools/azsupport-abi-check.sh: each SONAME of it they
#   need is in the new package, each symbol they bind from it is defined there): one
#   that fails is built again (one not in the queue goes from the repository); a package
#   that links a library of azsupport its azsupport_hash does not take (its SONAMEs,
#   shlibs_required: no library port of it among the dependencies to build of its port),
#   or that none of its dependencies to run brings (pkg refuses a package whose shared
#   library no package has), fails the run; results/azsupport-interface.txt: the library
#   ports, the interfaces that changed, the ABI check, the ports kept by interface while a
#   library they use was built again;
# - a port that names no file of the static tree of azsupport in its dependencies builds
#   without its archives (they go from its chroot): only a port that says AZSUPPORT_STATIC_LIBS
#   (tools/check-tree.sh) can link them;
# - the build tools of AZSUPPORT_TOOLS_OFFICIAL (below: Python, Perl, meson, GNU
#   make, pkgconf, Rust, autoconf, m4, the binutils, py-requests) come from the official
#   packages of FreeBSD also when this tree
#   has the origin (aZ, 11.11.2026:
#   our python312 and perl5.42 link libraries of azsupport, which needs them to build): for a
#   port that needs such an origin only to build it (FETCH_, EXTRACT_, PATCH_, BUILD_
#   or PKG_DEPENDS; not LIB_ or RUN_DEPENDS, and the port is no extension of Python, a
#   FLAVOR py*), the official package goes into its chroot, and the hash of our port
#   is not in its azsupport_hash (the official commit is in the base); a port that runs with
#   it (LIB_ or RUN_DEPENDS) or builds an extension for it gets ours, whose hash counts
#   (results/hashes.txt names the tools a port gets official);
# - a port whose origin has a package with the same azsupport_hash in the repository is not
#   built again (an incremental build) unless --force; a port that fails stops those
#   that need it (skipped, with the reason);
# - a port of a kernel module (USES=kmod) builds against the sources of the kernel in
#   /usr/src, as do the ports of AZSUPPORT_KERNEL_SOURCES (below: VirtualBox): when one is to
#   be built and the machine has none, gitup of the branch
#   releng/<release> of the machine (with the fixes of the release) into /usr/src, once
#   (ksrc_get; results/logs/kernel-sources.log); the chroots get /usr/src read only;
# - each port in a chroot of its own (work/ch/<key>), made for it in seconds and torn
#   down after it, whatever its result (unmounted, removed; rm -x): the base system
#   of the machine read only (nullfs), a copy of its /etc, devfs, an empty /usr/local,
#   /tmp and a pkg database of its own; the catalogs of the run (those of the machine,
#   updated once at the start: pkg -U, never during the run) and the cache of pkg of
#   the machine shared, so that an official package is downloaded once (the official
#   packages of the ports to build fetched at the start; then one chroot at a time
#   fetches, lockf); this tree, the official tree, packages/ and the repository read
#   only at their paths, the distfiles, WRKDIRPREFIX, the packages directory of the
#   port and results/azsupport-results read-write (ch_up). In it the official packages of its
#   dependencies (and those our packages it gets need to run) by pkg -c <chroot>
#   install from the FreeBSD repositories of the machine (not ours: azsupport, azbuild), ours
#   by pkg -c <chroot> add of the packages built before or of the repository (-f in the
#   place of an official package of the same name), in the order of the queue; then
#   make clean package in it (chroot(8), the environment of a login of root with the
#   make.conf of the run, AZSUPPORT_CPUTYPE and the variables above) with
#   USE_PACKAGE_DEPENDS_ONLY=yes (nothing is built from source but the port itself);
#   its log, its time (with those of its chroot and of its dependencies), OK or FAIL.
#   The /usr/local of the machine is never touched by a build: the checks after the
#   run (tools/install-php.sh, test-programs.sh) see nothing a build installed;
# - AZSUPPORT_JOBS above 1: each port as soon as the ports of this tree it needs are done and
#   a place is free (not after the whole wave before it; aZ, 24.11.2026), up to AZSUPPORT_JOBS
#   ports at once, of those ready the biggest first (the size of the package in the
#   repository), each with its chroot, its log and its own PACKAGES directory (its
#   distfiles fetched under lockf(1), one build at a time); a port of AZSUPPORT_ALONE (below:
#   GCC 16) starts when no other build is going, and none starts beside it; while
#   builds go it waits and the ports ready after it start meanwhile, until it has to
#   start to end before AZSUPPORT_TIME_HARD (alone_due; aZ, 24.11.2026); the summary in the
#   order of the queue, results/waves.txt (the ports that came ready together);
# - a NEED_ROOT port (azsupport/static and the library ports azsupport/<lib> build into the
#   real prefix and refuse files of a package of theirs there): into the /usr/local/azsupport
#   of its own chroot, as any port, with the packages of the libraries it needs there;
# - the repository: one package per origin (of two in <dir> at the start, the newer
#   version), the new ones in the place of the old ones of the same name or origin,
#   away with the packages of origins this tree has no more, pkg repo, signed and
#   checked (tools/pkg-repo-sign.sh); <dir> keeps a signed catalog or none: without
#   the signature (no key, or the key fails) its catalog goes, the packages stay, and
#   an unsigned catalog of them in work/repo-unsigned serves the checks of the run
#   only (never published);
# - AZSUPPORT_CONFIGURE_CHECK=1: after the build of a PHP port (lang/phpXY, www/mod_phpXY,
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
# hashes.txt, azsupport-interface.txt and abi-check.txt (the library ports of azsupport), plan.txt
# (AZSUPPORT_PLAN), waves.txt
# (AZSUPPORT_JOBS above 1, AZSUPPORT_DRYRUN), progress.log
# (the screen lines as they come), logs/<category>_<port>.log, logs/chroots.log (the
# catalogs and the official packages fetched at the start), pkg-repo.log; with AZSUPPORT_CONFIGURE_CHECK=1
# configure-check.txt (each port with differences, the checks with their diagnostic,
# then the others) and configure-check/ (a file per port, the two config.log files of
# a port with differences).
# Exit status: 0 every port of the queue built or kept (AZSUPPORT_PLAN: or to be built) and the
# repository signed (or unsigned without a key), or a dry run; 1 otherwise, 2 a wrong
# call.

set -u

# the official tree the overlay is built over: freebsd-ports main of 25.11.2026 17:35
# (Prague; aZ, 25.11.2026 18:20: «новости портов прогони прежде чем заново всё
# пересобирать», before the full rebuild of az as azsupport), the commit of azsupport/static/files/deps.conf too. The rule of aZ: the latest version of a port, or a newer release for its
# security or a serious bug (a take line of deps.conf), so before a build this goes to
# the latest commit of main (it had stayed at 04.11.2026: apache24 2.4.69 for 2.4.70
# of 07.11.2026, aZ 10.11.2026)
ports_commit="0530184620597905236e6930eb3e4834d1173390"
ports_url="https://github.com/freebsd/freebsd-ports"

# The build tools a port gets from the official packages of FreeBSD even when this
# tree has the origin (aZ, 11.11.2026): our Python and Perl link libraries of azsupport, and
# azsupport/static and the library ports need python3, meson and perl5 to build (a cycle, and every package built
# again with each update of them). For a port that needs one of these only to build
# it, the official package (see the head); for one that runs with it or builds an
# extension for it, ours. The origins as the dependencies name them (lang/python3 the
# meta port of the default Python, meson needs it); an origin this tree does not have
# is official anyway. Here only: not taken from the environment.
# lang/gcc16: the compiler of USES=azgcc (PHP, Redis, Python) and of the libraries of azsupport stays the
# official package until these move to the gcc16 of this tree with the next full build
# (aZ, 18.11.2026: «а) ... да, давай так»); our lang/gcc16-libs is not a tool and goes
# to the ports that run with it (sysutils/arcconf)
# devel/gmake, devel/pkgconf, lang/rust: ours are for the servers, where the native
# extensions of gems build with them (aZ, 20.11.2026); the builds of this tree keep the
# official packages, so that adding them builds again only the ports that run with
# them (www/npm-node18 and www/npm-node24: gmake for node-gyp)
# devel/autoconf, devel/autoconf-switch, devel/m4, devel/binutils, www/py-requests: ours for
# the packages of the repository that run with them (aZ, 26.11.2026 13:09: «Делаем его
# самодостаточным — лишние зависимости убираем, нужные собираем у нас.»: devel/automake
# with autoconf, lang/gcc16 with the binutils, www/yt-dlp with py-requests); a build of
# this tree that needs one only to build keeps the official package (phpize of every PHP
# module: autoconf; databases/mongodb80: m4 and py-requests), unless a port of ours it
# gets runs with it, which brings ours into its chroot over the official one (dep_lists):
# automake (USES=autoreconf) our autoconf and m4, lang/gcc16 (USES=azgcc) our binutils.
# The hash of such a build takes that of automake, in which autoconf counts, so a change
# of autoconf builds again automake and with it 47 ports of this tree (USES=autoreconf and
# what builds with them, 27.11.2026); of lang/gcc16 it takes the name of its package only
AZSUPPORT_TOOLS_OFFICIAL="lang/python3 lang/python312 lang/perl5.42 devel/meson devel/gmake devel/pkgconf lang/rust devel/autoconf devel/autoconf-switch devel/m4 devel/binutils www/py-requests"
# the ports that build against the sources of the kernel without being kernel modules
# (no USES=kmod, no IGNORE without them): they get them as a kernel module does
# (ksrc_get). VirtualBox generates headers of the kernel out of them (VBOX_FREEBSD_SRC=
# ${SRC_BASE}/sys of the official port; without them kmk: «No rule to make target
# '/usr/src/sys/kern/bus_if.m'», 21.11.2026, when its kernel module came from the
# repository and no port of the run had fetched the sources)
AZSUPPORT_KERNEL_SOURCES="emulators/virtualbox-ose-72"
# the ports built with no other build beside them (AZSUPPORT_JOBS above 1), for their memory:
# lang/gcc16, the LTO of its profiledbootstrap («xg++: fatal error: Killed signal
# terminated program lto1» beside databases/mongodb80 on a free runner, 21.11.2026)
AZSUPPORT_ALONE="lang/gcc16"

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

cputype="${AZSUPPORT_CPUTYPE:-x86-64-v3}"
case "$cputype" in
    x86-64-v[234]) ;;
    *) die "AZSUPPORT_CPUTYPE=$cputype: not x86-64-v2, x86-64-v3 or x86-64-v4" ;;
esac
azsupport_stamp="${AZSUPPORT_STAMP:-$(date -u +%y%m%d%H)}"
case "$azsupport_stamp" in
    ''|*[!0-9]*) die "AZSUPPORT_STAMP=$azsupport_stamp: not a number (yymmddhh)" ;;
esac
jobs="${AZSUPPORT_JOBS:-4}"
case "$jobs" in
    ''|*[!0-9]*|0*) die "AZSUPPORT_JOBS=$jobs: not a number of 1 or more" ;;
esac
case "${MAKE_JOBS_NUMBER-1}" in
    ''|*[!0-9]*|0*) die "MAKE_JOBS_NUMBER=$MAKE_JOBS_NUMBER: not a number of 1 or more" ;;
esac
# the world of the chroots (AZSUPPORT_WORLD; see the head): its real path, or none
world=""
if [ -n "${AZSUPPORT_WORLD:-}" ]; then
    world="$(cd "$AZSUPPORT_WORLD" 2> /dev/null && pwd -P)"
    [ -n "$world" ] && [ -x "$world/bin/sh" ] && [ -f "$world/usr/lib/crt1.o" ] ||
        die "AZSUPPORT_WORLD=$AZSUPPORT_WORLD: no world there (bin/sh, usr/lib/crt1.o)"
fi
case "${AZSUPPORT_DRYRUN:-}" in ''|0) dryrun=0 ;; *) dryrun=1 ;; esac
case "${AZSUPPORT_PLAN:-}" in ''|0) plan=0 ;; *) plan=1 ;; esac
case "${AZSUPPORT_CONFIGURE_CHECK:-}" in ''|0) ccheck=0 ;; *) ccheck=1 ;; esac
# one port after another as before AZSUPPORT_JOBS: AZSUPPORT_JOBS=1 (not a dry run)
serial=0
[ "$jobs" = 1 ] && [ "$dryrun" = 0 ] && serial=1
# the time of the run (AZSUPPORT_TIME_SOFT, AZSUPPORT_TIME_HARD): from the clock of this machine at
# the start of the script, whatever the clock of the host that set them
t_soft="${AZSUPPORT_TIME_SOFT:-}"; t_hard="${AZSUPPORT_TIME_HARD:-}"
case "$t_soft$t_hard" in *[!0-9]*) die "AZSUPPORT_TIME_SOFT, AZSUPPORT_TIME_HARD: seconds" ;; esac
[ -z "$t_soft" ] || [ -n "$t_hard" ] || t_hard="$t_soft"
[ -z "$t_hard" ] || [ -n "$t_soft" ] || t_soft="$t_hard"
t0="$(date +%s)"
deadline=""; deadline_hard=""
if [ -n "$t_soft" ]; then
    deadline=$((t0 + t_soft)); deadline_hard=$((t0 + t_hard))
    [ "$deadline_hard" -ge "$deadline" ] || deadline_hard="$deadline"
fi
time_over() { [ -n "$deadline" ] && [ "$(date +%s)" -ge "$deadline" ]; }
hard_over() { [ -n "$deadline_hard" ] && [ "$(date +%s)" -ge "$deadline_hard" ]; }
# time_short <origin>: true when the port (pre_port said 0: k set) usually builds longer
# than is left until AZSUPPORT_TIME_HARD (its minutes in tools/build-minutes.conf), so that it is
# not started only to be stopped there (aZ, 22.11.2026: lang/gcc16 lost 2 h so); a port
# with a cache between the runs (AZSUPPORT_PORT_CACHE) goes on from it and is never held back;
# bm and left: its minutes and the seconds left, for the message
time_short() {
    [ -n "$deadline_hard" ] || return 1
    bm="$(awk -v o="${1%%@*}" '$1 == o && $2 ~ /^[0-9]+$/ { print $2; exit }' "$top/tools/build-minutes.conf" 2> /dev/null)"
    [ -n "$bm" ] || return 1
    [ -z "$(port_cache "$k")" ] || return 1
    left=$((deadline_hard - $(date +%s)))
    [ $((bm * 60)) -gt "$left" ]
}
# alone_due <origin>: true when the port of AZSUPPORT_ALONE that waits (pend, in the waves) has
# to start now so as to end before AZSUPPORT_TIME_HARD: its usual minutes (build-minutes.conf)
# after the builds going (each from its start, its usual minutes or 15 when it has
# none) and after the next ready port, were that one started now; never without
# AZSUPPORT_TIME_HARD or without its minutes (then it starts when no other build goes)
bm_of() { awk -v o="${1%%@*}" '$1 == o && $2 ~ /^[0-9]+$/ { print $2; exit }' "$top/tools/build-minutes.conf" 2> /dev/null; }
alone_due() {
    [ -n "$deadline_hard" ] || return 1
    ad_bm="$(bm_of "$1")"
    [ -n "$ad_bm" ] || return 1
    ad_now="$(date +%s)"; ad_end="$ad_now"
    for ad_sf in "$q"/jobs/*.start; do
        [ -f "$ad_sf" ] || continue
        ad_k="${ad_sf##*/}"; ad_k="${ad_k%.start}"
        [ -f "$q/jobs/$ad_k.pid" ] || continue
        ad_m="$(bm_of "$(cat "$q/jobs/$ad_k.origin" 2> /dev/null)")"
        ad_e=$(($(cat "$ad_sf") + ${ad_m:-15} * 60))
        [ "$ad_e" -le "$ad_end" ] || ad_end="$ad_e"
    done
    ad_n="$(sed -n '1s/^[0-9]* //p' "$q/ready" 2> /dev/null)"
    if [ -n "$ad_n" ]; then
        ad_m="$(bm_of "$ad_n")"
        ad_e=$((ad_now + ${ad_m:-15} * 60))
        [ "$ad_e" -le "$ad_end" ] || ad_end="$ad_e"
    fi
    [ $((ad_end + ad_bm * 60)) -gt "$deadline_hard" ]
}
# tree_pids <pid>: the process and all its descendants; kill_tree <pid>: stop them all
# (stopped first, so that none starts another meanwhile), TERM, and KILL what is left
tree_pids() { echo "$1"; for _tp in $(pgrep -P "$1" 2> /dev/null); do tree_pids "$_tp"; done; }
kill_tree() {
    _kt="$(tree_pids "$1")"
    # shellcheck disable=SC2086
    kill -STOP $_kt 2> /dev/null; kill -TERM $_kt 2> /dev/null; kill -CONT $_kt 2> /dev/null
    sleep 5
    # shellcheck disable=SC2086,SC2046
    kill -KILL $_kt $(tree_pids "$1") 2> /dev/null
    return 0
}
work="${AZSUPPORT_WORK:-$top/work}"
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
mkdir -p "$res/logs" "$res/azsupport-results" "$q/info" "$q/deps" "$q/bdeps" "$q/rdeps" "$q/odeps" "$q/orun" "$q/pkgbase" "$q/state" \
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
if [ -n "${AZSUPPORT_PORTSDIR:-}" ]; then
    ports="$(cd "$AZSUPPORT_PORTSDIR" 2>/dev/null && pwd)"
    [ -n "$ports" ] && [ -f "$ports/Mk/bsd.port.mk" ] || die "AZSUPPORT_PORTSDIR=$AZSUPPORT_PORTSDIR: no Mk/bsd.port.mk there"
    c="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    [ "$c" = "$ports_commit" ] ||
        say "warning: the ports tree $ports (AZSUPPORT_PORTSDIR) is at ${c:-an unknown commit}, not at $ports_commit: taken as it is"
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
# WRKDIRPREFIX by its real path: bsdcpio of COPYTREE_BIN and COPYTREE_SHARE (bsd.port.mk)
# refuses to write through a symbolic link (ARCHIVE_EXTRACT_SECURE_SYMLINKS) and says
# so only to /dev/null there, so that the stage of a port that copies a tree stayed
# empty when work/ was a link (build-jail.yml: work -> /var/azbuild/work/<level>;
# net/rabbitmq, run 45477734952, 24.11.2026)
sed -e "s|@CPUTYPE@|$cputype|" -e "s|@PORTSDIR@|$ports|" -e "s|@OVERLAYS@|$top|" \
    -e "s|@WRKDIRPREFIX@|$workr/wrk|" -e "s|@PACKAGES@|$packages|" -e "s|@DISTDIR@|$distdir|" \
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
    case "${1%%/*}" in Mk|Templates|Keywords|Tools|tools|work|packages|distfiles|results|repo|keys|docs|portcache) return 1 ;; esac
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
# the azsupport_hash of a package file (its annotation), or nothing
pkg_hash() { pkg query -F "$1" '%At %Av' 2>/dev/null | awk '$1 == "azsupport_hash" { print $2; exit }'; }
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
# and /usr/src, read only, once it is there: the sources of the kernel for the ports of
# kernel modules (ksrc_get, below)
ch_base="$ch_base /usr/src"
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
# ch_kill <chroot>: the processes whose root directory is the chroot or below it
# (procstat), killed with SIGKILL (up to 3 times, 2 s apart) and said: those of a build
# that was stopped (its make and compilers go on without it and keep the mounts busy and
# the processors: the jail of as5, 24.11.2026)
ch_kill() {
    for _i in 1 2 3; do
        _kp="$(procstat -f -a 2> /dev/null | awk -v d="$1" '$3 == "root" && ($NF == d || index($NF, d "/") == 1) { print $1 }' | sort -u | tr '\n' ' ')"
        [ -n "$_kp" ] || return 0
        # shellcheck disable=SC2086
        [ "$_i" = 1 ] && say "  the chroot $1: processes still there killed: $(ps -o pid= -o command= -p "$(echo $_kp | tr ' ' ',')" 2> /dev/null | cut -c1-100 | tr '\n' ';' | cut -c1-400)"
        # shellcheck disable=SC2086
        kill -9 $_kp 2> /dev/null
        sleep 2
    done
}
# ch_down <chroot>: a chroot of the run away: the processes still in it killed (ch_kill),
# what is mounted in it unmounted (the deepest first, by force when busy), then its
# files, only when nothing is mounted there any more (and rm -x never crosses a mount
# point: the distfiles, the cache, the trees mounted in it stay whole); 1 when it stays
# (said)
ch_down() {
    case "$1" in "$chd"/?*) ;; *) say "  ch_down: $1 is no chroot of the run ($chd/<key>)"; return 1 ;; esac
    [ -e "$1" ] || [ -n "$(ch_mounts "$1")" ] || return 0
    ch_kill "$1"
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
# work directory, packages/, distfiles/, results/, the repository, portcache/: each
# port its own part, read-write) and the hidden ones
ch_ovl=""
for _d in "$topr"/*/; do
    _d="${_d%/}"
    [ -d "$_d" ] || continue
    _rd="$(realpath "$_d")"
    case " $workr $(realpath "$packages") $(realpath "$distdir") $(realpath "$res") $(realpath "$repo") " in
        *" $_rd "*) continue ;;
    esac
    [ "${_d##*/}" = portcache ] && continue
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
        # the world of AZSUPPORT_WORLD at the paths of the base, when there is one
        if [ -n "$world" ] && [ "$_d" != /usr/src ]; then
            [ -d "$world$_d" ] || continue
            ch_mount ro "$world$_d" "$_d" || return 1
            continue
        fi
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
    for _d in "$distdir" "$work/wrk" "$work/pk/$1" "$res/azsupport-results" $( [ "$ccheck" = 1 ] && echo "$work/ccw"); do
        mkdir -p "$_d" || { why="cannot make $_d"; return 1; }
        # shellcheck disable=SC2086
        if ch_under "$(realpath "$_d")" $_ro; then why="$_d is in a directory mounted read only in the chroot"; return 1; fi
        ch_mount rw "$_d" || return 1
    done
    # the cache of a port that keeps one between the runs (AZSUPPORT_PORT_CACHE: the disk cache
    # of Bazel of databases/mongodb80), read-write at the same path: portcache/<key>
    if [ -n "$(port_cache "$1")" ]; then
        mkdir -p "$top/portcache/$1" || { why="cannot make $top/portcache/$1"; return 1; }
        ch_mount rw "$top/portcache/$1" || return 1
    fi
    # the libraries of the base system the level strips (ch_compat_init), read only, with
    # their directory in the hints of the run-time linker
    if [ -d "$work/ch-compat/lib" ]; then
        ch_mount ro "$work/ch-compat/lib" /usr/local/lib/azsupport-basecompat || return 1
        mkdir -p "$c/usr/local/libdata/ldconfig" &&
            echo /usr/local/lib/azsupport-basecompat > "$c/usr/local/libdata/ldconfig/azsupport-basecompat" ||
            { why="cannot write $c/usr/local/libdata/ldconfig/azsupport-basecompat"; return 1; }
    fi
    # the hints of the run-time linker (/usr/local/lib; the packages add theirs)
    chroot "$c" /usr/sbin/service ldconfig start > /dev/null 2>&1 || :
    return 0
}
# port_cache <key>: the directory of the cache of the port of the key between the runs
# (portcache/<key> of this tree, AZSUPPORT_PORT_CACHE of its Makefile; build.yml keeps it in a
# draft release of its own: a build stopped at the time of the run goes on from there in
# the next one), or nothing; the key in results/portcache.txt once the port built here
port_cache() {
    [ -n "$(sed -n 25p "$q/info/$1" 2> /dev/null)" ] || return 0
    echo "$top/portcache/$1"
}
# ch_run [-l <lock file>] <command>...: a command in the chroot $c (under lockf(1) of
# the machine with -l), with the environment of a login of root, the make.conf of the
# run, the level, and AZSUPPORT_CFLAGS, AZSUPPORT_GCC_SO, AZSUPPORT_GCC_BIN and MAKE_CONF of the caller
# when set (nothing else of the caller: no key, no token). NOCLEANDEPENDS: make clean
# of a port leaves the ports it depends on alone: they may build at that moment in
# another chroot, with the same WRKDIRPREFIX (11.11.2026: make clean of
# ftp/curl, which takes the official perl5 to build, removed the work directory of
# lang/perl5.42 under its Configure; that of www/node18 the one of lang/python312)
ch_run() {
    _lk=""
    if [ "$1" = -l ]; then _lk="$2"; shift 2; fi
    set -- chroot "$c" /usr/bin/env -i HOME=/root USER=root LOGNAME=root SHELL=/bin/sh \
        PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin \
        __MAKE_CONF="$__MAKE_CONF" ASSUME_ALWAYS_YES=yes NOCLEANDEPENDS=yes AZSUPPORT_CPUTYPE="$cputype" \
        ${AZSUPPORT_CFLAGS+"AZSUPPORT_CFLAGS=$AZSUPPORT_CFLAGS"} ${AZSUPPORT_GCC_SO+"AZSUPPORT_GCC_SO=$AZSUPPORT_GCC_SO"} \
        ${AZSUPPORT_GCC_BIN+"AZSUPPORT_GCC_BIN=$AZSUPPORT_GCC_BIN"} ${MAKE_CONF+"MAKE_CONF=$MAKE_CONF"} \
        ${MAKE_JOBS_NUMBER+"MAKE_JOBS_NUMBER=$MAKE_JOBS_NUMBER"} "$@"
    if [ -n "$_lk" ]; then lockf -k "$_lk" "$@"; else "$@"; fi
}
# the chroots a run before left (stopped), and those of this run at its end, whatever ends it
c=""; cs="$q/ch"
ch_all_down
trap 'ch_all_down' EXIT
trap 'exit 2' HUP INT TERM

# tool_official <origin> <key>: a build tool of AZSUPPORT_TOOLS_OFFICIAL that the port of the
# key needs only to build (not among its LIB_ and RUN_DEPENDS), and the port is no
# extension of Python (its FLAVOR, line 19 of its info, not py*): it gets the official
# package of the origin, even when this tree has it
tool_official() {
    case " $AZSUPPORT_TOOLS_OFFICIAL " in *" ${1%%@*} "*) ;; *) return 1 ;; esac
    sed 's/@.*//' "$q/info/$2.run" | grep -qxF "${1%%@*}" && return 1
    case "$(sed -n 19p "$q/info/$2")" in py[0-9]*) return 1 ;; esac
    return 0
}

# port_info <origin>: what make -V says of a port of this tree into $q/info/<key>
# (lines: 1 PKGNAME, 2 IGNORE, 3-9 FETCH_ EXTRACT_ PATCH_ BUILD_ LIB_ RUN_ PKG_DEPENDS,
# 10 NEED_ROOT, 11 MASTERDIR, 12 FILESDIR, 13 PATCHDIR, 14 PKGDIR, 15 DISTINFO_FILE,
# 16 .MAKE.MAKEFILES, 17 AZSUPPORT_HASH_NOT_FOR_DEPENDENTS, 18 AZSUPPORT_HASH_LIBS, 19 FLAVOR,
# 20 AZSUPPORT_STATIC_LIBS, 21 EXTRA_PATCHES, 22 AZSUPPORT_PREFIX, 23 AZSUPPORT_STATIC, 24 AZSUPPORT_HASH_FILES,
# 25 AZSUPPORT_PORT_CACHE, 26 LICENSE_COMB, 27 its licenses as the official bsd.licenses.db.mk
# has them: <license>|<name>|<groups>|<permissions> each, 28 AZSUPPORT_LIB (a library port of
# azsupport: the name of its library in deps.conf), 29 AZSUPPORT_HASH_OFFICIAL (the official
# ports its build makes, whose files count in its hash: port_files)); our
# dependencies into $q/deps/<key> (all kinds), those it needs to build (FETCH_,
# EXTRACT_, PATCH_, BUILD_, LIB_ or PKG_DEPENDS: not only to run) into $q/bdeps/<key>, and
# $q/rdeps/<key> (LIB_ and RUN_DEPENDS: what pkg add of its package needs), the
# official ones into $q/odeps/<key> and $q/orun/<key>; the origins of this tree it gets
# official (tool_official) are among the official ones, and in $q/info/<key>.tools;
# $q/info/<key>.static when a dependency names a file of the static tree of azsupport
# (AZSUPPORT_STATIC, of azsupport/static: the port builds against it)
port_info() {
    _k="$(key "$1")"
    [ -f "$q/info/$_k" ] && return 0
    : > "$q/deps/$_k"; : > "$q/bdeps/$_k"; : > "$q/rdeps/$_k"; : > "$q/odeps/$_k"; : > "$q/orun/$_k"; : > "$q/info/$_k.tools"
    # the licenses: an expression of make (its single quotes on purpose)
    # shellcheck disable=SC2016
    if ! make -C "$top/$1" AZSUPPORT_STAMP="$azsupport_stamp" -V PKGNAME -V IGNORE -V FETCH_DEPENDS -V EXTRACT_DEPENDS \
            -V PATCH_DEPENDS -V BUILD_DEPENDS -V LIB_DEPENDS -V RUN_DEPENDS -V PKG_DEPENDS -V NEED_ROOT \
            -V MASTERDIR -V FILESDIR -V PATCHDIR -V PKGDIR -V DISTINFO_FILE -V .MAKE.MAKEFILES \
            -V AZSUPPORT_HASH_NOT_FOR_DEPENDENTS -V AZSUPPORT_HASH_LIBS -V FLAVOR -V AZSUPPORT_STATIC_LIBS -V EXTRA_PATCHES \
            -V AZSUPPORT_PREFIX -V AZSUPPORT_STATIC -V AZSUPPORT_HASH_FILES -V AZSUPPORT_PORT_CACHE -V LICENSE_COMB \
            -V '${LICENSE:@l@${l}|${_LICENSE_NAME_${l}}|${_LICENSE_GROUPS_${l}}|${_LICENSE_PERMS_${l}}@}' \
            -V AZSUPPORT_LIB -V AZSUPPORT_HASH_OFFICIAL \
            > "$q/info/$_k" 2> "$q/info/$_k.err" || [ -z "$(sed -n 1p "$q/info/$_k")" ]; then
        echo "make -V failed: $(grep . "$q/info/$_k.err" | head -n 1)" > "$q/info/$_k.bad"
        return 1
    fi
    _st="$(sed -n 23p "$q/info/$_k")"
    if [ -n "$_st" ] && sed -n '3,9p' "$q/info/$_k" | tr -s ' \t' '\n\n' | grep -q -e "^$_st/[^:]*:azsupport/static\$" -e "^$_st/[^:]*:azsupport/static[:@]"; then
        : > "$q/info/$_k.static"
    fi
    sed -n '3,9p' "$q/info/$_k" | dep_origins > "$q/info/$_k.all"
    sed -n '7,8p' "$q/info/$_k" | dep_origins > "$q/info/$_k.run"
    sed -n '3,7p;9p' "$q/info/$_k" | dep_origins > "$q/info/$_k.bld"
    for _d in $(cat "$q/info/$_k.all"); do
        [ "${_d%%@*}" = "$1" ] && continue
        if ! ours "$_d"; then
            echo "$_d" >> "$q/odeps/$_k"
        elif tool_official "$_d" "$_k"; then
            echo "$_d" >> "$q/odeps/$_k"
            echo "${_d%%@*}" >> "$q/info/$_k.tools"
        else
            echo "${_d%%@*}" >> "$q/deps/$_k"
            grep -qxF "$_d" "$q/info/$_k.bld" && echo "${_d%%@*}" >> "$q/bdeps/$_k"
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
# name and those of AZSUPPORT_HASH_FILES (files, or directories: their files; the files of
# the directory of another port its build reads, which tools/check-tree.sh asks for:
# graphics/ImageMagick6 the conf and policy of graphics/ImageMagick7, a library port its
# patches in azsupport/static/files/deps), and the
# makefiles of this tree it reads
# (.MAKE.MAKEFILES: Mk/bsd.overlay.mk, which every port reads, taken also when make
# does not say; Mk/Uses/php.mk only by the ports that read it); and the files of
# tools/ that the lines of those makefiles name outside their comments
# (tools/<name> or ${AZSUPPORT_TOOLS}/<name>: the wrapper ports run the builds of tools/,
# azsupport/static and the library ports (azsupport/static/Makefile.lib)
# ${AZSUPPORT_TOOLS}/azsupport-build.sh; the design comment of azsupport/static/Makefile names the
# scripts of all the wrapper ports and does not count), with the files of tools/
# those scripts name in turn (comments too: azsupport-build.sh names azsupport-check-links.py);
# the files of the official ports of its AZSUPPORT_HASH_OFFICIAL (the official port a
# library port builds by make patch: off_files), as those of the official tree it reads
tree_file() {
    case "$1" in
        "$workr"/*|"$portsr"/*|"$topr"/work/*|"$topr"/packages/*|"$topr"/distfiles/*|"$topr"/results/*|"$topr"/repo/*|"$topr"/.git/*) return 1 ;;
        "$topr"/*) return 0 ;;
    esac
    return 1
}
# tools_named <file>...: the files of tools/ of this tree that the files name
# (tools/<name>, ${AZSUPPORT_TOOLS}/<name>; a dot that ends a sentence is not of the name);
# tools_named_mk the same for makefiles, their comments (from # to the end of the
# line) left out. Never tools/build.sh, the builder itself, which no build of a port
# runs (what of it can change a package is the line "builder ..." of the base of every
# hash): a script that names it, in a comment too (tools/mc-build.sh, 12.11.2026), put
# it into the hash of its port, which every change of the builder then built again
tools_names() {
    grep -o -E '(tools|AZSUPPORT_TOOLS[})]?)/[A-Za-z0-9_.-]+' | sed -E 's#^[^/]*/#tools/#; s/\.+$//' | LC_ALL=C sort -u |
        grep -v -x 'tools/build\.sh' | while read -r _n; do [ -f "$topr/$_n" ] && echo "$topr/$_n"; done
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
# off_files <origin>: the files of an official port of AZSUPPORT_HASH_OFFICIAL (a library port
# builds it: make patch of tools/azsupport-build.sh): those of its directory, of its
# MASTERDIR, FILESDIR, PATCHDIR and DISTINFO_FILE, and the makefiles of the official tree
# it reads (.MAKE.MAKEFILES of make -V in the official tree), each by its real path, those
# under the official tree only; once an origin ($q/offi/<key>)
off_files() {
    _of="$q/offi/$(key "$1")"
    if [ ! -f "$_of" ]; then
        mkdir -p "$q/offi"
        {
            [ -d "$portsr/$1" ] && files_in "$portsr/$1"
            make -C "$ports/$1" -V .MAKE.MAKEFILES -V MASTERDIR -V FILESDIR -V PATCHDIR -V DISTINFO_FILE 2> /dev/null < /dev/null |
                tr -s ' \t' '\n\n' | grep . | while read -r _op; do
                    case "$_op" in /*) ;; *) _op="$ports/$1/$_op" ;; esac
                    if [ -d "$_op" ]; then files_in "$_op"; elif [ -f "$_op" ]; then echo "$_op"; fi
                done
        } | while read -r _op; do realpath "$_op" 2> /dev/null; done | while read -r _op; do
            case "$_op" in "$portsr"/*) echo "$_op" ;; esac
        done | LC_ALL=C sort -u > "$_of.t"
        mv -f "$_of.t" "$_of"
    fi
    cat "$_of"
}
port_files() {
    _k="$(key "$1")"
    {
        files_in "$topr/$1"
        [ -f "$topr/Mk/bsd.overlay.mk" ] && echo "$topr/Mk/bsd.overlay.mk"
        for _p in $(sed -n '11,16p' "$q/info/$_k"); do
            if [ -d "$_p" ]; then files_in "$_p"; elif [ -f "$_p" ]; then echo "$_p"; fi
        done
        # EXTRA_PATCHES (<file>[:-p<n>]) of this tree: ftp/curl applies the patch of curl of azsupport/static
        for _p in $(sed -n 21p "$q/info/$_k"); do
            _p="${_p%%:*}"
            [ -f "$_p" ] && echo "$_p"
        done
        # AZSUPPORT_HASH_FILES: files of the directory of another port its build reads
        for _p in $(sed -n 24p "$q/info/$_k"); do
            if [ -d "$_p" ]; then files_in "$_p"; elif [ -f "$_p" ]; then echo "$_p"; fi
        done
        # AZSUPPORT_HASH_OFFICIAL: the files of the official ports its build makes
        for _p in $(sed -n 29p "$q/info/$_k"); do
            off_files "$_p"
        done
    } 2> /dev/null | while read -r _f; do realpath "$_f" 2> /dev/null; done | LC_ALL=C sort -u > "$q/read-$_k"
    while read -r _f; do tree_file "$_f" && echo "$_f"; done < "$q/read-$_k" > "$q/files-$_k"
    # the files of the official tree among them (its makefiles there, a MASTERDIR
    # there...), but Mk/bsd.sites.mk (where the distfiles are fetched from: what is
    # fetched its distinfo says) and Mk/bsd.licenses.db.mk (every license: those of the
    # port, line 27 of its info, count instead)
    while read -r _f; do
        case "$_f" in
            "$portsr"/Mk/bsd.sites.mk|"$portsr"/Mk/bsd.licenses.db.mk) ;;
            "$portsr"/*) echo "$_f" ;;
        esac
    done < "$q/read-$_k" > "$q/ofiles-$_k"
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
    # the official files ("o freebsd-ports/<path>": the hashes of Mk/ once, $q/ohashes)
    # and the licenses ("l <LICENSE_COMB> <licenses>")
    awk 'FILENAME == ARGV[1] { h[$1] = $2; next } { print $0, (($0 in h) ? h[$0] : "-") }' "$q/ohashes" "$q/ofiles-$_k" |
        while read -r _f _h; do
            [ "$_h" != - ] || _h="$(hfile "$_f")"
            printf 'o freebsd-ports/%s %s\n' "${_f#"$portsr"/}" "$_h"
        done
    _ls="$(sed -n 27p "$q/info/$_k")"
    [ -z "$_ls" ] || printf 'l %s %s\n' "$(sed -n 26p "$q/info/$_k")" "$_ls"
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
    # the shared libraries the packages in the chroot need and neither the world of the
    # level nor a package there has (an official package built for the whole base
    # system, which the src.conf of the level strips: the libkrb5.so.122 of the official
    # curl, 24.11.2026): said, so that the failure of a tool at its start has its cause
    # in the log
    pkg -c "$c" query -a %b > "$cs/shlibs-have" 2> /dev/null
    _ml="$(pkg -c "$c" query -a '%n %B' 2> /dev/null | while read -r _pn _l; do
        # the 32-bit libraries (":32", the multilib of lang/gcc16): no world of ours has them
        case "$_l" in *:32) continue ;; esac
        [ -e "$c/lib/$_l" ] || [ -e "$c/usr/lib/$_l" ] || [ -e "$c/usr/local/lib/azsupport-basecompat/$_l" ] ||
            grep -qxF "$_l" "$cs/shlibs-have" || echo "$_l ($_pn)"
    done | LC_ALL=C sort -u | tr '\n' ' ')"
    [ -z "$_ml" ] || say "  $1: warning: needed in the chroot and not there: $_ml"
    # the archives of the static tree of azsupport (azsupport/static) only for a port that
    # names a file of that tree in its dependencies (and so says AZSUPPORT_STATIC_LIBS,
    # tools/check-tree.sh): no other can link them into its package, which its azsupport_hash
    # would not know
    _st="$(sed -n 23p "$q/info/$k")"
    if [ -n "$_st" ] && [ ! -f "$q/info/$k.static" ] && grep -qxF azsupport/static "$q/dl/$k.ours" && [ -d "$c$_st/lib" ]; then
        rm -f "$c$_st"/lib/*.a
        echo "== the archives of $_st/lib away from the chroot: $1 names no file of the static tree of azsupport in its dependencies (AZSUPPORT_STATIC_LIBS)" >> "$log"
    fi
    # the hints of the run-time linker with the libraries of the packages
    chroot "$c" /usr/sbin/service ldconfig start > /dev/null 2>&1 || :
    return 0
}

# --- the queue -----------------------------------------------------------------------
# the stages: the ports asked for in groups separated by ";", each group (with the
# ports of this tree it needs that no group before it has) built after the one before
# it; without ports the order of aZ (11.11.2026: "Первым делом ... azsupport, на php 5.6, 7.4,
# 8.1, 8.3, 8.2, 8.4 - в таком порядке"): azsupport (the ports azsupport/*: azsupport/azsupport,
# azsupport/static, the library ports azsupport/<lib>; and x11-fonts/fontconfig, the library
# port of fontconfig), then each PHP version (its core, mod_php and modules), then the other
# ports. $q/groups: "<group> <origin>"
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
    grep -E '^(azsupport/|x11-fonts/fontconfig$)' "$q/all.txt" | sed 's#^#1 #' > "$q/g.txt"
    if [ -s "$q/g.txt" ]; then cat "$q/g.txt" >> "$q/groups"; g=2; fi
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
# the library ports of the queue (AZSUPPORT_LIB of their Makefiles, line 28 of their info):
# $q/libports, "<origin> <library>" a line each in the order of the queue, and
# $q/islib/<key> with the name of its library
mkdir -p "$q/islib"
: > "$q/libports"
for o in $(cat "$q/queue.txt"); do
    k="$(key "$o")"
    [ -f "$q/info/$k.bad" ] && continue
    l="$(sed -n 28p "$q/info/$k" 2> /dev/null)"
    [ -n "$l" ] || continue
    lo="$(awk -v l="$l" '$2 == l { print $1; exit }' "$q/libports")"
    [ -z "$lo" ] || die "$o and $lo: both AZSUPPORT_LIB=$l (one port a library: tools/check-tree.sh)"
    case "$l" in common|*[!A-Za-z0-9_.+-]*) die "$o: AZSUPPORT_LIB=$l: not the name of a library of deps.conf" ;; esac
    echo "$o $l" >> "$q/libports"
    echo "$l" > "$q/islib/$k"
done
# azsupport/static (the static tree) in the queue: stin; and make -V worked for it: stq
stin=0; stq=0
grep -qxF azsupport/static "$q/queue.txt" && stin=1
[ "$stin" = 1 ] && [ ! -f "$q/info/azsupport_static.bad" ] && stq=1
[ -s "$q/libports" ] && say "the library ports of azsupport in the queue: $(wc -l < "$q/libports" | tr -d ' ')$( [ "$stq" = 1 ] && echo ', and azsupport/static')"
: > "$res/stages.txt"
i=1
while [ "$i" -le "$nst" ]; do
    echo "stage $i: $(wc -l < "$q/stage-$i.txt" | tr -d ' ') ports: $(head -n 3 "$q/stage-$i.txt" | tr '\n' ' ')$( [ "$(wc -l < "$q/stage-$i.txt")" -gt 3 ] && echo '...')" >> "$res/stages.txt"
    i=$((i + 1))
done
while read -r l; do say "$l"; done < "$res/stages.txt"

# --- the azsupport_hash of each port, in the order of the queue -------------------------------
# Two hashes a port: its azsupport_hash ($q/hash/<key>), and the one the ports that need it
# fold in ($q/dhash/<key>), the same without the files of AZSUPPORT_HASH_NOT_FOR_DEPENDENTS
# (a variable of its Makefile: files, or directories of files, it installs and uses at run
# time only, never read by the build of another port; lang/php74: its php.ini block, the profile
# script, the rc.d script, pkg-message). A file of that list counts in the azsupport_hash
# of the port whose directory holds it, and in no other: not in the hash its
# dependents fold in, nor in the azsupport_hash of its slaves (their MASTERDIR is its
# directory: the modules php74-*). Without the variable both hashes are the same.
#
# The libraries of azsupport (aZ, 12.11.2026: no build again of what needs a library for a fix
# inside it, as FreeBSD and Debian do not build again the dependents of a shared library for
# one; 26.11.2026: every library a port of its own). A library port (AZSUPPORT_LIB of its
# Makefile, $q/libports: azsupport/<lib>, package azsupport-<lib>, built by
# tools/azsupport-build.sh --lib into /usr/local/azsupport; x11-fonts/fontconfig, the official
# port into /usr/local) is built again when anything of it changes (its files, its rows of
# deps.conf written in its Makefile, the files of its official port: AZSUPPORT_HASH_OFFICIAL,
# the interfaces of the libraries it needs); a port that builds against library ports (they
# are among its dependencies to build) folds in, instead of their hashes, the interface
# hash of the library of each and of those these need (their closure: the requires lines of
# the manifests, libs_dep). The interface of a library comes out of its build: the manifest
# its package has (AZSUPPORT_PREFIX/share/azsupport/interface/<library>.txt: its headers, .pc
# files, *-config scripts and other files with their SHA-256, the SONAMEs of its shared
# libraries, its version, the hash of its build functions, the libraries of azsupport it
# requires by the NEEDED of its shared libraries, its .pc files and the #include lines of
# its headers; a line prefix when its files are elsewhere: /usr/local for
# x11-fonts/fontconfig), read by tools/azsupport-interface.sh. So a fix inside the code of a
# library (the same headers, .pc files, SONAMEs, version and options) builds again its port
# alone; a new version, a changed header or .pc, a new SONAME or a changed option builds
# again the ports that use that library. A library port a port needs only to run counts by
# the name of its package, as any other (and azsupport/azsupport, the pkg-config of the
# shared tree and the trigger of the services, which every library port needs to run).
# azsupport/static (package azsupport-static: the static tree, the archives, headers and .pc
# files of the libraries of kind static, for the PHP a server builds and the few ports that
# link them): a port that builds against it (its dependencies name a file of the static
# tree, ${AZSUPPORT_STATIC}/...:azsupport/static) folds in the interface hash of each static
# library of the files its dependencies name and of those its AZSUPPORT_HASH_LIBS names
# (graphics/GraphicsMagick, graphics/libimagemagick7), with their closure, the hash of the
# files of no library of that tree (common.txt: static/bin/pkg-config), and the content hash
# of the libraries of AZSUPPORT_STATIC_LIBS (it links their archives into its package; "none":
# it builds against the static tree, its package has no code of azsupport) and of their
# closure (static_dep): the manifests of the package of azsupport/static
# (AZSUPPORT_PREFIX/static/share/azsupport/interface). A file of the static tree a dependency
# names that no manifest has, or a name of those variables that is no static library: the
# hash of all of azsupport/static (said in results/hashes.txt); a library port done without
# a manifest: its hash. The manifests are those of the packages of the run: of the
# repository when the port is kept (its package has the same azsupport_hash and its
# manifests), of the new package when it is built, so the hashes of the ports that build
# against them (and of those that need these) are made once these are done (lib_resolve; they
# are the first stage), and no such port is ready before. A package of a library port or of
# azsupport/static of the repository without its manifests is built again.
#
# The base of every hash: the files of the official tree every build takes (Mk/Scripts,
# Keywords, Templates), the level, tools/make.conf.in and the way the builder builds
# ("builder chroot": each port in a chroot of its own, with only its dependencies; a
# change of that way that can change the packages changes this line, and every port is
# built again), and with AZSUPPORT_WORLD the world the chroots run on (its stamp .az-world of
# build-jail.yml: make.conf, src.conf and the version of the sources it was built of),
# whose crt*.o and libcompiler_rt.a go into every package. Not the commit of the official tree: the makefiles of it a port reads
# count in its own hash (port_files), so that a new pin builds again only the ports
# whose makefiles changed (aZ, 24.11.2026 15:47: "чтобы по каждому чиху все не
# пересобиралось"; the pin of 23.11.2026 built every package again, its Mk/ had changed
# in 6 files none of our builds takes). The build tools a port gets official
# (AZSUPPORT_TOOLS_OFFICIAL) are not among its dependencies of this tree: their hash is not
# in its own.
# The hashes as they were made before (the official commit in the base, no official
# files, the hash of a dependency only to run as that of any other): base_hash_old and
# $q/hash-old, $q/dhash-old, for the packages of the repository built with them
# (hash_same: such a package is kept, its line goes to tools/azsupport-hash-legacy.txt)
#
# The official packages the builds take (off_repos: the name, the url of the chroots, the
# url of the machine): those of the enabled repositories of pkg.FreeBSD.org of the
# machine, the one of the ports from latest whatever the machine has. The pin of the tree
# is a commit of main, and the official packages of main are those of latest; FreeBSD
# 15.1-RELEASE has quarterly in /etc/pkg/FreeBSD.conf (the jail of build-jail.yml took rust
# 1.98.1 of 2026Q4 for the cargo.mk of the pin, which needs 1.99.0: run 45477734952,
# 24.11.2026; the images of the VMs have latest). ch_init writes the url into the
# repositories of the chroots, and the line "official" is in the base of every hash: a
# package built with the official packages of another branch is built again.
off_repos="$(pkg -vv 2> /dev/null | awk '
    /^Repositories:/ { r = 1; next }
    r && /^[^ ]/ { r = 0 }
    r && /^  [^ ].*: *\{/ { n = $1; sub(/:$/, "", n); u = "" }
    r && /^ *url *:/ { u = $0; sub(/^ *url *: *"?/, "", u); sub(/"?,? *$/, "", u) }
    r && /^ *enabled *: *(yes|true)/ && n != "" && tolower(u) ~ /[\/.]pkg\.freebsd\.org\// {
        m = u; sub(/\/quarterly$/, "/latest", u); print n, u, m }')"
find "$portsr/Mk" -type f -name '*.mk' | LC_ALL=C sort | while read -r f; do echo "$f $(hfile "$f")"; done > "$q/ohashes"
off_hash="$( (cd "$portsr" && find Mk/Scripts Keywords Templates -type f 2> /dev/null | LC_ALL=C sort |
    while read -r f; do echo "$f $(hfile "$f")"; done) | hin)"
base_hash="$({ echo "freebsd-ports files $off_hash"; echo "cputype $cputype"; echo "builder chroot"
    [ -z "$world" ] || echo "world $(cut -d ' ' -f 1-3 "$world/.az-world" 2> /dev/null || echo none)"
    printf '%s\n' "$off_repos" | awk 'NF { printf "%s%s %s", (n++ ? ", " : "official "), $1, $2 } END { if (n) print "" }'
    cat "$top/tools/make.conf.in"; } | hin)"
base_hash_old="$({ echo "freebsd-ports $ports_head"; echo "cputype $cputype"; echo "builder chroot"; cat "$top/tools/make.conf.in"; } | hin)"
mkdir -p "$q/dhash" "$q/hash-old" "$q/dhash-old" "$q/azcov" "$q/uncov" "$q/abifail"
: > "$q/legacy"
: > "$res/hashes.txt"
: > "$q/deferred"; : > "$q/deferred.k"
# The manifests of the libraries of azsupport, as the run loads them (lib_resolve): $q/azif
# those of the library ports done so far (the shared ones, <lib>.txt: of the new package
# when the port was built, of the repository when it was kept; $q/azif.d/<lib> the
# manifest out of one package), azif.hashes and azif.sonames of them
# (tools/azsupport-interface.sh hashes, sonames); $q/azst those of azsupport/static (the
# static tree), azst.hashes and azst.paths; none until they are read
mkdir -p "$q/azif" "$q/azif.d" "$q/azst"
: > "$q/azif.hashes"; : > "$q/azif.sonames"; : > "$q/azif.sonames.names"; : > "$q/azif.err"
: > "$q/azst.hashes"; : > "$q/azst.paths"
# lib_extract <lib> <origin> <package> <dir>: the manifest of the library of a library port
# out of its package into <dir> (<dir>/<lib>.txt): AZSUPPORT_PREFIX/share/azsupport/interface of
# the port, else the path of such a file in the package (pkg query); 1 when it has none, or
# the manifest of another library
lib_extract() {
    mkdir -p "${4%/*}" || return 1
    le_pre="$(sed -n 22p "$q/info/$(key "$2")" 2> /dev/null)"
    if ! sh "$top/tools/azsupport-interface.sh" extract "$3" "$4" "${le_pre:-/usr/local/azsupport}" 2> "$4.err" || [ ! -f "$4/$1.txt" ]; then
        le_mp="$(pkg query -F "$3" '%Fp' 2> /dev/null | grep -E "/share/azsupport/interface/$1\\.txt\$" | grep -v '/static/share/azsupport/interface/' | head -n 1)"
        [ -n "$le_mp" ] || return 1
        sh "$top/tools/azsupport-interface.sh" extract "$3" "$4" "${le_mp%/share/azsupport/interface/*}" 2>> "$4.err" && [ -f "$4/$1.txt" ] || return 1
    fi
    [ "$(awk '$1 == "library" { print $2; exit }' "$4/$1.txt")" = "$1" ] ||
        { echo "$4/$1.txt is the manifest of another library" >> "$4.err"; return 1; }
}
# lib_load <lib> <origin> <package>: the manifest of a library port out of its package into
# $q/azif, with those loaded before, and azif.hashes, azif.sonames made again (written
# whole: the jobs of the builds read them, lib_cover_check); "<lib> <origin> <package>"
# into $q/libloaded; 1 when the package has none
lib_load() {
    lib_extract "$1" "$2" "$3" "$q/azif.d/$1" || { cat "$q/azif.d/$1.err" >> "$q/azif.err" 2> /dev/null; return 1; }
    cp "$q/azif.d/$1/$1.txt" "$q/azif/$1.txt" || return 1
    sh "$top/tools/azsupport-interface.sh" hashes "$q/azif" > "$q/azif.hashes.t" 2>> "$q/azif.err" &&
        sh "$top/tools/azsupport-interface.sh" sonames "$q/azif" > "$q/azif.sonames.t" 2>> "$q/azif.err" || return 1
    awk '{ print $1 }' "$q/azif.sonames.t" > "$q/azif.sonames.names.t"
    mv -f "$q/azif.hashes.t" "$q/azif.hashes"; mv -f "$q/azif.sonames.t" "$q/azif.sonames"
    mv -f "$q/azif.sonames.names.t" "$q/azif.sonames.names"
    echo "$1 $2 $3" >> "$q/libloaded"
}
# static_load <package of azsupport/static>: the manifests of its static libraries
# (AZSUPPORT_PREFIX/static/share/azsupport/interface: their paths relative to AZSUPPORT_PREFIX,
# static/...; common.txt, the files of no library of the static tree) into $q/azst,
# azst.hashes and azst.paths; 1 when it has none
static_load() {
    sl_pre="$(sed -n 22p "$q/info/azsupport_static" 2> /dev/null)"
    sh "$top/tools/azsupport-interface.sh" extract "$1" "$q/azst" "${sl_pre:-/usr/local/azsupport}" static/share/azsupport/interface 2> "$q/azst.err" &&
        sh "$top/tools/azsupport-interface.sh" hashes "$q/azst" > "$q/azst.hashes" 2>> "$q/azst.err" &&
        sh "$top/tools/azsupport-interface.sh" paths "$q/azst" > "$q/azst.paths" 2>> "$q/azst.err" &&
        [ -s "$q/azst.hashes" ] && return 0
    : > "$q/azst.hashes"; : > "$q/azst.paths"
    return 1
}
# static_dep <key>: the lines of azsupport/static for the hash of a port that builds against
# it: "dep azsupport/static common <hash>", "dep azsupport/static interface <library> <hash>"
# for each static library of the closure of those it uses (by the files of the static tree
# its dependencies name, and its AZSUPPORT_HASH_LIBS), "dep azsupport/static static <library>
# <hash>" (the content hash) for the closure of its AZSUPPORT_STATIC_LIBS; "dep azsupport/static
# <hash of azsupport/static>" when a file of the static tree its dependencies name is in no
# manifest or a name is no static library. The libraries its hash covers into
# $q/azlibs-s-<key> (static:<library>), what it says into $q/azdep-s-<key>
static_dep() {
    sd_libs="$(sed -n 18p "$q/info/$1")"
    sd_st="$(sed -n 20p "$q/info/$1")"
    [ "$sd_st" = none ] && sd_st=""
    sd_pre="$(sed -n 22p "$q/info/$1")"
    sd_bad=""
    for sd_e in $(sed -n '3,9p' "$q/info/$1"); do
        case "$sd_e" in *:azsupport/static | *:azsupport/static:* | *:azsupport/static@*) ;; *) continue ;; esac
        sd_p="${sd_e%%:*}"
        sd_l="$(awk -v p="${sd_p#"$sd_pre"/}" '$1 == p { print $2; exit }' "$q/azst.paths")"
        # a file of no library (static/bin/pkg-config): common, in the hash of every port on it
        [ "$sd_l" = common ] && continue
        if [ -n "$sd_l" ]; then sd_libs="$sd_libs $sd_l"; else sd_bad="$sd_bad $sd_p"; fi
    done
    for sd_l in $sd_libs $sd_st; do
        awk -v n="$sd_l" '$1 == n && n != "common" { f = 1 } END { exit !f }' "$q/azst.hashes" || sd_bad="$sd_bad $sd_l"
    done
    if [ -n "$sd_bad" ] || [ ! -s "$q/azst.hashes" ]; then
        echo "dep azsupport/static $(cat "$q/dhash/azsupport_static" 2>/dev/null || echo none)"
        awk '$1 != "common" { print "static:" $1 }' "$q/azst.hashes" > "$q/azlibs-s-$1"
        if [ -s "$q/azst.hashes" ]; then
            echo "all of azsupport/static: no static library of azsupport for$sd_bad" > "$q/azdep-s-$1"
        else
            echo "all of azsupport/static: no manifests of its static libraries" > "$q/azdep-s-$1"
        fi
        return 0
    fi
    awk -v libs="$sd_libs" -v st="$sd_st" -v out="$q/azlibs-s-$1" -v note="$q/azdep-s-$1" '
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
            print "dep azsupport/static common " ih["common"]
            n = sorted(want, a); l = ""
            for (i = 1; i <= n; i++) { print "dep azsupport/static interface " a[i] " " ih[a[i]]; print "static:" a[i] > out; l = l " " a[i] }
            m = sorted(swant, b); sl = ""
            for (i = 1; i <= m; i++) { print "dep azsupport/static static " b[i] " " ch[b[i]]; print "static:" b[i] > out; sl = sl " " b[i] }
            if (n + m == 0) printf "" > out
            printf "the interfaces of %d static libraries of azsupport/static:%s%s\n", n, l, (m ? "; the archives of" sl : "") > note
        }' "$q/azst.hashes"
}
# libs_dep <key>: the lines of the library ports a port builds against (among its
# dependencies to build): "dep <origin> interface <library> <hash>" for each library of the
# closure of theirs (azif.hashes: the requires lines of their manifests), sorted; "dep
# <origin> <hash for dependents>" for a library without a manifest loaded (its port done
# without one: said in results/hashes.txt). The libraries its hash covers into
# $q/azlibs-l-<key>, what it says into $q/azdep-l-<key>
libs_dep() {
    ld_ll=""
    for ld_d in $(cat "$q/bdeps/$1"); do
        [ -f "$q/islib/$(key "$ld_d")" ] && ld_ll="$ld_ll $(cat "$q/islib/$(key "$ld_d")")"
    done
    : > "$q/azlibs-l-$1"
    [ -n "$ld_ll" ] || return 0
    awk -v libs="$ld_ll" -v out="$q/azlibs-l-$1" '
        FILENAME == ARGV[1] { org[$2] = $1; next }
        { ih[$1] = $2; cl[$1] = $4 }
        END {
            n = split(libs, L, " ")
            for (i = 1; i <= n; i++) {
                if (L[i] in cl) { m = split(cl[L[i]], C, ","); for (j = 1; j <= m; j++) w[C[j]] = 1 }
                else w[L[i]] = 1
            }
            for (x in w) {
                print x > out
                if (x in ih) print "dep", ((x in org) ? org[x] : "library:" x), "interface", x, ih[x]
                else print "miss", ((x in org) ? org[x] : "library:" x), x
            }
        }' "$q/libports" "$q/azif.hashes" | LC_ALL=C sort > "$q/libsdep-$1"
    LC_ALL=C sort -u "$q/azlibs-l-$1" -o "$q/azlibs-l-$1"
    ld_miss=""
    while read -r ld_w ld_o ld_x ld_rest; do
        if [ "$ld_w" = dep ]; then
            echo "$ld_w $ld_o $ld_x $ld_rest"
        else
            echo "dep $ld_o $(cat "$q/dhash/$(key "$ld_o")" 2> /dev/null || echo none)"
            ld_miss="$ld_miss $ld_x"
        fi
    done < "$q/libsdep-$1"
    ld_n="$(grep -c . "$q/azlibs-l-$1")"
    echo "the interfaces of $ld_n libraries of the library ports of azsupport: $(tr '\n' ' ' < "$q/azlibs-l-$1" | sed 's/ $//')${ld_miss:+; the hash of the port for$ld_miss (no manifest of its library)}" > "$q/azdep-l-$1"
}
# hash_same <key> <origin> <azsupport_hash of its package in the repository>: true when that
# package is of the port as it is: the same azsupport_hash; or the hash it would have had as
# hashes were made before 24.11.2026 (the old hash of this run, $q/hash-old: then its
# line "<level> <origin> <that hash> <the azsupport_hash now>" goes into $q/legacy, for
# tools/azsupport-hash-legacy.txt), or such a line of tools/azsupport-hash-legacy.txt (so that a new
# pin, which changes the old hashes, does not build those packages again); hs_how: which
hash_same() {
    hs_how=""
    [ -n "$3" ] && [ "$3" != - ] || return 1
    hs_new="$(cat "$q/hash/$1" 2> /dev/null)"
    [ -n "$hs_new" ] || return 1
    [ "$3" = "$hs_new" ] && return 0
    if [ "$3" = "$(cat "$q/hash-old/$1" 2> /dev/null)" ]; then
        hs_how=" (as azsupport_hash was made before 24.11.2026)"
        echo "$cputype $2 $3 $hs_new" >> "$q/legacy"
        return 0
    fi
    if [ -f "$top/tools/azsupport-hash-legacy.txt" ] && awk -v c="$cputype" -v o="$2" -v a="$3" -v b="$hs_new" \
            '$1 == c && $2 == o && $3 == a && $4 == b { f = 1; exit } END { exit !f }' "$top/tools/azsupport-hash-legacy.txt"; then
        hs_how=" (its azsupport_hash before 24.11.2026, tools/azsupport-hash-legacy.txt)"
        return 0
    fi
    return 1
}
# hash_port <origin>: the two hashes of a port (its files in $q/pf-<key> and
# $q/nfd-<key>), its line of results/hashes.txt; the libraries of azsupport its hash covers,
# its own and those of the ports of this tree it needs, into $q/azcov/<key> (<library> of a
# library port, static:<library> of azsupport/static)
hash_port() {
    h_o="$1"; h_k="$(key "$1")"
    # the ports of this tree it needs: one it needs to build by its hash for the ports
    # that need it, one it takes only to run by the name of its package (nothing of the
    # package changes with it; aZ, 24.11.2026); the library ports and azsupport/static it
    # builds against by the interfaces of their libraries (libs_dep, static_dep); the lines
    # of the old hash beside
    : > "$q/dl-$h_k"; : > "$q/dlo-$h_k"
    rm -f "$q/azlibs-s-$h_k" "$q/azlibs-l-$h_k" "$q/azdep-s-$h_k" "$q/azdep-l-$h_k"
    h_lib=0
    for h_d in $(LC_ALL=C sort -u "$q/deps/$h_k"); do
        h_dk="$(key "$h_d")"
        if grep -qxF "$h_d" "$q/bdeps/$h_k"; then
            if [ "$h_d" = azsupport/static ]; then
                static_dep "$h_k" > "$q/dlaz-$h_k"
                cat "$q/dlaz-$h_k" >> "$q/dl-$h_k"; cat "$q/dlaz-$h_k" >> "$q/dlo-$h_k"
                continue
            fi
            if [ -f "$q/islib/$h_dk" ]; then h_lib=1; continue; fi
        fi
        echo "dep $h_d $(cat "$q/dhash-old/$h_dk" 2>/dev/null || echo none)" >> "$q/dlo-$h_k"
        # the compiler (lang/gcc<N> of USES=azgcc and azsupport/azsupport) by the name of its
        # package, also to build: a change of the port of GCC builds again itself only, the
        # next GCC (its name) the ports that build with it (aZ, 26.11.2026)
        case "$h_d" in
            lang/gcc[0-9][0-9])
                h_pn="$(sed -n 1p "$q/info/$h_dk" 2> /dev/null)"
                echo "tool $h_d ${h_pn%-*}" >> "$q/dl-$h_k" ;;
            *)
                if grep -qxF "$h_d" "$q/bdeps/$h_k"; then
                    echo "dep $h_d $(cat "$q/dhash/$h_dk" 2>/dev/null || echo none)" >> "$q/dl-$h_k"
                else
                    h_pn="$(sed -n 1p "$q/info/$h_dk" 2> /dev/null)"
                    echo "run $h_d ${h_pn%-*}" >> "$q/dl-$h_k"
                fi ;;
        esac
    done
    if [ "$h_lib" = 1 ]; then
        libs_dep "$h_k" > "$q/dllib-$h_k"
        cat "$q/dllib-$h_k" >> "$q/dl-$h_k"; cat "$q/dllib-$h_k" >> "$q/dlo-$h_k"
    fi
    {
        cat "$q/azlibs-s-$h_k" "$q/azlibs-l-$h_k" 2> /dev/null
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
    # the old hash: its files of this tree only ("f"), the base with the official commit
    {
        echo "base $base_hash_old"
        grep '^f ' "$q/pf-$h_k" | awk -v d="$h_o/" 'FILENAME == ARGV[1] { x[$1] = 1; next }
            ($2 in x) && substr($2, 1, length(d)) != d { next } { print }' "$q/nfd-$h_k" -
        cat "$q/dlo-$h_k"
    } | hin > "$q/hash-old/$h_k"
    {
        echo "base $base_hash_old"
        grep '^f ' "$q/pf-$h_k" | awk 'FILENAME == ARGV[1] { x[$1] = 1; next } !($2 in x) { print }' "$q/nfd-$h_k" -
        cat "$q/dlo-$h_k"
    } | hin > "$q/dhash-old/$h_k"
    h_n=""
    [ -f "$q/azdep-s-$h_k" ] && h_n=" ($(cat "$q/azdep-s-$h_k"))"
    [ -f "$q/azdep-l-$h_k" ] && h_n="$h_n ($(cat "$q/azdep-l-$h_k"))"
    if [ -s "$q/info/$h_k.tools" ]; then
        h_n="$h_n (the official packages of $(LC_ALL=C sort -u "$q/info/$h_k.tools" | tr '\n' ' ' | sed 's/ $//') to build it: AZSUPPORT_TOOLS_OFFICIAL, not in its hash)"
    fi
    echo "$h_o $(cat "$q/hash/$h_k")$h_n" >> "$res/hashes.txt"
}
# the files of each port, its hash when it builds against no library port and not against
# azsupport/static; those that do (or that need a port that does) wait for the manifests
# of these ($q/deferred, in the order of the queue: lib_resolve). A port whose
# AZSUPPORT_HASH_LIBS (the static libraries whose interfaces its hash takes) names libraries
# without a dependency to build on azsupport/static fails: the shared libraries go by the
# library ports among its dependencies
for o in $(cat "$q/queue.txt"); do
    k="$(key "$o")"
    [ -f "$q/info/$k.bad" ] && continue
    hl="$(sed -n 18p "$q/info/$k")"
    if [ -n "$hl" ] && ! grep -qxF azsupport/static "$q/bdeps/$k"; then
        echo "AZSUPPORT_HASH_LIBS ($hl) names libraries of the static tree, and it does not build against azsupport/static: name the library ports (azsupport/<lib>) in its dependencies" > "$q/info/$k.bad"
        say "$o: $(cat "$q/info/$k.bad")"
        continue
    fi
    port_files "$o" > "$q/pf-$k"
    # the files of AZSUPPORT_HASH_NOT_FOR_DEPENDENTS (files, or directories: their files),
    # relative to the tree
    for f in $(sed -n 17p "$q/info/$k"); do
        f="$(realpath "$f" 2> /dev/null)" || continue
        if [ -d "$f" ]; then files_in "$f"; else echo "$f"; fi
    done | while read -r f; do tree_file "$f" && echo "${f#"$topr"/}"; done | LC_ALL=C sort -u > "$q/nfd-$k"
    awk -v d="$o/" 'substr($0, 1, length(d)) == d' "$q/nfd-$k" > "$q/nfdown-$k"
    nfd="$(head -n 12 "$q/nfdown-$k" | tr '\n' ' ')"
    [ "$(grep -c . "$q/nfdown-$k")" -le 12 ] || nfd="${nfd}... ($(grep -c . "$q/nfdown-$k") files)"
    [ -n "$nfd" ] && say "$o: AZSUPPORT_HASH_NOT_FOR_DEPENDENTS, not in the hash of the ports that need it: $nfd"
    [ -s "$q/info/$k.tools" ] &&
        say "$o: the official packages of $(LC_ALL=C sort -u "$q/info/$k.tools" | tr '\n' ' ' | sed 's/ $//') to build it, not ours (AZSUPPORT_TOOLS_OFFICIAL)"
    wait_az=0
    for d in $(cat "$q/bdeps/$k"); do
        if [ "$d" = azsupport/static ] || [ -f "$q/islib/$(key "$d")" ]; then wait_az=1; break; fi
    done
    if [ "$wait_az" = 0 ] && [ -s "$q/deferred" ]; then
        for d in $(cat "$q/deps/$k"); do
            if grep -qxF "$d" "$q/deferred"; then wait_az=1; break; fi
        done
    fi
    if [ "$wait_az" = 0 ]; then hash_port "$o"; continue; fi
    # what it waits for, once: the library ports and azsupport/static among its dependencies to
    # build ($q/dwait-<key>), its deferred dependencies ($q/ddef-<key>), "<key> <origin>" a line
    for d in $(cat "$q/bdeps/$k"); do
        dk="$(key "$d")"
        if [ "$d" = azsupport/static ] || [ -f "$q/islib/$dk" ]; then echo "$dk $d"; fi
    done > "$q/dwait-$k"
    for d in $(cat "$q/deps/$k"); do
        grep -qxF "$d" "$q/deferred" && echo "$(key "$d") $d"
    done > "$q/ddef-$k"
    echo "$o" >> "$q/deferred"
    echo "$o=$k" >> "$q/deferred.k"
done

# the packages of the repository before: name origin azsupport_hash file, one per origin: of
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

# AZSUPPORT_PREFIX (every port has it of Mk/bsd.overlay.mk)
apre="$(sed -n 22p "$q/info/$(key "$(head -n 1 "$q/queue.txt")")" 2> /dev/null)"
apre="${apre:-/usr/local/azsupport}"
# The manifests of the repository before this run, for what changed
# (results/azsupport-interface.txt): $q/azold/<lib>.txt of the package of each library port
# of the queue ("<lib> <file>" into $q/azold.src); the first run after the split of
# azsupport into a port a library (no package of the port in the repository yet): of the
# package of azsupport/azsupport of before, which had every library (its
# share/azsupport/interface/<lib>.txt, without the files of the static tree); $q/azstold
# those of azsupport/static
mkdir -p "$q/azold" "$q/azold.d" "$q/libdone" "$q/lost" "$q/rcl" "$q/chk"
: > "$q/azold.src"; : > "$q/libloaded"; : > "$q/libbuilt"; : > "$q/ifbuilt"; : > "$q/hashed-late"
asold=""
ash="$(awk '$2 == "azsupport/static" { print $4; exit }' "$q/repo-had")"
if [ -n "$ash" ] && sh "$top/tools/azsupport-interface.sh" extract "$repo/$ash" "$q/azstold" "$apre" static/share/azsupport/interface 2> /dev/null; then
    asold="$ash"
fi
azcomb=""
ash="$(awk '$2 == "azsupport/azsupport" { print $4; exit }' "$q/repo-had")"
if [ -n "$ash" ] && sh "$top/tools/azsupport-interface.sh" extract "$repo/$ash" "$q/azcomb" "$apre" 2> /dev/null; then
    azcomb="$ash"
fi
while read -r lo ll; do
    lf="$(awk -v o="$lo" '$2 == o { print $4; exit }' "$q/repo-had")"
    if [ -n "$lf" ] && lib_extract "$ll" "$lo" "$repo/$lf" "$q/azold.d/$ll" 2> /dev/null; then
        cp "$q/azold.d/$ll/$ll.txt" "$q/azold/$ll.txt" && echo "$ll $lf" >> "$q/azold.src"
    elif [ -n "$azcomb" ] && [ -f "$q/azcomb/$ll.txt" ]; then
        awk '!(($1 == "file" || $1 == "link" || $1 == "soname" || $1 == "archive") && $2 ~ /^static\//)' "$q/azcomb/$ll.txt" > "$q/azold/$ll.txt" &&
            echo "$ll $azcomb (azsupport/azsupport of before the split)" >> "$q/azold.src"
    fi
done < "$q/libports"
# lib_manicheck <origin> <key>: a library port or azsupport/static kept by its hash (its package
# in the repository has the same azsupport_hash) whose package has not the manifests of its
# libraries is built again ($q/nomani-<key>, said)
lib_manicheck() {
    lm_hf="$(awk -v o="$1" '$2 == o { print $3, $4; exit }' "$q/repo-had")"
    [ -n "$lm_hf" ] && [ "$force" = 0 ] && hash_same "$2" "$1" "${lm_hf%% *}" || return 0
    if [ "$1" = azsupport/static ]; then
        sh "$top/tools/azsupport-interface.sh" extract "$repo/${lm_hf#* }" "$q/chk/s" "$apre" static/share/azsupport/interface > /dev/null 2>&1 && return 0
        say "azsupport/static: ${lm_hf#* } of the repository has no manifests of the interfaces of its static libraries: built again"
    else
        lib_extract "$(cat "$q/islib/$2")" "$1" "$repo/${lm_hf#* }" "$q/chk/l" > /dev/null 2>&1 && return 0
        say "$1: ${lm_hf#* } of the repository has no manifest of the interface of its library: built again"
    fi
    : > "$q/nomani-$2"
}
# the library ports and azsupport/static whose hash is made: kept by it, their packages need
# their manifests (those whose hash waits for the libraries they need: once it is made,
# lib_resolve); libwait: 1 while a library port, azsupport/static or a port that waits for
# their manifests is not done
libwait=0
: > "$q/libres"
for lo in $( [ "$stin" = 1 ] && echo azsupport/static ) $(awk '{ print $1 }' "$q/libports"); do
    libwait=1
    lk="$(key "$lo")"
    echo "$lo=$lk" >> "$q/libres"
    [ -s "$q/hash/$lk" ] || continue
    lib_manicheck "$lo" "$lk"
done
nlibres="$(grep -c . "$q/libres")"
# lib_resolve: what the library ports and azsupport/static done since the last call give
# (built, kept from the repository, failed or skipped): the manifests of their packages
# ($q/file/<key>: the new one, or that of the repository) loaded (lib_load, static_load;
# $q/libdone/<key>: loaded, noload, nopkg, or the state), the ABI check of the packages of
# the repository against a library built in this run (lib_abi); then the hashes of the
# deferred ports that can be made now, in the order of the queue: those whose library ports
# and azsupport/static among their dependencies to build are done and whose deferred
# dependencies have their hash; a port that cannot have one (such a port of it failed, or
# this dry run would build it: no package to read) into $q/lost/<key>, with why. Once
# nothing waits (libwait 0), the official packages of the ports hashed so late fetched
# (prefetch, as after the build of azsupport before 27.11.2026). Never in a job: pre_port and
# the loops of the builds call it
lib_resolve() {
    [ "$libwait" = 1 ] || return 0
    lr_new=0
    for lr_ok in $(cat "$q/libres"); do
        lr_o="${lr_ok%%=*}"; lr_k="${lr_ok#*=}"
        [ -f "$q/libdone/$lr_k" ] && continue
        [ -s "$q/state/$lr_k" ] || continue
        lr_new=1
        read -r lr_s < "$q/state/$lr_k"
        case "$lr_s" in
            ok|repo) ;;
            *) echo "$lr_s" > "$q/libdone/$lr_k"; continue ;;
        esac
        lr_f="$(cat "$q/file/$lr_k" 2> /dev/null)"
        if [ -z "$lr_f" ] || [ ! -f "$lr_f" ]; then
            # a dry run that would build it: its new interfaces are not known
            echo nopkg > "$q/libdone/$lr_k"
            continue
        fi
        if [ "$lr_o" = azsupport/static ]; then
            if static_load "$lr_f"; then
                echo loaded > "$q/libdone/$lr_k"
                [ "$lr_s" = ok ] && awk '$1 != "common" { print "static:" $1 }' "$q/azst.hashes" >> "$q/ifbuilt"
            else
                echo noload > "$q/libdone/$lr_k"
                say "warning: ${lr_f##*/} has no manifests of the interfaces of its static libraries ($(head -n 1 "$q/azst.err" 2> /dev/null)): the ports that build against azsupport/static take its hash"
            fi
            continue
        fi
        lr_l="$(cat "$q/islib/$lr_k")"
        if lib_load "$lr_l" "$lr_o" "$lr_f"; then
            echo loaded > "$q/libdone/$lr_k"
        else
            echo noload > "$q/libdone/$lr_k"
            say "warning: ${lr_f##*/} has no manifest of the interface of $lr_l ($(grep . "$q/azif.d/$lr_l.err" 2> /dev/null | head -n 1)): the ports that build against $lr_o take its hash"
        fi
        if [ "$lr_s" = ok ]; then
            echo "$lr_l" >> "$q/libbuilt"; echo "$lr_l" >> "$q/ifbuilt"
            lib_abi "$lr_l" "$lr_o" "$lr_f"
        fi
    done
    # a deferred port can be hashed only once a library port or azsupport/static is done
    [ "$lr_new" = 1 ] || return 0
    lr_n=0; lr_left=0
    for lr_ok in $(cat "$q/deferred.k"); do
        lr_o="${lr_ok%%=*}"; lr_k="${lr_ok#*=}"
        [ -s "$q/hash/$lr_k" ] && continue
        [ -f "$q/lost/$lr_k" ] && continue
        lr_w=0; lr_why=""
        while read -r lr_dk lr_d; do
            if [ ! -f "$q/libdone/$lr_dk" ]; then lr_w=1; break; fi
            read -r lr_v < "$q/libdone/$lr_dk"
            case "$lr_v" in
                loaded|noload) ;;
                nopkg) lr_why="$lr_d, which this dry run would build,"; break ;;
                *) lr_why="$lr_d ($lr_v)"; break ;;
            esac
        done < "$q/dwait-$lr_k"
        if [ "$lr_w" = 0 ] && [ -z "$lr_why" ]; then
            while read -r lr_dk lr_d; do
                [ -s "$q/hash/$lr_dk" ] && continue
                if [ -f "$q/lost/$lr_dk" ]; then read -r lr_why < "$q/lost/$lr_dk"; break; fi
                lr_w=1; break
            done < "$q/ddef-$lr_k"
        fi
        if [ -n "$lr_why" ]; then echo "$lr_why" > "$q/lost/$lr_k"; continue; fi
        if [ "$lr_w" = 1 ]; then lr_left=$((lr_left + 1)); continue; fi
        hash_port "$lr_o"
        echo "$lr_o" >> "$q/hashed-late"
        lr_n=$((lr_n + 1))
        # a library port that needs others: kept by its hash, its package needs its manifest
        [ -f "$q/islib/$lr_k" ] && lib_manicheck "$lr_o" "$lr_k"
    done
    [ "$lr_n" = 0 ] ||
        say "the azsupport_hash of $lr_n ports that build against library ports of azsupport or azsupport/static: made with the interfaces of $(grep -c . "$q/azif.hashes") libraries$( [ -s "$q/azst.hashes" ] && echo " and of $(grep -c -v '^common ' "$q/azst.hashes") static ones") (results/hashes.txt)"
    [ "$lr_left" = 0 ] || return 0
    [ "$(ls "$q/libdone" | grep -c .)" -ge "$nlibres" ] || return 0
    # nothing waits any more
    libwait=0
    lr_nl="$(ls "$q/lost" | grep -c .)"
    say "the library ports of azsupport done: $(grep -c . "$q/libloaded") manifests loaded, $(grep -c . "$q/libbuilt") libraries built in this run; the azsupport_hash of $(grep -c . "$q/hashed-late") ports made after them$( [ "$lr_nl" = 0 ] || echo ", $lr_nl ports without one (results/azsupport-interface.txt)")"
    if [ "$dryrun" = 0 ] && [ "$plan" = 0 ]; then
        # shellcheck disable=SC2046
        prefetch $(for lr_o in $(cat "$q/hashed-late"); do [ -s "$q/state/$(key "$lr_o")" ] || echo "$lr_o"; done)
    fi
    return 0
}
# repo_shlibs: "<origin> <file> <SONAME>" for each SONAME each package of the repository
# before this run needs (shlibs_required), once ($q/repo-shlibs): the packages the ABI check
# of a library takes
repo_shlibs() {
    while read -r rs_n rs_o rs_h rs_f; do
        pkg query -F "$repo/$rs_f" '%B' 2> /dev/null | awk -v o="$rs_o" -v f="$rs_f" 'NF { print o, f, $1 }'
    done < "$q/repo-had" > "$q/repo-shlibs.t"
    mv -f "$q/repo-shlibs.t" "$q/repo-shlibs"
}
# lib_abi <lib> <origin> <new package>: the packages of the repository that need the library
# (their shlibs_required meet its SONAMEs: those its new package and its package of the
# repository provide, and those of its manifests; $q/repo-shlibs), but that of its port,
# checked against the new package (tools/azsupport-abi-check.sh: its package in the repository
# before this run the old one; AZSUPPORT_PREFIX the prefix of its manifest, /usr/local for
# x11-fonts/fontconfig); one that fails is built again in this run when it is in the queue
# ($q/abifail/<key>, a line a library) and goes from the repository at the end when it is not
# built (results/abi-check.txt, a part a library). No package of the port in the repository
# before (its first build, the first run after the split): nothing to compare with, so every
# package kept that needs the library is built again
lib_abi() {
    la_l="$1"; la_o="$2"; la_new="$3"
    [ -f "$q/repo-shlibs" ] || repo_shlibs
    la_old="$(awk -v o="$la_o" '$2 == o { print $4; exit }' "$q/repo-had")"
    {
        pkg query -F "$la_new" '%b' 2> /dev/null
        [ -z "$la_old" ] || pkg query -F "$repo/$la_old" '%b' 2> /dev/null
        awk '$1 == "soname" && $3 != "-" { print $3 }' "$q/azif/$la_l.txt" "$q/azold/$la_l.txt" 2> /dev/null
    } | grep . | LC_ALL=C sort -u > "$q/abi-sn-$la_l"
    awk -v o="$la_o" 'NR == FNR { s[$1] = 1; next } $1 != o && ($3 in s) { print $1, $2 }' "$q/abi-sn-$la_l" "$q/repo-shlibs" |
        LC_ALL=C sort -u > "$q/abi-pkgs-$la_l"
    la_np="$(grep -c . "$q/abi-pkgs-$la_l")"
    echo "== $la_l ($la_o): ${la_old:-no package before this run} -> ${la_new##*/}; its SONAMEs: $(tr '\n' ' ' < "$q/abi-sn-$la_l" | sed 's/ $//'); $la_np packages of the repository need them" >> "$res/abi-check.txt"
    if [ -z "$la_old" ] || [ ! -f "$repo/$la_old" ]; then
        echo "no package of $la_o in the repository before this run: the packages kept that need $la_l are built again" >> "$res/abi-check.txt"
        while read -r la_po la_pf; do
            echo "$la_o: no package of it in the repository before this run to compare with" >> "$q/abifail/$(key "$la_po")"
        done < "$q/abi-pkgs-$la_l"
        if [ "$la_np" -gt 0 ]; then
            say "the ABI check of $la_l: no package of $la_o in the repository before this run: the $la_np packages kept that need it are built again"
        else
            say "the ABI check of $la_l: no package of the repository needs it"
        fi
        return 0
    fi
    [ "$la_np" -gt 0 ] || { say "the ABI check of $la_l: no package of the repository needs it"; return 0; }
    la_pre="$(awk '$1 == "prefix" { print $2; exit }' "$q/azif/$la_l.txt" 2> /dev/null)"
    [ -n "$la_pre" ] || la_pre="$(sed -n 22p "$q/info/$(key "$la_o")")"
    la_t0="$(date +%s)"
    # shellcheck disable=SC2046
    AZSUPPORT_PREFIX="$la_pre" AZSUPPORT_ABI_LIB="$la_l" sh "$top/tools/azsupport-abi-check.sh" "$repo/$la_old" "$la_new" "$work/abi" \
        $(awk -v r="$repo" '{ print r "/" $2 }' "$q/abi-pkgs-$la_l") > "$q/abi-$la_l.txt" 2>&1
    la_rc=$?
    cat "$q/abi-$la_l.txt" >> "$res/abi-check.txt"
    la_nf=0
    while read -r la_w la_p la_why; do
        [ "$la_w" = fail ] || continue
        la_po="$(awk -v f="${la_p##*/}" '$2 == f { print $1; exit }' "$q/abi-pkgs-$la_l")"
        [ -n "$la_po" ] || continue
        echo "$la_o: $la_why" >> "$q/abifail/$(key "$la_po")"
        la_nf=$((la_nf + 1))
    done < "$q/abi-$la_l.txt"
    if [ "$la_rc" = 2 ]; then
        say "warning: the ABI check of $la_l could not compare the two packages of $la_o ($(tail -n 1 "$q/abi-$la_l.txt")): the $la_np packages kept that need it are built again"
        while read -r la_po la_pf; do
            echo "$la_o: the ABI check could not compare its two packages" >> "$q/abifail/$(key "$la_po")"
        done < "$q/abi-pkgs-$la_l"
    else
        say "the ABI check of $la_l: $(grep -c -E '^(ok|fail) ' "$q/abi-$la_l.txt") packages of the repository that need it against the new package of $la_o in $(( $(date +%s) - la_t0 ))s, $la_nf failed (results/abi-check.txt; $(head -n 1 "$q/abi-$la_l.txt" | cut -c1-160))"
    fi
}
# run_closure <key>: the ports of this tree a package of the port needs to run, in turn: its
# LIB_ and RUN_DEPENDS of this tree and theirs ($q/rcl/<key>)
run_closure() {
    [ -f "$q/rcl/$1" ] && return 0
    LC_ALL=C sort -u "$q/rdeps/$1" > "$q/rcl/$1.t" 2> /dev/null
    cp "$q/rcl/$1.t" "$q/rcl/$1.new"
    while [ -s "$q/rcl/$1.new" ]; do
        for rc_c in $(cat "$q/rcl/$1.new"); do cat "$q/rdeps/$(key "$rc_c")" 2> /dev/null; done | LC_ALL=C sort -u |
            grep -vxF -f "$q/rcl/$1.t" > "$q/rcl/$1.next"
        cat "$q/rcl/$1.next" >> "$q/rcl/$1.t"
        mv -f "$q/rcl/$1.next" "$q/rcl/$1.new"
    done
    mv -f "$q/rcl/$1.t" "$q/rcl/$1"
}
# lib_cover_check <origin> <package>: the libraries of azsupport the package needs (the
# SONAMEs pkg recorded, shlibs_required, of the manifests loaded: azif.sonames; its own
# library, a library port, left out) that its azsupport_hash does not take ($q/azcov/<key>:
# no library port of theirs among the dependencies to build of the port or of a port it
# needs), and those that none of its dependencies to run brings (its LIB_ and RUN_DEPENDS of
# this tree and theirs to run, in turn: pkg refuses a package whose shared library no
# package has, run 42514624927): said (the text for the line of the summary), into
# $q/uncov/<key>; the run fails on them
lib_cover_check() {
    [ -s "$q/azif.sonames" ] || return 0
    lc_k="$(key "$1")"
    lc_own="$(cat "$q/islib/$lc_k" 2> /dev/null)"
    pkg query -F "$2" '%B' 2> /dev/null | awk -v own="$lc_own" 'NR == FNR { s[$1] = $2; next } ($1 in s) && s[$1] != own { print $1, s[$1] }' "$q/azif.sonames" - |
        LC_ALL=C sort -u > "$q/cov-$lc_k"
    [ -s "$q/cov-$lc_k" ] || return 0
    run_closure "$lc_k"
    lc_m=""; lc_r=""
    while read -r lc_sn lc_l; do
        if ! grep -qxF "$lc_l" "$q/azcov/$lc_k" 2> /dev/null; then
            case " $lc_m " in *" $lc_l "*) ;; *) lc_m="$lc_m $lc_l" ;; esac
        fi
        lc_o="$(awk -v l="$lc_l" '$2 == l { print $1; exit }' "$q/libports")"
        [ -n "$lc_o" ] && grep -qxF "$lc_o" "$q/rcl/$lc_k" && continue
        lc_r="$lc_r $lc_sn (${lc_o:-$lc_l})"
    done < "$q/cov-$lc_k"
    [ -n "$lc_m$lc_r" ] || return 0
    {
        [ -z "$lc_m" ] || echo "$1: its package links$lc_m of azsupport, which its azsupport_hash does not take: name their library ports (azsupport/<lib>) among its dependencies to build"
        [ -z "$lc_r" ] || echo "$1: its package needs$lc_r, which none of its dependencies to run brings (pkg refuses it): LIB_DEPENDS or RUN_DEPENDS on those library ports"
    } > "$q/uncov/$lc_k"
    [ -z "$lc_m" ] || printf '; warning: links%s of azsupport, not in its azsupport_hash (no library port of it among its dependencies to build)' "$lc_m"
    [ -z "$lc_r" ] || printf '; warning: needs%s, not among its dependencies to run' "$lc_r"
}

overlay_rev="$(git -C "$top" log -1 --format='%h %s' 2>/dev/null)"
{
    echo "ports:    freebsd-ports $ports_head${AZSUPPORT_PORTSDIR:+ (AZSUPPORT_PORTSDIR $ports)}"
    echo "overlay:  ${overlay_rev:-?}"
    echo "host:     $(uname -sr), $(cc --version 2>/dev/null | head -n 1)"
    echo "cputype:  $cputype; CFLAGS: $(sed -n 's/^CFLAGS=//p' "$work/make.conf")"
    echo "stamp:    $azsupport_stamp (AZSUPPORT_STAMP: the revision of the packages built in this run)"
    echo "pkg:      $(pkg -v 2>/dev/null); the official packages from: $(printf '%s\n' "$off_repos" | awk 'NF {
        printf "%s%s %s%s", (n++ ? ", " : ""), $1, $2, ($2 == $3 ? "" : " (the machine: " $3 ")") }')"
    echo "repo:     $repo ($(npkg "$repo") packages before the run)"
    echo "queue:    $(wc -l < "$q/queue.txt" | tr -d ' ') ports$( [ "$force" = 1 ] && echo ', --force')$( [ "$serial" = 0 ] && echo ", AZSUPPORT_JOBS=$jobs")$( [ "$dryrun" = 1 ] && echo ', AZSUPPORT_DRYRUN')$( [ "$plan" = 1 ] && echo ', AZSUPPORT_PLAN: the library ports, azsupport/static and the ports they need built, the others only decided')$( [ "$ccheck" = 1 ] && echo ', AZSUPPORT_CONFIGURE_CHECK')"
} > "$sum"

# --- the builds ------------------------------------------------------------------------
# a line of the summary and the state of a port: ok (built), repo (in the repository
# already), fail, skip (needs a port that failed), plan (AZSUPPORT_PLAN: to be built, not
# built); with AZSUPPORT_JOBS above 1 the line goes
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

# time_skip <origin>: a port that is to be built (pre_port said 0) after the time of the
# run is over (AZSUPPORT_TIME_SOFT, or stopped at AZSUPPORT_TIME_HARD): not built, the next run builds
# it; $q/timeskip lists them for results/time-limit
time_skip() {
    record "$1" skip "${pn:-$1}: not built: the time of this run is over (the next run builds it)"
    echo "$1" >> "$q/timeskip"
}

# pre_port <origin>: what is to be done with a port, before its dependencies: 1 when
# that is said already (the line of the summary: it failed, is skipped, its package
# with the same azsupport_hash is in the repository, or AZSUPPORT_PLAN: it is to be built, not
# built), 0 when it is to be built (k, log, pn, ign, h, hs, had set; asked again it
# says nothing more). A package with the same azsupport_hash that failed the ABI check against
# a library port built in this run ($q/abifail/<key>) is built again; one kept has its
# ksrc_get: the sources of the kernel for a port of a kernel module (USES=kmod: its
# SRC_BASE/sys, /usr/src/sys; without them the port says IGNORE "requires kernel source
# files") and for those of AZSUPPORT_KERNEL_SOURCES, once a run and only when such a port is to
# be built: gitup (aZ, 19.11.2026:
# «качай ... через gitup - быстро же») of the branch releng/<release> of the machine,
# with the fixes of the release (aZ: «с последними исправлениями в релизе»), into
# /usr/src, which the chroots get read only (ch_base). gitup is that of the official
# package, unpacked into work/ksrc (pkg fetch, the catalogs of the run): the /usr/local
# of the machine is not touched. 0 when /usr/src/sys is there, else 1 with ksrc_why;
# results/logs/kernel-sources.log
ksrc_state=""
ksrc_why=""
ksrc_get() {
    [ -f /usr/src/sys/Makefile ] && return 0
    [ -n "$ksrc_state" ] && return 1
    ksrc_state=tried
    _kr="$(freebsd-version -u)"; _kr="${_kr%%-*}"
    _kd="$work/ksrc"; _kl="$res/logs/kernel-sources.log"
    mkdir -p "$_kd/root" "$_kd/db" || { ksrc_why="cannot make $_kd"; return 1; }
    say "the sources of the kernel for a port of a kernel module: gitup of releng/$_kr into /usr/src"
    if ! pkg fetch -U -y -r FreeBSD-ports -o "$_kd" gitup > "$_kl" 2>&1; then
        ksrc_why="pkg fetch of gitup failed: $(tail -n 1 "$_kl")"; return 1
    fi
    # pkg fetch -o puts it under All/ or, from a repository of hashed names, All/Hashed/
    _kp="$(find "$_kd" -type f -name 'gitup-*.pkg' | head -n 1)"
    if [ -z "$_kp" ] || ! tar -xf "$_kp" -C "$_kd/root" >> "$_kl" 2>&1 || [ ! -x "$_kd/root/usr/local/bin/gitup" ]; then
        ksrc_why="no gitup out of the package of pkg fetch (${_kp:-none}: $(find "$_kd" -type f | head -n 3 | tr '\n' ' '))"; return 1
    fi
    printf '{\n\t"defaults" : {\n\t\t"host" : "git.freebsd.org",\n\t\t"port" : 443,\n\t\t"verbosity" : 1,\n\t\t"work_directory" : "%s",\n\t},\n\t"src" : {\n\t\t"repository_path" : "/src.git",\n\t\t"branch" : "releng/%s",\n\t\t"target_directory" : "/usr/src",\n\t\t"ignores" : [],\n\t},\n}\n' \
        "$_kd/db" "$_kr" > "$_kd/gitup.conf"
    _kt0="$(date +%s)"
    if ! "$_kd/root/usr/local/bin/gitup" -C "$_kd/gitup.conf" src >> "$_kl" 2>&1 || [ ! -f /usr/src/sys/Makefile ]; then
        ksrc_why="gitup of releng/$_kr failed: $(tail -n 1 "$_kl")"; return 1
    fi
    say "the sources of the kernel: releng/$_kr at $(cat /usr/src/.gituprevision 2> /dev/null) in /usr/src in $(( $(date +%s) - _kt0 ))s"
    return 0
}

# libraries of azsupport checked against its hash and its dependencies to run (lib_cover_check)
pre_port() {
    k="$(key "$1")"
    log="$res/logs/$k.log"
    pn="$(sed -n 1p "$q/info/$k" 2>/dev/null)"
    ign="$(sed -n 2p "$q/info/$k" 2>/dev/null)"
    h="$(cat "$q/hash/$k" 2>/dev/null)"
    hs="$(printf '%s' "$h" | cut -c1-12)"
    had="$(awk -v o="$1" '$2 == o { print $3, $4; exit }' "$q/repo-had")"
    [ -f "$q/tobuild-$k" ] && return 0
    # the library ports and azsupport/static done: the hashes of the ports that build against
    # them first (never in a job)
    if [ "$libwait" = 1 ]; then
        lib_resolve
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
    # a kernel module and no sources of the kernel yet (ksrc_get): kept from the
    # repository as any port, the sources only when it is to be built (below)
    kmod_src=0
    case "$ign" in *"requires kernel source files"*) [ -f /usr/src/sys/Makefile ] || { kmod_src=1; ign=""; } ;; esac
    if [ -n "$ign" ]; then record "$1" fail "$pn: the port says IGNORE: $ign"; return 1; fi
    # no azsupport_hash: it builds against a library port or azsupport/static that this dry run
    # does not build (their interfaces decide), or whose manifests are not there ($q/lost/<key>)
    if [ -z "$h" ]; then
        lw="$(cat "$q/lost/$k" 2> /dev/null)"
        if [ "$dryrun" = 1 ]; then
            record "$1" ok "$pn: dry run: its azsupport_hash is made once ${lw:-the library ports it builds against} is built (the interfaces of the new packages; AZSUPPORT_PLAN builds them and decides)"
        else
            record "$1" fail "$pn: no azsupport_hash (it builds against ${lw:-library ports of azsupport}, whose interfaces are not there)"
        fi
        return 1
    fi
    abi="$(tr '\n' ';' < "$q/abifail/$k" 2> /dev/null | sed 's/;$//; s/;/; /g')"
    # its package in the repository: the same azsupport_hash, another one, none
    if [ -n "$had" ] && [ "$force" = 0 ] && hash_same "$k" "$1" "${had%% *}" && [ -z "$abi" ] && [ ! -f "$q/nomani-$k" ] &&
        ! krb_needs "$repo/${had#* }" > /dev/null; then
        echo "$repo/${had#* }" > "$q/file/$k"
        # kept by the interfaces of libraries built again in this run ($q/ifbuilt)
        ki=""
        if [ -s "$q/ifbuilt" ] && [ -s "$q/azcov/$k" ]; then
            kil="$(grep -xF -f "$q/ifbuilt" "$q/azcov/$k" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
            if [ -n "$kil" ]; then ki="; kept by the interfaces of $kil, built again in this run"; echo "$1" >> "$q/kept-if"; fi
        fi
        record "$1" repo "${had#* }: in the repository already with the same azsupport_hash $hs$hs_how$ki$(lib_cover_check "$1" "$repo/${had#* }")"
        return 1
    fi
    if [ "$force" = 1 ]; then why="--force"
    elif [ -n "$abi" ]; then why="${had#* } fails the ABI check against the new package of $abi"
    elif [ -f "$q/nomani-$k" ]; then why="${had#* } in the repository has no manifests of the interfaces of its libraries"
    elif [ -z "$had" ]; then why="no package of $1 in the repository"
    elif [ "${had%% *}" = - ]; then why="${had#* } in the repository has no azsupport_hash"
    else why="azsupport_hash $hs, not $(printf '%s' "${had%% *}" | cut -c1-12) of ${had#* } in the repository"
    fi
    # AZSUPPORT_PLAN: only the library ports, azsupport/static and the ports they need are built;
    # the libraries of azsupport the package of the repository links checked against the new
    # hash (the same build)
    if [ "$plan" = 1 ] && ! grep -qxF "$1" "$q/azpre"; then
        record "$1" plan "$pn: to be built, azsupport_hash $hs ($why)$( [ -n "$had" ] && lib_cover_check "$1" "$repo/${had#* }")"
        return 1
    fi
    # a kernel module (USES=kmod; make -V says IGNORE for want of the sources only when
    # the target build is defined) or a port of AZSUPPORT_KERNEL_SOURCES: the sources of the
    # kernel first
    if [ "$kmod_src" = 0 ] && [ ! -f /usr/src/sys/Makefile ]; then
        case " $AZSUPPORT_KERNEL_SOURCES " in
        *" ${1%%@*} "*) kmod_src=1 ;;
        *) make -C "$top/$1" AZSUPPORT_STAMP="$azsupport_stamp" -V USES 2> /dev/null | tr ' ' '\n' | grep -qE '^kmod(:|$)' && kmod_src=1 ;;
        esac
    fi
    if [ "$kmod_src" = 1 ]; then
        if ! ksrc_get; then record "$1" fail "$pn: it builds against the sources of the kernel, and there are none: $ksrc_why"; return 1; fi
        ign="$(make -C "$top/$1" AZSUPPORT_STAMP="$azsupport_stamp" -V IGNORE 2> /dev/null)"
        if [ -n "$ign" ]; then record "$1" fail "$pn: the port says IGNORE: $ign"; return 1; fi
    fi
    say "$1: $pn ($why)"
    : > "$q/tobuild-$k"
    return 0
}

# krb_needs <package file>...: the libraries of ch_compat_init (the Kerberos of the base)
# the packages need, said ("<file>: <libraries>"); 0 when one needs any. No package of
# ours on them (aZ, 24.11.2026: the servers have no Kerberos, WITHOUT_KERBEROS; the
# chroots have its libraries for the official tools only, and no build finds them)
krb_needs() {
    [ -s "$q/compat-libs" ] || return 1
    _kr=1
    for _kf in "$@"; do
        _kl="$(pkg query -F "$_kf" '%B' 2> /dev/null | grep -xF -f "$q/compat-libs" | tr '\n' ' ')"
        [ -z "$_kl" ] || { echo "${_kf##*/}: $_kl"; _kr=0; }
    done
    return $_kr
}

# ch_compat_init: the libraries of the base system that the src.conf of the level strips
# and official packages need, for the chroots (work/ch-compat/lib, read only in each at
# /usr/local/lib/azsupport-basecompat, in the hints of the run-time linker): those of the
# package FreeBSD-kerberos-lib of the release (the repository FreeBSD-base of
# pkg.FreeBSD.org, pkgbase). The official curl takes GSSAPI from the base
# (libgssapi_krb5.so.122, libkrb5.so.122), and the worlds of the levels have none
# (WITHOUT_KERBEROS): cargo of the official rust, which links libcurl.so.4, did not start
# (graphics/libimagequant, 24.11.2026; our curl in its place cannot be: it needs the library ports
# of azsupport, and azsupport/gd needs libimagequant). No headers and no path of the linker: only a program
# linked against them before loads them, no build of ours finds them
ch_compat_init() {
    _cc="$work/ch-compat"
    rm -rf "$_cc"
    mkdir -p "$_cc/conf" "$_cc/db" "$_cc/fetch" "$_cc/x" || { say "warning: cannot make $_cc"; return 0; }
    printf '%s\n' 'FreeBSD-base: { url: "pkg+https://pkg.FreeBSD.org/${ABI}/base_release_${VERSION_MINOR}", mirror_type: "srv", signature_type: "fingerprints", fingerprints: "/usr/share/keys/pkgbase-${VERSION_MAJOR}", enabled: yes }' > "$_cc/conf/base.conf"
    echo "== the libraries of Kerberos of the base for the chroots (FreeBSD-base, FreeBSD-kerberos-lib)" >> "$_cl"
    if env PKG_DBDIR="$_cc/db" pkg -R "$_cc/conf" update -f >> "$_cl" 2>&1 &&
        env PKG_DBDIR="$_cc/db" pkg -R "$_cc/conf" fetch -y -o "$_cc/fetch" FreeBSD-kerberos-lib >> "$_cl" 2>&1; then
        _f="$(find "$_cc/fetch" -name 'FreeBSD-kerberos-lib-*.pkg' | head -n 1)"
        if [ -n "$_f" ] && tar -xf "$_f" -C "$_cc/x" 2>> "$_cl" && mkdir -p "$_cc/lib" &&
            cp -p "$_cc"/x/usr/lib/*.so.* "$_cc/lib/" 2>> "$_cl"; then
            ls "$_cc/lib" > "$q/compat-libs"
            say "the chroots: the libraries of Kerberos of the base at /usr/local/lib/azsupport-basecompat ($(basename "$_f" .pkg | sed 's/~.*//')): $(tr '\n' ' ' < "$q/compat-libs")"
            return 0
        fi
    fi
    rm -rf "$_cc/lib"
    say "warning: no libraries of Kerberos of the base for the chroots (results/logs/chroots.log): the official packages that need them do not start there"
    return 0
}

# ch_init: what the chroots of the run share (not for a dry run): the copy of /etc
# (without /etc/ssh: the host keys of the machine are of no build), pkg.conf and the
# repositories of /usr/local/etc/pkg/repos but ours (azsupport, azbuild: in a chroot pkg
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
            if grep -q -E '^[[:space:]]*"?(azsupport|azbuild)"?[[:space:]]*:|azsupport/ports' "$_f"; then
                say "the chroots: without $_f (a repository of ours: the official packages only)"
                continue
            fi
            cp -p "$_f" "$work/ch-local/pkg/repos/"
        done
    fi
    # the official repositories whose url in the chroots is another (off_repos): that url
    # in a file of their own after those of the machine (pkg reads the files in the order
    # of their names, and a later one of the same repository changes only what it says),
    # and not the catalogs of the machine (repos/<name>: pkg update fetches the whole
    # catalog of the url)
    _ox=""
    for _n in $(printf '%s\n' "$off_repos" | awk 'NF && $2 != $3 { print $1 }'); do _ox="$_ox --exclude ./$_n"; done
    if [ -n "$_ox" ]; then
        mkdir -p "$work/ch-local/pkg/repos"
        printf '%s\n' "$off_repos" | awk 'NF && $2 != $3 { printf "%s: { url: \"%s\" }\n", $1, $2 }' > "$work/ch-local/pkg/repos/zz-az-official.conf"
        say "the chroots: $(printf '%s\n' "$off_repos" | awk 'NF && $2 != $3 { printf "%s%s %s (the machine: %s)", (n++ ? ", " : ""), $1, $2, $3 }') (/usr/local/etc/pkg/repos/zz-az-official.conf)"
    fi
    # shellcheck disable=SC2086
    if [ -d "$pkgdb/repos" ]; then (cd "$pkgdb/repos" && tar -cf - $_ox .) | (cd "$work/ch-repos" && tar -xpf -); fi
    ch_compat_init
    _t0="$(date +%s)"
    ch_up _setup || die "no chroot for the run: $why"
    say "a chroot in $(( $(date +%s) - _t0 ))s: $ch_base read only$( [ -z "$world" ] || echo ' (but /usr/src: of the world of AZSUPPORT_WORLD)'), a copy of /etc, devfs$( [ "$ch_fdesc" = 1 ] && echo ', fdescfs')$( [ "$ch_proc" = 1 ] && echo ', procfs'), this tree, the official tree, packages/ and the repository read only (the chroot of each port the same)"
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
    # the official packages of the ports the run may build (those whose azsupport_hash is made:
    # the ports that build against library ports or azsupport/static come once these are done)
    # shellcheck disable=SC2046
    pf_fetch $(cat "$q/queue.txt")
    ch_down "$c" || die "the chroot $c could not be torn down"
    rm -rf "$q/ch/_setup" "$work/pk/_setup"
}
# pf_fetch <origin>...: the official packages of those of the ports the run may build
# (no package with the same azsupport_hash in the repository, or --force, or the ABI check
# failed; make -V worked, no IGNORE, its azsupport_hash made; AZSUPPORT_PLAN: the library ports,
# azsupport/static and the ports they need) fetched into the cache of pkg in the chroot $c
# (results/logs/chroots.log)
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
        [ "$force" = 0 ] && hash_same "$_k" "$_o" "$_hh" && [ ! -f "$q/abifail/$_k" ] && [ ! -f "$q/nomani-$_k" ] && continue
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
# prefetch <origin>...: pf_fetch in a chroot of its own (the ports that build against the
# library ports of azsupport or azsupport/static, once these are done: their hashes are made
# then, lib_resolve)
prefetch() {
    [ $# -gt 0 ] || return 0
    c="$chd/_pf"; cs="$q/ch/_pf"
    if ! ch_up _pf; then
        say "warning: no chroot to fetch the official packages of the ports that build against the libraries of azsupport ($why): each chroot fetches its own"
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

# --- the configure check (AZSUPPORT_CONFIGURE_CHECK=1) -----------------------------------------
# php_port <origin>: a port of PHP: a core lang/phpXY, mod_phpXY, a module phpXY-*
php_port() {
    case "$1" in lang/php[0-9][0-9]|www/mod_php[0-9][0-9]|*/php[0-9][0-9]-*) return 0 ;; esac
    return 1
}
# cc_flags <cc>: the permissive flags the compiler takes (tools/configure-check.sh
# probe in the chroot of the port: the compiler may be one of its packages), once for
# each compiler of the run ($q/ccflags-*, written whole: the builds going at once may
# ask together; none, a compiler not there, is not kept)
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
    _cd="$work/cc/$k"; _pw="$workr/ccw/$k"
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
            ch_run make -C "$top/$1" configure USE_PACKAGE_DEPENDS_ONLY=yes AZSUPPORT_STAMP="$azsupport_stamp" AZSUPPORT_HASH="$h" \
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
    # the distfiles one build at a time (lockf on the machine): the ports building at
    # once may share one (the tarball of PHP of the modules), and two fetches of it at once
    # break it; what fails here make package says again
    ch_run -l "$q/fetch.lock" make -C "$top/$1" checksum USE_PACKAGE_DEPENDS_ONLY=yes \
        AZSUPPORT_STAMP="$azsupport_stamp" AZSUPPORT_HASH="$h" >> "$log" 2>&1
    start="$(date +%s)"
    # AZSUPPORT_RESULTS: the results of the scripts of tools/ (azsupport/static: the line of each library)
    # in results/azsupport-results/<key>, where they stay after make clean
    _pcd="$(port_cache "$k")"
    if [ -n "$_pcd" ]; then
        grep -qxF "$k" "$res/portcache.txt" 2> /dev/null || echo "$k" >> "$res/portcache.txt"
        echo "== the cache of the port between the runs: $_pcd ($(du -sh "$_pcd" 2> /dev/null | cut -f1))" >> "$log"
    fi
    ch_run make -C "$top/$1" clean package USE_PACKAGE_DEPENDS_ONLY=yes AZSUPPORT_STAMP="$azsupport_stamp" AZSUPPORT_HASH="$h" \
        AZSUPPORT_RESULTS="$res/azsupport-results/$k" PACKAGES="$_pk" ${_pcd:+AZSUPPORT_PORT_CACHE_DIR="$_pcd"} >> "$log" 2>&1
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
    # no debug in our packages (aZ, 17.11.2026): the ELF files of each package of the
    # port without debug information and stripped (tools/debug-check.sh), a line each in
    # results/debug-check.txt, of which build.yml makes "debug: OK|FAIL" of the checks
    if [ -f "$top/tools/debug-check.sh" ]; then
        # shellcheck disable=SC2046
        sh "$top/tools/debug-check.sh" $(cat "$q/made-$k") > "$q/debug-$k" 2>&1 ||
            note="; debug: $(grep -c '^FAIL' "$q/debug-$k") of its packages with debug information or not stripped (results/debug-check.txt)"
        cat "$q/debug-$k" >> "$res/debug-check.txt"
    fi
    # shellcheck disable=SC2046
    if _kb="$(krb_needs $(cat "$q/made-$k"))"; then
        # shellcheck disable=SC2046
        rm -f $(cat "$q/made-$k")
        rm -f "$q/file/$k"
        record "$1" fail "$pn: it needs the Kerberos of the base, which the servers have not ($(printf '%s' "$_kb" | tr '\n' ';')): its packages removed"
        return 1
    fi
    [ "$(pkg_hash "$f")" = "$h" ] ||
        note="; warning: no annotation azsupport_hash $hs in the package (PKG_NOTES of Mk/bsd.overlay.mk): the next run builds it again"
    note="$note$(lib_cover_check "$1" "$f")"
    case "$pn" in
        *_"$azsupport_stamp"|*_"$azsupport_stamp",*) ;;
        *) note="$note; warning: the version has not the revision $azsupport_stamp (PORTREVISION= \${AZSUPPORT_STAMP}): no upgrade for pkg" ;;
    esac
    record "$1" ok "$pn: ${secs}s $cht, $(( $(wc -c < "$f") / 1024 )) KB, azsupport_hash $hs$note"
    return 0
}

# AZSUPPORT_PLAN: the library ports, azsupport/static and the ports of this tree they need,
# the ports it builds
: > "$q/azpre"
awk '{ print $1 }' "$q/libports" > "$q/libports.o"
if [ "$plan" = 1 ] && { [ -s "$q/libports" ] || grep -qxF azsupport/static "$q/queue.txt"; }; then
    { cat "$q/libports.o"; grep -xF azsupport/static "$q/queue.txt"; } | LC_ALL=C sort -u > "$q/azpre"
    cp "$q/azpre" "$q/azpre.new"
    while [ -s "$q/azpre.new" ]; do
        for o in $(cat "$q/azpre.new"); do cat "$q/deps/$(key "$o")"; done | LC_ALL=C sort -u | grep -vxF -f "$q/azpre" > "$q/azpre.next" || :
        cat "$q/azpre.next" >> "$q/azpre"
        mv "$q/azpre.next" "$q/azpre.new"
    done
    say "AZSUPPORT_PLAN: built when they are to be: the $(grep -c . "$q/libports") library ports of azsupport$(grep -qxF azsupport/static "$q/azpre" && echo ', azsupport/static') and the ports they need$(grep -vxF -f "$q/libports.o" "$q/azpre" | grep -vxF azsupport/static | tr '\n' ' ' | sed 's/ $//; s/^./: &/'); the other ports only decided"
fi
: > "$q/kept-if"
# the chroots share what ch_init makes (not for a dry run)
[ "$dryrun" = 1 ] || ch_init
if [ "$serial" = 1 ]; then
    # one port after another, in the order of the queue, each in its chroot (the ports
    # that build against library ports of azsupport or azsupport/static have their azsupport_hash
    # once these are done: lib_resolve)
    for o in $(cat "$q/queue.txt"); do
        lib_resolve
        pre_port "$o" || continue
        if time_over; then time_skip "$o"; continue; fi
        if time_short "$o"; then
            say "$o: not started: its build takes about $bm minutes (tools/build-minutes.conf), $((left / 60)) are left until AZSUPPORT_TIME_HARD"
            time_skip "$o"; continue
        fi
        dep_lists "$o"
        say "$o: make package (logs/$k.log)"
        # in a subshell, so that AZSUPPORT_TIME_HARD stops it as with AZSUPPORT_JOBS above 1: it has no line of
        # the summary then and comes again in the next run (time_skip), one with a cache
        # between the runs (AZSUPPORT_PORT_CACHE) from what it did here ($q/timecached)
        ( trap - EXIT HUP INT TERM; job_port "$o" ) &
        jp_=$!
        while kill -0 "$jp_" 2> /dev/null; do
            if hard_over && [ ! -f "$q/stopped" ]; then
                : > "$q/stopped"
                say "the time of this run is over (AZSUPPORT_TIME_HARD): the build of $o is stopped"
                kill_tree "$jp_"
            fi
            sleep 5
        done
        wait "$jp_" 2> /dev/null
        if [ -f "$q/stopped" ] && [ ! -s "$q/state/$k" ]; then
            time_skip "$o"
            [ -n "$(port_cache "$k")" ] && echo "$o" >> "$q/timecached"
        fi
    done
else
    # Waves (AZSUPPORT_JOBS above 1, or AZSUPPORT_DRYRUN): a port is ready once the ports of this tree
    # it needs are done (built, kept, failed or skipped); up to AZSUPPORT_JOBS ports at once,
    # each in a chroot of its own with only its own dependencies (so that the ports
    # building at once never take each other's packages away: one of a pair with the
    # same files, phpXY-mysqlnd and phpXY-mysqlnd-openssl, goes beside the other; azsupport/static
    # and the library ports, NEED_ROOT, as any port, into the /usr/local/azsupport of its chroot), each with its log
    # and its own packages directory; its screen output said when it ends. A port
    # starts as soon as it is ready and a place is free, not after the whole wave
    # before it (aZ, 24.11.2026 13:54: the 37 ports left waited from 13:22 to the end
    # of the run for www/node24 of the wave before them, which 5 of them need): a wave
    # is the ports that came ready together (results/waves.txt); a dry
    # run (AZSUPPORT_DRYRUN), which builds nothing, has them by the levels of the
    # dependencies, as before.
    mkdir -p "$q/sum" "$q/jobs" "$q/inq" "$q/depk"
    : > "$res/waves.txt"
    wave=0
    # the waves of a stage only, the stages one after another
    stage=1
    cp "$q/stage-1.txt" "$q/stage.txt"
    [ "$nst" = 1 ] || say "stage 1 of $nst: $(wc -l < "$q/stage.txt" | tr -d ' ') ports"
    # the keys of the ports of the stage and of the ports each needs, once (the scan
    # below runs after each build that ends, without a process of its own per port)
    stage_keys() {
        : > "$q/stage.k"
        for sk_o in $(cat "$q/stage.txt"); do
            sk_k="$(key "$sk_o")"
            echo "$sk_k=$sk_o" >> "$q/stage.k"
            [ -f "$q/depk/$sk_k" ] && continue
            if [ -f "$q/deps/$sk_k" ]; then tr '/@' '__' < "$q/deps/$sk_k" > "$q/depk/$sk_k"; else : > "$q/depk/$sk_k"; fi
        done
    }
    stage_keys
    # $q/ready: the ports ready to build that have not started ("<size> <origin>", the
    # biggest first: by the size of its package in the repository, the longer builds;
    # those without one after them, in the order they came ready); $q/inq/<key>: a port
    # there, waiting (pend), chosen to start next (nxt) or building
    : > "$q/ready"
    running=0
    # the key of a port of AZSUPPORT_ALONE that builds: nothing starts beside it, and it
    # starts when nothing else builds
    alone_k=""
    # a port of AZSUPPORT_ALONE that cannot start yet (builds going) waits in pend, and the
    # ports ready after it start meanwhile (aZ, 24.11.2026 04:38: lang/gcc16 behind
    # java/openjdk21 held the 38 other ports of its wave for 70 minutes); it starts when
    # no build goes, or earlier when it would no longer end before AZSUPPORT_TIME_HARD
    # (alone_due: then nothing more starts until it does); one that no longer fits at
    # all is not held for (time_short). One port of AZSUPPORT_ALONE waits at a time; a second
    # one, chosen meanwhile, starts when nothing else builds and holds the others
    pend=""
    # the port chosen to start next, until a place is free (and, for a port of AZSUPPORT_ALONE,
    # until no other build goes)
    nxt=""
    while :; do
        # the library ports and azsupport/static done: the hashes of the ports that build
        # against them (none of these is ready before)
        lib_resolve
        # the ports that came ready, those that need no build said at once (the next
        # ones may be ready then)
        more=1
        while [ "$more" = 1 ]; do
            more=0
            : > "$q/cand"
            for ko in $(cat "$q/stage.k"); do
                k="${ko%%=*}"
                [ -s "$q/state/$k" ] && continue
                [ -f "$q/inq/$k" ] && continue
                ready=1
                while read -r dk; do
                    [ -s "$q/state/$dk" ] || { ready=0; break; }
                done < "$q/depk/$k"
                [ "$ready" = 1 ] || continue
                o="${ko#*=}"
                if pre_port "$o" < /dev/null; then echo "$o" >> "$q/cand"; else more=1; fi
            done
        done
        if [ ! -s "$q/cand" ] && [ ! -s "$q/ready" ] && [ -z "$pend$nxt" ] && [ "$running" -eq 0 ]; then
            # nothing ready, waiting or building: the stage is done (the next one), or a
            # loop in the dependencies (the first port left in the order of the queue, as
            # with AZSUPPORT_JOBS=1)
            o=""
            for ko in $(cat "$q/stage.k"); do
                [ -s "$q/state/${ko%%=*}" ] || { o="${ko#*=}"; break; }
            done
            if [ -z "$o" ]; then
                stage=$((stage + 1))
                [ "$stage" -le "$nst" ] || break
                cp "$q/stage-$stage.txt" "$q/stage.txt"
                say "stage $stage of $nst: $(wc -l < "$q/stage.txt" | tr -d ' ') ports"
                stage_keys
                continue
            fi
            pre_port "$o" || continue
            echo "$o" > "$q/cand"
        fi
        if [ -s "$q/cand" ]; then
            wave=$((wave + 1))
            say "wave $wave: $(wc -l < "$q/cand" | tr -d ' ') ports ready, up to $jobs builds at once ($running going): $(tr '\n' ' ' < "$q/cand")"
            echo "wave $wave: $(tr '\n' ' ' < "$q/cand" | sed 's/ $//')" >> "$res/waves.txt"
            if [ "$dryrun" = 1 ]; then
                for o in $(cat "$q/cand"); do pre_port "$o"; record "$o" ok "$pn: dry run, not built"; done
                continue
            fi
            for o in $(cat "$q/cand"); do
                pre_port "$o"
                : > "$q/inq/$k"
                sz=0
                [ -n "$had" ] && [ -f "$repo/${had#* }" ] && sz="$(wc -c < "$repo/${had#* }" | tr -d ' ')"
                echo "$sz $o"
            done > "$q/cand.sz"
            cat "$q/ready" "$q/cand.sz" | sort -s -k1,1nr > "$q/ready.t" && mv "$q/ready.t" "$q/ready"
        fi
        # the next port to start: the one chosen before; else the port of AZSUPPORT_ALONE that
        # waits, when no build goes or it is due; else the biggest ready one
        if [ -z "$nxt" ]; then
            if [ -n "$pend" ]; then
                pre_port "$pend"
                if time_over; then time_skip "$pend"; pend=""; continue
                elif time_short "$pend"; then
                    say "$pend: not started: its build takes about $bm minutes (tools/build-minutes.conf), $((left / 60)) are left until AZSUPPORT_TIME_HARD"
                    time_skip "$pend"; pend=""; continue
                fi
            fi
            if [ -n "$pend" ] && { [ "$running" -eq 0 ] || alone_due "$pend"; }; then
                nxt="$pend"; pend=""
            elif [ -s "$q/ready" ]; then
                nxt="$(sed -n '1s/^[0-9]* //p' "$q/ready")"
                sed 1d "$q/ready" > "$q/ready.t" && mv "$q/ready.t" "$q/ready"
                case " $AZSUPPORT_ALONE " in
                    *" ${nxt%%@*} "*)
                        if [ -z "$pend" ] && [ "$running" -gt 0 ] && ! alone_due "$nxt"; then
                            pend="$nxt"; nxt=""
                            say "$pend: waits for the builds going (AZSUPPORT_ALONE: nothing beside it); the ports ready after it start meanwhile"
                            continue
                        fi ;;
                esac
            fi
        fi
        alone=0
        if [ -n "$nxt" ]; then case " $AZSUPPORT_ALONE " in *" ${nxt%%@*} "*) alone=1 ;; esac; fi
        # it starts now if a place is free, no port of AZSUPPORT_ALONE builds, and, being one
        # itself, no other build goes
        if [ -n "$nxt" ] && [ "$running" -lt "$jobs" ] && [ -z "$alone_k" ] && { [ "$alone" = 0 ] || [ "$running" -eq 0 ]; }; then
            o="$nxt"; nxt=""
            pre_port "$o"
            if time_over; then time_skip "$o"; continue; fi
            if time_short "$o"; then
                say "$o: not started: its build takes about $bm minutes (tools/build-minutes.conf), $((left / 60)) are left until AZSUPPORT_TIME_HARD"
                time_skip "$o"; continue
            fi
            # what it gets in its chroot, worked out here (not in the jobs beside it)
            dep_lists "$o"
            # its make -j: the processes of all the builds (AZSUPPORT_JOBS times MAKE_JOBS_NUMBER)
            # shared by the builds that can go at once now (those going, this one and the
            # ports ready after it, up to AZSUPPORT_JOBS), and one more (aZ, 25.11.2026 00:03:
            # 17, 9, 6, 5 on the 16 cores of the jail; azsupport/azsupport (the libraries then), alone in its wave, built with
            # make -j 4); a port of AZSUPPORT_ALONE, which builds alone, as one alone
            pj="${MAKE_JOBS_NUMBER:-}"
            if [ -n "$pj" ]; then
                _nr="$(grep -c . "$q/ready" 2> /dev/null)" || _nr=0
                _n=$((running + 1 + _nr)); [ "$_n" -le "$jobs" ] || _n="$jobs"
                [ "$alone" = 0 ] || _n=1
                pj=$((jobs * MAKE_JOBS_NUMBER / _n + 1))
            fi
            if [ "$alone" = 1 ]; then
                alone_k="$k"
                say "$o: make package (logs/$k.log)${pj:+, make -j $pj}, alone (AZSUPPORT_ALONE: no other build beside it)"
            else
                say "$o: make package (logs/$k.log)${pj:+, make -j $pj}"
            fi
            # .done after the subshell of the build, also if it ends early: the loop
            # below would otherwise wait for it until the timeout of the job; the traps
            # of the run (all chroots away) are not those of a job
            echo "$o" > "$q/jobs/$k.origin"
            date +%s > "$q/jobs/$k.start"
            ( trap - EXIT HUP INT TERM; [ -z "$pj" ] || MAKE_JOBS_NUMBER="$pj"; ( job_port "$o" ) > "$q/jobs/$k.out" 2>&1; : > "$q/jobs/$k.done" ) &
            echo $! > "$q/jobs/$k.pid"
            running=$((running + 1))
            continue
        fi
        # nothing builds and nothing can start: the scan above ends the stage
        [ "$running" -gt 0 ] || continue
        # nothing more can start now: wait until a build ends (the ports that need it
        # may be ready then), each writes $q/jobs/<key>.done when it ends
        reaped=0
        while :; do
            for dn in "$q"/jobs/*.done; do
                [ -f "$dn" ] || continue
                jk="${dn##*/}"; jk="${jk%.done}"
                wait "$(cat "$q/jobs/$jk.pid")" 2> /dev/null
                cat "$q/jobs/$jk.out"
                # a build stopped at AZSUPPORT_TIME_HARD (no line of the summary): not built,
                # the next run builds it (time_skip); one with a cache between the runs
                # (AZSUPPORT_PORT_CACHE) goes on there from what it did here ($q/timecached).
                # One gone without a result otherwise failed (else it would come ready
                # again and again)
                if [ ! -s "$q/state/$jk" ] && [ -s "$q/jobs/$jk.origin" ]; then
                    jo="$(cat "$q/jobs/$jk.origin")"
                    pn="$(sed -n 1p "$q/info/$jk" 2> /dev/null)"
                    if [ -f "$q/stopped" ]; then
                        time_skip "$jo"
                        [ -n "$(port_cache "$jk")" ] && echo "$jo" >> "$q/timecached"
                    else
                        record "$jo" fail "${pn:-$jo}: its build ended without a result (logs/$jk.log)"
                    fi
                fi
                rm -f "$dn" "$q/jobs/$jk.pid" "$q/jobs/$jk.out" "$q/jobs/$jk.origin" "$q/jobs/$jk.start"
                running=$((running - 1))
                reaped=1
                if [ "$jk" = "$alone_k" ]; then alone_k=""; fi
            done
            [ "$reaped" = 0 ] || break
            # AZSUPPORT_TIME_HARD: the builds still going are stopped once (the tree of each
            # job under its subshell, which then writes its .done); they have no state
            # and come again as not built (time_skip). A job whose subshell is gone
            # without a .done counts as done, so that this loop never waits on it
            if hard_over && [ ! -f "$q/stopped" ]; then
                : > "$q/stopped"
                say "the time of this run is over (AZSUPPORT_TIME_HARD): the $running builds still going are stopped"
                for pf in "$q"/jobs/*.pid; do
                    [ -f "$pf" ] || continue
                    for c_ in $(pgrep -P "$(cat "$pf")" 2> /dev/null); do kill_tree "$c_"; done
                done
            fi
            for pf in "$q"/jobs/*.pid; do
                [ -f "$pf" ] || continue
                jk="${pf##*/}"; jk="${jk%.pid}"
                [ -f "$q/jobs/$jk.done" ] || kill -0 "$(cat "$pf")" 2> /dev/null || : > "$q/jobs/$jk.done"
            done
            sleep 1
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
        echo "The configure check (AZSUPPORT_CONFIGURE_CHECK=1, tools/configure-check.sh): each PHP port"
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

# results/azsupport-interface.txt: the library ports of azsupport in this run (built or kept,
# the interface hash and the closure of each library), azsupport/static, the interfaces that
# changed against the repository before this run (of the libraries built again), the ABI
# check (results/abi-check.txt, a part a library), the ports that take interfaces of
# azsupport (and those kept by them while a library they use was built again), the packages
# that link libraries of azsupport their azsupport_hash does not take or their dependencies
# to run do not bring (the run fails), and the ports that got no azsupport_hash
if [ -s "$q/libports" ] || [ "$stq" = 1 ]; then
    : > "$q/azdiff"; : > "$q/azstdiff"
    for l in $(LC_ALL=C sort -u "$q/libbuilt"); do
        if [ ! -f "$q/azif/$l.txt" ]; then echo "$l: no manifest in its new package"; continue; fi
        if [ ! -f "$q/azold/$l.txt" ]; then echo "$l: new (no manifest of it in the repository before this run)"; continue; fi
        rm -rf "$q/ifo" "$q/ifn" && mkdir -p "$q/ifo" "$q/ifn"
        cp "$q/azold/$l.txt" "$q/ifo/" && cp "$q/azif/$l.txt" "$q/ifn/"
        sh "$top/tools/azsupport-interface.sh" diff "$q/ifo" "$q/ifn" 2>&1
    done > "$q/azdiff"
    if [ "$(st azsupport/static)" = ok ] && [ -n "$asold" ] && [ -s "$q/azst.hashes" ]; then
        sh "$top/tools/azsupport-interface.sh" diff "$q/azstold" "$q/azst" > "$q/azstdiff" 2>&1
    fi
    nlb="$(LC_ALL=C sort -u "$q/libbuilt" | grep -c .)"
    nki="$(grep -c . "$q/kept-if")"
    nabi="$(grep -c -E '^(ok|fail) ' "$res/abi-check.txt" 2> /dev/null)"; nabf="$(grep -c '^fail ' "$res/abi-check.txt" 2> /dev/null)"
    {
        echo "The library ports of azsupport in this run: the library, its port, built or kept, its interface hash and its closure (tools/azsupport-interface.sh)"
        while read -r lo ll; do
            case "$(st "$lo")" in
                ok) w=built ;;
                repo) w=kept ;;
                '') w="not done" ;;
                *) w="$(st "$lo")" ;;
            esac
            ih="$(awk -v n="$ll" '$1 == n { print substr($2, 1, 12), $4; exit }' "$q/azif.hashes")"
            printf '  %-14s %-26s %-8s %s\n' "$ll" "$lo" "$w" "${ih:-(no manifest)}"
        done < "$q/libports"
        if [ "$stq" = 1 ]; then
            case "$(st azsupport/static)" in
                ok) w="built in this run ($(basename "$(cat "$q/file/azsupport_static" 2> /dev/null)"))" ;;
                repo) w="kept from the repository ($(basename "$(cat "$q/file/azsupport_static" 2> /dev/null)"))" ;;
                '') w="not done" ;;
                *) w="$(st azsupport/static)" ;;
            esac
            echo "azsupport/static (the static tree): $w; the interfaces of its $(grep -c -v '^common ' "$q/azst.hashes") static libraries"
        fi
        if [ "$nlb" -gt 0 ]; then
            if [ -s "$q/azdiff" ]; then
                echo "the interfaces that changed against the repository before this run (of the $nlb libraries built again):"
                sed 's/^/  /' "$q/azdiff"
            else
                echo "against the repository before this run: no interface of the $nlb libraries built again changed"
            fi
            grep -q 'of before the split' "$q/azold.src" &&
                echo "  (the manifests before: of the package of azsupport/azsupport of before the split, its files of the static tree left out: $(grep -c 'of before the split' "$q/azold.src") libraries)"
        fi
        if [ "$(st azsupport/static)" = ok ]; then
            if [ -z "$asold" ]; then
                echo "azsupport/static: no package with manifests of it in the repository before this run: its static interfaces not compared"
            elif [ -s "$q/azstdiff" ]; then
                echo "the static interfaces that changed against azsupport/static of the repository before this run ($asold):"
                sed 's/^/  /' "$q/azstdiff"
            else
                echo "against azsupport/static of the repository before this run ($asold): no static interface changed"
            fi
        fi
        if [ -s "$res/abi-check.txt" ]; then
            echo "the ABI check of the packages of the repository that need a library built again (tools/azsupport-abi-check.sh, results/abi-check.txt):"
            grep -E '^(== |no package of )' "$res/abi-check.txt" | sed 's/^== //; s/^/  /' | cut -c1-300
            echo "  $((nabi - nabf)) passed, $nabf failed"
            grep '^fail ' "$res/abi-check.txt" | sed 's/^/  /'
        fi
        ntake=0
        for o in $(cat "$q/queue.txt"); do [ -s "$q/azcov/$(key "$o")" ] && ntake=$((ntake + 1)); done
        echo "ports of the queue whose azsupport_hash takes interfaces of azsupport: $ntake; kept by them while a library they use was built again in this run: $nki"
        [ -s "$q/kept-if" ] && tr '\n' ' ' < "$q/kept-if" | fold -s -w 100 | awk '{ sub(/ *$/, ""); print "  " $0 }'
        if [ -n "$(ls "$q/uncov")" ]; then
            echo "packages that link libraries of azsupport their azsupport_hash does not take, or that their dependencies to run do not bring:"
            cat "$q"/uncov/* | sed 's/^/  /'
        fi
        if [ -n "$(ls "$q/lost")" ]; then
            echo "ports without an azsupport_hash (a library port or azsupport/static they build against gave no manifests):"
            for f in "$q"/lost/*; do echo "  $(awk -v k="${f##*/}" '{ o = $0; gsub(/[\/@]/, "_", o) } o == k { print; exit }' "$q/queue.txt"): $(cat "$f")"; done
        fi
    } > "$res/azsupport-interface.txt"
    nlk=0; nlx=0
    while read -r lo ll; do
        case "$(st "$lo")" in repo) nlk=$((nlk + 1)) ;; ok) ;; *) nlx=$((nlx + 1)) ;; esac
    done < "$q/libports"
    if [ "$nlb" -gt 0 ]; then
        lbl=" ($(LC_ALL=C sort -u "$q/libbuilt" | head -n 12 | tr '\n' ' ' | sed 's/ $//')$( [ "$nlb" -gt 12 ] && echo " and $((nlb - 12)) more"))"
    else
        lbl=""
    fi
    if [ -s "$q/azdiff" ]; then azw="interfaces changed: $(cut -d: -f1 "$q/azdiff" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
    elif [ "$nlb" -gt 0 ]; then azw="no interface changed"
    else azw="no library built again"
    fi
    [ -s "$q/azstdiff" ] && azw="$azw; static interfaces changed: $(cut -d: -f1 "$q/azstdiff" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
    echo "libraries: $nlb built$lbl, $nlk kept$( [ "$nlx" = 0 ] || echo ", $nlx failed or not built")$( [ "$stq" = 1 ] && echo "; azsupport/static $(case "$(st azsupport/static)" in ok) echo built ;; repo) echo kept ;; *) st azsupport/static ;; esac)"); $azw; $nki ports kept by interface; ABI check: $nabf of $nabi packages failed (results/azsupport-interface.txt)" >> "$sum"
fi
# AZSUPPORT_PLAN: results/plan.txt, the ports to be built (and why) and the counts
if [ "$plan" = 1 ]; then
    npl="$(awk '$2 == "PLAN"' "$sum" | grep -c .)"
    nkp="$(for o in $(cat "$q/queue.txt"); do [ "$(st "$o")" = repo ] && echo "$o"; done | grep -c .)"
    nbu="$(for o in $(cat "$q/queue.txt"); do [ "$(st "$o")" = ok ] && echo "$o"; done | grep -c .)"
    {
        echo "The plan of the run (AZSUPPORT_PLAN): $npl ports to be built, $nkp kept from the repository, $nbu built in this run (the library ports, azsupport/static and the ports they need, when they were to be built)"
        awk '$2 == "PLAN" || ($1 ~ /\// && $2 == "OK") { print }' "$sum"
    } > "$res/plan.txt"
    echo "plan:     $npl to be built, $nkp kept from the repository, $nbu built (results/plan.txt)" >> "$sum"
    say "the plan (AZSUPPORT_PLAN): $npl ports to be built, $nkp kept, $nbu built (results/plan.txt)"
fi

if [ "$dryrun" = 1 ]; then
    echo "dry run: the waves in results/waves.txt, nothing built, no repository" >> "$sum"
    say "dry run (AZSUPPORT_DRYRUN): $wave waves (results/waves.txt), nothing built"
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
        # broken with a library built again, and not built again in this run: the next run builds it
        say "the repository: $f away: it fails the ABI check against the new package of $(tr '\n' ';' < "$q/abifail/$(key "$og")" | sed 's/;$//; s/;/; /g')"
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
# no manual pages, docs or info pages in a package (aZ, 20.11.2026): every package of the
# repository, built now or kept (tools/docs-check.sh); results/docs-check.txt, of which
# build.yml makes "docs: OK|FAIL" of the checks (a FAIL keeps the run from being published)
if [ -f "$top/tools/docs-check.sh" ]; then
    # shellcheck disable=SC2046
    sh "$top/tools/docs-check.sh" "$repo"/*.pkg > "$res/docs-check.txt" 2>&1 ||
        say "docs: $(grep -c '^FAIL' "$res/docs-check.txt") of the packages of the repository with manual pages, docs or info pages (results/docs-check.txt)"
fi
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
# the time of the run was over (AZSUPPORT_TIME_SOFT, AZSUPPORT_TIME_HARD): results/time-limit, its
# first line for build.yml (built=, kept=, not_built_for_time=), then the ports
if [ -s "$q/timeskip" ]; then
    {
        echo "built=$nok kept=$nkept not_built_for_time=$(wc -l < "$q/timeskip" | tr -d ' ') cached=$(cat "$q/timecached" 2> /dev/null | wc -l | tr -d ' ')"
        echo "the time of this run was over: these ports were not built (the next run builds them, and the ports that need them):"
        cat "$q/timeskip"
    } > "$res/time-limit"
    say "the time of this run was over: $(sed -n 1p "$res/time-limit") (results/time-limit)"
fi
# the packages kept by their azsupport_hash as it was made before 24.11.2026 (hash_same):
# results/hash-legacy.txt, the lines for tools/azsupport-hash-legacy.txt (in the summary of a
# plan, AZSUPPORT_PLAN, each as "legacy <level> <origin> <that hash> <the azsupport_hash now>")
LC_ALL=C sort -u "$q/legacy" > "$res/hash-legacy.txt"
if [ -s "$res/hash-legacy.txt" ]; then
    echo "old azsupport_hash: $(wc -l < "$res/hash-legacy.txt" | tr -d ' ') packages of the repository kept by their azsupport_hash as it was made before 24.11.2026 (results/hash-legacy.txt, tools/azsupport-hash-legacy.txt)" >> "$sum"
    [ "$plan" = 1 ] && sed 's/^/legacy /' "$res/hash-legacy.txt" >> "$sum"
fi
# the packages that link libraries of azsupport their azsupport_hash does not take, or that
# their dependencies to run do not bring (lib_cover_check)
uncov="$(cd "$q/uncov" && ls | sed 's/_/\//' | tr '\n' ' ' | sed 's/ $//')"
echo "built:    $nok, kept from the repository: $nkept$( [ "$plan" = 1 ] && echo ", to be built (AZSUPPORT_PLAN): $nplan")${failed:+, failed:$failed}${skipped:+, not built:$skipped}" >> "$sum"
if [ -z "$failed" ] && [ -z "$skipped" ] && [ "$repo_ok" = 1 ] && [ -z "$uncov" ]; then
    echo "result:   OK" >> "$sum"
    say "OK: $nok built, $nkept kept from the repository ($repo)"
    exit 0
fi
r=""
[ -n "$failed" ] && r="failed:$failed"
[ -n "$skipped" ] && r="${r:+$r; }not built:$skipped"
[ "$repo_ok" = 1 ] || r="${r:+$r; }pkg repo failed"
[ -n "$uncov" ] && r="${r:+$r; }libraries of azsupport not in the azsupport_hash or not among the dependencies to run (results/azsupport-interface.txt): $uncov"
echo "result:   FAIL ($r)" >> "$sum"
say "FAIL ($r)"
exit 1
