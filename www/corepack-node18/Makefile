# www/corepack-node18 of azsupport/ports: corepack of www/node18, made as our
# www/corepack-node24 (the official www/corepack; its pkg-plist and pkg-descr, the
# same files), which node18 depends on: corepack-node18 and corepack-node24, one of
# the two, as npm and yarn (aZ, 11.11.2026). corepack 0.33.0 is the last that runs
# on Node 18 (its engines: ^18.17.1 || ^20.10.0 || >=22.11.0; 0.34 and later need
# Node 20 or later), and newer than the 0.32.0 that Node 18.20.8 bundles. Its
# release on GitHub has no corepack.tgz, so the tarball of the npm registry (the
# same package/ tree; its SHA-512 that of the registry). corepack runs the package
# manager a project names (packageManager of its package.json: yarn 2 and later,
# pnpm), which it downloads on its first use.

PORTNAME=	corepack
PORTVERSION=	0.33.0
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://registry.npmjs.org/${PORTNAME}/-/
PKGNAMESUFFIX=	-node18

MAINTAINER=	github@azsupport.com
COMMENT=	Bridge between Node projects and their package managers (of azsupport/ports)
WWW=		https://github.com/nodejs/corepack \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/package/LICENSE.md

# the same files: one corepack at a time (the official package corepack too)
CONFLICTS_INSTALL=	corepack corepack-node[0-9][0-9]

USES=		tar:tgz

NO_ARCH=	yes
NO_BUILD=	yes
NO_WRKSUBDIR=	yes

post-patch:
	@${FIND} ${WRKSRC}/ \( -name '*.cmd' -o -name '*.ps1' \) -delete

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/node_modules/
	cd ${WRKSRC}/package/ && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/lib/node_modules/corepack/
	${LN} -s ../lib/node_modules/corepack/dist/corepack.js ${STAGEDIR}${PREFIX}/bin/corepack

.include <bsd.port.mk>
