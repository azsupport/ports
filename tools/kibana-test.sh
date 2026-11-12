#!/bin/sh
# kibana-test.sh - test Kibana 6 of the repository az, installed from it (aZ,
# 11.11.2026: for the legacy sites), on the Node.js 24 of www/node24, against
# elasticsearch6 of the repository: both started by their rc scripts, as a server
# starts them, Elasticsearch on 127.0.0.1:19200, Kibana on its default address
# (server.host "localhost") and the port 15601, with a configuration (the sample
# of the package), data directories and logs of the test:
#   - the package: its node is that of www/node24, re2 loads in it (built for
#     its NODE_MODULE_VERSION, linked to the base system only), nothing of macOS;
#     bin/kibana --version, kibana-plugin list, kibana-keystore;
#   - /api/status green on 127.0.0.1 (the IPv4 address of localhost, as Node.js 10
#     took it), its version, Machine Learning and Reporting off, the bundles of the
#     package taken as they are (not built again at the start);
#   - its page; an index pattern saved as the browser saves it, read and found
#     (saved objects, POST); the documents through its proxy of Elasticsearch
#     (POST _msearch, as the browser asks) and through the proxy of the console;
#     Timelion without and with a regular expression (re2) and with functions;
#     the Visual Builder; a sample data set installed (a stream of 4675 documents
#     through zlib into Elasticsearch) and removed;
#   - the bundles served as the files, plain and with gzip, 304 for their ETag;
#   - 100 requests at once, three times, each answer checked; a chunked body;
#     clients that go away, and it still answers;
#   - reload by the rc script (SIGHUP: the log file opened again after a rotation);
#   - no errors in its log; stopped by its rc script.
# Every request has a time limit: one without an answer is a failed check.
#
# Usage (FreeBSD, as root, the packages installed): sh tools/kibana-test.sh
# Results: kibana-results/tests.txt (one line per check, the summary at the end),
# the logs of Kibana and Elasticsearch next to it; exit status 0 when every check
# passed.

