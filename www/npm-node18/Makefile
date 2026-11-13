# www/npm-node18 of azsupport/ports: npm of our www/node18 (aZ, 11.11.2026: Node.js
# 18 for a legacy project), the official www/npm-node24 of the pinned tree with npm
# 10.9.10, the last npm for Node 18 (npm 10: ^18.17.0 || >=20.5.0; npm 11 and later
# need Node 20 or later), its own distinfo and pkg-plist (the plist of the official
# port made the same way for this tarball) and the fixes below. Without
# USES=nodejs: the official Mk/Uses/nodejs.mk of the pin knows Node 22, 24 and 26
# only, and a Mk/Uses/nodejs.mk of this tree would be read by npm-node24 and
# yarn-node24 too (in their az_hash: they would build again with each change) and
# have to follow the official one at each move of the pin, for what
# USES=nodejs:18,run gives: the RUN_DEPENDS on node of www/node18 and the suffix
# -node18, written here. npm-node18 and npm-node24, one of the two
# (CONFLICTS_INSTALL, the same files). Of what it takes, gmake and Python (node-gyp)
# are official packages.
# The vulnerabilities of what npm 10.9.10 bundles (the audit database of the
# registry, 13.11.2026; no npm 10.x release has their fixes): CVE-2026-9496 of its
# pacote 19.0.3 and of the pacote 20.0.1 of @npmcli/metavuln-calculator (fixed in
# pacote 21.5.1) by files/patch-CVE-2026-9496; four bundled dependencies replaced
# by a newer release of the same major version, of the registry, which the
# packages of npm that take them take by their ranges, with the files npm keeps of
# a bundled dependency (the node_modules/.gitignore of npm/cli: no README*,
# CHANGELOG*, *.ts, *.map):
#   brace-expansion 2.0.2 (CVE-2026-33750, CVE-2026-13149, CVE-2026-14257,
#     CVE-2026-69152, CVE-2026-102276, CVE-2026-102277, CVE-2026-102278; fixed in
#     2.1.7): 2.1.8, the newest 2.x, for minimatch 9.0.9 (^2.0.2); it also bounds
#     the work of one expansion, which 2.1.7 does not
#   ip-address 10.1.0 (CVE-2026-42338, CVE-2026-69192, CVE-2026-101911,
#     CVE-2026-101912, CVE-2026-101913, CVE-2026-111997; fixed in 10.7.4): 10.7.6,
#     the newest 10.x, for socks 2.8.7 (^10.0.1)
#   picomatch 4.0.3 (CVE-2026-33671, CVE-2026-33672; fixed in 4.0.4): 4.0.7, the
#     newest 4.x, for tinyglobby 0.2.15 (^4.0.3; the globs of node-gyp) and fdir
#     6.5.0; 4.0.5 gives back the branches that the ReDoS fix of 4.0.4 dropped
#     from a repeated extglob (+(*(a)|*(b)) matched no b)
#   postcss-selector-parser 7.1.1 (CVE-2026-9358, CVE-2026-104844; fixed in 7.1.6):
#     7.1.8, the newest 7.1.x, for @npmcli/query 4.0.1 (^7.0.0; npm query): it
#     closes one more CPU exhaustion (GHSA-67xj-gfww-g738 of its changelog, not in
#     the audit database yet) and has its own copy of cssesc (the cssesc npm
#     bundles stays, with its bin); not 7.2.x, which adds features and changes
#     behaviour (7.2.0 escaped class and id values, which 7.2.1 took back)
# The plist is that of npm 10.9.10 with the two files postcss-selector-parser 7.1.8
# adds (dist/util/cssesc.js, dist/util/maxNestingDepth.js).
# Not taken: what has its fix only in a new major version, outside the ranges of
# the packages of npm that take it: glob 10.5.0 (CVE-2026-118773, fixed in 14.0.2,
# which takes minimatch 11 and path-scurry 3; npm ^10.5.0, cacache,
# @npmcli/package-json and @npmcli/map-workspaces ^10.2.2), minimatch 9.0.9
# (CVE-2026-118764, fixed in 11.0.1, which takes brace-expansion 5; npm ^9.0.9, its
# glob, @npmcli/arborist, ignore-walk, libnpmdiff and the others ^9), sigstore
# 3.1.0 (CVE-2026-48815, fixed in 4.1.1, which needs Node ^20.17.0 || >=22.9.0;
# pacote and libnpmpublish ^3.0.0) and @sigstore/core 2.0.0 (CVE-2026-48758, fixed
# in 3.2.1, the same Node; sigstore 3, @sigstore/sign and @sigstore/verify ^2.0.0).
# npm 12.2.2 of npm-node24 has none of these but glob and minimatch (pacote 22.0.1,
# brace-expansion 5.0.12, ip-address 10.7.5, picomatch and postcss-selector-parser
# without an advisory).

PORTNAME=	npm
PORTVERSION=	10.9.10
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://registry.npmjs.org/${PORTNAME}/-/ \
		https://registry.npmjs.org/brace-expansion/-/:brace \
		https://registry.npmjs.org/ip-address/-/:ipaddress \
		https://registry.npmjs.org/picomatch/-/:picomatch \
		https://registry.npmjs.org/postcss-selector-parser/-/:postcss
