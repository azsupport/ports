#!/bin/sh
# opensearch-dashboards-test.sh - test OpenSearch Dashboards of the repository az,
# installed from it, on the Node.js 24 of www/node24: 2.17.1
# (textproc/opensearch-dashboards217; aZ, 12.11.2026: a legacy project) against
# OpenSearch 2.17.1 of textproc/opensearch217, or 2.19.7
# (textproc/opensearch-dashboards219; aZ, 12.11.2026: his cluster moves to 2.19)
# against OpenSearch 2.19.7 of textproc/opensearch219, whichever of the two is
# installed (the same files): both started by their rc scripts, as a server starts them,
# OpenSearch with the heap of opensearch_heap (512m) on its port 8200 with its
# network.host of the sample (both loopback addresses), as on aZ's nodes, Dashboards
# with the configuration of aZ's ko44 (server.host on 127.0.0.1 here,
# opensearch.hosts http://localhost:8200, the settings of the security plugin
# commented out) and node.options next to it:
#   - the package: no ELF file, no native module, no node/ of the tarball; its node
#     is that of www/node24; --version, the plugins (2.17.1: 13 in, 2.19.7: 15 in,
#     securityDashboards out), the sample configuration, the
#     default configuration of the rc script, newsyslog, the npm packages of the
#     port (2.17.1: those of the 2.17 branch and of the security fixes; 2.19.7:
#     @hapi/content 6.0.3) and its patched files;
#   - the rc script refuses a configuration with a setting of the security plugin,
#     which the package does not have (opensearch_security.*, nested, quoted), with its
#     lines, and starts nothing;
#   - /api/status green, its version, the statuses of the plugins in and none of
#     those out, the heap of node.options; the process: node as www, FreeBSD ELF64,
#     no file of the package mapped (no native module), listening on 127.0.0.1:5601;
#   - the pages of the core and of each plugin in, the bundle of each plugin in the
#     page, the bundles served as the files (plain and with gzip), every .gz of the
#     package the gzip of its file;
#   - the server plugin behind each plugin in answers through Dashboards: alerting,
#     anomaly detection, ml-commons, index management, notifications, observability and PPL,
#     the query workbench (SQL), reporting (a CSV and an XLSX of a saved search, made
#     by the server), security analytics (its rules; a rule's YAML with a
#     !!js/function made into nothing), search relevance; 2.19.7: flow framework
#     (a workflow made, read, found, provisioned, deprovisioned and deleted, its
#     presets) and query insights (the top queries, the settings of the cluster);
#   - saved objects: an index pattern (with the fields of its index, as the page
#     makes it), a visualization and a dashboard made, exported
#     with their references, deleted, imported and read back (.kibana -> .kibana_1);
#     an import with __proto__ refused;
#   - the security fixes over HTTP: //host/ not redirected off-site, the bounds of
#     POST /api/core/capabilities, a Content-Type with two boundaries refused, a
#     Content-Disposition of 200000 characters answered at once, and those of 3.x
#     both ports take: 101 types of the counts of saved objects refused (#12191), a
#     Content-Encoding on the routes of the import refused (#12189), a datasource
#     function chained in Timeline a series of its own (#12217);
#   - the console proxy, Timeline, TSVB with a math metric, the sample data flights
#     installed and removed, requests at once;
#   - reload by the rc script (the log file opened again), the rotation of newsyslog
#     without archives, no errors in its log, nothing left in /tmp, nothing written
#     in the package but data/; stopped by its rc script.
# Every request has a time limit: one without an answer is a failed check.
#
# Usage (FreeBSD, as root, the packages installed): sh tools/opensearch-dashboards-test.sh
# Results: opensearch-dashboards-results/tests.txt (one line per check, the summary
# at the end), the logs of Dashboards and OpenSearch next to it; exit status 0 when
# every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/opensearch-dashboards-results}"
T="${OSD_TEST_WORK:-/var/tmp/opensearch-dashboards-test}"
P=/usr/local
D="$P/www/opensearch-dashboards"
E="$P/etc/opensearch-dashboards"
rc="$P/etc/rc.d/opensearch-dashboards"
osrc="$P/etc/rc.d/opensearch"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T/a" "$T/m" "$T/conf"
chmod 755 "$T" "$T/conf"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
os="http://127.0.0.1:8200"
k="http://127.0.0.1:5601"
node="$P/bin/node"
pidfile=/var/run/opensearch_dashboards/opensearch_dashboards.pid
# the package installed (one of the two), the OpenSearch it goes with, its plugins
if pkg info -e opensearch-dashboards219; then
    osd=opensearch-dashboards219; ospkg=opensearch219
    IN="alertingDashboards anomalyDetectionDashboards assistantDashboards customImportMapDashboards flowFrameworkDashboards ganttChartDashboards indexManagementDashboards mlCommonsDashboards notificationsDashboards observabilityDashboards queryInsightsDashboards queryWorkbenchDashboards reportsDashboards searchRelevanceDashboards securityAnalyticsDashboards"
else
    osd=opensearch-dashboards217; ospkg=opensearch217
    IN="alertingDashboards anomalyDetectionDashboards assistantDashboards customImportMapDashboards ganttChartDashboards indexManagementDashboards mlCommonsDashboards notificationsDashboards observabilityDashboards queryWorkbenchDashboards reportsDashboards searchRelevanceDashboards securityAnalyticsDashboards"
