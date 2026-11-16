# mail/dovecot: the Dovecot 2.3 of azsupport/ports in the place of the official
# mail/dovecot (aZ, 15.11.2026: the branch 2.3, as long as upstream supports it; it
# gets only critical security fixes now) and, by its slave port mail/dovecot-mysql,
# of its flavor mysql (the SQL driver of MySQL). The official port with aZ's options
# (those of his servers, without libwrap: no tcpwrap in his configurations, aZ
# 15.11.2026): no GSSAPI, CDB, LDAP, PostgreSQL, SQLite, the FTS plugins (ICU,
# CLucene, Solr, textcat), libsodium, libunwind, Lua, LZ4, the docs and the examples
# (the official default has LDAP and libwrap too). zstd the shared library of az,
# with the run path /usr/local/az/lib (our ports link each other's shared libraries:
# aZ, 10.11.2026), its headers and library alone in a directory of the work; in
# dovecot-mysql the client library of databases/mariadb1011-client (mysql=10.11m of
# tools/make.conf.in; the official
# one takes the zstd and the MySQL 8.4 client of the ports); the OpenSSL, zlib,
# bzip2, xz and iconv of the base system. No flavors: dovecot-mysql is a slave
# port, as the variants of our other ports. The security fixes of 2.3 after 2.3.21.1
# as Ubuntu noble and RHEL 10 apply them to their 2.3.21 (aZ, 16.11.2026: the patches
# on 2.3.21.1): see DOVECOT_CVE_PATCHES.

PORTNAME=	dovecot
DISTVERSION=	2.3.21.1
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	mail
MASTER_SITES=	https://dovecot.org/releases/2.3/

MAINTAINER=	github@azsupport.com
COMMENT?=	Secure, fast and powerful IMAP and POP3 server (of azsupport/ports)
WWW=		https://www.dovecot.org/ \
		https://github.com/azsupport/ports

LICENSE=	LGPL21 MIT
LICENSE_COMB=	dual

CONFLICTS_INSTALL=	dovecot-cdb dovecot-ldap dovecot-pgsql dovecot-sqlite dovecot24*
.if ${PKGNAMESUFFIX:U} == "-mysql"
CONFLICTS_INSTALL+=	dovecot
.else
CONFLICTS_INSTALL+=	dovecot-mysql
.endif

# files/cve, in the order of Ubuntu (noble-security 2.3.21+dfsg1-2ubuntu6.5), then
# of RHEL (10, dovecot-2.3.21-22.el10_3), before the patches of the port, the source
# at the top of each: CVE-2022-30550, never taken into the branch 2.3; CVE-2026-73208,
# RHEL's three of the code in one patch on 2.3.21.1, without its tests; CVE-2025-59031
# (decode2text.sh removed) by the script not installed (post-install); the fixes of
# Pigeonhole (not in this port) not taken
DOVECOT_CVE_PATCHES=	01-CVE-2022-30550 02-CVE-2026-0394-1 03-CVE-2026-0394-2 \
			04-CVE-2026-27855-1 05-CVE-2026-27855-2 06-CVE-2026-27855-3 \
			07-CVE-2026-27855-4 08-CVE-2026-27856-1 09-CVE-2026-27856-2 \
			10-CVE-2026-27856-3 11-CVE-2026-27857-2 12-CVE-2026-27857-3 \
			13-CVE-2026-27857-4 14-CVE-2026-27857-5 15-CVE-2026-27859 \
			16-CVE-2026-33603 17-CVE-2026-40020-pre1 18-CVE-2026-40020 \
			19-CVE-2026-42006 20-CVE-2026-33263 21-CVE-2026-27852-1 \
			22-CVE-2026-27852-2 23-CVE-2026-27852-3 24-CVE-2026-27852-4 \
			25-CVE-2026-27852-5 26-CVE-2026-73208 27-CVE-2026-42391 \
			28-CVE-2026-40018
EXTRA_PATCHES=	${DOVECOT_CVE_PATCHES:@p@${FILESDIR}/cve/${p}.patch:-p1@}

