#!/bin/sh
# install-php.sh - install the PHP packages of a version in one of its two modes
# from the repository that tools/build.sh made, as a server installs them: for the
# checks of that mode (tools/check-php.sh <version> <mode>).
#
# Usage (as root on FreeBSD, after tools/build.sh):
#   sh tools/install-php.sh [--repo <dir>] <version> pkg|static
#
#   pkg           the core php74, mod_php74 and every module php74-<module> of the
#                 repository but php74-openssl-legacy (of the two kinds of openssl the
#                 standard one; the other stays in the repository for a swap:
#                 pkg install -y php74-openssl-legacy); php74-static deleted first
#   static        php74-static; php74, mod_php74 and php74-* deleted first (php74-static
#                 has their files)
#   --repo <dir>  the repository of tools/build.sh (default: work/repo)
#
# The repository is taken as the repository "azbuild" of pkg (file://, priority 100,
# so that its packages win over those of the same name of the FreeBSD repository; the
# signature is checked by tools/pkg-repo-sign.sh), in
# /usr/local/etc/pkg/repos/azbuild.conf, which stays for the checks (remove it after
# them on a build server). The packages go in by pkg install -f, so that every one is
# that of the repository. The log: results/install-php-<version>-<mode>.log.
# Exit status: 0 every package of the mode installed from the repository; 1 not;
# 2 a wrong call; 3 the repository has no package of that mode for the version.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n 's/^# \{0,1\}//; 6,16p' "$0" >&2; exit "${1:-2}"; }
say() { printf '[install-php %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { say "$*" >&2; exit 2; }

repo=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --repo=*) repo="${1#--repo=}"; shift ;;
        -h|--help) usage 0 ;;
        -*) say "unknown option $1" >&2; usage ;;
        *) break ;;
    esac
done
[ $# = 2 ] || usage
t="$1"; mode="$2"
case "$t" in [5-8].[0-9]) ;; *) die "not a version of PHP: $t (7.4)" ;; esac
case "$mode" in pkg|static) ;; *) die "not a mode: $mode (pkg or static)" ;; esac
short="$(echo "$t" | tr -d .)"
[ "$(uname -s)" = FreeBSD ] || die "FreeBSD only"
[ "$(id -u)" = 0 ] || die "as root (pkg install, pkg delete)"
repo="${repo:-${AZ_WORK:-$top/work}/repo}"
repo="$(cd "$repo" 2>/dev/null && pwd)"
[ -n "$repo" ] && [ -f "$repo/meta.conf" ] || die "no repository of pkg (meta.conf) in ${repo:-the directory given}: tools/build.sh first"
mkdir -p "$top/results" || die "cannot make $top/results"
log="$top/results/install-php-$t-$mode.log"
: > "$log"
export ASSUME_ALWAYS_YES=yes

conf=/usr/local/etc/pkg/repos/azbuild.conf
mkdir -p "${conf%/*}" || die "cannot make ${conf%/*}"
printf 'azbuild: { url: "file://%s", signature_type: "none", priority: 100, enabled: yes }\n' "$repo" > "$conf"
pkg update -f -r azbuild >> "$log" 2>&1 || { say "pkg update of the repository $repo failed ($log)"; exit 1; }
names="$(pkg rquery -r azbuild '%n' 2>> "$log" | grep -E "^(php$short|mod_php$short|php$short-.+)\$" | LC_ALL=C sort -u)"

# what goes in, and the installed packages of the other mode that go out first
if [ "$mode" = pkg ]; then
    printf '%s\n' "$names" | grep -qx "php$short" || { say "no package php$short in the repository $repo"; exit 3; }
    want="$(printf '%s\n' "$names" | grep -v -x -e "php$short-static" -e "php$short-openssl-legacy" | tr '\n' ' ')"
    del="$(pkg query '%n' "php$short-static" 2>/dev/null; pkg query '%n' "php$short-openssl-legacy" 2>/dev/null)"
else
    printf '%s\n' "$names" | grep -qx "php$short-static" || { say "no package php$short-static in the repository $repo"; exit 3; }
    want="php$short-static"
    del="$({ pkg query '%n' "php$short"; pkg query '%n' "mod_php$short"; pkg query -g '%n' "php$short-*"; } 2>/dev/null |
        grep -v -x "php$short-static")"
fi
del="$(printf '%s\n' "$del" | grep . | LC_ALL=C sort -u | tr '\n' ' ')"
if [ -n "$del" ]; then
    say "pkg delete $del(the files of the other mode)"
    # shellcheck disable=SC2086
    pkg delete -y $del >> "$log" 2>&1 || say "pkg delete failed ($log)"
fi
say "pkg install -f $want"
# shellcheck disable=SC2086
pkg install -y -f $want >> "$log" 2>&1 || say "pkg install says it failed ($log)"
bad=""
for p in $want; do
    r="$(pkg query '%R' "$p" 2>/dev/null)"
    [ "$r" = azbuild ] && continue
    if [ -n "$r" ]; then bad="$bad $p(from $r)"; else bad="$bad $p(not installed)"; fi
done
if [ -n "$bad" ]; then
    say "PHP $t $mode: not installed from the repository:$bad ($log)"
    exit 1
fi
say "PHP $t $mode: $(echo $want | wc -w | tr -d ' ') packages installed from $repo (the repository azbuild stays in $conf)"
exit 0
