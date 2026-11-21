# net/mtr of azsupport/ports: the official port (Mk/az-official.mk; aZ, 18.11.2026:
# the tools of his old server in our ports), mtr 0.96 in the flavor nox11 only (no
# GTK; the package mtr), setuid root as the official one, ncurses of the base
# system, with IPV6 (aZ, 18.11.2026: «включай конечно»), without JSON (--json:
# jansson; aZ: «да, выключить»). With two fixes of upstream after 0.96 (see the
# files): CVE-2026-14461, a buffer overrun of the ASN lookup (as Debian carries it),
# and no privileged source port of the UDP probes of the setuid mtr-packet.

FLAVOR=		nox11
AZ_OFFICIAL=	net/mtr
OPTIONS_SLAVE=	IPV6
OPTIONS_EXCLUDE=	JSON
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2026-14461 \
		${.CURDIR}/files/patch-udp-source-port

# The package mtr (aZ, 21.11.2026: the name with the version first, as php84: no
# -nox11, the only flavor built here): no PKGNAMESUFFIX on the command line of make
# (.MAKEFLAGS), which the -nox11 of the flavor does not replace. The official
# CONFLICTS_INSTALL names mtr and mtr-nox11 (the official packages).
.MAKEFLAGS:	PKGNAMESUFFIX=

.include "${.CURDIR:H:H}/Mk/az-official.mk"
