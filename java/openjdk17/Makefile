# java/openjdk17 of azsupport/ports: OpenJDK 17 headless (aZ, 11.11.2026: the
# JDK of textproc/elasticsearch6, so that a server with Elasticsearch gets nothing
# of a desktop: the official package pulls about 50 packages of one, X11, fonts,
# ALSA, HarfBuzz with GLib and Python, giflib, PNG, javavmwrapper). The package
# name, version and directory (/usr/local/openjdk17) of the official port. Taken
# from the official port of the pinned tree as they are, so that a new version of
# it comes by the pin by itself: its version (the variables of AZ_OFFICIAL_VARS,
# read in its Makefile), its distinfo (the source of battleblow/jdk17u and the
# bootstrap JDK of LOCAL/openjdk) and its patches but two (AZ_PATCHES_OUT). The
# rest is its Makefile with these changes:
# - --enable-headless-only: no X11 (make/autoconf/libraries.m4: NEEDS_LIB_X11
#   false), libawt_headless and no libawt_xawt; no libsplashscreen, the only user
#   of giflib and libpng (make/modules/java.desktop/lib/Awt2dLibraries.gmk), so
#   these two are bundled and unused;
# - no sound: FreeBSD without ALSA and libjsound, as AIX and OpenBSD
#   (files/patch-make_autoconf_libraries.m4-alsa,
#   files/patch-make_modules_java.desktop_Lib.gmk); javax.sound finds no native
#   library (com.sun.media.sound.Platform: no devices, no message);
# - libjpeg (mozjpeg), FreeType and Little CMS of az, by their .pc files with the
#   run path /usr/local/az/lib, which lands after the $ORIGIN of the JDK in the
#   three libraries that link them (libjavajpeg, libfontmanager, liblcms) and in
#   no other file; zlib of the base system; HarfBuzz bundled (no port of ours has
#   it);
# - fontconfig: its headers (those of az) to build, as libraries.m4 wants them
#   headless too; not linked: the two patches of the official port that link
#   libfontmanager with it (the hinting of FreeType from the settings of
#   fontconfig) are left out. OpenJDK loads libfontconfig.so.1 with dlopen(3) by
#   its name when it needs the fonts of the system; the rtld of FreeBSD looks for
#   it in LD_LIBRARY_PATH, the run path of bin/java (the lib of the JDK), the
#   ldconfig hints and /lib and /usr/lib, not in /usr/local/az/lib (no hints, and
#   the run path of the library that calls dlopen does not count). So with our
#   packages only Java has no fontconfig and no fonts of the system (text with the
#   logical fonts fails: tools/java-test.sh says how; Elasticsearch needs none);
#   with the official fontconfig and fonts installed it takes those;
# - no fonts (xorg-fonts-truetype) and no javavmwrapper (no @javavm: no
#   /usr/local/bin/java; Elasticsearch takes JAVA_HOME); CUPS: its headers to
#   build, as the official port, nothing at run time (libawt loads libcups with
#   dlopen to print);
# - without DTrace (aZ: every build here; configure enables it when it finds
#   dtrace(1));
# - checked after configure (headless, no ALSA and X11, the libraries of az with
#   their run path, no DTrace) and after the install: no ELF links a library of
#   X11, ALSA, giflib, libpng, HarfBuzz or fontconfig; libjpeg, libfreetype and
#   liblcms2 are those of az by the run path; no libjsound, libawt_xawt and
#   libsplashscreen, libawt_headless there; the package needs az only.
# The flags of make.conf are not those of the JDK (its configure ignores CFLAGS,
# the official port gives none): its own, and its JIT compiles for the CPU it runs
# on.

PORTNAME=	openjdk
DISTVERSIONPREFIX=	jdk-
DISTVERSION=	${JDK_MAJOR_VERSION}.${JDK_MINOR_VERSION}.${JDK_PATCH_VERSION}+${JDK_BUILD_NUMBER}-${BSD_JDK_VERSION}
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	java devel
PKGNAMESUFFIX?=	${JDK_MAJOR_VERSION}
MASTER_SITES=	LOCAL/openjdk/:boot
DISTFILES=	${BOOTSTRAPJDKFILE}:boot

MAINTAINER=	github@azsupport.com
COMMENT=	Java Development Kit ${JDK_MAJOR_VERSION}, headless (of azsupport/ports)
WWW=		https://openjdk.java.net/projects/jdk/17/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv2

