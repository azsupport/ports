# databases/postgresql18-server: the PostgreSQL 18 of azsupport/ports in the place of
# the official databases/postgresql18-server (and of the master of the official ports
# of 18, databases/postgresql19-server, which it includes), and by its slave ports of
# the client and the contrib modules (aZ, 16.11.2026: «давай наверно постгресс сразу на
# 18ый смени и добавим -server и -contrib»). Six packages, two chains, one of each
# component installs (CONFLICTS_INSTALL):
#   postgresql18-server, -client, -contrib            without OpenSSL;
#   postgresql18-server-openssl, -client-openssl,
#   postgresql18-contrib-openssl                      with the OpenSSL of the base system
# (aZ: «ssl в отдельный порт -openssl и для клиента и сервера»; the contrib modules
# likewise, aZ 16.11.2026: «contrib и contrib-openssl»: pgcrypto and sslinfo only in
# contrib-openssl). The server and the contrib modules of a chain take the client of
# their chain (libpq: pg_basebackup, pg_rewind, pg_upgrade, the tools of contrib), so a
# server without OpenSSL and contrib-openssl conflict: the chain with OpenSSL is the
# one with pgcrypto (its server listens without TLS unless ssl = on).
# The options of aZ (16.11.2026): the JIT of LLVM (devel/llvm19 of this tree, its
# backend of X86 and clang, with all its optimization), ICU, LZ4 and ZSTD, XML; no PAM,
# LDAP, GSSAPI, no procedural languages pl* (no ports of them); DTRACE, NLS and the docs
# off as everywhere (tools/make.conf.in), OPTIMIZED_CFLAGS on (-O3 -funroll-loops, as
# the make.conf of his servers), the time zones of the base system (TZDATA off), the
# man pages of the client off (MANPAGES, as everywhere: no docbook to build them).
# The libraries of az (ICU, lz4, zstd, libxml2, libxslt) with the run path
# /usr/local/az/lib, alone in a directory of the work with .pc files of their own (as
# mail/postfix: no other header or library of /usr/local/az); the readline of az for
# psql (aZ 20.11.2026 19:58: «переводи»: GNU readline in the place of the libedit of the
# base system, as the PHP and the Python of this tree have it).

PORTNAME?=	postgresql
DISTVERSION?=	18.7
PORTREVISION?=	${AZ_STAMP:U0}
CATEGORIES?=	databases
MASTER_SITES=	PGSQL/source/v${DISTVERSION}
.if defined(AZ_PG_OPENSSL)
AZ_PG_SSL=	-openssl
.endif
PKGNAMESUFFIX?= ${PORTVERSION:R}${COMPONENT}${AZ_PG_SSL}

MAINTAINER?=	github@azsupport.com
COMMENT?=	PostgreSQL database server (of azsupport/ports)
WWW=		https://www.postgresql.org/ \
		https://github.com/azsupport/ports

LICENSE=	PostgreSQL

CONFLICTS+=	${PORTNAME}1[^${PORTVERSION:R:C/.*([0-9]$)/\\1/}]*
# the same component of the other chain
.if defined(AZ_PG_OPENSSL)
CONFLICTS_INSTALL=	${PORTNAME}${PORTVERSION:R}${COMPONENT}
.else
CONFLICTS_INSTALL=	${PORTNAME}${PORTVERSION:R}${COMPONENT}-openssl
.endif

WRKSRC=		${WRKDIR}/postgresql-${DISTVERSION}
DIST_SUBDIR=	postgresql

OPTIONS_SUB=	yes

PKGINSTALL?=	${PKGDIR}/pkg-install${COMPONENT}
USES+=		tar:bzip2 cpe bison perl5
USE_PERL5+=	build

.if !defined(NO_BUILD)
USES+=		gmake
GNU_CONFIGURE=	yes
GNU_CONFIGURE_MANPREFIX=${PREFIX}/share
.endif

PG_USER?=	postgres
PG_GROUP?=	postgres
PG_UID?=	770

