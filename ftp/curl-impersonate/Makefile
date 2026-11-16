# ftp/curl-impersonate: the curl-impersonate of azsupport/ports in the place of the
# official ftp/curl-impersonate (aZ, 16.11.2026: built from source, the program and
# the library): curl-impersonate 2.3.2 of lexiforest, the official port of the pinned
# commit (2.3.2 of 13.11.2026: its distfiles, its patches of CMakeLists.txt,
# patches/boringssl.patch and patches/curl.patch, its layout), with:
# - the libraries of az where they keep the impersonation and the build (our ports
#   link each other's shared libraries, aZ 10.11.2026): c-ares 1.34.9 (the resolver,
#   and the HTTPS records of ECH), brotli 1.2.1 and zstd 1.5.7, the versions upstream
#   pins (its patch of brotli is for IA-64 and LoongArch only), and libidn2 2.3.8 (IDN;
#   it loads the libiconv of az) and libpsl 0.23.3 (PSL, its built-in list), which
#   upstream leaves out on FreeBSD (aZ, 16.11.2026 17:47: IDN and PSL from az, as in
#   ftp/curl and ftp/wget), shared, with the run path /usr/local/az/lib, and zlib of the
#   base system; their headers alone in a directory of the work. Upstream and the
#   official port build c-ares, brotli, zstd and zlib static into the library and the
#   program;
# - built in, static, into libcurl-impersonate.so alone, their symbols hidden there
#   (--exclude-libs: a process that loads the nghttp2 of az as well keeps the two
#   apart; upstream exports them): BoringSSL 156c7b75 with the patch of upstream (the
#   TLS handshake of the browsers, which the OpenSSL of the base system cannot make),
#   nghttp2 1.63.0 (upstream pins 1.64 or lower: 1.65 dropped the priorities of RFC
#   7540 that the HTTP/2 of the browsers sends; az has 1.71.0), nghttp3 1.15.0 and
#   ngtcp2 1.20.0 with the patches of upstream (the HTTP/3 SETTINGS and the QUIC
#   transport parameters of the browsers; ngtcp2 with its crypto on that BoringSSL:
#   www/libnghttp3 and net/libngtcp2 of this tree have neither), curl 8.23.0 with the
#   patch of upstream (the impersonation itself);
# - the fixes these lack (files/bundled-*.patch): nghttp2 CVE-2026-27135 (upstream
#   943b64c and 5c7df8f of 1.68.1, as RHEL 10 and Debian 13 carry them), ngtcp2
#   CVE-2026-40170 (upstream 708a764 of 1.22.1: qlog, which curl writes with QLOGDIR),
#   and in curl the conncache fix of ftp/curl (upstream ef6b17c, after 8.23.0);
# - the program on the shared library (upstream links the static one into it as well):
#   one copy of the code; no static libraries (the official port installs
#   lib/libcurl-impersonate.a and lib/curl-impersonate/*.a): ftp/py-curl-cffi links
#   the shared one;
# - our CFLAGS (-O3, the -march of the level) and LDFLAGS given to every build inside
#   (upstream gives the CFLAGS to BoringSSL and curl only), checked after the build;
#   the jobs of the framework (SUBJOBS);
# - the CA certificates of the base system (/etc/ssl/certs), as ftp/curl (the official
#   port takes what the build machine has);
# - curl-impersonate/2.3.2 in the version of curl (curl_version(), -V), not "local"
#   (no git in the build);
# - the program and the library stripped.
# The rest is upstream's build for FreeBSD: HTTP/2, HTTP/3 and HTTP/3 proxies, ECH with
# the HTTPS records, brotli, zstd, zlib, WebSockets, the export of SSL sessions, IPv6;
# no SCP and SFTP, LDAP, RTMP, GSS-API. The wrappers curl_<browser> are POSIX sh
# (#!/bin/sh): no bash. The layout of the official port (include/curl-impersonate,
# lib/libcurl-impersonate.so, bin/curl-impersonate-config,
# libdata/pkgconfig/libcurl-impersonate.pc), so that ftp/py-curl-cffi, the official port
# as it is (ours: Mk/az-official.mk), builds on it.

PORTNAME=	curl-impersonate
DISTVERSIONPREFIX=	v
DISTVERSION=	2.3.2
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	ftp
MASTER_SITES=	https://github.com/google/boringssl/archive/:boringssl \
		https://github.com/curl/curl/archive/:curl \
		https://github.com/nghttp2/nghttp2/releases/download/v1.63.0/:nghttp2 \
		https://github.com/ngtcp2/ngtcp2/releases/download/v1.20.0/:ngtcp2 \
		https://github.com/ngtcp2/nghttp3/releases/download/v1.15.0/:nghttp3
DISTFILES=	${BORING_SSL_COMMIT}.zip:boringssl \
		curl-8_23_0.tar.gz:curl \
		nghttp2-1.63.0.tar.bz2:nghttp2 \
		ngtcp2-1.20.0.tar.bz2:ngtcp2 \
		nghttp3-1.15.0.tar.bz2:nghttp3
