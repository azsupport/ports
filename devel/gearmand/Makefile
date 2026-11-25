# devel/gearmand of azsupport/ports (aZ, 16.11.2026: gearmand and its module of PHP):
# Gearman 2.2.0 of 18.10.2026 in three packages of one build of the source:
# - gearmand, the job server (sbin/gearmand, its rc.d script), without TLS, and
#   devel/gearmand-openssl (PKGNAMESUFFIX -openssl, the same files) with TLS on
#   the OpenSSL of the base system (aZ, 16.11.2026: two variants, as memcached and
#   redis82); one of the two;
# - devel/libgearman (a slave, PORTNAME libgearman): the client library libgearman
#   with its headers, and the tools gearman and gearadmin; with TLS (it is used only
#   when a client asks for it), so that one library serves both servers and the
#   modules phpXY-gearman, which need no server on the machine.
# The servers take libgearman for its tools (gearadmin). The FreeBSD tree has no
# gearmand any more (devel/gearmand-devel removed 20.04.2021, devel/gearmand, 1.0.6
# of 2013 there and broken, 04.04.2024): a port of this tree after the last
# official one (8c48389f5dc9: its rc.d script, pkg-descr and the alloca patches),
# with:
# - the fixes of master after 2.2.0 (aZ, 16.11.2026), files/patch-master-6b960b01
#   (its head lists them): background jobs submitted without a unique ID lost by a
#   persistent queue (they shared one key), clients blocked on one connection or
#   sending without TLS after the TLS option, a server that did not stop with
#   timers left, a division by zero of gearman; one of them adds a file to the
#   build of the server (libgearman/uuid.cc), so autoreconf, with the version in
#   version.m4 (it would take it from git describe);
# - the persistent queue of aZ: SQLite (libsqlite3 of azsupport), on in the rc.d script;
#   no MySQL, PostgreSQL, Redis, memcached, Tokyo Cabinet and Drizzle;
# - libevent and SQLite the shared libraries of azsupport, with the run path
#   /usr/local/azsupport/lib; Boost.Program_options (gearmand, gearadmin) and libuuid
#   (libgearman, gearmand) the archives of the official devel/boost-libs and
#   misc/libuuid, linked at build time (alone in a directory of the work; their
#   symbols not exported), so that the packages take no package but azsupport and ours;
#   no -fPIE -pie (the archive of boost-libs is not built for it), as the other
#   ports;
# - backtrace(3) of the libexecinfo of the base system; alloca(3) of stdlib.h (no
#   alloca.h on FreeBSD), as the official port had it;
# - not built: the tests, examples, benchmarks and the programs of the docs
#   (noinst_PROGRAMS); no static library; the manual pages with MANPAGES.

PORTNAME?=	gearmand
DISTVERSION=	2.2.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	devel
MASTER_SITES=	https://github.com/gearman/gearmand/releases/download/${DISTVERSION}/
DISTNAME=	gearmand-${DISTVERSION}
DISTINFO_FILE=	${MASTERDIR}/distinfo

MAINTAINER=	github@azsupport.com
COMMENT?=	Gearman job server (of azsupport/ports)
WWW=		https://gearman.org/ \
		https://github.com/gearman/gearmand \
		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	${LOCALBASE}/lib/libboost_program_options.a:devel/boost-libs \
		${LOCALBASE}/lib/libuuid.a:misc/libuuid \
		gperf:devel/gperf \
		${AZSUPPORT_PREFIX}/lib/libevent.so:azsupport/azsupport \
		${AZSUPPORT_PREFIX}/lib/libsqlite3.so:azsupport/azsupport

USES=		autoreconf compiler:c++14-lang gmake libtool pathfix pkgconfig ssl

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--disable-dtrace \
		--disable-hiredis \
		--disable-libdrizzle \
		--disable-libmemcached \
		--disable-libpq \
		--disable-libtokyocabinet \
		--disable-static \
		--disable-wolfssl \
		--enable-jobserver=no \
		--localstatedir=/var \
		--with-boost=${WRKDIR}/deps \
		--with-mysql=no \
		--with-postgresql=no \
		--with-sqlite3=${AZSUPPORT_PREFIX}
# no -fPIE -pie (the checks of AX_HARDEN_COMPILER_FLAGS, one flag a test)
CONFIGURE_ENV=	ax_cv_check_cflags__Werror__fPIE=no \
		ax_cv_check_cflags__Werror__pie=no \
		ax_cv_check_cxxflags__Werror__fPIE=no \
		ax_cv_check_cxxflags__Werror__pie=no