ONLY_FOR_ARCHS=	aarch64 amd64 i386 powerpc64 powerpc64le

# the official port of the pinned tree: its version (these variables of its
# Makefile), distinfo and patches
AZ_OFFICIAL_PORT=	${PORTSDIR:U/usr/ports}/java/openjdk17
AZ_OFFICIAL_VARS=	JDK_MAJOR_VERSION JDK_MINOR_VERSION JDK_PATCH_VERSION \
			JDK_BUILD_NUMBER BSD_JDK_VERSION BOOTSTRAPJDKFILE
.for v in ${AZ_OFFICIAL_VARS}
${v}!=		/usr/bin/sed -n -E 's/^${v}=[[:space:]]*//p' ${AZ_OFFICIAL_PORT}/Makefile 2> /dev/null || :
.  if empty(${v})
IGNORE=		has no ${v} of the official port (${AZ_OFFICIAL_PORT}/Makefile)
.  endif
.endfor
DISTINFO_FILE=	${AZ_OFFICIAL_PORT}/distinfo
# its patches but the two of fontconfig, each with the SHA-256 of the one left out
# (a change of either stops the build in pre-patch, to be looked at), before those
# of files/
AZ_PATCHES_OUT=	patch-make_modules_java.desktop_lib_Awt2dLibraries.gmk:f8bc51df06ee2e9be5200cf38030c9d07b8cb0b753d0e3e807e8f3311ace8c35 \
		patch-src_java.desktop_share_native_libfontmanager_freetypeScaler.c:1c1b147a01cba4d71669ca8cd0b8e748e24acc1e28e1e9fdb421069847af24ba
