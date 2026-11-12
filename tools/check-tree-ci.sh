#!/bin/sh
# check-tree-ci.sh - tools/check-tree.sh on a Linux runner of GitHub Actions, before
# the FreeBSD VM of build.yml and before a commit of yt-dlp-update.yml: bmake, that
# of the FreeBSD of the VM (contrib/bmake of freebsd-src, branch releng/<release>),
# built here in seconds; no mirror of Ubuntu (11.11.2026: apt-get of the runners
# could not resolve azure.archive.ubuntu.com for an hour, runs 43035735575,
# 43038380715 and those of the branches stopped here); the official tree at the
# commit pinned in tools/build.sh, sparse (Mk/, Templates/, Keywords/ and the
# Makefiles, *.mk and distinfo of every port); the make.conf of the builder for the
# level (the first part of tools/make.conf.in). Its lines go to the screen and into
# check-tree.txt of the tree (tools/report.sh reads it).
#
# Usage: sh tools/check-tree-ci.sh <FreeBSD release> <x86-64 level>
#   (sh tools/check-tree-ci.sh 15.1 x86-64-v3)
# Environment: RUNNER_TEMP, the work directory (default: a temporary directory).
# Exit status: that of tools/check-tree.sh (0 no FAIL, 1 a FAIL, 2 its usage or
# setup), 2 when there is no bmake or no official tree.

set -u
release="${1:?usage: sh tools/check-tree-ci.sh <FreeBSD release> <x86-64 level>}"
cputype="${2:?usage: sh tools/check-tree-ci.sh <FreeBSD release> <x86-64 level>}"
top="$(cd "$(dirname "$0")/.." && pwd)"
tmp="${RUNNER_TEMP:-}"
[ -n "$tmp" ] || tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-tree-ci.XXXXXX")" || exit 2

src="$tmp/freebsd-src"
for i in 1 2 3; do
    rm -rf "$src"
    if git clone -q --depth 1 --filter=blob:none --sparse --branch "releng/$release" \
        https://github.com/freebsd/freebsd-src "$src" && git -C "$src" sparse-checkout set contrib/bmake; then
        break
    fi
    [ "$i" != 3 ] || { echo "::error title=bmake::no contrib/bmake of freebsd-src releng/$release"; exit 2; }
    echo "git clone of freebsd-src failed (try $i of 3)"
    sleep 30
done
mkdir -p "$tmp/bmake-build" "$tmp/bin"
if ! (cd "$tmp/bmake-build" && sh "$src/contrib/bmake/configure" --without-meta --without-filemon > configure.log 2>&1 &&
    sh ./make-bootstrap.sh > build.log 2>&1); then
    tail -n 30 "$tmp/bmake-build/configure.log" "$tmp/bmake-build/build.log" 2> /dev/null
    echo "::error title=bmake::the build of contrib/bmake failed"
    exit 2
fi
cp "$tmp/bmake-build/bmake" "$tmp/bin/bmake" || exit 2
PATH="$tmp/bin:$PATH"; export PATH
echo "bmake $(sed -n 's/^_MAKE_VERSION=//p' "$src/contrib/bmake/VERSION") of freebsd-src releng/$release"

commit="$(sed -n 's/^ports_commit="\([0-9a-f]*\)".*/\1/p' "$top/tools/build.sh")"
[ -n "$commit" ] || { echo "::error title=check-tree::no ports_commit in tools/build.sh"; exit 2; }
off="$tmp/freebsd-ports"
rm -rf "$off"
mkdir -p "$off"
if ! { git -C "$off" init -q &&
    git -C "$off" remote add origin https://github.com/freebsd/freebsd-ports &&
    git -C "$off" fetch -q --depth 1 --filter=blob:none origin "$commit" &&
    git -C "$off" sparse-checkout set --no-cone '/Mk/' '/Templates/' '/Keywords/' '/Makefile*' '/*/Makefile*' '/*/*/Makefile*' '/*/*/*.mk' '/*/*/distinfo' &&
    git -C "$off" checkout -q FETCH_HEAD; }; then
    echo "::error title=check-tree::no official tree at $commit"
    exit 2
fi
sed -n '1,/^# The paths of tools\/build.sh/p' "$top/tools/make.conf.in" | sed "s|@CPUTYPE@|$cputype|" > "$tmp/make.conf"
{ MAKE_CONF="$tmp/make.conf" sh "$top/tools/check-tree.sh" "$off" 2>&1; echo "$?" > "$tmp/check-tree.rc"; } | tee "$top/check-tree.txt"
exit "$(cat "$tmp/check-tree.rc")"
