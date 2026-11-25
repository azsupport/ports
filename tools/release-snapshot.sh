#!/bin/sh
# release-snapshot.sh - the repository of pkg of a release of build.yml (azsupport-fbsd15-amd64-v3,
# azsupport-fbsd15-amd64-v2) kept also as a release of its own for each publish, one that never
# changes: <tag>-<YYYYMMDD>-<HHMM> (UTC) with the catalog and every package of that
# repository, so that a server goes back to it by the url of its repository azsupport, as a
# publish takes from the release the packages its repository has no more (aZ, 18.11.2026:
# «может 31 последних версий будем хранить?», «чуть что я бы переключал индекс
# репозитория на старее версию»). The old packages cannot stay in the release itself:
# GitHub keeps at most 1000 files in a release (HTTP 422, run 43930987665, 16.11.2026),
# and a build of every port gives every package a new name; it limits neither the size
# of releases nor their bandwidth (docs.github.com, "About releases").
#
# Usage:
#   sh tools/release-snapshot.sh before <tag>
#     Before a publish: the files of the release <tag> as a snapshot named by the time
#     its catalog (packagesite.pkg) went up, unless the newest snapshot of <tag> has that
#     catalog already (the same digest): the repository published before the snapshots
#     began, or by a publish whose snapshot failed. Each file downloaded is checked
#     against the digest GitHub gives for it.
#   sh tools/release-snapshot.sh after <directory> <tag> <keep>
#     After a publish: the files of <directory>, the repository just published, as the
#     snapshot <tag>-<now>; then away with the snapshots of <tag> past the newest <keep>
#     (0: none away).
#
# Environment: GH_TOKEN and GITHUB_REPOSITORY (gh); GITHUB_SERVER_URL, GITHUB_RUN_ID and
# GITHUB_SHA for the notes of a snapshot.
# A snapshot is made at the head of main, as the release (build.yml: the token of a run
# may not make a ref whose files of .github/workflows differ from those of main), and it
# is never the latest release of the repository. A server goes back to one with its url
# in /usr/local/etc/pkg/repos/azsupport.conf (README.md, "A server and the repository azsupport").
# Exit status: 0 done, or nothing to do; 1 failed (before: then nothing is to be
# published, the release as it is would be lost); 2 a wrong call.

set -u
usage() {
    echo "usage: sh tools/release-snapshot.sh before <tag> | after <directory> <tag> <keep>" >&2
    exit 2
}
repo="${GITHUB_REPOSITORY:?}"
run="${GITHUB_SERVER_URL:-https://github.com}/$repo/actions/runs/${GITHUB_RUN_ID:-?}"
w="$(mktemp -d "${TMPDIR:-/tmp}/release-snapshot.XXXXXX")" || exit 1
trap 'rm -rf "$w"' EXIT
say() { printf 'snapshot: %s\n' "$*"; }
sha256f() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum < "$1" | cut -c1-64; else sha256 -q "$1"; fi
}

# gh api with 5 tries, 20 s apart: an answer of GitHub such as "HTTP 504, we couldn't
# respond to your request in time" (run 45130779702 attempt 2, 23.11.2026: the list of
# the releases, so the publish stopped after the build and every check had passed)
# passes; a request that keeps failing still fails
gh_api() {
    _i=1
    while :; do
        gh api "$@" && return 0
        [ "$_i" -lt 5 ] || return 1
        say "gh api $1: try $_i failed, again in 20 s" >&2
        _i=$((_i + 1)); sleep 20
    done
}

# the snapshots of the release $1, newest first (their tags hold the time). 10 releases a
# page: each release comes with all its files, and 100 a page took GitHub 10 s, its limit
# (run 45623903407, 25.11.2026: 5 times HTTP 504 with 56 releases; 10 a page: 1-4 s)
snapshots() {
    : > "$w/snaps"
    _p=1
    while [ "$_p" -le 200 ]; do
        gh_api "repos/$repo/releases?per_page=10&page=$_p" --jq '.[] | "\(.draft) \(.tag_name)"' > "$w/page" || return 1
        [ -s "$w/page" ] || break
        while read -r _d _t; do
            [ "$_d" = false ] || continue
            case "$_t" in
                "$1"-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]) echo "$_t" >> "$w/snaps" ;;
            esac
        done < "$w/page"
        _p=$((_p + 1))
    done
    LC_ALL=C sort -r "$w/snaps"
}

