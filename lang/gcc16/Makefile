# lang/gcc16: GCC 16 of azsupport/ports in the place of the official lang/gcc16 (aZ,
# 18.11.2026: «собери gcc14 минималистично как и цланг собирал, но со всеми
# возможными оптимизациями»; «в) ... на GCC 16 вместо 14 ... так адекватнее и на
# вырост»; «и у нас последняя 16.х? если нет, то надо последнюю раз уже сами
# собираем»): GCC 16.2.0 (07.08.2026; the official port is at 16.1.0), two packages of
# this Makefile:
# - gcc16-libs (lang/gcc16-libs, a slave port: GCC_PART=libs): the run-time libraries
#   of GCC alone, in lib/gcc16 as in the official package (with its ldconfig hints):
#   libgcc_s.so.1, libstdc++.so.6, libatomic.so.1 and libgomp.so.1 (OpenMP), for a
#   program built by GCC that a server runs (sysutils/arcconf: libstdc++.so.6), without
#   the compiler and the binutils. Built without bootstrap: the compiler built once by
#   the base clang builds them (the code GCC gives does not depend on the compiler
#   that built GCC);
# - gcc16 (this port): the compiler, C and C++ (and the LTO of GCC), with what it needs
#   to build: the headers of libstdc++, the static libraries, libgcc, the links of the
#   shared libraries of gcc16-libs, which it needs (RUN_DEPENDS), and the as and ld of
#   the binutils of the ports (the official package of devel/binutils). Built as
#   optimized as GCC builds: profiledbootstrap-lean (PGO: stage1 by the base clang, an
#   instrumented stage that builds the next one as its training, then the final stage
#   with the profile) with bootstrap-lto-noplugin (LTO with fat objects, as the
#   official port: bootstrap-lto-lean archives its libraries by gcc-ranlib, which took
#   the ranlib of the base system, "Invalid option: '--plugin'", build run 44308740075;
#   fat in the stages of PGO too, post-patch),
#   and gmp 6.3.0,
#   mpfr 4.2.2, mpc 1.3.1 and isl 0.24 (Graphite: the loop optimizations -floop-* and
#   -fgraphite-identity) built in, static, the versions of contrib/download_prerequisites
#   of 16.2.0: neither package needs math/gmp, math/mpfr, math/mpc or devel/isl. No GCC
#   plugins (--disable-plugin: no -rdynamic, so that LTO takes every function of cc1 as
#   its own), no --enable-host-shared (the compiler not PIC; GCC: "a slightly slower
#   compiler"; only libgccjit needs it), no PCH of libstdc++.
# Every stage, and the libraries of both packages, with the CFLAGS of the build (aZ:
# -O3, the -march of the level, -fstack-protector-strong, -fno-strict-aliasing; with
# -D__USE_ISOC11, as the official port): STAGE1_CFLAGS, BOOT_CFLAGS, CFLAGS_FOR_TARGET
# and CXXFLAGS_FOR_TARGET, where GCC alone would take -g, -g -O2 and -g -O2 before
# them.
# Not built (aZ, 18.11.2026: minimal): Fortran, Objective-C, libgccjit (nothing of ours
# compiles with it at run time: the JIT of PHP is its own, that of PostgreSQL is LLVM),
# 32-bit (multilib), NLS, the sanitizers (libsanitizer), libitm (transactional memory),
# libquadmath (__float128 of Fortran; libstdc++ does not use it), libssp, libcc1 (GDB),
# the info pages (no makeinfo either since 24.11.2026, so they are not made at all: the
# configure of GCC and of its libraries builds them only with a makeinfo it finds, aZ:
# what is only for documentation off for every port). The code it gives is that of GCC 16.2.0 with the options of the
# official port that decide it (--enable-gnu-indirect-function, the as and ld of the
# binutils, the headers of libc++ for -stdlib=libc++): no default -march, PIE or SSP
# of its own; --with-pkgversion "azsupport/ports" (the .comment of what it builds,
# "GCC: (azsupport/ports) 16.2.0", tells it from the official one). Of the patches of
# the official port those of amd64 (files/); those of aarch64, arm and powerpc, of
# Fortran, libgccjit and the sanitizers left out.
# The ports of this tree that build with GCC (Mk/Uses/azgcc.mk: PHP, Redis, Python;
# azsupport/azsupport) take the official package of lang/gcc16 until they move to this one with the
# next full build (aZ, 18.11.2026: «а) ... да, давай так»): AZSUPPORT_TOOLS_OFFICIAL of
# tools/build.sh.

PORTNAME=	gcc
PORTVERSION=	16.2.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	lang
MASTER_SITES=	GCC \
		GCC/infrastructure:infra
PKGNAMESUFFIX=	${SUFFIX}${GCC_PART:D-${GCC_PART}}
DISTFILES=	${DISTNAME}${EXTRACT_SUFX} ${GCC_INFRA:S/$/:infra/}

