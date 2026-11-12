# textproc/opensearch217 of azsupport/ports: OpenSearch 2.17.1, the last of 2.17.x
# (aZ, 12.11.2026: for a legacy project; 2.17.2 was never released, its branch
# has no code after 2.17.1), named as the official versioned ports
# (textproc/opensearch216, textproc/opensearch219). The official
# textproc/opensearch was at 2.17.1 from 2024-10-14 (its state in the branch
# 2025Q1 of freebsd-ports: the bundle of OpenSearch with its plugins, the same
# file and distinfo, and the rc script, patches and pkg-message that
# textproc/opensearch216 of the pinned tree still has); this port starts from it.
# On OpenJDK 21, java/openjdk21 of ours (headless, as java/openjdk17; aZ,
# 12.11.2026: the JDK of textproc/opensearch219 and of 3.x, one JDK for both
# ports), the JDK of the bundle (Temurin 21.0.4, jdk/release): OpenSearch 2.17
# runs on 11, 17 and 21, and not on 24 and later (JEP 486: those JDKs refuse the
# Security Manager that OpenSearch 2.x installs at its start). USES=java with
# JAVA_VERSION 21 gives the rc script ${LOCALBASE}/openjdk21, and
# bin/opensearch-env takes it when JAVA_HOME is not set (it looked for
# /usr/local/bin/java on FreeBSD, the javavmwrapper our JDKs do not have), so
# the tools run by hand without JAVA_HOME; the JDK of the bundle is not
# installed. JNA of devel/jna, as the official port: lib/jna.jar a link to
# its jna.jar, the bundled jna-5.13.0.jar out; devel/jna is ours (no X11 and
# JAWT, the libffi of az), and JNA loads its native library from the file of
# that package, lib/jna/libjnidispatch.so (aZ, 12.11.2026, as for
# elasticsearch6: -Djna.boot.library.path and -Djna.nounpack of jvm.options;
# the launcher of OpenSearch puts -Djna.nosys=true first, which they make of no
# matter): nothing unpacked or listed in OPENSEARCH_TMPDIR at a start.
#
# The plugins (aZ, 12.11.2026): those of the bundle, as the official port has
# them (its option PLUGINS, on by default) and as aZ's cluster of 2.17.1 runs
# them (all 23, on ko41, ko44, ko48, ko56), so that a node of this port can take
# the place of one of his in the same cluster; out only the security plugin and
# what cannot run on FreeBSD, with what needs it:
#   out: opensearch-security (aZ: not needed, connections without TLS and
#        without passwords; his nodes run it with plugins.security.disabled:
#        true; out of the package entirely, with its tools and the demo
#        certificates of its installer: OpenSearch runs without it, and the rc
#        script refuses a start with a setting of it in opensearch.yml, which
#        OpenSearch would stop at as unknown), opensearch-knn (its engines faiss
#        and nmslib are libraries of Linux, with libgomp, loaded through JNI,
#        which a JVM of FreeBSD cannot load: an index of them would fail with an
#        Error, which stops a node of OpenSearch), opensearch-neural-search (it
#        extends opensearch-knn), opensearch-performance-analyzer (Linux only:
#        /proc, /dev/shm and its agent);
#   in:  opensearch-alerting, opensearch-anomaly-detection,
#        opensearch-asynchronous-search, opensearch-cross-cluster-replication,
#        opensearch-custom-codecs (its zstd codecs on the zstd-jni of the
#        server, which has a library for FreeBSD amd64; its QAT codecs need
#        Intel QuickAssist and Linux and are not offered here),
#        opensearch-flow-framework, opensearch-geospatial,
#        opensearch-index-management, opensearch-job-scheduler, opensearch-ml
#        (it loads without native code: its remote models, connectors to
#        outside services, run; its local models need ONNX Runtime, the
#        tokenizers of DJL or PyTorch, native code of Linux, macOS and Windows,
#        and cannot be deployed here: the two jars of that code are left out,
#        aZ, 12.11.2026, ML_NATIVE_JARS below: onnxruntime_gpu-1.16.3.jar, ONNX
#        Runtime with CUDA, 290 MiB, and tokenizers-0.28.0.jar, the tokenizers
#        of DJL, 19 MiB, 309 of the 357 MiB of the plugin; its policy names no
#        jar, and their classes are loaded only to deploy a local model; with
#        its own netty 4.1.108.Final, of the client of the AWS SDK of its
#        connectors), opensearch-notifications,
#        opensearch-notifications-core, opensearch-observability,
#        opensearch-reports-scheduler, opensearch-security-analytics,
#        opensearch-skills (it extends opensearch-ml), opensearch-sql,
#        opensearch-system-templates, query-insights; the modules of the server
#        all.
# No jar of the bundle is replaced (aZ, 12.11.2026: the fixes that newer jars of
# the same lines would bring go to him as a list first): the code of OpenSearch,
# its plugins and their libraries is that of 2.17.1 (the fixes of 2.18 and
# later in it cannot be applied to the bundle); post-patch checks that the jars
# of netty are those of the bundle this port was written for.
#
# No writes that are of no use (aZ, 11.11.2026, as for elasticsearch6): no
# heap dump at an OutOfMemoryError (-XX:+ExitOnOutOfMemoryError instead), no GC
# log (the official port put it into OPENSEARCH_TMPDIR), nothing in /tmp: no
# /tmp/hsperfdata_opensearch (-XX:+PerfDisableSharedMem in jvm.options,
# -XX:-UsePerfData for the small JVMs of bin/opensearch-env and bin/opensearch
# and for the tools, bin/opensearch-cli: opensearch-keystore, opensearch-plugin
# and the others run by hand leave none either), and the rc script sets
# OPENSEARCH_TMPDIR to the one /tmp/opensearch (opensearch_tmpdir of rc.conf),
# made anew at each start, where every start made a new
# /tmp/opensearch-<number> (TempDirectory; the named pipe of bash for the
# filter of bin/opensearch is made there too; bin/opensearch started by hand
# makes it for its user); no archives of old logs: the log files of the
# tarball stay as they are, each rolled at its size alone and the rolled file
# deleted at once (files/log4j2-rollover.properties; the tarball: the server
# logs every day, compressed, kept up to 2 GB). The fatal error files of the
# JVM in /var/log/opensearch, as the deb and rpm of OpenSearch. The warnings
# JDK 21 prints at each start for what OpenSearch 2.17 sets itself are taken out
# of the stderr of bin/opensearch, nothing else (as for elasticsearch6): the
# four lines about System::setSecurityManager (it calls it), the one of the
# incubator module jdk.incubator.vector (--add-modules of the 20-: line of its
# jvm.options, for the vectors of Lucene) and the two of the COMPAT locale
# provider (-Djava.locale.providers=SPI,COMPAT of its launcher, for its dates).
# The heap
# of a server is opensearch_heap of rc.conf (-Xms and -Xmx in
# OPENSEARCH_JAVA_OPTS, after jvm.options), so that jvm.options is one file for
# all; without it the heap is the 31g of jvm.options (aZ, 12.11.2026, as for
# elasticsearch6; the tarball: 1g), below the cutoff of compressed oops near
# 32 GB: for a server with 64 GB of RAM and more.