set -u
res="${AZ_RESULTS:-$(pwd)/kibana-results}"
T="${KIBANA_TEST_WORK:-/var/tmp/kibana-test}"
P=/usr/local
D="$P/www/kibana6"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T/a" "$T/m"
chmod 755 "$T"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
es="http://127.0.0.1:19200"
kb="http://127.0.0.1:15601"
node="$P/bin/node"
# rq <name> <method> <path> [<data or @file> [<content type>]]: a request to Kibana
# with a time limit (no body for an empty <data>); the answer in $T/a/<name>, its
# status the output
rq() {
    _n="$1"; _m="$2"; _p="$3"
    if [ $# -ge 4 ] && [ -n "$4" ]; then
        curl -s -m 60 -o "$T/a/$_n" -w '%{http_code}' -H 'kbn-xsrf: kibana-test' -H "Content-Type: ${5:-application/json}" \
            -X "$_m" "$kb$_p" --data-binary "$4" 2>/dev/null
    else
        curl -s -m 60 -o "$T/a/$_n" -w '%{http_code}' -H 'kbn-xsrf: kibana-test' -X "$_m" "$kb$_p" 2>/dev/null
    fi
}
# has <name> <text>: the answer has the text; ans <name>: its start, for a message
has() { grep -q -F -- "$2" "$T/a/$1" 2>/dev/null; }
ans() { head -c 200 "$T/a/$1" 2>/dev/null | tr '\n' ' '; }
# want <what> <name> <status> <text> <method> <path> [<data> [<type>]]: a request, its
# status and a text of its answer
want() {
    _w="$1"; _n="$2"; _s="$3"; _t="$4"; shift 4
    _c="$(rq "$_n" "$@")"
    if [ "$_c" = "$_s" ] && has "$_n" "$_t"; then pass "$_w"; else fail "$_w: $_c $(ans "$_n")"; fi
}
finish() {
    echo "kibana-test: $ok ok, $bad failed" >> "$out"
    [ "$bad" = 0 ]
    exit $?
}

for p in kibana6 elasticsearch6 node24; do
    pkg info -e "$p" || { fail "$p is not installed"; finish; }
done

# --- the package ---------------------------------------------------------------------
for b in kibana kibana-plugin kibana-keystore; do
    grep -q "^NODE=\"$node\"\$" "$D/bin/$b" || fail "bin/$b: its node is not $node: $(grep -m 1 '^NODE=' "$D/bin/$b")"
done
grep -q "procname=\"$node\"" "$P/etc/rc.d/kibana" && pass "bin/kibana and rc.d/kibana: the node of www/node24 ($("$node" --version))" ||
    fail "rc.d/kibana: procname is not $node"
r="$D/node_modules/re2/build/Release/re2.node"
n="$(find "$D" -name '*.node' | tr '\n' ' ')"
if [ "$n" = "$r " ]; then pass "one native module, re2.node"; else fail "native modules: $n"; fi
l="$(ldd "$r" 2>&1 | awk '/=>/ { print $3 }' | grep -v -E '^/(lib|usr/lib)/' | tr '\n' ' ')"
if [ -z "$l" ] && ldd "$r" > /dev/null 2>&1; then pass "re2.node links the base system only: $(ldd "$r" | awk '/=>/ { print $1 }' | tr '\n' ' ')"; else fail "re2.node links ${l:-nothing ldd can read}"; fi
a="$("$node" -e 'const RE2 = require(process.argv[1]); const t = Date.now();
    const r = new RE2("(a+)+$").test("a".repeat(60) + "!");
    console.log("x aaa".replace(new RE2("(a+)"), "<$1>"), r, Date.now() - t < 1000, process.versions.modules);' "$D/node_modules/re2" 2>&1)"
case "$a" in "x <aaa> false true "*) pass "re2 $(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$D/node_modules/re2/package.json") in node (NODE_MODULE_VERSION ${a##* }): a replace, (a+)+\$ on 60 letters in no time" ;;
    *) fail "re2 in node: $(printf '%s' "$a" | head -n 3 | tr '\n' ' ' | cut -c1-200)" ;; esac
f="$(find "$D" \( -name '*.orig' -o -name '*.rej' -o -name '*.zip' -path '*reporting*' -o -path "$D/node/*" \) | head -n 5 | tr '\n' ' ')"
if [ -z "$f" ]; then pass "no backups of patches, no Node.js or browsers of macOS in the package"; else fail "in the package: $f"; fi
if [ "$(readlink "$D/config")" = ../../etc/kibana ] || [ "$(cd "$D/config" 2>/dev/null && pwd -P)" = "$P/etc/kibana" ]; then pass "www/kibana6/config -> etc/kibana"; else fail "www/kibana6/config: $(readlink "$D/config")"; fi
v="$(cd /tmp && "$D/bin/kibana" --version 2>&1)"
if [ "$v" = "$(pkgv kibana6)" ]; then pass "bin/kibana --version: $v"; else fail "bin/kibana --version: $(printf '%s' "$v" | tail -n 2 | tr '\n' ' ' | cut -c1-200), the package is $(pkgv kibana6)"; fi
v="$(cd /tmp && "$D/bin/kibana-plugin" list 2>&1)"
r=$?
if [ "$r" = 0 ] && [ -z "$(printf '%s' "$v" | tr -d ' \n')" ]; then pass "bin/kibana-plugin list: no plugins, no warnings"; else fail "bin/kibana-plugin list: exit $r, $(printf '%s' "$v" | tail -n 2 | tr '\n' ' ' | cut -c1-200)"; fi

# --- Elasticsearch, as tools/elastic-test.sh starts it ------------------------------------
conf="$T/conf"
mkdir -p "$conf" "$T/data" "$T/logs"
for f in elasticsearch.yml jvm.options log4j2.properties role_mapping.yml roles.yml; do
    cp "$P/etc/elasticsearch/$f.sample" "$conf/$f" || fail "no $P/etc/elasticsearch/$f.sample"
done
sed -i '' -e "s|^path.data: .*|path.data: $T/data|" -e "s|^path.logs: .*|path.logs: $T/logs|" "$conf/elasticsearch.yml"
{ echo "http.port: 19200"; echo "transport.port: 19300"; echo "network.host: 127.0.0.1"; echo "cluster.name: az-test"; } >> "$conf/elasticsearch.yml"
sed -i '' -e 's|^-Xms31g$|-Xms512m|' -e 's|^-Xmx31g$|-Xmx512m|' "$conf/jvm.options"
chown -R elasticsearch:elasticsearch "$conf" "$T/data" "$T/logs"
# the heap of the test: elasticsearch_heap of the rc script (jvm.options before it)
export elasticsearch_config="$conf" elasticsearch_heap="512m"
(cd / && "$P/etc/rc.d/elasticsearch" onestart > "$T/es-start.out" 2>&1) || fail "rc.d/elasticsearch onestart: $(tail -n 2 "$T/es-start.out" | tr '\n' ' ')"
up=""
i=0
while [ "$i" -lt 90 ]; do
    case "$(curl -s -m 5 "$es/" 2>/dev/null)" in *'"number"'*) up=1; break ;; esac
    sleep 2; i=$((i + 1))
done
stop_es() {
    "$P/etc/rc.d/elasticsearch" onestop > "$T/es-stop.out" 2>&1 || fail "rc.d/elasticsearch onestop: $(tail -n 1 "$T/es-stop.out")"
    cp "$T/logs/az-test.log" "$res/elasticsearch.log" 2>/dev/null
}
if [ -z "$up" ]; then
    fail "Elasticsearch does not answer on $es in 180 s: $(tail -n 3 "$T/logs/az-test.log" 2>/dev/null | tr '\n' ' ' | cut -c1-300)"
    stop_es
    finish
fi
curl -s -m 30 -o /dev/null "$es/_cluster/health?wait_for_status=yellow&timeout=60s"
curl -s -m 30 -o /dev/null -H 'Content-Type: application/json' -X PUT "$es/az-test" -d '{ "settings": { "number_of_shards": 1, "number_of_replicas": 0 } }'
for i in 1 2 3; do
    curl -s -m 30 -o /dev/null -H 'Content-Type: application/json' -X POST "$es/az-test/_doc?refresh=true" \
        -d "{ \"t\": \"2026-11-11T1$i:00:00Z\", \"title\": \"doc $i of azsupport\", \"n\": $i }"
done

# --- Kibana by its rc script (from /, as rc runs it: www cannot read every directory) ------
kconf="$T/kibana.yml"
cp "$P/etc/kibana/kibana.yml.sample" "$kconf" || fail "no $P/etc/kibana/kibana.yml.sample"
if grep -q '^xpack.ml.enabled: false$' "$kconf" && grep -q '^xpack.reporting.enabled: false$' "$kconf"; then
    pass "kibana.yml.sample: Machine Learning and Reporting off"
else
    fail "kibana.yml.sample: Machine Learning and Reporting are not off"
fi
# server.host stays the default, "localhost"
printf '%s\n' 'server.port: 15601' "elasticsearch.hosts: [\"http://localhost:19200\"]" "path.data: $T/kibana-data" >> "$kconf"
mkdir -p "$T/kibana-data"
chown www:www "$T/kibana-data"
before="$(find "$D/optimize" -type f | xargs sha256 -q | sha256 -q)"
# the rc script, as rc.conf would set it up: the configuration and log of the test
export kibana_config="$kconf" kibana_log="$T/kibana.log"
(cd / && "$P/etc/rc.d/kibana" onestart > "$T/kibana-start.out" 2>&1)
r=$?
cp "$T/kibana-start.out" "$res/kibana-start.out"
if [ "$r" = 0 ]; then pass "rc.d/kibana onestart"; else fail "rc.d/kibana onestart: exit $r, $(tail -n 2 "$T/kibana-start.out" | tr '\n' ' ')"; fi
state() { sed -n 's/.*"overall":{"state":"\([a-z]*\)".*/\1/p' "$T/a/status" 2>/dev/null; }
i=0
while [ "$i" -lt 150 ]; do
    rq status GET /api/status > /dev/null
    [ "$(state)" = green ] && break
    sleep 2; i=$((i + 1))
done
stop_kibana() {
    (cd / && "$P/etc/rc.d/kibana" onestop > "$T/kibana-stop.out" 2>&1)
    r=$?
    sleep 2
    if [ "$r" = 0 ] && ! curl -s -m 5 -o /dev/null "$kb/api/status"; then pass "rc.d/kibana onestop"; else fail "rc.d/kibana onestop: exit $r, $(tail -n 1 "$T/kibana-stop.out")"; fi
    cp "$T/kibana.log" "$res/kibana.log" 2>/dev/null
}
if [ "$(state)" != green ]; then
    fail "kibana: /api/status $(state) on $kb after 300 s: $(tail -n 3 "$T/kibana.log" 2>/dev/null | cut -c1-300 | tr '\n' ' ')"
    stop_kibana; stop_es
    finish
fi
pass "/api/status green on $kb (server.host localhost) after $((i * 2)) s"
kv="$(sed -n 's/.*"version":{"number":"\([^"]*\)".*/\1/p' "$T/a/status")"
if [ "$kv" = "$(pkgv kibana6)" ]; then pass "version $kv"; else fail "version ${kv:-not told}, the package is $(pkgv kibana6)"; fi
np="$(grep -o '"id":"plugin:[a-z_]*@' "$T/a/status" | wc -l | tr -d ' ')"
if has status '"id":"plugin:ml@' || has status '"id":"plugin:reporting@'; then fail "Machine Learning or Reporting is on"; else pass "$np plugins, all green, no Machine Learning, no Reporting"; fi
pid="$(cat /var/run/kibana/kibana.pid 2>/dev/null)"
c="$(ps -o user= -o command= -p "${pid:-0}" 2>/dev/null)"
case "$c" in www*"$node"*"$D/src/cli"*) pass "the process of the pid file: $node as www, $(ps -o rss= -p "$pid" | tr -d ' ') KB" ;; *) fail "the process of the pid file ${pid:-none}: $c" ;; esac
if grep -q 'Optimizing and caching' "$T/kibana.log"; then
    fail "it built its bundles again at its start (those of the package are not for its plugins)"
else
    pass "the bundles of the package, not built again at its start"
fi

# --- the requests of the browser and of the API ------------------------------------------
FIELDS='[{\"name\":\"t\",\"type\":\"date\",\"count\":0,\"scripted\":false,\"searchable\":true,\"aggregatable\":true,\"readFromDocValues\":true},{\"name\":\"title\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"searchable\":true,\"aggregatable\":false,\"readFromDocValues\":false},{\"name\":\"n\",\"type\":\"number\",\"count\":0,\"scripted\":false,\"searchable\":true,\"aggregatable\":true,\"readFromDocValues\":true}]'
TL='"time":{"from":"2026-11-11T00:00:00Z","to":"2026-11-12T00:00:00Z","interval":"1h","timezone":"UTC"}'
printf '%s\n' '{"index":"az-test*"}' '{"query":{"match":{"title":"azsupport"}},"sort":[{"n":"asc"}]}' > "$T/msearch.ndjson"
want "its page /app/kibana" app 200 '<title>Kibana</title>' GET /app/kibana
want "an index pattern saved (saved objects, POST)" pattern 200 '"title":"az-test*"' POST '/api/saved_objects/index-pattern/az-test?overwrite=true' \
    "{\"attributes\":{\"title\":\"az-test*\",\"timeFieldName\":\"t\",\"fields\":\"$FIELDS\"}}"
want "the index pattern read" pattern-get 200 '"timeFieldName":"t"' GET /api/saved_objects/index-pattern/az-test
want "the index pattern found" pattern-find 200 '"total":1' GET '/api/saved_objects/_find?type=index-pattern&search_fields=title&search=az*'
want "the fields of the index, from Elasticsearch" fields 200 '"name":"title"' GET '/api/index_patterns/_fields_for_wildcard?pattern=az-test*'
want "a setting saved" setting 200 '"userValue":"UTC"' POST /api/kibana/settings/dateFormat:tz '{"value":"UTC"}'
want "the documents through the proxy of Elasticsearch (POST _msearch)" msearch 200 '"hits":{"total":3' POST /elasticsearch/_msearch "@$T/msearch.ndjson" application/x-ndjson
want "the console: GET _cluster/health" console 200 '"cluster_name" : "az-test"' POST '/api/console/proxy?path=_cluster%2Fhealth&method=GET' ''
want "the console: a search with a body" console-search 200 '"title" : "doc 1 of azsupport"' POST '/api/console/proxy?path=az-test%2F_search&method=POST' \
    '{"query":{"match_all":{}},"size":1,"sort":[{"n":"asc"}]}'
want "Timelion: .es().label()" timelion 200 '"label":"docs"' POST /api/timelion/run "{\"sheet\":[\".es(index=az-test*, timefield=t).label(\\\"docs\\\")\"],$TL}"
want "Timelion: .label() with a regular expression (re2)" timelion-regex 200 '"label":"x q:* > count"' POST /api/timelion/run \
    "{\"sheet\":[\".es(index=az-test*, timefield=t).label(\\\"x \$1\\\", \\\"(.*)\\\")\"],$TL}"
want "Timelion: .static().multiply(), .es(metric=sum:n).cusum()" timelion-math 200 '"label":"ten"' POST /api/timelion/run \
    "{\"sheet\":[\".static(5).multiply(2).label(ten), .es(index=az-test*, timefield=t, metric=sum:n).cusum()\"],$TL}"
want "the Visual Builder: a count per hour" tsvb 200 '"p1":{"id":"p1","series":[{' POST /api/metrics/vis/data \
    '{"timerange":{"timezone":"UTC","min":"2026-11-11T00:00:00Z","max":"2026-11-12T00:00:00Z"},"filters":[],"panels":[{"id":"p1","type":"timeseries","series":[{"id":"s1","split_mode":"everything","metrics":[{"id":"m1","type":"count"}],"seperate_axis":0,"axis_position":"right","formatter":"number","chart_type":"line"}],"time_field":"t","index_pattern":"az-test*","interval":"1h","axis_position":"left","axis_formatter":"number"}]}'
c="$(rq sample POST /api/sample_data/ecommerce '')"
curl -s -m 30 -o /dev/null -X POST "$es/kibana_sample_data_ecommerce/_refresh"
n="$(curl -s -m 30 "$es/kibana_sample_data_ecommerce/_count" | sed -n 's/.*"count":\([0-9]*\).*/\1/p')"
if [ "$c" = 200 ] && [ "${n:-0}" = 4675 ]; then pass "the sample data set ecommerce installed: $n documents in Elasticsearch"; else fail "the sample data set: $c $(ans sample), ${n:-no} documents"; fi
c="$(rq sample-remove DELETE /api/sample_data/ecommerce)"
n="$(curl -s -m 30 -o /dev/null -w '%{http_code}' "$es/kibana_sample_data_ecommerce")"
[ "$c" = 200 ] && [ "$n" = 404 ] && pass "the sample data set removed" || fail "the sample data set removed: $c $(ans sample-remove), its index: $n"
want "the license and features of X-Pack" xpack 200 '"type":"basic"' GET /api/xpack/v1/info
want "a wrong body: 400" bad-json 400 '"statusCode":400' POST /api/saved_objects/_bulk_get '{"a":'
c="$(curl -s -m 30 -o "$T/a/no-xsrf" -w '%{http_code}' -H 'Content-Type: application/json' -X POST "$kb/api/saved_objects/_bulk_get" -d '[]')"
[ "$c" = 400 ] && has no-xsrf 'kbn-xsrf' && pass "a POST without kbn-xsrf: 400" || fail "a POST without kbn-xsrf: $c $(ans no-xsrf)"

# --- the bundles -------------------------------------------------------------------------
n=0; d=0
for f in "$D"/optimize/bundles/*.bundle.js "$D"/optimize/bundles/*.style.css "$D"/built_assets/dlls/*.js; do
    [ -f "$f" ] || continue
    b="${f##*/}"; case "$f" in */dlls/*) u=/built_assets/dlls ;; *) u=/bundles ;; esac
    e="$(sed "s|__REPLACE_WITH_PUBLIC_PATH__|$u/|g" "$f" | sha256 -q)"
    s="$(curl -s -m 120 "$kb$u/$b" | sha256 -q)"
    z="$(curl -s -m 120 --compressed -H 'Accept-Encoding: gzip, deflate' "$kb$u/$b" | sha256 -q)"
    n=$((n + 1))
    [ "$s" = "$e" ] && [ "$z" = "$e" ] || { d=$((d + 1)); note "served differently: $b"; }
