# emulators/virtualbox-ose-kmod-72 of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), the kernel modules of VirtualBox 7.2 (vboxdrv, vboxnetflt,
# vboxnetadp) and the rc.d script vboxnet for emulators/virtualbox-ose-72 (aZ,
# 20.11.2026), with VIMAGE (vboxnetflt for a kernel with VIMAGE: GENERIC and the
# kernel az.st of aZ have it), without DEBUG and INVARIANTS (neither kernel has
# INVARIANTS). Built against the sources of the kernel of the release of the build, as
# net/amnezia-kmod (tools/build.sh: gitup of releng/15.1 into /usr/src): one build for
# GENERIC and az.st; a new release of FreeBSD, a new build. The patches are those of
# the official emulators/virtualbox-ose-72: its Makefile takes them from
# ${.CURDIR}/../virtualbox-ose-72/files, which here is the directory of our port of
# that origin (it has none), so PATCHDIR is given on the command line of make
# (.MAKEFLAGS), which the assignment of the official Makefile does not replace.

# The package virtualbox72-kmod (aZ, 21.11.2026: the name with the version, as
# php84): PKGBASE and PKGNAME as in emulators/virtualbox-ose-72; it conflicts with
# the official virtualbox-ose-kmod* (the same kernel modules).
PKGBASE=	virtualbox72-kmod
.MAKEFLAGS:	PKGNAME=virtualbox72-kmod-$${PKGVERSION} CONFLICTS_INSTALL=virtualbox-ose-kmod*

AZSUPPORT_OFFICIAL=	emulators/virtualbox-ose-kmod-72
OPTIONS_SLAVE=	VIMAGE
OPTIONS_EXCLUDE=	DEBUG INVARIANTS
.MAKEFLAGS:	PATCHDIR=${PORTSDIR:U/usr/ports}/emulators/virtualbox-ose-72/files

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
