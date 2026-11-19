# mail/opendkim of azsupport/ports: the official port (Mk/az-official.mk), the DKIM
# milter of Postfix (aZ, 19.11.2026), with the options of aZ: FILTER (the milter and
# its rc.d script milter-opendkim, as in the official default) on the libmilter of
# mail/libmilter (WITH_SENDMAIL_PORT: not the one of a base system that may be built
# without sendmail, as py-pymilter), the stock resolver of the base system
# (STOCK_RESOLVER in the place of UNBOUND: no libunbound, no dns/unbound), no LUA (no
# Lua policy scripts: key and signing tables in files); the other options off, as in
# the official default. Makefile.options is the file of the official port at the
# pinned commit, as it is: the official Makefile includes it from ${.CURDIR}, the
# directory of this port.

AZ_OFFICIAL=	mail/opendkim
OPTIONS_SLAVE=	STOCK_RESOLVER
OPTIONS_EXCLUDE=	UNBOUND LUA
WITH_SENDMAIL_PORT=	yes

.include "${.CURDIR:H:H}/Mk/az-official.mk"
