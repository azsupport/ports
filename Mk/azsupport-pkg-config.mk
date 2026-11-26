# Mk/azsupport-pkg-config.mk: the pkg-config of the shared libraries of azsupport for the
# configure of a port, a script in its work (aZ, 26.11.2026: no package of its own; until
# then bin/pkg-config of the package azsupport): ${AZSUPPORT_PKG_CONFIG} runs pkgconf with the
# .pc files of ${AZSUPPORT_PREFIX}/lib/pkgconfig (those of the libraries of azsupport the port
# depends on, installed) and of the base system, nothing of /usr/local. A port includes this
# file and gives it to its configure:
#
#   .include "${.CURDIR:H:H}/Mk/azsupport-pkg-config.mk"
#   CONFIGURE_ENV+=	PKG_CONFIG=${AZSUPPORT_PKG_CONFIG}
#
# (Mk/Uses/php.mk does so for the modules of PHP). The script is written before do-phpize of
# Mk/Uses/php.mk and before the pre-configure of the port (azsupport-pkg-config, 240 of the
# configure sequence). Only the ports that include it read this file: a change of it builds
# them again.

.if !defined(_AZSUPPORT_PKG_CONFIG_MK)
_AZSUPPORT_PKG_CONFIG_MK=	yes

AZSUPPORT_PKG_CONFIG=	${WRKDIR}/azsupport-pkg-config
BUILD_DEPENDS+=	pkgconf:devel/pkgconf
_USES_configure+=	240:azsupport-pkg-config

azsupport-pkg-config:
	@${PRINTF} '%s\n' '#!/bin/sh' "# pkg-config of ${AZSUPPORT_PREFIX}: its shared libraries and the base system." \
		"PKG_CONFIG_LIBDIR='${AZSUPPORT_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig'" \
		'export PKG_CONFIG_LIBDIR' 'unset PKG_CONFIG_PATH' 'exec ${LOCALBASE}/bin/pkgconf "$$@"' > ${AZSUPPORT_PKG_CONFIG}
	@${CHMOD} 755 ${AZSUPPORT_PKG_CONFIG}
.endif
