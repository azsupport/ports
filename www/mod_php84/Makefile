# The Apache module of PHP 8.4 of azsupport/php-src: the official www/mod_php84
# of freebsd-ports 1a235373d266. The module is libphp84.so (see
# lang/php84/Makefile), so it conflicts with no mod_php of another version: no
# CONFLICTS_INSTALL. PHP_PORT for the WARNING of the master, as mod_php74.

CATEGORIES=	www devel
PKGNAMEPREFIX=	mod_

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php84
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}

OPTIONS_DEFINE=		AP2FILTER
OPTIONS_EXCLUDE=	CGI CLI EMBED FPM

AP2FILTER_DESC=	Use Apache 2.x filter interface (experimental)

AP2FILTER_CONFIGURE_ON=--with-apxs2filter=${APXS}
AP2FILTER_CONFIGURE_OFF=--with-apxs2=${APXS}

.include "${MASTERDIR}/Makefile"
