# sysutils/grub2-bhyve of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), the grub loader of bhyve for the guests booted by grub (Linux
# and others), for sysutils/vm-bhyve (aZ, 19.11.2026). Built with the GCC of the
# official packages (a build tool only).

AZSUPPORT_OFFICIAL=	sysutils/grub2-bhyve
# no _FORTIFY_SOURCE (WITH_FORTIFY of tools/make.conf.in): grub declares memset, memcpy and
# the others of its own (grub/misc.h, EXPORT_FUNC), which the macros of the fortified
# string.h of libc turn into errors ("expected identifier or '(' before '__extension__'",
# run 45702768445)
FORTIFY_UNSAFE=	grub declares memset and the others of its own

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
