# www/aria2: the aria2 of azsupport/ports in the place of the official www/aria2
# (aZ, 15.11.2026): the official port (its rc.d script, pkg-plist, pkg-descr) with
# LIBXML2 of its default, without STATIC, NLS and the docs (aZ, 15.11.2026: we keep
# all its dependencies), with CARES (asynchronous DNS), and without LIBUV, SQLITE and
# SSH2 (aZ, 17.11.2026: the event poll is kqueue anyway; the cookies of Firefox and
# Chromium and SFTP are not needed, and each is more code that can be vulnerable;
# on 15.11.2026 LIBUV and SSH2 were on): libxml2 (Metalink, XML-RPC) and c-ares the
# shared libraries of azsupport with the run path /usr/local/azsupport/lib (our ports link each
# other's shared libraries: aZ, 10.11.2026), given to configure by their FOO_CFLAGS
# and FOO_LIBS (no pkg-config, no other header of azsupport seen); expat, libuv, SQLite and
# libssh2 of azsupport for the options off; OpenSSL and zlib of the base system (the
# official one takes libxml2 and sqlite3 of the ports). With the fix of openSUSE for
# IOFile::getLine() (files/patch-src_IOFile.cc; aZ, 16.11.2026).

PORTNAME=	aria2
PORTVERSION=	1.37.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://github.com/aria2/aria2/releases/download/release-${PORTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT=	Yet another download tool (of azsupport/ports)
WWW=		https://aria2.github.io/ \
		https://github.com/aria2/aria2 \
		https://github.com/azsupport/ports

LICENSE=	GPLv2
LICENSE_FILE=	${WRKSRC}/COPYING

USES=		compiler:c++11-lang cpe libtool pkgconfig ssl tar:xz

CONFIGURE_ARGS=	--disable-epoll \
		--enable-bittorrent \
		--enable-libaria2 \
		--enable-metalink \
		--enable-shared \
		--enable-ssl \
		--enable-threads=posix \
		--enable-websocket \
		--with-disk-cache=${ARIA2_DISK_CACHE} \
		--with-libz \
		--with-openssl \
		--without-appletls \
		--without-gnutls \
		--without-libgcrypt \
		--without-libgmp \
		--without-libnettle
CONFIGURE_ENV=	OPENSSL_CFLAGS=-I${OPENSSLINC} \
		OPENSSL_LIBS="-L${OPENSSLLIB} -lcrypto -lssl" \
		ac_cv_path_RST2HTML=no
GNU_CONFIGURE=	yes
# the libraries of azsupport with their run path
LDFLAGS+=	-Wl,-rpath,${AZSUPPORT_PREFIX}/lib
INSTALL_TARGET=	install-strip
USE_CXXSTD=	c++11
USE_LDCONFIG=	yes
USE_RC_SUBR=	aria2
# www/aria2-ssh2 is this port with SSH2 (aZ, 19.11.2026): one of the two
CONFLICTS_INSTALL?=	aria2-ssh2

PORTDOCS=	*

ARIA2_DISK_CACHE?=	16M

CPE_VENDOR=	aria2_project

OPTIONS_DEFINE=	CARES DOCS LIBUV NLS SQLITE SSH2 STATIC
OPTIONS_SINGLE=	XML
OPTIONS_SINGLE_XML=	EXPAT LIBXML2
OPTIONS_DEFAULT=CARES LIBXML2
OPTIONS_EXCLUDE=NLS STATIC
OPTIONS_SUB=	yes
LIBUV_DESC=	Event polling via libuv
SSH2_DESC=	SSH2 protocol support

CARES_CONFIGURE_WITH=	libcares
EXPAT_CONFIGURE_WITH=	libexpat
LIBUV_CONFIGURE_WITH=	libuv
LIBXML2_CONFIGURE_WITH=	libxml2
LIBXML2_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libxml2.so:azsupport/azsupport
LIBXML2_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libxml2.so:azsupport/azsupport
LIBXML2_CONFIGURE_ENV=	LIBXML2_CFLAGS="-I${AZSUPPORT_PREFIX}/include/libxml2" \
			LIBXML2_LIBS="-L${AZSUPPORT_PREFIX}/lib -lxml2"
