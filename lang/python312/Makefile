# lang/python312 of azsupport/ports: Python 3.12, the PYTHON_DEFAULT of the ports
# tree, under the name of the official package (aZ, 11.11.2026: our Python under
# FreeBSD's names, so that the py312-* packages of the FreeBSD repository work with
# it; a change of PYTHON_DEFAULT opens an issue of tools/upstream-check.py of
# azsupport/php-src). The official port (its patches, Makefile.version, pkg-plist,
# pkg-descr, pkg-message) with:
# - the options of aZ: LTO, PYMALLOC and IPV6 on, LIBMPDEC (libmpdec of our
#   math/mpdecimal, the official port as it is), DEBUG off, no hash of the radio
#   (the SipHash13 of CPython), the defaults of the official port (IPV6 by the
#   framework); NLS off, as everywhere (aZ, 16.11.2026: the OPTIONS_UNSET of
#   tools/make.conf.in; the official package has it): the locale module without
#   bindtextdomain and gettext (the gettext module of Python reads .mo files
#   itself); no DTrace either way (CPython only with --with-dtrace);
# - libffi (_ctypes), expat (pyexpat) and readline (readline) of azsupport, and libintl
#   (the locale module of libpython) with NLS, with the run path /usr/local/azsupport/lib, instead
#   of devel/libffi, textproc/expat2, devel/readline and devel/gettext-runtime:
#   the package takes no package but azsupport and mpdecimal; OpenSSL (_ssl, _hashlib),
#   ncurses, zlib, bzip2 and liblzma of the base system, as the official one;
# - the build sees of /usr/local only azsupport (its include directory, libraries and .pc
#   files) and libmpdec (mpdecimal.h and libmpdec.so alone in a directory of the
#   work), not ${LOCALBASE}/include and ${LOCALBASE}/lib of USES=readline and NLS:
#   no other package of the build machine gets into a module;
# - after the install: libpython and the modules link the libraries of azsupport by their
#   run path, _decimal libmpdec, _ssl and _hashlib the OpenSSL of the base system;
# - the C compiled by GCC 16 of the ports instead of the base clang (USES=azgcc,
#   Mk/Uses/azgcc.mk; a build dependency only), aZ 17.11.2026 («а) Python, Redis и
#   xxhash в azsupport»): tools/prog-bench.sh measured Python 3.12.16 built with GCC 16
#   against the base clang 19 (pyperformance --fast, 25 benchmarks, prog-bench run
#   44043639827): faster in all of them, by 1.3% to 22.3%, the median 14.9%. After the
#   install sysconfig names the compilers of the base system (cc, c++ and cpp in its
#   _sysconfigdata and in the Makefile of config-3.12), so that an extension built
#   with this Python (pip, setuptools) takes the base clang, not GCC, which a server
#   has not.
# As in the official port: no _gdbm, _tkinter and _sqlite3 (aZ: gdbm and tkinter
# not needed; py312-sqlite3 is our databases/py-sqlite3, on the SQLite of azsupport). The
# flags of the build go into sysconfig as there: an extension built with this
# Python (pip) links with the -L and the run path of azsupport too.
# The version is that of the official port: Mk/Uses/python.mk reads its
# Makefile.version after the one here, which (with distinfo and pkg-plist) is of
# that version; the port says IGNORE when the official tree is at another one.