fi
nin="$(echo $IN | wc -w | tr -d ' ')"
OUT="securityDashboards"
# rq <name> <method> <path> [<data or @file> [<content type>]]: a request to Dashboards
# with a time limit; the answer in $T/a/<name>, its status the output
rq() {
    _n="$1"; _m="$2"; _p="$3"
    if [ $# -ge 4 ] && [ -n "$4" ]; then
        curl -s -m 60 -o "$T/a/$_n" -w '%{http_code}' -H 'osd-xsrf: osd-test' -H "Content-Type: ${5:-application/json}" \
            -X "$_m" "$k$_p" --data-binary "$4" 2>/dev/null
    else
        curl -s -m 60 -o "$T/a/$_n" -w '%{http_code}' -H 'osd-xsrf: osd-test' -X "$_m" "$k$_p" 2>/dev/null
    fi
}
has() { grep -q -F -- "$2" "$T/a/$1" 2>/dev/null; }
ans() { head -c 200 "$T/a/$1" 2>/dev/null | tr '\n' ' '; }
# want <what> <name> <status> <text> <method> <path> [<data> [<type>]]
want() {
    _w="$1"; _n="$2"; _s="$3"; _t="$4"; shift 4
    _c="$(rq "$_n" "$@")"
    if [ "$_c" = "$_s" ] && has "$_n" "$_t"; then pass "$_w"; else fail "$_w: $_c $(ans "$_n")"; fi
}
finish() {
    echo "opensearch-dashboards-test: $ok ok, $bad failed" >> "$out"
    [ "$bad" = 0 ]
    exit $?
}
running() { pgrep -f "$D/src/cli/dist serve" > /dev/null 2>&1; }

for p in "$osd" "$ospkg" node24; do
    pkg info -e "$p" || { fail "$p is not installed"; finish; }
done
v="$(pkgv "$osd")"
note "$osd $v against $ospkg $(pkgv "$ospkg")"

# --- the package ---------------------------------------------------------------------
b="$(find "$D" -type f -exec file {} + 2>/dev/null | grep -E ': .*(ELF|Mach-O|PE32)' | head -n 3 | tr '\n' ' ')"
if [ -z "$b" ]; then pass "no ELF file in the package ($(find "$D" -type f | wc -l | tr -d ' ') files)"; else fail "binaries in the package: $b"; fi
n="$(find "$D" -name '*.node' | head -n 3 | tr '\n' ' ')"
if [ -z "$n" ] && [ ! -e "$D/node" ]; then pass "no native module (*.node), no node/ of the tarball"; else fail "in the package: ${n:-$D/node}"; fi
if grep -q "^  NODE=\"$node\"\$" "$D/bin/use_node" && grep -q "procname=\"$node\"" "$rc"; then
    pass "bin/use_node and rc.d/opensearch-dashboards: the node of www/node24 ($("$node" --version))"
else
    fail "bin/use_node or the rc script: not $node"
fi
# (its tools stop as root without --allow-root, as upstream: src/setup_node_env/root)
x="$(cd /tmp && "$D/bin/opensearch-dashboards" --version 2>&1)"; r=$?
case "$r $x" in 1*'should not be run as root'*) pass "as root without --allow-root its tools stop: $x" ;; *) fail "bin/opensearch-dashboards --version as root without --allow-root: exit $r, $(printf '%s' "$x" | tail -n 2 | tr '\n' ' ' | cut -c1-200)" ;; esac
x="$(cd /tmp && "$D/bin/opensearch-dashboards" --version --allow-root 2>&1)"
if [ "$x" = "$v" ]; then pass "bin/opensearch-dashboards --version --allow-root: $x"; else fail "bin/opensearch-dashboards --version --allow-root: $(printf '%s' "$x" | tail -n 2 | tr '\n' ' ' | cut -c1-200), the package is $v"; fi
# (list prints the id of each plugin, then an empty line)
x="$(cd /tmp && "$D/bin/opensearch-dashboards-plugin" list --allow-root 2>&1 | sed -e 's/@.*//' -e '/^$/d' | sort | tr '\n' ' ' | sed 's/ $//')"
w="$(printf '%s\n' $IN | sort | tr '\n' ' ' | sed 's/ $//')"
if [ "$x" = "$w" ]; then pass "bin/opensearch-dashboards-plugin list: the $nin plugins in"; else fail "bin/opensearch-dashboards-plugin list: $x"; fi
x="$(ls "$D/plugins" | sort | tr '\n' ' ' | sed 's/ $//')"
o=""; for p in $OUT; do [ -e "$D/plugins/$p" ] && o="$o $p"; done
if [ "$x" = "$w" ] && [ -z "$o" ]; then pass "plugins: $nin in, not $OUT"; else fail "plugins: $x; out but there:$o"; fi
# (--help prints the usage and exits 64: defaultHelp of src/cli/command.js)
(cd /tmp && "$D/bin/opensearch-dashboards-keystore" --help --allow-root > "$T/ks.out" 2>&1); r=$?
if [ "$r" = 64 ] && grep -q 'Usage: bin/opensearch-dashboards-keystore' "$T/ks.out" && grep -q -w create "$T/ks.out"; then
    pass "bin/opensearch-dashboards-keystore --help --allow-root: its usage (exit 64)"
else
    fail "bin/opensearch-dashboards-keystore --help --allow-root: exit $r, $(head -n 3 "$T/ks.out" | tr '\n' ' ' | cut -c1-200)"
fi
if [ "$(cd "$D/config" 2>/dev/null && pwd -P)" = "$E" ]; then pass "www/opensearch-dashboards/config -> etc/opensearch-dashboards"; else fail "www/opensearch-dashboards/config: $(readlink "$D/config")"; fi
if grep -q "opensearch_dashboards_config:=\"$E/opensearch_dashboards.yml\"" "$rc"; then pass "the rc script's configuration: $E/opensearch_dashboards.yml"; else fail "the rc script's default configuration is not $E/opensearch_dashboards.yml"; fi
s="$(grep -v -E '^[[:space:]]*(#|$)' "$E/opensearch_dashboards.yml.sample" | grep -v -x -e '---' | head -n 3 | tr '\n' ' ')"
if [ -z "$s" ] && ! grep -q -E 'kibanaserver|https://localhost' "$E/opensearch_dashboards.yml.sample"; then pass "opensearch_dashboards.yml.sample: no setting, no block of the security plugin"; else fail "opensearch_dashboards.yml.sample: $s"; fi
ns="$P/etc/newsyslog.conf.d/opensearch_dashboards.conf"
if [ -f "$ns" ] && newsyslog -n -f "$ns" > "$T/ns.out" 2>&1 && grep -q -E '^/var/log/opensearch_dashboards.log[[:space:]]+www:www[[:space:]]+640[[:space:]]+0[[:space:]]' "$ns"; then
    pass "newsyslog: $ns, count 0 (no archives), read by newsyslog -n"
else
    fail "newsyslog: $ns: $(head -n 2 "$T/ns.out" 2>/dev/null | tr '\n' ' ')"
fi
pv() { "$node" -p 'require(process.argv[1]).version' "$D/$1/package.json" 2>/dev/null; }
m=0
if [ "$osd" = opensearch-dashboards219 ]; then
    x="$(pv node_modules/@hapi/content) $(pv node_modules/@hapi/inert) $(pv node_modules/js-yaml) $(pv node_modules/@opensearch-project/opensearch-next) $(pv node_modules/json11)"
    if [ "$x" = "6.0.3 7.1.2 4.3.2 2.13.0 2.0.0" ]; then pass "@hapi/content 6.0.3 of the port; @hapi/inert 7.1.2, js-yaml 4.3.2, the client 2.13.0 and json11 2.0.0 of the tarball"; else fail "@hapi/content, @hapi/inert, js-yaml, client, json11: $x"; fi
    for f in src/core/server/saved_objects/routes/index.js src/plugins/saved_objects_management/server/routes/scroll_count.js \
        src/plugins/vis_type_timeline/server/handlers/chain_runner.js; do
        grep -q 'azsupport/ports' "$D/$f" || { fail "$f: not patched"; m=1; }
    done
    # (those of textproc/opensearch-dashboards217 that 2.19.7 has: its own code)
    grep -q 'MAX_APPLICATIONS = 1000' "$D/src/core/server/capabilities/routes/resolve_capabilities.js" || { fail "capabilities: not the bounds of #12563"; m=1; }
    grep -q "path.charAt(1) === '/'" "$D/src/legacy/server/http/index.js" || { fail "src/legacy/server/http/index.js: not the redirect of #12193"; m=1; }
    grep -q 'validateObject' "$D/src/core/server/saved_objects/routes/utils.js" || { fail "src/core/server/saved_objects/routes/utils.js: not the check of #12085"; m=1; }
    grep -q 'The trailing alternative consumes a name' "$D/node_modules/@hapi/content/lib/index.js" || { fail "@hapi/content: not the parser of Content-Disposition of 6.0.3"; m=1; }
    grep -q 'path.startsWith(confineDir + Path.sep)' "$D/node_modules/@hapi/inert/lib/file.js" || { fail "@hapi/inert: not the confinement of 7.1.1"; m=1; }
    [ "$m" = 0 ] && pass "the security fixes in their files (import with Content-Encoding, counts of saved objects, Timeline, @hapi/content; capabilities, redirects, import, @hapi/inert of 2.19.7)"
