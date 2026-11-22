# www/nginx-devel: the nginx-devel of azsupport/ports in the place of the official
# www/nginx-devel (aZ, 15.11.2026: «давай еще свой nginx-devel добавим», «может
# модулями его разбить»): nginx 1.31.9 (the security update of the official port,
# 230b1e426b, 18.11.2026; 1.31.8 before, of the pinned commit; of the files the
# patches below change, 1.31.9 changes src/event/ngx_event_openssl.c alone, away from
# the lines of its patch, and the configuration structures of proxy, fastcgi, scgi and
# uwsgi are the same), its options the union of those of three of aZ's servers,
# HTTP_GZIP_STATIC and HTTP_STATUS (for VTS).
#
# Fixes of freenginx that nginx 1.31.9 has not (aZ, 18.11.2026 22:39: «проверил фиксы?
# может висят в иссуес или в коммитах еще не зааррувленых?»): the double ngx_pfree() of
# gzip, the sanity checks of the "end" of mp4 (reads out of the buffer with a crafted
# file; after the patch of Angie), the invalid UTF-8 split between buffers of charset
# (CVE-2026-48142) and the positional captures of cloned subrequests after a non-match
# (files/patch-*: each its origin in its head). Those nginx 1.31.9 fixed its own way are
# not taken: DAV with alias (r->valid_location), the lengths of HTTP/2 and gRPC headers,
# r->main->blocked (the limit of pending operations), the session ticket keys. And of the
# older fixes of freenginx, those of 2024 and 2025 that F5 carries to nginx in the open
# pull request 1696 (27 commits, read whole 22.11.2026; aZ: «бери»): a limit on chunk
# extensions and trailer headers of a request body (they were skipped without an end, past
# client_max_body_size), the reading of a request body blocked when an error is returned,
# and no reuse of the connection of an HTTP/3 stream while it is reset. Of the others of
# that pull request: gzip and mp4 above; three are in nginx 1.31.9 already (the explicit
# NGX_AGAIN and the zero Content-Length of a discarded request body, the counter of
# limit_conn); HTTP/2 connections that come during a shutdown and the destination of COPY
# and MOVE of DAV with "alias" nginx handles its own way (ngx_http_v2_init(),
# ngx_http_dav_copy_move_handler()); the rest is left: mail, gRPC, uwsgi and scgi, SSI,
# auth_request, platforms without pread(), 32 bits, OpenSSL 4, Valgrind, and three of
# narrow use (open_file_cache_events with disable_symlinks, a redefinition of variables in
# a configuration, the AD bit in an answer to the resolver).
#
# The core has the modules of nginx itself built in (nginx can build only a few of
# them dynamic, here stream and image_filter, and DAV with files/patch-auto_options and
# patch-auto_modules), and brotli, headers-more and geoip2 (its http part), which
# every server of aZ uses
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
# place of the API of Angie, «testcookie, cache-purge нужны … берём»), and WebDAV,
# www/nginx-devel-dav (the DAV module of nginx: PUT, DELETE, MKCOL, COPY, MOVE) and
# www/nginx-devel-dav-ext (PROPFIND, OPTIONS, LOCK, UNLOCK; aZ, 18.11.2026: «мне в
# нгингс ещё надо для одного сервера http_webdav, его модулем можешь сделать?»; the
# review of the patches of the distributions: docs/distro-patches-nginx-dav-2026-11-18.md
# of azsupport/azsupport), and www/nginx-devel-vod (nginx-vod-module of the fork
# dio-az, its line v1.x at v1.11.2: HLS and DASH out of MP4 on the fly; aZ, 19.11.2026:
# «давай ветку VOD: v1.11.2 тянуть, main точно не надо раз там выпилили фичи»: main
# took out HLS AES-128, the muxed tracks of MP4, HDS and MSS). The core is built
# --with-compat and with --modules-path, so that a module built apart from it loads into
# it (nginx loads only a module of its own version: the slaves depend on the core of
# the same version, and they change together, both reading version.mk).
#
# zstd built in, as brotli (aZ, 22.11.2026 17:03: «и давай все таки и zstd добавим в
# nginx-devel без модуля»; 15.11.2026 it was not, a third-party module): nginx 1.31.9,
# freenginx and Angie 1.12.5 have no zstd of their own (their src/ and auto/, 22.11.2026),
# so it is nginx-zstd-module of the fork sysadmin-labs at 0.1.3, that of the official
# www/nginx-module-zstd (the option ZSTD of www/nginx and www/freenginx): the module of
# tokers (0.1.1, the last commit 23.06.2025) with three defects of its body filter fixed
# (20ac276, FreeBSD bug 299100: a worker spinning forever on an empty flush buffer, as an
# upstream that fails after the header gives; a response cut at 131072 bytes; a full
# output buffer dropped at the end of the frame), each call of libzstd checked, and a
# suite with the sanitizers, valgrind, a misbehaving upstream and reloads; 1466 lines
# of C. Not the module of tokers as Alpine (with its fix of the spin, tokers PR #23),
# Arch, NixOS and openSUSE build it, nor myguard-labs 0.90.9 of Debian
# (libnginx-mod-http-zstd) and www/angie-module-zstd: 23495 lines of C, with dictionary
# transport. In the core, not a package of a module (no load_module, no .so in
# libexec/nginx), with the length of a response given to zstd as a hint and the window
# of a response without a length capped at 512 KiB (files/extra-patch-zstd-window:
# 1273 KiB of memory for a response of 100 KB at level 3 in place of 3577 KiB; a hint,
# not a pledge: zstd fails a stream that is not of the pledged length, and the
# Content-Length of a response is not always that of its body, where gzip and brotli
# compress it whole), no flush after every buffer of input (files/extra-patch-zstd-continue:
# the module ended a block of zstd with each one, and a proxied page was 5 to 9 percent
# larger than the same page from a file, one through sub_filter 20 percent) and the
# q-values of Accept-Encoding as nginx takes them for gzip ("zstd;q=0" a refusal;
# files/extra-patch-zstd-accept-encoding). Before brotli
# in the chain of the filters: configure takes zstd before brotli (below), so that a
# client of "zstd, br" gets zstd, and post-configure checks it. Vary: Accept-Encoding by
# gzip_vary, as gzip and brotli.
#
# The ready files (aZ, 22.11.2026: «идея - врубать статик для всех трех компрессий»):
# gzip_static (of nginx), brotli_static (of ngx_brotli) and zstd_static
# (ngx_http_zstd_static_module of nginx-zstd-module, files/extra-patch-zstd-static), each
# off until a server turns it on, and each one alike: a .zst before a .br before a .gz
# among those that are on, that the client takes and that are there (nginx calls the
# handler it registered last first: zstd_static is configured after ngx_brotli, as a
# module of its own, files/extra-patch-zstd-config, and post-configure checks it), then
# the filters in the same order; q=0 a refusal; "Vary: Accept-Encoding" with gzip_vary
# wherever the ready file is, also for the client that does not take it
# (files/extra-patch-brotli-static-vary of Debian and extra-patch-brotli-static-gzip);
# none of them takes the gzip filter away from a response it did not serve
# (r->gzip_tested and r->gzip_ok, extra-patch-zstd-static and
# extra-patch-brotli-static-gzip). Every combination of the three static modules and the
# three filters on and off, for clients of every set of the encodings and with q=0, is
# checked: 1920 requests under ASan and UBSan before the commit, and
# tests/ports/servers-test.sh of azsupport/azsupport in the build. A ready file is not
# compared with the file it was made of: whoever makes them makes them again when the
# file changes.
#
# One Vary line (aZ, 22.11.2026; files/patch-src_http_ngx__http__core__module.c and the
# four next to it): the Vary lines of a response and the "Accept-Encoding" of gzip_vary
# in a single line, each member once, where nginx added its own line without a look at
# those of the response (twice "Vary: Accept-Encoding" behind an upstream that sends it).
# And the two fixes of the cache of pull request 1948 of nginx (CERT Polska: a tab
# between the members of Vary, "*" among them; files/patch-src_http_ngx__http__file__cache.c
# and patch-src_http_ngx__http__upstream.c).
#
# A response the slice filter puts together for a request with a Range is not compressed
# (aZ, 22.11.2026: «делай»; files/patch-src_http_modules_ngx__http__gzip__filter__module.c,
# extra-patch-brotli-slice-range, extra-patch-zstd-slice-range): compressed, nginx 1.31.9
# sends a 200 with the slice the range begins in for the whole object, and fetches every
# slice to the end of the object for it.
#
# No "Server" line of nginx itself (aZ, 22.11.2026 21:10: every configuration of his has
# more_clear_headers 'server', most of them nothing else of headers-more): built with
# -DNGX_HTTP_AZ_SERVER=0 (files/patch-src_http_ngx__http__header__filter__module.c and
# those of HTTP/2 and HTTP/3), nginx adds none, and the headers-more module has nothing
# to do for that directive where no backend has sent one
# (files/extra-patch-headers-more-server).
#
# Of the open pull requests of nginx (aZ, 22.11.2026: «бери разобрав их сам, вдруг там
# говно написали»; each read against the code of 1.31.9, its files/patch-* says how it
# was checked): ACK frames with ECN counts of QUIC handled (949 and 1005; a client that
# sends them got no response), no use of a QUIC path retired while its packet is handled
# (1634), no busy loop when SSL_write() wants to read (2004, with ssl_early_data). Not
# taken: 1624 and 1766 (the body of an HTTP/3 request: nginx 1.31.9 has it fixed its own
# way, st->skip).
#
# Libraries: OpenSSL of the base system (HTTP/3 too: the configure of nginx finds the
# QUIC API of OpenSSL 3.5, SSL_set_quic_tls_cbs, else it builds its compatibility layer),
# PCRE2 of devel/pcre2 of this tree, zlib of the base system; brotli, zstd and
# libmaxminddb (and the libgd of image_filter) of az: only their headers and libraries in ${WRKDIR}/az,
# with the run path /usr/local/az/lib (our ports link each other's shared libraries).
# The sources of brotli, headers-more, geoip2 and zstd come by GH_TUPLE, the commits of the
# official www/nginx-module-brotli, -headers-more and -geoip2 of the pinned commit (the
# same archives: their checksums in distinfo), headers-more ahead of it at 0.42, that of
# the official port after the pin, with its fix of more_set_input_headers -r (an absent
# header of several values, Cookie and the like, written through an uninitialized
# pointer; aZ, 19.11.2026: 0.42 now, not our patch of that fix on 0.41), not by those
# packages of sources, so the
# build does not depend on them being in the repository of FreeBSD; brotli with the
# patch of www/nginx-module-brotli (files/extra-patch-brotli-filter_config: the brotli
# of the system, not that of its git submodule). Not here: NJS, OTEL, Perl, XSLT, GeoIP 1,
# the GSSAPI modules and the other third-party modules of the official port.
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
#
# The handshake of SSL waits when the callback of the certificate yields
# (files/patch-src_event_ngx__event__openssl.c, the patch of OpenResty for nginx 1.31.8,
# as Debian has it; aZ, 18.11.2026): ssl_certificate_by_lua* of www/nginx-devel-lua can
# then do non-blocking I/O.

