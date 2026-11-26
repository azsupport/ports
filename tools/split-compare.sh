#!/bin/sh
# split-compare.sh - the packages of azsupport of two repositories compared, for the split of
# the package azsupport into a port a library (aZ, 26.11.2026: every library of azsupport a
# port of its own; tests T1 and T3 of the plan): the repository before (the files of the
# release, hard links taken before tools/build.sh) and the one a run made. The packages of
# azsupport: those of the origins azsupport/* and x11-fonts/fontconfig (in the repository
# before the split: the one package azsupport with every library, its static tree and its
# shared one in /usr/local/azsupport).
#   - the shared tree (/usr/local/azsupport but static/; fontconfig in /usr/local since the
#     split, its files taken by their paths under it, libdata/pkgconfig as lib/pkgconfig):
#     the same files in the packages after as before (but the manifests of
#     share/azsupport/interface, the VERSIONS of share/doc and the licences of LICENSES/,
#     which the split writes again, and bin/pkg-config, which is no package since (aZ,
#     26.11.2026: Mk/azsupport-pkg-config.mk writes it into the work of a port): said); each
#     header (include/) and .pc file the same SHA-256, each *-config script the same but the
#     directories of its build (APR_SOURCE_DIR= and the like: the work of the machine that
#     built it); each shared library the same SONAME and exported symbols (nm -D
#     --defined-only), the same RUNPATH but its repeated directories, no NEEDED it had not
#     before, and of those it had and has not (the dependency_libs of the .la files of the
#     one tree of before, which a library port does not install) none whose symbols it needs
#     that its other NEEDED do not have (nm -D of the libraries of the base system and of the
#     tree after); a link the same target; for fontconfig, which the official port builds
#     into /usr/local, the differences are said, not failed;
#   - the SBOM of each package (share/sbom/pc/<package>.pc of the ports framework: its
#     version, origin, dependencies) is a file of that package: new after for each library
#     port, another for azsupport (said);
#   - the static tree (/usr/local/azsupport/static): the same files (but its manifests in
#     static/share/azsupport/interface and its licences in static/LICENSES, new there), the
#     same SHA-256 for every file but the archives and the programs, each archive the same
#     members (ar t) and defined global symbols (nm -g --defined-only), each program (the
#     tools of ICU in static/sbin) the same NEEDED, RUNPATH and dynamic symbols (its bytes
#     differ when another machine built it: the start files of its base system, crt1.o and
#     crtbegin.o, are linked into it; said);
#   - every other origin built again (its package file another in the repository after) the
#     same shared libraries required (shlibs_required, pkg query %B);
#   - no package after depends on the port of the static tree (the origin of the package
#     that has it) but graphics/GraphicsMagick and graphics/libimagemagick7; with SPLIT_QUEUE
#     the packages of the origins of the queue of the run only (the others, of before the
#     split, said: a run of all the ports builds them again).
#
# Usage (FreeBSD; pkg, tar, readelf, nm, ar, sha256 of the base system):
#   sh tools/split-compare.sh <repository before> <repository after>
# Environment: AZSUPPORT_PREFIX (default /usr/local/azsupport), AZSUPPORT_STATIC (default
#   AZSUPPORT_PREFIX/static), SPLIT_WORK (the work directory, default a temporary one; the
#   packages of azsupport of both repositories are unpacked there), SPLIT_QUEUE (a file
#   with the origins of the queue of the run, one a line: results/queue.txt of
#   tools/build.sh; without it every package after is taken).
# Output: a line a check, "OK ...", "FAIL ..." or "INFO ...", then "result: OK" or
#   "result: FAIL (<n> checks failed)".
# Exit status: 0 no FAIL, 1 a FAIL, 2 usage or a repository that could not be read.

