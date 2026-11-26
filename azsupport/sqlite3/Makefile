# azsupport/sqlite3: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	sqlite3
PORTVERSION=	3.54.1
CATEGORIES=	azsupport databases
PKGNAMEPREFIX=	azsupport-

COMMENT=	sqlite3 of /usr/local/azsupport (shared; databases/sqlite3)
WWW=		https://github.com/azsupport/ports

LICENSE=	PD

BUILD_DEPENDS=	gcc16:lang/gcc16

AZSUPPORT_LIB=		sqlite3
AZSUPPORT_LIB_PORT=	databases/sqlite3
AZSUPPORT_LIB_CONF=	lib sqlite3 databases/sqlite3 shared
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	databases/sqlite3

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
