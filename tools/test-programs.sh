#!/bin/sh
# test-programs.sh - the tests of the programs and libraries of the repository that
# tools/build.sh made, installed from it as a server installs them: az, curl,
# ffmpeg, ImageMagick6, ImageMagick7, GraphicsMagick, mc and yt-dlp, by
# tools/az-test.sh, curl-test.sh, ffmpeg-test.sh, imagemagick-test.sh,
# graphicsmagick-test.sh, mc-test.sh and ytdlp-test.sh (yt-dlp with our ffmpeg),
# the utilities of the official ports (Mk/az-official.mk) by utils-test.sh, and the
# server packages (git, Apache, memcached, MariaDB, vsftpd-ext, BIND and its tools,
# vips, qt-faststart) by servers-test.sh.
#
# Usage (as root on FreeBSD, after tools/build.sh and the checks of PHP):
#   sh tools/test-programs.sh [--repo <dir>]
#
#   --repo <dir>  the repository of tools/build.sh (default: work/repo)
#
# 1. The samples (ffmpeg-test.sh --samples, imagemagick-test.sh --samples) are made
#    with the official packages, which those scripts install (ffmpeg-nox11,
#    ImageMagick7-nox11, dejavu), so ours with the same files go first (pkg delete
#    -f: the PHP modules that need them stay); after the samples the official ones
#    go again (pkg delete, pkg autoremove); dejavu stays, its fonts are those of the
#    tests of the text.
# 2. Ours from the repository, as the repository "azbuild" of pkg (file://, priority
#    100; as tools/install-php.sh): pkg install -f of each of the seven the repository
#    has, so that every one is that of the repository.
# 3. Each test (with the packages it needs; a test whose package is not in the
#    repository is skipped, with the reason): its results in
#    results/<test>-results/, a line in results/checks.txt ("test <name>: OK",
#    "FAIL (...)" or "SKIP (...)").
# Exit status: 0 no test failed, 1 a test failed or ours did not install, 2 a wrong
# call or no catalog in the repository.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n 's/^# \{0,1\}//; 7,10p' "$0" >&2; exit "${1:-2}"; }
say() { printf '[test-programs %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

repo=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --repo=*) repo="${1#--repo=}"; shift ;;
        -h|--help) usage 0 ;;
        *) say "unknown argument $1" >&2; usage ;;
    esac
done
[ "$(uname -s)" = FreeBSD ] || { say "FreeBSD only" >&2; exit 2; }
[ "$(id -u)" = 0 ] || { say "as root (pkg install, pkg delete)" >&2; exit 2; }
res="$top/results"
mkdir -p "$res" || exit 2
checks="$res/checks.txt"
log="$res/test-programs.log"
: > "$log"
line() { echo "test $1" >> "$checks"; say "test $1"; }
repo="${repo:-${AZ_WORK:-$top/work}/repo}"
repo="$(cd "$repo" 2>/dev/null && pwd)"
if [ -z "$repo" ] || [ ! -f "$repo/meta.conf" ]; then
    line "programs: SKIP (no catalog in the repository ${repo:-given}: $(tail -n 1 "$res/pkg-repo.log" 2>/dev/null))"
    exit 2
fi
export ASSUME_ALWAYS_YES=yes
conf=/usr/local/etc/pkg/repos/azbuild.conf
mkdir -p "${conf%/*}"
printf 'azbuild: { url: "file://%s", signature_type: "none", priority: 100, enabled: yes }\n' "$repo" > "$conf"
if ! pkg update -f -r azbuild >> "$log" 2>&1; then
    line "programs: FAIL (pkg update of the repository $repo failed: test-programs.log)"
    exit 1
fi
have="$(pkg rquery -r azbuild '%n' 2>> "$log" | LC_ALL=C sort -u)"
in_repo() { printf '%s\n' "$have" | grep -qx "$1"; }
rc=0

