# textproc/opensearch-dashboards219 of azsupport/ports: OpenSearch Dashboards 2.19.7,
# in the place of the official textproc/opensearch-dashboards219 (its origin, as
# textproc/opensearch219) and ahead of it (2.19.6 in the pinned tree and in
# freebsd-ports main, 13.11.2026), with textproc/opensearch219 2.19.7: aZ's cluster
# of 2.17.1 moves to 2.19 (aZ, 12.11.2026: the bridge to 3.x), and his Dashboards
# with it; Dashboards 2.19 is for OpenSearch 2.19 alone (2.19.7: "Compatible with
# OpenSearch and OpenSearch Dashboards version 2.19.7", its release notes). 2.19.7
# and not the 2.19.6 of the official port (the rule: a release ahead of its port
# for a vulnerability that touches aZ): it bounds POST /api/core/capabilities
# (CVE-2026-75897, a DoS without authentication; #12563, the backport of #12292,
# which textproc/opensearch-dashboards217 patches in), with the AST validation of
# Vega expressions (#12622), Node.js 18.20.8 for its bundle, @hapi/inert 7.1.2 and
# the bumps of #12920, #12929, #12910 and #12724 (its release notes). The commits of
# the 2.19 branch after 2.19.7: the bump to 2.19.8 alone (4772b32f, 09.11.2026); of
# the plugins in (below), only that of queryWorkbenchDashboards has one, qs 6.16.1
# (f446c90, CVE-2026-110816), which no code of its server loads (qs below).
#
# Made as textproc/opensearch-dashboards217, whose decisions hold here unless this
# says otherwise: the bundle of OpenSearch (the linux-x64 tarball; the official
# port's base) without its Node.js for Linux, on the node of our www/node24, named
# by its program (no USES=nodejs, as there); bin/use_node takes it
# (files/patch-bin_use__node, the same file as in 2.17.1, with its CONFIG_DIR typo,
# still in the main branch, fixed too, so that node.options of the configuration is
# read); the rc script, node.options, newsyslog (10 MB, no archives), pkg-deinstall,
# pkg-descr and the refusal of the settings of plugins it does not have, as there.
#
# Node.js: 2.19.7 is made for Node.js 18 (.nvmrc 18, .node-version 18.20.8,
# engines.node ">=14.20.1 <19"); its node/ has Node.js 18.20.8 and 14.21.3 (the
# fallback of bin/use_node) for Linux, the only ELF files of the tarball, which are
# not in the package. src/setup_node_env/node_version_validator.js is that of 2.17.1:
# it takes the first comparator of engines.node only (">=14.20.1"), so Node.js 24
# passes it. The code of its server calls none of the APIs Node.js 22 to 24 took
# away (util.is* and util.log, crypto.createCipher, tls.createSecurePair,
# process.binding, ...: none in src/ and in the server/ and common/ of its plugins
# at 2.19.7; in the node_modules of the tarball what has those names is the own util
# of bluebird and of zod, the ciphers of node-forge, builds for the browser (exceljs,
# aws-sdk, plotly.js, oui, object-hash, the workers of brace) and the fallbacks of
# lodash, safe-buffer and fs-minipass for versions of Node.js before 10 and 12.9).
# Node.js 24 warns of url.parse() alone (DEP0169, at the start: the opensearch.hosts
# of the configuration; reportsDashboards calls it too), and
# src/setup_node_env/exit_on_warning.js ends the process at the first warning unless
# Node.js runs with --no-warnings, as bin/opensearch-dashboards and the rc script run
# it. The linux-x64 tarball, prepared as here, answered on Node.js 24.22.2 against
# OpenSearch 2.19.7 without the plugins textproc/opensearch219 leaves out (green in
# 4 s; the routes of the 15 plugins in, reports, imports, Timeline, TSVB, sample
# data, the fixes below, a SIGHUP; a runner of GitHub, azsupport/ports, 13.11.2026).
# Its node_modules have no native module (no *.node; WebAssembly only: the
# tesseract.js-core of reportsDashboards, the mappings.wasm of source-map): nothing
# is built, the package is JavaScript.
#
# The plugins: the 16 of the bundle (the 14 of 2.17.1, flowFrameworkDashboards and
# queryInsightsDashboards), all whose server plugin textproc/opensearch219 has (aZ,
# 12.11.2026: out of it only the security plugin and what cannot run on FreeBSD,
# k-NN, neural-search and performance-analyzer, none of which has a plugin of its
# own in this bundle); so out only securityDashboards (no opensearch-security:
# connections without SSL and without a password), with the prefix of its settings,
# opensearch_security, which the rc script refuses. In, each with what it needs of
# the server (requiredOSDataSourcePlugins of its opensearch_dashboards.json):
# alertingDashboards (alerting), anomalyDetectionDashboards (anomaly-detection),
# assistantDashboards (ml, skills; assistant.chat.enabled is false by default),
# customImportMapDashboards (geospatial), flowFrameworkDashboards (flow-framework,
# ml: its presets of semantic, multimodal, hybrid and vector search make an index
# with index.knn of opensearch-knn, hybrid search with the normalization of
# neural-search, both left out of textproc/opensearch219: OpenSearch refuses those
# at their provisioning; its custom workflows and RAG with lexical retrieval, with
# the ml_inference processors of ml and its remote models, remain),
# indexManagementDashboards (index-management,
# job-scheduler), mlCommonsDashboards (ml), notificationsDashboards
# (notifications), observabilityDashboards (observability, sql),
# queryInsightsDashboards (query-insights: its top queries and settings, which are
# those of the cluster, search.insights.top_queries.*), queryWorkbenchDashboards
# (sql), reportsDashboards (reports-scheduler; no Chromium in 2.19.7 either: CSV
# and XLSX of saved searches made by the server, PDF and PNG by the browser),
# securityAnalyticsDashboards (security-analytics), ganttChartDashboards and
# searchRelevanceDashboards (none: its comparison of two searches is _search alone).
# The bundle's components are the 2.19.7 tags of OpenSearch Dashboards and the
# 2.19.7.0 tags of the plugins (its manifest.yml).
# The sample configuration is that of the min tarball: the bundle appends the
# settings of the security plugin (https, kibanaserver, opensearch_security.*) to
# it. The tarball has no .i18nrc.json of its own since 2.19 (the translations of
# the build are only copied with --with-translations): nothing to install of it.
#
# A fix of ours, still needed in 2.19.7 and in the main branch of OpenSearch
# Dashboards, as in textproc/opensearch-dashboards217: hapi 21 (21.4.10 in the
# bundle) still exposes the reconfigure() of @elastic/good (9.0.1-kibana3) as
# server.plugins.good (its expose() takes the scope off the name of a plugin), but
# src/legacy/server/osd_server.js asks server.plugins['@elastic/good']: at a SIGHUP
# (reload, newsyslog) it would log "Cannot read properties of undefined (reading
# 'reconfigure')", and the logging of the legacy server (the responses, the legacy
# plugins) would never open its file again.
#
# What textproc/opensearch-dashboards217 takes into 2.17.1 that 2.19.7 has already:
# the commits of the 2.17 branch after 2.17.1 (1b89a739, the check of large numerals,
# in @osd/std and the bundles; json11 2.0.0 and the client opensearch-next 2.13.0),
# CVE-2026-75897 (#12563), the redirects off-site (#12193), __proto__ keys in an
# import (#12085), the confinement of @hapi/inert (7.1.2), a js-yaml with its
# security fixes (4.3.2, for every user of js-yaml: a resolution of its
# package.json; securityAnalyticsDashboards loads a rule's YAML with its load(),
# which knows no !!js/function since js-yaml 4), and the parser of @hapi/content
# but the fix below (6.0.2).
# Security fixes after 2.19.7 that touch it, the server side (each with its
# source; the patches in files/patch-*, the npm package in OSD_NPM):
#  - @hapi/content 6.0.3 in the place of the 6.0.2 of the tarball (OpenSearch
#    Dashboards 44216f89, #13093, main, 29.10.2026; CVE-2026-115728): its parser of
#    Content-Disposition backtracked quadratically on a long parameter without "=",
#    which blocked the event loop (every multipart request: the imports of saved
#    objects); the package of the npm registry, its sha512 that of the registry;
#  - Timeline (1a09720a, #12217, main, 15.06.2026): a datasource function chained
#    after another one (.es().es()) starts a series of its own instead of being
#    given the series before it (a DoS of chained datasource functions);
#  - the counts of saved objects (23a4a157, #12191, main, 10.06.2026): at most 100
#    entries in each array of POST
#    /api/opensearch-dashboards/management/saved_objects/scroll/counts, where a
#    request of less than 1 MiB with 40000 of them ran the heap of the process out;
#  - the imports of saved objects (50c470c0, #12189, main, 10.06.2026): no
#    Content-Encoding on _import and _resolve_import_errors (400), whose body hapi
#    decompresses before the maxBytes of the multipart parser applies (a gzip of a
#    few MiB, many GiB decompressed, took the memory of the process).
# Each is reached by everyone who reaches Dashboards: without the security plugin
# there is no authentication. The last three are in 2.17.1 as well.
# Not taken, and why: #10987 (92d926d6, main: TSVB reads a value of a row by a path
# of the request with lodash get(), __proto__ included; it reads, writes nothing);
# the fixes of 3.x in the code of the browser (the field formats of the document
# table, #12190; the browser storage, #12984), compiled into the bundles, each
# needing a user who can save objects, which without the security plugin is
# everyone who reaches Dashboards, who can do anything through its console anyway
# (those of the browser that textproc/opensearch-dashboards217 leaves out are in
# 2.19.7: the axis labels, #11385 and #11435; URL and image labels, #11386; Vega,
# #12622 and VEGA_DEBUG, #11258; less, #11389; the integrations of
# observabilityDashboards, CVE-2026-77811, since its 2.19.6). CVE-2026-18420: the mathjs
# evaluator of TSVB in 3.x; 2.19.7 evaluates with tinymath. Workspaces (#12186, the
# permissions of their collaborators): workspace.enabled is off.
# Advisories of npm packages the server does not reach here: qs (6.16.0; the url
# package of the browser bundles, express, test tools), body-parser and express (of
# @modelcontextprotocol/sdk, which no code of the server loads), node-forge (1.4.0;
# PKCS#12 keystores: no SSL here), axios, form-data and follow-redirects (the
# branding URLs of the configuration only), handlebars (the bootstrap template of
# the package), moment (the locale of the configuration), and those of
# textproc/opensearch-dashboards217 that 2.19.7 has in newer versions or not at all
# (lodash, minimatch, picomatch, brace-expansion, decode-uri-component, ip-address,
# joi, ajv, uuid, cookie, aws-sdk, bn.js, @babel/runtime, json-2-csv 5 of
# reporting, the jsdom, dompurify, ws and form-data of the assistant); those of the
# browser are compiled into the bundles.

