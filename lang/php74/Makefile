# PHP 7.4 of azsupport/php-src for the overlay azsupport/ports: the official
# port lang/php74 of freebsd-ports 036685c034ba (the ports commit of PHP 7.4 in
# php-src freebsd/targets.conf), changed only where the overlay needs it, and
# for the framework of the pinned tree (f16b6dd0f7c1). What differs, and why:
#
# - Source: the dated release tarball of the fork azsupport/php-src, PHP 7.4.33
#   with the security backports of Remi Collet and the PECL extensions in ext/.
#   It carries the patches of the official port and a configure generated with
#   them, so this port has no files/patch-* and runs no buildconf (no
#   autoreconf). Of the official patches the fork leaves out (php-src
#   freebsd/patches/7.4/SKIPPED) one hunk matters here, main/php_config.h
#   including ext/php_config.h (patch-configure.ac): post-configure adds it.
#   A new dated release of the same PHP version: AZ_PHP_RELEASE and distinfo.
# - PORTREVISION is the stamp of the build, AZ_STAMP of the builder (0 without
#   it; Mk/bsd.overlay.mk), so that every build is an upgrade; the modules take
#   it from here.
# - Versions side by side (aZ): every path of PHP 7.4 has 74 in it, nothing is
#   shared with another version: bin/php74 ... (--program-suffix=74), etc/php74
#   (php.ini by @sample from php.ini.sample: php.ini-production with the
#   defaults of az, files/php.ini-az-74.in, at its end; errors in
#   /var/log/php74_error.log, made at install when missing; FPM with
#   /var/run/php-fpm74.pid, /var/log/php-fpm74.log, the pool www on
#   /var/run/php-fpm74.sock), the scan
#   dir etc/php74/conf.d (the ini files of the modules), lib/php74 (the build
#   files of phpize74), include/php74, share/php74, etc/rc.d/php_fpm74 and
#   libexec/apache24/libphp74.so (www/mod_php74); the modules in
#   lib/php/20190902 as the ports. So no CONFLICTS_INSTALL with the other
#   versions (the modules set theirs in Makefile.ext).
# - Libraries: libxml2 and argon2 of the package az (${AZ_PREFIX}), depended
#   on by a file (no ldconfig hints for ${AZ_PREFIX}/lib: never LIB_DEPENDS),
#   linked with its run path and found by its pkg-config; PCRE2 the shared
#   library of devel/pcre2 of this tree, not the one the fork bundles.
# - Options: no MYSQLND (mysqlnd is the module php74-mysqlnd); EMBED and DTRACE
#   off by default; PHPDBG off is --disable-phpdbg (7.4 builds phpdbg unless
#   told not to). OPcache and json are modules too (php74-opcache, php74-json),
#   and this PHP loads modules (no --disable-extension-loading of the fork).
# - Profiles (aZ, 08.11.2026): other configurations of the same PHP, each the
#   directory etc/php74-<profile> (php.ini, conf.d, php-fpm.conf), made by
#   bin/php74-profile (files/php-profile.in, generic: %%PHP_VER%%), which also
#   runs PHP with one and keeps the profiles that follow etc/php74 up to date
#   (--sync, from the modules); the rc.d script php_fpm74 runs their php-fpm74
#   as the profiles of www/apache24. Nothing of a profile is a file of the
#   package; pkg-message says how.
# - The compiler (aZ, 09.11.2026): GCC of the ports (lang/gcc16) for the C,
#   at build time only, by USES=azgcc of the overlay (Mk/Uses/azgcc.mk: why,
#   and how no file needs a library of GCC at run time): the core, mod_php74
#   and the modules (they take it from here), but those with C++ (intl, swoole,
#   openswoole) and imagick and gmagick (OpenMP), which keep the base clang
#   (AZ_GCC=no in their rules).
# - No DEPRECATED/EXPIRATION_DATE: the fork carries the security fixes.
# - The Apache module (PKGNAMEPREFIX mod_) with the idioms of the framework of
#   f16b6dd (USES=apache before bsd.port.pre.mk, as lang/php84 there).
#
# The slave ports, the modules php74-<module>: a slave's Makefile sets
#	CATEGORIES=	<category>
#	PKGNAMESUFFIX=	-<module>
#	MASTERDIR=	${.CURDIR}/../../lang/php74
#	.include "${MASTERDIR}/Makefile"
# With PKGNAMESUFFIX defined this Makefile includes ${MASTERDIR}/Makefile.ext
# (the rules of the modules) and ends with bsd.port.post.mk. Makefile.ext gets
# from here PORTNAME, DISTVERSION?= (a slave of a PECL extension sets its own
# version first), PORTREVISION (the stamp), CATEGORIES?=, MASTER_SITES,
# DISTNAME (the top directory of the tarball, without DISTVERSION),
# DIST_SUBDIR, distinfo (through MASTERDIR), MAINTAINER, WWW, LICENSE and USES
# (azgcc compiler:c11 cpe gnome pkgconfig tar:xz); it sets COMMENT,
# CONFLICTS_INSTALL, USES+= php:ext
# (php:zend), PHP_VER=74, PHP_MODNAME, WRKSRC and EXTRACT_AFTER_ARGS (only
# ${DISTNAME}/ext/<module>), PLIST=${NONEXISTENT}, the options and arguments of
# each module, and includes bsd.port.options.mk and bsd.port.pre.mk itself.
# Mk/Uses/php.mk of the overlay builds, installs and registers the module (see
# its head).