PORTNAME=	nginx
PORTVERSION=	${NGINX_VERSION}
.include "version.mk"
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://nginx.org/download/
PKGNAMESUFFIX?=	-devel
DISTFILES=	${DISTNAME}${EXTRACT_SUFX}
.if ${NGINX_AZ_MODULE:U} == passenger
# Phusion Passenger 6.2.2: the release of the version of www/rubygem-passenger, so that
# the module and the agent it starts are of one version (the official
# www/nginx-module-passenger, its sources for the official nginx, is 6.2.0)
NGINX_AZ_PASSENGER=	6.2.2
MASTER_SITES+=	https://github.com/phusion/passenger/releases/download/release-${NGINX_AZ_PASSENGER}/:passenger
DISTFILES+=	passenger-${NGINX_AZ_PASSENGER}.tar.gz:passenger
.endif

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
		openresty:headers-more-nginx-module:v0.42:headers_more \
		leev:ngx_http_geoip2_module:445df24:geoip2 \
		sysadmin-labs:nginx-zstd-module:0.1.3:zstd
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
.elif ${NGINX_AZ_MODULE:U} == dav-ext
# nginx-dav-ext-module 3.0.1 of sysadmin-labs (01.11.2026), the maintained fork of arut
# 3.0.0 (17.12.2018, the last of arut) that the official www/nginx-module-dav-ext takes:
# 3.0.0 with the pull requests #62 (PROPFIND lists the files whose names begin with a
# dot, only . and .. are left out) and #56 (a child it cannot stat no longer fails the
# whole PROPFIND); with files/extra-patch-dav-ext-dav-class (#46, as Alpine: DAV: 1,2
# with LOCK) and extra-patch-dav-ext-propfind-stat (the entry of that child taken back:
# without it the answer had an empty one)
GH_TUPLE+=	sysadmin-labs:nginx-dav-ext-module:v3.0.1:dav_ext
.elif ${NGINX_AZ_MODULE:U} == vod
# nginx-vod-module 1.11.2 of dio-az (02.11.2026), the maintained fork of kaltura that the
# official www/nginx-devel takes for its option VOD: the line v1.x, not main
GH_TUPLE+=	dio-az:nginx-vod-module:v1.11.2:vod
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
		--with-cc-opt="-DNGX_HTTP_AZ_SERVER=0 -I ${WRKDIR}/az/include -I ${LOCALBASE}/include" \
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
OPTIONS_GROUP_THIRDPARTYGRP=	BROTLI HEADERS_MORE HTTP_GEOIP2 ZSTD

