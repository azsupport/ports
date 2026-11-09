# PHP 5.6 of azsupport/php-src for the overlay azsupport/ports: the official
# port lang/php56 of freebsd-ports d2c06ef5efae (the ports commit of PHP 5.6 in
# php-src freebsd/targets.conf), changed as lang/php74 is (see its head; the
# same decisions of aZ, 08.11.2026), for the framework of the pinned tree
# (f16b6dd0f7c1). What differs, and why:
#
# - Source: the dated release tarball of the fork azsupport/php-src, PHP 5.6.40
#   with the security backports of Remi Collet (the branch with OpenSSL 1.1;
#   php-src freebsd/targets.conf), the fork's builds with OpenSSL 3, libxml2
#   2.12 and later and clang 16 and later (php-src freebsd/patches/5.6), the
#   patches of the official port, the PECL extensions in ext/, the PCRE 8.45
#   the fork bundles (renamed functions) and a configure generated with them:
#   no files/patch-*, no buildconf (no autoreconf). Of the patches the fork
#   leaves out (php-src freebsd/patches/5.6/SKIPPED), the include of
#   ext/php_config.h in main/php_config.h (patch-configure.in) is added in
#   post-configure, as in lang/php74. A new dated release of the same version:
#   AZ_PHP_RELEASE and distinfo.
# - PORTREVISION is the stamp of the build, AZ_STAMP of the builder (0 without
#   it; Mk/bsd.overlay.mk); the modules take it from here.
# - Versions side by side: every path of PHP 5.6 has 56 in it: bin/php56 ...
#   (--program-suffix=56), etc/php56 (php.ini by @sample from php.ini.sample:
#   php.ini-production with the defaults of az, files/php.ini-az-56.in, at its
#   end; errors in /var/log/php56_error.log, made at install when missing; FPM
#   with /var/run/php-fpm56.pid, /var/log/php-fpm56.log, and the pool www,
#   which 5.6 has in php-fpm.conf (no php-fpm.d), on /var/run/php-fpm56.sock),
#   the scan dir etc/php56/conf.d, lib/php56 (the build files of phpize56),
#   include/php56, share/php56, etc/rc.d/php_fpm56,
#   libexec/apache24/libphp56.so (www/mod_php56); the modules in
#   lib/php/20131226 as the ports. No CONFLICTS with other versions.
# - Libraries: libxml2 of the package az (${AZ_PREFIX}), by a file, with its
#   run path; the PCRE the fork bundles (no devel/pcre: no --with-pcre-regex).
#   PHP 5.6 takes libxml2 by xml2-config only, and that of az names the zlib of
#   the base system with -L/lib in --libs, which configure would put into the
#   run path of php56 (the run path is ${AZ_PREFIX}/lib only): AZ_XML2_CONFIG,
#   xml2-config of az without that -L/lib (the modules of libxml2 take it too).
#   No --with-zlib-dir: it was for the mysqlnd of the core, and without
#   patch-ext_zlib_config0.m4 of the port (SKIPPED by the fork) it would build
#   zlib into the core.
# - Options: no MYSQLND in the core (the module php56-mysqlnd: no
#   --enable-mysqlnd); EMBED off by default, as lang/php74. OPcache is the
#   module php56-opcache; this PHP loads modules.
# - No DEPRECATED/EXPIRATION_DATE (upstream end of life 31.12.2018 in the
#   official port): the fork carries the security fixes, as for 7.4.
# - Profiles: bin/php56-profile (files/php-profile.in, the template of every
#   version) and the profiles of the rc.d script php_fpm56, as lang/php74.
# - The Apache module (PKGNAMEPREFIX mod_) with the idioms of the framework of
#   f16b6dd: USES=apache before bsd.port.pre.mk (not the include of
#   Mk/Uses/apache.mk after it), AP2FILTER by option helpers of www/mod_php56,
#   as lang/php74; libphp56.so (aZ: libphpXY.so for every version; the
#   official name is libphp5.so), not loaded by itself.
#
# The slave ports, the modules php56-<module>: a slave's Makefile sets
#	CATEGORIES=	<category>
#	MASTERDIR=	${.CURDIR}/../../lang/php56
#	PKGNAMESUFFIX=	-<module>
#	.include "${MASTERDIR}/Makefile"
# With PKGNAMESUFFIX defined this Makefile includes ${MASTERDIR}/Makefile.ext
# (the rules of the modules) and ends with bsd.port.post.mk. Makefile.ext gets
# from here PORTNAME, DISTVERSION?= (a PECL extension sets its own version
# first), PORTREVISION, CATEGORIES?=, MASTER_SITES, DISTNAME (without
# DISTVERSION), DIST_SUBDIR, distinfo (through MASTERDIR), MAINTAINER, WWW,
# LICENSE, USES (cpe tar:xz), PHP_VER (56) and AZ_XML2_CONFIG.

