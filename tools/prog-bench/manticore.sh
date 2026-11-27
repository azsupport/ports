# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/manticore.sh: the group manticore32 of tools/prog-bench.sh (sourced by it).
# Manticore Search 32.1.10 (textproc/manticore32 on the master textproc/manticore14: the
# tarballs of its distinfo, its patches files/patch-*, its post-patch and its CMake
# arguments): Galera, RE2 and the Snowball stemmers static, ICU, jieba, SSL (the base system),
# zlib, zstd, curl, expat, iconv; ICU, expat, xxHash, zstd and curl of the packages (ours:
# azsupport and ftp/curl), Boost.Context and Boost.Filesystem the archives of boost-libs (so
# no PIE, as the port); MySQL off (the sources of indexer here are TSV). prog-bench.yml builds
# each variant in a VM of its own (the input split: 55 minutes a build of the port,
# tools/build-minutes.conf) and measures the three in one.
# The benchmarks: indexer (one thread) on 300000 documents of words of /usr/share/dict/words
# (a title of 6 words and a text of 120, two attributes), timed; searchd (threads 1, no query
# cache) on the last CPU, wrk on the others (16 connections, 8 s) through its HTTP /sql:
# full-text queries of 1 and 2 words (the top 20), one with a filter and ORDER BY an
# attribute, a phrase, and a GROUP BY of an attribute (a facet); requests per second.

g_progs="manticore32"
mcv=32.1.10
MCF="$top/textproc/manticore14/files"