# the libraries of az of the component (AZ_PG_LIBS: icu lz4 zstd xml2 xslt readline), alone in
# ${WRKDIR}/az (pre-configure), with the run path of az
LDFLAGS+=	-L${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib -L${LOCALBASE}/lib
INCLUDES+=	-I${WRKDIR}/az/include -I${WRKDIR}/az/include/libxml2 -I${LOCALBASE}/include
CONFIGURE_ARGS+=--with-libraries=${PREFIX}/lib \
		--with-includes=${PREFIX}/include \
		--enable-thread-safety
CONFIGURE_ENV+=	INCLUDES="${INCLUDES}" \
		PTHREAD_LIBS="-lpthread" \
		LDFLAGS_SL="${LDFLAGS_SL}" \
		PKG_CONFIG_LIBDIR=${WRKDIR}/az/pc:${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig
LDFLAGS+=	-lpthread
MAKE_ENV=	MAKELEVEL=0

PLIST=		${PKGDIR}/pkg-plist${COMPONENT}

INSTALL_DIRS?=	src/common src/timezone src/backend \
		src/backend/utils/mb/conversion_procs \
		src/backend/snowball src/backend/replication/libpqwalreceiver \
		src/backend/replication/pgoutput \
		src/bin/initdb src/bin/pg_ctl \
		src/bin/pg_archivecleanup src/bin/pg_basebackup \
		src/bin/pg_checksums src/bin/pg_combinebackup \
		src/bin/pg_controldata src/bin/pg_resetwal src/pl \
		src/bin/pg_rewind \
		src/bin/pg_test_fsync src/bin/pg_test_timing \
		src/bin/pg_waldump src/bin/pg_walsummary src/bin/pg_upgrade

BUILD_DIRS?=	src/port ${INSTALL_DIRS}
INSTALL_TARGET?=install-strip

.if !defined(CLIENT_ONLY) && !defined(SLAVE_ONLY)
SERVER_ONLY=	yes
COMPONENT=	-server
USE_RC_SUBR=	postgresql
USES+=		pgsql:${DISTVERSION:C/([0-9]\.?[0-9]).*/\1/g}
USERS=		${PG_USER}
GROUPS=		${PG_GROUP}
SUB_FILES+=	502.pgsql
AZ_PG_LIBS=	icu lz4 zstd xml2
.endif

# the server and the contrib modules take the client of their chain (not the one
# USES=pgsql would give: WANT_PGSQL empty); they have no line editing (only psql of
# the client has it, with the readline of az), so configure looks for no readline in
# them
.if !defined(CLIENT_ONLY)
WANT_PGSQL=
LIB_DEPENDS+=	libpq.so.5:databases/postgresql${PORTVERSION:R}-client${AZ_PG_SSL}
CONFIGURE_ARGS+=--without-readline
.endif

MAKE_ENV+=	PATH=${PREFIX}/bin:${PATH}
CONFIGURE_ENV+=	PATH=${PREFIX}/bin:${PATH}

.if defined(SERVER_ONLY)
OPTIONS_DEFINE=	DTRACE LDAP TZDATA XML DOCS LZ4 LLVM
OPTIONS_DEFAULT+=XML LZ4 LLVM
LDAP_DESC=	Build with LDAP authentication support
TZDATA_DESC=	Use internal timezone database
XML_DESC=	Build with XML data type
LZ4_DESC=	Build with LZ4 compression support
LLVM_DESC=	Build with support for JIT-compiling expressions

DTRACE_CONFIGURE_ENABLE=dtrace
DTRACE_LDFLAGS=		-lelf
DTRACE_INSTALL_TARGET=	install

LZ4_CONFIGURE_WITH=	lz4
LZ4_BUILD_DEPENDS=	${AZ_PREFIX}/lib/liblz4.so:az/az
LZ4_RUN_DEPENDS=	${AZ_PREFIX}/lib/liblz4.so:az/az

LLVM_CONFIGURE_WITH=	llvm
LLVM_CONFIGURE_ENV=	LLVM_CONFIG=${LLVM_CONFIG} \
			CLANG=${LOCALBASE}/bin/clang${LLVM_VERSION}
LLVM_USES=		llvm:lib

CONFIGURE_ARGS+=	--with-icu
BUILD_DEPENDS+=		${AZ_PREFIX}/lib/libicuuc.so:az/az
RUN_DEPENDS+=		${AZ_PREFIX}/lib/libicuuc.so:az/az
USES+=			pkgconfig

XML_CONFIGURE_WITH=	libxml
# libxml2 of az, its flags given (they go before pkg-config and xml2-config)
XML_CONFIGURE_ENV=	XML2_CFLAGS=-I${WRKDIR}/az/include/libxml2 \
			XML2_LIBS="-L${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib -lxml2"
XML_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libxml2.so:az/az
XML_RUN_DEPENDS=	${AZ_PREFIX}/lib/libxml2.so:az/az
.else
CONFIGURE_ARGS+=	--without-icu
.endif

.if !defined(SLAVE_ONLY)
OPTIONS_DEFINE+=	NLS PAM GSSAPI OPTIMIZED_CFLAGS DEBUG DOCS SSL
NLS_DESC=		Use internationalized messages
PAM_DESC=		Build with PAM Support
GSSAPI_DESC=		Build with GSSAPI from security/krb5
OPTIMIZED_CFLAGS_DESC=	Builds with compiler optimizations (-O3)
SSL_DESC=		Build with OpenSSL support

# the options of aZ (16.11.2026): OpenSSL in the chain -openssl only; -O3 and
# -funroll-loops as the make.conf of his servers
OPTIONS_DEFAULT+=	OPTIMIZED_CFLAGS
.  if defined(AZ_PG_OPENSSL)
OPTIONS_DEFAULT+=	SSL
.  endif

GSSAPI_USES=		gssapi:mit
GSSAPI_CONFIGURE_WITH=	gssapi

PATCH_DIST_STRIP=-p1
.endif # !SLAVE_ONLY

.if defined(SERVER_ONLY) || defined(CLIENT_ONLY) || ${COMPONENT} == "-contrib"
OPTIONS_DEFINE+=	ZSTD
OPTIONS_DEFAULT+=	ZSTD
ZSTD_DESC=		Build with ZSTD compression support
ZSTD_CONFIGURE_WITH=	zstd
ZSTD_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libzstd.so:az/az
ZSTD_RUN_DEPENDS=	${AZ_PREFIX}/lib/libzstd.so:az/az
USES+=			pkgconfig
.endif

SSL_USES=		ssl
SSL_CONFIGURE_WITH=	openssl

PAM_CONFIGURE_WITH=	pam

TZDATA_CONFIGURE_OFF=	--with-system-tzdata=/usr/share/zoneinfo

NLS_CONFIGURE_ENABLE=	nls
NLS_USES=		gettext

LDAP_CONFIGURE_WITH=	ldap
LDAP_USES=		ldap

OPTIMIZED_CFLAGS_CFLAGS=-O3 -funroll-loops

DEBUG_CONFIGURE_ENABLE=	debug

PLIST_SUB+=		PG_VERSION=${PORTVERSION:R} \
			PG_USER=${PG_USER} \
			PG_USER_regex=[[:<:]]${PG_USER}[[:>:]] \
			PG_GROUP=${PG_GROUP} \
			PG_GROUP_regex=[[:<:]]${PG_GROUP}[[:>:]]
SUB_LIST+=		PG_VERSION=${PORTVERSION:R} \
			PG_GROUP=${PG_GROUP} \
			PG_USER=${PG_USER} \
			PG_UID=${PG_UID}

.include <bsd.port.options.mk>

.if ${PORT_OPTIONS:MZSTD}
AZ_PG_LIBS+=	zstd
.endif

# For testing files in FILESDIR
.include <bsd.port.pre.mk>

.if ${PORT_OPTIONS:MLLVM}
INSTALL_DIRS+=		src/backend/jit/llvm
.endif

# the libraries of az: their headers and shared libraries alone in ${WRKDIR}/az, a .pc
# of each with the version of that of az, the run path of az; nothing else of
# /usr/local/az is seen (as mail/postfix)
pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib ${WRKDIR}/az/pc
	@for l in ${AZ_PG_LIBS:O:u}; do \
	    case $$l in \
	    icu) pc="icu-uc:-licuuc,-licudata icu-i18n:-licui18n"; \
		libs="libicuuc libicui18n libicudata"; incs="unicode" ;; \
	    lz4) pc="liblz4:-llz4"; libs="liblz4"; incs="lz4.h lz4hc.h lz4frame.h" ;; \
	    zstd) pc="libzstd:-lzstd"; libs="libzstd"; incs="zstd.h zdict.h zstd_errors.h" ;; \
	    xml2) pc="libxml-2.0:-lxml2"; libs="libxml2"; incs="libxml2" ;; \
	    xslt) pc=""; libs="libxslt libexslt"; incs="libxslt libexslt" ;; \
	    readline) pc=""; libs="libreadline libhistory"; incs="readline" ;; \
	    *) ${ECHO_MSG} "AZ_PG_LIBS: unknown $$l"; exit 1 ;; \
	    esac; \
	    for i in $$incs; do ${LN} -sf ${AZ_PREFIX}/include/$$i ${WRKDIR}/az/include/$$i; done; \
	    for f in $$libs; do ${LN} -sf ${AZ_PREFIX}/lib/$$f.so ${WRKDIR}/az/lib/$$f.so; done; \
	    for p in $$pc; do n=$${p%%:*}; L=$$(${ECHO_CMD} "$${p#*:}" | ${TR} , ' '); \
		v=$$(${SED} -n 's/^Version: *//p' ${AZ_PREFIX}/lib/pkgconfig/$$n.pc); \
		[ -n "$$v" ] || { ${ECHO_MSG} "no ${AZ_PREFIX}/lib/pkgconfig/$$n.pc"; exit 1; }; \
		r=""; [ $$n = icu-i18n ] && r="Requires: icu-uc"; \
		c="-I${WRKDIR}/az/include"; [ $$n = libxml-2.0 ] && c="$$c -I${WRKDIR}/az/include/libxml2"; \
		${PRINTF} 'Name: %s\nDescription: %s of az\nVersion: %s\n%s\nCflags: %s\nLibs: -L${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib %s\n' \
		    "$$n" "$$n" "$$v" "$$r" "$$c" "$$L" > ${WRKDIR}/az/pc/$$n.pc; \
	    done; \
	done

