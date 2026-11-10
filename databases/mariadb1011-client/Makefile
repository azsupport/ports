# databases/mariadb1011-client: the client of the MariaDB 10.11 of azsupport/ports
# (databases/mariadb1011-server: the options, the libraries of our ports, the
# socket /tmp/mysql.sock), in the place of the official one (aZ, 10.11.2026).

PORTNAME=	mariadb
PKGNAMESUFFIX=	1011-client

COMMENT=	Multithreaded SQL database (client, of azsupport/ports)

MASTERDIR=	${.CURDIR}/../${PORTNAME}${PKGNAMESUFFIX:C/-client/-server/}

PLIST=		${.CURDIR}/pkg-plist

.include "${MASTERDIR}/Makefile"
