# databases/postgresql18-contrib: the contrib modules of PostgreSQL 18 of azsupport/ports
# (databases/postgresql18-server: the design), without OpenSSL: all but pgcrypto and
# sslinfo; postgresql18-contrib-openssl with them, one of the two (aZ, 16.11.2026:
# «contrib и contrib-openssl»). xml2 on libxml2 and libxslt of az.

PORTNAME=	postgresql
CATEGORIES=	databases

COMMENT?=	The contrib utilities from the PostgreSQL distribution (of azsupport/ports)

MASTERDIR=	${.CURDIR}/../postgresql18-server

USES=		bison pgsql:${PORTVERSION:R}

BUILD_DIRS=	src/port src/include src/common contrib
INSTALL_DIRS=	contrib

# this port fails to build in parallel
MAKE_JOBS_UNSAFE=	yes

SLAVE_ONLY=	yes
COMPONENT=	-contrib
CONFIGURE_ARGS=	--disable-nls --with-uuid=bsd
LDFLAGS+=	-lpthread -L${PREFIX}/lib

OPTIONS_DEFINE=	DOCS OPENSSL XML
OPTIONS_DEFAULT=XML
.if defined(AZ_PG_OPENSSL)
OPTIONS_DEFAULT+=OPENSSL
.endif
OPTIONS_SUB=	yes

OPENSSL_DESC=		Build with OpenSSL support
OPENSSL_USES=		ssl
OPENSSL_CONFIGURE_WITH=	openssl

# libxml2 and libxslt of az (${WRKDIR}/az of the master); its flags given
AZ_PG_LIBS=		xml2 xslt
XML_CONFIGURE_WITH=	libxslt libxml
XML_CONFIGURE_ENV=	XML2_CFLAGS=-I${WRKDIR}/az/include/libxml2 \
			XML2_LIBS="-L${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib -lxml2"
XML_BUILD_DEPENDS=	${AZ_PREFIX}/lib/libxslt.so:az/az \
			${AZ_PREFIX}/lib/libxml2.so:az/az
XML_RUN_DEPENDS=	${AZ_PREFIX}/lib/libxslt.so:az/az \
			${AZ_PREFIX}/lib/libxml2.so:az/az

post-configure:
	@cd ${WRKSRC}/src/backend && ${SETENVI} ${WRK_ENV} ${MAKE_ENV} ${MAKE_CMD} generated-headers

post-install-DOCS-on:
	@- ${INSTALL_DATA} ${WRKSRC}/contrib/README ${STAGEDIR}${DOCSDIR}/extension/README

.include "${MASTERDIR}/Makefile"
