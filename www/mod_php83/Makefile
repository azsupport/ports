# The Apache module of PHP 8.3 of azsupport/php-src: the official www/mod_php83 of
# freebsd-ports eb0100f974b6. The module is libphp83.so (see lang/php83/Makefile), so
# it conflicts with no module of PHP of another version, only with the official
# mod_php83 (the same files: CONFLICTS_INSTALL). PHP_PORT for the WARNING of the
# master, as mod_php74.

CATEGORIES=	www devel
PKGNAMEPREFIX=	mod_

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php83
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}

OPTIONS_DEFINE=		AP2FILTER
OPTIONS_EXCLUDE=	CGI CLI EMBED FPM

AP2FILTER_DESC=	Use Apache 2.x filter interface (experimental)

AP2FILTER_CONFIGURE_ON=--with-apxs2filter=${APXS}
AP2FILTER_CONFIGURE_OFF=--with-apxs2=${APXS}

# The package apache24-php83 (aZ, 22.11.2026: the Apache it is for first, as
# apache24-mod_fastcgi and apache24-suexec, should an apache22 come beside it; before,
# mod_php83): PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS), which the
# PKGNAME= of bsd.port.mk does not replace; PKGNAMEPREFIX mod_ stays, by it lang/php83
# builds the module of Apache.
PKGBASE=	apache24-php83
CONFLICTS_INSTALL=	mod_php83
.MAKEFLAGS:	PKGNAME=apache24-php83-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