PORTNAME=	opensearch
DISTVERSION=	2.17.1
DISTVERSIONSUFFIX=	-linux-x64
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	textproc java devel
MASTER_SITES=	https://artifacts.opensearch.org/releases/bundle/${PORTNAME}/${DISTVERSION}/
PKGNAMESUFFIX=	217

MAINTAINER=	github@azsupport.com
COMMENT=	Full-text search engine for Java (of azsupport/ports)
WWW=		https://opensearch.org/ \
		https://github.com/azsupport/ports

LICENSE=	APACHE20

# JNA by the file of its native library, which jvm.options loads: a jna without
# it (the official package) does not satisfy this, where jna>0 would
RUN_DEPENDS=	bash>0:shells/bash \
		${LOCALBASE}/lib/jna/libjnidispatch.so:devel/jna

USES=		cpe java shebangfix

CONFLICTS_INSTALL=	opensearch opensearch[0-9][0-9] opensearch[0-9][0-9][0-9]

NO_ARCH=	yes
NO_BUILD=	yes
JAVA_VERSION=	21
USE_RC_SUBR=	${PORTNAME}
SHEBANG_FILES=	bin/opensearch bin/opensearch-cli \
		bin/opensearch-env bin/opensearch-env-from-file \
		bin/opensearch-keystore bin/opensearch-node \
		bin/opensearch-plugin bin/opensearch-shard

