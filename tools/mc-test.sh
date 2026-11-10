#!/bin/sh
# mc-test.sh - test the package mc of the port misc/mc (tools/mc-build.sh), installed
# in the place of that of the official port: what mc --version says it was built with
# (GLib, ncurses(w), libssh2, the editor, the subshell, the codepages, the VFS with
# sftpfs and shell; no X11 and no translations, as misc/mc/files/mc.conf has it), its
# libraries (the base system only), the links mcedit, mcview and mcdiff, its paths
# (mc -F), the extfs helper ubsdtar on a zip that tar of the base system makes (list,
# copyout), and mc itself in a terminal (script(1)): the panels drawn and F10 quits;
# mcview shows a file inside that zip (ubsdtar://, through extfs and the mc.ext.ini of
# the package).
#
# Usage (FreeBSD, the package mc installed): sh tools/mc-test.sh
# Results: mc-results/tests.txt (one line per check, the summary at the end); exit
# status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/mc-results}"
T="${MC_TEST_WORK:-/var/tmp/mc-test}"
P="${MC_PREFIX:-/usr/local}"
mc="$P/bin/mc"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T/home"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
finish() {
    echo "tests: $ok ok, $bad failed" >> "$out"
    cat "$out"
    [ "$bad" = 0 ]
    exit $?
}

[ -x "$mc" ] || { fail "no $mc (the port misc/mc first)"; finish; }
export HOME="$T/home" TERM=xterm SHELL=/bin/csh LANG=C.UTF-8
"$mc" --version > "$T/version.txt" 2>&1 || { fail "mc --version: $(head -n 2 "$T/version.txt" | tr '\n' ' ')"; finish; }
cp "$T/version.txt" "$res/version.txt"
first="$(head -n 1 "$T/version.txt")"
case "$first" in "GNU Midnight Commander "*) pass "$first" ;; *) fail "mc --version: $first" ;; esac
miss=""
for w in "Built with GLib" "Built with ncurses" "Built with libssh2" "With builtin editor" \
        "With subshell support as default" "With support for background operations" "With multiple codepages support"; do
    grep -q "^$w" "$T/version.txt" || miss="$miss; $w"
done
if [ -z "$miss" ]; then pass "built with: $(sed -n 's/^Built with //p' "$T/version.txt" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
else fail "mc --version lacks${miss#;}"; fi
extra=""
for w in "X11 events" "internationalization" "aspell" "ext2fs attributes"; do
    grep -q "$w" "$T/version.txt" && extra="$extra; $w"
done
if [ -z "$extra" ]; then pass "off: X11, translations, Aspell, ext2fs attributes"
else fail "mc --version has what mc.conf turns off:${extra#;}"; fi
vfs=" $(sed -n '/^Virtual File Systems:/{n;p;}' "$T/version.txt" | tr -d ',') "
miss=""
for v in cpiofs tarfs sfs extfs ftpfs sftpfs shell; do
    case "$vfs" in *" $v "*) ;; *) miss="$miss $v" ;; esac
done
if [ -z "$miss" ]; then pass "VFS:$vfs"; else fail "VFS missing:$miss (have:$vfs)"; fi
libs="$(ldd "$mc" | awk 'NR > 1 { print $3 }' | tr '\n' ' ')"
case "$libs" in *"/usr/local/"*) fail "links a library of /usr/local: $libs" ;; *) pass "libraries of the base system only: $libs" ;; esac
miss=""
for l in mcedit mcview mcdiff; do
    [ "$(readlink "$P/bin/$l" 2>/dev/null)" = mc ] || miss="$miss $l"
done
if [ -z "$miss" ]; then pass "bin/mcedit, mcview, mcdiff: links to mc"; else fail "no link to mc:$miss"; fi
"$mc" -F > "$T/paths.txt" 2>&1
miss=""
for d in "$P/etc/mc" "$P/share/mc" "$P/libexec/mc"; do
    grep -q "$d" "$T/paths.txt" || miss="$miss $d"
done
if [ -z "$miss" ]; then pass "mc -F: $P/etc/mc, $P/share/mc, $P/libexec/mc"; else fail "mc -F lacks$miss: $(tr '\n' ' ' < "$T/paths.txt" | cut -c1-200)"; fi

# ubsdtar on a zip of the tar of the base system
h="$P/libexec/mc/extfs.d/ubsdtar"
mkdir -p "$T/src/dir a"
echo "hello from the zip" > "$T/src/dir a/file [1].txt"
echo "second" > "$T/src/b.txt"
if (cd "$T/src" && tar -a -cf "$T/t.zip" .) 2> "$T/zip.err"; then
    if [ ! -x "$h" ]; then
        fail "no $h"
    else
        sh "$h" list "$T/t.zip" > "$T/list.txt" 2>&1
        if grep -q ' dir a/file \[1\]\.txt$' "$T/list.txt" && grep -q ' b\.txt$' "$T/list.txt"; then
            pass "ubsdtar list: $(wc -l < "$T/list.txt" | tr -d ' ') entries of the zip"
        else
            fail "ubsdtar list: $(head -n 3 "$T/list.txt" | tr '\n' ' ')"
        fi
        if sh "$h" copyout "$T/t.zip" "dir a/file [1].txt" "$T/out.txt" && [ "$(cat "$T/out.txt")" = "hello from the zip" ]; then
            pass "ubsdtar copyout: dir a/file [1].txt"
        else
            fail "ubsdtar copyout: $(head -c 200 "$T/out.txt" 2>/dev/null)"
        fi
    fi
else
    fail "tar -a -cf t.zip: $(head -n 2 "$T/zip.err" | tr '\n' ' ')"
fi

# mc in a terminal (script(1), 30 lines of 100), F10 after 3 s; mcview of the file
# in the zip, the same way
tui() {   # <name> <typescript> <command>...
    _n="$1" _t="$2"; shift 2
    (sleep 3; printf '\033[21~'; sleep 3) | timeout 60 script -q "$_t" sh -c 'stty rows 30 cols 100; exec "$@"' sh "$@" > /dev/null 2>&1
    _e=$?
    strings "$_t" 2>/dev/null > "$_t.txt"
    echo "$_e"
}
e="$(tui mc "$T/mc.typescript" "$mc" -u)"
if [ "$e" = 0 ] && grep -q Left "$T/mc.typescript.txt" && grep -q Quit "$T/mc.typescript.txt"; then
    pass "mc in a terminal: the panels drawn (Left, Quit), F10 quit it"
else
    fail "mc in a terminal: exit $e: $(tr '\n' ' ' < "$T/mc.typescript.txt" | cut -c1-200)"
fi
if [ -f "$T/t.zip" ]; then
    e="$(tui mcview "$T/mcview.typescript" "$P/bin/mcview" "$T/t.zip/ubsdtar://dir a/file [1].txt")"
    if [ "$e" = 0 ] && grep -q "hello from the zip" "$T/mcview.typescript.txt"; then
        pass "mcview t.zip/ubsdtar://dir a/file [1].txt: its text shown (extfs, ubsdtar)"
    else
        fail "mcview of the file in the zip: exit $e: $(tr '\n' ' ' < "$T/mcview.typescript.txt" | cut -c1-200)"
    fi
fi
finish
