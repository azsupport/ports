#!/bin/sh
# opensearch-upgrade-test.sh - the way aZ takes his nodes of OpenSearch 2.17.1 to
# 2.19.7 (aZ, 12.11.2026: 2.19 is the bridge of his cluster to 3.x, which upgrades
# from 2.19 alone), with the packages of the repository az:
#   1. opensearch217 and his node ko44 as his server has it: service opensearch
#      start (opensearch_enable and opensearch_heap 512m in
#      /etc/rc.conf.d/opensearch) with the opensearch.yml of ko44 in
#      /usr/local/etc/opensearch, a node of the cluster manager alone
#      (node.master: true, node.data: false, node.ingest: false), on 0.0.0.0, the
#      ports 8200 and 8300, bootstrap.memory_lock: true, the paths of the package,
#      /var/db/opensearch and /var/log/opensearch (its line
#      plugins.security.disabled out, its IPs and the initial master ko38
#      replaced by this node); a data node of the same package beside it, data1
#      (127.0.0.1:8201 and 8301, started by hand as opensearch, its own
#      directories), which holds the data: the index az-upgrade with 1001
#      documents, az-upgrade-zstd with the codec zstd of opensearch-custom-codecs,
#      a policy of opensearch-index-management on az-upgrade
#      (.opendistro-ism-config), a channel of opensearch-notifications
#      (.opensearch-notifications-config), a result of
#      opensearch-asynchronous-search kept in its index
#      (.opendistro-asynchronous-search-response), a connector of a remote model
#      of opensearch-ml (.plugins-ml-connector, its credential encrypted by the
#      master key of .plugins-ml-config), the log types of
#      opensearch-security-analytics; the settings of aZ's cluster, exactly as he
#      has them (those of ko44, 12.11.2026: 13 persistent, among them the
#      exporters of query-insights per metric and a key of no use 2.17.1 took,
#      and one transient), taken; every index, its health and its documents
#      noted; both stopped, data1 first;
#   2. pkg install opensearch219, as aZ will: pkg takes opensearch217 away (the
#      same files) and installs that of the repository; his opensearch.yml stays,
#      the jvm.options and log4j2.properties he did not change are those of the
#      new package, the keystore and /var/db/opensearch stay; data1 by hand and
#      ko44 by service opensearch start, both of opensearch219 now (data1 first,
#      as on his cluster, where the data nodes are up when the cluster manager
#      comes back), on the same path.data: the same cluster (its UUID), ko44 its cluster manager with the
#      role m alone, every index of 2.17.1 with the health it had, the documents
#      of the two indices (counted, one read by its id, found by a search, the
#      codec zstd), their version.created that of 2.17.1, a document written, the
#      policy and its index, the channel, the kept result of the search, the
#      connector, the log types and the prepackaged rules of
#      opensearch-security-analytics (from its directory in the configuration,
#      the package's), the plugins of opensearch219 loaded on both nodes; what
#      the new version does with each setting of aZ's cluster (kept, archived.*,
#      missing; an error would stop it from starting): as the sources of 2.19 have
#      it, the 8 it knows kept, the 5 of the exporters of query-insights per
#      metric, which 2.19 dropped for one exporter of all
#      (search.insights.top_queries.exporter.*), archived when ko44 loads the
#      state of the cluster from its disk, the transient one gone with the restart
#      of the cluster; a setting of the cluster changed with the archived there,
#      and the archived taken away ("archived.*": null); no [ERROR] in the logs of
#      the two; both stopped;
#   3. a cluster of the two versions on this host, as aZ's will be while he
#      upgrades it node by node, the data nodes first (OpenSearch: a node joins a
#      cluster manager of an older version, not one of a newer, so those eligible
#      as cluster manager go last): a node of 2.17.1 (the package opensearch217 of
#      the repository, pkg fetch, unpacked into the directory of this test), the
#      cluster manager with data, on 127.0.0.1:19211/19311, and a data node of the
#      installed opensearch219 on 127.0.0.1:19212/19312, which joins it, both
#      started by hand as opensearch (heaps of 512m), each on the JDK of its rc
#      script; the 13 persistent settings of aZ's cluster on it before the join
#      (the new version joins a cluster that has the exporter settings it does
#      not know, as aZ's will); an index with one replica made before the join:
#      green, its primary on 2.17.1 and its replica on the new version, its
#      documents found through both nodes, one written through the node of the new
#      version and counted on its replica; no [ERROR] in the logs of the two; both
#      stopped.
# The [ERROR] that opensearch-security-analytics 2.17.1 logs at each start
# ("Failed loading builtin log types from disk!", upstream
# security-analytics#1312) is its own, not one of these checks. The last lines
# of its output and summary.txt next to tests.txt (which tools/test-programs.sh
# shows) sum it up.
#
# Usage (FreeBSD, as root, opensearch217 installed from the repository azbuild of
# tools/test-programs.sh, which has opensearch219):
#   sh tools/opensearch-upgrade-test.sh
# Results: opensearch-upgrade-results/tests.txt (one line per check, the summary
# at the end), the logs of OpenSearch next to it; exit status 0 when every check
# passed.

