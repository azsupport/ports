#!/bin/sh
# opensearch-test.sh - test OpenSearch of the repository az, installed from it: the
# one of opensearch217 (2.17.1; aZ, 12.11.2026: for a legacy project) and
# opensearch219 (2.19.7; aZ, 12.11.2026: the bridge of his cluster of 2.17.1 to
# 3.x) that is installed (the same files: one of the two), on the OpenJDK its
# package depends on, started by its rc script, as a server starts it, on
# 127.0.0.1:19201 with a data and log directory of the test, then with the
# opensearch.yml of aZ's node ko44, and last once more for a query_string nested
# too deep:
#   - the package: lib/jna.jar a link to the jna.jar of devel/jna, a whole zip; the
#     plugins of the port (the 19 of aZ's cluster that run on FreeBSD, and
#     opensearch-ltr of the bundle of 2.19) and none of the four it leaves out (no
#     opensearch-security, its tools and demo certificates; no opensearch-knn,
#     -neural-search, -performance-analyzer); the netty of
#     modules/transport-netty4 that of the bundle (2.17.1: 4.1.112.Final, 2.19.7:
#     4.1.139.Final), no other netty but that of the client of opensearch-ml;
#     opensearch-ml without the two jars of the native code of its local models
#     (onnxruntime_gpu, tokenizers: aZ, 12.11.2026), its size and that of the
#     package; the paths of opensearch.yml.sample /var/db/opensearch and
#     /var/log/opensearch; 2.19: the prepackaged rules of
#     opensearch-security-analytics in
#     /usr/local/etc/opensearch/opensearch-security-analytics, which it reads from
#     the directory of the configuration (copied into those of this test, as
#     pkg-message says for a profile with its own);
#   - its tools run by hand as root, without JAVA_HOME (bin/opensearch-env takes the
#     JDK of the port) and without OPENSEARCH_TMPDIR (opensearch-keystore,
#     -plugin, -node, -shard, opensearch -V): each does its job and leaves nothing in
#     /tmp (no hsperfdata_<user>, no opensearch-<number>) but the /tmp/opensearch
#     that bin/opensearch makes for its user, and which it refuses when it is
#     another user's; opensearch-plugin install of an official plugin of this
#     version from a file (analysis-icu, fetched from artifacts.opensearch.org):
#     installed, listed, removed, and nothing of it left in /tmp;
#   - the rc script refuses a start with a setting of the security plugin in
#     opensearch.yml (plugins.security.disabled: true, as aZ's nodes have, and the
#     nested form plugins: / security:), names the lines, and starts nothing;
#   - the start: its version, that of the package, and the JVM it runs on (the
#     OpenJDK the package depends on, the default of its rc script); the heap from
#     opensearch_heap of rc.conf
#     (512m here) over the -Xms and -Xmx of jvm.options, a wrong opensearch_heap
#     refused; the options of jvm.options in the running JVM (no heap dump,
#     -XX:+ExitOnOutOfMemoryError, no GC log, -XX:+PerfDisableSharedMem); JNA from
#     the file of devel/jna (-Djna.boot.library.path=/usr/local/lib/jna,
#     -Djna.nounpack=true): the running OpenSearch (the pid of the pidfile of its
#     rc script) maps /usr/local/lib/jna/libjnidispatch.so and the libffi of az
#     (procstat -v), no jna* in /tmp/opensearch; its system call filter
#     (RLIMIT_NPROC of the process set to 0, which FreeBSD makes its least, 1) and
#     the memory lock that aZ's servers have on (bootstrap.memory_lock: true):
#     mlockall true; the plugins it loaded (_cat/plugins) those of the port; the
#     start says nothing of System::setSecurityManager (the four lines of JDK 17
#     and 21 are taken out), nor, on JDK 21, of the incubator module
#     jdk.incubator.vector or the COMPAT locale provider (taken out too), and no
#     warning of the JVM; on JDK 21 Lucene's lines in its log (MMapDirectory on
#     MemorySegment, the vector API once it uses vectors); no [ERROR] in its log;
#   - the health of the cluster, a document indexed and found; opensearch-ml
#     without native code: a connector of a remote model made (its credential
#     encrypted by the master key of the plugin), read and found; an index with the
#     codec zstd of opensearch-custom-codecs (zstd-jni on FreeBSD); HTTP with
#     Accept-Encoding gzip and zstd (2.17.1 hung on zstd on Linux: upstream #17408
#     of 2.19.1) and request bodies with Content-Encoding gzip and zstd (2.17.1
#     closes the connection, 2.19.7 answers, upstream #23324), each answered or
#     closed within 15 s with OpenSearch still up (what they leave in
#     /tmp/opensearch: a note); the builtin log types of
#     opensearch-security-analytics there (its
#     loader of 2.17.1 logs an [ERROR] at the start, upstream
#     security-analytics#1312: a note, not a failure); 2.19: its prepackaged rules
#     imported from the directory of the configuration
#     (rules/_search?pre_packaged=true), and opensearch-ltr: its feature store, a
#     feature set, and the value of its feature logged by an sltr query;
#   - nothing of OpenSearch in /tmp and /var/tmp from its start to its stop but its
#     temporary directory /tmp/opensearch (OPENSEARCH_TMPDIR of the rc script),
#     where only the named pipe of bash may be (nothing of JNA); no GC log; the log
#     files of the tarball alone in path.logs, none rolled, also after a rollover
#     forced by a size of 2 KB in a copy of log4j2.properties; nothing new in
#     /var/log/opensearch;
#   - stopped by its rc script;
#   - then the opensearch.yml of aZ's node ko44 (12.11.2026) as one node: refused
#     with its line plugins.security.disabled: true, started without it (its legacy
#     settings node.master, node.data, node.ingest, cluster.remote.connect,
#     reindex.remote.whitelist, its ports 8200 and 8300, network.host 0.0.0.0,
#     which makes the bootstrap checks errors, path.data /var/db/opensearch and
#     path.logs /var/log/opensearch, which the rc script makes; discovery.seed_hosts
#     and cluster.initial_master_nodes of this node alone in place of its IPs and
#     ko38; its directory owned by opensearch, as the ETCDIR of the package, where
#     OpenSearch makes its keystore): health, the role of the node, the deprecation
#     warnings it logs (a note each; the settings deprecated those expected:
#     cluster.initial_master_nodes, cluster.remote.connect, node.data, node.ingest,
#     node.master, reindex.remote.whitelist, and the role master of node.master),
#     no [ERROR] but that of opensearch-security-analytics 2.17.1; the settings of his
#     cluster (aZ, 12.11.2026: those of index-management and query-insights,
#     with a key of no use that 2.17.1 took, persistent, and one transient)
#     taken, each there with its value, and no [ERROR] after them; stopped;
#   - last, in a start of its own (a node it kills spoils no other check): a
#     query_string whose parentheses nest 15000 deep (30015 characters, within the
#     32000 of search.query.max_query_string_length; as deep as upstream's test of
#     #22854), which overflows the stack of Lucene's parser: 2.19.7 rejects it
#     (search.query.max_query_nesting_depth, 200) and stays up, a check; 2.17.1 has
#     no such limit, and what it does (OpenSearch halts at a StackOverflowError,
#     exit 126) is a note, a known weakness of it (aZ, 12.11.2026: his sites give
#     the text of their visitors to query_string). Each in summary.txt.
#
# Usage (FreeBSD, as root, opensearch217 or opensearch219 installed):
#   sh tools/opensearch-test.sh
# Results: opensearch-results/tests.txt (one line per check, the summary at the end),
# the logs of OpenSearch next to it; exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/opensearch-results}"
T="${OPENSEARCH_TEST_WORK:-/var/tmp/opensearch-test}"
P=/usr/local
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"
out="$res/tests.txt"
: > "$out"
# what it found that the line of tools/test-programs.sh shows (up to 3 lines)
sum="$res/summary.txt"
: > "$sum"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
rc="$P/etc/rc.d/opensearch"
os="http://127.0.0.1:19201"
# get <path>: the answer of OpenSearch, or nothing; send <method> <path> [<json>]
get() { fetch -q -o - "$os$1" 2>/dev/null; }
send() { curl -s -m 30 -H 'Content-Type: application/json' -X "$1" "$os$2" ${3:+-d "$3"} 2>/dev/null; }
# up <url> <seconds>: wait until OpenSearch answers there
up() { _i=0; while [ "$_i" -lt "$2" ]; do fetch -q -o - "$1/" 2>/dev/null | grep -q '"number"' && return 0; sleep 2; _i=$((_i + 2)); done; return 1; }

# the package installed, one of the two
pk=""
for p in opensearch217 opensearch219; do pkg info -e "$p" && pk="$pk $p"; done
pk="${pk# }"
# the plugins of the port, and those it leaves out; the netty of the bundle; the
# [ERROR] of the start that is a note (below); whether its query_string has the
# limit of nesting (the last check); whether its query-insights has exporters per
# metric (2.17: search.insights.top_queries.<metric>.exporter.*; 2.19 has one
# exporter of all, search.insights.top_queries.exporter.*)
plugins_in="opensearch-alerting opensearch-anomaly-detection opensearch-asynchronous-search opensearch-cross-cluster-replication opensearch-custom-codecs opensearch-flow-framework opensearch-geospatial opensearch-index-management opensearch-job-scheduler opensearch-ml opensearch-notifications opensearch-notifications-core opensearch-observability opensearch-reports-scheduler opensearch-security-analytics opensearch-skills opensearch-sql opensearch-system-templates query-insights"
plugins_out="opensearch-knn opensearch-neural-search opensearch-performance-analyzer opensearch-security"
case "$pk" in
    opensearch217) netty="4.1.112.Final"; known_err="Failed loading builtin log types from disk"; nesting=""; qi_metric=1 ;;
    opensearch219) netty="4.1.139.Final"; known_err=""; nesting=1; qi_metric=""; plugins_in="$plugins_in opensearch-ltr" ;;
    *)
        fail "not one of opensearch217 and opensearch219 installed: ${pk:-none}"
        echo "opensearch-test: $ok ok, $bad failed" >> "$out"
        exit 1 ;;
