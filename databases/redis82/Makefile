# databases/redis82: the Redis 8.2 of azsupport/ports in the place of the official
# databases/redis82 (aZ, 15.11.2026: 8.2, the line of 8.x with the long support of
# upstream, without the modules: «давай 8.2 без модулей как решили») and, by its
# slave port databases/redis82-openssl, with TLS. The official port with JEMALLOC on,
# the jemalloc of Redis (deps/jemalloc), which its active defragmentation needs
# (aZ, 15.11.2026: «jemalloc врубаем по умолчанию»), and without TLS, which the
# official one has on (as databases/memcached of this tree); redis82-openssl
# (PKGNAMESUFFIX 82-openssl, the same files) has it, on the OpenSSL of the base
# system. No library of the ports: Redis bundles hiredis, linenoise, lua, fpconv,
# hdr_histogram and jemalloc (deps/). The configurations of aZ for Redis 8.2 in the
# place of the redis.conf of Redis (aZ, 15.11.2026: «Составь из трёх конфигов
# идеальный конфиг», «кеш по умолчанию не сохранять»): files/redis.conf, the main
# cache, as etc/redis.conf.sample, and files/redis-session.conf, the PHP sessions
# (the profile "session" of the rc script), as etc/redis-session.conf.sample; both on
# 127.0.0.1 only (aZ, 15.11.2026: «не надо чтобы редис слушал на ipv6»), without
# snapshots, with the variants of a snapshot commented out.
# The C compiled by GCC 16 of the ports instead of the base clang (USES=azgcc,
# Mk/Uses/azgcc.mk; a build dependency only), aZ 17.11.2026 («а) Python, Redis и xxhash
# в az»): tools/prog-bench.sh measured redis-server 8.2.11 built with GCC 16 against the
# base clang 19 (redis-benchmark, 50 clients, pipeline 16, the server alone on a CPU):
# faster in 9 of 11 tests, the median -6.3% (prog-bench run 44043639827), and in 10 of
# 14, the median -5.9% (run 44046254033). Its one C++ file, fast_float_strtod.cpp of
# deps/fast_float (by g++16), includes <iostream> and <string>, which it does not use;
# <iostream> makes the object need libstdc++ (std::ios_base_library_init). Without them,
# and built without exceptions (-fno-exceptions: else GCC 16 puts __gxx_personality_v0
# of libstdc++ into its unwind tables, and the link failed, build run 44059209484), it
# needs libc only, and the link goes without -lstdc++, which with GCC would be the
# libstdc++.so.6 of the gcc package (a library of the ports, not on the servers): a
# symbol of the C++ library would fail the link, not the start; libgcc linked in
# (-static-libgcc). Without the -g -ggdb of its Makefile (DEBUG; no debug in our builds,
# aZ 17.11.2026).

PORTNAME=	redis
DISTVERSION=	8.2.11
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	databases
MASTER_SITES=	https://download.redis.io/releases/
PKGNAMESUFFIX?=	82

MAINTAINER=	github@azsupport.com
COMMENT?=	Persistent key-value database with built-in net interface (8.2.X, of azsupport/ports)
WWW=		https://redis.io/ \
		https://github.com/azsupport/ports

LICENSE=	AGPLv3 RSALv2 SSPLv1
LICENSE_COMB=	dual
LICENSE_NAME_RSALv2=	Redis Source Available License v2
LICENSE_NAME_SSPLv1=	Server Side Public License v1
LICENSE_FILE=	${WRKSRC}/LICENSE.txt
LICENSE_PERMS_RSALv2=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept
LICENSE_PERMS_SSPLv1=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

USES=		compiler:c11 cpe gmake tcl:test
# GCC of the ports for the C, at build time only (Mk/Uses/azgcc.mk)
USES+=		azgcc
CPE_VENDOR=	redislabs
USE_RC_SUBR=	redis sentinel

MAKE_ENV=	OPTIMIZATION= \
		V=yo
MAKE_ARGS=	DEBUG=

LDFLAGS+=	-lpthread -lm -lexecinfo
#PIE_UNSAFE=	ld: error: relocation R_X86_64_32 cannot be used against local \
#		symbol; recompile with -fPIC

