# Settings of the overlay azsupport/ports for every port built with
# OVERLAYS=<this tree>: bsd.port.mk includes this file twice (once before and
# once after the port's own settings are processed), so it only adds to lists
# and assigns with ?=.
#
# AZ_PREFIX: the shared tree of the package az (origin az/az): lib/ (the
# shared libraries, SONAME and run path ${AZ_PREFIX}/lib, no ldconfig hints),
# lib/pkgconfig/, include/, bin/pkg-config and bin/*-config. AZ_STATIC: its
# static tree (lib/, include/, bin/pkg-config --static). Our ports use these
# two, never the literal path, and do not define them (aZ, 08.11.2026: the
# prefix is /usr/local/az). Lazy assignments, so that a port may use them in its
# Makefile before this file is read (no := and no .if on them in a port).

# az: the category of our own ports that have no place in the official tree
VALID_CATEGORIES+=	az

AZ_PREFIX?=	${LOCALBASE}/az
AZ_STATIC?=	${AZ_PREFIX}/static
