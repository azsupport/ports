# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/misc.sh: the group misc of tools/prog-bench.sh (sourced by it): the small
# programs of this tree with a load of their own, each with the patches of its port.
#
# zip 3.0 and unzip 6.0 (archivers/zip, archivers/unzip: the official ports of the pinned
# freebsd-ports 7db71032fc, their patches from raw.githubusercontent.com, and ours over them:
# zip files/patch-*, unzip the fixes of Fedora, Debian and OpenBSD, ICONV) with their own
# deflate and inflate (not zlib); on a tree of /usr/include and /usr/share/man on a tmpfs:
# zip -r -6 and -9, unzip -t (inflate and CRC) and unzip into an empty directory; timed.
# procmail 3.24.20260812 (mail/procmail, BuGlessRB/procmail at 8b379c4) with its make: 2000
# deliveries (a process each, as from the MTA) of a message of 20 KB through a procmailrc of
# 30 recipes of regular expressions on the header and the body, into a Maildir; timed.
# tmux 3.8 (sysutils/tmux): libevent of the packages (ours: azsupport), utempter of the base
# system, no utf8proc; a session of 200x50 that cats 150 MB of text (its parser of the terminal
# and the grid), until the end; timed.

g_progs="zip unzip procmail tmux"
FP=https://raw.githubusercontent.com/freebsd/freebsd-ports/7db71032fc225badb995b5c6026a15e8bdfda147

g_need() { need libevent; }

