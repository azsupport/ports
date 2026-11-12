#!/bin/sh
# az-abi-check.sh - the packages kept from the repository that need az, checked against
# a new build of az before they are used with it (tools/build.sh, aZ 12.11.2026: a
# port that needs az is built again only when the interface of a library it uses
# changes, so a fix inside az leaves them as they are): each SONAME of az their
# NEEDED name is in the new az, and each undefined dynamic symbol they bind from a
# library of az is defined there. The symbols they bind from az: those the az they
# were kept with (the package of the repository before the run) defines in the
# libraries of az their files NEED. So the check is the difference of the two builds
# of az first (the SONAMEs that went, the symbols each SONAME no longer defines: nm
# -D), then for each package the SONAMEs pkg recorded it needs (shlibs_required) and,
# only when one of them lost symbols, its ELF files (readelf -d, nm -D); the names
# of the symbols are compared without their versions.
#
# Usage (FreeBSD; pkg, tar, readelf, nm of the base system):
#   sh tools/az-abi-check.sh <old az package> <new az package> <work dir> <package>...
# Environment: AZ_PREFIX (default /usr/local/az): the prefix of az in its packages.
# Output: "az: ..." (what the new az lost), then a line a package that needs az:
# "ok <package>" or "fail <package> <why>"; the packages that need no SONAME of az
# are left out.
# Exit status: 0 every package passed, 1 one failed, 2 usage or a package of az that
# could not be read.

set -u
[ $# -ge 3 ] || { echo "usage: sh tools/az-abi-check.sh <old az package> <new az package> <work dir> <package>..." >&2; exit 2; }
old="$1"; new="$2"; w="$3"; shift 3
pre="${AZ_PREFIX:-/usr/local/az}"
rm -rf "$w" && mkdir -p "$w/old" "$w/new" "$w/drop" || { echo "az-abi-check: cannot make $w" >&2; exit 2; }

# syms <tree> <out>: "<SONAME>" files of the defined dynamic symbols of the shared
# libraries of az in an extracted package, and <out>/sonames
syms() {
    mkdir -p "$2/syms"
    : > "$2/sonames"
    for f in "$1$pre"/lib/*.so*; do
        [ -f "$f" ] && [ ! -L "$f" ] || continue
        sn="$(readelf -d "$f" 2> /dev/null | sed -n 's/.*[Ll]ibrary soname: \[\(.*\)\].*/\1/p')"
        [ -n "$sn" ] || continue
        echo "$sn" >> "$2/sonames"
        nm -D --defined-only "$f" 2> /dev/null | awk 'NF >= 3 { s = $3; sub(/@.*/, "", s); print s }' | LC_ALL=C sort -u > "$2/syms/$sn"
    done
    LC_ALL=C sort -u "$2/sonames" -o "$2/sonames"
}
for x in old new; do
    if [ "$x" = old ]; then pf="$old"; else pf="$new"; fi
    mkdir -p "$w/$x/t"
    tar -xf "$pf" -C "$w/$x/t" "$pre/lib/*" 2> "$w/$x/err"
    syms "$w/$x/t" "$w/$x"
    if [ ! -s "$w/$x/sonames" ]; then
        echo "az-abi-check: no shared library of az in $pf: $(grep -v 'Removing leading' "$w/$x/err" | head -n 1)" >&2
        exit 2
    fi
    rm -rf "$w/$x/t"
done
# what the new az lost: SONAMEs, and symbols of the SONAMEs both have
LC_ALL=C comm -23 "$w/old/sonames" "$w/new/sonames" > "$w/gone"
LC_ALL=C comm -12 "$w/old/sonames" "$w/new/sonames" | while read -r sn; do
    LC_ALL=C comm -23 "$w/old/syms/$sn" "$w/new/syms/$sn" > "$w/drop/$sn"
    [ -s "$w/drop/$sn" ] || rm -f "$w/drop/$sn"
done
cat "$w/old/sonames" "$w/new/sonames" | LC_ALL=C sort -u > "$w/az"
lostl=""; nd=0
for f in "$w"/drop/*; do
    [ -f "$f" ] || continue
    nd=$((nd + 1)); lostl="$lostl, ${f##*/} $(wc -l < "$f" | tr -d ' ')"
done
echo "az: $(wc -l < "$w/new/sonames" | tr -d ' ') SONAMEs; gone: $(tr '\n' ' ' < "$w/gone" | sed 's/ $//')$( [ -s "$w/gone" ] || echo none); SONAMEs that lost symbols: $nd${lostl:+ (${lostl#, })}"

rc=0
for p in "$@"; do
    [ -f "$p" ] || { echo "fail $p not there"; rc=1; continue; }
    pkg query -F "$p" '%B' 2> /dev/null | LC_ALL=C sort -u > "$w/req"
    LC_ALL=C comm -12 "$w/req" "$w/az" > "$w/req.az"
    [ -s "$w/req.az" ] || continue
    why=""
    g="$(LC_ALL=C comm -12 "$w/req.az" "$w/gone" | tr '\n' ' ' | sed 's/ $//')"
    [ -n "$g" ] && why="needs $g, which the new az has not"
    lost=""
    for sn in $(cat "$w/req.az"); do [ -f "$w/drop/$sn" ] && lost="$lost $sn"; done
    if [ -n "$lost" ]; then
        # its ELF files: the symbols they bind from the SONAMEs that lost some
        rm -rf "$w/p" && mkdir -p "$w/p"
        tar -xf "$p" -C "$w/p" 2> /dev/null
        find "$w/p" -type f ! -name '+*' | while read -r f; do
            readelf -d "$f" > "$w/dyn" 2> /dev/null || continue
            for sn in $lost; do
                grep -q "Shared library: \[$sn\]" "$w/dyn" || continue
                nm -D --undefined-only "$f" 2> /dev/null | awk '{ s = $NF; sub(/@.*/, "", s); print s }' | LC_ALL=C sort -u |
                    LC_ALL=C comm -12 - "$w/drop/$sn" | head -n 5 | sed "s#^#${f#"$w/p"} binds #; s#\$# of $sn#"
            done
        done > "$w/bad"
        rm -rf "$w/p"
        if [ -s "$w/bad" ]; then
            why="${why:+$why; }$(head -n 3 "$w/bad" | tr '\n' ';' | sed 's/;$//; s/;/; /g'), which the new az does not define"
        fi
    fi
    if [ -n "$why" ]; then echo "fail $p $why"; rc=1; else echo "ok $p"; fi
done
exit "$rc"
