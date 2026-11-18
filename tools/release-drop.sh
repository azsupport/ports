#!/bin/sh
# release-drop.sh - a release of this repository away (a draft of tools/runs-save.sh): GitHub
# answered DELETE of drafts of 323 and 271 packages with HTTP 502 and kept them (run
# 44252348106, 18.11.2026), while drafts of tens went; so when the release does not go at
# once, its files go one by one first (the first page again and again: the files after
# a deleted one move up), then the release.
#
# Usage: sh tools/release-drop.sh <release id> [<name for the output>]
# Environment: GH_TOKEN and GITHUB_REPOSITORY (gh api).
# Exit status: 0 the release is away, 1 it is not.

set -u
id="${1:?usage: sh tools/release-drop.sh <release id> [<name>]}"
name="${2:-$id}"
repo="${GITHUB_REPOSITORY:?}"
w="$(mktemp -d "${TMPDIR:-/tmp}/release-drop.XXXXXX")" || exit 1
trap 'rm -rf "$w"' EXIT

gh api -X DELETE "repos/$repo/releases/$id" > /dev/null 2> "$w/err" && exit 0
echo "$name: DELETE answered $(tail -n 1 "$w/err"): its files one by one first"
n=0; i=0
while [ "$i" -lt 40 ]; do
    gh api "repos/$repo/releases/$id/assets?per_page=100&page=1" --jq '.[].id' > "$w/ids" 2> "$w/err" || break
    [ -s "$w/ids" ] || break
    while read -r a; do
        if gh api -X DELETE "repos/$repo/releases/assets/$a" > /dev/null 2>&1; then n=$((n + 1)); fi
    done < "$w/ids"
    i=$((i + 1))
done
echo "$name: $n files deleted"
for t in 1 2 3; do
    gh api -X DELETE "repos/$repo/releases/$id" > /dev/null 2> "$w/err" && exit 0
    sleep $((t * 10))
done
echo "$name: not deleted: $(tail -n 1 "$w/err")"
exit 1
