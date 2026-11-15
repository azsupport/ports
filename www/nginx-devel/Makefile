# www/nginx-devel: the nginx-devel of azsupport/ports in the place of the official
# www/nginx-devel (aZ, 15.11.2026: «давай еще свой nginx-devel добавим», «может
# модулями его разбить»): nginx 1.31.8 of the official port of the pinned commit, its
# options the union of those of the servers a server, a server and a server.
#
# The core has the modules of nginx itself built in (they cannot be dynamic), and
# brotli, headers-more and geoip2 (its http part), which every server of aZ uses
# (aZ, 15.11.2026: «бротли и хеадерсморе у меня на всех серверах есть, есть ли смысл
# вкомпилить их в нгингс тогда?»): their libraries are shared ones in both cases, and
# a module compiled in needs no load_module and cannot be of another version. A module
# only some servers use is dynamic, a package of its own: a slave of this port that
# sets NGINX_AZ_MODULE, builds the same nginx with only that module dynamic (make
# modules) and installs only its objects, www/nginx-devel-stream (aZ, 15.11.2026:
# «stream модулем, на 90% других серверов он не юзается») and
# www/nginx-devel-image-filter; the Lua modules are to follow. The core is built
# --with-compat and with --modules-path, so that a module built apart from it loads into
# it (nginx loads only a module of its own version: the slaves depend on the core of
# the same version, and they change together, both reading version.mk).
#
# Libraries: OpenSSL of the base system (HTTP/3 too: the configure of nginx finds the
# QUIC API of OpenSSL 3.5, SSL_set_quic_tls_cbs, else it builds its compatibility layer),
# PCRE2 of devel/pcre2 of this tree, zlib of the base system; brotli and libmaxminddb
# (and the libgd of image_filter) of az: only their headers and libraries in ${WRKDIR}/az,
# with the run path /usr/local/az/lib (our ports link each other's shared libraries).
# The sources of brotli, headers-more and geoip2 come by GH_TUPLE, the commits of the
# official www/nginx-module-brotli, -headers-more and -geoip2 of the pinned commit (the
# same archives: their checksums in distinfo), not by those packages of sources, so the
# build does not depend on them being in the repository of FreeBSD; brotli with the
# patch of www/nginx-module-brotli (files/extra-patch-brotli-filter_config: the brotli
# of the system, not that of its git submodule). Not here: VOD (aZ, 15.11.2026: «на vod
# пока забей тогда. вспомним когда понадобится»), NJS, OTEL, Perl, XSLT, GeoIP 1, the
# GSSAPI modules and the other third-party modules of the official port.

PORTNAME=	nginx
PORTVERSION=	${NGINX_VERSION}
.include "version.mk"
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://nginx.org/download/
PKGNAMESUFFIX?=	-devel
DISTFILES=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT?=	Robust and small WWW server (of azsupport/ports)
WWW=		https://nginx.com/ \
		https://github.com/azsupport/ports

LICENSE=	BSD2CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

USES=		cpe compiler:env
CPE_VENDOR=	f5
CPE_PRODUCT=	nginx_open_source

USE_GITHUB=	nodefault
GH_TUPLE=	google:ngx_brotli:a71f931:brotli \
		openresty:headers-more-nginx-module:v0.41:headers_more \
		leev:ngx_http_geoip2_module:445df24:geoip2

NGINX_VARDIR?=	/var
NGINX_LOGDIR?=	${NGINX_VARDIR}/log/nginx
NGINX_RUNDIR?=	${NGINX_VARDIR}/run
NGINX_TMPDIR?=	${NGINX_VARDIR}/tmp/nginx
HTTP_PORT?=	80

NGINX_ACCESSLOG?=	${NGINX_LOGDIR}/access.log
NGINX_ERRORLOG?=	${NGINX_LOGDIR}/error.log

MODULESDIR=	${PREFIX}/libexec/${PORTNAME}

HAS_CONFIGURE=	yes
CONFIGURE_ARGS+=--prefix=${ETCDIR} \
		--with-cc-opt="-I ${WRKDIR}/az/include -I ${LOCALBASE}/include" \
		--with-ld-opt="-L ${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib -L ${LOCALBASE}/lib" \
		--conf-path=${ETCDIR}/nginx.conf \
		--sbin-path=${PREFIX}/sbin/nginx \
		--modules-path=${MODULESDIR} \
		--pid-path=${NGINX_RUNDIR}/nginx.pid \
		--error-log-path=${NGINX_ERRORLOG} \
		--user=${WWWOWN} --group=${WWWGRP} \
		--with-compat \
		--with-pcre
