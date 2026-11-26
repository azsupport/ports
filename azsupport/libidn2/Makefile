# azsupport/libidn2: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	libidn2
PORTVERSION=	2.3.8
CATEGORIES=	azsupport dns
MASTER_SITES=	GNU/libidn:bundle
PKGNAMEPREFIX=	azsupport-
DISTFILES=	libidn2-2.3.8.tar.gz:bundle

COMMENT=	libidn2 of /usr/local/azsupport (shared; bundle, dns/libidn2)
WWW=		https://github.com/azsupport/ports

LICENSE=	GPLv3

AZSUPPORT_LIB=		libidn2
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib libidn2 bundle static,shared; needs libidn2 libiconv; libidn2 2.3.8 dns/libidn2 https://gitlab.com/libidn/libidn2.git libidn2-2.3.8.tar.gz f557911bf6171621e1f72ff35f5b1825bb35b52ed45325dcdee931e5d3c0787a https://ftp.gnu.org/gnu/libidn/libidn2-2.3.8.tar.gz
AZSUPPORT_LIB_NEEDS=	libiconv
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