# 1. the samples, with the official packages
for p in ImageMagick7 ffmpeg; do
    pkg info -e "$p" || continue
    say "pkg delete -f $p (the samples are made with the official package)"
    pkg delete -y -f "$p" >> "$log" 2>&1 || say "pkg delete -f $p failed (test-programs.log)"
done
# the official packages of a sample away before the next: ImageMagick7-nox11 of the
# ports needs their ffmpeg, which conflicts with ffmpeg-nox11 of the ffmpeg samples
# (pkg stopped, and the samples were made with ours: build.yml 42533903453)
# the HLS stream of ytdlp-test.sh too, when the repository has yt-dlp
for t in ffmpeg imagemagick $(in_repo yt-dlp && echo ytdlp); do
    say "$t-test.sh --samples"
    (cd "$res" && sh "$top/tools/$t-test.sh" --samples) >> "$log" 2>&1 ||
        say "$t-test.sh --samples failed: its test says so (test-programs.log)"
    for p in ImageMagick7-nox11 ImageMagick7 ffmpeg-nox11 ffmpeg; do
        pkg info -e "$p" || continue
        say "pkg delete $p (the official package of the samples)"
        pkg delete -y "$p" >> "$log" 2>&1 || say "pkg delete $p failed (test-programs.log)"
    done
done
pkg autoremove -y >> "$log" 2>&1
# autoremove takes the build tools that came as dependencies too, pkgconf among them:
# the link tests of az-test.sh need pkg-config (they failed with no word without it)
say "pkg install pkgconf (pkg-config of the link tests of az-test.sh)"
pkg install -y pkgconf >> "$log" 2>&1 || say "pkg install pkgconf failed (test-programs.log)"

# 2. ours from the repository
# inst <package>: installed from the repository: the annotation repository of the
# installed package (pkg query %R of pkg 2 says nothing for installed packages)
inst() { [ "$(pkg query '%At %Av' "$1" 2>/dev/null | awk '$1 == "repository" { print $2; exit }')" = azbuild ]; }
# again <log> <package>...: those pkg left from another repository, installed there
# already (the official rsync of the VM: pkg install -f reinstalled it from
# FreeBSD-ports, build.yml 42905358029), once more with -r azbuild: their
# dependencies are installed by then
again() {
    _l="$1"; shift
    _a=""
    for _p in "$@"; do inst "$_p" || _a="$_a $_p"; done
    [ -n "$_a" ] || return 0
    say "pkg install -f -r azbuild$_a: pkg left them from another repository"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f -r azbuild $_a >> "$_l" 2>&1 ||
        say "pkg install -f -r azbuild$_a says it failed (${_l##*/})"
}
want=""
for p in az curl ffmpeg ImageMagick6 ImageMagick7 GraphicsMagick mc; do
    if in_repo "$p"; then want="$want $p"; else say "$p: not in the repository, its tests are skipped"; fi
done
if [ -n "$want" ]; then
    say "pkg install -f$want"
    # shellcheck disable=SC2086
    # CONSERVATIVE_UPGRADE=no: the official curl a build dependency brought stays
    # from its repository otherwise (pkg install -f reinstalled it from FreeBSD-ports)
    # -r azbuild: pkg install -f reinstalled the curl of FreeBSD-ports even so
    # (build.yml 42533903453); their dependencies are ours or installed already
    CONSERVATIVE_UPGRADE=no pkg install -y -f -r azbuild $want > "$res/test-programs-install.log" 2>&1 || say "pkg install says it failed (test-programs-install.log)"
    cat "$res/test-programs-install.log" >> "$log"
fi
# yt-dlp by itself and without -r azbuild: its python packages are official ones
# (FreeBSD-ports), which pkg autoremove took above; yt-dlp is still that of azbuild
# (priority 100), as inst() checks
if in_repo yt-dlp; then
    say "pkg install -f yt-dlp"
    pkg install -y -f yt-dlp > "$res/test-programs-install-yt-dlp.log" 2>&1 || say "pkg install yt-dlp says it failed (test-programs-install-yt-dlp.log)"
    cat "$res/test-programs-install-yt-dlp.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-yt-dlp.log" >> "$log"
    want="$want yt-dlp"
