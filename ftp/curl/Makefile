# ftp/curl: the curl of azsupport/ports in the place of the official ftp/curl
# (the design: the head of azsupport/azsupport/Makefile), the package curl of tools/build-az.sh
# of azsupport/php-src: bin/curl and lib/libcurl.so.4 (only curl_* exported),
# the libcurl of every package (the PHP module curl, git and the others that link
# libcurl.so: one libcurl, aZ 10.11.2026). Built by tools/curl-build.sh
# (build_curl_program of build-deps.sh of php-src) against the shared tree of the
# package azsupport (nghttp2, brotli, zstd, libidn2, libpsl, libssh2, with the run path
# /usr/local/azsupport/lib: our ports link each other's shared libraries, aZ 10.11.2026)
# and OpenSSL and zlib of the base system, with the options of the official port
# (its CONFIGURE_ARGS and default options) and SCP and SFTP, without GSSAPI (the
# libraries of azsupport do not have it). The release is the bundled curl of azsupport
# (azsupport/azsupport/files/curl.conf), with the same patch of the official port
# (azsupport/azsupport/files/curl/curl-<version>.patch, one copy for both), extracted and
# patched by the framework. Compiled by GCC 16 (USES=azgcc; aZ, 27.11.2026 10:07: «да»):
# lib-bench3.sh of 26.11.2026 found libcurl 4.0% faster with it than with clang 23
# (docs/compiler-choice/decision.md of azsupport/azsupport; the program curl within the
# spread): tools/curl-build.sh takes AZSUPPORT_CC, gcc<N> of Mk/Uses/azgcc.mk with
# -static-libgcc, as the CC of its configure, and the flags of GCC of tools/azsupport-build.sh
# (libtool hands no -pie to the link of libcurl.so: bin/curl alone is PIE). The static
# libcurl.a of azsupport/azsupport, for the PHP of the servers, keeps the compiler of that port.

PORTNAME=	curl
PORTVERSION=	8.23.0
CATEGORIES=	ftp net www
MASTER_SITES=	https://curl.se/download/ \
		https://github.com/curl/curl/releases/download/curl-${PORTVERSION:S|.|_|g}/

COMMENT=	Command line tool and library for transferring data with URLs (of azsupport/ports)
WWW=		https://curl.se/ \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

# the libraries of azsupport in its hash (tools/build.sh) besides nghttp2: those libcurl.so.4
# links (their interfaces); the patch of curl of azsupport/azsupport is in its hash as its
# EXTRA_PATCHES; azsupport at run time too
AZSUPPORT_HASH_LIBS=	brotli libidn2 libpsl libssh2 zstd
BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libnghttp2.so:azsupport/azsupport \
		python3:lang/python3
RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libnghttp2.so:azsupport/azsupport

USES=		azgcc gmake perl5 pkgconfig tar:xz
USE_PERL5=	build

EXTRA_PATCHES=	${.CURDIR:H:H}/azsupport/azsupport/files/curl/curl-${PORTVERSION}.patch

.include "${.CURDIR:H:H}/azsupport/azsupport/Makefile.common"

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZSUPPORT_ENV} AZSUPPORT_CC="${CC} -static-libgcc" \
		${SH} ${AZSUPPORT_TOOLS}/curl-build.sh ${WRKSRC}

do-install:
	@${AZSUPPORT_COPY_STAGE}

post-install:
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
