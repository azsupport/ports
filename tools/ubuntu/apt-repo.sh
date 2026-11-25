#!/bin/sh
# tools/ubuntu/apt-repo.sh - the apt repositories of the releases az-ubuntu<24|22>-amd64-<v3|v2>
# of this repository (aZ, 25.11.2026: «давай тогда уж и свой репозиторий убунты сделаем?
# чтобы по apt и ставилось и обновлялось?»): each release a flat repository (apt: deb
# <address of the release> ./), as the releases az-fbsd* are the repositories of pkg, with
# these files next to those of tools/ubuntu/build.sh:
#
#   az-ffmpeg_<version>_amd64.deb, az-imagemagick7_<version>_amd64.deb
#       the packages of the release under names of their version (~ and the other signs
#       not kept in the names of assets as -); those of the version before stay, so that
#       an apt that read the index just before a publish still finds its files, older
#       ones are deleted. The packages under the names without the version
#       (az-ffmpeg-ubuntu24-amd64-v3.deb...) stay as they are, for curl.
#   Packages, Packages.gz, Packages.xz   the index (apt-ftparchive)
#   Release, Release.gpg, InRelease      its hashes, signed with the key of the secret
#                                        APT_SIGNING_KEY of this repository (OpenPGP,
#                                        armoured, without a passphrase; made by aZ)
#   az-apt.gpg, az-apt.asc               the public key of it (signed-by of apt)
#
# and a part "apt" in the notes of the release. Each index is read by apt before it is
# published (a file: repository of the files made here) and after (the address of the
# release: the redirects of GitHub, the signature, the hash of a package it downloads).
#
# Usage (GitHub Actions: ubuntu-apt.yml; GH_TOKEN, GITHUB_REPOSITORY):
#   sh tools/ubuntu/apt-repo.sh [<tag>...]     default: the four releases, those there are
# Environment:
#   APT_SIGNING_KEY   the private key; without it nothing is published (a warning)
#   AZ_APT_DRY=1      make and check the indexes only, publish nothing; without the key
#                     with a key made for the run
# Exit status: 0 done (or no key), 1 a release failed.