PORTNAME=	python
DISTVERSION=	${PYTHON_DISTVERSION}
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	lang python
MASTER_SITES=	PYTHON/ftp/python/${DISTVERSION:C/[a-z].*//}
PKGNAMESUFFIX=	${PYTHON_SUFFIX}
DISTNAME=	Python-${DISTVERSION}
DIST_SUBDIR=	python

PATCH_SITES=	https://github.com/python/cpython/commit/
PATCHFILES=	7f936694dbc0dc0dbb07d98fa668776c4e4ca595.patch:-p1 \
		43e495d6f4e0efe6e7a54625d559f2f656f36916.patch:-p1
# gh-115627 as RHEL 10 carries it for its Python 3.12 (00462; upstream in 3.13
# only, 12.11.2026): SSL_ERROR_SYSCALL after SSL_read_ex() and SSL_write_ex() was
# taken by their return value, so with OpenSSL 3.5 (that of the base system) a
# connection reset under load came as an EOF of the protocol, not as OSError (the
# HTTPS of yt-dlp goes through it); and gh-134100 as Gentoo carries it (the
# cherry-pick to 3.13 of 4e9005d): a use-after-free on an error path of a relative
# import; see the files
EXTRA_PATCHES=	${.CURDIR}/files/00462-fix-pyssl_seterror-handling-ssl_error_syscall.patch:-p1 \
		${.CURDIR}/files/gh-134100.patch:-p1

MAINTAINER=	github@azsupport.com
COMMENT=	Interpreted object-oriented programming language (of azsupport/ports)
WWW=		https://www.python.org/ \
		https://github.com/azsupport/ports

LICENSE=	PSFL

# the libraries of azsupport, to build and to run (no ldconfig hints for /usr/local/azsupport/lib:
# by a file); libintl with NLS
AZSUPPORT_PYTHON_LIBS=	libexpat.so libffi.so libreadline.so
BUILD_DEPENDS=	${AZSUPPORT_PYTHON_LIBS:@l@${AZSUPPORT_PREFIX}/lib/${l}:azsupport/azsupport@}
RUN_DEPENDS=	${AZSUPPORT_PYTHON_LIBS:@l@${AZSUPPORT_PREFIX}/lib/${l}:azsupport/azsupport@}

USES=		compiler:c11 cpe ncurses pathfix pkgconfig \
		python:${PYTHON_DISTVERSION:R},env shebangfix ssl tar:xz
# GCC of the ports for the C, at build time only (Mk/Uses/azgcc.mk)
USES+=		azgcc
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
# No -g with LTO: configure adds it when the compiler takes -g (ac_cv_prog_cc_g; bpo-30345)
# to the flags of the link and, for GCC (LTOCFLAGS is set for clang alone), of the
# compile too: libpython3.12.a came with debug information (debug-check, build run
# 44059209484); no debug in our builds (aZ, 17.11.2026)
CONFIGURE_ENV+=		ac_cv_prog_cc_g=no
# azsupport and the base system: the include directory and the libraries of azsupport (expat.h
# and -lexpat of --with-system-expat, libintl), with their run path; pkg-config
# (libffi, readline) sees the .pc files of azsupport and of the base system only
CONFIGURE_ENV+=		PKG_CONFIG_LIBDIR=${AZSUPPORT_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig
CPPFLAGS+=		-I${AZSUPPORT_PREFIX}/include
LDFLAGS+=		-L${AZSUPPORT_PREFIX}/lib -Wl,-rpath,${AZSUPPORT_PREFIX}/lib

INSTALL_TARGET=		altinstall					# Don't want cloberring of unprefixed files

TEST_TARGET=		buildbottest
TEST_ARGS=		TESTOPTS=-j${MAKE_JOBS_NUMBER}

MAKE_ARGS+=		COMPILEALL_OPTS=-j${MAKE_JOBS_NUMBER} \
			INSTALL_SHARED="${INSTALL_LIB}"				# Strip shared library
# the strip of the binutils of the ports for the install -s of the make of CPython
# too: the STRIPBIN that Mk/Uses/azgcc.mk exports did not reach it, and the strip of
# the base system left libpython, python3.12 and lib-dynload without .comment
# (17.11.2026: run 44149788389; with this, run 44180456352: GCC 16 there); only
# here, not in Mk/Uses/azgcc.mk, whose change would build every port of PHP again
# for the same files
MAKE_ENV+=		STRIPBIN=${STRIP_CMD}

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
# libintl of azsupport (its include directory and -L: CPPFLAGS and LDFLAGS above)
NLS_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libintl.so:azsupport/azsupport
NLS_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libintl.so:azsupport/azsupport
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
AZSUPPORT_PYTHON_DISTVERSION!=	${SED} -n 's/^PYTHON_DISTVERSION=[[:space:]]*//p' ${.CURDIR}/Makefile.version
.if ${AZSUPPORT_PYTHON_DISTVERSION} != ${PYTHON_DISTVERSION}
IGNORE=		is Python ${AZSUPPORT_PYTHON_DISTVERSION} (Makefile.version, distinfo, pkg-plist), the official port ${PYTHON_DISTVERSION}: bring it to that version
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
# the compilers of the build in sysconfig (GCC of USES=azgcc, its CC with -static-libgcc):
# those of the base system instead, which an extension built on a server takes (pip,
# setuptools); the bytecode of _sysconfigdata again
.if ${AZSUPPORT_GCC} != no
	@${SED} -i '' -e 's|gcc${AZSUPPORT_GCC} -static-libgcc|cc|g' -e 's|g++${AZSUPPORT_GCC}|c++|g' -e 's|cpp${AZSUPPORT_GCC}|cpp|g' \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/_sysconfigdata_${ABIFLAGS}_freebsd${OSREL:R}_.py \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/config-${PYTHON_VER}${ABIFLAGS}/Makefile
	@if ${GREP} -E -n 'gcc${AZSUPPORT_GCC}|g\+\+${AZSUPPORT_GCC}|cpp${AZSUPPORT_GCC}' \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/_sysconfigdata_${ABIFLAGS}_freebsd${OSREL:R}_.py \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/config-${PYTHON_VER}${ABIFLAGS}/Makefile; then \
		${ECHO_MSG} "sysconfig still names GCC (above)"; ${FALSE}; fi
	@cd ${WRKSRC} && ${SETENV} LD_LIBRARY_PATH=${WRKSRC} \
		./python -E -m compileall -q -f -o 0 -o 1 -o 2 -d ${PREFIX}/lib/python${PYTHON_VER} \
		${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/_sysconfigdata_${ABIFLAGS}_freebsd${OSREL:R}_.py
.endif
	for i in ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/*.so; do \
		${STRIP_CMD} $$i; done								# Strip shared extensions
.if ${AZSUPPORT_GCC} != no
# GCC 16 in the section .comment of libpython and python3.12, as python-test.sh of
# azsupport/azsupport checks it: the strip of the base system removes the section,
# that of the binutils of the ports keeps it (17.11.2026: the package of run
# 44149788389 had no .comment at all); the files of the build next to the staged
# ones, and the strip the environment named, when it is not there
	@for f in ${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 \
		${STAGEDIR}${PREFIX}/bin/python${PYTHON_VER}${ABIFLAGS}; do \
		if ! ${READELF:Ureadelf} -p .comment $$f 2>/dev/null | ${GREP} -q 'GCC: '; then \
			${ECHO_MSG} "$$f: no GCC in its .comment (STRIPBIN=$${STRIPBIN:-unset}, STRIP_CMD=${STRIP_CMD})"; \
			${ECHO_MSG} "the build: $$(${READELF:Ureadelf} -p .comment ${WRKSRC}/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 2>&1 | ${GREP} -c 'GCC: ') GCC line(s) in .comment of libpython of ${WRKSRC}"; \
			${FALSE}; \
		fi; \
	done
.endif
	${INSTALL_DATA} ${WRKSRC}/Tools/gdb/libpython.py \
		${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0-gdb.py
# the libraries of azsupport by the run path of libpython and of the modules, libmpdec of
# math/mpdecimal, the OpenSSL of the base system
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 | \
		${GREP} -E -q '(RUNPATH|RPATH).*${AZSUPPORT_PREFIX}/lib' || \
		{ ${ECHO_MSG} "libpython${PYTHON_VER}${ABIFLAGS}.so.1.0 has no run path ${AZSUPPORT_PREFIX}/lib"; ${FALSE}; }
.for m l in _ctypes libffi pyexpat libexpat readline libreadline _ssl libssl _hashlib libcrypto
	@f="$$(${LS} ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/${m}.cpython-*.so)" && \
		${READELF} -d "$$f" | ${GREP} -q 'Shared library: \[${l}\.so' || \
		{ ${ECHO_MSG} "lib-dynload/${m}: does not link ${l}"; ${FALSE}; }
.endfor
.for m in _ctypes pyexpat readline
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/python${PYTHON_VER}/lib-dynload/${m}.cpython-*.so | \
		${GREP} -E -q '(RUNPATH|RPATH).*${AZSUPPORT_PREFIX}/lib' || \
		{ ${ECHO_MSG} "lib-dynload/${m}: no run path ${AZSUPPORT_PREFIX}/lib"; ${FALSE}; }
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
