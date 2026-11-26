# dns/unbound: Unbound of azsupport/ports in the place of the official dns/unbound
# and of local_unbound of the base system (aZ, 20.11.2026: «давай удалять и делать
# свой unbound порт потому как всё равно трудно в системе его обновлять чем пакет,
# да и он там весь обрезанный и с кривыми стартуп скриптами»; the base system of the
# servers is built WITHOUT_UNBOUND): the official port of the pinned commit (Unbound
# 1.26.2, the newest release) with expat and libevent the shared libraries of azsupport,
# with the run path /usr/local/azsupport/lib (our ports link each other's shared libraries:
# aZ, 10.11.2026), so that it takes no package but azsupport (the official one takes expat2,
# libnghttp2, libevent and libsodium); OpenSSL of the base system. A resolver of the
# server itself (aZ, 20.11.2026 18:20: «а нужны ли EVAPI, GOST? да и DNSCRYPT,
# DYNLIB?»): ECDSA (the DNSSEC algorithms 13 and 14), LIBEVENT (kqueue, large
# outgoing ranges), THREADS and TFOCL, TFOSE (TCP Fast Open, as TCP_FASTOPEN of our
# dns/bind920) on; off: DNSCRYPT (DNSCrypt to clients, libsodium), DYNLIB (modules of
# other libraries), EVAPI (the event API of libunbound for programs that embed it),
# GOST (GOST R 34.10-2001 of DNSSEC, RFC 8624: not to be used; the OpenSSL of the
# base system has no GOST), and as in the official one DEP-RSA1024, DNSTAP,
# FILTER_AAAA, HIREDIS, MUNIN_PLUGIN, PYTHON, SUBNET; no DNS over HTTPS for clients
# (nghttp2, always on in the official port); no DOCS and no manual pages (the
# make.conf of the servers). The rest as the official port: the rc.d
# script unbound (unbound_enable, profiles, unbound-anchor before the start), the
# user unbound, /usr/local/etc/unbound with unbound.conf.sample.

PORTNAME=	unbound
DISTVERSION=	1.26.2
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	dns
MASTER_SITES=	https://www.nlnetlabs.nl/downloads/unbound/

MAINTAINER=	github@azsupport.com
COMMENT=	Validating, recursive, and caching DNS resolver (of azsupport/ports)
WWW=		https://www.nlnetlabs.nl/projects/unbound \
		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

# expat of azsupport (unbound-anchor): configure takes its header and library under the
# path of --with-libexpat
BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libexpat.so:azsupport/expat
RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libexpat.so:azsupport/expat

USES=		autoreconf cpe libtool pkgconfig ssl
CPE_VENDOR=	nlnetlabs
USE_LDCONFIG=	yes
USE_RC_SUBR=	${PORTNAME}

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--with-libexpat=${AZSUPPORT_PREFIX} \
		--without-libnghttp2 \
		--with-ssl=${OPENSSLBASE}
LDFLAGS+=	-Wl,-rpath,${AZSUPPORT_PREFIX}/lib
TEST_TARGET=	test

USERS=		${PORTNAME}
GROUPS=		${PORTNAME}

PORTDOCS=	CNAME-basedRedirectionDesignNotes.pdf CREDITS Changelog \
		FEATURES IP-BasedActions.pdf LICENSE README README.DNS64 \
		README.ipset.md README.svn README.tests TODO \
		control_proto_spec.txt example.conf ietf67-design-02.odp \
		ietf67-design-02.pdf requirements.txt

OPTIONS_DEFINE=		DEP-RSA1024 DNSCRYPT DNSTAP DOCS DYNLIB ECDSA EVAPI \
			FILTER_AAAA GOST HIREDIS LIBEVENT MUNIN_PLUGIN PYTHON \
			SUBNET TFOCL TFOSE THREADS
OPTIONS_DEFAULT=	ECDSA LIBEVENT TFOCL TFOSE THREADS
OPTIONS_SUB=		yes

DEP-RSA1024_DESC=	Deprecate the use of RSA 1024 keys
DNSCRYPT_DESC=		Enable dnscrypt support
DNSTAP_DESC=		Enable dnstap logging support
DYNLIB_DESC=		Enable support for dynamic (shared) 3rd-party libraries
ECDSA_DESC=		Enable ECDSA (elliptic curve) support (OpenSSL >= 1.0)
EVAPI_DESC=		Pluggable event based libunbound API support
FILTER_AAAA_DESC=	Build with AAAA filter functionality (contrib)
GOST_DESC=		Enable GOST support (requires OpenSSL >= 1.0)
HIREDIS_DESC=		Enable hiredis support for the cachedb module
LIBEVENT_DESC=		Build against libevent
MUNIN_PLUGIN_DESC=	Install Munin plugin
SUBNET_DESC=		Enable client subnet support
TFOCL_DESC=		Enable TCP Fast Open for client mode
TFOSE_DESC=		Enable TCP Fast Open for server mode

