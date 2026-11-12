#!/bin/sh
# ytdlp-update.sh - www/yt-dlp at the latest release of github.com/yt-dlp/yt-dlp, and
# what must move with it (aZ, 12.11.2026: «yt-dl кстати надо подхватывать свежие
# релизы из гитхаба, а не сидеть на том что в порте»): the exception for yt-dlp to the
# rule of this tree, the versions of the official ports tree. The workflow
# yt-dlp-update.yml runs it on main every 6 hours:
#
# 1. The latest release of yt-dlp/yt-dlp (releases/latest of the API of GitHub: not a
#    draft, not a pre-release; the nightly and master builds are the releases of other
#    repositories) against DISTVERSION of www/yt-dlp.
# 2. A newer one: its yt-dlp.tar.gz, the distfile of the port, with the SHA-256 the API
#    gives for it and the one of the SHA2-256SUMS of the release (both there agree; one
#    of them at least); the patches of the port applied to it as the ports framework
#    applies them (patch -p0 -E --forward, in order) without fuzz: one that applies only
#    with fuzz is made again from the result, as make makepatch makes it (diff -audp,
#    the date of the original in UTC); one that does not apply stops the update (no
#    commit; the report shows why). DISTVERSION and distinfo (TIMESTAMP, SHA256, SIZE).
# 3. yt-dlp-ejs: the version the release pins (yt-dlp-ejs==<version> of its
#    pyproject.toml, the same as EJS_VERSION of its Makefile and VERSION of
#    yt_dlp/extractor/youtube/jsc/_builtin/vendor/_info.py: yt-dlp takes the scripts of
#    yt-dlp-ejs only of that major.minor and with the SHA3-512 of that release) against
#    www/py-yt-dlp-ejs, ours when this tree has it, else the official port at the
#    commit pinned in tools/build.sh. A newer pin: ours made from tools/ytdlp-ejs/ (the
#    wheel of the release of github.com/yt-dlp/ejs, whose SHA-256 yt-dlp pins as
#    EJS_WHEEL_HASH of its Makefile) or ours updated, DISTVERSION and distinfo. The
#    oldest deno yt-dlp runs (DenoJsRuntime of yt_dlp/utils/_jsruntime.py) against the
#    official www/deno: a warning when that is older (deno stays the official package).
# 4. The ports checked with make -V (tools/check-tree-ci.sh), then one commit of aZ and
#    a push to main (a refused push: again on top of the new main, 5 times).
# 5. The build, when the releases az-fbsd<major>-amd64-v3 and -v2 do not have the
#    yt-dlp of the tree (and its yt-dlp-ejs, when that is ours): build.yml of main for
#    www/yt-dlp, both levels, publish with publish_only (the release takes the new
#    packages only when nothing else of the repository of the run differs from it;
#    else they go out with the next publish of aZ: the cache of the run keeps them).
#    Not while a run of build.yml of main is queued or running (a new run in its
#    concurrency group would cancel a pending one; the next check starts it), not again
#    after a run it started for the same commit of the ports runs or succeeded, nor
#    after 3 of them failed.
#
# Usage: sh tools/ytdlp-update.sh [--dry-run] [--pretend <version>] [--pretend-ejs <version>]
#   --dry-run          the update with its checks, the diff of its commit and the build
#                      it would start: nothing pushed or started
#   --pretend <v>      a test, with --dry-run: www/yt-dlp taken as at <v> (DISTVERSION
#                      and the paths of distinfo set to <v> first, in this checkout
#                      only), so that the latest release is an update
#   --pretend-ejs <v>  a test, with --dry-run: the official www/py-yt-dlp-ejs taken as
#                      at <v>, so that ours is made
# Outside a run of main (GITHUB_REF) it is always a dry run. For a Linux runner of
# GitHub (GNU patch, diff and sort, gh, curl).
# Environment: GH_TOKEN (gh, the API of GitHub), GITHUB_REPOSITORY, GITHUB_REF,
#   GITHUB_OUTPUT (changed: a commit pushed to main; notable: something to report),
#   GITHUB_STEP_SUMMARY, GITHUB_SERVER_URL, GITHUB_RUN_ID; REPORT, the report
#   (markdown; default ytdlp-update.md of the tree);
#   YTDLP_TAG, a release to take in the place of the latest (a test where the API
#   cannot read yt-dlp/yt-dlp: the SHA2-256SUMS of the release alone then);
#   CHECK_TREE, the command that checks the tree in the place of tools/check-tree-ci.sh
#   (a test).
# Exit status: 0 done (an update, or nothing to do), 1 a failure (in the report), 2 a
# wrong call.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
cd "$top" || exit 2
usage() { sed -n '/^# Usage/,/^# Outside/s/^# \{0,1\}//p' "$0" >&2; exit 2; }
dry=0; pretend=""; pretend_ejs=""
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) dry=1; shift ;;
        --pretend) [ $# -ge 2 ] || usage; pretend="$2"; shift 2 ;;
        --pretend-ejs) [ $# -ge 2 ] || usage; pretend_ejs="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "ytdlp-update: unknown argument $1" >&2; usage ;;
    esac
done
if [ -n "$pretend$pretend_ejs" ] && [ "$dry" = 0 ]; then
    echo "ytdlp-update: --pretend and --pretend-ejs only with --dry-run" >&2
    exit 2
fi
repo="${GITHUB_REPOSITORY:-azsupport/ports}"
runurl="${GITHUB_SERVER_URL:-https://github.com}/$repo/actions/runs/${GITHUB_RUN_ID:-0}"
mainnote=""
if [ "${GITHUB_REF:-}" != refs/heads/main ] && [ "$dry" = 0 ]; then
    dry=1
    mainnote=" (not a run of main: ${GITHUB_REF:-no GITHUB_REF})"
fi
rep="${REPORT:-$top/ytdlp-update.md}"
w="$(mktemp -d "${TMPDIR:-/tmp}/ytdlp-update.XXXXXX")" || exit 2
trap 'rm -rf "$w"' EXIT
mkdir -p "$w/dl" "$w/src"
: > "$rep"
# the commits of the workflow are aZ's, as those of sync.sh of azsupport/php-src
GIT_AUTHOR_NAME=aZ; GIT_AUTHOR_EMAIL=github@azsupport.com
GIT_COMMITTER_NAME=aZ; GIT_COMMITTER_EMAIL=github@azsupport.com
export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
start="$(git rev-parse HEAD)" || exit 2
# it commits (and a dry run resets the checkout to where it was): no changes of others
git diff --quiet HEAD -- || { echo "ytdlp-update: the checkout has changes not committed (git status)" >&2; exit 2; }
# changed: a commit pushed to main (the output of the step); committed: one made here
changed=0; committed=0; notable=0

say() { printf '[ytdlp-update] %s\n' "$*"; }
line() { printf '%s\n' "$*" >> "$rep"; }
finish() {
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        { echo "changed=$changed"; echo "notable=$notable"; } >> "$GITHUB_OUTPUT"
    fi
    [ -n "${GITHUB_STEP_SUMMARY:-}" ] && cat "$rep" >> "$GITHUB_STEP_SUMMARY"
    echo; cat "$rep"
    [ "$dry" = 1 ] && git reset -q --hard "$start"
    exit "$1"
}
fail() {
    line ""; line "**FAIL**: $*"
    echo "::error title=yt-dlp update::$*"
    notable=1
    finish 1
}
warn() {
    line "- **warning**: $*"
    echo "::warning title=yt-dlp update::$*"
    notable=1
}
# newer <a> <b>: version a is newer than b
newer() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ]; }
# mkvar <Makefile> <variable>: its value as written
mkvar() { sed -n "s/^$2=[[:space:]]*//p" "$1" | head -n 1; }
# setvar <Makefile> <variable> <value>
setvar() { sed "s/^\($2=[[:space:]]*\).*/\1$3/" "$1" > "$w/setvar" && cat "$w/setvar" > "$1"; }
sha256f() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum < "$1" | cut -c1-64; else sha256 -q "$1"; fi
}
re() { printf '%s' "$1" | sed 's/[.]/\\./g'; }
dl() {
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 10 -o "$2" "$1" 2> "$w/curl.err" ||
        fail "$1 not fetched: $(tail -n 1 "$w/curl.err")"
}
# offv <origin>: DISTVERSION of the official port at the pinned commit
offv() {
    curl -fsSL --retry 3 "https://raw.githubusercontent.com/freebsd/freebsd-ports/$commit/$1/Makefile" > "$w/off.mk" 2> /dev/null &&
        mkvar "$w/off.mk" DISTVERSION
}

