#!/bin/sh
# tools/hardening-check.sh <dir>...: the protections of the linker in the ELF programs and
# shared objects under the directories (the staging of a port, in its post-install): each
# program a PIE (DYN, not EXEC), each file with BIND_NOW and RELRO. For the ports whose
# build does not take the LDFLAGS of the framework (-pie, -Wl,-zrelro, -Wl,-znow), and the
# cmake ports, to which Mk/Features/pie.mk gives -DCMAKE_POSITION_INDEPENDENT_CODE alone
# (CMake links a program with -pie only after check_pie_supported() under the policy
# CMP0083), found by readelf of their packages (26.11.2026): the ports that name this file.
#
# The object files and the kernel modules (relocatable) are not checked. Exit 1 with
# each file and what it lacks; with HARDENING_CHECK_WARN=yes the same list, exit 0 (a
# port whose build is long: the list goes into its log, the package is kept).

tmp="$(mktemp -d "${TMPDIR:-/tmp}/hardening-check.XXXXXX")" || exit 1
trap 'rm -rf "$tmp"' EXIT
for d in "$@"; do
    [ -d "$d" ] || { echo "hardening-check: no directory $d" >&2; exit 1; }
    find "$d" -type f -exec file -N -F '|' {} + 2> /dev/null
done | awk -F '|' '{ t = $2; sub(/^ +/, "", t) } t ~ /^ELF / && t !~ /relocatable/ { print $1 }' > "$tmp/list"
p=0; l=0; bad=0
while read -r f; do
    t="$(readelf -h "$f" 2> /dev/null | awk '/Type:/ { print $2 }')"
    dy="$(readelf -d "$f" 2> /dev/null)"
    k=lib
    printf '%s\n' "$dy" | grep -q 'FLAGS_1.*PIE' && k=prog
    [ "$t" = EXEC ] && k=prog
    m=""
    [ "$t" = EXEC ] && m="$m not PIE (EXEC),"
    printf '%s\n' "$dy" | grep -q -E 'BIND_NOW|FLAGS_1.*NOW' || m="$m no BIND_NOW,"
    readelf -lW "$f" 2> /dev/null | grep -q GNU_RELRO || m="$m no RELRO,"
    if [ "$k" = prog ]; then p=$((p + 1)); else l=$((l + 1)); fi
    if [ -n "$m" ]; then
        echo "hardening-check: ${f}:${m%,}" >&2
        bad=$((bad + 1))
    fi
done < "$tmp/list"
if [ "$bad" = 0 ]; then
    echo "hardening-check: $p programs (PIE) and $l shared objects with BIND_NOW and RELRO under $*"
    exit 0
fi
echo "hardening-check: $bad of $((p + l)) files ($p programs, $l shared objects) without the protections above, under $*" >&2
[ "${HARDENING_CHECK_WARN:-}" = yes ] && exit 0
exit 1