OPTIONS_DEFINE=		DEBUG DEBUGLOG FILE_AIO IPV6 THREADS WWW
# the options of aZ: the union of three of his servers, and HTTP_GZIP_STATIC (aZ,
# 15.11.2026: «вруби HTTP_GZIP_STATIC в сборке нгингс еще»); HTTP_STATUS for
# www/nginx-devel-vts (aZ, 17.11.2026: VTS taken): the config of VTS sets
# NGX_STAT_STUB, so its module reads the counters ngx_stat_accepted... of the
# core, which only an nginx with the stub_status module has (without it: "dlopen()
# ... Undefined symbol ngx_stat_accepted", servers-test of run 44104438197); the
# official port has HTTP_STATUS on by default
OPTIONS_DEFAULT=	BROTLI FILE_AIO HEADERS_MORE HTTP HTTP_CACHE HTTP_GEOIP2 \
		HTTP_GZIP_STATIC HTTP_MP4 HTTP_REALIP HTTP_SECURE_LINK HTTP_SLICE \
		HTTP_SSL HTTP_STATUS HTTP_SUB HTTPV2 HTTPV3 IPV6 THREADS WWW ZSTD

OPTIONS_SUB=	yes

.include "Makefile.options.desc"

.for opt in ${OPTIONS_GROUP_MAILGRP:NMAIL}
${opt}_IMPLIES=	MAIL
.endfor

