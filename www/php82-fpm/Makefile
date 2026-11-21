# www/php82-fpm of azsupport/ports: the FPM of PHP 8.2 of azsupport/php-src, a port of its
# own (aZ, 21.11.2026: «давай еще разделим php-cgi и php-fpm на отдельные порты и
# соответственно phpXX-cgi phpXX-fpm и подредактируй название rc.d под новые названия
# в php-fpm»; «тут тоже php84-»): lang/php82 with the SAPI fpm alone (AZ_PHP_SAPI), as www/mod_php82 has
# the Apache module. sbin/php82-fpm; etc/php82/php-fpm.conf by @sample (pid
# /var/run/php82-fpm.pid, log /var/log/php82-fpm.log), its pools in etc/php82/php-fpm.d (the pool www on /var/run/php82-fpm.sock);
# share/php82/fpm/status.html; the rc.d script php82_fpm (php82_fpm_enable, the
# profiles of php82-profile: php82_fpm_profiles). php.ini and the modules are those of
# php82, which it needs.

CATEGORIES=	www devel

MAINTAINER=	github@azsupport.com

PHP_PORT=	lang/php82
MASTERDIR=	${.CURDIR}/../../${PHP_PORT}
PKGDIR=		${.CURDIR}
FILESDIR=	${.CURDIR}/files
AZ_PHP_SAPI=	fpm

OPTIONS_EXCLUDE=	CGI CLI EMBED PHPDBG
OPTIONS_SLAVE=	FPM

# the package php82-fpm: PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS),
# which the PKGNAME= of bsd.port.mk does not replace
PKGBASE=	php82-fpm
.MAKEFLAGS:	PKGNAME=php82-fpm-$${PKGVERSION}

.include "${MASTERDIR}/Makefile"