esac
pv="$(pkgv "$pk")"
# its JDK: the openjdk<N> its package depends on, the default of its rc script
jdk="$(pkg query '%dn' "$pk" | sed -n 's/^openjdk\([0-9][0-9]*\)$/\1/p' | head -n 1)"
if [ -z "$jdk" ]; then
    fail "$pk depends on no openjdk<N>: $(pkg query '%dn' "$pk" | tr '\n' ' ')"
    jdk=none
fi
# errs <log>: its lines of [ERROR] but the one that is a note
errs() { grep -E '\]\[ERROR\]' "$1" 2>/dev/null | if [ -n "$known_err" ]; then grep -v -e "$known_err"; else cat; fi; }
# the prepackaged rules of opensearch-security-analytics 2.19 (the package's, in
# its directory of the configuration): the rules and rule_categories.json
sar="$P/etc/opensearch/opensearch-security-analytics"
if [ "$pk" = opensearch219 ]; then
    nr_="$(find "$sar/rules" -type f 2>/dev/null | wc -l | tr -d ' ')"
    no_="$(find "$sar" -type f 2>/dev/null | grep -v -E "^$sar/rules/(.*\.yml|rule_categories\.json)\$" | head -n 3 | tr '\n' ' ')"
    if [ "$nr_" = 2327 ] && [ -z "$no_" ] && pkg which -q "$sar/rules/rule_categories.json" 2>/dev/null | grep -q "^$pk-"; then
        pass "the prepackaged rules of opensearch-security-analytics in $sar/rules: 2326 and rule_categories.json, files of $pk"
    else
        fail "the prepackaged rules of opensearch-security-analytics in $sar/rules: $nr_ files, not the 2327 of the bundle; other files: ${no_:-none}"
    fi
fi
# the package: its JDK, JNA, plugins, netty and paths
if grep -q "^: \${opensearch_java_home=\"/usr/local/openjdk$jdk\"}" "$rc"; then
    pass "rc.d/opensearch: opensearch_java_home /usr/local/openjdk$jdk by default"
else
    fail "rc.d/opensearch: opensearch_java_home is not /usr/local/openjdk$jdk by default: $(grep -m 1 'opensearch_java_home=' "$rc")"
fi
j="$P/lib/opensearch/lib/jna.jar"
l="$(readlink "$j")"
if [ "$l" = "$P/share/java/classes/jna.jar" ] && [ -f "$l" ] && unzip -tqq "$l" > /dev/null 2>&1; then
    pass "lib/jna.jar -> $l (devel/jna $(pkg query '%v' jna 2>/dev/null)), a whole zip"
else
    fail "lib/jna.jar: ${l:-not a link}$([ -n "$l" ] && [ ! -f "$l" ] && echo ', missing')$([ -f "$l" ] && ! unzip -tqq "$l" > /dev/null 2>&1 && echo ', not a whole zip')"
fi
if ls "$P"/lib/opensearch/lib/jna-*.jar > /dev/null 2>&1; then fail "another JNA in lib: $(ls "$P"/lib/opensearch/lib/jna-*.jar | tr '\n' ' ')"; fi
have="$(ls "$P/lib/opensearch/plugins" | LC_ALL=C sort | tr '\n' ' ')"
want="$(echo $plugins_in | tr ' ' '\n' | LC_ALL=C sort | tr '\n' ' ')"
o=""
for p in $plugins_out; do [ -e "$P/lib/opensearch/plugins/$p" ] || [ -e "$P/etc/opensearch/$p" ] && o="$o $p"; done
if [ "$have" = "$want" ] && [ -z "$o" ] && ! pkg info -l "$pk" | grep -q -i -e 'security/tools' -e 'demo' -e '\.pem$'; then
    pass "the plugins of the port ($(echo $plugins_in | wc -w | tr -d ' ')): $have; none of $plugins_out; no tools or certificates of the security plugin"
else
    fail "the plugins: $have; left out but there:${o:- none}; want: $want"
fi
n="$(cd "$P/lib/opensearch" && find . -name 'netty-*.jar' ! -path './plugins/opensearch-ml/*' | LC_ALL=C sort | tr '\n' ' ')"
nw="$(for a in netty-buffer netty-codec netty-codec-http netty-common netty-handler netty-resolver netty-transport netty-transport-native-unix-common; do printf './modules/transport-netty4/%s-%s.jar ' "$a" "$netty"; done)"
nm="$(cd "$P/lib/opensearch/plugins/opensearch-ml" 2>/dev/null && ls netty-*.jar | tr '\n' ' ')"
if [ "$n" = "$nw" ]; then pass "netty $netty of the bundle in modules/transport-netty4 (8 jars), no other netty but that of the client of opensearch-ml: $nm"; else fail "netty: $n"; fi
# opensearch-ml without the two jars of the native code of its local models
# (aZ, 12.11.2026: onnxruntime_gpu-1.16.3.jar and tokenizers-<the version of DJL>.jar)
ml="$P/lib/opensearch/plugins/opensearch-ml"
mj="$(ls "$ml" 2>/dev/null | grep -e '^onnxruntime_gpu' -e '^tokenizers-' | tr '\n' ' ')"
mk="$(du -sk "$ml" 2>/dev/null | awk '{ print $1 }')"
if [ -d "$ml" ] && [ -z "$mj" ] && [ "${mk:-999999}" -lt 102400 ]; then
    pass "opensearch-ml without onnxruntime_gpu and tokenizers: $(ls "$ml" | wc -l | tr -d ' ') files, $((mk / 1024)) MiB; the package $pk: $(pkg query '%sh' "$pk") installed"
else
    fail "opensearch-ml: ${mj:-the jars of the native code gone, but} $((${mk:-0} / 1024)) MiB"
fi
if [ "$(grep -v -e '^#' -e '^$' "$P/etc/opensearch/opensearch.yml.sample" | tr '\n' ' ')" = "path.data: /var/db/opensearch path.logs: /var/log/opensearch " ]; then
    pass "opensearch.yml.sample: path.data /var/db/opensearch, path.logs /var/log/opensearch, nothing else"
else
    fail "opensearch.yml.sample: $(grep -v -e '^#' -e '^$' "$P/etc/opensearch/opensearch.yml.sample" | tr '\n' ' ')"
fi
# a configuration of the test: that of the package, its own paths and port
conf="$T/conf"
mkdir -p "$conf" "$T/data" "$T/logs"
for f in opensearch.yml jvm.options log4j2.properties; do
    cp "$P/etc/opensearch/$f.sample" "$conf/$f" || fail "no $P/etc/opensearch/$f.sample"
done
for f in opensearch-notifications-core/notifications-core.yml opensearch-notifications/notifications.yml opensearch-observability/observability.yml opensearch-reports-scheduler/reports-scheduler.yml; do
    mkdir -p "$conf/${f%/*}"
    cp "$P/etc/opensearch/$f.sample" "$conf/$f" || fail "no $P/etc/opensearch/$f.sample"
done
[ "$pk" = opensearch219 ] && cp -Rp "$sar" "$conf/"
sed -i '' -e "s|^path.data: .*|path.data: $T/data|" -e "s|^path.logs: .*|path.logs: $T/logs|" "$conf/opensearch.yml"
{ echo "http.port: 19201"; echo "transport.port: 19301"; echo "network.host: 127.0.0.1"; echo "cluster.name: az-test"; echo "bootstrap.memory_lock: true"; } >> "$conf/opensearch.yml"

