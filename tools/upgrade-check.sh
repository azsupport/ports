#!/bin/sh
# upgrade-check.sh - the upgrade of a server from one repository of azsupport to another, as a
# server does it (the split of azsupport into a port a library, aZ 26.11.2026: test T4 of the
# plan): the packages installed from the old repository (the release), the state recorded,
# the repository switched to the new one, pkg upgrade in one transaction (the files of the
# libraries move from the old package azsupport to the packages of their ports, at the same
# paths: pkg has to delete the old before it installs the new), then checked: pkg check -d
# and -s, every file under /usr/local/azsupport (but the static tree) in exactly one package
# and none outside a package, every ELF file of the packages of azsupport finds its shared
# libraries (ldd), the same modules of PHP (php84 -m), the smoke tests of gd, intl (the time
# zone data), xsl, curl and ssh2, what pkg autoremove would take; with --keep-static the
# package of the static tree is marked as installed by hand first (a server that builds
# PHP against the static tree: tools/azsupport-menu.sh of azsupport/php-src), and the static
# tree has to stay.
#
# Usage (as root on FreeBSD, a machine without packages of azsupport: the VM of
# upgrade-test.yml):
#   sh tools/upgrade-check.sh [--keep-static] <old repository url> <new repository dir> <results dir> <package>...
#   <old repository url>  the repository a server has (the release: signed, keys/azsupport.pub)
#   <new repository dir>  the packages of the new repository (its catalog written here,
#                         unsigned, into a copy of hard links: <results dir>/../upgrade-repo)
#   <package>...          the packages to install first (those the old repository has not
#                         are said and left out)
# Environment: UPGRADE_CMD, the upgrade (default: pkg upgrade -y -r azsupport, the
#   procedure of a server); PHP, the CLI of PHP of the checks (default: php84).
# Output: a line a check, "test upgrade-<check>: OK|FAIL|SKIP|INFO <what>" (names of packages,
#   counts, no file contents); the outputs of pkg, ldd and PHP in <results dir>.
# Exit status: 0 every check OK, 1 a FAIL, 2 usage or setup.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
keep=0
if [ "${1:-}" = --keep-static ]; then keep=1; shift; fi
[ $# -ge 4 ] || { echo "usage: sh tools/upgrade-check.sh [--keep-static] <old repository url> <new repository dir> <results dir> <package>..." >&2; exit 2; }
oldurl="$1"; newdir="$2"; out="$3"; shift 3
[ "$(uname -s)" = FreeBSD ] || { echo "upgrade-check: FreeBSD only" >&2; exit 2; }
[ "$(id -u)" = 0 ] || { echo "upgrade-check: as root" >&2; exit 2; }
newdir="$(cd "$newdir" 2> /dev/null && pwd)" || { echo "upgrade-check: no directory $2" >&2; exit 2; }
mkdir -p "$out" || exit 2
out="$(cd "$out" && pwd)"
A=/usr/local/azsupport
php="${PHP:-php84}"
cmd="${UPGRADE_CMD:-pkg upgrade -y -r azsupport}"
pub="$top/keys/azsupport.pub"
[ -f "$pub" ] || { echo "upgrade-check: no $pub" >&2; exit 2; }
export ASSUME_ALWAYS_YES=yes
nf=0
t() { printf 'test upgrade-%s\n' "$*"; case "$*" in *": FAIL"*) nf=$((nf + 1)) ;; esac; }

# the repositories: the official one of the ports (latest, as tools/build.sh builds with it)
# and azsupport, the old one first (priority 100: our packages over the official ones of
# the same name)
mkdir -p /usr/local/etc/pkg/repos
printf '%s\n' 'FreeBSD: { url: "pkg+https://pkg.FreeBSD.org/${ABI}/latest", enabled: yes }' > /usr/local/etc/pkg/repos/FreeBSD.conf
printf 'azsupport: { url: "%s", signature_type: "pubkey", pubkey: "%s", priority: 100, enabled: yes }\n' "$oldurl" "$pub" > /usr/local/etc/pkg/repos/azsupport.conf
if ! pkg update -f > "$out/update-old.log" 2>&1; then
    t "repositories: FAIL (pkg update of the old repository: $(tail -n 1 "$out/update-old.log"))"
    exit 1
