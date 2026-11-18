# sysutils/ipmitool of azsupport/ports in the place of the official one (aZ,
# 18.11.2026: the tools of his old server in our ports, «arcconf, ipmitool, mtr,
# trafshow, gitup эти добавь»): ipmitool 1.8.19, the official port of the pinned tree
# with its patches (files/patch-*: buffer overruns of upstream #24, #368, #389 and
# others; files/status-ipmi.sh.in, the periodic script) and its distinfo, but the
# readline of "ipmitool shell": that of az (/usr/local/az/lib, our ports link each
# other's shared libraries: aZ, 10.11.2026), not the package of devel/readline the
# official USES=readline takes. The open interface of the base system (/dev/ipmi, the
# ipmi(4) driver), the OpenSSL of the base system; without FREEIPMI (the in-band
# driver of GNU FreeIPMI: ipmi(4) does it) and DOCS (the make.conf of the build). With
# three fixes Debian carries and the official port lacks: CVE-2011-4339, the PID file
# of ipmievd writable by every user, and a stack buffer overflow of "ipmitool tsol"
# (files/extra-patch-*, as Gentoo has them), and options=no-timeout of "chassis
# bootparam" (files/patch-chassis-bootparam).

PORTNAME=	ipmitool
PORTVERSION=	1.8.19
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	sysutils
MASTER_SITES=	https://codeberg.org/IPMITool/${PORTNAME}/archive/:ipmi \
		LOCAL/zi/:iana
DISTFILES=	IPMITOOL_${PORTVERSION:S/./_/g}${EXTRACT_SUFX}:ipmi \
		enterprise-numbers-20240907.txt:iana
EXTRACT_ONLY=	IPMITOOL_${PORTVERSION:S/./_/g}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	CLI to manage IPMI systems (of azsupport/ports)
WWW=		https://codeberg.org/IPMITool/ipmitool \
		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/COPYING

# libreadline.so of az; configure finds it by AC_SEARCH_LIBS (readline, then edit:
# the libedit of the base system, which the -L of ${WRKDIR}/az keeps away)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libreadline.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libreadline.so:az/az

USES=		autoreconf libtool cpe gmake ssl
CPE_VENDOR=	sun
GNU_CONFIGURE=	yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
PLIST_FILES=	bin/ipmitool \
		share/man/man1/ipmitool.1.gz \
		share/man/man8/ipmievd.8.gz \
		sbin/ipmievd \
		share/ipmitool/oem_ibm_sel_map \
		share/ipmitool/enterprise-numbers \
		${PERIODIC_DIR}/400.status-ipmi
SUB_FILES=	status-ipmi.sh
PORTDOCS=	AUTHORS COPYING ChangeLog README

PERIODIC_DIR=	etc/periodic/daily

OPTIONS_DEFINE=	FREEIPMI DOCS
FREEIPMI_DESC=	Enable support for freeipmi

WRKSRC=		${WRKDIR}/${PORTNAME}

CFLAGS+=	-I${OPENSSLINC}
LDFLAGS+=	-L${OPENSSLLIB}
# the headers and the library of readline of az alone (links in ${WRKDIR}/az), not
# the include directory of az with its other headers (iconv.h of GNU libiconv), and
# its run path
CPPFLAGS+=	-I${WRKDIR}/az/include
LDFLAGS+=	-L${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib

.if exists(/usr/include/sys/ipmi.h)
CONFIGURE_ARGS+=	--enable-intf-open
.else
CONFIGURE_ARGS+=	--disable-intf-open
.endif

# the shell required: configure fails without readline
CONFIGURE_ARGS+=	--enable-ipmishell IANADIR=${DATADIR}
EXTRA_PATCHES=	${FILESDIR}/extra-patch-CVE-2011-4339:-p1 \
		${FILESDIR}/extra-patch-tsol-buffer-overflow:-p1
DOCS_EXTRA_PATCHES_OFF=	${PATCHDIR}/extra-patch-Makefile.in

FREEIPMI_LIB_DEPENDS=	libfreeipmi.so:sysutils/freeipmi
FREEIPMI_CPPFLAGS=	-I${LOCALBASE}/include
FREEIPMI_LDFLAGS=	-L${LOCALBASE}/lib
FREEIPMI_CONFIGURE_ENABLE=	intf-free

.include <bsd.port.options.mk>

pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib
	${LN} -sf ${AZ_PREFIX}/include/readline ${WRKDIR}/az/include/readline
	${LN} -sf ${AZ_PREFIX}/lib/libreadline.so ${WRKDIR}/az/lib/libreadline.so

post-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/${PERIODIC_DIR}
	${INSTALL_SCRIPT} ${WRKDIR}/status-ipmi.sh \
		${STAGEDIR}${PREFIX}/${PERIODIC_DIR}/400.status-ipmi
	${INSTALL_DATA} ${DISTDIR}/enterprise-numbers-20240907.txt \
		${STAGEDIR}${DATADIR}/enterprise-numbers

.include <bsd.port.mk>
