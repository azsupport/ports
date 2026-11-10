# security/sudo of azsupport/ports: the official port (Mk/az-official.mk)
# without NLS (translations: gettext), LOGSRVD (sudo_logsrvd, the server of the
# I/O logs of other hosts) and SSL (TLS for that server only); PAM and AUDIT
# (BSM) of the base system as by default.

AZ_OFFICIAL=	security/sudo
OPTIONS_EXCLUDE=	LOGSRVD NLS SSL

.include "${.CURDIR:H:H}/Mk/az-official.mk"
