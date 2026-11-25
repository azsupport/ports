# graphics/libultrahdr: libultrahdr of azsupport/ports in the place of the official
# graphics/libultrahdr, for the libvips of net-im/rocketchat8 (Ultra HDR JPEG; aZ,
# 18.11.2026 16:02: «да конечно» — the libraries sharp needs that we do not have as
# ports of this tree become ours, shared, with the options of sharp-libvips). The
# official port on mozjpeg of azsupport (not USES=jpeg), with what sharp-libvips sets: no
# examples (ultrahdr_app), UHDR_ENABLE_HEIF off, the largest dimension 65500; the shared
# library alone (no static one). LTO (aZ, 18.11.2026 12:29).

PORTNAME=	libultrahdr
PORTVERSION=	2.0.2
DISTVERSIONPREFIX=	v
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	graphics

MAINTAINER=	github@azsupport.com
COMMENT=	Reference codec for the Ultra HDR format (of azsupport/ports)
WWW=		https://developer.android.com/media/platform/hdr-image-format \
		https://github.com/google/libultrahdr \
		https://github.com/azsupport/ports

LICENSE=	APACHE20 MIT
LICENSE_COMB=	dual
LICENSE_FILE=	${WRKSRC}/LICENSE

USES=		cmake
USE_GITHUB=	yes
GH_ACCOUNT=	google
USE_LDCONFIG=	yes
WITH_LTO=	yes

CMAKE_OFF=	BUILD_STATIC_LIBS \
		UHDR_BUILD_BENCHMARK \
		UHDR_BUILD_DEPS \
		UHDR_BUILD_EXAMPLES \
		UHDR_BUILD_FUZZERS \
		UHDR_BUILD_JAVA \
		UHDR_BUILD_PACKAGING \
		UHDR_BUILD_TESTS \
		UHDR_ENABLE_GLES \
		UHDR_ENABLE_HEIF \
		UHDR_ENABLE_LOGS \
		UHDR_ENABLE_SMPTE2094_50 \
		UHDR_ENABLE_WERROR \
		UHDR_WRITE_XMP
CMAKE_ON=	BUILD_SHARED_LIBS \
		UHDR_ENABLE_INSTALL \
		UHDR_ENABLE_INTRINSICS \
		UHDR_WRITE_ISO
# the headers of mozjpeg of azsupport alone (Mk/azsupport-libs.mk), its library in azsupport
CMAKE_ARGS=	-DUHDR_MAX_DIMENSION=65500 \
		-DCMAKE_PREFIX_PATH=${WRKDIR}/azsupport-libs \
		-DCMAKE_LIBRARY_PATH=${AZSUPPORT_PREFIX}/lib

PLIST_SUB=	PORTVERSION=${PORTVERSION}

AZSUPPORT_LIBS=	mozjpeg:libjpeg.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

post-install:
	@/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libuhdr.so | ${GREP} -q 'NEEDED.*\[libjpeg\.' || \
		{ ${ECHO_MSG} "libultrahdr: not linked with libjpeg"; exit 1; }

.include <bsd.port.mk>
