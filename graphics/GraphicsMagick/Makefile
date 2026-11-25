# graphics/GraphicsMagick: the GraphicsMagick of azsupport/ports in the place of
# the official graphics/GraphicsMagick (the design: the head of azsupport/azsupport/Makefile),
# built as our ImageMagick 7: bin/gm with only the formats of our ImageMagick
# (files/graphicsmagick.conf: which, and how the coders not registered take the
# place of a policy, which GraphicsMagick does not have), linking its shared
# libGraphicsMagick.so and libGraphicsMagickWand.so in the shared tree of azsupport
# (/usr/local/azsupport/lib, run path, with GraphicsMagick-config there), which the PHP
# module gmagick links too (--with-gmagick=/usr/local/azsupport; the libraries with the
# symbol prefix Gm: most of their names are those of ImageMagick otherwise); its
# static libraries, headers and GraphicsMagick-config in the static tree
# (/usr/local/azsupport/static), for the static gmagick of PHP built on a server.
# tools/graphicsmagick-build.sh makes the official port of the pinned commit (its
# distfiles, distinfo and patches; fetched in post-fetch), narrows its coders and
# builds it twice: static against the static tree of azsupport, shared against its shared
# tree (our ports link each other's shared libraries: aZ, 10.11.2026).

PORTNAME=	GraphicsMagick
PORTVERSION=	1.3.49
PORTEPOCH=	1
CATEGORIES=	graphics
# the distfiles are those of the official port (its make fetch in post-fetch)
DISTFILES=

COMMENT=	GraphicsMagick for the video sites (gm), and its libraries for gmagick
WWW=		https://graphicsmagick.sourceforge.io/ \
		https://github.com/azsupport/ports

LICENSE=	MIT

# the static tree for the static libraries, the shared tree for gm and the shared
# libraries, which link it
BUILD_DEPENDS=	${AZSUPPORT_STATIC}/lib/libheif.a:azsupport/azsupport \
		${AZSUPPORT_PREFIX}/lib/libheif.so:azsupport/azsupport
RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libheif.so:azsupport/azsupport
# the libraries of azsupport in its hash (tools/build.sh) besides libheif: those its shared
# libraries and gm link (their NEEDED), and their headers in the static tree
AZSUPPORT_HASH_LIBS=	freetype2 lcms2 libzip mozjpeg png webp
# its static libraries are its own objects (PHP built on a server links them with the
# archives of azsupport): no code of azsupport in its package
AZSUPPORT_STATIC_LIBS=	none

USES=		gmake pkgconfig

# the official package in its other flavor has the same files
CONFLICTS_INSTALL=	GraphicsMagick-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/azsupport/azsupport/Makefile.common"

AZSUPPORT_GM_ENV=	AZSUPPORT_GM_CONF=${FILESDIR}/graphicsmagick.conf

post-fetch:
	@${SETENV} ${AZSUPPORT_ENV} ${AZSUPPORT_GM_ENV} ${SH} ${AZSUPPORT_TOOLS}/graphicsmagick-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZSUPPORT_ENV} ${AZSUPPORT_GM_ENV} ${SH} ${AZSUPPORT_TOOLS}/graphicsmagick-build.sh

do-install:
	@${AZSUPPORT_COPY_STAGE}

post-install:
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
