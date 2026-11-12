#!/bin/sh
# mc-test.sh - test the package mc of the port misc/mc (tools/mc-build.sh), installed
# in the place of that of the official port: what mc --version says it was built with
# (GLib, ncurses(w), libssh2, the editor, the subshell, the codepages, the VFS with
# sftpfs and shell; no X11 and no translations, as misc/mc/files/mc.conf has it), its
# libraries (the base system, the shared ones of az, glib and pcre2), the links mcedit, mcview and mcdiff, its paths
# (mc -F), the extfs helper ubsdtar on a zip that tar of the base system makes (list,
# as mc reads it, copyout) and on a hard link in ISO 9660, and mc itself in a
# terminal (script(1)): the panels drawn and F10 quits;
# mcview shows a file inside that zip (ubsdtar://, through extfs and the mc.ext.ini of
# the package). The patches of misc/mc/files, through mc in that terminal: Enter on
# a tar entry with a name of 1504 bytes opens it (ext-cd-overflow), F5 with a Reget
# copies the next file whole (copy-reget), a click on Quit with TERM=xterm quits
# (mouse-sgr-ncurses), the subshell of tcsh enters a directory with a space, quotes,
# $, ! and Cyrillic, keeps the prompt of ~/.tcshrc and its exit ends mc with status 0
# (subshell-tcsh-prompt, subshell-eof), the prompt of bash in a directory named in
# CP1251 (prompt-invalid-utf8; when bash is installed), the history of tcsh after five
# cd of a panel, a command at mc's command line, the user menu and a command in Ctrl-O
# (subshell-tcsh-quiet: only the typed commands in "history" and ~/.history, the
# directories in the Dir Hist of mc's history file), num_history_items_recorded=96 in
# a new ~/.config/mc/ini (history-items-96), F5 inside a ZFS pool on an md device
# clones the blocks, not with file_cloning=false, a copy to another file system is
# whole (copy-clone-1). Checked by hand only (no
# server or shell for them here): ftp-reconnect, ftp-netrc-password (an FTP server
# with an idle timeout and ~/.netrc), subshell-fd (dash, ksh, mksh), mouse-drag-crash
# (a drag below a panel that is not full); parse-ls-short-name has no visible effect.
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
if libs_of "$mc" libglib-2.0 libpcre2-8; then pass "libraries of the base system, az, glib and pcre2: $libs_out"
else fail "libraries: $libs_bad"; fi
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
        if grep -q ' dir a/file \[1\]\.txt$' "$T/list.txt" && grep -q ' b\.txt$' "$T/list.txt" &&
                [ -z "$(awk '$2 < 1' "$T/list.txt")" ]; then
            pass "ubsdtar list: $(wc -l < "$T/list.txt" | tr -d ' ') entries of the zip, each with 1 link or more (mc takes no 0)"
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
# ubsdtar on a zip of Windows: its names in CP866 without the UTF-8 flag (the bytes
# of "Документы/отчёт.txt" in CP866; its data "привет" in UTF-8), which tar -tv
# gives as \NNN: read in CP866 (MC_UBSDTAR_ZIP_CHARSET)
if [ -x "$h" ]; then
    {
    printf '\120\113\003\004\024\000\000\000\000\000\307\132\153\135\072\034\235\243'
    printf '\015\000\000\000\015\000\000\000\023\000\000\000\204\256\252\343\254\245'
    printf '\255\342\353\057\256\342\347\361\342\056\164\170\164\320\277\321\200\320'
    printf '\270\320\262\320\265\321\202\012\120\113\001\002\024\003\024\000\000\000'
    printf '\000\000\307\132\153\135\072\034\235\243\015\000\000\000\015\000\000\000'
    printf '\023\000\000\000\000\000\000\000\000\000\000\000\200\001\000\000\000\000'
    printf '\204\256\252\343\254\245\255\342\353\057\256\342\347\361\342\056\164\170'
    printf '\164\120\113\005\006\000\000\000\000\001\000\001\000\101\000\000\000\076'
    printf '\000\000\000\000\000'
    } > "$T/win.zip"
    LC_ALL=C.UTF-8 sh "$h" list "$T/win.zip" > "$T/win-list.txt" 2>&1
    if grep -q ' Документы/отчёт\.txt$' "$T/win-list.txt"; then
        pass "ubsdtar list: a zip of Windows with names in CP866 (Документы/отчёт.txt)"
    else
        fail "ubsdtar list of a zip with names in CP866: $(head -n 2 "$T/win-list.txt" | tr '\n' ' ')"
    fi
    if LC_ALL=C.UTF-8 sh "$h" copyout "$T/win.zip" "Документы/отчёт.txt" "$T/win-out.txt" &&
            [ "$(cat "$T/win-out.txt")" = "привет" ]; then
        pass "ubsdtar copyout: Документы/отчёт.txt of a zip with names in CP866"
    else
        fail "ubsdtar copyout of a zip with names in CP866: $(head -c 200 "$T/win-out.txt" 2>/dev/null)"
    fi
