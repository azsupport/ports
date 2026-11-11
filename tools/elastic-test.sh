#!/bin/sh
# elastic-test.sh - test Elasticsearch 6 of the repository az, installed from it (aZ,
# 11.11.2026: for the legacy sites): elasticsearch6 started by its rc script, as a
# server starts it, on 127.0.0.1:9200 with a data and log directory of the test:
#   - its version 6.8.23 and the JVM it runs on (OpenJDK 17 of the ports, the default
#     of its rc script: no elasticsearch_java_home in rc.conf);
#   - lib/jna.jar a link to the jna.jar of devel/jna, which is a whole zip;
#   - the start says nothing of System::setSecurityManager (the four lines of JDK 17
#     are taken out), and its log has no JNA that failed (the JNA it bundles);
#   - the heap from elasticsearch_heap of rc.conf (512m here) over the -Xms and
#     -Xmx of jvm.options; the options of jvm.options for OpenJDK 17 in the running JVM
#     (no -XX:UseAVX, -XX:+ExitOnOutOfMemoryError, -Dlog4j2.formatMsgNoLookups);
#     no warning of the JVM at the start; the GC log in /var/log/elasticsearch;
#     a wrong elasticsearch_heap refused;
#   - the health of the cluster, a document indexed and found by a query;
#   - stopped by its rc script.
#
# Usage (FreeBSD, as root, the packages installed): sh tools/elastic-test.sh
# Results: elastic-results/tests.txt (one line per check, the summary at the end),
# the log of Elasticsearch next to it; exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/elastic-results}"
T="${ELASTIC_TEST_WORK:-/var/tmp/elastic-test}"
P=/usr/local
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
es="http://127.0.0.1:19200"
# get <path>, put <path> <json>: the answer of Elasticsearch, or nothing
get() { fetch -q -o - "$es$1" 2>/dev/null; }
send() { curl -s -m 30 -H 'Content-Type: application/json' -X "$1" "$es$2" ${3:+-d "$3"} 2>/dev/null; }

if ! pkg info -e elasticsearch6; then
    fail "elasticsearch6 is not installed"
    echo "elastic-test: $ok ok, $bad failed" >> "$out"
    exit 1
fi
# its rc script runs it on OpenJDK 17 by itself, its JNA is that of devel/jna
if grep -q '^: ${elasticsearch_java_home="/usr/local/openjdk17"}' "$P/etc/rc.d/elasticsearch"; then
    pass "rc.d/elasticsearch: elasticsearch_java_home /usr/local/openjdk17 by default"
else
    fail "rc.d/elasticsearch: elasticsearch_java_home is not /usr/local/openjdk17 by default: $(grep -m 1 'elasticsearch_java_home=' "$P/etc/rc.d/elasticsearch")"
fi
j="$P/lib/elasticsearch/lib/jna.jar"
l="$(readlink "$j")"
if [ "$l" = "$P/share/java/classes/jna.jar" ] && [ -f "$l" ] && unzip -tqq "$l" > /dev/null 2>&1; then
    pass "lib/jna.jar -> $l (devel/jna $(pkg query '%v' jna 2>/dev/null)), a whole zip"
else
    fail "lib/jna.jar: ${l:-not a link}$([ -n "$l" ] && [ ! -f "$l" ] && echo ', missing')$([ -f "$l" ] && ! unzip -tqq "$l" > /dev/null 2>&1 && echo ', not a whole zip')"
fi
if ls "$P"/lib/elasticsearch/lib/jna-*.jar > /dev/null 2>&1; then fail "another JNA in lib: $(ls "$P"/lib/elasticsearch/lib/jna-*.jar | tr '\n' ' ')"; fi
# a configuration of the test: that of the package, its own paths and port
conf="$T/conf"
mkdir -p "$conf" "$T/data" "$T/logs"
for f in elasticsearch.yml jvm.options log4j2.properties role_mapping.yml roles.yml; do
    cp "$P/etc/elasticsearch/$f.sample" "$conf/$f" || fail "no $P/etc/elasticsearch/$f.sample"