CONFLICTS_INSTALL=	redis-devel redis[0-9]*

SUB_FILES=	pkg-message
SUB_LIST=	PORTNAME=${PORTNAME} \
		REDIS_DBDIR=${REDIS_DBDIR} \
		REDIS_LOGDIR=${REDIS_LOGDIR} \
		REDIS_RUNDIR=${REDIS_RUNDIR} \
		REDIS_USER=${USERS}

USERS=		redis
GROUPS=		redis

PLIST_SUB=	REDIS_DBDIR=${REDIS_DBDIR} \
		REDIS_GROUP=${GROUPS} \
		REDIS_LOGDIR=${REDIS_LOGDIR} \
		REDIS_RUNDIR=${REDIS_RUNDIR} \
		REDIS_USER=${USERS}

OPTIONS_DEFINE=		JEMALLOC TLS
OPTIONS_DEFAULT=	JEMALLOC
# TLS only in redis82-openssl
.if ${PKGNAMESUFFIX:U} == "82-openssl"
OPTIONS_SLAVE=		TLS
.else
OPTIONS_EXCLUDE=	TLS
.endif
OPTIONS_SUB=		yes

JEMALLOC_DESC=	Use jemalloc
TLS_DESC=	Use TLS (openssl req.)

JEMALLOC_MAKE_ENV=	USE_JEMALLOC=yes
TLS_USES=		ssl
TLS_MAKE_ENV=		BUILD_TLS=yes

BIN_FILES=	redis-benchmark redis-check-aof redis-check-rdb redis-cli \
		redis-sentinel redis-server

REDIS_DBDIR?=	/var/db/redis
REDIS_RUNDIR?=	/var/run/redis
REDIS_LOGDIR?=	/var/log/redis

post-patch-JEMALLOC-on:
	@${REINPLACE_CMD} '78s!Linux!FreeBSD!g' ${WRKSRC}/src/Makefile

do-install:
	${INSTALL_PROGRAM} ${BIN_FILES:C!^!${WRKSRC}/src/!} ${STAGEDIR}${PREFIX}/bin/
	${INSTALL_DATA} ${FILESDIR}/redis.conf ${STAGEDIR}${PREFIX}/etc/redis.conf.sample
	${INSTALL_DATA} ${FILESDIR}/redis-session.conf ${STAGEDIR}${PREFIX}/etc/redis-session.conf.sample
	${INSTALL_DATA} ${WRKSRC}/sentinel.conf ${STAGEDIR}${PREFIX}/etc/sentinel.conf.sample
	${MKDIR} ${STAGEDIR}${REDIS_LOGDIR} \
		${STAGEDIR}${REDIS_DBDIR} \
		${STAGEDIR}${REDIS_RUNDIR}

do-test:
	@cd ${WRKSRC} && ${TCLSH} tests/test_helper.tcl

.include <bsd.port.pre.mk>

.if ${AZ_GCC} != no
LDFLAGS+=	-static-libgcc

post-patch:
	@${REINPLACE_CMD} -e '/^#include <iostream>$$/d' -e '/^#include <string>$$/d' \
		${WRKSRC}/deps/fast_float/fast_float_strtod.cpp
	@${REINPLACE_CMD} -e 's|^DEFS=-DFASTFLOAT_ALLOWS_LEADING_PLUS$$|& -fno-exceptions|' \
		${WRKSRC}/deps/fast_float/Makefile
	@${REINPLACE_CMD} -e 's|^FINAL_LIBS=-lm -lstdc++$$|FINAL_LIBS=-lm|' ${WRKSRC}/src/Makefile
	@${GREP} -q '^FINAL_LIBS=-lm$$' ${WRKSRC}/src/Makefile && \
		${GREP} -q '^DEFS=.* -fno-exceptions$$' ${WRKSRC}/deps/fast_float/Makefile && \
		! ${GREP} -q -E '^#include <(iostream|string)>' ${WRKSRC}/deps/fast_float/fast_float_strtod.cpp || \
		{ ${ECHO_MSG} "redis: -lstdc++, <iostream> or exceptions still there (src/Makefile, deps/fast_float)"; ${FALSE}; }
.endif

.include <bsd.port.post.mk>