fi
# the new repository: its packages as hard links (or copies) in a directory of their own, the
# catalog of pkg repo there, unsigned
nr="$(dirname "$out")/upgrade-repo"
rm -rf "$nr" && mkdir -p "$nr" || exit 2
for f in "$newdir"/*.pkg; do
    [ -f "$f" ] || continue
    case "${f##*/}" in packagesite.*|meta.*|digests.*|filesite.*|data.*) continue ;; esac
    ln "$f" "$nr/" 2> /dev/null || cp -p "$f" "$nr/"
done
if ! pkg repo "$nr" > "$out/repo-new.log" 2>&1; then
    t "repositories: FAIL (pkg repo of the new packages: $(tail -n 1 "$out/repo-new.log"))"
    exit 1
fi
t "repositories: OK (old: $oldurl; new: $(ls "$nr" | grep -c '\.pkg$') packages)"

# the packages, from the old repository
want=""; miss=""
for n in "$@"; do
    if pkg rquery -r azsupport '%n' "$n" 2> /dev/null | grep -qx "$n"; then want="$want $n"; else miss="$miss $n"; fi
done
[ -z "$miss" ] || t "install: INFO not in the old repository, left out:$miss"
[ -n "$want" ] || { t "install: FAIL (none of the packages is in the old repository)"; exit 1; }
# shellcheck disable=SC2086
if ! pkg install -y $want > "$out/install.log" 2>&1; then
    t "install: FAIL (pkg install from the old repository: $(grep -i -E 'error|conflict|missing' "$out/install.log" | tail -n 1 | cut -c1-200))"
    exit 1
fi
t "install: OK ($(echo $want | wc -w | tr -d ' ') packages and $(( $(pkg query -a '%n' | wc -l) - $(echo $want | wc -w) )) dependencies)"

# the state before
mkdir -p "$out/before" "$out/after"
state() {
    pkg query -a '%n %v %o %a %R' | LC_ALL=C sort > "$1/pkgs.txt"
    if command -v "$php" > /dev/null 2>&1; then "$php" -m > "$1/php-m.txt" 2>&1; else : > "$1/php-m.txt"; fi
    find "$A" \( -path "$A/static" -prune \) -o \( -type f -o -type l \) -print 2> /dev/null | LC_ALL=C sort > "$1/files.txt"
    while read -r f; do
        if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; else echo "$f $(sha256 -q "$f")"; fi
    done < "$1/files.txt" > "$1/sha256.txt"
    [ -d "$A/static" ] && find "$A/static" \( -type f -o -type l \) | wc -l | tr -d ' ' > "$1/static.count"
    return 0
}
state "$out/before"
# the package of the static tree: the owner of one of its archives
spkg_of() {
    f="$(find "$A/static/lib" -name '*.a' 2> /dev/null | head -n 1)"
    [ -n "$f" ] && pkg which -q "$f" 2> /dev/null | sed 's/-[^-]*$//'
}
sb="$(spkg_of)"
if [ "$keep" = 1 ]; then
    if [ -n "$sb" ]; then
        pkg set -y -A 0 "$sb" > /dev/null 2>&1
        t "keep-static: OK ($sb marked as installed by hand, as a server that builds PHP against the static tree)"
    else
        t "keep-static: FAIL (no package of the static tree $A/static before the upgrade)"
    fi
fi

# the upgrade: the new repository in the place of the old one, one transaction
printf 'azsupport: { url: "file://%s", signature_type: "none", priority: 100, enabled: yes }\n' "$nr" > /usr/local/etc/pkg/repos/azsupport.conf
pkg update -f -r azsupport > "$out/update-new.log" 2>&1 || { t "upgrade: FAIL (pkg update of the new repository: $(tail -n 1 "$out/update-new.log"))"; exit 1; }
pkg upgrade -n -r azsupport > "$out/upgrade-plan.log" 2>&1
r=0
$cmd > "$out/upgrade.log" 2>&1 || r=$?
grep -E 'Checking integrity|Running trigger: azsupport-services|conflict' "$out/upgrade.log" > "$out/upgrade-lines.txt"
ninst="$(sed -n 's/^Number of packages to be installed: *//p' "$out/upgrade-plan.log")"
nupg="$(sed -n 's/^Number of packages to be upgraded: *//p' "$out/upgrade-plan.log")"
nrem="$(sed -n 's/^Number of packages to be removed: *//p' "$out/upgrade-plan.log")"
if [ "$r" = 0 ]; then
    t "upgrade: OK ($cmd: ${ninst:-0} installed, ${nupg:-0} upgraded, ${nrem:-0} removed in one transaction)"
