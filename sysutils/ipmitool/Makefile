# sysutils/ipmitool of azsupport/ports: the official port (Mk/az-official.mk; aZ,
# 18.11.2026: the tools of his old server in our ports, «arcconf, ipmitool, mtr,
# trafshow, gitup эти добавь»), ipmitool 1.8.19 with its patches (buffer overruns of
# upstream #24, #368, #389 and others), the open interface of the base system
# (/dev/ipmi), the OpenSSL of the base system; without FREEIPMI (the in-band driver of
# GNU FreeIPMI: the ipmi(4) driver of the base system does it) and DOCS. With three
# fixes Debian carries and the official port lacks (see the files): CVE-2011-4339, the
# PID file of ipmievd writable by every user, and a stack buffer overflow of "ipmitool
# tsol" (as Gentoo has them), and options=no-timeout of "chassis bootparam".

AZ_OFFICIAL=	sysutils/ipmitool
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2011-4339:-p1 \
		${.CURDIR}/files/patch-tsol-buffer-overflow:-p1 \
		${.CURDIR}/files/patch-chassis-bootparam

.include "${.CURDIR:H:H}/Mk/az-official.mk"