set -u
res="${AZ_RESULTS:-$(pwd)/opensearch-upgrade-results}"
T="${OPENSEARCH_TEST_WORK:-/var/tmp/opensearch-upgrade-test}"
P=/usr/local
E="$P/etc/opensearch"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"
out="$res/tests.txt"
: > "$out"
sum="$res/summary.txt"
: > "$sum"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
# inst <package>: installed from the repository azbuild
inst() { [ "$(pkg query '%At %Av' "$1" 2>/dev/null | awk '$1 == "repository" { print $2; exit }')" = azbuild ]; }
ko="http://127.0.0.1:8200"
dn="http://127.0.0.1:8201"
na="http://127.0.0.1:19211"
nb="http://127.0.0.1:19212"
# get <url> <path>: the answer, or nothing; send <url> <method> <path> [<json>]
get() { curl -s -m 30 "$1$2" 2>/dev/null; }
send() { curl -s -m 60 -H 'Content-Type: application/json' -X "$2" "$1$3" ${4:+-d "$4"} 2>/dev/null; }
bulk() { curl -s -m 120 -H 'Content-Type: application/x-ndjson' -X POST "$1$2" --data-binary @"$3" 2>/dev/null; }
# up <url> <seconds>: wait until OpenSearch answers there
up() { _i=0; while [ "$_i" -lt "$2" ]; do curl -s -m 5 "$1/" 2>/dev/null | grep -q '"number"' && return 0; sleep 2; _i=$((_i + 2)); done; return 1; }
# js <key>, jn <key>: the first string, the first number of that key in the JSON
# on the standard input
js() { tr ',{}' '\n\n\n' | sed -n "s/^ *\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n 1; }
jn() { tr ',{}' '\n\n\n' | sed -n "s/^ *\"$1\" *: *\([0-9][0-9]*\).*/\1/p" | head -n 1; }
# errs <log>: its lines of [ERROR] (but the one of opensearch-security-analytics
# 2.17.1, above), at most two, shortened
known_err="Failed loading builtin log types from disk"
errs() { grep -E '\]\[ERROR\]' "$1" 2>/dev/null | grep -v -e "$known_err" | head -n 2 | sed -e 's/^[^]]*\]//' | cut -c1-300 | tr '\n' ' '; }
nerrs() { grep -E '\]\[ERROR\]' "$1" 2>/dev/null | grep -c -v -e "$known_err"; }
lg() { grep -E '\]\[(ERROR|WARN ?)\]' "$1" 2>/dev/null | tail -n 2 | sed -e 's/^[^]]*\]//' | cut -c1-220 | tr '\n' ' '; }
osproc() { pgrep -U opensearch -f 'org.opensearch.bootstrap.OpenSearch' > /dev/null; }
# the summary: the last lines of the output
s1="the upgrade: not tried"; s2="the cluster of two versions: not tried"
s3="the settings of aZ's cluster: not tried"
end() {
    echo "opensearch-upgrade-test: $ok ok, $bad failed" >> "$out"
    printf '%s\n%s\n%s\n' "$s1" "$s3" "$s2" >> "$sum"
    echo "$s1"
    echo "$s2"
    echo "opensearch-upgrade-test: $ok ok, $bad failed (opensearch-upgrade-results/tests.txt)"
    [ "$bad" = 0 ] && exit 0
    exit 1
}
# the nodes started by hand: stopnode <directory>
stopnode() {
    _p="$(cat "$1/pid" 2>/dev/null)"
    [ -n "$_p" ] || return 1
    kill "$_p" 2>/dev/null
    _i=0
    while kill -0 "$_p" 2>/dev/null && [ "$_i" -lt 90 ]; do sleep 1; _i=$((_i + 1)); done
    rm -f "$1/pid"
    ! kill -0 "$_p" 2>/dev/null
}
# mkconf <directory> <the ETCDIR of its package>: its configuration (the samples
# of the package, the prepackaged rules of opensearch-security-analytics when the
# package has them) and directories, of opensearch; its opensearch.yml stays
mkconf() {
    mkdir -p "$1/conf" "$1/data" "$1/logs" "$1/tmp"
    for f in jvm.options log4j2.properties opensearch-notifications-core/notifications-core.yml opensearch-notifications/notifications.yml \
        opensearch-observability/observability.yml opensearch-reports-scheduler/reports-scheduler.yml; do
        case "$f" in */*) mkdir -p "$1/conf/${f%/*}" ;; esac
        cp "$2/$f.sample" "$1/conf/$f" || return 1
    done
    rm -rf "$1/conf/opensearch-security-analytics"
    if [ -d "$2/opensearch-security-analytics" ]; then cp -Rp "$2/opensearch-security-analytics" "$1/conf/"; fi
    chown -R opensearch:opensearch "$1"
    chmod 700 "$1/tmp"
}
# jhome <rc script>: the JDK it runs OpenSearch on (its opensearch_java_home)
jhome() { sed -n 's/^: \${opensearch_java_home="\([^"]*\)"}.*/\1/p' "$1" | head -n 1; }
# startnode <directory> <the home of its OpenSearch> <its JDK>: by hand, as
# opensearch, as the rc script runs it (-d, a pidfile), with its own temporary
# directory
startnode() {
    (cd / && su -m opensearch -c "env -u OPENSEARCH_JAVA_HOME JAVA_HOME='$3' OPENSEARCH_PATH_CONF='$1/conf' OPENSEARCH_JAVA_OPTS='-Xms512m -Xmx512m' OPENSEARCH_TMPDIR='$1/tmp' '$2/bin/opensearch' -d -p '$1/pid'") > "$1/start.out" 2>&1 < /dev/null
}
# the settings of aZ's cluster (12.11.2026: those of ko44), persistent and
# transient, exactly as he has them
cat > "$T/ko44-cluster-settings.json" << 'EOF'
{
  "persistent": {
    "cluster.routing.allocation.enable": "all",
    "plugins.index_state_management.metadata_migration.status": 1,
    "plugins.index_state_management.template_migration.control": -1,
    "search.insights.top_queries.cpu.enabled": false,
    "search.insights.top_queries.latency.enabled": false,
    "search.insights.top_queries.cpu.exporter.config.index": "'top-cpu-'YYYY",
    "search.insights.top_queries.cpu.exporter.enabled": false,
    "search.insights.top_queries.cpu.exporter.asd": false,
    "search.insights.top_queries.latency.exporter.config.index": "'top-latensy-'YYYY",
    "search.insights.top_queries.latency.exporter.enabled": false,
    "search.insights.top_queries.group_by": "none",
    "search.insights.top_queries.max_groups_excluding_topn": 100,
    "search.query.metrics.enabled": false
  },
  "transient": {
    "cluster.routing.allocation.enable": "all"
  }
}
EOF
sed -n '/"persistent"/,/^  }/p' "$T/ko44-cluster-settings.json" | grep -v '"persistent"' | sed -n 's/^ *"\([a-z_.]*\)": *\(.*\)$/\1 \2/p' | sed -e 's/,$//' -e 's/ "\(.*\)"$/ \1/' > "$T/ko44-persistent.txt"
# the persistent ones alone, for the cluster of two versions (3.)
{ echo '{'; sed -n '/"persistent"/,/^  }/p' "$T/ko44-cluster-settings.json" | sed '$s/,$//'; echo '}'; } > "$T/ko44-persistent.json"
# fate <url>: each persistent setting of aZ's cluster as that node has it, one per
# line: "<key> kept" (with its value), "<key> archived" (archived.<key>, with its
# value) or "<key> missing"; and the transient one, "transient kept" or
# "transient gone"
fate() {
    _g="$(curl -s -m 30 "$1/_cluster/settings?flat_settings=true" 2>/dev/null)"
    _p="$(printf '%s' "$_g" | sed -n 's/.*"persistent" *: *{\([^}]*\)}.*/\1/p')"
    _t="$(printf '%s' "$_g" | sed -n 's/.*"transient" *: *{\([^}]*\)}.*/\1/p')"
    while read -r _k _v; do
        case "$_p" in
            *"\"archived.$_k\":\"$_v\""*) echo "$_k archived" ;;
            *"\"$_k\":\"$_v\""*) echo "$_k kept" ;;
            *) echo "$_k missing" ;;
        esac
    done < "$T/ko44-persistent.txt"
    case "$_t" in *'"cluster.routing.allocation.enable":"all"'*) echo "transient kept" ;; *) echo "transient gone" ;; esac
}
rcd=/etc/rc.conf.d/opensearch
D="$T/data1"
cleanup() {
    for d in "$T/b219" "$T/a217" "$D"; do [ -s "$d/pid" ] && stopnode "$d"; done
    service opensearch onestop > /dev/null 2>&1
    if [ -f "$T/rc.conf.d-opensearch" ]; then cp -p "$T/rc.conf.d-opensearch" "$rcd"; else rm -f "$rcd"; fi
    rm -rf "$T/os217" "$T/pkg"
}
trap cleanup EXIT
trap 'exit 1' INT TERM

if ! inst opensearch217; then
    fail "opensearch217 is not installed from the repository azbuild"
    end
fi
if [ "$(pkg rquery -r azbuild '%n' opensearch219 2>/dev/null)" != opensearch219 ]; then
    fail "the repository azbuild has no opensearch219"
    end
fi
v217="$(pkgv opensearch217)"
v219="$(pkg rquery -r azbuild '%v' opensearch219 2>/dev/null | sed 's/[_,].*//')"
service opensearch onestop > /dev/null 2>&1

