# textproc/elasticsearch6 of azsupport/ports: Elasticsearch 6.8.23, the last of 6.x
# (aZ, 11.11.2026: for the legacy sites, which run 6.8.16), back in the ports: the
# official port went on 2023-01-01, still at 6.8.16 (its last state, of the branch
# 2022Q4: the rc script with its profiles, the patch of elasticsearch.yml with the
# paths and xpack.ml.enabled: false, pkg-message, pkg-descr). 6.8.23 has log4j
# 2.17.1 (the fixes of Log4Shell and of its followers) and -Dlog4j2.formatMsgNoLookups.
# On OpenJDK 21 of this tree, java/openjdk21 (aZ, 12.11.2026: one JDK for
# Elasticsearch and OpenSearch; it was on OpenJDK 17 until then). Java 18 and
# later throw at System.setSecurityManager, which Elasticsearch 6 calls, unless
# the JVM has -Djava.security.manager=allow: jvm.options has it for 18 and later
# (as Elasticsearch 7.17 on those); JDK 24 and later have no Security Manager at
# all, so 21 is the last LTS it runs on. The four lines of the warning of the JDK
# about setSecurityManager and the two of JDK 21 about the COMPAT locale provider
# (which jvm.options keeps: the date formats of 6.x) are taken out of the stderr
# of bin/elasticsearch, nothing else (aZ, 11.11.2026). The rc script runs it on
# OpenJDK 21 without elasticsearch_java_home in rc.conf: USES=java with
# JAVA_VERSION 21 gives it ${LOCALBASE}/openjdk21 (the official port had USE_JAVA,
# which the framework of today no longer knows; aZ had to set
# elasticsearch_java_home in rc.conf). Without the module
# x-pack-ml (its native programs are for Linux, macOS and Windows). JNA of
# devel/jna, as the official port: lib/jna.jar a link to its jna.jar, the bundled
# jna-5.5.0.jar out (aZ linked lib/jna.jar to it by hand after every install of
# the old package); devel/jna is ours (no X11 and JAWT, the libffi of az), and
# JNA loads its native library from the file of that package,
# lib/jna/libjnidispatch.so (aZ, 12.11.2026; -Djna.boot.library.path and
# -Djna.nounpack of jvm.options in place of -Djna.nosys): nothing unpacked or listed
# in ES_TMPDIR at a start. The paths of
# jvm.options in
# /var/log/elasticsearch, as the deb and rpm of Elastic have them: the fatal error
# files of the JVM (the tarball has them relative to lib/elasticsearch, which the
# user elasticsearch cannot write). No writes that are of no use (aZ, 11.11.2026):
# no heap dump at an OutOfMemoryError (a file as large as the heap), no GC log
# (the tarball: up to 32 files of 64 MB; the official port put it in ES_TMPDIR),
# nothing in /tmp: no /tmp/hsperfdata_elasticsearch (-XX:+PerfDisableSharedMem in
# jvm.options, -XX:-UsePerfData for the small JVMs of bin/elasticsearch and
# bin/elasticsearch-env and for the tools: elasticsearch-keystore,
# elasticsearch-plugin and the others run by hand leave none either, aZ,
# 12.11.2026), and the rc script sets ES_TMPDIR to the one
# /tmp/elasticsearch (elasticsearch_tmpdir of rc.conf), made anew at each start,
# where every run of a script made a new /tmp/elasticsearch-<number> (the
# named pipe of bash for the filter of bin/elasticsearch is made there too;
# bin/elasticsearch-env has that directory as its default with no JVM to make
# one, and bin/elasticsearch started by hand makes it for its user); no
# archives of old logs: the log files of the tarball stay as they are, each rolled
# at its size alone and the rolled file deleted at once
# (files/log4j2-rollover.properties; the tarball: every day, compressed, kept).
# jvm.options for OpenJDK 17 and later (aZ, 11.11.2026; files/patch-config_jvm.options, each
# change with its source in a comment of the file): -XX:UseAVX=2 for JDK 10 alone
# (Elastic dropped it in 7.1: fixed in JDK 11; on JDK 17 it warned at every start
# on a CPU without AVX2), -XX:+ExitOnOutOfMemoryError (7.16), -XX:ReplayDataFile
# (8.x); the G1 options of 6.8.23 for JDK 14 and later stay. The heap of a server
# is elasticsearch_heap of rc.conf (-Xms and -Xmx in ES_JAVA_OPTS, after
# jvm.options), so that jvm.options is one file for all; without it the heap is
# the 31g of jvm.options (aZ, 12.11.2026; the tarball: 1g), below the cutoff of
# compressed oops near 32 GB: for a server with 64 GB of RAM and more.

