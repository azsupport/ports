# azsupport/nghttp2: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	nghttp2
PORTVERSION=	1.71.0
CATEGORIES=	azsupport www
MASTER_SITES=	https://github.com/nghttp2/nghttp2/releases/download/v1.71.0/:bundle
PKGNAMEPREFIX=	azsupport-
DISTFILES=	nghttp2-1.71.0.tar.xz:bundle

COMMENT=	nghttp2 of /usr/local/azsupport (shared; bundle, www/libnghttp2)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

AZSUPPORT_LIB=		nghttp2
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib nghttp2 bundle static,shared; nghttp2 1.71.0 www/libnghttp2 https://github.com/nghttp2/nghttp2 nghttp2-1.71.0.tar.xz c0f55121d88650e4b9227aec28cebaf664d2417ca60fe70be0f8d38829f52116 https://github.com/nghttp2/nghttp2/releases/download/v1.71.0/nghttp2-1.71.0.tar.xz
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
