#!/bin/sh
# elastic-test.sh - test Elasticsearch 6 of the repository az, installed from it (aZ,
# 11.11.2026: for the legacy sites): elasticsearch6 started by its rc script, as a
# server starts it, on 127.0.0.1:9200 with a data and log directory of the test:
#   - its version 6.8.23 and the JVM it runs on (OpenJDK 17 of the ports, the default
#     of its rc script: no elasticsearch_java_home in rc.conf);
#   - lib/jna.jar a link to the jna.jar of devel/jna, which is a whole zip;
#   - JNA loads its native library from the file of devel/jna (jvm.options:
#     -Djna.boot.library.path=/usr/local/lib/jna, -Djna.nounpack=true, no
#     -Djna.nosys; aZ, 12.11.2026): the running Elasticsearch (the pid of the
#     pidfile of its rc script) maps /usr/local/lib/jna/libjnidispatch.so and the
#     libffi of az (procstat -v), no jna* in its /tmp/elasticsearch, nothing of JNA
#     failing in its log, and its native part on FreeBSD works through it: the
#     system call filter, RLIMIT_NPROC of the process set to 0, which FreeBSD makes
#     its least, 1 (procstat -l; memory lock, bootstrap.memory_lock, is not turned
#     on here);
#   - the start says nothing of System::setSecurityManager (the four lines of JDK 17
#     are taken out), and its log has no JNA that failed (the JNA it bundles);
#   - its tools run by hand as root, without ES_TMPDIR (elasticsearch-keystore,
#     -plugin, -certutil, -shard, -croneval, -sql-cli, elasticsearch -V): each does
#     its job and leaves nothing in /tmp (no hsperfdata_<user>, no
#     elasticsearch-<number>) but the /tmp/elasticsearch that bin/elasticsearch
#     makes for its user, and which it refuses when it is another user's;
#   - the heap from elasticsearch_heap of rc.conf (512m here) over the -Xms and
#     -Xmx of jvm.options; the options of jvm.options for OpenJDK 17 in the running JVM
#     (no -XX:UseAVX, no heap dump, -XX:+ExitOnOutOfMemoryError, -Dlog4j2.formatMsgNoLookups);
#     no warning of the JVM at the start; no GC log; nothing of Elasticsearch in
#     /tmp and /var/tmp from its start to its stop but its temporary directory
#     /tmp/elasticsearch (ES_TMPDIR of the rc script), where only the named pipe
#     of bash may be (nothing of JNA); the log files of Elastic
#     alone in path.logs, none rolled, also after a rollover forced by a size of
#     2 KB in a copy of log4j2.properties; nothing new in /var/log/elasticsearch;
#     a wrong elasticsearch_heap refused; no [ERROR] in the log of the start
#     (xpack.ssl.cipher_suites of elasticsearch.yml: no unsupported ciphers);
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
# the tools by hand, as root, before any start: what each leaves in /tmp
B="$P/lib/elasticsearch/bin"
rm -rf /tmp/hsperfdata_root /tmp/elasticsearch
ls -A /tmp | sort > "$T/tools-before.txt"
tool() { (cd / && env -u ES_TMPDIR -u ES_JAVA_OPTS JAVA_HOME="$P/openjdk17" ES_PATH_CONF="$conf" "$B/$@") > "$T/tool.out" 2>&1 < /dev/null; }
said() { head -n 2 "$T/tool.out" | cut -c1-150 | tr '\n' ' '; }
tool elasticsearch-keystore create; r=$?
if [ "$r" = 0 ] && [ -s "$conf/elasticsearch.keystore" ]; then pass "elasticsearch-keystore create: $conf/elasticsearch.keystore"; else fail "elasticsearch-keystore create: exit $r, $(said)"; fi
tool elasticsearch-keystore list; r=$?
if [ "$r" = 0 ] && grep -q '^keystore\.seed$' "$T/tool.out"; then pass "elasticsearch-keystore list: keystore.seed"; else fail "elasticsearch-keystore list: exit $r, $(said)"; fi
tool elasticsearch-plugin list; r=$?
if [ "$r" = 0 ]; then pass "elasticsearch-plugin list: no plugin ($(wc -l < "$T/tool.out" | tr -d ' ') lines)"; else fail "elasticsearch-plugin list: exit $r, $(said)"; fi
tool elasticsearch-certutil --help; r=$?
if [ "$r" = 0 ] && grep -q -i 'certificate' "$T/tool.out"; then pass "elasticsearch-certutil --help"; else fail "elasticsearch-certutil --help: exit $r, $(said)"; fi
tool elasticsearch-shard --help; r=$?
if [ "$r" = 0 ] && grep -q -i 'shard' "$T/tool.out"; then pass "elasticsearch-shard --help"; else fail "elasticsearch-shard --help: exit $r, $(said)"; fi
tool elasticsearch-croneval '0 0 12 * * ?' -c 1; r=$?
if [ "$r" = 0 ] && grep -q 'Valid' "$T/tool.out"; then pass "elasticsearch-croneval: $(said)"; else fail "elasticsearch-croneval: exit $r, $(said)"; fi
tool elasticsearch-sql-cli --help; r=$?
if [ "$r" = 0 ] && [ -s "$T/tool.out" ]; then pass "elasticsearch-sql-cli --help"; else fail "elasticsearch-sql-cli --help: exit $r, $(said)"; fi
n="$(ls -A /tmp | sort | comm -13 "$T/tools-before.txt" - | tr '\n' ' ')"
if [ -z "$n" ]; then pass "the tools left nothing in /tmp"; else fail "the tools left in /tmp: $n"; fi
# bin/elasticsearch by hand (its version, with a heap of its own: that of
# jvm.options is 31g): makes /tmp/elasticsearch for its user, and does not start
# in that of another user
(cd / && env -u ES_TMPDIR JAVA_HOME="$P/openjdk17" ES_PATH_CONF="$conf" ES_JAVA_OPTS="-Xms64m -Xmx64m" "$B/elasticsearch" -V) > "$T/tool.out" 2>&1 < /dev/null; r=$?
n="$(ls -A /tmp | sort | comm -13 "$T/tools-before.txt" - | tr '\n' ' ')"
if [ "$r" = 0 ] && grep -q "Version: $(pkgv elasticsearch6)" "$T/tool.out" && [ "$n" = "elasticsearch " ] && [ "$(stat -f '%Su %Lp' /tmp/elasticsearch)" = "root 700" ]; then
    pass "bin/elasticsearch -V by hand as root: $(said | cut -c1-60); new in /tmp: /tmp/elasticsearch alone, root 700"
