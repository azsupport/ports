#!/bin/sh
# compare-official.sh - compare the PHP ports of one version in this tree with the
# official ports of freebsd-ports at the base commit of that version (php-src
# freebsd/targets.conf), so that what fell between our sources shows before CI:
# our module ports take their options from ext.conf and the 7.4 rules of this
# tree, the official ones carry fixes of their own (a patch in files/, a
# post-patch in the slave's Makefile, a configure option), and a module that
# builds alone (phpize) needs every one of them that is not in our source. Two
# such misses (php83-readline: the config.m4 patch of 7.4 that makes
# --with-readline work under phpize; php83-xsl: the post-patch of the official
# slave for the include of dom) were found by CI only.
#
# What is compared, one section per port of the report (markdown, to stdout):
#   - the core lang/phpXY and www/mod_phpXY: the variables (word by word) and the
#     targets of the core part of the Makefile (the official 8.x have the rules
#     of the modules in the Makefile, 7.4 in Makefile.ext: the part of the
#     modules outside their blocks is compared as "the common part of the
#     modules"), files/, pkg-plist (ours with the paths of the version mapped
#     to the official ones: bin/php74 is bin/php, etc/php74/ is etc/ ...), the
#     other files of the port;
#   - every slave <cat>/phpXY-<module>: (a) the block of the module, every
#     `.if ${PHP_MODNAME} == "<module>"` ... its `.endif` (nested and indented
#     `.  if` forms too, one condition naming several modules too) of ours
#     against the official, as a diff of the statements (comments and layout
#     left out); (b) every variable (but CATEGORIES MASTERDIR PKGNAMESUFFIX
#     TEST_TARGET) and target of the official slave's Makefile that ours (its
#     Makefile and its block) lacks or sets otherwise; (c) files/: the patches
#     the official has and we do not, ours it does not, and those that differ;
#   - a PECL module (no official slave): its official port, <cat>/pecl-<module>
#     or what MOVED renamed it to (databases/pecl-redis is databases/php-redis
#     at the 8.x commits), graphics/pecl-imagick-im7 for imagick (ImageMagick
#     7, as ours), at the base commit, else at the base commit of the nearest
#     higher version that has it (the rule of PORTS-SPEC), else at the commit
#     our rules come from (gmagick); the report says which, or that it is
#     absent (and MOVED's line for it). Its Makefile (and its master's, for a
#     slave such as pecl-imagick-im7) is compared as (b), against our block
#     and slave, and its files/ as (c);
#   - Mk/Uses/php.mk: ours against the official of the base commit, and the
#     changes of the official file from the commit ours is based on (the head
#     of ours names it) to the base commit: what the official changed since,
#     which ours may lack; Mk/php-modules.mk: the modules of USE_PHP the
#     official php.mk knows and ours does not;
#   - the official slaves of the version we have no port for, our ports the
#     official tree has no port for.
# With SRCDIR (the release tarball of the version unpacked: its top directory)
# every patch of (c) is tried on the source, as the framework applies it (-p0
# in WRKSRC: the top for the core, ext/<module> for a module): "in the source"
# (it applies reversed: the fork carries it), "not in the source" (it applies),
# or "does not apply" either way.
#
# The official files come from a shallow, treeless clone of freebsd-ports
# (github.com) in the work directory: the trees of each commit once (about
# 9 MB), the files the report needs in one fetch; kept between runs. git is
# needed for that (raw.githubusercontent.com lists no directories, and the
# GitHub API allows 60 calls an hour without a token).
#
# Usage: sh tools/compare-official.sh <php version> [<git ref of this tree>]
#   <php version>: 5.6 7.4 8.1 8.2 8.3 8.4 (or 56 ... 84)
#   <git ref>: the commit of this tree to compare (a branch: php83); without it
#   the files of the working tree (tracked or new, not ignored).
# Environment:
#   OFFICIAL_CACHE  the work directory (default ${TMPDIR:-/tmp}/compare-official)
#   OFFICIAL_COMMIT another official commit to compare with (full sha)
#   SRCDIR          the unpacked release tarball of the version, for the patches
# Exit status: 0 the report was written (differences or not), 2 usage or setup
# error (no git, a fetch that failed).

set -u
LC_ALL=C
export LC_ALL

me=compare-official
err() { printf '%s: %s\n' "$me" "$*" >&2; }
die() { err "$*"; exit 2; }
note() { printf '%s: %s\n' "$me" "$*" >&2; }

