# Settings of the overlay azsupport/ports for every port built with
# OVERLAYS=<this tree>: bsd.port.mk includes this file twice (once before and
# once after the port's own settings are processed), so it only adds to lists
# and assigns with ?=.
#
# AZSUPPORT_PREFIX: the shared tree of the package azsupport (origin azsupport/azsupport): lib/ (the
# shared libraries, SONAME and run path ${AZSUPPORT_PREFIX}/lib, no ldconfig hints),
# lib/pkgconfig/, include/, bin/pkg-config and bin/*-config. AZSUPPORT_STATIC: its
# static tree (lib/, include/, bin/pkg-config --static). Our ports use these
# two, never the literal path, and do not define them (aZ, 08.11.2026: the
# prefix is /usr/local/azsupport). Lazy assignments, so that a port may use them in its
# Makefile before this file is read (no := and no .if on them in a port).

# azsupport: the category of our own ports that have no place in the official tree
VALID_CATEGORIES+=	azsupport

AZSUPPORT_PREFIX?=	${LOCALBASE}/azsupport
AZSUPPORT_STATIC?=	${AZSUPPORT_PREFIX}/static

# AZSUPPORT_STAMP: the revision of our packages, the time of the build (yymmddhh),
# which the builder (tools/) passes, so that every build is an upgrade; 0
# without it. lang/php74 writes PORTREVISION= ${AZSUPPORT_STAMP:U0}: bsd.port.mk tests
# PORTREVISION before it reads this file.
AZSUPPORT_STAMP?=	0

# AZSUPPORT_HASH: the hash of the port (with its master, Mk/ and its dependencies)
# that the builder computes, kept in the package as the annotation azsupport_hash, so
# that the builder rebuilds a port only when its hash changes. Added once,
# although bsd.port.mk includes this file twice.
.if defined(AZSUPPORT_HASH) && !empty(AZSUPPORT_HASH) && empty(PKG_NOTES:Mazsupport_hash)
PKG_NOTES+=	azsupport_hash
PKG_NOTE_azsupport_hash=	${AZSUPPORT_HASH}
.endif

# The libraries of ${AZSUPPORT_PREFIX}/lib (azsupport, and the shared ones of ImageMagick7 and
# GraphicsMagick) count as libraries the packages provide: the framework gives
# pkg SHLIB_PROVIDE_PATHS_NATIVE from LIB_DIRS (and USE_LDCONFIG), only /lib,
# /usr/lib and ${LOCALBASE}/lib by default, so pkg 2 refused php74 ("Missing shlib
# libargon2.so.0", run 42514624927). No ldconfig hints for that directory (its
# libraries are found by their run path). Added once, although bsd.port.mk
# includes this file twice.
.if empty(LIB_DIRS:M${AZSUPPORT_PREFIX}/lib)
LIB_DIRS+=	${AZSUPPORT_PREFIX}/lib
.endif

# AZSUPPORT_OVERLAY: this tree (the directory above this Mk/), for the files of Mk/ the targets
# below use
AZSUPPORT_OVERLAY:=	${.PARSEDIR:H}

# The compiler of the ports (aZ, 26.11.2026 16:39: «что под гцц не собираем, то
# собираем цлангом, но не системным, а последним»): clang, clang++, clang-cpp and
# lld of devel/llvm${AZSUPPORT_CLANG} of this tree, the latest release of LLVM (the llvm of
# DEFAULT_VERSIONS in tools/make.conf.in), in the place of the clang 19 of the base
# system, for every port but those GCC builds (USES=azgcc with AZSUPPORT_GCC other than
# no: Mk/Uses/azgcc.mk; USE_GCC) and devel/llvm*, which the clang of the base system
# builds. In the first pass only, before the USES of the port are read:
# - CC, CXX and CPP, and a BUILD_DEPENDS on the port of the compiler;
# - BINARY_ALIAS (the directory of them is first in the PATH of configure and of the
#   build) for what builds call by name: cc, c++, cpp, clang and clang++, and ar,
#   nm, ranlib and ld of LLVM ${AZSUPPORT_CLANG}: the LTO of the ports (WITH_LTO, ThinLTO
#   of mongodb80, x264 of azsupport) puts the bitcode of the compiler into the objects
#   and the archives, which the ar and the lld of LLVM 19 of the base system do not
#   read;
# - AZSUPPORT_TOOLCHAIN_ENV for tools/*-build.sh (AZSUPPORT_CC, AZSUPPORT_CXX,
#   AZSUPPORT_AR, AZSUPPORT_NM, AZSUPPORT_RANLIB), which build without the
#   environment of make;
# - the annotation azsupport_cc, clang<N> (pkg info -A; Mk/Uses/azgcc.mk writes its own);
# - what Mk/Uses/compiler.mk would ask the compiler: its version (it takes the
#   major and the minor only: COMPILER_VERSION ${AZSUPPORT_CLANG}1), its C++ library (libc++
#   of the base system) and the standards it takes, so that make -V says the same
#   before llvm${AZSUPPORT_CLANG} is installed: the builder reads the dependencies of every
#   port before it builds one, and compiler.mk without the compiler would take it
#   for GCC.
AZSUPPORT_CLANG?=	${LLVM_DEFAULT}
.if defined(_PREMKINCLUDED) && !defined(_POSTMKINCLUDED) && !defined(_AZSUPPORT_CLANG_DONE)
_AZSUPPORT_CLANG_DONE=	yes
.  if !(${.CURDIR:H:T} == devel && !empty(.CURDIR:T:Mllvm[0-9]*)) && !defined(USE_GCC) && \
	(empty(USES:Mazgcc) || ${AZSUPPORT_GCC:U} == no)
