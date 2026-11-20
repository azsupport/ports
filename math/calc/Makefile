# math/calc of azsupport/ports in the place of the official one (aZ, 20.11.2026): calc
# 2.17.0.2 of Landon Curt Noll, the arbitrary precision calculator, the official port of
# the pinned tree (its files/Makefile.freebsd, distinfo, pkg-plist) with the options FULL
# (libcalc and libcustcalc, the headers, the resource files and cscripts) and HELP (the
# help files of its help command), without the flavor tiny; its command line on the
# readline of az (/usr/local/az/lib, our ports link each other's shared libraries: aZ,
# 10.11.2026), not the package of devel/readline the official USES=readline takes.

PORTNAME=	calc
PORTVERSION=	2.17.0.2
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONPREFIX=	v
CATEGORIES=	math

MAINTAINER=	github@azsupport.com
COMMENT=	Interactive CLI arbitrary-precision calculator (of azsupport/ports)
WWW=		https://github.com/lcn2/calc \
		https://github.com/azsupport/ports

LICENSE=	LGPL21
LICENSE_FILE=	${WRKSRC}/COPYING-LGPL

# libreadline.so and libhistory.so of az
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libreadline.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libreadline.so:az/az

USES=		gmake tar:bzip2
USE_GITHUB=	yes
GH_ACCOUNT=	lcn2

MAKE_ARGS=	DATADIR="${DATADIR}"
MAKE_JOBS_UNSAFE=	yes
TEST_TARGET=	check

CONFLICTS_INSTALL=	calc-tiny schilyutils
PLIST_SUB+=	VERSION=${PORTVERSION} VERSION_R=${PORTVERSION:R}

OPTIONS_DEFINE=	FULL HELP
OPTIONS_DEFAULT=FULL HELP
OPTIONS_SUB=	yes
FULL_DESC=	Install all funcs/scripts/headers (OFF: just basic calculator)
HELP_DESC=	Install calc help files

# We use Makefile.freebsd because Makefile.local is in our .gitignore; its readline is
# that of az alone (links in ${WRKDIR}/az: not the include directory of az with its other
# headers, iconv.h of GNU libiconv), with its run path
post-extract:
	${SED} -e 's|%%CC%%|${CC}|; s|%%CFLAGS%%|${CFLAGS}|; s|%%SH%%|${SH}|' \
		-e 's|%%AZ%%|${WRKDIR}/az|g; s|%%AZ_PREFIX%%|${AZ_PREFIX}|g' \
		${FILESDIR}/Makefile.freebsd > ${WRKSRC}/Makefile.local
# The upstream Makefiles are a mess. Bash is hardcoded in many files, and only
# some of the Makefiles allow overrides. Plus, they error out if sed .bkp files exist.
	${FIND} ${WRKSRC} -name 'Makefile*' \
		| ${XARGS} ${REINPLACE_CMD} -i '' -E -e '/SHELL:?=/s|bash|${SH}|'
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib
	${LN} -sf ${AZ_PREFIX}/include/readline ${WRKDIR}/az/include/readline
	${LN} -sf ${AZ_PREFIX}/lib/libreadline.so ${AZ_PREFIX}/lib/libhistory.so \
		${WRKDIR}/az/lib/

# the programs and the libraries themselves stripped, not the links lib*.so (strip writes
# a stripped copy in the place of a link; no debug in our packages, aZ 17.11.2026)
post-install:
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}

.include <bsd.port.mk>
