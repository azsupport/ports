# x11-fonts/fontconfig of azsupport/ports: the official port (Mk/azsupport-official.mk),
# the shared fontconfig of the packages of this tree (aZ, 26.11.2026 13:42: «да»: a port
# with the official name and place, /usr/local, instead of a copy in the shared tree of
# azsupport), on the shared expat and freetype2 of azsupport (azsupport/expat and
# azsupport/freetype2, Mk/azsupport-libs.mk: their headers and .pc files, the run path
# /usr/local/azsupport/lib), not on textproc/expat2 and print/freetype2: its LIB_DEPENDS is
# emptied (a variable of the command line, which the LIB_DEPENDS= of the official
# Makefile does not replace; so is what an option adds there: NLS, below). The libraries
# of AZSUPPORT_LIBS are those of the needs
# line of fontconfig in azsupport/azsupport/files/deps.conf (tools/azsupport-lib-ports.sh
# --check compares them).
#
# fontconfig 2.18.4 (18.11.2026) ahead of the official port (2.18.3_1 at 0530184620), the
# release of the take line of fontconfig in deps.conf (an access out of bounds in
# FcCharSetMerge, oss-security 18.11.2026; the static fontconfig of azsupport/azsupport is
# the same release): the version as a variable of the command line (as sysutils/screen),
# the distinfo of this directory (the SHA-256 of the take line, which take-sources.yml
# run 45028759013 had from its address; the size of that file). The plist of the official
# port stays: the files of 2.18.4 are those of 2.18.3 (the PLIST of fonts/fontconfig of
# pkgsrc the same before and after its update to 2.18.4, 335caa86, 18.11.2026); the patch
# of the official port applies to it as to 2.18.3 (the static build takes it). Back to the
# official port as it is (with the libraries of azsupport) once it has 2.18.4 or later.
#
# Its manifest (AZSUPPORT_LIB): ${AZSUPPORT_PREFIX}/share/azsupport/interface/fontconfig.txt
# with the prefix line /usr/local (tools/azsupport-interface.sh make: its headers, shared
# library, archive and .pc file, the SHA-256 of its MESON_ARGS, the libraries it requires),
# so that the ports that link it take its interface into their hash, as for the ports of
# the libraries of azsupport (tools/build.sh).

AZSUPPORT_OFFICIAL=	x11-fonts/fontconfig
AZSUPPORT_LIB=		fontconfig
AZSUPPORT_LIBS=		expat:libexpat.so freetype2:libfreetype.so
DISTINFO_FILE=	${.CURDIR}/distinfo
.MAKEFLAGS:	DISTVERSION=2.18.4 LIB_DEPENDS=

# The options of the official port, as the builder has them (OPTIONS_UNSET of
# tools/make.conf.in): BITMAPS and HINTING_SLIGHT on (its defaults); DOCS, NLS, TEST,
# HINTING_NONE, HINTING_MEDIUM and HINTING_FULL off. Of them only NLS needs a library,
# libintl (USES=gettext-runtime: its LIB_DEPENDS, which is emptied here): with NLS on
# that of azsupport/gettext, its headers and .pc files linked as those of AZSUPPORT_LIBS
# (azsupport-libs-prepare); TEST needs bash only to test, DOCS nothing.
NLS_VARS=	AZSUPPORT_LIBS+=gettext:libintl.so
NLS_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libintl.so:azsupport/gettext
NLS_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libintl.so:azsupport/gettext

PLIST_FILES+=	${AZSUPPORT_PREFIX:S,^${PREFIX}/,,}/share/azsupport/interface/fontconfig.txt
_USES_stage+=	710:azsupport-fontconfig-manifest

.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

azsupport-fontconfig-manifest:
	@${MKDIR} ${STAGEDIR}${AZSUPPORT_PREFIX}/share/azsupport/interface
	@${SH} ${.CURDIR:H:H}/tools/azsupport-interface.sh make fontconfig ${DISTVERSION} ${STAGEDIR} ${PREFIX} \
		"${MESON_ARGS}" ${AZSUPPORT_LIBS:C/:.*//} > ${STAGEDIR}${AZSUPPORT_PREFIX}/share/azsupport/interface/fontconfig.txt

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