g_need() {
    need boost-libs bison icu expat xxhash zstd
    if [ "$mode" = bench ]; then need wrk-luajit; fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    # <account>:<project>:<tag>:<directory of the work>:<sha256> (GH_TUPLE of the port)
    _t="manticoresoftware:manticoresearch:$mcv:.:8582350e62c5d2209d9a786b35ef5136a03e6e8ddabb2c3dda2eb634bbb3c868
manticoresoftware:cctz:8ca8e325cb3d8a0b768f7530d0e31a907982c6d4:freebsd-deps/cctz:7f8b4ab66f5478345357b940b537135970bc8368e95eae762427f7ee78af57cf
nlohmann:json:v3.12.0:freebsd-deps/nljson:4b92eb0c06d10683f7447ce9406cb97cd4b453be18d7279320f7b2f025c10187
manticoresoftware:columnar:12f86b4299dcef1495972838b76931bf46e4426f:mcl:54c4e48e283280eabbe664627bd6d1cb07306e6a8bf3fe9557dc366f1a9213f0
manticoresoftware:galera:dfce76623c63da32fe3154dc010bf22a399035e8:freebsd-deps/galera:6bd23c8cc956348bb7b01c47b18b6039780de2ada70074f1bd3bca3c45d9d3d3
percona:wsrep-API:2c211e1aad315e3118969beada4d4767118be88f:freebsd-deps/wsrep:30ae3908e421e11c584d0537f0886a9074c3b899a83f7bf8ccc19dbaa1d8c927
manticoresoftware:cppjieba:0fa3cb07232f5c144228c2e8e39521bfdc9d3bca:freebsd-deps/cppjieba:e541b011c1c07e0d24fa57d0e9d6293bf570a89075c5212f16a361cc146a2e57
yanyiwu:limonp:v0.9.0:freebsd-deps/cppjieba/deps/limonp:92d90b262ab2e3375dd386731deeb028f88ee7d07d0695d53d10bef6887d2f5f
manticoresoftware:re2:2015-06-01:freebsd-deps/re2:90b4f48c26b1f33f4df5f86406d8c663c8a44b103a5554387ce3c53228abf20e
manticoresoftware:snowball:v3.0.3:freebsd-deps/stemmer:e6127db8a7e4be394c75652b1e3486d88ec20bd2bbba5dea8c9017289aceecbe
manticoresoftware:uni-algo:v0.7.2:freebsd-deps/uni-algo:4df3a10b6f9f0cc3be98834f09100c822ba3e3be13e9dfd23cf4810ed229633f
RoaringBitmap:CRoaring:v4.3.2:freebsd-deps/roaring:3be2e83b27cfbbf6692b215f9d4c1d1076b8e0adf7a2e0eabd2417601bbaaac3"
    S="$W/src/mc-$_v"
    rm -rf "$S"
    echo "$_t" | while IFS=: read -r a p t d sum; do
        fetch "$a-$p-${t}_GH0.tar.gz" "$sum" "https://codeload.github.com/$a/$p/tar.gz/$t"
        mkdir -p "$S/$d" && tar -xf "$W/dist/$a-$p-${t}_GH0.tar.gz" -C "$S/$d" --strip-components 1 || die "cannot unpack $a/$p"
    done
    _b="$W/b-manticore32-$_v.log"
    : > "$_b"
    for p in "$MCF"/patch-*; do
        (cd "$S" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    # post-patch of the port
    sed -i '' -e "s|^#define VERNUMBERS \"0\\.0\\.0\"\$|#define VERNUMBERS \"$mcv\"|" "$S/src/sphinxversion.h.in"
    cp "$MCF/galera-local.cmake.in" "$S/cmake/"
    (cd "$S/freebsd-deps/re2" && patch -s -p1 < "$S/libre2/libre2.patch") >> "$_b" 2>&1 || echo "FAIL: libre2.patch" >> "$_b"
    cp "$S/libre2/CMakeLists.txt" "$S/freebsd-deps/re2/CMakeLists.txt"
    echo ok > "$S/freebsd-deps/re2/is_patched.txt"
    # pre-configure of the port: the archives of Boost alone in a directory; a CMake config of
    # xxHash (header only)
    D="$W/mcdeps"
    mkdir -p "$D/include" "$D/lib" "$D/lib/cmake/xxHash"
    ln -sf /usr/local/include/boost "$D/include/boost"
    ln -sf /usr/local/lib/libboost_context.a /usr/local/lib/libboost_filesystem.a "$D/lib/"
    printf '%s\n' 'if (NOT TARGET xxHash::xxhash)' '	add_library ( xxHash::xxhash INTERFACE IMPORTED )' \
        '	set_target_properties ( xxHash::xxhash PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "/usr/local/include" )' \
        'endif ()' > "$D/lib/cmake/xxHash/xxHashConfig.cmake"
    # CRoaring 4.3.2 calls bswap64 undeclared on FreeBSD (its portability.h includes
    # <byteswap.h>; bswap64 is of <sys/endian.h>), in roaring64.c, which searchd does not link:
    # an error of clang 23 and of GCC 14 and later, a warning of the base clang 19 (FreeBSD
    # takes DefaultError off implicit declarations and implicit int): the same warning for
    # clang23 and gcc16, said in the report (run 45918013549: their builds stopped there)
    case "$_v" in clang23|gcc16)
        export CFLAGS="$CFLAGS -Wno-error=implicit-function-declaration"
        echo "manticore32 $_v: CRoaring 4.3.2 calls bswap64 undeclared on FreeBSD (include/roaring/portability.h: <byteswap.h>, not <sys/endian.h>; in roaring64.c, which searchd does not link), an error of clang 23 and of GCC 14 and later (the base clang 19 of FreeBSD keeps it a warning): built with -Wno-error=implicit-function-declaration" >> "$W/fails/$group-notes-$_v.md" ;;
    esac
    # no PIE (the archives of boost-libs are not PIC), as the port
    _cf="$(echo "$CFLAGS" | sed -e 's/ -fPIE//' -e 's/ -fPIC//')"
    _cxf="$(echo "$CXXFLAGS" | sed -e 's/ -fPIE//' -e 's/ -fPIC//')"
    _lf="$(echo "$LDFLAGS" | sed -e 's/-pie //')"
    M="$S/freebsd-deps"
    if (cd "$S" && env CMAKE_POLICY_VERSION_MINIMUM=3.5 CFLAGS="$_cf" CXXFLAGS="$_cxf" LDFLAGS="$_lf" \
        cmake -S . -B _b -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG \
        -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG -DCMAKE_INSTALL_PREFIX="$W/manticore32-$_v" \
        -DBUILD_TESTING=OFF -DCACHEB="$W/mc-cache-$_v" \
        -DWITH_GALERA=ON -DGALERA_SOURCE_DIR="$M/galera" -DWSREP_SOURCE_DIR="$M/wsrep" \
        -DWITH_RE2=ON -DWITH_RE2_FORCE_STATIC=ON -DWITH_STEMMER=ON -DWITH_STEMMER_FORCE_STATIC=ON \
        -DWITH_ICU=ON -DWITH_ICU_FORCE_STATIC=OFF -DICU_ROOT=/usr/local -DWITH_JIEBA=ON \
        -DWITH_SSL=ON -DOPENSSL_USE_STATIC_LIBS=OFF -DOPENSSL_ROOT_DIR=/usr \
        -DWITH_ZLIB=ON -DWITH_ZSTD=ON -DWITH_CURL=ON -DCURL_NO_CURL_CMAKE=ON -DWITH_EXPAT=ON \
        -DWITH_ICONV=ON -DWITH_MYSQL=OFF -DWITH_ODBC=OFF -DWITH_POSTGRESQL=OFF \
        -DCMAKE_PREFIX_PATH="$D;/usr/local" -DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT="$D" -DBoost_NO_SYSTEM_PATHS=ON \
        -DFETCHCONTENT_FULLY_DISCONNECTED=ON -DFETCHCONTENT_SOURCE_DIR_CCTZ="$M/cctz" \
        -DFETCHCONTENT_SOURCE_DIR_JIEBA="$M/cppjieba" -DFETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON="$M/nljson" \
        -DFETCHCONTENT_SOURCE_DIR_RE2="$M/re2" -DFETCHCONTENT_SOURCE_DIR_ROARING="$M/roaring" \
        -DFETCHCONTENT_SOURCE_DIR_STEMMER="$M/stemmer" -DFETCHCONTENT_SOURCE_DIR_UNI-ALGO="$M/uni-algo" \
        -DMCL_LOCAL_RUNTIME=OFF &&
        env CMAKE_POLICY_VERSION_MINIMUM=3.5 ninja -C _b && env CMAKE_POLICY_VERSION_MINIMUM=3.5 ninja -C _b install) >> "$_b" 2>&1 &&
        [ -x "$W/manticore32-$_v/bin/searchd" ]; then
        bok manticore32 "$_v" "$W/manticore32-$_v/bin/searchd"
    else
        bno manticore32 "$_v" "$_b"
    fi
    rm -rf "$S"
}

