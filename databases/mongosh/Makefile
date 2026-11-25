# databases/mongosh of azsupport/ports: mongosh 2.14.3, the MongoDB Shell, the npm package
# on our Node.js 24 (aZ, 19.11.2026: «Пакет делай с нашей зависимостью node24»), in the
# place of the official databases/mongosh (a single executable with a Node.js of its own,
# built from source): the modules of Makefile.npm from registry.npmjs.org, extracted
# where npm puts them (lib/node_modules/mongosh), JavaScript only, nothing downloaded
# while it builds; bin/mongosh runs bin/mongosh.js with the node of PATH. The global
# configuration: etc/mongosh.conf of the prefix first (mongosh on FreeBSD reads
# /etc/mongosh.conf only), its sample with forceDisableTelemetry: true (aZ, 19.11.2026:
# no telemetry).

PORTNAME=	mongosh
DISTVERSION=	2.14.3
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	databases
MASTER_SITES=	https://registry.npmjs.org/:npm
DISTFILES=
DIST_SUBDIR=	mongosh

MAINTAINER=	github@azsupport.com
COMMENT=	MongoDB Shell on Node.js 24 (of azsupport/ports)
WWW=		https://www.mongodb.com/docs/mongodb-shell/ \
		https://github.com/mongodb-js/mongosh \
		https://github.com/azsupport/ports

LICENSE=	APACHE20

RUN_DEPENDS=	node24>=24.15:www/node24

NO_ARCH=	yes
NO_BUILD=	yes
WRKSRC=		${WRKDIR}/mongosh

MONGOSH_DIR=	lib/node_modules/mongosh

.include "${.CURDIR}/Makefile.npm"

# the npm tarballs as on the registry (<name>/-/<base>-<version>.tgz), each extracted where
# it goes (do-extract)
.for m in ${MONGOSH_NPM}
_MONGOSH_FILES+=	${m:C/^[^:]*://:C/:.*//}/-/${m:C/^[^:]*://:C/:.*//:T}-${m:C/.*://}.tgz
.endfor
.for t in ${_MONGOSH_FILES:O:u}
DISTFILES+=	${t}:npm
.endfor

do-extract:
	${MKDIR} ${WRKSRC}
.for m in ${MONGOSH_NPM}
	${MKDIR} ${WRKSRC}/${m:C/:.*//}
	${TAR} -xf ${_DISTDIR}/${m:C/^[^:]*://:C/:.*//}/-/${m:C/^[^:]*://:C/:.*//:T}-${m:C/.*://}.tgz \
		-C ${WRKSRC}/${m:C/:.*//} --strip-components 1 --no-same-owner --no-same-permissions
.endfor

# the global configuration of the prefix before /etc/mongosh.conf
post-patch:
	${REINPLACE_CMD} -e "s|paths.push('/etc/mongosh.conf');|paths.push('${PREFIX}/etc/mongosh.conf'); paths.push('/etc/mongosh.conf');|" \
		${WRKSRC}/node_modules/@mongosh/cli-repl/lib/config-directory.js
	@${GREP} -q "paths.push('${PREFIX}/etc/mongosh.conf')" \
		${WRKSRC}/node_modules/@mongosh/cli-repl/lib/config-directory.js || \
		{ ${ECHO_MSG} "config-directory.js: no ${PREFIX}/etc/mongosh.conf"; ${FALSE}; }
	${FIND} ${WRKSRC} -name '*.bak' -delete

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/${MONGOSH_DIR}
	cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/${MONGOSH_DIR}
	${CHMOD} 0755 ${STAGEDIR}${PREFIX}/${MONGOSH_DIR}/bin/mongosh.js
	${RLN} ${STAGEDIR}${PREFIX}/${MONGOSH_DIR}/bin/mongosh.js ${STAGEDIR}${PREFIX}/bin/mongosh
	${INSTALL_DATA} ${FILESDIR}/mongosh.conf.sample ${STAGEDIR}${PREFIX}/etc/mongosh.conf.sample

post-install:
	@${ECHO_CMD} bin/mongosh >> ${TMPPLIST}
	@${ECHO_CMD} "@sample etc/mongosh.conf.sample" >> ${TMPPLIST}
	cd ${STAGEDIR}${PREFIX} && ${FIND} ${MONGOSH_DIR} \( -type f -o -type l \) | ${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>