[ $# -ge 1 ] && [ $# -le 2 ] || die "usage: sh tools/compare-official.sh <php version: 5.6 7.4 8.1 8.2 8.3 8.4> [<git ref of this tree>]"
V="$(printf '%s' "$1" | tr -d .)"
ref="${2:-}"

# The base commits of the PHP versions (php-src freebsd/targets.conf has them
# short; the full ones: azsupport ports/freebsd/README.md), in the order of the
# versions (the nearest higher version of the PORTS-SPEC rule is the next one)
VERSIONS="56 74 81 82 83 84"
base_commit() {
    case "$1" in
    56) echo d2c06ef5efae04d669797eca655404f0cba5a24b ;;
    74) echo 036685c034ba77a67fcdb0b7a18ed6ef5994d945 ;;
    81) echo 6002588334a95c9937343017fc2a80cbccc0cd5f ;;
    82) echo 438e512499a99559cf18ba9119dc3a534af3b2a4 ;;
    83) echo eb0100f974b604825fd8aee7656233586e1f3827 ;;
    84) echo 1a235373d2661c911465f1ad1f50b5f0e2a1ba42 ;;
    *) return 1 ;;
    esac
}
# Full shas of the short commits the heads of our files name (git fetches a
# commit by its full sha only)
full_commit() {
    case "$1" in
    57eddb3fa57f*) echo 57eddb3fa57f0798f57bfaeb6eff73ce64d2ec58 ;;
    *) for v in $VERSIONS; do
           c="$(base_commit "$v")"
           case "$c" in "$1"*) echo "$c"; return 0 ;; esac
       done
       return 1 ;;
    esac
}
# The PECL modules whose rules come from a port that is at none of the base
# commits: <module> <origin> <commit> (the head of our Makefile.ext says so)
PECL_ELSEWHERE="gmagick graphics/pecl-gmagick 57eddb3fa57f0798f57bfaeb6eff73ce64d2ec58"
# The official port of a PECL module when it is not <category>/pecl-<module>:
# imagick links ImageMagick 7, as pecl-imagick-im7 (a slave of pecl-imagick)
pecl_candidates() { # <category> <module>
    case "$2" in
    imagick) echo "$1/pecl-imagick-im7 $1/pecl-imagick" ;;
    *) echo "$1/pecl-$2" ;;
    esac
}

commit="$(base_commit "$V")" || die "no PHP version $1 (5.6 7.4 8.1 8.2 8.3 8.4)"
[ -n "${OFFICIAL_COMMIT:-}" ] && commit="$OFFICIAL_COMMIT"
VD="${V%?}.${V#?}"
command -v git > /dev/null 2>&1 || die "no git (the official tree is read with git)"
top="$(cd "$(dirname "$0")/.." && pwd)"
cache="${OFFICIAL_CACHE:-${TMPDIR:-/tmp}/compare-official}"
mkdir -p "$cache" || die "no work directory $cache"
cache="$(cd "$cache" && pwd)"
repo="$cache/freebsd-ports.git"
srcdir=""
if [ -n "${SRCDIR:-}" ]; then
    srcdir="$(cd "$SRCDIR" 2>/dev/null && pwd)" || die "no SRCDIR $SRCDIR"
    [ -f "$srcdir/main/php_version.h" ] || die "SRCDIR $srcdir is not a PHP source (no main/php_version.h)"
    command -v patch > /dev/null 2>&1 || die "no patch (SRCDIR is set)"
fi
tmp="$(mktemp -d "${TMPDIR:-/tmp}/$me.XXXXXX")" || die "no temporary directory"
trap 'rm -rf "$tmp"' EXIT
trap 'exit 2' INT TERM

# --- the official tree -------------------------------------------------------

if [ ! -f "$repo/HEAD" ]; then
    git init -q --bare "$repo" && git -C "$repo" remote add origin https://github.com/freebsd/freebsd-ports.git \
        || die "cannot make the clone $repo"
fi
# off_trees <commit>: the trees of <commit> in the clone (a shallow, treeless fetch once)
off_trees() {
    grep -qx "$1" "$repo/shallow" 2> /dev/null && return 0
    note "fetching the trees of freebsd-ports $1 (once, about 9 MB)"
    git -C "$repo" fetch -q --depth 1 --filter=blob:none origin "$1" \
        || die "git fetch of freebsd-ports $1 failed"
}
# off_index <commit>: the files of <commit>, "<blob> <path>" a line, in $tmp/idx.<commit>
off_index() {
    [ -f "$tmp/idx.$1" ] && return 0
    off_trees "$1"
    git -C "$repo" ls-tree -r "$1" | awk -F '\t' '{ split($1, a, " "); if (a[2] == "blob") print a[3] " " $2 }' \
        > "$tmp/idx.$1" || die "git ls-tree of $1 failed"
}
# off_ls <commit> <dir>: the files under <dir>, relative to it; status 1: none
off_ls() {
    off_index "$1"
    grep -F " $2/" "$tmp/idx.$1" | awk -v d="$2/" 'index($2, d) == 1 { print substr($2, length(d) + 1) }' | grep . || return 1
}
# off_has <commit> <path>: a file of <commit>
off_has() {
    off_index "$1"
    grep -F " $2" "$tmp/idx.$1" | awk -v p="$2" '$2 == p { f = 1; exit } END { exit !f }'
}
# off_want <commit> <dir or file>...: their blobs fetched together (one fetch)
off_want() {
    ow_c="$1"; shift
    off_index "$ow_c"
    for ow_d in "$@"; do
        awk -v d="$ow_d" '$2 == d || index($2, d "/") == 1 { print $1 }' "$tmp/idx.$ow_c"
    done | sort -u > "$tmp/want"
    touch "$cache/blobs"
    sort -u "$cache/blobs" > "$tmp/have"
    comm -23 "$tmp/want" "$tmp/have" > "$tmp/missing"
    [ -s "$tmp/missing" ] || return 0
    note "fetching $(wc -l < "$tmp/missing" | tr -d ' ') files of freebsd-ports $ow_c"
    git -C "$repo" -c fetch.negotiationAlgorithm=noop fetch -q --no-tags --no-write-fetch-head \
        --recurse-submodules=no --filter=blob:none --stdin origin < "$tmp/missing" \
        || die "git fetch of the files of $ow_c failed"
    cat "$tmp/missing" >> "$cache/blobs"
}
# off_get <commit> <path> <file>: the official file (fetched by off_want first)
off_get() {
    git -C "$repo" cat-file -p "$1:$2" > "$3" 2> /dev/null || { err "no official $2 at $1"; return 1; }
}

