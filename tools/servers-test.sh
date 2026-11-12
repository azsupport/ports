#!/bin/sh
# servers-test.sh - test the server packages of the repository az, installed from it
# (aZ, 10.11.2026): git, apache24 with ap24-mod_maxminddb, memcached,
# mariadb1011-server and -client, vsftpd-ext (and vsftpd-ext-openssl), bind-tools,
# bind920, vips and qt-faststart. Each that is installed runs (its version) and
# loads only libraries of the base system,
# of az (/usr/local/az/lib) and of our other ports (pcre2, curl, its own): our ports
# link each other's shared libraries. And:
#   git          git grep -P (PCRE2) in a repository made here; git-remote-http
#                with the libcurl.so.4 of our curl
#   apache24     httpd -t and a run with the modules of aZ's servers and
#                mod_maxminddb, a configuration of its own on 127.0.0.1:18080: a
#                page, the same through mod_rewrite, the server status
#   memcached    on 127.0.0.1:21211: its version, a set and a get
#   mariadb      a data directory of its own; the server started without a socket
#                option and the client without one, so that both take the socket
#                compiled in, /tmp/mysql.sock (that of my.cnf.sample too); InnoDB
#                the default engine, REGEXP (PCRE2), the compression provider
#                provider_lz4 (lz4 of az) installed and active
#   vsftpd-ext   on 127.0.0.1:12121, and vsftpd-ext-openssl in its place (from the
#                repository azbuild of test-programs.sh; vsftpd-ext back after it): an
#                HTTP method before the login closes the connection, and so does the
#                11th unknown command (CVE-2021-3618; with TLS: ALPN only "ftp");
#                cmds_denied takes XMKD, XRMD, XCWD, XCUP, XPWD and P@SW as MKD, RMD,
#                CWD, CDUP, PWD and PASV (CVE-2026-119567); deny_file refuses the paths
#                through a denied directory, and through a symbolic link to a denied
#                directory or file (by the real path, CVE-2015-1419), and an upload
#                named a.php.x.php with *.php in it (a * matches up to the last .php);
#                curl gets a file over FTP, and over FTPS with TLS 1.3 and 1.2,
#                uploads one; a data connection over TLS with the session of another
#                login is refused, with the login's own resumed (CVE-2026-119568);
#                the lifetime of the TLS 1.3 session tickets 7 days, not INT_MAX
#   bind-tools   dig with libidn2 (IDN)
#   bind920      named -V with TCP Fast Open; named-checkconf of named.conf.sample; named
#                on 127.0.0.1:15353 with a zone of its own: dig over UDP and TCP and
#                of an IDN name (libidn2 of dig), rndc status and stop
#   vips         the formats of aZ in vips --vips-config; JPEG, a WebP thumbnail,
#                PNG, GIF and AVIF made and read back; an animated WebP and GIF of 3
#                pages read whole; its libraries those of az and
#                of our glib, libexif, cgif, libimagequant and highway
#   qt-faststart an MP4 of our ffmpeg (moov after mdat): moov first after it
#
# Usage (FreeBSD, as root, the packages installed): sh tools/servers-test.sh
# Results: servers-results/tests.txt (one line per check, the summary at the end);
# exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/servers-results}"
T="${SERVERS_TEST_WORK:-/var/tmp/servers-test}"
P=/usr/local
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"; chmod 755 "$T"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
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
# chk <name> <file> [<library of /usr/local/lib>...]: libs_of as a check
chk() {
    _n="$1"; _f="$2"; shift 2
    [ -e "$_f" ] || { fail "$_n: no $_f"; return 1; }
    if libs_of "$_f" "$@"; then pass "$_n: $libs_out"; else fail "$_n: $libs_bad"; return 1; fi
}
# ver <name> <text of its version> <command>...: the first line with the text
ver() {
    _n="$1"; _w="$2"; shift 2
    _v="$("$@" 2>&1 | grep -m 1 -- "$_w")"
    if [ -n "$_v" ]; then pass "$_n: $_v"; else fail "$_n: no \"$_w\" in what $* says: $("$@" 2>&1 | head -n 1)"; fi
}
have() { pkg info -e "$1" 2>/dev/null; }
skip() { note "$1 is not installed: not tested"; }
export LANG=C.UTF-8

# git
if have git; then
    ver git "git version 2.56" "$P/bin/git" --version
    chk git "$P/bin/git" libpcre2-8
    chk git-remote-http "$P/libexec/git-core/git-remote-http" libpcre2-8 libcurl
    mkdir -p "$T/repo"
    if (cd "$T/repo" && "$P/bin/git" init -q && printf 'abc 123\nxyz\n' > f && "$P/bin/git" add f &&
            "$P/bin/git" -c user.name=t -c user.email=t@example.org commit -q -m t) > "$T/git.log" 2>&1; then
        r="$(cd "$T/repo" && "$P/bin/git" grep -P '\d{3}' 2>&1)"
        if [ "$r" = "f:abc 123" ]; then pass "git grep -P (PCRE2): $r"; else fail "git grep -P: $r"; fi
    else
        fail "git init, add, commit: $(tail -n 2 "$T/git.log" | tr '\n' ' ')"
    fi
    if ls "$P"/share/man/man1/git*.1.gz > /dev/null 2>&1; then fail "git: manual pages installed"; else pass "git: no manual pages"; fi
else skip git; fi

