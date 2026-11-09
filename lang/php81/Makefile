# PHP 8.1 of azsupport/php-src for the overlay azsupport/ports: the official
# port lang/php81 of freebsd-ports 6002588334a9 (the ports commit of PHP 8.1 in
# php-src freebsd/targets.conf), changed as lang/php74 and lang/php83 are (see
# their heads; the same decisions of aZ, 08.11.2026), for the framework of the
# pinned tree (f16b6dd0f7c1). What differs, and why:
#
# - Source: the dated release tarball of the fork azsupport/php-src, PHP 8.1.34
#   with the security backports of Remi Collet (php-src freebsd/targets.conf),
#   the patches of the official port, the PECL extensions in ext/ and a
#   configure generated with them: no files/patch-*, no buildconf (no
#   autoreconf). Of the patches the fork leaves out (php-src
#   freebsd/patches/8.1/SKIPPED), the include of ext/php_config.h in
#   main/php_config.h (patch-configure.ac) is added in post-configure, as in
#   lang/php74. A new dated release of the same version: AZ_PHP_RELEASE and
#   distinfo.
# - PORTREVISION is the stamp of the build, AZ_STAMP of the builder (0 without
#   it; Mk/bsd.overlay.mk); the modules take it from here.
# - Versions side by side: every path of PHP 8.1 has 81 in it: bin/php81 ...
#   (--program-suffix=81), etc/php81 (php.ini by @sample from php.ini.sample:
#   php.ini-production with the defaults of az, files/php.ini-az-81.in, at its
#   end; errors in /var/log/php81_error.log, made at install when missing; FPM
#   with /var/run/php-fpm81.pid, /var/log/php-fpm81.log, the pool www on
#   /var/run/php-fpm81.sock), the scan dir etc/php81/conf.d, lib/php81 (the
#   build files of phpize81), include/php81, share/php81, etc/rc.d/php_fpm81,
#   libexec/apache24/libphp81.so (www/mod_php81); the modules in
#   lib/php/20210902 as the ports. No CONFLICTS_INSTALL with other versions.
# - Libraries: libxml2 and argon2 of the package az (${AZ_PREFIX}), by a file,
#   with its run path and pkg-config; the PCRE2 the fork bundles (no option
#   PCRE, no devel/pcre2). OpenSSL is not in the core (the official one has
#   --with-openssl): it is the module php81-openssl or php81-openssl-legacy, as
#   in lang/php74, so no USES=ssl here and php.conf has no openssl in
#   PHP_EXT_INC. No USES=localbase: no library of the ports.
# - Options: no MYSQLND (the module php81-mysqlnd), no PCRE (above); EMBED and
#   DTRACE off by default; PHPDBG off is --disable-phpdbg (8.1 builds phpdbg by
#   default too). OPcache is the module php81-opcache; this PHP loads modules.
# - No DEPRECATED/EXPIRATION_DATE (upstream end of life 31.12.2025 in the
#   official port): the fork carries the security fixes, as for 7.4.
# - Profiles: bin/php81-profile (files/php-profile.in, the template of every
#   version) and the profiles of the rc.d script php_fpm81, as lang/php74.
# - The Apache module (PKGNAMEPREFIX mod_): libphp81.so (8.x builds
#   libs/libphp.so: aZ, libphpXY.so for every version), not loaded by itself.
#
# The slave ports, the modules php81-<module>: a slave's Makefile sets
#	CATEGORIES=	<category>
#	PKGNAMESUFFIX=	-<module>
#	MASTERDIR=	${.CURDIR}/../../lang/php81
#	.include "${MASTERDIR}/Makefile"
# With PKGNAMESUFFIX defined this Makefile includes ${MASTERDIR}/Makefile.ext
# (the rules of the modules, as for lang/php74 and lang/php83; the official
# file has them inline) and ends with bsd.port.post.mk. Makefile.ext gets from
# here PORTNAME, DISTVERSION?= (a PECL extension sets its own version first),
# PORTREVISION, CATEGORIES?=, MASTER_SITES, DISTNAME (without DISTVERSION),
# DIST_SUBDIR, distinfo (through MASTERDIR), MAINTAINER, WWW, LICENSE, USES
# (compiler:c11 cpe gnome pkgconfig tar:xz) and PHP_VER (81).