# --- our tree ----------------------------------------------------------------

ours="$tmp/ours"
mkdir -p "$ours"
if [ -n "$ref" ]; then
    oursha="$(git -C "$top" rev-parse -q --verify "$ref^{commit}")" || die "no commit $ref in $top"
    git -C "$top" ls-tree -r --name-only "$oursha" > "$tmp/ours.all"
    ourname="$ref ($(printf '%.12s' "$oursha"))"
else
    git -C "$top" ls-files -co --exclude-standard > "$tmp/ours.all" 2> /dev/null \
        || (cd "$top" && find . -type f ! -path './.git/*' | sed 's|^\./||') > "$tmp/ours.all"
    ourname="the working tree of $top"
fi
grep -E "^(Mk/|lang/php$V/|www/mod_php$V/|[a-z]+/php$V-[^/]+/)" "$tmp/ours.all" > "$tmp/ours.files"
while read -r p; do
    mkdir -p "$ours/${p%/*}"
    if [ -n "$ref" ]; then
        git -C "$top" show "$oursha:$p" > "$ours/$p" || die "git show $ref:$p failed"
    else
        cp "$top/$p" "$ours/$p" || die "no $top/$p"
    fi
done < "$tmp/ours.files"
[ -f "$ours/lang/php$V/Makefile" ] || die "no lang/php$V in $ourname"

# --- the awk programs --------------------------------------------------------

