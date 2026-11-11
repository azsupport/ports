#!/bin/sh
# elastic-test.sh - test Elasticsearch 6 of the repository az, installed from it (aZ,
# 11.11.2026: for the legacy sites): elasticsearch6 started by its rc script, as a
# server starts it, on 127.0.0.1:9200 with a data and log directory of the test:
#   - its version 6.8.23 and the JVM it runs on (OpenJDK 17 of the ports);
#   - the start says nothing of System::setSecurityManager (the four lines of JDK 17
#     are taken out), and its log has no JNA that failed (the JNA it bundles);
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
# a configuration of the test: that of the package, its own paths and port
conf="$T/conf"
mkdir -p "$conf" "$T/data" "$T/logs"
for f in elasticsearch.yml jvm.options log4j2.properties role_mapping.yml roles.yml; do
    cp "$P/etc/elasticsearch/$f.sample" "$conf/$f" || fail "no $P/etc/elasticsearch/$f.sample"
done
sed -i '' -e "s|^path.data: .*|path.data: $T/data|" -e "s|^path.logs: .*|path.logs: $T/logs|" "$conf/elasticsearch.yml"
{ echo "http.port: 19200"; echo "transport.port: 19300"; echo "network.host: 127.0.0.1"; echo "cluster.name: az-test"; } >> "$conf/elasticsearch.yml"
sed -i '' -e 's|^-Xms1g$|-Xms512m|' -e 's|^-Xmx1g$|-Xmx512m|' "$conf/jvm.options"
chown -R elasticsearch:elasticsearch "$T"
# the rc script, as rc.conf would set it up: its configuration directory is ours
export elasticsearch_config="$conf"
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
