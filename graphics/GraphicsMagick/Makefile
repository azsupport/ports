# graphics/GraphicsMagick: the GraphicsMagick of azsupport/ports in the place of
# the official graphics/GraphicsMagick (the design: the head of az/az/Makefile),
# built as our ImageMagick 7: bin/gm with only the formats of our ImageMagick
# (files/graphicsmagick.conf: which, and how the coders not registered take the
# place of a policy, which GraphicsMagick does not have), linking its shared
# libGraphicsMagick.so and libGraphicsMagickWand.so in the shared tree of az
# (/usr/local/az/lib, run path, with GraphicsMagick-config there), which the PHP
# module gmagick links too (--with-gmagick=/usr/local/az; the libraries with the
# symbol prefix Gm: most of their names are those of ImageMagick otherwise); its
# static libraries, headers and GraphicsMagick-config in the static tree
# (/usr/local/az/static), for the static gmagick of PHP built on a server.
# tools/graphicsmagick-build.sh makes the official port of the pinned commit (its
# distfiles, distinfo and patches; fetched in post-fetch), narrows its coders and
# builds it twice: static against the static tree of az, shared against its shared
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
BUILD_DEPENDS=	${AZ_STATIC}/lib/libheif.a:az/az \
		${AZ_PREFIX}/lib/libheif.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az

USES=		gmake pkgconfig

# the official package in its other flavor has the same files
CONFLICTS_INSTALL=	GraphicsMagick-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_GM_ENV=	AZ_GM_CONF=${FILESDIR}/graphicsmagick.conf

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_GM_ENV} ${SH} ${AZ_TOOLS}/graphicsmagick-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_GM_ENV} ${SH} ${AZ_TOOLS}/graphicsmagick-build.sh

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
