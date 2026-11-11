# www/corepack-node24 of azsupport/ports: the official www/corepack as a port of this
# tree (aZ, 11.11.2026: ours, so that we update it ourselves; pkg-plist and pkg-descr
# of the official one), for www/node24, which depends on it: corepack-node24 and
# corepack-node18, one of the two, as npm and yarn (aZ, 11.11.2026: corepack 0.34
# and later run on Node 20, 22, 24 and later only, 0.35 and 0.36 on 22.22.2,
# 24.15.0 and later, so Node 18 has a corepack of its own). corepack runs the package
# manager a project names (packageManager of its package.json: yarn 2 and later,
# pnpm), which it downloads on its first use.

PORTNAME=	corepack
PORTVERSION=	0.36.0
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONPREFIX=	v
CATEGORIES=	www
MASTER_SITES=	https://github.com/nodejs/corepack/releases/download/v${PORTVERSION}/
DIST_SUBDIR=	corepack/${PORTVERSION}
DISTNAME=	corepack
PKGNAMESUFFIX=	-node24

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