PORTNAME=	elasticsearch
PORTVERSION=	6.8.23
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	textproc java devel
MASTER_SITES=	https://artifacts.elastic.co/downloads/${PORTNAME}/
PKGNAMESUFFIX=	6

MAINTAINER=	github@azsupport.com
COMMENT=	Full-text search engine for Java (of azsupport/ports)
WWW=		https://www.elastic.co/ \
		https://github.com/azsupport/ports

# The licenses of what this package has (aZ, 12.11.2026: X-Pack stays, for the
# monitoring that Kibana shows; the official port named Apache 2.0 alone). The
# tarball is the default distribution: its LICENSE.txt is the Elastic License
# agreement (1.0, that of 6.x), under which the binaries of the default
# distribution are ("The build produces two sets of binaries - one set that
# falls under the Elastic License and another set that falls under Apache
# License 2.0. The binaries that contain `-oss` in the artifact name are
# licensed under Apache License 2.0": LICENSE.txt of elastic/elasticsearch at
# v6.8.23; distribution/archives/build.gradle puts licenses/ELASTIC-LICENSE.txt
# into the tarball as LICENSE.txt); the code outside x-pack is under Apache 2.0
# (the same file; NOTICE.txt of the tarball: Elasticsearch and the notices of
# what it bundles). post-patch checks which file is which.
# What the Elastic License 1.0 allows (its text, the LICENSE.txt of the tarball):
# the use of the Basic features at no charge (1.1), for the internal business
# operations of the licensee and of its contractors and affiliates (6.5); not to
# "transfer, sell, rent, lease, distribute, sublicense [...] Elastic Software
# Object Code, in whole or in part, to any third party" (1.2 iii), nor to
# "modify, copy or use" it otherwise (1.2 ii); for a distribution, commercial or
# not, Elastic's permission (1.2, its end). So none of the permissions of the
# ports for it: no mirror and no sale of the distfile or of the package, and no
# acceptance for the user (it is an agreement that the use accepts).
LICENSE=	APACHE20 ELASTIC10
LICENSE_COMB=	multi
LICENSE_NAME_ELASTIC10=	Elastic License 1.0 (the default distribution: X-Pack)
LICENSE_FILE_ELASTIC10=	${WRKSRC}/LICENSE.txt
LICENSE_PERMS_ELASTIC10=	none

# JNA by the file of its native library, which jvm.options loads: a jna without
# it (the official package) does not satisfy this, where jna>0 would
RUN_DEPENDS=	bash>0:shells/bash \
		${LOCALBASE}/lib/jna/libjnidispatch.so:devel/jna

USES=		cpe java shebangfix
CPE_VENDOR=	elastic

CONFLICTS_INSTALL=	elasticsearch elasticsearch[0-9] elasticsearch[0-9][0-9]

NO_ARCH=	yes
NO_BUILD=	yes
JAVA_VERSION=	21
USE_RC_SUBR=	${PORTNAME}
SHEBANG_FILES=	bin/elasticsearch \
		bin/elasticsearch-certgen \
		bin/elasticsearch-certutil \
		bin/elasticsearch-cli \
		bin/elasticsearch-croneval \
		bin/elasticsearch-env \
		bin/elasticsearch-keystore \
		bin/elasticsearch-migrate \
		bin/elasticsearch-plugin \
		bin/elasticsearch-saml-metadata \
		bin/elasticsearch-setup-passwords \
		bin/elasticsearch-shard \
		bin/elasticsearch-sql-cli \
		bin/elasticsearch-syskeygen \
		bin/elasticsearch-translog \
		bin/elasticsearch-users \
		bin/x-pack-env \
		bin/x-pack-security-env \
		bin/x-pack-watcher-env

OPTIONS_DEFINE=	DOCS

.include <bsd.port.options.mk>

CONFIG_FILES=	elasticsearch.yml \
		jvm.options \
		log4j2.properties \
		role_mapping.yml \
		roles.yml