else
    x="$(pv node_modules/@opensearch-project/opensearch-next) $(pv node_modules/json11) $(pv node_modules/js-yaml)"
    if [ "$x" = "2.13.0 2.0.0 3.15.2" ]; then pass "the client 2.13.0 and json11 2.0.0 of the 2.17 branch, js-yaml 3.15.2"; else fail "client, json11, js-yaml: $x"; fi
    for f in src/legacy/server/http/index.js src/core/server/http/https_redirect_server.js src/core/server/saved_objects/routes/utils.js \
        src/core/server/capabilities/resolve_capabilities.js src/core/server/capabilities/routes/resolve_capabilities.js \
        src/core/server/saved_objects/routes/index.js src/plugins/saved_objects_management/server/routes/scroll_count.js \
        src/plugins/vis_type_timeline/server/handlers/chain_runner.js; do
        grep -q 'azsupport/ports' "$D/$f" || { fail "$f: not patched"; m=1; }
    done
    grep -q 'internals.boundaryParamRegex' "$D/node_modules/@hapi/content/lib/index.js" || { fail "@hapi/content: not the parser of 6.0.3"; m=1; }
    grep -q 'The trailing alternative consumes a name' "$D/node_modules/@hapi/content/lib/index.js" || { fail "@hapi/content: not the parser of Content-Disposition of 6.0.3"; m=1; }
    grep -q 'path.startsWith(confineDir + Path.sep)' "$D/node_modules/@hapi/inert/lib/file.js" || { fail "@hapi/inert: not the confinement of 7.1.1"; m=1; }
    [ "$m" = 0 ] && pass "the security fixes in their files (capabilities, redirects, import, import with Content-Encoding, counts of saved objects, Timeline, @hapi/content, @hapi/inert)"
fi
t="$(grep -rl -E 'Number\.MAX_SAFE_INTEGER[[:space:]]*\|\|' --include='*.js' "$D/node_modules/@osd" "$D/src" "$D/plugins" 2>/dev/null | while read -r f; do
    sed -n -e '/\([A-Za-z_$][A-Za-z0-9_$]*\)[[:space:]]*<[[:space:]]*Number\.MAX_SAFE_INTEGER[[:space:]]*||[[:space:]]*\1[[:space:]]*>/p' "$f" | grep -q . && echo "$f"
done | head -n 3 | tr '\n' ' ')"
if [ -z "$t" ] && grep -rq -E '<[[:space:]]*Number\.MIN_SAFE_INTEGER[[:space:]]*\|\|' --include='*.js' "$D/node_modules/@osd/std"; then pass "1b89a739: no check of large numerals with the typo left (@osd/std and the bundles)"; else fail "1b89a739: the typo in $t"; fi
g=0; c=0
for f in $(find "$D" -name '*.js.gz'); do
    c=$((c + 1))
    gzip -dc "$f" | cmp -s - "${f%.gz}" || { g=$((g + 1)); note "not the gzip of its file: ${f#$D/}"; }
done
for f in $(find "$D" -name '*.js.br'); do
    c=$((c + 1))
    "$node" -e 'const z = require("zlib"), fs = require("fs"); process.exit(z.brotliDecompressSync(fs.readFileSync(process.argv[1])).equals(fs.readFileSync(process.argv[2])) ? 0 : 1)' "$f" "${f%.br}" || { g=$((g + 1)); note "not the brotli of its file: ${f#$D/}"; }
done
if [ "$g" = 0 ] && [ "$c" -gt 10 ]; then pass "each of the $c .gz and .br of the bundles is that of its file"; else fail "$g of $c .gz and .br differ from their files"; fi

# --- OpenSearch of textproc/opensearch217 or opensearch219, by its rc script ------------------
osc="$T/osconf"
mkdir -p "$osc" "$T/osdata" "$T/oslogs"
(cd "$P/etc/opensearch" && find . -name '*.sample') | while read -r f; do
    mkdir -p "$osc/$(dirname "$f")"; cp "$P/etc/opensearch/$f" "$osc/${f%.sample}"
done
# (opensearch219: the prepackaged rules of opensearch-security-analytics, which 2.19
# reads from the directory of the configuration, as its pkg-message says for a
# configuration of its own)
[ -d "$P/etc/opensearch/opensearch-security-analytics" ] && cp -Rp "$P/etc/opensearch/opensearch-security-analytics" "$osc/"
sed -i '' -e "s|^path.data: .*|path.data: $T/osdata|" -e "s|^path.logs: .*|path.logs: $T/oslogs|" "$osc/opensearch.yml"
# no network.host: the default _local_ of the sample, ::1 and 127.0.0.1
{ echo "http.port: 8200"; echo "transport.port: 8300"; echo "cluster.name: az-test"; } >> "$osc/opensearch.yml"
chown -R opensearch:opensearch "$osc" "$T/osdata" "$T/oslogs"
(cd / && env opensearch_config="$osc" opensearch_heap=512m "$osrc" onestart > "$T/os-start.out" 2>&1) || fail "rc.d/opensearch onestart: $(tail -n 2 "$T/os-start.out" | tr '\n' ' ')"
up=""; i=0
while [ "$i" -lt 120 ]; do
    case "$(curl -s -m 5 "$os/" 2>/dev/null)" in *'"number"'*) up=1; break ;; esac
    sleep 2; i=$((i + 1))
done
stop_os() {
    (cd / && env opensearch_config="$osc" "$osrc" onestop > "$T/os-stop.out" 2>&1) || fail "rc.d/opensearch onestop: $(tail -n 1 "$T/os-stop.out")"
    cp "$T/oslogs/az-test.log" "$res/opensearch.log" 2>/dev/null
}
if [ -z "$up" ]; then
    fail "OpenSearch does not answer on $os in 240 s: $(tail -n 3 "$T/oslogs/az-test.log" 2>/dev/null | tr '\n' ' ' | cut -c1-300)"
    stop_os; finish
