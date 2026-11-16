# devel/libada of azsupport/ports in the place of the official one (its Makefile,
# pkg-plist and pkg-descr): the URL parser of www/node24 (aZ, 11.11.2026: the libraries
# that Node.js bundles as ports of this tree). 4.0.0 ahead of the official 3.4.4 (aZ,
# 16.11.2026): the ada that Node.js 24.22.3 bundles, with the fixes of 3.4.4..4.0.0 (a
# denial of service of the URLPattern tokenizer on malformed UTF-8, #1125; the length
# limit of href_from_file and of search params, #1193; parsing fixes, #1156, #1157,
# #1167, #1186); its library libada.so.4, one header more (url_ip-inl.h).

PORTNAME=	libada
DISTVERSIONPREFIX=	v
DISTVERSION=	4.0.0
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	devel www

MAINTAINER=	github@azsupport.com
COMMENT=	WHATWG-compliant and fast URL parser (of azsupport/ports)
WWW=		https://ada-url.com/ \
		https://github.com/azsupport/ports

LICENSE=	APACHE20 MIT
LICENSE_COMB=	dual
LICENSE_FILE_APACHE20=	${WRKSRC}/LICENSE-APACHE
LICENSE_FILE_MIT=	${WRKSRC}/LICENSE-MIT

USES=		cmake localbase:ldflags
USE_LDCONFIG=	yes

CMAKE_OFF=	ADA_TESTING ADA_BENCHMARKS ADA_TOOLS
CMAKE_ON=	BUILD_SHARED_LIBS \
		CMAKE_DISABLE_FIND_PACKAGE_Git \
		CMAKE_DISABLE_FIND_PACKAGE_Python3

USE_GITHUB=	yes
GH_ACCOUNT=	ada-url
GH_PROJECT=	ada

PLIST_SUB=	SOVERSION=${PORTVERSION}

.include <bsd.port.mk>