PORTNAME=	opensearch-dashboards
DISTVERSION=	2.19.7
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONSUFFIX=	-linux-x64
CATEGORIES=	textproc www
MASTER_SITES=	https://artifacts.opensearch.org/releases/bundle/${PORTNAME}/${DISTVERSION}/ \
		https://registry.npmjs.org/@hapi/content/-/:content
PKGNAMESUFFIX=	219
DISTFILES=	${DISTNAME}${EXTRACT_SUFX} \
		content-${CONTENT_VERSION}.tgz:content
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	Visualization dashboards for OpenSearch (of azsupport/ports)
WWW=		https://opensearch.org \
		https://github.com/azsupport/ports

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE.txt

# node to build too: the checks of the package
BUILD_DEPENDS=	node:www/node24
RUN_DEPENDS=	node:www/node24

USE_RC_SUBR=	${PORTNAME}

# the same files as textproc/opensearch-dashboards217 and the official ports: pkg
# install opensearch-dashboards219 takes the place of opensearch-dashboards217
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

CONTENT_VERSION=	6.0.3

# <plugin>:<the prefix of its settings> of the plugins left out (see the top)
OSD_PLUGINS_OUT=	securityDashboards:opensearch_security
OSD_PLUGINS_IN=		alertingDashboards anomalyDetectionDashboards \
			assistantDashboards customImportMapDashboards \
			flowFrameworkDashboards ganttChartDashboards \
			indexManagementDashboards mlCommonsDashboards \
			notificationsDashboards observabilityDashboards \
			queryInsightsDashboards queryWorkbenchDashboards \
			reportsDashboards searchRelevanceDashboards \
			securityAnalyticsDashboards