g_keep() { echo "$W/manticore32-$1"; }

g_bench() {
    C="$W/mc"
    mkdir -p "$C"
    # 300000 documents: id, a title of 6 words, a text of 120, cat (0-99), price (0-99999)
    awk -v n=300000 'BEGIN { srand(7) } { w[NR] = $1 } END {
        for (i = 1; i <= n; i++) {
            t = ""; for (j = 0; j < 6; j++) t = t " " w[int(rand() * NR) + 1]
            c = ""; for (j = 0; j < 120; j++) c = c " " w[int(rand() * NR) + 1]
            printf "%d\t%s\t%s\t%d\t%d\n", i, substr(t, 2), substr(c, 2), int(rand() * 100), int(rand() * 100000)
        } }' /usr/share/dict/words > "$C/docs.tsv"
    # the words of the queries: of the documents (frequent and rare alike)
    awk 'NR % 997 == 0 { print $1 }' /usr/share/dict/words | head -n 200 > "$C/words.txt"
    {
        printf 'local w = {'
        awk '{ printf "\"%s\",", $1 }' "$C/words.txt"
        printf '}\n'
        cat << 'EOF'
local kind = os.getenv("MCQ") or "one"
local i = 0
local function enc(s) return (s:gsub("[^%w]", function(c) return string.format("%%%02X", string.byte(c)) end)) end
request = function()
  i = i + 1
  local a, b = w[(i * 7) % #w + 1], w[(i * 13) % #w + 1]
  local q
  if kind == "one" then q = "SELECT id FROM idx1 WHERE MATCH('" .. a .. "') LIMIT 20"
  elseif kind == "two" then q = "SELECT id FROM idx1 WHERE MATCH('" .. a .. " " .. b .. "') LIMIT 20"
  elseif kind == "filter" then q = "SELECT id, price FROM idx1 WHERE MATCH('" .. a .. "') AND cat < 50 ORDER BY price DESC LIMIT 20"
  elseif kind == "phrase" then q = "SELECT id FROM idx1 WHERE MATCH('\"" .. a .. " " .. b .. "\"/1') LIMIT 20"
  else q = "SELECT cat, COUNT(*) FROM idx1 WHERE MATCH('" .. a .. "') GROUP BY cat LIMIT 100" end
  return wrk.format("POST", "/sql", { ["Content-Type"] = "application/x-www-form-urlencoded" }, "query=" .. enc(q))
end
EOF
    } > "$C/q.lua"
    cat > "$C/manticore.conf" << EOF
source src1 {
    type = tsvpipe
    tsvpipe_command = cat $C/docs.tsv
    tsvpipe_field = title
    tsvpipe_field = content
    tsvpipe_attr_uint = cat
    tsvpipe_attr_uint = price
}
index idx1 {
    source = src1
    path = $C/idx/idx1
    morphology = stem_en
    min_word_len = 2
}
indexer {
    mem_limit = 1024M
}
searchd {
    listen = 127.0.0.1:9312
    listen = 127.0.0.1:9308:http
    log = $C/searchd.log
    pid_file = $C/searchd.pid
    binlog_path =
    threads = 1
    qcache_max_bytes = 0
}
EOF
    for r in $(seq 1 "$rounds"); do
        say "manticore32: round $r of $rounds"
        for v in $(order "$r"); do
            have manticore32 "$v" || continue
            rm -rf "$C/idx"; mkdir -p "$C/idx"
            timed "$v" manticore32 "indexer: 300000 documents of 126 words (tsvpipe)" cpuset -l "$last" \
                "$W/manticore32-$v/bin/indexer" --config "$C/manticore.conf" --all --quiet
            [ -n "$(ls "$C/idx" 2> /dev/null)" ] || { say "manticore32 $v: no index: $(tail -n 3 "$W/cmd.err" | tr '\n' ' ')"; continue; }
            cpuset -l "$last" "$W/manticore32-$v/bin/searchd" --config "$C/manticore.conf" --nodetach > "$C/searchd-$v.out" 2>&1 &
            pid=$!
            if waitport 9308; then
                sleep 1
                export MCQ=one
                cpuset -l "$others" wrk -t 3 -c 16 -d 3s -s "$C/q.lua" http://127.0.0.1:9308/ > "$C/warm.out" 2>&1
                grep -q -E 'Non-2xx|Socket errors' "$C/warm.out" && say "manticore32 $v: $(grep -E 'Non-2xx|Socket errors|Requests/sec' "$C/warm.out" | tr '\n' ' ')"
                for k in "one:MATCH of a word, top 20" "two:MATCH of two words, top 20" "filter:MATCH, a filter, ORDER BY an attribute" \
                    "phrase:a phrase of two words (quorum 1)" "facet:MATCH, GROUP BY an attribute"; do
                    export MCQ="${k%%:*}"
                    PB_WRK_CONN=16; wrkrate "$v" manticore32 "searchd: ${k#*:}" http://127.0.0.1:9308/ -s "$C/q.lua"; unset PB_WRK_CONN
                done
            else
                say "manticore32 $v: searchd did not start: $(tail -n 5 "$C/searchd-$v.out" | tr '\n' ' ')"
            fi
            kill "$pid"; wait "$pid" 2> /dev/null
        done
    done
}
