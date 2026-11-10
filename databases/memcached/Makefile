# databases/memcached: the memcached of azsupport/ports in the place of the
# official databases/memcached (aZ, 10.11.2026): the official port with libevent
# the shared library of az, with the run path /usr/local/az/lib (our ports link
# each other's shared libraries: aZ, 10.11.2026), so that it takes no package but
# az (the official one takes libevent), without DOCS, DTRACE and SASL (the
# options of aZ's servers) and
# without TLS, which the official one has on FreeBSD; databases/memcached-openssl
# (PKGNAMESUFFIX -openssl, the same files) has it, on the OpenSSL of the base
# system.

PORTNAME=	memcached
DISTVERSION=	1.6.45
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	databases
MASTER_SITES=	http://www.memcached.org/files/

MAINTAINER=	github@azsupport.com
COMMENT?=	High-performance distributed memory object cache system (of azsupport/ports)
WWW=		https://memcached.org/ \
		https://github.com/azsupport/ports

LICENSE=	BSD3CLAUSE
LICENSE_FILE=	${WRKSRC}/COPYING

# libevent.so of az (its configure links -levent with -L<dir>/lib and -I<dir>/include;
# iconv is not used, so the GNU iconv.h there does not matter), its run path
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libevent.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libevent.so:az/az

USES=		autoreconf cpe pkgconfig shebangfix
USE_CSTD=	c99
USE_RC_SUBR=	memcached

SHEBANG_FILES=	scripts/memcached-tool

HAS_CONFIGURE=	yes
CONFIGURE_ARGS=	--disable-coverage \
		--program-prefix= \
		--with-libevent=${AZ_PREFIX}
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

MAKE_JOBS_UNSAFE=	yes

SUB_LIST+=	RC_SUBR_SUFFIX=${RC_SUBR_SUFFIX}

# Dtrace option disabled until it is fixed upstream
OPTIONS_DEFINE=		DOCS SASL
OPTIONS_DEFINE_amd64=	DTRACE
OPTIONS_DEFINE_powerpc64=	DTRACE
OPTIONS_DEFINE_powerpc64le=	DTRACE
OPTIONS_DEFAULT=	SASL
OPTIONS_DEFAULT_amd64=	DTRACE
OPTIONS_DEFAULT_powerpc64=	DTRACE
OPTIONS_DEFAULT_powerpc64le=	DTRACE
# the options of aZ's servers: none of the three (their helpers pass --disable-*)
OPTIONS_EXCLUDE=	DOCS DTRACE SASL

DTRACE_DESC=	Enable dtrace probes
SASL_DESC=	Enable SASL Authentication

DOCS_BUILD_DEPENDS=	xml2rfc:textproc/xml2rfc
DOCS_CONFIGURE_ENABLE=	docs
DTRACE_CONFIGURE_ENABLE=	dtrace
SASL_LIB_DEPENDS=	libsasl2.so:security/cyrus-sasl2
SASL_USES=	localbase:ldflags
SASL_CONFIGURE_ENABLE=	sasl

.include <bsd.port.pre.mk>

# TLS only in memcached-openssl
.if ${PKGNAMESUFFIX:U} == "-openssl"
CONFIGURE_ARGS+=	--enable-tls
USES+=			ssl
CONFLICTS_INSTALL=	memcached
.else
CONFLICTS_INSTALL=	memcached-openssl
.endif

.if ${ARCH} == amd64 || ${ARCH:Mpowerpc64*}
CONFIGURE_ARGS+=	--enable-64bit
.endif

post-install:
	${INSTALL_SCRIPT} ${WRKSRC}/scripts/memcached-tool ${STAGEDIR}${PREFIX}/bin

post-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}
.for i in protocol-binary-range.txt protocol-binary.txt protocol.txt \
		readme.txt threads.txt
	${INSTALL_DATA} ${WRKSRC}/doc/${i} ${STAGEDIR}${DOCSDIR}
.endfor

regression-test: test
test: build
	${MAKE} -C ${WRKSRC} test

.include <bsd.port.post.mk>
