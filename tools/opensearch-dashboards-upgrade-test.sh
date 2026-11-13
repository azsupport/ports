#!/bin/sh
# opensearch-dashboards-upgrade-test.sh - the way aZ takes his OpenSearch Dashboards
# of 2.17.1 to 2.19.7 (aZ, 12.11.2026: his cluster of 2.17.1 moves to 2.19, and
# Dashboards with it), with the packages of the repository az, on the saved objects
# that Dashboards 2.17.1 keeps in OpenSearch:
#   1. OpenSearch 2.17.1 (the package opensearch217 of the repository, pkg fetch,
#      unpacked into the directory of this test: opensearch219 is installed by
#      then) started by hand as opensearch, one node on 127.0.0.1:8200 (the port of
#      aZ's ko44) with the data directory of this test, on the JDK of its rc
#      script; Dashboards 2.17.1 (opensearch-dashboards217, installed) by service
#      opensearch-dashboards start (opensearch_dashboards_enable in
#      /etc/rc.conf.d/opensearch_dashboards) with the configuration of aZ's ko44 in
#      /usr/local/etc/opensearch-dashboards (its opensearch_dashboards.yml, a
#      node.options): saved objects made through it as a user makes them (an
#      index pattern with the fields of its index, a visualization, a dashboard
#      with it, a saved search, a saved query) and a setting of Advanced Settings
#      (dateFormat:tz), their index behind the alias .kibana noted; Dashboards
#      stopped, then OpenSearch;
#   2. OpenSearch 2.19.7 of the installed opensearch219 on the same data, by hand
#      as in 1., as aZ's nodes will be before he upgrades Dashboards (Dashboards
#      2.19 is for OpenSearch 2.19 alone);
#   3. pkg install opensearch-dashboards219, as aZ will: pkg takes
#      opensearch-dashboards217 away (the same files); his opensearch_dashboards.yml
#      and node.options stay; service opensearch-dashboards start: green, its
#      version; the saved objects migrated (the alias .kibana and the index behind
#      it, the index of 2.17.1), each object read back with its title, the dashboard
#      exported with its references, found by a search, the setting of Advanced
#      Settings in the configuration of 2.19.7, the saved search made into a CSV
#      by reporting, the saved query read, a new object made; no error in the log
#      of Dashboards since its start; Dashboards stopped, then OpenSearch.
# After it the configuration files of the package are its samples again, and
# /etc/rc.conf.d/opensearch_dashboards and /var/log/opensearch_dashboards.log are as
# they were; opensearch-dashboards219 stays installed (tools/test-programs.sh
# tests it next).
#
# Usage (FreeBSD, as root, opensearch-dashboards217 and opensearch219 installed
# from the repository azbuild of tools/test-programs.sh, which has opensearch217
# and opensearch-dashboards219):
#   sh tools/opensearch-dashboards-upgrade-test.sh
# Results: opensearch-dashboards-upgrade-results/tests.txt (one line per check, the
# summary at the end), the logs next to it; exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/opensearch-dashboards-upgrade-results}"
T="${OSD_TEST_WORK:-/var/tmp/opensearch-dashboards-upgrade-test}"
P=/usr/local
D="$P/www/opensearch-dashboards"
E="$P/etc/opensearch-dashboards"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T/a"
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
os="http://127.0.0.1:8200"
k="http://127.0.0.1:5601"
node="$P/bin/node"
log=/var/log/opensearch_dashboards.log
rcd=/etc/rc.conf.d/opensearch_dashboards
s1="the upgrade of Dashboards 2.17.1 -> 2.19.7: not tried"
end() {
    echo "opensearch-dashboards-upgrade-test: $ok ok, $bad failed" >> "$out"
    echo "$s1" >> "$sum"
    echo "$s1"
    echo "opensearch-dashboards-upgrade-test: $ok ok, $bad failed (opensearch-dashboards-upgrade-results/tests.txt)"
    [ "$bad" = 0 ] && exit 0
    exit 1
}
# rq <name> <method> <path> [<data or @file>]: a request to Dashboards with a time
# limit; the answer in $T/a/<name>, its status the output
rq() {
    if [ $# -ge 4 ] && [ -n "$4" ]; then
        curl -s -m 60 -o "$T/a/$1" -w '%{http_code}' -H 'osd-xsrf: osd-test' -H 'Content-Type: application/json' -X "$2" "$k$3" --data-binary "$4" 2>/dev/null
    else
        curl -s -m 60 -o "$T/a/$1" -w '%{http_code}' -H 'osd-xsrf: osd-test' -X "$2" "$k$3" 2>/dev/null
    fi
}
has() { grep -q -F -- "$2" "$T/a/$1" 2>/dev/null; }
ans() { head -c 200 "$T/a/$1" 2>/dev/null | tr '\n' ' '; }
# want <what> <name> <status> <text> <method> <path> [<data>]
want() {
    _w="$1"; _n="$2"; _s="$3"; _t="$4"; shift 4
    _c="$(rq "$_n" "$@")"
    if [ "$_c" = "$_s" ] && has "$_n" "$_t"; then pass "$_w"; else fail "$_w: $_c $(ans "$_n")"; fi
}
# green <seconds>: wait for /api/status green; its answer in $T/a/status
state() { sed -n 's/.*"overall":{[^}]*"state":"\([a-z]*\)".*/\1/p' "$T/a/status" 2>/dev/null; }
green() {
    _i=0
    while [ "$_i" -lt "$1" ]; do
        rq status GET /api/status > /dev/null
        [ "$(state)" = green ] && return 0
        sleep 2; _i=$((_i + 2))
    done
    return 1
}
running() { pgrep -f "$D/src/cli/dist serve" > /dev/null 2>&1; }
# the nodes of OpenSearch, by hand: stopnode <directory>
stopnode() {
    _p="$(cat "$1/pid" 2>/dev/null)"
    [ -n "$_p" ] || return 1
    kill "$_p" 2>/dev/null
    _i=0
    while kill -0 "$_p" 2>/dev/null && [ "$_i" -lt 90 ]; do sleep 1; _i=$((_i + 1)); done
    rm -f "$1/pid"
    ! kill -0 "$_p" 2>/dev/null
}
# mkconf <directory> <the ETCDIR of its package>: its configuration (the samples of
# the package, the prepackaged rules of opensearch-security-analytics when the
# package has them), of opensearch, and the opensearch.yml of this test
mkconf() {
    rm -rf "$1/conf"; mkdir -p "$1/conf" "$T/osdata" "$T/oslogs" "$1/tmp"
    for f in jvm.options log4j2.properties opensearch-notifications-core/notifications-core.yml opensearch-notifications/notifications.yml \
        opensearch-observability/observability.yml opensearch-reports-scheduler/reports-scheduler.yml; do
        case "$f" in */*) mkdir -p "$1/conf/${f%/*}" ;; esac
        cp "$2/$f.sample" "$1/conf/$f" || return 1
    done
    if [ -d "$2/opensearch-security-analytics" ]; then cp -Rp "$2/opensearch-security-analytics" "$1/conf/"; fi
    printf '%s\n' 'cluster.name: az-osd-upgrade' 'node.name: osd-upgrade' "path.data: $T/osdata" "path.logs: $T/oslogs" \
        'network.host: 127.0.0.1' 'http.port: 8200' 'transport.port: 8300' 'discovery.type: single-node' > "$1/conf/opensearch.yml"
    chown -R opensearch:opensearch "$1" "$T/osdata" "$T/oslogs"
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
up() { _i=0; while [ "$_i" -lt "$1" ]; do curl -s -m 5 "$os/" 2>/dev/null | grep -q '"number"' && return 0; sleep 2; _i=$((_i + 2)); done; return 1; }
osv() { curl -s -m 10 "$os/" 2>/dev/null | sed -n 's/.*"number" : "\([^"]*\)".*/\1/p'; }
# at the end: the configuration of the installed package its samples, rc.conf.d and
# the log of Dashboards as they were
[ -f "$rcd" ] && cp -p "$rcd" "$T/rc.conf.d.before"
hadlog=""; [ -e "$log" ] && hadlog=1
cleanup() {
    service opensearch-dashboards onestop > /dev/null 2>&1
    for d in "$T/b219" "$T/a217"; do [ -s "$d/pid" ] && stopnode "$d"; done
    if [ -f "$T/rc.conf.d.before" ]; then cp -p "$T/rc.conf.d.before" "$rcd"; else rm -f "$rcd"; fi
    for f in opensearch_dashboards.yml node.options; do [ -f "$E/$f.sample" ] && cp -p "$E/$f.sample" "$E/$f"; done
    [ -n "$hadlog" ] || rm -f "$log"
    rm -rf "$T/os217" "$T/pkg" "$T/osdata"
}
trap cleanup EXIT
trap 'exit 1' INT TERM

for p in opensearch-dashboards217 opensearch219; do
    inst "$p" || { fail "$p is not installed from the repository azbuild"; end; }
done
for p in opensearch217 opensearch-dashboards219; do
    [ "$(pkg rquery -r azbuild '%n' "$p" 2>/dev/null)" = "$p" ] || { fail "the repository azbuild has no $p"; end; }
done
v217="$(pkgv opensearch-dashboards217)"
v219="$(pkg rquery -r azbuild '%v' opensearch-dashboards219 2>/dev/null | sed 's/[_,].*//')"
service opensearch-dashboards onestop > /dev/null 2>&1

# 1. OpenSearch 2.17.1 of the repository, unpacked; Dashboards 2.17.1 with ko44's
# configuration by service opensearch-dashboards start
avail="$(df -k "$T" | awk 'NR == 2 { print $4 }')"
if [ "${avail:-0}" -lt 4194304 ]; then
    fail "not tried: $((${avail:-0} / 1024)) MB free in $T (4 GB wanted, opensearch217 unpacked)"
    end
fi
mkdir -p "$T/pkg" "$T/os217"
pkg fetch -y -r azbuild -o "$T/pkg" opensearch217 > "$T/pkg-fetch.out" 2>&1
pf="$(find "$T/pkg" -name 'opensearch217-*.pkg' | head -n 1)"
H217="$T/os217$P/lib/opensearch"
if [ -z "$pf" ] || ! tar -xf "$pf" -C "$T/os217" 2> "$T/tar.err" || [ ! -x "$H217/bin/opensearch" ]; then
    fail "opensearch217 of azbuild not fetched or unpacked: $(tail -n 1 "$T/pkg-fetch.out") $(head -n 1 "$T/tar.err" 2>/dev/null)"
    end
fi
rm -rf "$T/pkg"
ja="$(jhome "$T/os217$P/etc/rc.d/opensearch")"
mkconf "$T/a217" "$T/os217$P/etc/opensearch" || { fail "no configuration of OpenSearch 2.17.1 (the samples of opensearch217)"; end; }
startnode "$T/a217" "$H217" "${ja:-$P/openjdk21}"; r=$?
if [ "$r" != 0 ] || ! up 180; then
    fail "OpenSearch 2.17.1: exit $r, $(tail -n 2 "$T/a217/start.out" | cut -c1-200 | tr '\n' ' '); its log: $(tail -n 2 "$T/oslogs/az-osd-upgrade.log" 2>/dev/null | cut -c1-200 | tr '\n' ' ')"
    cp "$T/oslogs/az-osd-upgrade.log" "$res/opensearch-2.17.log" 2>/dev/null
    end
fi
va="$(osv)"
curl -s -m 60 -o /dev/null "$os/_cluster/health?wait_for_status=yellow&timeout=60s"
curl -s -m 30 -o /dev/null -H 'Content-Type: application/json' -X PUT "$os/az-up" -d '{"settings":{"number_of_shards":1,"number_of_replicas":0}}'
for i in 1 2 3; do
    curl -s -m 30 -o /dev/null -H 'Content-Type: application/json' -X POST "$os/az-up/_doc?refresh=true" \
        -d "{\"t\":\"2026-11-12T1$i:00:00Z\",\"title\":\"doc $i of the upgrade\",\"n\":$i}"
done
mkdir -p "${rcd%/*}"
printf '%s\n' 'opensearch_dashboards_enable="YES"' > "$rcd"
cp "$E/opensearch_dashboards.yml.sample" "$E/opensearch_dashboards.yml" || fail "no $E/opensearch_dashboards.yml.sample"
printf '%s\n' 'server.host: "127.0.0.1"' 'opensearch.hosts: ["http://localhost:8200"]' '#opensearch.hosts: ["http://localhost:9200"]' \
    'opensearch.ssl.verificationMode: none' '#opensearch.username: "kibanaserver"' '#opensearch.password: "kibanaserver"' \
    '#opensearch.requestHeadersWhitelist: [ authorization,securitytenant ]' '#opensearch_security.multitenancy.enabled: true' \
    '#opensearch_security.multitenancy.tenants.preferred: ["Private", "Global"]' '#opensearch_security.readonly_mode.roles: ["kibana_read_only"]' \
    '#opensearch_security.cookie.secure: false' >> "$E/opensearch_dashboards.yml"
cp "$E/node.options.sample" "$E/node.options" && echo '--max-old-space-size=700' >> "$E/node.options"
cp -p "$E/opensearch_dashboards.yml" "$T/yml.ko44"
cp -p "$E/node.options" "$T/options.ko44"
rm -f "$log"
(cd / && service opensearch-dashboards start > "$T/start-2.17.out" 2>&1); r=$?
if [ "$r" != 0 ] || ! green 300; then
    fail "Dashboards $v217: service opensearch-dashboards start: exit $r, $(tail -n 2 "$T/start-2.17.out" | tr '\n' ' '), /api/status $(state): $(grep '"error"' "$log" 2>/dev/null | tail -n 2 | cut -c1-300 | tr '\n' ' ')"
    cp "$log" "$res/osd-2.17.log" 2>/dev/null
    end
fi
x="$(sed -n 's/.*"version":{"number":"\([^"]*\)".*/\1/p' "$T/a/status")"
pass "Dashboards $x by service opensearch-dashboards start with the configuration of ko44 in $E, against OpenSearch $va (2.17.1 of the repository, unpacked)"
# the saved objects, as the pages make them
SS='{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}'
c="$(rq fields GET '/api/index_patterns/_fields_for_wildcard?pattern=az-up*&meta_fields=_source&meta_fields=_id&meta_fields=_type&meta_fields=_index&meta_fields=_score')"
if [ "$c" = 200 ] && "$node" -e 'const fs = require("fs"); const f = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).fields;
    if (!f.some((x) => x.name === "t" && x.type === "date")) process.exit(1);
    fs.writeFileSync(process.argv[2], JSON.stringify({ attributes: { title: "az-up*", timeFieldName: "t", fields: JSON.stringify(f) } }));' "$T/a/fields" "$T/ip.json"; then
    :
else
    fail "2.17.1: the fields of az-up*: $c $(ans fields)"
    printf '%s' '{"attributes":{"title":"az-up*","timeFieldName":"t"}}' > "$T/ip.json"
fi
m=""
c="$(rq ip POST /api/saved_objects/index-pattern/az-up-ip "@$T/ip.json")"; [ "$c" = 200 ] || m="$m index-pattern:$c"
c="$(rq vis POST /api/saved_objects/visualization/az-up-vis \
    "{\"attributes\":{\"title\":\"az up vis\",\"visState\":\"{\\\"title\\\":\\\"az up vis\\\",\\\"type\\\":\\\"metric\\\",\\\"aggs\\\":[{\\\"id\\\":\\\"1\\\",\\\"enabled\\\":true,\\\"type\\\":\\\"count\\\",\\\"params\\\":{},\\\"schema\\\":\\\"metric\\\"}],\\\"params\\\":{}}\",\"uiStateJSON\":\"{}\",\"description\":\"\",\"version\":1,\"kibanaSavedObjectMeta\":{\"searchSourceJSON\":\"$SS\"}},\"references\":[{\"name\":\"kibanaSavedObjectMeta.searchSourceJSON.index\",\"type\":\"index-pattern\",\"id\":\"az-up-ip\"}]}")"; [ "$c" = 200 ] || m="$m visualization:$c"
c="$(rq dash POST /api/saved_objects/dashboard/az-up-dash \
    '{"attributes":{"title":"az up dashboard","hits":0,"description":"","panelsJSON":"[{\"embeddableConfig\":{},\"gridData\":{\"h\":15,\"i\":\"1\",\"w\":24,\"x\":0,\"y\":0},\"panelIndex\":\"1\",\"version\":\"2.17.1\",\"panelRefName\":\"panel_0\"}]","optionsJSON":"{\"hidePanelTitles\":false,\"useMargins\":true}","version":1,"timeRestore":false,"kibanaSavedObjectMeta":{"searchSourceJSON":"{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"}},"references":[{"name":"panel_0","type":"visualization","id":"az-up-vis"}]}')"; [ "$c" = 200 ] || m="$m dashboard:$c"
c="$(rq search POST /api/saved_objects/search/az-up-search \
    "{\"attributes\":{\"title\":\"az up search\",\"columns\":[\"title\",\"n\"],\"sort\":[[\"t\",\"desc\"]],\"kibanaSavedObjectMeta\":{\"searchSourceJSON\":\"$SS\"}},\"references\":[{\"name\":\"kibanaSavedObjectMeta.searchSourceJSON.index\",\"type\":\"index-pattern\",\"id\":\"az-up-ip\"}]}")"; [ "$c" = 200 ] || m="$m search:$c"
c="$(rq query POST /api/saved_objects/query/az-up-query '{"attributes":{"title":"az up query","description":"azsupport","query":{"query":"n:1","language":"kuery"}}}')"; [ "$c" = 200 ] || m="$m query:$c"
c="$(rq settings POST /api/opensearch-dashboards/settings '{"changes":{"dateFormat:tz":"UTC"}}')"; [ "$c" = 200 ] && has settings '"dateFormat:tz":{"userValue":"UTC"}' || m="$m settings:$c"
cfg="$(curl -s -m 30 "$os/.kibana/_search?q=type:config&size=5" | grep -o '"_id":"config:[^"]*"' | tr '\n' ' ')"
ix1="$(curl -s -m 30 "$os/_cat/aliases/.kibana?h=index" | tr -d ' \n')"
n1="$(curl -s -m 30 "$os/.kibana/_count" | sed -n 's/.*"count":\([0-9]*\).*/\1/p')"
if [ -z "$m" ] && [ -n "$ix1" ]; then
    pass "2.17.1: an index pattern, a visualization, a dashboard, a saved search, a saved query and dateFormat:tz UTC made through Dashboards: the alias .kibana on $ix1 ($n1 documents; ${cfg:-no config})"
else
    fail "2.17.1: the saved objects:$m; the alias .kibana: ${ix1:-none}"
fi
(cd / && service opensearch-dashboards stop > "$T/stop-2.17.out" 2>&1); r=$?
sleep 2
if [ "$r" = 0 ] && ! running; then pass "2.17.1: service opensearch-dashboards stop"; else fail "2.17.1: service opensearch-dashboards stop: exit $r, $(tail -n 1 "$T/stop-2.17.out")"; fi
cp "$log" "$res/osd-2.17.log" 2>/dev/null
nl="$(wc -l < "$log" 2>/dev/null | tr -d ' ')"
stopnode "$T/a217" || fail "OpenSearch 2.17.1 not stopped"
cp "$T/oslogs/az-osd-upgrade.log" "$res/opensearch-2.17.log" 2>/dev/null

# 2. OpenSearch 2.19.7 of opensearch219 on the same data
jb="$(jhome "$P/etc/rc.d/opensearch")"
mkconf "$T/b219" "$P/etc/opensearch" || { fail "no configuration of OpenSearch 2.19.7 (the samples of opensearch219)"; end; }
startnode "$T/b219" "$P/lib/opensearch" "${jb:-$P/openjdk21}"; r=$?
if [ "$r" != 0 ] || ! up 240; then
    fail "OpenSearch 2.19.7 on the data of 2.17.1: exit $r, $(tail -n 2 "$T/b219/start.out" | cut -c1-200 | tr '\n' ' ')"
    cp "$T/oslogs/az-osd-upgrade.log" "$res/opensearch-2.19.log" 2>/dev/null
    end
fi
vb="$(osv)"
h="$(curl -s -m 90 "$os/_cluster/health?wait_for_status=green&timeout=60s" | sed -n 's/.*"status":"\([a-z]*\)".*/\1/p')"
n2="$(curl -s -m 30 "$os/.kibana/_count" | sed -n 's/.*"count":\([0-9]*\).*/\1/p')"
if [ "$vb" = "$(pkgv opensearch219)" ] && [ "$n2" = "$n1" ]; then
    pass "OpenSearch $vb (opensearch219) on the data of 2.17.1: health ${h:-not told}, the $n2 documents of .kibana there"
else
    fail "OpenSearch on the data of 2.17.1: version ${vb:-not told}, health ${h:-not told}, .kibana ${n2:-no} documents (it had $n1)"
fi

# 3. pkg install opensearch-dashboards219, as aZ will; then service opensearch-dashboards start
t1="$(date +%s)"
pkg install -y opensearch-dashboards219 > "$T/pkg-install.out" 2>&1; r=$?
cp "$T/pkg-install.out" "$res/pkg-install-opensearch-dashboards219.out"
if [ "$r" = 0 ] && inst opensearch-dashboards219 && ! pkg info -e opensearch-dashboards217; then
    pass "pkg install opensearch-dashboards219: opensearch-dashboards217 taken away, opensearch-dashboards219 $(pkg query '%v' opensearch-dashboards219) of azbuild installed"
else
    fail "pkg install opensearch-dashboards219: exit $r; from azbuild: $(inst opensearch-dashboards219 && echo yes || echo no); opensearch-dashboards217 still there: $(pkg info -e opensearch-dashboards217 && echo yes || echo no); $(grep -v '^\[' "$T/pkg-install.out" | tail -n 3 | cut -c1-160 | tr '\n' ' ')"
    if ! inst opensearch-dashboards219; then
        pkg install -y -f -r azbuild opensearch-dashboards219 >> "$T/pkg-install.out" 2>&1
        inst opensearch-dashboards219 || end
    fi
fi
cf=""
cmp -s "$E/opensearch_dashboards.yml" "$T/yml.ko44" || cf="$cf opensearch_dashboards.yml is not that of ko44;"
cmp -s "$E/node.options" "$T/options.ko44" || cf="$cf node.options is not that of ko44;"
[ -f "$rcd" ] || cf="$cf no $rcd;"
if [ -z "$cf" ]; then pass "after pkg install: the opensearch_dashboards.yml and node.options of ko44 kept, $rcd kept"; else fail "after pkg install:$cf"; fi
(cd / && service opensearch-dashboards start > "$T/start-2.19.out" 2>&1); r=$?
if [ "$r" != 0 ] || ! green 300; then
    fail "Dashboards $v219 on the saved objects of 2.17.1: service opensearch-dashboards start: exit $r, $(tail -n 2 "$T/start-2.19.out" | tr '\n' ' '), /api/status $(state): $(tail -n +"$((${nl:-0} + 1))" "$log" 2>/dev/null | grep '"error"' | tail -n 2 | cut -c1-300 | tr '\n' ' ')"
    cp "$log" "$res/osd.log" 2>/dev/null
    s1="the upgrade of Dashboards 2.17.1 -> $v219: FAIL, 2.19.7 not green on the saved objects of 2.17.1"
    end
fi
t2="$(date +%s)"
x="$(sed -n 's/.*"version":{"number":"\([^"]*\)".*/\1/p' "$T/a/status")"
if [ "$x" = "$v219" ]; then pass "Dashboards $x green by service opensearch-dashboards start on the saved objects of 2.17.1 after $((t2 - t1)) s"; else fail "Dashboards version ${x:-not told}, the package is $v219"; fi
tail -n +"$((${nl:-0} + 1))" "$log" > "$T/osd-2.19.log" 2>/dev/null
cp "$T/osd-2.19.log" "$res/osd-2.19.log"
ix2="$(curl -s -m 30 "$os/_cat/aliases/.kibana?h=index" | tr -d ' \n')"
ixs="$(curl -s -m 30 "$os/_cat/indices/.kibana*?h=index,docs.count&s=index" | tr -s ' ' | tr '\n' ';')"
mig="$(grep -o '"message":"[^"]*\(Migrating\|migrat\|Pointing alias\|Creating index\)[^"]*"' "$T/osd-2.19.log" | sed 's/"message":"\(.*\)"/\1/' | head -n 4 | tr '\n' '|')"
if [ -n "$ix2" ]; then
    if [ "$ix2" != "$ix1" ]; then
        case ";$ixs" in *";$ix1 "*) pass "the saved objects migrated: the alias .kibana from $ix1 to $ix2, $ix1 kept (indices: $ixs)" ;; *) fail "the alias .kibana from $ix1 to $ix2, but $ix1 is gone (indices: $ixs)" ;; esac
    else
        pass "the saved objects: the alias .kibana still on $ix1, no migration of their index needed (indices: $ixs)"
    fi
    [ -z "$mig" ] || note "its log of the migration: $mig"
else
    fail "the alias .kibana: none (indices: $ixs)"
fi
m=""
for o in index-pattern/az-up-ip:az-up* visualization/az-up-vis:"az up vis" dashboard/az-up-dash:"az up dashboard" search/az-up-search:"az up search" query/az-up-query:"az up query"; do
    c="$(rq get GET "/api/saved_objects/${o%%:*}")"
    if [ "$c" != 200 ] || ! has get "\"title\":\"${o#*:}\""; then m="$m ${o%%:*}:$c"; continue; fi
    note "${o%%:*}: $(grep -o '"migrationVersion":{[^}]*}' "$T/a/get" | head -n 1)"
done
if [ -z "$m" ]; then pass "the 5 saved objects of 2.17.1 read back with their titles"; else fail "the saved objects of 2.17.1 not read back:$m"; fi
c="$(curl -s -m 60 -o "$T/export.ndjson" -w '%{http_code}' -H 'osd-xsrf: t' -H 'Content-Type: application/json' -X POST "$k/api/saved_objects/_export" -d '{"objects":[{"type":"dashboard","id":"az-up-dash"}],"includeReferencesDeep":true}')"
if [ "$c" = 200 ] && [ "$(grep -c '"type":"\(index-pattern\|visualization\|dashboard\)"' "$T/export.ndjson")" = 3 ]; then pass "the dashboard of 2.17.1 exported with its references: 3 objects"; else fail "export: $c $(head -c 200 "$T/export.ndjson")"; fi
want "the dashboard of 2.17.1 found" find 200 '"total":1' GET '/api/saved_objects/_find?type=dashboard&search_fields=title&search=az*'
c="$(rq settings GET /api/opensearch-dashboards/settings)"
if [ "$c" = 200 ] && has settings '"dateFormat:tz":{"userValue":"UTC"}'; then
    pass "Advanced Settings: dateFormat:tz UTC of 2.17.1 in the configuration of $v219 ($(curl -s -m 30 "$os/.kibana/_search?q=type:config&size=5" | grep -o '"_id":"config:[^"]*"' | tr '\n' ' '))"
else
    fail "Advanced Settings: $c $(ans settings)"
fi
printf '%s' "{\"query_url\":\"/app/data-explorer/discover#/view/az-up-search\",\"time_from\":1794441600000,\"time_to\":1794528000000,\"report_definition\":{\"report_params\":{\"report_name\":\"az up csv\",\"report_source\":\"Saved search\",\"description\":\"azsupport\",\"core_params\":{\"base_url\":\"/app/data-explorer/discover#/view/az-up-search\",\"saved_search_id\":\"az-up-search\",\"report_format\":\"csv\",\"time_duration\":\"PT24H\",\"origin\":\"http://127.0.0.1:5601\",\"limit\":10000,\"excel\":true}},\"delivery\":{\"configIds\":[],\"title\":\"\",\"textDescription\":\"\",\"htmlDescription\":\"\"},\"trigger\":{\"trigger_type\":\"On demand\"}}}" > "$T/report.json"
c="$(rq report POST '/api/reporting/generateReport?timezone=UTC&dateFormat=YYYY-MM-DD&csvSeparator=,&allowLeadingWildcards=true' "@$T/report.json")"
if [ "$c" = 200 ] && has report 'doc 3 of the upgrade'; then pass "reporting: the CSV of the saved search of 2.17.1"; else fail "reporting: the CSV of the saved search of 2.17.1: $c $(ans report)"; fi
want "a new visualization made in $v219" vis2 200 '"title":"az up vis 2"' POST /api/saved_objects/visualization/az-up-vis2 \
    "{\"attributes\":{\"title\":\"az up vis 2\",\"visState\":\"{\\\"title\\\":\\\"az up vis 2\\\",\\\"type\\\":\\\"metric\\\",\\\"aggs\\\":[{\\\"id\\\":\\\"1\\\",\\\"enabled\\\":true,\\\"type\\\":\\\"count\\\",\\\"params\\\":{},\\\"schema\\\":\\\"metric\\\"}],\\\"params\\\":{}}\",\"uiStateJSON\":\"{}\",\"description\":\"\",\"version\":1,\"kibanaSavedObjectMeta\":{\"searchSourceJSON\":\"$SS\"}},\"references\":[{\"name\":\"kibanaSavedObjectMeta.searchSourceJSON.index\",\"type\":\"index-pattern\",\"id\":\"az-up-ip\"}]}"
(cd / && service opensearch-dashboards stop > "$T/stop-2.19.out" 2>&1); r=$?
sleep 2
if [ "$r" = 0 ] && ! running; then pass "$v219: service opensearch-dashboards stop"; else fail "$v219: service opensearch-dashboards stop: exit $r, $(tail -n 1 "$T/stop-2.19.out")"; fi
tail -n +"$((${nl:-0} + 1))" "$log" > "$T/osd-2.19.log" 2>/dev/null
cp "$T/osd-2.19.log" "$res/osd-2.19.log"
if grep -E '"type":"error"|"tags":\[[^]]*"(error|fatal)"' "$T/osd-2.19.log" > "$T/err.txt" 2>/dev/null; then
    fail "$(wc -l < "$T/err.txt" | tr -d ' ') errors in the log of $v219: $(head -n 2 "$T/err.txt" | cut -c1-240 | tr '\n' ' ')"
else
    pass "no errors in the log of $v219 since its start"
fi
stopnode "$T/b219" || fail "OpenSearch 2.19.7 not stopped"
cp "$T/oslogs/az-osd-upgrade.log" "$res/opensearch.log" 2>/dev/null
t3="$(date +%s)"
if [ "$bad" = 0 ]; then
    s1="the upgrade of Dashboards $v217 -> $v219 on its saved objects (OpenSearch $va -> $vb): OK (.kibana: $ix1 -> $ix2, $((t2 - t1)) s to green)"
else
    s1="the upgrade of Dashboards $v217 -> $v219: $bad checks failed"
fi
note "the times: the upgrade $((t3 - t1)) s"
end
