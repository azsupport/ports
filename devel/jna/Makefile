# devel/jna of azsupport/ports: JNA without X11 (aZ, 11.11.2026: the JNA of
# textproc/elasticsearch6, so that a server with Elasticsearch gets nothing of a
# desktop). The official port declares libX11 and libXt (USE_XORG makes them run
# dependencies too), although its libjnidispatch.so links neither (JNA loads JAWT
# at run time; only jawt_md.h needs the headers of X11 and Xt), and it builds the
# libffi it bundles, static. The package name, version and files of the official
# port; taken from the official port of the pinned tree as they are: its version
# (PORTVERSION and GH_TAGNAME, read in its Makefile), distinfo, pkg-descr and
# patches, then files/patch-native_Makefile-freebsd. The changes:
# - without JAWT on FreeBSD (-DNO_JAWT in native/Makefile, as JNA builds for
#   Android and macOS: Native.getWindowHandle0 gives 0), without the include
#   directories of X11 there: nothing of X11;
# - the libffi of az, shared (DYNAMIC_LIBFFI: the property dynlink.native of
#   build.xml), with the pkg-config of az and its directory as the run path, not
#   the static copy JNA bundles (so no texinfo, autoreconf and libtool);
# - built with our java/openjdk17 (JAVA_VERSION 17) and the Ant of our
#   devel/apache-ant, which runs on it: one JDK in the build;
# - the CFLAGS of make.conf (-march of the level, -fstack-protector-strong) for
#   its C code, before the -O2 of JNA (cflags_extra.native of build.xml);
# - checked after the install: the libjnidispatch.so of jna.jar and that of
#   jna-platform.jar (the official port installs build/freebsd-x86-64.jar, the jar
#   of the native library, under this name) are the one built here, which links
#   the libffi of az by its run path and nothing of X11; the package needs az
#   only.

PORTNAME=	jna
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	devel java

MAINTAINER=	github@azsupport.com
COMMENT=	Java access to native shared libraries (of azsupport/ports)
WWW=		https://github.com/java-native-access/jna \
		https://github.com/azsupport/ports

LICENSE=	APACHE20 LGPL21+
LICENSE_COMB=	dual
LICENSE_FILE_APACHE20=	${WRKSRC}/AL2.0
LICENSE_FILE_LGPL21+ =	${WRKSRC}/LGPL2.1
LICENSE_FILE=	${WRKSRC}/LICENSE

# the official port of the pinned tree: its version (these variables of its
# Makefile), distinfo, pkg-descr and patches (before those of files/)
AZ_OFFICIAL_PORT=	${PORTSDIR:U/usr/ports}/devel/jna
AZ_OFFICIAL_VARS=	PORTVERSION GH_TAGNAME
.for v in ${AZ_OFFICIAL_VARS}
${v}!=		/usr/bin/sed -n -E 's/^${v}=[[:space:]]*//p' ${AZ_OFFICIAL_PORT}/Makefile 2> /dev/null || :
.  if empty(${v})
IGNORE=		has no ${v} of the official port (${AZ_OFFICIAL_PORT}/Makefile)
.  endif
.endfor
DISTINFO_FILE=	${AZ_OFFICIAL_PORT}/distinfo
DESCR=		${AZ_OFFICIAL_PORT}/pkg-descr
_AZ_OFFICIAL_PATCHES!=	cd ${AZ_OFFICIAL_PORT}/files 2> /dev/null && ls patch-* 2> /dev/null || :
.if empty(_AZ_OFFICIAL_PATCHES)
IGNORE=		has no patches of the official port (${AZ_OFFICIAL_PORT}/files)
.endif
EXTRA_PATCHES=	${_AZ_OFFICIAL_PATCHES:S|^|${AZ_OFFICIAL_PORT}/files/|}

# the libffi of az, to build and to run (by a file: no ldconfig hints for
# /usr/local/az/lib)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libffi.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libffi.so:az/az

USES=		gmake java:ant pkgconfig
USE_GITHUB=	yes
GH_ACCOUNT=	java-native-access
JAVA_VERSION=	17
MAKE_ARGS=	-DCC="${CC}" \
		-DLD="${LD}" \
		-Ddynlink.native=true \
		-Dcflags_extra.native="${CFLAGS}"
