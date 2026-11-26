# azsupport/readline: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	readline
PORTVERSION=	8.3.6
CATEGORIES=	azsupport devel
PKGNAMEPREFIX=	azsupport-

COMMENT=	readline of /usr/local/azsupport (shared; devel/readline)
WWW=		https://github.com/azsupport/ports

LICENSE=	GPLv3

AZSUPPORT_LIB=		readline
AZSUPPORT_LIB_PORT=	devel/readline
AZSUPPORT_LIB_CONF=	lib readline devel/readline static,shared
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=	deps/readline-8.3.6.patch
AZSUPPORT_HASH_OFFICIAL=	devel/readline

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
