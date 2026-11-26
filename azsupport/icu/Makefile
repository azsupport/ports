# azsupport/icu: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	icu
PORTVERSION=	76.1
CATEGORIES=	azsupport devel
PKGNAMEPREFIX=	azsupport-

COMMENT=	icu of /usr/local/azsupport (shared; devel/icu)
WWW=		https://github.com/azsupport/ports

LICENSE=	BSD-3-Clause Unicode-3.0
LICENSE_COMB=	multi

AZSUPPORT_LIB=		icu
AZSUPPORT_LIB_PORT=	devel/icu
AZSUPPORT_LIB_CONF=	lib icu devel/icu static,shared
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=	deps/icu-76_1.patch
AZSUPPORT_HASH_OFFICIAL=	devel/icu

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
