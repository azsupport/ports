# www/node24 of azsupport/ports: Node.js 24 (aZ, 11.11.2026: our node24 with npm and
# yarn, for yt-dlp and Kibana 6), the official port (its patches, Makefile.version,
# pkg-plist, pkg-descr) on the shared libraries of az, with the run path
# /usr/local/az/lib (our ports link each other's shared libraries: aZ,
# 10.11.2026): brotli, c-ares, ICU, nghttp2, libuv, zstd and SQLite of az (az
# builds SQLite with the session extension that node:sqlite needs), instead of
# archivers/brotli, dns/c-ares, devel/icu, www/libnghttp2, devel/libuv,
# archivers/zstd and databases/sqlite3; ada, llhttp, nbytes, nghttp3, ngtcp2,
# simdjson, uvwasi and hdr_histogram, which Node.js bundles, of the ports of this
# tree (aZ, 11.11.2026: the official ones as they are, uvwasi on the libuv of az);
# OpenSSL (with the CA store of the base system) and zlib of the base system.
# GoogleTest stays bundled, so the package takes no devel/googletest (a LIB_DEPENDS
# of the official port): node uses its header gtest_prod.h only, and its library
# goes into the test program cctest only, which is not installed. No DTrace (the
# configure of Node.js has it off on FreeBSD), JIT on, no documents (DOCS off).
#
# Makefile.version and distinfo: 24.22.3 (11.11.2026), ahead of the official port at
# 24.22.2 (freebsd-ports at the pinned commit and main of 12.11.2026), for the
# security release of Node.js of November 2026 (aZ, 12.11.2026: node patched fully;
# a newer version for vulnerabilities that touch us): CVE-2026-123828,
# CVE-2026-123829, CVE-2026-123862, CVE-2026-123863, CVE-2026-123864,
# CVE-2026-123865, CVE-2026-123866, CVE-2026-123867, CVE-2026-123868,
# CVE-2026-123871, CVE-2026-123872, CVE-2026-123873, CVE-2026-123874,
# CVE-2026-123875, CVE-2026-123877 and CVE-2026-126051. The distinfo from the
# distinfo.yml run 43239019280 (the tarball of nodejs.org against its
# SHASUMS256.txt). The patches of the official port apply to it as to 24.22.2 (the
# files they touch are the same); the libraries stay: its SQLite 3.54.1 and brotli
# 1.2.1 are those of az, and its llhttp 9.4.4 fixes the SIMD code of arm64 and
# WebAssembly only, so www/llhttp 9.4.3 parses as it does on amd64 (see
# www/node18/Makefile).

PORTNAME=	node
PORTVERSION=	${NODEJS_PORTVERSION}
PORTREVISION=	${AZ_STAMP:U0}
DISTVERSIONPREFIX=	v
CATEGORIES=	www
MASTER_SITES=	https://nodejs.org/dist/v${PORTVERSION}/
PKGNAMESUFFIX=	${PORTVERSION:R:R}

MAINTAINER=	github@azsupport.com
COMMENT=	V8 JavaScript for client and server (of azsupport/ports)
WWW=		https://nodejs.org/ \
		https://github.com/nodejs/node \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

BROKEN_SSL=	libressl libressl-devel
BROKEN_SSL_REASON=	Node.js ${PORTVERSION:R:R}.x requires OpenSSL or the BUNDLED_SSL option enabled
ONLY_FOR_ARCHS=	aarch64 amd64 armv6 armv7 i386 powerpc64 powerpc64le

# the libraries of az that node links, with their run path
AZ_NODE_LIBS=	libbrotlidec.so libcares.so libicui18n.so libnghttp2.so libsqlite3.so \
		libuv.so libzstd.so
BUILD_DEPENDS=	${AZ_NODE_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}
LIB_DEPENDS=	libada.so:devel/libada \
		libhdr_histogram.so:graphics/hdr_histogram \
		libllhttp.so:www/llhttp \
		libnbytes.so:www/nbytes \
		libnghttp3.so:www/libnghttp3 \
		libngtcp2.so:net/libngtcp2 \
		libsimdjson.so:devel/simdjson \
		libuvwasi.so:devel/uvwasi
RUN_DEPENDS=	${AZ_NODE_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@} \
		corepack-node24>=0:www/corepack-node24

USES=		compiler:c++20-lang gmake localbase pkgconfig python:build shebangfix tar:xz

# merve stays bundled: devel/merve links the system libsimdutf, while node
# bundles and exports its own simdutf. rtld binds libsimdutf's internal calls
# to node's copy, the dispatch tables disagree, and CJS export lexing jumps
# to garbage (SIGBUS). Revisit together with --shared-simdutf.
CONFIGURE_ARGS=	--prefix=${PREFIX:S|^${DESTDIR}||} \
		--shared-ada \
		--shared-brotli \
		--shared-cares \
		--shared-hdr-histogram \
		--shared-http-parser \
		--shared-libuv \
		--shared-nbytes \
		--shared-nghttp2 \
		--shared-nghttp3 \
		--shared-ngtcp2 \
		--shared-simdjson \
		--shared-sqlite \
		--shared-uvwasi \
		--shared-uvwasi-includes=${LOCALBASE}/include \
		--shared-zlib \
		--shared-zstd \
		--with-intl=system-icu \
		--without-corepack \
		--without-npm