done
if [ "$d" = 0 ] && [ "$n" -gt 10 ]; then pass "$n bundles served as the files, plain and with gzip"; else fail "$d of $n bundles served differ from the files"; fi
h="$(curl -s -m 60 -D - -o /dev/null -H 'Accept-Encoding: gzip' "$kb/bundles/kibana.bundle.js" | tr -d '\r')"
et="$(printf '%s\n' "$h" | sed -n 's/^[Ee][Tt]ag: *//p')"
c="$(curl -s -m 60 -o /dev/null -w '%{http_code}' -H "If-None-Match: $et" "$kb/bundles/kibana.bundle.js")"
if printf '%s\n' "$h" | grep -q -i '^content-encoding: gzip' && [ "$c" = 304 ]; then pass "kibana.bundle.js: gzip, 304 for its ETag"; else fail "kibana.bundle.js: $(printf '%s' "$h" | tr '\n' ' ' | cut -c1-200), $c for If-None-Match"; fi

# --- many requests at once: only the requests are waited for -----------------------------
for round in 1 2 3; do
    pids=""
    i=1
    while [ "$i" -le 60 ]; do
        printf '%s\n' '{"index":"az-test*"}' "{\"query\":{\"match\":{\"title\":\"azsupport\"}},\"size\":$((i % 3 + 1)),\"sort\":[{\"n\":\"asc\"}]}" > "$T/m/q$i"
        curl -s -m 60 -o "$T/m/a$i" -w '%{http_code}' -H 'kbn-xsrf: t' -H 'Content-Type: application/x-ndjson' \
            -X POST "$kb/elasticsearch/_msearch" --data-binary "@$T/m/q$i" > "$T/m/c$i" 2>/dev/null &
        pids="$pids $!"
        i=$((i + 1))
    done
    i=1
    while [ "$i" -le 20 ]; do
        curl -s -m 60 -o "$T/m/s$i" -w '%{http_code}' -H 'kbn-xsrf: t' -H 'Content-Type: application/json' \
            -X POST "$kb/api/saved_objects/_bulk_get" -d '[{"type":"index-pattern","id":"az-test"}]' > "$T/m/d$i" 2>/dev/null &
        pids="$pids $!"
        curl -s -m 60 -o /dev/null -w '%{http_code}' --compressed "$kb/bundles/commons.bundle.js" > "$T/m/b$i" 2>/dev/null &
        pids="$pids $!"
        i=$((i + 1))
    done
    # shellcheck disable=SC2086
    wait $pids
    g=0; w=""
    i=1
    while [ "$i" -le 60 ]; do
        if [ "$(cat "$T/m/c$i")" = 200 ] && grep -q '"hits":{"total":3' "$T/m/a$i" && [ "$(grep -o '"_id"' "$T/m/a$i" | wc -l | tr -d ' ')" = $((i % 3 + 1)) ]; then
            g=$((g + 1))
        else
            w="${w:-msearch $i: $(cat "$T/m/c$i") $(head -c 120 "$T/m/a$i")}"
        fi
        i=$((i + 1))
    done
    i=1
    while [ "$i" -le 20 ]; do
        if [ "$(cat "$T/m/d$i")" = 200 ] && grep -q '"title":"az-test\*"' "$T/m/s$i"; then g=$((g + 1)); else w="${w:-bulk_get $i: $(cat "$T/m/d$i")}"; fi
        if [ "$(cat "$T/m/b$i")" = 200 ]; then g=$((g + 1)); else w="${w:-bundle $i: $(cat "$T/m/b$i")}"; fi
        i=$((i + 1))
    done
    if [ "$g" = 100 ]; then pass "100 requests at once (60 POST _msearch, 20 POST _bulk_get, 20 bundles), round $round: every answer right"; else fail "100 requests at once, round $round: $g right; $w"; fi