fi

# ubsdtar on a hard link in ISO 9660 (tar of the base system writes it): NAME -> FILE
# in the list, the data of FILE on copyout
mkdir -p "$T/iso/sub"
echo "data of a" > "$T/iso/a.txt"
ln "$T/iso/a.txt" "$T/iso/sub/hard.txt"
if [ ! -x "$h" ]; then
    :
elif (cd "$T/iso" && tar --format iso9660 -cf "$T/t.iso" .) 2> "$T/iso.err"; then
    sh "$h" list "$T/t.iso" > "$T/isolist.txt" 2>&1
    sh "$h" copyout "$T/t.iso" sub/hard.txt "$T/hard.txt" 2>> "$T/isolist.txt"
    if grep -q ' sub/hard\.txt -> a\.txt$' "$T/isolist.txt" && [ "$(cat "$T/hard.txt" 2>/dev/null)" = "data of a" ]; then
        pass "ubsdtar on ISO 9660: the hard link sub/hard.txt -> a.txt, the data of a.txt on copyout"
    else
        fail "ubsdtar on ISO 9660 with a hard link: $(tr '\n' ' ' < "$T/isolist.txt" | cut -c1-200) [$(cat "$T/hard.txt" 2>/dev/null)]"
    fi
else
    fail "tar --format iso9660: $(head -n 2 "$T/iso.err" | tr '\n' ' ')"
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

# The patches of misc/mc/files (each its header), through mc in a terminal as above:
# keys_run <typescript> <keys> <command>...: the keys (sh commands: sleeps and printfs)
# into the terminal; keys_exit its exit status (a signal: that of mc, as script(1)
# gives it), keys_secs its seconds, <typescript>.txt its strings
keys_run() {
    _t="$1" _k="$2"; shift 2
    keys_exit="?" keys_secs=0
    rm -f "$_t.rc"
    (eval "$_k") | {
        _s0=$(date +%s)
        timeout 60 script -q "$_t" sh -c 'stty rows 30 cols 100; exec "$@"' sh "$@" > /dev/null 2>&1
        echo "$? $(( $(date +%s) - _s0 ))" > "$_t.rc"
    }
    [ -f "$_t.rc" ] && read -r keys_exit keys_secs < "$_t.rc"
    strings "$_t" 2>/dev/null > "$_t.txt"
}
seen() { tr '\n' ' ' < "$1.txt" | cut -c1-160; }
down='\033OB' enter='\r' f10='\033[21~'
# ext-cd-overflow.patch: Enter on a tar entry with a name of 1504 bytes, whose action
# is "%cd %p/utar://": mc 4.8.33 copied it into a static buffer of 1 KB (SIGSEGV)
mkdir -p "$T/ov"
echo "inside the inner tar" > "$T/ov/inner.txt"
long="$(printf '%01500d' 0 | tr 0 L).tar"
if (cd "$T/ov" && tar -cf inner.tar inner.txt &&
        printf '#mtree\n%s type=file mode=0644 uid=0 gid=0 time=0 contents=%s\n' "$long" "$T/ov/inner.tar" |
        tar -cf outer.tar --format pax @-) 2> "$T/ov.err"; then
    keys_run "$T/ov.typescript" "sleep 3; printf '$down'; sleep 1; printf '$enter'; sleep 2; printf '$f10'; sleep 2" \
        "$mc" -u "$T/ov/outer.tar/utar://"
    if [ "$keys_exit" = 0 ] && grep -q 'inner\.txt' "$T/ov.typescript.txt"; then
        pass "Enter on a tar entry with a name of 1504 bytes (%cd %p/utar://): its inner tar opened (inner.txt)"
    else
        fail "Enter on a tar entry with a name of 1504 bytes: exit $keys_exit (11: SIGSEGV): $(seen "$T/ov.typescript")"
    fi