# the tools by hand, as root, before any start, without JAVA_HOME: what each
# leaves in /tmp
B="$P/lib/opensearch/bin"
rm -rf /tmp/hsperfdata_root /tmp/opensearch
ls -A /tmp | sort > "$T/tools-before.txt"
tool() { (cd / && env -u JAVA_HOME -u OPENSEARCH_JAVA_HOME -u OPENSEARCH_TMPDIR -u OPENSEARCH_JAVA_OPTS OPENSEARCH_PATH_CONF="$conf" "$B/$@") > "$T/tool.out" 2>&1 < /dev/null; }
said() { grep -v '^$' "$T/tool.out" | head -n 2 | cut -c1-150 | tr '\n' ' '; }
tool opensearch-keystore create; r=$?
if [ "$r" = 0 ] && [ -s "$conf/opensearch.keystore" ]; then pass "opensearch-keystore create without JAVA_HOME: $conf/opensearch.keystore"; else fail "opensearch-keystore create: exit $r, $(said)"; fi
tool opensearch-keystore list; r=$?
if [ "$r" = 0 ] && grep -q '^keystore\.seed$' "$T/tool.out"; then pass "opensearch-keystore list: keystore.seed"; else fail "opensearch-keystore list: exit $r, $(said)"; fi
tool opensearch-plugin list; r=$?
pl="$(LC_ALL=C sort "$T/tool.out" | tr '\n' ' ')"
if [ "$r" = 0 ] && [ "$pl" = "$want" ]; then pass "opensearch-plugin list: the plugins of the port"; else fail "opensearch-plugin list: exit $r, $(said)"; fi
tool opensearch-node --help; r=$?
if [ "$r" = 0 ] && grep -q -i 'cluster' "$T/tool.out"; then pass "opensearch-node --help"; else fail "opensearch-node --help: exit $r, $(said)"; fi
tool opensearch-shard --help; r=$?
if [ "$r" = 0 ] && grep -q -i 'shard' "$T/tool.out"; then pass "opensearch-shard --help"; else fail "opensearch-shard --help: exit $r, $(said)"; fi
n="$(ls -A /tmp | sort | comm -13 "$T/tools-before.txt" - | tr '\n' ' ')"
if [ -z "$n" ]; then pass "the tools left nothing in /tmp"; else fail "the tools left in /tmp: $n"; fi
# opensearch-plugin install from a file: it copies the zip into java.io.tmpdir,
# /tmp for the tools, and removes the copy itself; what stays in /tmp after the
# install and after the removal
pz="$T/analysis-icu-$pv.zip"
i=0
while [ "$i" -lt 3 ] && ! fetch -q -T 60 -o "$pz" "https://artifacts.opensearch.org/releases/plugins/analysis-icu/$pv/analysis-icu-$pv.zip" 2> "$T/fetch.err"; do i=$((i + 1)); sleep 10; done
if [ ! -s "$pz" ] || ! unzip -tqq "$pz" > /dev/null 2>&1; then
    fail "opensearch-plugin install: analysis-icu-$pv.zip not fetched from artifacts.opensearch.org: $(tail -n 1 "$T/fetch.err" 2>/dev/null)"
else
    tool opensearch-plugin install --batch "file://$pz"; r=$?
    n="$(ls -A /tmp | sort | comm -13 "$T/tools-before.txt" - | tr '\n' ' ')"
    (cd / && env -u JAVA_HOME OPENSEARCH_PATH_CONF="$conf" "$B/opensearch-plugin" list) > "$T/tool2.out" 2>&1 < /dev/null
    if [ "$r" = 0 ] && grep -q -x 'analysis-icu' "$T/tool2.out" && [ -d "$P/lib/opensearch/plugins/analysis-icu" ] && [ -z "$n" ]; then
        pass "opensearch-plugin install --batch file://analysis-icu-$pv.zip: installed and listed, nothing left in /tmp ($(wc -c < "$pz" | tr -d ' ') bytes of zip)"
    else
        fail "opensearch-plugin install: exit $r, $(said); listed: $(tr '\n' ' ' < "$T/tool2.out" | cut -c1-120); left in /tmp: ${n:-nothing}"
    fi
    tool opensearch-plugin remove analysis-icu; r=$?
    n="$(ls -A /tmp | sort | comm -13 "$T/tools-before.txt" - | tr '\n' ' ')"
    o="$(ls -A "$P/lib/opensearch/plugins" | LC_ALL=C sort | tr '\n' ' ')"
    if [ "$r" = 0 ] && [ "$o" = "$want" ] && [ -z "$n" ]; then
        pass "opensearch-plugin remove analysis-icu: the plugins of the port again, nothing left in /tmp"
    else
        fail "opensearch-plugin remove: exit $r, $(said); in plugins: $o; left in /tmp: ${n:-nothing}"
        rm -rf "$P/lib/opensearch/plugins/analysis-icu" "$P"/lib/opensearch/plugins/.removing-* "$P"/lib/opensearch/plugins/.installing-*
    fi
fi
# bin/opensearch by hand (its version, with a heap of its own: that of
# jvm.options is 31g): makes /tmp/opensearch for its user, and does not start
# in that of another user
(cd / && env -u JAVA_HOME -u OPENSEARCH_TMPDIR OPENSEARCH_PATH_CONF="$conf" OPENSEARCH_JAVA_OPTS="-Xms64m -Xmx64m" "$B/opensearch" -V) > "$T/tool.out" 2>&1 < /dev/null; r=$?
n="$(ls -A /tmp | sort | comm -13 "$T/tools-before.txt" - | tr '\n' ' ')"
if [ "$r" = 0 ] && grep -q "Version: $pv" "$T/tool.out" && [ "$n" = "opensearch " ] && [ "$(stat -f '%Su %Lp' /tmp/opensearch)" = "root 700" ]; then
    pass "bin/opensearch -V by hand as root without JAVA_HOME: $(said | cut -c1-80); new in /tmp: /tmp/opensearch alone, root 700"
else
    fail "bin/opensearch -V by hand: exit $r, $(said); new in /tmp: ${n:-nothing}; $(stat -f '%Su %Lp' /tmp/opensearch 2>&1)"
fi
chown -R opensearch:opensearch "$T"
(cd / && su -m opensearch -c "env -u OPENSEARCH_TMPDIR JAVA_HOME='$P/openjdk$jdk' OPENSEARCH_PATH_CONF='$conf' OPENSEARCH_JAVA_OPTS='-Xms64m -Xmx64m' '$B/opensearch' -V") > "$T/tool.out" 2>&1 < /dev/null; r=$?
if [ "$r" != 0 ] && grep -q 'is not a directory of the user opensearch' "$T/tool.out"; then
    pass "bin/opensearch by hand as opensearch with the /tmp/opensearch of root: refused"
else
    fail "bin/opensearch by hand as opensearch with the /tmp/opensearch of root: exit $r, $(said)"
fi

# the rc script refuses a setting of the security plugin: the line of aZ's nodes,
# then the nested form; nothing starts
refused() {
    # refused <name> <opensearch.yml lines>: a copy of the configuration of the
    # test with these lines at its end, started by the rc script
    rm -rf "$T/conf-sec"; cp -Rp "$conf" "$T/conf-sec"
    printf '%s\n' "$2" >> "$T/conf-sec/opensearch.yml"
    nl_="$(wc -l < "$T/conf-sec/opensearch.yml" | tr -d ' ')"
    opensearch_config="$T/conf-sec" opensearch_heap=512m "$rc" onestart > "$T/sec.out" 2>&1; r_=$?
    sleep 2
    if [ "$r_" != 0 ] && grep -q 'sets the security plugin, which this package does not have' "$T/sec.out" && grep -q '^not started$' "$T/sec.out" \
        && ! pgrep -U opensearch -f 'org.opensearch.bootstrap.OpenSearch' > /dev/null && [ ! -s /var/run/opensearch/opensearch.pid ]; then
        pass "rc.d/opensearch onestart with $1 in opensearch.yml: refused, nothing started: $(grep '^    line ' "$T/sec.out" | sed 's/^ *//' | tr '\n' ';' | sed 's/;$//') (the file has $nl_ lines)"
    else
        fail "rc.d/opensearch onestart with $1: exit $r_, $(head -n 3 "$T/sec.out" | cut -c1-200 | tr '\n' ' ')"
        "$rc" onestop > /dev/null 2>&1
    fi
}
refused "plugins.security.disabled: true" "plugins.security.disabled: true"
refused "the nested form plugins: / security:" "$(printf 'plugins:\n  index_state_management.enabled: true\n  security:\n    ssl.http.enabled: false')"

# the rc script, as rc.conf would set it up: its configuration directory is ours,
# the heap of this server 512m (jvm.options stays that of the package, 31g); it
# makes /tmp/opensearch anew, which is that of root now
export opensearch_config="$conf"
export opensearch_heap="4x"
if "$rc" onestart > "$T/badheap.out" 2>&1; then
    fail "rc.d/opensearch onestart with opensearch_heap=4x: started"
    "$rc" onestop > /dev/null 2>&1
elif grep -q 'opensearch_heap="4x" is not a size' "$T/badheap.out"; then
    pass "opensearch_heap=4x refused: $(head -n 1 "$T/badheap.out")"
else
    fail "opensearch_heap=4x: $(head -n 2 "$T/badheap.out" | tr '\n' ' ')"
fi
export opensearch_heap="512m"
rm -f /var/log/opensearch/gc.log*
# what the user opensearch has in /tmp and /var/tmp before the start (the
# directory of this test and its temporary directory apart)
tmpd=/tmp/opensearch
tmpls() { find -x /tmp /var/tmp \( -path "$T" -o -path "$tmpd" \) -prune -o -user opensearch -print 2>/dev/null | sort; }
rm -rf /tmp/hsperfdata_opensearch
tmpls > "$T/tmp-before.txt"
ls -A /var/log/opensearch 2>/dev/null | sort > "$T/varlog-before.txt"
tmpwhen=""
tmpmark() { n_="$(tmpls | comm -13 "$T/tmp-before.txt" - | tr '\n' ' ')"; [ -z "$n_" ] || tmpwhen="$tmpwhen [$1 $(date +%T): $n_]"; }
"$rc" onestart > "$T/start.out" 2>&1
r=$?
cp "$T/start.out" "$res/opensearch-start.out"
tmpmark "after onestart"
if [ "$r" = 0 ]; then pass "rc.d/opensearch onestart"; else fail "rc.d/opensearch onestart: exit $r, $(tail -n 2 "$T/start.out" | tr '\n' ' ')"; fi
upok=""
up "$os" 180 && upok=1
cp "$T/logs/az-test.log" "$res/opensearch.log" 2>/dev/null
if [ -z "$upok" ]; then
    fail "no answer on $os in 180 s: $(tail -n 3 "$T/logs/az-test.log" 2>/dev/null | cut -c1-200 | tr '\n' ' ')"
