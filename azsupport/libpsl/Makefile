# azsupport/libpsl: made by tools/azsupport-lib-ports.sh from its lines of
# azsupport/azsupport/files/deps.conf and curl-deps.conf: do not edit; --write makes it again.

PORTNAME=	libpsl
PORTVERSION=	0.23.3
CATEGORIES=	azsupport dns
MASTER_SITES=	https://github.com/rockdaboot/libpsl/releases/download/0.23.3/:bundle \
		https://codeload.github.com/publicsuffix/list/tar.gz/73f8cc7?dummy=/:psllist
PKGNAMEPREFIX=	azsupport-
DISTFILES=	libpsl-0.23.3.tar.lz:bundle \
		publicsuffix-list-20261031-73f8cc7_GH0.tar.gz:psllist

COMMENT=	libpsl of /usr/local/azsupport (shared; bundle, dns/libpsl)
WWW=		https://github.com/azsupport/ports

LICENSE=	MIT

AZSUPPORT_LIB=		libpsl
AZSUPPORT_LIB_PORT=	bundle
AZSUPPORT_LIB_CONF=	lib libpsl bundle static,shared; libpsl 0.23.3 dns/libpsl https://github.com/rockdaboot/libpsl libpsl-0.23.3.tar.lz 9e60f70c9806f5e3f36581e9c05e9d817767953da3428c08e0ed9b9ad321d444 https://github.com/rockdaboot/libpsl/releases/download/0.23.3/libpsl-0.23.3.tar.lz; psl-list 20261031 dns/public_suffix_list - publicsuffix-list-20261031-73f8cc7_GH0.tar.gz 40caa0d2cc1900fb885751c85bc331868286914dc750b9338c2fc75d5252b880 https://codeload.github.com/publicsuffix/list/tar.gz/73f8cc7
AZSUPPORT_LIB_NEEDS=
AZSUPPORT_LIB_FILES=
AZSUPPORT_HASH_OFFICIAL=

.include "${.CURDIR:H}/azsupport/Makefile.lib"
.include <bsd.port.mk>
