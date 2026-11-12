# textproc/kibana6 of azsupport/ports: Kibana 6.8.23, the last of 6.x (aZ, 11.11.2026:
# for the legacy sites, with textproc/elasticsearch6, at its version), back in the
# ports on the Node.js 24 of this tree, www/node24 (aZ: the latest Node.js of the
# ports), not on the Node.js 10.24.1 it was made for. The official port went on
# 2022-03-31 with www/node10, at 6.8.16; this is its last state (branch 2022Q1: the
# darwin tarball, the rc script with daemon(8), the user www, the log file,
# www/kibana6 with config a link to etc/kibana, pkg-deinstall, the patch of
# src/setup_node_env/index.js) with what Node.js 24 needs. Why the darwin tarball:
# Kibana takes the files of macOS on FreeBSD (the browsers of Reporting:
# x-pack/plugins/reporting/server/browsers/*/paths.js); with what cannot run on
# FreeBSD taken out, the darwin and the linux tarball are the same files.
# The others that packaged Kibana 6 took the version check of Node.js out and ran
# it on their Node.js, with no patch for it: OpenBSD www/kibana (the darwin
# tarball too, 6.x until 2019 with package.json set to its Node.js 10, bin/* to
# its node as here; removed in 2023 as unusable), Gentoo www-apps/kibana-bin (its
# last 6.8.23, on Node.js 10 to 13 only), kibana6 of the AUR (6.8.13 on the nodejs
# of Arch); pkgsrc and Debian have none. For node-re2 the official textproc/kibana8
# and kibana9x of today: built with node-gyp for the Node.js of the ports.
# For Node.js 24:
#  - src/setup_node_env/node_compat.js (files/node_compat.js), which index.js loads
#    in the place of the version check, in every process of Kibana: util.is* and
#    util.log (removed in Node.js 23) as Node.js 10 had them; MD5 in the place of MD4
#    (OpenSSL 3 has it in its legacy provider only) for the names webpack 4 makes
#    when Kibana builds its bundles; a rejected promise that nothing handles a
#    warning, as in Node.js 10, not the end of Kibana; the IPv4 address of a name
#    first (server.host is "localhost": 127.0.0.1:5601 as before, not [::1]:5601).
#  - hapi 17.9.4 (@commercial/hapi) with the fixes of hapi for Node.js 11 and 16
#    (hapi a3a5ca97, 1288112c, 4639686a, 0d32840c): since Node.js 16 a request emits
#    "close" once its body is read, which hapi 17 took for the client gone, so no
#    POST had an answer. With them the tests of hapi 17.9.4 pass on Node.js 24 but
#    for 6 of 889 (the wording of three errors of V8, two tests that take destroy()
#    away from a stream, one simulated close of an injected request). Its two files
#    have CRLF line ends in the tarball: USES=dos2unix for the patches.
#  - re2 (Timelion's .label() with a regular expression): the tarball has re2 1.14.0
#    built for Node.js 10 of macOS (NODE_MODULE_VERSION 64; Node.js 24 has 137, and
#    1.14.0 does not build for it): node-re2 1.27.1 in its place (the latest, that
#    of the official kibana8), built here with node-gyp of www/npm-node24 and nan, as
#    npm builds it: with the RE2 and abseil it vendors compiled into re2.node, no
#    library of the ports (aZ, 12.11.2026: RE2 in this port, its only user, no port
#    of RE2 or abseil). Those are the commits of their release tags: RE2 2025-11-05,
#    the version of the official devel/re2, and abseil 20260817.0, an LTS release
#    (absl::lts_20260817; the official devel/abseil has 20250127.1 with two patches,
#    one in 20260817.0 already, one for PowerPC). RE2_VENDOR_RE2 and
#    RE2_VENDOR_ABSEIL name them and post-extract checks them: a node-re2 that
#    vendors others stops the build until they are written down.
# Machine Learning and Reporting off, as the official port meant it (XPACK_ML_ENABLED
# and XPACK_REPORTING_ENABLED in the environment of its rc script, which only the
# Docker image of Kibana reads; the official kibana7 to kibana9x pass
# --xpack.reporting.enabled=false): in the sample kibana.yml and by the rc script
# (kibana_args) for an older kibana.yml too. ML needs the machine learning of
# Elasticsearch (not on FreeBSD), Reporting unpacks and starts the Chromium of
# macOS at every start. Out of the package: node/ (the Node.js 10 of macOS), the
# two browsers. The bundles of the browser are built in the build (bin/kibana
# --optimize, half a minute, 1 GB) for these plugins: the official port left that
# to the first start, the tarball has them for all plugins only. Built on Node.js
# 24 they are not byte for byte those of Node.js 10 (the numbers webpack gives the
# modules follow Array.sort, stable since V8 7.0; the same with MD4 and with MD5):
# their pages were compared in Chrome with those of Kibana on its own Node.js 10,
# as were the answers of its API.

