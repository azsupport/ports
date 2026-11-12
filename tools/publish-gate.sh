#!/bin/sh
# publish-gate.sh - may the repository of a run of build.yml go out as the release
# when only some ports may change it (the input publish_only of build.yml: the
# automatic publish of yt-dlp-update.yml, aZ 12.11.2026)? A run of main takes the
# files of the release and the cache of the last run, published or not, so its
# repository can carry packages aZ has not let out yet (a rebuild not published);
# then nothing is published, and what the run built goes out with the next publish
# of aZ (the cache of this run keeps it).
#
# The packages of the repository (<name>-<version>.pkg, as the step Publish takes
# them) against those of the release, by name and by the SHA-256 GitHub gives for
# each file: every package that is not in the release, or not with that SHA-256, has
# to be of one of the origins given (the origin of its +COMPACT_MANIFEST), and every
# package of the release the repository has no more has to be another version of one
# of those (one with its name). The catalog (meta, meta.conf, packagesite.pkg,
# data.pkg) is made anew by every run and is not compared.
#
# Usage: sh tools/publish-gate.sh <repository> <release tag> <origin>...
#   (sh tools/publish-gate.sh repo az-fbsd15-amd64-v3 www/yt-dlp www/py-yt-dlp-ejs)
# Environment: GH_TOKEN and GITHUB_REPOSITORY (gh api); PUBLISH_GATE_ASSETS, a file
#   of the files of the release, "<name> sha256:<hex>" a line, in the place of the
#   API (a test).
# On the standard output a section of the report (markdown).
# Exit status: 0 the repository differs from the release by packages of those origins
# alone: publish; 3 it does not differ: nothing to publish; 1 something else differs,
# or there is no release yet: no publish; 2 a wrong call, or the API failed.

set -u
[ $# -ge 3 ] || { echo "usage: sh tools/publish-gate.sh <repository> <release tag> <origin>..." >&2; exit 2; }
dir="$1"; tag="$2"; shift 2
only="$*"
[ -d "$dir" ] || { echo "publish-gate: no directory $dir" >&2; exit 2; }
w="$(mktemp -d "${TMPDIR:-/tmp}/publish-gate.XXXXXX")" || exit 2
trap 'rm -rf "$w"' EXIT
say() { printf '%s\n' "$*"; }
ispkg() { printf '%s\n' "$1" | grep -q -E '^[^/]+-[0-9][^/]*\.pkg$'; }
sha256f() {
    if command -v sha256sum > /dev/null 2>&1; then sha256sum < "$1" | cut -c1-64; else sha256 -q "$1"; fi
}

say "### Publish: only $only (publish_only)"
say ""
if [ -n "${PUBLISH_GATE_ASSETS:-}" ]; then
    cp "$PUBLISH_GATE_ASSETS" "$w/rel" || exit 2
else
    # the release gives all its files (up to the 1000 GitHub allows), with their SHA-256
    if ! gh api "repos/$GITHUB_REPOSITORY/releases/tags/$tag" --jq '.assets[] | .name + " " + (.digest // "")' \
        > "$w/rel" 2> "$w/err"; then
        if grep -q 'HTTP 404' "$w/err"; then
            say "Not published: there is no release $tag yet; its first publish is aZ's."
            exit 1
        fi
        say "Not published: the release $tag could not be read ($(tail -n 1 "$w/err"))."
        exit 2
    fi
fi
: > "$w/relpkg"
while read -r n d; do
    ispkg "$n" && printf '%s %s\n' "$n" "${d:-}" >> "$w/relpkg"
done < "$w/rel"
: > "$w/new"; : > "$w/bad"; : > "$w/names"; : > "$w/gone"
nloc=0
for f in "$dir"/*.pkg; do
    [ -f "$f" ] || continue
    n="${f##*/}"
    ispkg "$n" || continue
    nloc=$((nloc + 1))
    d="$(awk -v n="$n" '$1 == n { print $2; exit }' "$w/relpkg")"
    s="sha256:$(sha256f "$f")"
    [ "$d" = "$s" ] && continue
    if [ -n "$d" ]; then why="another file than that of the release"
    elif awk -v n="$n" '$1 == n { f = 1 } END { exit !f }' "$w/relpkg"; then why="in the release without a SHA-256"
    else why="not in the release"; fi
    # the name and the origin of the package: the first two keys of its manifest, as
    # pkg writes it (those of its dependencies come later); none: not of these
    m="$(tar -xOf "$f" +COMPACT_MANIFEST 2> /dev/null)"
    name="$(printf '%s' "$m" | sed -n 's/^{"name":"\([^"]*\)","origin":"[^"]*".*/\1/p')"
    origin="$(printf '%s' "$m" | sed -n 's/^{"name":"[^"]*","origin":"\([^"]*\)".*/\1/p')"
    ok=0
    for o in $only; do [ -n "$origin" ] && [ "$origin" = "$o" ] && ok=1; done
    if [ "$ok" = 1 ] && [ -n "$name" ]; then
        echo "$n ($origin, $why)" >> "$w/new"
        echo "$name" >> "$w/names"
    else
        echo "$n (${origin:-no origin in its manifest}, $why)" >> "$w/bad"
    fi
done
while read -r n d; do
    [ -f "$dir/$n" ] && continue
    base="$(printf '%s' "$n" | sed 's/-[^-]*\.pkg$//')"
    if grep -qxF "$base" "$w/names"; then echo "$n" >> "$w/gone"
    else echo "$n (in the release, not in this repository)" >> "$w/bad"; fi
done < "$w/relpkg"
say "- the release $tag: $(grep -c . "$w/relpkg") packages; this repository: $nloc"
if [ -s "$w/new" ]; then
    say "- new, of these: $(tr '\n' ';' < "$w/new" | sed 's/;$//; s/;/; /g')"
fi
if [ -s "$w/gone" ]; then
    say "- their versions in the release, away: $(tr '\n' ' ' < "$w/gone" | sed 's/ $//')"
fi
if [ -s "$w/bad" ]; then
    nb="$(grep -c . "$w/bad")"
    say "- **other differences**, $nb:"
    say ""
    say '```'
    head -n 40 "$w/bad"
    [ "$nb" -gt 40 ] && echo "... and $((nb - 40)) more"
    say '```'
    say ""
    say "Not published: the repository of this run differs from the release by more than $only. What this run built goes out with the next publish of aZ (the cache of this run keeps it)."
    exit 1
fi
if [ ! -s "$w/new" ]; then
    say ""
    say "Nothing to publish: the packages of this repository are those of the release."
    exit 3
fi
say ""
say "Published: the repository differs from the release by packages of $only alone."
exit 0
