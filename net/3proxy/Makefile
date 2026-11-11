# net/3proxy of azsupport/ports in the place of the official net/3proxy: 3proxy
# 0.9.9.3 (07.11.2026), the LTS line of upstream (aZ, 11.11.2026), for the fixes of
# its vulnerabilities (RADIUS replies and PTR answers past buffers on the stack, the
# match data of pcre rules shared by connections, StringsPlugin past the lines of
# its string tables ...). The official port has 0.9.5, which upstream no longer
# supports (SECURITY.md: not before 0.9.8). With the two fixes of the 0.9 branch
# after 0.9.9.3 (files/patch-src_pcre.c: a pcre rule without an ACL freed as the
# match data of a connection; files/patch-src_tlspr.c: tlspr past a short
# ServerHello) and users with NT passwords without TLS as in 0.9.5
# (files/patch-src_auth.c, files/patch-src_conf.c).
#
# Built with CMake, as upstream advises (README.md), with the names and paths of the
# official port: the standalone servers without a prefix (-D3PROXY_BINARY_PREFIX=),
# proxy as httppr, the crypt tool mycrypt (and its manual page), the plugins in
# lib/3proxy (their names end in .ld.so now: links by the names of 0.9.5 for the
# configs that load them, StringsPlugin.so, TrafficPlugin.so and pamauth.so; PCRE is
# inside 3proxy since 0.9.7, and a "plugin ... PCREPlugin.so pcre_plugin" line is
# taken as it is), the sample config with the patch of the official port brought up
# to 0.9.9.3, its rc.d script and pkg-descr. More than the official port installs,
# all of them built by upstream: the servers tlspr (by the name in the TLS
# ClientHello) and imapp (0.9.8), FilePlugin and TransparentPlugin. PCRE2 the shared
# library of devel/pcre2 of this tree, PAM (PamAuth) of the base system; without
# TLS (the TLS servers and clients and the MITM inside 3proxy since 0.9.7), as the
# official port: net/3proxy-openssl (PKGNAMESUFFIX -openssl, the same files) has it,
# on the OpenSSL of the base system (aZ, 11.11.2026); no ODBC, no LDAP plugin. Not
# the install of CMake: it puts files in /opt, an rc.d script and a config directory
# of its own. Built with it on Linux: users with CL, CR ($1$, $3$) and NT passwords
# and a pcre rule without an ACL.

PORTNAME=	3proxy
DISTVERSION=	0.9.9.3
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	net
MASTER_SITES=	https://github.com/3proxy/3proxy/releases/download/${DISTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT?=	Proxy servers set (support HTTP(S), FTP, SOCKS, POP3, TCP & UDP) (of azsupport/ports)
WWW=		https://3proxy.org/ \
		https://github.com/azsupport/ports

LICENSE=	APACHE20 BSD3CLAUSE GPLv2+ LGPL21+
LICENSE_COMB=	dual

LIB_DEPENDS=	libpcre2-8.so:devel/pcre2

USES=		cmake cpe pkgconfig
USE_RC_SUBR=	3proxy

CMAKE_ARGS=	-D3PROXY_BINARY_PREFIX= \
		-D3PROXY_USE_WOLFSSL=OFF \
		-D3PROXY_USE_PCRE2=ON \
		-D3PROXY_USE_PAM=ON \
		-D3PROXY_USE_ODBC=OFF

# TLS only in 3proxy-openssl
.if ${PKGNAMESUFFIX:U} == "-openssl"
CMAKE_ARGS+=	-D3PROXY_USE_OPENSSL=ON
USES+=		ssl
CONFLICTS_INSTALL=	3proxy
.else
CMAKE_ARGS+=	-D3PROXY_USE_OPENSSL=OFF
CONFLICTS_INSTALL=	3proxy-openssl
.endif

PLIST_SUB=	3PROXY_LOGDIR=${3PROXY_LOGDIR} \
		PORTNAME=${PORTNAME}

PORTDOCS=	README.md

OPTIONS_DEFINE=	DOCS

3PROXY_LOGDIR=	/var/log/${PORTNAME}
3PROXY_SERVERS=	ftppr imapp pop3p smtpp socks tcppm tlspr udppm
3PROXY_PLUGINS=	FilePlugin PamAuth StringsPlugin TrafficPlugin TransparentPlugin

