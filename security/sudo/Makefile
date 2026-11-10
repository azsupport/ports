# security/sudo of azsupport/ports: the official port (Mk/az-official.mk) with
# PAM, without AUDIT (BSM), NLS (translations: gettext), LOGSRVD (sudo_logsrvd, the
# server of the I/O logs of other hosts) and SSL (TLS for that server only) (aZ,
# 10.11.2026).

AZ_OFFICIAL=	security/sudo
OPTIONS_EXCLUDE=	AUDIT LOGSRVD NLS SSL

.include "${.CURDIR:H:H}/Mk/az-official.mk"
