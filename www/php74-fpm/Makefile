# www/php74-fpm of azsupport/ports: the FPM of PHP 7.4 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php74 with the SAPI fpm alone (AZ_PHP_SAPI), as www/mod_php74 has
# the Apache module. sbin/php74-fpm; etc/php74/php-fpm.conf by @sample (pid
# /var/run/php74-fpm.pid, log /var/log/php74-fpm.log), its pools in etc/php74/php-fpm.d (the pool www on /var/run/php74-fpm.sock);
# share/php74/fpm/status.html; the rc.d script php74_fpm (php74_fpm_enable, the
# profiles of php74-profile: php74_fpm_profiles). php.ini and the modules are those of
# php74, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php74
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
FILESDIR=	${.CURDIR}/files
AZ_PHP_SAPI=	fpm

OPTIONS_EXCLUDE=	CGI CLI EMBED PHPDBG
OPTIONS_SLAVE=	FPM

# the package php74-fpm: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php74-fpm
.MAKEFLAGS:	PKGNAME=php74-fpm-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
