CATEGORIES=	www

PKGNAMESUFFIX=	-opcache

USES=		php:zend,noflavors

MASTERDIR=	${.CURDIR}/../../lang/php82

# files/patch-ZendAccelerator.c (ours): zend_get_file_handle_timestamp() takes
# the time of a file whose zend_stream holds no php_stream (the ionCube Loader
# gives the file one of its own, phar one over its archive) by its path, as for
# a file name; it read the handle as a php_stream and called a stat function of
# whatever lay there: php81 -l and php84 -l with devel/php81-ioncube and
# devel/php84-ioncube died of SIGBUS (a general protection fault at that call
# in opcache.so; build run 44836444295, 21.11.2026), the other versions by luck
# not. Upstream (php-src master) has the same code.

.include "${MASTERDIR}/Makefile"
