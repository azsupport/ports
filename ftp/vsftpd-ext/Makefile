# ftp/vsftpd-ext of azsupport/ports: the official port (Mk/az-official.mk) with
# RC_SCRIPT (its default: the rc.d script vsftpd), without VSFTPD_SSL; the one
# with it is ftp/vsftpd-ext-openssl, the same files (aZ, 10.11.2026); with the fixes
# of CVE-2021-3618, CVE-2026-119567, CVE-2026-119568 and of deny_file (12.11.2026).

AZ_OFFICIAL=	ftp/vsftpd-ext
OPTIONS_SLAVE=	RC_SCRIPT
OPTIONS_EXCLUDE=	VSFTPD_SSL
CONFLICTS_INSTALL=	vsftpd-ext-openssl
# CVE-2021-3618 (ALPACA), which vsftpd-ext 3.0.3.1 lacks: the fixes of vsftpd 3.0.5
# on its files (see the file); in this build without TLS the HTTP methods and the
# 11th unknown command before the login close the connection. And ours (aZ,
# 12.11.2026; each file says what and why): CVE-2026-119567, cmds_allowed and
# cmds_denied take XMKD, XRMD, XCWD, XCUP, XPWD and P@SW as MKD, RMD, CWD, CDUP,
# PWD and PASV; deny_file denies the paths through a denied directory;
# CVE-2026-119568, a data connection over TLS resumes only a session of its own
# login (TLS code, not built here: the same files as ftp/vsftpd-ext-openssl)
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2021-3618 \
		${.CURDIR}/files/patch-CVE-2026-119567 \
		${.CURDIR}/files/patch-deny_file \
		${.CURDIR}/files/patch-CVE-2026-119568

.include "${.CURDIR:H:H}/Mk/az-official.mk"
