# ftp/curl: the curl of azsupport/ports in the place of the official ftp/curl
# (the design: the head of az/az/Makefile), the package curl of tools/build-az.sh
# of azsupport/php-src: bin/curl (static) and lib/libcurl.so.4 with the
# libraries inside (only curl_* exported), so that both need only libz and libthr
# of the base system, and git and the other packages that link libcurl.so get
# it. Built by tools/curl-build.sh (build_curl_program of build-deps.sh of
# php-src) against the static tree of the package az, with the options of the
# official port (its CONFIGURE_ARGS and default options; no SCP and SFTP, no
# GSSAPI: the libraries of az do not have them). The release is the bundled curl
# of az (az/az/files/curl.conf), with the same patch of the official port
# (az/az/files/curl/curl-<version>.patch, one copy for both), extracted and
# patched by the framework. A static program: no RUN_DEPENDS.

PORTNAME=	curl
PORTVERSION=	8.23.0
CATEGORIES=	ftp net www
MASTER_SITES=	https://curl.se/download/ \
		https://github.com/curl/curl/releases/download/curl-${PORTVERSION:S|.|_|g}/

COMMENT=	Command line tool and library for transferring data with URLs (static, of azsupport/ports)
WWW=		https://curl.se/ \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	${AZ_STATIC}/lib/libnghttp2.a:az/az \
		python3:lang/python3

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
