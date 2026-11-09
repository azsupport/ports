# The Apache module of PHP 5.6 of azsupport/php-src: the official www/mod_php56
# of freebsd-ports d2c06ef5efae with the idioms of the framework of f16b6dd
# (AP2FILTER by option helpers, as www/mod_php74). The module is libphp56.so
# (see lang/php56/Makefile), so it conflicts with no mod_php of another
# version.

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

.include "${MASTERDIR}/Makefile"
