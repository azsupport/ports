# www/rubygem-passenger of azsupport/ports: Phusion Passenger 6.2.2 for nginx, the package
# ruby34-passenger-nginx (PassengerAgent, passenger-config, its Ruby part), which the
# module package www/nginx-devel-passenger needs (aZ, 20.11.2026: «nginx-devel-passenger
# нужен обязательно. www/rubygem-passenger добавляй если у него к нему зависимость»).
# The official port (its patches, pkg-descr, pkg-message of nginx) with:
# - the flavor nginx alone (the Apache module of the flavor apache is not needed: the
#   Apache of aZ runs PHP), the package ruby34-passenger-nginx (aZ, 21.11.2026: the
#   name with the version first, as php84), not rubygem-passenger-nginx;
# - no APR (devel/apr1): only the Apache module links it, not the agent; libcurl of
#   ftp/curl of this tree (the agent), OpenSSL of the base system;
# - our gems: ruby34-etc, -logger, -rack, -rackup and -rake of this tree, on lang/ruby34;
# - CFLAGS and LDFLAGS of the framework to rake too, not CXXFLAGS alone: PassengerAgent a
#   PIE with BIND_NOW (26.11.2026), checked by tools/hardening-check.sh.

PORTNAME=	passenger
PORTVERSION=	6.2.2
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	www rubygems
PKGNAMEPREFIX=	${RUBY_PKGNAMEPREFIX}
MASTER_SITES=	RG \
		https://github.com/phusion/passenger/releases/download/release-${PORTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT=	Modules for running Ruby on Rails and Rack applications (of azsupport/ports)
WWW=		https://www.phusionpassenger.com/ \
		https://github.com/phusion/passenger \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	${RUBY_PKGNAMEPREFIX}logger>=1.7.0:devel/rubygem-logger \
		${RUBY_PKGNAMEPREFIX}rack>=1.6.13,3:www/rubygem-rack \
		${RUBY_PKGNAMEPREFIX}rake>=12.3.3:devel/rubygem-rake \
		utf8cpp>=4.0.3:devel/utf8cpp
LIB_DEPENDS=	libcurl.so:ftp/curl
RUN_DEPENDS=	${RUBY_PKGNAMEPREFIX}etc>=0:devel/rubygem-etc \
		${RUBY_PKGNAMEPREFIX}logger>=1.7.0:devel/rubygem-logger \
		${RUBY_PKGNAMEPREFIX}rack>=1.6.13,3:www/rubygem-rack \
		${RUBY_PKGNAMEPREFIX}rackup>=1.0.1:www/rubygem-rackup \
		${RUBY_PKGNAMEPREFIX}rake>=12.3.3:devel/rubygem-rake

USES=		compiler:c++14-lang cpe gem libtool python:env ssl

CXXFLAGS+=	-I${LOCALBASE}/include/utf8cpp
USE_CXXSTD=	c++14

PLIST_FILES=	bin/passenger \
		bin/passenger-config \
		bin/passenger-memory-stats \
		bin/passenger-status

SUB_FILES=	pkg-message-${FLAVOR}
SUB_LIST=	GEM_LIB_DIR=${GEM_LIB_DIR} RUBY=${RUBY}


CPE_VENDOR=	phusion

FLAVORS=	nginx
FLAVOR?=	${FLAVORS:[1]}
nginx_PKGNAMESUFFIX=	-nginx


OPTIONS_DEFINE=	DEBUG SYMLINK
OPTIONS_DEFAULT=SYMLINK
OPTIONS_EXCLUDE=DOCS
SYMLINK_DESC=	Create passenger symlink

SYMLINK_PLIST_FILES=	${GEMS_DIR}/passenger
SYMLINK_SUB_LIST=	PASSENGER_INSTALL_DIR="${PREFIX}/${GEMS_DIR}/passenger"
SYMLINK_SUB_LIST_OFF=	PASSENGER_INSTALL_DIR="${PREFIX}/${GEM_LIB_DIR}"

post-patch:
# Clean up bundled libraries
	@${RM} -r ${WRKSRC}/src/cxx_supportlib/vendor-copy/utf8*

post-patch-DEBUG-off:
	@${REINPLACE_CMD} 's|-DPASSENGER_DEBUG|-DNDEBUG|g' ${WRKSRC}/build/basics.rb

# rake: the flags of the framework for each part of its build (26.11.2026, readelf of
# ruby34-passenger-nginx 6.2.2_26112521: PassengerAgent EXEC, without BIND_NOW): CFLAGS
# for its C (the libev and libuv it builds, which the agent links), CXXFLAGS for its C++,
# LDFLAGS (-pie, -Wl,-zrelro, -Wl,-znow) for the link of the agent (build/basics.rb of
# Passenger: EXTRA_LDFLAGS goes to its executables alone, not to the static libraries
# and the objects the nginx module links)
post-build:
.if ${FLAVOR} == nginx
	cd ${WRKSRC} && ${SETENV} CC=${CC} CXX=${CXX} EXTRA_CFLAGS="${CFLAGS}" EXTRA_CXXFLAGS="${CXXFLAGS}" \
		EXTRA_LDFLAGS="${LDFLAGS}" USE_VENDORED_LIBUV=true ${LOCALBASE}/bin/rake nginx
.endif
	${FIND} ${WRKSRC} -name '*.bak' -o -name '*.o' -o -name '*.orig' -delete

post-install:
	cd ${WRKSRC} && ${COPYTREE_SHARE} buildout ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/
	${CHMOD} +x ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/buildout/support-binaries/*
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/buildout/ruby/*/passenger_native_support.so
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/buildout/support-binaries/PassengerAgent
	@${SH} ${.CURDIR:H:H}/tools/hardening-check.sh ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/buildout/support-binaries
# the static libraries and the object files of buildout (libboost_oxt.a, the objects of
# libboost_oxt/ and the others the nginx module links) without their debug information
# (rake builds them with -g; no debug in our packages, aZ 17.11.2026)
	${FIND} ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/buildout -type f \( -name '*.a' -o -name '*.o' \) -exec ${STRIP_CMD} --strip-debug {} +
	${FIND} ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR} -type d -empty -delete
	${RM} ${STAGEDIR}${PREFIX}/bin/passenger-install-apache2-module ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/bin/passenger-install-apache2-module
	${RM} ${STAGEDIR}${PREFIX}/bin/passenger-install-nginx-module ${STAGEDIR}${PREFIX}/${GEM_LIB_DIR}/bin/passenger-install-nginx-module

post-install-SYMLINK-on:
	${LN} -s ${GEM_NAME} ${STAGEDIR}${PREFIX}/${GEMS_DIR}/passenger

.include <bsd.port.mk>
