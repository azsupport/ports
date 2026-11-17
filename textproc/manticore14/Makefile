# textproc/manticore14 of azsupport/ports (aZ, 16.11.2026: Manticore Search 14 and 31,
# one of the two installed; with Galera; Buddy after his check): Manticore Search 14.7.6
# of 29.11.2025, the last of the line 14 (textproc/manticore31: the current line). The
# FreeBSD tree has no port of it (textproc/sphinxsearch only): written for this tree.
# - searchd, indexer, indextool, spelldump, wordbreaker; the rc.d script manticore with
#   profiles (manticore_profiles: a config, pid file and data of its own each, as the
#   profiles of redis); the config /usr/local/etc/manticore.conf (aZ, 16.11.2026; the
#   default path of the programs), its sample manticore.conf.sample: RT mode, on
#   127.0.0.1 only (9312 binary API, 9306 MySQL, 9308 HTTP), data /var/db/manticore,
#   logs /var/log/manticore, pid /var/run/manticore; the user manticore (UID 9306);
# - Galera (replication: CREATE CLUSTER; aZ, 16.11.2026): the module
#   share/manticore/modules/libgalera_manticore.so of the galera and wsrep-API of
#   Manticore (it needs OpenSSL: that of the base system), Boost 1.89+ fixed;
# - the libraries of az wherever az has them (aZ, 16.11.2026): ICU linked (with the run
#   path /usr/local/az/lib), xxHash 0.8.4 (its header, inline), and loaded when used
#   (dlopen, as upstream builds it): zstd, expat (xmlpipe2 of indexer); libcurl (Buddy)
#   that of our ftp/curl, the libcurl of every package (az has it static only, for PHP);
#   the client of MariaDB (MySQL sources of indexer) of databases/mariadb1011-client,
#   loaded the same way; OpenSSL of the base system, shared (HTTPS and SSL of the MySQL
#   listener; upstream links the static one); Boost.Context and Boost.Filesystem the
#   archives of the official devel/boost-libs, at build time, alone in a directory of the
#   work (as devel/gearmand);
# - what az has not, in the build only, static, from distfiles (cmake downloads nothing:
#   FETCHCONTENT_SOURCE_DIR_*, GALERA_SOURCE_DIR, COLUMNAR_LOCATOR): RE2 2015-06-01
#   patched by Manticore (aZ's recipe: WITH_RE2_FORCE_STATIC), libstemmer (Snowball 3.0.3
#   of Manticore, that of Manticore 31: the libstemmer_c.tgz of snowballstem.org 14.7.6
#   took is no longer there), cctz, CRoaring, uni-algo, nlohmann/json, cppjieba with
#   limonp (its dictionaries in share/manticore/jieba), the API of columnar c27-s18-k9;
# - time zones: share/manticore/tzdata a link to /usr/share/zoneinfo (aZ);
# - CMake 4: CMAKE_POLICY_VERSION_MINIMUM=3.5 in the environment, for the dependencies
#   whose minimum is under 3.5 (cctz, nlohmann/json); the tree has CMake 3.31;
# - not built: ODBC and PostgreSQL sources of indexer, the tests; the libraries
#   columnar, secondary and knn (with embeddings): textproc/manticore14-columnar;
#   Buddy (aZ, 16.11.2026: after his check).

PORTNAME=	manticore
DISTVERSION?=	14.7.6
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	textproc
PKGNAMESUFFIX?=	14
DIST_SUBDIR=	manticore

MAINTAINER=	github@azsupport.com
COMMENT=	Manticore Search ${PKGNAMESUFFIX}, full-text search server (of azsupport/ports)
WWW=		https://manticoresearch.com/ \
		https://github.com/manticoresoftware/manticoresearch \
		https://github.com/azsupport/ports

LICENSE=	GPLv3+
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	${LOCALBASE}/lib/libboost_context.a:devel/boost-libs \
		bison:devel/bison \
		${AZ_PREFIX}/lib/libexpat.so:az/az \
		${AZ_PREFIX}/lib/libicuuc.so:az/az \
		${AZ_PREFIX}/lib/libxxhash.so:az/az \
		${AZ_PREFIX}/lib/libzstd.so:az/az
LIB_DEPENDS=	libcurl.so:ftp/curl
RUN_DEPENDS=	${AZ_PREFIX}/lib/libexpat.so:az/az \
		${AZ_PREFIX}/lib/libicuuc.so:az/az \
		${AZ_PREFIX}/lib/libzstd.so:az/az

USES=		cmake compiler:c++17-lang mysql ssl
USE_GITHUB=	yes
GH_ACCOUNT=	manticoresoftware
GH_PROJECT=	manticoresearch
# the line 14 (textproc/manticore31 sets its own): cctz, nlohmann/json and columnar
MC_TUPLES?=	manticoresoftware:cctz:cf11f758e2532161c9e21c3ec2461b0fafb15853:cctz/freebsd-deps/cctz \
		nlohmann:json:v3.10.5:nljson/freebsd-deps/nljson \
		manticoresoftware:columnar:c27-s18-k9:columnar/freebsd-deps/columnar