PKGNAMESUFFIX=	-node18
DISTFILES=	${DISTNAME}${EXTRACT_SUFX} \
		brace-expansion-${BRACE_EXPANSION_VERSION}.tgz:brace \
		ip-address-${IP_ADDRESS_VERSION}.tgz:ipaddress \
		picomatch-${PICOMATCH_VERSION}.tgz:picomatch \
		postcss-selector-parser-${POSTCSS_SELECTOR_PARSER_VERSION}.tgz:postcss
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	Node package manager (of azsupport/ports)
WWW=		https://www.npmjs.com/package/npm \
		https://docs.npmjs.com/ \
		https://github.com/npm/cli \
		https://github.com/azsupport/ports

LICENSE=	ART20
LICENSE_FILE=	${WRKSRC}/LICENSE

RUN_DEPENDS=	gmake:devel/gmake \
		node:www/node18

USES=		cpe python shebangfix tar:tgz
CPE_VENDOR=	npmjs
SHEBANG_GLOB=	*.py

CONFLICTS_INSTALL=	npm-node[0-9][0-9]

REINPLACE_ARGS=	-i ''
NO_ARCH=	yes
NO_BUILD=	yes
PORTSCOUT=	ignore:1

WRKSRC=		${WRKDIR}/package

# the bundled dependencies of the registry in the place of those of npm (see the top)
BRACE_EXPANSION_VERSION=	2.1.8
IP_ADDRESS_VERSION=	10.7.6
PICOMATCH_VERSION=	4.0.7
POSTCSS_SELECTOR_PARSER_VERSION=	7.1.8

NPM_DIR=	lib/node_modules/npm
# Executables of the bundled dependencies, as linked by "npm install"
NPM_BINS=	arborist:@npmcli/arborist/bin/index.js cssesc:cssesc/bin/cssesc \
		installed-package-contents:@npmcli/installed-package-contents/bin/index.js \
		node-gyp:node-gyp/bin/node-gyp.js node-which:which/bin/which.js \
		nopt:nopt/bin/nopt.js pacote:pacote/bin/index.js \
		qrcode-terminal:qrcode-terminal/bin/qrcode-terminal.js \
		semver:semver/bin/semver.js

post-extract:
.for p v in brace-expansion ${BRACE_EXPANSION_VERSION} ip-address ${IP_ADDRESS_VERSION} \
	picomatch ${PICOMATCH_VERSION} postcss-selector-parser ${POSTCSS_SELECTOR_PARSER_VERSION}
	${RM} -r ${WRKSRC}/node_modules/${p}
	${MKDIR} ${WRKSRC}/node_modules/${p}
	${TAR} -xf ${DISTDIR}/${p}-${v}.tgz -C ${WRKSRC}/node_modules/${p} --strip-components 1 \
		--exclude 'README*' --exclude 'CHANGELOG*' --exclude '*.ts' --exclude '*.map'
.endfor

post-patch:
	@${REINPLACE_CMD} -e '/^exec/ s|python|${PYTHON_CMD}|' ${WRKSRC}/node_modules/node-gyp/gyp/gyp
	@${FIND} ${WRKSRC}/ -name '*.bak' -delete
	@${RM} ${WRKSRC}/node_modules/node-gyp/macOS_Catalina_acid_test.sh

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/${NPM_DIR}/node_modules/.bin ${STAGEDIR}${PREFIX}/etc/man.d
	cd ${WRKSRC}/ && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/${NPM_DIR}/
	${FIND} ${STAGEDIR}${PREFIX}/${NPM_DIR}/man -type f -exec ${GZIP_CMD} {} +
	${ECHO_CMD} "MANPATH ${PREFIX}/${NPM_DIR}/man" > ${STAGEDIR}${PREFIX}/etc/man.d/npm.conf
	${RLN} ${STAGEDIR}${PREFIX}/${NPM_DIR}/bin/npm-cli.js ${STAGEDIR}${PREFIX}/bin/npm
	${RLN} ${STAGEDIR}${PREFIX}/${NPM_DIR}/bin/npx-cli.js ${STAGEDIR}${PREFIX}/bin/npx
	${RLN} ${STAGEDIR}${PREFIX}/${NPM_DIR}/node_modules/node-gyp/bin/node-gyp.js ${STAGEDIR}${PREFIX}/bin/node-gyp
.for bin in ${NPM_BINS}
	${RLN} ${STAGEDIR}${PREFIX}/${NPM_DIR}/node_modules/${bin:C/^[^:]*://} ${STAGEDIR}${PREFIX}/${NPM_DIR}/node_modules/.bin/${bin:C/:.*//}
.endfor
	${PYTHON_CMD} -m compileall -d ${PREFIX}/${NPM_DIR}/node_modules/node-gyp/gyp -f ${STAGEDIR}${PREFIX}/${NPM_DIR}/node_modules/node-gyp/gyp -o 0 -o 1

.include <bsd.port.mk>
