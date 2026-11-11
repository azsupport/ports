#!/bin/sh
# utils-test.sh - test the utilities of the repository az, installed from it: the
# official ports built with the options of aZ (Mk/az-official.mk) and wget and
# rsync with the shared libraries of az (and wget with PCRE2 of devel/pcre2): each
# runs (its version) and has its libraries (none missing; those of the base system,
# but its own of bsddialog and sudo, and those of az and pcre2 of wget and rsync);
# zip makes an archive unzip reads.
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
# libs_of <file> [<library of /usr/local/lib>...]: what it loads (ldd) when every
# library is found and is of the base system, of az (/usr/local/az/lib: our ports
# link each other's shared libraries, aZ 10.11.2026) or one of those named (of our
# other ports, in /usr/local/lib) in libs_out; else why in libs_bad (in this shell,
# not in $( ): a failure has to give the caller its libs_bad)
libs_of() {
    _f="$1"; shift
    libs_bad=""; libs_out=""
    _l="$(ldd "$_f" 2>&1)" || { libs_bad="ldd failed: $(printf '%s\n' "$_l" | tail -n 1)"; return 1; }
    case "$_l" in *"not found"*) libs_bad="$(printf '%s\n' "$_l" | grep 'not found' | head -n 2 | tr '\n' ' ')"; return 1 ;; esac
    _all=""
    for _x in $(printf '%s\n' "$_l" | awk 'NF > 2 && $2 == "=>" { print $3 }'); do
        _all="$_all $_x"
        case "$_x" in
            /lib/* | /usr/lib/* | /usr/local/az/lib/*) continue ;;
            /usr/local/lib/*) for _a in "$@"; do case "${_x##*/}" in "$_a"*) continue 2 ;; esac; done ;;
        esac
        libs_bad="$libs_bad $_x"
    done
    [ -z "$libs_bad" ] || { libs_bad="not of the base system, az or our ports:$libs_bad"; return 1; }
    libs_out="${_all# }"
}
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
for b in zip unzip screen bash yamdi; do libs "$P/bin/$b"; done
# 3proxy 0.9.9 (net/3proxy, 11.11.2026): PCRE2 of devel/pcre2 inside it, the plugins
# by the names of 0.9.5 too (links to the .ld.so files of 0.9.9)
libs "$P/bin/3proxy" libpcre2-8
miss=""
for f in StringsPlugin.so TrafficPlugin.so pamauth.so StringsPlugin.ld.so TrafficPlugin.ld.so PamAuth.ld.so FilePlugin.ld.so TransparentPlugin.ld.so; do
    [ -e "$P/lib/3proxy/$f" ] || miss="$miss $f"
done
if [ -z "$miss" ]; then pass "3proxy: the plugins, by the names of 0.9.5 too"; else fail "3proxy: no$miss in $P/lib/3proxy"; fi
if libs_of "$P/bin/wget" libpcre2-8; then pass "wget: $libs_out"; else fail "wget: $libs_bad"; fi
feat=" $("$P/bin/wget" --version 2>&1 | sed -n '/^[+-]/p' | tr '\n' ' ') "
miss=""
for f in +https +ipv6 +iri +psl +ssl/openssl -nls -ntlm; do
    case "$feat" in *" $f "*) ;; *) miss="$miss $f" ;; esac
done
if [ -z "$miss" ]; then pass "wget: +https +ipv6 +iri +psl +ssl/openssl -nls -ntlm"; else fail "wget lacks$miss (it has:$feat)"; fi
rv="$("$P/bin/rsync" --version 2>&1)"
miss=""
for f in xxh128 zstd lz4 file-flags; do printf '%s\n' "$rv" | grep -q -- "$f" || miss="$miss $f"; done
if [ -z "$miss" ]; then pass "rsync: xxh128, zstd, lz4, file-flags"; else fail "rsync --version lacks$miss"; fi
if libs_of "$P/bin/rsync"; then pass "rsync: $libs_out"; else fail "rsync: $libs_bad"; fi
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
