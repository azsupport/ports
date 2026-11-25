# multimedia/ffmpeg: the FFmpeg of azsupport/ports in the place of the official
# multimedia/ffmpeg (the design: the head of az/az/Makefile), the package ffmpeg
# of tools/build-az.sh of azsupport/php-src: bin/ffmpeg and bin/ffprobe with only
# what the video sites need (files/ffmpeg.conf: why, and the options), its own
# libraries in them.
# tools/ffmpeg-build.sh makes the official port of the pinned commit (its
# distfiles, distinfo and patches; fetched in post-fetch), then applies
# files/ffmpeg/*.patch and builds it with the configure lines of ffmpeg.conf,
# against the shared libraries of the package az (x264, dav1d, SVT-AV1, libwebp, mozjpeg), with the
# run path /usr/local/az/lib (our ports link each other's shared libraries: aZ,
# 10.11.2026): az at run time too. Built with the AAC encoder libfdk_aac
# (files/ffmpeg-nonfree.conf, --enable-nonfree; AZ_FFMPEG_ENV below), one ffmpeg in the
# place of a separate nonfree port (aZ, 16.11.2026: the nonfree part goes when he moves
# to open libraries, within a month); its package is published on his responsibility.

PORTNAME=	ffmpeg
DISTVERSION=	9.1
PORTEPOCH=	1
CATEGORIES=	multimedia audio net
# the distfiles are those of the official port (its make fetch in post-fetch)
DISTFILES=

COMMENT?=	FFmpeg for the video sites (ffmpeg, ffprobe)
WWW=		https://ffmpeg.org/ \
		https://github.com/azsupport/ports

# GPL: --enable-gpl, with libx264 (as build-az.sh)
LICENSE=	GPLv2+

# the libraries of az in its hash (tools/build.sh): x264, dav1d, SVT-AV1, libwebp and
# mozjpeg (the encoder libjpeg; their interfaces and those of the libraries they need),
# more than the files of its dependency names
AZ_HASH_LIBS=	x264 dav1d svtav1 webp mozjpeg
# cmake: fdk-aac of the nonfree build (tools/ffmpeg-build.sh, b_fdkaac)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libx264.so:az/az \
		${AZ_PREFIX}/lib/libSvtAv1Enc.so:az/az \
		${AZ_PREFIX}/lib/libjpeg.so:az/az \
		cmake:devel/cmake-core \
		nasm:devel/nasm
RUN_DEPENDS=	${AZ_PREFIX}/lib/libx264.so:az/az \
		${AZ_PREFIX}/lib/libSvtAv1Enc.so:az/az \
		${AZ_PREFIX}/lib/libjpeg.so:az/az

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same files
CONFLICTS_INSTALL=	ffmpeg-nox11

NO_WRKSUBDIR=	yes

# for ffmpeg-build.sh, after AZ_ENV: the nonfree build with libfdk_aac (aZ, 16.11.2026)
AZ_FFMPEG_ENV=	AZ_FFMPEG_NONFREE=yes

.include "${.CURDIR:H:H}/az/az/Makefile.common"

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_FFMPEG_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/ffmpeg-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_FFMPEG_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/ffmpeg-build.sh

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