else
    a="$(get /)"
    v="$(printf '%s' "$a" | sed -n 's/.*"number" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
    if [ "$v" = "$pv" ]; then pass "version $v"; else fail "version $v, the package $pk is $pv"; fi
    j="$(get '/_nodes/_local/jvm?filter_path=**.jvm.version' | sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
    case "$j" in "$jdk".*) pass "the JVM: $j" ;; *) fail "the JVM: ${j:-not told}, not $jdk" ;; esac
    sj="$pk $v on the JVM ${j:-not told}"
    # the options of the running JVM, one per line, in their order
    get '/_nodes/_local/jvm?filter_path=**.jvm.input_arguments,**.jvm.mem.heap_max_in_bytes' > "$T/jvm.json"
    sed -e 's/.*"input_arguments" *: *\[//' -e 's/\].*//' "$T/jvm.json" | tr ',' '\n' | sed -e 's/^"//' -e 's/"$//' > "$T/args.txt"
    cp "$T/args.txt" "$res/opensearch-jvm-arguments.txt"
    hm="$(sed -n 's/.*"heap_max_in_bytes" *: *\([0-9]*\).*/\1/p' "$T/jvm.json")"
    if [ "$(grep '^-Xmx' "$T/args.txt" | tail -n 1)" = "-Xmx512m" ] && [ "$(grep '^-Xms' "$T/args.txt" | tail -n 1)" = "-Xms512m" ] && [ "${hm:-0}" -gt 400000000 ] && [ "${hm:-0}" -le 536870912 ]; then
        pass "the heap of opensearch_heap: -Xms512m -Xmx512m after the 31g of jvm.options, heap_max_in_bytes $hm"
    else
        fail "the heap: last $(grep '^-Xm[sx]' "$T/args.txt" | tail -n 2 | tr '\n' ' '), heap_max_in_bytes ${hm:-not told}, not the 512m of opensearch_heap"
    fi
    m=""
    for o in '-XX:+UseG1GC' '-XX:G1ReservePercent=25' '-XX:InitiatingHeapOccupancyPercent=30' '-XX:+ExitOnOutOfMemoryError' \
        '-XX:ErrorFile=/var/log/opensearch/hs_err_pid%p.log' '-XX:ReplayDataFile=/var/log/opensearch/replay_pid%p.log' \
        '-Dio.netty.noUnsafe=true' '-XX:+AlwaysPreTouch' '-XX:+PerfDisableSharedMem' "-Djava.io.tmpdir=$tmpd"; do
        grep -q -x -F -e "$o" "$T/args.txt" || m="$m $o"
    done
    if [ -z "$m" ] && ! grep -q -E 'HeapDump|Xlog|GCLog|PrintGC' "$T/args.txt"; then
        pass "the options of jvm.options in the JVM, java.io.tmpdir $tmpd; no heap dump, no GC log"
    else
        fail "the options of the JVM: missing:${m:- none}$(grep -E 'HeapDump|Xlog|GCLog|PrintGC' "$T/args.txt" | sed 's/^/, has /' | tr '\n' ' ')"
    fi
    # its temporary directory while it runs: of opensearch, 0700, at most the
    # named pipe of bash (JNA unpacks nothing there, -Djna.nounpack)
    td="$(stat -f '%Su %Lp' "$tmpd" 2>/dev/null)"
    o="$(find "$tmpd" -mindepth 1 ! -name 'sh-np.*' 2>/dev/null | head -n 5 | tr '\n' ' ')"
    if [ "$td" = "opensearch 700" ] && [ -z "$o" ]; then
        pass "$tmpd: $td; in it while OpenSearch runs: $(find "$tmpd" -mindepth 1 2>/dev/null | sed "s|^$tmpd/||" | tr '\n' ' ' | sed 's/ $//;s/^$/nothing/')"
    else
        fail "$tmpd: ${td:-missing}; in it not the pipe of bash: ${o:-nothing}"
    fi
    # JNA from the file of devel/jna: the options of jvm.options in the JVM (after
    # -Djna.nosys=true of the launcher), the file and the libffi of az mapped in
    # the process of the pidfile of the rc script (that of the API too), no jna* in
    # its temporary directory
    pid="$(cat /var/run/opensearch/opensearch.pid 2>/dev/null)"
    get '/_nodes/_local/process?filter_path=**.process.id,**.process.mlockall' > "$T/process.json"
    apid="$(sed -n 's/.*"id" *: *\([0-9]*\).*/\1/p' "$T/process.json")"
    mla="$(sed -n 's/.*"mlockall" *: *\([a-z]*\).*/\1/p' "$T/process.json")"
    procstat -v "${pid:-0}" > "$T/vm.txt" 2>&1
    cp "$T/vm.txt" "$res/opensearch-procstat-v.txt"
    jl="$(awk '$NF ~ /libjnidispatch/ { print $NF }' "$T/vm.txt" | sort -u | tr '\n' ' ')"
    fl="$(awk '$NF ~ /\/libffi\.so/ { print $NF }' "$T/vm.txt" | sort -u | tr '\n' ' ')"
    jt="$(find "$tmpd" -mindepth 1 -name 'jna*' 2>/dev/null | tr '\n' ' ')"
    ja="$(grep '^-Djna\.' "$T/args.txt" | tr '\n' ' ')"
    case "$fl" in "$P/az/lib/libffi.so"*) ffi=1 ;; *) ffi="" ;; esac
    if [ -n "$pid" ] && [ "$pid" = "$apid" ] && [ "$ja" = "-Djna.nosys=true -Djna.boot.library.path=$P/lib/jna -Djna.nounpack=true " ] \
        && [ "$jl" = "$P/lib/jna/libjnidispatch.so " ] && [ -n "$ffi" ] && [ "$fl" = "${fl%% *} " ] && [ -z "$jt" ]; then
        pass "JNA: ${ja}in the JVM; the process $pid maps ${jl}and ${fl}(procstat -v: opensearch-procstat-v.txt), no jna* in $tmpd"
    else
        fail "JNA: ${ja:-no -Djna options} in the JVM; the process ${pid:-of no pidfile} (the API: ${apid:-no id}) maps ${jl:-no libjnidispatch} and ${fl:-no libffi}; jna* in $tmpd: ${jt:-none}"
    fi
    # the native part of OpenSearch on FreeBSD, through JNA: its system call
    # filter, setrlimit(RLIMIT_NPROC) to 0 (SystemCallFilter.bsdImpl), which the
    # kernel raises to its least, 1: no new process for the user opensearch
    nproc="$(procstat -l "${pid:-0}" 2>/dev/null | awk '$3 == "maxprocesses" { print $4, $5 }')"
    if [ "$nproc" = "1 1" ]; then
        pass "the system call filter of OpenSearch through JNA: maxprocesses 1 1 of the process $pid (procstat -l: set to 0)"
    else
        fail "the system call filter: maxprocesses ${nproc:-not told} of the process ${pid:-of no pidfile}, not 1 1 (RLIMIT_NPROC set to 0)"
    fi
    # bootstrap.memory_lock: true, as on aZ's servers: mlockall(MCL_CURRENT) through
    # JNA, allowed by the login class root of the rc script and vm.max_user_wired
    ml="$(procstat -l "${pid:-0}" 2>/dev/null | awk '$3 == "memorylocked" { print $4, $5 }')"
    if [ "$mla" = true ] && ! grep -q -i 'Unable to lock JVM Memory' "$T/logs/az-test.log"; then
        pass "bootstrap.memory_lock: mlockall true, no \"Unable to lock JVM Memory\" in the log (memorylocked ${ml:-not told} of the process, vm.max_user_wired $(sysctl -n vm.max_user_wired 2>/dev/null) pages)"
    else
        fail "bootstrap.memory_lock: mlockall ${mla:-not told}; memorylocked ${ml:-not told}; $(grep -i -m 1 -A 1 'Unable to lock JVM' "$T/logs/az-test.log" | cut -c1-200 | tr '\n' ' ')"
    fi
    # the plugins OpenSearch loaded
    cp="$(get '/_cat/plugins?h=component' | sed 's/[[:space:]]*$//' | LC_ALL=C sort | tr '\n' ' ')"
    if [ "$cp" = "$want" ]; then pass "_cat/plugins: the plugins of the port loaded"; else fail "_cat/plugins: ${cp:-no answer}"; fi
    h="$(get '/_cluster/health?wait_for_status=yellow&timeout=60s' | sed -n 's/.*"status" *: *"\([^"]*\)".*/\1/p')"
    case "$h" in green|yellow) pass "cluster health: $h" ;; *) fail "cluster health: ${h:-no answer}" ;; esac
    send PUT /az-test '{ "settings": { "number_of_shards": 1, "number_of_replicas": 0 } }' > "$T/i.out"
    send PUT '/az-test/_doc/1?refresh=true' '{ "title": "opensearch of azsupport", "n": 42 }' > "$T/d.out"
    s="$(send GET /az-test/_search '{ "query": { "match": { "title": "azsupport" } } }')"
    case "$s" in *'"total":{"value":1'*) pass "a document indexed and found" ;;
        *) fail "the search: $(printf '%s' "$s" | cut -c1-200) (index: $(cut -c1-120 "$T/i.out"), document: $(cut -c1-120 "$T/d.out"))" ;; esac
    # opensearch-ml without native code: a connector of a remote model (to the
    # API of OpenAI, never called; an endpoint ML Commons trusts by default), kept
    # with its credential encrypted by the master key of the plugin, read and
    # found again
    mc="$(send POST /_plugins/_ml/connectors/_create '{ "name": "az-test", "description": "a connector of the test of azsupport, never called", "version": 1, "protocol": "http", "parameters": { "model": "text-embedding-3-small" }, "credential": { "openAI_key": "not-a-key" }, "actions": [ { "action_type": "predict", "method": "POST", "url": "https://api.openai.com/v1/embeddings", "headers": { "Authorization": "Bearer ${credential.openAI_key}" }, "request_body": "{ \"input\": ${parameters.input}, \"model\": \"${parameters.model}\" }", "pre_process_function": "connector.pre_process.openai.embedding", "post_process_function": "connector.post_process.openai.embedding" } ] }')"
    mcid="$(printf '%s' "$mc" | sed -n 's/.*"connector_id" *: *"\([^"]*\)".*/\1/p')"
    mg="$(get "/_plugins/_ml/connectors/${mcid:-none}")"
    msn="$(send POST /_plugins/_ml/connectors/_search '{ "query": { "match": { "name": "az-test" } } }' | sed -n 's/.*"total" *: *{ *"value" *: *\([0-9]*\).*/\1/p')"
    if [ -n "$mcid" ] && printf '%s' "$mg" | grep -q '"name" *: *"az-test"' && [ "$msn" = 1 ]; then
        pass "opensearch-ml without native code: a connector of a remote model made ($mcid), read and found (_plugins/_ml/connectors)"
    else
        fail "opensearch-ml: the connector: $(printf '%s' "$mc" | cut -c1-200); read: $(printf '%s' "$mg" | cut -c1-120); found: ${msn:-no answer}"
    fi
    # HTTP compression of the netty of the port: the answers, gzip and zstd asked
    # for; request bodies in gzip and in zstd (garbage: an error, not a hang)
    hc() { curl -s -m 15 -o "$T/hc.body" -D "$T/hc.head" -w '%{http_code} %{time_total}' "$@" 2>/dev/null; }
    ce() { tr -d '\r' < "$T/hc.head" | awk -F': *' 'tolower($1) == "content-encoding" { print $2 }'; }
    w="$(hc -H 'Accept-Encoding: gzip' "$os/")"; e="$(ce)"
    if [ "${w%% *}" = 200 ] && [ "$e" = gzip ] && gzip -dc < "$T/hc.body" | grep -q '"number"'; then pass "Accept-Encoding: gzip: 200 in ${w#* } s, gzip"; else fail "Accept-Encoding: gzip: ${w:-no answer in 15 s}, Content-Encoding ${e:-none}"; fi
    w="$(hc -H 'Accept-Encoding: zstd' "$os/")"; e="$(ce)"
    if [ "${w%% *}" = 200 ]; then pass "Accept-Encoding: zstd: 200 in ${w#* } s, Content-Encoding ${e:-none}"; else fail "Accept-Encoding: zstd: ${w:-no answer in 15 s (upstream #17408 of 2.19.1: the encoder of zstd hangs)}, Content-Encoding ${e:-none}"; fi
    printf '{ "query": { "match": { "title": "azsupport" } } }' | gzip > "$T/q.gz"
    w="$(hc -H 'Content-Type: application/json' -H 'Content-Encoding: gzip' --data-binary @"$T/q.gz" "$os/az-test/_search")"
    if [ "${w%% *}" = 200 ] && grep -q '"total":{"value":1' "$T/hc.body"; then pass "a request body in gzip: 200 in ${w#* } s, the document found"; else fail "a request body in gzip: ${w:-no answer in 15 s}, $(cut -c1-160 "$T/hc.body" 2>/dev/null)"; fi
    # 2.17.1 closes the connection without an answer, 2.19.7 passes the body on
    # as it is and answers that it is no JSON (upstream #23324): no hang and no
    # harm to the node is what is checked here
    w="$(printf 'not zstd at all' | hc -H 'Content-Type: application/json' -H 'Content-Encoding: zstd' --data-binary @- "$os/az-test/_search")"
    t_="${w#* }"; t_="${t_%%.*}"
    if [ -n "$w" ] && [ "${w%% *}" != 200 ] && [ "${t_:-99}" -lt 15 ] && get / | grep -q '"number"'; then
        pass "a request body in zstd that is not: $([ "${w%% *}" = 000 ] && echo 'the connection closed without an answer' || echo "${w%% *}") in ${w#* } s, OpenSearch still answers"
    else
        fail "a request body in zstd that is not: ${w:-no answer in 15 s}; OpenSearch answers after it: $(get / | grep -c '"number"')"
    fi
    note "$tmpd after the requests of HTTP compression: $(find "$tmpd" -mindepth 1 2>/dev/null | sed "s|^$tmpd/||" | tr '\n' ' ' | sed 's/ $//;s/^$/nothing/')"
    # opensearch-custom-codecs: an index with its codec zstd (zstd-jni of the
    # server, its library for FreeBSD)
    send PUT /az-zstd '{ "settings": { "number_of_shards": 1, "number_of_replicas": 0, "codec": "zstd" } }' > "$T/z.out"
    send PUT '/az-zstd/_doc/1?refresh=true' '{ "title": "zstd of azsupport", "n": 7 }' > "$T/zd.out"
    send POST /az-zstd/_flush > /dev/null
    s="$(send GET /az-zstd/_search '{ "query": { "match": { "title": "zstd" } } }')"
    c="$(get '/az-zstd/_settings?filter_path=**.codec' | sed -n 's/.*"codec" *: *"\([^"]*\)".*/\1/p')"
    case "$s" in *'"total":{"value":1'*)
        [ "$c" = zstd ] && pass "an index with \"codec\": \"zstd\" (opensearch-custom-codecs): created, a document indexed, flushed and found" ||
            fail "the index with the codec zstd: its codec is ${c:-not told}" ;;
        *) fail "the index with the codec zstd: $(cut -c1-200 "$T/z.out"); the document: $(cut -c1-120 "$T/zd.out"); the search: $(printf '%s' "$s" | cut -c1-160)" ;; esac
    note "$tmpd after the index with the codec zstd: $(find "$tmpd" -mindepth 1 2>/dev/null | sed "s|^$tmpd/||" | tr '\n' ' ' | sed 's/ $//;s/^$/nothing/')"
    # JDK 21: Lucene on it, by the lines it logs (the log of the start, or its
    # stderr): MMapDirectory on MemorySegment, which every index opens; the vector
    # API of jdk.incubator.vector (the 20-: line of jvm.options), which Lucene
    # takes up at its first use of vectors, and no word of it being unusable
    if [ "$jdk" = 21 ]; then
        lm="$(cat "$T/logs/az-test.log" "$T/start.out" 2>/dev/null | grep -o 'Using MemorySegmentIndexInput[^;"]*' | head -n 1)"
        lv="$(cat "$T/logs/az-test.log" "$T/start.out" 2>/dev/null | grep -o 'Java vector incubator API enabled[^"]*' | head -n 1)"
        lw="$(cat "$T/logs/az-test.log" "$T/start.out" 2>/dev/null | grep -i -E 'incubator module is not readable|vector.*(can.t be enabled|disabled)|MMapDirectory.*(not|unavailable|cannot)' | head -n 1 | cut -c1-200)"
        if [ -n "$lm" ] && [ -z "$lw" ]; then
            pass "Lucene on JDK 21: \"$lm\"; the vector API: ${lv:-no line yet (no vectors used)}"
        else
            fail "Lucene on JDK 21: MMapDirectory: ${lm:-no line of MemorySegmentIndexInput}; ${lw:-the vector API: ${lv:-no line}} ($(grep -h -i -E 'vectoriz|MemorySegment|MMapDirectory|incubator' "$T/logs/az-test.log" "$T/start.out" 2>/dev/null | head -n 2 | sed -e 's/^[^]]*\]//' | cut -c1-200 | tr '\n' ' '))"
        fi
        sj="$sj; Lucene: ${lm:-no MemorySegmentIndexInput}; ${lv:-no line of the vector API}"
    fi
    echo "$sj" >> "$sum"
    # opensearch-security-analytics: its builtin log types, which its loader of
    # 2.17.1 may fail to read at the start (upstream security-analytics#1312, the
    # [ERROR] "Failed loading builtin log types from disk!", on Linux and macOS too)
    lt=""; i=0
    while [ "$i" -lt 12 ]; do
        lt="$(send POST /_plugins/_security_analytics/logtype/_search '{ "size": 0, "query": { "match_all": {} } }' | sed -n 's/.*"total" *: *{ *"value" *: *\([0-9]*\).*/\1/p')"
        [ "${lt:-0}" -gt 0 ] && break
        sleep 5; i=$((i + 1))
    done
    if [ "${lt:-0}" -gt 0 ]; then
        pass "opensearch-security-analytics: its log types there ($lt, _plugins/_security_analytics/logtype/_search)"
    else
        fail "opensearch-security-analytics: no log types in 60 s ($(send POST /_plugins/_security_analytics/logtype/_search '{ "size": 0, "query": { "match_all": {} } }' | cut -c1-160))"
    fi
    if [ "$pk" = opensearch219 ]; then
        # its prepackaged rules: imported at the first search of them from
        # <the directory of the configuration>/opensearch-security-analytics/rules
        # (RuleIndices.importRules of 2.19), a copy of the package's here
        a_="$(curl -s -m 180 -H 'Content-Type: application/json' -X POST "$os/_plugins/_security_analytics/rules/_search?pre_packaged=true" -d '{ "size": 0, "query": { "match_all": {} } }' 2>/dev/null)"
        nr_="$(printf '%s' "$a_" | sed -n 's/.*"total" *: *{ *"value" *: *\([0-9]*\).*/\1/p')"
        if [ "${nr_:-0}" -gt 1000 ]; then
            pass "opensearch-security-analytics: $nr_ prepackaged rules imported from $conf/opensearch-security-analytics/rules (rules/_search?pre_packaged=true)"
        else
            fail "opensearch-security-analytics: its prepackaged rules: ${nr_:-none} ($(printf '%s' "$a_" | cut -c1-200))"
        fi
        # opensearch-ltr (Learning to Rank): its default feature store, a feature
        # set with a template of Mustache, and the value of its feature logged by
        # an sltr query for the document of the test
        st_="$(send PUT /_ltr)"
        fs_="$(send POST /_ltr/_featureset/az_fs '{ "featureset": { "features": [ { "name": "title_match", "params": [ "keywords" ], "template_language": "mustache", "template": { "match": { "title": "{{keywords}}" } } } ] } }')"
        lg_="$(send POST /az-test/_search '{ "query": { "bool": { "filter": [ { "terms": { "_id": [ "1" ] } }, { "sltr": { "_name": "logged_featureset", "featureset": "az_fs", "params": { "keywords": "azsupport" } } } ] } }, "ext": { "ltr_log": { "log_specs": { "name": "log_entry1", "named_query": "logged_featureset" } } } }')"
        fv_="$(printf '%s' "$lg_" | tr '{}' '\n\n' | grep '"title_match"' | sed -n 's/.*"value" *: *\([0-9.Ee+-]*\).*/\1/p' | head -n 1)"
        if printf '%s' "$st_" | grep -q '"acknowledged" *: *true' && printf '%s' "$fs_" | grep -q '"result" *: *"created"' \
            && [ -n "$fv_" ] && awk -v v="$fv_" 'BEGIN { exit !(v + 0 > 0) }'; then
            pass "opensearch-ltr: the feature store .ltrstore, the feature set az_fs, its feature title_match logged by an sltr query: $fv_"
        else
            fail "opensearch-ltr: the store: $(printf '%s' "$st_" | cut -c1-100); the feature set: $(printf '%s' "$fs_" | cut -c1-100); the logged search: $(printf '%s' "$lg_" | cut -c1-200)"
        fi
    fi
