# graphics/ImageMagick6: the programs of the ImageMagick 6 of azsupport/ports in the
# place of the official graphics/ImageMagick6 (the design: the head of azsupport/static/Makefile):
# bin/convert, identify, mogrify, composite and the others by their usual names (aZ,
# 14.11.2026: without the 6 at the end, which only graphics/ImageMagick67 gives them,
# next to ImageMagick 7), with only what the video sites need. Its libraries,
# headers, config scripts, configuration and the policy of azsupport/ports
# (graphics/ImageMagick7/files/imagemagick.conf and policy.xml, one copy for all:
# etc/ImageMagick-6/policy.xml) are the package libimagemagick6
# (graphics/libimagemagick6), which it depends on, as imagick6 of PHP does (aZ,
# 14.11.2026: the libraries in packages of their own). tools/imagemagick-build.sh
# makes the official port of the pinned commit with the release of the take line of
# imagemagick.conf (a distfile of this port), applies files/imagemagick6-*.patch,
# builds it against the shared tree of azsupport (run path /usr/local/azsupport/lib: our ports link
# each other's shared libraries, aZ 10.11.2026) and keeps the programs
# (AZSUPPORT_IM_PART=bin). It conflicts with ImageMagick7 and ImageMagick67 (their files).

PORTNAME=	ImageMagick
DISTVERSION=	6.9.13-61
PORTEPOCH=	1
CATEGORIES=	graphics
# the take line of imagemagick.conf (the release before the port's)
MASTER_SITES=	https://download.imagemagick.org/archive/releases/ \
		https://ftp.acc.umu.se/mirror/imagemagick.org/ftp/releases/ \
		https://mirror.dogado.de/imagemagick/releases/
PKGNAMESUFFIX=	6
DISTFILES=	${DISTNAME}.tar.xz

COMMENT=	ImageMagick 6 for the video sites (convert, identify, ...)
WWW=		https://legacy.imagemagick.org/ \
		https://github.com/azsupport/ports

# the licence name of build-az.sh
LICENSE=	ImageMagick
LICENSE_NAME=	ImageMagick License
LICENSE_TEXT=	The licence is in share/licenses/ImageMagick6/LICENSE of libimagemagick6
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# its libraries: built with the programs, the package has only the programs, which
# run with those of libimagemagick6 (also when the build checks them); the libraries of
# azsupport its shared libraries and its programs link (their NEEDED), to build and to run
# (by a file: no ldconfig hints for /usr/local/azsupport/lib), and fontconfig
# (x11-fonts/fontconfig)
AZSUPPORT_IM_LIBS=	freetype2:libfreetype.so lcms2:liblcms2.so libheif:libheif.so \
		mozjpeg:libjpeg.so png:libpng16.so webp:libwebp.so
BUILD_DEPENDS=	${AZSUPPORT_IM_LIBS:@l@${AZSUPPORT_PREFIX}/lib/${l:C/^[^:]*://}:azsupport/${l:C/:.*//}@} \
		${LOCALBASE}/lib/libfontconfig.so:x11-fonts/fontconfig \
		${AZSUPPORT_PREFIX}/lib/libMagickWand-6.so:graphics/libimagemagick6
RUN_DEPENDS=	${AZSUPPORT_IM_LIBS:@l@${AZSUPPORT_PREFIX}/lib/${l:C/^[^:]*://}:azsupport/${l:C/:.*//}@} \
		${LOCALBASE}/lib/libfontconfig.so:x11-fonts/fontconfig \
		${AZSUPPORT_PREFIX}/lib/libMagickWand-6.so:graphics/libimagemagick6

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same configuration files;
# ImageMagick7 the same names of the programs, ImageMagick67 the same files of
# ImageMagick 6 and those names (aZ, 14.11.2026: none of the three with another)
CONFLICTS_INSTALL=	ImageMagick6-nox11 ImageMagick7 ImageMagick7-nox11 \
			ImageMagick67

NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR:H:H}/azsupport/static/Makefile.common"

AZSUPPORT_IM_ENV=	AZSUPPORT_IM_CONF=${.CURDIR:H}/ImageMagick7/files/imagemagick.conf AZSUPPORT_IM_PART=bin
# the conf (im, take and configure lines of both) and the policy of
# graphics/ImageMagick7, one copy for all, which tools/imagemagick-build.sh reads
# for ImageMagick 6 too: in its azsupport_hash (tools/build.sh), so that a change of them
# builds it again
AZSUPPORT_HASH_FILES=	${.CURDIR:H}/ImageMagick7/files/imagemagick.conf \
		${.CURDIR:H}/ImageMagick7/files/policy.xml

post-fetch:
	@${SETENV} ${AZSUPPORT_ENV} ${AZSUPPORT_IM_ENV} ${SH} ${AZSUPPORT_TOOLS}/imagemagick-build.sh --fetch imagemagick6

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZSUPPORT_ENV} ${AZSUPPORT_IM_ENV} ${SH} ${AZSUPPORT_TOOLS}/imagemagick-build.sh imagemagick6

do-install:
	@${AZSUPPORT_COPY_STAGE}

post-install:
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
