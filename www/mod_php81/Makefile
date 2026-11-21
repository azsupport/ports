# The Apache module of PHP 8.1 of azsupport/php-src: the official www/mod_php81 of
# freebsd-ports 6002588334a9. The module is libphp81.so (see lang/php81/Makefile), so
# it conflicts with no module of PHP of another version, only with the official
# mod_php81 (the same files: CONFLICTS_INSTALL).

CATEGORIES=	www devel
PKGNAMEPREFIX=	mod_

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php81
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}

OPTIONS_DEFINE=		AP2FILTER
OPTIONS_EXCLUDE=	CGI CLI EMBED FPM

AP2FILTER_DESC=	Use Apache 2.x filter interface (experimental)

AP2FILTER_CONFIGURE_ON=--with-apxs2filter=${APXS}
AP2FILTER_CONFIGURE_OFF=--with-apxs2=${APXS}

# The package php81-apache (aZ, 21.11.2026: the name with the version first, as
# php84-gd): PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS), which the
# PKGNAME= of bsd.port.mk does not replace; PKGNAMEPREFIX mod_ stays, by it lang/php81
# builds the module of Apache.
PKGBASE=	php81-apache
CONFLICTS_INSTALL=	mod_php81
.MAKEFLAGS:	PKGNAME=php81-apache-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
