# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/mariadb.sh: the group mariadb of tools/prog-bench.sh (sourced by it).
# MariaDB 10.11.20 (databases/mariadb1011-server, the tarball of its distinfo), the server
# with the engines of our port that the benchmarks use (InnoDB, Aria, MyISAM), the others
# off (RocksDB, Mroonga, Spider, CONNECT, OQGRAPH, SphinxSE, ColumnStore, S3, Galera,
# mariabackup, the tests); PCRE2 of the packages, the OpenSSL and zlib of the base system, as
# the port; CMAKE_BUILD_TYPE Release with the flags of the variant alone (as Uses/cmake.mk:
# -DNDEBUG). prog-bench.yml builds each variant in a VM of its own (the input split: 75
# minutes a build of the port, tools/build-minutes.conf) and measures the three in one.
# The benchmarks: sysbench 1.0 of the packages (its client library: that of the default
# MySQL of the packages) on the other CPUs, the server on the last one: oltp_point_select,
# oltp_read_only and oltp_read_write, 8 threads, 8 tables of 100000 rows (in the buffer pool,
# the log not flushed at a commit, no binary log), 20 seconds each after 5 of warming up;
# the transactions per second (point_select: a query each).

mv=10.11.20
g_progs="mariadb"

g_need() {
    if [ "$mode" = bench ]; then need sysbench; else need pcre2; fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch "mariadb-$mv.tar.gz" ac5c003f725950a4cbf9829bd9b191b73f8ab0f2630d6dbc6292fc5244d3c7cb \
        "https://archive.mariadb.org/mariadb-$mv/source/mariadb-$mv.tar.gz" \
        "https://downloads.mariadb.org/rest-api/mariadb/$mv/mariadb-$mv.tar.gz"
    unpack "mariadb-$mv.tar.gz" "$W/src/mdb-$_v"
    _b="$W/b-mariadb-$_v.log"
    _off=""
    for p in ROCKSDB MROONGA SPIDER CONNECT OQGRAPH SPHINX COLUMNSTORE S3 TOKUDB FEDERATEDX FEDERATED ARCHIVE BLACKHOLE \
        AUTH_GSSAPI AUTH_GSSAPI_CLIENT AUTH_PAM AUTH_PAM_V1 AUTH_TEST_PLUGIN HASHICORP_KEY_MANAGEMENT AWS_KEY_MANAGEMENT \
        PROVIDER_BZIP2 PROVIDER_LZ4 PROVIDER_LZMA PROVIDER_LZO PROVIDER_SNAPPY; do
        _off="$_off -DPLUGIN_$p=NO"
    done
    # shellcheck disable=SC2086
    if (cd "$W/src/mdb-$_v" && cmake -S . -B _b -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG \
        -DCMAKE_INSTALL_PREFIX="$W/mariadb-$_v" -DINSTALL_MYSQLTESTDIR= -DINSTALL_SQLBENCHDIR= \
        -DWITH_SSL=system -DWITH_PCRE=system -DWITH_ZLIB=system -DWITH_LIBFMT=bundled \
        -DWITH_UNIT_TESTS=OFF -DCONC_WITH_UNIT_TESTS=OFF -DWITH_WSREP=OFF -DWITH_MARIABACKUP=OFF \
        -DWITH_EMBEDDED_SERVER=OFF -DWITHOUT_DOCS=ON -DWITH_SYSTEMD=no -DCOMPILATION_COMMENT="prog-bench $_v" \
        $_off && ninja -C _b && ninja -C _b install) > "$_b" 2>&1; then
        bok mariadb "$_v" "$W/mariadb-$_v/bin/mariadbd"
    else
        bno mariadb "$_v" "$_b"
    fi
    rm -rf "$W/src/mdb-$_v"
}

g_keep() { echo "$W/mariadb-$1"; }

# mdb_start <variant> [<option>...]: the server of the variant on its own data directory
mdb_start() {
    _v="$1"; shift
    cpuset -l "$last" "$W/mariadb-$_v/bin/mariadbd" --no-defaults --user=root --basedir="$W/mariadb-$_v" \
        --datadir="$W/mdbdata-$_v" --socket="$W/mdb.sock" --port=3307 --bind-address=127.0.0.1 \
        --innodb-buffer-pool-size=2G --innodb-log-file-size=512M --innodb-flush-log-at-trx-commit=0 \
        --skip-log-bin --sync-binlog=0 --max-connections=200 --performance-schema=OFF \
        --skip-name-resolve --init-file="$W/mdb-init.sql" $mdb_extra "$@" > "$W/mariadbd-$_v.log" 2>&1 &
    mpid=$!
    _n=0
    while [ ! -S "$W/mdb.sock" ]; do
        _n=$((_n + 1)); sleep 0.2
        if [ "$_n" -gt 300 ] || ! kill -0 "$mpid" 2> /dev/null; then
            say "mariadb $_v: the server did not start: $(tail -n 5 "$W/mariadbd-$_v.log" | tr '\n' ' ')"; return 1
        fi
    done
    sleep 1
}
mdb_stop() { kill "$mpid"; wait "$mpid" 2> /dev/null; rm -f "$W/mdb.sock"; }

