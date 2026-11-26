# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/cache.sh: the group cache of tools/prog-bench.sh (sourced by it).
#
# memcached 1.6.45 (databases/memcached, its distinfo) as the port: libevent of the packages
# (in our package that of azsupport), --enable-64bit, no TLS, SASL, DTrace, docs. The server:
# one worker thread (-t 1) on the last CPU, 1 GB; the load: memaslap of libmemcached (the
# package) on the others, 3 threads, 48 connections, keys of 64 bytes, values of 512, 15
# seconds after 5 of filling: get and set 9:1, and the same with gets of 10 keys at once
# (-d 10); the operations per second.
#
# gearmand 2.2.0 (devel/gearmand, its distinfo) with the patches of the port (the fixes of
# master after 2.2.0, files/patch-*) and its options: libevent, Boost.Program_options and
# libuuid of the packages, SQLite (the persistent queue, off here), no TLS, no PIE (the port:
# PIE_UNSAFE); its blobslap_client and blobslap_worker (of the build by clang19 for all). The
# server on the last CPU (-t 1), 4 workers and the client on the others: 100000 jobs of 64
# to 512 bytes, 100 at once, timed.

g_progs="memcached gearmand"

g_need() {
    need libevent boost-libs libuuid gperf autoconf automake libtool sqlite3
    if [ "$mode" = bench ]; then need libmemcached; fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch memcached-1.6.45.tar.gz d362c64e6d8d5287153501eabf7c85b4a761432fbf53f5d7b085d0bb1653c1dd \
        https://www.memcached.org/files/memcached-1.6.45.tar.gz
    fetch gearmand-2.2.0.tar.gz fec69ec0e893147a9eb8bfa203e173cc5598adc372e307fea12d587d13071d75 \
        https://github.com/gearman/gearmand/releases/download/2.2.0/gearmand-2.2.0.tar.gz
    unpack memcached-1.6.45.tar.gz "$W/src/memcached-$_v"
    _b="$W/b-memcached-$_v.log"
    if (cd "$W/src/memcached-$_v" && ./configure --prefix="$W/memcached-$_v" --enable-64bit --disable-coverage \
        --disable-docs --disable-sasl --disable-dtrace --disable-tls --with-libevent=/usr/local &&
        gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok memcached "$_v" "$W/memcached-$_v/bin/memcached"
    else
        bno memcached "$_v" "$_b"
    fi
    unpack gearmand-2.2.0.tar.gz "$W/src/gearmand-$_v"
    _b="$W/b-gearmand-$_v.log"
    : > "$_b"
    for p in "$top"/devel/gearmand/files/patch-*; do
        (cd "$W/src/gearmand-$_v" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    # PIE_UNSAFE of the port
    _cf="$(echo "$CFLAGS" | sed -e 's/ -fPIE//' -e 's/ -fPIC//')"
    _cxf="$(echo "$CXXFLAGS" | sed -e 's/ -fPIE//' -e 's/ -fPIC//')"
    _lf="$(echo "$LDFLAGS" | sed -e 's/-pie //')"
    if (cd "$W/src/gearmand-$_v" && autoreconf -fi && MAKE=gmake CFLAGS="$_cf" CXXFLAGS="$_cxf" LDFLAGS="-L/usr/local/lib $_lf" \
        CPPFLAGS=-I/usr/local/include LIBS=-lexecinfo ./configure --prefix="$W/gearmand-$_v" \
        --disable-dtrace --disable-hiredis --disable-libdrizzle --disable-libmemcached --disable-libpq \
        --disable-libtokyocabinet --disable-shared --enable-static --disable-wolfssl --disable-ssl \
        --enable-jobserver=no --with-boost=/usr/local --with-mysql=no --with-postgresql=no --with-sqlite3=/usr/local &&
        gmake -j"$ncpu" && mkdir -p "$W/gearmand-$_v/bin" &&
        cp gearmand/gearmand benchmark/blobslap_client benchmark/blobslap_worker "$W/gearmand-$_v/bin/") >> "$_b" 2>&1; then
        bok gearmand "$_v" "$W/gearmand-$_v/bin/gearmand"
    else
        bno gearmand "$_v" "$_b"
    fi
}

g_keep() { echo "$W/memcached-$1 $W/gearmand-$1"; }

g_bench() {
    printf 'key\n64 64 1\nvalue\n512 512 1\ncmd\n0 0.1\n1 0.9\n' > "$W/memaslap.cnf"
    printf 'key\n64 64 1\nvalue\n512 512 1\ncmd\n0 1\n1 0\n' > "$W/memaslap-set.cnf"
    for r in $(seq 1 "$rounds"); do
        say "cache: round $r of $rounds"
        for v in $(order "$r"); do
            if have memcached "$v"; then
                cpuset -l "$last" "$W/memcached-$v/bin/memcached" -u nobody -l 127.0.0.1 -p 11299 -U 0 -t 1 -m 1024 -c 4096 \
                    > "$W/memcached-$v.log" 2>&1 &
                pid=$!
                if waitport 11299; then
                    cpuset -l "$others" memaslap -s 127.0.0.1:11299 -T 3 -c 48 -t 5s -F "$W/memaslap-set.cnf" > /dev/null 2>&1
                    for m in "get and set 9:1|" "gets of 10 keys at once, set 9:1|-d 10"; do
                        n="${m%%|*}"; o="${m#*|}"
                        # shellcheck disable=SC2086
                        cpuset -l "$others" memaslap -s 127.0.0.1:11299 -T 3 -c 48 -t 15s -F "$W/memaslap.cnf" $o > "$W/ma.out" 2>&1
                        # "Run time: 15.0s Ops: 1503042 TPS: 100195 Net_rate: 52.1M/s"
                        x="$(sed -n -E 's/^Run time: .*TPS: ([0-9]+).*/\1/p' "$W/ma.out" | tail -n 1)"
                        [ -n "$x" ] || say "memcached $n $v: $(tail -n 3 "$W/ma.out" | tr '\n' ' ')"
                        record memcached "$n (memaslap, 48 connections)" ops higher "$v" "$x"
                    done
                else
                    say "memcached $v: did not start: $(tail -n 3 "$W/memcached-$v.log" | tr '\n' ' ')"
                fi
                kill "$pid"; wait "$pid" 2> /dev/null
            fi
            if have gearmand "$v"; then
                gb="$W/gearmand-clang19/bin"
                cpuset -l "$last" "$W/gearmand-$v/bin/gearmand" -L 127.0.0.1 -p 4731 -t 1 --log-file=none \
                    > "$W/gearmand-$v.log" 2>&1 &
                pid=$!
                if waitport 4731; then
                    wpids=""
                    for i in 1 2 3 4; do
                        cpuset -l "$others" "$gb/blobslap_worker" -h 127.0.0.1 -p 4731 > /dev/null 2>&1 &
                        wpids="$wpids $!"
                    done
                    sleep 1
                    timed "$v" gearmand "100000 jobs of 64-512 bytes, 100 at once (blobslap, 4 workers)" \
                        cpuset -l "$others" "$gb/blobslap_client" -h 127.0.0.1 -p 4731 -c 1000 -n 100 -m 64 -M 512
                    # shellcheck disable=SC2086
                    kill $wpids 2> /dev/null; wait $wpids 2> /dev/null
                else
                    say "gearmand $v: did not start: $(tail -n 3 "$W/gearmand-$v.log" | tr '\n' ' ')"
                fi
                kill "$pid"; wait "$pid" 2> /dev/null
            fi
        done
    done
}