done
sed -i '' -e "s|^path.data: .*|path.data: $T/data|" -e "s|^path.logs: .*|path.logs: $T/logs|" "$conf/elasticsearch.yml"
{ echo "http.port: 19200"; echo "transport.port: 19300"; echo "network.host: 127.0.0.1"; echo "cluster.name: az-test"; } >> "$conf/elasticsearch.yml"
chown -R elasticsearch:elasticsearch "$T"
# the rc script, as rc.conf would set it up: its configuration directory is ours,
# the heap of this server 512m (jvm.options stays that of the package, 1g)
export elasticsearch_config="$conf"
export elasticsearch_heap="4x"
if "$P/etc/rc.d/elasticsearch" onestart > "$T/badheap.out" 2>&1; then
    fail "rc.d/elasticsearch onestart with elasticsearch_heap=4x: started"
    "$P/etc/rc.d/elasticsearch" onestop > /dev/null 2>&1
elif grep -q 'elasticsearch_heap="4x" is not a size' "$T/badheap.out"; then
    pass "elasticsearch_heap=4x refused: $(head -n 1 "$T/badheap.out")"
else
    fail "elasticsearch_heap=4x: $(head -n 2 "$T/badheap.out" | tr '\n' ' ')"
fi
export elasticsearch_heap="512m"
gclog=/var/log/elasticsearch/gc.log
rm -f "$gclog"
"$P/etc/rc.d/elasticsearch" onestart > "$T/start.out" 2>&1
r=$?
cp "$T/start.out" "$res/elasticsearch-start.out"
if [ "$r" = 0 ]; then pass "rc.d/elasticsearch onestart"; else fail "rc.d/elasticsearch onestart: exit $r, $(tail -n 2 "$T/start.out" | tr '\n' ' ')"; fi
up=""
i=0
while [ "$i" -lt 90 ]; do
    a="$(get /)" && case "$a" in *'"number"'*) up=1; break ;; esac
    sleep 2; i=$((i + 1))
done
cp "$T/logs/az-test.log" "$res/elasticsearch.log" 2>/dev/null
if [ -z "$up" ]; then
    fail "no answer on $es in 180 s: $(tail -n 3 "$T/logs/az-test.log" 2>/dev/null | tr '\n' ' ')"
