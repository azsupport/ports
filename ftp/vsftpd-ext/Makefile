# ftp/vsftpd-ext of azsupport/ports: the official port (Mk/az-official.mk) with
# RC_SCRIPT (its default: the rc.d script vsftpd), without VSFTPD_SSL; the one
# with it is ftp/vsftpd-ext-openssl, the same files (aZ, 10.11.2026); with the fix
# of CVE-2021-3618 (12.11.2026).

AZ_OFFICIAL=	ftp/vsftpd-ext
OPTIONS_SLAVE=	RC_SCRIPT
OPTIONS_EXCLUDE=	VSFTPD_SSL
CONFLICTS_INSTALL=	vsftpd-ext-openssl
# CVE-2021-3618 (ALPACA), which vsftpd-ext 3.0.3.1 lacks: the fixes of vsftpd 3.0.5
# on its files (see the file); in this build without TLS the HTTP methods and the
# 11th unknown command before the login close the connection
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2021-3618

.include "${.CURDIR:H:H}/Mk/az-official.mk"