fi
cp "$T/start.out" "$res/opensearch-start.out"
if grep -q 'setSecurityManager' "$T/start.out"; then
    fail "the start printed the warning of JDK $jdk about setSecurityManager: $(grep -m 1 'setSecurityManager' "$T/start.out")"
else
    pass "the start without the warning of JDK $jdk about setSecurityManager"
fi
# JDK 21: the line of the incubator module of jvm.options, and the two of the
# COMPAT locale provider of the launcher, taken out too
if [ "$jdk" = 21 ]; then
    if grep -E 'jdk\.incubator\.vector|COMPAT locale provider|LocaleProviderAdapter' "$T/start.out" > "$T/jdk21.txt"; then
        fail "the start printed the warnings of JDK 21 of the bundle's options: $(head -n 2 "$T/jdk21.txt" | cut -c1-160 | tr '\n' ' ')"
    else
        pass "the start without the warnings of JDK 21 about jdk.incubator.vector and the COMPAT locale provider"
    fi
fi
if grep -i -E 'warning|deprecated|unrecognized|ignoring option' "$T/start.out" > "$T/warn.txt"; then
    fail "the start printed $(wc -l < "$T/warn.txt" | tr -d ' ') warnings: $(head -n 2 "$T/warn.txt" | cut -c1-200 | tr '\n' ' ')"