PORTNAME=	kibana
PORTVERSION=	6.8.23
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONSUFFIX=	-darwin-x86_64
CATEGORIES=	textproc www
MASTER_SITES=	https://artifacts.elastic.co/downloads/kibana/ \
		https://registry.npmjs.org/re2/-/:re2 \
		https://registry.npmjs.org/nan/-/:nan
PKGNAMESUFFIX=	6
DISTFILES=	${DISTNAME}${EXTRACT_SUFX} \
		re2-${RE2_VERSION}.tgz:re2 \
		nan-${NAN_VERSION}.tgz:nan
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	Browser based analytics and search interface to Elasticsearch (of azsupport/ports)
WWW=		https://www.elastic.co/kibana \
		https://github.com/azsupport/ports

# The licenses of what this package has (aZ, 12.11.2026: X-Pack stays, for its
# monitoring; the official port named Apache 2.0 alone). The tarball is the
# default distribution: its LICENSE.txt is the Elastic License agreement (1.0,
# that of 6.x), under which the binaries of the default distribution are ("The
# build produces two sets of binaries - one set that falls under the Elastic
# License and another set that falls under Apache License Version 2.0":
# LICENSE.txt of elastic/kibana at v6.8.23; its build copies
# licenses/ELASTIC-LICENSE.txt to LICENSE.txt, src/dev/build/tasks/
# license_file_task.js); the code outside x-pack is under Apache 2.0 (the same
# file; NOTICE.txt of the tarball begins "Kibana with X-Pack", the name its build
# gives the default distribution, src/dev/build/tasks/notice_file_task.js).
# node-re2 and re2 under the BSD license of three clauses, abseil under Apache
# 2.0. post-patch checks which file is which.
# What the Elastic License 1.0 allows (its text, the LICENSE.txt of the tarball):
# the use of the Basic features at no charge (1.1), for the internal business
# operations of the licensee and of its contractors and affiliates (6.5); not to
# "transfer, sell, rent, lease, distribute, sublicense [...] Elastic Software
# Object Code, in whole or in part, to any third party" (1.2 iii), nor to
# "modify, copy or use" it otherwise (1.2 ii); for a distribution, commercial or
# not, Elastic's permission (1.2, its end). So none of the permissions of the
# ports for it: no mirror and no sale of the distfile or of the package, and no
# acceptance for the user (it is an agreement that the use accepts).
LICENSE=	APACHE20 BSD3CLAUSE ELASTIC10
LICENSE_COMB=	multi
LICENSE_NAME_ELASTIC10=	Elastic License 1.0 (the default distribution: X-Pack)
LICENSE_FILE_ELASTIC10=	${WRKSRC}/LICENSE.txt
LICENSE_PERMS_ELASTIC10=	none

# uv.h, which nan includes: of the libuv of az, which our node24 links (the
# official kibana8 has devel/libuv for it)
BUILD_DEPENDS=	npm-node24>0:www/npm-node24 \
		${AZ_PREFIX}/include/uv.h:az/az

