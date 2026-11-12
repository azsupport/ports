# multimedia/yamdi of azsupport/ports: the official port (Mk/az-official.mk), with
# the fix of Debian for -c (12.11.2026).

AZ_OFFICIAL=	multimedia/yamdi
# -c <creator> of 256 bytes or more: strncpy() left the field without its final
# NUL, and strlen() read past it, into the file; as Debian sid and trixie carry it
# (1010-strn-buffer-overflow.patch, see the file; upstream silent since 2010). The
# lines of yamdi.c end in CR LF, and so do those of the patch.
EXTRA_PATCHES=	${.CURDIR}/files/patch-yamdi.c:-p1

.include "${.CURDIR:H:H}/Mk/az-official.mk"
