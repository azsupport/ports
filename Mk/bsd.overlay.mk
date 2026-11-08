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

# AZ_STAMP: the revision of our packages, the time of the build (yymmddhh),
# which the builder (tools/) passes, so that every build is an upgrade; 0
# without it. lang/php74 writes PORTREVISION= ${AZ_STAMP:U0}: bsd.port.mk tests
# PORTREVISION before it reads this file.
AZ_STAMP?=	0

# AZ_HASH: the hash of the port (with its master, Mk/ and its dependencies)
# that the builder computes, kept in the package as the annotation az_hash, so
# that the builder rebuilds a port only when its hash changes. Added once,
# although bsd.port.mk includes this file twice.
.if defined(AZ_HASH) && !empty(AZ_HASH) && empty(PKG_NOTES:Maz_hash)
PKG_NOTES+=	az_hash
PKG_NOTE_az_hash=	${AZ_HASH}
.endif
