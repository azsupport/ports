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
# pacote 21.5.1) by files/patch-CVE-2026-9496; brace-expansion 2.0.2
# (CVE-2026-33750, CVE-2026-13149, CVE-2026-14257, CVE-2026-69152, CVE-2026-102276,
# CVE-2026-102277, CVE-2026-102278; fixed in 2.1.7) and ip-address 10.1.0
# (CVE-2026-42338, CVE-2026-69192, CVE-2026-101911, CVE-2026-101912,
# CVE-2026-101913, CVE-2026-111997; fixed in 10.7.4) replaced by the newest of their
# major versions, of the registry: brace-expansion 2.1.8 (what the minimatch 9.0.9
# of npm takes, ^2.0.2; it also bounds the work of one expansion, which 2.1.7 does
# not) and ip-address 10.7.6 (what socks 2.8.7 takes, ^10.0.1), with the files npm
# keeps of a bundled dependency (the node_modules/.gitignore of npm/cli: no README*,
# *.ts, *.map), which are the files of those npm bundles: the plist is the same.
# npm 12.2.2 of npm-node24 has none of them (pacote 22.0.1, brace-expansion 5.0.12,
# ip-address 10.7.5).

PORTNAME=	npm
PORTVERSION=	10.9.10
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://registry.npmjs.org/${PORTNAME}/-/ \
		https://registry.npmjs.org/brace-expansion/-/:brace \
		https://registry.npmjs.org/ip-address/-/:ipaddress
PKGNAMESUFFIX=	-node18
DISTFILES=	${DISTNAME}${EXTRACT_SUFX} \
		brace-expansion-${BRACE_EXPANSION_VERSION}.tgz:brace \
		ip-address-${IP_ADDRESS_VERSION}.tgz:ipaddress
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

NPM_DIR=	lib/node_modules/npm
# Executables of the bundled dependencies, as linked by "npm install"
NPM_BINS=	arborist:@npmcli/arborist/bin/index.js cssesc:cssesc/bin/cssesc \
		installed-package-contents:@npmcli/installed-package-contents/bin/index.js \
		node-gyp:node-gyp/bin/node-gyp.js node-which:which/bin/which.js \
		nopt:nopt/bin/nopt.js pacote:pacote/bin/index.js \
		qrcode-terminal:qrcode-terminal/bin/qrcode-terminal.js \
		semver:semver/bin/semver.js

post-extract:
.for p v in brace-expansion ${BRACE_EXPANSION_VERSION} ip-address ${IP_ADDRESS_VERSION}
	${RM} -r ${WRKSRC}/node_modules/${p}
	${MKDIR} ${WRKSRC}/node_modules/${p}
	${TAR} -xf ${DISTDIR}/${p}-${v}.tgz -C ${WRKSRC}/node_modules/${p} --strip-components 1 \
		--exclude 'README*' --exclude '*.ts' --exclude '*.map'
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