[ -f www/yt-dlp/Makefile ] || fail "no www/yt-dlp in this tree"
commit="$(sed -n 's/^ports_commit="\([0-9a-f]*\)".*/\1/p' tools/build.sh)"
[ -n "$commit" ] || fail "no ports_commit in tools/build.sh"
# the FreeBSD release of the builds: the default of build.yml
release="$(awk '/^      release:$/ { r = 1 } r && /^ *default:/ { gsub(/[^0-9.]/, "", $2); print $2; exit }' .github/workflows/build.yml)"
case "$release" in [0-9]*.[0-9]*) ;; *) fail "no default release in .github/workflows/build.yml" ;; esac
line "## yt-dlp at the latest release of GitHub"
line ""
[ "$dry" = 1 ] && line "Dry run$mainnote: nothing pushed or started."
[ "$dry" = 1 ] && line ""

# --- 1. the port and the latest release ---------------------------------------------------
cur="$(mkvar www/yt-dlp/Makefile DISTVERSION)"
[ -n "$cur" ] || fail "no DISTVERSION in www/yt-dlp/Makefile"
if [ -n "$pretend" ]; then
    setvar www/yt-dlp/Makefile DISTVERSION "$pretend"
    sed "s#(yt-dlp/$cur/#(yt-dlp/$pretend/#" www/yt-dlp/distinfo > "$w/di" && cat "$w/di" > www/yt-dlp/distinfo
    git commit -q -m "pretend: www/yt-dlp at $pretend (a test, never pushed)" -- www/yt-dlp || fail "the commit of --pretend failed"
    line "- pretend: www/yt-dlp taken as at $pretend (it is at $cur)"
    cur="$pretend"
