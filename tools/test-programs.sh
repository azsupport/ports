#!/bin/sh
# test-programs.sh - the tests of the programs and libraries of the repository that
# tools/build.sh made, installed from it as a server installs them: az, curl,
# ffmpeg, ImageMagick6, ImageMagick7, GraphicsMagick, mc and yt-dlp, by
# tools/az-test.sh, curl-test.sh, ffmpeg-test.sh, imagemagick-test.sh,
# graphicsmagick-test.sh, mc-test.sh and ytdlp-test.sh (yt-dlp with our ffmpeg),
# the utilities of the official ports (Mk/az-official.mk) by utils-test.sh, the
# server packages (git, Apache, memcached, MariaDB, vsftpd-ext, BIND and its tools,
# vips, qt-faststart) by servers-test.sh, Node.js (node24, npm-node24,
# yarn-node24, corepack-node24) by node-test.sh, Python (python312, py312-sqlite3,
# mpdecimal, python3; the official py312-* packages over it) by python-test.sh,
# OpenJDK 17 and JNA (openjdk17, headless, and jna without X11) by java-test.sh,
# Elasticsearch 6 by elastic-test.sh, Kibana 6 (on our node24, with elasticsearch6)
# by kibana-test.sh, OpenSearch 2.17 (opensearch217) by opensearch-test.sh, Node.js
# 18 (node18, npm-node18, yarn-node18, corepack-node18) by
# node18-test.sh after the tests on node24, installed in the place of node24 (one of
# the two: pkg takes node24 and its npm, yarn and corepack away), and Perl (perl5,
# under the name of FreeBSD's) by perl-test.sh, with the XS modules of FreeBSD's
# p5-* packages, which it installs from the FreeBSD repository itself.
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
usage() { sed -n '/^# Usage/,/^#   --repo/s/^# \{0,1\}//p' "$0" >&2; exit "${1:-2}"; }
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
# Python (aZ, 11.11.2026) as the server packages: python312 under the name of the
# official package, py312-sqlite3, mpdecimal and python3 (the meta port); before
# yt-dlp, which takes them from the repository (priority 100) with the official
# py312-* packages
pys="python312 py312-sqlite3 mpdecimal python3"
p_=""
for p in $pys; do in_repo "$p" && p_="$p_ $p"; done
if [ -n "$p_" ]; then
    say "pkg install -f$p_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $p_ > "$res/test-programs-install-python.log" 2>&1 || say "pkg install of Python says it failed (test-programs-install-python.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-python.log" $p_
    cat "$res/test-programs-install-python.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-python.log" >> "$log"
    want="$want$p_"
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
# (servers-test.sh puts vsftpd-ext-openssl of the repository in the place of
# vsftpd-ext for its checks, and vsftpd-ext back)
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
# Node.js (aZ, 11.11.2026) as the server packages: node24 with npm, yarn and
# corepack (gmake and Python of npm are official packages)
nodes="node24 npm-node24 yarn-node24 corepack-node24"
n_=""
for p in $nodes; do in_repo "$p" && n_="$n_ $p"; done
if [ -n "$n_" ]; then
    say "pkg install -f$n_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $n_ > "$res/test-programs-install-node.log" 2>&1 || say "pkg install of Node.js says it failed (test-programs-install-node.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-node.log" $n_
    cat "$res/test-programs-install-node.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-node.log" >> "$log"
    want="$want$n_"
fi
# Node.js 18 (aZ, 11.11.2026: a legacy project): node18 with npm, yarn and corepack,
# one of node18 and node24 (the same files), so installed only for its test, after
# the tests on node24 (node24, Kibana), in its place (3. below)
nodes18="node18 npm-node18 yarn-node18 corepack-node18"
n18_=""
if in_repo node18; then
    for p in $nodes18; do in_repo "$p" && n18_="$n18_ $p"; done
else
    say "node18: not in the repository, its tests are skipped"
fi
# OpenJDK 17 and JNA (aZ, 11.11.2026: ours, headless and without X11, those of
# Elasticsearch 6) as the server packages, before Elasticsearch
javas="openjdk17 jna"
j_=""
for p in $javas; do in_repo "$p" && j_="$j_ $p"; done
if [ -n "$j_" ]; then
    say "pkg install -f$j_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $j_ > "$res/test-programs-install-java.log" 2>&1 || say "pkg install of Java says it failed (test-programs-install-java.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-java.log" $j_
    cat "$res/test-programs-install-java.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-java.log" >> "$log"
    want="$want$j_"
fi
# Elasticsearch 6 (aZ, 11.11.2026: the legacy sites) as the server packages; its
# OpenJDK 17 and JNA are those above
elastic="elasticsearch6"
e_=""
for p in $elastic; do in_repo "$p" && e_="$e_ $p"; done
if [ -n "$e_" ]; then
    say "pkg install -f$e_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $e_ > "$res/test-programs-install-elastic.log" 2>&1 || say "pkg install of Elasticsearch says it failed (test-programs-install-elastic.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-elastic.log" $e_
    cat "$res/test-programs-install-elastic.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-elastic.log" >> "$log"
    want="$want$e_"
fi
# Kibana 6 (aZ, 11.11.2026: the legacy sites, with Elasticsearch 6) as the server
# packages: kibana6 with our node24 and elasticsearch6, which its test starts
kibanas="kibana6"
k_=""
for p in $kibanas; do in_repo "$p" && k_="$k_ $p"; done
if [ -n "$k_" ]; then
    say "pkg install -f$k_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $k_ > "$res/test-programs-install-kibana.log" 2>&1 || say "pkg install of Kibana says it failed (test-programs-install-kibana.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-kibana.log" $k_
    cat "$res/test-programs-install-kibana.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-kibana.log" >> "$log"
    want="$want$k_"
fi
# OpenSearch 2.17 (aZ, 12.11.2026: a legacy project) as the server packages; its
# OpenJDK 17 and JNA are those above
opensearches="opensearch217"
os_=""
for p in $opensearches; do in_repo "$p" && os_="$os_ $p"; done
if [ -n "$os_" ]; then
    say "pkg install -f$os_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $os_ > "$res/test-programs-install-opensearch.log" 2>&1 || say "pkg install of OpenSearch says it failed (test-programs-install-opensearch.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-opensearch.log" $os_
    cat "$res/test-programs-install-opensearch.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-opensearch.log" >> "$log"
    want="$want$os_"
fi
# Perl (aZ, 11.11.2026: under the name of FreeBSD's, so that its p5-* packages work
# with it) as the server packages: perl5; perl-test.sh installs the official p5-*
# packages with XS over it (as a server does) and takes them away again
perls="perl5"
l_=""
for p in $perls; do in_repo "$p" && l_="$l_ $p"; done
if [ -n "$l_" ]; then
    say "pkg install -f$l_"
    # shellcheck disable=SC2086
    CONSERVATIVE_UPGRADE=no pkg install -y -f $l_ > "$res/test-programs-install-perl.log" 2>&1 || say "pkg install of Perl says it failed (test-programs-install-perl.log)"
    # shellcheck disable=SC2086
    again "$res/test-programs-install-perl.log" $l_
    cat "$res/test-programs-install-perl.log" >> "$res/test-programs-install.log"
    cat "$res/test-programs-install-perl.log" >> "$log"
    want="$want$l_"
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
        "graphicsmagick GraphicsMagick" "mc mc" ${p_:+"python$p_"} "ytdlp yt-dlp ffmpeg" "utils $utils" \
        ${s_:+"servers$s_"} ${n_:+"node$n_"} ${j_:+"java$j_"} ${e_:+"elastic$e_"} \
        ${k_:+"kibana$k_ elasticsearch6 node24"} ${os_:+"opensearch$os_"} ${n18_:+"node18$n18_"} ${l_:+"perl$l_"}; do
    # shellcheck disable=SC2086
    set -- $spec
    t="$1"; shift
    if [ "$t" = node18 ]; then
        # node18 and its npm, yarn and corepack in the place of node24 and its own:
        # pkg install as on a server, which removes those of node24 (their files).
        # What needs node24 besides its npm and yarn (kibana6, tested before) goes
        # first, as on a server, where node18 cannot come under it
        : > "$res/test-programs-install-node18.log"
        r24_="$(pkg query '%rn' node24 2> /dev/null | grep -v -x -e npm-node24 -e yarn-node24 | tr '\n' ' ')"
        if [ -n "$r24_" ]; then
            # r24_ ends with a space (tr): "pkg delete kibana6 failed"
            say "pkg delete ${r24_}(they need node24; their tests are done)"
            # shellcheck disable=SC2086
            pkg delete -y $r24_ >> "$res/test-programs-install-node18.log" 2>&1 || say "pkg delete ${r24_}failed (test-programs-install-node18.log)"
        fi
        say "pkg install -f$n18_ (in the place of$n_)"
        # shellcheck disable=SC2086
        CONSERVATIVE_UPGRADE=no pkg install -y -f $n18_ >> "$res/test-programs-install-node18.log" 2>&1 || say "pkg install of Node.js 18 says it failed (test-programs-install-node18.log)"
        # shellcheck disable=SC2086
        again "$res/test-programs-install-node18.log" $n18_
        cat "$res/test-programs-install-node18.log" >> "$res/test-programs-install.log"
        cat "$res/test-programs-install-node18.log" >> "$log"
    fi
    miss=""
    for p in "$@"; do inst "$p" || miss="$miss $p"; done
    if [ -n "$miss" ] && [ "$t" = node18 ]; then
        line "$t: FAIL (not installed from the repository in the place of node24:$miss; test-programs-install-node18.log: $(grep -v '^\[' "$res/test-programs-install-node18.log" | tail -n 2 | tr '\n' ' ' | cut -c1-160))"
        rc=1
        continue
    fi
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