GH_TUPLE=	${MC_TUPLES} \
		manticoresoftware:galera:dfce76623c63da32fe3154dc010bf22a399035e8:galera/freebsd-deps/galera \
		percona:wsrep-API:2c211e1aad315e3118969beada4d4767118be88f:wsrep/freebsd-deps/wsrep \
		manticoresoftware:cppjieba:0fa3cb07232f5c144228c2e8e39521bfdc9d3bca:jieba/freebsd-deps/cppjieba \
		yanyiwu:limonp:v0.9.0:limonp/freebsd-deps/cppjieba/deps/limonp \
		manticoresoftware:re2:2015-06-01:re2/freebsd-deps/re2 \
		manticoresoftware:snowball:v3.0.3:stemmer/freebsd-deps/stemmer \
		manticoresoftware:uni-algo:v0.7.2:unialgo/freebsd-deps/uni-algo \
		RoaringBitmap:CRoaring:v4.3.2:roaring/freebsd-deps/roaring
USE_RC_SUBR=	manticore

MC_DEPS=	${WRKSRC}/freebsd-deps
CMAKE_ARGS=	-DBUILD_TESTING=OFF -DVERNUMBERS=${DISTVERSION} \
		-DCMAKE_INSTALL_LOCALSTATEDIR=/var/db/manticore \
		-DCMAKE_INSTALL_RUNSTATEDIR=/var/run \
		-DCACHEB=${WRKDIR}/manticore-cache \
		-DWITH_GALERA=ON -DGALERA_SOURCE_DIR=${MC_DEPS}/galera \
		-DWSREP_SOURCE_DIR=${MC_DEPS}/wsrep \
		-DWITH_RE2=ON -DWITH_RE2_FORCE_STATIC=ON \
		-DWITH_STEMMER=ON -DWITH_STEMMER_FORCE_STATIC=ON \
		-DWITH_ICU=ON -DWITH_ICU_FORCE_STATIC=OFF -DICU_ROOT=${WRKDIR}/az \
		-DWITH_JIEBA=ON \
		-DWITH_SSL=ON -DOPENSSL_USE_STATIC_LIBS=OFF \
		-DOPENSSL_ROOT_DIR=${OPENSSLBASE} \
		-DWITH_ZLIB=ON -DWITH_ZSTD=ON -DWITH_CURL=ON -DCURL_NO_CURL_CMAKE=ON \
		-DWITH_EXPAT=ON \
		-DWITH_ICONV=ON -DWITH_MYSQL=ON \
		-DWITH_ODBC=OFF -DWITH_POSTGRESQL=OFF \
		-DCMAKE_PREFIX_PATH=${WRKDIR}/az \
		-DBoost_NO_BOOST_CMAKE=ON -DBOOST_ROOT=${WRKDIR}/deps \
		-DBoost_NO_SYSTEM_PATHS=ON \
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON \
		-DFETCHCONTENT_SOURCE_DIR_CCTZ=${MC_DEPS}/cctz \
		-DFETCHCONTENT_SOURCE_DIR_JIEBA=${MC_DEPS}/cppjieba \
		-DFETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON=${MC_DEPS}/nljson \
		-DFETCHCONTENT_SOURCE_DIR_RE2=${MC_DEPS}/re2 \
		-DFETCHCONTENT_SOURCE_DIR_ROARING=${MC_DEPS}/roaring \
		-DFETCHCONTENT_SOURCE_DIR_STEMMER=${MC_DEPS}/stemmer \
		-DFETCHCONTENT_SOURCE_DIR_UNI-ALGO=${MC_DEPS}/uni-algo
# the dependencies (cctz, RE2...) and galera are configured and built by cmake at
# configure time in builds of their own: the minimum of CMake 4 and the flags of the
# make.conf of the build (-O3, the -march of the level; else they have the flags of
# CMake alone) through the environment; the API of columnar: of the sources here
# (COLUMNAR_LOCATOR; the line 31 has it in its submodule mcl, MCL_LOCAL_RUNTIME=OFF)
CONFIGURE_ENV=	CMAKE_POLICY_VERSION_MINIMUM=3.5 CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}"
MC_COLUMNAR_ENV?=	COLUMNAR_LOCATOR="SOURCE_DIR ${MC_DEPS}/columnar"
CONFIGURE_ENV+=	${MC_COLUMNAR_ENV}
CMAKE_ARGS+=	${MC_COLUMNAR_ARGS}
MAKE_ENV=	CMAKE_POLICY_VERSION_MINIMUM=3.5
# ICU of az (and the libraries of az loaded at run time) by the run path of az
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

USERS=		manticore
GROUPS=		manticore
UID_FILES=	${PORTSDIR}/UIDs ${FILESDIR}/UIDs
GID_FILES=	${PORTSDIR}/GIDs ${FILESDIR}/GIDs
SUB_LIST=	USERS=${USERS} GROUPS=${GROUPS} MC_LINE=${PKGNAMESUFFIX}
SUB_FILES=	pkg-message

