#!/bin/sh
# az-interface.sh - the interfaces of the libraries of the package az, from the
# manifests tools/az-build.sh writes into it (AZ_PREFIX/share/az/interface: <name>.txt
# a library, common.txt the files of no library), for tools/build.sh (aZ, 12.11.2026):
# a port that needs az takes into its az_hash the interface hash of each library of
# az it uses and of those these need, so that a fix inside a library (the same
# headers, .pc files, SONAMEs, version and options) builds again only az, and a port
# that links the archives of a library into its package (AZ_STATIC_LIBS) its content
# hash.
#
# Usage:
#   sh tools/az-interface.sh extract <package of az> <dir> [<AZ_PREFIX>]
#       the manifests of a package file of az into <dir> (AZ_PREFIX: default
#       /usr/local/az); exit 1 when the package has none (built before 12.11.2026)
#   sh tools/az-interface.sh hashes <dir>
#       a line a library: <name> <interface hash> <content hash> <closure>, the closure
#       the library and those it needs, in turn (its requires lines), separated by
#       commas; first "common <hash> <hash> common" of the files of no library
#   sh tools/az-interface.sh paths <dir>
#       "<path> <library>" for each path of the manifests (relative to AZ_PREFIX)
#   sh tools/az-interface.sh sonames <dir>
#       "<SONAME> <library>" for each shared library of the manifests
#   sh tools/az-interface.sh diff <old dir> <new dir>
#       a line a library whose interface differs, with what differs (version, options,
#       requires, the paths of the files that differ, came or went)
#
# The interface hash of a library: the SHA-256 of its manifest with the hash of each
# archive left out (its path stays); the content hash: of the whole manifest.
# Exit status: 0 done, 1 no manifests, 2 usage.

