# filesystems/fusefs-libs of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), libfuse 2 (aZ, 15.11.2026) for rclone mount of
# net/rclone (its build with cmount). With the fix of libfuse #571 that 2.9.9 lacks
# (aZ, 16.11.2026): files/patch-lib_fuse.c (EXTRA_PATCHES, after the patches of the
# official port).

AZSUPPORT_OFFICIAL=	filesystems/fusefs-libs
EXTRA_PATCHES=	${.CURDIR}/files/patch-lib_fuse.c

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