else
    fail "a tar with an entry of 1504 bytes (tar @- of mtree): $(head -n 2 "$T/ov.err" | tr '\n' ' ')"
fi
# copy-reget.patch: a and b copied (F5) where the destination has half of a: "Reget"
# for a, then b whole (mc 4.8.33 copied b from the offset of a)
mkdir -p "$T/rg/src" "$T/rg/dst"
printf '%01000d' 0 | tr 0 A > "$T/rg/src/a"
printf '%01000d' 0 | tr 0 B > "$T/rg/src/b"
printf '%0500d' 0 | tr 0 A > "$T/rg/dst/a"
keys_run "$T/rg.typescript" "sleep 3; printf '$down'; sleep 0.5; printf '\033[2~'; sleep 0.5; printf '\033[2~'; sleep 0.5;
        printf '\033[15~'; sleep 1.5; printf '$enter'; sleep 2; printf r; sleep 2; printf '$f10'; sleep 2" \
    "$mc" -u "$T/rg/src" "$T/rg/dst"
if cmp -s "$T/rg/src/a" "$T/rg/dst/a" && cmp -s "$T/rg/src/b" "$T/rg/dst/b"; then
    pass "F5 of a and b, Reget of a (500 of 1000 bytes there): a and b whole"
else
    fail "F5 of a and b with Reget of a: exit $keys_exit, sizes a $(wc -c < "$T/rg/dst/a" | tr -d ' '), b $(wc -c < "$T/rg/dst/b" 2>/dev/null | tr -d ' ') (1000 each): $(seen "$T/rg.typescript")"
fi
# mouse-sgr-ncurses.patch: TERM=xterm (kmous=\E[< in terminfo since ncurses 6.1) and a
# click (SGR mode, as mc turns it on) on "10Quit" of the button bar: mc quits at once
km="$(infocmp -1 xterm 2>/dev/null | sed -n 's/^[[:space:]]*kmous=\(.*\),$/\1/p')"
keys_run "$T/click.typescript" "sleep 3; printf '\033[<0;95;30M'; sleep 0.3; printf '\033[<0;95;30m'; sleep 6; printf '$f10'; sleep 2" \
    "$mc" -u
if [ "$keys_exit" = 0 ] && [ "$keys_secs" -le 6 ]; then
    pass "TERM=xterm (kmous ${km:-?}): a click on Quit quit mc (${keys_secs}s)"
else
    fail "TERM=xterm (kmous ${km:-?}): a click on Quit did not quit mc: exit $keys_exit after ${keys_secs}s (F10 at 9s)"
fi
# The subshell of tcsh (/bin/csh, SHELL above), with history, savehist (merge), histdup
# (erase) and noclobber in ~/.tcshrc and an old event in ~/.history: five cd of the
# left panel (Enter; into a directory with a space, quotes, $, ! and Cyrillic, into d2
# and back), a command at the command line of mc, the user menu (F2, its entry m),
# then in Ctrl-O a command, history and pwd into files, exit.
# subshell-tcsh-quiet.patch: the history of tcsh, in memory and in ~/.history after
# the exit, has the old event and the three typed commands and none of mc's lines (its
# init, the cd, the command of the user menu; mc 4.8.33: all of them), and the "Dir
# Hist" of the panel in mc's history file has the directories; subshell-tcsh-prompt
# (the prompt of ~/.tcshrc stays), subshell-eof (exit in Ctrl-O ends mc with status 0;
# mc 4.8.33: "read (subshell_pty...)" and status 1), the cd (pwd in Ctrl-O)
d="дир 'q' \$x !b"
mkdir -p "$T/sh/$d" "$T/sh/d2" "$HOME/.config/mc"
cat > "$HOME/.tcshrc" << 'EOF'
set prompt="mc-test-prompt> "
set history = 100
set savehist = (100 merge)
set histdup = erase
set noclobber
EOF
printf '#+1700000001\necho mc-test-old\n' > "$HOME/.history"
printf 'm       mc-test menu entry\n\techo menu-ran > %s/menu.txt\n' "$T" > "$HOME/.config/mc/menu"
rm -f "$T/pwd.txt" "$T/hist.txt" "$T/menu.txt"
keys_run "$T/sh.typescript" "sleep 3; printf '$down'; sleep 0.5; printf '$down'; sleep 0.5; printf '$enter'; sleep 1.5;
        printf '$enter'; sleep 1.5; printf '\033OA'; sleep 0.5; printf '$enter'; sleep 1.5; printf '$enter'; sleep 1.5;
        printf '$down'; sleep 0.5; printf '$enter'; sleep 1.5; printf 'echo mc-test-cmdline\r'; sleep 2;
        printf '\033OQ'; sleep 1.5; printf m; sleep 2; printf '\017'; sleep 2; printf 'echo mc-test-typed\r'; sleep 1;
        printf 'history >! $T/hist.txt\r'; sleep 1.5; printf 'pwd >! $T/pwd.txt\r'; sleep 1.5; printf 'exit\r'; sleep 4;
        printf '$f10'; sleep 2" \
    sh -c 'cd "$1" && exec "$2"' sh "$T/sh" "$mc"
