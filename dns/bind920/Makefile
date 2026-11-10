# dns/bind920: BIND 9.20 of azsupport/ports, the DNS server named with rndc,
# named-checkconf and the other programs of the server, in the place of the
# official dns/bind920 (aZ, 10.11.2026), and, as in the official tree, the master
# of dns/bind-tools (BIND_TOOLS_SLAVE: delv, dig, host, nslookup, nsupdate, mdig
# and the DNSSEC tools), which named needs. aZ's options (10.11.2026):
# TCP_FASTOPEN, IDN (libidn2) and no GSSAPI; DNSTAP, LMDB, STATS_JSON and
# STATS_XML, on in the official one, off. The libraries of our ports, as shared
# ones (aZ, 10.11.2026: our ports link each other's shared libraries): libuv,
# liburcu, nghttp2 (DNS over HTTPS) and libidn2 of az, with the run path
# /usr/local/az/lib, and by their options libxml2 (STATS_XML) and libmaxminddb
# (GEOIP) of az; of the base system OpenSSL, zlib and libedit (the line editing of
# nslookup and nsupdate). The other options take the libraries of the ports, as
# the official one: fstrm and protobuf-c (DNSTAP), lmdb0 (LMDB), json-c
# (STATS_JSON). No manual pages (MANPAGES of the make.conf of the servers, as the
# other packages of this tree) and no headers of the libraries of BIND (nothing
# here builds against them); the rest as the official one: the rc script named,
# /usr/local/etc/namedb with named.conf.sample, the user bind of the base system.

PORTNAME=	bind
DISTVERSION=	9.20.30
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	dns net
MASTER_SITES=	ISC/bind9/${DISTVERSION}
.if defined(BIND_TOOLS_SLAVE)
PKGNAMESUFFIX=	-tools
.else
PKGNAMESUFFIX=	920
.endif

MAINTAINER=	github@azsupport.com
.if defined(BIND_TOOLS_SLAVE)
COMMENT=	Command line tools from BIND: delv, dig, host, nslookup... (of azsupport/ports)
.else
COMMENT=	BIND DNS suite with updated DNSSEC and DNS64 (of azsupport/ports)
.endif
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
.if !defined(BIND_TOOLS_SLAVE)
RUN_DEPENDS+=	bind-tools>0:dns/bind-tools
.endif

USES=		autoreconf compiler:c11 cpe libtool pkgconfig ssl tar:xz

