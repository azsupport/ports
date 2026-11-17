# www/nginx-devel: the nginx-devel of azsupport/ports in the place of the official
# www/nginx-devel (aZ, 15.11.2026: «давай еще свой nginx-devel добавим», «может
# модулями его разбить»): nginx 1.31.8 of the official port of the pinned commit, its
# options the union of those of three of aZ's servers, and HTTP_GZIP_STATIC.
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
# www/nginx-devel-image-filter, and on LuaJIT www/nginx-devel-lua (ndk and lua) and
# www/nginx-devel-stream-lua (aZ, 15.11.2026: «давай luajit»), and www/nginx-devel-vts,
# www/nginx-devel-cache-purge and www/nginx-devel-testcookie (aZ, 17.11.2026: VTS in the
# place of the API of Angie, «testcookie, cache-purge нужны … берём»). The core is built
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
#
# The mp4 module with mp4_limit_rate and mp4_limit_rate_after of Angie, the directives
# of NGINX Plus (aZ, 17.11.2026: «замена стандартного mp4 модуля на его файл из agnie
# ... там есть крутые фичи из nginx plus по ограничению скорости»): the rate of a
# response limited to a factor of the average bitrate of the file after a playback time
# (files/patch-src_http_modules_ngx__http__mp4__module.c: the change of the file of
# Angie 1.12.4 against that of nginx 1.31.8, with the check of nginx that mp4_buffer_size
# and mp4_max_buffer_size are not zero, which Angie has not). A patch, not the file of
# Angie in the place of that of nginx: a fix of nginx in the parser of MP4 stays, and a
# change of nginx in those lines stops the build instead of being lost.
#
# The image_filter module with the watermark of Intaro (aZ, 17.11.2026: their file in the
# place of that of nginx for years, «надо портировать улучшения из этого файла и при это
# проверить на возможные уязвимости»): "image_filter watermark" and image_filter_watermark,
# _position, _width_from and _height_from
# (files/patch-src_http_modules_ngx__http__image__filter__module.c: their change of the file
# of nginx 1.11.6 brought to that of nginx 1.31.8, the output byte for byte theirs, without
# the crashes of their file and its read of freed memory; the details in its head).

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
.if ${NGINX_AZ_MODULE:U} == lua || ${NGINX_AZ_MODULE:U} == stream-lua
# ndk, lua-nginx-module and stream-lua-nginx-module: the commits of the official
# www/nginx-module-ndk, -lua and -lua-stream of the pinned commit
GH_TUPLE+=	openresty:ngx_devel_kit:v0.3.6:ndk \
		openresty:lua-nginx-module:v0.10.31:lua \
		openresty:stream-lua-nginx-module:v0.0.19rc4:luastream