else
    pass "the start without a warning of the JVM ($(wc -l < "$T/start.out" | tr -d ' ') lines: opensearch-start.out)"
fi
cp "$T/logs/az-test.log" "$res/opensearch.log" 2>/dev/null
# the [ERROR] of the loader of log types of opensearch-security-analytics 2.17.1
# (above) is the plugin's, a note
if [ -n "$known_err" ] && grep -q "$known_err" "$T/logs/az-test.log" 2>/dev/null; then
    note "opensearch-security-analytics 2.17.1 logged its [ERROR] \"Failed loading builtin log types from disk!\" (FileSystemNotFoundException of an unused Paths.get, upstream security-analytics#1312; gone in 2.18)"
fi
if errs "$T/logs/az-test.log" > "$T/err.txt" && [ -s "$T/err.txt" ]; then
    fail "the log of the start has $(wc -l < "$T/err.txt" | tr -d ' ') lines of [ERROR]: $(head -n 2 "$T/err.txt" | sed -e 's/^[^]]*\]//' | cut -c1-300 | tr '\n' ' ')"
else
    pass "the log of the start without [ERROR]"
fi
if grep -E -i 'jna (not found|is not available)|unable to load jna|cannot load jna|native methods.* will be disabled|unable to link C library|syscall filter|system call filters failed' "$T/logs/az-test.log" > "$T/jna.txt" 2>/dev/null; then
    fail "JNA: $(head -n 2 "$T/jna.txt" | cut -c1-200 | tr '\n' ' ')"
else
    pass "JNA: nothing of JNA failing in the log (its library, the C library, the system call filter)"
fi
w="$(grep -c '\]\[WARN \]' "$T/logs/az-test.log" 2>/dev/null)"
[ "${w:-0}" = 0 ] || note "the log has $w warnings (opensearch.log): $(grep '\]\[WARN \]' "$T/logs/az-test.log" | head -n 4 | sed -e 's/^[^]]*\]//' | cut -c1-200 | tr '\n' ' ')"
tmpmark "before onestop"
"$rc" onestop > "$T/stop.out" 2>&1
r=$?
if [ "$r" = 0 ] && ! get / > /dev/null; then pass "rc.d/opensearch onestop"; else fail "rc.d/opensearch onestop: exit $r, $(tail -n 1 "$T/stop.out")"; fi
# after the stop: nothing of OpenSearch new in /tmp and /var/tmp, no GC log
tmpls > "$T/tmp-after.txt"
n="$(comm -13 "$T/tmp-before.txt" "$T/tmp-after.txt")"
if [ -z "$n" ]; then
    pass "nothing of the user opensearch new in /tmp and /var/tmp after start, requests and stop but $tmpd ($(find "$tmpd" -mindepth 1 2>/dev/null | sed "s|^$tmpd/||" | tr '\n' ' ' | sed 's/ $//;s/^$/empty/'))"
else
    fail "new in /tmp and /var/tmp: $(printf '%s' "$n" | head -n 6 | tr '\n' ' ');$tmpwhen"
fi
g="$(ls /var/log/opensearch/gc.log* "$T"/logs/gc.log* "$P"/lib/opensearch/logs/gc.log* "$tmpd"/gc.log* 2>/dev/null | tr '\n' ' ')"
if [ -z "$g" ]; then pass "no GC log"; else fail "a GC log: $g"; fi
# the logs (path.logs of this test): the files of the tarball's log4j2.properties,
# none rolled; then a start with every size of rollover at 2 KB: the server logs
# roll many times, and the rolled files are deleted
logs_check() {
    l="$(ls -A "$T/logs" 2>/dev/null | grep -v -x -E 'az-test(_server\.json|\.log|_deprecation\.(json|log)|_index_search_slowlog\.(json|log)|_index_indexing_slowlog\.(json|log)|_task_detailslog\.(json|log))' | tr '\n' ' ')"
    if [ -z "$l" ] && [ -f "$T/logs/az-test.log" ] && [ -f "$T/logs/az-test_server.json" ]; then
        pass "path.logs $1: the log files alone, none rolled: $(ls -A "$T/logs" | tr '\n' ' ')($(wc -c < "$T/logs/az-test.log" | tr -d ' ') bytes of az-test.log)"
    else
        fail "path.logs $1: ${l:-no az-test.log or az-test_server.json}"
    fi
}
logs_check "after start, requests and stop"
n0="$(grep -c 'starting \.\.\.' "$T/logs/az-test.log")"
sed -i '' -E 's|^(appender\.[a-z0-9_]+\.policies\.size\.size) = .*|\1 = 2KB|' "$conf/log4j2.properties"
if [ "$(grep -c '^appender\.[a-z0-9_]*\.policies\.size\.size = 2KB$' "$conf/log4j2.properties")" = 12 ] && "$rc" onestart > "$T/start2.out" 2>&1; then
    up "$os" 180; u=$?
    "$rc" onestop > /dev/null 2>&1
    sleep 2
    s="$(wc -c < "$T/logs/az-test.log" | tr -d ' ')"
    if [ "$u" = 0 ] && [ "$s" -lt 20000 ] && [ "$(grep -c 'starting \.\.\.' "$T/logs/az-test.log")" -le "$n0" ]; then
        logs_check "after a start with the rollover at 2 KB (az-test.log began anew)"
    else
        fail "the rollover at 2 KB: az-test.log has $s bytes, up: $u: not rolled"
    fi
else
    fail "the start with the rollover at 2 KB: $(tail -n 2 "$T/start2.out" 2>/dev/null | tr '\n' ' ')"
fi
ls -A /var/log/opensearch 2>/dev/null | sort > "$T/varlog-after.txt"
n="$(comm -13 "$T/varlog-before.txt" "$T/varlog-after.txt" | tr '\n' ' ')"
if [ -z "$n" ]; then pass "nothing new in /var/log/opensearch"; else fail "new in /var/log/opensearch: $n"; fi