pw="$(cat "$T/pwd.txt" 2>/dev/null)"
if [ "$pw" = "$T/sh/$d" ]; then
    pass "tcsh subshell: mc's cd into \"$d\" (pwd in Ctrl-O)"
else
    fail "tcsh subshell: pwd in Ctrl-O \"$pw\", not \"$T/sh/$d\": $(seen "$T/sh.typescript")"
fi
if grep -q 'mc-test-prompt>' "$T/sh.typescript.txt"; then
    pass "tcsh subshell: the prompt of ~/.tcshrc (mc-test-prompt>) kept"
else
    fail "tcsh subshell: no prompt of ~/.tcshrc (mc-test-prompt>): $(grep -m 1 -o '[^ ]*@[^ ]*[#>]' "$T/sh.typescript.txt")"
fi
if [ "$keys_exit" = 0 ] && [ "$keys_secs" -le 26 ] && ! grep -q 'read (subshell_pty' "$T/sh.typescript.txt"; then
    pass "tcsh subshell: exit in Ctrl-O ended mc with status 0 (${keys_secs}s)"
else
    fail "tcsh subshell: exit in Ctrl-O: status $keys_exit after ${keys_secs}s (exit at 24s, F10 at 28s): $(grep -m 1 'read (subshell' "$T/sh.typescript.txt")"
fi
if [ "$(cat "$T/menu.txt" 2>/dev/null)" = menu-ran ]; then
    pass "the user menu (F2, m) ran its command"
else
    fail "the user menu (F2, m) did not run its command (no $T/menu.txt)"
fi
# hist_check <what> <file>: the old event and the typed commands there, none of mc's lines
hist_check() {
    _miss="" _mc=""
    for _w in "echo mc-test-old" "echo mc-test-cmdline" "echo mc-test-typed"; do
        grep -q -F -- "$_w" "$2" 2> /dev/null || _miss="$_miss; $_w"
    done
    _mc="$(grep -E "printf '%b'|alias precmd|bindkey|history -c|mcusr|mc\.cmd\.|(^|[[:space:]])cd[[:space:]]" "$2" 2> /dev/null |
        head -n 3 | tr '\n' ' ' | cut -c1-200)"
    if [ ! -s "$2" ]; then
        fail "tcsh subshell: no $1 ($2)"
    elif [ -z "$_miss" ] && [ -z "$_mc" ]; then
        pass "tcsh subshell: $1 has the old event and the 3 typed commands, none of mc's lines ($(grep -c -v '^#+' "$2" | tr -d ' ') lines)"
    else
        fail "tcsh subshell: $1:${_miss:+ lacks${_miss#;};}${_mc:+ has mc's lines: $_mc}"
    fi
}
hist_check "history in Ctrl-O" "$T/hist.txt"
hist_check "~/.history after the exit" "$HOME/.history"
mch="$HOME/.local/share/mc/history"
dh="$(awk '/^\[/ { s = ($0 == "[Dir Hist New Left Panel]"); next } s && /=/ { sub(/^[^=]*=/, ""); print }' "$mch" 2> /dev/null)"
if printf '%s\n' "$dh" | grep -q -x -F "$T/sh/d2" && printf '%s\n' "$dh" | grep -q -x -F "$T/sh/$d"; then
    pass "the Dir Hist of the left panel in mc's history: $T/sh/d2, $T/sh/$d ($(printf '%s\n' "$dh" | grep -c .) entries)"