fi
pass "OpenSearch $(curl -s -m 10 "$os/" | sed -n 's/.*"number" : "\([^"]*\)".*/\1/p') on port 8200 after $((i * 2)) s, plugins: $(curl -s -m 10 "$os/_cat/plugins?h=component" | sort | tr '\n' ' ' | cut -c1-300)"
# Node.js 24 tries each address of localhost (autoSelectFamily, on since Node.js 20):
# ko44's http://localhost:8200 whether OpenSearch answers on ::1 or not
if curl -s -m 5 'http://[::1]:8200/' | grep -q '"number"'; then
    note "OpenSearch answers on [::1]:8200 and 127.0.0.1:8200: opensearch.hosts http://localhost:8200 of ko44"
else
    note "OpenSearch answers on 127.0.0.1:8200, not on [::1]:8200: opensearch.hosts http://localhost:8200 of ko44"
fi
curl -s -m 60 -o /dev/null "$os/_cluster/health?wait_for_status=yellow&timeout=60s"
curl -s -m 30 -o /dev/null -H 'Content-Type: application/json' -X PUT "$os/az-test" -d '{"settings":{"number_of_shards":1,"number_of_replicas":0}}'
for i in 1 2 3; do
    curl -s -m 30 -o /dev/null -H 'Content-Type: application/json' -X POST "$os/az-test/_doc?refresh=true" \
        -d "{\"t\":\"2026-11-12T1$i:00:00Z\",\"title\":\"doc $i of azsupport\",\"n\":$i}"
done

# --- the configuration of aZ's ko44, the refusals of the rc script ---------------------------
conf="$T/conf/opensearch_dashboards.yml"
cp "$E/opensearch_dashboards.yml.sample" "$conf" || fail "no $E/opensearch_dashboards.yml.sample"
printf '%s\n' 'server.host: "127.0.0.1"' 'opensearch.hosts: ["http://localhost:8200"]' '#opensearch.hosts: ["http://localhost:9200"]' \
    'opensearch.ssl.verificationMode: none' '#opensearch.username: "kibanaserver"' '#opensearch.password: "kibanaserver"' \
    '#opensearch.requestHeadersWhitelist: [ authorization,securitytenant ]' '#opensearch_security.multitenancy.enabled: true' \
    '#opensearch_security.multitenancy.tenants.preferred: ["Private", "Global"]' '#opensearch_security.readonly_mode.roles: ["kibana_read_only"]' \
    '#opensearch_security.cookie.secure: false' >> "$conf"
cp "$E/node.options.sample" "$T/conf/node.options" && echo '--max-old-space-size=700' >> "$T/conf/node.options"
chmod 644 "$conf" "$T/conf/node.options"
export opensearch_dashboards_config="$conf" opensearch_dashboards_log="$T/osd.log"
refuse() {
    _w="$1"; shift
    printf '%s\n' "$@" > "$T/conf/bad.yml"; cat "$conf" >> "$T/conf/bad.yml"; chmod 644 "$T/conf/bad.yml"
    (cd / && opensearch_dashboards_config="$T/conf/bad.yml" "$rc" onestart > "$T/refuse.out" 2>&1); _r=$?
    sleep 1
    if [ "$_r" != 0 ] && grep -q 'settings of plugins this package does not have' "$T/refuse.out" && grep -q "^1:" "$T/refuse.out" && ! running; then
        pass "rc.d/opensearch-dashboards onestart with $_w: refused with its line, nothing started"
    else
        fail "rc.d/opensearch-dashboards onestart with $_w: exit $_r, $(head -n 2 "$T/refuse.out" | tr '\n' ' ' | cut -c1-200)"
        "$rc" onestop > /dev/null 2>&1
    fi
}
refuse "opensearch_security.multitenancy.enabled: true" 'opensearch_security.multitenancy.enabled: true'
refuse "nested opensearch_security: cookie.secure" 'opensearch_security:' '  cookie.secure: false'
refuse "\"opensearch_security.cookie.secure\": false, quoted" '"opensearch_security.cookie.secure": false'
rm -f "$T/conf/bad.yml"

# --- Dashboards by its rc script ----------------------------------------------------------
ls -A /tmp | sort > "$T/tmp-before.txt"
touch "$T/marker"; sleep 1
(cd / && "$rc" onestart > "$T/osd-start.out" 2>&1); r=$?
cp "$T/osd-start.out" "$res/osd-start.out"
if [ "$r" = 0 ]; then pass "rc.d/opensearch-dashboards onestart with the configuration of ko44"; else fail "rc.d/opensearch-dashboards onestart: exit $r, $(tail -n 2 "$T/osd-start.out" | tr '\n' ' ')"; fi
state() { sed -n 's/.*"overall":{[^}]*"state":"\([a-z]*\)".*/\1/p' "$T/a/status" 2>/dev/null; }
i=0
while [ "$i" -lt 150 ]; do
    rq status GET /api/status > /dev/null
    [ "$(state)" = green ] && break
    sleep 2; i=$((i + 1))
done
stop_osd() {
    (cd / && "$rc" onestop > "$T/osd-stop.out" 2>&1); _r=$?
    sleep 2
    if [ "$_r" = 0 ] && ! running && ! curl -s -m 5 -o /dev/null "$k/api/status"; then pass "rc.d/opensearch-dashboards onestop"; else fail "rc.d/opensearch-dashboards onestop: exit $_r, $(tail -n 1 "$T/osd-stop.out")"; fi
    cp "$T/osd.log" "$res/osd.log" 2>/dev/null
}
if [ "$(state)" != green ]; then
    fail "/api/status $(state) on $k after 300 s: $(grep -E '"error"' "$T/osd.log" 2>/dev/null | tail -n 2 | cut -c1-300 | tr '\n' ' ')"
    stop_osd; stop_os; finish
fi
pass "/api/status green on $k after $((i * 2)) s"
x="$(sed -n 's/.*"version":{"number":"\([^"]*\)".*/\1/p' "$T/a/status")"
if [ "$x" = "$v" ]; then pass "version $x"; else fail "version ${x:-not told}, the package is $v"; fi
m=""; for p in $IN; do has status "\"id\":\"plugin:$p@" || m="$m $p"; done
o=""; for p in $OUT; do has status "\"id\":\"plugin:$p@" && o="$o $p"; done
if [ -z "$m$o" ]; then pass "the statuses of the $nin plugins in, none of securityDashboards"; else fail "statuses: missing$m; out but there:$o"; fi
if grep -o '"state":"[a-z]*"' "$T/a/status" | grep -v -q '"green"'; then fail "statuses not green: $(grep -o '"id":"[^"]*","message":"[^"]*","since":"[^"]*","state":"[a-z]*"' "$T/a/status" | grep -v green | head -n 3 | tr '\n' ' ' | cut -c1-300)"; else pass "every status green"; fi
hl="$(sed -n 's/.*"size_limit":\([0-9]*\).*/\1/p' "$T/a/status")"
if [ -n "$hl" ] && [ "$hl" -ge 734003200 ] && [ "$hl" -le 943718400 ]; then pass "the heap of node.options (--max-old-space-size=700): a limit of $((hl / 1048576)) MB"; else fail "the heap limit ${hl:-not told}: not that of node.options"; fi
pid="$(cat "$pidfile" 2>/dev/null)"
c="$(ps -o user= -o command= -p "${pid:-0}" 2>/dev/null)"
case "$c" in www*"$node"*"$D/src/cli/dist serve"*) pass "the process of the pid file: $node as www, $(ps -o rss= -p "$pid" | tr -d ' ') KB" ;; *) fail "the process of the pid file ${pid:-none}: $c" ;; esac
x="$(ps -o emul= -p "${pid:-0}" 2>/dev/null | tr -d ' ')"
if [ "$x" = "FreeBSDELF64" ]; then pass "its ABI: FreeBSD ELF64"; else fail "its ABI: $x"; fi
procstat -v "${pid:-0}" 2>/dev/null | awk '$NF ~ /^\// { print $NF }' | sort -u > "$T/maps.txt"
x="$(grep -v -E "^($node|/lib/|/usr/lib/|/libexec/|$P/lib/|$P/az/lib/)" "$T/maps.txt" | head -n 5 | tr '\n' ' ')"
if [ -z "$x" ] && [ -s "$T/maps.txt" ]; then pass "mapped: node and the libraries of the base system, of the ports and of az, nothing of the package ($(wc -l < "$T/maps.txt" | tr -d ' ') files)"; else fail "mapped files: ${x:-none}"; fi
cp "$T/maps.txt" "$res/osd-maps.txt"
x="$(sockstat -4 -6 -l 2>/dev/null | awk -v p="${pid:-0}" '$3 == p { print $6 }' | sort -u | tr '\n' ' ')"
if [ "$x" = "127.0.0.1:5601 " ]; then pass "listens on 127.0.0.1:5601 only (server.host)"; else fail "listens on: $x"; fi
note "its connections to OpenSearch: $(sockstat -4 -6 -c 2>/dev/null | awk -v p="${pid:-0}" '$3 == p && $7 ~ /:8200$/ { print $7 }' | sort | uniq -c | tr '\n' ' ')"

# --- the pages, the bundles -----------------------------------------------------------------
pg=""
apps=""
[ "$osd" = opensearch-dashboards219 ] && apps="opensearch-flow query-insights-dashboards"
for a in home dashboards data-explorer/discover visualize dev_tools management alerting anomaly-detection-dashboards \
    opensearch_index_management_dashboards notifications-dashboards observability-logs opensearch-query-workbench \
    reports-dashboards searchRelevance opensearch_security_analytics_dashboards maps-dashboards $apps; do
    c="$(rq page GET "/app/$a")"
    if [ "$c" != 200 ] || ! has page '<title>OpenSearch Dashboards</title>'; then pg="$pg $a:$c"; fi
done
if [ -z "$pg" ]; then pass "the pages of the core and of the plugins in: 200 with the page of OpenSearch Dashboards"; else fail "pages:$pg"; fi
rq bootstrap GET /bootstrap.js > /dev/null
# (any /app/<id> is the same page; the bundle of each plugin makes the difference)
m=""; for p in $IN; do grep -q "/bundles/plugin/$p/$p.plugin.js" "$T/a/bootstrap" || m="$m $p"; done
o=""; for p in $OUT; do grep -q "/bundles/plugin/$p/" "$T/a/bootstrap" && o="$o $p"; done
if [ -z "$m$o" ]; then pass "the page loads the bundle of each of the $nin plugins in, none of $OUT"; else fail "the bundles of the plugins in the page: missing$m; out but there:$o"; fi
grep -o "/[0-9]*/bundles/[^\"' ]*\\.js" "$T/a/bootstrap" | sort -u > "$T/bundles.txt"
n=0; d=0
while read -r u; do
    f="$(find "$D/src" "$D/plugins" "$D/node_modules/@osd/ui-shared-deps" -path "*/target*/${u##*/}" -type f 2>/dev/null | head -n 1)"
    [ -n "$f" ] || { d=$((d + 1)); note "no file for $u"; continue; }
    e="$(sha256 -q "$f")"
    s="$(curl -s -m 120 "$k$u" | sha256 -q)"
    z="$(curl -s -m 120 --compressed -H 'Accept-Encoding: gzip' "$k$u" | sha256 -q)"
    n=$((n + 1))
    [ "$s" = "$e" ] && [ "$z" = "$e" ] || { d=$((d + 1)); note "served differently: $u"; }
done < "$T/bundles.txt"
if [ "$d" = 0 ] && [ "$n" -gt 20 ]; then pass "$n bundles of the page served as the files, plain and with gzip"; else fail "$d of $n bundles served differ from the files"; fi

# --- the server plugins behind the plugins in -----------------------------------------------
# (no monitor yet: "ok":false with totalMonitors 0 for the missing index, an error has no totalMonitors)
want "alerting: the monitors" alerting 200 '"totalMonitors":' GET '/api/alerting/monitors?from=0&size=10&search=&sortField=name&sortDirection=desc&state=all'
want "anomaly detection: the detectors" ad 200 '"ok":true' GET /api/anomaly_detectors/detectors/_list
want "ml-commons: the models" ml 200 '"total_models"' GET '/api/ml-commons/model?from=0&size=10'
want "index management: the policies" ism 200 '"ok":true' GET '/api/ism/policies?from=0&size=20&search=&sortField=id&sortDirection=desc'
want "notifications: the channels" notif 200 'config_list' GET '/api/notifications/get_configs?from_index=0&max_items=10&config_type=slack&config_type=email&sort_field=name&sort_order=asc'
want "observability: the operational panels" obs 200 'panels' GET /api/observability/operational_panels/panels
want "observability: PPL source=az-test" ppl 200 'doc 1 of azsupport' POST /api/ppl/search '{"query":"source=az-test | fields title","format":"jdbc"}'
want "query workbench: SQL SELECT title FROM az-test" sql 200 'doc 2 of azsupport' POST /api/sql_console/sqlquery '{"query":"SELECT title FROM az-test"}'
# (the routes of securityAnalyticsDashboards are under /_plugins/_security_analytics of Dashboards)
want "security analytics: the prepackaged rules" sarules 200 '"ok":true' POST '/_plugins/_security_analytics/rules/_search?prePackaged=true' '{"from":0,"size":1,"query":{"match_all":{}}}'
printf '%s' '{"title":"azsupport test rule","category":"windows","description":"azsupport","detection":"selection:\n  EventID: 4688\ncondition: selection","status":"experimental","author":"azsupport","references":[],"tags":[],"level":"low","false_positives":[]}' > "$T/rule.json"
want "security analytics: a rule made from its YAML" rule 200 '"ok":true' POST '/_plugins/_security_analytics/rules?category=windows' "@$T/rule.json"
rm -f /tmp/osd-yaml-probe
printf '%s' '{"title":"azsupport probe rule","category":"windows","description":"azsupport","detection":"selection:\n  EventID: { toJSON: !!js/function '"'"'function () { process.mainModule.require(\"fs\").writeFileSync(\"/tmp/osd-yaml-probe\", \"ran\"); return 1; }'"'"' }\ncondition: selection","status":"experimental","author":"azsupport","references":[],"tags":[],"level":"low","false_positives":[]}' > "$T/probe.json"
c="$(rq probe POST '/_plugins/_security_analytics/rules?category=windows' "@$T/probe.json")"
if [ ! -e /tmp/osd-yaml-probe ] && ! has probe '"ok":true'; then pass "security analytics: a rule with !!js/function refused ($c, ok false), its function never run"; else fail "security analytics: the !!js/function rule: $c $(ans probe), /tmp/osd-yaml-probe: $(cat /tmp/osd-yaml-probe 2>/dev/null)"; rm -f /tmp/osd-yaml-probe; fi
c="$(rq rel POST /api/relevancy/search '{"query1":{"index":"az-test","pipeline":"","size":1,"query":{"match_all":{}}},"query2":{"index":"az-test","pipeline":"","size":1,"query":{"match":{"title":"doc"}}}}')"
if [ "$c" = 200 ] && has rel '"result1":' && has rel '"result2":' && ! has rel 'errorMessage'; then pass "search relevance: two queries compared"; else fail "search relevance: two queries compared: $c $(ans rel)"; fi
if [ "$osd" = opensearch-dashboards219 ]; then
    # flow framework: its presets (files of the plugin), then a workflow of one noop
    # step through opensearch-flow-framework, from its making to its deletion
    c="$(rq ffpresets GET /api/flow_framework/workflow/presets)"
    if [ "$c" = 200 ] && has ffpresets '"name":"Custom Search"' && has ffpresets '"name":"RAG with Lexical Retrieval"'; then pass "flow framework: the presets of workflows"; else fail "flow framework: the presets: $c $(ans ffpresets)"; fi
    c="$(rq ffcreate POST /api/flow_framework/workflow/create '{"name":"az-test-workflow","description":"azsupport","use_case":"CUSTOM","version":{"template":"1.0.0","compatibility":["2.19.0","3.0.0"]},"workflows":{"provision":{"nodes":[{"id":"az_noop","type":"noop","user_inputs":{}}]}}}')"
    fid="$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' "$T/a/ffcreate" | head -n 1)"
    s_="$c"
    c="$(rq ffget GET "/api/flow_framework/workflow/${fid:-none}")"; s_="$s_ $c"
    has ffget '"name":"az-test-workflow"' || s_="$s_ (not read)"
    c="$(rq ffsearch POST /api/flow_framework/workflow/search '{"query":{"match_all":{}},"size":1000}')"; s_="$s_ $c"
    has ffsearch "\"${fid:-none}\":" || s_="$s_ (not found)"
    c="$(rq ffprov POST "/api/flow_framework/workflow/provision/${fid:-none}")"; s_="$s_ $c"
    i=0; while [ "$i" -lt 15 ]; do rq ffstate GET "/api/flow_framework/workflow/state/${fid:-none}" > /dev/null; has ffstate '"workflowState":"Completed"' && break; sleep 2; i=$((i + 1)); done
    has ffstate '"workflowState":"Completed"' || s_="$s_ (state: $(ans ffstate))"
    c="$(rq ffdeprov POST "/api/flow_framework/workflow/deprovision/${fid:-none}")"; s_="$s_ $c"
    c="$(rq ffdelete DELETE "/api/flow_framework/workflow/delete/${fid:-none}")"; s_="$s_ $c"
    c="$(rq ffgone GET "/api/flow_framework/workflow/${fid:-none}")"; s_="$s_ $c"
    if [ -n "$fid" ] && [ "$s_" = "200 200 200 200 200 200 404" ]; then
        pass "flow framework: a workflow made ($fid), read, found, provisioned (Completed), deprovisioned and deleted"
    else
        fail "flow framework: the workflow ${fid:-not made}: $s_ $(ans ffcreate)"
    fi
    # query insights: the top queries of query-insights (latency is on by default in
    # 2.19), the settings of the cluster, a change of them
    want "query insights: the top queries" qitop 200 '"ok":true,"response":{"top_queries":[' GET /api/top_queries
    want "query insights: the top queries by latency of a time range" qilat 200 '"ok":true,"response":{"top_queries":[' GET \
        '/api/top_queries/latency?from=2026-11-12T00:00:00.000Z&to=2099-01-01T00:00:00.000Z&verbose=false'
    want "query insights: the settings of the cluster" qiset 200 '"ok":true,"response":{"persistent":' GET /api/settings
    c="$(rq qiupd PUT '/api/update_settings?metric=latency&enabled=true&top_n_size=10&window_size=1m&group_by=none&exporterType=none')"
    x="$(curl -s -m 30 "$os/_cluster/settings?flat_settings=true")"
    case "$c $x" in
        200*'"search.insights.top_queries.latency.top_n_size":"10"'*'"search.insights.top_queries.latency.window_size":"1m"'*) pass "query insights: its settings changed through it (latency: top 10, window 1m)" ;;
        *) fail "query insights: the settings changed: $c $(ans qiupd); the cluster: $(printf '%s' "$x" | cut -c1-200)" ;;
    esac
fi

# --- saved objects: made, exported, deleted, imported, read back -----------------------------
SS='{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[],\"indexRefName\":\"kibanaSavedObjectMeta.searchSourceJSON.index\"}'
# the index pattern with its fields, as the page makes it (reporting parses them for its date fields)
c="$(rq fields GET '/api/index_patterns/_fields_for_wildcard?pattern=az-test*&meta_fields=_source&meta_fields=_id&meta_fields=_type&meta_fields=_index&meta_fields=_score')"
if [ "$c" = 200 ] && "$node" -e 'const fs = require("fs"); const f = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).fields;
    if (!f.some((x) => x.name === "t" && x.type === "date")) process.exit(1);
    fs.writeFileSync(process.argv[2], JSON.stringify({ attributes: { title: "az-test*", timeFieldName: "t", fields: JSON.stringify(f) } }));' "$T/a/fields" "$T/ip.json"; then
    pass "the fields of az-test*: $(grep -o '"name":"[^"]*"' "$T/a/fields" | sed 's/"name":"\(.*\)"/\1/' | tr '\n' ' ')(t a date)"
else
    fail "the fields of az-test*: $c $(ans fields)"
    printf '%s' '{"attributes":{"title":"az-test*","timeFieldName":"t"}}' > "$T/ip.json"
fi
want "an index pattern made" ip 200 '"title":"az-test*"' POST /api/saved_objects/index-pattern/az-ip "@$T/ip.json"
want "a visualization made" vis 200 '"title":"az vis"' POST /api/saved_objects/visualization/az-vis \
    "{\"attributes\":{\"title\":\"az vis\",\"visState\":\"{\\\"title\\\":\\\"az vis\\\",\\\"type\\\":\\\"metric\\\",\\\"aggs\\\":[{\\\"id\\\":\\\"1\\\",\\\"enabled\\\":true,\\\"type\\\":\\\"count\\\",\\\"params\\\":{},\\\"schema\\\":\\\"metric\\\"}],\\\"params\\\":{}}\",\"uiStateJSON\":\"{}\",\"description\":\"\",\"version\":1,\"kibanaSavedObjectMeta\":{\"searchSourceJSON\":\"$SS\"}},\"references\":[{\"name\":\"kibanaSavedObjectMeta.searchSourceJSON.index\",\"type\":\"index-pattern\",\"id\":\"az-ip\"}]}"
want "a dashboard made" dash 200 '"title":"az dashboard"' POST /api/saved_objects/dashboard/az-dash \
    '{"attributes":{"title":"az dashboard","hits":0,"description":"","panelsJSON":"[{\"embeddableConfig\":{},\"gridData\":{\"h\":15,\"i\":\"1\",\"w\":24,\"x\":0,\"y\":0},\"panelIndex\":\"1\",\"version\":\"'"$v"'\",\"panelRefName\":\"panel_0\"}]","optionsJSON":"{\"hidePanelTitles\":false,\"useMargins\":true}","version":1,"timeRestore":false,"kibanaSavedObjectMeta":{"searchSourceJSON":"{\"query\":{\"query\":\"\",\"language\":\"kuery\"},\"filter\":[]}"}},"references":[{"name":"panel_0","type":"visualization","id":"az-vis"}]}'
c="$(curl -s -m 60 -o "$T/export.ndjson" -w '%{http_code}' -H 'osd-xsrf: t' -H 'Content-Type: application/json' -X POST "$k/api/saved_objects/_export" -d '{"objects":[{"type":"dashboard","id":"az-dash"}],"includeReferencesDeep":true}')"
if [ "$c" = 200 ] && [ "$(grep -c '"type":"\(index-pattern\|visualization\|dashboard\)"' "$T/export.ndjson")" = 3 ]; then pass "the dashboard exported with its references: 3 objects"; else fail "export: $c $(head -c 200 "$T/export.ndjson")"; fi
for o in dashboard/az-dash visualization/az-vis index-pattern/az-ip; do rq del DELETE "/api/saved_objects/$o" > /dev/null; done
c="$(curl -s -m 60 -o "$T/a/import" -w '%{http_code}' -H 'osd-xsrf: t' -X POST "$k/api/saved_objects/_import" -F "file=@$T/export.ndjson")"
if [ "$c" = 200 ] && has import '"success":true' && has import '"successCount":3'; then pass "the 3 objects imported"; else fail "import: $c $(ans import)"; fi
g=""; for o in index-pattern/az-ip visualization/az-vis dashboard/az-dash; do [ "$(rq get GET "/api/saved_objects/$o")" = 200 ] || g="$g $o"; done
if [ -z "$g" ]; then pass "the 3 objects read back"; else fail "not read back:$g"; fi
want "the dashboard found" find 200 '"total":1' GET '/api/saved_objects/_find?type=dashboard&search_fields=title&search=az*'
x="$(curl -s -m 30 "$os/_cat/aliases/.kibana?h=alias,index" | tr -s ' ' | tr '\n' ';')"
case "$x" in *".kibana .kibana_"*) pass "the saved objects in OpenSearch: $x" ;; *) fail "the alias .kibana: $x" ;; esac
printf '%s\n' '{"type":"index-pattern","id":"az-proto","attributes":{"title":"x","__proto__":{"polluted":1}}}' > "$T/proto.ndjson"
c="$(curl -s -m 60 -o "$T/a/proto" -w '%{http_code}' -H 'osd-xsrf: t' -X POST "$k/api/saved_objects/_import" -F "file=@$T/proto.ndjson")"
if [ "$c" = 400 ] && has proto '__proto__'; then pass "an import with __proto__ refused: 400 (#12085)"; else fail "an import with __proto__: $c $(ans proto)"; fi

# --- reporting: CSV and XLSX of a saved search, made by the server ----------------------------
want "a saved search made" search 200 '"title":"az search"' POST /api/saved_objects/search/az-search \
    "{\"attributes\":{\"title\":\"az search\",\"columns\":[\"title\",\"n\"],\"sort\":[[\"t\",\"desc\"]],\"kibanaSavedObjectMeta\":{\"searchSourceJSON\":\"$SS\"}},\"references\":[{\"name\":\"kibanaSavedObjectMeta.searchSourceJSON.index\",\"type\":\"index-pattern\",\"id\":\"az-ip\"}]}"
for fmt in csv xlsx; do
    printf '%s' "{\"query_url\":\"/app/data-explorer/discover#/view/az-search\",\"time_from\":1794441600000,\"time_to\":1794528000000,\"report_definition\":{\"report_params\":{\"report_name\":\"az $fmt\",\"report_source\":\"Saved search\",\"description\":\"azsupport\",\"core_params\":{\"base_url\":\"/app/data-explorer/discover#/view/az-search\",\"saved_search_id\":\"az-search\",\"report_format\":\"$fmt\",\"time_duration\":\"PT24H\",\"origin\":\"http://127.0.0.1:5601\",\"limit\":10000,\"excel\":true}},\"delivery\":{\"configIds\":[],\"title\":\"\",\"textDescription\":\"\",\"htmlDescription\":\"\"},\"trigger\":{\"trigger_type\":\"On demand\"}}}" > "$T/report-$fmt.json"
    c="$(rq "report-$fmt" POST '/api/reporting/generateReport?timezone=UTC&dateFormat=YYYY-MM-DD&csvSeparator=,&allowLeadingWildcards=true' "@$T/report-$fmt.json")"
    if [ "$fmt" = csv ]; then
        if [ "$c" = 200 ] && has report-csv 'doc 3 of azsupport'; then pass "reporting: the CSV of the saved search, by the server"; else fail "reporting CSV: $c $(ans report-csv)"; fi
    else
        if [ "$c" = 200 ] && grep -q -E '"data":"(data:[^"]*base64,)?UEsDB' "$T/a/report-xlsx"; then pass "reporting: the XLSX of the saved search (a zip), by the server"; else fail "reporting XLSX: $c $(ans report-xlsx)"; fi
    fi
done

# --- the security fixes over HTTP -------------------------------------------------------------
c="$(curl -s -m 10 -o /dev/null -w '%{http_code} %{redirect_url}' "$k//example.com/")"
case "$c" in 404*) pass "//example.com/: 404, not redirected off-site (#12193)" ;; *) fail "//example.com/: $c" ;; esac
# (a path of no route with a / at its end: the redirect of src/legacy/server/http that
# #12193 fixes; /app/<id>/ is a route of its own, 200)
c="$(curl -s -m 10 -o /dev/null -w '%{http_code} %{redirect_url}' "$k/az-redirect/")"
case "$c" in 30[12]*"/az-redirect") pass "/az-redirect/: still redirected to /az-redirect" ;; *) fail "/az-redirect/: $c" ;; esac
"$node" -e 'console.log(JSON.stringify({ applications: Array.from({ length: 1001 }, (_, i) => "a" + i) }))' > "$T/caps1001.json"
"$node" -e 'console.log(JSON.stringify({ applications: ["x".repeat(257)] }))' > "$T/caps257.json"
"$node" -e 'console.log(JSON.stringify({ applications: Array.from({ length: 1000 }, (_, i) => "app" + i) }))' > "$T/caps1000.json"
c1="$(rq caps1 POST /api/core/capabilities "@$T/caps1001.json")"; c2="$(rq caps2 POST /api/core/capabilities "@$T/caps257.json")"
t0="$(date +%s)"; c3="$(rq caps3 POST /api/core/capabilities "@$T/caps1000.json")"; t1="$(date +%s)"
if [ "$c1" = 400 ] && [ "$c2" = 400 ] && [ "$c3" = 200 ] && [ $((t1 - t0)) -le 2 ] && has caps3 '"navLinks"'; then
    pass "POST /api/core/capabilities: 1001 applications 400, a name of 257 characters 400, 1000 applications 200 in $((t1 - t0)) s (CVE-2026-75897)"