# the opensearch.yml of aZ's node ko44 (12.11.2026), one node here: its IPs and
# the initial master ko38 replaced by this node; with its line of the security
# plugin refused, without it started on the paths of the package
k="$T/ko44"
rm -rf "$k"; mkdir -p "$k"
for f in jvm.options log4j2.properties; do cp "$P/etc/opensearch/$f.sample" "$k/$f"; done
[ "$pk" = opensearch219 ] && cp -Rp "$sar" "$k/"
cat > "$k/opensearch.yml" << 'EOF'
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
plugins.security.disabled: true
cluster.initial_master_nodes: ["ko44"]
reindex.remote.whitelist: "localhost:*"
EOF
# owned by opensearch, as the ETCDIR of the package: OpenSearch makes its keystore
# there at its first start
chown -R opensearch:opensearch "$k"
ko="http://127.0.0.1:8200"
export opensearch_config="$k"
"$rc" onestart > "$T/ko44-sec.out" 2>&1; r=$?
sleep 2
if [ "$r" != 0 ] && grep -q '^    line 21: plugins.security.disabled: true$' "$T/ko44-sec.out" && ! fetch -q -o - "$ko/" > /dev/null 2>&1; then
    pass "ko44: refused with its plugins.security.disabled: true (line 21 named), nothing started"
else
    fail "ko44 with plugins.security.disabled: true: exit $r, $(head -n 3 "$T/ko44-sec.out" | cut -c1-200 | tr '\n' ' ')"
    "$rc" onestop > /dev/null 2>&1
fi
sed -i '' '/^plugins\.security\.disabled: true$/d' "$k/opensearch.yml"
rm -rf /var/db/opensearch /var/log/opensearch
"$rc" onestart > "$T/ko44-start.out" 2>&1; r=$?
cp "$T/ko44-start.out" "$res/ko44-start.out"
if [ "$r" = 0 ] && up "$ko" 180; then
    pass "ko44 without that line: started on 0.0.0.0:8200 (its bootstrap checks errors), $(fetch -q -o - "$ko/" | sed -n 's/.*"number" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
    # a node of the cluster manager alone (node.data: false): the system indices
    # the plugins make at its start have no data node to go to, so the health is
    # red here; on aZ's cluster his data nodes hold them
    h="$(fetch -q -o - "$ko/_cluster/health?timeout=30s" 2>/dev/null | sed -n 's/.*"status" *: *"\([^"]*\)".*/\1/p')"
    nr="$(fetch -q -o - "$ko/_cat/nodes?h=name,node.role,cluster_manager" 2>/dev/null | tr -s ' ' | sed 's/ $//' | tr '\n' ';')"
    ix="$(fetch -q -o - "$ko/_cat/indices?h=health,index&expand_wildcards=all" 2>/dev/null | tr -s ' ' | sed 's/ $//' | sort | tr '\n' ';')"
    if [ "$nr" = "ko44 m *;" ]; then
        pass "ko44: the elected cluster manager, roles m alone (node.master: true, node.data: false, node.ingest: false); health ${h:-not told}, the indices: ${ix:-none}"
    else
        fail "ko44: the node: ${nr:-no answer} (not ko44 m *); health ${h:-not told}"
    fi
    d1="$(stat -f '%Su:%Sg %Lp' /var/db/opensearch 2>/dev/null)"; d2="$(stat -f '%Su:%Sg %Lp' /var/log/opensearch 2>/dev/null)"
    if [ "$d1" = "opensearch:opensearch 755" ] && [ "$d2" = "opensearch:opensearch 755" ] && [ -f /var/log/opensearch/ko44.log ] && [ -d /var/db/opensearch/nodes ]; then
        pass "ko44: /var/db/opensearch and /var/log/opensearch made by the rc script ($d1), its data and log there"
    else
        fail "ko44: /var/db/opensearch $d1, /var/log/opensearch $d2: $(ls /var/log/opensearch 2>/dev/null | tr '\n' ' ')"
    fi
else
    fail "ko44 without that line: exit $r, $(grep -v -E '^[[:space:]]+at |^[[:space:]]*\.\.\. [0-9]+ more' "$T/ko44-start.out" | grep -E 'Exception|Error|error|failed|unknown|illegal|check' | head -n 3 | cut -c1-220 | tr '\n' ' '); its log: $(grep -E '\]\[(ERROR|WARN ?)\]' /var/log/opensearch/ko44.log 2>/dev/null | tail -n 2 | sed -e 's/^[^]]*\]//' | cut -c1-220 | tr '\n' ' ')"
fi
cp /var/log/opensearch/ko44.log "$res/ko44.log" 2>/dev/null
cp /var/log/opensearch/ko44_deprecation.log "$res/ko44_deprecation.log" 2>/dev/null
# its deprecation warnings (the log of deprecation): the settings of his file
# that 2.17 and 2.19 deprecate, and nothing else; a note each
dw="$(sed -n 's/^\[[^]]*\]\[DEPRECATION\]\[[^]]*\] *\[[^]]*\] *//p' /var/log/opensearch/ko44_deprecation.log 2>/dev/null | sort -u)"
printf '%s\n' "$dw" | grep -v '^$' | while read -r w; do note "ko44 deprecation: $(printf '%s' "$w" | cut -c1-300)"; done
dk="$(printf '%s\n' "$dw" | sed -n 's/^\[\([a-z_.]*\)\] setting was deprecated .*/\1/p' | sort -u | tr '\n' ' ')"
do_="$(printf '%s\n' "$dw" | grep -v -e '^$' -e '^\[[a-z_.]*\] setting was deprecated ' -e '^Assigning \[master\] role in setting \[node\.roles\] is deprecated\. To promote inclusive language, please use \[cluster_manager\] role instead\.$' | cut -c1-90 | tr '\n' '|')"
if [ "$dk" = "cluster.initial_master_nodes cluster.remote.connect node.data node.ingest node.master reindex.remote.whitelist " ] && [ -z "$do_" ]; then
    pass "ko44: deprecated, as expected: $dk"
else
    fail "ko44: the deprecated settings: ${dk:-none}; other deprecations: ${do_:-none}"
fi
if errs /var/log/opensearch/ko44.log > "$T/ko44-err.txt" && [ -s "$T/ko44-err.txt" ]; then
    fail "ko44: its log has $(wc -l < "$T/ko44-err.txt" | tr -d ' ') lines of [ERROR]: $(head -n 2 "$T/ko44-err.txt" | sed -e 's/^[^]]*\]//' | cut -c1-300 | tr '\n' ' ')"
else
    pass "ko44: its log without [ERROR]"
fi
w="$(grep -c '\]\[WARN \]' /var/log/opensearch/ko44.log 2>/dev/null)"
[ "${w:-0}" = 0 ] || note "ko44: its log has $w warnings: $(grep '\]\[WARN \]' /var/log/opensearch/ko44.log | head -n 4 | sed -e 's/^[^]]*\]//' | cut -c1-200 | tr '\n' ' ')"
# the settings of aZ's cluster (12.11.2026: those of ko44), persistent and
# transient, exactly as he has them. 2.17.1 takes them all, each there with its
# value (_cluster/settings, flat), the key of no use
# search.insights.top_queries.cpu.exporter.asd too. 2.19 has no exporters of
# query-insights per metric (search.insights.top_queries.<metric>.exporter.*, one
# exporter of all instead): each of those five keys refused as not recognized,
# all of them together refused, and the other eight with the transient one
# taken, each there with its value. No [ERROR] after them
cat > "$T/ko44-cluster-settings.json" << 'END'
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
END
# the eight that 2.19 knows, with the transient one
grep -v -E '"search\.insights\.top_queries\.(cpu|latency)\.exporter\.' "$T/ko44-cluster-settings.json" > "$T/ko44-cluster-settings-known.json"
putset() { curl -s -m 30 -H 'Content-Type: application/json' -X PUT "$ko/_cluster/settings" --data-binary "$1" 2>/dev/null; }
ne="$(grep -c -E '\]\[ERROR\]' /var/log/opensearch/ko44.log 2>/dev/null)"
cs="$(putset @"$T/ko44-cluster-settings.json")"
cs2=""; ek=""; eo=""
if [ -z "$qi_metric" ]; then
    # each exporter key per metric alone, with the value aZ has
    for kv in "search.insights.top_queries.cpu.exporter.config.index|\"'top-cpu-'YYYY\"" 'search.insights.top_queries.cpu.exporter.enabled|false' \
        'search.insights.top_queries.cpu.exporter.asd|false' "search.insights.top_queries.latency.exporter.config.index|\"'top-latensy-'YYYY\"" \
        'search.insights.top_queries.latency.exporter.enabled|false'; do
        k_="${kv%%|*}"; v_="${kv#*|}"
        a_="$(putset "{ \"persistent\": { \"$k_\": $v_ } }")"
        if printf '%s' "$a_" | grep -q "persistent setting \[$k_\], not recognized"; then ek="$ek ${k_#search.insights.top_queries.}"; else eo="$eo $k_: $(printf '%s' "$a_" | cut -c1-80);"; fi
    done
    cs2="$(putset @"$T/ko44-cluster-settings-known.json")"
fi
sleep 2
cg="$(fetch -q -o - "$ko/_cluster/settings?flat_settings=true" 2>/dev/null)"
cp_="$(printf '%s' "$cg" | sed -n 's/.*"persistent" *: *{\([^}]*\)}.*/\1/p')"
ct_="$(printf '%s' "$cg" | sed -n 's/.*"transient" *: *{\([^}]*\)}.*/\1/p')"
cm=""; cx=""
for kv in '"cluster.routing.allocation.enable":"all"' '"plugins.index_state_management.metadata_migration.status":"1"' \
    '"plugins.index_state_management.template_migration.control":"-1"' '"search.insights.top_queries.cpu.enabled":"false"' \
    '"search.insights.top_queries.latency.enabled":"false"' "\"search.insights.top_queries.cpu.exporter.config.index\":\"'top-cpu-'YYYY\"" \
    '"search.insights.top_queries.cpu.exporter.enabled":"false"' '"search.insights.top_queries.cpu.exporter.asd":"false"' \
    "\"search.insights.top_queries.latency.exporter.config.index\":\"'top-latensy-'YYYY\"" '"search.insights.top_queries.latency.exporter.enabled":"false"' \
    '"search.insights.top_queries.group_by":"none"' '"search.insights.top_queries.max_groups_excluding_topn":"100"' '"search.query.metrics.enabled":"false"'; do
    case "$kv" in
        *.exporter.*)
            if [ -n "$qi_metric" ]; then
                case "$cp_" in *"$kv"*) ;; *) cm="$cm persistent $kv;" ;; esac
            else
                case "$cp_" in *"${kv%%:*}"*) cx="$cx $kv;" ;; esac
            fi ;;
        *) case "$cp_" in *"$kv"*) ;; *) cm="$cm persistent $kv;" ;; esac ;;
    esac
