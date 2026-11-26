# security/py-pycryptodomex of azsupport/ports: the official port (Mk/azsupport-official.mk),
# PyCryptodome 3.24.1 as the package Cryptodome (AES-128 of HLS and other data), the
# package py312-pycryptodomex of our lang/python312, which www/yt-dlp runs with (aZ,
# 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости убираем, нужные
# собираем у нас.»). Its C code is its own, no library of other ports.
# The official security/py-pycryptodomex is a slave port that names its master by
# ${.CURDIR}/../py-pycryptodome, a directory this tree does not have: this Makefile sets
# what the slave sets (PORTNAME, CONFLICTS_INSTALL, its distinfo, NAMESPACE), over the
# master security/py-pycryptodome as AZSUPPORT_OFFICIAL.

AZSUPPORT_OFFICIAL=	security/py-pycryptodome
PORTNAME=	pycryptodomex
CONFLICTS_INSTALL=
DISTINFO_FILE=	${PORTSDIR:U/usr/ports}/security/py-pycryptodomex/distinfo
NAMESPACE=	Cryptodome

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
