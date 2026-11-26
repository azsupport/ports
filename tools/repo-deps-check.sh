#!/bin/sh
# repo-deps-check.sh - the run dependencies of the packages of a repository of pkg against
# its packages (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»): each dependency of each package of its catalog (the
# deps of packagesite.yaml: a name and an origin) is to be a package of the repository
# (the same name and origin), but pkg of ports-mgmt/pkg, the one exception (aZ, 26.11.2026
# 13:40: net-snmp links libpkg.so of the pkg of FreeBSD): of a package that depends on it,
# each SONAME libpkg.so.* it needs (its shlibs_required) is to be one the pkg of the build
# provides (pkg query %b pkg: the build took the official pkg of the same repositories). A
# warning only, for now (aZ, 26.11.2026): the list, and exit 0.
#
# Usage: sh tools/repo-deps-check.sh <repository>
#   <repository>: the directory of the repository (its catalog packagesite.pkg, or .txz
#   or .tzst of an older pkg), or the file packagesite.yaml of a catalog
#
# The lines it writes, then the summary as the last line (the workflows put that one
# into results/checks.txt and the others into results/repo-deps.txt):
#   WARN <name> (<origin>): no package of the repository; needed by <packages>
#   WARN <name> (<origin>): the repository has <name> of <other origin>; needed by <packages>
#   OK pkg: <package> needs <SONAMEs>, which pkg <version> of the build provides
#   WARN pkg: <package> needs <SONAME>, the pkg <version> of the build provides <SONAMEs>
#   SKIP pkg: <why> (no pkg on this machine)
#   repo-deps: OK (<n> packages, ... every run dependency is a package of the repository)
#   repo-deps: WARN (<k> run dependencies are no packages of the repository: <names>; ...)
# FreeBSD /bin/sh and its base utilities (tar of libarchive reads the zstd of the catalog;
# GNU tar with zstd does too); the catalog is read with awk (one JSON object a line).
# Exit status: 0 (also with a WARN), 2 when the catalog cannot be read or a wrong call.

