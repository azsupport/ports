# devel/php84-composer: Composer of azsupport/ports for PHP 8.4, in the place of the
# official devel/php-composer (aZ, 15.11.2026), and the master of
# devel/php56-composer, php74, php81, php82 and php83: the official port (its
# modules ctype, filter, intl, mbstring, phar and, by its default CURL, curl; json
# too for 5.6 and 7.4, where it is a module) with the version of PHP in the names, as
# our PHP has it (bin/php84): bin/composer84 runs libexec/composer84.phar with
# bin/php84, so that the Composers of every PHP install side by side (the phar starts
# with "#!/usr/bin/env php", and our PHP has no bin/php). Composer 2.11.3 for PHP
# 7.2.5 and later; for PHP 5.6 the LTS line 2.2 (2.2.33), from the releases of
# Composer on GitHub. 2.11.3 and 2.2.33 (24.11.2026), taken before the official port
# (2.11.2) for their security fixes: GHSA-374h-4mh9-7rpm (code run by Composer in a
# directory whose composer.json and vendor directory an attacker prepared, a way
# around the fix of CVE-2024-24821), package metadata rendered as console markup, and
# the credentials of repository URLs in error messages; the file of GitHub and that
# of getcomposer.org the same (size, SHA-256, and the .sha256sum of getcomposer.org;
# fetch-sums.yml on a runner of aZ, 24.11.2026). No openssl module as a dependency, as in the
# official port: phpXY-openssl or phpXY-openssl-legacy, one of the two, for
# packagist.org over HTTPS.

PORTNAME=	composer
DISTVERSION?=	2.11.3
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	devel
MASTER_SITES=	https://github.com/composer/composer/releases/download/${DISTVERSION}/ \
		https://getcomposer.org/download/${DISTVERSION}/
PKGNAMEPREFIX=	${PHP_PKGNAMEPREFIX}
DISTNAME=	composer
EXTRACT_SUFX=	.phar
DIST_SUBDIR=	${PORTNAME}-${PORTVERSION}

MAINTAINER=	github@azsupport.com
COMMENT=	Dependency Manager for PHP (of azsupport/ports)
WWW=		https://getcomposer.org/ \
		https://github.com/azsupport/ports

LICENSE=	MIT

PHP_VER?=	84
USES=		cpe php
CPE_VENDOR=	getcomposer
USE_PHP=	ctype filter intl mbstring phar
.if ${PHP_VER} == 56 || ${PHP_VER} == 74
USE_PHP+=	json
.endif
NO_ARCH=	yes
NO_BUILD=	yes
NO_WRKSUBDIR=	yes

SUB_FILES=	composer
SUB_LIST=	PHP=${PREFIX}/bin/php${PHP_VER} \
		PHAR=${PREFIX}/libexec/composer${PHP_VER}.phar
PLIST_FILES=	bin/composer${PHP_VER} \
		libexec/composer${PHP_VER}.phar

OPTIONS_DEFINE=		CURL
OPTIONS_DEFAULT=	CURL
CURL_DESC=	Install the cURL extension for faster downloads
CURL_USE=	PHP=curl

do-extract:
	${MKDIR} ${WRKSRC}/
	${CP} ${_DISTDIR}/composer.phar ${WRKSRC}/

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/libexec
	${INSTALL_DATA} ${WRKSRC}/composer.phar ${STAGEDIR}${PREFIX}/libexec/composer${PHP_VER}.phar
	${INSTALL_SCRIPT} ${WRKDIR}/composer ${STAGEDIR}${PREFIX}/bin/composer${PHP_VER}

.include <bsd.port.mk>