# 1. opensearch217: ko44, of the cluster manager alone, and data1, which holds
# the data
[ -f "$rcd" ] && cp -p "$rcd" "$T/rc.conf.d-opensearch"
mkdir -p "${rcd%/*}"
printf '%s\n' 'opensearch_enable="YES"' 'opensearch_heap="512m"' > "$rcd"
cat > "$E/opensearch.yml" << 'EOF'
indices.recovery.max_concurrent_file_chunks: 5
indices.recovery.max_bytes_per_sec: 2048mb
cluster.routing.allocation.cluster_concurrent_rebalance: 200
cluster.routing.allocation.node_initial_primaries_recoveries: 200
cluster.routing.allocation.node_concurrent_recoveries: 200
cluster.remote.connect: false
cluster.name: ko44
node.name: ko44
node.master: true
node.data: false
node.ingest: false
path.data: /var/db/opensearch
path.logs: /var/log/opensearch
bootstrap.memory_lock: true
network.host: 0.0.0.0
http.port: 8200
transport.port: 8300
#xpack.ml.enabled: false
#xpack.monitoring.history.duration: 1d
discovery.seed_hosts: ["127.0.0.1:8300"]
cluster.initial_master_nodes: ["ko44"]
reindex.remote.whitelist: "localhost:*"
EOF
cp "$E/opensearch.yml" "$T/opensearch.yml.ko44"
rm -rf /var/db/opensearch /var/log/opensearch
t0="$(date +%s)"
service opensearch start > "$T/start-2.17.out" 2>&1; r=$?
if [ "$r" != 0 ] || ! up "$ko" 180; then
    fail "2.17.1, ko44: service opensearch start: exit $r, $(tail -n 2 "$T/start-2.17.out" | cut -c1-200 | tr '\n' ' '); its log: $(lg /var/log/opensearch/ko44.log)"
    cp /var/log/opensearch/ko44.log "$res/ko44-2.17.log" 2>/dev/null
    end
fi
mkconf "$D" "$E" || fail "2.17.1, data1: no configuration (the samples of opensearch217)"
cat > "$D/conf/opensearch.yml" << EOF
cluster.name: ko44
node.name: data1
node.roles: [ data, ingest ]
path.data: $D/data
path.logs: $D/logs
network.host: 127.0.0.1
http.port: 8201
transport.port: 8301
discovery.seed_hosts: ["127.0.0.1:8300"]
EOF
chown opensearch:opensearch "$D/conf/opensearch.yml"
j217="$(jhome "$P/etc/rc.d/opensearch")"
startnode "$D" "$P/lib/opensearch" "${j217:-$P/openjdk21}"; r=$?
if [ "$r" != 0 ] || ! up "$dn" 180; then
    fail "2.17.1, data1: exit $r, $(tail -n 2 "$D/start.out" | cut -c1-200 | tr '\n' ' '); its log: $(lg "$D/logs/ko44.log")"
    cp "$D/logs/ko44.log" "$res/data1-2.17.log" 2>/dev/null
    end
fi
a="$(get "$ko" /)"
v="$(printf '%s' "$a" | js number)"
cu="$(printf '%s' "$a" | js cluster_uuid)"
jv1="$(get "$ko" '/_nodes/_local/jvm?filter_path=**.jvm.version' | js version)"
h0="$(get "$ko" '/_cluster/health?wait_for_nodes=2&timeout=120s' | jn number_of_nodes)"
nd1="$(get "$ko" '/_cat/nodes?h=name,version,node.role,cluster_manager&s=name' | tr -s ' ' | sed 's/ $//' | tr '\n' ';')"
mla="$(get "$ko" '/_nodes/_local/process?filter_path=**.process.mlockall' | sed -n 's/.*"mlockall" *: *\([a-z]*\).*/\1/p')"
if [ "$v" = "$v217" ] && [ -n "$cu" ] && [ "$h0" = 2 ] && [ "$nd1" = "data1 $v217 di -;ko44 $v217 m *;" ] && [ "$mla" = true ]; then
    pass "2.17.1: ko44 by service opensearch start with its opensearch.yml in $E (the cluster manager alone, 0.0.0.0:8200, mlockall true) and data1 (data, ingest) by hand: the cluster $cu, $nd1"
else
    fail "2.17.1: version ${v:-not told} (the package: $v217), the cluster ${cu:-not told}, nodes ${h0:-none}: ${nd1:-no answer}; mlockall of ko44 ${mla:-not told}"
fi
# the documents, on data1
send "$ko" PUT /az-upgrade '{ "settings": { "number_of_shards": 2, "number_of_replicas": 0 }, "mappings": { "properties": { "title": { "type": "text" }, "tag": { "type": "keyword" }, "n": { "type": "integer" } } } }' > "$T/i1.out"
awk 'BEGIN { for (i = 1; i <= 1000; i++) printf "{\"index\":{\"_id\":\"%d\"}}\n{\"title\":\"document %d of the upgrade\",\"tag\":\"t%d\",\"n\":%d}\n", i, i, i % 10, i }' > "$T/bulk1.ndjson"
bulk "$ko" '/az-upgrade/_bulk?refresh=true' "$T/bulk1.ndjson" > "$T/bulk1.out"
send "$ko" PUT '/az-upgrade/_doc/ko44-1?refresh=true' '{ "title": "opensearch of azsupport before the upgrade", "tag": "ko44", "n": 2171 }' > "$T/d1.out"
send "$ko" PUT /az-upgrade-zstd '{ "settings": { "number_of_shards": 1, "number_of_replicas": 0, "codec": "zstd" } }' > "$T/i2.out"
awk 'BEGIN { for (i = 1; i <= 100; i++) printf "{\"index\":{\"_id\":\"%d\"}}\n{\"title\":\"zstd document %d\",\"n\":%d}\n", i, i, i }' > "$T/bulk2.ndjson"
bulk "$ko" '/az-upgrade-zstd/_bulk?refresh=true' "$T/bulk2.ndjson" > "$T/bulk2.out"
send "$ko" POST /az-upgrade-zstd/_flush > /dev/null
c1="$(get "$ko" /az-upgrade/_count | jn count)"
c2="$(get "$ko" /az-upgrade-zstd/_count | jn count)"
sh1="$(get "$ko" '/_cat/shards/az-upgrade*?h=node' | sort -u | tr '\n' ' ')"
if [ "$c1" = 1001 ] && [ "$c2" = 100 ] && grep -q '"errors" *: *false' "$T/bulk1.out" && grep -q '"errors" *: *false' "$T/bulk2.out" && [ "$sh1" = "data1 " ]; then
    pass "2.17.1: az-upgrade with 1001 documents, az-upgrade-zstd (the codec zstd) with 100, their shards on data1"
else
    fail "2.17.1: the documents: az-upgrade ${c1:-none} of 1001, az-upgrade-zstd ${c2:-none} of 100, their shards on ${sh1:-no node} ($(cut -c1-120 "$T/i1.out") $(cut -c1-120 "$T/bulk1.out") $(cut -c1-120 "$T/i2.out"))"
fi
vc1="$(get "$ko" '/az-upgrade/_settings?filter_path=**.version.created' | js created)"
# the objects of the plugins, in their system indices
p1="$(send "$ko" PUT /_plugins/_ism/policies/az-upgrade '{ "policy": { "description": "the upgrade test of azsupport", "default_state": "hot", "states": [ { "name": "hot", "actions": [], "transitions": [] } ] } }')"
p2="$(send "$ko" POST /_plugins/_ism/add/az-upgrade '{ "policy_id": "az-upgrade" }')"
if printf '%s' "$p1" | grep -q '"_id" *: *"az-upgrade"' && printf '%s' "$p2" | grep -q '"updated_indices" *: *1'; then
    pass "2.17.1: the policy az-upgrade of opensearch-index-management, on the index az-upgrade"
else
    fail "2.17.1: the policy of opensearch-index-management: $(printf '%s' "$p1" | cut -c1-150); on the index: $(printf '%s' "$p2" | cut -c1-150)"
