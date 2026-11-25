# devel/simdjson of azsupport/ports: the JSON parser of www/node24 (aZ, 11.11.2026: the
# libraries that Node.js bundles as ports of this tree), a copy of the official port at
# its version (the row "port devel/simdjson" of freebsd/upstream.conf of
# azsupport/php-src): simdjson 5.3.0 (aZ, 24.11.2026: «обновлять»), before the official
# port (5.1.1). Its release file is that of the tag v5.3.0 of GitHub (the SHA-256 that
# of the simdjson formula of Homebrew; fetched on a runner of aZ), its install the same
# (one header, the shared library, the CMake files, the .pc), the shared library
# libsimdjson.so.38 (36 before: www/node24 is built again with it); the test data of
# simdjson-data at the commit 5.3.0 names in dependencies/CMakeLists.txt, the same as
# for 5.1.1.

PORTNAME=	simdjson
DISTVERSIONPREFIX=	v
DISTVERSION=	5.3.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	devel textproc

MAINTAINER=	github@azsupport.com
COMMENT=	Parsing gigabytes of JSON per second
WWW=		https://simdjson.org/ \
		https://github.com/simdjson/simdjson/

LICENSE=	APACHE20 MIT
LICENSE_COMB=	dual
LICENSE_FILE_APACHE20=	${WRKSRC}/LICENSE
LICENSE_FILE_MIT=	${WRKSRC}/LICENSE-MIT

USES=		cmake:testing compiler:c++17-lang pathfix python:test
USE_GITHUB=	yes
# Found in dependencies/CMakeLists.txt
GH_TUPLE=	simdjson:simdjson-data:351949906abde446f0314bf79606fb5d884f5be7:simdjson_data/dependencies/.cache/simdjson-data
USE_LDCONFIG=	yes

CMAKE_ON=		BUILD_SHARED_LIBS
CMAKE_TESTING_ON=	SIMDJSON_DEVELOPER_MODE
CMAKE_TESTING_OFF=	SIMDJSON_ALLOW_DOWNLOADS \
			SIMDJSON_COMPETITION \
			SIMDJSON_GOOGLE_BENCHMARKS

CXXFLAGS_i386=		-DSIMDJSON_NO_PORTABILITY_WARNING

.include <bsd.port.mk>
