#!/bin/sh
# runs-save.sh - the packages tools/build.sh made in the VM of build.yml, saved one by one
# while the VM still builds, so that a VM that dies or a job that is stopped loses none of
# them (aZ, 17.11.2026: «почему ты не скачиваешь сразу уже готовый пакет, а чего-то там
# ждёшь пока все не соберутся»). vmactions copies repo/ back only after the script in
# the VM ended well; until then the packages of the run are in packages/All of the VM
# alone.
#
# Usage: sh tools/runs-save.sh <part> [<minutes>]
#
# On the runner of build.yml, in the background (nohup), with GH_TOKEN (contents: write),
# GITHUB_REPOSITORY, GITHUB_RUN_ID, GITHUB_RUN_ATTEMPT, GITHUB_REF_NAME, GITHUB_WORKSPACE
# and RUNNER_TEMP as GitHub Actions sets them. Every <minutes> (5; the first time after
# 2): the files that work/queue/made-* of the VM names (tools/build.sh writes there the
# packages of a port once it built and they are in packages/All), each new one copied
# here with scp, its SHA-256 compared with that of the file in the VM, and uploaded to
# the draft release wip-<part>-<branch>-<run>-<attempt> of this repository (a draft is
# seen only by those who may push). The VM: the first host of ~/.ssh/config that answers
# ssh, as for tools/runs-progress.sh. $RUNNER_TEMP/runs-save.id has the id of the
# release, $RUNNER_TEMP/runs-save.tag its tag, $RUNNER_TEMP/runs-save/saved/ a file per
# package saved. The next run of the branch takes the files of such drafts into repo/
# before the VM starts (build.yml, "The packages saved by runs that did not end"), where
# tools/build.sh keeps the newest package of each origin and builds no port whose
# package has its az_hash; build.yml deletes a draft once the cache of a run has its
# packages. It stops when the VM gave results/ back (results/rc), after 8 hours, or when
# the job ends. A failure here never touches the build: it goes into the log of this
# script (build.yml shows its end) and the package is tried again the next time.

set -u
part="${1:?usage: sh tools/runs-save.sh <part> [<minutes>]}"
every="${2:-5}"
ws="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ws" || exit 0
repo="${GITHUB_REPOSITORY:?}"
t="${RUNNER_TEMP:-/tmp}"
w="$t/runs-save"
mkdir -p "$w/pkgs" "$w/saved" || exit 0
branch="$(printf '%s' "${GITHUB_REF_NAME:-main}" | tr -c 'A-Za-z0-9._-' '-')"
tag="wip-$part-$branch-${GITHUB_RUN_ID:?}-${GITHUB_RUN_ATTEMPT:-1}"
echo "$tag" > "$t/runs-save.tag"
o="-o BatchMode=yes -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=2"
end=$(( $(date +%s) + 8 * 3600 ))
vm=""

log() { echo "$(date -u '+%H:%M:%S') $*"; }

# the id of the draft release of this run, made the first time a package is to go there
release_id() {
    if [ -s "$t/runs-save.id" ]; then cat "$t/runs-save.id"; return 0; fi
    _id="$(gh api -X POST "repos/$repo/releases" -f tag_name="$tag" -f name="$tag" -F draft=true \
        -f body="The packages of run $GITHUB_RUN_ID (attempt ${GITHUB_RUN_ATTEMPT:-1}, $part, $branch), saved as they were built (tools/runs-save.sh); deleted once the cache of a run has them." \
        --jq .id 2> "$w/err")" || { log "the draft $tag was not made: $(tail -n 1 "$w/err")" >&2; return 1; }
    [ -n "$_id" ] || return 1
    echo "$_id" > "$t/runs-save.id"
    # into the log, not into the id the caller takes from stdout
    log "the draft release $tag: id $_id" >&2
    echo "$_id"
}

