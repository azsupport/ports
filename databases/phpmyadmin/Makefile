# databases/phpmyadmin of azsupport/ports: the official port (Mk/az-official.mk),
# phpMyAdmin 4.9.11 for PHP 5.6, the package phpMyAdmin-php56 (aZ, 19.11.2026: the
# stable line of phpMyAdmin for each PHP of az). The line 4.9 is the one for PHP 5.5
# to 7.4 (its last release of 08.02.2023); PHP 7.4 and 8.x take the line 5.2 of
# databases/phpmyadmin5. The modules of PHP: those the official port requires but
# mysqli (ctype, filter, iconv, session, xml), those of its default options (BZ2,
# GD, MBSTRING, ZIP, ZLIB), and json and hash, modules in PHP 5.6. No mysqli as a
# dependency: our phpXY-mysqli and phpXY-mysqli-openssl install the same mysqli.so,
# one of the two goes with it. One phpMyAdmin on a server: each package installs
# into www/phpMyAdmin (CONFLICTS_INSTALL of the official port).

AZ_OFFICIAL=	databases/phpmyadmin
PHP_VER=	56
WITHOUT_PHP_DEPENDS=	yes
USE_PHP=	bz2 ctype filter gd hash iconv json mbstring session xml zip zlib

.include "${.CURDIR:H:H}/Mk/az-official.mk"
