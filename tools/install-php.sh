#!/bin/sh
# install-php.sh - install the PHP packages of a version from the repository that
# tools/build.sh made, as a server installs them: for the checks of
# tools/check-php.sh <version>.
#
# Usage (as root on FreeBSD, after tools/build.sh):
#   sh tools/install-php.sh [--repo <dir>] <version>
#
#   <version>     7.4: the core php74, mod_php74 and every module php74-<module> of the
#                 repository but php74-openssl-legacy (of the two kinds of openssl the
#                 standard one; the other stays in the repository for a swap:
#                 pkg install -y php74-openssl-legacy); php74-gmagick too (its ini is
#                 off, so it does not clash with imagick; its CLI profile has it on)
#   --repo <dir>  the repository of tools/build.sh (default: work/repo)
#
# The repository is taken as the repository "azbuild" of pkg (file://, priority 100,
# so that its packages win over those of the same name of the FreeBSD repository; the
# signature is checked by tools/pkg-repo-sign.sh), in
# /usr/local/etc/pkg/repos/azbuild.conf, which stays for the checks (remove it after
# them on a build server). The packages go in by pkg install -f, so that every one is
# that of the repository. The log: results/install-php-<version>.log.
# Exit status: 0 every package installed from the repository; 1 not; 2 a wrong call;
# 3 the repository has no php74 (no core of that version).

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n 's/^# \{0,1\}//; 6,13p' "$0" >&2; exit "${1:-2}"; }
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
[ $# = 1 ] || usage
t="$1"
case "$t" in [5-8].[0-9]) ;; *) die "not a version of PHP: $t (7.4)" ;; esac
short="$(echo "$t" | tr -d .)"
[ "$(uname -s)" = FreeBSD ] || die "FreeBSD only"
[ "$(id -u)" = 0 ] || die "as root (pkg install, pkg delete)"
repo="${repo:-${AZ_WORK:-$top/work}/repo}"
repo="$(cd "$repo" 2>/dev/null && pwd)"
[ -n "$repo" ] && [ -f "$repo/meta.conf" ] || die "no repository of pkg (meta.conf) in ${repo:-the directory given}: tools/build.sh first"
mkdir -p "$top/results" || die "cannot make $top/results"
log="$top/results/install-php-$t.log"
: > "$log"
export ASSUME_ALWAYS_YES=yes

conf=/usr/local/etc/pkg/repos/azbuild.conf
mkdir -p "${conf%/*}" || die "cannot make ${conf%/*}"
printf 'azbuild: { url: "file://%s", signature_type: "none", priority: 100, enabled: yes }\n' "$repo" > "$conf"
pkg update -f -r azbuild >> "$log" 2>&1 || { say "pkg update of the repository $repo failed ($log)"; exit 1; }
names="$(pkg rquery -r azbuild '%n' 2>> "$log" | grep -E "^(php$short|mod_php$short|php$short-.+)\$" | LC_ALL=C sort -u)"

# what goes in: the core, mod_php and the modules, with the standard openssl
printf '%s\n' "$names" | grep -qx "php$short" || { say "no package php$short in the repository $repo"; exit 3; }
want="$(printf '%s\n' "$names" | grep -v -x "php$short-openssl-legacy" | tr '\n' ' ')"
if pkg info -e "php$short-openssl-legacy"; then
    say "pkg delete php$short-openssl-legacy (php$short-openssl goes in, the same files)"
    pkg delete -y "php$short-openssl-legacy" >> "$log" 2>&1 || say "pkg delete failed ($log)"
fi
say "pkg install -f $want"
# CONSERVATIVE_UPGRADE=no: pkg keeps a package from the repository it came from
# (an official one of the same name, a build dependency), the priority of azbuild
# decides only without it
# shellcheck disable=SC2086
CONSERVATIVE_UPGRADE=no pkg install -y -f $want >> "$log" 2>&1 || say "pkg install says it failed ($log)"
# the repository a package came from: its annotation repository (pkg query %R of
# pkg 2 says nothing for installed packages); none: pkg add of a file
repo_of() { pkg query '%At %Av' "$1" 2>/dev/null | awk '$1 == "repository" { print $2; exit }'; }
bad=""
for p in $want; do
    r="$(repo_of "$p")"
    [ "$r" = azbuild ] && continue
    if ! pkg info -e "$p"; then bad="$bad $p(not installed)"; else bad="$bad $p(from ${r:-a file, pkg add})"; fi
done
if [ -n "$bad" ]; then
    say "PHP $t: not installed from the repository:$bad ($log)"
    exit 1
fi
say "PHP $t: $(echo $want | wc -w | tr -d ' ') packages installed from $repo (the repository azbuild stays in $conf)"
exit 0