else
    fail "POST /api/core/capabilities: $c1 $c2 $c3 in $((t1 - t0)) s"
fi
printf -- '--a\r\n\r\n--a--\r\n' > "$T/dup.bin"
c="$(curl -s -m 30 -o "$T/a/dup" -w '%{http_code}' -H 'osd-xsrf: t' -H 'Content-Type: multipart/form-data; boundary=a; boundary=b' -X POST "$k/api/saved_objects/_import" --data-binary "@$T/dup.bin")"
if [ "$c" = 400 ]; then pass "a Content-Type with two boundaries: 400 (@hapi/content 6.0.3)"; else fail "a Content-Type with two boundaries: $c $(ans dup)"; fi
"$node" -e 'process.stdout.write("--b\r\nContent-Disposition: form-data; " + "a".repeat(200000) + "\r\n\r\nx\r\n--b--\r\n")' > "$T/disp.bin"
t0="$(date +%s)"; c="$(curl -s -m 30 -o "$T/a/disp" -w '%{http_code}' -H 'osd-xsrf: t' -H 'Content-Type: multipart/form-data; boundary=b' -X POST "$k/api/saved_objects/_import" --data-binary "@$T/disp.bin")"; t1="$(date +%s)"
if [ "$c" != 000 ] && [ $((t1 - t0)) -le 3 ]; then pass "a Content-Disposition of 200000 characters: $c in $((t1 - t0)) s (@hapi/content 6.0.3)"; else fail "a Content-Disposition of 200000 characters: $c in $((t1 - t0)) s"; fi
# the fixes of 3.x that both ports take (files/patch-*)
"$node" -e 'console.log(JSON.stringify({ typesToInclude: Array.from({ length: 101 }, (_, i) => "t" + i) }))' > "$T/sc101.json"
"$node" -e 'console.log(JSON.stringify({ typesToInclude: Array.from({ length: 100 }, (_, i) => i ? "t" + i : "dashboard") }))' > "$T/sc100.json"
c1="$(rq sc101 POST /api/opensearch-dashboards/management/saved_objects/scroll/counts "@$T/sc101.json")"
c2="$(rq sc100 POST /api/opensearch-dashboards/management/saved_objects/scroll/counts "@$T/sc100.json")"
if [ "$c1" = 400 ] && has sc101 'cannot be greater than [100]' && [ "$c2" = 200 ] && has sc100 '"dashboard":1'; then
    pass "the counts of saved objects: 101 types 400, 100 types 200 (#12191)"