# norm: a Makefile as statements, one a line: no comments or blank lines,
# continuation lines joined, blanks collapsed, "NAME op value" for an
# assignment, ".if ..." for a directive (".  if", ".\tif" too), a tab before
# a line of a recipe
cat > "$tmp/norm.awk" << 'EOF'
{
    line = $0
    while (line ~ /\\$/) {
        if ((getline nxt) <= 0) break
        sub(/\\$/, "", line)
        line = line " " nxt
    }
    if (line ~ /^[ \t]*#/ || line ~ /^[ \t]*$/) next
    if (line ~ /^\t/) {
        sub(/^[ \t]+/, "", line); gsub(/[ \t]+/, " ", line); sub(/ $/, "", line)
        print "\t" line; next
    }
    gsub(/[ \t]+/, " ", line); sub(/^ /, "", line); sub(/ $/, "", line)
    if (line ~ /^\. ?[a-z]/) { sub(/^\. /, ".", line); print line; next }
    if (match(line, /^[A-Za-z0-9_.${}-]+ ?[+?:!]?=/)) {
        name = substr(line, 1, RLENGTH); val = substr(line, RLENGTH + 1)
        op = name; sub(/^[A-Za-z0-9_.${}-]+ ?/, "", op)
        sub(/ ?[+?:!]?=$/, "", name); sub(/^ /, "", val)
        print name " " op " " val; next
    }
    print line
}
EOF
# split: the statements of a Makefile tagged by where they are: "head" (outside
# `.if !defined(PKGNAMESUFFIX)`), "core" (its first branch), "modc" (its .else:
# the modules, outside their blocks), "mod:<module>" (a block of a module);
# a file without that `.if` (Makefile.ext alone) is "modc" and blocks
cat > "$tmp/split.awk" << 'EOF'
function mods(s,   out, t) {
    out = ""
    while (match(s, /PHP_MODNAME\} ?== ?"[^"]+"/)) {
        t = substr(s, RSTART, RLENGTH); sub(/^[^"]*"/, "", t); sub(/"$/, "", t)
        out = out (out == "" ? "" : " ") t
        s = substr(s, RSTART + RLENGTH)
    }
    return out
}
function emit(l,   n, i, a) {
    if (blk != "") { n = split(blk, a, " "); for (i = 1; i <= n; i++) print "mod:" a[i] "\t" l }
    else print region "\t" l
}
BEGIN { depth = 0; blk = ""; rdepth = -1; if (region == "") region = "head" }
{
    l = $0
    if (l ~ /^\.if/) {
        depth++
        if (rdepth == -1 && blk == "" && l == ".if !defined(PKGNAMESUFFIX)") { rdepth = depth; region = "core"; next }
        if (blk == "" && (m = mods(l)) != "") { blk = m; bdepth = depth }
        emit(l); next
    }
    if (l ~ /^\.el/) {
        if (rdepth == depth && blk == "" && l == ".else") { region = "modc"; next }
        if (blk != "" && depth == bdepth && l ~ /^\.elif/ && (m = mods(l)) != "") blk = m
        emit(l); next
    }
    if (l ~ /^\.endif/) {
        if (rdepth == depth && blk == "") { region = "head"; rdepth = -2; depth--; next }
        emit(l)
        if (blk != "" && depth == bdepth) blk = ""
        depth--; next
    }
    emit(l)
}
EOF
# cmpvars: the statements of the official (first file) against ours (second
# file): the variables word by word and the targets with their recipes, as
# markdown items. -v ign="A B": names left out; -v both=1: what only ours has
# too; -v oname=, uname=: what to call the two
cat > "$tmp/cmpvars.awk" << 'EOF'
# the value as make would have it (an "=" replaces what was there, "?=" sets
# only the unset; the branches of an .if all taken)
function addv(s, name, op, val,   n, i, w, k) {
    k = s SUBSEP name
    if (!(k in seen)) { seen[k] = 1; order[s, ++nv[s]] = name }
    else if (op == "?=") return
    if (op == "=" || op == ":=") {
        n = split(wo[k], w, " "); for (i = 1; i <= n; i++) delete wd[s, name, w[i]]
        wo[k] = ""; st[k] = ""
    }
    st[k] = st[k] (st[k] == "" ? "" : " / ") name " " op " " val
    n = split(val, w, " ")
    for (i = 1; i <= n; i++) if (!((s, name, w[i]) in wd)) { wd[s, name, w[i]] = 1; wo[k] = wo[k] " " w[i] }
}
BEGIN { n = split(ign, a, " "); for (i = 1; i <= n; i++) skip[a[i]] = 1 }
FNR == 1 { s = (s == "" ? "o" : "u"); tgt = "" }
/^\t/ { if (tgt != "") rc[s, tgt] = rc[s, tgt] (rc[s, tgt] == "" ? "" : "\n") substr($0, 2); next }
# a directive in a recipe is part of it (a .if of the version, say); the
# .endif that closes the block around the target is dropped when printed
/^\./ { if (tgt != "" && $0 ~ /^\.(if|el|endif|for|endfor)/) rc[s, tgt] = rc[s, tgt] (rc[s, tgt] == "" ? "" : "\n") $0; else tgt = ""; next }
{
    if (match($0, /^[^ ]+ [+?:!]?= /) || match($0, /^[^ ]+ [+?:!]?=$/)) {
        tgt = ""
        name = $1; op = $2; val = substr($0, length($1) + length($2) + 3)
        addv(s, name, op, val); next
    }
    if (match($0, /^[^ ]+:/)) {
        t = substr($0, 1, RLENGTH - 1)
        if (!((s, t) in tseen)) { tseen[s, t] = 1; torder[s, ++nt[s]] = t }
        tl[s, t] = $0; tgt = t
        next
    }
    tgt = ""
}
# prt: a target and its recipe, as a fenced block of the item; the
# directives that do not open or close within the recipe left out
function cl(k, t,   n, j, r, d, keep, l, out) {
    n = split(rc[k, t], r, "\n"); d = 0; out = ""
    for (j = 1; j <= n; j++) {
        l = r[j]; keep = 1
        if (l ~ /^\.(if|for)/) d++
        else if (l ~ /^\.(endif|endfor)/) { if (d > 0) d--; else keep = 0 }
        else if (l ~ /^\.el/ && d == 0) keep = 0
        if (keep) out = out (out == "" ? "" : "\n") "  " (l ~ /^\./ ? "" : "\t") l
    }
    return out
}
function prt(k, t,   c) {
    print "  ```"; print "  " tl[k, t]
    c = cl(k, t); if (c != "") print c
    print "  ```"
}
function words(k, other, s2,   n, i, w, out) {
    out = ""
    n = split(wo[k], w, " ")
    for (i = 1; i <= n; i++) if (!((s2, other, w[i]) in wd)) out = out " " w[i]
    return substr(out, 2)
}
END {
    for (i = 1; i <= nv["o"]; i++) {
        name = order["o", i]
        if (name in skip) continue
        if (!(("u", name) in seen)) { print "- `" name "`: " oname " `" st["o" SUBSEP name] "`, " uname " has none"; continue }
        miss = words("o" SUBSEP name, name, "u"); extra = words("u" SUBSEP name, name, "o")
        if (miss != "" || extra != "") {
            line = "- `" name "`:"
            if (miss != "") line = line " " oname " has `" miss "`"
            if (miss != "" && extra != "") line = line ";"
            if (extra != "") line = line " " uname " has `" extra "`"
            print line
        }
    }
    if (both) for (i = 1; i <= nv["u"]; i++) {
        name = order["u", i]
        if (name in skip || ("o", name) in seen) continue
        print "- `" name "`: " uname " only, `" st["u" SUBSEP name] "`"
    }
    for (i = 1; i <= nt["o"]; i++) {
        t = torder["o", i]
        if (!(("u", t) in tseen)) {
            print "- target `" t ":`: " oname " has it, " uname " not:"
            prt("o", t)
        } else if (cl("o", t) != cl("u", t) || tl["o", t] != tl["u", t]) {
            print "- target `" t ":` differs; " oname ":"
            prt("o", t)
            print "  " uname ":"
            prt("u", t)
        }
    }
    if (both) for (i = 1; i <= nt["u"]; i++) {
        t = torder["u", i]
        if (!(("o", t) in tseen)) print "- target `" t ":`: " uname " only"
    }
}
EOF

norm() { awk -f "$tmp/norm.awk" "$@"; }
# whole <port dir> <out>: the normalized Makefile, Makefile.ext inlined where it is included
whole() {
    norm "$1/Makefile" > "$tmp/w.mk"
    if [ -f "$1/Makefile.ext" ]; then
        norm "$1/Makefile.ext" > "$tmp/w.ext"
        awk -v ext="$tmp/w.ext" '$0 == ".include \"${MASTERDIR}/Makefile.ext\"" { while ((getline l < ext) > 0) print l; next } { print }' \
            "$tmp/w.mk" > "$2"
    else
        cp "$tmp/w.mk" "$2"
    fi
}
part() { awk -F '\t' -v t="$1" '$1 == t { print substr($0, length(t) + 2) }' "$2"; }

# udiff <official> <ours>: a unified diff without its header, or nothing
udiff() { diff -u "$1" "$2" | sed '1,2d'; }
fence() { printf '%s\n' '```diff'; cat; printf '%s\n' '```'; }
details() { printf '<details><summary>%s</summary>\n\n' "$1"; fence; printf '\n</details>\n'; }

# patch_state <patch> <dir>: what the patch is to the source in <dir>
patch_state() {
    [ -n "$srcdir" ] || return 0
    if [ ! -d "$2" ]; then printf ' (no %s in SRCDIR)' "${2#"$srcdir"/}"; return 0; fi
    if patch -p0 -R -f -s --dry-run -d "$2" < "$1" > /dev/null 2>&1; then printf ' (in the source)'
    elif patch -p0 --forward -f -s --dry-run -d "$2" < "$1" > /dev/null 2>&1; then printf ' (**not in the source**: it applies)'
    else printf ' (**does not apply** to the source, either way)'
    fi
}
# files_cmp <official port dir> <our port dir> <source dir>: files/ compared
files_cmp() {
    fc_o="$1"; fc_u="$2"; fc_s="$3"
    off_ls "$commit_of_files" "$fc_o/files" > "$tmp/fo" 2> /dev/null || : > "$tmp/fo"
    (cd "$ours/$fc_u/files" 2> /dev/null && find . -type f | sed 's|^\./||' | sort) > "$tmp/fu" || : > "$tmp/fu"
    sort -o "$tmp/fo" "$tmp/fo"
    comm -23 "$tmp/fo" "$tmp/fu" | while read -r f; do
        off_get "$commit_of_files" "$fc_o/files/$f" "$tmp/pf" || continue
        case "$f" in patch-*) st="$(patch_state "$tmp/pf" "$fc_s")" ;; *) st="" ;; esac
        printf -- '- files/%s: the official has it, we do not%s\n' "$f" "$st"
    done
    comm -13 "$tmp/fo" "$tmp/fu" | while read -r f; do
        case "$f" in patch-*) st="$(patch_state "$ours/$fc_u/files/$f" "$fc_s")" ;; *) st="" ;; esac
        printf -- '- files/%s: ours only%s\n' "$f" "$st"
    done
    comm -12 "$tmp/fo" "$tmp/fu" | while read -r f; do
        off_get "$commit_of_files" "$fc_o/files/$f" "$tmp/pf" || continue
        if ! cmp -s "$tmp/pf" "$ours/$fc_u/files/$f"; then
            case "$f" in patch-*) st="$(patch_state "$ours/$fc_u/files/$f" "$fc_s")" ;; *) st="" ;; esac
            printf -- '- files/%s: differs%s\n' "$f" "$st"
            diff -u "$tmp/pf" "$ours/$fc_u/files/$f" | sed '1,2d' | details "files/$f: official -> ours"
        fi
    done
}
# plist_norm <file>: our pkg-plist with the paths of the version as the official ones
plist_norm() {
    sed -E -e "s#(^|[@ %])etc/php$V/#\\1etc/#g" -e "s#include/php$V/#include/#g" -e "s#lib/php$V/#lib/php/#g" \
        -e "s#share/php$V/#share/php/#g" -e "s#php$V#php#g" -e "s#(-cgi|-config|phpdbg|phpize|-fpm|php-profile)$V#\\1#g" \
        -e "s#(php[-_a-z]*)$V([.]|\$)#\\1\\2#g" "$1"
}