else
    t "upgrade: FAIL ($cmd: exit $r: $(grep -i -E 'error|conflict|missing|cannot' "$out/upgrade.log" | tail -n 1 | cut -c1-200))"
fi
grep -q 'Checking integrity' "$out/upgrade.log" && t "integrity: INFO $(grep 'Checking integrity' "$out/upgrade.log" | tail -n 1 | cut -c1-120)"
if grep -q 'Running trigger: azsupport-services' "$out/upgrade.log"; then t "trigger: OK (azsupport-services ran)"; else t "trigger: INFO (azsupport-services did not run: no package of a service in the transaction)"; fi
state "$out/after"

# pkg check: the dependencies, the checksums
pkg check -d -a > "$out/check-d.log" 2>&1; r=$?
if [ "$r" = 0 ] && ! grep -q -i 'missing\|has a missing' "$out/check-d.log"; then t "check-d: OK"; else t "check-d: FAIL ($(grep . "$out/check-d.log" | head -n 3 | tr '\n' ';' | cut -c1-240))"; fi
pkg check -s -a > "$out/check-s.log" 2>&1; r=$?
if [ "$r" = 0 ] && ! grep -q -i 'checksum mismatch\|missing' "$out/check-s.log"; then t "check-s: OK"; else t "check-s: FAIL ($(grep . "$out/check-s.log" | head -n 3 | tr '\n' ';' | cut -c1-240))"; fi

# every file of the shared tree in exactly one package, and none outside a package
pkg query -a '%Fp' | awk -v a="$A/" -v s="$A/static/" 'index($0, a) == 1 && index($0, s) != 1' | LC_ALL=C sort > "$out/after/owned.txt"
uniq -d "$out/after/owned.txt" > "$out/after/owned-twice.txt"
LC_ALL=C sort -u "$out/after/owned.txt" | LC_ALL=C comm -13 - "$out/after/files.txt" > "$out/after/not-owned.txt"
if [ -s "$out/after/owned-twice.txt" ] || [ -s "$out/after/not-owned.txt" ]; then
    t "files: FAIL ($(grep -c . "$out/after/owned-twice.txt") files of $A in two packages, $(grep -c . "$out/after/not-owned.txt") in none: $(cat "$out/after/owned-twice.txt" "$out/after/not-owned.txt" | head -n 5 | tr '\n' ' ' | cut -c1-240))"
else
    t "files: OK ($(grep -c . "$out/after/files.txt") files of $A but the static tree, each in one package)"
fi

# ldd: every ELF file of the packages of azsupport (those of the repository azsupport)
pkg query -a '%R %n' | awk '$1 == "azsupport" { print $2 }' > "$out/after/ours.txt"
for n in $(cat "$out/after/ours.txt"); do pkg query '%Fp' "$n"; done | LC_ALL=C sort -u > "$out/after/ours-files.txt"
tr '\n' '\000' < "$out/after/ours-files.txt" | xargs -0 awk 'FNR == 1 { if (substr($0, 1, 4) == "\177ELF") print FILENAME; nextfile }' 2> /dev/null > "$out/after/elf.txt"
: > "$out/after/ldd-bad.txt"
while read -r f; do
    ldd "$f" > "$out/ldd.out" 2>&1 || continue
    grep -q 'not found' "$out/ldd.out" && { echo "$f: $(grep 'not found' "$out/ldd.out" | awk '{ print $1 }' | tr '\n' ' ')" >> "$out/after/ldd-bad.txt"; }
done < "$out/after/elf.txt"
if [ -s "$out/after/ldd-bad.txt" ]; then
    t "ldd: FAIL ($(grep -c . "$out/after/ldd-bad.txt") of $(grep -c . "$out/after/elf.txt") ELF files miss a shared library: $(head -n 3 "$out/after/ldd-bad.txt" | tr '\n' ';' | cut -c1-240))"
else
    t "ldd: OK ($(grep -c . "$out/after/elf.txt") ELF files of $(grep -c . "$out/after/ours.txt") packages of azsupport find their shared libraries)"
fi