# the files of the release with the tag $1, "<name> <digest> <size>" a line (digest
# "null" when GitHub gives none)
assets() {
    gh_api "repos/$repo/releases/tags/$1" --jq '.assets[] | select(.state == "uploaded") | "\(.name) \(.digest) \(.size)"'
}

# the files of the directory $1, "<name> sha256:<hex> <size>" a line
local_files() {
    for _f in "$1"/*; do
        [ -f "$_f" ] || continue
        echo "${_f##*/} sha256:$(sha256f "$_f") $(wc -c < "$_f" | tr -d ' ')"
    done
}

# the names of the files of the list $1 (local_files) that the list $2 (assets) lacks
# or has with another digest (the same size when it has no digest); by FILENAME, not
# NR == FNR, which an empty $2 (a release just made) would make true for $1 too
missing() {
    awk -v have="$2" 'FILENAME == have { d[$1] = $2; s[$1] = $3; next }
        !($1 in d) { print $1; next }
        d[$1] != "null" && d[$1] != "" && d[$1] != $2 { print $1; next }
        (d[$1] == "null" || d[$1] == "") && s[$1] != $3 { print $1 }' "$2" "$1"
}

# put <directory> <tag of the snapshot> <notes>: a release with every file of the
# directory, checked by name and digest (three tries for what did not go up); one of
# that tag with another catalog is not touched
put() {
    local_files "$1" > "$w/local"
    [ -s "$w/local" ] || { say "no files in $1"; return 1; }
    _cat="$(awk '$1 == "packagesite.pkg" { print $2 }' "$w/local")"
    if gh release view "$2" --repo "$repo" > /dev/null 2>&1; then
        _c="$(assets "$2" | awk '$1 == "packagesite.pkg" { print $2 }')"
        if [ -n "$_c" ] && [ "$_c" != null ] && [ "$_c" != "$_cat" ]; then
            say "$2 is there already with another catalog: not touched"
            return 1
        fi
        say "$2 is there already: what it lacks goes up"
    else
        gh release create "$2" --repo "$repo" --title "$2" --notes "$3" --target main --latest=false > /dev/null ||
            { say "$2 was not made"; return 1; }
    fi
    # again after 1, 5 and 15 minutes for what did not go up: a limit of GitHub on the
    # requests that make content (403, secondary rate limit) passes with time
    _n=0
    while :; do
        assets "$2" > "$w/have" || { say "no list of the files of $2"; return 1; }
        missing "$w/local" "$w/have" > "$w/miss"
        [ -s "$w/miss" ] || break
        _n=$((_n + 1))
        if [ "$_n" -gt 4 ]; then
            say "$2: $(wc -l < "$w/miss" | tr -d ' ') files not there after 4 tries: $(head -n 5 "$w/miss" | tr '\n' ' ')"
            return 1
        fi
        case "$_n" in 2) _z=60 ;; 3) _z=300 ;; 4) _z=900 ;; *) _z=0 ;; esac
        if [ "$_z" -gt 0 ]; then
            say "$2: $(wc -l < "$w/miss" | tr -d ' ') files did not go up: again in $_z s"
            sleep "$_z"
        fi
        say "$2: $(wc -l < "$w/miss" | tr -d ' ') files to go up (try $_n)"
        (cd "$1" && xargs gh release upload "$2" --repo "$repo" --clobber < "$w/miss") || :
    done
    say "$2: $(wc -l < "$w/local" | tr -d ' ') files, $(awk '{ s += $3 } END { printf "%.0f", s / 1048576 }' "$w/local") MB: ${GITHUB_SERVER_URL:-https://github.com}/$repo/releases/tag/$2"
}

# the rest of the notes of a snapshot: how a server takes it
howto() {
    echo "A server goes back to it with url \"${GITHUB_SERVER_URL:-https://github.com}/$repo/releases/download/$1\" in /usr/local/etc/pkg/repos/azsupport.conf, then pkg update -f -r azsupport and pkg upgrade -f -r azsupport (the packages of azsupport as they were in it); back to the release with its url again, pkg update -f -r azsupport, pkg upgrade -r azsupport (README.md, A server and the repository azsupport)."
}

