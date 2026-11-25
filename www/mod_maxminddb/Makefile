# www/mod_maxminddb: the mod_maxminddb of azsupport/ports in the place of the
# official www/mod_maxminddb (aZ, 10.11.2026): the official port with
# libmaxminddb the shared library of azsupport, with the run path /usr/local/azsupport/lib
# (our ports link each other's shared libraries, aZ 10.11.2026: nginx will take
# the same one), so that it takes no package but azsupport (the official one takes
# net/libmaxminddb); for the Apache of this tree (www/apache24).

PORTNAME=	mod_maxminddb
PORTVERSION=	1.3.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	www
# the package apache24-mod_maxminddb (aZ, 21.11.2026: the name with the version first,
# as php84, as apache24-suexec), in the place of the official ap24-mod_maxminddb
PKGNAMEPREFIX=	apache24-
CONFLICTS_INSTALL=	ap24-mod_maxminddb

MAINTAINER=	github@azsupport.com
COMMENT=	MaxMind DB Apache Module (of azsupport/ports)
WWW=		https://github.com/maxmind/mod_maxminddb \
		https://github.com/azsupport/ports

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libmaxminddb.so:azsupport/azsupport
RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libmaxminddb.so:azsupport/azsupport

USES=		apache autoreconf compiler:c11 gmake
GNU_CONFIGURE=	yes
USE_GITHUB=	yes
GH_ACCOUNT=	maxmind

# maxminddb.h and maxminddb_config.h alone in a directory of the work (the
# include directory of azsupport has others, GNU iconv.h among them); in CFLAGS too,
# which src/Makefile.am gives apxs (not CPPFLAGS); -lmaxminddb of azsupport with its run
# path, through apxs
CPPFLAGS+=	-I${WRKDIR}/azsupport
CFLAGS+=	-I${WRKDIR}/azsupport
LDFLAGS+=	-L${AZSUPPORT_PREFIX}/lib -Wl,-rpath,${AZSUPPORT_PREFIX}/lib

post-patch:
	@${REINPLACE_CMD} -e 's|%%LIBEXECDEST%%|${STAGEDIR}${PREFIX}/${APACHEMODDIR}|g' ${WRKSRC}/src/Makefile.am

pre-configure:
	@${MKDIR} ${WRKDIR}/azsupport
	@${LN} -sf ${AZSUPPORT_PREFIX}/include/maxminddb.h ${AZSUPPORT_PREFIX}/include/maxminddb_config.h ${WRKDIR}/azsupport/

pre-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/${APACHEMODDIR}

# the module stripped: apxs installs it as it was linked (no debug in our packages,
# aZ 17.11.2026)
post-install:
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}/${APACHEMODDIR}

.include <bsd.port.mk>