# the work directory deps: the headers of Boost and of libuuid, libboost_program_options.a
# and libuuid.a, nothing else of /usr/local (their symbols not exported by libgearman
# and gearmand: --exclude-libs); libevent and SQLite of azsupport (-levent of AX_LIBEVENT
# through CPPFLAGS and LDFLAGS)
CPPFLAGS+=	-I${WRKDIR}/deps/include -I${AZSUPPORT_PREFIX}/include
LDFLAGS+=	-L${WRKDIR}/deps/lib -L${AZSUPPORT_PREFIX}/lib -Wl,-rpath,${AZSUPPORT_PREFIX}/lib \
		-Wl,--exclude-libs,libboost_program_options.a:libuuid.a
LIBS+=		-lexecinfo

# not the programs of the tests, examples, benchmarks and docs
MAKE_ARGS+=	noinst_PROGRAMS=
INSTALL_TARGET=	install-strip

OPTIONS_DEFINE=	MANPAGES
OPTIONS_DEFAULT=	MANPAGES
OPTIONS_SUB=	yes

.if ${PORTNAME} == "libgearman"
# the client library and the tools, with TLS
CONFIGURE_ARGS+=	--enable-ssl --with-openssl=${OPENSSLBASE}
USE_LDCONFIG=		yes
.else
# the server: TLS only in gearmand-openssl; the tools of libgearman
.  if ${PKGNAMESUFFIX:U} == "-openssl"
CONFIGURE_ARGS+=	--enable-ssl --with-openssl=${OPENSSLBASE}
CONFLICTS_INSTALL=	gearmand
.  else
CONFLICTS_INSTALL=	gearmand-openssl
.  endif
RUN_DEPENDS=		${AZSUPPORT_PREFIX}/lib/libevent.so:azsupport/azsupport \
			${AZSUPPORT_PREFIX}/lib/libsqlite3.so:azsupport/azsupport \
			${LOCALBASE}/bin/gearadmin:devel/libgearman
USE_RC_SUBR=		gearmand
USERS=			gearmand
GROUPS=			gearmand
SUB_LIST+=		USERS=${USERS} GROUPS=${GROUPS}
.endif

# AX_AM_JOBSERVER of configure.ac out: automake 1.20 (devel/automake of the pin of
# 19.11.2026) has an --enable-jobserver of its own, yes or no only ("bad value '64' for
# --enable-jobserver", 13Z0 run 44469975840), and the configure target of bsd.port.mk
# adds --enable-jobserver=${MAKE_JOBS_NUMBER} when the help shows the "[=no/yes/#]" of
# that macro; without it the "no" of CONFIGURE_ARGS goes to that of automake (make -j
# of the framework as before)
post-patch:
	@${ECHO_CMD} 'm4_define([VERSION_NUMBER], [${DISTVERSION}])' > ${WRKSRC}/version.m4
	@${REINPLACE_CMD} -e '/^AX_AM_JOBSERVER(/d' ${WRKSRC}/configure.ac

pre-configure:
	@${MKDIR} ${WRKDIR}/deps/include ${WRKDIR}/deps/lib
	@${LN} -sf ${LOCALBASE}/include/boost ${LOCALBASE}/include/uuid ${WRKDIR}/deps/include/
	@${LN} -sf ${LOCALBASE}/lib/libboost_program_options.a ${LOCALBASE}/lib/libuuid.a \
		${WRKDIR}/deps/lib/

# each package its part of what make install put there (pkg-plist; libgearman has
# one of its own)
post-install:
.if ${PORTNAME} == "libgearman"
	@${RM} ${STAGEDIR}${PREFIX}/sbin/gearmand ${STAGEDIR}${PREFIX}/share/man/man8/gearmand.8
.else
	@${RM} ${STAGEDIR}${PREFIX}/bin/gearadmin ${STAGEDIR}${PREFIX}/bin/gearman \
		${STAGEDIR}${PREFIX}/lib/libgearman.so* ${STAGEDIR}${PREFIX}/libdata/pkgconfig/gearmand.pc
	@${RM} -r ${STAGEDIR}${PREFIX}/include/libgearman ${STAGEDIR}${PREFIX}/include/libgearman-1.0
	@${FIND} ${STAGEDIR}${PREFIX}/share/man/man1 ${STAGEDIR}${PREFIX}/share/man/man3 -type f -delete
.endif

post-install-MANPAGES-off:
	@${FIND} ${STAGEDIR}${PREFIX}/share/man -type f -delete

.include <bsd.port.mk>
