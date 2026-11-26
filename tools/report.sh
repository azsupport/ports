#!/bin/sh
# report.sh - turn the results of tools/build.sh and of the checks of PHP (the lines
# of results/checks.txt and the files results/check-php-<version>.txt of
# tools/check-php.sh) into the job log, the job summary ($GITHUB_STEP_SUMMARY) and
# annotations (an error for each port that failed or was not built and for checks
# that failed, a notice for the outcome), so that it shows on the page of the run
# and in the API; the configure check of tools/build.sh (results/configure-check.txt)
# as a section and an annotation of its own, which do not fail the run.
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
# the curl of azsupport against that of azsupport/php-src (curl-sync-check.txt of the
# workflow): all of it when something differs
if [ -s "$top/curl-sync-check.txt" ] && grep -q 'FAIL' "$top/curl-sync-check.txt"; then
    {
        echo "### $title: the curl of azsupport and that of azsupport/php-src (tools/curl-sync-check.sh)"
        echo
        echo '```'
        cut -c1-240 "$top/curl-sync-check.txt"
        echo '```'
        echo
    } >> "$summary"
    grep 'FAIL' "$top/curl-sync-check.txt" | head -n 30 | while read -r l; do
        printf '::error title=curl-sync-check::%s\n' "$(printf '%s\n' "$l" | escape)"
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
        # those of the compilers, of cmake, of the commands ninja ran and of cargo too
        grep -E ' error:|^error(\[E[0-9]+\])?:|CMake Error|^FAILED: |Error code|^\*\*\*|^===>.*(not found|failed|IGNORE)' "$l" | head -n 15 | cut -c1-240
        echo "..."
        tail -n 15 "$l" | cut -c1-240
    done
    # the libraries of azsupport/azsupport, a line each (tools/azsupport-build.sh), when it was built, with
    # their interfaces (azsupport-results/azsupport_azsupport/interface.txt)
    if [ -s "$res/azsupport-results/azsupport_azsupport/summary.txt" ]; then
        echo
        echo "== azsupport/azsupport: the libraries (azsupport-results/azsupport_azsupport/summary.txt)"
        cut -c1-200 "$res/azsupport-results/azsupport_azsupport/summary.txt"
    fi
    if [ -s "$res/azsupport-results/azsupport_azsupport/interface.txt" ]; then
        echo
        echo "== azsupport/azsupport: the interfaces of its libraries (azsupport-results/azsupport_azsupport/interface.txt)"
        cut -c1-240 "$res/azsupport-results/azsupport_azsupport/interface.txt"
    fi
    # the interfaces of azsupport in this run: what changed, the ABI check, the ports kept by
    # interface (tools/build.sh, results/azsupport-interface.txt)
    if [ -s "$res/azsupport-interface.txt" ]; then
        echo
        echo "== azsupport: the interfaces of its libraries in the hashes of the ports (results/azsupport-interface.txt)"
        cut -c1-400 "$res/azsupport-interface.txt"
    fi
} > "$tmp/build.txt"
echo "==================== build"
cat "$tmp/build.txt"
# the last line "result: ..." of a summary
result() { grep '^result:' "$1" 2>/dev/null | tail -n 1 | sed 's/^result: *//'; }
r="$(result "$res/summary.txt")"
case "$r" in OK) level=notice ;; *) level=error; rc=1 ;; esac
# the plan of the run (AZSUPPORT_PLAN of tools/build.sh, results/plan.txt): first, a section
# and an annotation of its own
if [ -s "$res/plan.txt" ]; then
    echo "==================== the plan"
    cat "$res/plan.txt"
    head -n 60 "$res/plan.txt" | cut -c1-300 > "$tmp/plan.txt"
    annot notice "$title: the plan ($(head -n 1 "$res/plan.txt" | sed 's/^The plan of the run (AZSUPPORT_PLAN): //' | cut -c1-120))" "$tmp/plan.txt"
    {
        echo "### $title: the plan (AZSUPPORT_PLAN: what the run would build)"
        echo
        echo '```'
        cat "$res/plan.txt"
        echo '```'
        echo
    } >> "$summary"