MAINTAINER=	github@azsupport.com
COMMENT?=	GNU Compiler Collection 16, C and C++ (of azsupport/ports)
WWW=		https://gcc.gnu.org/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv3 GPLv3RLE
LICENSE_COMB=	multi

ONLY_FOR_ARCHS=	amd64
ONLY_FOR_ARCHS_REASON=	the x86-64 levels of azsupport/ports only

USES=		compiler:c++11-lang cpe gmake iconv libtool perl5 tar:xz
USE_BINUTILS=	yes
USE_PERL5=	build
CPE_VENDOR=	gnu
CPE_VERSION=	${PORTVERSION}

CONFLICTS_INSTALL=	gcc16-devel

# the libraries of the compiler, built in (static): the files of contrib/download_prerequisites
# of 16.2.0 (gcc.gnu.org/pub/gcc/infrastructure/), checked there against
# contrib/prerequisites.sha512 (distinfo.yml run 44294401089)
GCC_INFRA=	gmp-6.3.0.tar.bz2 mpfr-4.2.2.tar.bz2 mpc-1.3.1.tar.gz isl-0.24.tar.bz2

SUFFIX=		${PORTVERSION:C/([0-9]+).*/\1/}
TARGLIB=	${PREFIX}/lib/gcc${SUFFIX}
LIBEXEC=	${PREFIX}/libexec/gcc${SUFFIX}
CFLAGS:=	${CFLAGS:N-mretpoline} -D__USE_ISOC11
CXXFLAGS:=	${CXXFLAGS:N-mretpoline}

GNU_CONFIGURE=	yes
GNU_CONFIGURE_MANPREFIX=${PREFIX}/share
CONFIGURE_OUTSOURCE=	yes
CONFIGURE_ARGS=	--disable-libcc1 \
		--disable-libitm \
		--disable-libquadmath \
		--disable-libsanitizer \
		--disable-libssp \
		--disable-libstdcxx-pch \
		--disable-multilib \
		--disable-nls \
		--disable-plugin \
		--enable-gnu-indirect-function \
		--enable-languages=c,c++ \
		--libdir=${TARGLIB} \
		--libexecdir=${LIBEXEC} \
		--program-suffix=${SUFFIX} \
		--with-as=${LOCALBASE}/bin/as \
		--with-gxx-include-dir=${TARGLIB}/include/c++/ \
		--with-gxx-libcxx-include-dir=/usr/include/c++/v1 \
		--with-ld=${LOCALBASE}/bin/ld \
		${ICONV_CONFIGURE_ARG} \
		--with-pkgversion="azsupport/ports" \
		--with-system-zlib \
		--without-zstd
# the libraries of GCC (libgcc, libstdc++, libatomic, libgomp) with the flags of the build
CONFIGURE_ENV=	CFLAGS_FOR_TARGET="${CFLAGS}" \
		CXXFLAGS_FOR_TARGET="${CXXFLAGS}"

PLIST_SUB+=	GCC_VERSION=${PORTVERSION} \
		GNU_HOST=${CONFIGURE_TARGET} \
		SUFFIX=${SUFFIX}

.if ${GCC_PART:U} == libs
# the compiler once (the base clang), then the libraries of GCC with it
CONFIGURE_ARGS+=	--disable-bootstrap
INSTALL_TARGET=	install-strip-target
USE_LDCONFIG=	${TARGLIB}
.else
RUN_DEPENDS=	${LOCALBASE}/bin/as:devel/binutils \
		gcc${SUFFIX}-libs>=${PORTVERSION}:lang/gcc${SUFFIX}-libs
CONFIGURE_ARGS+=	--enable-bootstrap \
			--with-build-config=bootstrap-lto-noplugin
ALL_TARGET=	profiledbootstrap-lean
MAKE_ARGS+=	STAGE1_CFLAGS="${CFLAGS}" \
		BOOT_CFLAGS="${CFLAGS}"
INSTALL_TARGET=	install-strip
PIE_UNSAFE=	yes
SUB_FILES=	pkg-message
SUB_LIST+=	TARGLIB=${TARGLIB}
# ccache between the runs of build.yml (aZ, 24.11.2026 09:48: a build stopped at the
# time of a run goes on in the next one; 24.11.2026 it was stopped after 246 minutes):
# stage 1 (the base clang) through the wrappers of ccache (WITH_CCACHE_BUILD of the
# framework), the compilers of the stages after it (xgcc and xg++, built again in each
# run: their content in the hash, CCACHE_COMPILERCHECK) by STAGE_CC_WRAPPER of the
# Makefile of GCC; the cache in AZSUPPORT_PORT_CACHE_DIR (portcache/lang_gcc16,
# tools/build.sh), ccache of the official packages
AZSUPPORT_PORT_CACHE=	ccache
BUILD_DEPENDS+=	ccache:devel/ccache
.  if !empty(AZSUPPORT_PORT_CACHE_DIR)
WITH_CCACHE_BUILD=	yes
CCACHE_DIR=	${AZSUPPORT_PORT_CACHE_DIR}/ccache
MAKE_ARGS+=	STAGE_CC_WRAPPER=ccache
MAKE_ENV+=	CCACHE_COMPILERCHECK=content CCACHE_MAXSIZE=8G
.  endif
.endif

