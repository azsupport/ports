# devel/uvwasi of azsupport/ports: the official port (its patch of uvwasi.pc,
# pkg-plist, pkg-descr) on the libuv of az, with the run path /usr/local/az/lib
# (aZ, 11.11.2026: the libraries that Node.js bundles as ports of this tree; our
# ports link each other's shared libraries), not on devel/libuv: the WASI of
# www/node24.

PORTNAME=	uvwasi
PORTVERSION=	0.0.23
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONPREFIX=	v
CATEGORIES=	devel

MAINTAINER=	github@azsupport.com
COMMENT=	WASI syscall API built atop libuv (of azsupport/ports)
WWW=		https://github.com/nodejs/uvwasi \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libuv.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libuv.so:az/az

USES=		cmake:testing
USE_GITHUB=	yes
GH_ACCOUNT=	nodejs

# cmake/FindLIBUV.cmake finds these by find_path and find_library, which take
# the cache variables as they are: the libuv of az (its uv.h and libuv.so), with
# its directory as the run path of libuvwasi.so (CMAKE_INSTALL_RPATH_USE_LINK_PATH
# of USES=cmake, and the -rpath below)
CMAKE_ARGS=	-DLIBUV_INCLUDE_DIR=${AZ_PREFIX}/include \
		-DLIBUV_LIBRARIES=${AZ_PREFIX}/lib/libuv.so
CMAKE_OFF=	ASAN \
		BUILD_TESTING \
		CODE_COVERAGE \
		UVWASI_DEBUG_LOG
CMAKE_ON=	INSTALL_UVWASI
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

# libuvwasi.so: the libuv of az, found by its run path
post-install:
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/libuvwasi.so | ${GREP} -q 'Shared library: \[libuv\.so\.1\]' || \
		{ ${ECHO_MSG} "libuvwasi.so does not link libuv.so.1"; ${FALSE}; }
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/libuvwasi.so | ${GREP} -E -q '(RUNPATH|RPATH).*${AZ_PREFIX}/lib' || \
		{ ${ECHO_MSG} "libuvwasi.so has no run path ${AZ_PREFIX}/lib"; ${FALSE}; }

.include <bsd.port.mk>