USES=		compiler:c++20-lang cpe dos2unix gmake nodejs:24,build,run python:build
CPE_VENDOR=	elastic
USE_RC_SUBR=	${PORTNAME}

CONFLICTS_INSTALL=	kibana kibana[0-9] kibana[0-9][0-9]

WWWDIR=		${PREFIX}/www/${PORTNAME}${PKGNAMESUFFIX}

SUB_FILES=	pkg-deinstall pkg-message
SUB_LIST+=	PKGNAMESUFFIX=${PKGNAMESUFFIX} \
		PORTNAME=${PORTNAME}

# sed without a backup: the whole tree goes into the package
REINPLACE_ARGS=	-i ''

RE2_VERSION=	1.27.1
NAN_VERSION=	2.30.0
# the RE2 and abseil that node-re2 vendors and re2.node has (post-extract):
# vendor/re2, the version of its MODULE.bazel; vendor/abseil-cpp, the LTS of the
# inline namespace (absl/base/options.h) and its patch level (absl/base/config.h:
# a patch release keeps the namespace)
RE2_VENDOR_RE2=	2025-11-05
RE2_VENDOR_ABSEIL=	20260817.0
RE2_WRKSRC=	${WRKDIR}/re2
NODE_GYP=	${LOCALBASE}/bin/node ${LOCALBASE}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js

# node-gyp: the headers of node in ${LOCALBASE}/include/node, uv.h of az; abseil
# takes backtrace() of libexecinfo on FreeBSD
CPPFLAGS+=	-I${AZ_PREFIX}/include
LDFLAGS+=	-lexecinfo

# the two files of hapi the patches change (CRLF in the tarball)
DOS2UNIX_FILES=	node_modules/@commercial/hapi/lib/request.js \
		node_modules/@commercial/hapi/lib/transmit.js
# what cannot run on FreeBSD: the Node.js 10 of macOS, the browsers of Reporting;
# re2 1.14.0 for Node.js 10 of macOS (ours in its place)
KIBANA_FOREIGN=	node \
		node_modules/re2 \
		node_modules/x-pack/plugins/reporting/.chromium \
		node_modules/x-pack/plugins/reporting/.phantom
# the files of files/patch-*, whose backups (.orig) patch(1) leaves
KIBANA_PATCHED=	config/kibana.yml \
		${DOS2UNIX_FILES} \
		src/setup_node_env/index.js
KIBANA_BINS=	kibana kibana-keystore kibana-plugin
# Kibana as the build runs it: its Node.js, no cache of babel
KIBANA_ENV=	HOME=${WRKDIR} NODE_ENV=production BABEL_DISABLE_CACHE=1

post-extract:
	${MKDIR} ${RE2_WRKSRC}/node_modules/nan
	${TAR} -xf ${DISTDIR}/re2-${RE2_VERSION}.tgz -C ${RE2_WRKSRC} --strip-components 1
	${TAR} -xf ${DISTDIR}/nan-${NAN_VERSION}.tgz -C ${RE2_WRKSRC}/node_modules/nan --strip-components 1
# the RE2 and abseil node-re2 vendors: those of RE2_VENDOR_RE2 and RE2_VENDOR_ABSEIL
	@v="$$(${SED} -n '/^module(/,/^)/s/^ *version = "\(.*\)",$$/\1/p' ${RE2_WRKSRC}/vendor/re2/MODULE.bazel)"; \
	[ "$$v" = "${RE2_VENDOR_RE2}" ] || \
		{ ${ECHO_MSG} "node-re2 ${RE2_VERSION} vendors RE2 $${v:-of no version} (vendor/re2/MODULE.bazel), not ${RE2_VENDOR_RE2}: write it into RE2_VENDOR_RE2"; ${FALSE}; }
	@n="$$(${SED} -n 's/^#define ABSL_OPTION_INLINE_NAMESPACE_NAME //p' ${RE2_WRKSRC}/vendor/abseil-cpp/absl/base/options.h)"; \
	p="$$(${SED} -n 's/^#define ABSL_LTS_RELEASE_PATCH_LEVEL //p' ${RE2_WRKSRC}/vendor/abseil-cpp/absl/base/config.h)"; \
	[ "$$n.$$p" = "lts_${RE2_VENDOR_ABSEIL}" ] || \
		{ ${ECHO_MSG} "node-re2 ${RE2_VERSION} vendors abseil $${n:-of no namespace}, patch level $${p:-none} (vendor/abseil-cpp/absl/base/options.h, config.h), not ${RE2_VENDOR_ABSEIL}: write it into RE2_VENDOR_ABSEIL"; ${FALSE}; }
