# graphics/ImageMagick7: the programs of the ImageMagick 7 of azsupport/ports in the
# place of the official graphics/ImageMagick7 (the design: the head of az/az/Makefile):
# bin/magick and the usual names linked to it, with only what the video sites need
# (files/imagemagick.conf: why, and the options). Its libraries, headers, config
# scripts, configuration and policy (files/policy.xml as etc/ImageMagick-7/policy.xml)
# are the package libimagemagick7 (graphics/libimagemagick7), which it depends on, as
# imagick7 of PHP does (aZ, 14.11.2026: the libraries in packages of their own).
# tools/imagemagick-build.sh makes the official port of the pinned commit with the
# release of the take line of imagemagick.conf (a distfile of this port), builds it
# against the shared tree of az (run path /usr/local/az/lib: our ports link each
# other's shared libraries, aZ 10.11.2026) and keeps the programs (AZ_IM_PART=bin).
# The conf and the policy here are those of graphics/ImageMagick6, ImageMagick67,
# libimagemagick6 and libimagemagick7 too. It conflicts with ImageMagick6 and
# ImageMagick67 (aZ, 14.11.2026), whose ImageMagick 7 is this one.

PORTNAME=	ImageMagick
DISTVERSION=	7.1.2-36
CATEGORIES=	graphics
# the take line of files/imagemagick.conf (the release before the port's)
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	7
DISTFILES=	${DISTNAME}.tar.xz

COMMENT=	ImageMagick 7 for the video sites (magick, convert, identify, ...)
WWW=		https://imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licence is in share/licenses/ImageMagick7/LICENSE of libimagemagick7
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# its libraries: built with the programs, the package has only the programs, which
# run with those of libimagemagick7 (also when the build checks them)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az \
		${AZ_PREFIX}/lib/libMagickWand-7.so:graphics/libimagemagick7
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az \
		${AZ_PREFIX}/lib/libMagickWand-7.so:graphics/libimagemagick7
# the libraries of az in its hash (tools/build.sh) besides libheif: those its shared
# libraries and magick link (their NEEDED)
AZ_HASH_LIBS=	fontconfig freetype2 lcms2 mozjpeg png webp

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same files; ImageMagick6 the
# same names of the programs, ImageMagick67 these files (aZ, 14.11.2026: none of the
# three with another)
CONFLICTS_INSTALL=	ImageMagick7-nox11 ImageMagick6 ImageMagick6-nox11 \
			ImageMagick67

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_IM_ENV=	AZ_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf AZ_IM_PART=bin

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh --fetch imagemagick7

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick7

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