ALL_TARGET=

LIB_DEPENDS+=	libpcre2-8.so:devel/pcre2

NO_OPTIONS_SORT=	yes

OPTIONS_GROUP=	HTTPGRP MAILGRP THIRDPARTYGRP
OPTIONS_GROUP_HTTPGRP=	HTTP HTTP_ADDITION HTTP_AUTH_REQ HTTP_CACHE HTTP_DAV \
	HTTP_DEGRADATION HTTP_FLV HTTP_GUNZIP_FILTER HTTP_GZIP_STATIC HTTP_MP4 \
	HTTP_RANDOM_INDEX HTTP_REALIP HTTP_SECURE_LINK HTTP_SLICE HTTP_SSL \
	HTTP_STATUS HTTP_SUB HTTPV2 HTTPV3
OPTIONS_GROUP_MAILGRP=	MAIL MAIL_IMAP MAIL_POP3 MAIL_SMTP MAIL_SSL
OPTIONS_GROUP_THIRDPARTYGRP=	BROTLI HEADERS_MORE HTTP_GEOIP2

OPTIONS_DEFINE=		DEBUG DEBUGLOG FILE_AIO IPV6 THREADS WWW
# the options of aZ: the union of a server, a server and a server (aZ, 15.11.2026)
OPTIONS_DEFAULT=	BROTLI FILE_AIO HEADERS_MORE HTTP HTTP_CACHE HTTP_GEOIP2 \
		HTTP_MP4 HTTP_REALIP HTTP_SECURE_LINK HTTP_SLICE HTTP_SSL HTTP_SUB \
		HTTPV2 HTTPV3 IPV6 THREADS WWW

OPTIONS_SUB=	yes

.include "Makefile.options.desc"

.for opt in ${OPTIONS_GROUP_MAILGRP:NMAIL}
${opt}_IMPLIES=	MAIL
.endfor

.for opt in ${OPTIONS_GROUP_HTTPGRP:NHTTP} WWW BROTLI HEADERS_MORE HTTP_GEOIP2
${opt}_IMPLIES=	HTTP
.endfor

DEBUG_CFLAGS=		-g
DEBUG_VARS=		STRIP=#do not strip if nginx with debug information
DEBUGLOG_CONFIGURE_ON=	--with-debug
FILE_AIO_CONFIGURE_ON=	--with-file-aio
IPV6_CONFIGURE_OFF=	--with-cc-opt="-DNGX_HAVE_INET6=0 -I ${WRKDIR}/az/include -I ${LOCALBASE}/include"
THREADS_CONFIGURE_ON=	--with-threads

HTTP_CONFIGURE_ON=		--http-client-body-temp-path=${NGINX_TMPDIR}/client_body_temp \
				--http-fastcgi-temp-path=${NGINX_TMPDIR}/fastcgi_temp \
				--http-proxy-temp-path=${NGINX_TMPDIR}/proxy_temp \
				--http-scgi-temp-path=${NGINX_TMPDIR}/scgi_temp \
				--http-uwsgi-temp-path=${NGINX_TMPDIR}/uwsgi_temp \
				--http-log-path=${NGINX_ACCESSLOG}
