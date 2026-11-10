# ftp/vsftpd-ext of azsupport/ports: the official port (Mk/az-official.mk) with
# RC_SCRIPT (its default: the rc.d script vsftpd), without VSFTPD_SSL; the one
# with it is ftp/vsftpd-ext-openssl, the same files (aZ, 10.11.2026).

AZ_OFFICIAL=	ftp/vsftpd-ext
OPTIONS_SLAVE=	RC_SCRIPT
OPTIONS_EXCLUDE=	VSFTPD_SSL
CONFLICTS_INSTALL=	vsftpd-ext-openssl

.include "${.CURDIR:H:H}/Mk/az-official.mk"
