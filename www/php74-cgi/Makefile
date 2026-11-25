# www/php74-cgi of azsupport/ports: the CGI of PHP 7.4 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php74 with the SAPI cgi alone (AZSUPPORT_PHP_SAPI), as www/mod_php74 has
# the Apache module. bin/php74-cgi, for a web server that runs PHP as CGI or FastCGI
# programs (suexec and mod_fastcgi of Apache); php.ini and the modules are those of
# php74, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php74
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
# lang/php74 sets PHP_VER for its core only (its block of the core): the CGI
# takes it here, for the name of its program (bin/php74-cgi, as its plist)
PHP_VER=	74
PKGDIR=		${.CURDIR}
AZSUPPORT_PHP_SAPI=	cgi

OPTIONS_EXCLUDE=	CLI EMBED FPM PHPDBG
OPTIONS_SLAVE=	CGI

# the package php74-cgi: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php74-cgi
.MAKEFLAGS:	PKGNAME=php74-cgi-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
