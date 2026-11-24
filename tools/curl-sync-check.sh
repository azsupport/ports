#!/bin/sh
# curl-sync-check.sh - is the curl of the package az that of the PHP of
# azsupport/php-src?
#
# Usage: sh tools/curl-sync-check.sh [<checkout of azsupport/php-src>]
# Runs from the top of a checkout of this tree (build.yml, on the runner before
# the VM). Without an argument it takes freebsd/ of master of azsupport/php-src
# (a sparse clone: git and the network needed), or of the branch FORK_REF names:
# a change of curl and its libraries goes to a branch of the fork first, and a
# run of a branch here that carries it compares with that branch (build.yml,
# input fork_ref); both go into their main branches at the same moment.
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
ref="${FORK_REF:-master}"
if [ -z "$fork" ]; then
    fork="$t/php-src"
    git clone -q --depth 1 --filter=blob:none --no-checkout --branch "$ref" \
        https://github.com/azsupport/php-src.git "$fork" &&
        git -C "$fork" sparse-checkout set --no-cone /freebsd/curl/ /freebsd/curl.conf /freebsd/curl-deps.conf &&
        git -C "$fork" checkout -q "$ref" ||
        { echo "curl-sync-check: cannot take freebsd/ of $ref of azsupport/php-src (git)" >&2; exit 2; }
    echo "azsupport/php-src: $ref $(git -C "$fork" rev-parse --short=12 HEAD)"
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
# the release files of curl.conf and curl-deps.conf here: in the distinfo of az/az with
# their SHA-256 (the DISTFILES of az/az, under the names of the confs, / made _), so
# that a release changed in the confs is the one the build takes (24.11.2026: zstd 1.6.0
# in curl-deps.conf, 1.5.7 in az/az, and every library of the bundled curl failed)
di="$top/az/az/distinfo"
{
    data "$here/curl-deps.conf" | awk '{ print $5, $6 }'
    data "$here/curl.conf" | awk '{ n = $3; sub(/.*\//, "", n); print n, $4 }'
} | LC_ALL=C sort -u | while read -r f s; do
    n="az/$(printf '%s' "$f" | tr / _)"
    if grep -qxF "SHA256 ($n) = $s" "$di"; then
        echo "OK   az/az/distinfo: $n"
    else
        echo "FAIL az/az/distinfo: no $n with the SHA-256 of the confs ($s): its DISTFILES, MASTER_SITES and distinfo"
        : > "$t/dfail"
    fi
done
[ ! -f "$t/dfail" ] || rc=1
if [ "$rc" -ne 0 ]; then
    echo
    echo "The curl of az must be that of the PHP of azsupport/php-src ($ref): bring az/az/files/curl.conf,"
    echo "curl-deps.conf and curl/ to freebsd/curl.conf, curl-deps.conf and curl/ of azsupport/php-src"
    echo "(their data lines and patches; the comments name the paths of this tree), then the"
    echo "distinfo of az/az (the release files of curl and its libraries). A change of curl not"
    echo "yet in master of the fork: on a branch of the fork, and FORK_REF (build.yml: fork_ref) that branch."
fi
exit "$rc"
