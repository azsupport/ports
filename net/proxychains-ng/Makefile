# net/proxychains-ng of azsupport/ports: the official port as it is
# (Mk/az-official.mk), programs through a chain of SOCKS and HTTP proxies (aZ,
# 19.11.2026). files/extra-patch-src_libproxychains.c-overflow: upstream cc005b7 (after
# 4.17, as Debian carries it): a user name or password of more than 255 bytes of an
# HTTP proxy in the configuration overflowed a buffer.

AZ_OFFICIAL=	net/proxychains-ng
EXTRA_PATCHES=	${.CURDIR}/files/extra-patch-src_libproxychains.c-overflow:-p1

.include "${.CURDIR:H:H}/Mk/az-official.mk"
