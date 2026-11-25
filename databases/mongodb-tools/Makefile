# databases/mongodb-tools of azsupport/ports in the place of the official one (aZ,
# 18.11.2026 10:55: MongoDB 8.0, mongodb-tools and mongosh of our build, «Всё наше»):
# the MongoDB Database Tools 100.20.1, the official port of the pinned tree without its
# options: the eight tools (bsondump, mongodump, mongoexport, mongofiles, mongoimport,
# mongorestore, mongostat, mongotop), TLS (the tag ssl: crypto/tls of Go, no OpenSSL),
# no SASL (cyrus-sasl2: PLAIN/LDAP and Kerberos; SCRAM is in the driver), no docs;
# Go of the level (GOAMD64 by the -march of the build), -trimpath, no symbols and no
# DWARF (-s -w).

PORTNAME=	mongodb-tools
DISTVERSION=	100.20.1
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	databases

MAINTAINER=	github@azsupport.com
COMMENT=	MongoDB Database Tools (of azsupport/ports)
WWW=		https://www.mongodb.com/docs/database-tools/ \
		https://github.com/azsupport/ports

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE.md

ONLY_FOR_ARCHS=	amd64
ONLY_FOR_ARCHS_REASON=	the x86-64 levels of azsupport/ports only

USES=		compiler:c++14-lang go localbase
USE_GITHUB=	yes
GH_ACCOUNT=	mongodb
GH_PROJECT=	mongo-tools

GO_PKGNAME=	github.com/${GH_ACCOUNT}/${GH_PROJECT}
GO_TARGET=	./bsondump/main:bsondump \
		./mongodump/main:mongodump \
		./mongoexport/main:mongoexport \
		./mongofiles/main:mongofiles \
		./mongoimport/main:mongoimport \
		./mongorestore/main:mongorestore \
		./mongostat/main:mongostat \
		./mongotop/main:mongotop
GO_BUILDFLAGS=	-tags "ssl"
# the version and the commit each tool prints with --version, as the build script of
# mongo-tools sets them (main.VersionStr, main.GitCommit of each main package); without
# them "built-without-version-string" (the publish run 44391248725, 18.11.2026)
GO_LDFLAGS=	-w -X main.VersionStr=${DISTVERSION} \
		-X main.GitCommit=99fd6bc7140e31e0287a9b4ef7e03194d834c7f0
GOAMD64=	${CFLAGS:M-march=x86-64-v[234]:S/-march=x86-64-//}

# This should be TEST_ENV according to bsd.port.mk, but Uses/go.mk passes
# MAKE_ENV instead of TEST_ENV in the do-test target.
# https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=284387
MAKE_ENV+=		TOOLS_TESTING_UNIT=true

.include <bsd.port.mk>