# PHP: the same modules, and the smoke tests
if [ -s "$out/before/php-m.txt" ]; then
    if cmp -s "$out/before/php-m.txt" "$out/after/php-m.txt"; then
        t "php-m: OK ($(grep -c -v '^\[' "$out/after/php-m.txt") modules of $php, as before)"
    else
        t "php-m: FAIL (the modules of $php differ: $(LC_ALL=C comm -3 "$out/before/php-m.txt" "$out/after/php-m.txt" | tr -d '\t' | tr '\n' ' ' | cut -c1-200))"
    fi
    cat > "$out/smoke.php" <<'EOF'
<?php
$c = [
    'gd' => function () {
        $im = imagecreatetruecolor(4, 4);
        ob_start(); imagepng($im); $png = ob_get_clean();
        return strlen($png) > 0 ? 'OK' : 'FAIL no PNG';
    },
    'intl' => function () {
        $v = IntlTimeZone::getTZDataVersion();
        $f = new IntlDateFormatter('en_US', IntlDateFormatter::FULL, IntlDateFormatter::FULL, 'America/Asuncion');
        return ($v !== '' && $f->format(0) !== false) ? 'OK ' . $v : 'FAIL';
    },
    'xsl' => function () {
        $x = new DOMDocument(); $x->loadXML('<a>1</a>');
        $s = new DOMDocument();
        $s->loadXML('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="text"/><xsl:template match="/">v<xsl:value-of select="a"/></xsl:template></xsl:stylesheet>');
        $p = new XSLTProcessor(); $p->importStylesheet($s);
        return trim($p->transformToXML($x)) === 'v1' ? 'OK' : 'FAIL';
    },
    'curl' => function () { return 'OK ' . curl_version()['version']; },
    'ssh2' => function () { return function_exists('ssh2_connect') ? 'OK' : 'FAIL no ssh2_connect'; },
];
foreach ($c as $k => $f) {
    try { $r = $f(); } catch (Throwable $e) { $r = 'FAIL ' . get_class($e) . ': ' . $e->getMessage(); }
    echo "$k $r\n";
}
EOF
    "$php" "$out/smoke.php" > "$out/after/smoke.txt" 2>&1
    for c in gd intl xsl curl ssh2; do
        v="$(awk -v c="$c" '$1 == c { $1 = ""; sub(/^ /, ""); print; exit }' "$out/after/smoke.txt")"
        case "$v" in OK*) t "php-$c: $v" ;; *) t "php-$c: FAIL (${v:-no result: $(head -n 1 "$out/after/smoke.txt" | cut -c1-160)})" ;; esac
    done
else
    t "php-m: SKIP (no $php before the upgrade)"
fi

# the files of the shared tree before and after (INFO: the libraries built again differ)
LC_ALL=C comm -3 "$out/before/sha256.txt" "$out/after/sha256.txt" > "$out/sha256-diff.txt"
t "sha256: INFO $(grep -c . "$out/before/sha256.txt") files before, $(grep -c . "$out/after/sha256.txt") after, $(LC_ALL=C comm -12 "$out/before/sha256.txt" "$out/after/sha256.txt" | grep -c .) the same"

# what pkg autoremove would take; the static tree
pkg autoremove -n > "$out/autoremove.log" 2>&1
ar="$(awk '/^[[:space:]]+[^[:space:]]+-[0-9][^[:space:]]*$/ { print $1 }' "$out/autoremove.log" | tr '\n' ' ')"
sa="$(spkg_of)"
t "autoremove: INFO ${ar:-nothing}${sa:+ (the static tree: $sa)}"
if [ "$keep" = 1 ]; then
    if [ -n "$sa" ] && [ -d "$A/static/lib" ]; then
        case " $ar " in
            *" $sa-"*) t "static: FAIL ($sa, the static tree, would go with pkg autoremove)" ;;
            *) t "static: OK (the static tree stays: $sa, $(cat "$out/after/static.count" 2> /dev/null) files)" ;;
        esac
    else
        t "static: FAIL (no static tree after the upgrade: install its package, pkg install -r azsupport <package of $A/static>)"
    fi
else
    if [ -d "$A/static/lib" ]; then t "static: INFO the static tree is there (${sa:-no package}: a package installed needs it)"; else t "static: INFO no static tree after the upgrade (no package installed needs it)"; fi
fi

echo "result: $( [ "$nf" = 0 ] && echo OK || echo "FAIL ($nf checks)")"
[ "$nf" = 0 ]
