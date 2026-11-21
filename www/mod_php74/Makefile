# The Apache module of PHP 7.4 of azsupport/php-src: the official www/mod_php74 of
# freebsd-ports 036685c034ba with the idioms of the framework of f16b6dd (AP2FILTER by
# option helpers, as www/mod_php84 there). The module is libphp74.so (see
# lang/php74/Makefile), so it conflicts with no module of PHP of another version, only
# with the official mod_php74 (the same files: CONFLICTS_INSTALL).

CATEGORIES=	www devel
PKGNAMEPREFIX=	mod_

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php74
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}

OPTIONS_DEFINE=		AP2FILTER
OPTIONS_EXCLUDE=	CGI CLI EMBED FPM
AP2FILTER_DESC=		Use Apache 2.x filter interface (experimental)

AP2FILTER_CONFIGURE_ON=--with-apxs2filter=${APXS}
AP2FILTER_CONFIGURE_OFF=--with-apxs2=${APXS}

# The package apache24-php74 (aZ, 22.11.2026: the Apache it is for first, as
# apache24-mod_fastcgi and apache24-suexec, should an apache22 come beside it; before,
# mod_php74): PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS), which the
# PKGNAME= of bsd.port.mk does not replace; PKGNAMEPREFIX mod_ stays, by it lang/php74
# builds the module of Apache.
PKGBASE=	apache24-php74
CONFLICTS_INSTALL=	mod_php74
.MAKEFLAGS:	PKGNAME=apache24-php74-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