else
    v="$(printf '%s' "$a" | sed -n 's/.*"number" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
    if [ "$v" = "$(pkgv elasticsearch6)" ]; then pass "version $v"; else fail "version $v, the package is $(pkgv elasticsearch6)"; fi
    j="$(get '/_nodes/_local/jvm?filter_path=**.jvm.version,**.jvm.vm_name' | sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
    case "$j" in 17.*) pass "the JVM: $j" ;; *) fail "the JVM: ${j:-not told}, not 17" ;; esac
    # the options of the running JVM, one per line, in their order
    get '/_nodes/_local/jvm?filter_path=**.jvm.input_arguments,**.jvm.mem.heap_max_in_bytes' > "$T/jvm.json"
    sed -e 's/.*"input_arguments" *: *\[//' -e 's/\].*//' "$T/jvm.json" | tr ',' '\n' | sed -e 's/^"//' -e 's/"$//' > "$T/args.txt"
    cp "$T/args.txt" "$res/elasticsearch-jvm-arguments.txt"
    hm="$(sed -n 's/.*"heap_max_in_bytes" *: *\([0-9]*\).*/\1/p' "$T/jvm.json")"
    if [ "$(grep '^-Xmx' "$T/args.txt" | tail -n 1)" = "-Xmx512m" ] && [ "$(grep '^-Xms' "$T/args.txt" | tail -n 1)" = "-Xms512m" ] && [ "${hm:-0}" -gt 400000000 ] && [ "${hm:-0}" -le 536870912 ]; then
        pass "the heap of elasticsearch_heap: -Xms512m -Xmx512m after the 1g of jvm.options, heap_max_in_bytes $hm"
    else
        fail "the heap: last $(grep '^-Xm[sx]' "$T/args.txt" | tail -n 2 | tr '\n' ' '), heap_max_in_bytes ${hm:-not told}, not the 512m of elasticsearch_heap"
    fi
    m=""
    for o in '-XX:+UseG1GC' '-XX:G1ReservePercent=25' '-XX:InitiatingHeapOccupancyPercent=30' '-XX:+ExitOnOutOfMemoryError' '-XX:+HeapDumpOnOutOfMemoryError' '-XX:HeapDumpPath=/var/db/elasticsearch' \
        '-XX:ErrorFile=/var/log/elasticsearch/hs_err_pid%p.log' '-XX:ReplayDataFile=/var/log/elasticsearch/replay_pid%p.log' '-Dlog4j2.formatMsgNoLookups=true' \
        '-Djava.locale.providers=COMPAT' '-Dio.netty.noUnsafe=true' '-XX:+AlwaysPreTouch'; do
        grep -q -x -F -e "$o" "$T/args.txt" || m="$m $o"
    done
    if [ -z "$m" ] && ! grep -q 'UseAVX' "$T/args.txt"; then
        pass "the options of jvm.options for OpenJDK 17 in the JVM, no -XX:UseAVX"
    else
        fail "the options of the JVM: missing:${m:- none}$(grep 'UseAVX' "$T/args.txt" | sed 's/^/, has /')"
    fi
    if [ -s "$gclog" ]; then pass "the GC log: $gclog, $(wc -l < "$gclog" | tr -d ' ') lines"; else fail "no GC log $gclog"; fi
    h="$(get '/_cluster/health?wait_for_status=yellow&timeout=60s' | sed -n 's/.*"status" *: *"\([^"]*\)".*/\1/p')"
    case "$h" in green|yellow) pass "cluster health: $h" ;; *) fail "cluster health: ${h:-no answer}" ;; esac
    send PUT /az-test '{ "settings": { "number_of_shards": 1, "number_of_replicas": 0 } }' > "$T/i.out"
    send PUT '/az-test/_doc/1?refresh=true' '{ "title": "elasticsearch of azsupport", "n": 42 }' > "$T/d.out"
    s="$(send GET /az-test/_search '{ "query": { "match": { "title": "azsupport" } } }')"
    case "$s" in *'"total":1'* | *'"total":{"value":1'*) pass "a document indexed and found" ;;
        *) fail "the search: $(printf '%s' "$s" | cut -c1-200) (index: $(cut -c1-120 "$T/i.out"), document: $(cut -c1-120 "$T/d.out"))" ;; esac
fi
cp "$T/start.out" "$res/elasticsearch-start.out"
if grep -q 'setSecurityManager' "$T/start.out"; then
    fail "the start printed the warning of JDK 17 about setSecurityManager: $(grep -m 1 'setSecurityManager' "$T/start.out")"
else
    pass "the start without the warning of JDK 17 about setSecurityManager"
fi
if grep -i -E 'warning|deprecated|unrecognized|ignoring option' "$T/start.out" > "$T/warn.txt"; then
    fail "the start printed $(wc -l < "$T/warn.txt" | tr -d ' ') warnings: $(head -n 2 "$T/warn.txt" | cut -c1-200 | tr '\n' ' ')"
else
    pass "the start without a warning of the JVM ($(wc -l < "$T/start.out" | tr -d ' ') lines: elasticsearch-start.out)"
fi
if grep -E -i 'jna (not found|is not available)|unable to load jna|cannot load jna' "$T/logs/az-test.log" > "$T/jna.txt" 2>/dev/null; then
    fail "JNA: $(head -n 1 "$T/jna.txt" | cut -c1-200)"
else
    pass "JNA: no failure in the log"
fi
w="$(grep -c '\]\[WARN \]' "$T/logs/az-test.log" 2>/dev/null)"
[ "${w:-0}" = 0 ] || note "the log has $w warnings (elasticsearch.log): $(grep '\]\[WARN \]' "$T/logs/az-test.log" | head -n 3 | cut -c1-160 | tr '\n' ' ')"
"$P/etc/rc.d/elasticsearch" onestop > "$T/stop.out" 2>&1
r=$?
if [ "$r" = 0 ] && ! get / > /dev/null; then pass "rc.d/elasticsearch onestop"; else fail "rc.d/elasticsearch onestop: exit $r, $(tail -n 1 "$T/stop.out")"; fi

echo "elastic-test: $ok ok, $bad failed" >> "$out"
[ "$bad" = 0 ]