CC=	${LOCALBASE}/bin/clang${AZSUPPORT_CLANG}
CXX=	${LOCALBASE}/bin/clang++${AZSUPPORT_CLANG}
CPP=	${LOCALBASE}/bin/clang-cpp${AZSUPPORT_CLANG}
BUILD_DEPENDS+=	clang${AZSUPPORT_CLANG}:devel/llvm${AZSUPPORT_CLANG}
BINARY_ALIAS+=	cc=${CC} c++=${CXX} cpp=${CPP} clang=${CC} clang++=${CXX} \
		ar=${LOCALBASE}/bin/llvm-ar${AZSUPPORT_CLANG} nm=${LOCALBASE}/bin/llvm-nm${AZSUPPORT_CLANG} \
		ranlib=${LOCALBASE}/bin/llvm-ranlib${AZSUPPORT_CLANG} ld=${LOCALBASE}/bin/ld.lld${AZSUPPORT_CLANG}
AZSUPPORT_TOOLCHAIN_ENV=	AZSUPPORT_CC=${CC} AZSUPPORT_CXX=${CXX} \
		AZSUPPORT_AR=${LOCALBASE}/bin/llvm-ar${AZSUPPORT_CLANG} \
		AZSUPPORT_NM=${LOCALBASE}/bin/llvm-nm${AZSUPPORT_CLANG} \
		AZSUPPORT_RANLIB=${LOCALBASE}/bin/llvm-ranlib${AZSUPPORT_CLANG}
.    if empty(USES:Mazgcc)
PKG_NOTES+=	azsupport_cc
PKG_NOTE_azsupport_cc=	clang${AZSUPPORT_CLANG}
.    endif
_AZSUPPORT_CC_HASH:=	${CC:hash}
_AZSUPPORT_CXX_HASH:=	${CXX:hash}
_CCVERSION_${_AZSUPPORT_CC_HASH}=	clang version ${AZSUPPORT_CLANG}.1.0 (devel/llvm${AZSUPPORT_CLANG} of azsupport/ports) Target: x86_64-portbld-freebsd${OSREL}
_CXXINTERNAL_${_AZSUPPORT_CXX_HASH}=	"-lc++"
.    for _s in c89 c99 c11 c17 gnu89 gnu99 gnu11 c++98 c++0x c++11 c++14 c++17 c++20 c++23 c++2b \
	gnu++98 gnu++11 gnu++14 gnu++17 gnu++20 gnu++2b
CC_OUTPUT_${_AZSUPPORT_CC_HASH}_${_s:hash}=	yes
.    endfor
.  else
AZSUPPORT_TOOLCHAIN_ENV=
.  endif
.endif