DIST_SUBDIR=	${PORTNAME}
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	Curl with impersonation (of azsupport/ports)
WWW=		https://curl-impersonate.readthedocs.io/en/latest/ \
		https://github.com/lexiforest/curl-impersonate \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

BROKEN_i386=	compilation fails: x86 assembly requires SSE2

# c-ares, brotli, zstd, libidn2 and libpsl of az, to build and to run (by a file: no
# ldconfig hints for /usr/local/az/lib)
AZ_CI_LIBS=	libbrotlidec.so libcares.so libidn2.so libpsl.so libzstd.so
BUILD_DEPENDS=	${AZ_CI_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}
RUN_DEPENDS=	${AZ_CI_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}

# no localbase (no library of /usr/local/lib is linked) and no ssl (the TLS library is
# the BoringSSL inside; nothing of OpenSSL is linked)
USES=		cmake pkgconfig
USE_GITHUB=	yes
GH_ACCOUNT=	lexiforest

BORING_SSL_COMMIT=	156c7b75ae9b8c3b3f847acf264f17594c3859fb

# AZ_INCLUDE_DIR, AZ_LIB_DIR and BASE_ZLIB_LIBRARY: files/patch-CMakeLists.txt
CMAKE_ARGS=	-DAZ_INCLUDE_DIR:PATH=${WRKDIR}/az-include \
		-DAZ_LIB_DIR:PATH=${AZ_PREFIX}/lib \
		-DBASE_ZLIB_LIBRARY:FILEPATH=/usr/lib/libz.so \
		-DCURL_CA_BUNDLE:STRING=none \
		-DCURL_CA_PATH:STRING=/etc/ssl/certs \
		-DCURL_IMPERSONATE_VERSION:STRING=${DISTVERSION} \
		-DSUBJOBS:STRING=${MAKE_JOBS_NUMBER}
# the run path of the libraries of az (files/patch-CMakeLists.txt gives the linker
# flags to curl)
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

USE_LDCONFIG=	yes

post-patch:
	@${RLN} ${DISTDIR}/${DIST_SUBDIR}/${BORING_SSL_COMMIT}.zip ${WRKSRC}/${BORING_SSL_COMMIT}.zip
	@${RLN} ${DISTDIR}/${DIST_SUBDIR}/curl-8_23_0.tar.gz ${WRKSRC}/curl-8_23_0.tar.gz
	@${RLN} ${DISTDIR}/${DIST_SUBDIR}/nghttp2-1.63.0.tar.bz2 ${WRKSRC}/nghttp2-1.63.0.tar.bz2
	@${RLN} ${DISTDIR}/${DIST_SUBDIR}/ngtcp2-1.20.0.tar.bz2 ${WRKSRC}/ngtcp2-1.20.0.tar.bz2
	@${RLN} ${DISTDIR}/${DIST_SUBDIR}/nghttp3-1.15.0.tar.bz2 ${WRKSRC}/nghttp3-1.15.0.tar.bz2
	# the fixes of the builds inside (files/bundled-*.patch): their patches in patches/
	${CP} ${FILESDIR}/bundled-nghttp2.patch ${WRKSRC}/patches/nghttp2.patch
	${CAT} ${FILESDIR}/bundled-ngtcp2.patch >> ${WRKSRC}/patches/ngtcp2.patch
	${CAT} ${FILESDIR}/bundled-curl.patch >> ${WRKSRC}/patches/curl.patch

# the headers of c-ares, brotli, zstd, libidn2 and libpsl of az and of zlib of the base
# system alone in a directory of the work: no other header of az or of /usr/include (the
# OpenSSL of the base system) comes before those of BoringSSL
pre-configure:
	@${REINPLACE_CMD} \
		-e 's|https://github.com/google/boringssl/archive/$${BORINGSSL_COMMIT}.zip|file://$${CMAKE_SOURCE_DIR}/$${BORINGSSL_COMMIT}.zip|' \
		-e 's|https://github.com/nghttp2/nghttp2/releases/download/v$${NGHTTP2_VERSION}/nghttp2-$${NGHTTP2_VERSION}.tar.bz2|file://$${CMAKE_SOURCE_DIR}/nghttp2-$${NGHTTP2_VERSION}.tar.bz2|' \
		-e 's|https://github.com/ngtcp2/ngtcp2/releases/download/v$${NGTCP2_VERSION}/ngtcp2-$${NGTCP2_VERSION}.tar.bz2|file://$${CMAKE_SOURCE_DIR}/ngtcp2-$${NGTCP2_VERSION}.tar.bz2|' \
		-e 's|https://github.com/ngtcp2/nghttp3/releases/download/v$${NGHTTP3_VERSION}/nghttp3-$${NGHTTP3_VERSION}.tar.bz2|file://$${CMAKE_SOURCE_DIR}/nghttp3-$${NGHTTP3_VERSION}.tar.bz2|' \
		-e 's|https://github.com/curl/curl/archive/$${CURL_VERSION}.tar.gz|file://$${CMAKE_SOURCE_DIR}/$${CURL_VERSION}.tar.gz|' \
		${WRKSRC}/CMakeLists.txt
	@${MKDIR} ${WRKDIR}/az-include
	${LN} -sf ${AZ_PREFIX}/include/ares*.h ${AZ_PREFIX}/include/brotli \
		${AZ_PREFIX}/include/idn2.h ${AZ_PREFIX}/include/libpsl.h \
		${AZ_PREFIX}/include/zstd.h ${AZ_PREFIX}/include/zstd_errors.h \
		/usr/include/zlib.h /usr/include/zconf.h ${WRKDIR}/az-include/

