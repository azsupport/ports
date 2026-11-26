# azsupport/libzip: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	libzip
PORTVERSION=	1.12.1
CATEGORIES=	azsupport archivers
PKGNAMEPREFIX=	azsupport-

COMMENT=	libzip of /usr/local/azsupport (shared; archivers/libzip)
WWW=		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE

AZSUPPORT_LIB=		libzip
AZSUPPORT_LIB_PORT=	archivers/libzip
AZSUPPORT_LIB_CONF=	lib libzip archivers/libzip static,shared; needs libzip zstd
AZSUPPORT_LIB_NEEDS=	zstd
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	archivers/libzip

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
