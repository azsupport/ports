# azsupport/zstd: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	zstd
PORTVERSION=	1.6.0
CATEGORIES=	azsupport archivers
MASTER_SITES=	https://github.com/facebook/zstd/releases/download/v1.6.0/:bundle
PKGNAMEPREFIX=	azsupport-
DISTFILES=	zstd-1.6.0.tar.zst:bundle

COMMENT=	zstd of /usr/local/azsupport (shared; bundle, archivers/zstd)
WWW=		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE GPLv2
LICENSE_COMB=	dual

AZSUPPORT_LIB=		zstd
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib zstd bundle static,shared; zstd 1.6.0 archivers/zstd https://github.com/facebook/zstd zstd-1.6.0.tar.zst 2ca30d45c7a61f255e17024373f7fe75b6403b2ade6b21220c1472964d8a466a https://github.com/facebook/zstd/releases/download/v1.6.0/zstd-1.6.0.tar.zst
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