# Apache with the modules of aZ's servers and mod_maxminddb
if have apache24; then
    httpd="$P/sbin/httpd"
    ver apache24 "Apache/2.4" "$httpd" -v
    chk httpd "$httpd" libpcre2-8
    mods="mpm_prefork access_compat authz_core authn_core auth_basic authn_file authz_host authz_groupfile authz_user mime remoteip unixd status dir alias rewrite include log_config setenvif dumpio actions reqtimeout cgi env"
    have ap24-mod_maxminddb && mods="$mods maxminddb"
    for m in $mods; do
        f="$P/libexec/apache24/mod_$m.so"
        if [ ! -f "$f" ]; then fail "apache24: no mod_$m.so"; continue; fi
        libs_of "$f" libpcre2-8 || fail "mod_$m.so: $libs_bad"
    done
    case " $mods " in *" maxminddb "*) chk mod_maxminddb "$P/libexec/apache24/mod_maxminddb.so" ;; esac
    mkdir -p "$T/www"
    echo "apache of azsupport" > "$T/www/index.html"
    {
        echo "ServerRoot \"$P\""
        echo "Listen 127.0.0.1:18080"
        echo "ServerName 127.0.0.1"
        echo "PidFile \"$T/httpd.pid\""
        echo "ErrorLog \"$T/httpd-error.log\""
        for m in $mods; do echo "LoadModule ${m}_module libexec/apache24/mod_$m.so"; done
        echo "User www"
        echo "Group www"
        echo "TypesConfig etc/apache24/mime.types"
        echo "DocumentRoot \"$T/www\""
        echo "<Directory \"$T/www\">"
        echo "    Require all granted"
        echo "</Directory>"
        echo "DirectoryIndex index.html"
        echo "RewriteEngine On"
        echo "RewriteRule ^/old\$ /index.html [PT]"
        echo "<Location /server-status>"
        echo "    SetHandler server-status"
        echo "    Require ip 127.0.0.1"
        echo "</Location>"
        case " $mods " in *" maxminddb "*) echo "MaxMindDBEnable Off" ;; esac
    } > "$T/httpd.conf"
    if "$httpd" -t -f "$T/httpd.conf" > "$T/httpd-t.log" 2>&1; then pass "httpd -t: $(tail -n 1 "$T/httpd-t.log")"
    else fail "httpd -t: $(tail -n 3 "$T/httpd-t.log" | tr '\n' ' ')"; fi
    if "$httpd" -f "$T/httpd.conf" -k start > "$T/httpd-start.log" 2>&1; then
        sleep 2
        a="$(fetch -q -T 10 -o - http://127.0.0.1:18080/ 2>&1)"
        b="$(fetch -q -T 10 -o - http://127.0.0.1:18080/old 2>&1)"
        s="$(fetch -q -T 10 -o - 'http://127.0.0.1:18080/server-status?auto' 2>&1 | grep -m 1 'ServerVersion')"
        if [ "$a" = "apache of azsupport" ]; then pass "apache: the page"; else fail "apache: the page: $a"; fi
        if [ "$b" = "apache of azsupport" ]; then pass "apache: mod_rewrite"; else fail "apache: /old through mod_rewrite: $b"; fi
        if [ -n "$s" ]; then pass "apache: mod_status, $s"; else fail "apache: no server status"; fi
        "$httpd" -f "$T/httpd.conf" -k stop > /dev/null 2>&1
        sleep 1
    else
        fail "httpd -k start: $(tail -n 3 "$T/httpd-start.log" "$T/httpd-error.log" 2>/dev/null | tr '\n' ' ')"
    fi
else skip apache24; fi

# memcached
if have memcached; then
    ver memcached "memcached 1.6" "$P/bin/memcached" -V
    chk memcached "$P/bin/memcached"
    if "$P/bin/memcached" -d -u nobody -l 127.0.0.1 -p 21211 -P "$T/memcached.pid" > "$T/memcached.log" 2>&1; then
        sleep 1
        r="$(printf 'set k 0 0 5\r\nvalue\r\nget k\r\nversion\r\nquit\r\n' | nc -w 5 127.0.0.1 21211 2>&1 | tr -d '\r' | tr '\n' ' ')"
        case "$r" in *"STORED VALUE k 0 5 value END VERSION 1.6"*) pass "memcached: set, get, version: $r" ;;
            *) fail "memcached: $r" ;; esac
        [ -f "$T/memcached.pid" ] && kill "$(cat "$T/memcached.pid")" 2>/dev/null
    else
        fail "memcached -d: $(head -n 2 "$T/memcached.log" | tr '\n' ' ')"
    fi
else skip memcached; fi

