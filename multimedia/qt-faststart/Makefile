# multimedia/qt-faststart: qt-faststart of azsupport/ports (aZ, 10.11.2026: still
# needed for compatibility, to go when it no longer is), the port that expired
# from the official tree on 30.06.2022 (MOVED: obsolete, ffmpeg does it; removed in
# c46b556a1b83) brought back: tools/qt-faststart.c of the FFmpeg release of
# multimedia/ffmpeg of this tree (only that file is extracted), which moves the
# moov atom of an MP4 or MOV file in front of its data for progressive playback,
# as ffmpeg -movflags +faststart does; in the public domain. The official port was
# 0.2: a copy of that file of about 2010 in its files/, no patches, no options,
# bin/qt-faststart only; FFmpeg's has the same use (qt-faststart <in> <out>, the
# same message and exit when moov is first already) and the fixes since (sizes of
# the atoms checked, a limit on ftyp, stco made co64 when the offsets pass 4 GB).
# One file of C, no library: bin/qt-faststart (PIE, RELRO, BIND_NOW); 9.0.2 is
# above 0.2, so pkg upgrades an old one.

PORTNAME=	qt-faststart
DISTVERSION=	9.0.2
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	multimedia
MASTER_SITES=	https://ffmpeg.org/releases/
DISTNAME=	ffmpeg-${DISTVERSION}

MAINTAINER=	github@azsupport.com
COMMENT=	Move the moov atom of MP4 and MOV files to the front (of azsupport/ports)
WWW=		https://ffmpeg.org/ \
		https://github.com/azsupport/ports

LICENSE=	PD

USES=		tar:xz
EXTRACT_AFTER_ARGS=	--no-same-owner --no-same-permissions \
			${DISTNAME}/tools/qt-faststart.c

CFLAGS+=	-fPIE
LDFLAGS+=	-pie -Wl,-z,relro,-z,now

PLIST_FILES=	bin/qt-faststart

do-build:
	${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} -o ${WRKSRC}/qt-faststart \
		${WRKSRC}/tools/qt-faststart.c

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/qt-faststart ${STAGEDIR}${PREFIX}/bin/

.include <bsd.port.mk>
