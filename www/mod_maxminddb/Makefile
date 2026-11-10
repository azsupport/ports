# www/mod_maxminddb: the mod_maxminddb of azsupport/ports in the place of the
# official www/mod_maxminddb (aZ, 10.11.2026): the official port with
# libmaxminddb the shared library of az, with the run path /usr/local/az/lib
# (our ports link each other's shared libraries, aZ 10.11.2026: nginx will take
# the same one), so that it takes no package but az (the official one takes
# net/libmaxminddb); for the Apache of this tree (www/apache24).

PORTNAME=	mod_maxminddb
PORTVERSION=	1.3.0
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
PKGNAMEPREFIX=	${APACHE_PKGNAMEPREFIX}

MAINTAINER=	github@azsupport.com
COMMENT=	MaxMind DB Apache Module (of azsupport/ports)
WWW=		https://github.com/maxmind/mod_maxminddb \
		https://github.com/azsupport/ports

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az

USES=		apache autoreconf compiler:c11 gmake
GNU_CONFIGURE=	yes
USE_GITHUB=	yes
GH_ACCOUNT=	maxmind

# maxminddb.h and maxminddb_config.h alone in a directory of the work (the
# include directory of az has others, GNU iconv.h among them); in CFLAGS too,
# which src/Makefile.am gives apxs (not CPPFLAGS); -lmaxminddb of az with its run
# path, through apxs
CPPFLAGS+=	-I${WRKDIR}/az
CFLAGS+=	-I${WRKDIR}/az
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib

post-patch:
	@${REINPLACE_CMD} -e 's|%%LIBEXECDEST%%|${STAGEDIR}${PREFIX}/${APACHEMODDIR}|g' ${WRKSRC}/src/Makefile.am

pre-configure:
	@${MKDIR} ${WRKDIR}/az
	@${LN} -sf ${AZ_PREFIX}/include/maxminddb.h ${AZ_PREFIX}/include/maxminddb_config.h ${WRKDIR}/az/

pre-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/${APACHEMODDIR}

.include <bsd.port.mk>