PORTNAME=	php56
DISTVERSION?=	5.6.40
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES?=	lang devel www
MASTER_SITES=	https://github.com/azsupport/php-src/releases/download/freebsd-5.6-${AZ_PHP_RELEASE}/
DISTNAME=	php-5.6.40-fbsd-${AZ_PHP_RELEASE}
DIST_SUBDIR=	php

MAINTAINER=	github@azsupport.com
COMMENT=	PHP Scripting Language (5.6.X branch of azsupport/php-src)
WWW=		https://github.com/azsupport/php-src

LICENSE=	PHP301

USES+=		tar:xz cpe
CPE_PRODUCT=	php
NO_OPTIONS_SORT=yes
PHP_VER=	56

# the dated release of the fork: its tag freebsd-5.6-<date>-<commit>; DISTNAME
# without DISTVERSION, which the slaves of PECL extensions set to their version
AZ_PHP_RELEASE=	20261108-5c2cc46b

# xml2-config of az without the -L/lib of its --libs (the head): configure
# takes it from the cache variable of PHP_SETUP_LIBXML (acinclude.m4), the core
# and the modules alike; the script is made in pre-configure (az-xml2-config)
AZ_XML2_CONFIG=	${WRKDIR}/az-xml2-config

# the files of this port that the ports needing it need not see (tools/build.sh),
# as in lang/php74: run-time files of the core only (post-install, USE_RC_SUBR,
# SUB_FILES), read by no module and not by mod_php56: the block of az for
# php.ini, bin/php56-profile, the rc.d script php_fpm56 and pkg-message
AZ_HASH_NOT_FOR_DEPENDENTS=	${FILESDIR}/php.ini-az-56.in ${FILESDIR}/php-profile.in \
				${FILESDIR}/php_fpm56.in ${FILESDIR}/pkg-message.in

.if !defined(PKGNAMESUFFIX)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libxml2.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libxml2.so:az/az

GNU_CONFIGURE=	yes
CONFIGURE_ARGS+=--with-layout=GNU \
		--with-config-file-path=${PREFIX}/etc/php${PHP_VER} \
		--with-config-file-scan-dir=${PREFIX}/etc/php${PHP_VER}/conf.d \
		--disable-all \
		--enable-libxml \
		--with-libxml-dir=${AZ_PREFIX} \
		--program-prefix="" \
		--program-suffix=${PHP_VER} \
		--sysconfdir=${PREFIX}/etc/php${PHP_VER} \
		--libdir=${PREFIX}/lib/php${PHP_VER} \
		--includedir=${PREFIX}/include/php${PHP_VER} \
		--datadir=${PREFIX}/share/php${PHP_VER}
CONFIGURE_ENV=	EXTENSION_DIR=${PREFIX}/lib/php/${PHP_EXT_DIR} \
		ac_cv_php_xml2_config_path=${AZ_XML2_CONFIG}
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib

# the directory of the modules: ZEND_MODULE_API_NO of PHP 5.6, as the ports
PHP_EXT_DIR=	20131226
PLIST_SUB+=	PHP_EXT_DIR=${PHP_EXT_DIR}

# PR230207 Allow relocations against read-only segments (override lld default)
LDFLAGS_i386=	-Wl,-z,notext

OPTIONS_DEFINE+=CLI CGI FPM EMBED PHPDBG DEBUG DTRACE IPV6 MAILHEAD LINKTHR ZTS
OPTIONS_DEFAULT=CLI CGI FPM LINKTHR
# Bug 197128:  No ASM code for MIPS/MIPS64, disable FPM
OPTIONS_EXCLUDE_mips=FPM
OPTIONS_EXCLUDE_mips64=FPM
OPTIONS_SUB=	yes

CLI_DESC=	Build CLI version
CGI_DESC=	Build CGI version
FPM_DESC=	Build FPM version
EMBED_DESC=	Build embedded library
DEBUG_DESC=	Enable debug
DTRACE_DESC=	Enable DTrace support
MAILHEAD_DESC=	Enable mail header patch
LINKTHR_DESC=	Link thread lib (for threaded extensions)
ZTS_DESC=	Force Zend Thread Safety (ZTS) build

DESTDIRNAME=	INSTALL_ROOT

