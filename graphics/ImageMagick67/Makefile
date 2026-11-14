# graphics/ImageMagick67: the programs of ImageMagick 6 and 7 of azsupport/ports in
# one package (aZ, 14.11.2026), as ImageMagick6 and ImageMagick7 were side by side
# before: ImageMagick 7 as in graphics/ImageMagick7 (bin/magick and the usual names
# linked to it), ImageMagick 6 as in graphics/ImageMagick6 with a 6 at the end of the
# name of every program (convert6, identify6, mogrify6, composite6...: AZ_IM6_SUFFIX=6
# of tools/imagemagick-build.sh). Their libraries, headers, configuration and
# policy are the packages libimagemagick6 and libimagemagick7, which it depends on;
# the conf and the policy of graphics/ImageMagick7/files, the patches of
# graphics/ImageMagick6/files. It conflicts with ImageMagick6 and ImageMagick7 (their
# programs). The script builds each ImageMagick into a stage of its own (it starts
# the stage of the one it builds anew); the package has the programs of both
# (AZ_IM_PART=bin).

PORTNAME=	ImageMagick
IM6_VERSION=	6.9.13-60
IM7_VERSION=	7.1.2-35
# both releases (the take lines of imagemagick.conf), ImageMagick 7 first: a new
# release of either gives a higher version
PORTVERSION=	${IM7_VERSION:S/-/./}.${IM6_VERSION:S/-/./}
CATEGORIES=	graphics
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	67
DISTFILES=	${PORTNAME}-${IM6_VERSION}.tar.xz ${PORTNAME}-${IM7_VERSION}.tar.xz

COMMENT=	ImageMagick 7 (magick) and 6 (convert6, identify6, ...) for the video sites
WWW=		https://imagemagick.org/ \
		https://legacy.imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licences are in share/licenses/ImageMagick6/ of libimagemagick6 and share/licenses/ImageMagick7/ of libimagemagick7
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# the programs run with the libraries of libimagemagick6 and libimagemagick7 (also
# when the build checks them)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az \
		${AZ_PREFIX}/lib/libMagickWand-6.so:graphics/libimagemagick6 \
		${AZ_PREFIX}/lib/libMagickWand-7.so:graphics/libimagemagick7
RUN_DEPENDS=	${AZ_PREFIX}/lib/libheif.so:az/az \
		${AZ_PREFIX}/lib/libMagickWand-6.so:graphics/libimagemagick6 \
		${AZ_PREFIX}/lib/libMagickWand-7.so:graphics/libimagemagick7
AZ_HASH_LIBS=	fontconfig freetype2 lcms2 mozjpeg png webp

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# ImageMagick6 and ImageMagick7 have its programs, the official packages in both
# flavors too
CONFLICTS_INSTALL=	ImageMagick6 ImageMagick6-nox11 ImageMagick7 \
			ImageMagick7-nox11

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/az/az/Makefile.common"

AZ_IM_ENV=	AZ_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf AZ_IM_PART=bin
# what tools/imagemagick-build.sh reads of the other ports: the conf and the policy
# of graphics/ImageMagick7, the patches of graphics/ImageMagick6 (in its az_hash,
# tools/build.sh, so that a change of them builds it again)
AZ_HASH_FILES=	${.CURDIR:H}/ImageMagick6/files \
		${.CURDIR:H}/ImageMagick7/files

post-fetch:
.for im in imagemagick6 imagemagick7
	@${SETENV} ${AZ_ENV} ${AZ_IM_ENV} ${SH} ${AZ_TOOLS}/imagemagick-build.sh --fetch ${im}
.endfor

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} AZ_STAGEDIR=${AZ_STAGEDIR}6 \
		AZ_IM6_SUFFIX=6 ${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick6
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_IM_ENV} AZ_STAGEDIR=${AZ_STAGEDIR}7 \
		${SH} ${AZ_TOOLS}/imagemagick-build.sh imagemagick7

do-install:
	@${MKDIR} ${STAGEDIR}
.for v in 6 7
	@(cd ${AZ_STAGEDIR}${v} && ${TAR} -cf - .) | (cd ${STAGEDIR} && ${TAR} -xpf -)
.endfor

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