_AZ_OFFICIAL_PATCHES!=	cd ${AZ_OFFICIAL_PORT}/files 2> /dev/null && ls patch-* 2> /dev/null || :
.for p in ${AZ_PATCHES_OUT:C/:.*//}
_AZ_OFFICIAL_PATCHES:=	${_AZ_OFFICIAL_PATCHES:N${p}}
.endfor
.if empty(_AZ_OFFICIAL_PATCHES)
IGNORE=		has no patches of the official port (${AZ_OFFICIAL_PORT}/files)
.endif
EXTRA_PATCHES=	${_AZ_OFFICIAL_PATCHES:S|^|${AZ_OFFICIAL_PORT}/files/|}

# the libraries of az the JDK links, to build and to run (by a file: no ldconfig
# hints for /usr/local/az/lib), and fontconfig of az for its headers
AZ_JDK_LIBS=	libfreetype.so libjpeg.so liblcms2.so
BUILD_DEPENDS=	zip:archivers/zip \
		autoconf>0:devel/autoconf \
		${LOCALBASE}/include/cups/cups.h:print/cups \
		bash:shells/bash \
		gsed:textproc/gsed \
		${AZ_JDK_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@} \
		${AZ_PREFIX}/lib/libfontconfig.so:az/az
RUN_DEPENDS=	${AZ_JDK_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}

USES=		compiler:features cpe gmake iconv pkgconfig

CPE_VENDOR=	oracle

USE_GITHUB=	yes
GH_ACCOUNT=	battleblow
GH_PROJECT=	jdk17u

NO_CCACHE=	yes

# Suppress passing -j to do-build target via Mk/bsd.port.mk
# In the JDK build the number of parallel jobs is passed in via configure --with-num-cores=N
_MAKE_JOBS=
MAKE_ENV=	CLASSPATH="" \
		JAVA_HOME="" \
		LD_LIBRARY_PATH="" \
		CC=${CC} \
		CXX=${CXX} \
		CPP=${CPP} \
		LOG=cmdlines \
		MAKEFLAGS="CONF_CHECK=ignore"

JDK_ARCH=	${ARCH:S/amd64/x86_64/:S/i386/x86/:S/powerpc64/ppc64/}
JDK_OSARCH=	bsd-${JDK_ARCH}
JDK_BUILDDIR=	${WRKSRC}/build/${JDK_OSARCH}-${JDK_BUILD_JVM}-${JDK_BUILD_TYPE}
.if defined(BUILD_JRE)
JDK_IMAGEDIR=	${JDK_BUILDDIR}/images/jre
.else
JDK_IMAGEDIR=	${JDK_BUILDDIR}/images/jdk
.endif
INSTALLDIR=	${PREFIX}/${PKGBASE}
BOOTSTRAPJDKDIR=	${WRKDIR}/boot-jdk

NOPRECIOUSMAKEVARS=	yes

JDK_BUG_URL=	https://bugs.freebsd.org/bugzilla/enter_bug.cgi?product=Ports%20%26%20Packages&component=Individual%20Port(s)&short_desc=java/${PORTNAME}${JDK_MAJOR_VERSION}%3A%20

# pkg-config: the .pc files of az of the three libraries with the run path of az
# (pre-configure), then those of az and of the base system
GNU_CONFIGURE=	yes
CONFIGURE_ENV=	CC=${CC} \
		CXX=${CXX} \
		CPP=${CPP} \
		PKG_CONFIG_LIBDIR=${WRKDIR}/az-pc:${AZ_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig \
		ac_cv_path_SED=${LOCALBASE}/bin/gsed
CONFIGURE_ARGS=	--with-boot-jdk=${BOOTSTRAPJDKDIR} \
		--disable-ccache \
		--disable-dtrace \
		--disable-javac-server \
		--disable-hotspot-gtest \
		--enable-headless-only \
		--with-cups=${LOCALBASE} \
		--with-fontconfig=${AZ_PREFIX} \
		--with-freetype=system \
		--with-libjpeg=system \
		--with-giflib=bundled \
		--with-harfbuzz=bundled \
		--with-libpng=bundled \
		--with-num-cores=${MAKE_JOBS_NUMBER} \
		--with-zlib=system \
		--with-lcms=system \
		--with-version-string=${JDK_MAJOR_VERSION}.${JDK_MINOR_VERSION}.${JDK_PATCH_VERSION}+${JDK_BUILD_NUMBER}-${BSD_JDK_VERSION} \
		--with-native-debug-symbols=none \
		--with-debug-level=release \
		--with-vendor-name="OpenJDK BSD Porting Team" \
		--with-vendor-url="https://github.com/${GH_ACCOUNT}/${GH_PROJECT}/" \
		--with-vendor-bug-url="${JDK_BUG_URL}" \
		--with-vendor-vm-bug-url="${JDK_BUG_URL}"
# the .pc files of az whose Libs get the run path of az
AZ_JDK_PC=	freetype2 lcms2 libjpeg

.if defined(BUILD_JRE)
ALL_TARGET=		legacy-images
.else
ALL_TARGET=		images
.endif
JDK_BUILD_TYPE=		release

.include <bsd.port.pre.mk>

# portsfallout.com shows flapping builds on 14.2
.if ${OPSYS} == FreeBSD && ${OSVERSION} < 1500000
MAKE_JOBS_NUMBER_LIMIT=	3
.endif

JDK_BUILD_JVM=	server

MAKE_ENV+=		--with-toolchain-type=${COMPILER_TYPE}
CONFIGURE_ARGS+=	--with-toolchain-type=${COMPILER_TYPE}
CONFIGURE_ARGS+=	--disable-warnings-as-errors

.if ${COMPILER_TYPE} == gcc
USE_GCC=	yes
CONFIGURE_ARGS+=	--with-extra-ldflags="-Wl,-rpath=${LOCALBASE}/lib/gcc${GCC_DEFAULT} -L${LOCALBASE}/lib/gcc${GCC_DEFAULT}" \
			--with-extra-cflags="-Wl,-rpath=${LOCALBASE}/lib/gcc${GCC_DEFAULT}" \
			--with-extra-cxxflags="-Wl,-rpath=${LOCALBASE}/lib/gcc${GCC_DEFAULT}"
.else
MAKE_ENV+=	USE_CLANG=true
.endif

.if ${ARCH} == aarch64
CONFIGURE_ARGS+=	--with-boot-jdk-jvmargs=-XX:-UseCompressedClassPointers
MAKE_ENV+=		JAVA_TOOL_OPTIONS="-XX:-UseCompressedClassPointers"
.endif

.if empty(ICONV_LIB)
ICONV_CFLAGS=	-DLIBICONV_PLUG
.else
ICONV_CFLAGS=	-I${LOCALBASE}/include
ICONV_LDFLAGS=	-L${LOCALBASE}/lib
ICONV_LIBS=	${ICONV_LIB}
.endif

# the patches of the official port left out are those of AZ_PATCHES_OUT
pre-patch:
.for p in ${AZ_PATCHES_OUT}
	@[ "$$(${SHA256} -q ${AZ_OFFICIAL_PORT}/files/${p:C/:.*//} 2> /dev/null)" = "${p:C/^[^:]*://}" ] || \
		{ ${ECHO_MSG} "${AZ_OFFICIAL_PORT}/files/${p:C/:.*//}: changed or gone (not the patch this port leaves out, SHA-256 ${p:C/^[^:]*://}): look at it and at AZ_PATCHES_OUT"; ${FALSE}; }
.endfor

pre-configure:
	@${FIND} ${WRKSRC} -name '*.orig' -delete
	@${CHMOD} 755 ${WRKSRC}/configure
	@${REINPLACE_CMD} -e 's|%%LOCALBASE%%|${LOCALBASE}|' \
		${WRKSRC}/configure \
		${WRKSRC}/src/hotspot/os/bsd/os_bsd.cpp
	@${REINPLACE_CMD} -e 's|%%ICONV_CFLAGS%%|${ICONV_CFLAGS}|' \
		-e 's|%%ICONV_LDFLAGS%%|${ICONV_LDFLAGS}|' \
		-e 's|%%ICONV_LIBS%%|${ICONV_LIBS}|' \
		${WRKSRC}/make/autoconf/libraries.m4
	@${MKDIR} ${WRKDIR}/az-pc
.for p in ${AZ_JDK_PC}
	@${SED} -e 's|^Libs:|Libs: -Wl,-rpath,${AZ_PREFIX}/lib|' ${AZ_PREFIX}/lib/pkgconfig/${p}.pc > ${WRKDIR}/az-pc/${p}.pc
	@${GREP} -q '^Libs: -Wl,-rpath,${AZ_PREFIX}/lib .*-L' ${WRKDIR}/az-pc/${p}.pc || \
		{ ${ECHO_MSG} "${AZ_PREFIX}/lib/pkgconfig/${p}.pc: no Libs with -L"; ${FALSE}; }
.endfor

# what configure found: headless, no ALSA and X11, zlib of the base system, the
# libraries of az by pkg-config with their run path, the bundled ones, no DTrace
AZ_JDK_SPEC=	ENABLE_HEADLESS_ONLY=true ALSA_LIBS= X_LIBS= USE_EXTERNAL_LIBZ=true \
		USE_EXTERNAL_LIBJPEG=true USE_EXTERNAL_LCMS=true FREETYPE_TO_USE=system \
		USE_EXTERNAL_HARFBUZZ=false USE_EXTERNAL_LIBGIF=false USE_EXTERNAL_LIBPNG=false
post-configure:
	@s=${JDK_BUILDDIR}/spec.gmk; for e in ${AZ_JDK_SPEC}; do \
		n="$${e%%=*}"; w="$${e#*=}"; \
		g="$$(${SED} -n -E "s/^$$n[[:space:]]*:=[[:space:]]*//p" $$s | ${SED} -E 's/[[:space:]]+$$//')"; \
		[ "$$g" = "$$w" ] || { ${ECHO_MSG} "spec.gmk: $$n is '$$g', not '$$w'"; exit 1; }; \
	done; \
	for n in FREETYPE_LIBS JPEG_LIBS LCMS_LIBS; do \
		g=" $$(${SED} -n -E "s/^$$n[[:space:]]*:=//p" $$s) "; \
		case "$$g" in *" -Wl,-rpath,${AZ_PREFIX}/lib "*) ;; *) g="" ;; esac; \
		case "$$g" in *" -L${AZ_PREFIX}/lib "*) ;; *) g="" ;; esac; \
		[ -n "$$g" ] || { ${ECHO_MSG} "spec.gmk: $$n is not the library of az with its run path: $$(${GREP} "^$$n" $$s)"; exit 1; }; \
	done; \
	if ${GREP} -E '^JVM_FEATURES_server[[:space:]]*:=' $$s | ${GREP} -q -w dtrace; then \
		${ECHO_MSG} "spec.gmk: DTrace among the features of the JVM: $$(${GREP} '^JVM_FEATURES_server' $$s)"; exit 1; \
	fi