# upload <release id> <file>: an asset of the draft (GitHub turns a comma of the name into
# a dot, as tools/build.sh does for the release; pkg reads the name from the package)
upload() {
    _n="$(printf '%s' "${2##*/}" | sed 's/%/%25/g; s/+/%2B/g; s/,/%2C/g')"
    curl -sS -f --max-time 1800 -X POST -H "Authorization: Bearer $GH_TOKEN" \
        -H "Accept: application/vnd.github+json" -H "Content-Type: application/octet-stream" \
        --data-binary @"$2" -o "$w/up" \
        "https://uploads.github.com/repos/$repo/releases/$1/assets?name=$_n" 2> "$w/err"
}

# an asset of that name there already (an upload cut off before: GitHub keeps it as
# "starter"): the same size and uploaded, it is saved; else it goes and the next time
# uploads it again
asset_check() {
    _a="$(gh api "repos/$repo/releases/$1/assets?per_page=100" \
        --jq ".[] | select(.name == \"$(printf '%s' "$2" | tr ',' '.')\") | \"\(.id) \(.size) \(.state)\"" 2> /dev/null | head -n 1)"
    [ -n "$_a" ] || return 1
    # shellcheck disable=SC2086
    set -- $_a "$3"
    if [ "$3" = uploaded ] && [ "$2" = "$4" ]; then return 0; fi
    gh api -X DELETE "repos/$repo/releases/assets/$1" > /dev/null 2>&1
    return 1
}

nap=120
while [ "$(date +%s)" -lt "$end" ]; do
    sleep "$nap"
    nap=$(( every * 60 ))
    # the VM gave results/ and repo/ back: nothing is lost any more
    if [ -f results/rc ]; then log "the VM gave its results back: done"; break; fi
    if [ -z "$vm" ]; then
        for h in freebsd $(awk 'tolower($1) == "host" { print $2 }' "$HOME/.ssh/config" 2>/dev/null); do
            # shellcheck disable=SC2086
            if timeout 60 ssh $o "$h" true < /dev/null > /dev/null 2>&1; then vm="$h"; break; fi
        done
        [ -n "$vm" ] || { log "the VM does not answer ssh yet"; continue; }
    fi
    # shellcheck disable=SC2086
    if ! timeout 180 ssh $o "$vm" "cat '$ws'/work/queue/made-* 2>/dev/null; true" < /dev/null > "$w/made.vm" 2> "$w/err"; then
        log "ssh $vm failed: $(tail -n 1 "$w/err")"
        continue
    fi
    LC_ALL=C sort -u "$w/made.vm" > "$w/made"
    while read -r f; do
        b="${f##*/}"
        case "$b" in *.pkg) ;; *) continue ;; esac
        [ -e "$w/saved/$b" ] && continue
        # shellcheck disable=SC2086
        s="$(timeout 300 ssh $o "$vm" "sha256 -q '$f'" < /dev/null 2> "$w/err")"
        [ -n "$s" ] || { log "$b: no SHA-256 from the VM: $(tail -n 1 "$w/err")"; continue; }
        # shellcheck disable=SC2086
        if ! timeout 1800 scp -q $o "$vm:$f" "$w/pkgs/$b.part" < /dev/null 2> "$w/err"; then
            log "$b: scp failed: $(tail -n 1 "$w/err")"
            rm -f "$w/pkgs/$b.part"
            continue
        fi
        if [ "$(sha256sum < "$w/pkgs/$b.part" | cut -c1-64)" != "$s" ]; then
            log "$b: not the SHA-256 of the VM ($s): again the next time"
            rm -f "$w/pkgs/$b.part"
            continue
        fi
        mv -f "$w/pkgs/$b.part" "$w/pkgs/$b"
        id="$(release_id)" || continue
        sz="$(wc -c < "$w/pkgs/$b" | tr -d ' ')"
        if upload "$id" "$w/pkgs/$b" || asset_check "$id" "$b" "$sz"; then
            echo "$s $sz" > "$w/saved/$b"
            log "saved: $b ($sz bytes, SHA-256 $s)"
            rm -f "$w/pkgs/$b"
        else
            log "$b: the upload failed: $(tail -n 1 "$w/err") $(head -c 300 "$w/up" 2> /dev/null)"
        fi
    done < "$w/made"
done
exit 0