fi
if [ -n "${YTDLP_TAG:-}" ]; then
    tag="$YTDLP_TAG"; draft=false; pre=false; published="?"; digest=""; hasasset=1
    line "- the release: $tag (YTDLP_TAG, not the API: the SHA2-256SUMS of the release alone)"
else
    gh api repos/yt-dlp/yt-dlp/releases/latest --jq '[.tag_name, (.draft | tostring), (.prerelease | tostring), (.published_at // ""),
        (([.assets[] | select(.name == "yt-dlp.tar.gz") | (.digest // "") + "|1"]) + ["|0"])[0]] | join("|")' \
        > "$w/rel" 2> "$w/err" || fail "the latest release of yt-dlp/yt-dlp: the API of GitHub failed ($(tail -n 1 "$w/err"))"
    IFS='|' read -r tag draft pre published digest hasasset < "$w/rel"
fi
case "$tag" in
    [0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9] | [0-9][0-9][0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9]*) ;;
    *) fail "the latest release of yt-dlp/yt-dlp has the tag \"$tag\", not a version (YYYY.MM.DD)" ;;
esac
[ "$draft" = false ] && [ "$pre" = false ] || fail "the latest release $tag is a draft or a pre-release (draft $draft, prerelease $pre)"
say "www/yt-dlp: $cur; the latest release: $tag ($published)"

# --- 5. the build (also when nothing is new: one that could not start before) --------------
# build_check: whether build.yml of main has to build the yt-dlp of the tree, and start it
build_check() {
    only="www/yt-dlp"
    [ -f www/py-yt-dlp-ejs/Makefile ] && only="$only www/py-yt-dlp-ejs"
    v="$(mkvar www/yt-dlp/Makefile DISTVERSION)"
    ev=""; [ -f www/py-yt-dlp-ejs/Makefile ] && ev="$(mkvar www/py-yt-dlp-ejs/Makefile DISTVERSION)"
    major="${release%%.*}"
    if [ "$committed" = 0 ]; then
        miss=""
        for lv in v3 v2; do
            t="az-fbsd$major-amd64-$lv"
            if ! gh api "repos/$repo/releases/tags/$t" --jq '.assets[].name' > "$w/assets" 2> "$w/err"; then
                if grep -q 'HTTP 404' "$w/err"; then
                    line "- the build: no release $t yet (its first publish is aZ's): no build"
                    return 0
                fi
                warn "the files of the release $t: the API failed ($(tail -n 1 "$w/err")): no build now"
                return 0
            fi
            grep -q -E "^yt-dlp-$(re "$v")(_[0-9]+)?\.pkg\$" "$w/assets" || miss="$miss yt-dlp-$v ($t)"
            if [ -n "$ev" ]; then
                grep -q -E "^py[0-9]+-yt-dlp-ejs-$(re "$ev")(_[0-9]+)?\.pkg\$" "$w/assets" || miss="$miss yt-dlp-ejs-$ev ($t)"
            fi
        done
        if [ -z "$miss" ]; then
            line "- the build: none needed, the releases az-fbsd$major-amd64-v3 and -v2 have yt-dlp $v${ev:+ and yt-dlp-ejs $ev}"
            return 0
        fi
        notable=1
        since="$(git log -1 --format=%ct -- www/yt-dlp www/py-yt-dlp-ejs)"
        line "- not published:$miss"
    else
        since="$(date +%s)"
    fi
    # the runs of build.yml of main: id|status|conclusion|created (s)|actor
    gh api "repos/$repo/actions/workflows/build.yml/runs?branch=main&per_page=50" --jq '.workflow_runs[] |
        [(.id | tostring), .status, (.conclusion // ""), (.created_at | fromdateiso8601 | tostring),
         (.triggering_actor.login // .actor.login // "")] | join("|")' > "$w/runs" 2> "$w/err" ||
        { warn "the runs of build.yml: the API failed ($(tail -n 1 "$w/err")): no build now, the next check"; return 0; }
    busy="$(awk -F'|' '$2 != "completed" { print $1 " (" $2 ")"; exit }' "$w/runs")"
    mine="$(awk -F'|' -v s="$since" '$5 == "github-actions[bot]" && $4 >= s' "$w/runs")"
    ok="$(printf '%s\n' "$mine" | awk -F'|' '$2 == "completed" && $3 == "success" { print $1; exit }')"
    nmine="$(printf '%s\n' "$mine" | grep -c '|')"
    burl="${GITHUB_SERVER_URL:-https://github.com}/$repo/actions/runs"
    wurl="${GITHUB_SERVER_URL:-https://github.com}/$repo/actions/workflows/build.yml?query=branch%3Amain"
    if [ -n "$ok" ]; then
        line "- the build: run $burl/$ok, started by this workflow after the last change of the ports, succeeded: what it did not publish (publish_only) goes out with the next publish of aZ"
        return 0
    fi
    if [ -n "$busy" ]; then
        line "- the build: waits, build.yml of main has the run $burl/${busy%% *} ${busy#* } (a new run would cancel a pending one): the next check starts it"
        notable=1
        return 0
    fi
    if [ "$nmine" -ge 3 ]; then
        warn "the build: $nmine runs of build.yml started by this workflow after the last change of the ports failed or were cancelled: not again (a hand is needed)"
        return 0
    fi
    notable=1
    set -- -f ref=main -f 'inputs[cputype]=both' -f 'inputs[ports]=www/yt-dlp' -f 'inputs[publish]=true' -f "inputs[publish_only]=$only"
    if [ "$dry" = 1 ]; then
        line "- the build it would start: build.yml of main, cputype both, ports www/yt-dlp, publish with publish_only \"$only\""
        return 0
    fi
    if gh api -X POST "repos/$repo/actions/workflows/build.yml/dispatches" "$@" > "$w/err" 2>&1; then
        line "- the build: build.yml of main started ($wurl), cputype both, ports www/yt-dlp, publish with publish_only \"$only\": published when nothing else differs from the releases"
    else
        warn "the build: build.yml could not be started ($(tail -n 1 "$w/err")): the next check"
    fi
}

if [ "$tag" = "$cur" ]; then
    line "- www/yt-dlp: $cur, the latest release of yt-dlp/yt-dlp ($published): up to date"
    build_check
    finish 0
fi
if ! newer "$tag" "$cur"; then
    warn "the latest release of yt-dlp/yt-dlp, $tag, is older than www/yt-dlp ($cur): nothing done"
    finish 0
fi
notable=1
line "- www/yt-dlp: $cur; the latest release of yt-dlp/yt-dlp: **$tag** ($published)"
[ "$hasasset" = 1 ] || { line "- the release $tag has no yt-dlp.tar.gz yet: the next check"; finish 0; }

# --- 2. the distfile and the patches -------------------------------------------------------
grep -q "^SHA256 (yt-dlp/$(re "$cur")/yt-dlp\.tar\.gz) = " www/yt-dlp/distinfo ||
    fail "www/yt-dlp/distinfo has no line SHA256 (yt-dlp/$cur/yt-dlp.tar.gz): not the layout this script writes"
u="https://github.com/yt-dlp/yt-dlp/releases/download/$tag"
dl "$u/yt-dlp.tar.gz" "$w/dl/yt-dlp.tar.gz"
sha="$(sha256f "$w/dl/yt-dlp.tar.gz")"
size="$(wc -c < "$w/dl/yt-dlp.tar.gz" | tr -d ' ')"
ssum=""
if curl -fsSL --retry 5 --retry-all-errors --retry-delay 10 -o "$w/dl/SHA2-256SUMS" "$u/SHA2-256SUMS" 2> /dev/null; then
    ssum="$(awk '$2 == "yt-dlp.tar.gz" || $2 == "*yt-dlp.tar.gz" { print $1; exit }' "$w/dl/SHA2-256SUMS")"
fi
[ -n "$digest$ssum" ] || fail "yt-dlp.tar.gz of $tag: neither the API nor a SHA2-256SUMS of the release gives its SHA-256"
[ -z "$digest" ] || [ "$digest" = "sha256:$sha" ] || fail "yt-dlp.tar.gz of $tag: SHA-256 $sha, the API gives $digest"
[ -z "$ssum" ] || [ "$ssum" = "$sha" ] || fail "yt-dlp.tar.gz of $tag: SHA-256 $sha, its SHA2-256SUMS has $ssum"
by=""
[ -n "$digest" ] && by="the API of GitHub"
[ -n "$ssum" ] && by="${by:+$by and }the SHA2-256SUMS of the release"
line "- yt-dlp.tar.gz: $size bytes, SHA-256 $sha (as $by give it)"
tar -xzf "$w/dl/yt-dlp.tar.gz" -C "$w/src" 2> "$w/err" || fail "yt-dlp.tar.gz of $tag does not unpack: $(tail -n 1 "$w/err")"
src="$w/src/yt-dlp"
[ -f "$src/pyproject.toml" ] || fail "yt-dlp.tar.gz of $tag has no yt-dlp/pyproject.toml (the WRKSRC of the port)"

# patch_files <patch>: the files it changes (its +++ lines; -p0)
patch_files() { sed -n 's/^+++ \([^[:space:]]*\).*/\1/p' "$1"; }
# remake <patch> <source>: the patch made again from the originals (<file>.az-orig) and
# the patched files, as make makepatch makes it; the lines before its first diff kept
remake() {
    sed -n '/^--- /q; p' "$1" > "$w/remake"
    for f in $(patch_files "$1"); do
        (cd "$2" && mv "$f.az-orig" "$f.orig" && TZ=UTC diff -audp "$f.orig" "$f") |
            sed -e '/^---/s|\.[0-9]* +0000$| UTC|' -e '/^+++/s|\([[:blank:]][-0-9:.+]*\)*$||' >> "$w/remake"
        mv "$2/$f.orig" "$2/$f.az-orig"
    done
    cat "$w/remake" > "$1"
}
remade=""
line "- the patches of www/yt-dlp on $tag:"
for p in www/yt-dlp/files/patch-*; do
    [ -f "$p" ] || continue
    pn="${p##*/}"
    for f in $(patch_files "$p"); do
        [ -f "$src/$f" ] || fail "$pn: $tag has no $f"
        cp -p "$src/$f" "$src/$f.az-orig"
    done
    if patch -d "$src" -p0 -E --forward --batch --fuzz=0 --dry-run < "$p" > "$w/patch.out" 2>&1; then
        patch -d "$src" -p0 -E --forward --batch --fuzz=0 --no-backup-if-mismatch < "$p" > /dev/null 2>&1 || fail "$pn: patch failed after its dry run"
        off="$(grep -c 'succeeded at .*offset' "$w/patch.out")"
        line "  - $pn: applies without fuzz$( [ "$off" != 0 ] && echo " ($off hunks at an offset)")"
    elif patch -d "$src" -p0 -E --forward --batch --dry-run < "$p" > "$w/patch.out" 2>&1; then
        patch -d "$src" -p0 -E --forward --batch --no-backup-if-mismatch < "$p" > /dev/null 2>&1 || fail "$pn: patch failed after its dry run"
        remake "$p" "$src"
        remade="$remade $pn"
        line "  - $pn: applies only with fuzz ($(grep -c 'with fuzz' "$w/patch.out") hunks): made again from the result"
    else
        line "  - $pn: **does not apply**:"
        line '```'
        cat "$w/patch.out" >> "$rep"
        line '```'
        fail "$pn does not apply to yt-dlp $tag: the port needs a hand (no commit)"
    fi
    for f in $(patch_files "$p"); do rm -f "$src/$f.az-orig"; done
done
setvar www/yt-dlp/Makefile DISTVERSION "$tag"
{
    echo "TIMESTAMP = $(date +%s)"
    echo "SHA256 (yt-dlp/$tag/yt-dlp.tar.gz) = $sha"
    echo "SIZE (yt-dlp/$tag/yt-dlp.tar.gz) = $size"
} > www/yt-dlp/distinfo

# --- 3. yt-dlp-ejs and deno ----------------------------------------------------------------
pin="$(sed -n 's/^[[:space:]]*"yt-dlp-ejs==\([0-9][0-9a-z.]*\)",\{0,1\}[[:space:]]*$/\1/p' "$src/pyproject.toml" | sort -u)"
case "$pin" in
    "") fail "pyproject.toml of $tag pins no yt-dlp-ejs (\"yt-dlp-ejs==<version>\"): the port needs a hand" ;;
    *"
"*) fail "pyproject.toml of $tag pins more than one yt-dlp-ejs: $(echo $pin)" ;;
esac
vpin="$(sed -n "s/^VERSION = '\([^']*\)'.*/\1/p" "$src/yt_dlp/extractor/youtube/jsc/_builtin/vendor/_info.py" 2> /dev/null)"
mpin="$(sed -n 's/^EJS_VERSION = //p' "$src/Makefile")"
whash="$(sed -n 's/^EJS_WHEEL_HASH = sha256:\([0-9a-f]\{64\}\)$/\1/p' "$src/Makefile")"
wname="$(sed -n 's/^EJS_WHEEL_NAME = //p' "$src/Makefile")"
[ "$vpin" = "$pin" ] || fail "yt-dlp $tag: pyproject.toml pins yt-dlp-ejs $pin, its vendor/_info.py has ${vpin:-none}"
[ "$mpin" = "$pin" ] || fail "yt-dlp $tag: pyproject.toml pins yt-dlp-ejs $pin, EJS_VERSION of its Makefile is ${mpin:-none}"
ours=0; [ -f www/py-yt-dlp-ejs/Makefile ] && ours=1
offejs="$(offv www/py-yt-dlp-ejs)"
[ -n "$pretend_ejs" ] && offejs="$pretend_ejs" && line "- pretend: the official www/py-yt-dlp-ejs taken as at $pretend_ejs"
if [ "$ours" = 1 ]; then
    have="$(mkvar www/py-yt-dlp-ejs/Makefile DISTVERSION)"; whose="ours"
else
    [ -n "$offejs" ] || fail "no official www/py-yt-dlp-ejs at $commit (raw.githubusercontent.com)"
    have="$offejs"; whose="the official port"
fi
ejsnote=""
if newer "$pin" "$have"; then
    whl="yt_dlp_ejs-$pin-py3-none-any.whl"
    [ -n "$whash" ] || fail "yt-dlp $tag pins yt-dlp-ejs $pin without EJS_WHEEL_HASH in its Makefile: no SHA-256 to check the wheel by"
    [ -z "$wname" ] || [ "$wname" = "$whl" ] || fail "yt-dlp $tag: EJS_WHEEL_NAME is $wname, not $whl"
    dl "https://github.com/yt-dlp/ejs/releases/download/$pin/$whl" "$w/dl/$whl"
    esha="$(sha256f "$w/dl/$whl")"
    esize="$(wc -c < "$w/dl/$whl" | tr -d ' ')"
    [ "$esha" = "$whash" ] || fail "$whl of github.com/yt-dlp/ejs: SHA-256 $esha, EJS_WHEEL_HASH of yt-dlp $tag is $whash"
    if [ "$ours" = 0 ]; then
        mkdir -p www/py-yt-dlp-ejs
        cp tools/ytdlp-ejs/Makefile tools/ytdlp-ejs/pkg-descr www/py-yt-dlp-ejs/ || fail "tools/ytdlp-ejs/ not copied"
        ejsnote="www/py-yt-dlp-ejs: ours at $pin, made from tools/ytdlp-ejs/ (the official port of the pinned tree has $have)"
    else
        ejsnote="www/py-yt-dlp-ejs: ours from $have to $pin"
    fi
    setvar www/py-yt-dlp-ejs/Makefile DISTVERSION "$pin"
    {
        echo "TIMESTAMP = $(date +%s)"
        echo "SHA256 (yt-dlp-ejs/$whl) = $esha"
        echo "SIZE (yt-dlp-ejs/$whl) = $esize"
    } > www/py-yt-dlp-ejs/distinfo
    line "- yt-dlp-ejs: $tag pins **$pin**, $whose has $have: $ejsnote; $whl of the release of github.com/yt-dlp/ejs, $esize bytes, SHA-256 $esha (EJS_WHEEL_HASH of yt-dlp)"
elif [ "$pin" = "$have" ]; then
    line "- yt-dlp-ejs: $tag pins $pin, $whose has it"
else
    warn "yt-dlp-ejs: $tag pins $pin, $whose has $have, newer: yt-dlp takes the scripts of $pin only (major.minor and SHA3-512)"
fi
if [ "$ours" = 1 ] && [ -n "$offejs" ] && ! newer "$(mkvar www/py-yt-dlp-ejs/Makefile DISTVERSION)" "$offejs"; then
    line "- yt-dlp-ejs: the official port of the pinned tree has $offejs, as ours: ours can go (git rm -r www/py-yt-dlp-ejs)"
fi
dmin="$(awk '/^class DenoJsRuntime/ { d = 1 } d && /MIN_SUPPORTED_VERSION *=/ { gsub(/[^0-9,]/, ""); gsub(/,/, "."); print; exit }' "$src/yt_dlp/utils/_jsruntime.py" 2> /dev/null)"
deno="$(offv www/deno)"
if [ -z "$dmin" ] || [ -z "$deno" ]; then
    warn "deno: the oldest one yt-dlp $tag runs (${dmin:-not found in yt_dlp/utils/_jsruntime.py}) or the official www/deno (${deno:-not found}) unknown"
elif newer "$dmin" "$deno"; then
    warn "deno: yt-dlp $tag runs deno $dmin or newer, the official www/deno of the pinned tree is $deno: yt-dlp cannot solve the challenges of YouTube with it"
else
    line "- deno: the official $deno; yt-dlp $tag runs $dmin or newer"
fi
line "- the dependencies yt-dlp $tag declares (pyproject.toml, default): $(sed -n '/^default = \[/,/^\]/p' "$src/pyproject.toml" | sed -n 's/^[[:space:]]*"\([^"]*\)".*/`\1`/p' | tr '\n' ' ' | sed 's/ $//; s/` `/`, `/g')"

# --- 4. the check of the tree, the commit, the push ----------------------------------------
say "the check of the tree with make -V"
if [ -n "${CHECK_TREE:-}" ]; then
    sh -c "$CHECK_TREE" > "$w/check-tree.log" 2>&1
else
    sh tools/check-tree-ci.sh "$release" x86-64-v3 > "$w/check-tree.log" 2>&1
fi
rc=$?
for o in www/yt-dlp www/py-yt-dlp-ejs; do
    l="$(grep -E "^[A-Z]+ +$o:" "$w/check-tree.log")"
    [ -n "$l" ] && line "- tools/check-tree.sh: $l"
done
if [ "$rc" != 0 ]; then
    line '```'
    grep -E 'FAIL|error' "$w/check-tree.log" | head -n 30 >> "$rep"
    tail -n 3 "$w/check-tree.log" >> "$rep"
    line '```'
    fail "the check of the tree failed (exit $rc): no commit"
fi
git add -A -- www/yt-dlp || fail "git add failed"
[ -d www/py-yt-dlp-ejs ] && { git add -A -- www/py-yt-dlp-ejs || fail "git add failed"; }
subj="www/yt-dlp: $tag, the latest release of GitHub"
case "$ejsnote" in www/py-yt-dlp-ejs:*) subj="$subj; www/py-yt-dlp-ejs: $pin" ;; esac
{
    # one paragraph, folded as a whole
    printf '%s' "The latest release of github.com/yt-dlp/yt-dlp, $tag (published $published),"
    printf ' %s' "taken by yt-dlp-update.yml (tools/ytdlp-update.sh, run $runurl):" \
        "DISTVERSION and distinfo, yt-dlp.tar.gz of $size bytes with the SHA-256 $by give."
    if [ -n "$remade" ]; then
        printf ' %s' "Made again from the result, as they applied only with fuzz:$remade; the other patches apply without fuzz."
    else
        printf ' %s' "The patches apply without fuzz."
    fi
    if [ -n "$ejsnote" ]; then
        printf ' %s' "$ejsnote: the wheel of the release of github.com/yt-dlp/ejs, with the SHA-256 yt-dlp pins (EJS_WHEEL_HASH)."
    else
        printf ' %s' "yt-dlp-ejs: $pin, the pin of the release, as $whose has it."
    fi
    echo
} | fold -s -w 72 | sed 's/ *$//' > "$w/body"
{ echo "$subj"; echo; cat "$w/body"; } > "$w/msg"
git commit -q -F "$w/msg" || fail "git commit failed"
committed=1
line ""
line "The commit$( [ "$dry" = 1 ] && echo " it would push to main" ):"
line ""
line '```diff'
git show --format='commit %h, %an <%ae>%n%n%B' --stat -p HEAD | sed 's/^```/` ``/' >> "$rep"
line '```'
if [ "$dry" = 0 ]; then
    i=0
    while ! git push -q origin HEAD:main 2> "$w/push.err"; do
        i=$((i + 1))
        [ "$i" -lt 5 ] || fail "the push to main failed 5 times: $(tail -n 2 "$w/push.err" | tr '\n' ' ')"
        sleep $((i * 5))
        if ! git pull -q --rebase origin main 2>> "$w/push.err"; then
            git rebase --abort 2> /dev/null
            fail "main moved and the commit does not go on top of it: $(tail -n 2 "$w/push.err" | tr '\n' ' ')"
        fi
    done
    line ""
    line "Pushed to main: $(git rev-parse --short HEAD)."
    changed=1
fi
build_check
finish 0