HTTP_CONFIGURE_OFF=		--without-http
HTTP_ADDITION_CONFIGURE_ON=	--with-http_addition_module
HTTP_AUTH_REQ_CONFIGURE_ON=	--with-http_auth_request_module
HTTP_CACHE_CONFIGURE_OFF=	--without-http-cache
HTTP_DAV_CONFIGURE_ON=		--with-http_dav_module
HTTP_DEGRADATION_CONFIGURE_ON=	--with-http_degradation_module
HTTP_FLV_CONFIGURE_ON=		--with-http_flv_module
HTTP_GZIP_STATIC_CONFIGURE_ON=	--with-http_gzip_static_module
HTTP_GUNZIP_FILTER_CONFIGURE_ON=--with-http_gunzip_module
HTTP_MP4_CONFIGURE_ON=		--with-http_mp4_module
HTTP_RANDOM_INDEX_CONFIGURE_ON=	--with-http_random_index_module
HTTP_REALIP_CONFIGURE_ON=	--with-http_realip_module
HTTP_SECURE_LINK_CONFIGURE_ON=	--with-http_secure_link_module
HTTP_SLICE_CONFIGURE_ON=	--with-http_slice_module
HTTP_SSL_CONFIGURE_ON=		--with-http_ssl_module
HTTP_SSL_USES=			ssl
HTTP_STATUS_CONFIGURE_ON=	--with-http_stub_status_module
HTTP_SUB_CONFIGURE_ON=		--with-http_sub_module
HTTPV2_IMPLIES=			HTTP_SSL
HTTPV2_CONFIGURE_ON=		--with-http_v2_module
HTTPV3_IMPLIES=			HTTP_SSL
HTTPV3_CONFIGURE_ON=		--with-http_v3_module
MAIL_CONFIGURE_ON=		--with-mail
MAIL_IMAP_CONFIGURE_OFF=	--without-mail_imap_module
MAIL_POP3_CONFIGURE_OFF=	--without-mail_pop3_module
MAIL_SMTP_CONFIGURE_OFF=	--without-mail_smtp_module
MAIL_SSL_USES=			ssl
MAIL_SSL_CONFIGURE_ON=		--with-mail_ssl_module

# brotli and libmaxminddb of az (only the headers and the libraries they need, in
# ${WRKDIR}/az: pre-configure)
BROTLI_BUILD_DEPENDS=		${AZ_PREFIX}/lib/libbrotlienc.so:az/az
BROTLI_RUN_DEPENDS=		${AZ_PREFIX}/lib/libbrotlienc.so:az/az
BROTLI_CONFIGURE_ON=		--add-module=${WRKSRC_brotli}
HEADERS_MORE_CONFIGURE_ON=	--add-module=${WRKSRC_headers_more}
HTTP_GEOIP2_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
HTTP_GEOIP2_RUN_DEPENDS=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
HTTP_GEOIP2_CONFIGURE_ON=	--add-module=${WRKSRC_geoip2}

.if defined(NGINX_AZ_MODULE)
# a package of one dynamic module (the slaves www/nginx-devel-${NGINX_AZ_MODULE}): the
# same configure as the core but for that module, make modules, only its objects; the
# third-party modules of the core are not in it, so neither are their libraries
PKGNAMESUFFIX=	-devel-${NGINX_AZ_MODULE}
OPTIONS_EXCLUDE=	BROTLI HEADERS_MORE HTTP_GEOIP2 MAIL MAIL_IMAP MAIL_POP3 \
		MAIL_SMTP MAIL_SSL
RUN_DEPENDS+=	nginx-devel>=${NGINX_VERSION}:www/nginx-devel
ALL_TARGET=	modules
PLIST=		${.CURDIR}/pkg-plist
PKGMESSAGE=	${.CURDIR}/pkg-message
. if ${NGINX_AZ_MODULE} == stream
# stream with realip, ssl and ssl_preread, and the stream part of geoip2 (its http part
# is in the core)
CONFIGURE_ARGS+=	--with-stream=dynamic --with-stream_realip_module \
			--with-stream_ssl_module --with-stream_ssl_preread_module \
			--add-dynamic-module=${WRKSRC_geoip2}
USES+=		ssl
BUILD_DEPENDS+=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
RUN_DEPENDS+=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
NGINX_AZ_OBJS=	ngx_stream_module.so ngx_stream_geoip2_module.so
. elif ${NGINX_AZ_MODULE} == image-filter
# image_filter on the libgd of az
CONFIGURE_ARGS+=	--with-http_image_filter_module=dynamic
BUILD_DEPENDS+=	${AZ_PREFIX}/lib/libgd.so:az/az
RUN_DEPENDS+=	${AZ_PREFIX}/lib/libgd.so:az/az
NGINX_AZ_OBJS=	ngx_http_image_filter_module.so
. else
IGNORE=		NGINX_AZ_MODULE ${NGINX_AZ_MODULE}: no such module package
. endif
.else
CONFLICTS_INSTALL=	nginx nginx-full nginx-lite nginx-naxsi
USE_RC_SUBR=	nginx
SUB_FILES=	pkg-message
SUB_LIST+=	WWWOWN=${WWWOWN} \
		WWWGRP=${WWWGRP} \
		NGINX_RUNDIR=${NGINX_RUNDIR} \
		NGINX_TMPDIR=${NGINX_TMPDIR} \
		PREFIX=${PREFIX}