before() {
    if ! assets "$1" > "$w/cur" 2> "$w/err"; then
        if grep -q 'Not Found' "$w/err"; then say "no release $1 yet: nothing to keep"; return 0; fi
        say "no list of the files of $1: $(tail -n 1 "$w/err")"
        return 1
    fi
    _cat="$(awk '$1 == "packagesite.pkg" { print $2 }' "$w/cur")"
    [ -n "$_cat" ] || { say "$1 has no catalog (packagesite.pkg): nothing to keep"; return 0; }
    snapshots "$1" > "$w/list" || { say "no list of the releases"; return 1; }
    _last="$(head -n 1 "$w/list")"
    if [ -n "$_last" ] && [ "$_cat" != null ]; then
        if [ "$(assets "$_last" | awk '$1 == "packagesite.pkg" { print $2 }')" = "$_cat" ]; then
            say "the repository of $1 is kept already: $_last"
            return 0
        fi
    fi
    _t="$(gh_api "repos/$repo/releases/tags/$1" --jq '.assets[] | select(.name == "packagesite.pkg") | .updated_at')"
    _s="$(printf '%s\n' "$_t" | sed -n 's/^\([0-9]\{4\}\)-\([0-9][0-9]\)-\([0-9][0-9]\)T\([0-9][0-9]\):\([0-9][0-9]\).*/\1\2\3-\4\5/p')"
    [ -n "$_s" ] || { say "no time of the catalog of $1 ($_t)"; return 1; }
    mkdir -p "$w/old"
    gh_api "repos/$repo/releases/tags/$1" --jq '.assets[] | select(.state == "uploaded") | "\(.name) \(.browser_download_url)"' > "$w/urls" ||
        { say "no list of the files of $1"; return 1; }
    say "$1 as it is ($(wc -l < "$w/urls" | tr -d ' ') files, its catalog of $_t) into $1-$_s"
    while read -r _n _u; do
        curl -fsSL --retry 5 --retry-all-errors --retry-delay 10 -o "$w/old/$_n" "$_u" ||
            { say "$_n did not download ($_u)"; return 1; }
    done < "$w/urls"
    local_files "$w/old" > "$w/got"
    missing "$w/got" "$w/cur" > "$w/bad"
    if [ -s "$w/bad" ]; then
        say "not as $1 gives them: $(head -n 5 "$w/bad" | tr '\n' ' ')"
        return 1
    fi
    put "$w/old" "$1-$_s" "The repository of pkg of the release $1 as it was published at $_t (the time its catalog went up), kept by run $run before it published the next one. $(howto "$1-$_s")"
}

after() {
    [ -d "$1" ] || { say "no directory $1"; return 1; }
    _s="$2-$(date -u +%Y%m%d-%H%M)"
    put "$1" "$_s" "The repository of pkg of the release $2 as published at $(date -u '+%Y-%m-%d %H:%M') UTC by run $run (commit ${GITHUB_SHA:-?}). $(howto "$_s")" || return 1
    prune "$2" "$3"
}

# away with the snapshots of $1 past the newest $2 (0: none); a failure here only says so
prune() {
    case "$2" in '' | *[!0-9]*) say "keep is not a number ($2): none away"; return 0 ;; esac
    [ "$2" -gt 0 ] || { say "every snapshot of $1 kept"; return 0; }
    snapshots "$1" > "$w/list" || { say "no list of the releases: none away"; return 0; }
    tail -n +"$(($2 + 1))" "$w/list" > "$w/away"
    if [ ! -s "$w/away" ]; then
        say "$(wc -l < "$w/list" | tr -d ' ') snapshots of $1, the newest $2 are kept: none away"
        return 0
    fi
    while read -r _s; do
        _id="$(gh api "repos/$repo/releases/tags/$_s" --jq .id 2> /dev/null)" || _id=""
        if [ -n "$_id" ] && gh api -X DELETE "repos/$repo/releases/$_id" > /dev/null; then
            if gh api -X DELETE "repos/$repo/git/refs/tags/$_s" > /dev/null 2>&1; then
                say "$_s deleted (past the newest $2), its tag too"
            else
                say "$_s deleted (past the newest $2); its tag stays"
            fi
        else
            say "$_s not deleted"
        fi
    done < "$w/away"
    return 0
}

case "${1:-}" in
    before) [ $# -eq 2 ] || usage; before "$2" ;;
    after) [ $# -eq 4 ] || usage; after "$2" "$3" "$4" ;;
    *) usage ;;
esac
