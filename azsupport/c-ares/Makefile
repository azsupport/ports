# azsupport/c-ares: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	c-ares
PORTVERSION=	1.34.9
CATEGORIES=	azsupport dns
MASTER_SITES=	https://github.com/c-ares/c-ares/releases/download/v1.34.9/:bundle
PKGNAMEPREFIX=	azsupport-
DISTFILES=	c-ares-1.34.9.tar.gz:bundle

COMMENT=	c-ares of /usr/local/azsupport (shared; bundle, dns/c-ares)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

AZSUPPORT_LIB=		c-ares
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib c-ares bundle static,shared; c-ares 1.34.9 dns/c-ares https://github.com/c-ares/c-ares c-ares-1.34.9.tar.gz 9364b70a12eb59a06830fb488d9357f90100dff0d98b23ea3593a183d43e6f2f https://github.com/c-ares/c-ares/releases/download/v1.34.9/c-ares-1.34.9.tar.gz
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