done
c="$(curl -s -m 60 -o "$T/a/chunked" -w '%{http_code}' -H 'kbn-xsrf: t' -H 'Content-Type: application/json' -H 'Transfer-Encoding: chunked' -X POST "$kb/api/saved_objects/_bulk_get" --data-binary '[{"type":"index-pattern","id":"az-test"}]')"
[ "$c" = 200 ] && has chunked '"title":"az-test*"' && pass "a body with Transfer-Encoding: chunked" || fail "a body with Transfer-Encoding: chunked: $c $(ans chunked)"
i=1
while [ "$i" -le 20 ]; do
    curl -s -m 0.02 -o /dev/null "$kb/bundles/commons.bundle.js" 2>/dev/null &
    curl -s -m 0.01 -o /dev/null -H 'kbn-xsrf: t' -H 'Content-Type: application/x-ndjson' -X POST "$kb/elasticsearch/_msearch" --data-binary "@$T/m/q1" 2>/dev/null &
    i=$((i + 1))
done
sleep 3
want "it answers after 40 clients that went away" after 200 '"state":"green"' GET /api/status

# --- reload, the log, the stop ------------------------------------------------------------
mv "$T/kibana.log" "$T/kibana.log.0"
install -o www -g www -m 640 /dev/null "$T/kibana.log"
(cd / && "$P/etc/rc.d/kibana" onereload > "$T/kibana-reload.out" 2>&1)
r=$?
sleep 2
rq status GET /api/status > /dev/null
if [ "$r" = 0 ] && grep -q 'Reloaded logging configuration due to SIGHUP' "$T/kibana.log"; then
    pass "rc.d/kibana onereload: the new log file is written"
