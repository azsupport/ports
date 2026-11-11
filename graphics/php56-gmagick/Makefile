# PECL gmagick of ext/gmagick of the release tarball of azsupport/php-src:
# its version there (php-src freebsd/pecl.conf)
DISTVERSION=	1.1.7RC3
CATEGORIES=	graphics

MASTERDIR=	${.CURDIR}/../../lang/php56

PKGNAMESUFFIX=	-gmagick

# GraphicsMagick-config of az, which config.m4 runs, runs pkgconf: the build of
# PHP 5.6 has no USES=pkgconfig of its own (7.4 and later have one), and its
# chroot had no pkgconf (11.11.2026, run 43043682500: "exec: /usr/local/bin/pkgconf:
# not found", then "You need at least GraphicsMagick version 1.1.0"); here, not in
# lang/php56/Makefile.ext, which every port of PHP 5.6 reads (and hashes)
USES=		pkgconfig

.include "${MASTERDIR}/Makefile"