.for opt in ${OPTIONS_GROUP_HTTPGRP:NHTTP} WWW BROTLI HEADERS_MORE HTTP_GEOIP2 ZSTD
${opt}_IMPLIES=	HTTP
.endfor

DEBUG_CFLAGS=		-g
DEBUG_VARS=		STRIP=#do not strip if nginx with debug information
DEBUGLOG_CONFIGURE_ON=	--with-debug
FILE_AIO_CONFIGURE_ON=	--with-file-aio
IPV6_CONFIGURE_OFF=	--with-cc-opt="-DNGX_HAVE_INET6=0 -DNGX_HTTP_AZ_SERVER=0 -I ${WRKDIR}/az/include -I ${LOCALBASE}/include"
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

# brotli, libzstd and libmaxminddb of az (only the headers and the libraries they need,
# in ${WRKDIR}/az: pre-configure)
BROTLI_BUILD_DEPENDS=		${AZ_PREFIX}/lib/libbrotlienc.so:az/az
BROTLI_RUN_DEPENDS=		${AZ_PREFIX}/lib/libbrotlienc.so:az/az
HEADERS_MORE_CONFIGURE_ON=	--add-module=${WRKSRC_headers_more}
HTTP_GEOIP2_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
HTTP_GEOIP2_RUN_DEPENDS=	${AZ_PREFIX}/lib/libmaxminddb.so:az/az
HTTP_GEOIP2_CONFIGURE_ON=	--add-module=${WRKSRC_geoip2}
# the shared libzstd of az: only libzstd.so in ZSTD_LIB, so the config of the module, which
# takes an archive first for a module built in, finds none and links the shared library
ZSTD_BUILD_DEPENDS=		${AZ_PREFIX}/lib/libzstd.so:az/az
ZSTD_RUN_DEPENDS=		${AZ_PREFIX}/lib/libzstd.so:az/az
ZSTD_CONFIGURE_ENV=		ZSTD_INC=${WRKDIR}/az/include ZSTD_LIB=${WRKDIR}/az/lib
# the --add-module of zstd and brotli: after bsd.port.pre.mk, in their order