# The configure of node takes the include directories and the -L of the shared
# libraries from pkg-config: those of az first (brotli, c-ares, ICU, nghttp2,
# libuv, zstd, sqlite3), then those of the ports of this tree, then libssl and
# zlib of the base system. The -L of az goes before the -L${LOCALBASE}/lib of
# USES=localbase, so that a library of the same name in ${LOCALBASE}/lib (an
# official package of the build machine) is not taken instead.
CONFIGURE_ENV=	PKG_CONFIG_LIBDIR=${AZ_PREFIX}/lib/pkgconfig:${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib
HAS_CONFIGURE=	yes
MAKE_ENV=	CC.host="${CCACHE_BIN} ${CC}" \
		CFLAGS.host="${CFLAGS}" \
		CXX.host="${CCACHE_BIN} ${CXX}" \
		CXXFLAGS.host="${CXXFLAGS}" \
		LDFLAGS.host="${LDFLAGS}" \
		LINK.host="${CXX}"
REINPLACE_ARGS=	-i ''

CONFLICTS_INSTALL=	node[0-9][0-9]

SHEBANG_FILES=	deps/v8/third_party/inspector_protocol/*.py \
		deps/v8/tools/*.py \
		tools/*.py \
		tools/inspector_protocol/*.py

OPTIONS_DEFINE=	BUNDLED_SSL DOCS JIT
OPTIONS_DEFAULT=JIT
OPTIONS_SUB=	yes
BUNDLED_SSL_DESC=	Use bundled OpenSSL implementation from node.js
JIT_DESC=		Use Just In Time compiler

BUNDLED_SSL_CONFIGURE_OFF=	--openssl-use-def-ca-store --shared-openssl
BUNDLED_SSL_USES_OFF=	ssl
JIT_CONFIGURE_OFF=	--v8-lite-mode

.include "Makefile.version"
.include <bsd.port.options.mk>

.if ${PORT_OPTIONS:MBUNDLED_SSL} && ${ARCH} != amd64
CONFIGURE_ARGS+=--openssl-no-asm
.endif

post-patch:
	@${REINPLACE_CMD} -e 's|/usr/local|${LOCALBASE}|' ${WRKSRC}/tools/v8_gypfiles/v8.gyp
# Clean up bundled libraries (not deps/googletest: see the top)
	@${RM} -r ${WRKSRC}/deps/ada/
	@${RM} -r ${WRKSRC}/deps/brotli/
	@${RM} -r ${WRKSRC}/deps/cares/
	@${RM} -r ${WRKSRC}/deps/corepack/
	@${RM} -r ${WRKSRC}/deps/histogram/
	@${RM} -r ${WRKSRC}/deps/icu-small/
	@${RM} -r ${WRKSRC}/deps/llhttp/
	@${RM} -r ${WRKSRC}/deps/nbytes/
	@${RM} -r ${WRKSRC}/deps/nghttp2/
	@${RM} -r ${WRKSRC}/deps/ngtcp2/
	@${RM} -r ${WRKSRC}/deps/npm/
	@${RM} -r ${WRKSRC}/deps/simdjson/
	@${RM} -r ${WRKSRC}/deps/sqlite/
	@${RM} -r ${WRKSRC}/deps/uv/
	@${RM} -r ${WRKSRC}/deps/uvwasi/
	@${RM} -r ${WRKSRC}/deps/zlib/
	@${RM} -r ${WRKSRC}/deps/zstd/

post-configure:
	# Post-process Makefile and *.mk files created by node-gyp and remove
	# all occurrences of -I${LOCALBASE}/include. C*FLAGS include this
	# before all -I../deps/* for bundled code. This can cause build
	# breakages if the dependency is installed in ${LOCALBASE}. The
	# USES+=localbase above will ensure that we pick up includes for real
	# external dependencies.
	@${FIND} ${WRKSRC}/out -type f -print0 | ${XARGS} -0 ${REINPLACE_CMD} -e 's|-I${LOCALBASE}/include||g'
# the include directory of az, as pkg-config gave it
	@${GREP} -q -- '${AZ_PREFIX}/include' ${WRKSRC}/config.gypi || \
		{ ${ECHO_MSG} "config.gypi: no include directory ${AZ_PREFIX}/include (pkg-config of az)"; ${FALSE}; }

post-install:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/node
# Fail if two simdutf copies end up in one process (node exports its bundled
# simdutf; a DSO linking the system libsimdutf.so, e.g. libmerve, then binds
# to the wrong one and CJS export lexing SIGBUSes). Importing a CommonJS
# module from ESM runs that lexer; stdin avoids a temp file.
	${ECHO_CMD} 'exports.ok = 1' | ${STAGEDIR}${PREFIX}/bin/node --input-type=module -e 'import "/dev/stdin"'
# bin/node: the libraries of az by its run path, those of our ports, the base
# system's OpenSSL and zlib (nghttp3 and ngtcp2 are for QUIC, which this build
# has not: not asked for)
	@${READELF} -d ${STAGEDIR}${PREFIX}/bin/node | ${GREP} -E -q '(RUNPATH|RPATH).*${AZ_PREFIX}/lib' || \
		{ ${ECHO_MSG} "bin/node has no run path ${AZ_PREFIX}/lib"; ${FALSE}; }
.for l in libbrotlidec libcares libicui18n libnghttp2 libsqlite3 libuv libzstd libada libllhttp \
	libnbytes libsimdjson libuvwasi libhdr_histogram libssl libcrypto libz
	@${READELF} -d ${STAGEDIR}${PREFIX}/bin/node | ${GREP} -q 'Shared library: \[${l}\.so' || \
		{ ${ECHO_MSG} "bin/node does not link ${l}"; ${FALSE}; }
.endfor

post-install-BUNDLED_SSL-on:
	cd ${STAGEDIR}${PREFIX} && ${FIND} include/node/openssl/ -type f >> ${TMPPLIST}

.include <bsd.port.mk>