WRKSRC=		${WRKDIR}/${PORTNAME}-${PORTVERSION}

CONFIG_FILES=	opensearch.yml jvm.options log4j2.properties
PLUGINS_CONFIG_FILES= \
		opensearch-notifications-core/notifications-core.yml \
		opensearch-notifications/notifications.yml \
		opensearch-observability/observability.yml \
		opensearch-reports-scheduler/reports-scheduler.yml

BINS=		opensearch opensearch-cli opensearch-env \
		opensearch-env-from-file opensearch-keystore \
		opensearch-node opensearch-plugin \
		opensearch-shard

# the plugins of the bundle this port installs, and those it leaves out (above)
OPENSEARCH_PLUGINS= \
		opensearch-alerting opensearch-anomaly-detection \
		opensearch-asynchronous-search \
		opensearch-cross-cluster-replication opensearch-custom-codecs \
		opensearch-flow-framework opensearch-geospatial \
		opensearch-index-management opensearch-job-scheduler \
		opensearch-ml opensearch-notifications \
		opensearch-notifications-core opensearch-observability \
		opensearch-reports-scheduler opensearch-security-analytics \
		opensearch-skills opensearch-sql opensearch-system-templates \
		query-insights
OPENSEARCH_PLUGINS_OUT= \
		opensearch-knn opensearch-neural-search \
		opensearch-performance-analyzer opensearch-security

# the two jars of opensearch-ml with the native code of its local models, out
# (above)
ML_NATIVE_JARS=	onnxruntime_gpu-1.16.3.jar tokenizers-0.28.0.jar

# the jars of netty of the bundle: those of modules/transport-netty4 (the HTTP
# and transport ports), and those of opensearch-ml (the client of the AWS SDK of
# its connectors)
NETTY_JARS=	netty-buffer netty-codec netty-codec-http netty-common \
		netty-handler netty-resolver netty-transport \
		netty-transport-native-unix-common
NETTY_BUNDLED=	4.1.112.Final
NETTY_ML=	netty-buffer-4.1.108.Final.jar netty-codec-4.1.108.Final.jar \
		netty-codec-http-4.1.108.Final.jar \
		netty-codec-http2-4.1.108.Final.jar \
		netty-common-4.1.108.Final.jar netty-handler-4.1.108.Final.jar \
		netty-nio-client-2.25.40.jar netty-resolver-4.1.108.Final.jar \
		netty-transport-4.1.108.Final.jar \
		netty-transport-classes-epoll-4.1.108.Final.jar \
		netty-transport-native-unix-common-4.1.108.Final.jar

# the appenders and loggers of the config/log4j2.properties of the tarball
OS_LOG4J=	appender.console appender.deprecation_rolling \
		appender.deprecation_rolling_old appender.header_warning \
		appender.index_indexing_slowlog_rolling \
		appender.index_indexing_slowlog_rolling_old \
		appender.index_search_slowlog_rolling \
		appender.index_search_slowlog_rolling_old appender.rolling \
		appender.rolling_old appender.search_request_slowlog_json_appender \
		appender.search_request_slowlog_log_appender \
		appender.task_detailslog_rolling \
		appender.task_detailslog_rolling_old logger.deprecation \
		logger.index_indexing_slowlog logger.index_search_slowlog_rolling \
		logger.search_request_slowlog_logger logger.task_detailslog_rolling

SEARCHUSER?=	opensearch
SEARCHGROUP?=	${SEARCHUSER}
USERS=		${SEARCHUSER}
GROUPS=		${SEARCHGROUP}

SUB_FILES=	pkg-message
SUB_LIST=	ETCDIR=${ETCDIR} \
		JAVA_HOME=${JAVA_HOME}

