# The Apache module of PHP 8.1 of azsupport/php-src: the official www/mod_php81
# of freebsd-ports 6002588334a9. The module is libphp81.so (see
# lang/php81/Makefile), so it conflicts with no mod_php of another version: no
# CONFLICTS_INSTALL.

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

.include "${MASTERDIR}/Makefile"
