# azsupport/services: the package azsupport-services (aZ, 26.11.2026 15:48: «везде делаем
# azsupport-services»), the trigger of pkg that names, at the end of a transaction, the
# commands that restart the services of the packages of azsupport it touched and that
# rc.conf enables:
# share/pkg/triggers/azsupport-services.ucl (files/; Mk/bsd.overlay.mk gives the packages
# their directories share/azsupport/services/<service>), before in the package azsupport.
# Every port of a library of the shared tree needs it to run
# (azsupport/azsupport/Makefile.lib); a file of run time only, not in the hash of a port
# that would need it to build (AZSUPPORT_HASH_NOT_FOR_DEPENDENTS).

PORTNAME=	services
PORTVERSION=	20261127
CATEGORIES=	azsupport sysutils
PKGNAMEPREFIX=	azsupport-
DISTFILES=

COMMENT=	Trigger of pkg naming the services of our packages to restart
WWW=		https://github.com/azsupport/ports

LICENSE=	BSD2CLAUSE

NO_BUILD=	yes
NO_ARCH=	yes
NO_WRKSUBDIR=	yes

AZSUPPORT_HASH_NOT_FOR_DEPENDENTS=	${FILESDIR}/azsupport-services.ucl
PLIST_FILES=	share/pkg/triggers/azsupport-services.ucl

.include "${.CURDIR:H}/azsupport/Makefile.common"

do-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/pkg/triggers
	${INSTALL_DATA} ${FILESDIR}/azsupport-services.ucl ${STAGEDIR}${PREFIX}/share/pkg/triggers

.include <bsd.port.mk>
