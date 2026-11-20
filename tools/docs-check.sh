#!/bin/sh
# tools/docs-check.sh <package>...: the packages with manual pages, documentation or info
# pages (aZ, 20.11.2026: «и доки и маны мы не юзаем»; Mk/bsd.overlay.mk, az-no-docs,
# takes them out of every package).
#
# A line per package on the output:
#   OK <package>
#   FAIL <package>: <n> files of manual pages, docs or info pages: <files>
# (the paths in the package, the first five): files and directories under share/man, man,
# share/doc, share/info or etc/man.d of /usr/local, or under a directory man of Perl
# (lib/perl5/<dir>/man, lib/perl5/<dir>/perl/man). Exit 1 when a package fails, 2 when one
# cannot be read. The files and directories of a package: pkg query -F (FreeBSD), else the
# keys of "files" and "directories" of its +MANIFEST (tar).
#
# tools/build.sh runs it on every package of the repository it writes
# (results/docs-check.txt); .github/workflows/build.yml makes the line "docs: OK|FAIL"
# of results/checks.txt of it, a FAIL keeps the run from being published.

[ $# -gt 0 ] || { echo "usage: sh tools/docs-check.sh <package>..." >&2; exit 2; }

re='^/usr/local/(share/(man|doc|info)|man|etc/man\.d|lib/perl5/[^/]+/(perl/)?man)(/|$)'
rc=0
for p in "$@"; do
    n="${p##*/}"
    if command -v pkg > /dev/null 2>&1 && files="$(pkg query -F "$p" '%Fp' 2> /dev/null; pkg query -F "$p" '%Dn' 2> /dev/null)"; then
        :
    elif files="$(tar -xOf "$p" +MANIFEST 2> /dev/null | tr ',' '\n' | sed -n 's/^.*"\(\/[^"]*\)":.*$/\1/p')" && [ -n "$files" ]; then
        :
    else
        echo "FAIL $n: cannot read its files"
        [ "$rc" = 1 ] || rc=2
        continue
    fi
    bad="$(printf '%s\n' "$files" | grep -E "$re")"
    if [ -n "$bad" ]; then
        echo "FAIL $n: $(printf '%s\n' "$bad" | grep -c .) files or directories of manual pages, docs or info pages: $(printf '%s\n' "$bad" | head -n 5 | tr '\n' ' ')"
        rc=1
    else
        echo "OK $n"
    fi
done
exit "$rc"