.if defined(SERVER_ONLY)
pre-build:
	@${SH} ${PKGINSTALL} ${PORTNAME} PRE-INSTALL
.endif

.if !defined(NO_BUILD) && !target(do-build)

do-build:
	@ cd ${WRKSRC}/src/backend && ${SETENVI} ${WRK_ENV} ${MAKE_ENV} ${MAKE_CMD} generated-headers
	@ for dir in ${BUILD_DIRS}; do \
		cd ${WRKSRC}/$${dir} && ${SETENVI} ${WRK_ENV} ${MAKE_ENV} ${MAKE_CMD} ; \
	done
.  if defined(CLIENT_ONLY) && ${PORT_OPTIONS:MMANPAGES}
	@ cd ${WRKSRC}/doc && ${SETENVI} ${WRK_ENV} ${MAKE_ENV} ${MAKE_CMD} man
.  endif
.  if exists(${FILESDIR}/pkg-message${COMPONENT}.in)
SUB_FILES+=	pkg-message${COMPONENT}
PKGMESSAGE=	${WRKSRC}/pkg-message${COMPONENT}
.  endif
.  if exists(${FILESDIR}/pkg-install${COMPONENT}.in)
SUB_FILES+=	pkg-install${COMPONENT}
.  endif

post-patch:
.  if defined(CLIENT_ONLY) && !defined(OPENSSL_PORT)
	@${REINPLACE_CMD} \
		-e '/^PKG_CONFIG_REQUIRES_PRIVATE = libssl libcrypto/d' \
		${WRKSRC}/src/interfaces/libpq/Makefile
