#!/bin/sh
# tools/strip-elf.sh <dir>...: strips the ELF programs and shared libraries under the
# directories that are not stripped (aZ, 17.11.2026: no debug in our packages;
# tools/debug-check.sh checks them), for the ports whose install copies the files as
# they were linked: azsupport/azsupport (its tree), java/openjdk21 (the image of the JDK), devel/git,
# www/mod_maxminddb (apxs), and the official ports graphics/libimagequant (cargo
# cinstall), security/sudo (libsudo_util.so) and devel/t1lib (libt1.so).
#
# The object files (relocatable) keep their symbols. The strip of STRIP_CMD of the
# environment of the port, else strip. A file with more hard links (the programs of
# git) is stripped once, into a copy written back into it: the links stay one file.

s="${STRIP_CMD:-strip}"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/strip-elf.XXXXXX")" || exit 1
trap 'rm -rf "$tmp"' EXIT
for d in "$@"; do
    [ -d "$d" ] || { echo "strip-elf: no directory $d" >&2; exit 1; }
    find "$d" -type f -exec file -N -F '|' {} + 2> /dev/null
done | awk -F '|' '{ t = $2; sub(/^ +/, "", t) }
    t ~ /^ELF / && t ~ /not stripped/ && t !~ /relocatable/ { print $1 }' > "$tmp/list"
n=0; rc=0; seen=" "
while read -r f; do
    i="$(ls -i "$f" | awk '{ print $1 }')"
    case "$seen" in *" $i "*) continue ;; esac
    seen="$seen$i "
    m="$(stat -f '%Lp' "$f")"
    if $s -o "$tmp/out" "$f" && chmod u+w "$f" && cat "$tmp/out" > "$f" && chmod "$m" "$f"; then
        n=$((n + 1))
    else
        echo "strip-elf: cannot strip $f" >&2
        rc=1
    fi
done < "$tmp/list"
echo "strip-elf: $n files stripped under $*"
exit "$rc"