set -u
usage() { sed -n 's/^# \{0,1\}//; 11,26p' "$0" >&2; exit 2; }
[ $# -ge 2 ] || usage
if command -v sha256 > /dev/null 2>&1; then hin() { sha256; }; else hin() { sha256sum | cut -d ' ' -f 1; }; fi
cmd="$1"; shift

# the manifests of a directory: <name>.txt of the libraries, common.txt
mans() {
    [ -d "$1" ] || { echo "az-interface: no directory $1" >&2; exit 1; }
    [ -f "$1/common.txt" ] || { echo "az-interface: no manifests in $1 (common.txt)" >&2; exit 1; }
}

case "$cmd" in
extract)
    [ $# -ge 2 ] || usage
    pf="$1"; d="$2"; pre="${3:-/usr/local/az}"
    [ -f "$pf" ] || { echo "az-interface: no package $pf" >&2; exit 1; }
    t="$(mktemp -d "${TMPDIR:-/tmp}/az-interface.XXXXXX")" || exit 1
    trap 'rm -rf "$t"' EXIT
    # the paths of a package start with / (bsdtar takes it away)
    tar -xf "$pf" -C "$t" "$pre/share/az/interface/*" 2> "$t/err"
    rm -rf "$d" && mkdir -p "$d" || exit 1
    if [ -d "$t$pre/share/az/interface" ]; then
        cp "$t$pre"/share/az/interface/*.txt "$d/" 2> /dev/null
    fi
    if [ ! -f "$d/common.txt" ]; then
        echo "az-interface: $pf has no manifests in $pre/share/az/interface ($(grep . "$t/err" | grep -v 'Removing leading' | head -n 1))" >&2
        exit 1
    fi
    exit 0 ;;
hashes)
    mans "$1"
    t="$(mktemp -d "${TMPDIR:-/tmp}/az-interface.XXXXXX")" || exit 1
    trap 'rm -rf "$t"' EXIT
    for m in "$1"/*.txt; do
        n="$(awk '$1 == "library" { print $2; exit }' "$m")"
        [ -n "$n" ] || { echo "az-interface: $m has no library line" >&2; exit 1; }
        ih="$(awk '$1 == "archive" { print $1, $2; next } { print }' "$m" | hin)"
        ch="$(hin < "$m")"
        echo "$n $ih $ch" >> "$t/h"
        awk -v n="$n" '$1 == "requires" { print n, $2 }' "$m" >> "$t/r"
    done
    : >> "$t/r"
    # the closure of each library: itself and what it requires, in turn
    awk 'FILENAME == ARGV[1] { req[$1] = req[$1] " " $2; next }
        function walk(x,   n, i, t) {
            if (x in seen) return
            seen[x] = 1; out = out "," x
            n = split(req[x], t, " ")
            for (i = 1; i <= n; i++) walk(t[i])
        }
        { split("", seen); out = ""
          if ($1 == "common") out = ",common"; else walk($1)
          n = split(substr(out, 2), a, ","); s = ""
          # sorted, for a closure that does not depend on the order of the requires
          for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (a[j] < a[i]) { x = a[i]; a[i] = a[j]; a[j] = x }
          for (i = 1; i <= n; i++) s = s (i > 1 ? "," : "") a[i]
          print $1, $2, $3, s }' "$t/r" "$t/h" | LC_ALL=C sort | awk '$1 == "common" { print; next } { l[++n] = $0 }
        END { for (i = 1; i <= n; i++) print l[i] }'
    exit 0 ;;
paths)
    mans "$1"
    for m in "$1"/*.txt; do
        awk '$1 == "library" { n = $2 } $1 == "file" || $1 == "link" || $1 == "soname" || $1 == "archive" { print $2, n }' "$m"
    done
    exit 0 ;;
sonames)
    mans "$1"
    for m in "$1"/*.txt; do
        awk '$1 == "library" { n = $2 } $1 == "soname" && $3 != "-" { print $3, n }' "$m"
    done | LC_ALL=C sort -u
    exit 0 ;;
diff)
    [ $# -ge 2 ] || usage
    mans "$1"; mans "$2"
    for m in "$1"/*.txt "$2"/*.txt; do echo "${m##*/}"; done | LC_ALL=C sort -u | while read -r b; do
        o="$1/$b"; n="$2/$b"
        if [ ! -f "$o" ]; then echo "${b%.txt}: new"; continue; fi
        if [ ! -f "$n" ]; then echo "${b%.txt}: gone"; continue; fi
        # the interface only (the hashes of the archives left out)
        ao="$(awk '$1 == "archive" { print $1, $2; next } { print }' "$o" | hin)"
        an="$(awk '$1 == "archive" { print $1, $2; next } { print }' "$n" | hin)"
        [ "$ao" = "$an" ] && continue
        awk 'function key() { return ($1 == "version" || $1 == "options" || $1 == "library") ? $1 : $1 " " $2 }
            FILENAME == ARGV[1] { if ($1 == "archive") $3 = ""; o[key()] = $0; next }
            { if ($1 == "archive") $3 = ""; k = key(); if (!(k in o)) add[k] = $0; else if (o[k] != $0) chg[k] = $0; seen[k] = 1 }
            END {
                for (k in o) if (!(k in seen)) gone[k] = 1
                s = ""
                for (k in chg) { split(k, w, " "); if (w[1] == "version" || w[1] == "options") s = s "; " w[1] " " (w[1] == "version" ? substr(o[k], 9) " -> " substr(chg[k], 9) : "changed"); else s = s "; changed " w[2] }
                for (k in add) { split(k, w, " "); if (w[1] == "version" || w[1] == "options") s = s "; " w[1] " " (w[1] == "version" ? substr(add[k], 9) : "changed"); else s = s "; new " w[1] " " w[2] }
                for (k in gone) { split(k, w, " "); if (w[1] != "version" && w[1] != "options") s = s "; gone " w[1] " " w[2] }
                print substr(s, 3)
            }' "$o" "$n" | sed "s#^#${b%.txt}: #"
    done
    exit 0 ;;
*) usage ;;
esac
