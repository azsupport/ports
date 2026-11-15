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
CPE_VENDOR=	redislabs
USE_RC_SUBR=	redis sentinel

MAKE_ENV=	OPTIMIZATION= \
		V=yo

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

.include <bsd.port.mk>
