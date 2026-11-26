# azsupport/gd: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	gd
PORTVERSION=	2.3.3
CATEGORIES=	azsupport graphics
PKGNAMEPREFIX=	azsupport-

COMMENT=	gd of /usr/local/azsupport (shared; graphics/gd)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

LIB_DEPENDS=	libimagequant.so:graphics/libimagequant

AZSUPPORT_LIB=		gd
AZSUPPORT_LIB_PORT=	graphics/gd
AZSUPPORT_LIB_CONF=	lib gd graphics/gd static,shared; needs gd freetype2 libiconv mozjpeg png webp
AZSUPPORT_LIB_NEEDS=	freetype2 libiconv mozjpeg png webp
AZSUPPORT_LIB_FILES=	deps/gd-2.3.3.patch
AZSUPPORT_HASH_OFFICIAL=	graphics/gd

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
