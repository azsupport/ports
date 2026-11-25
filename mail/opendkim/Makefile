# mail/opendkim of azsupport/ports: the official port (Mk/azsupport-official.mk), the DKIM
# milter of Postfix (aZ, 19.11.2026), with the options of aZ: FILTER (the milter and
# its rc.d script milter-opendkim, as in the official default) on the libmilter of
# mail/libmilter (WITH_SENDMAIL_PORT: not the one of a base system that may be built
# without sendmail, as py-pymilter), the stock resolver of the base system
# (STOCK_RESOLVER in the place of UNBOUND: no libunbound, no dns/unbound), no LUA (no
# Lua policy scripts: key and signing tables in files); the other options off, as in
# the official default. Makefile.options is the file of the official port at the
# pinned commit, as it is: the official Makefile includes it from ${.CURDIR}, the
# directory of this port.

# files/extra-patch-libopendkim_dkim.c-d-tag: the check of "d=" of upstream after 2.10.3
# (14d54524e0a9), as Debian carries it (the patches of the distributions reviewed on
# 20.11.2026; their other fixes are for 2.11 or for options that are off here).
AZSUPPORT_OFFICIAL=	mail/opendkim
EXTRA_PATCHES=	${.CURDIR}/files/extra-patch-libopendkim_dkim.c-d-tag
OPTIONS_SLAVE=	STOCK_RESOLVER
OPTIONS_EXCLUDE=	UNBOUND LUA
WITH_SENDMAIL_PORT=	yes

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
