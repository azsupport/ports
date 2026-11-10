# dns/bind-tools: the BIND tools of azsupport/ports in the place of the official
# dns/bind-tools (aZ, 10.11.2026): delv, dig, host, nslookup, nsupdate, mdig and the
# DNSSEC tools of BIND 9.20; the official port, a slave of dns/bind920, in one
# port (its BIND_TOOLS_SLAVE part, and the files of dns/bind920 it takes), with
# aZ's options: IDN (libidn2) on, DNSTAP, FIXED_RRSET and LARGE_FILE off, no
# GSSAPI. The libraries of our ports, as shared ones (aZ, 10.11.2026: our ports
# link each other's shared libraries): libuv, liburcu, nghttp2 (DNS over HTTPS)
# and libidn2 of az, with the run path /usr/local/az/lib; of the base system
# OpenSSL, libedit (the line editing of nslookup and nsupdate) and zlib. The
# official one takes libuv, liburcu, libnghttp2, libidn2, libedit (and fstrm,
# protobuf-c with DNSTAP) of the ports. No manual pages (MANPAGES of the make.conf
# of the servers, as the other packages of this tree).

PORTNAME=	bind
DISTVERSION=	9.20.30
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	dns net
MASTER_SITES=	ISC/bind9/${DISTVERSION}
PKGNAMESUFFIX=	-tools

MAINTAINER=	github@azsupport.com
COMMENT=	Command line tools from BIND: delv, dig, host, nslookup... (of azsupport/ports)
WWW=		https://www.isc.org/bind/ \
		https://github.com/azsupport/ports

LICENSE=	MPL20
LICENSE_FILE=	${WRKSRC}/COPYRIGHT

# the libraries of az, to build and to run (no ldconfig hints for /usr/local/az/lib:
# by a file)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libuv.so:az/az \
		${AZ_PREFIX}/lib/liburcu.so:az/az \
		${AZ_PREFIX}/lib/libnghttp2.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libuv.so:az/az \
		${AZ_PREFIX}/lib/liburcu.so:az/az \
		${AZ_PREFIX}/lib/libnghttp2.so:az/az

USES=		autoreconf compiler:c11 cpe libtool pkgconfig ssl tar:xz