fi
n1="$(send "$ko" POST /_plugins/_notifications/configs '{ "config_id": "az-upgrade", "config": { "name": "the upgrade test of azsupport", "description": "a channel of the test, never used", "config_type": "webhook", "is_enabled": true, "webhook": { "url": "https://example.com/az-upgrade" } } }')"
if printf '%s' "$n1" | grep -q '"config_id" *: *"az-upgrade"'; then
    pass "2.17.1: the channel az-upgrade of opensearch-notifications (a webhook, never used)"
else
    fail "2.17.1: the channel of opensearch-notifications: $(printf '%s' "$n1" | cut -c1-200)"
fi
q1="$(send "$ko" POST '/az-upgrade/_plugins/_asynchronous_search?wait_for_completion_timeout=1ms&keep_on_completion=true&keep_alive=2d' '{ "size": 0, "track_total_hits": true, "query": { "match_all": {} } }')"
aid="$(printf '%s' "$q1" | js id)"
q2=""; i=0
while [ -n "$aid" ] && [ "$i" -lt 30 ]; do
    q2="$(get "$ko" "/_plugins/_asynchronous_search/$aid")"
    case "$(printf '%s' "$q2" | js state)" in STORE_RESIDENT|PERSIST_SUCCEEDED) break ;; esac
    sleep 2; i=$((i + 1))
done
qs="$(printf '%s' "$q2" | js state)"; qv="$(printf '%s' "$q2" | jn value)"
case "$qs" in
    STORE_RESIDENT|PERSIST_SUCCEEDED)
        if [ "$qv" = 1001 ]; then pass "2.17.1: a search of opensearch-asynchronous-search, its result kept ($qs: 1001 hits)"; else fail "2.17.1: the kept search: $qs, ${qv:-no} hits, not 1001"; fi ;;
    *) fail "2.17.1: the search of opensearch-asynchronous-search: ${qs:-no state} ($(printf '%s' "${q2:-$q1}" | cut -c1-200))" ;;
esac
# the connector: opensearch-ml makes its master key when the cluster has its
# index (.plugins-ml-config) on a data node; until then it answers "The ML
# encryption master key has not been initialized yet. Please retry after waiting
# for 10 seconds": retried so, up to 2 minutes
i=0; mtry=1
while :; do
    mc="$(send "$ko" POST /_plugins/_ml/connectors/_create '{ "name": "az-upgrade", "description": "a connector of the upgrade test of azsupport, never called", "version": 1, "protocol": "http", "parameters": { "model": "text-embedding-3-small" }, "credential": { "openAI_key": "not-a-key" }, "actions": [ { "action_type": "predict", "method": "POST", "url": "https://api.openai.com/v1/embeddings", "headers": { "Authorization": "Bearer ${credential.openAI_key}" }, "request_body": "{ \"input\": ${parameters.input}, \"model\": \"${parameters.model}\" }", "pre_process_function": "connector.pre_process.openai.embedding", "post_process_function": "connector.post_process.openai.embedding" } ] }')"
    printf '%s' "$mc" | grep -q 'master key has not been initialized yet' || break
    [ "$i" -lt 12 ] || break
    sleep 10; i=$((i + 1)); mtry=$((mtry + 1))
done
mcid="$(printf '%s' "$mc" | js connector_id)"
if [ -n "$mcid" ]; then pass "2.17.1: a connector of a remote model of opensearch-ml ($mcid$([ "$mtry" -gt 1 ] && echo "; at try $mtry: before it the master key of the plugin was not made yet"))"; else fail "2.17.1: the connector of opensearch-ml, $mtry tries: $(printf '%s' "$mc" | cut -c1-200)"; fi
cs="$(curl -s -m 30 -H 'Content-Type: application/json' -X PUT "$ko/_cluster/settings" --data-binary @"$T/ko44-cluster-settings.json" 2>/dev/null)"
sleep 2
fate "$ko" > "$T/fate-2.17.txt"
cp "$T/fate-2.17.txt" "$res/settings-2.17.txt"
if printf '%s' "$cs" | grep -q '"acknowledged" *: *true' && [ "$(grep -c ' kept$' "$T/fate-2.17.txt")" = 14 ]; then
    pass "2.17.1: the settings of aZ's cluster taken, the 13 persistent and the transient one, each with its value"
else
    fail "2.17.1: the settings of aZ's cluster: $(printf '%s' "$cs" | cut -c1-160); not kept: $(grep -v ' kept$' "$T/fate-2.17.txt" | tr '\n' ';')"
fi
lt1=""; i=0
while [ "$i" -lt 12 ]; do
    lt1="$(send "$ko" POST /_plugins/_security_analytics/logtype/_search '{ "size": 0, "query": { "match_all": {} } }' | jn value)"
    [ "${lt1:-0}" -gt 0 ] && break
    sleep 5; i=$((i + 1))
done
[ "${lt1:-0}" -gt 0 ] && pass "2.17.1: the log types of opensearch-security-analytics: $lt1" || fail "2.17.1: no log types of opensearch-security-analytics in 60 s"
# the indices, their health and documents
# (the health waits up to 60 s for green, curl longer: yellow is told when an
# index has a replica no node can hold)
h1="$(curl -s -m 90 "$ko/_cluster/health?wait_for_status=green&wait_for_no_initializing_shards=true&wait_for_no_relocating_shards=true&timeout=60s" 2>/dev/null | js status)"
get "$ko" '/_cat/indices?h=index,health,status,pri,rep,docs.count&s=index&expand_wildcards=all' | tr -s ' ' | sed 's/ $//' | grep . > "$T/indices-2.17.txt"
cp "$T/indices-2.17.txt" "$res/indices-2.17.txt"
ni="$(wc -l < "$T/indices-2.17.txt" | tr -d ' ')"
case "$h1" in green|yellow) pass "2.17.1: the health of the cluster $h1, $ni indices (indices-2.17.txt)" ;; *) fail "2.17.1: the health of the cluster: ${h1:-no answer}" ;; esac
stopnode "$D"; rd=$?
service opensearch stop > "$T/stop-2.17.out" 2>&1; r=$?
sleep 2
cp /var/log/opensearch/ko44.log "$res/ko44-2.17.log" 2>/dev/null
cp "$D/logs/ko44.log" "$res/data1-2.17.log" 2>/dev/null
e1="$(errs /var/log/opensearch/ko44.log)"; e2="$(errs "$D/logs/ko44.log")"
[ -z "$e1$e2" ] || note "2.17.1: [ERROR] in the log of ko44: ${e1:-none}; of data1: ${e2:-none}"
if [ "$r" = 0 ] && [ "$rd" = 0 ] && ! curl -s -m 5 "$ko/" > /dev/null 2>&1 && ! osproc; then
    pass "2.17.1: data1 stopped, then ko44 by service opensearch stop"
else
    fail "2.17.1: stopped: data1 $rd (0: stopped), ko44 by service opensearch stop: exit $r, $(tail -n 1 "$T/stop-2.17.out")"
    end
fi
nl="$(wc -l < /var/log/opensearch/ko44.log | tr -d ' ')"
nld="$(wc -l < "$D/logs/ko44.log" | tr -d ' ')"
b1="$bad"

# 2. pkg install opensearch219, as aZ will, and both nodes on their path.data
t1="$(date +%s)"
pkg install -y opensearch219 > "$T/pkg-install.out" 2>&1; r=$?
cp "$T/pkg-install.out" "$res/pkg-install-opensearch219.out"
cfl="$(grep -i -m 1 'conflicts with' "$T/pkg-install.out" | sed 's/^[ -]*//' | cut -c1-160)"
if [ "$r" = 0 ] && inst opensearch219 && ! pkg info -e opensearch217; then
    pass "pkg install opensearch219: opensearch217 taken away (${cfl:-no conflict told}), opensearch219 $(pkg query '%v' opensearch219) of azbuild installed"