# MariaDB: the socket compiled in, /tmp/mysql.sock
if have mariadb1011-server && have mariadb1011-client; then
    ver mariadb "10.11" "$P/bin/mariadb" --version
    chk mariadbd "$P/libexec/mariadbd" libpcre2-8
    chk mariadb "$P/bin/mariadb" libmariadb
    chk provider_lz4 "$P/lib/mysql/plugin/provider_lz4.so"
    if grep -q '^socket[[:space:]]*=[[:space:]]*/tmp/mysql.sock' "$P/etc/mysql/my.cnf.sample" 2>/dev/null; then
        pass "my.cnf.sample: socket = /tmp/mysql.sock"
    else
        fail "my.cnf.sample: $(grep -m 1 '^socket' "$P/etc/mysql/my.cnf.sample" 2>/dev/null || echo 'no socket line')"
    fi
    if [ -e /tmp/mysql.sock ]; then
        fail "mariadb: /tmp/mysql.sock is there already: not tested"
    elif "$P/bin/mariadb-install-db" --no-defaults --user=root --basedir="$P" --datadir="$T/db" \
            --auth-root-authentication-method=normal > "$T/install-db.log" 2>&1; then
        "$P/libexec/mariadbd" --no-defaults --user=root --basedir="$P" --datadir="$T/db" \
            --pid-file="$T/mariadbd.pid" --skip-networking --log-error="$T/mariadbd.err" > /dev/null 2>&1 &
        i=0
        while [ ! -S /tmp/mysql.sock ] && [ "$i" -lt 60 ]; do sleep 1; i=$((i + 1)); done
        if [ -S /tmp/mysql.sock ]; then
            pass "mariadbd: listens on /tmp/mysql.sock without --socket (${i} s)"
            r="$("$P/bin/mariadb" --no-defaults -u root -N -B -e "select @@socket; select @@default_storage_engine; select 'abc' regexp 'b+c'; install soname 'provider_lz4'; select plugin_status from information_schema.plugins where plugin_name = 'provider_lz4'; select version()" 2>&1 | tr '\n' ' ')"
            case "$r" in
                "/tmp/mysql.sock InnoDB 1 ACTIVE 10.11"*) pass "mariadb (its socket by default): socket, engine, REGEXP, provider_lz4, version: $r" ;;
                *) fail "mariadb: $r" ;;
            esac
            "$P/bin/mariadb-admin" --no-defaults -u root shutdown > "$T/shutdown.log" 2>&1 ||
                fail "mariadb-admin shutdown: $(head -n 2 "$T/shutdown.log" | tr '\n' ' ')"
            i=0
            while [ -S /tmp/mysql.sock ] && [ "$i" -lt 30 ]; do sleep 1; i=$((i + 1)); done
        else
            fail "mariadbd: no /tmp/mysql.sock after 60 s: $(tail -n 3 "$T/mariadbd.err" 2>/dev/null | tr '\n' ' ')"
            [ -f "$T/mariadbd.pid" ] && kill "$(cat "$T/mariadbd.pid")" 2>/dev/null
        fi
    else
        fail "mariadb-install-db: $(tail -n 3 "$T/install-db.log" | tr '\n' ' ')"
    fi
else skip "mariadb1011-server or mariadb1011-client"; fi

