# www/aria2-ssh2: www/aria2 with SSH2 (SFTP, the libssh2 of az), the package
# aria2-ssh2 (aZ, 19.11.2026: «ssh2 вынести в aria2-ssh2 отдельный порт»); the
# same files and options otherwise. One of the two on a server.

PKGNAMESUFFIX=	-ssh2
OPTIONS_SLAVE=	SSH2
CONFLICTS_INSTALL=	aria2
MASTERDIR=	${.CURDIR}/../aria2

.include "${MASTERDIR}/Makefile"
