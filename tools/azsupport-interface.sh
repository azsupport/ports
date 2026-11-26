#!/bin/sh
# azsupport-interface.sh - the interfaces of the libraries of azsupport, from the manifests
# their packages have (tools/build.sh, aZ 12.11.2026): a library port (AZSUPPORT_LIB of its
# Makefile: azsupport/<lib>, package azsupport-<lib>, and x11-fonts/fontconfig) has the
# manifest of its library, AZSUPPORT_PREFIX/share/azsupport/interface/<lib>.txt (written by
# tools/azsupport-build.sh --lib, that of x11-fonts/fontconfig by the command make below);
# azsupport/azsupport (package azsupport, the static tree) those of its static
# libraries, AZSUPPORT_PREFIX/static/share/azsupport/interface/<lib>.txt, and common.txt, the
# files of no library. A port that builds against a library port takes into its
# azsupport_hash the interface hash of its library and of those it needs, so that a fix
# inside a library (the same headers, .pc files, SONAMEs, version and options) builds
# again only the port of that library; a port that links the archives of a library into
# its package (AZSUPPORT_STATIC_LIBS) its content hash.
#
# Usage:
#   sh tools/azsupport-interface.sh extract <package> <dir> [<prefix> [<subdir>]]
#       the manifests (*.txt) of <prefix>/<subdir> of a package file into <dir> (<prefix>:
#       default /usr/local/azsupport, AZSUPPORT_PREFIX; <subdir>: default
#       share/azsupport/interface, static/share/azsupport/interface for azsupport/azsupport);
#       exit 1 when the package has no manifest of a library there
#   sh tools/azsupport-interface.sh hashes <dir>
#       a line a library: <name> <interface hash> <content hash> <closure>, the closure
#       the library and those it needs, in turn (its requires lines), separated by
#       commas; first "common <hash> <hash> common" of the files of no library, when the
#       directory has common.txt
#   sh tools/azsupport-interface.sh paths <dir>
#       "<path> <library>" for each path of the manifests (relative to the prefix)
#   sh tools/azsupport-interface.sh sonames <dir>
#       "<SONAME> <library>" for each shared library of the manifests
#   sh tools/azsupport-interface.sh diff <old dir> <new dir>
#       a line a library whose interface differs, with what differs (version, options,
#       requires, the paths of the files that differ, came or went)
#   sh tools/azsupport-interface.sh make <name> <version> <root> <prefix> <options> [<requires>...]
#       the manifest of a library installed in <root><prefix> (a stage: x11-fonts/fontconfig,
#       which builds with the official port into /usr/local) on the standard output: lines
#       library, prefix, version, options (the SHA-256 of the text <options>: the options of
#       its build), a requires line for each library of azsupport it needs, and the files of
#       include/ (all), lib/*.so*, lib/*.a, lib/pkgconfig/*.pc, libdata/pkgconfig/*.pc and
#       bin/*-config, by their paths relative to <prefix>
#
# A manifest: "library <name>", "prefix <dir>" (only when its files are not under
# AZSUPPORT_PREFIX: x11-fonts/fontconfig, /usr/local), "version <version>", "options <hash>",
# "requires <library>" a line each, then a line a file: "file <path> <SHA-256>" (headers,
# .pc files, *-config scripts, cmake and other files), "link <path> <target>",
# "soname <path> <SONAME>" (a shared library: its SONAME, not its code), "archive <path>
# <SHA-256>" (a static archive: its code counts only for a port that links it into its
# package, AZSUPPORT_STATIC_LIBS). The interface hash of a library: the SHA-256 of its
# manifest with the hash of each archive left out (its path stays); the content hash: of
# the whole manifest.
# Exit status: 0 done, 1 no manifests, 2 usage.

set -u
usage() { sed -n 's/^# \{0,1\}//; 15,39p' "$0" >&2; exit 2; }
[ $# -ge 2 ] || usage
if command -v sha256 > /dev/null 2>&1; then
    hin() { sha256; }
    hfile() { sha256 -q "$1"; }
else
    hin() { sha256sum | cut -d ' ' -f 1; }
    hfile() { sha256sum "$1" | cut -d ' ' -f 1; }
fi
cmd="$1"; shift

# has_mans <dir>: a manifest of a library there (<name>.txt with its library line, not
# common.txt, the files of no library)
has_mans() {
    for _m in "$1"/*.txt; do
        [ -f "$_m" ] && [ "${_m##*/}" != common.txt ] || continue
        grep -q '^library ' "$_m" && return 0
    done
    return 1
}
# the manifests of a directory: <name>.txt of the libraries (common.txt with them in that
# of azsupport/azsupport, the static tree)
mans() {
    [ -d "$1" ] || { echo "azsupport-interface: no directory $1" >&2; exit 1; }
    has_mans "$1" || { echo "azsupport-interface: no manifest of a library in $1" >&2; exit 1; }
}