# vsftpd-ext and vsftpd-ext-openssl (the same files, with TLS; one of the two installed)
# vsf_wait <file> <extended regular expression> <tenths of a second>: until a line of
# the file matches, at most that long
vsf_wait() {
    _i=0
    while [ "$_i" -lt "$3" ] && ! grep -q -E "$2" "$1" 2>/dev/null; do sleep 0.1; _i=$((_i + 1)); done
}
# vsf_ftp <command>...: the replies of an anonymous login without TLS that sends the
# commands, each after the reply to the one before
vsf_ftp() {
    { sleep 0.5; printf 'USER anonymous\r\n'; sleep 0.4; printf 'PASS x@x\r\n'; sleep 0.4
      for _c in "$@"; do printf '%s\r\n' "$_c"; sleep 0.4; done; printf 'QUIT\r\n'; sleep 0.4; } |
        nc -w 5 127.0.0.1 12121 2>&1 | tr -d '\r'
}
# vsf_tls <TLS option of s_client> <name> <session file>: an anonymous login over TLS
# (AUTH TLS: s_client -starttls ftp, its session written to $W/<name>.sess) lists pub
# (NLST) on a data connection over TLS (PROT P, EPSV) that s_client makes with the
# session of the file: the replies in $W/<name>.out, what s_client says of the data
# connection in $W/<name>-data.out
vsf_tls() {
    _o="$W/$2.out"
    rm -f "$_o" "$W/$2.sess" "$W/$2-data.out"
    # the commands wait for the replies that s_client writes to $_o
    # shellcheck disable=SC2094
    { sleep 1; printf 'USER anonymous\r\nPASS x@x\r\nPBSZ 0\r\nPROT P\r\nEPSV\r\n'
      vsf_wait "$_o" '^229 ' 100
      printf 'NLST pub\r\n'
      vsf_wait "$_o" '^(226|425|426|451|522) ' 150
      printf 'QUIT\r\n'; sleep 1; } |
        timeout 60 openssl s_client -connect 127.0.0.1:12121 -starttls ftp "$1" -quiet \
            -sess_out "$W/$2.sess" > "$_o" 2>&1 &
    _c=$!
    vsf_wait "$_o" '^229 ' 100
    _dp="$(sed -n 's/^229 .*(|||\([0-9]*\)|).*/\1/p' "$_o" | tr -d '\r')"
    if [ -n "$_dp" ]; then
        timeout 20 openssl s_client -connect "127.0.0.1:$_dp" "$1" -sess_in "$3" -ign_eof \
            < /dev/null > "$W/$2-data.out" 2>&1
    fi
    wait "$_c"
}
# vsftpd_test <package>: the checks of its vsftpd on 127.0.0.1:12121 with a
# configuration of its own in $T/<package>: the anonymous login (as bin) in a root of
# its own, with a directory it may write in (pub/up), one deny_file denies
# (pub/.private) and symbolic links to it and to a denied file (pub/link, pub/s.txt),
# cmds_denied=XPWD,CWD,CDUP,MKD,RMD,P@SW (each name of the list and of the command
# taken as its RFC 959 one: files/patch-CVE-2026-119567) and
# deny_file={*.mp3,*.mov,.private,*.php} (files/patch-deny_file,
# files/patch-deny_file-realpath); vsftpd-ext-openssl with FTPS too: allow_anon_ssl,
# require_ssl_reuse=YES (its default), a certificate made here
vsftpd_test() {
    vp="$1"; W="$T/$vp"
    # -v writes to the descriptor 0 (that of the control connection under inetd)
    r="$("$P/libexec/vsftpd" -v 0>&1 2>&1)"
    case "$r" in *"version 3"*) pass "$vp: $r" ;;
        *) fail "$vp: no \"version 3\" in what vsftpd -v 0>&1 says: $r" ;; esac
    chk "$vp" "$P/libexec/vsftpd"
    mkdir -p "$W/ftproot/pub/.private" "$W/ftproot/pub/dir" "$W/ftproot/pub/up/old"
    echo secret > "$W/ftproot/pub/.private/secret"
    echo private > "$W/ftproot/pub/dir/.private"
    echo ok > "$W/ftproot/pub/ok.txt"
    echo mp3 > "$W/ftproot/pub/a.mp3"
    ln -s .private "$W/ftproot/pub/link"
    ln -s a.mp3 "$W/ftproot/pub/s.txt"
    echo upload > "$W/up.txt"
    chmod -R a+rX "$W/ftproot"
    chmod 777 "$W/ftproot/pub/up" "$W/ftproot/pub/.private"
    {
        printf '%s\n' listen=YES listen_address=127.0.0.1 listen_port=12121 background=NO \
            anonymous_enable=YES "anon_root=$W/ftproot" ftp_username=bin local_enable=NO \
            "secure_chroot_dir=$P/share/vsftpd/empty" write_enable=YES \
            anon_upload_enable=YES anon_mkdir_write_enable=YES anon_other_write_enable=YES \
            cmds_denied=XPWD,CWD,CDUP,MKD,RMD,P@SW 'deny_file={*.mp3,*.mov,.private,*.php}'
        if [ "$vp" = vsftpd-ext-openssl ]; then
            printf '%s\n' ssl_enable=YES allow_anon_ssl=YES require_ssl_reuse=YES \
                "rsa_cert_file=$W/cert.pem" "rsa_private_key_file=$W/key.pem"
        fi
    } > "$W/vsftpd.conf"
    if [ "$vp" = vsftpd-ext-openssl ] && ! openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
            -subj /CN=127.0.0.1 -keyout "$W/key.pem" -out "$W/cert.pem" > "$W/req.log" 2>&1; then
        fail "$vp: openssl req (the certificate of the test): $(tail -n 1 "$W/req.log")"
        return
    fi
    "$P/libexec/vsftpd" "$W/vsftpd.conf" > "$W/vsftpd.log" 2>&1 &
    vsf=$!
    sleep 1
    # CVE-2021-3618 (files/patch-CVE-2021-3618 of the port): before the login an HTTP
    # method closes the connection, and so does the 11th unknown command; with TLS a
    # client whose ALPN does not offer "ftp" is refused (alert 120)
    r="$(printf 'GET / HTTP/1.1\r\n' | nc -w 5 127.0.0.1 12121 2>&1 | tr -d '\r' | tr '\n' ' ')"
    case "$r" in *"500 HTTP protocol commands not allowed."*) pass "$vp: an HTTP method before the login: $r" ;;
        *) fail "$vp: an HTTP method before the login: $r $(head -n 2 "$W/vsftpd.log" | tr '\n' ' ')" ;; esac
    r="$( (i=0; while [ "$i" -lt 11 ]; do printf 'XYZ\r\n'; sleep 0.2; i=$((i + 1)); done) |
        nc -w 5 127.0.0.1 12121 2>&1 | tr -d '\r' | tr '\n' ' ')"
    case "$r" in *"530 Please login with USER and PASS. 500 Too many errors."*)
            pass "$vp: the 11th unknown command before the login: 500 Too many errors." ;;
        *) fail "$vp: 11 unknown commands before the login: $r" ;; esac
    if [ "$vp" = vsftpd-ext-openssl ]; then
        r="$( { sleep 1; printf 'QUIT\r\n'; sleep 1; } | timeout 20 openssl s_client -connect 127.0.0.1:12121 \
            -starttls ftp -alpn http/1.1 -quiet 2>&1 | tr -d '\r' | tr '\n' ' ')"
        s="$( { sleep 1; printf 'QUIT\r\n'; sleep 1; } | timeout 20 openssl s_client -connect 127.0.0.1:12121 \
            -starttls ftp -alpn ftp -quiet 2>&1 | tr -d '\r' | tr '\n' ' ')"
        case "$r:$s" in *"alert number 120"*:*"221 Goodbye."*)
                pass "$vp: ALPN http/1.1 refused (alert 120), ALPN ftp served" ;;
            *) fail "$vp: ALPN http/1.1: $r; ALPN ftp: $s" ;; esac
    fi
    # CVE-2026-119567: the other names of denied commands (XPWD denies PWD too, P@SW
    # PASV); XMKD would make pub/up/new, XRMD remove pub/up/old
    r="$(vsf_ftp XPWD PWD 'XCWD pub' XCUP 'XMKD pub/up/new' 'XRMD pub/up/old' P@SW PASV)"
    n="$(printf '%s\n' "$r" | grep -c '^550 Permission denied.')"
    if [ "$n" = 8 ] && [ -d "$W/ftproot/pub/up/old" ] && [ ! -e "$W/ftproot/pub/up/new" ]; then
        pass "$vp: cmds_denied=XPWD,CWD,CDUP,MKD,RMD,P@SW: XPWD, PWD, XCWD, XCUP, XMKD, XRMD, P@SW and PASV refused (CVE-2026-119567)"
    else
        fail "$vp: cmds_denied=XPWD,CWD,CDUP,MKD,RMD,P@SW: $n of XPWD, PWD, XCWD, XCUP, XMKD, XRMD, P@SW and PASV refused: $(printf '%s\n' "$r" | grep -E '^[1-5][0-9][0-9] ' | tr '\n' ' ')"
    fi
    # deny_file: the paths through a denied directory (pub/.private), to it and a
    # delete in it are refused as the name itself is
    r="$(vsf_ftp 'SIZE pub/ok.txt' 'SIZE pub/.private/secret' 'SIZE pub/dir/.private' 'SIZE pub/a.mp3' \
        'SIZE /pub/.private/secret' 'SIZE pub//.private/../.private/secret' 'SIZE pub/.private/' \
        'DELE pub/.private/secret')"
    s="$(printf '%s\n' "$r" | grep -E '^(213|250|550) ' | tr '\n' ' ')"
    [ -f "$W/ftproot/pub/.private/secret" ] || s="$s(pub/.private/secret deleted)"
    d='550 Permission denied.'
    case "$s" in "213 3 $d $d $d $d $d $d $d ")
            pass "$vp: deny_file={*.mp3,*.mov,.private,*.php}: pub/ok.txt read; pub/dir/.private, pub/a.mp3, the paths through pub/.private and to it and DELE pub/.private/secret refused" ;;
        *) fail "$vp: deny_file={*.mp3,*.mov,.private,*.php}: the SIZE of pub/ok.txt, pub/.private/secret, pub/dir/.private, pub/a.mp3, /pub/.private/secret, pub//.private/../.private/secret and pub/.private/, DELE pub/.private/secret: $s" ;;
    esac
    # deny_file by the real path (files/patch-deny_file-realpath, CVE-2015-1419): a
    # path through the symbolic link pub/link to pub/.private and the link pub/s.txt to
    # pub/a.mp3 are refused (they were read)
    r="$(vsf_ftp 'SIZE pub/link/secret' 'SIZE /pub/link/secret' 'SIZE pub/s.txt')"
    s="$(printf '%s\n' "$r" | grep -E '^(213|250|550) ' | tr '\n' ' ')"
    case "$s" in "$d $d $d ")
            pass "$vp: deny_file by the real path: pub/link/secret (pub/link -> .private) and pub/s.txt (-> a.mp3) refused" ;;
        *) fail "$vp: deny_file by the real path: the SIZE of pub/link/secret, /pub/link/secret and pub/s.txt (pub/link -> .private, pub/s.txt -> a.mp3): $s" ;;
    esac
    # a client: our curl gets a file over FTP (EPSV: PASV is denied) and, with TLS, over
    # FTPS with TLS 1.3 and 1.2: require_ssl_reuse, so its data connection resumed the
    # session of its control connection
    if [ -x "$P/bin/curl" ]; then
        r="$("$P/bin/curl" -sS --max-time 20 --ftp-method nocwd "ftp://127.0.0.1:12121/pub/ok.txt" 2>&1)"
        if [ "$r" = ok ]; then pass "$vp: FTP: curl got pub/ok.txt"; else fail "$vp: FTP: curl: $r"; fi
        # uploads: a.txt is stored; with *.php in deny_file a.php.x.php is refused (the
        # * of the filter takes up to the last .php: Apache would run the file as PHP),
        # and so is a name through the link to the denied directory
        for f in a.txt a.php.x.php link-new.txt; do
            u="pub/up/$f"; [ "$f" = link-new.txt ] && u=pub/link/new.txt
            r="$("$P/bin/curl" -sS --max-time 20 --ftp-method nocwd -T "$W/up.txt" "ftp://127.0.0.1:12121/$u" 2>&1)"
            e=$?
            if [ "$f" = a.txt ]; then
                if [ "$e" = 0 ] && [ "$(cat "$W/ftproot/$u" 2>/dev/null)" = upload ]; then pass "$vp: FTP: curl uploaded $u"
                else fail "$vp: FTP: curl -T $u: exit $e: $r"; fi
            elif [ "$e" != 0 ] && [ ! -e "$W/ftproot/pub/up/$f" ] && [ ! -e "$W/ftproot/pub/.private/new.txt" ]; then
                pass "$vp: deny_file: the upload of $u refused: $(printf '%s' "$r" | tr '\n' ' ')"
            else
                fail "$vp: deny_file: the upload of $u: exit $e: $r$(ls "$W/ftproot/pub/up" "$W/ftproot/pub/.private" 2>&1 | tr '\n' ' ')"
            fi
        done
        if [ "$vp" = vsftpd-ext-openssl ]; then
            for v in 1.3 1.2; do
                r="$("$P/bin/curl" -sS --max-time 20 -k --ssl-reqd "--tlsv$v" --tls-max "$v" --ftp-method nocwd \
                    "ftp://127.0.0.1:12121/pub/ok.txt" 2>&1)"
                if [ "$r" = ok ]; then
                    pass "$vp: FTPS, TLS $v: curl got pub/ok.txt, its data connection resumed the session of its control connection (require_ssl_reuse)"
                else
                    fail "$vp: FTPS, TLS $v: curl: $r"
                fi
            done
        fi
    else
        note "$vp: no $P/bin/curl: no file got by a client"
    fi
    # CVE-2026-119568: a data connection over TLS made with the session of another
    # login (b, logged in meanwhile) is refused, one with the login's own resumed
    if [ "$vp" = vsftpd-ext-openssl ]; then
        for v in 1.3 1.2; do
            o="-tls1_${v#1.}"
            rm -f "$W/b.out" "$W/b.sess" "$W/b.done"
            { sleep 1; printf 'USER anonymous\r\nPASS x@x\r\n'; vsf_wait "$W/b.done" end 300
              printf 'QUIT\r\n'; sleep 1; } |
                timeout 60 openssl s_client -connect 127.0.0.1:12121 -starttls ftp "$o" -quiet \
                    -sess_out "$W/b.sess" > "$W/b.out" 2>&1 &
            b=$!
            vsf_wait "$W/b.out" '^230 ' 100
            if [ -s "$W/b.sess" ]; then
                vsf_tls "$o" ab "$W/b.sess"
                vsf_tls "$o" aa "$W/aa.sess"
            fi
            # the lifetime of the session tickets of TLS 1.3: 7 days, which RFC 8446 allows
            # at most (require_ssl_reuse sets the timeout of the sessions to INT_MAX, which
            # clients on GnuTLS refused as the lifetime, Debian #929958; OpenSSL 3 sends
            # 7 days at most)
            if [ "$v" = 1.3 ]; then
                lt="$(openssl sess_id -in "$W/b.sess" -noout -text 2>/dev/null | sed -n 's/.*lifetime hint: *\([0-9]*\).*/\1/p')"
                if [ "$lt" = 604800 ]; then pass "$vp: FTPS, TLS 1.3: the lifetime of the session tickets 604800 s (7 days)"
                else fail "$vp: FTPS, TLS 1.3: the lifetime of the session tickets ${lt:-not found}, not 604800"; fi
            fi
            echo end > "$W/b.done"
            wait "$b"
            if [ ! -s "$W/b.sess" ]; then
                fail "$vp: FTPS, TLS $v: no session of the login b: $(tr -d '\r' < "$W/b.out" | tail -n 3 | tr '\n' ' ')"
                continue
            fi
            for w in ab aa; do
                c="$(tr -d '\r' < "$W/$w.out" | grep -E '^(150|226|425|426|451|522) ' | tr '\n' ' ')"
                s="$(grep -E '^(New|Reused),' "$W/$w-data.out" 2>/dev/null | head -n 1)"
                if [ "$w" = ab ]; then
                    case "$c" in *"226 "*) fail "$vp: FTPS, TLS $v: a data connection with the session of another login served (${s:-no data connection}): $c" ;;
                        *"522 "*) pass "$vp: FTPS, TLS $v: a data connection with the session of another login refused (${s:-no data connection}): $c(CVE-2026-119568)" ;;
                        *) fail "$vp: FTPS, TLS $v: a data connection with the session of another login (${s:-no data connection}): $c$(tr -d '\r' < "$W/$w.out" | tail -n 2 | tr '\n' ' ')" ;; esac
                else
                    case "$c:$s" in *"226 "*:Reused*) pass "$vp: FTPS, TLS $v: the login's own session resumed on its data connection ($s): $c" ;;
                        *) fail "$vp: FTPS, TLS $v: the login's own session on its data connection (${s:-no data connection}): $c$(tr -d '\r' < "$W/$w.out" | tail -n 2 | tr '\n' ' ')" ;; esac
                fi
            done
        done
    fi
    kill "$vsf" 2>/dev/null
    wait "$vsf" 2>/dev/null
}
if have vsftpd-ext; then
    vsftpd_test vsftpd-ext
    # vsftpd-ext-openssl from the repository azbuild of test-programs.sh in the place of
    # vsftpd-ext (pkg install takes it away, the same files, as on a server), and
    # vsftpd-ext back after its checks
    if [ -n "$(pkg rquery -r azbuild '%n' vsftpd-ext-openssl 2>/dev/null)" ]; then
        CONSERVATIVE_UPGRADE=no pkg install -y -f -r azbuild vsftpd-ext-openssl > "$T/pkg-vsftpd.log" 2>&1
        if have vsftpd-ext-openssl && ! have vsftpd-ext; then
            vsftpd_test vsftpd-ext-openssl
        else
            fail "vsftpd-ext-openssl: not installed in the place of vsftpd-ext: $(tail -n 2 "$T/pkg-vsftpd.log" | tr '\n' ' ')"
        fi
        CONSERVATIVE_UPGRADE=no pkg install -y -f -r azbuild vsftpd-ext >> "$T/pkg-vsftpd.log" 2>&1
        if have vsftpd-ext && ! have vsftpd-ext-openssl; then
            pass "vsftpd-ext: back in the place of vsftpd-ext-openssl"
        else
            fail "vsftpd-ext: not back in the place of vsftpd-ext-openssl: $(tail -n 2 "$T/pkg-vsftpd.log" | tr '\n' ' ')"
        fi
    else
        note "vsftpd-ext-openssl: not in a repository azbuild (that of test-programs.sh): not tested"
    fi
