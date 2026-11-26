# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/mail.sh: the group mail of tools/prog-bench.sh (sourced by it).
#
# Dovecot 2.3.21.1 (mail/dovecot, its distinfo) with the patches of the port (files/patch-*)
# and its options: OpenSSL of the base system, zstd of the packages (ours: azsupport), no
# GSSAPI, LDAP, FTS, Lua, LZ4, libsodium, libunwind, shadow, systemd. IMAP on 127.0.0.1
# (plain logins, a static password and user), a Maildir of 20000 messages on a tmpfs; the
# server on the last CPU, the clients (imaplib of the Python of the packages) on the others:
# the first SELECT and FETCH of the envelopes of all (the index built), the same with the
# index (5 times), SEARCH BODY of a word (3 times, no FTS: the bodies read), 4 clients at
# once each fetching 200 whole messages 5 times; timed.
#
# Postfix 3.11.8 (mail/postfix, its distinfo) with the patches of the port and its options
# but those of maps (EAI, ICU, LMDB, TLSRPT left out: none of them in the path of a message
# here; the hash and btree maps of the Berkeley DB of the libc of the base system, the
# defaults of postfix): PCRE2 of the packages, TLS of the base system; static. The master and its daemons on
# the last CPU, the queue on a tmpfs; smtp-source (of the build by clang19) on the others: 20000
# messages of 2 KB, 20 sessions at once, to the default transport discard: until the queue
# is empty (smtpd, cleanup, trivial-rewrite, qmgr, discard), timed.

g_progs="dovecot postfix"