# --- the report --------------------------------------------------------------

out() { printf '%s\n' "$*"; }
ndiff=0
same() { out "$1: same"; out; }

off_trees "$commit"
off_index "$commit"
cshort="$(printf '%.12s' "$commit")"
out "# PHP $VD: our ports against the official ones"
out
out "Ours: $ourname. Official: freebsd-ports [$cshort](https://github.com/freebsd/freebsd-ports/tree/$commit), the base commit of PHP $VD."
if [ -n "$srcdir" ]; then out "Patches tried on the source $srcdir (-p0, in WRKSRC)."; else out "Patches not tried on a source (no SRCDIR)."; fi
out
out "Generated by tools/compare-official.sh. Lines: \"the official\" is freebsd-ports, \"ours\" this tree; a diff goes from the official to ours."
out

# our ports of the version and their official counterparts
sed -n "s#^\([a-z]*/php$V-[^/]*\)/Makefile\$#\\1#p" "$tmp/ours.files" | sort -u > "$tmp/slaves"
awk '{ print $2 }' "$tmp/idx.$commit" | sed -n "s#^\([a-z]*/php$V-[^/]*\)/Makefile\$#\\1#p" | sort -u > "$tmp/offslaves"
note "fetching what the report needs"
off_want "$commit" "lang/php$V" "www/mod_php$V" Mk/Uses/php.mk MOVED $(cat "$tmp/offslaves")
commit_of_files="$commit"

