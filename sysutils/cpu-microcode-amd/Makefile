# sysutils/cpu-microcode-amd: the microcode of AMD CPUs of azsupport/ports in the
# place of the official sysutils/cpu-microcode-amd (aZ, 15.11.2026: «для amd так же
# как и для intel»): the official port with the options of
# sysutils/cpu-microcode-intel, both on: RC, the rc.d script of
# sysutils/cpu-microcode-rc as a dependency (the official one has it always), and
# SPLIT, the files of the families in share/cpucontrol for cpucontrol(8) and the rc.d
# script (always in the official one: linux-firmware has them split by family, so
# there is nothing to split, unlike the files of Intel); /boot/firmware/amd-ucode.bin
# for the loader always, as intel-ucode.bin. Its pkg-message of the official tree
# after the pinned commit. The files of the commit also from the repository of
# linux-firmware on GitLab, where it is kept (git.kernel.org: "No route to host" from
# the runners of GitHub, run 43708464894; distcache of FreeBSD: not found).

PORTNAME=	microcode
PORTVERSION=	20251202
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	sysutils
MASTER_SITES=	https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/amd-ucode/ \
		https://gitlab.com/kernel-firmware/linux-firmware/-/raw/${_REV}/amd-ucode/
PKGNAMEPREFIX=	cpu-
PKGNAMESUFFIX=	-amd
DISTFILES=	microcode_amd.bin?id=${_REV} \
		microcode_amd_fam15h.bin?id=${_REV} \
		microcode_amd_fam16h.bin?id=${_REV} \
		microcode_amd_fam17h.bin?id=${_REV} \
		microcode_amd_fam19h.bin?id=${_REV} \
		microcode_amd_fam1ah.bin?id=${_REV}
DIST_SUBDIR=	${PKGNAMEPREFIX}${PORTNAME}${PKGNAMESUFFIX}

MAINTAINER=	github@azsupport.com
COMMENT=	AMD CPU microcode updates (of azsupport/ports)
WWW=		https://github.com/azsupport/ports

LICENSE=	EULA
LICENSE_NAME=	Advanced Micro Devices License Agreement
LICENSE_FILE=	${FILESDIR}/LICENSE.amd-ucode
LICENSE_PERMS=	dist-mirror no-dist-sell pkg-mirror no-pkg-sell auto-accept

ONLY_FOR_ARCHS=	amd64 i386

DATADIR=	${PREFIX}/share/cpucontrol
FWDIR=		/boot/firmware

EXTRACT_CMD=	${CP}
EXTRACT_BEFORE_ARGS=	# empty
EXTRACT_AFTER_ARGS=	.
NO_ARCH=	yes
NO_BUILD=	yes
NO_WRKSUBDIR=	yes

PLIST_FILES=	${FWDIR}/amd-ucode.bin

OPTIONS_DEFINE=		RC SPLIT
OPTIONS_DEFAULT=	RC SPLIT
RC_DESC=	Depend on RC script port (automatic update method two)
SPLIT_DESC=	Install the files of the families (for cpucontrol(8) and RC script)
RC_IMPLIES=	SPLIT
RC_RUN_DEPENDS=	${LOCALBASE}/etc/rc.d/microcode_update:sysutils/cpu-microcode-rc
SPLIT_PLIST_FILES=	${DISTFILES:S/^/${DATADIR}\//g:C/\?.*//}

_REV=		2b318c8e4159234ddbcc1cadc90cf32d17d9ee82

post-extract:
	${CAT} ${WRKSRC}/microcode_amd* > ${WRKSRC}/amd-ucode.bin

do-install:
	${MKDIR} ${STAGEDIR}${FWDIR}
	${INSTALL_DATA} ${WRKSRC}/amd-ucode.bin ${STAGEDIR}${FWDIR}/

do-install-SPLIT-on:
	${MKDIR} ${STAGEDIR}${DATADIR}/
.for f in ${DISTFILES}
	${INSTALL_DATA} ${WRKSRC}/${f} ${STAGEDIR}${DATADIR}/${f:C/\?.*//}
.endfor

.include <bsd.port.mk>