# The Apache module of the version, libphp56.so (aZ: libphpXY.so for every
# version, so that the versions side by side do not overwrite each other; the
# official name is libphp5.so). Not loaded by itself: the package brings
# etc/apache24/modules.d/280_mod_php56.conf.sample to copy (one PHP module per
# Apache instance), so no apxs -e -a. It uses etc/php56 and the modules of
# php56, so it depends on php56.
.if defined(PKGNAMEPREFIX)
USES+=		apache
RUN_DEPENDS+=	${LOCALBASE}/include/php${PHP_VER}/php/main/php.h:lang/php${PHP_VER}
PLIST=		${PKGDIR}/pkg-plist.mod
PKGMESSAGE=	${PKGDIR}/pkg-message.mod
MODULENAME=	libphp${PHP_VER}
SHORTMODNAME=	php5
WARNING=	"!!! If you have a threaded Apache, you must build ${PHP_PORT} with ZTS support to enable thread-safety in extensions !!!"
.endif

.include <bsd.port.pre.mk>

PATCH_DIST_STRIP=	-p1

PATCH_SITES+=	LOCAL/ale

.if ${PORT_OPTIONS:MMAILHEAD}
PATCHFILES+=	php-5.5.x-mail-header.patch:mail
PATCH_SITES+=	http://choon.net/opensource/php/:mail
.endif

.if ${PORT_OPTIONS:MCLI}
PHP_SAPI+=	cli
.else
CONFIGURE_ARGS+=--disable-cli
.endif

.if ${PORT_OPTIONS:MCGI}
PHP_SAPI+=	cgi
.else
CONFIGURE_ARGS+=--disable-cgi
.endif

.if ${PORT_OPTIONS:MFPM}
PHP_SAPI+=	fpm
USE_RC_SUBR+=	php_fpm${PHP_VER}
CONFIGURE_ARGS+=--enable-fpm \
		--with-fpm-user=${WWWOWN} \
		--with-fpm-group=${WWWGRP}
.endif

.if ${PORT_OPTIONS:MEMBED}
PHP_SAPI+=	embed
CONFIGURE_ARGS+=--enable-embed
.endif

.if ${PORT_OPTIONS:MPHPDBG}
PHP_SAPI+=	phpdbg
CONFIGURE_ARGS+=--enable-phpdbg
.if ${PORT_OPTIONS:MDEBUG}
CONFIGURE_ARGS+=--enable-phpdbg-debug
.endif
.endif

.if ${PORT_OPTIONS:MCLI} || ${PORT_OPTIONS:MEMBED}
PLIST_SUB+=	SAPI_INC=""
.else
PLIST_SUB+=	SAPI_INC="@comment "
.endif

.if !defined(WITH_REGEX_TYPE) || ${WITH_REGEX_TYPE} == "php"
CONFIGURE_ARGS+=--with-regex=php
.elif defined(WITH_REGEX_TYPE) && ${WITH_REGEX_TYPE} == "system"
CONFIGURE_ARGS+=--with-regex=system
.endif

.if !defined(WITH_ZEND_VM) || ${WITH_ZEND_VM} == "CALL"
CONFIGURE_ARGS+=--with-zend-vm=CALL
.elif defined(WITH_ZEND_VM) && ${WITH_ZEND_VM} == "SWITCH"
CONFIGURE_ARGS+=--with-zend-vm=SWITCH
.elif defined(WITH_ZEND_VM) && ${WITH_ZEND_VM} == "GOTO"
CONFIGURE_ARGS+=--with-zend-vm=GOTO
.endif

CONFIGURE_ENV+=	ac_cv_pthreads_lib="" \
		ac_cv_pthreads_cflags="" \
		ac_cv_decimal_fp_supported="no" \
		pthreads_working="yes" \
		lt_cv_path_SED="sed"

.if ${PORT_OPTIONS:MLINKTHR}
LIBS+=		-lpthread
.endif

.if ${PORT_OPTIONS:MDEBUG}
CONFIGURE_ARGS+=--enable-debug
.endif

.if ${PORT_OPTIONS:MZTS}
CONFIGURE_ARGS+=--enable-maintainer-zts
.endif

.if ${PORT_OPTIONS:MDTRACE}
CONFIGURE_ARGS+=--enable-dtrace
PLIST_SUB+=	DTRACE=""
.else
PLIST_SUB+=	DTRACE="@comment "
.endif

.if empty(PORT_OPTIONS:MIPV6)
CONFIGURE_ARGS+=--disable-ipv6
.endif