else
    fail "the Dir Hist of the left panel in $mch: $(printf '%s' "$dh" | tr '\n' ' ' | cut -c1-200)"
fi
rm -f "$HOME/.tcshrc" "$HOME/.history" "$HOME/.config/mc/menu"
# prompt-invalid-utf8.patch, with bash when it is installed (tcsh puts such bytes of
# its prompt into UTF-8 itself): the prompt "<dir>/d\370> " (\370: "ш" in CP1251) is
# "<dir>/d> " on mc's command line (mc 4.8.33 lost "> " and read past the end)
bash="${MC_TEST_BASH:-/usr/local/bin/bash}"
if [ -x "$bash" ]; then
    cpd="$T/cp/d$(printf '\370')"
    mkdir -p "$cpd"
    printf "PS1='\\\\w> '\n" > "$HOME/.bashrc"
    keys_run "$T/cp.typescript" "sleep 3; printf '$f10'; sleep 2" env SHELL="$bash" sh -c 'cd "$1" && exec "$2"' sh "$cpd" "$mc"
    rm -f "$HOME/.bashrc"
    if [ "$keys_exit" = 0 ] && grep -q "$T/cp/d> " "$T/cp.typescript.txt"; then
        pass "bash subshell in a directory named in CP1251: the prompt on the command line \"$T/cp/d> \""
    else
        fail "bash subshell in a directory named in CP1251: exit $keys_exit, no \"$T/cp/d> \": $(grep -m 1 "$T/cp" "$T/cp.typescript.txt" | cut -c1-120)"
    fi
else
    echo "skip  the prompt of bash with a byte that is not UTF-8: no $bash" >> "$out"