else
    fail "the counts of saved objects: 101 types $c1 $(ans sc101); 100 types $c2 $(ans sc100)"
fi
gzip -c "$T/export.ndjson" > "$T/export.ndjson.gz"
c1="$(curl -s -m 30 -o "$T/a/gz1" -w '%{http_code}' -H 'osd-xsrf: t' -H 'Content-Type: application/octet-stream' -H 'Content-Encoding: gzip' -X POST "$k/api/saved_objects/_import" --data-binary "@$T/export.ndjson.gz")"
c2="$(curl -s -m 30 -o "$T/a/gz2" -w '%{http_code}' -H 'osd-xsrf: t' -H 'Content-Encoding: gzip' -X POST "$k/api/saved_objects/_resolve_import_errors" -F "file=@$T/export.ndjson" -F 'retries=[]')"
if [ "$c1" = 400 ] && has gz1 'Content-Encoding is not supported' && [ "$c2" = 400 ] && has gz2 'Content-Encoding is not supported'; then
    pass "a Content-Encoding on _import and _resolve_import_errors: 400 (#12189)"
else
    fail "a Content-Encoding on the routes of the import: _import $c1 $(ans gz1); _resolve_import_errors $c2 $(ans gz2)"
fi
# (.es() chained after .es(): a series of its own, that of its q, with the label
# after it; one series)
TL='"time":{"from":"2026-11-12T00:00:00Z","to":"2026-11-13T00:00:00Z","interval":"1h","timezone":"UTC"}'
c="$(rq tlchain POST /api/timeline/run "{\"sheet\":[\".es(index=az-test*, timefield=t).es(index=az-test*, timefield=t, q=n:1).label(second)\"],$TL}")"
if [ "$c" = 200 ] && has tlchain '"label":"second","split":"n:1"' && [ "$(grep -o '"type":"series"' "$T/a/tlchain" | wc -l | tr -d ' ')" = 1 ]; then
    pass "Timeline: .es() chained after .es() makes a series of its own (#12217)"
