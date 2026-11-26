# azsupport/libde265: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	libde265
PORTVERSION=	1.1.3
CATEGORIES=	azsupport multimedia
MASTER_SITES=	https://github.com/strukturag/libde265/releases/download/v1.1.3/:take
PKGNAMEPREFIX=	azsupport-
DISTFILES=	libde265-1.1.3.tar.gz:take

COMMENT=	libde265 of /usr/local/azsupport (shared; multimedia/libde265)
WWW=		https://github.com/azsupport/ports

LICENSE=	LGPL3

AZSUPPORT_LIB=		libde265
AZSUPPORT_LIB_PORT=	multimedia/libde265
AZSUPPORT_LIB_CONF=	lib libde265 multimedia/libde265 static,shared; take libde265 1.1.3 https://github.com/strukturag/libde265/releases/download/v1.1.3/libde265-1.1.3.tar.gz 554228bd17788c99a7e63b37ab5634722190e6e2bf60c1dcb01cef328e133905 libde265-1.1.3
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=	deps/libde265-1.1.3.patch
AZSUPPORT_HASH_OFFICIAL=	multimedia/libde265

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
