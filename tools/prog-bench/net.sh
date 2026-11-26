# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/net.sh: the group net of tools/prog-bench.sh (sourced by it): the clients
# and the proxy of this tree against an nginx of the packages (3 workers on the other CPUs;
# HTTP on 8081, HTTPS with HTTP/2 on 8443, a certificate of its own).
#
# curl 8.23.0 (ftp/curl, its distinfo): the OpenSSL of the base system, nghttp2 of the
# packages (ours: azsupport), static; on the last CPU: 20000 requests of 1 KB on one
# connection (HTTP/1.1), 5000 on one of TLS 1.3, 20000 over HTTP/2, 100 at once (-Z), 1 GB
# over HTTP and over HTTPS. wget 1.25.0 (ftp/wget, its distinfo): OpenSSL of the base
# system, PCRE2 of the packages, no NLS, libpsl, IDN: 2000 requests of 1 KB (-i, one
# connection), 1 GB over HTTP.
# 3proxy 0.9.9.3 (net/3proxy, its distinfo; CMake as the port), on the last CPU, curl of the
# packages and wrk on the others: through its HTTP proxy 5000 requests of 1 KB on one
# connection, 1 GB, and wrk (64 connections) with absolute URLs; through its SOCKS5 5000
# requests of 1 KB and 1 GB.

g_progs="curl wget 3proxy"