.if defined(NGINX_AZ_MODULE)
# a package of one dynamic module (the slaves www/nginx-devel-${NGINX_AZ_MODULE}): the
# same configure as the core but for that module, make modules, only its objects; the
# third-party modules of the core are not in it, so neither are their libraries
PKGNAMESUFFIX=	-devel-${NGINX_AZ_MODULE}
OPTIONS_EXCLUDE=	BROTLI HEADERS_MORE HTTP_GEOIP2 MAIL MAIL_IMAP MAIL_POP3 \
		MAIL_SMTP MAIL_SSL ZSTD
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
. elif ${NGINX_AZ_MODULE} == dav
# PUT, DELETE, MKCOL, COPY and MOVE (dav_methods, create_full_put_path, dav_access,
# min_delete_depth): the DAV module of nginx, dynamic (files/patch-auto_options and
# patch-auto_modules)
CONFIGURE_ARGS+=	--with-http_dav_module=dynamic
NGINX_AZ_OBJS=	ngx_http_dav_module.so
. elif ${NGINX_AZ_MODULE} == dav-ext
# PROPFIND, OPTIONS, LOCK and UNLOCK (dav_ext_methods, dav_ext_lock_zone, dav_ext_lock)
# on libxml2 and libxslt of az; with the DAV module of nginx (www/nginx-devel-dav) for
# the methods that write
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKSRC_dav_ext}
BUILD_DEPENDS+=	${AZ_PREFIX}/lib/libxml2.so:az/az \
		${AZ_PREFIX}/lib/libxslt.so:az/az
RUN_DEPENDS+=	${AZ_PREFIX}/lib/libxml2.so:az/az \
		${AZ_PREFIX}/lib/libxslt.so:az/az \
		nginx-devel-dav>=${NGINX_VERSION}:www/nginx-devel-dav
NGINX_AZ_OBJS=	ngx_http_dav_ext_module.so
. elif ${NGINX_AZ_MODULE} == vod
# vod hls, dash and the others in vod_mode local, mapped and remote, out of MP4 and MKV on
# the fly; zlib and iconv of the base system and its EVP of the OpenSSL nginx loads (HLS
# AES-128 and SAMPLE-AES, DASH CENC); without FFmpeg (libavcodec, libswscale, libavfilter
# are not in the build): no thumbnails, volume maps or audio filters (ko48: vod hls of
# vod_mode remote, aZ, 19.11.2026)
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKSRC_vod}
NGINX_AZ_OBJS=	ngx_http_vod_module.so
. elif ${NGINX_AZ_MODULE} == passenger
# Ruby and Rack applications under nginx (passenger_enabled; aZ, 20.11.2026:
# «nginx-devel-passenger нужен обязательно»): the module of the release above, its
# support libraries built by its config script (rake nginx:as_dynamic_module, in the
# tree of the release), as the option PASSENGER of the official nginx-devel (OPTIMIZE,
# -DNDEBUG, C++14); the agent is that of ruby34-passenger-nginx
CONFIGURE_ARGS+=	--add-dynamic-module=${WRKDIR}/passenger-${NGINX_AZ_PASSENGER}/src/nginx_module
CONFIGURE_ENV+=	OPTIMIZE="yes" EXTRA_PRE_CXXFLAGS="-std=c++14"
CFLAGS+=	-DNDEBUG
USES+=		compiler:c++14-lang ruby
BUILD_DEPENDS+=	${LOCALBASE}/bin/rake:devel/rubygem-rake
RUN_DEPENDS+=	${RUBY_PKGNAMEPREFIX}passenger-nginx>=${NGINX_AZ_PASSENGER}:www/rubygem-passenger
NGINX_AZ_OBJS=	ngx_http_passenger_module.so
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