set -u
[ $# -eq 1 ] || { echo "usage: sh tools/repo-deps-check.sh <repository directory | packagesite.yaml>" >&2; exit 2; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/repo-deps-check.XXXXXX")" || { echo "repo-deps-check: no temporary directory" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
trap 'exit 2' HUP INT TERM

if [ -d "$1" ]; then
    cat=""
    for c in packagesite.pkg packagesite.tzst packagesite.txz; do
        [ -f "$1/$c" ] && { cat="$1/$c"; break; }
    done
    [ -n "$cat" ] || { echo "repo-deps: SKIP (no catalog packagesite.pkg in $1)"; exit 2; }
    tar -xOf "$cat" packagesite.yaml > "$tmp/site" 2> "$tmp/err" ||
        { echo "repo-deps: SKIP ($cat does not unpack: $(tail -n 1 "$tmp/err"))"; exit 2; }
elif [ -f "$1" ]; then
    cat "$1" > "$tmp/site" || exit 2
else
    echo "repo-deps: SKIP (no repository $1)"; exit 2
fi
[ -s "$tmp/site" ] || { echo "repo-deps: SKIP (an empty catalog: $1)"; exit 2; }

# the catalog into three lists: the packages (<name> <origin>), their dependencies
# (<package> <name> <origin>), the SONAMEs libpkg.so.* they need (<package> <SONAME>).
# A string of JSON holds no unescaped quote, so "name":" and "origin":" first match the
# fields of the package (they come before deps), and a dependency is
# "<name>":{"origin":"<origin>","version":"<version>"} in "deps":{...}
awk -v P="$tmp/pkgs" -v D="$tmp/deps" -v S="$tmp/shlibs" '
function field(k,    re) {
    re = "\"" k "\":\"[^\"]*\""
    if (!match($0, re)) return ""
    return substr($0, RSTART + length(k) + 4, RLENGTH - length(k) - 5)
}
{
    n = field("name"); o = field("origin")
    if (n == "") next
    print n, o > P
    if (match($0, /"deps":[{]("[^"]*":[{][^}]*[}],?)*[}]/)) {
        d = substr($0, RSTART + 8, RLENGTH - 9)
        c = split(d, part, /[}],?/)
        for (i = 1; i <= c; i++) {
            if (part[i] == "") continue
            dn = part[i]; sub(/^"/, "", dn); sub(/".*/, "", dn)
            do_ = part[i]
            if (!sub(/.*"origin":"/, "", do_)) do_ = "?"
            sub(/".*/, "", do_)
            print n, dn, do_ > D
        }
    }
    if (match($0, /"shlibs_required":\[[^]]*\]/)) {
        s = substr($0, RSTART + 19, RLENGTH - 20)
        c = split(s, lib, /,/)
        for (i = 1; i <= c; i++) {
            l = lib[i]; gsub(/"/, "", l)
            if (l ~ /^libpkg\.so/) print n, l > S
        }
    }
}' "$tmp/site"
[ -s "$tmp/pkgs" ] || { echo "repo-deps: SKIP (no package in the catalog of $1)"; exit 2; }
touch "$tmp/deps" "$tmp/shlibs"
np="$(wc -l < "$tmp/pkgs" | tr -d ' ')"
nd="$(awk '{ print $1 }' "$tmp/deps" | sort -u | wc -l | tr -d ' ')"

# the dependencies that are no packages of the repository (pkg aside), each with the
# packages that need it
awk 'NR == FNR { o[$1] = $2; next }
    $2 == "pkg" && $3 == "ports-mgmt/pkg" { next }
    !($2 in o) { k = $2 " (" $3 "): no package of the repository"; miss[k] = miss[k] " " $1; next }
    o[$2] != $3 { k = $2 " (" $3 "): the repository has " $2 " of " o[$2]; miss[k] = miss[k] " " $1 }
    END { for (k in miss) print k ";" miss[k] }' "$tmp/pkgs" "$tmp/deps" | LC_ALL=C sort |
    while IFS=';' read -r what who; do
        echo "WARN $what; needed by$(printf '%s\n' $who | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//; s/^/ /')"
    done > "$tmp/warn"

# pkg, the exception: the SONAMEs of libpkg the packages that depend on it need, against
# those the pkg of this machine provides
awk '$2 == "pkg" && $3 == "ports-mgmt/pkg" { print $1 }' "$tmp/deps" | LC_ALL=C sort -u > "$tmp/onpkg"
: > "$tmp/pkgline"
if [ -s "$tmp/onpkg" ]; then
    if command -v pkg > /dev/null 2>&1 && pv="$(pkg query '%v' pkg 2> /dev/null)" && [ -n "$pv" ]; then
        pkg query '%b' pkg 2> /dev/null | LC_ALL=C sort -u > "$tmp/provided"
        while read -r p; do
            need="$(awk -v p="$p" '$1 == p { print $2 }' "$tmp/shlibs" | LC_ALL=C sort -u)"
            if [ -z "$need" ]; then
                echo "OK pkg: $p links no libpkg (its shlibs_required); pkg $pv of the build"
                continue
            fi
            bad=""
            for l in $need; do grep -qxF "$l" "$tmp/provided" || bad="$bad $l"; done
            if [ -z "$bad" ]; then
                echo "OK pkg: $p needs $(echo $need), which pkg $pv of the build provides"
            else
                echo "WARN pkg: $p needs$bad, the pkg $pv of the build provides $(grep '^libpkg' "$tmp/provided" | tr '\n' ' ' | sed 's/ $//')"
            fi
        done < "$tmp/onpkg" > "$tmp/pkgline"
    else
        echo "SKIP pkg: no pkg on this machine to compare the libpkg of $(tr '\n' ' ' < "$tmp/onpkg" | sed 's/ $//') with" > "$tmp/pkgline"
    fi
fi

cat "$tmp/warn" "$tmp/pkgline"
nw="$(grep -c . "$tmp/warn")"
pw="$(grep -c '^WARN' "$tmp/pkgline")"
pinfo="$(sed -n -E -e 's/^(OK|WARN) pkg: ([^ ]*).*/\1 \2/p' -e 's/^SKIP pkg: .*/not checked (no pkg here)/p' "$tmp/pkgline" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
if [ "$nw" = 0 ] && [ "$pw" = 0 ]; then
    echo "repo-deps: OK ($np packages, $nd with run dependencies: every one is a package of the repository but pkg${pinfo:+; pkg: $pinfo})"
else
    names="$(sed -n 's/^WARN \([^ ]*\) .*/\1/p' "$tmp/warn" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
    echo "repo-deps: WARN ($nw run dependencies of the $np packages are no packages of the repository${names:+: $names}${pinfo:+; pkg: $pinfo}; results/repo-deps.txt)"
fi
exit 0
