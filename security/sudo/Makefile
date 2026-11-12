# security/sudo of azsupport/ports: the official port (Mk/az-official.mk) with
# PAM, without AUDIT (BSM), NLS (translations: gettext), LOGSRVD (sudo_logsrvd, the
# server of the I/O logs of other hosts) and SSL (TLS for that server only) (aZ,
# 10.11.2026); with the fixes of CVE-2026-96512 (11.11.2026), CVE-2026-35535 and of
# @includedir (12.11.2026).

AZ_OFFICIAL=	security/sudo
OPTIONS_EXCLUDE=	AUDIT LOGSRVD NLS SSL
# the fix of CVE-2026-96512 (the time zone of the user), which the official port
# lacks: the three upstream commits, as OpenBSD carries them (see the file); that
# of CVE-2026-35535 (the mailer, which sudo starts by default, e.g. for a user not
# in sudoers, ran as root with the groups of the user) and that of a file of an
# @includedir with ":" in its name (read as a list of paths): the upstream commits
# 3e474c2 and ff0b6be, which no release has yet, as Debian sid carries them on
# 1.9.17p2 (see the files)
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2026-96512:-p1 \
		${.CURDIR}/files/patch-CVE-2026-35535:-p1 \
		${.CURDIR}/files/patch-open_sudoers-includedir:-p1

.include "${.CURDIR:H:H}/Mk/az-official.mk"