# zstd of az, with its run path: its headers and library alone in a directory of the
# work (the pkg-config check of configure takes ZSTD_CFLAGS and ZSTD_LIBS, the
# checks of zstd_errors.h and of ZSTD_getErrorCode CPPFLAGS and LDFLAGS)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libzstd.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libzstd.so:az/az
CONFIGURE_ENV=	ZSTD_CFLAGS="-I${WRKDIR}/az" \
		ZSTD_LIBS="-L${WRKDIR}/az/lib -lzstd"

USES=		cpe iconv libtool pkgconfig ssl
USE_LDCONFIG=	${PREFIX}/lib/${PORTNAME}
USE_RC_SUBR=	${PORTNAME}

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--localstatedir=/var \
		--with-docs \
		--with-ssl=openssl \
		--with-statedir=/var/db/${PORTNAME} \
		--with-shadow=no \
		--with-systemd=no \
		--with-zstd

INSTALL_TARGET=	install-strip

CPPFLAGS+=	-I${WRKDIR}/az -I${LOCALBASE}/include -I${OPENSSLINC}
LDFLAGS+=	-L${WRKDIR}/az/lib -L${LOCALBASE}/lib -L${OPENSSLLIB} \
		-Wl,-rpath,${AZ_PREFIX}/lib

SUB_FILES+=	pkg-message
SUB_LIST+=	REQUIRE="${_REQUIRE}"
# Default requirement for dovecot rc script
_REQUIRE=	LOGIN

USERS=		${PORTNAME} dovenull
GROUPS=		${USERS}

DOCS=		AUTHORS COPYING INSTALL NEWS TODO README
PORTDOCS=	*
PORTEXAMPLES=	*

OPTIONS_DEFINE=		LIBSODIUM LIBUNWIND LIBWRAP LUA LZ4 DOCS EXAMPLES
OPTIONS_DEFAULT=	GSSAPI_NONE

OPTIONS_GROUP=		DB FTS
OPTIONS_GROUP_DB=	CDB LDAP MYSQL PGSQL SQLITE
OPTIONS_GROUP_FTS=	ICU LUCENE SOLR TEXTCAT

OPTIONS_SINGLE=		GSSAPI
OPTIONS_SINGLE_GSSAPI=	GSSAPI_BASE GSSAPI_HEIMDAL GSSAPI_MIT GSSAPI_NONE

OPTIONS_SUB=		yes

CDB_DESC=		CDB database support
DB_DESC=		Database support
FTS_DESC=		Full text search plugins
GSSAPI_BASE_DESC=	Use GSSAPI from base
GSSAPI_HEIMDAL_DESC=	Use Heimdal GSSAPI from security/heimdal
GSSAPI_MIT_DESC=	Use MIT GSSAPI from security/krb5
GSSAPI_NONE_DESC=	Build without GSSAPI support
ICU_DESC=		Use libicu for FTS unicode normalization
LIBSODIUM_DESC=		Support libsodium based crypts (ARGON2I/ARGON2ID)
LIBUNWIND_DESC=		Get backtraces using libunwind
LUCENE_DESC=		CLucene FTS support
SOLR_DESC=		Solr FTS support
TEXTCAT_DESC=		Libexttextcat FTS support

CDB_LIB_DEPENDS=		libcdb.so:databases/tinycdb
CDB_CONFIGURE_WITH=		cdb

GSSAPI_BASE_USES=		gssapi
GSSAPI_HEIMDAL_USES=		gssapi:heimdal
GSSAPI_MIT_USES=		gssapi:mit
GSSAPI_NONE_CONFIGURE_ON=	--without-gssapi
GSSAPI_NONE_CONFIGURE_OFF=	--with-gssapi ${GSSAPI_CONFIGURE_ARGS}

ICU_LIB_DEPENDS=		libicui18n.so:devel/icu \
				libicuuc.so:devel/icu
ICU_CONFIGURE_WITH=		icu
ICU_LDFLAGS=			-licuuc