fi
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

# the configure check (AZSUPPORT_CONFIGURE_CHECK of tools/build.sh): results/configure-check.txt
# in the summary (its first 5000 lines), and an annotation of its head (a warning
# when a PHP port has differences); it does not fail the run
if [ -s "$res/configure-check.txt" ]; then
    echo "==================== the configure check"
    cat "$res/configure-check.txt"
    nd="$(sed -n 's/^PHP ports: [0-9]* configured, \([0-9]*\) with differences.*/\1/p' "$res/configure-check.txt")"
    case "$nd" in ''|*[!0-9]*) nd="?"; level=warning ;; 0) level=notice ;; *) level=warning ;; esac
    sed -n '/^PHP ports: /,/^$/p' "$res/configure-check.txt" | grep . | cut -c1-600 > "$tmp/cc.txt"
    annot "$level" "$title: the configure check ($nd PHP ports with differences)" "$tmp/cc.txt"
    {
        echo "### $title: the configure check (each PHP port configured once more, permissive)"
        echo
        echo '```'
        head -n 5000 "$res/configure-check.txt"
        echo '```'
        n="$(wc -l < "$res/configure-check.txt" | tr -d ' ')"
        [ "$n" -gt 5000 ] && echo "($n lines: the rest in results/configure-check.txt)"
        echo
    } >> "$summary"
fi

# the checks of PHP: results/checks.txt (a line per version, written by the workflow)
# and the output of tools/check-php.sh, results/check-php-<version>.txt
if [ -s "$res/checks.txt" ]; then
    {
        cat "$res/checks.txt"
        for f in "$res"/debug-check.txt "$res"/docs-check.txt "$res"/check-php-*.txt "$res"/check-variants-*.txt "$res"/*-results/tests.txt; do
            [ -f "$f" ] || continue
            grep -q '^FAIL' "$f" || continue
            echo
            echo "== ${f#"$res"/}: what failed"
            grep '^FAIL' "$f" | head -n 40 | cut -c1-240
        done
        # the run dependencies that are no packages of the repository (tools/repo-deps-check.sh,
        # a warning for now: aZ, 26.11.2026)
        if [ -f "$res/repo-deps.txt" ] && grep -q '^WARN' "$res/repo-deps.txt"; then
            echo
            echo "== repo-deps.txt: the run dependencies that are no packages of the repository"
            grep '^WARN' "$res/repo-deps.txt" | head -n 60 | cut -c1-400
        fi
    } > "$tmp/php.txt"
    echo "==================== the checks"
    cat "$tmp/php.txt"
    # the FAIL of the tests of tests_nonblocking (build-jail.yml: the line "tests: the FAIL
    # of <names> does not keep the publish") stays in the checks, as a warning
    nb="$(sed -n 's/^tests: the FAIL of \(.*\) does not keep the publish .*/\1/p' "$res/checks.txt" | head -n 1)"
    fl="$(grep ': FAIL' "$res/checks.txt")"
    for t in $nb; do
        fl="$(printf '%s\n' "$fl" | grep -v -F "test $t: FAIL")"
    done
    if [ -n "$fl" ]; then level=error; rc=1
    elif grep -q -e ': FAIL' -e '^repo-deps: WARN' "$res/checks.txt"; then level=warning
    else level=notice; fi
    annot "$level" "$title: the checks of PHP and the tests of the programs" "$tmp/php.txt"
    {
        echo "### $title: the packages installed and checked (PHP, the programs)"
        echo
        echo '```'
        cat "$tmp/php.txt"
        echo '```'
        echo
        for f in "$res"/check-php-*.txt "$res"/check-variants-*.txt; do
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