elif have vsftpd-ext-openssl; then
    vsftpd_test vsftpd-ext-openssl
else skip "vsftpd-ext and vsftpd-ext-openssl"; fi

# bind-tools
if have bind-tools; then
    ver bind-tools "DiG 9.20" "$P/bin/dig" -v
    if chk dig "$P/bin/dig" libisc libdns libns; then
        case " $libs_out " in
            *"/libidn2.so"*) pass "dig: IDN with libidn2 of az" ;;
            *) fail "dig: no libidn2 (IDN)" ;;
        esac
    fi
    for b in host nslookup nsupdate delv; do chk "$b" "$P/bin/$b" libisc libdns libns; done
else skip bind-tools; fi

# bind920: named on 127.0.0.1:15353 with a zone of its own (an IDN name in it), rndc
# on 127.0.0.1:15953 with a key of rndc-confgen; dig of bind-tools asks
if have bind920; then
    ver bind920 "BIND 9.20" "$P/sbin/named" -v
    chk named "$P/sbin/named" libisc libdns libns
    for b in rndc rndc-confgen; do chk "$b" "$P/sbin/$b" libisc libdns libns; done
    for b in named-checkconf named-checkzone; do chk "$b" "$P/bin/$b" libisc libdns libns; done
    case "$("$P/sbin/named" -V 2>&1)" in
        *--enable-tcp-fastopen*) pass "named -V: --enable-tcp-fastopen" ;;
        *) fail "named -V: no --enable-tcp-fastopen" ;;
    esac
    if [ -x "$P/etc/rc.d/named" ]; then pass "the rc script named"; else fail "no $P/etc/rc.d/named"; fi
    if r="$("$P/bin/named-checkconf" "$P/etc/namedb/named.conf.sample" 2>&1)"; then
        pass "named-checkconf of named.conf.sample"
    else
        fail "named-checkconf of named.conf.sample: $(printf '%s\n' "$r" | head -n 2 | tr '\n' ' ')"
    fi
    n="$T/named"; mkdir -p "$n"
    idn="$(printf 'b\303\274cher.az.test')"
    # shellcheck disable=SC2016
    printf '%s\n' '$TTL 300' '@ IN SOA ns.az.test. hostmaster.az.test. 1 3600 600 86400 300' '@ IN NS ns' \
        'ns IN A 127.0.0.1' 'www IN A 192.0.2.1' 'xn--bcher-kva IN A 192.0.2.2' > "$n/az.test.db"
    if "$P/sbin/rndc-confgen" -a -c "$n/rndc.key" -k rndc-key > "$T/rndc-confgen.log" 2>&1; then
        printf '%s\n' "include \"$n/rndc.key\";" \
            'controls { inet 127.0.0.1 port 15953 allow { 127.0.0.1; } keys { "rndc-key"; }; };' \
            "options { directory \"$n\"; pid-file \"$n/named.pid\"; listen-on port 15353 { 127.0.0.1; };" \
            '    listen-on-v6 { none; }; recursion no; };' \
            'zone "az.test" { type primary; file "az.test.db"; };' > "$n/named.conf"
        if r="$("$P/bin/named-checkconf" -z "$n/named.conf" 2>&1)"; then
            pass "named-checkconf -z: $(printf '%s\n' "$r" | head -n 1)"
            "$P/sbin/named" -g -c "$n/named.conf" > "$T/named.log" 2>&1 &
            np=$!
            i=0; r=""
            while [ "$i" -lt 30 ]; do
                r="$("$P/bin/dig" @127.0.0.1 -p 15353 +short +time=1 +tries=1 www.az.test A 2>&1)"
                [ "$r" = 192.0.2.1 ] && break
                sleep 1; i=$((i + 1))
            done
            if [ "$r" = 192.0.2.1 ]; then
                pass "named: www.az.test A over UDP: $r (${i} s)"
                r="$("$P/bin/dig" @127.0.0.1 -p 15353 +short +tcp www.az.test A 2>&1)"
                if [ "$r" = 192.0.2.1 ]; then pass "named: over TCP: $r"; else fail "named: over TCP: $r"; fi
                r="$(env LC_ALL=C.UTF-8 "$P/bin/dig" @127.0.0.1 -p 15353 +short "$idn" A 2>&1)"
                if [ "$r" = 192.0.2.2 ]; then pass "dig: the IDN name $idn (xn--bcher-kva.az.test): $r"
                else fail "dig: the IDN name $idn: $r"; fi
                r="$("$P/sbin/rndc" -k "$n/rndc.key" -s 127.0.0.1 -p 15953 status 2>&1)"
                case "$r" in *"server is up and running"*) pass "rndc status: $(printf '%s\n' "$r" | grep -m 1 '^version')" ;;
                    *) fail "rndc status: $(printf '%s\n' "$r" | tail -n 2 | tr '\n' ' ')" ;; esac
                "$P/sbin/rndc" -k "$n/rndc.key" -s 127.0.0.1 -p 15953 stop > /dev/null 2>&1
                i=0
                while kill -0 "$np" 2>/dev/null && [ "$i" -lt 15 ]; do sleep 1; i=$((i + 1)); done
            else
                fail "named: no answer on 127.0.0.1:15353 after 30 s ($r): $(tail -n 3 "$T/named.log" | tr '\n' ' ')"
            fi
            kill "$np" 2>/dev/null
        else
            fail "named-checkconf -z: $(printf '%s\n' "$r" | head -n 3 | tr '\n' ' ')"
        fi
    else
        fail "rndc-confgen -a: $(head -n 2 "$T/rndc-confgen.log" | tr '\n' ' ')"
    fi