BINS=		elasticsearch \
		elasticsearch-certgen \
		elasticsearch-certutil \
		elasticsearch-cli \
		elasticsearch-croneval \
		elasticsearch-env \
		elasticsearch-keystore \
		elasticsearch-migrate \
		elasticsearch-plugin \
		elasticsearch-saml-metadata \
		elasticsearch-setup-passwords \
		elasticsearch-shard \
		elasticsearch-sql-cli \
		elasticsearch-sql-cli-${PORTVERSION}.jar \
		elasticsearch-syskeygen \
		elasticsearch-translog \
		elasticsearch-users \
		x-pack-env \
		x-pack-security-env \
		x-pack-watcher-env

PORTDOCS=	LICENSE.txt \
		NOTICE.txt \
		README.textile

# the appenders and loggers of the config/log4j2.properties of the tarball (post-patch)
ES_LOG4J=	appender.audit_rolling appender.console appender.deprecated_audit_rolling \
		appender.deprecation_rolling appender.index_indexing_slowlog_rolling \
		appender.index_search_slowlog_rolling appender.rolling logger.action \
		logger.deprecation logger.index_indexing_slowlog \
		logger.index_search_slowlog_rolling logger.saml2_decrypt \
		logger.samlxml_decrypt logger.xmlsig \
		logger.xpack_security_audit_deprecated_logfile \
		logger.xpack_security_audit_logfile

SEARCHUSER?=	elasticsearch
SEARCHGROUP?=	${SEARCHUSER}
USERS=		${SEARCHUSER}
GROUPS=		${SEARCHGROUP}

SUB_LIST=	ETCDIR=${ETCDIR} JAVA_HOME=${JAVA_HOME}
# pkg-message: a message for an upgrade from a package on OpenJDK 17 too (what to
# do with elasticsearch_java_home of rc.conf and with openjdk17): its
# maximum_version is 6.8.23_26111400, 14.11.2026 00:00 UTC (PORTREVISION is the
# hour of the build, yymmddhh in UTC), as every package on 17 was built before
# (the official 6.8.16 too)
SUB_FILES=	pkg-message

