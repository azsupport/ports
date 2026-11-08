# The PHP modules of the overlay for Mk/Uses/php.mk, which includes this file
# after its own table of <module>_DEPENDS and before it reads USE_PHP: USE_PHP=
# <module> of a port is a dependency by the file
# lib/php/${PHP_EXT_DIR}/<module>.so on the port of the module.
#
# Only what that table (the official one of freebsd-ports 036685c034ba) has not
# or has otherwise: the bundled modules have the origins of the official ports
# there (math/php74-bcmath, www/php74-session, ...), and the ports of the
# overlay take their places. Here: the PECL extensions with the origins of our
# packages (<category>/php-<module>, no "pecl": aZ, 08.11.2026; slave ports of
# lang/php74), and the modules the table lacks (mysqlnd, imagick, excimer,
# swoole, openswoole). openssl-legacy installs openssl.so too, so USE_PHP=
# openssl takes it as well.
#
# The priorities of the ini (ext-<NN>-<module>.ini): the rule of php.mk (20, 30
# with USE_PHP) with PHP_MOD_PRIO of lang/php74/Makefile.ext (opcache 10,
# session 18) gives every module that of php-src freebsd/ext.conf, except
# xmlrpc: 30, as the official port (USE_PHP=xml:build: it needs the parser of
# xml), where ext.conf has 20 and no need.

_USE_PHP_VER74+=	excimer imagick mysqlnd openswoole swoole

excimer_DEPENDS=	devel/php-excimer
igbinary_DEPENDS=	converters/php-igbinary
imagick_DEPENDS=	graphics/php-imagick
mcrypt_DEPENDS=		security/php-mcrypt
memcache_DEPENDS=	databases/php-memcache
memcached_DEPENDS=	databases/php-memcached
mysqlnd_DEPENDS=	databases/php${PHP_VER}-mysqlnd
openswoole_DEPENDS=	devel/php-openswoole
redis_DEPENDS=		databases/php-redis
swoole_DEPENDS=		devel/php-swoole
