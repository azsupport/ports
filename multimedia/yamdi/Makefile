# multimedia/yamdi of azsupport/ports: the official port (Mk/azsupport-official.mk), with
# the fix of Debian for -c (12.11.2026).

AZSUPPORT_OFFICIAL=	multimedia/yamdi
# -c <creator> of 256 bytes or more: strncpy() left the field without its final
# NUL, and strlen() read past it, into the file; as Debian sid and trixie carry it
# (1010-strn-buffer-overflow.patch, see the file; upstream silent since 2010). The
# lines of yamdi.c end in CR LF, and so do those of the patch.
EXTRA_PATCHES=	${.CURDIR}/files/patch-yamdi.c:-p1
# The protections of the linker (26.11.2026, readelf: yamdi EXEC, without BIND_NOW): the
# do-build of the official port compiles and links in one command, ${CC} ${CFLAGS}
# yamdi.c -o yamdi, without LDFLAGS; those of the framework (-pie, -Wl,-zrelro,
# -Wl,-znow) through CFLAGS
CFLAGS+=	${LDFLAGS}

post-install:
	@${SH} ${.CURDIR:H:H}/tools/hardening-check.sh ${STAGEDIR}${PREFIX}/bin

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
