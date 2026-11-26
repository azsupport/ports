# azsupport/libmcrypt: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	libmcrypt
PORTVERSION=	2.5.8
CATEGORIES=	azsupport security
PKGNAMEPREFIX=	azsupport-

COMMENT=	libmcrypt of /usr/local/azsupport (shared; security/libmcrypt)
WWW=		https://github.com/azsupport/ports

LICENSE=	LGPL21+

AZSUPPORT_LIB=		libmcrypt
AZSUPPORT_LIB_PORT=	security/libmcrypt
AZSUPPORT_LIB_CONF=	lib libmcrypt security/libmcrypt static,shared
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=	deps/libmcrypt-2.5.8.patch
AZSUPPORT_HASH_OFFICIAL=	security/libmcrypt

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