CPE_VENDOR=	isc
CPE_VERSION=	${DISTVERSION:C/-.*//}
.if ${DISTVERSION:M*-*}
CPE_UPDATE=	${DISTVERSION:C/.*-//:tl}
.endif

.if !defined(BIND_TOOLS_SLAVE)
USE_RC_SUBR=	named
.endif

GNU_CONFIGURE=	yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
CONFIGURE_ARGS=	--enable-dnsrps \
		--localstatedir=/var \
		--sysconfdir=${ETCDIR} \
		--with-openssl=${OPENSSLBASE} \
		--with-readline=libedit \
		--disable-tracing
# libuv, liburcu, nghttp2 of az and libedit of the base system by hand, their
# headers alone in directories of the work (pre-configure: the include directory
# of az has others, GNU iconv.h among them; the code includes <editline/readline.h>,
# the base system has edit/readline/readline.h), -L of az, which has no other
# library BIND links; pkg-config only the base system (OpenSSL, zlib), so that
# nothing of /usr/local is taken (lmdb, libxml2, json-c, libmaxminddb: by their
# options below)
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

.if !defined(BIND_TOOLS_SLAVE)
CONFLICTS=	bind9-devel bind918
.endif

ETCDIR=		${PREFIX}/etc/namedb

.if defined(BIND_TOOLS_SLAVE)
EXTRA_PATCHES=		${PATCHDIR}/extrapatch-bind-tools
CONFIGURE_ARGS+=	--libdir=${PREFIX}/lib/bind-tools
.else
SUB_FILES=		named.conf pkg-message
EXTRA_PATCHES=		${PATCHDIR}/extrapatch-no-bind-tools

PORTDOCS=	*
.endif

OPTIONS_DEFINE=		DNSTAP DOCS FIXED_RRSET GEOIP IDN LARGE_FILE LMDB \
			OVERRIDECACHE QUERYTRACE START_LATE TCP_FASTOPEN
# aZ's (10.11.2026); the official ones: DNSTAP GSSAPI_BASE IDN LMDB STATS_JSON
# STATS_XML TCP_FASTOPEN
OPTIONS_DEFAULT=	GSSAPI_NONE IDN TCP_FASTOPEN

OPTIONS_GROUP=		STATS
OPTIONS_GROUP_STATS=	STATS_JSON STATS_XML

OPTIONS_SINGLE=		GSSAPI
OPTIONS_SINGLE_GSSAPI=	GSSAPI_BASE GSSAPI_HEIMDAL GSSAPI_MIT GSSAPI_NONE

.if defined(BIND_TOOLS_SLAVE)
OPTIONS_EXCLUDE=	DOCS GEOIP LMDB OVERRIDECACHE QUERYTRACE START_LATE \
			STATS_JSON STATS_XML TCP_FASTOPEN
.endif

OPTIONS_SUB=	yes

DNSTAP_DESC=		Provides fast passive logging of DNS messages
FIXED_RRSET_DESC=	Enable fixed rrset ordering
GSSAPI_BASE_DESC=	Using MIT in base
GSSAPI_HEIMDAL_DESC=	Using security/heimdal (nsupdate is broken)
GSSAPI_MIT_DESC=	Using security/krb5
GSSAPI_NONE_DESC=	Disable
LARGE_FILE_DESC=	64-bit file support
LMDB_DESC=		Use LMDB for zone management
OVERRIDECACHE_DESC=	Use the override-cache patch
QUERYTRACE_DESC=	Enable the very verbose query tracelogging
START_LATE_DESC=	Start BIND late in the boot process (see help)
STATS_DESC=		Statistics channels
STATS_JSON_DESC=	Enable JSON statistics channel
STATS_XML_DESC=		Enable XML statistics channel
TCP_FASTOPEN_DESC=	RFC 7413 support

# DNSTAP: fstrm and protobuf-c of the ports, through their pkg-config files
DNSTAP_LIB_DEPENDS=		libfstrm.so:devel/fstrm \
				libprotobuf-c.so:devel/protobuf-c
DNSTAP_CONFIGURE_ENABLE=	dnstap
DNSTAP_CONFIGURE_ENV=		PKG_CONFIG_LIBDIR=${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig

DOCS_BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}sphinx_rtd_theme>0:textproc/py-sphinx_rtd_theme@${PY_FLAVOR} \
			sphinx-build:textproc/py-sphinx
DOCS_USES=		gmake python:env
DOCS_ALL_TARGET=	all html

FIXED_RRSET_CONFIGURE_ENABLE=	fixed-rrset

# GEOIP: libmaxminddb of az, its two headers alone in a directory of the work; the
# GeoIP databases where net/geoipupdate puts them (MAXMINDDB_PREFIX/share/GeoIP)
GEOIP_BUILD_DEPENDS=		${AZ_PREFIX}/lib/libmaxminddb.so:az/az
GEOIP_RUN_DEPENDS=		${AZ_PREFIX}/lib/libmaxminddb.so:az/az
GEOIP_CONFIGURE_ENABLE=		geoip
GEOIP_CONFIGURE_WITH=		maxminddb
GEOIP_CONFIGURE_ENV=		MAXMINDDB_CFLAGS="-I${WRKDIR}/mmdb" \
				MAXMINDDB_LIBS="-L${AZ_PREFIX}/lib -lmaxminddb" \
				MAXMINDDB_PREFIX="${LOCALBASE}"

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

LMDB_LIB_DEPENDS=	liblmdb0.so:databases/lmdb0
LMDB_CONFIGURE_WITH=	lmdb=${LOCALBASE}/lmdb0

OVERRIDECACHE_EXTRA_PATCHES=	${FILESDIR}/extrapatch-bind-min-override-ttl

QUERYTRACE_CONFIGURE_ENABLE=	querytrace

START_LATE_SUB_LIST=		NAMED_BEFORE="LOGIN" \
				NAMED_REQUIRE="SERVERS cleanvar"
START_LATE_SUB_LIST_OFF=	NAMED_BEFORE="SERVERS" \
				NAMED_REQUIRE="NETWORKING ldconfig syslogd"

# STATS_JSON: json-c of the ports (<json_object.h>: its include directory has only
# its headers), libjson-c.so alone in a directory of the work
STATS_JSON_LIB_DEPENDS=		libjson-c.so:devel/json-c
STATS_JSON_CONFIGURE_WITH=	json-c
STATS_JSON_CONFIGURE_ENV=	JSON_C_CFLAGS="-I${LOCALBASE}/include/json-c" \
				JSON_C_LIBS="-L${WRKDIR}/json-c -ljson-c"

# STATS_XML: libxml2 of az (<libxml/...>: its include/libxml2 has only libxml)
STATS_XML_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libxml2.so:az/az
STATS_XML_RUN_DEPENDS=		${AZ_PREFIX}/lib/libxml2.so:az/az
STATS_XML_CONFIGURE_WITH=	libxml2
STATS_XML_CONFIGURE_ENV=	LIBXML2_CFLAGS="-I${AZ_PREFIX}/include/libxml2" \
				LIBXML2_LIBS="-L${AZ_PREFIX}/lib -lxml2"

TCP_FASTOPEN_CONFIGURE_ENABLE=	tcp-fastopen

.include <bsd.port.options.mk>

.if !${PORT_OPTIONS:MDOCS}
CONFIGURE_ENV+=	ac_cv_path_SPHINX_BUILD=
.endif

.if ${OSREL:R} >= 15 && ${PORT_OPTIONS:MGSSAPI_HEIMDAL}
BROKEN=		Does not build
.endif

.include <bsd.port.pre.mk>

.if ${SSL_DEFAULT} == base
SUB_LIST+=	ENGINES=/usr/lib/engines
.else
SUB_LIST+=	ENGINES=${LOCALBASE}/lib/engines
.endif

pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/rl ${WRKDIR}/idn2/include ${WRKDIR}/idn2/lib
	@${LN} -sf ${AZ_PREFIX}/include/uv.h ${AZ_PREFIX}/include/uv \
		${AZ_PREFIX}/include/nghttp2 ${AZ_PREFIX}/include/urcu* ${WRKDIR}/az/include/
	@${LN} -sf /usr/include/edit/readline ${WRKDIR}/rl/editline
	@${LN} -sf ${AZ_PREFIX}/include/idn2.h ${WRKDIR}/idn2/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libidn2.so ${WRKDIR}/idn2/lib/

pre-configure-GEOIP-on:
	@${MKDIR} ${WRKDIR}/mmdb
	@${LN} -sf ${AZ_PREFIX}/include/maxminddb.h ${AZ_PREFIX}/include/maxminddb_config.h ${WRKDIR}/mmdb/

pre-configure-STATS_JSON-on:
	@${MKDIR} ${WRKDIR}/json-c
	@${LN} -sf ${LOCALBASE}/lib/libjson-c.so ${WRKDIR}/json-c/

post-patch:
.for FILE in check/named-checkconf.rst named/named.rst nsupdate/nsupdate.rst \
	rndc/rndc.rst
	@${REINPLACE_CMD} -e 's#/etc/named.conf#${ETCDIR}/named.conf#g' \
		-e 's#/etc/rndc.conf#${ETCDIR}/rndc.conf#g' \
		-e "s#/var\/run\/named\/named.pid#/var/run/named/pid#" \
		${WRKSRC}/bin/${FILE}
.endfor

# lib and bin, not doc (the manual pages); the headers of lib/*/include out
do-install:
	for dir in lib bin; do \
		(cd ${INSTALL_WRKSRC}/$$dir && ${SETENV} ${MAKE_ENV} ${FAKEROOT} ${MAKE_CMD} ${MAKE_FLAGS} ${MAKEFILE} ${MAKE_ARGS} ${INSTALL_TARGET}) ; \
	done
	@${RM} -r ${STAGEDIR}${PREFIX}/include

.if !defined(BIND_TOOLS_SLAVE)
post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/mtree
	${MKDIR} ${STAGEDIR}${ETCDIR}
.  for i in dynamic primary secondary working
	@${MKDIR} ${STAGEDIR}${ETCDIR}/$i
.  endfor
	${INSTALL_DATA} ${WRKDIR}/named.conf ${STAGEDIR}${ETCDIR}/named.conf.sample
	${INSTALL_DATA} ${FILESDIR}/named.root ${STAGEDIR}${ETCDIR}
	${INSTALL_DATA} ${FILESDIR}/empty.db ${STAGEDIR}${ETCDIR}/primary
	${INSTALL_DATA} ${FILESDIR}/localhost-forward.db ${STAGEDIR}${ETCDIR}/primary
	${INSTALL_DATA} ${FILESDIR}/localhost-reverse.db ${STAGEDIR}${ETCDIR}/primary
	${INSTALL_DATA} ${FILESDIR}/BIND.chroot.dist ${STAGEDIR}${PREFIX}/etc/mtree/BIND.chroot.dist.sample
	${INSTALL_DATA} ${FILESDIR}/BIND.chroot.local.dist ${STAGEDIR}${PREFIX}/etc/mtree/BIND.chroot.local.dist.sample
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/*.so ${STAGEDIR}${PREFIX}/lib/bind/*.so

post-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}/arm
	${INSTALL_DATA} ${WRKSRC}/README.md ${STAGEDIR}${DOCSDIR}
	cd ${WRKSRC}/doc/arm/_build/html && ${COPYTREE_SHARE} . ${STAGEDIR}${DOCSDIR}/arm
.else
post-install:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/bind-tools/*.so
.endif

.include <bsd.port.post.mk>
