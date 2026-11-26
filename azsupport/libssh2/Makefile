# azsupport/libssh2: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	libssh2
PORTVERSION=	1.11.1
CATEGORIES=	azsupport security
MASTER_SITES=	https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.1/:bundle
PKGNAMEPREFIX=	azsupport-
DISTFILES=	libssh2-1.11.1.tar.xz:bundle

COMMENT=	libssh2 of /usr/local/azsupport (shared; bundle, security/libssh2)
WWW=		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE

AZSUPPORT_LIB=		libssh2
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib libssh2 bundle static,shared; libssh2 1.11.1 security/libssh2 https://github.com/libssh2/libssh2 libssh2-1.11.1.tar.xz 9954cb54c4f548198a7cbebad248bdc87dd64bd26185708a294b2b50771e3769 https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.1/libssh2-1.11.1.tar.xz
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=	curl/build-libcurl.sh curl/libssh2-1.11.1.patch
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