else
    fail "bin/elasticsearch -V by hand: exit $r, $(said); new in /tmp: ${n:-nothing}; $(stat -f '%Su %Lp' /tmp/elasticsearch 2>&1)"
fi
chown -R elasticsearch:elasticsearch "$T"
(cd / && su -m elasticsearch -c "env -u ES_TMPDIR JAVA_HOME='$P/openjdk17' ES_PATH_CONF='$conf' ES_JAVA_OPTS='-Xms64m -Xmx64m' '$B/elasticsearch' -V") > "$T/tool.out" 2>&1 < /dev/null; r=$?
if [ "$r" != 0 ] && grep -q 'is not a directory of the user elasticsearch' "$T/tool.out"; then
    pass "bin/elasticsearch by hand as elasticsearch with the /tmp/elasticsearch of root: refused"
else
    fail "bin/elasticsearch by hand as elasticsearch with the /tmp/elasticsearch of root: exit $r, $(said)"
fi
# the rc script, as rc.conf would set it up: its configuration directory is ours,
# the heap of this server 512m (jvm.options stays that of the package, 31g); it
# makes /tmp/elasticsearch anew, which is that of root now
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
rm -f /var/log/elasticsearch/gc.log*
# what the user elasticsearch has in /tmp and /var/tmp before the start (the
# directory of this test and its temporary directory apart)
tmpd=/tmp/elasticsearch
tmpls() { find -x /tmp /var/tmp \( -path "$T" -o -path "$tmpd" \) -prune -o -user elasticsearch -print 2>/dev/null | sort; }
rm -rf /tmp/hsperfdata_elasticsearch
tmpls > "$T/tmp-before.txt"
ls -A /var/log/elasticsearch 2>/dev/null | sort > "$T/varlog-before.txt"
tmpwhen=""
tmpmark() { n_="$(tmpls | comm -13 "$T/tmp-before.txt" - | tr '\n' ' ')"; [ -z "$n_" ] || tmpwhen="$tmpwhen [$1 $(date +%T): $n_]"; }
"$P/etc/rc.d/elasticsearch" onestart > "$T/start.out" 2>&1
r=$?
cp "$T/start.out" "$res/elasticsearch-start.out"
tmpmark "after onestart"
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
        pass "the heap of elasticsearch_heap: -Xms512m -Xmx512m after the 31g of jvm.options, heap_max_in_bytes $hm"
    else
        fail "the heap: last $(grep '^-Xm[sx]' "$T/args.txt" | tail -n 2 | tr '\n' ' '), heap_max_in_bytes ${hm:-not told}, not the 512m of elasticsearch_heap"
    fi
    m=""
    for o in '-XX:+UseG1GC' '-XX:G1ReservePercent=25' '-XX:InitiatingHeapOccupancyPercent=30' '-XX:+ExitOnOutOfMemoryError' \
        '-XX:ErrorFile=/var/log/elasticsearch/hs_err_pid%p.log' '-XX:ReplayDataFile=/var/log/elasticsearch/replay_pid%p.log' '-Dlog4j2.formatMsgNoLookups=true' \
        '-Djava.locale.providers=COMPAT' '-Dio.netty.noUnsafe=true' '-XX:+AlwaysPreTouch' '-XX:+PerfDisableSharedMem' "-Djava.io.tmpdir=$tmpd"; do
        grep -q -x -F -e "$o" "$T/args.txt" || m="$m $o"
    done
    if [ -z "$m" ] && ! grep -q -E 'UseAVX|HeapDump|Xlog|GCLog|PrintGC' "$T/args.txt"; then
        pass "the options of jvm.options for OpenJDK 17 in the JVM, java.io.tmpdir $tmpd; no -XX:UseAVX, no heap dump, no GC log"
    else
        fail "the options of the JVM: missing:${m:- none}$(grep -E 'UseAVX|HeapDump|Xlog|GCLog|PrintGC' "$T/args.txt" | sed 's/^/, has /' | tr '\n' ' ')"
    fi
    # its temporary directory while it runs: of elasticsearch, 0700, at most the
    # named pipe of bash (JNA unpacks nothing there, -Djna.nounpack)
    td="$(stat -f '%Su %Lp' "$tmpd" 2>/dev/null)"
    o="$(find "$tmpd" -mindepth 1 ! -name 'sh-np.*' 2>/dev/null | head -n 5 | tr '\n' ' ')"
    if [ "$td" = "elasticsearch 700" ] && [ -z "$o" ]; then
        pass "$tmpd: $td; in it while Elasticsearch runs: $(find "$tmpd" -mindepth 1 2>/dev/null | sed "s|^$tmpd/||" | tr '\n' ' ' | sed 's/ $//;s/^$/nothing/')"
    else
        fail "$tmpd: ${td:-missing}; in it not the pipe of bash: ${o:-nothing}"
    fi
    # JNA from the file of devel/jna: the options of jvm.options in the JVM, the
    # file and the libffi of az mapped in the process of the pidfile of the rc script
    # (that of the API too), no jna* in its temporary directory
    pid="$(cat /var/run/elasticsearch/elasticsearch.pid 2>/dev/null)"
    get '/_nodes/_local/process?filter_path=**.process.id,**.process.mlockall' > "$T/process.json"
    apid="$(sed -n 's/.*"id" *: *\([0-9]*\).*/\1/p' "$T/process.json")"
    mla="$(sed -n 's/.*"mlockall" *: *\([a-z]*\).*/\1/p' "$T/process.json")"
    procstat -v "${pid:-0}" > "$T/vm.txt" 2>&1
    cp "$T/vm.txt" "$res/elasticsearch-procstat-v.txt"
    jl="$(awk '$NF ~ /libjnidispatch/ { print $NF }' "$T/vm.txt" | sort -u | tr '\n' ' ')"
    fl="$(awk '$NF ~ /\/libffi\.so/ { print $NF }' "$T/vm.txt" | sort -u | tr '\n' ' ')"
    jt="$(find "$tmpd" -mindepth 1 -name 'jna*' 2>/dev/null | tr '\n' ' ')"
    ja="$(grep '^-Djna\.' "$T/args.txt" | tr '\n' ' ')"
    case "$fl" in "$P/az/lib/libffi.so"*) ffi=1 ;; *) ffi="" ;; esac
    if [ -n "$pid" ] && [ "$pid" = "$apid" ] && [ "$ja" = "-Djna.boot.library.path=$P/lib/jna -Djna.nounpack=true " ] \
        && [ "$jl" = "$P/lib/jna/libjnidispatch.so " ] && [ -n "$ffi" ] && [ "$fl" = "${fl%% *} " ] && [ -z "$jt" ]; then
        pass "JNA: ${ja}in the JVM; the process $pid maps ${jl}and ${fl}(procstat -v: elasticsearch-procstat-v.txt), no jna* in $tmpd"
    else
        fail "JNA: ${ja:-no -Djna options} in the JVM; the process ${pid:-of no pidfile} (the API: ${apid:-no id}) maps ${jl:-no libjnidispatch} and ${fl:-no libffi}; jna* in $tmpd: ${jt:-none}"
    fi
    # the native part of Elasticsearch on FreeBSD, through JNA: its system call
    # filter, setrlimit(RLIMIT_NPROC) to 0 (SystemCallFilter.bsdImpl), which the
    # kernel raises to its least, 1 (kern_proc_setrlimit): no new process for the
    # user elasticsearch, which has this one, so no fork; memory lock is not turned
    # on here
    nproc="$(procstat -l "${pid:-0}" 2>/dev/null | awk '$3 == "maxprocesses" { print $4, $5 }')"
    if [ "$nproc" = "1 1" ]; then
        pass "the system call filter of Elasticsearch through JNA: maxprocesses 1 1 of the process $pid (procstat -l: set to 0); mlockall ${mla:-not told} (bootstrap.memory_lock not set)"
    else
        fail "the system call filter: maxprocesses ${nproc:-not told} of the process ${pid:-of no pidfile}, not 1 1 (RLIMIT_NPROC set to 0)"
    fi
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
# xpack.ssl.cipher_suites of elasticsearch.yml: the suites this JDK has, so that
# x-pack does not log its default ones that the JDK lacks as an error
cp "$T/logs/az-test.log" "$res/elasticsearch.log" 2>/dev/null
if grep -E '\]\[ERROR\]|unsupported ciphers' "$T/logs/az-test.log" > "$T/err.txt" 2>/dev/null; then
    fail "the log of the start has $(wc -l < "$T/err.txt" | tr -d ' ') lines of [ERROR]: $(head -n 2 "$T/err.txt" | sed -e 's/^[^]]*\]//' -e 's/ were requested but.*//' | cut -c1-420 | tr '\n' ' ')"
