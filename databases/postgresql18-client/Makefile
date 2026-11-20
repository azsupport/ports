# databases/postgresql18-client: the client of PostgreSQL 18 of azsupport/ports (libpq,
# psql, pg_dump and the tools; databases/postgresql18-server: the design), without
# OpenSSL; postgresql18-client-openssl with it, one of the two. The line editing of
# psql by the GNU readline of az (aZ 20.11.2026 19:58: «переводи»: bracketed paste,
# UTF-8, the ~/.inputrc of bash), not the libedit of the base system, the official
# devel/libedit or devel/readline; the man pages only with MANPAGES
# (off, as everywhere: no docbook to build them).

PORTNAME=	postgresql

COMMENT?=	PostgreSQL database client (of azsupport/ports)

MASTERDIR=	${.CURDIR}/../postgresql18-server

BUILD_DIRS=	config src/include src/interfaces src/port src/fe_utils src/bin/pg_amcheck \
		src/bin/pg_dump src/bin/psql src/bin/scripts src/bin/pg_config \
		src/bin/pgbench src/makefiles src/test/regress
INSTALL_DIRS=	${BUILD_DIRS}

CLIENT_ONLY=	yes
COMPONENT=	-client
USE_LDCONFIG=	yes
USES=		pkgconfig

# libreadline.so and libhistory.so of az, their headers alone in ${WRKDIR}/az
AZ_PG_LIBS=	readline
BUILD_DEPENDS+=	${AZ_PREFIX}/lib/libreadline.so:az/az
RUN_DEPENDS+=	${AZ_PREFIX}/lib/libreadline.so:az/az

OPTIONS_DEFINE+=MANPAGES DOCS
MANPAGES_BUILD_DEPENDS=	docbook-xml>0:textproc/docbook-xml \
			docbook-xsl>=0:textproc/docbook-xsl \
			xmllint:textproc/libxml2 \
			xsltproc:textproc/libxslt

.include "${MASTERDIR}/Makefile"
