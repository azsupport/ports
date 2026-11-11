# www/yarn-node18 of azsupport/ports: Yarn 1 of our www/node18 (aZ, 11.11.2026:
# Node.js 18 for a legacy project), with bin/yarn (HADOOPCOMPAT off): the official
# www/yarn-node24 of the pinned tree as it is (its patch, distinfo, pkg-plist and
# pkg-descr), the same Yarn 1.22.19 as our yarn-node24, so that a project keeps its
# Yarn when it moves between node18 and node24. Without USES=nodejs, as
# www/npm-node18 (its Makefile says why): the RUN_DEPENDS on node of www/node18 and
# the suffix -node18 written here. yarn-node18 and yarn-node24, one of the two
# (CONFLICTS_INSTALL, the same files).

PORTNAME=	yarn
DISTVERSIONPREFIX=	v
PORTVERSION=	1.22.19
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://yarnpkg.com/downloads/${PORTVERSION}/
PKGNAMESUFFIX=	-node18

MAINTAINER=	github@azsupport.com
COMMENT=	Package manager for node, alternative to npm (of azsupport/ports)
WWW=		https://classic.yarnpkg.com/ \
		https://github.com/azsupport/ports

LICENSE=	BSD2CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

RUN_DEPENDS=	node:www/node18

USES=		cpe
CPE_VENDOR=	${PORTNAME}pkg

CONFLICTS_INSTALL=	yarn-node[0-9][0-9]

OPTIONS_DEFINE=	HADOOPCOMPAT
HADOOPCOMPAT_DESC=	hadoop2 compatibility, the yarn script is excluded

OPTIONS_SUB=	yes

HADOOPCOMPAT_CONFLICTS_INSTALL_OFF=	hadoop2*

NO_ARCH=	yes
NO_BUILD=	yes

post-patch:
	@${RM} ${WRKSRC}/bin/*.cmd
	@${REINPLACE_CMD} -i '' \
		-e 's|"installationMethod": "tar"|"installationMethod": "pkg"|g' \
		${WRKSRC}/package.json
	@${REINPLACE_CMD} -i '' -e 's%Linux)%Linux|FreeBSD)%g' \
		${WRKSRC}/bin/yarn

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/node_modules/yarn
	(cd ${WRKSRC}/ && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/lib/node_modules/yarn)
	${RLN} ${STAGEDIR}${PREFIX}/lib/node_modules/yarn/bin/yarn.js \
		${STAGEDIR}${PREFIX}/bin/yarn.js
	${RLN} ${STAGEDIR}${PREFIX}/lib/node_modules/yarn/bin/yarnpkg \
		${STAGEDIR}${PREFIX}/bin/yarnpkg

do-install-HADOOPCOMPAT-off:
	${RLN} ${STAGEDIR}${PREFIX}/lib/node_modules/yarn/bin/yarn \
		${STAGEDIR}${PREFIX}/bin/yarn

.include <bsd.port.mk>