set -u
[ $# -eq 2 ] || { echo "usage: sh tools/split-compare.sh <repository before> <repository after>" >&2; exit 2; }
old="$(cd "$1" 2> /dev/null && pwd)" || { echo "split-compare: no directory $1" >&2; exit 2; }
new="$(cd "$2" 2> /dev/null && pwd)" || { echo "split-compare: no directory $2" >&2; exit 2; }
pre="${AZSUPPORT_PREFIX:-/usr/local/azsupport}"; pre="${pre%/}"
spre="${AZSUPPORT_STATIC:-$pre/static}"; spre="${spre%/}"
srel="${spre#"$pre"/}"
lb=/usr/local
if [ -n "${SPLIT_WORK:-}" ]; then
    w="$SPLIT_WORK"; rm -rf "$w"; mkdir -p "$w" || { echo "split-compare: cannot make $w" >&2; exit 2; }
else
    w="$(mktemp -d "${TMPDIR:-/tmp}/split-compare.XXXXXX")" || { echo "split-compare: no temporary directory" >&2; exit 2; }
    trap 'rm -rf "$w"' EXIT
fi
trap 'exit 2' INT TERM
if command -v sha256 > /dev/null 2>&1; then hfile() { sha256 -q "$1"; }; else hfile() { sha256sum "$1" | cut -d ' ' -f 1; }; fi
nf=0
ok() { printf 'OK   %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*"; nf=$((nf + 1)); }
info() { printf 'INFO %s\n' "$*"; }

# the packages of a repository: "<origin> <name> <file>" ($w/<side>.pkgs), the catalog left out;
# of two packages of an origin (the cache of a run and the files of the release, together
# before tools/build.sh), the newer version, as tools/build.sh keeps it
for side in old new; do
    if [ "$side" = old ]; then d="$old"; else d="$new"; fi
    : > "$w/$side.notpkg"
    for f in "$d"/*.pkg; do
        [ -f "$f" ] || continue
        case "${f##*/}" in packagesite.*|meta.*|digests.*|filesite.*|data.*) continue ;; esac
        onv="$(pkg query -F "$f" '%o %n %v' 2> /dev/null)"
        [ -n "$onv" ] || { echo "${f##*/}" >> "$w/$side.notpkg"; continue; }
        echo "$onv ${f##*/}"
    done | LC_ALL=C sort > "$w/$side.all"
    [ -s "$w/$side.notpkg" ] && info "packages: not packages in $d: $(tr '\n' ' ' < "$w/$side.notpkg")"
    : > "$w/$side.pkgs"
    po=""; pn=""; pv=""; pf=""
    while read -r o n v f; do
        if [ "$o" = "$po" ]; then
            if [ "$(pkg version -t "$v" "$pv" 2> /dev/null)" = ">" ]; then
                info "packages: $pf of $d left out ($f of $o is newer)"; pn="$n"; pv="$v"; pf="$f"
            else
                info "packages: $f of $d left out ($pf of $o is newer or the same version)"
            fi
            continue
        fi
        [ -z "$po" ] || echo "$po $pn $pf" >> "$w/$side.pkgs"
        po="$o"; pn="$n"; pv="$v"; pf="$f"
    done < "$w/$side.all"
    [ -z "$po" ] || echo "$po $pn $pf" >> "$w/$side.pkgs"
    [ -s "$w/$side.pkgs" ] || { echo "split-compare: no package in $d" >&2; exit 2; }
done
info "packages: $(grep -c . "$w/old.pkgs") before ($old), $(grep -c . "$w/new.pkgs") after ($new)"

# the packages of azsupport of each side, unpacked into $w/<side>/root, and their files:
# "<key> <origin> <path>" ($w/<side>.files), the key the path relative to AZSUPPORT_PREFIX (that
# of fontconfig relative to /usr/local, libdata/pkgconfig as lib/pkgconfig; a path elsewhere
# as itself)
for side in old new; do
    if [ "$side" = old ]; then d="$old"; else d="$new"; fi
    mkdir -p "$w/$side/root"
    : > "$w/$side.files"
    while read -r o n f; do
        case "$o" in azsupport/*|x11-fonts/fontconfig) ;; *) continue ;; esac
        if ! tar -xf "$d/$f" -C "$w/$side/root" 2> "$w/tar.err"; then
            fail "unpack: $f of $d: $(head -n 1 "$w/tar.err")"
            continue
        fi
        pkg query -F "$d/$f" '%Fp' 2> /dev/null | awk -v o="$o" -v pre="$pre" -v lb="$lb" '
            { p = $0; k = p
              if (index(p, pre "/") == 1) k = substr(p, length(pre) + 2)
              else if (o == "x11-fonts/fontconfig" && index(p, lb "/") == 1) {
                  k = substr(p, length(lb) + 2); sub(/^libdata\/pkgconfig\//, "lib/pkgconfig/", k) }
              print k, o, p }' >> "$w/$side.files"
    done < "$w/$side.pkgs"
    LC_ALL=C sort -k 1,1 "$w/$side.files" -o "$w/$side.files"
    awk '{ print $1 }' "$w/$side.files" | uniq -d > "$w/$side.dup"
    if [ -s "$w/$side.dup" ]; then
        fail "files ($side): $(grep -c . "$w/$side.dup") paths in two packages of azsupport: $(head -n 10 "$w/$side.dup" | tr '\n' ' ')"
    fi
done
info "the packages of azsupport: before $(awk '{ print $2 }' "$w/old.files" | LC_ALL=C sort -u | tr '\n' ' ')($(grep -c . "$w/old.files") files); after $(awk '{ print $2 }' "$w/new.files" | LC_ALL=C sort -u | grep -c .) origins ($(grep -c . "$w/new.files") files)"

# the static tree and the rest, each sorted by its key
for side in old new; do
    awk -v s="$srel/" 'index($1, s) == 1' "$w/$side.files" | LC_ALL=C sort -k 1,1 > "$w/$side.static"
    awk -v s="$srel/" 'index($1, s) != 1' "$w/$side.files" | LC_ALL=C sort -k 1,1 > "$w/$side.shared"
done
# twocol <a> <b>: the lines of one of two sorted files only, "before: <line>" or "after: <line>"
twocol() {
    LC_ALL=C comm -3 "$1" "$2" | awk -F '\t' '{ if ($1 != "") print "before: " $1; else print "after: " $2 }'
}
# expected <part> <key>: a file the split writes again or moves, said and not failed: the
# manifests, the lists of versions and the licences, which the split writes again; the
# pkg-config of the shared tree, no package since (aZ, 26.11.2026); the SBOM of a package (the
# ports framework writes share/sbom/pc/<package>.pc into each: a new one for each library
# port, another for azsupport, whose version and files changed)
expected() {
    case "$1:$2" in
        shared:share/azsupport/interface/*|shared:share/doc/azsupport/*|shared:share/doc/azsupport-*/*|shared:LICENSES/*) return 0 ;;
        shared:bin/pkg-config) return 0 ;;
        shared:"$lb"/share/sbom/pc/*.pc) return 0 ;;
        static:"$srel"/share/azsupport/interface/*|static:"$srel"/LICENSES/*) return 0 ;;
    esac
    return 1
}
# the files of one side only, of a part (shared, static); the files of both:
# "<key> <origin before> <path before> <origin after> <path after>" ($w/both.<part>)
for part in shared static; do
    LC_ALL=C join -j 1 "$w/old.$part" "$w/new.$part" > "$w/both.$part"
    LC_ALL=C join -j 1 -v 1 "$w/old.$part" "$w/new.$part" > "$w/gone.$part"
    LC_ALL=C join -j 1 -v 2 "$w/old.$part" "$w/new.$part" > "$w/came.$part"
    : > "$w/gone.$part.bad"; : > "$w/gone.$part.exp"; : > "$w/came.$part.bad"; : > "$w/came.$part.exp"
    while read -r k o p; do
        if expected "$part" "$k"; then echo "$k" >> "$w/gone.$part.exp"; else echo "$k" >> "$w/gone.$part.bad"; fi
    done < "$w/gone.$part"
    # a file only after: of fontconfig (the official port has its programs and data) said
    while read -r k o p; do
        if expected "$part" "$k" || [ "$o" = x11-fonts/fontconfig ]; then echo "$k ($o)" >> "$w/came.$part.exp"; else echo "$k ($o)" >> "$w/came.$part.bad"; fi
    done < "$w/came.$part"
    if [ -s "$w/gone.$part.bad" ]; then
        fail "files ($part): $(grep -c . "$w/gone.$part.bad") before and in no package after: $(head -n 20 "$w/gone.$part.bad" | tr '\n' ' ')"
    else
        ok "files ($part): every file before is in a package after ($(grep -c . "$w/old.$part") before, $(grep -c . "$w/new.$part") after)"
    fi
    [ -s "$w/gone.$part.exp" ] && info "files ($part): written again by the split or no package since, gone from where they were: $(grep -c . "$w/gone.$part.exp") ($(head -n 8 "$w/gone.$part.exp" | tr '\n' ' ')...)"
    if [ -s "$w/came.$part.bad" ]; then
        fail "files ($part): $(grep -c . "$w/came.$part.bad") new in the packages after: $(head -n 20 "$w/came.$part.bad" | tr '\n' ' ')"
    else
        ok "files ($part): no file of a library new after"
    fi
    [ -s "$w/came.$part.exp" ] && info "files ($part): new after, by design: $(grep -c . "$w/came.$part.exp") ($(head -n 8 "$w/came.$part.exp" | tr '\n' ' ')...)"
done

# elf_dyn <file>: the dynamic section of an ELF file, sorted: "soname <name>", "needed <library>",
# "runpath <directories>" and "rpath <directories>" with each directory once, in its order (a
# repeated one finds nothing more: libtool of the one tree of before wrote /usr/local/azsupport/lib
# three times into some)
elf_dyn() {
    readelf -d "$1" 2> /dev/null | sed -n -e 's/.*[Ll]ibrary soname: \[\(.*\)\].*/soname \1/p' \
        -e 's/.*[Ss]hared library: \[\(.*\)\].*/needed \1/p' -e 's/.*[Ll]ibrary runpath: \[\(.*\)\].*/runpath \1/p' \
        -e 's/.*[Ll]ibrary rpath: \[\(.*\)\].*/rpath \1/p' |
        awk '$1 == "runpath" || $1 == "rpath" {
                n = split($2, d, ":"); s = ""; split("", seen)
                for (i = 1; i <= n; i++) if (!(d[i] in seen)) { seen[d[i]] = 1; s = s (s == "" ? "" : ":") d[i] }
                print $1, s; next }
            { print }' | LC_ALL=C sort -u
}
# esyms <file>: the dynamic symbols it defines, with their kinds and versions
esyms() { nm -D --defined-only "$1" 2> /dev/null | awk 'NF >= 3 { print "sym", $2, $3 }' | LC_ALL=C sort -u; }
# dnames <file>: the names of the dynamic symbols it defines; unames <file>: of those it
# needs (U; a weak one may stay unresolved), the versions left out
dnames() { nm -D --defined-only "$1" 2> /dev/null | awk 'NF >= 3 { s = $3; sub(/@.*/, "", s); print s }' | LC_ALL=C sort -u; }
unames() { nm -D --undefined-only "$1" 2> /dev/null | awk '$1 == "U" { s = $2; sub(/@.*/, "", s); print s }' | LC_ALL=C sort -u; }
# libfile <name>: the file of a library a NEEDED names: of the tree after, of the base system,
# of /usr/local/lib (after, and of the machine)
libfile() {
    for _d in "$w/new/root$pre/lib" /lib /usr/lib "$w/new/root$lb/lib" "$lb/lib"; do
        [ -e "$_d/$1" ] && { echo "$_d/$1"; return 0; }
    done
    return 1
}
# elf_cmp <before> <after> <note file>: the differences of two ELF files that fail, on the
# standard output, a line each (none: the same SONAME, RUNPATH, exported symbols, no NEEDED
# new); a NEEDED of before only fails only when the file needs a symbol of that library that
# its other NEEDED do not define (else into the note file: the over-linking of the .la files
# of the one tree of before)
elf_cmp() {
    elf_dyn "$1" > "$w/dyn.old"; elf_dyn "$2" > "$w/dyn.new"
    esyms "$1" > "$w/sym.old"; esyms "$2" > "$w/sym.new"
    grep -v '^needed ' "$w/dyn.old" > "$w/dyn.old.x"; grep -v '^needed ' "$w/dyn.new" > "$w/dyn.new.x"
    twocol "$w/dyn.old.x" "$w/dyn.new.x"
    twocol "$w/sym.old" "$w/sym.new" | head -n 6
    sed -n 's/^needed //p' "$w/dyn.old" > "$w/need.old"; sed -n 's/^needed //p' "$w/dyn.new" > "$w/need.new"
    LC_ALL=C comm -13 "$w/need.old" "$w/need.new" | sed 's/^/a NEEDED new after: /'
    LC_ALL=C comm -23 "$w/need.old" "$w/need.new" > "$w/need.gone"
    [ -s "$w/need.gone" ] || return 0
    unames "$2" > "$w/und"
    : > "$w/have"
    while read -r _y; do
        _yf="$(libfile "$_y")" && dnames "$_yf" >> "$w/have"
    done < "$w/need.new"
    LC_ALL=C sort -u "$w/have" -o "$w/have"
    while read -r _x; do
        if ! _xf="$(libfile "$_x")"; then
            echo "needed $_x before only, and no $_x here to see whether it needs a symbol of it"
            continue
        fi
        dnames "$_xf" | LC_ALL=C comm -12 "$w/und" - | LC_ALL=C comm -23 - "$w/have" > "$w/lost"
        if [ -s "$w/lost" ]; then
            echo "needed $_x before only, and it needs $(grep -c . "$w/lost") symbols that only it of its NEEDED of before defines: $(head -n 5 "$w/lost" | tr '\n' ' ' | sed 's/ $//')"
        else
            echo "${2#"$w"/new/root}: $_x NEEDED before only, none of its symbols needed (or its other NEEDED define them)" >> "$3"
        fi
    done < "$w/need.gone"
}
# cfg_norm <file>: a *-config script without the directories of its build (APR_SOURCE_DIR=,
# APU_BUILD_DIR= ...: the work of the machine that built it; used only from a source tree)
cfg_norm() { sed -E '/^[A-Z][A-Z0-9_]*_(SOURCE|BUILD)_DIR=/d' "$1"; }
# the shared tree, the files in both: their contents, as their kind asks
nb=0; nc=0; nfc=0; nsb=0
: > "$w/shared.bad"; : > "$w/shared.fc"; : > "$w/shared.note"
while read -r k oo op no np; do
    of="$w/old/root$op"; nf_="$w/new/root$np"
    why=""
    case "$k" in "$lb"/share/sbom/pc/*.pc) nsb=$((nsb + 1)); continue ;; esac
    if [ -L "$of" ] || [ -L "$nf_" ]; then
        [ "$(readlink "$of" 2> /dev/null)" = "$(readlink "$nf_" 2> /dev/null)" ] || why="link $(readlink "$of" 2> /dev/null) -> $(readlink "$nf_" 2> /dev/null)"
    else
        case "$k" in
            lib/*.so | lib/*.so.*)
                if readelf -d "$of" > /dev/null 2>&1; then
                    why="$(elf_cmp "$of" "$nf_" "$w/shared.note" | head -n 6 | tr '\n' ';' | sed 's/;$//; s/;/; /g')"
                    nc=$((nc + 1))
                elif [ "$(hfile "$of")" != "$(hfile "$nf_")" ]; then
                    why="SHA-256"
                fi ;;
            bin/*-config)
                if [ "$(hfile "$of")" != "$(hfile "$nf_")" ]; then
                    cfg_norm "$of" > "$w/cfg.old"; cfg_norm "$nf_" > "$w/cfg.new"
                    if cmp -s "$w/cfg.old" "$w/cfg.new"; then
                        echo "$k: the same but the directories of its build" >> "$w/shared.note"
                    else
                        why="SHA-256 ($(diff "$w/cfg.old" "$w/cfg.new" | grep -c '^[<>]') lines differ but the directories of its build)"
                    fi
                fi ;;
            include/* | *.pc)
                [ "$(hfile "$of")" = "$(hfile "$nf_")" ] || why="SHA-256" ;;
        esac
    fi
    nb=$((nb + 1))
    [ -n "$why" ] || continue
    if [ "$no" = x11-fonts/fontconfig ]; then
        echo "$k: $why" >> "$w/shared.fc"; nfc=$((nfc + 1))
    else
        echo "$k ($no): $why" >> "$w/shared.bad"
    fi
done < "$w/both.shared"
if [ -s "$w/shared.bad" ]; then
    fail "the shared tree: $(grep -c . "$w/shared.bad") of the $nb files in both differ (headers and .pc files by SHA-256, *-config scripts by SHA-256 but the directories of their builds, shared libraries by SONAME, NEEDED, RUNPATH and exported symbols, links by target):"
    head -n 40 "$w/shared.bad" | cut -c1-400 | sed 's/^/    /'
else
    ok "the shared tree: the $nb files in both the same (headers, .pc files: SHA-256; *-config scripts: SHA-256 but the directories of their builds; $nc shared libraries: SONAME, RUNPATH, exported symbols, no NEEDED new; links)"
fi
if [ -s "$w/shared.note" ]; then
    info "the shared tree: $(grep -c . "$w/shared.note") differences of no weight:"
    head -n 40 "$w/shared.note" | cut -c1-300 | sed 's/^/    /'
fi
[ "$nsb" = 0 ] || info "the shared tree: the SBOM of $nsb packages in both (share/sbom/pc/<package>.pc of the ports framework: their versions, files and dependencies) not compared"
if [ -s "$w/shared.fc" ]; then
    info "fontconfig, built by the official port into $lb: $nfc of its files differ from those it had in $pre:"
    head -n 20 "$w/shared.fc" | cut -c1-300 | sed 's/^/    /'
fi

# the static tree: every file but the archives and the programs by SHA-256, the archives by
# their members and their defined global symbols, the programs (ELF: the tools of ICU) by
# elf_cmp and the symbols they need
ar_sig() {
    ar t "$1" 2> /dev/null | LC_ALL=C sort | sed 's/^/member /'
    nm -g --defined-only "$1" 2> /dev/null | awk '/:$/ { m = $0; sub(/:$/, "", m); next } NF >= 2 { print "sym", m, $(NF - 1), $NF }' | LC_ALL=C sort -u
}
nb=0; na=0; ne=0
: > "$w/static.bad"; : > "$w/static.note"
while read -r k oo op no np; do
    of="$w/old/root$op"; nf_="$w/new/root$np"
    nb=$((nb + 1))
    if [ -L "$of" ] || [ -L "$nf_" ]; then
        [ "$(readlink "$of" 2> /dev/null)" = "$(readlink "$nf_" 2> /dev/null)" ] || echo "$k: link $(readlink "$of" 2> /dev/null) -> $(readlink "$nf_" 2> /dev/null)" >> "$w/static.bad"
        continue
    fi
    case "$k" in
        *.a)
            na=$((na + 1))
            ar_sig "$of" > "$w/ar.old"; ar_sig "$nf_" > "$w/ar.new"
            if ! cmp -s "$w/ar.old" "$w/ar.new"; then
                echo "$k: $(twocol "$w/ar.old" "$w/ar.new" | grep -c .) members or symbols differ: $(twocol "$w/ar.old" "$w/ar.new" | head -n 4 | tr '\n' ';' | sed 's/;$//; s/;/; /g')" >> "$w/static.bad"
            fi ;;
        *)
            [ "$(hfile "$of")" = "$(hfile "$nf_")" ] && continue
            if readelf -h "$of" > /dev/null 2>&1 && readelf -h "$nf_" > /dev/null 2>&1; then
                ne=$((ne + 1))
                why="$( { elf_cmp "$of" "$nf_" "$w/static.note"; unames "$of" > "$w/und.old"; unames "$nf_" > "$w/und.new"; twocol "$w/und.old" "$w/und.new" | sed 's/^/symbol needed /'; } | head -n 6 | tr '\n' ';' | sed 's/;$//; s/;/; /g')"
                if [ -n "$why" ]; then
                    echo "$k: $why" >> "$w/static.bad"
                else
                    echo "$k: another file with the same NEEDED, RUNPATH and dynamic symbols (built on another machine: the start files of its base system, crt1.o and crtbegin.o, are linked into it)" >> "$w/static.note"
                fi
            else
                echo "$k: SHA-256" >> "$w/static.bad"
            fi ;;
    esac
done < "$w/both.static"
if [ -s "$w/static.bad" ]; then
    fail "the static tree: $(grep -c . "$w/static.bad") of the $nb files in both differ (archives: ar t and nm -g --defined-only; programs: NEEDED, RUNPATH, dynamic symbols; the other files: SHA-256):"
    head -n 40 "$w/static.bad" | cut -c1-300 | sed 's/^/    /'
else
    ok "the static tree: the $nb files in both the same ($na archives: members and defined global symbols; $ne programs another file: NEEDED, RUNPATH and dynamic symbols; the others: SHA-256)"
fi
if [ -s "$w/static.note" ]; then
    info "the static tree: $(grep -c . "$w/static.note") differences of no weight:"
    head -n 40 "$w/static.note" | cut -c1-300 | sed 's/^/    /'
fi

# every other origin built again: the same shlibs_required
nr=0
: > "$w/shlibs.bad"
LC_ALL=C join -j 1 "$w/old.pkgs" "$w/new.pkgs" 2> /dev/null | while read -r o on of nn nf2; do
    case "$o" in azsupport/*|x11-fonts/fontconfig) continue ;; esac
    # the same file (a hard link of the repository before, a package kept): not built again
    if [ "$of" = "$nf2" ] && { [ "$old/$of" -ef "$new/$nf2" ] || [ "$(hfile "$old/$of")" = "$(hfile "$new/$nf2")" ]; }; then continue; fi
    echo "$o $of $nf2"
done > "$w/rebuilt"
while read -r o of nf2; do
    nr=$((nr + 1))
    pkg query -F "$old/$of" '%B' 2> /dev/null | LC_ALL=C sort -u > "$w/B.old"
    pkg query -F "$new/$nf2" '%B' 2> /dev/null | LC_ALL=C sort -u > "$w/B.new"
    cmp -s "$w/B.old" "$w/B.new" && continue
    echo "$o ($of -> $nf2): $(twocol "$w/B.old" "$w/B.new" | sed 's/^before: /-/; s/^after: /+/' | tr '\n' ' ' | sed 's/ $//')" >> "$w/shlibs.bad"
done < "$w/rebuilt"
if [ -s "$w/shlibs.bad" ]; then
    fail "the origins built again: $(grep -c . "$w/shlibs.bad") of $nr with other shared libraries required (shlibs_required; - before only, + after only):"
    head -n 40 "$w/shlibs.bad" | cut -c1-300 | sed 's/^/    /'
else
    ok "the origins built again: the $nr of them with the same shared libraries required (shlibs_required)"
fi

# the port of the static tree after: the origin of the package with files of it; no package
# depends on it but those that link its archives (GraphicsMagick and libimagemagick7)
so="$(awk -v s="$srel/" 'index($1, s) == 1 { print $2 }' "$w/new.files" | LC_ALL=C sort -u)"
case "$(printf '%s\n' "$so" | grep -c .)" in
    0) fail "the static tree: no package after has it ($spre)" ;;
    1)
        : > "$w/sdeps"; : > "$w/sdeps.out"
        while read -r o n f; do
            pkg query -F "$new/$f" '%do' 2> /dev/null | grep -qxF "$so" || continue
            case "$o" in
                graphics/GraphicsMagick|graphics/libimagemagick7) ok "dependencies: $o depends on $so (it links the archives of the static tree)" ;;
                *)
                    # SPLIT_QUEUE: a package of an origin not in the queue of the run is one of
                    # before the split (no port of it built or kept by its hash in this run)
                    if [ -n "${SPLIT_QUEUE:-}" ] && ! grep -qxF "$o" "$SPLIT_QUEUE" 2> /dev/null; then
                        echo "$o" >> "$w/sdeps.out"
                    else
                        echo "$o" >> "$w/sdeps"
                    fi ;;
            esac
        done < "$w/new.pkgs"
        if [ -s "$w/sdeps" ]; then
            fail "dependencies: $(grep -c . "$w/sdeps") packages depend on $so, the static tree, but only graphics/GraphicsMagick and graphics/libimagemagick7 are to: $(tr '\n' ' ' < "$w/sdeps")"
        else
            ok "dependencies: no other package$( [ -n "${SPLIT_QUEUE:-}" ] && echo " of the origins of the queue ($(grep -c . "$SPLIT_QUEUE" 2> /dev/null) of $SPLIT_QUEUE)") depends on $so (the static tree)"
        fi
        [ -s "$w/sdeps.out" ] && info "dependencies: $(grep -c . "$w/sdeps.out") packages of origins not in the queue of this run depend on $so (packages of before the split, not built in this run; a run of all the ports builds them again): $(tr '\n' ' ' < "$w/sdeps.out")"
        : ;;
    *) fail "the static tree: in more than one package after: $(printf '%s\n' "$so" | tr '\n' ' ')" ;;
esac

if [ "$nf" = 0 ]; then
    echo "result: OK"
    exit 0
fi
echo "result: FAIL ($nf checks failed)"
exit 1
