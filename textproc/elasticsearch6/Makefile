# textproc/elasticsearch6 of azsupport/ports: Elasticsearch 6.8.23, the last of 6.x
# (aZ, 11.11.2026: for the legacy sites, which run 6.8.16), back in the ports: the
# official port went on 2023-01-01, still at 6.8.16 (its last state, of the branch
# 2022Q4: the rc script with its profiles, the patch of elasticsearch.yml with the
# paths and xpack.ml.enabled: false, pkg-message, pkg-descr). 6.8.23 has log4j
# 2.17.1 (the fixes of Log4Shell and of its followers) and -Dlog4j2.formatMsgNoLookups.
# On OpenJDK 17 of the ports (aZ: it ran on OpenJDK 17 for him; Java 18 and later
# throw at System.setSecurityManager, which Elasticsearch 6 calls): the four lines
# of the warning of JDK 17 about it are taken out of the stderr of
# bin/elasticsearch, nothing else (aZ, 11.11.2026). The rc script runs it on
# OpenJDK 17 without elasticsearch_java_home in rc.conf: USES=java with
# JAVA_VERSION 17 gives it ${LOCALBASE}/openjdk17 (the official port had USE_JAVA,
# which the framework of today no longer knows; aZ had to set
# elasticsearch_java_home="/usr/local/openjdk17" in rc.conf). Without the module
# x-pack-ml (its native programs are for Linux, macOS and Windows). JNA of
# devel/jna, as the official port: lib/jna.jar a link to its jna.jar, the bundled
# jna-4.5.1.jar out (aZ linked lib/jna.jar to it by hand after every install of
# the old package); devel/jna brings the libraries libX11 and libXt. The paths of
# jvm.options in
# /var/db/elasticsearch and /var/log/elasticsearch, as the deb and rpm of Elastic
# have them in /var/lib and /var/log: heap dumps, the fatal error files of the JVM
# and the GC log (the tarball has them relative to lib/elasticsearch, which the
# user elasticsearch cannot write; the official port put the GC log in ES_TMPDIR).
# jvm.options for OpenJDK 17 (aZ, 11.11.2026; files/patch-config_jvm.options, each
# change with its source in a comment of the file): -XX:UseAVX=2 for JDK 10 alone
# (Elastic dropped it in 7.1: fixed in JDK 11; on JDK 17 it warned at every start
# on a CPU without AVX2), -XX:+ExitOnOutOfMemoryError (7.16), -XX:ReplayDataFile
# (8.x); the G1 options of 6.8.23 for JDK 14 and later stay. The heap of a server
# is elasticsearch_heap of rc.conf (-Xms and -Xmx in ES_JAVA_OPTS, after
# jvm.options), so that jvm.options is one file for all.

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

# the core under Apache 2.0, X-Pack of the default distribution under the Elastic
# License (as the official port, which named Apache 2.0 only)
LICENSE=	APACHE20

RUN_DEPENDS=	bash>0:shells/bash \
		jna>0:devel/jna

USES=		cpe java shebangfix
CPE_VENDOR=	elastic

CONFLICTS_INSTALL=	elasticsearch elasticsearch[0-9] elasticsearch[0-9][0-9]

NO_ARCH=	yes
NO_BUILD=	yes
JAVA_VERSION=	17
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

SEARCHUSER?=	elasticsearch
SEARCHGROUP?=	${SEARCHUSER}
USERS=		${SEARCHUSER}
GROUPS=		${SEARCHGROUP}

SUB_LIST=	ETCDIR=${ETCDIR} JAVA_HOME=${JAVA_HOME}
SUB_FILES=	pkg-message

post-patch:
	# ML is not supported on FreeBSD
	@${RM} -r ${WRKSRC}/modules/x-pack-ml
	# the JNA of devel/jna instead (do-install)
	@${RM} ${WRKSRC}/lib/jna-*.jar
	# files/patch-config_jvm.options: the paths, and what it sets for OpenJDK 17
	@${GREP} -q '^-XX:HeapDumpPath=/var/db/elasticsearch$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:ErrorFile=/var/log/elasticsearch/hs_err_pid%p\.log$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-XX:ReplayDataFile=/var/log/elasticsearch/replay_pid%p\.log$$' ${WRKSRC}/config/jvm.options && \
		[ "$$(${GREP} -c '/var/log/elasticsearch/gc\.log' ${WRKSRC}/config/jvm.options)" = 2 ] && \
		! ${GREP} -E -q '(=|:)(logs/|data$$)' ${WRKSRC}/config/jvm.options || \
		{ ${ECHO_MSG} "config/jvm.options: the paths are not those of files/patch-config_jvm.options"; ${FALSE}; }
	@${GREP} -q '^10:-XX:UseAVX=2$$' ${WRKSRC}/config/jvm.options && \
		! ${GREP} -q '^10-:' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^9-:-XX:+ExitOnOutOfMemoryError$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^14-:-XX:G1ReservePercent=25$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Dlog4j2\.formatMsgNoLookups=true$$' ${WRKSRC}/config/jvm.options && \
		${GREP} -q '^-Xms1g$$' ${WRKSRC}/config/jvm.options && ${GREP} -q '^-Xmx1g$$' ${WRKSRC}/config/jvm.options || \
		{ ${ECHO_MSG} "config/jvm.options: not the options of files/patch-config_jvm.options"; ${FALSE}; }
	@${GREP} -q 'es_jdk17_warnings' ${WRKSRC}/bin/elasticsearch

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
	# OpenJDK 17 of the dependency (its file of the work directory: install-rc-script
	# puts it into the stage directory after post-install)
	@[ "$$(readlink ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib/jna.jar)" = "${JAVAJARDIR}/jna.jar" ] && \
		! ls ${STAGEDIR}${PREFIX}/lib/elasticsearch/lib/jna-*.jar > /dev/null 2>&1 || \
		{ ${ECHO_MSG} "lib/jna.jar is not the link to ${JAVAJARDIR}/jna.jar alone"; ${FALSE}; }
	@[ "${JAVA_HOME}" = "${LOCALBASE}/openjdk17" ] && \
		${GREP} -q 'elasticsearch_java_home="${LOCALBASE}/openjdk17"' ${WRKDIR}/elasticsearch || \
		{ ${ECHO_MSG} "rc.d/elasticsearch: elasticsearch_java_home is not ${LOCALBASE}/openjdk17 (JAVA_HOME ${JAVA_HOME})"; ${FALSE}; }
	@${GREP} -q 'export ES_JAVA_OPTS="-Xms$${elasticsearch_heap} -Xmx$${elasticsearch_heap}"' ${WRKDIR}/elasticsearch && \
		${SH} -n ${WRKDIR}/elasticsearch || \
		{ ${ECHO_MSG} "rc.d/elasticsearch: no heap of elasticsearch_heap, or not a script of sh"; ${FALSE}; }
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