.elif ${NGINX_AZ_MODULE:U} == vts
# VTS at 128ccd2 (10.11.2026), not at c382342 (24.05.2025) as the official
# www/nginx-devel: its fixes since, among them the overCounts of the cache zones in the
# JSON in the wrong order (cc73da6: every value of them shifted) and the status code
# counters of a node freed and cleared with it (b8ebf46, 1588db1)
GH_TUPLE+=	vozlt:nginx-module-vts:128ccd2:vts
.elif ${NGINX_AZ_MODULE:U} == cache-purge
# ngx_cache_purge 3.0.4 of nginx-modules, the version of the official
# www/nginx-module-cache-purge (its one patch is for freenginx alone); its copies of the
# proxy, fastcgi, scgi and uwsgi configuration structures match those of nginx 1.31.8
# up to cache_key (host_set of its copy is host_value of nginx 1.31.8, both 8 bytes)
GH_TUPLE+=	nginx-modules:ngx_cache_purge:3.0.4:cache_purge
.elif ${NGINX_AZ_MODULE:U} == testcookie
# testcookie at de7ca88 (14.11.2026), with the fixes of that day: two heap buffer
# overflows (#87), a read past the query (#90), the request body discarded before the
# refresh page (#89), $testcookie_set of a whitelisted client (#95); the FreeBSD tree has
# it only for Angie (www/angie-module-testcookie), at 7d263d43, before them
GH_TUPLE+=	kyprizel:testcookie-nginx-module:de7ca88:testcookie
.endif

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
# the options of aZ: the union of three of his servers, and HTTP_GZIP_STATIC (aZ,
# 15.11.2026: «вруби HTTP_GZIP_STATIC в сборке нгингс еще»)
OPTIONS_DEFAULT=	BROTLI FILE_AIO HEADERS_MORE HTTP HTTP_CACHE HTTP_GEOIP2 \
		HTTP_GZIP_STATIC HTTP_MP4 HTTP_REALIP HTTP_SECURE_LINK HTTP_SLICE \
		HTTP_SSL HTTP_SUB HTTPV2 HTTPV3 IPV6 THREADS WWW

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
. elif ${NGINX_AZ_MODULE} == lua
# ndk and the http lua module, on the LuaJIT of lang/luajit-openresty (lua-nginx-module
# has no standard Lua), with lua-resty-core, without which it does not start (aZ,
# 15.11.2026: «давай luajit»)
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKSRC_ndk} --add-dynamic-module=${WRKSRC_lua}
CONFIGURE_ENV+=	LUAJIT_INC=${LOCALBASE}/include/luajit-2.1 LUAJIT_LIB=${LOCALBASE}/lib
LIB_DEPENDS+=	libluajit-5.1.so:lang/luajit-openresty
RUN_DEPENDS+=	lua-resty-core>0:www/lua-resty-core
NGINX_AZ_OBJS=	ndk_http_module.so ngx_http_lua_module.so
. elif ${NGINX_AZ_MODULE} == stream-lua
# the stream lua module, built with the stream of nginx-devel-stream (realip, ssl,
# ssl_preread) and ndk, which come from nginx-devel-stream and nginx-devel-lua
CONFIGURE_ARGS+=	--with-stream=dynamic --with-stream_realip_module \
			--with-stream_ssl_module --with-stream_ssl_preread_module \
			--add-dynamic-module=${WRKSRC_ndk} \
			--add-dynamic-module=${WRKSRC_luastream}
CONFIGURE_ENV+=	LUAJIT_INC=${LOCALBASE}/include/luajit-2.1 LUAJIT_LIB=${LOCALBASE}/lib
USES+=		ssl
LIB_DEPENDS+=	libluajit-5.1.so:lang/luajit-openresty
RUN_DEPENDS+=	lua-resty-core>0:www/lua-resty-core \
		nginx-devel-lua>=${NGINX_VERSION}:www/nginx-devel-lua \
		nginx-devel-stream>=${NGINX_VERSION}:www/nginx-devel-stream
NGINX_AZ_OBJS=	ngx_stream_lua_module.so
. elif ${NGINX_AZ_MODULE} == vts
# the traffic of the server, upstream and cache zones: JSON, Prometheus and its HTML page
# (aZ, 17.11.2026: in the place of the API of Angie)
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKSRC_vts}
NGINX_AZ_OBJS=	ngx_http_vhost_traffic_status_module.so
. elif ${NGINX_AZ_MODULE} == cache-purge
# proxy_cache_purge, fastcgi_cache_purge, scgi_cache_purge and uwsgi_cache_purge (aZ,
# 17.11.2026)
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKSRC_cache_purge}
NGINX_AZ_OBJS=	ngx_http_cache_purge_module.so
. elif ${NGINX_AZ_MODULE} == testcookie
# the cookie (or the page that sets it) a client has to give back before it is served:
# clients that keep no cookies are not (aZ, 17.11.2026); its AES (the encrypted cookie)
# from the OpenSSL nginx loads
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKSRC_testcookie}
NGINX_AZ_OBJS=	ngx_http_testcookie_access_module.so
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
# brotli_static: Vary only where a .br file is, as gzip_static (from Debian; aZ, 16.11.2026)
	@cd ${WRKSRC_brotli} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-brotli-static-vary
# geoip2: the cached lookup result reset at a reload of the database (from Debian; aZ,
# 16.11.2026), the http module and that of stream
	@cd ${WRKSRC_geoip2} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-geoip2-reload-cache
	@${REINPLACE_CMD} 's!%%PREFIX%%!${WRKDIR}/az!g' ${WRKSRC_brotli}/filter/config
.if ${NGINX_AZ_MODULE:U} == stream-lua
	@cd ${WRKSRC_luastream} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-lua-stream-src_ngx__stream__lua__module.c
.endif

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
