# emulators/virtualbox-ose-additions-72 of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), the Guest Additions of VirtualBox 7.2 for a FreeBSD guest (aZ,
# 20.11.2026), in the flavor nox11 only (the package virtualbox-ose-additions-nox11-72):
# the kernel modules vboxguest and vboxvfs (the shared folders, mount_vboxvfs),
# VBoxService (the time of the guest, the guest properties, the memory balloon),
# VBoxControl, pam_vbox and the rc.d scripts vboxguest and vboxservice; no X11, DBUS
# and DEBUG (the options the flavor nox11 leaves out). Its kernel modules are built
# against the sources of the kernel of the release of the build, as net/amnezia-kmod
# (tools/build.sh: gitup of releng/15.1 into /usr/src). The patches are those of the
# official emulators/virtualbox-ose-72: its Makefile takes them from
# ${.CURDIR}/../virtualbox-ose-72/files, which here is the directory of our port of
# that origin (it has none), so PATCHDIR is given on the command line of make
# (.MAKEFLAGS), which the assignment of the official Makefile does not replace.

# The package virtualbox72-additions (aZ, 21.11.2026: the name with the version, as
# php84): PKGBASE and PKGNAME as in emulators/virtualbox-ose-72; it conflicts with
# the official virtualbox-ose-additions* (the same files).
PKGBASE=	virtualbox72-additions
.MAKEFLAGS:	PKGNAME=virtualbox72-additions-$${PKGVERSION} CONFLICTS_INSTALL=virtualbox-ose-additions*

FLAVOR=		nox11
AZSUPPORT_OFFICIAL=	emulators/virtualbox-ose-additions-72
.MAKEFLAGS:	PATCHDIR=${PORTSDIR:U/usr/ports}/emulators/virtualbox-ose-72/files

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
