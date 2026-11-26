# azsupport/freetype2: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf: do not edit; --write makes it again.

PORTNAME=	freetype2
PORTVERSION=	2.15.0
CATEGORIES=	azsupport print
MASTER_SITES=	https://download.savannah.gnu.org/releases/freetype/:take \
		https://downloads.sourceforge.net/project/freetype/freetype2/2.15.0/:take
PKGNAMEPREFIX=	azsupport-
DISTFILES=	freetype-2.15.0.tar.xz:take

COMMENT=	freetype2 of /usr/local/azsupport (shared; print/freetype2)
WWW=		https://github.com/azsupport/ports

LICENSE=	FTL GPLv2+
LICENSE_COMB=	dual
LICENSE_NAME_FTL=	The FreeType Project license
LICENSE_PERMS_FTL=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept
LICENSE_TEXT_FTL=	the licence files of freetype2 are in /usr/local/azsupport/LICENSES

AZSUPPORT_LIB=		freetype2
AZSUPPORT_LIB_PORT=	print/freetype2
AZSUPPORT_LIB_CONF=	lib freetype2 print/freetype2 static,shared; take freetype2 2.15.0 https://download.savannah.gnu.org/releases/freetype/freetype-2.15.0.tar.xz,https://downloads.sourceforge.net/project/freetype/freetype2/2.15.0/freetype-2.15.0.tar.xz 93cd47eb719c325107f2d3cf087d06299e944c3b48a40b55537302304dea1dd5 freetype-2.15.0
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=	print/freetype2

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