else
    fail "rc.d/kibana onereload: exit $r, $(tail -n 1 "$T/kibana-reload.out"), the new log: $(wc -l < "$T/kibana.log" | tr -d ' ') lines"
fi
cat "$T/kibana.log" >> "$T/kibana.log.0"; mv "$T/kibana.log.0" "$T/kibana.log"
after="$(find "$D/optimize" -type f | xargs sha256 -q | sha256 -q)"
if [ "$before" = "$after" ]; then pass "optimize/ of the package as it was installed"; else fail "the files of optimize/ changed while Kibana ran"; fi
# the answers 400 of the two wrong requests above are logged as responses, not errors
if grep -E '"type":"error"|"tags":\[[^]]*"(error|fatal)"' "$T/kibana.log" > "$T/kerr.txt" 2>/dev/null; then
    fail "$(wc -l < "$T/kerr.txt" | tr -d ' ') errors in its log (kibana.log): $(head -n 1 "$T/kerr.txt" | cut -c1-240)"
else
    pass "no errors in its log"
fi
w="$(grep -c '"tags":\[[^]]*"warning"' "$T/kibana.log" 2>/dev/null)"
[ "${w:-0}" = 0 ] || note "its log has $w warnings (kibana.log): $(grep '"tags":\[[^]]*"warning"' "$T/kibana.log" | sed 's/.*"message":"\([^"]*\)".*/\1/' | sort -u | head -n 3 | cut -c1-160 | tr '\n' ' ')"
stop_kibana
stop_es
finish
