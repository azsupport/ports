#!/bin/sh
# curl-sync-check.sh - is the curl of the package az that of the PHP of
# azsupport/php-src?
#
# Usage: sh tools/curl-sync-check.sh [<checkout of azsupport/php-src>]
# Runs from the top of a checkout of this tree (build.yml, on the runner before
# the VM). Without an argument it takes freebsd/ of master of azsupport/php-src
# (a sparse clone: git and the network needed).
#
# The fork bundles curl into PHP (--with-curl=bundled: freebsd/curl.conf,
# freebsd/curl-deps.conf, freebsd/curl/ there), and az/az builds the libcurl of
# the package az and the program curl from copies of them (az/az/files/curl.conf,
# curl-deps.conf, curl/ here): the same releases of curl and of its libraries,
# with the same patches, so that a fix of curl reaches both (aZ, 10.11.2026).
# Compared: the lines of the two conf files without comments and blank lines; the
# patches of curl/ byte for byte, and which there are; build-libcurl.sh without
# its comment lines (the comments name the paths of each tree). config-hook.m4 of
# the fork (the configure hook of PHP) has no copy here.
#
# Exit status: 0 the same; 1 a difference (what differs, and what to copy);
# 2 no fork to compare with.

set -u
top="$(pwd)"
here="$top/az/az/files"
[ -f "$here/curl.conf" ] ||
    { echo "curl-sync-check: no $here/curl.conf (run from the top of a checkout of azsupport/ports)" >&2; exit 2; }
t="$(mktemp -d "${TMPDIR:-/tmp}/curl-sync-check.XXXXXX")" || exit 2
trap 'rm -rf "$t"' EXIT
fork="${1:-}"
if [ -z "$fork" ]; then
    fork="$t/php-src"
    git clone -q --depth 1 --filter=blob:none --no-checkout https://github.com/azsupport/php-src.git "$fork" &&
        git -C "$fork" sparse-checkout set --no-cone /freebsd/curl/ /freebsd/curl.conf /freebsd/curl-deps.conf &&
        git -C "$fork" checkout -q master ||
        { echo "curl-sync-check: cannot take freebsd/ of master of azsupport/php-src (git)" >&2; exit 2; }
    echo "azsupport/php-src: master $(git -C "$fork" rev-parse --short=12 HEAD)"
fi
there="$fork/freebsd"
[ -f "$there/curl.conf" ] || { echo "curl-sync-check: no $there/curl.conf" >&2; exit 2; }

rc=0
# data <file>: its lines without comments and blank lines
data() { grep -v '^[[:space:]]*#' "$1" | grep -v '^[[:space:]]*$'; }
# code <file>: a script without its comment lines (the #! line stays)
code() { awk 'NR == 1 && /^#!/ { print; next } !/^[[:space:]]*#/' "$1"; }
# same <what> <file of the fork> <file here> <how>: compare and say it
same() {
    "$4" "$2" > "$t/a" && "$4" "$3" > "$t/b" || { echo "FAIL $1: cannot read it"; rc=1; return; }
    if cmp -s "$t/a" "$t/b"; then
        echo "OK   $1"
    else
        echo "FAIL $1: not that of azsupport/php-src (< the fork, > here):"
        diff "$t/a" "$t/b" | sed -n '/^[<>]/p' | head -n 20 | sed 's/^/       /'
        rc=1
    fi
}
same curl.conf "$there/curl.conf" "$here/curl.conf" data
same curl-deps.conf "$there/curl-deps.conf" "$here/curl-deps.conf" data
same curl/build-libcurl.sh "$there/curl/build-libcurl.sh" "$here/curl/build-libcurl.sh" code
# the patches: the same names, byte for byte
{
    ls "$there/curl"
    ls "$here/curl"
} | grep -v -e '^build-libcurl\.sh$' -e '^config-hook\.m4$' | LC_ALL=C sort -u > "$t/names"
while read -r n; do
    if [ ! -f "$here/curl/$n" ]; then
        echo "FAIL curl/$n: only in azsupport/php-src (freebsd/curl/$n), not here"; rc=1
    elif [ ! -f "$there/curl/$n" ]; then
        echo "FAIL curl/$n: only here, not in freebsd/curl/ of azsupport/php-src"; rc=1
    elif cmp -s "$there/curl/$n" "$here/curl/$n"; then
        echo "OK   curl/$n"
    else
        echo "FAIL curl/$n: not that of azsupport/php-src"; rc=1
    fi
done < "$t/names"
if [ "$rc" -ne 0 ]; then
    echo
    echo "The curl of az must be that of the PHP of azsupport/php-src: bring az/az/files/curl.conf,"
    echo "curl-deps.conf and curl/ to freebsd/curl.conf, curl-deps.conf and curl/ of azsupport/php-src"
    echo "(their data lines and patches; the comments name the paths of this tree), then the"
    echo "distinfo of az/az (the release files of curl and its libraries)."
fi
exit "$rc"
