# graphics/tiff: libtiff of azsupport/ports in the place of the official graphics/tiff,
# for the libvips of net-im/rocketchat8 (sharp; aZ, 18.11.2026 16:02: «да конечно» —
# the libraries sharp needs that we do not have as ports of this tree become ours,
# shared, with the options of sharp-libvips). The library alone, as sharp-libvips
# builds it: JPEG (mozjpeg of azsupport), Deflate (zlib of the base system) and WebP (of azsupport);
# no JBIG, LERC, libdeflate, LZMA, ZSTD, old JPEG, PixarLog, OpenGL, C++ library,
# tools, contrib, documents, tests, MDI. LTO (aZ, 18.11.2026 12:29).

PORTNAME=	tiff
DISTVERSION=	4.7.2
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	graphics
MASTER_SITES=	https://download.osgeo.org/libtiff/

MAINTAINER=	github@azsupport.com
COMMENT=	Library routines for working with TIFF images (of azsupport/ports)
WWW=		http://www.simplesystems.org/libtiff/ \
		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE.md

USES=		cmake cpe pathfix pkgconfig tar:xz
CPE_PRODUCT=	libtiff
PATHFIX_CMAKELISTSTXT=	PkgConfig.cmake
USE_LDCONFIG=	yes
WITH_LTO=	yes

CMAKE_ON=	CMAKE_DISABLE_FIND_PACKAGE_GLUT \
		CMAKE_DISABLE_FIND_PACKAGE_OpenGL \
		jpeg \
		webp \
		zlib
CMAKE_OFF=	jbig \
		lerc \
		libdeflate \
		lzma \
		mdi \
		old-jpeg \
		pixarlog \
		tiff-contrib \
		tiff-cxx \
		tiff-docs \
		tiff-opengl \
		tiff-tests \
		tiff-tools \
		zstd
# the headers of mozjpeg and WebP of azsupport alone (Mk/azsupport-libs.mk), their libraries in azsupport
CMAKE_ARGS=	-DCMath_HAVE_LIBC_POW=1 \
		-DCMAKE_PREFIX_PATH=${WRKDIR}/azsupport-libs \
		-DCMAKE_LIBRARY_PATH=${AZSUPPORT_PREFIX}/lib

AZSUPPORT_LIBS=	mozjpeg:libjpeg.so \
		webp:libwebp.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# the codecs CMake found, not ones it left out without a word: JPEG and WebP of azsupport, zlib
post-install:
	@n="$$(/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libtiff.so.6 | ${GREP} NEEDED)"; \
	for l in libjpeg libwebp libz; do \
		echo "$$n" | ${GREP} -q "\[$$l\." || { ${ECHO_MSG} "libtiff: no $$l ($$n)"; exit 1; }; \
	done
	@/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libtiff.so.6 | ${GREP} -Eq '(RPATH|RUNPATH).*${AZSUPPORT_PREFIX}/lib' || \
		{ ${ECHO_MSG} "libtiff: no run path ${AZSUPPORT_PREFIX}/lib"; exit 1; }

.include <bsd.port.mk>
