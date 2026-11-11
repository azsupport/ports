# www/corepack of azsupport/ports: the official port as a port of this tree (aZ,
# 11.11.2026: ours, so that we update it ourselves; pkg-plist and pkg-descr of the
# official one), which www/node24 depends on. corepack runs the package manager a
# project names (packageManager of its package.json: yarn 2 and later, pnpm), which
# it downloads on its first use.

PORTNAME=	corepack
PORTVERSION=	0.36.0
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONPREFIX=	v
CATEGORIES=	www
MASTER_SITES=	https://github.com/nodejs/corepack/releases/download/v${PORTVERSION}/
DIST_SUBDIR=	corepack/${PORTVERSION}
DISTNAME=	corepack

MAINTAINER=	github@azsupport.com
COMMENT=	Bridge between Node projects and their package managers (of azsupport/ports)
WWW=		https://github.com/nodejs/corepack \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/package/LICENSE.md

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
