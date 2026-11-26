# azsupport/expat: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	expat
PORTVERSION=	2.11.0
CATEGORIES=	azsupport textproc
PKGNAMEPREFIX=	azsupport-

COMMENT=	expat of /usr/local/azsupport (shared; textproc/expat2)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

BUILD_DEPENDS=	gcc16:lang/gcc16

AZSUPPORT_LIB=		expat
AZSUPPORT_LIB_PORT=	textproc/expat2
AZSUPPORT_LIB_CONF=	lib expat textproc/expat2 static,shared
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	textproc/expat2

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
