# ftp/curl: the curl of azsupport/ports in the place of the official ftp/curl
# (the design: the head of azsupport/static/Makefile), the package curl of tools/build-az.sh
# of azsupport/php-src: bin/curl and lib/libcurl.so.4 (only curl_* exported),
# the libcurl of every package (the PHP module curl, git and the others that link
# libcurl.so: one libcurl, aZ 10.11.2026). Built by tools/curl-build.sh
# (build_curl_program of build-deps.sh of php-src) against the shared libraries of
# azsupport (nghttp2, brotli, zstd, libidn2, libpsl, libssh2: a port azsupport/<name> each,
# with the run path /usr/local/azsupport/lib: our ports link each other's shared libraries,
# aZ 10.11.2026)
# and OpenSSL and zlib of the base system, with the options of the official port
# (its CONFIGURE_ARGS and default options) and SCP and SFTP, without GSSAPI (the
# libraries of azsupport do not have it). The release is the bundled curl of azsupport
# (azsupport/static/files/curl.conf), with the same patch of the official port
# (azsupport/static/files/curl/curl-<version>.patch, one copy for both), extracted and
# patched by the framework.

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

# the libraries of azsupport libcurl.so.4 links, to build and to run (by a file: no ldconfig
# hints for /usr/local/azsupport/lib; their interfaces in its hash, tools/build.sh); the patch
# of curl of azsupport/static is in its hash as its EXTRA_PATCHES
AZSUPPORT_CURL_LIBS=	brotli:libbrotlidec.so libidn2:libidn2.so libpsl:libpsl.so \
		libssh2:libssh2.so nghttp2:libnghttp2.so zstd:libzstd.so
BUILD_DEPENDS=	${AZSUPPORT_CURL_LIBS:@l@${AZSUPPORT_PREFIX}/lib/${l:C/^[^:]*://}:azsupport/${l:C/:.*//}@} \
		python3:lang/python3
RUN_DEPENDS=	${AZSUPPORT_CURL_LIBS:@l@${AZSUPPORT_PREFIX}/lib/${l:C/^[^:]*://}:azsupport/${l:C/:.*//}@}

USES=		gmake perl5 pkgconfig tar:xz
USE_PERL5=	build

EXTRA_PATCHES=	${.CURDIR:H:H}/azsupport/static/files/curl/curl-${PORTVERSION}.patch

.include "${.CURDIR:H:H}/azsupport/static/Makefile.common"

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZSUPPORT_ENV} ${SH} ${AZSUPPORT_TOOLS}/curl-build.sh ${WRKSRC}

do-install:
	@${AZSUPPORT_COPY_STAGE}

post-install:
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