PORTNAME=	php74
DISTVERSION?=	7.4.33
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES?=	lang devel www
MASTER_SITES=	https://github.com/azsupport/php-src/releases/download/freebsd-7.4-${AZ_PHP_RELEASE}/
DISTNAME=	php-7.4.33-fbsd-${AZ_PHP_RELEASE}
DIST_SUBDIR=	php

MAINTAINER=	github@azsupport.com
COMMENT=	PHP Scripting Language (7.4.X branch of azsupport/php-src)
WWW=		https://github.com/azsupport/php-src

LICENSE=	PHP301

USES+=		compiler:c11 tar:xz cpe gnome pkgconfig
# GCC of the ports for the C, at build time only (Mk/Uses/azgcc.mk)
USES+=		azgcc
CPE_PRODUCT=	php
NO_OPTIONS_SORT=yes

# the dated release of the fork: its tag freebsd-7.4-<date>-<commit>; DISTNAME
# without DISTVERSION, which the slaves of PECL extensions set to their version
AZ_PHP_RELEASE=	20261113-397aa202

# the files of this port that the ports needing it need not see (tools/build.sh):
# they are installed and used at run time only (post-install, USE_RC_SUBR,
# SUB_FILES of the core) and no module or mod_php74 build reads them, so a change
# of one builds php74 again, not the modules and mod_php74 (the slaves of this
# Makefile leave them out of their az_hash too): the block of az for php.ini,
# bin/php74-profile, the rc.d script php_fpm74 and pkg-message
AZ_HASH_NOT_FOR_DEPENDENTS=	${FILESDIR}/php.ini-az-74.in ${FILESDIR}/php-profile.in \
				${FILESDIR}/php_fpm74.in ${FILESDIR}/pkg-message.in

.if !defined(PKGNAMESUFFIX)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libargon2.so:az/az \
		${AZ_PREFIX}/lib/libxml2.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libargon2.so:az/az \
		${AZ_PREFIX}/lib/libxml2.so:az/az

