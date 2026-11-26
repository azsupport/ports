# azsupport/libxslt: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	libxslt
PORTVERSION=	1.1.45
CATEGORIES=	azsupport textproc
PKGNAMEPREFIX=	azsupport-

COMMENT=	libxslt of /usr/local/azsupport (shared; textproc/libxslt)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

AZSUPPORT_LIB=		libxslt
AZSUPPORT_LIB_PORT=	textproc/libxslt
AZSUPPORT_LIB_CONF=	lib libxslt textproc/libxslt shared; needs libxslt libxml2
AZSUPPORT_LIB_NEEDS=	libxml2
AZSUPPORT_LIB_FILES=	deps/libxslt-1.1.45.patch
AZSUPPORT_HASH_OFFICIAL=	textproc/libxslt

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