# the files of files/patch-*, whose backups (.orig) patch(1) leaves
OSD_PATCHED=	bin/use_node \
		src/core/server/saved_objects/routes/index.js \
		src/plugins/saved_objects_management/server/routes/scroll_count.js \
		src/plugins/vis_type_timeline/server/handlers/chain_runner.js
# npm packages in the place of those of the tarball: <tarball>:<directory>
OSD_NPM=	content-${CONTENT_VERSION}.tgz:node_modules/@hapi/content
# the check of large numerals with the typo of 1b89a739 (x < MAX || x > MAX)
OSD_NUMERALS_LEFT=	\([A-Za-z_$$][A-Za-z0-9_$$]*\)[[:space:]]*<[[:space:]]*Number\.MAX_SAFE_INTEGER[[:space:]]*||[[:space:]]*\1[[:space:]]*>

# the packages of OSD_NPM, each in the place of the directory of the tarball (its own
# node_modules kept, if it has one)
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
	@if ${GREP} -n -E '^[^#[:space:]]' ${WRKSRC}/config/opensearch_dashboards.yml | ${GREP} -v -x '1:---'; then \
		${ECHO_MSG} "config/opensearch_dashboards.yml: settings left in the sample"; ${FALSE}; fi
	${PRINTF} '%s\n' '' \
		'# azsupport/ports: this package has no security plugin (securityDashboards):' \
		'# OpenSearch Dashboards talks to OpenSearch over plain http without credentials' \
		'# (opensearch.hosts). The rc script refuses to start with a setting of that' \
		'# plugin (opensearch_security.*): OpenSearch Dashboards would stop at its start' \
		'# on it.' \
		>> ${WRKSRC}/config/opensearch_dashboards.yml
