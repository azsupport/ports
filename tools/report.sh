#!/bin/sh
# report.sh - turn the results of tools/build.sh and of the checks of PHP (the lines
# of results/checks.txt and the files results/check-php-<version>.txt of
# tools/check-php.sh) into the job log, the job summary ($GITHUB_STEP_SUMMARY) and
# annotations (an error for each port that failed or was not built and for checks
# that failed, a notice for the outcome), so that it shows on the page of the run
# and in the API.
#
# Usage: sh tools/report.sh [<results>]    (default: results/ of the tree)
# REPORT_TITLE: the title of the summary (default "azsupport/ports").
# Exit status: 0 the build and every check passed, 1 otherwise.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
res="${1:-$top/results}"
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
title="${REPORT_TITLE:-azsupport/ports}"

# workflow commands need %, CR and LF escaped
escape() { sed 's/%/%25/g; s/\r/%0D/g' | awk '{ printf "%s%%0A", $0 }'; }
# annot <level> <title> <file>: the file as annotations of about 3.8 KB each
annot() {
    _i=1
    fold -b -s -w 3600 "$3" | LC_ALL=C awk -v d="$3" '
        { line = $0 "\n"
          if (n == 0 || size + length(line) > 3800) { if (n) close(f); n++; size = 0; f = d ".annot." n }
          printf "%s", line > f; size += length(line) }'
    while [ -f "$3.annot.$_i" ]; do
        if [ "$_i" = 1 ]; then _t="$2"; else _t="$2, continued ($_i)"; fi
        printf '::%s title=%s::%s\n' "$1" "$_t" "$(escape < "$3.annot.$_i")"
        rm -f "$3.annot.$_i"
        _i=$((_i + 1))
    done
}

# the check of the tree before the VM (check-tree.txt of the workflow): its FAIL lines
if [ -s "$top/check-tree.txt" ] && grep -q 'FAIL' "$top/check-tree.txt"; then
    {
        echo "### $title: the check of the tree (tools/check-tree.sh)"
        echo
        echo '```'
        grep 'FAIL' "$top/check-tree.txt" | cut -c1-240
        echo '```'
        echo
    } >> "$summary"
    grep 'FAIL' "$top/check-tree.txt" | head -n 30 | while read -r l; do
        printf '::error title=check-tree::%s\n' "$(printf '%s\n' "$l" | escape)"
    done
fi
if [ ! -s "$res/summary.txt" ]; then
    echo "::error title=$title::no results: $res/summary.txt is missing (the build did not run to its end)"
    printf '### %s\n\nno results: %s/summary.txt is missing\n' "$title" "$res" >> "$summary"
    exit 1
fi
rc=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# the build: the summary, and for each port that failed the end of its log
{
    cat "$res/summary.txt"
    awk '$1 ~ /\// && $2 == "FAIL" { print $1 }' "$res/summary.txt" | while read -r o; do
        k="$(printf '%s' "$o" | tr '/@' '__')"
        l="$res/logs/$k.log"
        [ -s "$l" ] || continue
        echo
        echo "== $o: the errors of logs/$k.log, then its end"
        grep -E ' error:|Error code|^\*\*\*|^===>.*(not found|failed|IGNORE)' "$l" | head -n 15 | cut -c1-240
        echo "..."
        tail -n 15 "$l" | cut -c1-240
    done
} > "$tmp/build.txt"
echo "==================== build"
cat "$tmp/build.txt"
# the last line "result: ..." of a summary
result() { grep '^result:' "$1" 2>/dev/null | tail -n 1 | sed 's/^result: *//'; }
r="$(result "$res/summary.txt")"
case "$r" in OK) level=notice ;; *) level=error; rc=1 ;; esac
annot "$level" "$title: build ($(printf '%s' "${r:-no result line}" | cut -c1-120))" "$tmp/build.txt"
# each port that failed or was not built: an annotation of its own
awk '$1 ~ /\// && ($2 == "FAIL" || ($2 == "SKIP" && / needs /)) { print }' "$res/summary.txt" | while read -r o w rest; do
    printf '::error title=%s %s::%s\n' "$o" "$w" "$(printf '%s\n' "$rest" | escape)"
done
{
    echo "### $title: build"
    echo
    echo '```'
    cat "$tmp/build.txt"
    echo '```'
    echo
} >> "$summary"

# the checks of PHP: results/checks.txt (a line per version, written by the workflow)
# and the output of tools/check-php.sh, results/check-php-<version>.txt
if [ -s "$res/checks.txt" ]; then
    {
        cat "$res/checks.txt"
        for f in "$res"/check-php-*.txt; do
            [ -f "$f" ] || continue
            grep -q '^FAIL' "$f" || continue
            echo
            echo "== ${f##*/}: what failed"
            grep '^FAIL' "$f" | cut -c1-240
        done
    } > "$tmp/php.txt"
    echo "==================== PHP"
    cat "$tmp/php.txt"
    if grep -q ': FAIL' "$res/checks.txt"; then level=error; rc=1; else level=notice; fi
    annot "$level" "$title: PHP checks" "$tmp/php.txt"
    {
        echo "### $title: PHP, the packages installed and checked"
        echo
        echo '```'
        cat "$tmp/php.txt"
        echo '```'
        echo
        for f in "$res"/check-php-*.txt; do
            [ -f "$f" ] || continue
            echo "<details><summary>${f##*/}</summary>"
            echo
            echo '```'
            cat "$f"
            echo '```'
            echo '</details>'
            echo
        done
    } >> "$summary"
fi
exit "$rc"
