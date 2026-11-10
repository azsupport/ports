# ftp/wget: the wget of azsupport/ports in the place of the official ftp/wget (aZ,
# 10.11.2026): the official port with IPv6, IRI and the OpenSSL of the base system,
# and IDN (libidn2), PSL (libpsl) and PCRE2 from the static tree of az (those of
# curl), so that it takes no package (the official one takes libidn2 and
# libunistring, libpsl, pcre2). The
# unistring of IRI is the one wget bundles (--with-included-libunistring). Without
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

BUILD_DEPENDS=	${AZ_STATIC}/lib/libidn2.a:az/az \
		${AZ_STATIC}/lib/libpcre2-8.a:az/az \
		${AZ_STATIC}/lib/libpsl.a:az/az

USES=		charsetfix cpe iconv pkgconfig ssl tar:lz
CPE_VENDOR=	gnu
USE_CSTD=	c99

GNU_CONFIGURE=	yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
# pkg-config of the static tree of az: libidn2, libpsl, pcre2 with their static link
# lines; OpenSSL of the base system (--with-libssl-prefix: not pkg-config)
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
CONFIGURE_ENV=	PKG_CONFIG="${AZ_STATIC}/bin/pkg-config" \
		ac_cv_path_POD2MAN=no
# gnulib of wget and the unistring libidn2.a of az has in it may both define a
# function: the first one is taken
LDFLAGS+=	-Wl,-z,muldefs

PLIST_FILES=	bin/wget \
		"@sample etc/wgetrc.sample"

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