# No manual pages, documentation or info pages in our packages (aZ, 20.11.2026: «и доки и
# маны мы не юзаем»; DOCS, MAN3 and MANPAGES were off already, but most ports install
# their manual pages whatever the options, and the package script of postfix chowned the
# manual pages of the main.cf of a server: "chown: /usr/local/man/man1/mailq.1.gz: No such
# file or directory"). azsupport-no-docs, a target of POST_PLIST (990 of the stage: after
# compress-man and the add-plist-* targets), takes out of the stage share/man, man,
# share/doc and share/info of the prefix, the manual directories of MANDIRS under it
# (the man3 of Perl), the empty site_perl/man/man1 and man3 that lang/perl5.* makes and
# etc/man.d (the manpath of those pages), and their lines out of the plist (files, @dir,
# @info and the other keywords). tools/docs-check.sh (tools/build.sh) fails a repository
# with such a file or directory.
.if empty(POST_PLIST:Mazsupport-no-docs)
POST_PLIST+=	azsupport-no-docs
.endif
.if !target(azsupport-no-docs)
azsupport-no-docs:
	@for d in ${MANDIRS:M${PREFIX}/*:S,^${PREFIX}/,,} man share/man share/doc share/info etc/man.d lib/perl5/site_perl/man; do \
		[ ! -e "${STAGEDIR}${PREFIX}/$$d" ] || ${RM} -r "${STAGEDIR}${PREFIX}/$$d"; \
		${SED} -i '' -E -e "\#^(@[^[:space:]]+[[:space:]]+)?(${PREFIX}/)?$$d(/|\$$)#d" ${TMPPLIST}; \
	done
.endif

# No info pages, so no print/indexinfo either (aZ, 24.11.2026 19:31: «а с какого хера
# bash зависимость к indexinfo? и тем более котоой у нас нет?»; 19:35: for every port in
# this file, automake too): bsd.port.mk adds indexinfo:print/indexinfo to RUN_DEPENDS
# and the @info lines of add-plist-info for INFO, both after both inclusions of this
# file, and azsupport-no-docs takes share/info out of every package. INFO set by the port's
# Makefile (that of the official port for Mk/azsupport-official.mk) is undefined here, in both
# passes.
.undef INFO

# The keywords of pkg create for our packages: those of the official tree with those of
# Mk/Keywords over them (pkg takes one directory, PLIST_KEYWORDS_DIR), copied by
# azsupport-keywords in the stage. Mk/Keywords/sample.ucl: @sample without "You may need to
# manually remove ... if it is no longer needed." at an upgrade (see its head).
.if empty(PKG_ENV:MPLIST_KEYWORDS_DIR=*)
PKG_ENV+=	PLIST_KEYWORDS_DIR=${WRKDIR}/azsupport-keywords
.endif
# the files of Mk/ the targets read (not makefiles): in the azsupport_hash of every port
.if empty(AZSUPPORT_HASH_FILES:M${AZSUPPORT_OVERLAY}/Mk/Keywords)
AZSUPPORT_HASH_FILES+=	${AZSUPPORT_OVERLAY}/Mk/Keywords ${AZSUPPORT_OVERLAY}/Mk/azsupport-services.awk
.endif
.if empty(POST_PLIST:Mazsupport-keywords)
POST_PLIST+=	azsupport-keywords
.endif
.if !target(azsupport-keywords)
azsupport-keywords:
	@${MKDIR} ${WRKDIR}/azsupport-keywords
	@${CP} ${KEYWORDS}/*.ucl ${AZSUPPORT_OVERLAY}/Mk/Keywords/*.ucl ${WRKDIR}/azsupport-keywords/
.endif

# The services of a package (aZ, 20.11.2026: at the end of pkg upgrade, the commands that
# restart what was upgraded): an empty directory share/azsupport/services/<service> for each
# rc.d script of the package and for the service its modules belong to (lib/php/<API>
# and etc/php<NN>/conf.d: php_fpm<NN>; libexec/nginx: nginx; libexec/apache24:
# apache24). pkg counts the directories of a package it installs or removes as touched,
# and the trigger of azsupport (azsupport/azsupport/files/azsupport-services.ucl) names the services touched in the
# transaction that rc.conf enables.
.if empty(POST_PLIST:Mazsupport-services)
POST_PLIST+=	azsupport-services
.endif
.if !target(azsupport-services)
azsupport-services:
	@for s in $$(${AWK} -v p="${PREFIX}/" -f ${AZSUPPORT_OVERLAY}/Mk/azsupport-services.awk ${TMPPLIST} | ${SORT} -u); do \
		${MKDIR} ${STAGEDIR}${PREFIX}/share/azsupport/services/$$s; \
		${ECHO_CMD} "@dir share/azsupport/services/$$s" >> ${TMPPLIST}; \
	done
.endif