# - the core
out "## lang/php$V (the core)"
out
whole "$ours/lang/php$V" "$tmp/u.whole"
awk -v region=head -f "$tmp/split.awk" "$tmp/u.whole" > "$tmp/u.split"
mkdir -p "$tmp/o/lang/php$V"
off_ls "$commit" "lang/php$V" | grep -v '^files/' > "$tmp/ocore" || : > "$tmp/ocore"
while read -r f; do off_get "$commit" "lang/php$V/$f" "$tmp/o/lang/php$V/$f"; done < "$tmp/ocore"
whole "$tmp/o/lang/php$V" "$tmp/o.whole"
awk -v region=head -f "$tmp/split.awk" "$tmp/o.whole" > "$tmp/o.split"
{ part head "$tmp/o.split"; part core "$tmp/o.split"; } > "$tmp/o.core"
{ part head "$tmp/u.split"; part core "$tmp/u.split"; } > "$tmp/u.core"
out "### Makefile: the core part (outside \`.if !defined(PKGNAMESUFFIX)\` and its first branch)"
out
awk -v oname="the official" -v uname="ours" -v both=1 -f "$tmp/cmpvars.awk" "$tmp/o.core" "$tmp/u.core" > "$tmp/r"
if [ -s "$tmp/r" ]; then cat "$tmp/r"; out; udiff "$tmp/o.core" "$tmp/u.core" | details "the statements of the core part: official -> ours"; else out "same"; fi
out
out "### Makefile: the common part of the modules (the .else of \`.if !defined(PKGNAMESUFFIX)\`, outside the blocks of the modules)"
out
part modc "$tmp/o.split" > "$tmp/o.modc"; part modc "$tmp/u.split" > "$tmp/u.modc"
awk -v oname="the official" -v uname="ours" -v both=1 -f "$tmp/cmpvars.awk" "$tmp/o.modc" "$tmp/u.modc" > "$tmp/r"
if [ -s "$tmp/r" ]; then cat "$tmp/r"; out; udiff "$tmp/o.modc" "$tmp/u.modc" | details "the statements of the common part of the modules: official -> ours"; else out "same"; fi
out
out "### files/"
out
files_cmp "lang/php$V" "lang/php$V" "$srcdir" > "$tmp/r"
if [ -s "$tmp/r" ]; then cat "$tmp/r"; else out "same"; fi
out
out "### the other files of the port"
out
(cd "$ours/lang/php$V" && find . -type f ! -path './files/*' | sed 's|^\./||' | sort) > "$tmp/ucore"
sort -o "$tmp/ocore" "$tmp/ocore"
comm -23 "$tmp/ocore" "$tmp/ucore" | while read -r f; do out "- $f: the official has it, we do not"; done
comm -13 "$tmp/ocore" "$tmp/ucore" | grep -v '^Makefile.ext$' | while read -r f; do out "- $f: ours only"; done
comm -12 "$tmp/ocore" "$tmp/ucore" | grep -v -e '^Makefile$' -e '^Makefile.ext$' | while read -r f; do
    case "$f" in
    pkg-plist*)
        plist_norm "$ours/lang/php$V/$f" | sort -u > "$tmp/pu"; sort -u "$tmp/o/lang/php$V/$f" > "$tmp/po"
        if cmp -s "$tmp/po" "$tmp/pu"; then out "- $f: same (with the paths of the version as the official ones)"; continue; fi
        out "- $f (ours with the paths of the version as the official ones):"
        comm -23 "$tmp/po" "$tmp/pu" | sed 's/^/  - the official only: `/; s/$/`/'
        comm -13 "$tmp/po" "$tmp/pu" | sed 's/^/  - ours only: `/; s/$/`/'
        ;;
    *)
        if cmp -s "$tmp/o/lang/php$V/$f" "$ours/lang/php$V/$f"; then out "- $f: same"; continue; fi
        out "- $f: differs"; out
        udiff "$tmp/o/lang/php$V/$f" "$ours/lang/php$V/$f" | details "$f: official -> ours"
        ;;
    esac
done
out