PLIST_SUB+=	NGINX_TMPDIR=${NGINX_TMPDIR} NGINX_LOGDIR=${NGINX_LOGDIR} WWWOWN=${WWWOWN} WWWGRP=${WWWGRP}
USERS=		${WWWOWN}
GROUPS=		${WWWGRP}
.endif

.include <bsd.port.pre.mk>

.if empty(PORT_OPTIONS:MHTTP) && empty(PORT_OPTIONS:MMAIL)
IGNORE=		requires at least HTTP or MAIL to \
		be defined.  Please do 'make config' again
.endif

.if ${COMPILER_TYPE} == clang && ${COMPILER_VERSION} >= 191
CFLAGS+=	-Wno-error=cast-function-type-mismatch
.endif

# the headers and libraries of az the port needs, and only them
pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib
.if !empty(PORT_OPTIONS:MBROTLI) && !defined(NGINX_AZ_MODULE)
	@${LN} -sfh ${AZ_PREFIX}/include/brotli ${WRKDIR}/az/include/brotli
	@${LN} -sf ${AZ_PREFIX}/lib/libbrotlienc.so ${AZ_PREFIX}/lib/libbrotlicommon.so ${WRKDIR}/az/lib/
.endif
.if (!empty(PORT_OPTIONS:MHTTP_GEOIP2) && !defined(NGINX_AZ_MODULE)) || ${NGINX_AZ_MODULE:U} == stream
	@${LN} -sf ${AZ_PREFIX}/include/maxminddb.h ${AZ_PREFIX}/include/maxminddb_config.h ${WRKDIR}/az/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libmaxminddb.so ${WRKDIR}/az/lib/
.endif
.if ${NGINX_AZ_MODULE:U} == image-filter
	@${LN} -sf ${AZ_PREFIX}/include/gd*.h ${WRKDIR}/az/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libgd.so ${WRKDIR}/az/lib/
.endif

post-patch:
	@${REINPLACE_CMD} 's!%%HTTP_PORT%%!${HTTP_PORT}!; \
		s!%%PREFIX%%!${PREFIX}!; \
		s!%%NGINX_ERRORLOG%%!${NGINX_ERRORLOG}!' \
		${WRKSRC}/conf/nginx.conf
	@cd ${WRKSRC_brotli} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-brotli-filter_config
	@${REINPLACE_CMD} 's!%%PREFIX%%!${WRKDIR}/az!g' ${WRKSRC_brotli}/filter/config

.if defined(NGINX_AZ_MODULE)
do-install:
	${MKDIR} ${STAGEDIR}${MODULESDIR}
.for o in ${NGINX_AZ_OBJS}
	${INSTALL_LIB} ${WRKSRC}/objs/${o} ${STAGEDIR}${MODULESDIR}
.endfor
.else
do-install:
	${MKDIR} ${STAGEDIR}${ETCDIR}
	${MKDIR} ${STAGEDIR}${NGINX_TMPDIR}
	${MKDIR} ${STAGEDIR}${NGINX_LOGDIR}
	${INSTALL_PROGRAM} ${WRKSRC}/objs/nginx ${STAGEDIR}${PREFIX}/sbin
.for i in koi-utf koi-win win-utf
	${INSTALL_DATA} ${WRKSRC}/conf/${i} ${STAGEDIR}${ETCDIR}
.endfor
.for i in fastcgi_params mime.types scgi_params uwsgi_params
	${INSTALL_DATA} ${WRKSRC}/conf/${i} ${STAGEDIR}${ETCDIR}/${i}-dist
.endfor

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/share/vim/vimfiles
	cd ${WRKSRC}/contrib/vim && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/share/vim/vimfiles
	${INSTALL_MAN} ${WRKSRC}/objs/nginx.8 ${STAGEDIR}${PREFIX}/share/man/man8
	${CAT} ${WRKSRC}/conf/nginx.conf >> ${STAGEDIR}${ETCDIR}/nginx.conf-dist

post-install-WWW-on:
	${MKDIR} ${STAGEDIR}${PREFIX}/www/nginx-dist
	(cd ${WRKSRC}/html && ${COPYTREE_SHARE} . ${STAGEDIR}${PREFIX}/www/nginx-dist && \
	${TOUCH} ${STAGEDIR}${PREFIX}/www/nginx-dist/EXAMPLE_DIRECTORY-DONT_ADD_OR_TOUCH_ANYTHING)
.endif

.include <bsd.port.post.mk>
