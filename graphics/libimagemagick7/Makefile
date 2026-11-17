# graphics/libimagemagick7: the libraries of the ImageMagick 7 of azsupport/ports in
# a package of their own (aZ, 14.11.2026), which the programs (ImageMagick7,
# ImageMagick67) and imagick7 of PHP depend on, so that PHP needs no programs: its
# shared libMagickCore-7.so and libMagickWand-7.so with lib/ImageMagick-7.* in
# /usr/local/az/lib, its headers (include/ImageMagick-7), .pc files and
# bin/MagickWand-config, bin/MagickCore-config there (the link line with the run
# path), which imagick7 runs; its static libraries, headers and config scripts in
# /usr/local/az/static, for the static imagick of PHP built on a server
# (az-menu.sh); etc/ImageMagick-7 (its configuration, with the policy
# graphics/ImageMagick7/files/policy.xml, which the libraries read) and
# share/ImageMagick-7 in /usr/local, the licences and share/doc/ImageMagick7/VERSIONS.
# tools/imagemagick-build.sh makes the official port of the pinned commit with the
# release of the take line of imagemagick.conf (a distfile of this port), builds it
# twice, static against the static tree of az, shared against its shared tree (run
# path /usr/local/az/lib), and keeps all but the programs (AZ_IM_PART=lib).

PORTNAME=	libimagemagick
DISTVERSION=	7.1.2-36
CATEGORIES=	graphics
# the take line of graphics/ImageMagick7/files/imagemagick.conf
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	7
DISTNAME=	ImageMagick-${DISTVERSION}
DISTFILES=	${DISTNAME}.tar.xz

COMMENT=	Libraries, headers and policy of ImageMagick 7 (for magick and imagick7)
WWW=		https://imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licence is in share/licenses/ImageMagick7/LICENSE
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# the static tree for the static libraries, the shared tree for libMagickWand-7.so,
# which links it
BUILD_DEPENDS=	${AZ_STATIC}/lib/libheif.a:az/az \
		${AZ_PREFIX}/lib/libheif.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az
# the libraries of az in its hash (tools/build.sh) besides libheif: those its shared
# libraries link (their NEEDED), and their headers in the static tree
AZ_HASH_LIBS=	fontconfig freetype2 lcms2 mozjpeg png webp
# its static libraries are its own objects (PHP built on a server links them with the
# archives of az): no code of az in its package
AZ_STATIC_LIBS=	none

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package (both flavors) has its configuration in etc/ImageMagick-7
CONFLICTS_INSTALL=	ImageMagick7-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_IM_ENV=	AZ_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf AZ_IM_PART=lib
# the conf and the policy of graphics/ImageMagick7, which tools/imagemagick-build.sh
# reads: in its az_hash (tools/build.sh)
AZ_HASH_FILES=	${.CURDIR:H}/ImageMagick7/files

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh --fetch imagemagick7

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick7

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