else
    fail "pkg install opensearch219: exit $r; opensearch219 from azbuild: $(inst opensearch219 && echo yes || echo "no ($(pkg query '%At %Av' opensearch219 2>/dev/null | tr '\n' ' '))"); opensearch217 still there: $(pkg info -e opensearch217 && echo yes || echo no); $(grep -v '^\[' "$T/pkg-install.out" | tail -n 3 | cut -c1-160 | tr '\n' ' ')"
    if ! inst opensearch219; then
        pkg install -y -f -r azbuild opensearch219 >> "$T/pkg-install.out" 2>&1
        inst opensearch219 || end
    fi
fi
cf=""
cmp -s "$E/opensearch.yml" "$T/opensearch.yml.ko44" || cf="$cf opensearch.yml is not that of ko44;"
for f in jvm.options log4j2.properties; do cmp -s "$E/$f" "$E/$f.sample" || cf="$cf $f is not the $f.sample of $v219;"; done
[ -s "$E/opensearch.keystore" ] || cf="$cf no opensearch.keystore;"
[ -d /var/db/opensearch/nodes ] || cf="$cf no /var/db/opensearch/nodes;"
[ -f "$E/opensearch-security-analytics/rules/rule_categories.json" ] || cf="$cf no prepackaged rules of opensearch-security-analytics in $E;"
if [ -z "$cf" ]; then
    pass "after pkg install: the opensearch.yml of ko44 kept, jvm.options and log4j2.properties those of $v219 (those of 2.17.1 were not changed), the keystore and /var/db/opensearch kept, the prepackaged rules of opensearch-security-analytics in $E"
else
    fail "after pkg install:$cf"
fi
# data1 first, as on aZ's cluster, where the data nodes are up when the cluster
# manager comes back: it waits for ko44 (its configuration of the new package, as a
# server with the package has it, the prepackaged rules of
# opensearch-security-analytics too); then ko44 by its rc script
mkconf "$D" "$E" || fail "$v219, data1: no configuration (the samples of opensearch219)"
j219="$(jhome "$P/etc/rc.d/opensearch")"
startnode "$D" "$P/lib/opensearch" "${j219:-$P/openjdk21}"; rd=$?
service opensearch start > "$T/start-2.19.out" 2>&1; r=$?
if [ "$r" != 0 ] || ! up "$ko" 240; then
    tail -n +"$((nl + 1))" /var/log/opensearch/ko44.log > "$T/ko44-2.19.log" 2>/dev/null
    fail "$v219, ko44 on the data of 2.17.1: service opensearch start: exit $r, $(tail -n 2 "$T/start-2.19.out" | cut -c1-200 | tr '\n' ' '); its log: $(lg "$T/ko44-2.19.log")"
    cp "$T/ko44-2.19.log" "$res/ko44-2.19.log" 2>/dev/null
    s1="the upgrade 2.17.1 -> $v219: FAIL, ko44 of $v219 did not start on its data of 2.17.1"
    end
fi
if [ "$rd" != 0 ] || ! up "$dn" 240; then
    tail -n +"$((nld + 1))" "$D/logs/ko44.log" > "$T/data1-2.19.log" 2>/dev/null
    fail "$v219, data1 on its data of 2.17.1: exit $rd, $(tail -n 2 "$D/start.out" | cut -c1-200 | tr '\n' ' '); its log: $(lg "$T/data1-2.19.log")"
    cp "$T/data1-2.19.log" "$res/data1-2.19.log" 2>/dev/null
    s1="the upgrade 2.17.1 -> $v219: FAIL, data1 of $v219 did not start on its data of 2.17.1"
    end
fi
a="$(get "$ko" /)"
v="$(printf '%s' "$a" | js number)"; cu2="$(printf '%s' "$a" | js cluster_uuid)"
cn="$(printf '%s' "$a" | js cluster_name)"; nn="$(printf '%s' "$a" | js name)"
vd="$(get "$dn" / | js number)"
jv2="$(get "$ko" '/_nodes/_local/jvm?filter_path=**.jvm.version' | js version)"
h2="$(curl -s -m 210 "$ko/_cluster/health?wait_for_nodes=2&wait_for_status=${h1:-green}&wait_for_no_initializing_shards=true&timeout=180s" 2>/dev/null | js status)"
# the lines the logs had when the cluster was back with its shards: what the
# plugins logged before, while their indices were still recovering, is a note
nlr="$(wc -l < /var/log/opensearch/ko44.log | tr -d ' ')"
nldr="$(wc -l < "$D/logs/ko44.log" | tr -d ' ')"
nd2="$(get "$ko" '/_cat/nodes?h=name,version,node.role,cluster_manager&s=name' | tr -s ' ' | sed 's/ $//' | tr '\n' ';')"
if [ "$v" = "$v219" ] && [ "$vd" = "$v219" ] && [ "$cu2" = "$cu" ] && [ "$cn" = ko44 ] && [ "$nn" = ko44 ] && [ "$nd2" = "data1 $v219 di -;ko44 $v219 m *;" ]; then
    pass "$v219 on the data of 2.17.1: ko44 by service opensearch start and data1 by hand, the same cluster ($cu2), ko44 its cluster manager alone: $nd2"
else
    fail "$v219 on the data of 2.17.1: version of ko44 ${v:-not told}, of data1 ${vd:-not told}; the cluster ${cu2:-not told} (it was $cu), cluster.name ${cn:-not told}, node ${nn:-not told}; the nodes: ${nd2:-no answer}"
fi
get "$ko" '/_cat/indices?h=index,health,status,pri,rep,docs.count&s=index&expand_wildcards=all' | tr -s ' ' | sed 's/ $//' | grep . > "$T/indices-2.19.txt"
cp "$T/indices-2.19.txt" "$res/indices-2.19.txt"
miss=""; dh=""; dd=""; dsys=""
while read -r ix hh st pr rp dc; do
    l2="$(awk -v i="$ix" '$1 == i { print; exit }' "$T/indices-2.19.txt")"
    if [ -z "$l2" ]; then miss="$miss $ix"; continue; fi
    # shellcheck disable=SC2086
    set -- $l2
    [ "$2" = "$hh" ] && [ "$3" = "$st" ] && [ "$4" = "$pr" ] && [ "$5" = "$rp" ] || dh="$dh $ix ($hh $st $pr $rp -> $2 $3 $4 $5)"
    case "$ix" in
        az-upgrade|az-upgrade-zstd) [ "${6:-}" = "$dc" ] || dd="$dd $ix ($dc -> ${6:-none})" ;;
        *) [ "${6:-}" = "$dc" ] || dsys="$dsys $ix ($dc -> ${6:-none})" ;;
    esac
done < "$T/indices-2.17.txt"
nw="$(awk 'NR == FNR { o[$1] = 1; next } !($1 in o) { printf "%s ", $1 }' "$T/indices-2.17.txt" "$T/indices-2.19.txt")"
if [ "$h2" = "$h1" ] && [ -z "$miss" ] && [ -z "$dh" ]; then
    pass "$v219: the health of the cluster $h2 as before, the $ni indices of 2.17.1 there with the health, state, shards and replicas they had (indices-2.19.txt); new:${nw:+ }${nw:-none}"
else
    fail "$v219: the health of the cluster ${h2:-not told} (it was $h1); missing:${miss:- none}; changed:${dh:- none}"