# the library itself, not its link .libs/libunbound.so: strip writes a stripped copy in
# the place of a link, and libtool installs the file the link points to
STRIP_FILES=	.libs/libunbound.so.8.1.41 unbound-checkconf unbound unbound-control \
		.libs/unbound-host .libs/unbound-anchor

DEP-RSA1024_CONFIGURE_ON=	--with-deprecate-rsa-1024
DNSCRYPT_BUILD_DEPENDS=		${AZSUPPORT_PREFIX}/lib/libsodium.so:azsupport/libsodium
DNSCRYPT_RUN_DEPENDS=		${AZSUPPORT_PREFIX}/lib/libsodium.so:azsupport/libsodium
DNSCRYPT_CONFIGURE_ENABLE=	dnscrypt
DNSCRYPT_CONFIGURE_ON=		--with-libsodium=${AZSUPPORT_PREFIX}
DNSTAP_LIB_DEPENDS=		libfstrm.so:devel/fstrm \
				libprotobuf-c.so:devel/protobuf-c
DNSTAP_CONFIGURE_ENABLE=	dnstap
DYNLIB_CONFIGURE_ON=		--with-dynlibmodule
ECDSA_CONFIGURE_ENABLE=		ecdsa
ECDSA_VARS=			DEPENDS_ARGS+=WITH_ECDSA=yes
EVAPI_CONFIGURE_ENABLE=		event-api
GOST_CONFIGURE_ENABLE=		gost
GOST_VARS=			DEPENDS_ARGS+=WITH_GOST=yes
HIREDIS_LIB_DEPENDS=		libhiredis.so:databases/hiredis
HIREDIS_CONFIGURE_ON=		--enable-cachedb \
				--with-libhiredis
LIBEVENT_BUILD_DEPENDS=		${AZSUPPORT_PREFIX}/lib/libevent.so:azsupport/libevent
LIBEVENT_RUN_DEPENDS=		${AZSUPPORT_PREFIX}/lib/libevent.so:azsupport/libevent
LIBEVENT_CONFIGURE_ON=		--with-libevent=${AZSUPPORT_PREFIX}
LIBEVENT_CONFIGURE_OFF=		--without-libevent
MUNIN_PLUGIN_SUB_FILES=		pkg-message
PYTHON_BUILD_DEPENDS=		swig:devel/swig
PYTHON_USES=			python
PYTHON_CONFIGURE_ON=		--with-pythonmodule=yes \
				--with-pyunbound=yes \
				ac_cv_path_SWIG=${LOCALBASE}/bin/swig \
				LDFLAGS="-L${LOCALBASE}/lib"
PYTHON_VARS=			STRIP_FILES+=.libs/_unbound.so
SUBNET_CONFIGURE_ENABLE=	subnet
TFOCL_CONFIGURE_ENABLE=		tfo-client
TFOSE_CONFIGURE_ENABLE=		tfo-server
THREADS_CONFIGURE_WITH=		pthreads

post-patch:
	@${RM} ${WRKSRC}/util/configlexer.c
	@${REINPLACE_CMD} -e 's|if test ! -e "$$(DESTDIR)$$(configfile)"; then || ; \
		s|$$(configfile)"; fi|$$(configfile).sample"|' \
		${WRKSRC}/Makefile.in

post-patch-FILTER_AAAA-on:
	@${CAT} ${WRKSRC}/contrib/aaaa-filter-iterator.patch | \
		${PATCH} -d ${WRKSRC} -p1 -s

post-build:
	${STRIP_CMD} ${STRIP_FILES:S|^|${WRKSRC}/|}

post-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${PORTDOCS:S|^|${WRKSRC}/doc/|} \
		${STAGEDIR}${DOCSDIR}

post-install-MUNIN_PLUGIN-on:
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/munin/plugins
	${INSTALL_SCRIPT} ${WRKDIR}/unbound-${DISTVERSION}/contrib/unbound_munin_ \
		${STAGEDIR}${PREFIX}/share/munin/plugins/
	@${ECHO_MSG}
	@${ECHO_MSG} "============================================================="
	@${CAT} ${WRKDIR}/pkg-message
	@${ECHO_MSG} "============================================================="

post-install-PYTHON-on:
	@${STRIP_CMD} ${STAGEDIR}${PYTHON_SITELIBDIR}/_unbound.so

.include <bsd.port.mk>