else
    pass "the log of the start without [ERROR], no unsupported ciphers"
fi
if grep -E -i 'jna (not found|is not available)|unable to load jna|cannot load jna|native methods.* will be disabled|unable to link C library|syscall filter|system call filters failed' "$T/logs/az-test.log" > "$T/jna.txt" 2>/dev/null; then
    fail "JNA: $(head -n 2 "$T/jna.txt" | cut -c1-200 | tr '\n' ' ')"
else
    pass "JNA: nothing of JNA failing in the log (its library, the C library, the system call filter)"
fi
w="$(grep -c '\]\[WARN \]' "$T/logs/az-test.log" 2>/dev/null)"
[ "${w:-0}" = 0 ] || note "the log has $w warnings (elasticsearch.log): $(grep '\]\[WARN \]' "$T/logs/az-test.log" | head -n 3 | cut -c1-160 | tr '\n' ' ')"
tmpmark "before onestop"
"$P/etc/rc.d/elasticsearch" onestop > "$T/stop.out" 2>&1
r=$?
if [ "$r" = 0 ] && ! get / > /dev/null; then pass "rc.d/elasticsearch onestop"; else fail "rc.d/elasticsearch onestop: exit $r, $(tail -n 1 "$T/stop.out")"; fi
# after the stop: nothing of Elasticsearch new in /tmp and /var/tmp, no GC log
tmpls > "$T/tmp-after.txt"
n="$(comm -13 "$T/tmp-before.txt" "$T/tmp-after.txt")"
if [ -z "$n" ]; then
    pass "nothing of the user elasticsearch new in /tmp and /var/tmp after start, requests and stop but $tmpd ($(find "$tmpd" -mindepth 1 2>/dev/null | sed "s|^$tmpd/||" | tr '\n' ' ' | sed 's/ $//;s/^$/empty/'))"