else
    say "yt-dlp: not in the repository, its tests are skipped"
fi
# the utilities (official ports, Mk/az-official.mk; wget and rsync ours) as yt-dlp:
# what some of the official ones take (indexinfo of bash) are official packages
utils="3proxy bash bsddialog bsnmp-ucd portmaster rsync screen sudo unzip wget yamdi zip"
u_=""
for p in $utils; do in_repo "$p" && u_="$u_ $p"; done
if [ -n "$u_" ]; then
    say "pkg install -f$u_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $u_ > "$res/test-programs-install-utils.log" 2>&1 || say "pkg install of the utilities says it failed (test-programs-install-utils.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-utils.log" $u_
    cat "$res/test-programs-install-utils.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-utils.log" >> "$log"
    want="$want$u_"
fi
# the server packages (aZ, 10.11.2026) as the utilities: git, Apache with
# mod_maxminddb, memcached, MariaDB, vsftpd-ext, the BIND tools, qt-faststart
servers="apache24 ap24-mod_maxminddb bind-tools bind920 git mariadb1011-client mariadb1011-server memcached qt-faststart vips vsftpd-ext"
s_=""
for p in $servers; do in_repo "$p" && s_="$s_ $p"; done
if [ -n "$s_" ]; then
    say "pkg install -f$s_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $s_ > "$res/test-programs-install-servers.log" 2>&1 || say "pkg install of the server packages says it failed (test-programs-install-servers.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-servers.log" $s_
    cat "$res/test-programs-install-servers.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-servers.log" >> "$log"
    want="$want$s_"
fi
# every installed package the repository has, from the repository: a dependency pkg
# kept or took from another one (the official glib, which mc then loaded with the
# libintl and libiconv of /usr/local/lib: run 42994770290), once more with -r azbuild
deps_=""
for p in $(pkg query '%n' 2> /dev/null | LC_ALL=C sort -u); do
    in_repo "$p" && ! inst "$p" && deps_="$deps_ $p"
done
if [ -n "$deps_" ]; then
    # shellcheck disable=SC2086
    again "$res/test-programs-install-deps.log" $deps_
    cat "$res/test-programs-install-deps.log" >> "$res/test-programs-install.log" 2> /dev/null
    cat "$res/test-programs-install-deps.log" >> "$log" 2> /dev/null
fi
for p in $want; do
    inst "$p" && continue
    say "$p did not install from the repository; what pkg said:"
    sed 's/^/    | /' "$res/test-programs-install.log"
    rc=1
done

# 3. the tests: name, the packages it needs
for spec in "az az ImageMagick7 GraphicsMagick" "curl curl" "ffmpeg ffmpeg" "imagemagick ImageMagick6 ImageMagick7" \
        "graphicsmagick GraphicsMagick" "mc mc" "ytdlp yt-dlp ffmpeg" "utils $utils" ${s_:+"servers$s_"}; do
    # shellcheck disable=SC2086
    set -- $spec
    t="$1"; shift
    miss=""
    for p in "$@"; do inst "$p" || miss="$miss $p"; done
    if [ -n "$miss" ]; then
        line "$t: SKIP (not installed from the repository:$miss)"
        continue
    fi
    if [ ! -f "$top/tools/$t-test.sh" ]; then
        line "$t: SKIP (no tools/$t-test.sh)"
        continue
    fi
    say "$t-test.sh"
    r=0
    (cd "$res" && AZ_RESULTS="$res/$t-results" sh "$top/tools/$t-test.sh") > "$res/$t-test.log" 2>&1 || r=$?
    tail -n 3 "$res/$t-test.log" | sed 's/^/    | /'
    if [ "$r" = 0 ]; then
        line "$t: OK ($t-results/tests.txt)"
    else
        line "$t: FAIL ($t-results/tests.txt, exit $r: $(grep -m 1 '^FAIL' "$res/$t-results/tests.txt" 2>/dev/null | cut -c1-160))"
        rc=1
    fi
done
exit "$rc"
