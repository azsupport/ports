# security/sudo of azsupport/ports: the official port (Mk/az-official.mk) with
# PAM, without AUDIT (BSM), NLS (translations: gettext), LOGSRVD (sudo_logsrvd, the
# server of the I/O logs of other hosts) and SSL (TLS for that server only) (aZ,
# 10.11.2026); with the fix of CVE-2026-96512 (11.11.2026).

AZ_OFFICIAL=	security/sudo
OPTIONS_EXCLUDE=	AUDIT LOGSRVD NLS SSL
# the fix of CVE-2026-96512 (the time zone of the user), which the official port
# lacks: the three upstream commits, as OpenBSD carries them (see the file)
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2026-96512:-p1

.include "${.CURDIR:H:H}/Mk/az-official.mk"