else skip bind920; fi

# vips: the formats of aZ in its configuration; noise saved as JPEG, a WebP thumbnail
# of it, PNG, GIF (cgif with libimagequant) and AVIF (libheif with SVT-AV1), each read
# back with its loader
if have vips; then
    vl="libvips libglib-2.0 libgobject-2.0 libgio-2.0 libgmodule-2.0 libintl libpcre2 libffi libexif libcgif libimagequant libhwy"
    ver vips "vips-8.18" "$P/bin/vips" --version
    # shellcheck disable=SC2086
    chk vips "$P/bin/vips" $vl
    # shellcheck disable=SC2086
    chk vipsthumbnail "$P/bin/vipsthumbnail" $vl
    c="$("$P/bin/vips" --vips-config 2>&1)"
    for w in "JPEG load/save with libjpeg: true" "PNG load/save with libpng: true" \
            "WebP load/save with libwebp: true" "HEIC/AVIF load/save with libheif: true" \
            "GIF save with cgif: true" "image quantisation with imagequant: true" \
            "EXIF metadata support with libexif: true" "ICC profile support with lcms2: true" \
            "SIMD support with libhwy: true" "Magick load/save with MagickCore: false" \
            "TIFF load/save with libtiff: false"; do
        case "$c" in *"$w"*) pass "vips --vips-config: $w" ;; *) fail "vips --vips-config: not \"$w\"" ;; esac
    done
    v="$T/vips"; mkdir -p "$v"
    if "$P/bin/vips" gaussnoise "$v/n.jpg" 128 96 > "$T/vips.log" 2>&1 &&
            "$P/bin/vipsthumbnail" "$v/n.jpg" --size 64 -o "$v/t.webp" >> "$T/vips.log" 2>&1 &&
            "$P/bin/vips" copy "$v/n.jpg" "$v/n.png" >> "$T/vips.log" 2>&1 &&
            "$P/bin/vips" copy "$v/n.png" "$v/n.gif" >> "$T/vips.log" 2>&1 &&
            "$P/bin/vips" copy "$v/n.jpg" "$v/n.avif" >> "$T/vips.log" 2>&1; then
        for f in n.jpg:jpegload t.webp:webpload n.png:pngload n.gif:gifload n.avif:heifload; do
            h="$("$P/bin/vipsheader" "$v/${f%%:*}" 2>&1)"
            case "$h" in *"${f#*:}"*) pass "vips: ${f%%:*}: ${h#"$v"/}" ;; *) fail "vips: ${f%%:*}: $h" ;; esac
        done
        case "$("$P/bin/vipsheader" "$v/t.webp" 2>&1)" in *" 64x48 "*) pass "vipsthumbnail: 128x96 to 64x48" ;;
            *) fail "vipsthumbnail: $("$P/bin/vipsheader" "$v/t.webp" 2>&1)" ;; esac
        # an animated WebP and GIF of 3 pages read whole (n=-1), through the checks of the
        # total height (graphics/vips/files/patch-webpload-height, patch-gifload-height);
        # three different pages (the encoders merge equal ones into one frame)
        if "$P/bin/vips" colourspace "$v/n.png" "$v/c1.png" srgb >> "$T/vips.log" 2>&1 &&
                "$P/bin/vips" invert "$v/c1.png" "$v/c2.png" >> "$T/vips.log" 2>&1 &&
                "$P/bin/vips" flip "$v/c1.png" "$v/c3.png" horizontal >> "$T/vips.log" 2>&1 &&
                "$P/bin/vips" arrayjoin "$v/c1.png $v/c2.png $v/c3.png" "$v/s.png" --across 1 >> "$T/vips.log" 2>&1 &&
                "$P/bin/vips" copy "$v/s.png" "$v/a.webp[page-height=96]" >> "$T/vips.log" 2>&1 &&
                "$P/bin/vips" copy "$v/s.png" "$v/a.gif[page-height=96]" >> "$T/vips.log" 2>&1; then
            for f in a.webp a.gif; do
                h="$("$P/bin/vipsheader" -f height "$v/${f}[n=-1]" 2>&1) $("$P/bin/vipsheader" -f n-pages "$v/$f" 2>&1)"
                if [ "$h" = "288 3" ]; then pass "vips: $f of 3 pages, n=-1: height 288"; else fail "vips: $f of 3 pages, n=-1: $h"; fi
            done
        else
            fail "vips: an animated WebP and GIF: $(tail -n 3 "$T/vips.log" | tr '\n' ' ')"
        fi
    else
        fail "vips: $(tail -n 3 "$T/vips.log" | tr '\n' ' ')"
    fi