done
case "$ct_" in *'"cluster.routing.allocation.enable":"all"'*) ;; *) cm="$cm transient cluster.routing.allocation.enable;" ;; esac
ne2="$(grep -c -E '\]\[ERROR\]' /var/log/opensearch/ko44.log 2>/dev/null)"
if [ -n "$qi_metric" ]; then
    if printf '%s' "$cs" | grep -q '"acknowledged" *: *true' && [ -z "$cm" ] && [ "${ne2:-0}" = "${ne:-0}" ]; then
        pass "ko44: the settings of aZ's cluster taken, the 13 persistent (search.insights.top_queries.cpu.exporter.asd too) and the transient one, each there with its value, no [ERROR] after them"
    else
        fail "ko44: the settings of aZ's cluster: $(printf '%s' "$cs" | cut -c1-200); not there:${cm:- none}; [ERROR] after them: $((${ne2:-0} - ${ne:-0})) ($(grep -E '\]\[ERROR\]' /var/log/opensearch/ko44.log 2>/dev/null | tail -n 1 | sed -e 's/^[^]]*\]//' | cut -c1-200))"
    fi
else
    nk="$(printf '%s' "$cs" | sed -n 's/.*persistent setting \[\([^]]*\)\], not recognized.*/\1/p' | head -n 1)"
    if [ -n "$nk" ] && [ "$(echo $ek | wc -w | tr -d ' ')" = 5 ] && [ -z "$eo" ] && printf '%s' "$cs2" | grep -q '"acknowledged" *: *true' \
        && [ -z "$cm" ] && [ -z "$cx" ] && [ "${ne2:-0}" = "${ne:-0}" ]; then
        pass "ko44: the settings of aZ's cluster as $pv has them: all of them refused (persistent setting [$nk], not recognized), each of the five exporters per metric of query-insights refused alone as not recognized ($ek), the other 8 persistent and the transient one taken, each there with its value; no [ERROR] after them"
    else
        fail "ko44: the settings of aZ's cluster: all of them: $(printf '%s' "$cs" | cut -c1-160); the exporters per metric refused alone:${ek:- none}, otherwise:${eo:- none}; the other 8: $(printf '%s' "$cs2" | cut -c1-120); not there:${cm:- none}; exporters per metric there:${cx:- none}; [ERROR] after them: $((${ne2:-0} - ${ne:-0}))"
    fi
    echo "aZ's settings on a new cluster of $pv: the 5 exporters per metric of query-insights refused, each not recognized ($ek); the other 8 and the transient one taken" >> "$sum"
fi
"$rc" onestop > "$T/ko44-stop.out" 2>&1; r=$?
if [ "$r" = 0 ] && ! fetch -q -o - "$ko/" > /dev/null 2>&1; then pass "ko44: rc.d/opensearch onestop"; else fail "ko44: rc.d/opensearch onestop: exit $r, $(tail -n 1 "$T/ko44-stop.out")"; fi

# last, in a start of its own, so that a node it kills spoils no other check: a
# query_string whose parentheses nest 15000 deep, as in upstream's test of
# #22854 (30015 characters, within the 32000 of
# search.query.max_query_string_length), on the index of the test once its shard
# is up. The classic query parser of Lucene recurses at each parenthesis and
# overflows the stack of its thread (-Xss1m), and OpenSearch halts at a
# StackOverflowError (OpenSearchUncaughtExceptionHandler: exit 126). 2.19.7
# rejects it before the parser (search.query.max_query_nesting_depth, 200): the
# check is the node up after it, no fatal error in its log, and the query
# refused, with the reason of its shard shown; 2.17.1 has no such limit, and what
# it does is a note, a known weakness of it (aZ, 12.11.2026: his sites give the
# text of their visitors to query_string)
export opensearch_config="$conf"
cp "$P/etc/opensearch/log4j2.properties.sample" "$conf/log4j2.properties"
nl0="$(wc -l < "$T/logs/az-test.log" 2>/dev/null | tr -d ' ')"
"$rc" onestart > "$T/nest-start.out" 2>&1; r=$?
if [ "$r" != 0 ] || ! up "$os" 180; then
    fail "query_string nested 15000 deep: the node of the test did not start again: exit $r, $(tail -n 2 "$T/nest-start.out" | cut -c1-200 | tr '\n' ' ')"
    echo "query_string nested 15000 deep: not tried, the node did not start" >> "$sum"
    "$rc" onestop > /dev/null 2>&1
else
    npid="$(cat /var/run/opensearch/opensearch.pid 2>/dev/null)"
    # its shard started first (a search before it answers 503, all shards failed)
    nh="$(curl -s -m 90 "$os/_cluster/health/az-test?wait_for_status=yellow&timeout=60s" 2>/dev/null | sed -n 's/.*"status" *: *"\([^"]*\)".*/\1/p')"
    awk 'BEGIN { printf "{ \"query\": { \"query_string\": { \"query\": \""; for (i = 0; i < 15000; i++) printf "("; printf "title:azsupport"; for (i = 0; i < 15000; i++) printf ")"; printf "\" } } }\n" }' > "$T/nest.json"
    w="$(curl -s -m 60 -o "$T/nest.body" -w '%{http_code} %{time_total}' -H 'Content-Type: application/json' --data-binary @"$T/nest.json" "$os/az-test/_search" 2>/dev/null)"
    sleep 5
    alive=""
    [ -n "$npid" ] && kill -0 "$npid" 2>/dev/null && get / | grep -q '"number"' && alive=1
    tail -n +"$((${nl0:-0} + 1))" "$T/logs/az-test.log" > "$T/nest.log" 2>/dev/null
    cp "$T/nest.log" "$res/opensearch-nesting.log"
    # the reason: that of the limit of nesting, else the deepest one the answer
    # gives (caused_by of the shard), else its first
    why="$(grep -o 'Query string parenthesis nesting depth exceeds max allowed depth [0-9]* ([a-z_.]*); actual depth: [0-9]*' "$T/nest.body" 2>/dev/null | head -n 1)"
    [ -n "$why" ] || why="$(grep -o '"reason" *: *"[^"]\{0,160\}' "$T/nest.body" 2>/dev/null | tail -n 1 | sed 's/^"reason" *: *"//')"
    soe="$(grep -E -m 1 'fatal error in thread|StackOverflowError' "$T/nest.log" | sed -e 's/^[^]]*\]\[[^]]*\]\[[^]]*\] *//' | cut -c1-160)"
    if [ -n "$alive" ] && [ -z "$soe" ] && [ -n "$w" ] && [ "${w%% *}" != 200 ] && [ "${w%% *}" != 000 ]; then
        what="refused with HTTP ${w%% *} in ${w#* } s (\"${why:-no reason told}\"), the node up, no fatal error in its log"
    elif [ -z "$alive" ]; then
        what="the node halted (HTTP ${w%% *} after ${w#* } s; its log: ${soe:-no word of it})"
    else
        what="HTTP ${w%% *} in ${w#* } s, the node up (az-test ${nh:-not told}): ${why:-no reason told}; ${soe:-no fatal error in its log}"
    fi
    if [ -n "$nesting" ]; then
        case "$what" in refused*) pass "query_string nested 15000 deep (30015 characters): $what" ;;
            *) fail "query_string nested 15000 deep (30015 characters): $what" ;; esac
    else
        note "query_string nested 15000 deep (30015 characters), a known weakness of $pv, which has no limit of nesting (2.19.7 has, upstream #22854): $what"
    fi
    echo "query_string nested 15000 deep: $pv $what" >> "$sum"
    if [ -n "$alive" ]; then
        "$rc" onestop > "$T/nest-stop.out" 2>&1 || fail "query_string nested 15000 deep: rc.d/opensearch onestop: $(tail -n 1 "$T/nest-stop.out")"
    else
        rm -f /var/run/opensearch/opensearch.pid
    fi
fi
pkill -U opensearch -f 'org.opensearch.bootstrap.OpenSearch' 2>/dev/null

echo "opensearch-test: $ok ok, $bad failed" >> "$out"
[ "$bad" = 0 ]
