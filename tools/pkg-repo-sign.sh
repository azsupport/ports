#!/bin/sh
# pkg-repo-sign.sh: the catalog of pkg repo for a directory of packages, signed when
# the key of the repository az is there (FreeBSD; the workflows run it in the VM).
#
#   sh tools/pkg-repo-sign.sh <directory> <log>
#
# AZ_PKG_KEY_FILE: a file with the RSA private key (PEM) of the repository, base64 in
# one line (the workflows: the secret PKG_SIGNING_KEY through base64 -w0 on the runner,
# masked, into the VM with envs: of vmactions, where the first line of each block
# moves it into /root/.az-pkg-key.b64 and unsets it, so that no build or test of the
# VM has it in its environment; the block removes the file at its end). AZ_PKG_KEY,
# the same in the environment, is taken when there is no file. With it the key goes
# into a file of mode 600 in a directory of mode 700 under /tmp (outside the work
# directory, which the VM gives back to the runner), pkg repo <directory> <key> signs the catalog (pkg-repo(8):
# the catalog holds the SHA-256 of each package, so the signature covers them all),
# and the key is removed at once; then the signature is checked without the network:
# the directory as a file:// repository with signature_type "pubkey" and the public
# key of that key (openssl rsa -pubout), pkg update -f of it into a database of its
# own. Without it: pkg repo <directory> unsigned, with a warning; the build goes on.
#
# The output of pkg repo and pkg update goes to <log>; the last line on the screen
# and in <log> says what was done ("pkg repo: signed ..." / "pkg repo: not signed
# ..." / "pkg repo failed: ..."). Exit: 0 done; 1 pkg repo failed, the key is not
# an RSA key, or the signature does not verify.

usage="usage: sh tools/pkg-repo-sign.sh <directory> <log>"
dir="${1:?$usage}"
log="${2:?$usage}"
[ -d "$dir" ] || { echo "pkg repo failed: no directory $dir"; exit 1; }
: > "$log" || { echo "pkg repo failed: cannot write $log"; exit 1; }
line() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$log"; }
fail() { _t="$(tail -n 2 "$log" | tr '\n' ' ')"; line "pkg repo failed: $* ${_t:+($_t)}"; exit 1; }

b64=""
if [ -n "${AZ_PKG_KEY_FILE:-}" ] && [ -s "$AZ_PKG_KEY_FILE" ]; then b64="$(cat "$AZ_PKG_KEY_FILE")"
elif [ -n "${AZ_PKG_KEY:-}" ]; then b64="$AZ_PKG_KEY"; fi
unset AZ_PKG_KEY
if [ -z "$b64" ]; then
    echo "::warning::the repository is not signed: no PKG_SIGNING_KEY"
    pkg repo "$dir" >> "$log" 2>&1 || fail "pkg repo $dir"
    line "pkg repo: not signed (no PKG_SIGNING_KEY)"
    exit 0
fi

kd="$(umask 077 && mktemp -d /tmp/az-pkg-sign.XXXXXX)" || fail "no directory for the key"
trap 'rm -rf "$kd"' EXIT
trap 'exit 1' HUP INT TERM
# the mode 600 only for the key: the catalog pkg repo writes keeps the usual modes
(umask 077 && printf '%s' "$b64" | openssl base64 -d -A > "$kd/az.key") 2>> "$log"
b64=""
chmod 600 "$kd/az.key"
# the forms of the secret: PEM (as in php-src); the base64 of a PEM pasted as the secret
# (decoded once more); CR LF line ends; a PEM on one line (header, body, footer apart
# by blanks). An OpenSSH key is not one pkg can use.
tr -d '\r' < "$kd/az.key" > "$kd/k" && cat "$kd/k" > "$kd/az.key" && rm -f "$kd/k"
if ! grep -q -e '-----BEGIN' "$kd/az.key"; then
    if (umask 077 && openssl base64 -d -A < "$kd/az.key" | tr -d '\r' > "$kd/k") 2>> "$log" &&
        grep -q -e '-----BEGIN' "$kd/k"; then
        cat "$kd/k" > "$kd/az.key"; line "the key: the base64 of a PEM key, decoded once more"
    fi
    rm -f "$kd/k"
fi
if [ "$(awk 'END { print NR }' "$kd/az.key")" -le 1 ] && grep -q -e '-----BEGIN [A-Z ]*-----.*-----END' "$kd/az.key"; then
    awk '{
        match($0, /-----BEGIN [A-Z ]+-----/); h = substr($0, RSTART, RLENGTH); r = substr($0, RSTART + RLENGTH)
        match(r, /-----END [A-Z ]+-----/); f = substr(r, RSTART, RLENGTH); b = substr(r, 1, RSTART - 1)
        gsub(/[ \t]/, "", b); print h
        while (length(b) > 64) { print substr(b, 1, 64); b = substr(b, 65) }
        if (length(b)) print b; print f
    }' "$kd/az.key" > "$kd/k" && cat "$kd/k" > "$kd/az.key" && rm -f "$kd/k"
    line "the key: a PEM key on one line, put back into lines"
fi
if grep -q -e '-----BEGIN OPENSSH PRIVATE KEY' "$kd/az.key"; then
    rm -f "$kd/az.key"; fail "PKG_SIGNING_KEY is an OpenSSH key, not an RSA private key in PEM (ssh-keygen -p -m PEM -f <file> converts a copy)"
fi
line "the key: $(sed -n 's/^-----BEGIN \([A-Z ]*\)-----$/\1/p' "$kd/az.key" | head -n 1 | sed 's/^$/no PEM header/')"
openssl rsa -in "$kd/az.key" -pubout -out "$kd/az.pub" >> "$log" 2>&1 ||
    { rm -f "$kd/az.key"; fail "PKG_SIGNING_KEY is not an RSA private key in PEM"; }
pkg repo "$dir" "$kd/az.key" >> "$log" 2>&1
rc=$?
rm -f "$kd/az.key"
[ "$rc" = 0 ] || fail "pkg repo $dir with the key"

# the check: the catalog as a server with the public key reads it
abs="$(cd "$dir" && pwd)"
mkdir -p "$kd/repos" "$kd/db" "$kd/cache"
printf 'azsign: { url: "file://%s", signature_type: "pubkey", pubkey: "%s", enabled: yes }\n' \
    "$abs" "$kd/az.pub" > "$kd/repos/azsign.conf"
pkg -R "$kd/repos" -o PKG_DBDIR="$kd/db" -o PKG_CACHEDIR="$kd/cache" update -f -r azsign >> "$log" 2>&1 ||
    fail "the signature does not verify with the public key of PKG_SIGNING_KEY (pkg update -f of file://$abs)"
fp="$(openssl dgst -sha256 < "$kd/az.pub" | sed 's/.*= //')"
line "pkg repo: signed, the signature checked (pkg update -f of file://$abs with signature_type pubkey); the public key: SHA-256 $fp (sha256 of az.pub)"
exit 0