LDAP_USES=			ldap
LDAP_CONFIGURE_WITH=		ldap
LDAP_VARS=			_REQUIRE+=slapd

LIBSODIUM_LIB_DEPENDS=		libsodium.so:security/libsodium
LIBSODIUM_CONFIGURE_WITH=	sodium

LIBUNWIND_LIB_DEPENDS=		libunwind.so:devel/libunwind
LIBUNWIND_CONFIGURE_ON=		--with-libunwind=yes
LIBUNWIND_CONFIGURE_OFF=	--with-libunwind=no

LIBWRAP_CONFIGURE_WITH=		libwrap

LUA_USES=			lua:51,53
LUA_CONFIGURE_WITH=		lua

LUCENE_LIB_DEPENDS=		libclucene-core.so:textproc/clucene
LUCENE_CONFIGURE_WITH=		lucene stemmer

LZ4_LIB_DEPENDS=		liblz4.so:archivers/liblz4
LZ4_CONFIGURE_WITH=		lz4

.if ${PKGNAMESUFFIX:U} == "-mysql"
OPTIONS_SLAVE=		MYSQL
.endif

MYSQL_USES=			mysql
MYSQL_CONFIGURE_WITH=		mysql
MYSQL_VARS=			_REQUIRE+=mysql

PGSQL_USES=			pgsql
PGSQL_CONFIGURE_WITH=		pgsql
PGSQL_VARS=			_REQUIRE+=postgresql

SOLR_LIB_DEPENDS=		libcurl.so:ftp/curl \
				libexpat.so:textproc/expat2
SOLR_CONFIGURE_WITH=		solr

SQLITE_USES=			sqlite
SQLITE_CONFIGURE_WITH=		sqlite

TEXTCAT_LIB_DEPENDS=		libexttextcat-2.0.so:textproc/libexttextcat
TEXTCAT_CONFIGURE_WITH=		textcat

pre-configure:
	@${MKDIR} ${WRKDIR}/az/lib
	@${LN} -sf ${AZ_PREFIX}/include/zstd.h ${AZ_PREFIX}/include/zstd_errors.h ${WRKDIR}/az/
	@${LN} -sf ${AZ_PREFIX}/lib/libzstd.so ${WRKDIR}/az/lib/

post-patch:
	@${REINPLACE_CMD} -e 's,/etc/dovecot,${ETCDIR},g; \
		s,sysconfdir=/etc,sysconfdir=${PREFIX}/etc,g' \
		${WRKSRC}/doc/example-config/*.conf ${WRKSRC}/doc/example-config/conf.d/* \
		${WRKSRC}/doc/example-config/*.conf.ext
	@${REINPLACE_CMD} -e '/^LIBS =/s/$$/ @LTLIBICONV@/' \
		${WRKSRC}/src/lib-mail/Makefile.in
# Install the sample config files into ETCDIR/example-config/
	@${REINPLACE_CMD} -e '/^exampledir =/s|\$$(docdir)|${ETCDIR}|' \
		${WRKSRC}/doc/example-config/Makefile.in \
		${WRKSRC}/doc/example-config/conf.d/Makefile.in

post-patch-LUA-on:
	@${REINPLACE_CMD} -e '/^libdovecot_lua_la_DEPENDENCIES =/ s|LUA_LIBS|true|' \
		${WRKSRC}/src/lib-lua/Makefile.in

post-install:
	@${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	${MV} ${STAGEDIR}${DOCSDIR}/dovecot-openssl.cnf ${STAGEDIR}${EXAMPLESDIR}
	${MV} ${STAGEDIR}${DOCSDIR}/mkcert.sh ${STAGEDIR}${EXAMPLESDIR}
	${RM} ${STAGEDIR}${PREFIX}/libexec/${PORTNAME}/decode2text.sh

post-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	(cd ${WRKSRC} && ${INSTALL_DATA} ${DOCS} ${STAGEDIR}${DOCSDIR})

.include <bsd.port.mk>