# - mod_php
out "## www/mod_php$V"
out
if off_has "$commit" "www/mod_php$V/Makefile"; then
    off_get "$commit" "www/mod_php$V/Makefile" "$tmp/omod"
    norm "$tmp/omod" > "$tmp/omod.n"; norm "$ours/www/mod_php$V/Makefile" > "$tmp/umod.n"
    awk -v oname="the official" -v uname="ours" -v both=1 -f "$tmp/cmpvars.awk" "$tmp/omod.n" "$tmp/umod.n" > "$tmp/r"
    files_cmp "www/mod_php$V" "www/mod_php$V" "$srcdir" >> "$tmp/r"
    if [ -s "$tmp/r" ]; then cat "$tmp/r"; out; udiff "$tmp/omod.n" "$tmp/umod.n" | details "Makefile: official -> ours"; else out "same"; fi
else
    out "no official www/mod_php$V"
fi
out

# - Mk
out "## Mk/Uses/php.mk"
out
off_get "$commit" Mk/Uses/php.mk "$tmp/ophp.mk"
norm "$tmp/ophp.mk" > "$tmp/ophp.n"; norm "$ours/Mk/Uses/php.mk" > "$tmp/uphp.n"
obase="$(sed -n 's/.*freebsd-ports \([0-9a-f]\{12,40\}\).*/\1/p' "$ours/Mk/Uses/php.mk" | head -n 1)"
if cmp -s "$tmp/ophp.n" "$tmp/uphp.n"; then out "same"; else
    out "Ours against the official of $cshort:"
    out
    udiff "$tmp/ophp.n" "$tmp/uphp.n" | details "Mk/Uses/php.mk: official $cshort -> ours (statements)"
    if [ -n "$obase" ] && fb="$(full_commit "$obase")" && [ "$fb" != "$commit" ]; then
        off_want "$fb" Mk/Uses/php.mk
        off_get "$fb" Mk/Uses/php.mk "$tmp/bphp.mk"
        norm "$tmp/bphp.mk" > "$tmp/bphp.n"
        out
        if cmp -s "$tmp/bphp.n" "$tmp/ophp.n"; then
            out "The official file is the same at $obase (the base of ours) and at $cshort."
        else
            out "What the official changed from $obase (the base of ours, its head says) to $cshort: each a change ours may lack:"
            out
            udiff "$tmp/bphp.n" "$tmp/ophp.n" | fence
        fi
    fi
fi
out
if [ -f "$ours/Mk/php-modules.mk" ]; then
    out "## Mk/php-modules.mk (ours: the modules of USE_PHP)"
    out
    awk -v v="$V" '$1 == "_USE_PHP_ALL" || $1 == "_USE_PHP_VER" v { for (i = 3; i <= NF; i++) if ($i != "${_USE_PHP_ALL}") print $i }' \
        "$tmp/ophp.n" | sort -u > "$tmp/omods"
    sed -n 's/^\([a-z_0-9]*\)_DEPENDS[+?]*=.*/\1/p' "$ours/Mk/php-modules.mk" | sort -u > "$tmp/umods"
    if [ -s "$tmp/omods" ]; then
        m="$(comm -23 "$tmp/omods" "$tmp/umods" | tr '\n' ' ' | sed 's/ $//')"
        if [ -n "$m" ]; then out "- the official php.mk knows these modules of USE_PHP, ours does not: $m"; else out "- every module of USE_PHP of the official php.mk is in ours"; fi
    else
        out "- no _USE_PHP_ALL in the official php.mk: not compared"
    fi
    out
fi