.if ${GCC_PART:U} != libs
# the fat LTO objects of stage2 and stage3 in the stages of PGO too: without the plugin of
# the linker (bootstrap-lto-noplugin) a slim LTO object in an archive gives ld nothing,
# and isl_test of stagefeedback found no isl_val_* in libisl.a (build run 44369059639 of
# 13Z0/13Z0, 18.11.2026: "undefined reference to `isl_val_pow2'")
post-patch:
	${REINPLACE_CMD} -E 's/^(STAGE(profile|train|feedback)_CFLAGS \+= -flto=jobserver -frandom-seed=1)$$/\1 -ffat-lto-objects/' \
		${WRKSRC}/config/bootstrap-lto-noplugin.mk
	@n=$$(${GREP} -c -e '-ffat-lto-objects' ${WRKSRC}/config/bootstrap-lto-noplugin.mk); \
	[ "$$n" = 5 ] || { ${ECHO_MSG} "bootstrap-lto-noplugin.mk: $$n lines with -ffat-lto-objects, not 5"; exit 1; }
.endif

# the libraries of the compiler in the tree, as contrib/download_prerequisites puts them
post-extract:
.for d in ${GCC_INFRA:C/\.tar\..*//}
	${MV} ${WRKDIR}/${d} ${WRKSRC}/${d:C/-[0-9.]+$//}
.endfor

pre-configure:
	cd ${WRKSRC} ; contrib/gcc_update --touch

post-stage:
	${RM} -r ${STAGEDIR}${PREFIX}/share/info ${STAGEDIR}${PREFIX}/share/man/man7
	${RM} ${WRKDIR}/PLIST.lib
.if ${GCC_PART:U} == libs
	# the shared libraries of run time alone (lib*.so.N and their links, not the gdb
	# scripts of libstdc++)
	cd ${STAGEDIR}${PREFIX} && ${FIND} . ! -type d \
		! \( -path './lib/gcc${SUFFIX}/lib*.so.[0-9]*' ! -name '*.py' \) -delete
	# the directories those files were in, not those of the hierarchy of the stage
	# (mtree): libdata/ldconfig takes the file of USE_LDCONFIG after this target
	# (build run 44299593024: "cannot create .../libdata/ldconfig/gcc16-libs")
	${RM} -r ${STAGEDIR}${PREFIX}/share/gcc-${PORTVERSION}
	cd ${STAGEDIR}${PREFIX} && ${FIND} lib/gcc${SUFFIX} -mindepth 1 -depth -type d -empty -delete
	# stripped: libgcc_s.so.1 comes with the debug information of libgcc (-g of
	# LIBGCC2_DEBUG_CFLAGS) and not stripped by install-strip-target (build run
	# 44308740075, debug-check)
	${FIND} ${STAGEDIR}${TARGLIB} -name 'lib*.so.[0-9]*' -type f -exec ${STRIP_CMD} {} +
	cd ${STAGEDIR}${PREFIX} && ${FIND} lib/gcc${SUFFIX} -type f -o -type l | \
		${SORT} > ${WRKDIR}/PLIST.lib
.else
	# the shared libraries of run time are gcc16-libs; the gdb scripts of libstdc++ and
	# the headers of fixincludes (as the official port) not packaged
	${RM} ${STAGEDIR}${TARGLIB}/lib*.so.[0-9]*
	${RM} -r ${STAGEDIR}${PREFIX}/share/gcc-${PORTVERSION} \
		${STAGEDIR}${TARGLIB}/gcc/*/${PORTVERSION}/include-fixed
	# the static libraries without debug information, their symbols kept: libgcc.a,
	# libgcc_eh.a and libgcov.a come with that of -g of LIBGCC2_DEBUG_CFLAGS, which
	# install-strip leaves (build run 44385710548 of 13Z0/13Z0, 18.11.2026, debug-check:
	# .debug_info of 122 KB, 74 KB and 51 KB)
	${FIND} ${STAGEDIR}${TARGLIB} -name '*.a' -type f -exec ${STRIP_CMD} --strip-debug {} +
.  for d in ${TARGLIB:S/^${PREFIX}\///} ${LIBEXEC:S/^${PREFIX}\///}
	cd ${STAGEDIR}${PREFIX} && ${FIND} ${d} -type f -o -type l | \
		${SORT} >> ${WRKDIR}/PLIST.lib
.  endfor
.endif
	cd ${WRKDIR} && ${SED} -i -e "/PLIST.lib/ r PLIST.lib" ${TMPPLIST}

.include <bsd.port.mk>
