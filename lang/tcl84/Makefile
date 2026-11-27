# lang/tcl84 of azsupport/ports: Tcl 8.4.20, the last release of 8.4 (2013), for an
# old application of aZ (19.11.2026). The official port of freebsd-ports
# fc3b56ba75eb, before it was removed as expired (7fc25c874cfc, 21.11.2017), with
# its patches, brought to the framework of the pinned tree: no DEPRECATED, the build
# stamp as PORTREVISION, WWW here, the manual pages (TCLMAN) in share/man, the
# release from SourceForge first. Beside lang/tcl86: tclsh8.4, libtcl84.so.1,
# lib/tcl8.4 and include/tcl8.4 are its own.
# The C compiled by GCC 16 of the ports (USES=azgcc, Mk/Uses/azgcc.mk; a build dependency
# only), aZ 27.11.2026 08:41 («tcl84 — на gcc16»; 08:43 «окей, следуем инфе с тестов»):
# prog-bench (array, expr, list, regexp, string) against the base clang 19, run
# 45926215732: GCC 16 -8.1%, clang 23 -1.4% by the median, GCC 16 faster than clang 23 by
# 7.3% (regexp -46.1%, string -20.7%), clear in 4 of 5; -4.5% on another machine
# (45918232254). Its configure (autoconf 2.13) does not take GCC 14 and later (nor clang
# 23) with the errors of implicit int and implicit declarations of its tests: these, and
# int-conversion and incompatible pointer types, warnings (AZSUPPORT_GCC_CFLAGS), as
# measured and as the base clang 19 has them. Its configure sets the LDFLAGS of FreeBSD
# itself (no -pie of the framework) and links libtcl84.so.1 by ${CC} -shared, the CC of
# configure with -static-libgcc (Mk/Uses/azgcc.mk); tclConfig.sh names cc
# (Mk/azsupport-cc-names.sh).

PORTNAME=	tcl
PORTVERSION=	8.4.20
PORTREVISION=	${AZSUPPORT_STAMP:U0}
PORTEPOCH=	1
CATEGORIES=	lang tcl
MASTER_SITES=	SF/tcl/Tcl/${PORTVERSION} \
		TCLTK/tcl8_4
PKGNAMESUFFIX=	${PORTVERSION:R:S/.//}
DISTNAME=	${PORTNAME}${PORTVERSION}-src

MAINTAINER=	github@azsupport.com
COMMENT=	Tool Command Language 8.4
WWW=		https://www.tcl-lang.org/

LICENSE=	TclTk
LICENSE_NAME=	Tcl/Tk License
LICENSE_FILE=	${WRKSRC}/../license.terms
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

OPTIONS_DEFINE=	TCLMAN THREADS
OPTIONS_DEFAULT=THREADS
TCLMAN_DESC=	Install Tcl function manpages

WRKSRC=		${WRKDIR}/${PORTNAME}${PORTVERSION}/unix

ALL_TARGET=	all
INSTALL_TARGET=	install install-libraries
TEST_TARGET=	test

USE_LDCONFIG=	yes
# GCC of the ports for the C, at build time only (Mk/Uses/azgcc.mk)
USES=		azgcc
AZSUPPORT_GCC_CFLAGS=	-Wno-error=implicit-int -Wno-error=implicit-function-declaration \
			-Wno-error=int-conversion -Wno-error=incompatible-pointer-types
GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--enable-shared \
		--enable-man-suffix=.${MAN_SUFFIX} \
		--includedir=${PREFIX}/include/tcl${TCL_VER}
CONFIGURE_ENV=	PORTSDIR=${PORTSDIR}

TCL_VER=	8.4
SHORT_TCL_VER=	${TCL_VER:S/8./8/}
MAN_SUFFIX=	${PKGBASE}

MAKE_ENV=	SHORT_TCL_VER="${SHORT_TCL_VER}" \
		MAN_SUFFIX=.${MAN_SUFFIX}

PLIST_SUB=	TCL_VER=${TCL_VER} \
		SHORT_TCL_VER=${SHORT_TCL_VER}

TCLMAN_INSTALL_TARGET=	install-doc
TCLMAN_PLIST_SUB=	MAN=""
TCLMAN_PLIST_SUB_OFF=	MAN="@comment "
THREADS_CONFIGURE_ON=	--enable-threads
THREADS_CONFIGURE_OFF=	--disable-threads

post-patch:
	${REINPLACE_CMD} -e \
	    's|@TCL_BUILD_LIB_SPEC@|@TCL_LIB_SPEC@|; \
	     s|@TCL_BUILD_STUB_LIB_SPEC@|@TCL_STUB_LIB_SPEC@|; \
	     s|@TCL_BUILD_STUB_LIB_PATH@|@TCL_STUB_LIB_PATH@|; \
	     s|@TCL_SRC_DIR@|${PREFIX}/include/tcl${TCL_VER}|' \
	     ${WRKSRC}/tclConfig.sh.in

post-configure:
	${REINPLACE_CMD} \
		-e 's,-DNO_MEMMOVE=1,,' -e 's,-DNO_STRING_H=1,,' \
		-e 's,^COMPAT_OBJS.*,,' ${WRKSRC}/Makefile

post-install:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/tclsh${TCL_VER}
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/libtcl${SHORT_TCL_VER}.so.1

.include <bsd.port.mk>