CONFLICTS_INSTALL?=	manticore31

OPTIONS_DEFINE=	DOCS MANPAGES
OPTIONS_DEFAULT=	MANPAGES
OPTIONS_SUB=	yes

PORTDOCS=	*

# galera of the sources here (files/patch-cmake_GetGALERA.cmake); RE2: the patch of
# Manticore and its CMakeLists.txt, as cmake/GetRE2.cmake would put them (it runs
# "patch --binary", an option of GNU patch alone: the patch of the base system fails,
# without a word in 14 (RE2 left unpatched) and fatally in 31), is_patched.txt marking
# it done
post-patch:
	@${CP} ${FILESDIR}/galera-local.cmake.in ${WRKSRC}/cmake/
	@${PATCH} -s -d ${MC_DEPS}/re2 -p1 < ${WRKSRC}/libre2/libre2.patch
	@${CP} ${WRKSRC}/libre2/CMakeLists.txt ${MC_DEPS}/re2/CMakeLists.txt
	@${ECHO_CMD} ok > ${MC_DEPS}/re2/is_patched.txt

# Boost: its headers and the two archives alone in ${WRKDIR}/deps (the include
# directory of devel/boost-libs is /usr/local/include, with the official ICU of its
# dependencies); the libraries of az alone in ${WRKDIR}/az (nothing else of
# /usr/local/az is seen), with the libcurl of ftp/curl
pre-configure:
	@${MKDIR} ${WRKDIR}/deps/include ${WRKDIR}/deps/lib ${WRKDIR}/az/include ${WRKDIR}/az/lib
	@${LN} -sf ${LOCALBASE}/include/boost ${WRKDIR}/deps/include/boost
	@${LN} -sf ${LOCALBASE}/lib/libboost_context.a ${LOCALBASE}/lib/libboost_filesystem.a \
		${WRKDIR}/deps/lib/
.for i in unicode expat.h expat_external.h expat_config.h xxhash.h xxh3.h zstd.h zdict.h zstd_errors.h
	@if [ -e ${AZ_PREFIX}/include/${i} ]; then ${LN} -sf ${AZ_PREFIX}/include/${i} ${WRKDIR}/az/include/${i}; fi
.endfor
.for l in libicuuc libicudata libicui18n libexpat libzstd
	@${LN} -sf ${AZ_PREFIX}/lib/${l}.so ${WRKDIR}/az/lib/${l}.so
.endfor
	@${LN} -sf ${LOCALBASE}/include/curl ${WRKDIR}/az/include/curl
	@${LN} -sf ${LOCALBASE}/lib/libcurl.so ${WRKDIR}/az/lib/libcurl.so
# xxHash of az for cmake/GetxxHash.cmake (find_package CONFIG): its header only,
# Manticore includes it with XXH_INLINE_ALL (nothing to link)
	@${MKDIR} ${WRKDIR}/az/lib/cmake/xxHash
	@${PRINTF} '%s\n' 'if (NOT TARGET xxHash::xxhash)' \
		'	add_library ( xxHash::xxhash INTERFACE IMPORTED )' \
		'	set_target_properties ( xxHash::xxhash PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${WRKDIR}/az/include" )' \
		'endif ()' > ${WRKDIR}/az/lib/cmake/xxHash/xxHashConfig.cmake

# what upstream installs for Debian and RPM only (no distr for FreeBSD): the module of
# galera, the dictionaries of cppjieba, the manual pages; the config as the sample;
# the directories of the service (pkg-plist)
post-install:
	@${RM} -r ${STAGEDIR}${PREFIX}/etc/manticoresearch ${STAGEDIR}/var
	${INSTALL_DATA} ${FILESDIR}/manticore.conf.sample ${STAGEDIR}${PREFIX}/etc/manticore.conf.sample
	@${MKDIR} ${STAGEDIR}${DATADIR}/modules ${STAGEDIR}${DATADIR}/jieba
	${INSTALL_LIB} ${WRKDIR}/manticore-cache/freebsd-amd64/galera/lib/libgalera_manticore.so* \
		${STAGEDIR}${DATADIR}/modules/
	${INSTALL_DATA} ${WRKDIR}/manticore-cache/freebsd-amd64/jieba/dict/*.utf8 ${STAGEDIR}${DATADIR}/jieba/
	${LN} -s /usr/share/zoneinfo ${STAGEDIR}${DATADIR}/tzdata

post-install-MANPAGES-on:
	${INSTALL_MAN} ${WRKSRC}/doc/searchd.1 ${WRKSRC}/doc/indexer.1 ${WRKSRC}/doc/indextool.1 \
		${STAGEDIR}${PREFIX}/share/man/man1/

post-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/README.md ${WRKSRC}/example.sql ${STAGEDIR}${DOCSDIR}/

.include <bsd.port.mk>
