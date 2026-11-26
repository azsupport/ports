# archivers/zip of azsupport/ports: the official port (Mk/azsupport-official.mk), with
# three fixes of openSUSE, RHEL and Gentoo (12.11.2026).

AZSUPPORT_OFFICIAL=	archivers/zip
# with -j the patterns of -i, -x and -R lost their paths, so -x 'dir/sub/*'
# excluded every file (openSUSE zip-3.0-nomutilation.patch); a strcpy() of
# overlapping strings for each backslash in ZIP or ZIPOPT (RHEL 10, its length
# corrected: memmove()); the offsets of the entries after a name with the UTF-8
# flag, which zip and zipnote -w left wrong (zipnote hung; Gentoo bug 322047); see
# the files
EXTRA_PATCHES=	${.CURDIR}/files/patch-zip.c-nomutilation \
		${.CURDIR}/files/patch-util.c-envargs \
		${.CURDIR}/files/patch-zipnote-utf8:-p1

# The protections of the linker (26.11.2026, readelf: zip, zipcloak, zipnote and zipsplit
# EXEC, without BIND_NOW): unix/Makefile links with $(BIND), which is $(CC) alone;
# LDFLAGS of the framework (-pie, -Wl,-zrelro, -Wl,-znow) are in the environment of its
# make (MAKE_ENV), the objects are compiled with CFLAGS (-fPIE -fPIC: the official
# patch-unix_Makefile gives them to unix/configure)
post-patch:
	@${REINPLACE_CMD} -e 's|^BIND = $$(CC)$$|BIND = $$(CC) $$(LDFLAGS)|' ${WRKSRC}/unix/Makefile
	@${GREP} -q '^BIND = $$(CC) $$(LDFLAGS)$$' ${WRKSRC}/unix/Makefile || \
		{ ${ECHO_MSG} "==> zip: no line BIND = \$$(CC) in unix/Makefile"; ${FALSE}; }

post-install:
	@${SH} ${.CURDIR:H:H}/tools/hardening-check.sh ${STAGEDIR}${PREFIX}/bin

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
