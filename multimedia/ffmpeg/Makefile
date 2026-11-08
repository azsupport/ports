# multimedia/ffmpeg: the FFmpeg of azsupport/ports in the place of the official
# multimedia/ffmpeg (the design: the head of az/az/Makefile), the package ffmpeg
# of tools/build-az.sh of azsupport/php-src: bin/ffmpeg and bin/ffprobe, static,
# with only what the video sites need (files/ffmpeg.conf: why, and the options).
# tools/ffmpeg-build.sh makes the official port of the pinned commit (its
# distfiles, distinfo and patches; fetched in post-fetch), then applies
# files/ffmpeg/*.patch and builds it with the configure lines of ffmpeg.conf,
# against the static libraries of the package az (x264, dav1d, libwebp). A static
# program: no RUN_DEPENDS.

PORTNAME=	ffmpeg
DISTVERSION=	9.0.2
PORTEPOCH=	1
CATEGORIES=	multimedia audio net
# the distfiles are those of the official port (its make fetch in post-fetch)
DISTFILES=

COMMENT=	FFmpeg for the video sites, static (ffmpeg, ffprobe)
WWW=		https://ffmpeg.org/ \
		https://github.com/azsupport/ports

# GPL: --enable-gpl, with libx264 (as build-az.sh)
LICENSE=	GPLv2+

BUILD_DEPENDS=	${AZ_STATIC}/lib/libx264.a:az/az \
		nasm:devel/nasm

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same files
CONFLICTS_INSTALL=	ffmpeg-nox11

NO_WRKSUBDIR=	yes

.include "${.CURDIR:H:H}/az/az/Makefile.common"

post-fetch:
	@${SETENV} ${AZ_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/ffmpeg-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/ffmpeg-build.sh

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
