# The PHP modules of the overlay, for Mk/Uses/php.mk (which includes this file
# in its post part): every module of ours with the origin of its port, and the
# priority of its ini file where the rule of php.mk is not that of php-src
# freebsd/ext.conf.
#
# <module>_DEPENDS=<origin>: USE_PHP=<module> of a port is a dependency by the
# file lib/php/${PHP_EXT_DIR}/<module>.so on that port (with :build at build
# time too); a module without a line here is unknown to USE_PHP, but those built
# into the core (PHP_EXT_INC). The bundled modules have the origins of the
# official ports (the ports of the overlay take their places), the PECL
# extensions those of our packages, <category>/php-<module> (no "pecl": aZ,
# 08.11.2026; slave ports of lang/php74 as the others). openssl-legacy installs
# openssl.so too, so USE_PHP=openssl takes it as well.
#
# <module>_PRIO=<NN>: the priority of its ini file, ext-<NN>-<module>.ini (PHP
# loads conf.d in the order of the names), where the rule of php.mk (20 for a
# module that needs no other one, 30 with USE_PHP) is not that of ext.conf: the
# PHP_MOD_PRIO of the official lang/php74/Makefile.ext.

bcmath_DEPENDS=		math/php${PHP_VER}-bcmath
bz2_DEPENDS=		archivers/php${PHP_VER}-bz2
calendar_DEPENDS=	misc/php${PHP_VER}-calendar
ctype_DEPENDS=		textproc/php${PHP_VER}-ctype
curl_DEPENDS=		ftp/php${PHP_VER}-curl
dba_DEPENDS=		databases/php${PHP_VER}-dba
dom_DEPENDS=		textproc/php${PHP_VER}-dom
excimer_DEPENDS=	devel/php-excimer
exif_DEPENDS=		graphics/php${PHP_VER}-exif
ffi_DEPENDS=		devel/php${PHP_VER}-ffi
fileinfo_DEPENDS=	sysutils/php${PHP_VER}-fileinfo
filter_DEPENDS=		security/php${PHP_VER}-filter
ftp_DEPENDS=		ftp/php${PHP_VER}-ftp
gd_DEPENDS=		graphics/php${PHP_VER}-gd
gettext_DEPENDS=	devel/php${PHP_VER}-gettext
gmp_DEPENDS=		math/php${PHP_VER}-gmp
iconv_DEPENDS=		converters/php${PHP_VER}-iconv
igbinary_DEPENDS=	converters/php-igbinary
imagick_DEPENDS=	graphics/php-imagick
intl_DEPENDS=		devel/php${PHP_VER}-intl
json_DEPENDS=		devel/php${PHP_VER}-json
mbstring_DEPENDS=	converters/php${PHP_VER}-mbstring
mcrypt_DEPENDS=		security/php-mcrypt
memcache_DEPENDS=	databases/php-memcache
memcached_DEPENDS=	databases/php-memcached
mysqli_DEPENDS=		databases/php${PHP_VER}-mysqli
mysqlnd_DEPENDS=	databases/php${PHP_VER}-mysqlnd
opcache_DEPENDS=	www/php${PHP_VER}-opcache
openssl_DEPENDS=	security/php${PHP_VER}-openssl
openswoole_DEPENDS=	devel/php-openswoole
pcntl_DEPENDS=		devel/php${PHP_VER}-pcntl
pdo_DEPENDS=		databases/php${PHP_VER}-pdo
pdo_mysql_DEPENDS=	databases/php${PHP_VER}-pdo_mysql
pdo_sqlite_DEPENDS=	databases/php${PHP_VER}-pdo_sqlite
phar_DEPENDS=		archivers/php${PHP_VER}-phar
posix_DEPENDS=		sysutils/php${PHP_VER}-posix
readline_DEPENDS=	devel/php${PHP_VER}-readline
redis_DEPENDS=		databases/php-redis
session_DEPENDS=	www/php${PHP_VER}-session
shmop_DEPENDS=		devel/php${PHP_VER}-shmop
simplexml_DEPENDS=	textproc/php${PHP_VER}-simplexml
soap_DEPENDS=		net/php${PHP_VER}-soap
sockets_DEPENDS=	net/php${PHP_VER}-sockets
sodium_DEPENDS=		security/php${PHP_VER}-sodium
sqlite3_DEPENDS=	databases/php${PHP_VER}-sqlite3
swoole_DEPENDS=		devel/php-swoole
sysvmsg_DEPENDS=	devel/php${PHP_VER}-sysvmsg
sysvsem_DEPENDS=	devel/php${PHP_VER}-sysvsem
sysvshm_DEPENDS=	devel/php${PHP_VER}-sysvshm
tidy_DEPENDS=		www/php${PHP_VER}-tidy
tokenizer_DEPENDS=	devel/php${PHP_VER}-tokenizer
xml_DEPENDS=		textproc/php${PHP_VER}-xml
xmlreader_DEPENDS=	textproc/php${PHP_VER}-xmlreader
xmlrpc_DEPENDS=		net/php${PHP_VER}-xmlrpc
xmlwriter_DEPENDS=	textproc/php${PHP_VER}-xmlwriter
xsl_DEPENDS=		textproc/php${PHP_VER}-xsl
zip_DEPENDS=		archivers/php${PHP_VER}-zip
zlib_DEPENDS=		archivers/php${PHP_VER}-zlib

# This is needed by Zend extensions, keep before everything.
opcache_PRIO=	10
session_PRIO=	18