fi
[ -z "$dsys" ] || note "$v219: the documents of system indices changed:$dsys"
c1b="$(get "$ko" /az-upgrade/_count | jn count)"
c2b="$(get "$ko" /az-upgrade-zstd/_count | jn count)"
d1="$(get "$ko" /az-upgrade/_doc/ko44-1)"
f1="$(send "$ko" POST /az-upgrade/_search '{ "query": { "match": { "title": "azsupport" } } }' | jn value)"
f2="$(send "$ko" POST /az-upgrade-zstd/_search '{ "size": 0, "query": { "match": { "title": "zstd" } } }' | jn value)"
cz="$(get "$ko" '/az-upgrade-zstd/_settings?filter_path=**.codec' | js codec)"
if [ "$c1b" = 1001 ] && [ "$c2b" = 100 ] && [ -z "$dd" ] && printf '%s' "$d1" | grep -q '"found" *: *true' && printf '%s' "$d1" | grep -q 'before the upgrade' \
    && [ "$f1" = 1 ] && [ "$f2" = 100 ] && [ "$cz" = zstd ]; then
    pass "$v219: the documents of 2.17.1: az-upgrade 1001 (ko44-1 read by its id, found by a search), az-upgrade-zstd 100 (its codec zstd, searched)"
else
    fail "$v219: the documents of 2.17.1: az-upgrade ${c1b:-none} of 1001, az-upgrade-zstd ${c2b:-none} of 100 (codec ${cz:-not told}); ko44-1: $(printf '%s' "$d1" | cut -c1-120); searches: ${f1:-none} of 1, ${f2:-none} of 100"
fi
vc2="$(get "$ko" '/az-upgrade/_settings?filter_path=**.version.created' | js created)"
w="$(send "$ko" PUT '/az-upgrade/_doc/ko44-2?refresh=true' '{ "title": "opensearch of azsupport after the upgrade", "tag": "ko44", "n": 2197 }')"
c1c="$(get "$ko" /az-upgrade/_count | jn count)"
if [ -n "$vc1" ] && [ "$vc2" = "$vc1" ] && [ "$c1c" = 1002 ]; then
    pass "$v219: az-upgrade still an index of 2.17.1 (index.version.created $vc2), a document written into it (1002)"
else
    fail "$v219: az-upgrade: index.version.created ${vc2:-not told} (it was ${vc1:-not told}); the document written: $(printf '%s' "$w" | cut -c1-120), ${c1c:-no} documents"
fi
pg="$(get "$ko" /_plugins/_ism/policies/az-upgrade)"
ex="$(get "$ko" /_plugins/_ism/explain/az-upgrade)"
if printf '%s' "$pg" | grep -q '"_id" *: *"az-upgrade"' && printf '%s' "$ex" | grep -q '"policy_id" *: *"az-upgrade"' && printf '%s' "$ex" | grep -q '"total_managed_indices" *: *1'; then
    pass "$v219: the policy az-upgrade of 2.17.1 there, az-upgrade managed by it"
else
    fail "$v219: the policy of 2.17.1: $(printf '%s' "$pg" | cut -c1-120); its index: $(printf '%s' "$ex" | cut -c1-160)"
fi
ng="$(get "$ko" /_plugins/_notifications/configs/az-upgrade)"
if printf '%s' "$ng" | grep -q '"config_id" *: *"az-upgrade"'; then pass "$v219: the channel az-upgrade of 2.17.1 there"; else fail "$v219: the channel of 2.17.1: $(printf '%s' "$ng" | cut -c1-200)"; fi
q3="$(get "$ko" "/_plugins/_asynchronous_search/$aid")"
qs="$(printf '%s' "$q3" | js state)"; qv="$(printf '%s' "$q3" | jn value)"
if [ -n "$aid" ] && [ "$qv" = 1001 ]; then pass "$v219: the kept result of the search of 2.17.1 there ($qs: 1001 hits)"; else fail "$v219: the kept search of 2.17.1: ${qs:-no state}, ${qv:-no} hits ($(printf '%s' "$q3" | cut -c1-160))"; fi
mg="$(get "$ko" "/_plugins/_ml/connectors/${mcid:-none}")"
if [ -n "$mcid" ] && printf '%s' "$mg" | grep -q '"name" *: *"az-upgrade"'; then pass "$v219: the connector of 2.17.1 there ($mcid)"; else fail "$v219: the connector of 2.17.1: $(printf '%s' "$mg" | cut -c1-200)"; fi
# the settings of aZ's cluster: what the sources of 2.19 say (query-insights
# 2.19 has no exporter per metric, search.insights.top_queries.<metric>.exporter.*
# of 2.17.1.0, but one of all, search.insights.top_queries.exporter.*: those
# archived when ko44 loads the state of the cluster from its disk; the rest it
# knows; a transient setting does not outlive a restart of the whole cluster)
fate "$ko" > "$T/fate-2.19.txt"
cp "$T/fate-2.19.txt" "$res/settings-2.19.txt"
cat > "$T/fate-want.txt" << 'EOF'
cluster.routing.allocation.enable kept
plugins.index_state_management.metadata_migration.status kept
plugins.index_state_management.template_migration.control kept
search.insights.top_queries.cpu.enabled kept
search.insights.top_queries.latency.enabled kept
search.insights.top_queries.cpu.exporter.config.index archived
search.insights.top_queries.cpu.exporter.enabled archived
search.insights.top_queries.cpu.exporter.asd archived
search.insights.top_queries.latency.exporter.config.index archived
search.insights.top_queries.latency.exporter.enabled archived
search.insights.top_queries.group_by kept
search.insights.top_queries.max_groups_excluding_topn kept
search.query.metrics.enabled kept
transient gone
EOF
s3="aZ's settings of 2.17.1 on $v219: archived.* $(awk '$2 == "archived" { sub(/^search\.insights\.top_queries\./, "", $1); printf "%s%s", (n++ ? ", " : ""), $1 }' "$T/fate-2.19.txt" | sed 's/^$/none/'); missing $(awk '$2 == "missing" { printf "%s%s", (n++ ? ", " : ""), $1 }' "$T/fate-2.19.txt" | sed 's/^$/none/'); kept the other $(grep -c ' kept$' "$T/fate-2.19.txt"); the transient $(awk '$1 == "transient" { print $2 }' "$T/fate-2.19.txt"); the start not refused"
if cmp -s "$T/fate-2.19.txt" "$T/fate-want.txt"; then
    pass "$v219: the settings of aZ's cluster as the sources of 2.19 have them: 8 kept, the 5 exporters per metric of query-insights archived (archived.*), the transient one gone"
else
    fail "$v219: the settings of aZ's cluster, not as the sources have them: $(diff "$T/fate-want.txt" "$T/fate-2.19.txt" | sed -n 's/^> //p' | tr '\n' ';')"