# our CFLAGS in every build inside (the cache of each), shown in the log
post-build:
.for d in boringssl nghttp2 nghttp3 ngtcp2 curl
	@${ECHO_MSG} "===> ${d}: $$(${GREP} '^CMAKE_C_FLAGS:' ${BUILD_WRKSRC}/deps/build/${d}/CMakeCache.txt)"
	@for f in ${CFLAGS}; do \
		${GREP} '^CMAKE_C_FLAGS:' ${BUILD_WRKSRC}/deps/build/${d}/CMakeCache.txt | ${GREP} -qF -- "$$f" || \
		{ ${ECHO_MSG} "${d}: built without $$f of the CFLAGS of the port"; exit 1; }; \
	done
.endfor

post-install:
	@${RM} -r ${STAGEDIR}${PREFIX}/lib/CMakeFiles
	@${RM} ${STAGEDIR}${PREFIX}/LICENSE*
	# move curl headers to include/curl-impersonate, before https://github.com/lexiforest/curl-impersonate/pull/300 lands
	@${MV} ${STAGEDIR}${PREFIX}/include/curl/*.h ${STAGEDIR}${PREFIX}/include/curl-impersonate
	@${RMDIR} ${STAGEDIR}${PREFIX}/include/curl
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/curl-impersonate \
		${STAGEDIR}${PREFIX}/lib/libcurl-impersonate.so.4.*
# the library: c-ares, brotli, zstd, libidn2 and libpsl of az by its run path (that
# alone), zlib of the base system, no OpenSSL and no nghttp2, nghttp3 or ngtcp2 of a
# package, none of the symbols of what is built in exported, curl_easy_impersonate
# exported; the program: the library, the same run path
.for f in lib/libcurl-impersonate.so.4 bin/curl-impersonate
	@${READELF} -d ${STAGEDIR}${PREFIX}/${f} | ${GREP} -E -q '(RUNPATH|RPATH).*\[${AZ_PREFIX}/lib\]' || \
		{ ${ECHO_MSG} "${f}: its run path is not ${AZ_PREFIX}/lib alone"; ${FALSE}; }
.endfor
.for l in libcares libbrotlidec libbrotlicommon libidn2 libpsl libzstd libz
	@${READELF} -d ${STAGEDIR}${PREFIX}/lib/libcurl-impersonate.so.4 | ${GREP} -q 'Shared library: \[${l}\.so' || \
		{ ${ECHO_MSG} "lib/libcurl-impersonate.so.4 does not link ${l}"; ${FALSE}; }
.endfor
	@! ${READELF} -d ${STAGEDIR}${PREFIX}/lib/libcurl-impersonate.so.4 | \
		${GREP} -E 'Shared library: \[lib(ssl|crypto|nghttp2|nghttp3|ngtcp2)' || \
		{ ${ECHO_MSG} "lib/libcurl-impersonate.so.4 links a library it has inside"; ${FALSE}; }
	@! ${NM} -D --defined-only ${STAGEDIR}${PREFIX}/lib/libcurl-impersonate.so.4 | \
		${GREP} -E ' (nghttp2_|nghttp3_|ngtcp2_|SSL_|EVP_)' || \
		{ ${ECHO_MSG} "lib/libcurl-impersonate.so.4 exports what it has inside"; ${FALSE}; }
	@${NM} -D --defined-only ${STAGEDIR}${PREFIX}/lib/libcurl-impersonate.so.4 | ${GREP} -q ' curl_easy_impersonate$$' || \
		{ ${ECHO_MSG} "lib/libcurl-impersonate.so.4 does not export curl_easy_impersonate"; ${FALSE}; }
	@${READELF} -d ${STAGEDIR}${PREFIX}/bin/curl-impersonate | ${GREP} -q 'Shared library: \[libcurl-impersonate\.so\.4\]' || \
		{ ${ECHO_MSG} "bin/curl-impersonate does not link libcurl-impersonate.so.4"; ${FALSE}; }

.include <bsd.port.mk>
