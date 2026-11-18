# sysutils/arcconf of azsupport/ports in the place of the official one (aZ, 18.11.2026:
# the tools of his old server in our ports, «arcconf, ipmitool, mtr, trafshow, gitup
# эти добавь»): arcconf 5.12.00 build 28542 of Microchip (the Adaptec RAID controllers),
# the binary for FreeBSD 15 of its archive (freebsd15_x86_64/cmdline/arcconf), with the
# periodic script of the official port (410.status-aac-raid). The archive may not be
# fetched or mirrored (the licence of Microchip: no-dist-mirror, no-dist-sell,
# no-pkg-sell; aZ downloaded it accepting the licence, 18.11.2026 12:03): build.yml
# takes it from the private azsupport/azsupport (distfiles/) into the distfiles of the
# build and leaves it out of their cache; the package may be given out (pkg-mirror).
# Its libstdc++.so.6 (GLIBCXX_3.4.29 at most) is that of gcc16-libs (lang/gcc16-libs:
# the run-time libraries of GCC 16 of this tree alone), in the place of the whole of
# lang/gcc14 the official port takes (USE_GCC: the compiler, gmp, mpfr, mpc and the
# binutils on a server); libgcc_s.so.1, libtinfow, libcam, libthr and libm of the base
# system.

PORTNAME=	arcconf
DISTVERSION=	5.12.00.${BUILD}
PORTEPOCH=	1
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	sysutils
MASTER_SITES=	https://www.microchip.com/en-us/adaptec/
DISTNAME=	arcconf_B${BUILD}

MAINTAINER=	github@azsupport.com
COMMENT=	Adaptec SCSI/SAS RAID administration tool (of azsupport/ports)
WWW=		https://www.microchip.com/en-us/adaptec/ \
		https://github.com/azsupport/ports

LICENSE=	Microchip
LICENSE_NAME=	Microchip License
LICENSE_FILE=	${WRKSRC}/freebsd${DIST_TYPE}/cmdline/License.txt
LICENSE_PERMS=	no-dist-mirror no-dist-sell no-pkg-sell auto-accept

ONLY_FOR_ARCHS=	amd64
ONLY_FOR_ARCHS_REASON=	precompiled binary
LIB_DEPENDS=	libstdc++.so.6:lang/gcc16-libs

USES=		zip
BUILD=		28542
DIST_TYPE=	15_x86_64

NO_BUILD=	yes

SUB_FILES+=	${PERIODICSCRIPT}

PERIODICSCRIPT=	410.status-aac-raid

NO_WRKSUBDIR=	yes

PLIST_FILES=	etc/periodic/daily/410.status-aac-raid \
		sbin/arcconf

.include <bsd.port.pre.mk>

.if !exists(${DISTDIR}/${DISTNAME}${EXTRACT_SUFX})
IGNORE=		may not be redistributed because of licensing reasons. Please visit ${WWW:[1]}, accept the Microchip software license agreement, and download ${DISTNAME}${EXTRACT_SUFX} into ${DISTDIR}
.endif

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/freebsd${DIST_TYPE}/cmdline/arcconf ${STAGEDIR}${PREFIX}/sbin
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/periodic/daily
	${INSTALL_SCRIPT} ${WRKDIR}/${PERIODICSCRIPT} ${STAGEDIR}${PREFIX}/etc/periodic/daily

.include <bsd.port.post.mk>