g_bench() {
    cat > "$W/mdb-init.sql" << 'EOF'
CREATE DATABASE IF NOT EXISTS sbtest;
CREATE USER IF NOT EXISTS 'sb'@'localhost' IDENTIFIED BY 'sb';
CREATE USER IF NOT EXISTS 'sb'@'127.0.0.1' IDENTIFIED BY 'sb';
GRANT ALL ON *.* TO 'sb'@'localhost';
GRANT ALL ON *.* TO 'sb'@'127.0.0.1';
EOF
    sb="--db-driver=mysql --mysql-socket=$W/mdb.sock --mysql-user=sb --mysql-password=sb --mysql-db=sbtest --tables=8 --table-size=100000"
    mdb_extra=""
    for v in $variants; do
        have mariadb "$v" || continue
        rm -rf "$W/mdbdata-$v"; mkdir -p "$W/mdbdata-$v"
        "$W/mariadb-$v/scripts/mariadb-install-db" --no-defaults --user=root --basedir="$W/mariadb-$v" \
            --datadir="$W/mdbdata-$v" --auth-root-authentication-method=normal --skip-name-resolve > "$W/mdbinit-$v.log" 2>&1 || {
            say "mariadb $v: mariadb-install-db failed: $(tail -n 5 "$W/mdbinit-$v.log" | tr '\n' ' ')"; rm -f "$W/ok/$group-mariadb-$v"; continue; }
        mdb_start "$v" || { rm -f "$W/ok/$group-mariadb-$v"; continue; }
        # shellcheck disable=SC2086
        if ! cpuset -l "$others" sysbench oltp_read_write $sb --threads=8 prepare > "$W/sbprep-$v.log" 2>&1 &&
            grep -q -i -E 'auth|access denied|plugin' "$W/sbprep-$v.log"; then
            # the client library of sysbench (MySQL) and the logins of MariaDB: without the
            # privileges then, for every variant
            say "mariadb $v: sysbench could not log in ($(tail -n 2 "$W/sbprep-$v.log" | tr '\n' ' ')): --skip-grant-tables"
            echo "sysbench could not log in to MariaDB ($(tail -n 1 "$W/sbprep-$v.log")): the servers run with --skip-grant-tables" >> "$W/fails/$group-notes.md"
            mdb_stop; mdb_extra="--skip-grant-tables"; mdb_start "$v" || { rm -f "$W/ok/$group-mariadb-$v"; continue; }
            # shellcheck disable=SC2086
            cpuset -l "$others" sysbench oltp_read_write $sb --threads=8 cleanup > /dev/null 2>&1
            cpuset -l "$others" sysbench oltp_read_write $sb --threads=8 prepare > "$W/sbprep-$v.log" 2>&1
        fi
        grep -q -E 'Inserting 100000 records into .sbtest8' "$W/sbprep-$v.log" || {
            say "mariadb $v: sysbench prepare failed: $(tail -n 5 "$W/sbprep-$v.log" | tr '\n' ' ')"; mdb_stop; rm -f "$W/ok/$group-mariadb-$v"; continue; }
        mdb_stop
    done
    have mariadb clang19 || die "mariadb: no data of clang19 (above)"
    for r in $(seq 1 "$rounds"); do
        say "mariadb: round $r of $rounds"
        for v in $(order "$r"); do
            have mariadb "$v" || continue
            mdb_start "$v" || continue
            # shellcheck disable=SC2086
            cpuset -l "$others" sysbench oltp_read_only $sb --threads=8 --time=5 run > /dev/null 2>&1
            for t in oltp_point_select oltp_read_only oltp_read_write; do
                # shellcheck disable=SC2086
                cpuset -l "$others" sysbench "$t" $sb --threads=8 --time=20 --report-interval=0 run > "$W/sb.out" 2>&1
                # "    transactions:                        1234567 (61728.20 per sec.)"
                x="$(sed -n -E 's/^ *transactions: *[0-9]+ +\(([0-9.]+) per sec\.\).*/\1/p' "$W/sb.out")"
                [ -n "$x" ] || say "mariadb $t $v: $(tail -n 3 "$W/sb.out" | tr '\n' ' ')"
                record mariadb "$t (8 threads)" tps higher "$v" "$x"
            done
            mdb_stop
        done
    done
}