PORTNAME=	php81
DISTVERSION?=	8.1.34
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES?=	lang devel www
MASTER_SITES=	https://github.com/azsupport/php-src/releases/download/freebsd-8.1-${AZ_PHP_RELEASE}/
DISTNAME=	php-8.1.34-fbsd-${AZ_PHP_RELEASE}
DIST_SUBDIR=	php

MAINTAINER=	github@azsupport.com
COMMENT=	PHP Scripting Language (8.1.X branch of azsupport/php-src)
WWW=		https://github.com/azsupport/php-src

LICENSE=	PHP301

USES+=		compiler:c11 cpe gnome pkgconfig tar:xz
CPE_PRODUCT=	php
PHP_VER=	81

# the dated release of the fork: its tag freebsd-8.1-<date>-<commit>; DISTNAME
# without DISTVERSION, which the slaves of PECL extensions set to their version
AZ_PHP_RELEASE=	20261109-af0f042f

# the files of this port that the ports needing it need not see (tools/build.sh),
# as in lang/php74: run-time files of the core only (post-install, USE_RC_SUBR,
# SUB_FILES), read by no module and not by mod_php81: the block of az for
# php.ini, bin/php81-profile, the rc.d script php_fpm81 and pkg-message
AZ_HASH_NOT_FOR_DEPENDENTS=	${FILESDIR}/php.ini-az-81.in ${FILESDIR}/php-profile.in \
				${FILESDIR}/php_fpm81.in ${FILESDIR}/pkg-message.in

.if !defined(PKGNAMESUFFIX)

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libargon2.so:az/az \
		${AZ_PREFIX}/lib/libxml2.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libargon2.so:az/az \
		${AZ_PREFIX}/lib/libxml2.so:az/az

GNU_CONFIGURE=	yes
CONFIGURE_ARGS+=	\
		--disable-all \
		--program-prefix="" \
		--program-suffix=${PHP_VER} \
		--with-config-file-path=${PREFIX}/etc/php${PHP_VER} \
		--with-config-file-scan-dir=${PREFIX}/etc/php${PHP_VER}/conf.d \
		--with-layout=GNU \
		--with-libxml \
		--with-password-argon2=${AZ_PREFIX} \
		--sysconfdir=${PREFIX}/etc/php${PHP_VER} \
		--libdir=${PREFIX}/lib/php${PHP_VER} \
		--includedir=${PREFIX}/include/php${PHP_VER} \
		--datadir=${PREFIX}/share/php${PHP_VER}
CONFIGURE_ENV=	CPPFLAGS="-I${AZ_PREFIX}/include" \
		EXTENSION_DIR=${PREFIX}/lib/php/${PHP_EXT_DIR}
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib

# the directory of the modules: ZEND_MODULE_API_NO of PHP 8.1, as the ports
PHP_EXT_DIR=	20210902
PLIST_SUB+=	PHP_EXT_DIR=${PHP_EXT_DIR}

# PR230207 Allow relocations against read-only segments (override lld default)
LDFLAGS_i386+=	-Wl,-z,notext

OPTIONS_DEFINE+=CGI CLI DEBUG DTRACE EMBED FPM IPV6 LINKTHR \
				PHPDBG ZTS