post-patch:
	# the license files of the tarball: LICENSE.txt the Elastic License agreement,
	# NOTICE.txt that of Elasticsearch (LICENSE_FILE_ELASTIC10, PORTDOCS)
	@[ "$$(${HEAD} -n 1 ${WRKSRC}/LICENSE.txt)" = "ELASTIC LICENSE AGREEMENT" ] && \
		${GREP} -q '^  1\.1 Object Code End User License\.' ${WRKSRC}/LICENSE.txt && \
		${GREP} -q 'distribute, sublicense, loan or otherwise transfer, Elastic Software Object' ${WRKSRC}/LICENSE.txt && \
		[ "$$(${HEAD} -n 1 ${WRKSRC}/NOTICE.txt)" = "Elasticsearch" ] && \
		${GREP} -q 'The Apache Software' ${WRKSRC}/NOTICE.txt || \
		{ ${ECHO_MSG} "LICENSE.txt, NOTICE.txt of the tarball: not the Elastic License 1.0 and the notice of Elasticsearch: $$(${HEAD} -n 1 ${WRKSRC}/LICENSE.txt), $$(${HEAD} -n 1 ${WRKSRC}/NOTICE.txt)"; ${FALSE}; }
	# ML is not supported on FreeBSD
	@${RM} -r ${WRKSRC}/modules/x-pack-ml
	# the JNA of devel/jna instead (do-install)
	@${RM} ${WRKSRC}/lib/jna-*.jar
	# and its native library from the file of devel/jna, that of the RUN_DEPENDS
	# above (config/jvm.options: -Djna.boot.library.path=%%LOCALBASE%%/lib/jna of
	# files/patch-config_jvm.options, -Djna.nounpack=true, no -Djna.nosys)
	@${REINPLACE_CMD} -e 's|%%LOCALBASE%%|${LOCALBASE}|g' ${WRKSRC}/config/jvm.options
	@${GREP} -q '^-Djna\.boot\.library\.path=${LOCALBASE}/lib/jna$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Djna\.nounpack=true$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -v '^#' ${WRKSRC}/config/jvm.options | ${GREP} -q -e 'jna\.nosys' -e '%%' || \
		{ ${ECHO_MSG} "config/jvm.options: not the JNA of files/patch-config_jvm.options: $$(${GREP} -v '^#' ${WRKSRC}/config/jvm.options | ${GREP} -i -e 'jna' -e '%%' | ${TR} '\n' ' ')"; ${FALSE}; }
	# files/patch-config_jvm.options: the paths, and what it sets for OpenJDK 17 and later
	@! ${GREP} -q '^[0-9:-]*-XX:[+]*HeapDump' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:ErrorFile=/var/log/elasticsearch/hs_err_pid%p\.log$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:ReplayDataFile=/var/log/elasticsearch/replay_pid%p\.log$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:+PerfDisableSharedMem$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -E -q '^[0-9:-]*-(Xlog|XX:[^ ]*GC(Log|Details|DateStamps|ApplicationStoppedTime)|XX:+PrintTenuringDistribution)' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -v '^#' ${WRKSRC}/config/jvm.options | ${GREP} -E -q '(=|:)(logs/|data$$)' || \
		{ ${ECHO_MSG} "config/jvm.options: the paths are not those of files/patch-config_jvm.options"; ${FALSE}; }
	@${GREP} -q '^10:-XX:UseAVX=2$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -q '^10-:' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^9-:-XX:+ExitOnOutOfMemoryError$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^14-:-XX:G1ReservePercent=25$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Dlog4j2\.formatMsgNoLookups=true$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Xms31g$$' ${WRKSRC}/config/jvm.options && ${GREP} -q '^-Xmx31g$$' ${WRKSRC}/config/jvm.options || \
		{ ${ECHO_MSG} "config/jvm.options: not the options of files/patch-config_jvm.options"; ${FALSE}; }
	@[ "$$(${GREP} -c 'es_jdk_warnings' ${WRKSRC}/bin/elasticsearch)" = 3 ] && \
		${GREP} -q '^18-:-Djava\.security\.manager=allow$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^9-:-Djava\.locale\.providers=COMPAT$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -q 'BiasedLocking' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^  if ! mkdir -m 0700 "\$$ES_TMPDIR"; then$$' ${WRKSRC}/bin/elasticsearch && \
		${GREP} -q '^export TMPDIR="\$$ES_TMPDIR"$$' ${WRKSRC}/bin/elasticsearch
	# No JVM of the scripts leaves /tmp/hsperfdata_<user>: -XX:-UsePerfData for the
	# small ones (the check of the Java version of bin/elasticsearch-env, the parser of
	# jvm.options of bin/elasticsearch), for the tools (the ES_JAVA_OPTS of
	# bin/elasticsearch-cli, which every tool but the next runs) and for
	# bin/elasticsearch-sql-cli (java -jar); the server has -XX:+PerfDisableSharedMem
	# in jvm.options. And no /tmp/elasticsearch-<number> of every run of a script:
	# without ES_TMPDIR bin/elasticsearch-env started a JVM (TempDirectory) that
	# made one; ES_TMPDIR is now the /tmp/elasticsearch of the rc script, which
	# bin/elasticsearch alone uses and makes (files/patch-bin_elasticsearch): the
	# tools do not pass it to their JVM, whose java.io.tmpdir stays /tmp (the
	# copy of the zip of elasticsearch-plugin install, which it removes itself at
	# its end: InstallPluginCommand.close; tools/elastic-test.sh installs one).
	@${REINPLACE_CMD} -e 's|"\$$JAVA" -cp "\$$ES_CLASSPATH" org\.elasticsearch\.tools\.|"$$JAVA" -XX:-UsePerfData -cp "$$ES_CLASSPATH" org.elasticsearch.tools.|' \
		-e 's|^  ES_TMPDIR=`"\$$JAVA" .*\.TempDirectory`$$|  ES_TMPDIR=/tmp/elasticsearch|' \
		-e 's|^ES_JAVA_OPTS="-Xms4m -Xmx64m -XX:+UseSerialGC \$${ES_JAVA_OPTS}"$$|ES_JAVA_OPTS="-Xms4m -Xmx64m -XX:+UseSerialGC -XX:-UsePerfData $${ES_JAVA_OPTS}"|' \
		-e 's|^  -jar "\$$CLI_JAR" \\$$|  -XX:-UsePerfData -jar "$$CLI_JAR" \\|' \
		${WRKSRC}/bin/elasticsearch ${WRKSRC}/bin/elasticsearch-env \
		${WRKSRC}/bin/elasticsearch-cli ${WRKSRC}/bin/elasticsearch-sql-cli
	@cd ${WRKSRC}/bin && \
		[ "$$(${GREP} -l '"\$$JAVA"' ${BINS:N*.jar} | ${TR} '\n' ' ')" = "elasticsearch elasticsearch-cli elasticsearch-env elasticsearch-sql-cli " ] && \
		! ${GREP} -h '"\$$JAVA"' ${BINS:N*.jar} | ${GREP} -q -v -E '^(if \[ ! -x "\$$JAVA" \]; then|[A-Z_]*=`"\$$JAVA" -XX:-UsePerfData -cp .*`|"\$$JAVA" -XX:-UsePerfData -cp .*| *"\$$JAVA" \\)$$' && \
		[ "$$(${GREP} -c '"\$$JAVA" -XX:-UsePerfData -cp "\$$ES_CLASSPATH" org\.elasticsearch\.tools\.' elasticsearch)" = 1 ] && \
		[ "$$(${GREP} -c '"\$$JAVA" -XX:-UsePerfData -cp "\$$ES_CLASSPATH" org\.elasticsearch\.tools\.' elasticsearch-env)" = 1 ] && \
		[ "$$(${GREP} -c '^ *"\$$JAVA" \\$$' elasticsearch)" = 2 ] && \
		[ "$$(${GREP} -c '^ *"\$$JAVA" \\$$' elasticsearch-cli)" = 1 ] && \
		[ "$$(${GREP} -c '^ *"\$$JAVA" \\$$' elasticsearch-sql-cli)" = 1 ] && \
		${GREP} -q '^ES_JAVA_OPTS="-Xms4m -Xmx64m -XX:+UseSerialGC -XX:-UsePerfData \$${ES_JAVA_OPTS}"$$' elasticsearch-cli && \
		${GREP} -q '^  -XX:-UsePerfData -jar "\$$CLI_JAR" \\$$' elasticsearch-sql-cli && \
		${GREP} -q '^  ES_TMPDIR=/tmp/elasticsearch$$' elasticsearch-env && \
		! ${GREP} -q 'TempDirectory' ${BINS:N*.jar} || \
		{ ${ECHO_MSG} "bin: not the JVMs this port gives -XX:-UsePerfData (the two small ones, elasticsearch-cli, elasticsearch-sql-cli; the two of the server by jvm.options), or the TempDirectory of bin/elasticsearch-env is not replaced"; ${FALSE}; }
	# config/log4j2.properties: that of the tarball, which has to be the one this was
	# written for (its appenders and loggers), with files/log4j2-rollover.properties
	# in place of its lines of rollover
	@[ "$$(${SED} -n -E 's/^(appender|logger)\.([a-z0-9_]+)\.name *=.*/\1.\2/p' ${WRKSRC}/config/log4j2.properties | ${SORT} | ${TR} '\n' ' ')" = "${ES_LOG4J:O} " ] || \
		{ ${ECHO_MSG} "config/log4j2.properties of the tarball: its appenders and loggers are not those files/log4j2-rollover.properties was written for: $$(${SED} -n -E 's/^(appender|logger)\.([a-z0-9_]+)\.name *=.*/\1.\2/p' ${WRKSRC}/config/log4j2.properties | ${SORT} | ${TR} '\n' ' ')"; ${FALSE}; }
	@${REINPLACE_CMD} -E -e '/^appender\.[a-z0-9_]+\.(filePattern|policies|strategy)[. ]/d' ${WRKSRC}/config/log4j2.properties
	@${CAT} ${FILESDIR}/log4j2-rollover.properties >> ${WRKSRC}/config/log4j2.properties
	@[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.filePattern = .*\.log\.%i\.rolled$$' ${WRKSRC}/config/log4j2.properties)" = 6 ] && \
		[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.filePattern' ${WRKSRC}/config/log4j2.properties)" = 6 ] && \
		[ "$$(${GREP} -c '^appender\.[a-z0-9_]*\.strategy\.action\.type = Delete$$' ${WRKSRC}/config/log4j2.properties)" = 6 ] && \
		! ${GREP} -v '^#' ${WRKSRC}/config/log4j2.properties | ${GREP} -E -q 'TimeBasedTriggeringPolicy|\.gz|%d\{yyyy|IfAccumulatedFileSize' && \
		${GREP} -q '^rootLogger\.level = info$$' ${WRKSRC}/config/log4j2.properties || \
		{ ${ECHO_MSG} "config/log4j2.properties: not the rollover of files/log4j2-rollover.properties alone"; ${FALSE}; }

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/elasticsearch
.for f in ${CONFIG_FILES}
	${INSTALL} ${WRKSRC}/config/${f} ${STAGEDIR}${ETCDIR}/${f}.sample
