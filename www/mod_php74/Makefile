# The Apache module of PHP 7.4 of azsupport/php-src: the official www/mod_php74
# of freebsd-ports 036685c034ba with the idioms of the framework of f16b6dd
# (AP2FILTER by option helpers, as www/mod_php84 there). The module is
# libphp74.so (see lang/php74/Makefile), so it conflicts with no mod_php of
# another version: CONFLICTS_INSTALL php74-static of the master (the same file).

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

.include "${MASTERDIR}/Makefile"
