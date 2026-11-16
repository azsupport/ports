# filesystems/sshfs of azsupport/ports: the official port as it is
# (Mk/az-official.mk), sshfs (aZ, 15.11.2026), the package fusefs-sshfs: on
# libfuse 3 of our filesystems/fusefs-libs3 and the GLib of our devel/glib20; without
# its manual page (DOCS: the make.conf of the build). With two fixes of master after
# 3.7.7 (aZ, 16.11.2026: «так сделай»): files/patch-sshfs.c (EXTRA_PATCHES, after the
# patches of the official port).

AZ_OFFICIAL=	filesystems/sshfs
EXTRA_PATCHES=	${.CURDIR}/files/patch-sshfs.c

.include "${.CURDIR:H:H}/Mk/az-official.mk"