.for p in ${OSD_PLUGINS_OUT:C/:.*//}
	${RM} -r ${WRKSRC}/plugins/${p}
.endfor
	@[ "$$(cd ${WRKSRC}/plugins && ${LS} | ${XARGS})" = "${OSD_PLUGINS_IN:ts }" ] || \
		{ ${ECHO_MSG} "plugins: $$(cd ${WRKSRC}/plugins && ${LS} | ${XARGS}), not ${OSD_PLUGINS_IN}"; ${FALSE}; }
# reconfigure() of good at a SIGHUP (see the top)
	${REINPLACE_CMD} -e "s|this\.server\.plugins\[[\"']@elastic/good[\"']]\.reconfigure(|this.server.plugins.good.reconfigure(|" \
		${WRKSRC}/src/legacy/server/osd_server.js
	@${GREP} -q 'this\.server\.plugins\.good\.reconfigure(' ${WRKSRC}/src/legacy/server/osd_server.js || \
		{ ${ECHO_MSG} "src/legacy/server/osd_server.js: the reconfigure() of good not fixed"; ${FALSE}; }
# 1b89a739 is in 2.19.7 (above): no copy of its typo left, in @osd/std and the bundles
	@${GREP} -rq -E '<[[:space:]]*Number\.MIN_SAFE_INTEGER[[:space:]]*\|\|' --include='*.js' \
		${WRKSRC}/node_modules/@osd/std || \
		{ ${ECHO_MSG} "node_modules/@osd/std: not the check of large numerals of 1b89a739"; ${FALSE}; }
	@cd ${WRKSRC} && ${GREP} -rl -E 'Number\.MAX_SAFE_INTEGER[[:space:]]*\|\|' --include='*.js' \
		node_modules/@osd node_modules/@opensearch-project/opensearch-next src plugins | \
		while read f; do \
			if ${SED} -n -e '/${OSD_NUMERALS_LEFT}/p' $$f | ${GREP} -q .; then \
				${ECHO_MSG} "1b89a739: $$f has the typo"; exit 1; fi; \
		done

do-install:
	${MKDIR} ${STAGEDIR}${WWWDIR} ${STAGEDIR}${ETCDIR} ${STAGEDIR}${PREFIX}/etc/newsyslog.conf.d
	${INSTALL_DATA} ${WRKSRC}/config/opensearch_dashboards.yml ${STAGEDIR}${ETCDIR}/opensearch_dashboards.yml.sample
	${INSTALL_DATA} ${WRKSRC}/config/node.options ${STAGEDIR}${ETCDIR}/node.options.sample
	${INSTALL_DATA} ${FILESDIR}/newsyslog.conf \
		${STAGEDIR}${PREFIX}/etc/newsyslog.conf.d/opensearch_dashboards.conf.sample
	(cd ${WRKSRC} && \
		${COPYTREE_SHARE} "NOTICE.txt data node_modules package.json plugins src" ${STAGEDIR}${WWWDIR} && \
		${COPYTREE_BIN} bin ${STAGEDIR}${WWWDIR})
	${INSTALL} -lrs ${STAGEDIR}${ETCDIR} ${STAGEDIR}${WWWDIR}/config

# the package: no ELF file, no native module, no backup of a patch, the node of
# www/node24, the version, the packages of OSD_NPM
post-install:
	@if ${FIND} ${STAGEDIR}${WWWDIR} -type f -exec ${FILE} {} + | ${GREP} -E ': .*(ELF|Mach-O|PE32)'; then \
		${ECHO_MSG} "binaries in the package"; ${FALSE}; fi
	@if ${FIND} ${STAGEDIR}${WWWDIR} \( -name '*.node' -o -name '*.orig' -o -name '*.rej' -o -path '*/node/bin/*' \) | \
		${GREP} .; then ${ECHO_MSG} "these files must not be in the package"; ${FALSE}; fi
# (its configuration: that of the work tree, as the package has the samples only;
# bin/opensearch-dashboards reads it to set up APM before it parses its arguments;
# --allow-root: its tools stop as root without it, src/setup_node_env/root, and the
# build is root)
	@v="$$(cd /tmp && ${SETENV} HOME=${WRKDIR} OSD_PATH_CONF=${WRKSRC}/config ${STAGEDIR}${WWWDIR}/bin/opensearch-dashboards --version --allow-root 2>&1)"; \
		[ "$$v" = "${DISTVERSION}" ] || \
		{ ${ECHO_MSG} "bin/opensearch-dashboards --version does not say ${DISTVERSION}: $$v"; ${FALSE}; }
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
