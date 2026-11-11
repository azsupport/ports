# www/node18 of azsupport/ports: Node.js 18.20.8, the last 18.x (end of life since
# 30.04.2025), for a legacy project (aZ, 11.11.2026), back in the ports (the official
# port went on 2025-09-03): the official port of its last state (freebsd-ports
# d0f03d433e19, the parent of its removal f9d9e0a5dd66, the same as 2025Q3) with its
# patches, Makefile.version, distinfo and pkg-descr, made as our www/node24: on the
# shared libraries of az, with the run path /usr/local/az/lib (our ports link each
# other's shared libraries: aZ, 10.11.2026): brotli, c-ares, ICU, nghttp2 and libuv
# of az instead of archivers/brotli, dns/c-ares, devel/icu, www/libnghttp2 and
# devel/libuv (Node 18 takes them newer than it bundles: the official port built
# with those of the ports, ICU 76 with its patch-icu); llhttp of www/llhttp (9.4.3,
# the llhttp the patches of SUSE below put into Node 18: llhttp 9 fills its
# llhttp_settings_t in another order than the llhttp 6.1.1 of 18.20.8, which
# src/node_http_parser.cc of 18.20.8 does not compile with); OpenSSL (with the CA
# store of the base system, as node24: no security/ca_root_nss) and zlib of the base
# system. Bundled, as Node 18 has no option for a shared one: ada 2.8.0 (no
# --shared-ada; our devel/libada is ada 3), uvwasi 0.0.19 (no --shared-uvwasi; it
# builds on the uv.h of az), HdrHistogram, simdutf and base64; GoogleTest goes into
# the test program cctest only, which is not installed; ngtcp2 and nghttp3 are not
# built (QUIC: Node 18 has it only with the QUIC API of an OpenSSL fork). Node 18
# has no SQLite and no zstd. npm, Yarn and corepack: www/npm-node18,
# www/yarn-node18 and www/corepack-node18 (aZ, 11.11.2026: one of node18 and node24,
# with their npm, yarn and corepack; CONFLICTS_INSTALL). No DTrace (the configure of
# Node.js has it off on FreeBSD; so no objdump of devel/binutils either, a
# BUILD_DEPENDS of the official port for tools/genv8constants.py of DTrace builds
# only), JIT on, no documents (DOCS off). pkg-plist: that of the official port
# without corepack and, as node24, without the headers of the bundled OpenSSL,
# which post-install-BUNDLED_SSL-on adds.
#
# The fixes of the vulnerabilities after the end of life (aZ, 11.11.2026: the
# patches of the distributions that still ship Node 18), as SUSE has them for the
# nodejs18 18.20.8 of SUSE Linux Enterprise 15 SP4 LTSS (Adam Majer, 15.09.2026;
# https://api.opensuse.org/public/source/SUSE:SLE-15-SP4:Update/nodejs18.46615), in
# files/suse: CVE-2026-21637.patch, CVE-2025-59465.patch and cves.patch (without the
# parts the libraries of az and www/llhttp take the place of: its header says
# which), applied in the order of SUSE (EXTRA_PATCHES, before the patches of the
# official port, which touch other files): CVE-2025-23166, CVE-2025-23167 (llhttp
# 9), CVE-2025-55131, CVE-2025-59465, CVE-2025-59466, CVE-2026-21637,
# CVE-2026-21710, CVE-2026-21713, CVE-2026-21714, CVE-2026-21717, CVE-2026-48618,
# CVE-2026-48619, CVE-2026-48928, CVE-2026-48930, CVE-2026-48931, CVE-2026-48932
# and CVE-2026-58044 (one fix), CVE-2026-48933, CVE-2026-48934, CVE-2026-48937,
# CVE-2026-56846, CVE-2026-56848, CVE-2026-56850, CVE-2026-58040, CVE-2026-58042,
# CVE-2026-58045; undici 6.28.0 for CVE-2026-6733, CVE-2026-9679, CVE-2026-11525,
# CVE-2026-12151, CVE-2026-15157, CVE-2026-16728, CVE-2026-16729, CVE-2026-22036.
# They are all the fixes of Debian 12 for its nodejs 18.20.4 (18.20.4+dfsg-1~deb12u3,
# 16.08.2026) and more. Open on 11.11.2026 (no distribution has them for Node 18):
# those of the Node.js release of 21.10.2026, CVE-2026-105481, CVE-2026-105482,
# CVE-2026-106069, CVE-2026-106072 and CVE-2026-106074, and the undici releases
# after 6.28.0. The others of 2025 and 2026 are of the Permission Model, node:sqlite,
# Windows or code of Node 20 and later; CVE-2026-111497 is in the brotli of 18.20.8,
# not in the brotli 1.2.1 of az.

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
AZ_NODE_LIBS=	libbrotlidec.so libcares.so libicui18n.so libnghttp2.so libuv.so
BUILD_DEPENDS=	${AZ_NODE_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@}
LIB_DEPENDS=	libllhttp.so:www/llhttp
RUN_DEPENDS=	${AZ_NODE_LIBS:@l@${AZ_PREFIX}/lib/${l}:az/az@} \
		corepack-node18>=0:www/corepack-node18

