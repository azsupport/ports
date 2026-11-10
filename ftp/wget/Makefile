# ftp/wget of azsupport/ports: the official port (Mk/az-official.mk) without
# NLS and IDN, so that it needs no library outside the base system (OpenSSL of
# the base system): no translations (gettext), no names of hosts in national
# scripts (libidn2, libunistring: a host such as xn--...rf works).

AZ_OFFICIAL=	ftp/wget
OPTIONS_EXCLUDE=	IDN NLS

.include "${.CURDIR:H:H}/Mk/az-official.mk"