post-build:
.if defined(OPENJDK_SYMLINK_CACERTS)
	@${RM} ${JDK_IMAGEDIR}/lib/security/cacerts
	@${LN} -sf ${OPENJDK_SYMLINK_CACERTS} ${JDK_IMAGEDIR}/lib/security/cacerts
.endif

# as the official port without its line "@javavm ${INSTALLDIR}/bin/java" (no
# javavmwrapper)
do-install:
	@${MKDIR} ${STAGEDIR}${INSTALLDIR}
	@cd ${JDK_IMAGEDIR} && ${COPYTREE_SHARE} . ${STAGEDIR}${INSTALLDIR}
	@cd ${STAGEDIR}${INSTALLDIR} && \
		${FIND} bin -type f -exec ${CHMOD} ${BINMODE} {} \;
	@${CHMOD} ${BINMODE} ${STAGEDIR}${INSTALLDIR}/lib/jspawnhelper
	@${FIND} ${STAGEDIR}${INSTALLDIR} -not -type d | ${SORT} | \
		${SED} -e 's|^${STAGEDIR}${PREFIX}/||' >> ${TMPPLIST}

# the libraries a desktop needs (NEEDED of an ELF), and the JDK libraries that
# link those of az: library:the library of az
AZ_JDK_NOT_NEEDED=	lib(X[A-Za-z0-9_-]*|xcb[A-Za-z0-9_-]*|asound|gif|png[0-9]*|harfbuzz[A-Za-z0-9_-]*|fontconfig)\.so
AZ_JDK_AZ_LINKS=	libfontmanager.so:libfreetype libjavajpeg.so:libjpeg liblcms.so:liblcms2
post-install:
	@[ -z "${LIB_DEPENDS}${RUN_DEPENDS:N*\:az/az}" ] || \
		{ ${ECHO_MSG} "the package needs more than az: ${LIB_DEPENDS} ${RUN_DEPENDS:N*\:az/az}"; ${FALSE}; }
	@cd ${STAGEDIR}${INSTALLDIR} && n=0 && for f in $$(${FIND} . -type f | ${SORT}); do \
		${FILE} -b "$$f" | ${GREP} -q '^ELF ' || continue; \
		n=$$((n + 1)); \
		b="$$(${READELF} -d "$$f" | ${SED} -n 's/.*Shared library: \[\(.*\)\].*/\1/p' | ${GREP} -E -x '${AZ_JDK_NOT_NEEDED}[.0-9]*' | ${TR} '\n' ' ')"; \
		[ -z "$$b" ] || { ${ECHO_MSG} "$${f#./} links $$b"; exit 1; }; \
	done && [ "$$n" -gt 50 ] || { ${ECHO_MSG} "the ELF files of the JDK: $$n, not more than 50"; exit 1; }
	@cd ${STAGEDIR}${INSTALLDIR}/lib && for e in ${AZ_JDK_AZ_LINKS}; do \
		f="$${e%%:*}"; l="$${e#*:}"; \
		so="$$(${READELF} -d $$f | ${SED} -n "s/.*Shared library: \[\($$l\.so\.[0-9.]*\)\].*/\1/p")"; \
		rp="$$(${READELF} -d $$f | ${SED} -n 's/.*Library runpath: \[\(.*\)\].*/\1/p')"; \
		[ -n "$$so" ] || { ${ECHO_MSG} "lib/$$f does not link $$l"; exit 1; }; \
		[ -f ${AZ_PREFIX}/lib/$$so ] && [ ! -e "$$so" ] || \
			{ ${ECHO_MSG} "lib/$$f: $$so is not ${AZ_PREFIX}/lib/$$so alone"; exit 1; }; \
		case "$$rp" in '$$ORIGIN:'*'${AZ_PREFIX}/lib'*) ;; \
		*) ${ECHO_MSG} "lib/$$f: the run path is '$$rp', not \$$ORIGIN, then ${AZ_PREFIX}/lib"; exit 1 ;; esac; \
	done
	@cd ${STAGEDIR}${INSTALLDIR}/lib && for f in libjsound.so libawt_xawt.so libsplashscreen.so; do \
		[ ! -e $$f ] || { ${ECHO_MSG} "lib/$$f is there: not a JDK without sound and X11"; exit 1; }; \
	done && [ -f libawt_headless.so ] || { ${ECHO_MSG} "no lib/libawt_headless.so"; exit 1; }

.include <bsd.port.post.mk>
