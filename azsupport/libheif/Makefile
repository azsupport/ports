# azsupport/libheif: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	libheif
PORTVERSION=	1.23.7
CATEGORIES=	azsupport graphics
PKGNAMEPREFIX=	azsupport-

COMMENT=	libheif of /usr/local/azsupport (shared; graphics/libheif)
WWW=		https://github.com/azsupport/ports

LICENSE=	LGPL3+

AZSUPPORT_LIB=		libheif
AZSUPPORT_LIB_PORT=	graphics/libheif
AZSUPPORT_LIB_CONF=	lib libheif graphics/libheif static,shared; needs libheif dav1d libde265 svtav1
AZSUPPORT_LIB_NEEDS=	dav1d libde265 svtav1
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	graphics/libheif

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
