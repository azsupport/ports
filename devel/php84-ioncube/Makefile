# devel/php84-ioncube of azsupport/ports (aZ, 20.11.2026: the ionCube Loader for our
# PHP, as the distributions package it): the ionCube Loader 15.5.1 (18.09.2026) for
# PHP 8.4, and the master of php56-ioncube, php74-ioncube, php81-ioncube,
# php82-ioncube and php83-ioncube (each sets PHP_VER). The loaders are ionCube's
# binaries for FreeBSD as they are (ioncube_loaders_fre_11_x86-64, stripped by
# ionCube; NO_BUILD): built on FreeBSD 11, they call stat@FBSD_1.0 and fstat@FBSD_1.0
# of libc, which need COMPAT_FREEBSD11 in the kernel (GENERIC has it). As the
# distributions install them:
# - the loader of the NTS build of the version (our cores are not ZTS), as
#   lib/php/<API>/ioncube_loader.so (FreeBSD devel/ioncube; Remi php-ioncube-loader
#   and Arch php-ioncube_loader: <extension dir>/ioncube_loader.so);
# - loaded before every other zend_extension ("It must be the first engine extension
#   to be installed", the README of ionCube): etc/phpXY/conf.d/ext-05-ioncube.ini,
#   before ext-10-opcache.ini (FreeBSD: ext-05-ioncube.ini; Remi:
#   01-ioncube_loader.ini; Arch: 00-ioncube_loader.ini), zend_extension=ioncube_loader.so
#   as for our OPcache (Remi the same from PHP 5.5 on);
# - the license of ionCube with it (LICENSE.txt 2.1: the loader may be distributed
#   "provided that this license is also included"), in share/licenses/<package>/.
# The tarball of the version (ionCube keeps one per release, as Remi takes it) over
# the one of the latest release, whose name stays and whose content changes.

PORTNAME=	ioncube
DISTVERSION=	15.5.1
CATEGORIES=	devel
MASTER_SITES=	https://downloads2.ioncube.com/loader_downloads/ \
		https://downloads.ioncube.com/loader_downloads/
PKGNAMEPREFIX=	php${PHP_VER}-
DISTNAME=	ioncube_loaders_fre_11_x86-64_${DISTVERSION}
DIST_SUBDIR=	ioncube

MAINTAINER=	github@azsupport.com
COMMENT=	ionCube Loader for PHP ${PHP_VER:C/^(.)/\1./}: runs files encoded by ionCube
WWW=		https://www.ioncube.com/loaders.php

LICENSE=	IONCUBE-PHP-LOADER
LICENSE_NAME=	ionCube PHP Loader
LICENSE_FILE=	${WRKSRC}/LICENSE.txt
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

ONLY_FOR_ARCHS=	amd64
ONLY_FOR_ARCHS_REASON=	ionCube builds its loaders for FreeBSD for amd64 and i386 only

USES=		php
PHP_VER?=	84
NO_BUILD=	yes
WRKSRC=		${WRKDIR}/ioncube

PHP_DOTVER=	${PHP_VER:C/^(.)/\1./}
IC_INI=		etc/php${PHP_VER}/conf.d/ext-05-ioncube.ini
PLIST_FILES=	lib/php/${PHP_EXT_DIR}/ioncube_loader.so \
		"@sample ${IC_INI}.sample" \
		share/licenses/${PKGBASE}/LICENSE.txt

do-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR} \
		${STAGEDIR}${PREFIX}/etc/php${PHP_VER}/conf.d \
		${STAGEDIR}${PREFIX}/share/licenses/${PKGBASE}
	${INSTALL_DATA} ${WRKSRC}/ioncube_loader_fre_${PHP_DOTVER}.so \
		${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR}/ioncube_loader.so
	${CHMOD} 0555 ${STAGEDIR}${PREFIX}/lib/php/${PHP_EXT_DIR}/ioncube_loader.so
	${PRINTF} '%s\n' '; the ionCube Loader ${DISTVERSION}: the first zend_extension of PHP ${PHP_DOTVER}' \
		'; (ext-05, before ext-10-opcache.ini)' 'zend_extension=ioncube_loader.so' \
		> ${STAGEDIR}${PREFIX}/${IC_INI}.sample
	${INSTALL_DATA} ${WRKSRC}/LICENSE.txt ${STAGEDIR}${PREFIX}/share/licenses/${PKGBASE}/LICENSE.txt

.include <bsd.port.mk>
