# textproc/opensearch-dashboards217 of azsupport/ports: OpenSearch Dashboards 2.17.1,
# the last 2.17.x (aZ, 12.11.2026: a legacy project, with textproc/opensearch217;
# 2.17.2 was never released), named as the official versioned ports
# (textproc/opensearch-dashboards219). The official port of 2.17.1 is the base:
# textproc/opensearch-dashboards of the branch 2025Q1 (the bundle with the plugins,
# Node.js 18, the rc script, pkg-deinstall, pkg-descr), with what follows.
#
# Node.js: 2.17.1 is made for Node.js 18 (.nvmrc 18.19.0, engines ">=14.20.1 <19"):
# the node of our www/node18 (18.20.8 with its security fixes), named by its program
# (no USES=nodejs: the official Mk/Uses/nodejs.mk of the pin knows 22, 24 and 26
# only); bin/use_node of the tarball takes it (files/patch-bin_use__node: its
# CONFIG_DIR typo fixed too, so node.options of the configuration is read). The
# tarball's node/ (Node.js 18.19.0 and 14.21.3 for Linux) is not in the package: they
# are its only ELF files. Its node_modules have no native module (no *.node; the
# @node-rs/xxhash of webpack, which a production start does not load, without its
# platform packages; WebAssembly only): nothing is built, the package is JavaScript.
#
# The plugins: the bundle's 14 (the official port's choice), but those whose server
# plugin textproc/opensearch217 does not have (aZ, 12.11.2026: out of it the security
# plugin and what cannot run on FreeBSD), each with its configPath, the prefix of its
# settings, which the rc script refuses:
#  - securityDashboards: no opensearch-security (aZ: connections without SSL and
#    without a password);
#  - mlCommonsDashboards: no opensearch-ml (its ONNX Runtime, tokenizers and PyTorch
#    are native code for Linux);
#  - assistantDashboards: its agents are those of opensearch-ml, skills and
#    flow-framework, none of them in opensearch217.
# In, each with what it needs of the server: alertingDashboards (alerting),
# anomalyDetectionDashboards (anomaly-detection), customImportMapDashboards
# (geospatial), indexManagementDashboards (index-management, job-scheduler),
# notificationsDashboards (notifications), observabilityDashboards (observability,
# sql), queryWorkbenchDashboards (sql), reportsDashboards (reports-scheduler; no
# Chromium in 2.17.1: CSV and XLSX of saved searches made by the server, PDF and PNG
# by the browser with html2canvas and jsPDF), securityAnalyticsDashboards
# (security-analytics), ganttChartDashboards and searchRelevanceDashboards (none).
# The sample configuration is that of the min tarball: the bundle appends the
# settings of the security plugin (https, kibanaserver, opensearch_security.*) to it.
#
# The commits of the 2.17 branch after 2.17.1 (what 2.17.2 would have been):
#  - 1b89a739 (#9037): the check for large numerals took every number for one
#    ("val < Number.MAX_SAFE_INTEGER || val > ...", MIN for the first): in @osd/std on
#    the server and in the bundles of the browser (each one fixed, its .gz and .br
#    made again);
#  - 0c69517e (#9044) and f6b6da1a (#9045): json11 2.0.0 and the client
#    @opensearch-project/opensearch-next 2.13.0 (the typo fixed there too), in the
#    place of those of the tarball (on the server; the sha512 of the 2.17 branch's
#    yarn.lock);
#  - not taken: d500ecb0 (#9034, a saved search loaded in Discover) changes React
#    code compiled into the Discover bundle; e9c9983f (#8637) changes only the routes
#    of data_source.enabled (off here), half of it in a bundle; 159a2df6 (#9043, the
#    npm package url): the server takes the url of Node.js, the browser has it in the
#    bundles.
# Of the plugins in, the 2.17 branches of alerting, anomaly-detection, notifications,
# reporting and security-analytics have commits after 2.17.1.0, none taken: code of
# the browser (compiled into their bundles), the routes of data_source.enabled,
# release notes, alerting 1a665d7 (its server half alone changes no answer a user
# sees), anomaly-detection f22b65c (_remote/info refused: only by the permissions of
# the security plugin), and the bumps of their own npm packages (of those the server
# loads only lodash, 4.17.21 in the yarn.lock of those branches too).
#
# Security fixes after 2.17.1 that touch it, the server side (files/patch-*, each
# with its source): CVE-2026-75897, POST /api/core/capabilities without a bound
# (cf92fa6d, #12292, 3.8.0); //host/ paths redirected off-site (05be93b, #12193,
# 2.19.6); __proto__ keys in an import (e4d78b4, #12085, 2.19.6); @hapi/content, the
# parser of every request's Content-Type, with that of 6.0.3 (GHSA-36hh-x5p5-jgc8,
# GHSA-8494-f6mr-cjpv, GHSA-jg4p-7fhp-p32p); @hapi/inert, the confinement of
# 7.1.1 (GHSA-rcvq-m9j9-6f4g); js-yaml 3.15.2 in the place of 3.14.1 (the 3.x line
# with its security fixes only: GHSA-mh29-5h37-fv8m, GHSA-h67p-54hq-rp68,
# GHSA-52cp-r559-cp3m, GHSA-5p4m-2wfm-xmqj, GHSA-2883-xcg3-v3hh): the YAML of the
# rules a request gives securityAnalyticsDashboards goes through its load() (the
# functions js-yaml 3 load() makes of !!js/function there are never called:
# safeDump() throws on them before the rule is sent; azsupport/ports, 12.11.2026).
# The rest, and what is not taken and why: README.md of the tree.

