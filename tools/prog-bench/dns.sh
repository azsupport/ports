# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/dns.sh: the group dns of tools/prog-bench.sh (sourced by it).
#
# Unbound 1.26.2 (dns/unbound, its distinfo) with the options of the port: ECDSA, libevent,
# threads, TCP Fast Open (client and server), expat and libevent of the packages (in our
# package those of azsupport), the OpenSSL of the base system, no nghttp2; its LTO as its
# configure takes it (--enable-flto by default). BIND 9.20.31 (dns/bind920, its distinfo)
# with the options of the port: DNSRPS, the OpenSSL of the base system, libedit, no tracing;
# libuv, liburcu, nghttp2 (DoH) and libidn2 of the packages.
# The servers: one thread (unbound num-threads 1, named -n 1) on the last CPU; dnsperf of the
# packages on the others (3 threads, 16 clients, 10 s), 10000 names in a random order:
# named authoritative for a zone of 10000 A records; unbound from its local-data (10000
# records) and from its cache (the zone of named forwarded, warmed up); queries per second.

g_progs="unbound bind"

g_need() {
    need libevent expat libuv userspace-rcu libnghttp2 libidn2
    if [ "$mode" = bench ]; then need dnsperf; fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch unbound-1.26.2.tar.gz d8ee7aa6bbb3ff1be7d9e57637d0d0ec2f18273a8efff1a0afe2c665858b96f7 \
        https://www.nlnetlabs.nl/downloads/unbound/unbound-1.26.2.tar.gz
    fetch bind-9.20.31.tar.xz 9bfecd503ec79209d321053689c794da9f8dba993a24e9cd6bd7aa87cdf4122f \
        https://downloads.isc.org/isc/bind9/9.20.31/bind-9.20.31.tar.xz https://ftp.isc.org/isc/bind9/9.20.31/bind-9.20.31.tar.xz
    unpack unbound-1.26.2.tar.gz "$W/src/unbound-$_v"
    _b="$W/b-unbound-$_v.log"
    if (cd "$W/src/unbound-$_v" && ./configure --prefix="$W/unbound-$_v" --with-ssl=/usr --with-libexpat=/usr/local \
        --with-libevent=/usr/local --without-libnghttp2 --enable-ecdsa --with-pthreads --enable-tfo-client \
        --enable-tfo-server --disable-shared && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok unbound "$_v" "$W/unbound-$_v/sbin/unbound"
    else
        bno unbound "$_v" "$_b"
    fi
    unpack bind-9.20.31.tar.xz "$W/src/bind-$_v"
    _b="$W/b-bind-$_v.log"
    if (cd "$W/src/bind-$_v" && CPPFLAGS=-I/usr/local/include LDFLAGS="-L/usr/local/lib $LDFLAGS" \
        ./configure --prefix="$W/bind-$_v" --enable-dnsrps --with-openssl=/usr --with-readline=libedit \
        --disable-tracing --disable-doc --without-lmdb --without-gssapi --disable-geoip &&
        gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok bind "$_v" "$W/bind-$_v/sbin/named"
    else
        bno bind "$_v" "$_b"
    fi
}

g_keep() { echo "$W/unbound-$1 $W/bind-$1"; }

# dperf <variant> <program> <bench> <port>: the queries per second of dnsperf
dperf() {
    cpuset -l "$others" dnsperf -s 127.0.0.1 -p "$4" -d "$W/dnsq.txt" -l 10 -c 16 -T 3 -q 300 > "$W/dnsperf.out" 2>&1
    # "  Queries per second:   123456.789012"
    _x="$(sed -n -E 's/^ *Queries per second: *([0-9.]+).*/\1/p' "$W/dnsperf.out")"
    [ -n "$_x" ] || say "$2 $3 $1: $(tail -n 3 "$W/dnsperf.out" | tr '\n' ' ')"
    _lost="$(sed -n -E 's/^ *Queries lost: *([0-9]+).*/\1/p' "$W/dnsperf.out")"
    [ "${_lost:-0}" = 0 ] || say "$2 $3 $1: $_lost queries lost"
    record "$2" "$3" qps higher "$1" "$_x"
}

g_bench() {
    mkdir -p "$W/named"
    {
        echo '$TTL 3600'
        echo '@ IN SOA ns.bench.test. hostmaster.bench.test. 1 3600 600 86400 3600'
        echo '@ IN NS ns.bench.test.'
        echo 'ns IN A 127.0.0.1'
        i=1; while [ "$i" -le 10000 ]; do echo "h$i IN A 10.$((i / 65536 % 256)).$((i / 256 % 256)).$((i % 256))"; i=$((i + 1)); done
    } > "$W/named/bench.test.zone"
    i=1; while [ "$i" -le 10000 ]; do echo "local-data: \"l$i.local.test. 3600 IN A 10.9.$((i / 256 % 256)).$((i % 256))\""; i=$((i + 1)); done > "$W/unbound-local.conf"
    # 10000 names in an order of their own (the same for every run)
    i=1; while [ "$i" -le 10000 ]; do echo "$(( (i * 7919) % 10000 + 1 ))"; i=$((i + 1)); done > "$W/dnsn.txt"
    sed 's/.*/h&.bench.test A/' "$W/dnsn.txt" > "$W/dnsq-bind.txt"
    sed 's/.*/l&.local.test A/' "$W/dnsn.txt" > "$W/dnsq-local.txt"
    cat > "$W/named/named.conf" << EOF
options {
    directory "$W/named";
    pid-file "$W/named/named.pid";
    listen-on port 5354 { 127.0.0.1; };
    listen-on-v6 { none; };
    recursion no;
    allow-query { any; };
    minimal-responses yes;
};
zone "bench.test" { type primary; file "$W/named/bench.test.zone"; };
EOF
    cat > "$W/unbound.conf" << EOF
server:
    interface: 127.0.0.1
    port: 5353
    num-threads: 1
    do-daemonize: no
    username: ""
    chroot: ""
    directory: "$W"
    pidfile: "$W/unbound.pid"
    use-syslog: no
    logfile: ""
    verbosity: 0
    access-control: 127.0.0.0/8 allow
    do-not-query-localhost: no
    harden-referral-path: no
    msg-cache-size: 64m
    rrset-cache-size: 128m
    local-zone: "local.test." static
    include: "$W/unbound-local.conf"
    domain-insecure: "bench.test."
forward-zone:
    name: "bench.test."
    forward-addr: 127.0.0.1@5354
EOF
    # named of clang19 for the cache of unbound (the forwarder), on the other CPUs
    for r in $(seq 1 "$rounds"); do
        say "dns: round $r of $rounds"
        for v in $(order "$r"); do
            if have bind "$v"; then
                cpuset -l "$last" "$W/bind-$v/sbin/named" -g -n 1 -c "$W/named/named.conf" > "$W/named-$v.log" 2>&1 &
                pid=$!
                sleep 2
                if kill -0 "$pid" 2> /dev/null; then
                    cp "$W/dnsq-bind.txt" "$W/dnsq.txt"
                    dperf "$v" bind "named, authoritative, 10000 A records" 5354
                else
                    say "bind $v: named did not start: $(tail -n 3 "$W/named-$v.log" | tr '\n' ' ')"
                fi
                kill "$pid"; wait "$pid" 2> /dev/null
            fi
            if have unbound "$v"; then
                cpuset -l "$others" "$W/bind-clang19/sbin/named" -g -n 1 -c "$W/named/named.conf" > "$W/named-fwd.log" 2>&1 &
                npid=$!
                cpuset -l "$last" "$W/unbound-$v/sbin/unbound" -d -c "$W/unbound.conf" > "$W/unbound-$v.log" 2>&1 &
                pid=$!
                sleep 2
                if kill -0 "$pid" 2> /dev/null; then
                    cp "$W/dnsq-local.txt" "$W/dnsq.txt"
                    dperf "$v" unbound "local-data, 10000 records" 5353
                    cp "$W/dnsq-bind.txt" "$W/dnsq.txt"
                    # the cache filled first
                    cpuset -l "$others" dnsperf -s 127.0.0.1 -p 5353 -d "$W/dnsq.txt" -n 1 -c 4 -q 50 > /dev/null 2>&1
                    dperf "$v" unbound "the cache (a zone forwarded to named)" 5353
                else
                    say "unbound $v: did not start: $(tail -n 3 "$W/unbound-$v.log" | tr '\n' ' ')"
                fi
                kill "$pid" "$npid"; wait "$pid" "$npid" 2> /dev/null
            fi
        done
    done
}
