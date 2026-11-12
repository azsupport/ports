# ftp/vsftpd-ext-openssl of azsupport/ports: the official ftp/vsftpd-ext
# (Mk/az-official.mk) with VSFTPD_SSL (FTP over TLS, the OpenSSL of the base
# system) and RC_SCRIPT, as the package vsftpd-ext-openssl (the official port
# names it vsftpd-ext-ssl); the same files as vsftpd-ext (aZ, 10.11.2026), the
# same fixes (12.11.2026).

AZ_OFFICIAL=	ftp/vsftpd-ext
PKGNAMESUFFIX=	-openssl
OPTIONS_SLAVE=	RC_SCRIPT VSFTPD_SSL
CONFLICTS_INSTALL=	vsftpd-ext
# CVE-2021-3618 (ALPACA), which vsftpd-ext 3.0.3.1 lacks: the fixes of vsftpd 3.0.5
# on its files, the same file as ftp/vsftpd-ext's (see it): ALPN only "ftp",
# ssl_sni_hostname, the HTTP methods and the 11th unknown command before the login
# close the connection (12.11.2026). And ours, the same files as ftp/vsftpd-ext's
# (aZ, 12.11.2026; each file says what and why): CVE-2026-119567, cmds_allowed and
# cmds_denied take XMKD, XRMD, XCWD, XCUP, XPWD and P@SW as MKD, RMD, CWD, CDUP,
# PWD and PASV; deny_file denies the paths through a denied directory;
# CVE-2026-119568, a data connection over TLS resumes only a session of its own
# login (no stateless session tickets)
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2021-3618 \
		${.CURDIR}/files/patch-CVE-2026-119567 \
		${.CURDIR}/files/patch-deny_file \
		${.CURDIR}/files/patch-CVE-2026-119568

.include "${.CURDIR:H:H}/Mk/az-official.mk"