fi
# a setting of the cluster changed while the archived are there, then the
# archived taken away, as aZ would after the upgrade
cu1="$(send "$ko" PUT /_cluster/settings '{ "persistent": { "cluster.routing.allocation.enable": "all" } }')"
cu3="$(send "$ko" PUT /_cluster/settings '{ "persistent": { "archived.*": null } }')"
na_="$(curl -s -m 30 "$ko/_cluster/settings?flat_settings=true" 2>/dev/null | grep -o '"archived\.[^"]*"' | wc -l | tr -d ' ')"
if printf '%s' "$cu1" | grep -q '"acknowledged" *: *true' && printf '%s' "$cu3" | grep -q '"acknowledged" *: *true' && [ "$na_" = 0 ]; then
    pass "$v219: a setting of the cluster changed with the archived there; the archived taken away (\"archived.*\": null)"
else
    fail "$v219: a setting changed: $(printf '%s' "$cu1" | cut -c1-160); the archived taken away: $(printf '%s' "$cu3" | cut -c1-160); archived left: $na_"
fi
lt2=""; i=0
while [ "$i" -lt 12 ]; do
    lt2="$(send "$ko" POST /_plugins/_security_analytics/logtype/_search '{ "size": 0, "query": { "match_all": {} } }' | jn value)"
    [ "${lt2:-0}" -gt 0 ] && break
    sleep 5; i=$((i + 1))
done
ra="$(curl -s -m 180 -H 'Content-Type: application/json' -X POST "$ko/_plugins/_security_analytics/rules/_search?pre_packaged=true" -d '{ "size": 0, "query": { "match_all": {} } }' 2>/dev/null)"
rn="$(printf '%s' "$ra" | sed -n 's/.*"total" *: *{ *"value" *: *\([0-9]*\).*/\1/p')"
if [ "${lt2:-0}" -gt 0 ] && [ "${rn:-0}" -gt 1000 ]; then
    pass "$v219: the log types of opensearch-security-analytics ($lt2; 2.17.1: $lt1), its prepackaged rules imported from opensearch-security-analytics/rules of the configuration ($rn)"
else
    fail "$v219: opensearch-security-analytics: log types ${lt2:-none} (2.17.1: $lt1); prepackaged rules ${rn:-none} ($(printf '%s' "$ra" | cut -c1-160))"
fi
pl="$(get "$ko" '/_cat/plugins?h=name,component' | tr -s ' ' | sed 's/ $//')"
pk_="$(printf '%s\n' "$pl" | awk '$1 == "ko44" { print $2 }' | LC_ALL=C sort | tr '\n' ' ')"
pd_="$(printf '%s\n' "$pl" | awk '$1 == "data1" { print $2 }' | LC_ALL=C sort | tr '\n' ' ')"
pw="$(ls "$P/lib/opensearch/plugins" | LC_ALL=C sort | tr '\n' ' ')"
if [ -n "$pk_" ] && [ "$pk_" = "$pw" ] && [ "$pd_" = "$pw" ]; then
    pass "$v219: _cat/plugins: the $(echo $pw | wc -w | tr -d ' ') plugins of opensearch219 loaded on ko44 and data1"
else
    fail "$v219: _cat/plugins: ko44 ${pk_:-none}; data1 ${pd_:-none}; installed: $pw"
fi
tail -n +"$((nl + 1))" /var/log/opensearch/ko44.log > "$T/ko44-2.19.log" 2>/dev/null
tail -n +"$((nld + 1))" "$D/logs/ko44.log" > "$T/data1-2.19.log" 2>/dev/null
cp "$T/ko44-2.19.log" "$res/ko44-2.19.log"
cp "$T/data1-2.19.log" "$res/data1-2.19.log"
cp /var/log/opensearch/ko44_deprecation.log "$res/ko44_deprecation.log" 2>/dev/null
# [ERROR] while the cluster recovered (before its health above): a note; after
# it: a failure
head -n "$((nlr - nl))" "$T/ko44-2.19.log" > "$T/ko44-2.19-recovery.log"
tail -n +"$((nlr - nl + 1))" "$T/ko44-2.19.log" > "$T/ko44-2.19-after.log"
head -n "$((nldr - nld))" "$T/data1-2.19.log" > "$T/data1-2.19-recovery.log"
tail -n +"$((nldr - nld + 1))" "$T/data1-2.19.log" > "$T/data1-2.19-after.log"
r1="$(errs "$T/ko44-2.19-recovery.log")"; r2="$(errs "$T/data1-2.19-recovery.log")"
[ -z "$r1$r2" ] || note "$v219: [ERROR] while the cluster recovered, in the log of ko44 ($(nerrs "$T/ko44-2.19-recovery.log")): ${r1:-none}; of data1 ($(nerrs "$T/data1-2.19-recovery.log")): ${r2:-none}"
e1="$(errs "$T/ko44-2.19-after.log")"; e2="$(errs "$T/data1-2.19-after.log")"
if [ -z "$e1$e2" ]; then
    pass "$v219: the logs of ko44 and data1 without [ERROR] once the cluster was back with its shards (ko44-2.19.log, data1-2.19.log)"
else
    fail "$v219: [ERROR] in the log of ko44 ($(nerrs "$T/ko44-2.19-after.log")): ${e1:-none}; of data1 ($(nerrs "$T/data1-2.19-after.log")): ${e2:-none}"
fi
w_="$(grep -c '\]\[WARN \]' "$T/ko44-2.19.log")"
[ "${w_:-0}" = 0 ] || note "$v219: the log of ko44 has $w_ warnings: $(grep '\]\[WARN \]' "$T/ko44-2.19.log" | head -n 4 | sed -e 's/^[^]]*\]//' | cut -c1-200 | tr '\n' ' ')"
stopnode "$D"; rd=$?
service opensearch stop > "$T/stop-2.19.out" 2>&1; r=$?
sleep 2
if [ "$r" = 0 ] && [ "$rd" = 0 ] && ! curl -s -m 5 "$ko/" > /dev/null 2>&1 && ! osproc; then
    pass "$v219: data1 stopped, then ko44 by service opensearch stop"
else
    fail "$v219: stopped: data1 $rd (0: stopped), ko44 by service opensearch stop: exit $r, $(tail -n 1 "$T/stop-2.19.out")"
fi
t2="$(date +%s)"
b2="$bad"
if [ "$b2" = "$b1" ]; then
    s1="the upgrade 2.17.1 -> $v219 of ko44 (the cluster manager alone, /var/db/opensearch) and data1: OK ($((t2 - t1)) s: the cluster $cu, $ni indices with their health ($h2), the documents, the objects of the plugins; index.version.created $vc2; JDK ${jv1:-?} -> ${jv2:-?})"
else
    s1="the upgrade 2.17.1 -> $v219 of ko44 and data1: $((b2 - b1)) checks failed"
fi
# the configuration of the package again, the data of the test away
cp -p "$E/opensearch.yml.sample" "$E/opensearch.yml"
rm -rf /var/db/opensearch "$D"

# 3. a cluster of 2.17.1 and the new version on this host: the node of 2.17.1
# from the package of the repository, unpacked here
avail="$(df -k "$T" | awk 'NR == 2 { print $4 }')"
if [ "${avail:-0}" -lt 4194304 ]; then
    fail "the cluster of 2.17.1 and $v219: not tried, $((${avail:-0} / 1024)) MB free in $T (4 GB wanted, opensearch217 unpacked)"
    s2="the cluster of 2.17.1 and $v219: not tried ($((${avail:-0} / 1024)) MB free)"
    end
fi
mkdir -p "$T/pkg" "$T/os217"
pkg fetch -y -r azbuild -o "$T/pkg" opensearch217 > "$T/pkg-fetch.out" 2>&1
pf="$(find "$T/pkg" -name 'opensearch217-*.pkg' | head -n 1)"
H217="$T/os217$P/lib/opensearch"
if [ -z "$pf" ] || ! tar -xf "$pf" -C "$T/os217" 2> "$T/tar.err" || [ ! -x "$H217/bin/opensearch" ]; then
    fail "the cluster of 2.17.1 and $v219: opensearch217 of azbuild not fetched or unpacked: $(tail -n 1 "$T/pkg-fetch.out") $(head -n 1 "$T/tar.err" 2>/dev/null)"
    s2="the cluster of 2.17.1 and $v219: not tried (opensearch217 not unpacked)"
    end
fi
rm -rf "$T/pkg"
ja="$(jhome "$T/os217$P/etc/rc.d/opensearch")"
jb="$(jhome "$P/etc/rc.d/opensearch")"
mk=""
mkconf "$T/a217" "$T/os217$P/etc/opensearch" || mk="$mk 2.17.1"
mkconf "$T/b219" "$E" || mk="$mk $v219"
cat > "$T/a217/conf/opensearch.yml" << EOF
cluster.name: az-mixed
node.name: a217
node.roles: [ cluster_manager, data, ingest ]
path.data: $T/a217/data
path.logs: $T/a217/logs
network.host: 127.0.0.1
http.port: 19211
transport.port: 19311
discovery.seed_hosts: ["127.0.0.1:19311"]
cluster.initial_cluster_manager_nodes: ["a217"]
EOF
cat > "$T/b219/conf/opensearch.yml" << EOF
cluster.name: az-mixed
node.name: b219
node.roles: [ data, ingest ]
path.data: $T/b219/data
path.logs: $T/b219/logs
network.host: 127.0.0.1
http.port: 19212
transport.port: 19312
discovery.seed_hosts: ["127.0.0.1:19311"]
EOF
chown opensearch:opensearch "$T/a217/conf/opensearch.yml" "$T/b219/conf/opensearch.yml"
if [ -n "$mk" ]; then
    fail "the cluster of 2.17.1 and $v219: no configuration of$mk (the samples of its package)"
    s2="the cluster of 2.17.1 and $v219: not tried (no configuration)"
    end
fi
startnode "$T/a217" "$H217" "${ja:-$P/openjdk21}"; r=$?
if [ "$r" != 0 ] || ! up "$na" 180; then
    fail "the node of 2.17.1 (a217): exit $r, $(tail -n 2 "$T/a217/start.out" | cut -c1-200 | tr '\n' ' '); its log: $(lg "$T/a217/logs/az-mixed.log")"
    cp "$T/a217/logs/az-mixed.log" "$res/a217.log" 2>/dev/null
    s2="the cluster of 2.17.1 and $v219: FAIL, the node of 2.17.1 did not start"
    end
fi
va="$(get "$na" / | js number)"
# an index with one replica while the node of 2.17.1 is alone: its primary there
send "$na" PUT /az-mixed '{ "settings": { "number_of_shards": 1, "number_of_replicas": 1 } }' > "$T/m1.out"
awk 'BEGIN { for (i = 1; i <= 200; i++) printf "{\"index\":{\"_id\":\"%d\"}}\n{\"title\":\"mixed document %d\",\"n\":%d}\n", i, i, i }' > "$T/bulk3.ndjson"
bulk "$na" '/az-mixed/_bulk?refresh=true' "$T/bulk3.ndjson" > "$T/bulk3.out"
# the persistent settings of aZ's cluster, those the new version does not know
# among them
cm_="$(curl -s -m 30 -H 'Content-Type: application/json' -X PUT "$na/_cluster/settings" --data-binary @"$T/ko44-persistent.json" 2>/dev/null)"
startnode "$T/b219" "$P/lib/opensearch" "${jb:-$P/openjdk21}"; r=$?
if [ "$r" != 0 ] || ! up "$nb" 180; then
    fail "the node of $v219 (b219): exit $r, $(tail -n 2 "$T/b219/start.out" | cut -c1-200 | tr '\n' ' '); its log: $(lg "$T/b219/logs/az-mixed.log")"
    cp "$T/a217/logs/az-mixed.log" "$res/a217.log" 2>/dev/null; cp "$T/b219/logs/az-mixed.log" "$res/b219.log" 2>/dev/null
    s2="the cluster of 2.17.1 and $v219: FAIL, the node of $v219 did not start"
    end
fi
hm="$(get "$na" '/_cluster/health?wait_for_nodes=2&wait_for_status=green&timeout=120s' | js status)"
nd="$(get "$na" '/_cat/nodes?h=name,version,node.role,cluster_manager&s=name' | tr -s ' ' | sed 's/ $//' | tr '\n' ';')"
sh_="$(get "$na" '/_cat/shards/az-mixed?h=prirep,state,node&s=prirep' | tr -s ' ' | sed 's/ $//' | tr '\n' ';')"
cua="$(get "$na" / | js cluster_uuid)"; cub="$(get "$nb" / | js cluster_uuid)"
if [ "$hm" = green ] && [ -n "$cua" ] && [ "$cub" = "$cua" ] && [ "$(printf '%s' "$nd" | tr ';' '\n' | awk '{ print $1, $2 }' | tr '\n' ';')" = "a217 $va;b219 $v219;" ]; then
    pass "the cluster of two versions: b219 ($v219, data, on $jb) joined a217 ($va, cluster manager, on $ja) with the persistent settings of aZ's cluster ($(printf '%s' "$cm_" | grep -q '"acknowledged" *: *true' && echo taken || echo "not taken: $(printf '%s' "$cm_" | cut -c1-80)")): $nd green"
else
    fail "the cluster of two versions: health ${hm:-not told}; the nodes: ${nd:-no answer}; the clusters: ${cua:-none} and ${cub:-none}; the log of b219: $(lg "$T/b219/logs/az-mixed.log")"
fi
if [ "$sh_" = "p STARTED a217;r STARTED b219;" ]; then
    pass "the cluster of two versions: az-mixed, its primary on 2.17.1 and its replica on $v219: $sh_"
else
    fail "the cluster of two versions: the shards of az-mixed: ${sh_:-no answer} (want its primary on a217, its replica on b219)"
fi
w="$(send "$nb" PUT '/az-mixed/_doc/b219?refresh=true' '{ "title": "mixed document written through 2.19", "n": 219 }')"
ca="$(get "$na" /az-mixed/_count | jn count)"
cb="$(get "$nb" '/az-mixed/_count?preference=_only_local' | jn count)"
fb="$(send "$nb" POST /az-mixed/_search '{ "size": 0, "query": { "match": { "title": "mixed" } } }' | jn value)"
if [ "$ca" = 201 ] && [ "$cb" = 201 ] && [ "$fb" = 201 ]; then
    pass "the cluster of two versions: a document written through b219 ($v219): 201 documents counted through a217, on the replica of b219, and found through b219"
else
    fail "the cluster of two versions: written through b219: $(printf '%s' "$w" | cut -c1-120); counted through a217: ${ca:-none}, on b219: ${cb:-none}, found through b219: ${fb:-none} (of 201)"
fi
ea="$(errs "$T/a217/logs/az-mixed.log")"; eb="$(errs "$T/b219/logs/az-mixed.log")"
if [ -z "$ea$eb" ]; then pass "the cluster of two versions: the logs of a217 and b219 without [ERROR]"; else fail "the cluster of two versions: [ERROR] in the log of a217: ${ea:-none}; of b219: ${eb:-none}"; fi
stopnode "$T/b219"; rb=$?
stopnode "$T/a217"; ra_=$?
if [ "$rb" = 0 ] && [ "$ra_" = 0 ] && ! osproc; then pass "the cluster of two versions: both nodes stopped"; else fail "the cluster of two versions: stopped b219 $rb, a217 $ra_ (0: stopped)"; fi
cp "$T/a217/logs/az-mixed.log" "$res/a217.log" 2>/dev/null
cp "$T/b219/logs/az-mixed.log" "$res/b219.log" 2>/dev/null
t3="$(date +%s)"
if [ "$bad" = "$b2" ]; then
    s2="the cluster of 2.17.1 and $v219: OK ($((t3 - t2)) s: $nd $sh_ JDK $ja and $jb)"
else
    s2="the cluster of 2.17.1 and $v219: $((bad - b2)) checks failed"
fi
note "the times: 2.17.1 and its data $((t1 - t0)) s, the upgrade $((t2 - t1)) s, the cluster of two versions $((t3 - t2)) s"
end
