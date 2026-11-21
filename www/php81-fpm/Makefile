# www/php81-fpm of azsupport/ports: the FPM of PHP 8.1 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php81 with the SAPI fpm alone (AZ_PHP_SAPI), as www/mod_php81 has
# the Apache module. sbin/php81-fpm; etc/php81/php-fpm.conf by @sample (pid
# /var/run/php81-fpm.pid, log /var/log/php81-fpm.log), its pools in etc/php81/php-fpm.d (the pool www on /var/run/php81-fpm.sock);
# share/php81/fpm/status.html; the rc.d script php81_fpm (php81_fpm_enable, the
# profiles of php81-profile: php81_fpm_profiles). php.ini and the modules are those of
# php81, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php81
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
FILESDIR=	${.CURDIR}/files
AZ_PHP_SAPI=	fpm

OPTIONS_EXCLUDE=	CGI CLI EMBED PHPDBG
OPTIONS_SLAVE=	FPM

# the package php81-fpm: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php81-fpm
.MAKEFLAGS:	PKGNAME=php81-fpm-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
