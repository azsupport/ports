# lang/python312 of azsupport/ports: Python 3.12, the PYTHON_DEFAULT of the ports
# tree, under the name of the official package (aZ, 11.11.2026: our Python under
# FreeBSD's names, so that the py312-* packages of the FreeBSD repository work with
# it; a change of PYTHON_DEFAULT opens an issue of tools/upstream-check.py of
# azsupport/php-src). The official port (its patches, Makefile.version, pkg-plist,
# pkg-descr, pkg-message) with:
# - the options of aZ: LTO, PYMALLOC, IPV6 and NLS on, LIBMPDEC (libmpdec of our
#   math/mpdecimal, the official port as it is), DEBUG off, no hash of the radio
#   (the SipHash13 of CPython). These are the defaults of the official port too
#   (IPV6 and NLS by the framework), so the options of the two packages are the
#   same; no DTrace either way (CPython only with --with-dtrace);
# - libffi (_ctypes), expat (pyexpat), readline (readline) and libintl (the locale
#   module of libpython, NLS) of az, with the run path /usr/local/az/lib, instead
#   of devel/libffi, textproc/expat2, devel/readline and devel/gettext-runtime:
#   the package takes no package but az and mpdecimal; OpenSSL (_ssl, _hashlib),
#   ncurses, zlib, bzip2 and liblzma of the base system, as the official one;
# - the build sees of /usr/local only az (its include directory, libraries and .pc
#   files) and libmpdec (mpdecimal.h and libmpdec.so alone in a directory of the
#   work), not ${LOCALBASE}/include and ${LOCALBASE}/lib of USES=readline and NLS:
#   no other package of the build machine gets into a module;
# - after the install: libpython and the modules link the libraries of az by their
#   run path, _decimal libmpdec, _ssl and _hashlib the OpenSSL of the base system.
# As in the official port: no _gdbm, _tkinter and _sqlite3 (aZ: gdbm and tkinter
# not needed; py312-sqlite3 is our databases/py-sqlite3, on the SQLite of az). The
# flags of the build go into sysconfig as there: an extension built with this
# Python (pip) links with the -L and the run path of az too.
# The version is that of the official port: Mk/Uses/python.mk reads its
# Makefile.version after the one here, which (with distinfo and pkg-plist) is of
# that version; the port says IGNORE when the official tree is at another one.

