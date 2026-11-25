# www/npm-node24 of azsupport/ports: the official port (Mk/azsupport-official.mk), npm of
# our www/node24 (aZ, 11.11.2026). Of what it takes, gmake and Python (node-gyp) are
# official packages.

AZSUPPORT_OFFICIAL=	www/npm-node24

# The package node24-npm (aZ, 21.11.2026: the name with the version first, as php84):
# PKGNAMEPREFIX, and no PKGNAMESUFFIX (the -node24 of the official port) on the
# command line of make (.MAKEFLAGS), which the assignment of the official Makefile
# does not replace; the conflicts of the official port and those of our names.
PKGNAMEPREFIX=	node24-
.MAKEFLAGS:	PKGNAMESUFFIX= CONFLICTS_INSTALL="npm-node[0-9][0-9] node[0-9][0-9]-npm"

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