# zstd before brotli (aZ, 22.11.2026): the config of each puts its filter right after that
# of gzip in the list of the filters, so the one configure takes first ends up last in the
# list, and nginx calls the last filter first: zstd first, so that a client of "zstd, br"
# gets zstd and one of "br, gzip" br (the option helpers would give them in the order of
# the names of the options, brotli first). post-configure checks the order.
.if !empty(PORT_OPTIONS:MZSTD) && !defined(NGINX_AZ_MODULE)
CONFIGURE_ARGS+=	--add-module=${WRKSRC_zstd}
.endif
.if !empty(PORT_OPTIONS:MBROTLI) && !defined(NGINX_AZ_MODULE)
CONFIGURE_ARGS+=	--add-module=${WRKSRC_brotli}
.endif
# zstd_static after brotli_static (aZ, 22.11.2026): nginx calls the handler registered
# last first, so the module configured last: a .zst before a .br for a client of both
.if !empty(PORT_OPTIONS:MZSTD) && !defined(NGINX_AZ_MODULE)
CONFIGURE_ARGS+=	--add-module=${WRKSRC_zstd}/static
.endif

# the headers and libraries of az the port needs, and only them
pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib
.if !empty(PORT_OPTIONS:MBROTLI) && !defined(NGINX_AZ_MODULE)
	@${LN} -sfh ${AZ_PREFIX}/include/brotli ${WRKDIR}/az/include/brotli
	@${LN} -sf ${AZ_PREFIX}/lib/libbrotlienc.so ${AZ_PREFIX}/lib/libbrotlicommon.so ${WRKDIR}/az/lib/
.endif
.if !empty(PORT_OPTIONS:MZSTD) && !defined(NGINX_AZ_MODULE)
	@${LN} -sf ${AZ_PREFIX}/include/zstd.h ${AZ_PREFIX}/include/zstd_errors.h ${WRKDIR}/az/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libzstd.so ${WRKDIR}/az/lib/
.endif
.if (!empty(PORT_OPTIONS:MHTTP_GEOIP2) && !defined(NGINX_AZ_MODULE)) || ${NGINX_AZ_MODULE:U} == stream
	@${LN} -sf ${AZ_PREFIX}/include/maxminddb.h ${AZ_PREFIX}/include/maxminddb_config.h ${WRKDIR}/az/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libmaxminddb.so ${WRKDIR}/az/lib/
.endif
.if ${NGINX_AZ_MODULE:U} == image-filter
	@${LN} -sf ${AZ_PREFIX}/include/gd*.h ${WRKDIR}/az/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libgd.so ${WRKDIR}/az/lib/
.endif
# dav-ext (ngx_module_libs=LIBXSLT): libxml and libxslt, not libexslt, so that the
# configure of nginx finds the first two in ${WRKDIR}/az and links nothing more
.if ${NGINX_AZ_MODULE:U} == dav-ext
	@${LN} -sfh ${AZ_PREFIX}/include/libxml2/libxml ${WRKDIR}/az/include/libxml
	@${LN} -sfh ${AZ_PREFIX}/include/libxslt ${WRKDIR}/az/include/libxslt
	@${LN} -sf ${AZ_PREFIX}/lib/libxml2.so ${AZ_PREFIX}/lib/libxslt.so ${WRKDIR}/az/lib/
.endif

post-patch:
	@${REINPLACE_CMD} 's!%%HTTP_PORT%%!${HTTP_PORT}!; \
		s!%%PREFIX%%!${PREFIX}!; \
		s!%%NGINX_ERRORLOG%%!${NGINX_ERRORLOG}!' \
		${WRKSRC}/conf/nginx.conf
	@cd ${WRKSRC_brotli} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-brotli-filter_config