case "$cmd" in
extract)
    [ $# -ge 2 ] || usage
    pf="$1"; d="$2"; pre="${3:-/usr/local/azsupport}"; sub="${4:-share/azsupport/interface}"
    sub="${sub#/}"; sub="${sub%/}"
    [ -f "$pf" ] || { echo "azsupport-interface: no package $pf" >&2; exit 1; }
    t="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-interface.XXXXXX")" || exit 1
    trap 'rm -rf "$t"' EXIT
    # the paths of a package start with / (bsdtar takes it away)
    tar -xf "$pf" -C "$t" "$pre/$sub/*" 2> "$t/err"
    rm -rf "$d" && mkdir -p "$d" || exit 1
    if [ -d "$t$pre/$sub" ]; then
        cp "$t$pre/$sub"/*.txt "$d/" 2> /dev/null
    fi
    if ! has_mans "$d"; then
        echo "azsupport-interface: $pf has no manifest of a library in $pre/$sub ($(grep . "$t/err" | grep -v 'Removing leading' | head -n 1))" >&2
        exit 1
    fi
    exit 0 ;;
hashes)
    mans "$1"
    t="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-interface.XXXXXX")" || exit 1
    trap 'rm -rf "$t"' EXIT
    # common.txt (the files of no library) gives the line common, when it is there
    for m in "$1"/*.txt; do
        [ -f "$m" ] || continue
        n="$(awk '$1 == "library" { print $2; exit }' "$m")"
        [ -n "$n" ] || { echo "azsupport-interface: $m has no library line" >&2; exit 1; }
        ih="$(awk '$1 == "archive" { print $1, $2; next } { print }' "$m" | hin)"
        ch="$(hin < "$m")"
        echo "$n $ih $ch" >> "$t/h"
        awk -v n="$n" '$1 == "requires" { print n, $2 }' "$m" >> "$t/r"
    done
    : >> "$t/h"; : >> "$t/r"
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
        [ -f "$m" ] || continue
        awk '$1 == "library" { n = $2 } $1 == "file" || $1 == "link" || $1 == "soname" || $1 == "archive" { print $2, n }' "$m"
    done
    exit 0 ;;
sonames)
    mans "$1"
    for m in "$1"/*.txt; do
        [ -f "$m" ] || continue
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
make)
    [ $# -ge 5 ] || usage
    nm="$1"; ver="$2"; root="$3"; pre="/${4#/}"; opt="$5"; shift 5
    pre="${pre%/}"
    d="$root$pre"
    [ -n "$nm" ] && [ "$nm" != common ] || { echo "azsupport-interface: make: no name of a library (${nm:-empty})" >&2; exit 2; }
    [ -d "$d" ] || { echo "azsupport-interface: make: no directory $d" >&2; exit 1; }
    t="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-interface.XXXXXX")" || exit 1
    trap 'rm -rf "$t"' EXIT
    # the files of its interface, as tools/azsupport-build.sh takes them: include/, the
    # shared libraries and archives of lib/, the .pc files, the *-config scripts
    (
        cd "$d" || exit 1
        [ ! -d include ] || find include \( -type f -o -type l \)
        [ ! -d lib ] || find lib -maxdepth 1 \( -type f -o -type l \) \( -name '*.so' -o -name '*.so.*' -o -name '*.a' \)
        for pc in lib/pkgconfig libdata/pkgconfig; do
            [ ! -d "$pc" ] || find "$pc" -maxdepth 1 \( -type f -o -type l \) -name '*.pc'
        done
        [ ! -d bin ] || find bin -maxdepth 1 \( -type f -o -type l \) -name '*-config'
    ) > "$t/paths" || exit 1
    while read -r p; do
        f="$d/$p"
        if [ -L "$f" ]; then
            echo "link $p $(readlink "$f")"
            continue
        fi
        case "$p" in
            lib/*.so | lib/*.so.*)
                # a shared library (not a linker script of that name): its SONAME
                if readelf -d "$f" > "$t/dyn" 2> /dev/null; then
                    sn="$(sed -n 's/.*[Ll]ibrary soname: \[\(.*\)\].*/\1/p' "$t/dyn" | head -n 1)"
                    echo "soname $p ${sn:--}"
                    continue
                fi ;;
            *.a) echo "archive $p $(hfile "$f")"; continue ;;
        esac
        echo "file $p $(hfile "$f")"
    done < "$t/paths" > "$t/entries"
    if ! awk '$1 == "soname" || $1 == "archive" { f = 1 } END { exit !f }' "$t/entries"; then
        echo "azsupport-interface: make: no shared library or archive of $nm in $d/lib" >&2
        exit 1
    fi
    echo "library $nm"
    echo "prefix $pre"
    echo "version $ver"
    echo "options $(printf '%s\n' "$opt" | hin)"
    for r in "$@"; do
        [ -n "$r" ] && [ "$r" != "$nm" ] && echo "requires $r"
    done | LC_ALL=C sort -u
    LC_ALL=C sort -k 2,2 "$t/entries"
    exit 0 ;;
*) usage ;;
esac
