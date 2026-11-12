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
# login (no stateless session tickets).
# Then deny_file by the real path too, the part of the fix of CVE-2015-1419 that
# vsftpd-ext lacks (Debian 0050, 0070 and 0082): a symbolic link to a denied
# directory or file, made other than by FTP, led past it; and Debian's 0080 (Red
# Hat): a SIGCHLD of a process a PAM module had started and reaped (pam_exec) hung
# the privileged process of the login in wait(2); and openSUSE's: the client socket
# was the stderr of a session, so what a library printed there (NSS, PAM, libwrap)
# went to the FTP client
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2021-3618 \
		${.CURDIR}/files/patch-CVE-2026-119567 \
		${.CURDIR}/files/patch-deny_file \
		${.CURDIR}/files/patch-CVE-2026-119568 \
		${.CURDIR}/files/patch-deny_file-realpath \
		${.CURDIR}/files/patch-pam-exec-hang:-p1 \
		${.CURDIR}/files/patch-no-stderr-on-control-connection

.include "${.CURDIR:H:H}/Mk/az-official.mk"