else skip vips; fi

# qt-faststart, on an MP4 of our ffmpeg (moov after mdat, as ffmpeg writes it)
if have qt-faststart; then
    chk qt-faststart "$P/bin/qt-faststart"
    if have ffmpeg; then
        if "$P/bin/ffmpeg" -v error -f lavfi -i testsrc=duration=1:size=64x64:rate=10 -c:v libx264 \
                -pix_fmt yuv420p "$T/in.mp4" > "$T/ffmpeg.log" 2>&1 &&
                "$P/bin/qt-faststart" "$T/in.mp4" "$T/out.mp4" > "$T/qt.log" 2>&1; then
            o1="$("$P/bin/ffprobe" -v trace "$T/in.mp4" 2>&1 | grep -o "type:'m[od][oa][vt]'" | head -n 2 | tr '\n' ' ')"
            o2="$("$P/bin/ffprobe" -v trace "$T/out.mp4" 2>&1 | grep -o "type:'m[od][oa][vt]'" | head -n 2 | tr '\n' ' ')"
            case "$o2" in "type:'moov' type:'mdat' ") pass "qt-faststart: moov before mdat ($o1-> $o2)" ;;
                *) fail "qt-faststart: the atoms of out.mp4: $o2 (in.mp4: $o1)" ;; esac
        else
            fail "qt-faststart: $(tail -n 2 "$T/ffmpeg.log" "$T/qt.log" 2>/dev/null | tr '\n' ' ')"
        fi
    else
        note "ffmpeg is not installed: qt-faststart not run on a file"
    fi
else skip qt-faststart; fi

echo "tests: $ok ok, $bad failed" >> "$out"
cat "$out"
[ "$bad" = 0 ]