GNU_CONFIGURE=	yes
CONFIGURE_ARGS+=--with-layout=GNU \
		--with-config-file-path=${PREFIX}/etc/php74 \
		--with-config-file-scan-dir=${PREFIX}/etc/php74/conf.d \
		--disable-all \
		--with-libxml \
		--with-password-argon2=${AZ_PREFIX} \
		--program-prefix="" \
		--program-suffix=74 \
		--sysconfdir=${PREFIX}/etc/php74 \
		--libdir=${PREFIX}/lib/php74 \
		--includedir=${PREFIX}/include/php74 \
		--datadir=${PREFIX}/share/php74
CONFIGURE_ENV=	CPPFLAGS="-I${AZ_PREFIX}/include" \
		EXTENSION_DIR=${PREFIX}/lib/php/${PHP_EXT_DIR}
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib
# PCRE2: the shared library of devel/pcre2 of this tree, not the one the fork
# bundles (aZ, 10.11.2026: our ports link each other's shared libraries; one PCRE2
# for PHP, Apache, git, nginx): --with-external-pcre, its flags by hand (the
# pkg-config of the core is that of az): pcre2.h and libpcre2-8.so alone in a
# directory of the work (links to those of /usr/local: no other header or library
# of /usr/local is seen; pre-configure), -lpcre2-8 by its -L after that of az; no
# run path, libpcre2-8.so.0 is in /usr/local/lib, one of ldconfig. The modules find pcre2.h next to
# php_pcre.h, which includes it ("pcre2.h"): the link ext/pcre/pcre2.h of the
# headers (post-install)
LIB_DEPENDS=	libpcre2-8.so:devel/pcre2
CONFIGURE_ARGS+=	--with-external-pcre
CONFIGURE_ENV+=	PCRE2_CFLAGS="-I${WRKDIR}/pcre2" \
		PCRE2_LIBS="-lpcre2-8"
LDFLAGS+=	-L${WRKDIR}/pcre2

# the directory of the modules: ZEND_MODULE_API_NO of PHP 7.4, as the ports
PHP_EXT_DIR=	20190902
PLIST_SUB+=	PHP_EXT_DIR=${PHP_EXT_DIR}

# PR230207 Allow relocations against read-only segments (override lld default)
LDFLAGS_i386=	-Wl,-z,notext

OPTIONS_DEFINE+=CLI CGI FPM EMBED PHPDBG DEBUG DTRACE IPV6 LINKTHR ZTS
OPTIONS_DEFAULT=CLI CGI FPM LINKTHR
OPTIONS_EXCLUDE_DragonFly=	DTRACE
# ld(1) fails to link probes: Relocations in generic ELF (EM: 0)
OPTIONS_EXCLUDE_aarch64=	DTRACE
# dt_modtext:opensolaris/ib/libdtrace/common/dt_link.c: arm not impemented
OPTIONS_EXCLUDE_armv6=		DTRACE
OPTIONS_EXCLUDE_armv7=		DTRACE
# Bug 197128:  No ASM code for MIPS/MIPS64, disable FPM
OPTIONS_EXCLUDE_mips=		DTRACE FPM
OPTIONS_EXCLUDE_mips64=		DTRACE FPM
OPTIONS_EXCLUDE_powerpc64=	${OPTIONS_EXCLUDE_${ARCH}_${OSREL:R}}
OPTIONS_EXCLUDE_powerpc64_12=	DTRACE
OPTIONS_EXCLUDE_riscv64=	DTRACE
OPTIONS_EXCLUDE_sparc64=	DTRACE
OPTIONS_SUB=	yes

CGI_DESC=	Build CGI version
CLI_DESC=	Build CLI version
EMBED_DESC=	Build embedded library
FPM_DESC=	Build FPM version
LINKTHR_DESC=	Link thread lib (for threaded extensions)
PHPDBG_DESC=	Interactive PHP debugger
ZTS_DESC=	Force Zend Thread Safety (ZTS) build