g_need() {
    need zstd pcre2
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch dovecot-2.3.21.1.tar.gz 2d90a178c4297611088bf7daae5492a3bc3d5ab6328c3a032eb425d2c249097e \
        https://www.dovecot.org/releases/2.3/dovecot-2.3.21.1.tar.gz
    fetch postfix-3.11.8.tar.gz 244bca208c86f678ad0a72ff1f744ec8ef922ccf3310851f6c992ff44bb5b4ff \
        https://de.postfix.org/ftpmirror/official/postfix-3.11.8.tar.gz https://archive.mgm51.com/mirrors/postfix-source/official/postfix-3.11.8.tar.gz \
        https://ftp.porcupine.org/mirrors/postfix-release/official/postfix-3.11.8.tar.gz
    unpack dovecot-2.3.21.1.tar.gz "$W/src/dovecot-$_v"
    _b="$W/b-dovecot-$_v.log"
    : > "$_b"
    for p in "$top"/mail/dovecot/files/patch-*; do
        (cd "$W/src/dovecot-$_v" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    if (cd "$W/src/dovecot-$_v" && ./configure --prefix="$W/dovecot-$_v" --with-ssl=openssl --with-shadow=no \
        --with-systemd=no --with-zstd --without-gssapi --without-ldap --without-lucene --without-solr \
        --without-icu --without-lz4 --without-sodium --without-libunwind --without-lua --without-docs \
        CPPFLAGS=-I/usr/local/include LDFLAGS="-L/usr/local/lib $LDFLAGS" &&
        gmake -j"$ncpu" && gmake install) >> "$_b" 2>&1 && [ -x "$W/dovecot-$_v/sbin/dovecot" ]; then
        bok dovecot "$_v" "$W/dovecot-$_v/lib/dovecot/libdovecot.so"
    else
        bno dovecot "$_v" "$_b"
    fi
    rm -rf "$W/src/dovecot-$_v"
    unpack postfix-3.11.8.tar.gz "$W/src/postfix-$_v"
    _b="$W/b-postfix-$_v.log"
    : > "$_b"
    for p in "$top"/mail/postfix/files/patch-*; do
        (cd "$W/src/postfix-$_v" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    # its make takes CC, OPT (the flags), CCARGS and AUXLIBS; no maps of Berkeley DB, NIS, LMDB
    _cc="$CC"
    if (cd "$W/src/postfix-$_v" && gmake -f Makefile.init makefiles CC="$_cc" OPT="$CFLAGS" DEBUG= \
        CCARGS="-DNO_NIS -DNO_LMDB -DNO_EAI -DUSE_TLS -DHAS_PCRE=2 -I/usr/local/include -DDEF_CONFIG_DIR=\\\"$W/pf/etc\\\"" \
        AUXLIBS="$LDFLAGS -lssl -lcrypto" AUXLIBS_PCRE="$(pcre2-config --libs8)" shared=no dynamicmaps=no &&
        gmake) >> "$_b" 2>&1 && [ -x "$W/src/postfix-$_v/libexec/master" ]; then
        mkdir -p "$W/postfix-$_v"
        cp -R "$W/src/postfix-$_v/bin" "$W/src/postfix-$_v/libexec" "$W/src/postfix-$_v/conf" "$W/postfix-$_v/"
        [ -x "$W/postfix-$_v/bin/smtp-source" ] || cp "$W/src/postfix-$_v/src/smtpstone/smtp-source" "$W/postfix-$_v/bin/"
        cp "$W/src/postfix-$_v/postfix-install" "$W/postfix-$_v/"
        bok postfix "$_v" "$W/postfix-$_v/libexec/smtpd"
    else
        bno postfix "$_v" "$_b"
    fi
    rm -rf "$W/src/postfix-$_v"
}

g_keep() { echo "$W/dovecot-$1 $W/postfix-$1"; }

dovecot_conf() {
    cat > "$W/dovecot-$1.conf" << EOF
protocols = imap
listen = 127.0.0.1
base_dir = $W/dovecot-run
state_dir = $W/dovecot-state
log_path = $W/dovecot.log
ssl = no
disable_plaintext_auth = no
auth_mechanisms = plain
default_login_user = dovenull
default_internal_user = dovecot
passdb {
  driver = static
  args = password=pass
}
userdb {
  driver = static
  args = uid=pbmail gid=pbmail home=/mnt/pbrd/mail/%u
}
mail_location = maildir:~/Maildir
mail_fsync = never
service imap-login {
  inet_listener imap {
    address = 127.0.0.1
    port = 1143
  }
}
EOF
}

g_bench() {
    pbrd
    for u in dovecot dovenull pbmail; do pw usershow "$u" > /dev/null 2>&1 || pw useradd "$u" -d /nonexistent -s /usr/sbin/nologin; done
    pw groupshow postfix > /dev/null 2>&1 || pw groupadd postfix
    pw usershow postfix > /dev/null 2>&1 || pw useradd postfix -g postfix -d /nonexistent -s /usr/sbin/nologin
    pw groupshow maildrop > /dev/null 2>&1 || pw groupadd maildrop
    mkdir -p "$W/dovecot-run" "$W/dovecot-state"
    # the Maildir: 20000 messages of words of /usr/share/dict/words
    M=/mnt/pbrd/mail/u1/Maildir
    mkdir -p "$M/cur" "$M/new" "$M/tmp"
    awk -v d="$M/cur" 'BEGIN { srand(11) } { w[NR] = $1 } END {
        for (i = 1; i <= 20000; i++) {
            f = sprintf("%s/%d.M%dP1.pb:2,S", d, 1700000000 + i, i)
            s = ""; for (j = 0; j < 8; j++) s = s " " w[int(rand() * NR) + 1]
            printf "Return-Path: <a%d@example.com>\nFrom: User %d <a%d@example.com>\nTo: <u1@example.com>\nSubject:%s\nDate: Thu, 26 Nov 2026 20:00:00 +0100\nMessage-ID: <%d@example.com>\nMIME-Version: 1.0\nContent-Type: text/plain; charset=utf-8\n\n", i % 500, i, i % 500, s, i > f
            n = 50 + int(rand() * 300)
            for (j = 0; j < n; j++) printf "%s%s", w[int(rand() * NR) + 1], (j % 12 == 11) ? "\n" : " " > f
            printf "\nzebrafish%d\n", i % 50 > f
            close(f)
        } }' /usr/share/dict/words
    chown -R pbmail:pbmail /mnt/pbrd/mail
    cat > "$W/imapb.py" << 'EOF'
import imaplib, sys, random
mode = sys.argv[1]
m = imaplib.IMAP4('127.0.0.1', 1143)
m.login('u1', 'pass')
if mode == 'envelopes':
    for k in range(int(sys.argv[2])):
        m.select('INBOX', readonly=True)
        t, d = m.fetch('1:*', '(FLAGS INTERNALDATE RFC822.SIZE ENVELOPE)')
        assert t == 'OK' and len(d) >= 20000, (t, len(d))
elif mode == 'search':
    m.select('INBOX', readonly=True)
    for k in range(3):
        t, d = m.search(None, 'BODY', 'zebrafish7')
        assert t == 'OK' and len(d[0].split()) == 400, (t, d[0][:80])
elif mode == 'bodies':
    m.select('INBOX', readonly=True)
    r = random.Random(int(sys.argv[2]))
    for k in range(5):
        for i in range(200):
            t, d = m.fetch(str(r.randint(1, 20000)), '(BODY.PEEK[])')
            assert t == 'OK'
m.logout()
EOF
    # Postfix: the main.cf of the benchmark (made once by postfix-install of clang19)
    Q=/mnt/pbrd/pfq
    ss="$(ls "$W"/postfix-clang19/bin/smtp-source "$W"/postfix-clang19/libexec/smtp-source 2> /dev/null | head -n 1)"
    for r in $(seq 1 "$rounds"); do
        say "mail: round $r of $rounds"
        for v in $(order "$r"); do
            if have dovecot "$v"; then
                dovecot_conf "$v"
                find /mnt/pbrd/mail/u1/Maildir -maxdepth 1 -name 'dovecot*' -exec rm -f {} +
                cpuset -l "$last" "$W/dovecot-$v/sbin/dovecot" -c "$W/dovecot-$v.conf" > "$W/dovecot-start.log" 2>&1
                if waitport 1143; then
                    py=python3
                    timed "$v" dovecot "the first SELECT and FETCH of the envelopes of 20000 (the index built)" cpuset -l "$others" $py "$W/imapb.py" envelopes 1
                    timed "$v" dovecot "FETCH of the envelopes of 20000 with the index, 5 times" cpuset -l "$others" $py "$W/imapb.py" envelopes 5
                    timed "$v" dovecot "SEARCH BODY of a word in 20000, 3 times (no FTS)" cpuset -l "$others" $py "$W/imapb.py" search
                    timed "$v" dovecot "4 clients: 1000 whole messages each" sh -c '
                        for i in 1 2 3 4; do cpuset -l "$1" python3 "$2" bodies "$i" & done; wait' sh "$others" "$W/imapb.py"
                else
                    say "dovecot $v: did not start: $(tail -n 3 "$W/dovecot-start.log" "$W/dovecot.log" 2> /dev/null | tr '\n' ' ')"
                fi
                grep -E -i 'error|fatal|panic|killed' "$W/dovecot.log" 2> /dev/null | tail -n 5 | while IFS= read -r l; do say "dovecot $v: $l"; done
                : > "$W/dovecot.log"
                "$W/dovecot-$v/bin/doveadm" -c "$W/dovecot-$v.conf" stop > /dev/null 2>&1 || pkill -f "$W/dovecot-$v/sbin/dovecot"
                sleep 2
            fi
            if have postfix "$v"; then
                P="$W/pf-$v"
                rm -rf "$P" "$Q"; mkdir -p "$P/etc"
                cp "$W/postfix-$v/conf"/* "$P/etc/" 2> /dev/null
                (cd "$W/postfix-$v" && sh postfix-install -non-interactive install_root=/ tempdir="$W" config_directory="$P/etc" \
                    command_directory="$P/sbin" daemon_directory="$P/libexec" data_directory="$P/data" queue_directory="$Q" \
                    meta_directory="$P/etc" shlib_directory=no html_directory=no manpage_directory=no readme_directory=no \
                    sendmail_path="$P/sbin/sendmail" newaliases_path="$P/bin/newaliases" mailq_path="$P/bin/mailq" \
                    mail_owner=postfix setgid_group=maildrop) > "$W/pf-install-$v.log" 2>&1 ||
                    { say "postfix $v: postfix-install: $(tail -n 3 "$W/pf-install-$v.log" | tr '\n' ' ')"; continue; }
                pc="$P/sbin/postconf -c $P/etc"
                $pc -e "inet_interfaces = 127.0.0.1" "inet_protocols = ipv4" "mydestination =" "relay_domains =" \
                    "mynetworks = 127.0.0.0/8" "default_transport = discard" "local_transport = discard" \
                    "smtpd_recipient_restrictions = permit_mynetworks, reject" "smtpd_relay_restrictions = permit_mynetworks, reject" \
                    "alias_maps =" "alias_database =" "maillog_file = $P/maillog" "default_process_limit = 50" \
                    "smtpd_client_connection_count_limit = 0" "smtpd_client_message_rate_limit = 0" "compatibility_level = 3.11"
                sed -i '' -e 's/^smtp      inet/2525      inet/' "$P/etc/master.cf"
                cpuset -l "$last" "$P/sbin/postfix" -c "$P/etc" start > "$W/pf-start-$v.log" 2>&1
                if waitport 2525; then
                    timed "$v" postfix "20000 messages of 2 KB, 20 sessions, to discard (until the queue is empty)" sh -c '
                        cpuset -l "$1" "$2" -c -l 2048 -m 20000 -s 20 -f a@example.com -t b@remote.example 127.0.0.1:2525 || exit 1
                        n=0; while [ -n "$(find "$3" -type f \( -path "*/incoming/*" -o -path "*/active/*" -o -path "*/deferred/*" -o -path "*/maildrop/*" \) | head -n 1)" ]; do
                            n=$((n + 1)); [ "$n" -lt 6000 ] || exit 1; sleep 0.05; done' \
                        sh "$others" "$ss" "$Q"
                else
                    say "postfix $v: did not start: $(tail -n 3 "$W/pf-start-$v.log" "$P/maillog" 2> /dev/null | tr '\n' ' ')"
                fi
                "$P/sbin/postfix" -c "$P/etc" stop > /dev/null 2>&1
                sleep 2
            fi
        done
    done
}