else
    fail "Timeline: .es() chained after .es(): $c $(ans tlchain)"
fi

# --- the core: console, Timeline, TSVB, sample data, requests at once --------------------------
# (the console asks OpenSearch with pretty=true, but parses its JSON answer and gives
# it back compact: stringify of @osd/std, src/plugins/console/server/routes/api/console/proxy)
want "the console: GET _cluster/health" console 200 '"cluster_name":"az-test"' POST '/api/console/proxy?path=_cluster%2Fhealth&method=GET' ''
TL='"time":{"from":"2026-11-12T00:00:00Z","to":"2026-11-13T00:00:00Z","interval":"1h","timezone":"UTC"}'
want "Timeline: .es().label() with a regular expression" timeline 200 '"label":"x ' POST /api/timeline/run \
    "{\"sheet\":[\".es(index=az-test*, timefield=t).label(\\\"x \$1\\\", \\\"(.*)\\\")\"],$TL}"
# (its answer: "p1":{"annotations":null,"id":"p1","series":[...]}; the value of the
# series is that of its last metric, the math: 2 for each hour with one document)
c="$(rq tsvb POST /api/metrics/vis/data \
    '{"timerange":{"timezone":"UTC","min":"2026-11-12T00:00:00Z","max":"2026-11-13T00:00:00Z"},"filters":[],"panels":[{"id":"p1","type":"timeseries","series":[{"id":"s1","split_mode":"everything","metrics":[{"id":"m1","type":"count"},{"id":"m2","type":"math","variables":[{"id":"v1","name":"a","field":"m1"}],"script":"params.a * 2"}],"seperate_axis":0,"axis_position":"right","formatter":"number","chart_type":"line"}],"time_field":"t","index_pattern":"az-test*","interval":"1h","axis_position":"left","axis_formatter":"number"}]}')"
