# graphics/ImageMagick7: the ImageMagick 7 of azsupport/ports in the place of the
# official graphics/ImageMagick7 (the design: the head of az/az/Makefile), the
# package ImageMagick7 of tools/build-az.sh of azsupport/php-src: bin/magick and
# the usual names linked to it, with only what the video sites need
# (files/imagemagick.conf: why, and the options) and the policy
# files/policy.xml (etc/ImageMagick-7/policy.xml), linking its shared
# libMagickCore-7.so and libMagickWand-7.so in the shared tree of az
# (/usr/local/az/lib, with MagickWand-config there), which imagick of PHP links
# too; its static libraries, headers and MagickWand-config in the static tree of
# az (/usr/local/az/static), for the static imagick of PHP built on a server.
# tools/imagemagick-build.sh makes the official port of the pinned commit with the
# release of the take line of imagemagick.conf (a distfile of this port), then
# builds it twice: static against the static tree of az, shared against its shared
# tree, run path /usr/local/az/lib (our ports link each other's shared libraries:
# aZ, 10.11.2026). The conf and the policy here are those of
# graphics/ImageMagick6 too.

PORTNAME=	ImageMagick
DISTVERSION=	7.1.2-35
CATEGORIES=	graphics
# the take line of files/imagemagick.conf (the release before the port's)
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	7
DISTFILES=	${DISTNAME}.tar.xz

COMMENT=	ImageMagick 7 for the video sites (magick), and its libraries for imagick
WWW=		https://imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licence is in share/licenses/ImageMagick7/LICENSE
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# the static tree for the static libraries, the shared tree for the programs and
# libMagickWand-7.so, which link it
BUILD_DEPENDS=	${AZ_STATIC}/lib/libheif.a:az/az \
		${AZ_PREFIX}/lib/libheif.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same files
CONFLICTS_INSTALL=	ImageMagick7-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_IM_ENV=	AZ_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh --fetch imagemagick7

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick7

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
