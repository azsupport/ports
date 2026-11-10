# graphics/ImageMagick6: the ImageMagick 6 of azsupport/ports in the place of the
# official graphics/ImageMagick6 (the design: the head of az/az/Makefile), the
# package ImageMagick6 of tools/build-az.sh of azsupport/php-src: bin/convert6,
# identify6, mogrify6, composite6 and the others (a 6 at the end of every name,
# next to ImageMagick 7), with only what the video sites need and the policy of
# azsupport/ports (graphics/ImageMagick7/files/imagemagick.conf and policy.xml,
# one copy for both: etc/ImageMagick-6/policy.xml), linking its libraries
# libMagickCore-6.Q16 and libMagickWand-6.Q16 in /usr/local/az/lib.
# tools/imagemagick-build.sh makes the official port of the pinned commit with the
# release of the take line of imagemagick.conf (a distfile of this port), applies
# files/imagemagick6-*.patch and builds it against the shared tree of az, run
# path /usr/local/az/lib (our ports link each other's shared libraries: aZ,
# 10.11.2026): az at run time too.

PORTNAME=	ImageMagick
DISTVERSION=	6.9.13-60
PORTEPOCH=	1
CATEGORIES=	graphics
# the take line of imagemagick.conf (the release before the port's)
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	6
DISTFILES=	${DISTNAME}.tar.xz

COMMENT=	ImageMagick 6 for the video sites (convert6, identify6, ...)
WWW=		https://legacy.imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licence is in share/licenses/ImageMagick6/LICENSE
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same configuration files
CONFLICTS_INSTALL=	ImageMagick6-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_IM_ENV=	AZ_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh --fetch imagemagick6

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick6

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