# - the modules
out "## The modules"
out
for o in $(cat "$tmp/slaves"); do
    port="${o#*/php$V-}"
    mod="$port"; [ "$port" = openssl-legacy ] && mod=openssl
    norm "$ours/$o/Makefile" > "$tmp/us.n"
    part "mod:$mod" "$tmp/u.split" > "$tmp/ub.n"
    if grep -qx "$o" "$tmp/offslaves"; then
        : > "$tmp/r"
        part "mod:$mod" "$tmp/o.split" > "$tmp/ob.n"
        off_get "$commit" "$o/Makefile" "$tmp/os"
        norm "$tmp/os" > "$tmp/os.n"
        # a line of a block that the other side has in the slave's Makefile is
        # not missing: it moved (said at the line)
        if ! cmp -s "$tmp/ob.n" "$tmp/ub.n"; then
            { out "- the block of $mod (official -> ours):"
              udiff "$tmp/ob.n" "$tmp/ub.n" | awk -v us="$tmp/us.n" -v os="$tmp/os.n" '
                BEGIN { while ((getline l < us) > 0) u[l] = 1; while ((getline l < os) > 0) o[l] = 1 }
                /^-/ && (substr($0, 2) in u) { print $0 "    <- in our slave Makefile"; next }
                /^\+/ && (substr($0, 2) in o) { print $0 "    <- in the official slave Makefile"; next }
                { print }' | fence; } >> "$tmp/r"
        fi
        cat "$tmp/us.n" "$tmp/ub.n" > "$tmp/uall.n"
        awk -v oname="the official slave" -v uname="ours (slave and block)" \
            -v ign="CATEGORIES MASTERDIR PKGNAMESUFFIX TEST_TARGET" -f "$tmp/cmpvars.awk" "$tmp/os.n" "$tmp/uall.n" >> "$tmp/r"
        files_cmp "$o" "$o" "$srcdir${srcdir:+/ext/$mod}" >> "$tmp/r"
        if [ -s "$tmp/r" ]; then out "### $o"; out; cat "$tmp/r"; out; else same "### $o"; fi
        continue
    fi
    # no official slave: a PECL module or ours
    cat="${o%%/*}"
    found=""; where=""
    vs=""; past=""
    for v in $VERSIONS; do [ "$v" = "$V" ] && past=1; [ -n "$past" ] && vs="$vs $v"; done
    for v in $vs; do
        c="$(base_commit "$v")"; [ "$v" = "$V" ] && c="$commit"
        off_index "$c"
        for cand in $(pecl_candidates "$cat" "$mod"); do
            p="$cand"; hops=0
            while [ -n "$p" ] && [ $hops -lt 5 ]; do
                if off_has "$c" "$p/Makefile"; then found="$p"; where="$c"; break 3; fi
                off_want "$c" MOVED
                off_get "$c" MOVED "$tmp/moved" || break
                nx="$(awk -F '|' -v p="$p" '$1 == p { n = $2 } END { print n }' "$tmp/moved")"
                [ "$nx" = "$p" ] && break
                p="$nx"; hops=$((hops + 1))
            done
        done
    done
    if [ -z "$found" ]; then
        set -- $PECL_ELSEWHERE
        while [ $# -ge 3 ]; do
            if [ "$1" = "$mod" ]; then off_trees "$3"; off_index "$3"; off_has "$3" "$2/Makefile" && { found="$2"; where="$3"; }; fi
            shift 3
        done
    fi
    out "### $o"
    out
    if [ -z "$found" ]; then
        mv="$(awk -F '|' -v p="$cat/pecl-$mod" '$1 == p { print "MOVED at " c ": " $0 }' c="$cshort" "$tmp/moved" 2> /dev/null)"
        out "- no official port: no slave $o, no $(pecl_candidates "$cat" "$mod" | sed 's/ / or /g') at the base commit or later ones${mv:+; $mv}: ours"
        out
        continue
    fi
    wshort="$(printf '%.12s' "$where")"
    wv=""; for v in $VERSIONS; do [ "$(base_commit "$v")" = "$where" ] && wv="$v"; done
    if [ "$where" = "$commit" ]; then out "- official: $found at the base commit"
    elif [ -n "$wv" ]; then out "- official: $found at $wshort, the base commit of PHP ${wv%?}.${wv#?} (none at the base commit)"
    else out "- official: $found at $wshort (the commit our rules come from: at none of the base commits)"
    fi
    off_want "$where" "$found"
    off_get "$where" "$found/Makefile" "$tmp/op"
    norm "$tmp/op" > "$tmp/op.n"
    mdir="$(sed -n 's#^MASTERDIR ?= \${.CURDIR}/\.\./\(.*\)$#\1#p; s#^MASTERDIR = \${.CURDIR}/\.\./\(.*\)$#\1#p' "$tmp/op.n" | head -n 1)"
    if [ -n "$mdir" ]; then
        case "$mdir" in ../*) mo="${mdir#../}" ;; *) mo="${found%%/*}/$mdir" ;; esac
        out "- $found is a slave of $mo: compared with both (its Makefile first)"
        off_want "$where" "$mo"
        off_get "$where" "$mo/Makefile" "$tmp/opm"
        norm "$tmp/opm" >> "$tmp/op.n"
    fi
    ov="$(sed -n -E 's/^(DISTVERSION|PORTVERSION) [?]?= //p' "$tmp/op.n" | head -n 1)"
    uv="$(sed -n -E 's/^DISTVERSION [?]?= //p' "$tmp/us.n" | head -n 1)"
    out "- version: the official $ov, ours $uv"
    cat "$tmp/us.n" "$tmp/u.modc" "$tmp/ub.n" > "$tmp/uall.n"
    awk -v oname="the official" -v uname="ours (slave, block, common part)" \
        -v ign="PORTNAME DISTVERSION PORTVERSION DISTVERSIONPREFIX DISTVERSIONSUFFIX PORTREVISION PORTEPOCH CATEGORIES MASTERDIR PKGNAMESUFFIX PKGNAMEPREFIX MAINTAINER TEST_TARGET" \
        -f "$tmp/cmpvars.awk" "$tmp/op.n" "$tmp/uall.n"
    commit_of_files="$where"
    files_cmp "$found" "$o" "$srcdir${srcdir:+/ext/$mod}"
    [ -n "$mdir" ] && files_cmp "$mo" "$o" "$srcdir${srcdir:+/ext/$mod}" | grep -v ': ours only'
    commit_of_files="$commit"
    out
    cat "$tmp/us.n" "$tmp/ub.n" > "$tmp/uall.n"
    udiff "$tmp/op.n" "$tmp/uall.n" | details "$found (Makefile) -> ours (slave and block)"
    out
done

# - the official modules we have no port for, and the blocks of modules without a port
out "## The official slaves of PHP $VD we have no port for"
out
m="$(comm -23 "$tmp/offslaves" "$tmp/slaves" | tr '\n' ' ' | sed 's/ $//')"
if [ -n "$m" ]; then out "$m"; else out "none"; fi
out