g_need() {
    need libnghttp2 pcre2
    if [ "$mode" = bench ]; then need nginx wrk; fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch curl-8.23.0.tar.xz 8dadd7d2536a314f982ad05a651b713f426bf7d02cc2c76cffb9796f2218e6c5 \
        https://curl.se/download/curl-8.23.0.tar.xz
    fetch wget-1.25.0.tar.lz 19225cc756b0a088fc81148dc6a40a0c8f329af7fd8483f1c7b2fe50f4e08a1f \
        https://ftp.gnu.org/gnu/wget/wget-1.25.0.tar.lz https://ftpmirror.gnu.org/gnu/wget/wget-1.25.0.tar.lz
    fetch 3proxy-0.9.9.3.tar.gz bfa49c54e30cdf79a255063b498d2163aa1f828f714a0ca11399387ee1badcbf \
        https://github.com/3proxy/3proxy/releases/download/0.9.9.3/3proxy-0.9.9.3.tar.gz
    unpack curl-8.23.0.tar.xz "$W/src/curl-$_v"
    _b="$W/b-curl-$_v.log"
    if (cd "$W/src/curl-$_v" && ./configure --prefix="$W/curl-$_v" --with-openssl=/usr --with-nghttp2=/usr/local \
        --without-libpsl --without-brotli --without-zstd --without-libidn2 --without-libssh2 --disable-ldap \
        --disable-ldaps --disable-shared --enable-static --disable-manual --disable-docs &&
        gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok curl "$_v" "$W/curl-$_v/bin/curl"
    else
        bno curl "$_v" "$_b"
    fi
    unpack wget-1.25.0.tar.lz "$W/src/wget-$_v"
    _b="$W/b-wget-$_v.log"
    if (cd "$W/src/wget-$_v" && ./configure --prefix="$W/wget-$_v" --with-ssl=openssl --without-libpsl \
        --disable-nls --disable-iri --without-metalink --without-libuuid CPPFLAGS=-I/usr/local/include \
        LDFLAGS="-L/usr/local/lib $LDFLAGS" && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok wget "$_v" "$W/wget-$_v/bin/wget"
    else
        bno wget "$_v" "$_b"
    fi
    unpack 3proxy-0.9.9.3.tar.gz "$W/src/3proxy-$_v"
    _b="$W/b-3proxy-$_v.log"
    if (cd "$W/src/3proxy-$_v" && cmake -S . -B _b -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG -DCMAKE_INSTALL_PREFIX="$W/3proxy-$_v" &&
        ninja -C _b && mkdir -p "$W/3proxy-$_v/bin" &&
        cp "$(find _b -name 3proxy -type f -perm -u+x | head -n 1)" "$W/3proxy-$_v/bin/3proxy") > "$_b" 2>&1 &&
        [ -x "$W/3proxy-$_v/bin/3proxy" ]; then
        bok 3proxy "$_v" "$W/3proxy-$_v/bin/3proxy"
    else
        bno 3proxy "$_v" "$_b"
    fi
}

g_keep() { echo "$W/curl-$1 $W/wget-$1 $W/3proxy-$1"; }

g_bench() {
    pbrd
    H=/mnt/pbrd/h
    mkdir -p "$H"
    head -c 1024 /etc/services > "$H/1k.html"
    head -c 1073741824 /dev/zero > "$H/1g.bin"
    chmod -R a+rX "$H"
    openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -keyout "$W/k.pem" -out "$W/c.pem" \
        -days 2 -subj /CN=localhost > /dev/null 2>&1 || die "net: no certificate"
    cat > "$W/ngx-net.conf" << EOF
worker_processes 3;
error_log $W/ngx-net-error.log warn;
pid $W/ngx-net.pid;
events { worker_connections 4096; }
http {
    access_log off;
    sendfile on;
    keepalive_requests 1000000;
    keepalive_timeout 60;
    server {
        listen 127.0.0.1:8081 backlog=4096;
        listen 127.0.0.1:8443 ssl backlog=4096;
        http2 on;
        ssl_certificate $W/c.pem;
        ssl_certificate_key $W/k.pem;
        ssl_protocols TLSv1.3;
        root $H;
    }
}
EOF
    cpuset -l "$others" nginx -c "$W/ngx-net.conf" || die "net: the nginx of the packages did not start"
    waitport 8443 || die "net: nginx does not listen"
    i=1; while [ "$i" -le 2000 ]; do echo "http://127.0.0.1:8081/1k.html?$i"; i=$((i + 1)); done > "$W/wget-urls.txt"
    printf 'nscache 65536\nmaxconn 1000\nauth none\nproxy -p3128 -i127.0.0.1 -e127.0.0.1\nsocks -p1080 -i127.0.0.1 -e127.0.0.1\n' > "$W/3proxy.cfg"
    printf 'wrk.method = "GET"\nwrk.path = "http://127.0.0.1:8081/1k.html"\nwrk.headers["Host"] = "127.0.0.1:8081"\n' > "$W/proxy.lua"
    u=http://127.0.0.1:8081 s=https://127.0.0.1:8443
    for r in $(seq 1 "$rounds"); do
        say "net: round $r of $rounds"
        for v in $(order "$r"); do
            if have curl "$v"; then
                c="$W/curl-$v/bin/curl"
                timed "$v" curl "HTTP/1.1: 20000 requests of 1 KB, one connection" cpuset -l "$last" "$c" -s "$u/1k.html?[1-20000]"
                timed "$v" curl "HTTPS, TLS 1.3: 5000 requests of 1 KB, one connection" cpuset -l "$last" "$c" -s -k "$s/1k.html?[1-5000]"
                timed "$v" curl "HTTP/2 over TLS: 20000 requests of 1 KB, 100 at once" cpuset -l "$last" "$c" -s -k --http2 -Z --parallel-max 100 "$s/1k.html?[1-20000]"
                timed "$v" curl "1 GB over HTTP" cpuset -l "$last" "$c" -s -o /dev/null "$u/1g.bin"
                timed "$v" curl "1 GB over HTTPS" cpuset -l "$last" "$c" -s -k -o /dev/null "$s/1g.bin"
            fi
            if have wget "$v"; then
                w="$W/wget-$v/bin/wget"
                timed "$v" wget "2000 requests of 1 KB (-i, one connection)" cpuset -l "$last" "$w" -q -O /dev/null -i "$W/wget-urls.txt"
                timed "$v" wget "1 GB over HTTP" cpuset -l "$last" "$w" -q -O /dev/null "$u/1g.bin"
            fi
            if have 3proxy "$v"; then
                cpuset -l "$last" "$W/3proxy-$v/bin/3proxy" "$W/3proxy.cfg" > "$W/3proxy-$v.log" 2>&1 &
                pid=$!
                if waitport 3128 && waitport 1080; then
                    timed "$v" 3proxy "HTTP proxy: 5000 requests of 1 KB, one connection (curl)" cpuset -l "$others" curl -s -x http://127.0.0.1:3128 "$u/1k.html?[1-5000]"
                    timed "$v" 3proxy "HTTP proxy: 1 GB (curl)" cpuset -l "$others" curl -s -x http://127.0.0.1:3128 -o /dev/null "$u/1g.bin"
                    wrkrate "$v" 3proxy "HTTP proxy: requests of 1 KB, 64 connections (wrk)" http://127.0.0.1:3128/ -s "$W/proxy.lua"
                    timed "$v" 3proxy "SOCKS5: 5000 requests of 1 KB, one connection (curl)" cpuset -l "$others" curl -s --socks5 127.0.0.1:1080 "$u/1k.html?[1-5000]"
                    timed "$v" 3proxy "SOCKS5: 1 GB (curl)" cpuset -l "$others" curl -s --socks5 127.0.0.1:1080 -o /dev/null "$u/1g.bin"
                else
                    say "3proxy $v: did not start: $(tail -n 3 "$W/3proxy-$v.log" | tr '\n' ' ')"
                fi
                kill "$pid"; wait "$pid" 2> /dev/null
            fi
        done
    done
    kill "$(cat "$W/ngx-net.pid")" 2> /dev/null
}
