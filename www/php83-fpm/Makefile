# www/php83-fpm of azsupport/ports: the FPM of PHP 8.3 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php83 with the SAPI fpm alone (AZSUPPORT_PHP_SAPI), as www/mod_php83 has
# the Apache module. sbin/php83-fpm; etc/php83/php-fpm.conf by @sample (pid
# /var/run/php83-fpm.pid, log /var/log/php83-fpm.log), its pools in etc/php83/php-fpm.d (the pool www on /var/run/php83-fpm.sock);
# share/php83/fpm/status.html; the rc.d script php83_fpm (php83_fpm_enable, the
# profiles of php83-profile: php83_fpm_profiles). php.ini and the modules are those of
# php83, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php83
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
FILESDIR=	${.CURDIR}/files
AZSUPPORT_PHP_SAPI=	fpm

OPTIONS_EXCLUDE=	CGI CLI EMBED PHPDBG
OPTIONS_SLAVE=	FPM

# the package php83-fpm: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php83-fpm
.MAKEFLAGS:	PKGNAME=php83-fpm-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