NLS_CONFIGURE_OFF=	--disable-nls --without-libintl-prefix
NLS_CONFIGURE_ON=	--with-libintl-prefix=${LOCALBASE}
NLS_LDFLAGS=		-lintl
NLS_USES=		gettext localbase
SQLITE_CONFIGURE_WITH=	sqlite3
SSH2_CONFIGURE_WITH=	libssh2
STATIC_CONFIGURE_ENABLE=static

# c-ares, expat, libuv, SQLite and libssh2 of azsupport: their headers alone in a
# directory of the work
CARES_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libcares.so:azsupport/azsupport
CARES_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libcares.so:azsupport/azsupport
CARES_CONFIGURE_ENV=	LIBCARES_CFLAGS="-I${WRKDIR}/azsupport" \
			LIBCARES_LIBS="-L${AZSUPPORT_PREFIX}/lib -lcares"
EXPAT_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libexpat.so:azsupport/azsupport
EXPAT_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libexpat.so:azsupport/azsupport
EXPAT_CONFIGURE_ENV=	EXPAT_CFLAGS="-I${WRKDIR}/azsupport" \
			EXPAT_LIBS="-L${AZSUPPORT_PREFIX}/lib -lexpat"
LIBUV_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libuv.so:azsupport/azsupport
LIBUV_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libuv.so:azsupport/azsupport
LIBUV_CONFIGURE_ENV=	LIBUV_CFLAGS="-I${WRKDIR}/azsupport" \
			LIBUV_LIBS="-L${AZSUPPORT_PREFIX}/lib -luv"
SQLITE_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libsqlite3.so:azsupport/azsupport
SQLITE_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libsqlite3.so:azsupport/azsupport
SQLITE_CONFIGURE_ENV=	SQLITE3_CFLAGS="-I${WRKDIR}/azsupport" \
			SQLITE3_LIBS="-L${AZSUPPORT_PREFIX}/lib -lsqlite3"
SSH2_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libssh2.so:azsupport/azsupport
SSH2_RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libssh2.so:azsupport/azsupport
SSH2_CONFIGURE_ENV=	LIBSSH2_CFLAGS="-I${WRKDIR}/azsupport" \
			LIBSSH2_LIBS="-L${AZSUPPORT_PREFIX}/lib -lssh2"

pre-configure-CARES-on:
	@${MKDIR} ${WRKDIR}/azsupport
	cd ${AZSUPPORT_PREFIX}/include && ${LN} -sf ${AZSUPPORT_PREFIX}/include/ares*.h ${WRKDIR}/azsupport/

pre-configure-EXPAT-on:
	@${MKDIR} ${WRKDIR}/azsupport
	cd ${AZSUPPORT_PREFIX}/include && ${LN} -sf ${AZSUPPORT_PREFIX}/include/expat*.h ${WRKDIR}/azsupport/

pre-configure-LIBUV-on:
	@${MKDIR} ${WRKDIR}/azsupport
	cd ${AZSUPPORT_PREFIX}/include && ${LN} -sf ${AZSUPPORT_PREFIX}/include/uv.h ${AZSUPPORT_PREFIX}/include/uv ${WRKDIR}/azsupport/

pre-configure-SQLITE-on:
	@${MKDIR} ${WRKDIR}/azsupport
	cd ${AZSUPPORT_PREFIX}/include && ${LN} -sf ${AZSUPPORT_PREFIX}/include/sqlite3.h ${AZSUPPORT_PREFIX}/include/sqlite3ext.h ${WRKDIR}/azsupport/

pre-configure-SSH2-on:
	@${MKDIR} ${WRKDIR}/azsupport
	cd ${AZSUPPORT_PREFIX}/include && ${LN} -sf ${AZSUPPORT_PREFIX}/include/libssh2*.h ${WRKDIR}/azsupport/

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/bash_completion.d/
	${INSTALL_DATA} ${WRKSRC}/doc/bash_completion/aria2c ${STAGEDIR}${PREFIX}/etc/bash_completion.d/

.include <bsd.port.mk>