# offpatch <dir> <port> <file>...: the patches of the official port (-p0), from GitHub
offpatch() {
    _d="$1" _p="$2"; shift 2
    for _f in "$@"; do
        mkdir -p "$W/dist/fp/$_p"
        [ -s "$W/dist/fp/$_p/$_f" ] || curl -fsSL --retry 3 -o "$W/dist/fp/$_p/$_f" "$FP/$_p/files/$_f" || { echo "FAIL: cannot download $_p/$_f"; continue; }
        (cd "$_d" && patch -s -p0 < "$W/dist/fp/$_p/$_f") || echo "FAIL: $_p/$_f"
    done
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch zip30.tar.gz f0e8bb1f9b7eb0b01285495a2699df3a4b766784c1765a8f1aeedf63c0806369 \
        "https://downloads.sourceforge.net/project/infozip/Zip%203.x%20%28latest%29/3.0/zip30.tar.gz"
    fetch unzip60.tar.gz 036d96991646d0449ed0aa952e4fbe21b476ce994abc276e49d30e686708bd37 \
        "https://downloads.sourceforge.net/project/infozip/UnZip%206.x%20%28latest%29/UnZip%206.0/unzip60.tar.gz"
    fetch BuGlessRB-procmail-3.24.20260812-8b379c4f536320abafd524fd4ccfedaf3f387f54_GH0.tar.gz \
        d59ac54469bd294d5c5c49d5ca2a1f47e18ea31f98c71af24cb991588d5ed844 \
        https://codeload.github.com/BuGlessRB/procmail/tar.gz/8b379c4f536320abafd524fd4ccfedaf3f387f54
    fetch tmux-3.8.tar.gz e79c699c7e949dccd0a4a125e17b8d1261e311b16979dbc8eb34542f3966d82e \
        https://github.com/tmux/tmux/releases/download/3.8/tmux-3.8.tar.gz
    # zip
    unpack zip30.tar.gz "$W/src/zip-$_v"
    _b="$W/b-zip-$_v.log"
    {
        offpatch "$W/src/zip-$_v" archivers/zip patch-fileio.c patch-unix_Makefile patch-unix_configure patch-unix_unix.c patch-zip.c patch-zipnote.c
        (cd "$W/src/zip-$_v" && patch -s -p0 < "$top/archivers/zip/files/patch-zip.c-nomutilation" &&
            patch -s -p0 < "$top/archivers/zip/files/patch-util.c-envargs" &&
            patch -s -p1 < "$top/archivers/zip/files/patch-zipnote-utf8") || echo "FAIL: the patches of archivers/zip"
        sed -i '' -e 's|^BIND = $(CC)$|BIND = $(CC) $(LDFLAGS)|' "$W/src/zip-$_v/unix/Makefile"
    } > "$_b" 2>&1
    if (cd "$W/src/zip-$_v" && make -f unix/Makefile generic CC="$CC" CFLAGS="$CFLAGS -Wno-deprecated-non-prototype" \
        LDFLAGS="$LDFLAGS") >> "$_b" 2>&1 && [ -x "$W/src/zip-$_v/zip" ]; then
        mkdir -p "$W/zip-$_v" && cp "$W/src/zip-$_v/zip" "$W/zip-$_v/"
        bok zip "$_v" "$W/zip-$_v/zip"
    else
        bno zip "$_v" "$_b"
    fi
    # unzip
    unpack unzip60.tar.gz "$W/src/unzip-$_v"
    _b="$W/b-unzip-$_v.log"
    U="$top/archivers/unzip/files"
    {
        offpatch "$W/src/unzip-$_v" archivers/unzip patch-consts.h patch-crypt.c patch-extract.c patch-process.c patch-unix_Makefile \
            patch-unix_unix.c extra-iconv-patch-unix_unix.c extra-iconv-patch-unix_unxcfg.h extra-iconv-patch-unzip.c \
            extra-iconv-patch-unzpriv.h extra-iconv-patch-zipinfo.c
        for p in unzip-6.0-close.patch unzip-6.0-attribs-overflow.patch unzip-6.0-format-secure.patch unzip-6.0-valgrind.patch \
            unzip-6.0-overflow.patch unzip-6.0-cve-2014-8141.patch unzip-6.0-overflow-long-fsize.patch \
            0001-Fix-CVE-2016-9844-rhbz-1404283.patch unzip-6.0-cve-2018-1000035-heap-based-overflow.patch \
            unzip-6.0-cve-2018-18384.patch unzip-6.0-COVSCAN-fix-unterminated-string.patch unzip-zipbomb-part1.patch \
            unzip-zipbomb-part2.patch unzip-zipbomb-part3.patch unzip-zipbomb-part4.patch unzip-zipbomb-part5.patch \
            unzip-zipbomb-part6.patch unzip-zipbomb-part7.patch unzip-6.0-fix-false-overlap-detection-on-32bit-systems.patch \
            CVE-2021-4217.patch CVE-2022-0529.patch CVE-2022-0530.patch unzip-6.0-sast.patch; do
            patch -d "$W/src/unzip-$_v" -p1 -s -f < "$U/fedora/$p" || echo "FAIL: fedora/$p"
        done
        for p in can-2026-2034442.patch can-2026-2034443.patch fix-integer-underflow-csiz-decrypted.patch zipgrep-cve-2022-1271.patch \
            fix-zipgrep.patch initialize-the-symlink-flag.patch handle-pkware-verification-bit.patch handle-windows-zip64-files.patch \
            restore-unix-timestamps-accurately.patch fix-warning-messages-on-big-files.patch allow-greater-hostver-values.patch \
            harden-parsing-of-up-extra-field.patch print-newline-on-interrupt.patch; do
            patch -d "$W/src/unzip-$_v" -p1 -s -f < "$U/debian/$p" || echo "FAIL: debian/$p"
        done
        for p in patch-explode_c patch-inflate_c; do patch -d "$W/src/unzip-$_v" -p0 -s -f < "$U/openbsd/$p" || echo "FAIL: openbsd/$p"; done
        patch -d "$W/src/unzip-$_v" -p1 -s -f < "$U/cve-2014-8139-pkvms.patch" || echo "FAIL: cve-2014-8139-pkvms.patch"
        patch -d "$W/src/unzip-$_v" -p1 -s -f < "$U/zipinfo-usage.patch" || echo "FAIL: zipinfo-usage.patch"
        sed -i '' -e '/^[LSF][FL] = -o /s|$(LFLAGS1)$|$(LFLAGS1) $(LDFLAGS)|' "$W/src/unzip-$_v/unix/Makefile"
    } > "$_b" 2>&1
    # iconv(3) and bzip2 of the base system (ICONV of the port: ICONV_LIB empty), not -I and -L of
    # /usr/local: its iconv.h of libiconv (here a package) makes iconv_open libiconv_open, which
    # the link does not find (45938357673)
    # gcc16: -fpermissive (the errors of GCC 14 and later of its K&R C as warnings, as the base
    # clang 19 has them; 45941929373: its build stopped), said
    _ucf="$CFLAGS"
    if [ "$_v" = gcc16 ]; then
        _ucf="$CFLAGS -fpermissive"
        echo "unzip gcc16: built with -fpermissive (the errors of GCC 14 and later of its K&R C as warnings, as the base clang 19 has them)" >> "$W/fails/$group-notes-gcc16.md"
    fi
    if (cd "$W/src/unzip-$_v" && env LOCAL_UNZIP="$_ucf -DNATIVE -DACORN_FTYPE_NFS -DWILD_STOP_AT_DIR -DUNICODE_SUPPORT -DUTF8_MAYBE_NATIVE -D_MBCS -DLARGE_FILE_SUPPORT" \
        D_USE_BZ2=-DUSE_BZIP2 L_BZ2=-lbz2 make -f unix/Makefile bsd CC="$CC" LF2= LFLAGS1= LDFLAGS="$LDFLAGS") >> "$_b" 2>&1 &&
        [ -x "$W/src/unzip-$_v/unzip" ]; then
        mkdir -p "$W/unzip-$_v" && cp "$W/src/unzip-$_v/unzip" "$W/unzip-$_v/"
        bok unzip "$_v" "$W/unzip-$_v/unzip"
    else
        bno unzip "$_v" "$_b"
    fi
    grep '^FAIL' "$W/b-zip-$_v.log" "$_b" | head -n 10 >&3
    # procmail: the patches of the port (files/patch-*: LOCKINGTEST "/tmp ." with BATCH, the
    # autoconf without its read of the terminal, config.h and the flags of initmake), its
    # post-patch (cd x; $(MAKE) as $(MAKE) -C x), its make with BATCH and the input of /dev/null
    # as the ports build, 25 minutes at most (without the patches and with yes '' into it,
    # 45907096652 and 45930853611 stood for hours in this build)
    unpack BuGlessRB-procmail-3.24.20260812-8b379c4f536320abafd524fd4ccfedaf3f387f54_GH0.tar.gz "$W/src/procmail-$_v"
    _b="$W/b-procmail-$_v.log"
    : > "$_b"
    for p in "$top"/mail/procmail/files/patch-*; do
        (cd "$W/src/procmail-$_v" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    find "$W/src/procmail-$_v" -name 'Makefile*' -exec sed -i '' -E -e 's|cd (.+); (\$\(MAKE\))|\2 -C \1|' {} +
    # clang23 and gcc16: the autoconf.h of the build of clang19 (the base compiler, as the port
    # builds): its autoconf times strstr() in a loop that gcc16 -O3 makes endless (45938357673:
    # "Benchmarking your system's strstr() implementation" until the timeout); the same findings
    # for the three
    if [ "$_v" != clang19 ] && [ -f "$W/procmail-autoconf.h" ]; then
        # a time ahead of the Makefiles initmake writes, so that make does not make it again
        cp "$W/procmail-autoconf.h" "$W/src/procmail-$_v/autoconf.h" && touch -t 203001010000 "$W/src/procmail-$_v/autoconf.h"
        echo "procmail $_v: the autoconf.h of the build of clang19 (its autoconf times strstr() in a loop that gcc16 -O3 makes endless)" >> "$W/fails/$group-notes-$_v.md"
    fi
    # gcc16: -fpermissive (its autoconf and its code of K&R C: the errors of GCC 14 and later,
    # implicit declarations, implicit int, int-conversion, incompatible pointer types, warnings
    # as with the base clang 19; 45930853611 stood in this build of gcc16 alone), said
    _pcf="$CFLAGS"
    if [ "$_v" = gcc16 ]; then
        _pcf="$CFLAGS -fpermissive"
        echo "procmail gcc16: built with -fpermissive (the errors of GCC 14 and later of its K&R C as warnings, as the base clang 19 has them)" >> "$W/fails/$group-notes-gcc16.md"
    fi
    if (cd "$W/src/procmail-$_v" && timeout -k 30 1500 make BATCH=yes CC="$CC" CFLAGS0="$_pcf" LDFLAGS0="$LDFLAGS" BASENAME="$W/procmail-$_v" < /dev/null) >> "$_b" 2>&1 &&
        [ -x "$W/src/procmail-$_v/src/procmail" ]; then
        mkdir -p "$W/procmail-$_v" && cp "$W/src/procmail-$_v/src/procmail" "$W/procmail-$_v/"
        [ "$_v" != clang19 ] || cp "$W/src/procmail-$_v/autoconf.h" "$W/procmail-autoconf.h"
        bok procmail "$_v" "$W/procmail-$_v/procmail"
    else
        bno procmail "$_v" "$_b"
    fi
    # tmux
    unpack tmux-3.8.tar.gz "$W/src/tmux-$_v"
    _b="$W/b-tmux-$_v.log"
    if (cd "$W/src/tmux-$_v" && ./configure --prefix="$W/tmux-$_v" --enable-utempter --disable-utf8proc \
        CPPFLAGS=-I/usr/local/include LDFLAGS="-L/usr/local/lib $LDFLAGS" && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok tmux "$_v" "$W/tmux-$_v/bin/tmux"
    else
        bno tmux "$_v" "$_b"
    fi
}

g_keep() { echo "$W/zip-$1 $W/unzip-$1 $W/procmail-$1 $W/tmux-$1"; }

g_bench() {
    pbrd
    T=/mnt/pbrd/m
    mkdir -p "$T/src"
    tar -cf - -C / usr/include usr/share/man 2> /dev/null | tar -xf - -C "$T/src"
    say "misc: the tree of zip: $(find "$T/src" -type f | wc -l | tr -d ' ') files, $(du -sm "$T/src" | cut -f 1) MB"
    if have zip clang19; then (cd "$T/src" && "$W/zip-clang19/zip" -q -r -6 "$T/ref.zip" .); fi
    # procmail: a message of 20 KB, a procmailrc of 30 recipes
    awk 'BEGIN { srand(5) } { w[NR] = $1 } END {
        print "From: Sender <sender@example.com>"; print "To: <u1@example.com>"; print "Subject: the weekly report of the servers"
        print "Date: Thu, 26 Nov 2026 20:00:00 +0100"; print "Message-ID: <x@example.com>"; print "X-Spam-Score: 1.5"
        for (i = 0; i < 40; i++) printf "Received: from host%d.example.net (host%d.example.net [10.0.%d.%d]) by mx.example.com\n", i, i, i, i
        print ""
        for (i = 0; i < 2800; i++) printf "%s%s", w[int(rand() * NR) + 1], (i % 12 == 11) ? "\n" : " "
        print "" }' /usr/share/dict/words > "$W/msg.eml"
    mkdir -p "$T/maildir"
    {
        echo "MAILDIR=$T/maildir/"
        echo "DEFAULT=$T/maildir/inbox/"
        echo "LOGFILE=/dev/null"
        i=1; while [ "$i" -le 25 ]; do
            printf ':0\n* ^Subject:.*(invoice|payment|order) number [0-9]+%d\n%s/maildir/r%d/\n\n' "$i" "$T" "$i"; i=$((i + 1)); done
        printf ':0 B\n* (viagra|lottery|winner|inheritance)[^a-z]+(claim|prize)\n%s/maildir/spam/\n\n' "$T"
        printf ':0 B\n* ^.*zebra[a-z]*fish[0-9]+$\n%s/maildir/zf/\n\n' "$T"
        printf ':0\n* ^X-Spam-Score: ([5-9]|[1-9][0-9])\\.\n%s/maildir/spam/\n\n' "$T"
        printf ':0\n* ^Received: from [a-z0-9.]+\\.evil\\.example\n%s/maildir/evil/\n\n' "$T"
        printf ':0 HB\n* -1^1 [a-z]+ing\n* 2000^0\n%s/maildir/scored/\n\n' "$T"
    } > "$W/procmailrc"
    awk 'BEGIN { for (i = 0; i < 3000000; i++) printf "\033[3%dm%08d\033[0m the line %d of the text of the benchmark of tmux, %s\n", i % 8, i, i, (i % 3) ? "plain" : "with more words in it" }' > "$T/tmux.txt"
    say "misc: tmux.txt $(du -m "$T/tmux.txt" | cut -f 1) MB"
    for r in $(seq 1 "$rounds"); do
        say "misc: round $r of $rounds"
        for v in $(order "$r"); do
            if have zip "$v"; then
                rm -f "$T/o.zip"
                timed "$v" zip "zip -r -6 of the tree" timeout -k 10 900 sh -c 'cd "$1" && cpuset -l "$2" "$3" -q -r -6 "$4" .' sh "$T/src" "$last" "$W/zip-$v/zip" "$T/o.zip"
                rm -f "$T/o.zip"
                timed "$v" zip "zip -r -9 of the tree" timeout -k 10 900 sh -c 'cd "$1" && cpuset -l "$2" "$3" -q -r -9 "$4" .' sh "$T/src" "$last" "$W/zip-$v/zip" "$T/o.zip"
                rm -f "$T/o.zip"
            fi
            if have unzip "$v"; then
                timed "$v" unzip "unzip -t of the zip of the tree" timeout -k 10 900 cpuset -l "$last" "$W/unzip-$v/unzip" -qq -t "$T/ref.zip"
                rm -rf "$T/x"
                timed "$v" unzip "unzip into an empty directory" timeout -k 10 900 cpuset -l "$last" "$W/unzip-$v/unzip" -qq -o "$T/ref.zip" -d "$T/x"
                rm -rf "$T/x"
            fi
            if have procmail "$v"; then
                timed "$v" procmail "2000 deliveries of 20 KB, 30 recipes" timeout -k 10 900 sh -c '
                    i=0; while [ "$i" -lt 2000 ]; do cpuset -l "$1" "$2" -m "$3" < "$4" || exit 1; i=$((i + 1)); done' \
                    sh "$last" "$W/procmail-$v/procmail" "$W/procmailrc" "$W/msg.eml"
                rm -rf "$T/maildir"; mkdir -p "$T/maildir"
            fi
            if have tmux "$v"; then
                timed "$v" tmux "a session cats 150 MB of text (200x50)" timeout -k 10 900 env TERM=xterm sh -c '
                    cpuset -l "$1" "$2" -L pb -f /dev/null new-session -d -x 200 -y 50 "cat $3; $2 -L pb wait-for -S done" &&
                    "$2" -L pb wait-for done; "$2" -L pb kill-server 2> /dev/null; exit 0' sh "$last" "$W/tmux-$v/bin/tmux" "$T/tmux.txt"
            fi
        done
    done
}
