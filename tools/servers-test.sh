#!/bin/sh
# servers-test.sh - test the server packages of the repository az, installed from it
# (aZ, 10.11.2026): git, apache24 with ap24-mod_maxminddb, memcached,
# mariadb1011-server and -client, vsftpd-ext, bind-tools, bind920 and qt-faststart. Each
# that is installed runs (its version) and loads only libraries of the base system,
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
#   bind-tools   dig with libidn2 (IDN)
#   bind920      named -V with TCP Fast Open; named-checkconf of named.conf.sample; named
#                on 127.0.0.1:15353 with a zone of its own: dig over UDP and TCP and
#                of an IDN name (libidn2 of dig), rndc status and stop
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
# other ports, in /usr/local/lib); else nothing, and why in libs_bad
libs_of() {
    _f="$1"; shift
    libs_bad=""
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
    echo "${_all# }"
}
# chk <name> <file> [<library of /usr/local/lib>...]: libs_of as a check
chk() {
    _n="$1"; _f="$2"; shift 2
    [ -e "$_f" ] || { fail "$_n: no $_f"; return 1; }
    if _r="$(libs_of "$_f" "$@")"; then pass "$_n: $_r"; else fail "$_n: $libs_bad"; return 1; fi
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
        libs_of "$f" libpcre2-8 > /dev/null || fail "mod_$m.so: $libs_bad"
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

# vsftpd-ext
if have vsftpd-ext; then
    ver vsftpd-ext "version 3" "$P/libexec/vsftpd" -v
    chk vsftpd "$P/libexec/vsftpd"
else skip vsftpd-ext; fi

# bind-tools
if have bind-tools; then
    ver bind-tools "DiG 9.20" "$P/bin/dig" -v
    if chk dig "$P/bin/dig" libisc libdns libns; then
        case " $(libs_of "$P/bin/dig" libisc libdns libns) " in
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
