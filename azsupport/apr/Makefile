# azsupport/apr: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	apr
PORTVERSION=	1.7.6.1.6.6
CATEGORIES=	azsupport devel
PKGNAMEPREFIX=	azsupport-

COMMENT=	apr of /usr/local/azsupport (shared; devel/apr1)
WWW=		https://github.com/azsupport/ports

# the licence of what this package has: APR and APR-util without Berkeley DB (--without-berkeley-db): the BSD4CLAUSE of the option BDB1 of its port is not in it (LICENSE of devel/apr1: APACHE20 BSD4CLAUSE, dual)
LICENSE=	APACHE20

AZSUPPORT_LIB=		apr
AZSUPPORT_LIB_PORT=	devel/apr1
AZSUPPORT_LIB_CONF=	lib apr devel/apr1 shared; needs apr expat libiconv
AZSUPPORT_LIB_NEEDS=	expat libiconv
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	devel/apr1

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
