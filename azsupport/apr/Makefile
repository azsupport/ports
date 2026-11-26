# azsupport/apr: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	apr
PORTVERSION=	1.7.6.1.6.6
CATEGORIES=	azsupport devel
PKGNAMEPREFIX=	azsupport-

COMMENT=	apr of /usr/local/azsupport (shared; devel/apr1)
WWW=		https://github.com/azsupport/ports

LICENSE=	APACHE20 BSD4CLAUSE
LICENSE_COMB=	dual

AZSUPPORT_LIB=		apr
AZSUPPORT_LIB_PORT=	devel/apr1
AZSUPPORT_LIB_CONF=	lib apr devel/apr1 shared; needs apr expat libiconv
AZSUPPORT_LIB_NEEDS=	expat libiconv
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	devel/apr1

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
