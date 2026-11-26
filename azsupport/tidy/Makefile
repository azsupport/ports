# azsupport/tidy: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	tidy
PORTVERSION=	5.8.0
CATEGORIES=	azsupport www
PKGNAMEPREFIX=	azsupport-

COMMENT=	tidy of /usr/local/azsupport (shared; www/tidy-html5)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

AZSUPPORT_LIB=		tidy
AZSUPPORT_LIB_PORT=	www/tidy-html5
AZSUPPORT_LIB_CONF=	lib tidy www/tidy-html5 shared
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=	deps/tidy-5.8.0.patch
AZSUPPORT_HASH_OFFICIAL=	www/tidy-html5

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
