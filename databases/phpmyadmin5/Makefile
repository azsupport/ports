# databases/phpmyadmin5 of azsupport/ports: the official port (Mk/az-official.mk),
# phpMyAdmin 5.2.3 for PHP 8.4, the package phpMyAdmin5-php84 (aZ, 19.11.2026: the
# stable line of phpMyAdmin for each PHP of az), and the master of
# databases/phpmyadmin5-php74, -php81, -php82 and -php83 (phpMyAdmin5-php74 ...).
# The line 5.2 is for PHP 7.2.5 and later (5.2.3 of 08.10.2025 with the deprecations
# of PHP 8.4 and 8.5 fixed); PHP 5.6 takes databases/phpmyadmin (4.9.11); 6.0 (PHP
# 8.2 and later) is not released yet. The modules of PHP: those the official port
# requires but mysqli (ctype, filter, iconv, session, xml, xmlwriter), those of its
# default options (BZ2, GD, MBSTRING, ZIP, ZLIB), and json for PHP 7.4 (a module
# there). Neither mysqli nor openssl, which 5.2 needs, as a dependency: our
# phpXY-mysqli and phpXY-mysqli-openssl install the same mysqli.so, phpXY-openssl
# and phpXY-openssl-legacy the same openssl.so, one of each two goes with it (as for
# devel/php84-composer). One phpMyAdmin on a server: each package installs into
# www/phpMyAdmin (CONFLICTS_INSTALL of the official port).

AZ_OFFICIAL=	databases/phpmyadmin5
PHP_VER?=	84
WITHOUT_PHP_DEPENDS=	yes
USE_PHP=	bz2 ctype filter gd iconv mbstring session xml xmlwriter zip zlib
.if ${PHP_VER} == 74
USE_PHP+=	json
.endif

.include "${.CURDIR:H:H}/Mk/az-official.mk"
