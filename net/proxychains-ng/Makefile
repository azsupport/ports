# net/proxychains-ng of azsupport/ports: the official port as it is
# (Mk/az-official.mk), programs through a chain of SOCKS and HTTP proxies (aZ,
# 19.11.2026). 4.18 (22.11.2026): the version and the distinfo of the official port
# of freebsd-ports f9c2ab54ac, after the pinned commit (its only change there):
# DISTVERSION on the command line of make (.MAKEFLAGS), which the DISTVERSION= of the
# official Makefile does not replace, and distinfo here; with the next move of the pin
# past that commit both go. 4.18 has upstream cc005b7 (a user name or password of more
# than 255 bytes of an HTTP proxy in the configuration overflowed a buffer), the extra
# patch of 4.17 here before.

AZ_OFFICIAL=	net/proxychains-ng
.MAKEFLAGS:	DISTVERSION=4.18
DISTINFO_FILE=	${.CURDIR}/distinfo

.include "${.CURDIR:H:H}/Mk/az-official.mk"