PORTNAME=	python
DISTVERSION=	${PYTHON_DISTVERSION}
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	lang python
MASTER_SITES=	PYTHON/ftp/python/${DISTVERSION:C/[a-z].*//}
PKGNAMESUFFIX=	${PYTHON_SUFFIX}
DISTNAME=	Python-${DISTVERSION}
DIST_SUBDIR=	python

PATCH_SITES=	https://github.com/python/cpython/commit/
PATCHFILES=	7f936694dbc0dc0dbb07d98fa668776c4e4ca595.patch:-p1 \
		43e495d6f4e0efe6e7a54625d559f2f656f36916.patch:-p1

MAINTAINER=	github@azsupport.com
COMMENT=	Interpreted object-oriented programming language (of azsupport/ports)
WWW=		https://www.python.org/ \
		https://github.com/azsupport/ports

LICENSE=	PSFL

# the libraries of az, to build and to run (no ldconfig hints for /usr/local/az/lib:
# by a file); libintl with NLS
AZ_PYTHON_LIBS=	libexpat.so libffi.so libreadline.so
BUILD_DEPENDS=	${AZ_PYTHON_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}
RUN_DEPENDS=	${AZ_PYTHON_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}

USES=		compiler:c11 cpe ncurses pathfix pkgconfig \
		python:${PYTHON_DISTVERSION:R},env shebangfix ssl tar:xz
PATHFIX_MAKEFILEIN=	Makefile.pre.in
USE_LDCONFIG=	yes
GNU_CONFIGURE=	yes
python_CMD=	${PREFIX}/bin/python${PYTHON_DISTVERSION:R}
SHEBANG_FILES=	Lib/*.py Lib/*/*.py Lib/*/*/*.py Lib/*/*/*/*.py
SHEBANG_FILES+=	Lib/test/ziptestdata/exe_with_z64 \
		Lib/test/ziptestdata/exe_with_zip \
		Lib/test/ziptestdata/header.sh

DISABLED_EXTENSIONS=	_sqlite3 _tkinter _gdbm
CONFIGURE_ARGS+=	--enable-shared --without-ensurepip --with-system-expat
CONFIGURE_ENV+=		OPT="" # Null out OPT to respect user CFLAGS and remove optimizations
# az and the base system: the include directory and the libraries of az (expat.h
# and -lexpat of --with-system-expat, libintl), with their run path; pkg-config
# (libffi, readline) sees the .pc files of az and of the base system only
CONFIGURE_ENV+=		PKG_CONFIG_LIBDIR=${AZ_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig
CPPFLAGS+=		-I${AZ_PREFIX}/include
LDFLAGS+=		-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib

INSTALL_TARGET=		altinstall					# Don't want cloberring of unprefixed files

TEST_TARGET=		buildbottest
TEST_ARGS=		TESTOPTS=-j${MAKE_JOBS_NUMBER}

MAKE_ARGS+=		COMPILEALL_OPTS=-j${MAKE_JOBS_NUMBER} \
			INSTALL_SHARED="${INSTALL_LIB}"				# Strip shared library

SUB_FILES=		pkg-message
SUB_LIST=		PYTHON_SUFFIX=${PYTHON_SUFFIX}

PLIST_SUB=		ABI=${ABIFLAGS} \
			DISTVERSION=${DISTVERSION} \
			OSMAJOR=${OSVERSION:C/([0-9]*)[0-9]{5}/\1/}		# For plat-freebsd* in pkg-plist. https://bugs.python.org/issue19554

OPTIONS_DEFINE=		DEBUG IPV6 LIBMPDEC LTO NLS PYMALLOC
OPTIONS_DEFAULT=	LIBMPDEC LTO PYMALLOC
OPTIONS_EXCLUDE_riscv64=	LTO
OPTIONS_RADIO=		HASH
OPTIONS_RADIO_HASH=	FNV SIPHASH
OPTIONS_SUB=		yes

LIBMPDEC_DESC=		Use libmpdec from ports instead of bundled version
NLS_DESC=		Enable gettext support for the locale module
PYMALLOC_DESC=		Enable specialized mallocs

HASH_DESC=		Hash Algorithm (PEP-456)
FNV_DESC=		Modified Fowler-Noll-Vo Algorithm
SIPHASH_DESC=		SipHash24 Algorithm

FNV_CONFIGURE_ON=	--with-hash-algorithm=fnv
SIPHASH_CONFIGURE_ON=	--with-hash-algorithm=siphash24

DEBUG_CONFIGURE_WITH=	pydebug
IPV6_CONFIGURE_ENABLE=	ipv6

# libmpdec of math/mpdecimal: mpdecimal.h and libmpdec.so alone in a directory of
# the work (pre-configure), the flags of the module _decimal
LIBMPDEC_CONFIGURE_ON=	--with-system-libmpdec
LIBMPDEC_CONFIGURE_ENV=	LIBMPDEC_CFLAGS="-I${WRKDIR}/mpdec" \
			LIBMPDEC_LDFLAGS="-L${WRKDIR}/mpdec -lmpdec"
LIBMPDEC_LIB_DEPENDS=	libmpdec.so:math/mpdecimal

LTO_CONFIGURE_ON=	--with-lto

# Use CPPFLAGS over CFLAGS due to -I ordering, causing elementtree and pyexpat
# to break in Python 2.7, or preprocessor complaints in Python >= 3.3
# Upstream Issue: https://bugs.python.org/issue6299
# libintl of az (its include directory and -L: CPPFLAGS and LDFLAGS above)
NLS_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libintl.so:az/az
NLS_RUN_DEPENDS=	${AZ_PREFIX}/lib/libintl.so:az/az
NLS_LIBS=		-lintl
NLS_CONFIGURE_ENV_OFF=	ac_cv_lib_intl_textdomain=no ac_cv_header_libintl_h=no

PYMALLOC_CONFIGURE_WITH=	pymalloc

.include "${.CURDIR}/Makefile.version"
.include <bsd.port.options.mk>

.if ${PORT_OPTIONS:MDEBUG}
ABIFLAGS:=	d${ABIFLAGS}
.endif

.if !empty(ABIFLAGS)
PLIST_FILES+=	bin/python${PYTHON_VER}${ABIFLAGS} \
		bin/python${PYTHON_VER}${ABIFLAGS}-config \
		libdata/pkgconfig/python-${PYTHON_VER}${ABIFLAGS}.pc \
		libdata/pkgconfig/python-${PYTHON_VER}${ABIFLAGS}-embed.pc
.endif

# See https://bugs.freebsd.org/115940 and https://bugs.freebsd.org/193650
.if !exists(/usr/bin/ypcat) || defined(WITHOUT_NIS)
PLIST_SUB+=	NO_NIS="@comment "
DISABLED_EXTENSIONS+=	nis
.else
PLIST_SUB+=	NO_NIS=""
.endif

.if ${SSL_DEFAULT:Mlibressl*}
EXTRA_PATCHES+=	${PATCHDIR}/libressl
CONFIGURE_ENV+=	ac_cv_working_openssl_hashlib=yes
.endif

.include <bsd.port.pre.mk>

# the version of Makefile.version here (PYTHON_DISTVERSION is that of the official
# port by now) and of the official port
AZ_PYTHON_DISTVERSION!=	${SED} -n 's/^PYTHON_DISTVERSION=[[:space:]]*//p' ${.CURDIR}/Makefile.version
.if ${AZ_PYTHON_DISTVERSION} != ${PYTHON_DISTVERSION}
IGNORE=		is Python ${AZ_PYTHON_DISTVERSION} (Makefile.version, distinfo, pkg-plist), the official port ${PYTHON_DISTVERSION}: bring it to that version
.endif

# llvm17 with -flto=thin makes Programs/_freeze_module crash on armv7; workaround
# cf. https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=276249
.if ${ARCH} == armv7 && ${CHOSEN_COMPILER_TYPE} == clang && ${COMPILER_VERSION} >= 170 && \
	${COMPILER_VERSION} < 180
CONFIGURE_ARGS:=	${CONFIGURE_ARGS:N${LTO_CONFIGURE_ON}}
.endif

post-patch:
# disable the detection of includes and library from libuuid,
# which introduces hidden dependency and breaks build
	@${REINPLACE_CMD} -e 's|uuid/uuid.h|ignore_&|' ${WRKSRC}/configure

# disable detection of multiarch as it breaks with clang >= 13, which adds a
# major.minor version number in -print-multiarch output, confusing Python
	@${REINPLACE_CMD} -e 's|^\( *MULTIARCH=\).*--print-multiarch.*|\1|' ${WRKSRC}/configure
# Apply DISABLED_EXTENSIONS
	@${ECHO_CMD} '*disabled*' > ${WRKSRC}/Modules/Setup.local
.  for _module in ${DISABLED_EXTENSIONS}
		@${ECHO_CMD} ${_module} >> ${WRKSRC}/Modules/Setup.local
.  endfor

pre-configure-LIBMPDEC-on:
	@${MKDIR} ${WRKDIR}/mpdec
	@${LN} -sf ${LOCALBASE}/include/mpdecimal.h ${LOCALBASE}/lib/libmpdec.so ${WRKDIR}/mpdec/

post-install:
.if ! ${PORT_OPTIONS:MDEBUG}
	${RM} ${STAGEDIR}${PREFIX}/lib/libpython3.so						# Upstream Issue: https://bugs.python.org/issue17975
.endif
	${LN} -sf libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 ${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1
# This code block exists for the qemu-user enabled cross build environment.
# When using this environment in poudriere, CC is not set to the default
# of /usr/bin/cc and a cross-compile toolchain is used.  We need to hand
# edit this so that the run time configuration for python matches what the
# FreeBSD base system provides.  sbruno 02Aug2017
.if ${CC} == /nxb-bin/usr/bin/cc
	@${REINPLACE_CMD} -e 's=/nxb-bin==' \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/_sysconfigdata_${ABIFLAGS}_freebsd${OSREL:R}_.py
	@cd ${WRKSRC} && ${SETENV} LD_LIBRARY_PATH=${WRKSRC} \
		./python -E -m compileall -d ${PREFIX}/lib/python${PYTHON_VER} \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/_sysconfigdata_${ABIFLAGS}_freebsd${OSREL:R}_.py
	@cd ${WRKSRC} && ${SETENV} LD_LIBRARY_PATH=${WRKSRC} \
		./python -E -O -m compileall -d ${PREFIX}/lib/python${PYTHON_VER} \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/_sysconfigdata_${ABIFLAGS}_freebsd${OSREL:R}_.py
	@${REINPLACE_CMD} -e 's=/nxb-bin==' \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/config-${PYTHON_VER}${ABIFLAGS}/Makefile
.endif
	for i in ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/*.so; do \
		${STRIP_CMD} $$i; done								# Strip shared extensions
	${INSTALL_DATA} ${WRKSRC}/Tools/gdb/libpython.py \
		${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0-gdb.py
# the libraries of az by the run path of libpython and of the modules, libmpdec of
# math/mpdecimal, the OpenSSL of the base system
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 | \
		${GREP} -E -q '(RUNPATH|RPATH).*${AZ_PREFIX}/lib' || \
		{ ${ECHO_MSG} "libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 has no run path ${AZ_PREFIX}/lib"; ${FALSE}; }
.for m l in _ctypes libffi pyexpat libexpat readline libreadline _ssl libssl _hashlib libcrypto
	@f="$$(${LS} ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/${m}.cpython-*.so)" && \
		${READELF} -d "$$f" | ${GREP} -q 'Shared library: \[${l}\.so' || \
		{ ${ECHO_MSG} "lib-dynload/${m}: does not link ${l}"; ${FALSE}; }
.endfor
.for m in _ctypes pyexpat readline
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/${m}.cpython-*.so | \
		${GREP} -E -q '(RUNPATH|RPATH).*${AZ_PREFIX}/lib' || \
		{ ${ECHO_MSG} "lib-dynload/${m}: no run path ${AZ_PREFIX}/lib"; ${FALSE}; }
.endfor

post-install-LIBMPDEC-on:
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/_decimal.cpython-*.so | \
		${GREP} -q 'Shared library: \[libmpdec\.so' || \
		{ ${ECHO_MSG} "lib-dynload/_decimal: does not link libmpdec"; ${FALSE}; }

post-install-NLS-on:
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 | \
		${GREP} -q 'Shared library: \[libintl\.so' || \
		{ ${ECHO_MSG} "libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 does not link libintl"; ${FALSE}; }

.include <bsd.port.post.mk>
