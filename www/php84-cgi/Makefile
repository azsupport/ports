# www/php84-cgi of azsupport/ports: the CGI of PHP 8.4 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php84 with the SAPI cgi alone (AZ_PHP_SAPI), as www/mod_php84 has
# the Apache module. bin/php84-cgi, for a web server that runs PHP as CGI or FastCGI
# programs (suexec and mod_fastcgi of Apache); php.ini and the modules are those of
# php84, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php84
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
AZ_PHP_SAPI=	cgi

OPTIONS_EXCLUDE=	CLI EMBED FPM PHPDBG
OPTIONS_SLAVE=	CGI

# the package php84-cgi: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php84-cgi
.MAKEFLAGS:	PKGNAME=php84-cgi-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
