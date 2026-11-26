# filesystems/sshfs of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), sshfs (aZ, 15.11.2026), the package fusefs-sshfs: on
# libfuse 3 of our filesystems/fusefs-libs3 and the GLib of our devel/glib20; without
# its manual page (DOCS: the make.conf of the build). With two fixes of master after
# 3.7.7 (aZ, 16.11.2026: «так сделай»): files/patch-sshfs.c (EXTRA_PATCHES, after the
# patches of the official port).
# No devel/gettext-runtime (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние
# зависимости убираем, нужные собираем у нас.»): USE_GNOME=glib20 of the official port
# adds libintl.so:devel/gettext-runtime to LIB_DEPENDS with GLib (glib20_LIB_DEPENDS of
# Mk/Uses/gnome.mk, which bsd.port.mk reads with the USES of the port), and sshfs links
# no libintl (fusefs-sshfs 3.7.7_26112604: libfuse3, libglib-2.0, libthr and libc). The
# -lintl of glib-2.0.pc (our GLib is on the libintl of azsupport) is found there by -L
# of azsupport and dropped by the --as-needed of meson, as it dropped the libintl of
# the official package before. The targets of bsd.port.mk read LIB_DEPENDS when they
# run, so it goes out after the include.

AZSUPPORT_OFFICIAL=	filesystems/sshfs
EXTRA_PATCHES=	${.CURDIR}/files/patch-sshfs.c
LDFLAGS+=	-L${AZSUPPORT_PREFIX}/lib

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

LIB_DEPENDS:=	${LIB_DEPENDS:Nlibintl.so\:devel/gettext-runtime}
