# ftp/curl: the curl of azsupport/ports in the place of the official ftp/curl
# (the design: the head of az/az/Makefile), the package curl of tools/build-az.sh
# of azsupport/php-src: bin/curl and lib/libcurl.so.4 (only curl_* exported),
# the libcurl of every package (the PHP module curl, git and the others that link
# libcurl.so: one libcurl, aZ 10.11.2026). Built by tools/curl-build.sh
# (build_curl_program of build-deps.sh of php-src) against the shared tree of the
# package az (nghttp2, brotli, zstd, libidn2, libpsl, libssh2, with the run path
# /usr/local/az/lib: our ports link each other's shared libraries, aZ 10.11.2026)
# and OpenSSL and zlib of the base system, with the options of the official port
# (its CONFIGURE_ARGS and default options) and SCP and SFTP, without GSSAPI (the
# libraries of az do not have it). The release is the bundled curl of az
# (az/az/files/curl.conf), with the same patch of the official port
# (az/az/files/curl/curl-<version>.patch, one copy for both), extracted and
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

# the libraries of az in its hash (tools/build.sh): those up to curl in deps.conf,
# all it links (the bundled ones, curl and its patch), more than the file of its
# dependency names; az at run time too (the libraries libcurl.so.4 links)
AZ_HASH_LIBS=	curl
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libnghttp2.so:az/az \
		python3:lang/python3
RUN_DEPENDS=	${AZ_PREFIX}/lib/libnghttp2.so:az/az

USES=		gmake perl5 pkgconfig tar:xz
USE_PERL5=	build

EXTRA_PATCHES=	${.CURDIR:H:H}/az/az/files/curl/curl-${PORTVERSION}.patch

.include "${.CURDIR:H:H}/az/az/Makefile.common"

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${SH} ${AZ_TOOLS}/curl-build.sh ${WRKSRC}

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
