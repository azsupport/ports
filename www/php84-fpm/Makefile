# www/php84-fpm of azsupport/ports: the FPM of PHP 8.4 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php84 with the SAPI fpm alone (AZ_PHP_SAPI), as www/mod_php84 has
# the Apache module. sbin/php84-fpm; etc/php84/php-fpm.conf by @sample (pid
# /var/run/php84-fpm.pid, log /var/log/php84-fpm.log), its pools in etc/php84/php-fpm.d (the pool www on /var/run/php84-fpm.sock);
# share/php84/fpm/status.html; the rc.d script php84_fpm (php84_fpm_enable, the
# profiles of php84-profile: php84_fpm_profiles). php.ini and the modules are those of
# php84, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php84
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
FILESDIR=	${.CURDIR}/files
AZ_PHP_SAPI=	fpm

OPTIONS_EXCLUDE=	CGI CLI EMBED PHPDBG
OPTIONS_SLAVE=	FPM

# the package php84-fpm: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php84-fpm
.MAKEFLAGS:	PKGNAME=php84-fpm-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
