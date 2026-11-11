#!/bin/sh
# runs-progress.sh - the progress of a build that is running: GitHub gives the log of
# a job only when the job ends, so while the VM of build.yml builds, this reads the
# lines tools/build.sh writes there (results/progress.log: its screen lines with the
# time, the result of every port among them) every few minutes and commits a short
# progress report into the branch "runs" of azsupport/azsupport with
# tools/runs-report.sh: <repository>-<workflow>/<date>/<run id>-<part>-progress.md,
# next to the report of the run, which takes its place when the run ends
# (aZ, 11.11.2026: "а почему у тебя нет механизма прогресс сборки смотреть?").
#
# Usage: sh tools/runs-progress.sh <part> [<minutes>]   (in the background: nohup ... &)
#   <part>     the part of the run (x86-64-v3, x86-64-v2...)
#   <minutes>  how often (10)
# Environment: RUNS_TOKEN (tools/runs-report.sh), GITHUB_WORKSPACE (the tree, at the
# same path in the VM of vmactions), GITHUB_* as GitHub Actions sets them;
# RUNS_PROGRESS_SLEEP the seconds between two looks instead of <minutes> (a test).
# The VM: the first host of ~/.ssh/config that answers ssh (vmactions writes it for
# its VM, "freebsd"). It ends when the VM has given results/rc back to the runner,
# after 8 hours, or when the job ends (GitHub stops what a job left running). A
# failure here never touches the build: what it could not do goes into the progress
# report itself, or into its log on the runner.

set -u
part="${1:?usage: sh tools/runs-progress.sh <part> [<minutes>]}"
every="${2:-10}"
ws="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ws" || exit 0
w="$(mktemp -d)"
trap 'rm -rf "$w"' EXIT
end=$(( $(date +%s) + 8 * 3600 ))
started="$(date -u '+%H:%M')"
vm=""
last=""
o="-o BatchMode=yes -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=2"

while [ "$(date +%s)" -lt "$end" ]; do
    sleep "${RUNS_PROGRESS_SLEEP:-$(( every * 60 ))}"
    # the VM gave its results back: the report of the run comes next
    [ -f results/rc ] && break
    if [ -z "$vm" ]; then
        for h in freebsd $(awk 'tolower($1) == "host" { print $2 }' "$HOME/.ssh/config" 2>/dev/null); do
            # shellcheck disable=SC2086
            if ssh $o "$h" true < /dev/null > /dev/null 2>&1; then vm="$h"; break; fi
        done
    fi
    {
        echo "## Progress of the build (tools/runs-progress.sh, every $every minutes)"
        echo
        echo "- the reporter since: $started UTC; now: $(date -u '+%H:%M') UTC"
        if [ -z "$vm" ]; then
            echo "- the VM does not answer ssh yet (hosts: freebsd $(awk 'tolower($1) == "host" { printf "%s ", $2 }' "$HOME/.ssh/config" 2>/dev/null))"
        else
            # shellcheck disable=SC2086
            if ssh $o "$vm" "cat '$ws/results/queue.txt' 2>/dev/null | wc -l; echo ====; cat '$ws/results/progress.log' 2>/dev/null" \
                < /dev/null > "$w/vm" 2> "$w/err"; then
                total="$(sed -n 1p "$w/vm" | tr -d ' ')"
                sed '1,/^====$/d' "$w/vm" > "$w/log"
                # the result lines of tools/build.sh: "[build HH:MM:SS] <origin>: OK|FAIL|SKIP ..."
                grep -E '^\[build [0-9:]+\] [^ ]+: (OK|FAIL|SKIP) ' "$w/log" > "$w/done" || :
                nd="$(wc -l < "$w/done" | tr -d ' ')"
                nok="$(grep -c ': OK ' "$w/done")"
                nfail="$(grep -c ': FAIL ' "$w/done")"
                nkept="$(grep -c 'in the repository already' "$w/done")"
                nskip=$(( nd - nok - nfail - nkept ))
                echo "- ports: $nd of ${total:-?} done: built $nok, kept from the repository $nkept, failed $nfail, not built $nskip"
                # building now: started ("make package" with AZ_JOBS above 1, "<origin>:
                # <pkgname> (<why>)" one by one) and with no result line yet
                grep -E '^\[build [0-9:]+\] [^ ]+: make package \(logs/' "$w/log" | awk '{ sub(":$", "", $3); print $3, substr($2, 1, 5) }' > "$w/run" || :
                now=""
                while read -r po pt; do
                    grep -qE "^\[build [0-9:]+\] $po: (OK|FAIL|SKIP) " "$w/done" || now="$now $po (since $pt)"
                done < "$w/run"
                echo "- building now:${now:- -}"
                if [ "$nfail" != 0 ]; then
                    echo "- failed:"
                    grep ': FAIL ' "$w/done" | cut -c 1-300 | sed 's/^/  - /'
                fi
                echo
                echo "The last lines of tools/build.sh in the VM (results/progress.log):"
                echo
                tail -n 15 "$w/log" | cut -c 1-300 | sed 's/^/    /'
            else
                echo "- ssh $vm failed: $(tail -n 1 "$w/err" | cut -c 1-200)"
            fi
        fi
    } > "$w/progress.md"
    # committed when it says something new (not for the time alone)
    cur="$(grep -v '^- the reporter since' "$w/progress.md" | cksum)"
    if [ "$cur" != "$last" ]; then
        sh tools/runs-report.sh "$w/progress.md" "$part-progress" && last="$cur"
    fi
done
