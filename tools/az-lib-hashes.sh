#!/bin/sh
# az-lib-hashes.sh - the hash of each library of the package az for the ports that
# link it (tools/build.sh), so that a library added to az, or changed, builds again
# only az and the ports that link it, not PHP and every program (aZ, 10.11.2026).
#
# Usage: sh tools/az-lib-hashes.sh <tree> <files>
#   <tree>   the tree of azsupport/ports
#   <files>  the files of the az_hash of az/az (tools/build.sh: those of its
#            directory, Mk/, the files of tools/ its makefiles name), one a line,
#            as "f <path relative to the tree> <sha256>" or as a path alone
# Output, one a line: "common <hash>", then "<library> <position> <hash>" for each
# "lib" line of az/az/files/deps.conf, in its order (position 1, 2, ...).
#
# The lines of the files go each to one library or to the common part:
#   deps.conf            its "lib" and "take" line to that library; "upstream" lines
#                        (the checks of new releases) to none; the rest common
#   tools/az-build.sh    the functions b_<name> and s_<name> (static and shared build;
#                        - of the name as _) to that library
#   files/curl/build-libcurl.sh  lib_<name> to that library, build_curl and
#                        curl_features to curl
#   files/curl-deps.conf the line of a library to it (psl-list to libpsl)
#   files/curl.conf      to curl
#   files/curl/<name>-<version>.patch, files/deps/<name>-<version>/,
#   files/deps/<name>-<version>.patch  to that library
#   Makefile             a line of MASTER_SITES or DISTFILES with :<group> to the
#                        library of the group (cares: c-ares, psllist: libpsl)
#   distinfo             the lines of a distfile of such a group to its library;
#                        TIMESTAMP to none
#   *.md, pkg-descr      to none (not read by a build)
# and every comment line (# first, not #!) to none; all else is common. A library's
# hash is that of the common part, of its own lines and of the hash of the library
# before it in deps.conf: a library may use those built before it (az-build.sh
# builds them in that order), so a port folds in the hash of the last library it
# links and has those before it too. A library added at the end of the "lib" lines
# changes no hash of the libraries before it.