# the tarball is what this port was made for: one native module, that of re2
	@[ "$$(cd ${WRKSRC} && ${FIND} . -name '*.node' -not -path './node/*')" = ./node_modules/re2/build/Release/re2.node ] || \
		{ ${ECHO_MSG} "the tarball has other native modules than that of re2:"; \
		cd ${WRKSRC} && ${FIND} . -name '*.node' -not -path './node/*'; ${FALSE}; }

post-patch:
	# the license files of the tarball: LICENSE.txt the Elastic License agreement,
	# NOTICE.txt that of Kibana with X-Pack (LICENSE_FILE_ELASTIC10)
	@[ "$$(${HEAD} -n 1 ${WRKSRC}/LICENSE.txt)" = "ELASTIC LICENSE AGREEMENT" ] && \
		${GREP} -q '^  1\.1 Object Code End User License\.' ${WRKSRC}/LICENSE.txt && \
		${GREP} -q 'distribute, sublicense, loan or otherwise transfer, Elastic Software Object' ${WRKSRC}/LICENSE.txt && \
		[ "$$(${HEAD} -n 1 ${WRKSRC}/NOTICE.txt)" = "Kibana with X-Pack" ] || \
		{ ${ECHO_MSG} "LICENSE.txt, NOTICE.txt of the tarball: not the Elastic License 1.0 and the notice of Kibana with X-Pack: $$(${HEAD} -n 1 ${WRKSRC}/LICENSE.txt), $$(${HEAD} -n 1 ${WRKSRC}/NOTICE.txt)"; ${FALSE}; }
	${RM} ${KIBANA_PATCHED:S|^|${WRKSRC}/|:S|$|.orig|}
	${CP} ${FILESDIR}/node_compat.js ${WRKSRC}/src/setup_node_env/node_compat.js
# bin/kibana, kibana-keystore and kibana-plugin: the node of www/node24 (they
# look for node/bin/node of the tarball, then for the first node of PATH)
	${REINPLACE_CMD} -e 's|^NODE="$${DIR}/node/bin/node"$$|NODE="${LOCALBASE}/bin/node"|' \
		${KIBANA_BINS:S|^|${WRKSRC}/bin/|}
	@for f in ${KIBANA_BINS}; do \
		${GREP} -q '^NODE="${LOCALBASE}/bin/node"$$' ${WRKSRC}/bin/$$f || \
		{ ${ECHO_MSG} "bin/$$f: no NODE= line set"; ${FALSE}; }; \
	done
.for d in ${KIBANA_FOREIGN}
	${RM} -r ${WRKSRC}/${d}
.endfor
	${FIND} -s ${WRKSRC}/node_modules -type d -empty -delete

