#!/bin/sh
# tools/debug-check.sh <package>...: the ELF files of packages with debug information
# or a symbol table (aZ, 17.11.2026: no debug in our builds, the packages stripped).
#
# A line per package on the output:
#   OK <package>: <n> ELF files
#   FAIL <package>: <d> of <n> ELF files with debug information, <s> more not stripped: <files>
# (the paths in the package, the first ten); exit 1 when a package fails, 2 when one
# cannot be read. An object file (relocatable) needs its symbols: it fails with debug
# information only. file(1) says what each file is: "with debug_info", "not stripped".
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
    # the type of every file at once; the pkg metadata (+COMPACT_MANIFEST...) is no ELF
    find "$d" -type f -exec file -N -F '|' {} + 2> /dev/null > "$tmp/types"
    awk -F '|' -v d="$d" -v n="$n" '
        {
            f = $1; t = $2
            if (index(f, d) == 1) f = substr(f, length(d) + 1)
            sub(/^ +/, "", t)
            if (t !~ /^ELF /) next
            ne++
            if (t ~ /with debug_info/) { nd++; bad[++nb] = f }
            else if (t ~ /not stripped/ && t !~ /relocatable/) { ns++; bad[++nb] = f }
        }
        END {
            if (nb == 0) { printf "OK %s: %d ELF files\n", n, ne; exit 0 }
            l = ""
            for (i = 1; i <= nb && i <= 10; i++) l = l " " bad[i]
            if (nb > 10) l = l " (and " nb - 10 " more)"
            printf "FAIL %s: %d of %d ELF files with debug information, %d more not stripped:%s\n", n, nd, ne, ns, l
            exit 1
        }' "$tmp/types" || rc=1
done
exit "$rc"