PORTNAME=	opensearch-dashboards
DISTVERSION=	2.17.1
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONSUFFIX=	-linux-x64
CATEGORIES=	textproc www
MASTER_SITES=	https://artifacts.opensearch.org/releases/bundle/${PORTNAME}/${DISTVERSION}/ \
		https://registry.npmjs.org/@opensearch-project/opensearch/-/:client \
		https://registry.npmjs.org/json11/-/:json11 \
		https://registry.npmjs.org/js-yaml/-/:jsyaml
PKGNAMESUFFIX=	217
DISTFILES=	${DISTNAME}${EXTRACT_SUFX} \
		opensearch-${CLIENT_VERSION}.tgz:client \
		json11-${JSON11_VERSION}.tgz:json11 \
		js-yaml-${JSYAML_VERSION}.tgz:jsyaml
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	Visualization dashboards for OpenSearch (of azsupport/ports)
WWW=		https://opensearch.org \
		https://github.com/azsupport/ports

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE.txt

# node to build too: the checks of the package, the brotli of the bundles fixed
BUILD_DEPENDS=	node:www/node18
RUN_DEPENDS=	node:www/node18

USE_RC_SUBR=	${PORTNAME}

CONFLICTS_INSTALL=	opensearch-dashboards opensearch-dashboards[0-9]*

NO_ARCH=	yes
NO_BUILD=	yes

SUB_FILES=	pkg-deinstall pkg-message
SUB_LIST=	OSD_CONFIG_OUT="${OSD_PLUGINS_OUT:C/^[^:]*://}" \
		OSD_PLUGINS_OUT="${OSD_PLUGINS_OUT:C/:.*//}" \
		PKGNAMESUFFIX="${PKGNAMESUFFIX}" \
		PORTNAME="${PORTNAME}" \
		WWWDIR=${WWWDIR}

WRKSRC=		${WRKDIR}/${PORTNAME}-${DISTVERSION}

# sed without a backup: the whole tree goes into the package
REINPLACE_ARGS=	-i ''

CLIENT_VERSION=	2.13.0
JSON11_VERSION=	2.0.0
JSYAML_VERSION=	3.15.2

# <plugin>:<the prefix of its settings> of the plugins left out (see the top)
OSD_PLUGINS_OUT=	securityDashboards:opensearch_security \
			mlCommonsDashboards:ml_commons_dashboards \
			assistantDashboards:assistant
OSD_PLUGINS_IN=		alertingDashboards anomalyDetectionDashboards \
			customImportMapDashboards ganttChartDashboards \
			indexManagementDashboards notificationsDashboards \
			observabilityDashboards queryWorkbenchDashboards \
			reportsDashboards searchRelevanceDashboards \
			securityAnalyticsDashboards
# the files of files/patch-*, whose backups (.orig) patch(1) leaves
OSD_PATCHED=	bin/use_node \
		node_modules/@hapi/content/lib/index.js \
		node_modules/@hapi/inert/lib/file.js \
		src/core/server/capabilities/resolve_capabilities.js \
		src/core/server/capabilities/routes/resolve_capabilities.js \
		src/core/server/http/https_redirect_server.js \
		src/core/server/saved_objects/routes/utils.js \
		src/legacy/server/http/index.js
# npm packages in the place of those of the tarball: <tarball>:<directory>
OSD_NPM=	opensearch-${CLIENT_VERSION}.tgz:node_modules/@opensearch-project/opensearch-next \
		json11-${JSON11_VERSION}.tgz:node_modules/json11 \
		js-yaml-${JSYAML_VERSION}.tgz:node_modules/js-yaml
