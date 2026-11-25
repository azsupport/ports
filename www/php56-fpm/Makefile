# www/php56-fpm of azsupport/ports: the FPM of PHP 5.6 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php56 with the SAPI fpm alone (AZSUPPORT_PHP_SAPI), as www/mod_php56 has
# the Apache module. sbin/php56-fpm; etc/php56/php-fpm.conf by @sample (pid
# /var/run/php56-fpm.pid, log /var/log/php56-fpm.log), the pool www in it, on /var/run/php56-fpm.sock;
# share/php56/fpm/status.html; the rc.d script php56_fpm (php56_fpm_enable, the
# profiles of php56-profile: php56_fpm_profiles). php.ini and the modules are those of
# php56, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php56
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
FILESDIR=	${.CURDIR}/files
AZSUPPORT_PHP_SAPI=	fpm

OPTIONS_EXCLUDE=	CGI CLI EMBED PHPDBG
OPTIONS_SLAVE=	FPM

# the package php56-fpm: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php56-fpm
.MAKEFLAGS:	PKGNAME=php56-fpm-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