post-patch:
	# the plugins: those of the bundle this was written for, without the ones
	# left out (above), with their configuration and tools
	@[ "$$(cd ${WRKSRC}/plugins && ls | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "$$(echo ${OPENSEARCH_PLUGINS} ${OPENSEARCH_PLUGINS_OUT} | ${TR} ' ' '\n' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" ] || \
		{ ${ECHO_MSG} "plugins of the bundle: not those this port was written for: $$(cd ${WRKSRC}/plugins && ls | ${TR} '\n' ' ')"; ${FALSE}; }
.for p in ${OPENSEARCH_PLUGINS_OUT}
	@${RM} -r ${WRKSRC}/plugins/${p} ${WRKSRC}/config/${p} ${WRKSRC}/bin/${p}
.endfor
	@${RM} -r ${WRKSRC}/performance-analyzer-rca
	@[ "$$(cd ${WRKSRC}/plugins && ls | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "$$(echo ${OPENSEARCH_PLUGINS} | ${TR} ' ' '\n' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" ] && \
		[ "$$(cd ${WRKSRC}/config && ${FIND} . -type f ! -name '*.orig' ! -name '*.bak' | ${SED} 's|^\./||' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "$$(echo ${CONFIG_FILES} ${PLUGINS_CONFIG_FILES} | ${TR} ' ' '\n' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" ] && \
		[ -z "$$(${FIND} ${WRKSRC}/lib ${WRKSRC}/modules ${WRKSRC}/plugins \( -name '*.so' -o -name '*.so.*' -o -name '*.dylib' -o -name '*.dll' -o -name '*.sh' -o -type l \) -print)" ] || \
		{ ${ECHO_MSG} "plugins and config after the removal: not those of the port: $$(cd ${WRKSRC}/plugins && ls | ${TR} '\n' ' '); config: $$(cd ${WRKSRC}/config && ${FIND} . -type f | ${TR} '\n' ' ')"; ${FALSE}; }
	# opensearch-ml without the jars of the native code of its local models
	# (ML_NATIVE_JARS): those two there, then gone, and nothing else
	@cd ${WRKSRC}/plugins/opensearch-ml && ls | LC_ALL=C ${SORT} > ${WRKDIR}/ml-files.bundle && \
		for j in ${ML_NATIVE_JARS}; do [ -f $$j ] || { ${ECHO_MSG} "plugins/opensearch-ml: no $$j, which this port takes out"; exit 1; }; done && \
		${RM} ${ML_NATIVE_JARS} && \
		[ "$$(ls | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "$$(${GREP} -v -x -F ${ML_NATIVE_JARS:S/^/-e /} ${WRKDIR}/ml-files.bundle | ${TR} '\n' ' ')" ] && \
		[ $$(ls | wc -l) -eq $$(($$(wc -l < ${WRKDIR}/ml-files.bundle) - 2)) ] && \
		! ls | ${GREP} -q -e '^onnxruntime_gpu' -e '^tokenizers-' || \
		{ ${ECHO_MSG} "plugins/opensearch-ml: not the files of the bundle without ${ML_NATIVE_JARS}: $$(ls | ${TR} '\n' ' ')"; ${FALSE}; }
	# netty: the jars of the bundle this port was written for (above)
	@[ "$$(cd ${WRKSRC}/modules/transport-netty4 && LC_ALL=C ls netty-*.jar | ${TR} '\n' ' ')" = "${NETTY_JARS:O:S/$/-${NETTY_BUNDLED}.jar/} " ] && \
		[ "$$(cd ${WRKSRC} && ${FIND} lib plugins modules -name 'netty-*.jar' ! -path 'modules/transport-netty4/*' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "${NETTY_ML:O:S|^|plugins/opensearch-ml/|} " ] || \
		{ ${ECHO_MSG} "netty of the bundle: not the jars this port was written for: $$(${FIND} ${WRKSRC} -name 'netty-*.jar' | ${SED} 's|^${WRKSRC}/||' | ${TR} '\n' ' ')"; ${FALSE}; }
	# the JNA of devel/jna instead (do-install)
	@[ "$$(cd ${WRKSRC}/lib && ls jna-*.jar)" = "jna-5.13.0.jar" ] || \
		{ ${ECHO_MSG} "lib: not the jna-5.13.0.jar this port was written for: $$(cd ${WRKSRC}/lib && ls jna*)"; ${FALSE}; }
	@${RM} ${WRKSRC}/lib/jna-*.jar
	# and its native library from the file of devel/jna, that of the RUN_DEPENDS
	# above (config/jvm.options: -Djna.boot.library.path=%%LOCALBASE%%/lib/jna of
	# files/patch-config_jvm.options, -Djna.nounpack=true)
	@${REINPLACE_CMD} -e 's|%%LOCALBASE%%|${LOCALBASE}|g' ${WRKSRC}/config/jvm.options
	@${GREP} -q '^-Djna\.boot\.library\.path=${LOCALBASE}/lib/jna$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Djna\.nounpack=true$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -v '^#' ${WRKSRC}/config/jvm.options | ${GREP} -q -e 'jna\.nosys' -e '%%' || \
		{ ${ECHO_MSG} "config/jvm.options: not the JNA of files/patch-config_jvm.options: $$(${GREP} -v '^#' ${WRKSRC}/config/jvm.options | ${GREP} -i -e 'jna' -e '%%' | ${TR} '\n' ' ')"; ${FALSE}; }
	# files/patch-config_jvm.options: the paths, and what it sets; the two lines
	# for JDK 18 and later and 20 and later, which JDK 21 takes and whose
	# warnings bin/opensearch takes out, and no other line of a version past 17
	@! ${GREP} -q '^[0-9:-]*-XX:[+]*HeapDump' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:+ExitOnOutOfMemoryError$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:ErrorFile=/var/log/opensearch/hs_err_pid%p\.log$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:ReplayDataFile=/var/log/opensearch/replay_pid%p\.log$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:+PerfDisableSharedMem$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -E -q '^[0-9:-]*-(Xlog|Xloggc|XX:[^ ]*GC(Log|Details|DateStamps|ApplicationStoppedTime)|XX:+PrintTenuringDistribution)' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -v '^#' ${WRKSRC}/config/jvm.options | ${GREP} -E -q '(=|:)(logs/|data$$)' && \
		${GREP} -q '^11-:-XX:+UseG1GC$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Djava\.io\.tmpdir=\$${OPENSEARCH_TMPDIR}$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Xms31g$$' ${WRKSRC}/config/jvm.options && ${GREP} -q '^-Xmx31g$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^18-:-Djava\.security\.manager=allow$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^20-:--add-modules=jdk\.incubator\.vector$$' ${WRKSRC}/config/jvm.options && \
		[ "$$(${GREP} -c -E '^(1[89]|2[0-9])-?:' ${WRKSRC}/config/jvm.options)" = 2 ] || \
		{ ${ECHO_MSG} "config/jvm.options: not the options of files/patch-config_jvm.options"; ${FALSE}; }
	# config/opensearch.yml: the paths of the official port
	@${GREP} -q '^path\.data: /var/db/opensearch$$' ${WRKSRC}/config/opensearch.yml && \
		${GREP} -q '^path\.logs: /var/log/opensearch$$' ${WRKSRC}/config/opensearch.yml && \
		[ "$$(${GREP} -v -e '^#' -e '^$$' ${WRKSRC}/config/opensearch.yml | ${TR} '\n' ' ')" = "path.data: /var/db/opensearch path.logs: /var/log/opensearch " ] || \
		{ ${ECHO_MSG} "config/opensearch.yml: not the settings of files/patch-config_opensearch.yml alone: $$(${GREP} -v -e '^#' -e '^$$' ${WRKSRC}/config/opensearch.yml | ${TR} '\n' ' ')"; ${FALSE}; }
	# No JVM of the scripts leaves /tmp/hsperfdata_<user>: -XX:-UsePerfData for the
	# small ones (the probe of CDS and the check of the Java version of
	# bin/opensearch-env, the parser of jvm.options of bin/opensearch: files/
	# patch-bin_opensearch) and for the tools (the OPENSEARCH_JAVA_OPTS of
	# bin/opensearch-cli, which every tool runs, the check of the keystore of each
	# start too); the server has -XX:+PerfDisableSharedMem in jvm.options. The
	# java of FreeBSD for bin/opensearch-env without JAVA_HOME: that of this port's
	# JDK (it named /usr/local/bin/java, of javavmwrapper, which our openjdk21
	# does not install). And no /tmp/opensearch-<number> of every start: the
	# TempDirectory of bin/opensearch is replaced (files/patch-bin_opensearch); the
	# tools do not use OPENSEARCH_TMPDIR, their java.io.tmpdir stays /tmp (the
	# copy of the zip of opensearch-plugin install, which it removes itself at
	# its end; tools/opensearch-test.sh installs one).
	@${REINPLACE_CMD} -e 's|^if \[\[ "\$$("\$$JAVA" -version 2>/dev/null)" =~ "Unable to map CDS archive" \]\]; then$$|if [[ "$$("$$JAVA" -XX:-UsePerfData -version 2>/dev/null)" =~ "Unable to map CDS archive" ]]; then|' \
		-e 's|^"\$$JAVA" "\$$XSHARE" -cp "\$$OPENSEARCH_CLASSPATH" org\.opensearch\.tools\.java_version_checker\.JavaVersionChecker$$|"$$JAVA" "$$XSHARE" -XX:-UsePerfData -cp "$$OPENSEARCH_CLASSPATH" org.opensearch.tools.java_version_checker.JavaVersionChecker|' \
		-e 's|^    JAVA="/usr/local/bin/java"$$|    JAVA="${JAVA_HOME}/bin/java"|' \
		${WRKSRC}/bin/opensearch-env
	@${REINPLACE_CMD} -e 's|^OPENSEARCH_JAVA_OPTS="-Xms4m -Xmx64m -XX:+UseSerialGC \$${OPENSEARCH_JAVA_OPTS}"$$|OPENSEARCH_JAVA_OPTS="-Xms4m -Xmx64m -XX:+UseSerialGC -XX:-UsePerfData $${OPENSEARCH_JAVA_OPTS}"|' \
		${WRKSRC}/bin/opensearch-cli
	@cd ${WRKSRC}/bin && \
		[ "$$(${GREP} -l '"\$$JAVA"' ${BINS} | ${TR} '\n' ' ')" = "opensearch opensearch-cli opensearch-env " ] && \
		! ${GREP} -h '"\$$JAVA"' ${BINS} | ${GREP} -q -v -E '^(if \[ ! -x "\$$JAVA" \]; then|if \[\[ "\$$\("\$$JAVA" -XX:-UsePerfData -version 2>/dev/null\)" =~ .*|"\$$JAVA" "\$$XSHARE" -XX:-UsePerfData -cp .*|OPENSEARCH_JAVA_OPTS=`export OPENSEARCH_TMPDIR; "\$$JAVA" "\$$XSHARE" -XX:-UsePerfData -cp .*| *"\$$JAVA" \\)$$' && \
		[ "$$(${GREP} -c '^ *"\$$JAVA" \\$$' opensearch)" = 2 ] && \
		[ "$$(${GREP} -c '^ *"\$$JAVA" \\$$' opensearch-cli)" = 1 ] && \
		${GREP} -q '^OPENSEARCH_JAVA_OPTS="-Xms4m -Xmx64m -XX:+UseSerialGC -XX:-UsePerfData \$${OPENSEARCH_JAVA_OPTS}"$$' opensearch-cli && \
		${GREP} -q '^    JAVA="${JAVA_HOME}/bin/java"$$' opensearch-env && \
		${GREP} -q '^  OPENSEARCH_TMPDIR=/tmp/opensearch$$' opensearch && \
		${GREP} -q '^export TMPDIR="\$$OPENSEARCH_TMPDIR"$$' opensearch && \
		[ "$$(${GREP} -c 'opensearch_jdk_warnings' opensearch)" = 3 ] && \
		! ${GREP} -q -e 'launchers\.TempDirectory' -e '/usr/local/bin/java' ${BINS} || \
		{ ${ECHO_MSG} "bin: not the JVMs this port gives -XX:-UsePerfData, the java of opensearch-env, or the TempDirectory of bin/opensearch is not replaced: $$(${GREP} -h -e '"\$$JAVA"' -e 'TempDirectory' -e 'bin/java' ${BINS} | ${TR} '\n' '|')"; ${FALSE}; }
	# config/log4j2.properties: that of the tarball, which has to be the one this was
	# written for (its appenders and loggers), with its lines continued by a
	# backslash joined, and files/log4j2-rollover.properties in place of its lines
	# of rollover
	@${AWK} '{ if (sub(/\\$$/, "")) { printf "%s", $$0; c = 1; next } if (c) sub(/^[ \t]+/, ""); c = 0; print }' \
		${WRKSRC}/config/log4j2.properties > ${WRKDIR}/log4j2.properties.joined
	@${MV} ${WRKDIR}/log4j2.properties.joined ${WRKSRC}/config/log4j2.properties
	@! ${GREP} -q '\\$$' ${WRKSRC}/config/log4j2.properties && \
		[ "$$(${SED} -n -E 's/^(appender|logger)\.([a-z0-9_]+)\.name *=.*/\1.\2/p' ${WRKSRC}/config/log4j2.properties | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "${OS_LOG4J:O} " ] || \
		{ ${ECHO_MSG} "config/log4j2.properties of the tarball: its appenders and loggers are not those files/log4j2-rollover.properties was written for: $$(${SED} -n -E 's/^(appender|logger)\.([a-z0-9_]+)\.name *=.*/\1.\2/p' ${WRKSRC}/config/log4j2.properties | LC_ALL=C ${SORT} | ${TR} '\n' ' ')"; ${FALSE}; }
	@${REINPLACE_CMD} -E -e '/^appender\.[a-z0-9_]+\.(filePattern|policies|strategy)[. ]/d' ${WRKSRC}/config/log4j2.properties
	@${CAT} ${FILESDIR}/log4j2-rollover.properties >> ${WRKSRC}/config/log4j2.properties
	@[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.filePattern = .*\.%i\.rolled$$' ${WRKSRC}/config/log4j2.properties)" = 12 ] && \
		[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.filePattern' ${WRKSRC}/config/log4j2.properties)" = 12 ] && \
		[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.type = RollingFile$$' ${WRKSRC}/config/log4j2.properties)" = 12 ] && \
		[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.strategy\.action\.type = Delete$$' ${WRKSRC}/config/log4j2.properties)" = 12 ] && \
		! ${GREP} -v '^#' ${WRKSRC}/config/log4j2.properties | ${GREP} -E -q 'TimeBasedTriggeringPolicy|\.gz|%d\{yyyy|IfAccumulatedFileSize|fileIndex' && \
		${GREP} -q '^rootLogger\.level = info$$' ${WRKSRC}/config/log4j2.properties || \
		{ ${ECHO_MSG} "config/log4j2.properties: not the rollover of files/log4j2-rollover.properties alone"; ${FALSE}; }

do-install:
	${MKDIR} ${STAGEDIR}${ETCDIR}
.for f in ${CONFIG_FILES}
	${INSTALL_DATA} ${WRKSRC}/config/${f} ${STAGEDIR}${ETCDIR}/${f}.sample
.endfor
.for f in ${PLUGINS_CONFIG_FILES}
	${MKDIR} ${STAGEDIR}${ETCDIR}/${f:H}
	${INSTALL_DATA} ${WRKSRC}/config/${f} ${STAGEDIR}${ETCDIR}/${f}.sample
.endfor
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/opensearch/bin
.for f in ${BINS}
	${INSTALL_SCRIPT} ${WRKSRC}/bin/${f} ${STAGEDIR}${PREFIX}/lib/opensearch/bin
.endfor
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/opensearch/extensions
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/opensearch/lib
	(cd ${WRKSRC}/ && ${COPYTREE_SHARE} "lib modules plugins" ${STAGEDIR}${PREFIX}/lib/opensearch/)
	${MKDIR} ${STAGEDIR}${PREFIX}/libexec/opensearch
	${INSTALL} -lrs ${STAGEDIR}${ETCDIR} ${STAGEDIR}${PREFIX}/lib/opensearch/config
	${LN} -sf ${JAVAJARDIR}/jna.jar ${STAGEDIR}${PREFIX}/lib/opensearch/lib/jna.jar

post-install:
	# JNA: a link to the jna.jar of devel/jna, no other JNA; the plugins and the
	# netty of the bundle; the rc script on the OpenJDK 21 of the dependency (its
	# file of the work directory: install-rc-script puts it into the stage
	# directory after post-install)
	@[ "$$(readlink ${STAGEDIR}${PREFIX}/lib/opensearch/lib/jna.jar)" = "${JAVAJARDIR}/jna.jar" ] && \
		! ls ${STAGEDIR}${PREFIX}/lib/opensearch/lib/jna-*.jar > /dev/null 2>&1 || \
		{ ${ECHO_MSG} "lib/jna.jar is not the link to ${JAVAJARDIR}/jna.jar alone"; ${FALSE}; }
	@[ "$$(cd ${STAGEDIR}${PREFIX}/lib/opensearch/plugins && ls | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "$$(echo ${OPENSEARCH_PLUGINS} | ${TR} ' ' '\n' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" ] && \
		[ -z "$$(cd ${STAGEDIR}${PREFIX}/lib/opensearch/plugins/opensearch-ml && ls ${ML_NATIVE_JARS} 2>/dev/null)" ] && \
		[ "$$(cd ${STAGEDIR}${PREFIX}/lib/opensearch && ${FIND} . -name 'netty-*.jar' | LC_ALL=C ${SORT} | ${TR} '\n' ' ')" = "$$(for j in ${NETTY_JARS:O}; do printf './modules/transport-netty4/%s-${NETTY_BUNDLED}.jar ' $$j; done)${NETTY_ML:O:S|^|./plugins/opensearch-ml/|} " ] || \
		{ ${ECHO_MSG} "lib/opensearch: not the plugins of the port or the netty of the bundle"; ${FALSE}; }
	@[ "${JAVA_HOME}" = "${LOCALBASE}/openjdk21" ] && \
		${GREP} -q 'opensearch_java_home="${LOCALBASE}/openjdk21"' ${WRKDIR}/opensearch || \
		{ ${ECHO_MSG} "rc.d/opensearch: opensearch_java_home is not ${LOCALBASE}/openjdk21 (JAVA_HOME ${JAVA_HOME})"; ${FALSE}; }
	@${GREP} -q 'export OPENSEARCH_JAVA_OPTS="-Xms$${opensearch_heap} -Xmx$${opensearch_heap}"' ${WRKDIR}/opensearch && \
		${GREP} -q '^export OPENSEARCH_TMPDIR="$${opensearch_tmpdir}"$$' ${WRKDIR}/opensearch && \
		${GREP} -q 'opensearch_security_settings "$${_yml}"' ${WRKDIR}/opensearch && \
		${SH} -n ${WRKDIR}/opensearch || \
		{ ${ECHO_MSG} "rc.d/opensearch: no heap of opensearch_heap, no OPENSEARCH_TMPDIR, no check of the settings of the security plugin, or not a script of sh"; ${FALSE}; }
.for f in ${CONFIG_FILES} ${PLUGINS_CONFIG_FILES}
	${ECHO} "@sample(opensearch,opensearch,640) ${ETCDIR}/${f}.sample" >> ${TMPPLIST}
.endfor
	${FIND} -s ${STAGEDIR}${PREFIX}/lib/opensearch -not -type d | LC_ALL=C ${SORT} | \
		${SED} -e 's#^${STAGEDIR}${PREFIX}/##' >> ${TMPPLIST}
	${ECHO} "@dir lib/opensearch/extensions" >> ${TMPPLIST}
	${ECHO} "@dir lib/opensearch/plugins" >> ${TMPPLIST}
	${ECHO} "@dir libexec/opensearch" >> ${TMPPLIST}
.for d in ${PLUGINS_CONFIG_FILES:H:O:u}
	${ECHO} "@dir(opensearch,opensearch,0750) ${ETCDIR}/${d}" >> ${TMPPLIST}
.endfor
	${ECHO} "@dir(opensearch,opensearch,0750) ${ETCDIR}/" >> ${TMPPLIST}

.include <bsd.port.mk>