else
    fail "new in /tmp and /var/tmp: $(printf '%s' "$n" | head -n 6 | tr '\n' ' ');$tmpwhen"
fi
g="$(ls /var/log/elasticsearch/gc.log* "$T"/logs/gc.log* "$P"/lib/elasticsearch/logs/gc.log* 2>/dev/null | tr '\n' ' ')"
if [ -z "$g" ]; then pass "no GC log"; else fail "a GC log: $g"; fi
# the logs (path.logs of this test): the files of Elastic's log4j2.properties, none
# rolled; then a start with every size of rollover at 2 KB: the main log rolls
# many times, and the rolled files are deleted
logs_check() {
    l="$(ls -A "$T/logs" 2>/dev/null | grep -v -x -E 'az-test(_deprecation|_index_search_slowlog|_index_indexing_slowlog|_audit|_access)?\.log' | tr '\n' ' ')"
    if [ -z "$l" ] && [ -f "$T/logs/az-test.log" ]; then
        pass "path.logs $1: the log files alone, none rolled: $(ls -A "$T/logs" | tr '\n' ' ')($(wc -c < "$T/logs/az-test.log" | tr -d ' ') bytes of az-test.log)"
    else
        fail "path.logs $1: ${l:-no az-test.log}"
    fi
}
logs_check "after start, requests and stop"
n0="$(grep -c 'starting \.\.\.' "$T/logs/az-test.log")"
sed -i '' -E 's|^(appender\.[a-z0-9_]+\.policies\.size\.size) = .*|\1 = 2KB|' "$conf/log4j2.properties"
if [ "$(grep -c '^appender\.[a-z0-9_]*\.policies\.size\.size = 2KB$' "$conf/log4j2.properties")" = 6 ] && "$P/etc/rc.d/elasticsearch" onestart > "$T/start2.out" 2>&1; then
    i=0
    while [ "$i" -lt 90 ]; do get / | grep -q '"number"' && break; sleep 2; i=$((i + 1)); done
    "$P/etc/rc.d/elasticsearch" onestop > /dev/null 2>&1
    sleep 2
    s="$(wc -c < "$T/logs/az-test.log" | tr -d ' ')"
    if [ "$i" -lt 90 ] && [ "$s" -lt 20000 ] && [ "$(grep -c 'starting \.\.\.' "$T/logs/az-test.log")" -le "$n0" ]; then
        logs_check "after a start with the rollover at 2 KB (az-test.log began anew)"
    else
        fail "the rollover at 2 KB: az-test.log has $s bytes, up after $((i * 2)) s: not rolled"
    fi
else
    fail "the start with the rollover at 2 KB: $(tail -n 2 "$T/start2.out" 2>/dev/null | tr '\n' ' ')"
fi
ls -A /var/log/elasticsearch 2>/dev/null | sort > "$T/varlog-after.txt"
n="$(comm -13 "$T/varlog-before.txt" "$T/varlog-after.txt" | tr '\n' ' ')"
if [ -z "$n" ]; then pass "nothing new in /var/log/elasticsearch"; else fail "new in /var/log/elasticsearch: $n"; fi

echo "elastic-test: $ok ok, $bad failed" >> "$out"
[ "$bad" = 0 ]
