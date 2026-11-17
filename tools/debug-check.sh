#!/bin/sh
# tools/debug-check.sh <package>...: the ELF files of packages built with debug
# information or not stripped (aZ, 17.11.2026: no debug in our builds, the packages
# stripped).
#
# A line per package on the output:
#   OK <package>: <n> ELF files and static libraries
#   FAIL <package>: <d> of <n> ELF files and static libraries built with debug
#        information, <s> more not stripped: <files>
# (the paths in the package, the first ten); exit 1 when a package fails, 2 when one
# cannot be read. Built with debug information: a .debug_info over 8 KB (size -A); an
# ELF file that is not stripped (file(1)) has a symbol table and the small
# .debug_info of the objects of the base system the linker adds (the crt: crti.S,
# crtbegin.c... about 1 KB; with a piece of compiler-rt up to about 5 KB), what strip
# takes away. An object file (relocatable) and a static library
# (the .debug_info of its members) need their symbols: they fail with debug
# information only.
#
# tools/build.sh runs it on the packages of each port it builds (results/debug-check.txt);
# .github/workflows/build.yml makes the line "debug: OK|FAIL" of results/checks.txt of it.

[ $# -gt 0 ] || { echo "usage: $0 <package>..." >&2; exit 2; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/debug-check.XXXXXX")" || exit 2
trap 'rm -rf "$tmp"' EXIT
rc=0
for p in "$@"; do
    n="${p##*/}"; n="${n%.pkg}"
    d="$tmp/x"
    rm -rf "$d"; mkdir -p "$d"
    if ! tar -xf "$p" -C "$d" 2> "$tmp/err"; then
        echo "FAIL $n: cannot unpack it: $(head -n 1 "$tmp/err")"
        [ "$rc" = 0 ] && rc=2
        continue
    fi
    # the type of every file at once (the metadata of pkg, +MANIFEST..., is no ELF): a
    # line per ELF file and static library, "<s|-> <r|a|-> <path>" (not stripped;
    # relocatable, archive: their symbols are needed, debug information alone counts)
    find "$d" -type f -exec file -N -F '|' {} + 2> /dev/null |
        awk -F '|' '{
            t = $2; sub(/^ +/, "", t)
            if (t ~ /ar archive/) { printf "- a %s\n", $1; next }
            if (t !~ /^ELF /) next
            printf "%s %s %s\n", (t ~ /not stripped/ ? "s" : "-"), (t ~ /relocatable/ ? "r" : "-"), $1
        }' > "$tmp/elf"
    ne=0; nd=0; ns=0; : > "$tmp/bad"
    while read -r s r f; do
        ne=$((ne + 1))
        # an archive: the .debug_info of all its members
        di="$(size -A "$f" 2> /dev/null | awk '$1 == ".debug_info" { t += $2 } END { print t + 0 }')"
        if [ "${di:-0}" -gt 8192 ]; then
            nd=$((nd + 1)); echo "${f#"$d"}" >> "$tmp/bad"
        elif [ "$s" = s ] && [ "$r" = - ]; then
            ns=$((ns + 1)); echo "${f#"$d"}" >> "$tmp/bad"
        fi
    done < "$tmp/elf"
    if [ "$nd" = 0 ] && [ "$ns" = 0 ]; then
        echo "OK $n: $ne ELF files and static libraries"
        continue
    fi
    nb=$((nd + ns))
    l="$(head -n 10 "$tmp/bad" | tr '\n' ' ' | sed 's/ $//')"
    [ "$nb" -gt 10 ] && l="$l (and $((nb - 10)) more)"
    echo "FAIL $n: $nd of $ne ELF files and static libraries built with debug information, $ns more not stripped: $l"
    rc=1
done
exit "$rc"