OPTIONS_DEFAULT=	CGI CLI FPM LINKTHR
OPTIONS_EXCLUDE_DragonFly=	DTRACE
# ld(1) fails to link probes: Relocations in generic ELF (EM: 0)
OPTIONS_EXCLUDE_aarch64=	DTRACE
# dt_modtext:opensolaris/ib/libdtrace/common/dt_link.c: arm not impemented
OPTIONS_EXCLUDE_armv6=	DTRACE
OPTIONS_EXCLUDE_armv7=	DTRACE
# Bug 197128:  No ASM code for MIPS/MIPS64, disable FPM
OPTIONS_EXCLUDE_mips=	DTRACE FPM
OPTIONS_EXCLUDE_mips64=	DTRACE FPM
OPTIONS_EXCLUDE_riscv64=	DTRACE
NO_OPTIONS_SORT=	yes
OPTIONS_SUB=			yes

CGI_DESC=	Build CGI version
CLI_DESC=	Build CLI version
EMBED_DESC=	Build embedded library
FPM_DESC=	Build FPM version
LINKTHR_DESC=	Link thread lib (for threaded extensions)
PHPDBG_DESC=	Interactive PHP debugger
ZTS_DESC=	Force Zend Thread Safety (ZTS) build

CGI_CONFIGURE_OFF=	--disable-cgi
CGI_VARS=		PHP_SAPI+=cgi
CLI_CONFIGURE_OFF=	--disable-cli
CLI_VARS=		PHP_SAPI+=cli
DEBUG_CONFIGURE_ON=	--enable-debug
DTRACE_CONFIGURE_ON=	--enable-dtrace
EMBED_CONFIGURE_ON=	--enable-embed
EMBED_VARS=		PHP_SAPI+=embed
FPM_CONFIGURE_ON=	--enable-fpm \
			--with-fpm-group=${WWWGRP} \
			--with-fpm-user=${WWWOWN}
FPM_VARS=		PHP_SAPI+=fpm \
			USE_RC_SUBR+=php_fpm${PHP_VER}
IPV6_CONFIGURE_OFF=	--disable-ipv6
LINKTHR_LIBS=		-lpthread
PHPDBG_CONFIGURE_ON=	--enable-phpdbg
PHPDBG_CONFIGURE_OFF=	--disable-phpdbg
PHPDBG_VARS=		PHP_SAPI+=phpdbg
ZTS_CONFIGURE_ON=	--enable-zts
ZTS_CONFIGURE_ENV=	pthreads_working="yes"

DESTDIRNAME=	INSTALL_ROOT

# The Apache module of the version, libphp81.so (aZ: libphpXY.so for every
# version; the official name is libphp.so), not loaded by itself: the package
# brings etc/apache24/modules.d/280_mod_php81.conf.sample to copy (one PHP
# module per Apache instance). It uses etc/php81 and the modules of php81.
.if defined(PKGNAMEPREFIX)
USES+=			apache
RUN_DEPENDS+=		${LOCALBASE}/include/php${PHP_VER}/php/main/php.h:lang/php${PHP_VER}
PLIST=			${PKGDIR}/pkg-plist.mod
PKGMESSAGE=		${PKGDIR}/pkg-message.mod
MODULENAME=		libphp${PHP_VER}
SHORTMODNAME=		php
WARNING=		"!!! If you have a threaded Apache, you must build ${PHP_PORT} with ZTS support to enable thread-safety in extensions !!!"
WARNING+=	"!!! Consider switching to php-fpm and mod_proxy_fcgi as per Apache httpd recommendations !!!"
.endif

.include <bsd.port.pre.mk>

.if ${ARCH} == riscv64
CONFIGURE_ARGS+=	--without-pcre-jit
.endif

.if ${PORT_OPTIONS:MPHPDBG} && ${PORT_OPTIONS:MDEBUG}
CONFIGURE_ARGS+=	--enable-phpdbg-debug
.endif

.if ${PORT_OPTIONS:MCLI} || ${PORT_OPTIONS:MEMBED}
PLIST_SUB+=	SAPI_INC=""
.else
PLIST_SUB+=	SAPI_INC="@comment "
.endif

CONFIGURE_ENV+=	ac_cv_decimal_fp_supported="no" \
		lt_cv_path_SED="sed"