fi
# copy-clone-1.patch: F5 of a file of 40 MB inside a ZFS pool (on a file of 256 MB, an
# md device; kldload zfs) clones its blocks (copy_file_range with COPY_FILE_RANGE_CLONE):
# bcloneused of the pool grows by the copy, cmp finds it identical; with
# file_cloning=false in ~/.config/mc/ini bcloneused stays, the copy identical; a copy to
# another file system identical, mc without an error; a Reget onto a part of the file
# that is not aligned to the blocks (copy-clone-2-reget). Pool and md device go after.
# clone_copy <name> <to dir> [<key>]: F5 of zp/s/src.bin into the dir (the other panel),
# the key (r: Reget) into the dialog "File exists", F10 when the copy is whole (a copy
# without cloning takes some seconds on the md device: up to 45 s)
clone_copy() {
    keys_run "$T/$1.typescript" "sleep 3; printf '$down'; sleep 0.5; printf '\033[15~'; sleep 1.5; printf '$enter';
        sleep 2; ${3:+printf $3;} i=0; while [ \$i -lt 45 ] && [ \"\$(stat -f %z '$2/src.bin' 2> /dev/null)\" != 41943040 ];
        do sleep 1; i=\$((i + 1)); done; sleep 2; printf '$f10'; sleep 2" "$mc" -u "$T/zp/s" "$2"
}
# ini_cloning <true|false>: file_cloning in the ini of mc (written at its exits above)
ini_cloning() {
    _ini="$HOME/.config/mc/ini"
    if grep -q '^file_cloning=' "$_ini" 2> /dev/null; then
        sed -i '' "s/^file_cloning=.*/file_cloning=$1/" "$_ini"
    else
        mkdir -p "${_ini%/*}"
        { echo "[Midnight-Commander]"; echo "file_cloning=$1"; } >> "$_ini"
    fi
}
bclone() { zpool get -Hp -o value bcloneused "$pool" 2> /dev/null; }
pool="mctest$$" md="" ctmp="/tmp/mc-test-clone.$$"
if ! kldload -n zfs 2> "$T/zfs.err"; then
    fail "file cloning: kldload zfs: $(head -n 1 "$T/zfs.err")"
elif ! truncate -s 256m "$T/zpool.img" || ! md="$(mdconfig -a -t vnode -f "$T/zpool.img" 2> "$T/zfs.err")"; then
    fail "file cloning: no md device on $T/zpool.img: $(head -n 1 "$T/zfs.err")"
elif ! zpool create -f -O mountpoint="$T/zp" -O atime=off "$pool" "/dev/$md" 2> "$T/zfs.err"; then
    fail "file cloning: zpool create on /dev/$md: $(head -n 1 "$T/zfs.err")"
else
    be="$(sysctl -n vfs.zfs.bclone_enabled 2> /dev/null)"
    mkdir -p "$T/zp/s" "$T/zp/c1" "$T/zp/c2" "$ctmp"
    dd if=/dev/random of="$T/zp/s/src.bin" bs=1m count=40 2> /dev/null
    zpool sync "$pool"
    ini_cloning true
    b0="$(bclone)"
    clone_copy cl1 "$T/zp/c1"
    zpool sync "$pool"
    b1="$(bclone)"
    if [ "$keys_exit" = 0 ] && cmp -s "$T/zp/s/src.bin" "$T/zp/c1/src.bin" && [ $(( b1 - b0 )) -ge 40000000 ]; then
        pass "file cloning on ZFS (vfs.zfs.bclone_enabled=$be): F5 cloned 40 MB, bcloneused +$(( b1 - b0 )), the copy identical"
    else
        fail "file cloning on ZFS (vfs.zfs.bclone_enabled=$be): exit $keys_exit, bcloneused $b0 -> $b1, cmp: $(cmp "$T/zp/s/src.bin" "$T/zp/c1/src.bin" 2>&1 | head -n 1)"
    fi
    # copy-clone-2-reget.patch: a Reget onto a part of 20 MB and 1000 bytes (not aligned to
    # the blocks: the clone of the rest fails, mc appends instead, with O_WRONLY now)
    mkdir -p "$T/zp/c3"
    head -c 20972520 "$T/zp/s/src.bin" > "$T/zp/c3/src.bin"
    clone_copy cl-rg "$T/zp/c3" r
    if [ "$keys_exit" = 0 ] && cmp -s "$T/zp/s/src.bin" "$T/zp/c3/src.bin"; then
        pass "file cloning on: Reget onto 20 MB and 1000 bytes of the 40 MB, the copy identical"
    else
        fail "file cloning on, Reget onto a part that is not aligned: exit $keys_exit, size $(wc -c < "$T/zp/c3/src.bin" | tr -d ' '), cmp: $(cmp "$T/zp/s/src.bin" "$T/zp/c3/src.bin" 2>&1 | head -n 1): $(grep -m 1 -i -E 'cannot|bad file' "$T/cl-rg.typescript.txt")"
    fi
    zpool sync "$pool"
    b1="$(bclone)"
    ini_cloning false
    clone_copy cl2 "$T/zp/c2"
    zpool sync "$pool"
    b2="$(bclone)"
    if [ "$keys_exit" = 0 ] && cmp -s "$T/zp/s/src.bin" "$T/zp/c2/src.bin" && [ $(( b2 - b1 )) -lt 1000000 ]; then
        pass "file_cloning=false: F5 copied 40 MB without cloning (bcloneused +$(( b2 - b1 ))), the copy identical"
    else
        fail "file_cloning=false: exit $keys_exit, bcloneused $b1 -> $b2, cmp: $(cmp "$T/zp/s/src.bin" "$T/zp/c2/src.bin" 2>&1 | head -n 1)"
    fi
    ini_cloning true
    clone_copy cl3 "$ctmp"
    if [ "$keys_exit" = 0 ] && cmp -s "$T/zp/s/src.bin" "$ctmp/src.bin" && ! grep -q -i 'cannot' "$T/cl3.typescript.txt"; then
        pass "file cloning on: F5 from the pool to $ctmp (another file system) copied 40 MB, identical, no error"
    else
        fail "file cloning on, F5 to another file system: exit $keys_exit, cmp: $(cmp "$T/zp/s/src.bin" "$ctmp/src.bin" 2>&1 | head -n 1): $(grep -m 1 -i 'cannot' "$T/cl3.typescript.txt")"
    fi
fi
zpool destroy -f "$pool" 2> /dev/null
[ -n "$md" ] && mdconfig -d -u "$md" 2> /dev/null
rm -rf "$T/zpool.img" "$T/zp" "$ctmp"
# history-items-96.patch: the ini of mc, written at its exits above into a new HOME
if grep -q -x 'num_history_items_recorded=96' "$HOME/.config/mc/ini" 2> /dev/null; then
    pass "a new ~/.config/mc/ini has num_history_items_recorded=96"
else
    fail "~/.config/mc/ini: $(grep num_history_items_recorded "$HOME/.config/mc/ini" 2> /dev/null || echo "no $HOME/.config/mc/ini")"
fi
finish
