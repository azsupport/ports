# multimedia/ffmpeg: the FFmpeg of azsupport/ports in the place of the official
# multimedia/ffmpeg (the design: the head of azsupport/static/Makefile), the package ffmpeg
# of tools/build-az.sh of azsupport/php-src: bin/ffmpeg and bin/ffprobe with only
# what the video sites need (files/ffmpeg.conf: why, and the options), its own
# libraries in them.
# tools/ffmpeg-build.sh makes the official port of the pinned commit (its
# distfiles, distinfo and patches; fetched in post-fetch), then applies
# files/ffmpeg/*.patch and builds it with the configure lines of ffmpeg.conf,
# against the shared libraries of azsupport (x264, dav1d, SVT-AV1, libwebp, mozjpeg: a port
# azsupport/<name> each), with the run path /usr/local/azsupport/lib (our ports link each
# other's shared libraries: aZ, 10.11.2026): these at run time too. Built with the AAC encoder libfdk_aac
# (files/ffmpeg-nonfree.conf, --enable-nonfree; AZSUPPORT_FFMPEG_ENV below), one ffmpeg in the
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

# the libraries of azsupport it links, to build and to run (by a file: no ldconfig hints for
# /usr/local/azsupport/lib; their interfaces and those of the libraries they need in its
# hash, tools/build.sh): x264, dav1d, SVT-AV1, libwebp and mozjpeg (the encoder libjpeg);
# cmake: fdk-aac of the nonfree build (tools/ffmpeg-build.sh, b_fdkaac)
BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libx264.so:azsupport/x264 \
		${AZSUPPORT_PREFIX}/lib/libdav1d.so:azsupport/dav1d \
		${AZSUPPORT_PREFIX}/lib/libSvtAv1Enc.so:azsupport/svtav1 \
		${AZSUPPORT_PREFIX}/lib/libwebp.so:azsupport/webp \
		${AZSUPPORT_PREFIX}/lib/libjpeg.so:azsupport/mozjpeg \
		cmake:devel/cmake-core \
		nasm:devel/nasm
RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libx264.so:azsupport/x264 \
		${AZSUPPORT_PREFIX}/lib/libdav1d.so:azsupport/dav1d \
		${AZSUPPORT_PREFIX}/lib/libSvtAv1Enc.so:azsupport/svtav1 \
		${AZSUPPORT_PREFIX}/lib/libwebp.so:azsupport/webp \
		${AZSUPPORT_PREFIX}/lib/libjpeg.so:azsupport/mozjpeg

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

# the official package in its other flavor has the same files
CONFLICTS_INSTALL=	ffmpeg-nox11

NO_WRKSUBDIR=	yes

# for ffmpeg-build.sh, after AZSUPPORT_ENV: the nonfree build with libfdk_aac (aZ, 16.11.2026)
AZSUPPORT_FFMPEG_ENV=	AZSUPPORT_FFMPEG_NONFREE=yes

.include "${.CURDIR:H:H}/azsupport/static/Makefile.common"

post-fetch:
	@${SETENV} ${AZSUPPORT_ENV} ${AZSUPPORT_FFMPEG_ENV} AZSUPPORT_FILESDIR=${FILESDIR} ${SH} ${AZSUPPORT_TOOLS}/ffmpeg-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZSUPPORT_ENV} ${AZSUPPORT_FFMPEG_ENV} AZSUPPORT_FILESDIR=${FILESDIR} ${SH} ${AZSUPPORT_TOOLS}/ffmpeg-build.sh

do-install:
	@${AZSUPPORT_COPY_STAGE}

post-install:
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
