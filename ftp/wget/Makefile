# ftp/wget: the wget of azsupport/ports in the place of the official ftp/wget (aZ,
# 10.11.2026): the official port with IPv6, IRI and the OpenSSL of the base system,
# IDN (libidn2) and PSL (libpsl) the shared libraries of az (those of curl, with
# the run path /usr/local/az/lib), and PCRE2 the shared library of devel/pcre2 of
# this tree: our ports link each other's shared libraries (aZ, 10.11.2026), so that
# it takes no package but az and pcre2 (the official one takes libidn2 and
# libunistring, libpsl, pcre2). The unistring of IRI is the one wget bundles
# (--with-included-libunistring); iconv that of libc. Without
# NLS, NTLM, Metalink, the man page (MANPAGES of the make.conf of the servers) and
# the info page.

PORTNAME=	wget
DISTVERSION=	1.25.0
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	ftp www
MASTER_SITES=	GNU

MAINTAINER=	github@azsupport.com
COMMENT=	Retrieve files from the Net via HTTP(S) and FTP (of azsupport/ports)
WWW=		https://www.gnu.org/s/wget/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv3+
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libidn2.so:az/az \
		${AZ_PREFIX}/lib/libpsl.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libidn2.so:az/az \
		${AZ_PREFIX}/lib/libpsl.so:az/az
LIB_DEPENDS=	libpcre2-8.so:devel/pcre2

USES=		charsetfix cpe iconv pkgconfig ssl tar:lz
CPE_VENDOR=	gnu
USE_CSTD=	c99

GNU_CONFIGURE=	yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
# pkg-config of the shared tree of az (its .pc files and those of the base
# system: zlib, OpenSSL; nothing of /usr/local); libidn2 and libpsl of az by hand:
# idn2.h and libpsl.h alone in a directory of the work (pre-configure: the
# include directory of az has GNU iconv.h, which would take wget's iconv from the
# libiconv of az), -lidn2 and -lpsl from the -L of az, which has no other library
# wget links, its run path in LDFLAGS; PCRE2 of devel/pcre2 by hand too: pcre2.h
# alone in a directory of the work (no other header of /usr/local),
# libpcre2-8.so by its path (no -L/usr/local/lib for the others); OpenSSL of the
# base system (--with-libssl-prefix)
CONFIGURE_ARGS=	--with-ssl=openssl \
		--with-libssl-prefix=${OPENSSLBASE} \
		--enable-ipv6 \
		--enable-iri \
		--with-included-libunistring \
		--with-libpsl \
		--enable-pcre2 \
		--disable-pcre \
		--disable-nls \
		--disable-ntlm \
		--without-metalink \
		--without-libuuid
CONFIGURE_ENV=	PKG_CONFIG="${AZ_PREFIX}/bin/pkg-config" \
		LIBIDN2_CFLAGS="-I${WRKDIR}/az" \
		LIBIDN2_LIBS="-L${AZ_PREFIX}/lib -lidn2" \
		LIBPSL_CFLAGS="-I${WRKDIR}/az" \
		LIBPSL_LIBS="-L${AZ_PREFIX}/lib -lpsl" \
		PCRE2_CFLAGS="-I${WRKDIR}/pcre2" \
		PCRE2_LIBS="${LOCALBASE}/lib/libpcre2-8.so" \
		ac_cv_path_POD2MAN=no
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

PLIST_FILES=	bin/wget \
		"@sample etc/wgetrc.sample"

pre-configure:
	@${MKDIR} ${WRKDIR}/pcre2 ${WRKDIR}/az
	@${LN} -sf ${LOCALBASE}/include/pcre2.h ${WRKDIR}/pcre2/pcre2.h
	@${LN} -sf ${AZ_PREFIX}/include/idn2.h ${AZ_PREFIX}/include/libpsl.h ${WRKDIR}/az/

post-patch:
	${REINPLACE_CMD} -e 's,WGETRC = $$(sysconfdir)/wgetrc,&.sample,' \
		${WRKSRC}/doc/Makefile.in
	${REINPLACE_CMD} -e 's,/usr/local/etc/wgetrc,${PREFIX}/etc/wgetrc,' \
		${WRKSRC}/doc/sample.wgetrc* \
		${WRKSRC}/doc/wget.texi
	${REINPLACE_CMD} \
		-e '/^all: wget.info/ s,wget.info,,' \
		-e '/^all-am:/ s, $$(INFO_DEPS),,' \
		-e '/^install-data-am:/ s, install-info-am,,' \
		${WRKSRC}/doc/Makefile.in

.include <bsd.port.mk>