post-patch:
	@${REINPLACE_CMD} -e 's|%%3PROXY_LOGDIR%%|${3PROXY_LOGDIR}|' ${WRKSRC}/cfg/3proxy.cfg.sample
	@${REINPLACE_CMD} -E -e 's| proxy( ?\(8\))| httppr\1|' -e 's|3proxy_crypt|mycrypt|g' ${WRKSRC}/man/*
	@${REINPLACE_CMD} -E -e 's|([^P] "?)proxy|\1httppr|' ${WRKSRC}/man/proxy.8
	@${REINPLACE_CMD} -E -e 's|#!/.+|#!${PREFIX}/bin/3proxy|' -e 's|/[^ ]+/3proxy\.cfg|${PREFIX}/etc/3proxy.cfg|' \
		-e 's|3proxy\.cfg \(3\)|3proxy.cfg (5)|' ${WRKSRC}/man/3proxy.8

# its CMake finds PCRE2 and PAM QUIET: a build without them stops here, and
# 3proxy-openssl without libssl
post-build:
	@${READELF} -d ${BUILD_WRKSRC}/bin/3proxy | ${GREP} -q 'libpcre2-8' || \
		{ ${ECHO_MSG} "==> 3proxy was built without PCRE2"; ${FALSE}; }
	@${TEST} -f ${BUILD_WRKSRC}/bin/PamAuth.ld.so || \
		{ ${ECHO_MSG} "==> 3proxy was built without PAM (PamAuth.ld.so)"; ${FALSE}; }
.if ${PKGNAMESUFFIX:U} == "-openssl"
	@${READELF} -d ${BUILD_WRKSRC}/bin/3proxy | ${GREP} -q 'libssl' || \
		{ ${ECHO_MSG} "==> 3proxy-openssl was built without TLS"; ${FALSE}; }
.endif

do-install:
	@${MKDIR} ${STAGEDIR}${3PROXY_LOGDIR} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}
	${INSTALL_PROGRAM} ${BUILD_WRKSRC}/bin/3proxy ${BUILD_WRKSRC}/bin/mycrypt ${STAGEDIR}${PREFIX}/bin/
	${INSTALL_PROGRAM} ${BUILD_WRKSRC}/bin/proxy ${STAGEDIR}${PREFIX}/bin/httppr
.for s in ${3PROXY_SERVERS}
	${INSTALL_PROGRAM} ${BUILD_WRKSRC}/bin/${s} ${STAGEDIR}${PREFIX}/bin/
.endfor
.for p in ${3PROXY_PLUGINS}
	${INSTALL_LIB} ${BUILD_WRKSRC}/bin/${p}.ld.so ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/
.endfor
	${RLN} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/StringsPlugin.ld.so ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/StringsPlugin.so
	${RLN} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/TrafficPlugin.ld.so ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/TrafficPlugin.so
	${RLN} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/PamAuth.ld.so ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/pamauth.so
	${INSTALL_DATA} ${WRKSRC}/cfg/3proxy.cfg.sample ${STAGEDIR}${PREFIX}/etc/
	${INSTALL_MAN} ${WRKSRC}/man/3proxy.cfg.5 ${STAGEDIR}${PREFIX}/share/man/man5/
	${INSTALL_MAN} ${WRKSRC}/man/3proxy.8 ${STAGEDIR}${PREFIX}/share/man/man8/
	${INSTALL_MAN} ${WRKSRC}/man/proxy.8 ${STAGEDIR}${PREFIX}/share/man/man8/httppr.8
	${INSTALL_MAN} ${WRKSRC}/man/3proxy_crypt.8 ${STAGEDIR}${PREFIX}/share/man/man8/mycrypt.8
.for s in ${3PROXY_SERVERS}
	${INSTALL_MAN} ${WRKSRC}/man/${s}.8 ${STAGEDIR}${PREFIX}/share/man/man8/
.endfor

do-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	cd ${WRKSRC} && ${INSTALL_DATA} ${PORTDOCS} ${STAGEDIR}${DOCSDIR}/

.include <bsd.port.mk>
