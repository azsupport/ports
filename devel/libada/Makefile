# devel/libada of azsupport/ports in the place of the official one (its Makefile,
# pkg-plist and pkg-descr): the URL parser of www/node24 (aZ, 11.11.2026: the libraries
# that Node.js bundles as ports of this tree). 4.0.0 ahead of the official 3.4.4 (aZ,
# 16.11.2026): the ada that Node.js 24.22.3 bundles, with the fixes of 3.4.4..4.0.0 (a
# denial of service of the URLPattern tokenizer on malformed UTF-8, #1125; the length
# limit of href_from_file and of search params, #1193; parsing fixes, #1156, #1157,
# #1167, #1186); its library libada.so.4, one header more (url_ip-inl.h). 4.1.1 since
# 22.11.2026 (a release of the major version we have that fixes vulnerabilities, rule
# of aZ of that day): memory safety fixes, a use-after-free of the inputs of a URLPattern
# result (#1360), the iterators and reset of the search params of the C API (#1310), the
# input of a setter that aliases the buffer of the URL (#1320), the members of a moved
# url_pattern_result (#1358), set_host grown past the length limit by IDNA (#1328), the
# strings of the C API NUL-terminated (#1353), the index of ada_strings_get checked
# (#1293); the same API and libada.so.4, two headers more (url_pattern_list.h,
# url_pattern_list-inl.h). SHA-256 of the archive as in the ada-url formula of
# Homebrew (distinfo.yml of 22.11.2026, run 45027832708).

PORTNAME=	libada
DISTVERSIONPREFIX=	v
DISTVERSION=	4.1.1
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