post-patch:
	@${TOUCH} ${WRKSRC}/ext/php_config.h
	@${REINPLACE_CMD} "s|^\(extension_dir\)|; \1|" ${WRKSRC}/php.ini-*
.if ${PORT_OPTIONS:MFPM}
# the FPM of the version: its own pid file and log, and the pool www (in
# php-fpm.conf in 5.6) on its own socket for the web server
	@${REINPLACE_CMD} -e "s|^;*pid = .*|pid = /var/run/php-fpm${PHP_VER}.pid|" \
		-e "s|^;*error_log = .*|error_log = /var/log/php-fpm${PHP_VER}.log|" \
		-e "s|^;\(pm\.[a-z_]*_servers\)|\1|" \
		-e "s|^listen = .*|listen = /var/run/php-fpm${PHP_VER}.sock|" \
		-e "s|^;*listen\.owner = .*|listen.owner = ${WWWOWN}|" \
		-e "s|^;*listen\.group = .*|listen.group = ${WWWGRP}|" \
		-e "s|^;*listen\.mode = .*|listen.mode = 0660|" \
		${WRKSRC}/sapi/fpm/php-fpm.conf.in
.endif

# xml2-config of az without -L/lib (AZ_XML2_CONFIG)
pre-configure:
	@${PRINTF} '%s\n' '#!/bin/sh' \
		'${AZ_PREFIX}/bin/xml2-config "$$@" | ${SED} -e "s|[[:space:]]-L/lib[[:space:]]| |g"' \
		> ${AZ_XML2_CONFIG}
	@${CHMOD} 755 ${AZ_XML2_CONFIG}

# main/php_config.h includes ext/php_config.h, where the packages of the
# modules add the config.h of their module (Mk/Uses/php.mk): the hunk of
# patch-configure.in of the official port that the fork does not apply
post-configure:
	@${ECHO_CMD} '#include <ext/php_config.h>' >> ${WRKSRC}/main/php_config.h

.if !defined(PKGNAMEPREFIX)
post-build:
	@${ECHO_CMD} "PHP_VER=${PHP_VER}" > ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_VERSION=${PORTVERSION}" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_SAPI=${PHP_SAPI}" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_EXT_INC=pcre spl" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} -n "PHP_EXT_DIR=" >> ${WRKDIR}/php.conf
	@${SH} ${WRKSRC}/scripts/php-config --extension-dir | sed -ne 's,^${PREFIX}/lib/php/,,p' >> ${WRKDIR}/php.conf

test: build
	@(cd ${WRKSRC} && ${MAKE} test)

# bin/php56-profile, the pkg-message (profiles, php.ini) and the block of az
# for php.ini, from templates (PHP_VER; the block one file per version); in
# files/, so that the modules do not take the message
SUB_FILES+=	php-profile pkg-message php.ini-az-${PHP_VER}
SUB_LIST+=	PHP_VER=${PHP_VER}

# etc/php56: php.conf (the version for Mk/Uses/php.mk), php.ini-development,
# php.ini-production and php.ini.sample (php.ini-production with the block of
# az at its end; php.ini by @sample); the empty directories of the modules: the
# scan dir etc/php56/conf.d and lib/php/20131226 (@dir)
post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/php${PHP_VER}/conf.d \
		${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR}
	${CAT} ${WRKSRC}/php.ini-production ${WRKDIR}/php.ini-az-${PHP_VER} \
		> ${WRKDIR}/php.ini.sample
	${INSTALL_DATA} ${WRKSRC}/php.ini-development ${WRKSRC}/php.ini-production \
		${WRKDIR}/php.ini.sample ${WRKDIR}/php.conf \
		${STAGEDIR}${PREFIX}/etc/php${PHP_VER}
	${INSTALL_SCRIPT} ${WRKDIR}/php-profile \
		${STAGEDIR}${PREFIX}/bin/php${PHP_VER}-profile
.else
do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/${APACHEMODDIR} \
		${STAGEDIR}${PREFIX}/${APACHEETCDIR}/modules.d
	${INSTALL_LIB} ${WRKSRC}/libs/libphp5.so \
		${STAGEDIR}${PREFIX}/${APACHEMODDIR}/${MODULENAME}.so
	${INSTALL_DATA} ${FILESDIR}/280_mod_php${PHP_VER}.conf.sample \
		${STAGEDIR}${PREFIX}/${APACHEETCDIR}/modules.d
.endif

.else
.include "${MASTERDIR}/Makefile.ext"
.endif
.include <bsd.port.post.mk>
