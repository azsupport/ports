#!/bin/sh
# report.sh - turn the results of tools/build.sh and tools/check-php.sh into the job
# log, the job summary ($GITHUB_STEP_SUMMARY) and annotations (an error for each port
# that failed or was not built and for each version whose checks failed, a notice
# for the outcome), so that it shows on the page of the run and in the API.
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

# the checks of PHP
for d in "$res"/check-php-*/; do
    [ -f "$d/summary.txt" ] || continue
    v="${d%/}"; v="${v##*/check-php-}"
    {
        cat "$d/summary.txt"
        if grep -q '^FAIL ' "$d/tests.txt" 2>/dev/null; then
            echo "checks that failed:"
            grep '^FAIL ' "$d/tests.txt" | cut -c1-240
        fi
    } > "$tmp/php-$v.txt"
    echo "==================== PHP $v"
    cat "$tmp/php-$v.txt"
    case "$(result "$d/summary.txt")" in OK) level=notice ;; *) level=error; rc=1 ;; esac
    annot "$level" "$title: PHP $v checks" "$tmp/php-$v.txt"
    {
        echo "### $title: PHP $v, the packages installed together and checked"
        echo
        echo '```'
        cat "$tmp/php-$v.txt"
        echo '```'
        echo
        echo '<details><summary>tests.txt</summary>'
        echo
        echo '```'
        cat "$d/tests.txt" 2>/dev/null
        echo '```'
        echo '</details>'
        echo
    } >> "$summary"
done
exit "$rc"