# the pkg-config of the package az, after the PKG_CONFIG=pkgconf of
# USES=pkgconfig (the last one in CONFIGURE_ENV is the one configure gets)
CONFIGURE_ENV+=	PKG_CONFIG=${AZ_PREFIX}/bin/pkg-config

post-patch:
	@${TOUCH} ${WRKSRC}/ext/php_config.h

# the FPM of the version: its own pid file and log (php-fpm.conf), the pool www
# on its own socket for the web server (www.conf)
post-patch-FPM-on:
	@${REINPLACE_CMD} -e "s|^;*pid = .*|pid = /var/run/php-fpm${PHP_VER}.pid|" \
		-e "s|^;*error_log = .*|error_log = /var/log/php-fpm${PHP_VER}.log|" \
		-e "s|^;\(pm\.[a-z_]*_servers\)|\1|" \
		${WRKSRC}/sapi/fpm/php-fpm.conf.in
	@${REINPLACE_CMD} -e "s|^listen = .*|listen = /var/run/php-fpm${PHP_VER}.sock|" \
		-e "s|^;*listen\.owner = .*|listen.owner = ${WWWOWN}|" \
		-e "s|^;*listen\.group = .*|listen.group = ${WWWGRP}|" \
		-e "s|^;*listen\.mode = .*|listen.mode = 0660|" \
		${WRKSRC}/sapi/fpm/www.conf.in

# main/php_config.h includes ext/php_config.h, where the packages of the
# modules add the config.h of their module (Mk/Uses/php.mk): the hunk of
# patch-configure.ac of the official port that the fork does not apply
post-configure:
	@${ECHO_CMD} '#include <ext/php_config.h>' >> ${WRKSRC}/main/php_config.h

.if !defined(PKGNAMEPREFIX)
post-build:
	@${ECHO_CMD} "PHP_VER=${PHP_VER}" > ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_VERSION=${PORTVERSION}" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_SAPI=${PHP_SAPI}" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} -n "PHP_EXT_DIR=" >> ${WRKDIR}/php.conf
	@${SH} ${WRKSRC}/scripts/php-config --extension-dir | ${SED} -ne 's,^${PREFIX}/lib/php/,,p' >> ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_EXT_INC=hash json pcre spl" >> ${WRKDIR}/php.conf

test: build
	@(cd ${WRKSRC} && ${MAKE} test)

# bin/php81-profile, the pkg-message (profiles, php.ini) and the block of az
# for php.ini, from templates (PHP_VER; the block one file per version); in
# files/, so that the modules do not take the message
SUB_FILES+=	php-profile pkg-message php.ini-az-${PHP_VER}
SUB_LIST+=	PHP_VER=${PHP_VER}

# etc/php81: php.conf (the version for Mk/Uses/php.mk), php.ini-development,
# php.ini-production and php.ini.sample (php.ini-production with the block of
# az at its end; php.ini by @sample); the empty directories of the modules: the
# scan dir etc/php81/conf.d and lib/php/20210902 (@dir)
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

post-install-CGI-on:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/php-cgi${PHP_VER}

post-install-CLI-on:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/php${PHP_VER}

post-install-EMBED-on:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/php${PHP_VER}/libphp.so

post-install-FPM-on:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/sbin/php-fpm${PHP_VER}

post-install-PHPDBG-on:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/phpdbg${PHP_VER}

.else
do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/${APACHEMODDIR} \
		${STAGEDIR}${PREFIX}/${APACHEETCDIR}/modules.d
	${INSTALL_LIB} ${WRKSRC}/libs/libphp.so \
		${STAGEDIR}${PREFIX}/${APACHEMODDIR}/${MODULENAME}.so
	${INSTALL_DATA} ${FILESDIR}/280_mod_php${PHP_VER}.conf.sample \
		${STAGEDIR}${PREFIX}/${APACHEETCDIR}/modules.d
.endif

.else
.include "${MASTERDIR}/Makefile.ext"
.endif
.include <bsd.port.post.mk>