if [ "$c" = 200 ] && has tsvb '"id":"p1","series":[{"id":"s1"' && grep -q ',2\]' "$T/a/tsvb"; then pass "TSVB: a count and a math metric (tinymath): 2 for each hour with a document"; else fail "TSVB: a count and a math metric: $c $(ans tsvb)"; fi
c="$(rq sample POST /api/sample_data/flights '')"
curl -s -m 30 -o /dev/null -X POST "$os/opensearch_dashboards_sample_data_flights/_refresh"
n="$(curl -s -m 30 "$os/opensearch_dashboards_sample_data_flights/_count" | sed -n 's/.*"count":\([0-9]*\).*/\1/p')"
if [ "$c" = 200 ] && [ "${n:-0}" -gt 10000 ]; then pass "the sample data flights installed: $n documents"; else fail "the sample data flights: $c $(ans sample), ${n:-no} documents"; fi
c="$(rq sample-remove DELETE /api/sample_data/flights)"
n="$(curl -s -m 30 -o /dev/null -w '%{http_code}' "$os/opensearch_dashboards_sample_data_flights")"
[ "$c" = 204 ] || [ "$c" = 200 ] && [ "$n" = 404 ] && pass "the sample data flights removed" || fail "the sample data flights removed: $c, its index $n"
pids=""
i=1
while [ "$i" -le 40 ]; do
    curl -s -m 60 -o "$T/m/c$i" -w '%{http_code}' -H 'osd-xsrf: t' -X POST "$k/api/console/proxy?path=az-test%2F_search%3Fsize%3D$((i % 3 + 1))&method=GET" > "$T/m/s$i" 2>/dev/null &
    pids="$pids $!"
    curl -s -m 60 -o "$T/m/g$i" -w '%{http_code}' "$k/api/saved_objects/dashboard/az-dash" > "$T/m/t$i" 2>/dev/null &
    pids="$pids $!"
    i=$((i + 1))
done
# shellcheck disable=SC2086
wait $pids
g=0
i=1
while [ "$i" -le 40 ]; do
    [ "$(cat "$T/m/s$i")" = 200 ] && grep -q '"doc ' "$T/m/c$i" && g=$((g + 1))
    [ "$(cat "$T/m/t$i")" = 200 ] && grep -q '"az dashboard"' "$T/m/g$i" && g=$((g + 1))
    i=$((i + 1))
done
if [ "$g" = 80 ]; then pass "80 requests at once (40 searches through the console, 40 saved objects): every answer right"; else fail "80 requests at once: $g right"; fi

# --- reload, newsyslog, the log, the stop ------------------------------------------------------
mv "$T/osd.log" "$T/osd.log.0"
install -o www -g www -m 640 /dev/null "$T/osd.log"
(cd / && "$rc" onereload > "$T/reload.out" 2>&1); r=$?
sleep 2
rq status GET /api/status > /dev/null
sleep 1
# (the response of that request is written by the logging of the legacy server, which
# opens its file again only with the reconfigure() of good fixed)
if [ "$r" = 0 ] && grep -q '"type":"response".*/api/status' "$T/osd.log"; then
    pass "rc.d/opensearch-dashboards onereload: the new log file is written, the responses too"
else
    fail "rc.d/opensearch-dashboards onereload: exit $r, $(tail -n 1 "$T/reload.out"), the new log: $(wc -c < "$T/osd.log" | tr -d ' ') bytes, $(grep -c '"type":"response"' "$T/osd.log") responses"
fi
cat "$T/osd.log" >> "$T/osd.log.0"; mv "$T/osd.log.0" "$T/osd.log"
cp "$T/osd.log" "$T/osd-before-rotation.log"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$T/osd.log" www:www 640 0 1 '*' B "$pidfile" 1 > "$T/newsyslog.conf"
newsyslog -F -f "$T/newsyslog.conf" > "$T/newsyslog.out" 2>&1; r=$?
sleep 2
rq status GET /api/status > /dev/null
sleep 1
x="$(ls "$T" | grep '^osd\.log\.' | tr '\n' ' ')"
if [ "$r" = 0 ] && [ -z "$x" ] && grep -q '"type":"response".*/api/status' "$T/osd.log" && [ "$(wc -c < "$T/osd.log")" -lt "$(wc -c < "$T/osd-before-rotation.log")" ]; then
    pass "newsyslog -F with count 0: the log rolled, no archive kept, the new file written after its SIGHUP, the responses too"
else
    fail "newsyslog: exit $r, archives: ${x:-none}, the log $(wc -c < "$T/osd.log" | tr -d ' ') bytes; $(head -n 1 "$T/newsyslog.out")"
fi
cat "$T/osd.log" >> "$T/osd-before-rotation.log"; mv "$T/osd-before-rotation.log" "$T/osd.log"
if grep -E '"type":"error"|"tags":\[[^]]*"(error|fatal)"' "$T/osd.log" > "$T/err.txt" 2>/dev/null; then
    fail "$(wc -l < "$T/err.txt" | tr -d ' ') errors in its log: $(head -n 2 "$T/err.txt" | cut -c1-240 | tr '\n' ' ')"
    cp "$T/err.txt" "$res/osd-errors.txt"
else
    pass "no errors in its log"
fi
w="$(grep -c '"tags":\[[^]]*"warning"' "$T/osd.log" 2>/dev/null)"
[ "${w:-0}" = 0 ] || note "its log has $w warnings: $(grep '"tags":\[[^]]*"warning"' "$T/osd.log" | sed 's/.*"message":"\([^"]*\)".*/\1/' | sort -u | head -n 3 | cut -c1-160 | tr '\n' ' ')"
stop_osd
x="$(ls -A /tmp | sort | comm -13 "$T/tmp-before.txt" - | tr '\n' ' ')"
if [ -z "$x" ]; then pass "nothing left in /tmp"; else fail "left in /tmp: $x"; fi
x="$(find "$D" -newer "$T/marker" ! -path "$D/data" ! -path "$D/data/*" | head -n 5 | tr '\n' ' ')"
if [ -z "$x" ]; then pass "nothing written in the package but data/ ($(ls "$D/data" | tr '\n' ' '))"; else fail "written in the package: $x"; fi
stop_os
finish
