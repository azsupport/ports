# PECL gearman of ext/gearman of the release tarball of azsupport/php-src:
# its version there (php-src freebsd/pecl.conf)
DISTVERSION=	1.1.2
CATEGORIES=	devel

MASTERDIR=	${.CURDIR}/../../lang/php56

PKGNAMESUFFIX=	-gearman

# no run path /usr/local/lib, which its config.m4 adds for libgearman
# (PHP_ADD_LIBRARY_WITH_PATH): libgearman.so of devel/libgearman is found there by
# ldconfig, and the run path of a module is that of az only (tools/check-php.sh;
# build.yml 44041486788: "the run path is /usr/local/lib:/usr/local/az/lib")
CONFIGURE_ENV+=	PHP_RPATH=no

.include "${MASTERDIR}/Makefile"