CGI_CONFIGURE_OFF=--disable-cgi
CGI_VARS=	PHP_SAPI+=cgi
CLI_CONFIGURE_OFF=--disable-cli
CLI_VARS=	PHP_SAPI+=cli
DEBUG_CONFIGURE_ON=--enable-debug
DTRACE_CONFIGURE_ON=--enable-dtrace
EMBED_CONFIGURE_ON=--enable-embed
EMBED_VARS=	PHP_SAPI+=embed
FPM_CONFIGURE_ON=--enable-fpm \
		--with-fpm-user=${WWWOWN} \
		--with-fpm-group=${WWWGRP}
FPM_VARS=	PHP_SAPI+=fpm USE_RC_SUBR+=php_fpm74
IPV6_CONFIGURE_OFF=--disable-ipv6
LINKTHR_LIBS=		-lpthread
PHPDBG_CONFIGURE_ON=--enable-phpdbg
PHPDBG_CONFIGURE_OFF=--disable-phpdbg
PHPDBG_VARS=	PHP_SAPI+=phpdbg
ZTS_CONFIGURE_ENV=	pthreads_working="yes"
ZTS_CONFIGURE_ON=--enable-maintainer-zts

DESTDIRNAME=	INSTALL_ROOT

# The Apache module of the version, libphp74.so (aZ: libphpXY.so for every
# version, so that the versions side by side do not overwrite each other; the
# official name is libphp7.so). Not loaded by itself: the package brings
# etc/apache24/modules.d/280_mod_php74.conf.sample to copy (one PHP module per
# Apache instance), so no apxs -e -a. It uses etc/php74 and the modules of
# php74, so it depends on php74.
.if defined(PKGNAMEPREFIX)
USES+=		apache
RUN_DEPENDS+=	${LOCALBASE}/include/php74/php/main/php.h:lang/php74
PLIST=		${PKGDIR}/pkg-plist.mod
PKGMESSAGE=	${PKGDIR}/pkg-message.mod
MODULENAME=	libphp74
SHORTMODNAME=	php7
WARNING=	"!!! If you have a threaded Apache, you must build ${PHP_PORT} with ZTS support to enable thread-safety in extensions !!!"
.endif

.include <bsd.port.pre.mk>

.if ${ARCH} == riscv64
CONFIGURE_ARGS+=--without-pcre-jit
.endif

.if ${PORT_OPTIONS:MPHPDBG} && ${PORT_OPTIONS:MDEBUG}
CONFIGURE_ARGS+=--enable-phpdbg-debug
.endif

.if ${PORT_OPTIONS:MCLI} || ${PORT_OPTIONS:MEMBED}
PLIST_SUB+=	SAPI_INC=""
.else
PLIST_SUB+=	SAPI_INC="@comment "
.endif

CONFIGURE_ENV+=	ac_cv_decimal_fp_supported="no" \
		lt_cv_path_SED="sed"

# the pkg-config of the package az (it runs pkgconf of USES=pkgconfig with the
# .pc files of ${AZ_PREFIX} first): after USES=pkgconfig added PKG_CONFIG=pkgconf
# to CONFIGURE_ENV, so that this one, the last, is the one configure gets
CONFIGURE_ENV+=	PKG_CONFIG=${AZ_PREFIX}/bin/pkg-config

post-patch:
	@${TOUCH} ${WRKSRC}/ext/php_config.h
	@${REINPLACE_CMD} "s|^\(extension_dir\)|; \1|" ${WRKSRC}/php.ini-*

# the FPM of the version: its own pid file and log (php-fpm.conf), the pool www
# on its own socket for the web server (www.conf)
post-patch-FPM-on:
	@${REINPLACE_CMD} -e "s|^;*pid = .*|pid = /var/run/php-fpm74.pid|" \
		-e "s|^;*error_log = .*|error_log = /var/log/php-fpm74.log|" \
		-e "s|^;\(pm\.[a-z_]*_servers\)|\1|" \
		${WRKSRC}/sapi/fpm/php-fpm.conf.in
	@${REINPLACE_CMD} -e "s|^listen = .*|listen = /var/run/php-fpm74.sock|" \
		-e "s|^;*listen\.owner = .*|listen.owner = ${WWWOWN}|" \
		-e "s|^;*listen\.group = .*|listen.group = ${WWWGRP}|" \
		-e "s|^;*listen\.mode = .*|listen.mode = 0660|" \
		${WRKSRC}/sapi/fpm/www.conf.in