# python: the configure of Node 18 takes Python 3.6 to 3.13
USES=		compiler:c++11-lib gmake localbase pkgconfig python:3.9-3.13,build \
		shebangfix tar:xz

# the security fixes (see the top), in the order of SUSE
EXTRA_PATCHES=	${FILESDIR}/suse/CVE-2026-21637.patch:-p1 \
		${FILESDIR}/suse/CVE-2025-59465.patch:-p1 \
		${FILESDIR}/suse/cves.patch:-p1

# llhttp: Node 18 links -lhttp_parser without --shared-http-parser-libname and has
# no pkg-config name for it, so no -L either: the -L${LOCALBASE}/lib of
# USES=localbase is in LIBS, which the makefiles of gyp set for each target
# ("unable to find library -lllhttp": run 43053513194); it comes after the -L of az
# of LDFLAGS on the command line of the linker. llhttp.h comes from
# ${LOCALBASE}/include (USES=localbase).
CONFIGURE_ARGS=	--prefix=${PREFIX:S|^${DESTDIR}||} \
		--shared-brotli \
		--shared-cares \
		--shared-http-parser \
		--shared-http-parser-libname=llhttp \
		--shared-http-parser-libpath=${LOCALBASE}/lib \
		--shared-libuv \
		--shared-nghttp2 \
		--shared-zlib \
		--with-intl=system-icu \
		--without-corepack \
		--without-npm
# The configure of node takes the include directories and the -L of the shared
# libraries from pkg-config: those of az first (brotli, c-ares, ICU, nghttp2,
# libuv), then libssl and zlib of the base system. The -L of az goes before the
# -L${LOCALBASE}/lib of USES=localbase, so that a library of the same name in
# ${LOCALBASE}/lib (an official package of the build machine) is not taken instead.
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
.include <bsd.port.pre.mk>

.if ${COMPILER_TYPE} == clang && (${ARCH} == aarch64 || ${ARCH} == armv7 || ${ARCH:Mpowerpc64*})
CXXFLAGS+=	-Wno-error=enum-constexpr-conversion
.endif

.if ${PORT_OPTIONS:MBUNDLED_SSL} && ${ARCH} != amd64
CONFIGURE_ARGS+=--openssl-no-asm
.endif

post-patch:
	@${REINPLACE_CMD} -e 's|/usr/local|${LOCALBASE}|' ${WRKSRC}/tools/v8_gypfiles/v8.gyp
# Clean up bundled libraries (those above; not the ones Node 18 has no option for)
	@${RM} -r ${WRKSRC}/deps/brotli/
	@${RM} -r ${WRKSRC}/deps/cares/
	@${RM} -r ${WRKSRC}/deps/corepack/
	@${RM} -r ${WRKSRC}/deps/icu-small/
	@${RM} -r ${WRKSRC}/deps/llhttp/
	@${RM} -r ${WRKSRC}/deps/nghttp2/
	@${RM} -r ${WRKSRC}/deps/npm/
	@${RM} -r ${WRKSRC}/deps/uv/
	@${RM} -r ${WRKSRC}/deps/zlib/

post-configure:
	# Post-process Makefile and *.mk files created by node-gyp and remove
	# all occurrences of -I${LOCALBASE}/include. C*FLAGS include this
	# before all -I../deps/* for bundled code. This can cause build
	# breakages if the dependency is installed in ${LOCALBASE}. The
	# USES+=localbase # above will ensure that we pick up includes for real
	# external dependencies.
	@${FIND} ${WRKSRC}/out -type f -print0 | ${XARGS} -0 ${REINPLACE_CMD} -e "s|-I${LOCALBASE}/include||g"
# the include directory of az, as pkg-config gave it
	@${GREP} -q -- '${AZ_PREFIX}/include' ${WRKSRC}/config.gypi || \
		{ ${ECHO_MSG} "config.gypi: no include directory ${AZ_PREFIX}/include (pkg-config of az)"; ${FALSE}; }

post-install:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/node
# bin/node: the libraries of az by its run path, llhttp of www/llhttp, the base
# system's OpenSSL and zlib
	@${READELF} -d ${STAGEDIR}${PREFIX}/bin/node | ${GREP} -E -q '(RUNPATH|RPATH).*${AZ_PREFIX}/lib' || \
		{ ${ECHO_MSG} "bin/node has no run path ${AZ_PREFIX}/lib"; ${FALSE}; }
.for l in libbrotlidec libcares libicui18n libnghttp2 libuv libllhttp libssl libcrypto libz
	@${READELF} -d ${STAGEDIR}${PREFIX}/bin/node | ${GREP} -q 'Shared library: \[${l}\.so' || \
		{ ${ECHO_MSG} "bin/node does not link ${l}"; ${FALSE}; }
.endfor

post-install-BUNDLED_SSL-on:
	cd ${STAGEDIR}${PREFIX} && ${FIND} include/node/openssl/ -type f >> ${TMPPLIST}

.include <bsd.port.post.mk>
