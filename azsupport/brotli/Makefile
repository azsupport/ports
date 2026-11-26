# azsupport/brotli: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	brotli
PORTVERSION=	1.2.1
CATEGORIES=	azsupport archivers
MASTER_SITES=	https://codeload.github.com/google/brotli/tar.gz/v1.2.1?dummy=/:bundle
PKGNAMEPREFIX=	azsupport-
DISTFILES=	brotli_1.2.1_google-brotli-v1.2.1_GH0.tar.gz:bundle

COMMENT=	brotli of /usr/local/azsupport (shared; bundle, archivers/brotli)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

AZSUPPORT_LIB=		brotli
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib brotli bundle static,shared; brotli 1.2.1 archivers/brotli https://github.com/google/brotli brotli/1.2.1/google-brotli-v1.2.1_GH0.tar.gz 98d35d11a78dc453aebb7d10c3748f3f73ff78c8267c0dc697b8631f67bf7e8f https://codeload.github.com/google/brotli/tar.gz/v1.2.1
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
