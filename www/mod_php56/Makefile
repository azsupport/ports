# The Apache module of PHP 5.6 of azsupport/php-src: the official www/mod_php56 of
# freebsd-ports d2c06ef5efae with the idioms of the framework of f16b6dd (AP2FILTER by
# option helpers, as www/mod_php74). The module is libphp56.so (see
# lang/php56/Makefile), so it conflicts with no module of PHP of another version, only
# with the official mod_php56 (the same files: CONFLICTS_INSTALL).

CATEGORIES=	www devel
PKGNAMEPREFIX=	mod_

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php56
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}

OPTIONS_DEFINE=	AP2FILTER
AP2FILTER_DESC=	Use Apache 2.x filter interface (experimental)
OPTIONS_EXCLUDE=	CGI CLI FPM EMBED

AP2FILTER_CONFIGURE_ON=--with-apxs2filter=${APXS}
AP2FILTER_CONFIGURE_OFF=--with-apxs2=${APXS}

# The package apache24-php56 (aZ, 22.11.2026: the Apache it is for first, as
# apache24-mod_fastcgi and apache24-suexec, should an apache22 come beside it; from
# 21.11.2026 php56-apache): PKGBASE, and PKGNAME on the command line of make
# (.MAKEFLAGS), which the PKGNAME= of bsd.port.mk does not replace; PKGNAMEPREFIX mod_
# stays, by it lang/php56 builds the module of Apache.
PKGBASE=	apache24-php56
CONFLICTS_INSTALL=	mod_php56 php56-apache
.MAKEFLAGS:	PKGNAME=apache24-php56-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
