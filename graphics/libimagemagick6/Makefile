# graphics/libimagemagick6: the libraries of the ImageMagick 6 of azsupport/ports in
# a package of their own (aZ, 14.11.2026), which the programs (ImageMagick6,
# ImageMagick67) and imagick6 of PHP depend on, so that PHP needs no programs: its
# shared libMagickCore-6.Q16 and libMagickWand-6.Q16 with lib/ImageMagick-6.* in
# /usr/local/az/lib, its headers (include/ImageMagick-6) and the .pc files with its
# version in the name there (those without it are of ImageMagick 7),
# libexec/ImageMagick-6/bin/MagickWand-config and MagickCore-config (the link line
# with the run path; imagick6 of PHP: --with-imagick=/usr/local/az/libexec/ImageMagick-6,
# as those of ImageMagick 7 in /usr/local/az/bin have the same names);
# etc/ImageMagick-6 (its configuration, with the policy
# graphics/ImageMagick7/files/policy.xml, which the libraries read) and
# share/ImageMagick-6 in /usr/local, the licences and share/doc/ImageMagick6/VERSIONS.
# tools/imagemagick-build.sh makes the official port of the pinned commit with the
# release of the take line of imagemagick.conf (a distfile of this port), applies
# graphics/ImageMagick6/files/imagemagick6-*.patch, builds it against the shared
# tree of az (run path /usr/local/az/lib) and keeps all but the programs
# (AZ_IM_PART=lib).

PORTNAME=	libimagemagick
DISTVERSION=	6.9.13-60
CATEGORIES=	graphics
# the take line of graphics/ImageMagick7/files/imagemagick.conf
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	6
DISTNAME=	ImageMagick-${DISTVERSION}
DISTFILES=	${DISTNAME}.tar.xz

COMMENT=	Libraries, headers and policy of ImageMagick 6 (for convert and imagick6)
WWW=		https://legacy.imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licence is in share/licenses/ImageMagick6/LICENSE
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az
# the libraries of az in its hash (tools/build.sh) besides libheif: those its shared
# libraries link (their NEEDED)
AZ_HASH_LIBS=	fontconfig freetype2 lcms2 mozjpeg png webp

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package (both flavors) has its configuration in etc/ImageMagick-6
CONFLICTS_INSTALL=	ImageMagick6-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_IM_ENV=	AZ_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf AZ_IM_PART=lib
# what tools/imagemagick-build.sh reads of the other ports: the conf and the policy
# of graphics/ImageMagick7, the patches of graphics/ImageMagick6 (in its az_hash,
# tools/build.sh, so that a change of them builds it again)
AZ_HASH_FILES=	${.CURDIR:H}/ImageMagick6/files \
		${.CURDIR:H}/ImageMagick7/files

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh --fetch imagemagick6

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick6

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