# the directory of PCRE2 for configure: pcre2.h and libpcre2-8.so alone
# (PCRE2_CFLAGS and LDFLAGS above)
pre-configure:
	@${MKDIR} ${WRKDIR}/pcre2
	@${LN} -sf ${LOCALBASE}/include/pcre2.h ${LOCALBASE}/lib/libpcre2-8.so ${WRKDIR}/pcre2/

# main/php_config.h includes ext/php_config.h, where the packages of the
# modules add the config.h of their module (Mk/Uses/php.mk): the hunk of
# patch-configure.ac of the official port that the fork does not apply
post-configure:
	@${ECHO_CMD} '#include <ext/php_config.h>' >> ${WRKSRC}/main/php_config.h

.if !defined(PKGNAMEPREFIX)
post-build:
	@${ECHO_CMD} "PHP_VER=74" > ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_VERSION=${PORTVERSION}" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_SAPI=${PHP_SAPI}" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} "PHP_EXT_INC=hash pcre spl" >> ${WRKDIR}/php.conf
	@${ECHO_CMD} -n "PHP_EXT_DIR=" >> ${WRKDIR}/php.conf
	@${SH} ${WRKSRC}/scripts/php-config --extension-dir | ${SED} -ne 's,^${PREFIX}/lib/php/,,p' >> ${WRKDIR}/php.conf

test: build
	@(cd ${WRKSRC} && ${MAKE} test)

# bin/php74-profile, the pkg-message (profiles, php.ini) and the block of az
# for php.ini, from templates (PHP_VER; the block one file per version); in
# files/, so that the modules do not take the message
PHP_VER=	74
SUB_FILES+=	php-profile pkg-message php.ini-az-${PHP_VER}
SUB_LIST+=	PHP_VER=${PHP_VER}

# etc/php74: php.conf (the version for Mk/Uses/php.mk), php.ini-development,
# php.ini-production and php.ini.sample (php.ini-production with the block of
# az at its end; php.ini by @sample); the empty directories of the modules: the
# scan dir etc/php74/conf.d and lib/php/20190902 (@dir)
post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/php74/conf.d \
		${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR}
	${LN} -sf ${LOCALBASE}/include/pcre2.h \
		${STAGEDIR}${PREFIX}/include/php${PHP_VER}/php/ext/pcre/pcre2.h
	${CAT} ${WRKSRC}/php.ini-production ${WRKDIR}/php.ini-az-${PHP_VER} \
		> ${WRKDIR}/php.ini.sample
	${INSTALL_DATA} ${WRKSRC}/php.ini-development ${WRKSRC}/php.ini-production \
		${WRKDIR}/php.ini.sample ${WRKDIR}/php.conf ${STAGEDIR}${PREFIX}/etc/php74
	${INSTALL_SCRIPT} ${WRKDIR}/php-profile ${STAGEDIR}${PREFIX}/bin/php74-profile
.else
do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/${APACHEMODDIR} \
		${STAGEDIR}${PREFIX}/${APACHEETCDIR}/modules.d
	${INSTALL_LIB} ${WRKSRC}/libs/libphp7.so \
		${STAGEDIR}${PREFIX}/${APACHEMODDIR}/${MODULENAME}.so
	${INSTALL_DATA} ${FILESDIR}/280_mod_php74.conf.sample \
		${STAGEDIR}${PREFIX}/${APACHEETCDIR}/modules.d
.endif

.else
.include "${MASTERDIR}/Makefile.ext"
.endif
.include <bsd.port.post.mk>