.  endif

do-install:
	for dir in ${INSTALL_DIRS}; do \
	    cd ${WRKSRC}/$${dir} && \
		${SETENVI} ${WRK_ENV} ${MAKE_ENV} ${MAKE_CMD} ${MAKE_ARGS} ${INSTALL_TARGET}; \
	done
.  if defined(SERVER_ONLY)
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/postgresql/*.so
	${MKDIR} ${STAGEDIR}${PREFIX}/share/postgresql
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/periodic/daily
	${INSTALL_SCRIPT} ${WRKDIR}/502.pgsql \
			${STAGEDIR}${PREFIX}/etc/periodic/daily
.  endif # SERVER_ONLY
.  if defined(CLIENT_ONLY)
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/* ${STAGEDIR}${PREFIX}/lib/lib*.so
	cd ${WRKSRC}/src && ${SETENVI} ${WRK_ENV} ${MAKE_ENV} ${MAKE_CMD} ${MAKE_ARGS} install-local
.    if ${PORT_OPTIONS:MMANPAGES}
	cd ${WRKSRC}/doc/src/sgml && ${COPYTREE_SHARE} "man1 man3 man7" ${STAGEDIR}${PREFIX}/share/man
.    endif
.  endif
.  if defined(SLAVE_ONLY)
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/postgresql/*.so
.  endif
.  if ${PORT_OPTIONS:MDOCS}
	if [ -r ${PKGMESSAGE} ]; then \
		${MKDIR} ${STAGEDIR}${DOCSDIR} ;\
		${INSTALL_DATA} ${PKGMESSAGE} ${STAGEDIR}${DOCSDIR}/README${COMPONENT} ;\
	fi
.  endif
.endif # !NO_BUILD

.include <bsd.port.post.mk>