.endfor
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/elasticsearch/bin
.for f in ${BINS}
	${INSTALL_SCRIPT} ${WRKSRC}/bin/${f} ${STAGEDIR}${PREFIX}/lib/elasticsearch/bin
.endfor
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib
	(cd ${WRKSRC}/lib && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib/ "-name *\.jar")

	${MKDIR} ${STAGEDIR}${PREFIX}/lib/elasticsearch/modules
	(cd ${WRKSRC}/modules && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/lib/elasticsearch/modules/)
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/elasticsearch/plugins
	${MKDIR} ${STAGEDIR}${PREFIX}/libexec/elasticsearch
	${INSTALL} -lrs ${STAGEDIR}${ETCDIR} ${STAGEDIR}${PREFIX}/lib/elasticsearch/config
	${LN} -sf ${JAVAJARDIR}/jna.jar ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib/jna.jar

do-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}
.for f in ${PORTDOCS}
	${INSTALL_DATA} ${WRKSRC}/${f} ${STAGEDIR}${DOCSDIR}
.endfor

post-install:
	# JNA: a link to the jna.jar of devel/jna, no other JNA; the rc script on the
	# OpenJDK 21 of the dependency (its file of the work directory: install-rc-script
	# puts it into the stage directory after post-install)
	@[ "$$(readlink ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib/jna.jar)" = "${JAVAJARDIR}/jna.jar" ] && \
		! ls ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib/jna-*.jar > /dev/null 2>&1 || \
		{ ${ECHO_MSG} "lib/jna.jar is not the link to ${JAVAJARDIR}/jna.jar alone"; ${FALSE}; }
	@[ "${JAVA_HOME}" = "${LOCALBASE}/openjdk21" ] && \
		${GREP} -q 'elasticsearch_java_home="${LOCALBASE}/openjdk21"' ${WRKDIR}/elasticsearch || \
		{ ${ECHO_MSG} "rc.d/elasticsearch: elasticsearch_java_home is not ${LOCALBASE}/openjdk21 (JAVA_HOME ${JAVA_HOME})"; ${FALSE}; }
	@${GREP} -q 'export ES_JAVA_OPTS="-Xms$${elasticsearch_heap} -Xmx$${elasticsearch_heap}"' ${WRKDIR}/elasticsearch && \
		${GREP} -q '^export ES_TMPDIR="$${elasticsearch_tmpdir}"$$' ${WRKDIR}/elasticsearch && \
		${SH} -n ${WRKDIR}/elasticsearch || \
		{ ${ECHO_MSG} "rc.d/elasticsearch: no heap of elasticsearch_heap, no ES_TMPDIR, or not a script of sh"; ${FALSE}; }
	${ECHO} "@sample ${ETCDIR}/elasticsearch.yml.sample" >> ${TMPPLIST}
	${ECHO} "@sample ${ETCDIR}/log4j2.properties.sample" >> ${TMPPLIST}
	${ECHO} "@sample ${ETCDIR}/jvm.options.sample" >> ${TMPPLIST}
	${ECHO} "@sample ${ETCDIR}/roles.yml.sample" >> ${TMPPLIST}
	${ECHO} "@sample ${ETCDIR}/role_mapping.yml.sample" >> ${TMPPLIST}
	${FIND} -s ${STAGEDIR}${PREFIX}/lib/elasticsearch -not -type d | ${SORT} | \
		${SED} -e 's#^${STAGEDIR}${PREFIX}/##' >> ${TMPPLIST}
	${ECHO} "@dir lib/elasticsearch/plugins" >> ${TMPPLIST}
	${ECHO} "@dir libexec/elasticsearch" >> ${TMPPLIST}
	${ECHO} "@dir(elasticsearch,elasticsearch,0755) ${ETCDIR}" >> ${TMPPLIST}

.include <bsd.port.mk>