# brotli_static: Vary only where a .br file is, as gzip_static (from Debian; aZ, 16.11.2026),
# and there also for the client that does not take br; the gzip filter left to gzip (aZ,
# 22.11.2026)
	@cd ${WRKSRC_brotli} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-brotli-static-vary
	@cd ${WRKSRC_brotli} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-brotli-static-gzip
# a ranged response of the slice filter not compressed (aZ, 22.11.2026), as by gzip and zstd
	@cd ${WRKSRC_brotli} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-brotli-slice-range
# headers-more: more_clear_headers 'server' with nothing to clear does nothing (aZ,
# 22.11.2026): this nginx adds no Server line of its own (-DNGX_HTTP_AZ_SERVER=0)
	@cd ${WRKSRC_headers_more} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-headers-more-server
# geoip2: the cached lookup result reset at a reload of the database (from Debian; aZ,
# 16.11.2026), the http module and that of stream
	@cd ${WRKSRC_geoip2} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-geoip2-reload-cache
	@${REINPLACE_CMD} 's!%%PREFIX%%!${WRKDIR}/az!g' ${WRKSRC_brotli}/filter/config
# zstd (aZ, 22.11.2026): the static module out of the config of the module (a module of
# its own, above), the length as a hint and the capped window, the q-values of
# Accept-Encoding, h->next of the Content-Encoding line, the static module, no flush
# after every buffer of input, a ranged response of the slice filter not compressed
.for p in config window accept-encoding header-next static continue slice-range
	@cd ${WRKSRC_zstd} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-zstd-${p}
.endfor
.if ${NGINX_AZ_MODULE:U} == stream-lua
	@cd ${WRKSRC_luastream} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-lua-stream-src_ngx__stream__lua__module.c
.endif
.if ${NGINX_AZ_MODULE:U} == dav-ext
	@cd ${WRKSRC_dav_ext} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-dav-ext-dav-class
	@cd ${WRKSRC_dav_ext} && ${PATCH} -s -p0 < ${FILESDIR}/extra-patch-dav-ext-propfind-stat
.endif

# the filters of zstd and brotli in objs/ngx_modules.c, where nginx calls the last one
# first: that of zstd after that of brotli, or a client of "zstd, br" would get br
post-configure:
.if !empty(PORT_OPTIONS:MZSTD) && !empty(PORT_OPTIONS:MBROTLI) && !defined(NGINX_AZ_MODULE)
	@z=$$(${GREP} -n '&ngx_http_zstd_filter_module,' ${WRKSRC}/objs/ngx_modules.c | ${CUT} -d: -f1); \
	b=$$(${GREP} -n '&ngx_http_brotli_filter_module,' ${WRKSRC}/objs/ngx_modules.c | ${CUT} -d: -f1); \
	if [ -z "$$z" ] || [ -z "$$b" ] || [ "$$z" -le "$$b" ]; then \
		${ECHO_MSG} "objs/ngx_modules.c: the filter of zstd (line $$z) not after that of brotli (line $$b): a client of zstd, br would get br"; \
		exit 1; \
	fi; \
	${ECHO_MSG} "===>  the filter of zstd (line $$z of objs/ngx_modules.c) after that of brotli ($$b): zstd first"
# and the static modules: the handler of zstd_static after that of brotli_static, or a
# client of "zstd, br" would get the .br where both files are
	@z=$$(${GREP} -n '&ngx_http_zstd_static_module,' ${WRKSRC}/objs/ngx_modules.c | ${CUT} -d: -f1); \
	b=$$(${GREP} -n '&ngx_http_brotli_static_module,' ${WRKSRC}/objs/ngx_modules.c | ${CUT} -d: -f1); \
	if [ -z "$$z" ] || [ -z "$$b" ] || [ "$$z" -le "$$b" ]; then \
		${ECHO_MSG} "objs/ngx_modules.c: zstd_static (line $$z) not after brotli_static (line $$b): a client of zstd, br would get the .br"; \
		exit 1; \
	fi; \
	${ECHO_MSG} "===>  zstd_static (line $$z of objs/ngx_modules.c) after brotli_static ($$b): the .zst first"
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