# re2 for the Node.js of the ports, with its headers (${LOCALBASE}/include/node);
# then the bundles for the plugins of kibana.yml (ML and Reporting off): Kibana's
# own --optimize, as kibana-plugin runs it, with that re2 in its place
do-build:
	cd ${RE2_WRKSRC} && ${SETENV} ${MAKE_ENV} HOME=${WRKDIR} V=1 ${NODE_GYP} rebuild \
		--nodedir=${LOCALBASE} --python=${PYTHON_CMD} --jobs=${MAKE_JOBS_NUMBER}
	${MKDIR} ${WRKSRC}/node_modules/re2/build/Release
	${INSTALL_DATA} ${RE2_WRKSRC}/re2.js ${RE2_WRKSRC}/package.json ${RE2_WRKSRC}/LICENSE \
		${WRKSRC}/node_modules/re2/
	${INSTALL_LIB} ${RE2_WRKSRC}/build/Release/re2.node ${WRKSRC}/node_modules/re2/build/Release/
	cd ${WRKSRC} && ${SETENV} ${KIBANA_ENV} ${LOCALBASE}/bin/node --no-warnings \
		--max-old-space-size=4096 src/cli --optimize \
		--config ${WRKSRC}/config/kibana.yml --path.data=${WRKDIR}/data
	@${TEST} -s ${WRKSRC}/optimize/bundles/kibana.bundle.js || \
		{ ${ECHO_MSG} "optimize/bundles: no kibana.bundle.js"; ${FALSE}; }
	@if ${GREP} -l -e '"ml"' -e '"reporting"' ${WRKSRC}/optimize/bundles/*.entry.js; then \
		${ECHO_MSG} "optimize/bundles: built with ML or Reporting"; ${FALSE}; fi
	@if [ -e ${WRKSRC}/optimize/bundles/ml.bundle.js ]; then \
		${ECHO_MSG} "optimize/bundles: ml.bundle.js of the tarball is still there"; ${FALSE}; fi
	${RM} -r ${WRKSRC}/optimize/.cache

do-install:
	${MKDIR} ${STAGEDIR}${WWWDIR} ${STAGEDIR}${ETCDIR}
	${INSTALL_DATA} ${WRKSRC}/config/kibana.yml ${STAGEDIR}${ETCDIR}/kibana.yml.sample
	(cd ${WRKSRC} && \
		${RM} -r config && \
		${COPYTREE_SHARE} . ${STAGEDIR}${WWWDIR} && \
		${COPYTREE_BIN} bin ${STAGEDIR}${WWWDIR})
	${INSTALL} -lrs ${STAGEDIR}${ETCDIR} ${STAGEDIR}${WWWDIR}/config
	${STRIP_CMD} ${STAGEDIR}${WWWDIR}/node_modules/re2/build/Release/re2.node

post-install:
# the package: re2 loads in the Node.js of the ports and works, the node of
# bin/kibana, no backup of a patch, nothing of macOS
	@${LOCALBASE}/bin/node -e 'const RE2 = require(process.argv[1]); \
		if ("x aaa".replace(new RE2("(a+)"), "<$$1>") !== "x <aaa>") { process.exit(1); }' \
		${STAGEDIR}${WWWDIR}/node_modules/re2 || \
		{ ${ECHO_MSG} "node_modules/re2 does not work in ${LOCALBASE}/bin/node"; ${FALSE}; }
	@[ "$$(${SETENV} ${KIBANA_ENV} ${STAGEDIR}${WWWDIR}/bin/kibana --version)" = "${PORTVERSION}" ] || \
		{ ${ECHO_MSG} "bin/kibana --version does not say ${PORTVERSION}"; ${FALSE}; }
	@if ${FIND} ${STAGEDIR}${WWWDIR} \( -name '*.orig' -o -name '*.rej' -o -path '*/node/bin/node' \) | \
		${GREP} .; then ${ECHO_MSG} "these files must not be in the package"; ${FALSE}; fi
	@[ "$$(cd ${STAGEDIR}${WWWDIR} && ${FIND} . -name '*.node')" = ./node_modules/re2/build/Release/re2.node ] || \
		{ ${ECHO_MSG} "native modules other than ours of re2 in the package"; ${FALSE}; }
	${ECHO} "@sample ${ETCDIR}/kibana.yml.sample" >> ${TMPPLIST}
	${FIND} -s ${STAGEDIR}${WWWDIR} -not -type d | ${SORT} | \
		${SED} -e 's#^${STAGEDIR}${PREFIX}/##' >> ${TMPPLIST}
	${ECHO} "@dir(www,www) ${WWWDIR}/data" >> ${TMPPLIST}
	${ECHO} "@dir ${WWWDIR}/plugins" >> ${TMPPLIST}

.include <bsd.port.mk>