set -u
repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY}"
dry="${AZ_APT_DRY:-}"
[ $# -gt 0 ] || set -- az-ubuntu24-amd64-v3 az-ubuntu24-amd64-v2 az-ubuntu22-amd64-v3 az-ubuntu22-amd64-v2
w="$(mktemp -d "${RUNNER_TEMP:-/tmp}/az-apt.XXXXXX")" || exit 1
say() { printf '[apt %s] %s\n' "$(date -u '+%H:%M:%S')" "$*"; }
warn() { echo "::warning title=apt::$*"; }
err() { echo "::error title=apt::$*"; }

for t in apt-ftparchive gpg gpgv dpkg-deb gh xz gzip; do
    command -v "$t" > /dev/null 2>&1 || { err "no $t"; exit 1; }
done

# the key: into a GnuPG home of this run only
export GNUPGHOME="$w/gnupg"
mkdir -m 700 "$GNUPGHOME" || exit 1
if [ -n "${APT_SIGNING_KEY:-}" ]; then
    printf '%s\n' "$APT_SIGNING_KEY" | gpg --batch --quiet --import 2> "$w/import.log" ||
        { err "the key of APT_SIGNING_KEY does not import: $(tail -n 1 "$w/import.log")"; exit 1; }
elif [ -n "$dry" ]; then
    warn "no APT_SIGNING_KEY: a key of this run only (AZ_APT_DRY)"
    gpg --batch --quiet --pinentry-mode loopback --passphrase '' --quick-gen-key 'azsupport apt test <github@azsupport.com>' \
        rsa4096 sign 1d 2> "$w/gen.log" || { err "no test key: $(tail -n 1 "$w/gen.log")"; exit 1; }
else
    warn "no APT_SIGNING_KEY: the apt repositories are not published (the secret, made by aZ: https://github.com/$repo/settings/secrets/actions)"
    exit 0
fi
fpr="$(gpg --batch --with-colons --list-secret-keys | awk -F: '$1 == "fpr" { print $10; exit }')"
[ -n "$fpr" ] || { err "no secret key in APT_SIGNING_KEY"; exit 1; }
gpg --batch --export "$fpr" > "$w/az-apt.gpg" && gpg --batch --armor --export "$fpr" > "$w/az-apt.asc" || exit 1
say "key $fpr ($(gpg --batch --with-colons --list-keys "$fpr" | awk -F: '$1 == "uid" { print $10; exit }'))"

# aptq <directory> <sources line> <apt-get or apt-cache> <arguments...>: apt with only this
# source and its own lists (nothing of the system's sources); as root without the user
# _apt of its downloads, which cannot read the directories of mktemp
aptq() {
    q="$1" line="$2" tool="$3"; shift 3
    sb=""; [ "$(id -u)" != 0 ] || sb="-o APT::Sandbox::User=root"
    mkdir -p "$q/lists/partial" "$q/archives/partial" "$q/etc/preferences.d" &&
        printf '%s\n' "$line" > "$q/etc/sources.list" &&
        # shellcheck disable=SC2086
        "$tool" -q $sb -o Dir::State::Lists="$q/lists" -o Dir::Cache="$q" -o Dir::Cache::archives="$q/archives" \
            -o Dir::Etc::SourceList="$q/etc/sources.list" -o Dir::Etc::SourceParts=/nonexistent \
            -o Dir::Etc::PreferencesParts="$q/etc/preferences.d" -o Debug::NoLocking=1 -o APT::Get::List-Cleanup=0 \
            -o Acquire::Retries=3 "$@"
}
# check_apt <directory> <sources line> <ffmpeg version> <imagemagick7 version> [download]:
# apt reads the index and takes these versions; with download, it also fetches az-ffmpeg
check_apt() {
    q="$1" line="$2" vf="$3" vi="$4" dl="${5:-}"
    aptq "$q" "$line" apt-get update > "$q.update.log" 2>&1 || { echo "apt-get update: $(grep -E '^(E|W):' "$q.update.log" | head -n 3 | tr '\n' ' ')"; return 1; }
    if grep -E '^(E|W):' "$q.update.log" > /dev/null; then echo "apt-get update: $(grep -E '^(E|W):' "$q.update.log" | head -n 3 | tr '\n' ' ')"; return 1; fi
    for pv in "az-ffmpeg $vf" "az-imagemagick7 $vi"; do
        set -- $pv
        c="$(aptq "$q" "$line" apt-cache policy "$1" 2>&1 | sed -n 's/^ *Candidate: //p')"
        [ "$c" = "$2" ] || { echo "apt-cache policy $1: candidate ${c:-none}, not $2"; return 1; }
    done
    if [ -n "$dl" ]; then
        (cd "$q" && aptq "$q" "$line" apt-get download az-ffmpeg > "$q.download.log" 2>&1) ||
            { echo "apt-get download az-ffmpeg: $(tail -n 2 "$q.download.log" | tr '\n' ' ')"; return 1; }
    fi
    return 0
}

ubuntu_of() { case "$1" in ubuntu24) echo 24.04 ;; ubuntu22) echo 22.04 ;; esac; }
codename_of() { case "$1" in ubuntu24) echo noble ;; ubuntu22) echo jammy ;; esac; }
rc=0
for tag in "$@"; do
    case "$tag" in az-ubuntu2[24]-amd64-v[23]) ;; *) err "$tag: not az-ubuntu<24|22>-amd64-<v3|v2>"; rc=1; continue ;; esac
    rel="${tag#az-}"; rel="${rel%%-amd64-*}"
    lvl="${tag##*-}"
    ubuntu="$(ubuntu_of "$rel")"
    d="$w/$tag"
    mkdir -p "$d/stable" "$d/idx" || exit 1
    if ! gh api "repos/$repo/releases/tags/$tag" > "$d/release.json" 2> "$d/release.err"; then
        say "$tag: no release ($(tail -n 1 "$d/release.err")), left out"
        continue
    fi
    rid="$(gh api "repos/$repo/releases/tags/$tag" --jq .id)"
    gh api "repos/$repo/releases/$rid/assets?per_page=100" --jq '.[] | [.id, .name, .created_at] | @tsv' > "$d/assets.tsv" ||
        { err "$tag: no list of its assets"; rc=1; continue; }
    # the packages of the release (the names without the version) and their .sha256
    ok=1
    for p in az-ffmpeg az-imagemagick7; do
        f="$p-$rel-amd64-$lvl.deb"
        gh release download "$tag" -R "$repo" -D "$d/stable" -p "$f" -p "$f.sha256" --clobber > /dev/null 2>&1 &&
            (cd "$d/stable" && sha256sum -c --quiet "$f.sha256") || { err "$tag: $f and its .sha256 do not download or do not match"; ok=""; }
    done
    [ -n "$ok" ] || { rc=1; continue; }
    # under the names of their version, into the index
    : > "$d/new.txt"
    vf="" vi=""
    for p in az-ffmpeg az-imagemagick7; do
        f="$d/stable/$p-$rel-amd64-$lvl.deb"
        v="$(dpkg-deb -f "$f" Version)"
        a="$(dpkg-deb -f "$f" Architecture)"
        [ "$(dpkg-deb -f "$f" Package)" = "$p" ] && [ -n "$v" ] && [ "$a" = amd64 ] ||
            { err "$tag: ${f##*/} is not $p for amd64"; ok=""; break; }
        n="${p}_$(printf '%s' "$v" | tr -c 'A-Za-z0-9.-' '-')_$a.deb"
        cp "$f" "$d/idx/$n" || { ok=""; break; }
        awk -F '\t' -v n="$n" '$2 == n { found = 1 } END { exit !found }' "$d/assets.tsv" || echo "$n" >> "$d/new.txt"
        case "$p" in az-ffmpeg) vf="$v" ;; az-imagemagick7) vi="$v" ;; esac
    done
    [ -n "$ok" ] || { rc=1; continue; }
    (
        cd "$d/idx" || exit 1
        apt-ftparchive packages . > Packages 2> ../packages.log &&
            [ "$(grep -c '^Package: ' Packages)" = 2 ] &&
            gzip -9nk Packages && xz -9k Packages &&
            apt-ftparchive -o APT::FTPArchive::Release::Origin=azsupport -o "APT::FTPArchive::Release::Label=$tag" \
                -o "APT::FTPArchive::Release::Suite=$tag" -o "APT::FTPArchive::Release::Codename=$(codename_of "$rel")" \
                -o APT::FTPArchive::Release::Architectures=amd64 \
                -o "APT::FTPArchive::Release::Description=FFmpeg and ImageMagick 7 of azsupport/ports for Ubuntu $ubuntu, x86-64-$lvl" \
                release . > ../Release && mv ../Release Release &&
            gpg --batch --yes --pinentry-mode loopback --passphrase '' --local-user "$fpr" --digest-algo SHA512 --clearsign -o InRelease Release &&
            gpg --batch --yes --pinentry-mode loopback --passphrase '' --local-user "$fpr" --digest-algo SHA512 -abs -o Release.gpg Release &&
            gpgv --quiet --keyring "$w/az-apt.gpg" InRelease 2> ../gpgv.log &&
            gpgv --quiet --keyring "$w/az-apt.gpg" Release.gpg Release 2>> ../gpgv.log &&
            cp "$w/az-apt.gpg" "$w/az-apt.asc" .
    ) || { err "$tag: the index is not made or not signed ($(tail -n 1 "$d/packages.log" "$d/gpgv.log" 2>/dev/null | tr '\n' ' '))"; rc=1; continue; }
    # apt reads it as a file: repository
    if ! m="$(check_apt "$d/apt-file" "deb [signed-by=$w/az-apt.gpg] file:$d/idx ./" "$vf" "$vi")"; then
        err "$tag: apt does not take the index made here: $m"; rc=1; continue
    fi
    say "$tag: az-ffmpeg $vf, az-imagemagick7 $vi; index ok (apt, file:)"
    if [ -n "$dry" ]; then
        say "$tag: AZ_APT_DRY, not published; new: $(tr '\n' ' ' < "$d/new.txt")"
        continue
    fi
    # the packages of the version first, then the index (its files in one go)
    if [ -s "$d/new.txt" ]; then
        # shellcheck disable=SC2046
        (cd "$d/idx" && gh release upload "$tag" -R "$repo" $(cat "$d/new.txt")) > "$d/upload.log" 2>&1 ||
            { err "$tag: the packages do not upload: $(tail -n 2 "$d/upload.log" | tr '\n' ' ')"; rc=1; continue; }
    fi
    (cd "$d/idx" && gh release upload "$tag" -R "$repo" --clobber Packages Packages.gz Packages.xz Release Release.gpg InRelease az-apt.gpg az-apt.asc) \
        > "$d/upload.log" 2>&1 || { err "$tag: the index does not upload: $(tail -n 2 "$d/upload.log" | tr '\n' ' ')"; rc=1; continue; }
    gh api "repos/$repo/releases/$rid/assets?per_page=100" --jq '.[] | [.id, .name, .created_at] | @tsv' > "$d/assets.tsv"
    while read -r n; do
        awk -F '\t' -v n="$n" '$2 == n { found = 1 } END { exit !found }' "$d/assets.tsv" ||
            { err "$tag: the asset $n is not there after the upload (GitHub renamed it?)"; rc=1; }
    done < "$d/new.txt"
    # the address of the release, as a server reads it
    url="https://github.com/$repo/releases/download/$tag"
    if ! m="$(check_apt "$d/apt-url" "deb [signed-by=$w/az-apt.gpg] $url ./" "$vf" "$vi" download)"; then
        err "$tag: apt does not take $url: $m"; rc=1; continue
    fi
    say "$tag: published; apt takes $url (az-ffmpeg downloaded: $(ls "$d/apt-url" | grep -c '\.deb$') file)"
    # the versions of the packages before the one before: deleted
    for p in az-ffmpeg az-imagemagick7; do
        awk -F '\t' -v p="$p" 'index($2, p "_") == 1 && $2 ~ /_amd64\.deb$/ { print $3 "\t" $1 "\t" $2 }' "$d/assets.tsv" |
            LC_ALL=C sort -r | sed -n '3,$p' | while IFS="$(printf '\t')" read -r _c id n; do
                if gh api -X DELETE "repos/$repo/releases/assets/$id" > /dev/null 2>&1; then say "$tag: $n deleted (older than the two last)"
                else warn "$tag: $n not deleted"; fi
            done
    done
    # the part apt of the notes of the release, in the place of the one before
    gh api "repos/$repo/releases/$rid" --jq .body > "$d/notes.md" 2>/dev/null || : > "$d/notes.md"
    awk '/^<!-- apt -->$/ { skip = 1 } !skip { print } /^<!-- \/apt -->$/ { skip = 0 }' "$d/notes.md" > "$d/notes-new.md"
    {
        echo '<!-- apt -->'
        echo
        echo "The apt repository of this release (Ubuntu $ubuntu, x86-64-$lvl), signed with the key $fpr:"
        echo
        echo '```'
        echo "sudo install -d -m 0755 /etc/apt/keyrings"
        echo "sudo curl -fsSL -o /etc/apt/keyrings/az-apt.gpg $url/az-apt.gpg"
        echo "echo 'deb [signed-by=/etc/apt/keyrings/az-apt.gpg] $url ./' | sudo tee /etc/apt/sources.list.d/az.list"
        echo "sudo apt-get update"
        echo "sudo apt-get install -y az-ffmpeg az-imagemagick7"
        echo '```'
        echo
        echo "The updates then come with apt-get upgrade."
        echo
        echo '<!-- /apt -->'
    } >> "$d/notes-new.md"
    gh api -X PATCH "repos/$repo/releases/$rid" -F "body=@$d/notes-new.md" > /dev/null 2>&1 || warn "$tag: the notes are not updated"
done
exit "$rc"