set -eu
[ $# -eq 2 ] || { echo "usage: sh tools/az-lib-hashes.sh <tree> <files>" >&2; exit 2; }
top="$1"; list="$2"
if command -v sha256 > /dev/null 2>&1; then hin() { sha256; }; else hin() { sha256sum | cut -d ' ' -f 1; }; fi
deps="$top/az/az/files/deps.conf"
[ -f "$deps" ] || { echo "az-lib-hashes: no $deps" >&2; exit 2; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/az-lib-hashes.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

awk '$1 == "lib" { print $2 }' "$deps" > "$tmp/libs"
awk '{ print ($1 == "f" ? $2 : $1) }' "$list" | LC_ALL=C sort -u > "$tmp/all"
# the files of tools/ the build of az runs: named outside the comments of its makefiles
# and, in turn, of the scripts so named and of files/curl/build-libcurl.sh (the az_hash
# of az has also those its comments name: tools/mc-build.sh, ffmpeg-build.sh ... in the
# design comment of az/az/Makefile, which no library of az is built with)
named() {
    for _f in "$@"; do
        case "$_f" in
            *Makefile* | *.mk) sed 's/#.*//' "$top/$_f" ;;
            *) grep -v '^[[:space:]]*#' "$top/$_f" ;;
        esac
    done 2> /dev/null | grep -o -E '(tools|AZ_TOOLS[})]?)/[A-Za-z0-9_.-]+' | sed -E 's#^[^/]*/#tools/#; s/\.+$//' | LC_ALL=C sort -u
}
grep -v '^tools/' "$tmp/all" > "$tmp/files" || true
# shellcheck disable=SC2046
set -- $(grep -E '(Makefile[^/]*|\.mk)$' "$tmp/files") az/az/files/curl/build-libcurl.sh
: > "$tmp/tools"
while [ $# -gt 0 ]; do
    named "$@" | while read -r t; do
        grep -qx "$t" "$tmp/all" && ! grep -qx "$t" "$tmp/tools" && echo "$t"
    done > "$tmp/new" || true
    cat "$tmp/new" >> "$tmp/tools"
    # shellcheck disable=SC2046
    set -- $(cat "$tmp/new")
done
LC_ALL=C sort -u "$tmp/files" "$tmp/tools" -o "$tmp/files"

# owner<TAB>path<TAB>line of every line of the files, in the order of the files
while read -r f; do
    [ -f "$top/$f" ] || continue
    awk -v path="$f" -v libsfile="$tmp/libs" -v mkfile="$top/az/az/Makefile" '
        BEGIN {
            while ((getline l < libsfile) > 0) lib[l] = 1
            group["cares"] = "c-ares"; group["psllist"] = "libpsl"
            # the distfiles of the groups: <file>:<group> of the Makefile
            while ((getline l < mkfile) > 0) {
                n = split(l, w, /[ \t\\]+/)
                for (i = 1; i <= n; i++) if (w[i] ~ /\.[a-z]+:[A-Za-z0-9_-]+$/) {
                    g = w[i]; sub(/.*:/, "", g); fn = w[i]; sub(/:[^:]*$/, "", fn); dist[fn] = g
                }
            }
            own = ""
        }
        function libname(id,   x) {
            if (id in lib) return id
            x = id; gsub(/_/, "-", x); if (x in lib) return x
            if (id in group && group[id] in lib) return group[id]
            return ""
        }
        # the library of "<name>-<version>": the longest name of a library before a dash
        function prefixlib(s,   i, best) {
            best = ""
            for (i = length(s); i > 1; i--) if (substr(s, i, 1) == "-" && (substr(s, 1, i - 1) in lib)) { best = substr(s, 1, i - 1); break }
            return best
        }
        function out(o) { if (o != "-") printf "%s\t%s\t%s\n", o, path, $0 }
        {
            if ($0 ~ /^[ \t]*#/ && !(FNR == 1 && $0 ~ /^#!/)) next
            if (path ~ /\.md$/ || path == "az/az/pkg-descr") next
            o = "common"
            if (path == "az/az/files/deps.conf") {
                if ($1 == "lib" || $1 == "take") o = (($2 in lib) ? $2 : "common")
                else if ($1 == "upstream" || NF == 0) o = "-"
            } else if (path == "tools/az-build.sh" || path == "az/az/files/curl/build-libcurl.sh") {
                if (own == "" && match($0, /^[A-Za-z_][A-Za-z0-9_]*\(\) *\{/)) {
                    fn = substr($0, 1, index($0, "(") - 1); id = ""
                    if (path == "tools/az-build.sh" && fn ~ /^[bs]_/) id = substr(fn, 3)
                    if (path != "tools/az-build.sh" && fn ~ /^lib_/) id = substr(fn, 5)
                    if (path != "tools/az-build.sh" && (fn == "build_curl" || fn == "curl_features")) id = "curl"
                    if (id != "") {
                        own = libname(id)
                        if (own != "" && $0 ~ /\}[ \t]*$/) { out(own); own = ""; next }
                    }
                }
                if (own != "") { out(own); if ($0 ~ /^\}/) own = ""; next }
            } else if (path == "az/az/files/curl-deps.conf") {
                if (NF > 0) { o = libname($1); if (o == "" && $1 == "psl-list") o = "libpsl"; if (o == "") o = "common" }
            } else if (path == "az/az/files/curl.conf") {
                o = ("curl" in lib) ? "curl" : "common"
            } else if (path ~ /^az\/az\/files\/curl\/[^\/]+\.patch$/) {
                b = path; sub(/.*\//, "", b); o = prefixlib(b); if (o == "") o = "common"
            } else if (path ~ /^az\/az\/files\/deps\/[^\/]+\.patch$/) {
                b = path; sub(/.*\//, "", b); o = prefixlib(b); if (o == "") o = "common"
            } else if (path ~ /^az\/az\/files\/deps\/[^\/]+\//) {
                b = path; sub(/^az\/az\/files\/deps\//, "", b); sub(/\/.*/, "", b); o = prefixlib(b); if (o == "") o = "common"
            } else if (path == "az/az/Makefile") {
                if (match($0, /:[A-Za-z0-9_-]+[ \t]*\\?[ \t]*$/)) {
                    g = $0; sub(/[ \t]*\\?[ \t]*$/, "", g); sub(/.*:/, "", g)
                    if (g != "" && libname(g) != "") o = libname(g)
                }
            } else if (path == "az/az/distinfo") {
                if ($1 == "TIMESTAMP") o = "-"
                else if (match($0, /\(.*\)/)) { fn = substr($0, RSTART + 1, RLENGTH - 2); sub(/.*\//, "", fn); if ((fn in dist) && libname(dist[fn]) != "") o = libname(dist[fn]) }
            }
            out(o)
        }' "$top/$f"
done < "$tmp/files" > "$tmp/lines"

# AZ_LIB_LINES=<file>: the lines with their owners, to see where each went
[ -z "${AZ_LIB_LINES:-}" ] || cp "$tmp/lines" "$AZ_LIB_LINES"
common="$(awk -F '\t' '$1 == "common"' "$tmp/lines" | hin)"
echo "common $common"
prev="$common"; i=0
while read -r n; do
    i=$((i + 1))
    o="$(awk -F '\t' -v n="$n" '$1 == n' "$tmp/lines" | hin)"
    prev="$(printf 'common %s\nbefore %s\nown %s %s\n' "$common" "$prev" "$n" "$o" | hin)"
    echo "$n $i $prev"
done < "$tmp/libs"
