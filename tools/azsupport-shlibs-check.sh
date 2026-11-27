#!/bin/sh
# azsupport-shlibs-check.sh - the packages of a repository that need a shared library of
# /usr/local/azsupport which no package of the repository has (aZ, 27.11.2026: such a
# package goes from the repository, a line each in the report of the run; its port is
# built in the same run; a package of no port of this tree fails the run). The case it is
# for: a library port that failed, or that a run did not build, when the package
# azsupport of before the split (every shared library of /usr/local/azsupport) is gone, so
# that a package of before that needs that library has none (php84-gd and
# nginx-devel-image-filter on libgd.so.3, build-jail.yml 45928963778). tools/build.sh
# runs it before the builds (the repository as it was) and before the catalog (the
# repository of the run), with the files it makes of pkg query.
#
# Usage: sh tools/azsupport-shlibs-check.sh <SONAMEs> <provided> <required>
#   <SONAMEs>   a SONAME a line: those of /usr/local/azsupport (the shlibs_provided of
#               the packages of azsupport/*, the soname lines of their manifests)
#   <provided>  "<file> <SONAME>" a line: the shlibs_provided (%b) of each package
#   <required>  "<file> <SONAME>" a line: the shlibs_required (%B) of each package
# Output: "<file> <SONAME>[,<SONAME>...]" a line for each package to go, with the SONAMEs
#   of /usr/local/azsupport it needs and no other package has; one that goes takes its
#   SONAMEs with it, so a package that needs one of them goes too (in the order of
#   LC_ALL=C sort). A package that provides a SONAME it needs is not its own provider.
#   sh tools/azsupport-shlibs-check.sh --test: its cases ("ok" or "FAIL" a line).
# Exit status: 0, 1 a case of --test failed, 2 a wrong call.

set -u

check() {
    awk 'FILENAME == ARGV[1] { if (NF) az[$1] = 1; next }
        FILENAME == ARGV[2] { if (NF == 2 && !(($1, $2) in pv)) { pv[$1, $2] = 1; np[$2]++; pf[$1] = pf[$1] " " $2 } next }
        NF == 2 && ($2 in az) && !(($1, $2) in rs) { rs[$1, $2] = 1; rq[$1] = rq[$1] " " $2 }
        END {
            do {
                n = 0
                for (f in rq) {
                    if (f in out) continue
                    m = split(rq[f], r, " "); miss = ""
                    for (i = 1; i <= m; i++) if (np[r[i]] - ((f, r[i]) in pv) <= 0) miss = miss (miss == "" ? "" : ",") r[i]
                    if (miss != "") { now[++n] = f; why[f] = miss }
                }
                for (j = 1; j <= n; j++) {
                    f = now[j]; out[f] = 1; print f, why[f]
                    k = split(pf[f], p, " "); for (i = 1; i <= k; i++) np[p[i]]--
                }
            } while (n > 0)
        }' "$1" "$2" "$3" | LC_ALL=C sort
}

# --test: each case its three files and what it is to print
selftest() {
    t="${TMPDIR:-/tmp}/azsupport-shlibs-check.$$"
    mkdir -p "$t" || exit 2
    bad=0
    case_() {
        printf '%s\n' "$2" | tr ';' '\n' | grep . > "$t/az"
        printf '%s\n' "$3" | tr ';' '\n' | grep . > "$t/b"
        printf '%s\n' "$4" | tr ';' '\n' | grep . > "$t/r"
        got="$(check "$t/az" "$t/b" "$t/r" | tr '\n' ';')"
        if [ "$got" = "$5" ]; then echo "ok    $1"; else echo "FAIL  $1: got [$got], want [$5]"; bad=1; fi
    }
    # the library there: nothing goes
    case_ "provided" "libgd.so.3" "azsupport-gd.pkg libgd.so.3" "php84-gd.pkg libgd.so.3" ""
    # the case of 45928963778: azsupport of before gone, azsupport-gd not built
    case_ "no package has it" "libgd.so.3;libpng16.so.16" "azsupport-png.pkg libpng16.so.16" \
        "php84-gd.pkg libgd.so.3;php84-gd.pkg libpng16.so.16;mrtg.pkg libgd.so.3" "mrtg.pkg libgd.so.3;php84-gd.pkg libgd.so.3;"
    # a SONAME that is not of /usr/local/azsupport (an official package, the base system)
    case_ "not of azsupport" "libgd.so.3" "" "php84-gd.pkg libimagequant.so.0" ""
    # in turn: azsupport-libxslt of before needs libxml2.so.16 (gone), php84-xsl its libxslt
    case_ "in turn" "libxml2.so.16;libxslt.so.1;libexslt.so.0" "azsupport-libxslt.pkg libxslt.so.1;azsupport-libxslt.pkg libexslt.so.0" \
        "azsupport-libxslt.pkg libxml2.so.16;php84-xsl.pkg libxslt.so.1;php84-xsl.pkg libexslt.so.0" \
        "azsupport-libxslt.pkg libxml2.so.16;php84-xsl.pkg libxslt.so.1,libexslt.so.0;"
    # its own SONAME is not its provider; another package that has it is
    case_ "its own" "libfoo.so.1" "a.pkg libfoo.so.1" "a.pkg libfoo.so.1" "a.pkg libfoo.so.1;"
    case_ "another has it" "libfoo.so.1" "a.pkg libfoo.so.1;b.pkg libfoo.so.1" "a.pkg libfoo.so.1" ""
    find "$t" -delete
    [ "$bad" = 0 ]
}

case "${1:-}" in
    --test) selftest; exit $? ;;
esac
[ $# = 3 ] && [ -f "$1" ] && [ -f "$2" ] && [ -f "$3" ] || { sed -n '/^# Usage/,/^# Exit/s/^# \{0,1\}//p' "$0" >&2; exit 2; }
check "$1" "$2" "$3"
