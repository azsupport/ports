#!/bin/sh
# utils-test.sh - test the utilities of the repository az, the official ports built
# as they are with the options of aZ (Mk/az-official.mk), installed from the
# repository: each runs (its version) and has its libraries (none missing; those of
# the base system, but the official ones its port takes: lz4, xxhash and zstd of
# rsync, its own of bsddialog and sudo); zip makes an archive unzip reads.
#
# Usage (FreeBSD, the packages installed): sh tools/utils-test.sh
# Results: utils-results/tests.txt (one line per check, the summary at the end);
# exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/utils-results}"
T="${UTILS_TEST_WORK:-/var/tmp/utils-test}"
P=/usr/local
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
export LANG=C.UTF-8

# ver <name> <text of its version> <command>...: the first line with the text
ver() {
    name="$1"; want="$2"; shift 2
    v="$("$@" 2>&1 | grep -m 1 "$want")"
    if [ -n "$v" ]; then pass "$name: $v"; else fail "$name: no \"$want\" in what $* says: $("$@" 2>&1 | head -n 1)"; fi
}
# libs <file> [<library>...]: none missing, those of /lib and /usr/lib but the ones named
libs() {
    f="$1"; shift
    [ -e "$f" ] || { fail "no $f"; return; }
    l="$(ldd "$f" 2>&1)"
    case "$l" in *"not found"*) fail "${f##*/}: $(printf '%s\n' "$l" | grep 'not found' | head -n 2 | tr '\n' ' ')"; return ;; esac
    other=""
    for x in $(printf '%s\n' "$l" | awk 'NR > 1 && $3 ~ /^\// { print $3 }'); do
        case "$x" in /lib/* | /usr/lib/*) continue ;; esac
        a_=""
        for a in "$@"; do case "${x##*/}" in "$a"*) a_=1 ;; esac; done
        [ -n "$a_" ] || other="$other $x"
    done
    if [ -z "$other" ]; then pass "${f##*/}: $(printf '%s\n' "$l" | awk 'NR > 1 && $3 ~ /^\// { print $3 }' | sed 's#.*/##' | tr '\n' ' ' | sed 's/ $//')"
    else fail "${f##*/}: libraries outside the base system:$other"; fi
}

ver zip "This is Zip 3.0" "$P/bin/zip" -v
ver unzip "UnZip 6.00" "$P/bin/unzip" -v
ver wget "GNU Wget 1.25" "$P/bin/wget" --version
ver rsync "rsync  version 3" "$P/bin/rsync" --version
ver screen "Screen version 5" "$P/bin/screen" -v
ver sudo "Sudo version 1.9" "$P/bin/sudo" -V
ver bash "GNU bash, version 5" "$P/bin/bash" --version
ver bsddialog "1\.1" "$P/bin/bsddialog" --version
ver portmaster "3\.35" "$P/sbin/portmaster" --version
for b in zip unzip wget screen bash yamdi 3proxy; do libs "$P/bin/$b"; done
libs "$P/bin/rsync" liblz4 libxxhash libzstd
libs "$P/bin/sudo" libsudo_util
libs "$P/bin/bsddialog" libbsddialog
libs "$P/lib/snmp_ucd.so"

mkdir -p "$T/src/dir a"
printf 'zip of azsupport\n' > "$T/src/dir a/file 1.txt"
if (cd "$T/src" && "$P/bin/zip" -q -r "$T/t.zip" .) > "$T/zip.log" 2>&1 &&
        "$P/bin/unzip" -q -o -d "$T/out" "$T/t.zip" > "$T/unzip.log" 2>&1 &&
        cmp -s "$T/src/dir a/file 1.txt" "$T/out/dir a/file 1.txt"; then
    pass "zip -r, unzip: the file as it was"
else
    fail "zip, unzip: $(cat "$T/zip.log" "$T/unzip.log" 2> /dev/null | head -n 3 | tr '\n' ' ')"
fi

echo "tests: $ok ok, $bad failed" >> "$out"
cat "$out"
[ "$bad" = 0 ]
