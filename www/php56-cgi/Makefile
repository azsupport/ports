# www/php56-cgi of azsupport/ports: the CGI of PHP 5.6 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php56 with the SAPI cgi alone (AZ_PHP_SAPI), as www/mod_php56 has
# the Apache module. bin/php56-cgi, for a web server that runs PHP as CGI or FastCGI
# programs (suexec and mod_fastcgi of Apache); php.ini and the modules are those of
# php56, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php56
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
AZ_PHP_SAPI=	cgi

OPTIONS_EXCLUDE=	CLI EMBED FPM PHPDBG
OPTIONS_SLAVE=	CGI

# the package php56-cgi: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php56-cgi
.MAKEFLAGS:	PKGNAME=php56-cgi-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