MAKE_ENV=	ANT_OPTS="-Drelease -DARCH=${ANT_ARCH}" \
		JAVACMD=${JAVA} \
		PKG_CONFIG_LIBDIR=${AZ_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig
ALL_TARGET=	native jar
TEST_TARGET=	test

PLIST_FILES=	${JAVAJARDIR}/jna-platform.jar \
		${JAVAJARDIR}/jna.jar
PORTDOCS=	javadoc platform-${PORTVERSION}-javadoc.jar

OPTIONS_DEFINE=	DOCS

ANT_ARCH=	${ARCH:S/amd64/x86-64/:S/armv6/arm/:S/armv7/arm/:S/i386/x86/:S/powerpc/ppc/}

post-patch:
	@${REINPLACE_CMD} -e 's|%%LOCALBASE%%|${LOCALBASE}|' \
		${WRKSRC}/native/Makefile

post-build-DOCS-on:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${ANT} javadoc

do-install:
	${INSTALL_DATA} ${WRKSRC}/build/freebsd-${ANT_ARCH}.jar \
		${STAGEDIR}${JAVAJARDIR}/jna-platform.jar
	${INSTALL_DATA} ${WRKSRC}/build/jna.jar \
		${STAGEDIR}${JAVAJARDIR}/jna.jar

do-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	@cd ${WRKSRC}/doc && ${COPYTREE_SHARE} javadoc ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/dist/platform-${PORTVERSION}-javadoc.jar \
		${STAGEDIR}${DOCSDIR}

# the libjnidispatch.so of the two jars: built here, the libffi of az by the run
# path, nothing of X11 (or of JAWT)
post-install:
	@[ -z "${LIB_DEPENDS}${RUN_DEPENDS:N*\:az/az}" ] || \
		{ ${ECHO_MSG} "the package needs more than az: ${LIB_DEPENDS} ${RUN_DEPENDS:N*\:az/az}"; ${FALSE}; }
	@d=${WRKDIR}/az-jars && ${RM} -r $$d && ${MKDIR} $$d/jna.jar $$d/jna-platform.jar && \
	${TAR} -xf ${STAGEDIR}${JAVAJARDIR}/jna.jar -C $$d/jna.jar com/sun/jna/freebsd-${ANT_ARCH}/libjnidispatch.so && \
	${TAR} -xf ${STAGEDIR}${JAVAJARDIR}/jna-platform.jar -C $$d/jna-platform.jar libjnidispatch.so || \
		{ ${ECHO_MSG} "no libjnidispatch.so of freebsd-${ANT_ARCH} in jna.jar and jna-platform.jar"; exit 1; }; \
	for f in $$d/jna.jar/com/sun/jna/freebsd-${ANT_ARCH}/libjnidispatch.so $$d/jna-platform.jar/libjnidispatch.so; do \
		j="$${f#$$d/}"; j="$${j%%/*}"; \
		cmp -s $$f ${WRKSRC}/build/native-freebsd-${ANT_ARCH}/libjnidispatch.so || \
			{ ${ECHO_MSG} "the libjnidispatch.so of $$j is not the one built here"; exit 1; }; \
		so="$$(${READELF} -d $$f | ${SED} -n 's/.*Shared library: \[\(libffi\.so\.[0-9.]*\)\].*/\1/p')"; \
		[ -n "$$so" ] && [ -f ${AZ_PREFIX}/lib/$$so ] || \
			{ ${ECHO_MSG} "the libjnidispatch.so of $$j does not link the libffi of ${AZ_PREFIX}/lib: $${so:-none}"; exit 1; }; \
		rp="$$(${READELF} -d $$f | ${SED} -n 's/.*Library runpath: \[\(.*\)\].*/\1/p')"; \
		case ":$$rp:" in *:${AZ_PREFIX}/lib:*) ;; \
		*) ${ECHO_MSG} "the libjnidispatch.so of $$j: the run path is '$$rp', not ${AZ_PREFIX}/lib"; exit 1 ;; esac; \
		b="$$(${READELF} -d $$f | ${SED} -n 's/.*Shared library: \[\(.*\)\].*/\1/p' | ${GREP} -E '^lib(X|xcb|jawt)' | ${TR} '\n' ' ')"; \
		[ -z "$$b" ] || { ${ECHO_MSG} "the libjnidispatch.so of $$j links $$b"; exit 1; }; \
	done

.include <bsd.port.mk>