# 1b89a739: "x < Number.MAX_SAFE_INTEGER || x > Number.MAX_SAFE_INTEGER", MIN first
OSD_NUMERALS=	s/\(\([A-Za-z_$$][A-Za-z0-9_$$]*\)[[:space:]]*<[[:space:]]*Number\.\)MAX_SAFE_INTEGER\([[:space:]]*||[[:space:]]*\2[[:space:]]*>[[:space:]]*Number\.MAX_SAFE_INTEGER\)/\1MIN_SAFE_INTEGER\3/g

# the packages of OSD_NPM, each in the place of the directory of the tarball (its own
# node_modules kept: hpagent 1.2.0 of the client)
post-extract:
.for n in ${OSD_NPM}
	@[ -f ${WRKSRC}/${n:C/^[^:]*://}/package.json ] || \
		{ ${ECHO_MSG} "${n:C/^[^:]*://}: not in the tarball"; ${FALSE}; }
	${FIND} ${WRKSRC}/${n:C/^[^:]*://} -mindepth 1 -maxdepth 1 ! -name node_modules -exec ${RM} -r {} +
	${TAR} -xf ${DISTDIR}/${n:C/:.*//} -C ${WRKSRC}/${n:C/^[^:]*://} --strip-components 1
.endfor
# the tarball is what this port was made for: no native module, ELF files in node/ only
	@if ${FIND} ${WRKSRC} -name '*.node' | ${GREP} .; then \
		${ECHO_MSG} "native modules in the tarball"; ${FALSE}; fi

post-patch:
	${RM} ${OSD_PATCHED:S|^|${WRKSRC}/|:S|$|.orig|}
	${REINPLACE_CMD} -e 's|%%LOCALBASE%%|${LOCALBASE}|' ${WRKSRC}/bin/use_node
	@${GREP} -q '^  NODE="${LOCALBASE}/bin/node"$$' ${WRKSRC}/bin/use_node || \
		{ ${ECHO_MSG} "bin/use_node: no NODE= line set"; ${FALSE}; }
# the sample of the min tarball: the bundle's block of the security plugin away
	${REINPLACE_CMD} -e '/^opensearch\.hosts: \[https:\/\/localhost:9200\]$$/,$$d' \
		${WRKSRC}/config/opensearch_dashboards.yml
	@if ${GREP} -n -E '^[^#[:space:]]' ${WRKSRC}/config/opensearch_dashboards.yml; then \
		${ECHO_MSG} "config/opensearch_dashboards.yml: settings left in the sample"; ${FALSE}; fi
	${PRINTF} '%s\n' '' \
		'# azsupport/ports: this package has no security plugin (securityDashboards):' \
		'# OpenSearch Dashboards talks to OpenSearch over plain http without credentials' \
		'# (opensearch.hosts). The rc script refuses to start with a setting of a plugin' \
		'# the package does not have (opensearch_security.* and the others it names):' \
		'# OpenSearch Dashboards would stop at its start on them.' \
		>> ${WRKSRC}/config/opensearch_dashboards.yml
.for p in ${OSD_PLUGINS_OUT:C/:.*//}
	${RM} -r ${WRKSRC}/plugins/${p}
.endfor
	@[ "$$(cd ${WRKSRC}/plugins && ${LS} | ${XARGS})" = "${OSD_PLUGINS_IN}" ] || \
		{ ${ECHO_MSG} "plugins: $$(cd ${WRKSRC}/plugins && ${LS} | ${XARGS}), not ${OSD_PLUGINS_IN}"; ${FALSE}; }
# 1b89a739: each file with the check of large numerals, its .gz and .br made again
	@cd ${WRKSRC} && ${GREP} -rl -E 'Number\.MAX_SAFE_INTEGER[[:space:]]*\|\|' \
		--include='*.js' node_modules/@osd src plugins > ${WRKDIR}/numerals.txt || ${TRUE}
	@while read f; do \
		${CP} -p ${WRKSRC}/$$f ${WRKDIR}/numerals.tmp; \
		${SED} -i '' -e '${OSD_NUMERALS}' ${WRKSRC}/$$f; \
		if ! ${CMP} -s ${WRKSRC}/$$f ${WRKDIR}/numerals.tmp; then \
			${ECHO_MSG} "1b89a739: $$f"; \
			if [ -f ${WRKSRC}/$$f.gz ]; then ${GZIP_CMD:N-*} -9 -n -c ${WRKSRC}/$$f > ${WRKSRC}/$$f.gz; fi; \
			if [ -f ${WRKSRC}/$$f.br ]; then ${LOCALBASE}/bin/node -e 'const z = require("zlib"), fs = require("fs"); \
				fs.writeFileSync(process.argv[2], z.brotliCompressSync(fs.readFileSync(process.argv[1]), \
				{ params: { [z.constants.BROTLI_PARAM_QUALITY]: 11 } }))' ${WRKSRC}/$$f ${WRKSRC}/$$f.br; fi; \
		fi; \
	done < ${WRKDIR}/numerals.txt
	@${RM} ${WRKDIR}/numerals.tmp
	@${GREP} -q 'val < Number.MIN_SAFE_INTEGER || val > Number.MAX_SAFE_INTEGER' \
		${WRKSRC}/node_modules/@osd/std/target/json.js || \
		{ ${ECHO_MSG} "node_modules/@osd/std/target/json.js: 1b89a739 not applied"; ${FALSE}; }
	@if cd ${WRKSRC} && ${GREP} -rl -e '\([A-Za-z_$$][A-Za-z0-9_$$]*\)[[:space:]]*<[[:space:]]*Number\.MAX_SAFE_INTEGER[[:space:]]*||[[:space:]]*\1[[:space:]]*>' \
		--include='*.js' node_modules/@osd node_modules/@opensearch-project/opensearch-next src plugins; then \
		${ECHO_MSG} "1b89a739: these still have the typo"; ${FALSE}; fi

do-install:
	${MKDIR} ${STAGEDIR}${WWWDIR} ${STAGEDIR}${ETCDIR} ${STAGEDIR}${PREFIX}/etc/newsyslog.conf.d
	${INSTALL_DATA} ${WRKSRC}/config/opensearch_dashboards.yml ${STAGEDIR}${ETCDIR}/opensearch_dashboards.yml.sample
	${INSTALL_DATA} ${WRKSRC}/config/node.options ${STAGEDIR}${ETCDIR}/node.options.sample
	${INSTALL_DATA} ${FILESDIR}/newsyslog.conf \
		${STAGEDIR}${PREFIX}/etc/newsyslog.conf.d/opensearch_dashboards.conf.sample
	(cd ${WRKSRC} && \
		${COPYTREE_SHARE} ".i18nrc.json NOTICE.txt data node_modules package.json plugins src" ${STAGEDIR}${WWWDIR} && \
		${COPYTREE_BIN} bin ${STAGEDIR}${WWWDIR})
	${INSTALL} -lrs ${STAGEDIR}${ETCDIR} ${STAGEDIR}${WWWDIR}/config

# the package: no ELF file, no native module, no backup of a patch, the node of
# www/node18, the version, the packages of OSD_NPM
post-install:
	@if ${FIND} ${STAGEDIR}${WWWDIR} -type f -exec ${FILE} {} + | ${GREP} -E ': .*(ELF|Mach-O|PE32)'; then \
		${ECHO_MSG} "binaries in the package"; ${FALSE}; fi
	@if ${FIND} ${STAGEDIR}${WWWDIR} \( -name '*.node' -o -name '*.orig' -o -name '*.rej' -o -path '*/node/bin/*' \) | \
		${GREP} .; then ${ECHO_MSG} "these files must not be in the package"; ${FALSE}; fi
	@[ "$$(cd /tmp && ${SETENV} HOME=${WRKDIR} ${STAGEDIR}${WWWDIR}/bin/opensearch-dashboards --version 2>&1)" = "${DISTVERSION}" ] || \
		{ ${ECHO_MSG} "bin/opensearch-dashboards --version does not say ${DISTVERSION}"; ${FALSE}; }
.for n in ${OSD_NPM}
	@[ "$$(${LOCALBASE}/bin/node -p 'require(process.argv[1]).version' ${STAGEDIR}${WWWDIR}/${n:C/^[^:]*://}/package.json)" = \
		"$$(echo ${n:C/:.*//:R} | ${SED} 's/.*-//')" ] || \
		{ ${ECHO_MSG} "${n:C/^[^:]*://}: not the version of ${n:C/:.*//}"; ${FALSE}; }
.endfor
	${ECHO} "@sample ${ETCDIR}/opensearch_dashboards.yml.sample" >> ${TMPPLIST}
	${ECHO} "@sample ${ETCDIR}/node.options.sample" >> ${TMPPLIST}
	${ECHO} "@sample etc/newsyslog.conf.d/opensearch_dashboards.conf.sample" >> ${TMPPLIST}
	${FIND} -s ${STAGEDIR}${WWWDIR} -not -type d | ${SORT} | \
		${SED} -e 's#^${STAGEDIR}${PREFIX}/##' >> ${TMPPLIST}
	${ECHO} "@dir(www,www) ${WWWDIR}/data" >> ${TMPPLIST}
	${FIND} -s ${STAGEDIR}${WWWDIR} -type d -empty ! -path ${STAGEDIR}${WWWDIR}/data | ${SORT} | \
		${SED} -e 's#^${STAGEDIR}${PREFIX}/#@dir #' >> ${TMPPLIST}

.include <bsd.port.mk>
