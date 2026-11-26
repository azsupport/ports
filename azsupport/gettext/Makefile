# azsupport/gettext: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	gettext
PORTVERSION=	1.0
CATEGORIES=	azsupport devel
PKGNAMEPREFIX=	azsupport-

COMMENT=	gettext of /usr/local/azsupport (shared; devel/gettext-runtime)
WWW=		https://github.com/azsupport/ports

LICENSE=	LGPL21+ GPLv3+
LICENSE_COMB=	multi

AZSUPPORT_LIB=		gettext
AZSUPPORT_LIB_PORT=	devel/gettext-runtime
AZSUPPORT_LIB_CONF=	lib gettext devel/gettext-runtime static,shared; needs gettext libiconv
AZSUPPORT_LIB_NEEDS=	libiconv
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	devel/gettext-runtime devel/gettext

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