CPE_VENDOR=	isc
CPE_VERSION=	${DISTVERSION:C/-.*//}

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--enable-dnsrps \
		--localstatedir=/var \
		--sysconfdir=${ETCDIR} \
		--with-openssl=${OPENSSLBASE} \
		--with-readline=libedit \
		--libdir=${PREFIX}/lib/bind-tools \
		--disable-tracing
# libuv, liburcu, nghttp2 of az and libedit of the base system by hand, their
# headers alone in directories of the work (pre-configure: the include directory
# of az has others, GNU iconv.h among them; the code includes <editline/readline.h>,
# the base system has edit/readline/readline.h), -L of az, which has no other
# library the tools link; pkg-config only the base system (OpenSSL, zlib), so that
# nothing of /usr/local is taken (libxml2, json-c, lmdb, libmaxminddb: off)
CONFIGURE_ENV=	PKG_CONFIG_LIBDIR=/usr/libdata/pkgconfig \
		LIBUV_CFLAGS="-I${WRKDIR}/az/include" \
		LIBUV_LIBS="-L${AZ_PREFIX}/lib -luv" \
		LIBURCU_CFLAGS="-I${WRKDIR}/az/include" \
		LIBURCU_LIBS="-L${AZ_PREFIX}/lib -lurcu -lurcu-cds -lurcu-common" \
		LIBNGHTTP2_CFLAGS="-I${WRKDIR}/az/include" \
		LIBNGHTTP2_LIBS="-L${AZ_PREFIX}/lib -lnghttp2" \
		READLINE_CFLAGS="-I${WRKDIR}/rl" \
		READLINE_LIBS="-ledit"
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

MAKE_JOBS_UNSAFE=	yes

ETCDIR=		${PREFIX}/etc/namedb

EXTRA_PATCHES=	${PATCHDIR}/extrapatch-bind-tools

# the options of the official bind-tools (those of dns/bind920 but its
# OPTIONS_EXCLUDE for the tools), with the defaults of aZ (10.11.2026)
OPTIONS_DEFINE=		DNSTAP FIXED_RRSET IDN LARGE_FILE
OPTIONS_DEFAULT=	GSSAPI_NONE IDN
OPTIONS_SINGLE=		GSSAPI
OPTIONS_SINGLE_GSSAPI=	GSSAPI_BASE GSSAPI_HEIMDAL GSSAPI_MIT GSSAPI_NONE
OPTIONS_SUB=		yes

DNSTAP_DESC=		Provides fast passive logging of DNS messages
FIXED_RRSET_DESC=	Enable fixed rrset ordering
GSSAPI_BASE_DESC=	Using MIT in base
GSSAPI_HEIMDAL_DESC=	Using security/heimdal (nsupdate is broken)
GSSAPI_MIT_DESC=	Using security/krb5
GSSAPI_NONE_DESC=	Disable
LARGE_FILE_DESC=	64-bit file support

# DNSTAP: fstrm and protobuf-c of the ports, through their pkg-config files
DNSTAP_LIB_DEPENDS=		libfstrm.so:devel/fstrm \
				libprotobuf-c.so:devel/protobuf-c
DNSTAP_CONFIGURE_ENABLE=	dnstap
DNSTAP_CONFIGURE_ENV=		PKG_CONFIG_LIBDIR=${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig

FIXED_RRSET_CONFIGURE_ENABLE=	fixed-rrset

GSSAPI_BASE_USES=		gssapi
GSSAPI_BASE_CONFIGURE_ON=	${GSSAPI_CONFIGURE_ARGS} \
				--with-gssapi="${KRB5CONFIG}"
GSSAPI_HEIMDAL_USES=		gssapi:heimdal
GSSAPI_HEIMDAL_CONFIGURE_ON=	${GSSAPI_CONFIGURE_ARGS} \
				--with-gssapi="${KRB5CONFIG}"
GSSAPI_MIT_USES=		gssapi:mit
GSSAPI_MIT_CONFIGURE_ON=	${GSSAPI_CONFIGURE_ARGS} \
				--with-gssapi="${KRB5CONFIG}"
GSSAPI_NONE_CONFIGURE_ON=	--without-gssapi

# libidn2 of az: its idn2.h and libidn2.so alone in a directory of the work
# (--with-libidn2=<path>: -I<path>/include, -L<path>/lib), its run path above
IDN_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libidn2.so:az/az
IDN_RUN_DEPENDS=	${AZ_PREFIX}/lib/libidn2.so:az/az
IDN_CONFIGURE_ON=	--with-libidn2=${WRKDIR}/idn2
IDN_CONFIGURE_OFF=	--without-libidn2

LARGE_FILE_CONFIGURE_ENABLE=	largefile

.include <bsd.port.options.mk>

.if ${OSREL:R} >= 15 && ${PORT_OPTIONS:MGSSAPI_HEIMDAL}
BROKEN=		Does not build
.endif

pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/rl ${WRKDIR}/idn2/include ${WRKDIR}/idn2/lib
	@${LN} -sf ${AZ_PREFIX}/include/uv.h ${AZ_PREFIX}/include/uv \
		${AZ_PREFIX}/include/nghttp2 ${AZ_PREFIX}/include/urcu* ${WRKDIR}/az/include/
	@${LN} -sf /usr/include/edit/readline ${WRKDIR}/rl/editline
	@${LN} -sf ${AZ_PREFIX}/include/idn2.h ${WRKDIR}/idn2/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libidn2.so ${WRKDIR}/idn2/lib/

do-install:
	for dir in bin lib; do \
		(cd ${INSTALL_WRKSRC}/$$dir && ${SETENV} ${MAKE_ENV} ${FAKEROOT} ${MAKE_CMD} ${MAKE_FLAGS} ${MAKEFILE} ${MAKE_ARGS} ${INSTALL_TARGET}) ; \
	done
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/bind-tools/*.so
	@${RM} -r ${STAGEDIR}${PREFIX}/include

.include <bsd.port.mk>
