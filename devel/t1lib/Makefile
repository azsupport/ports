# devel/t1lib of azsupport/ports: the official port (Mk/azsupport-official.mk), the
# libt1 of php56-gd-t1lib (aZ, 11.11.2026), without X11 (no libt1x and xglyph,
# no X libraries) and its documents, and with the fixes of the vulnerabilities of
# t1lib 5.1.2 (abandoned in 2007) that the official port lacks, as Gentoo carries
# them (media-libs/t1lib 5.1.2-r5 of gentoo/gentoo, files/): CVE-2010-2642,
# CVE-2011-0433 and CVE-2011-5244 (the AFM parser), CVE-2011-0764, CVE-2011-1552,
# CVE-2011-1553 and CVE-2011-1554 (crafted Type 1 fonts), the format strings of
# its messages, and C99 declarations; in the order of Gentoo (that of
# CVE-2011-1552 changes lines of that of CVE-2011-0764).

AZSUPPORT_OFFICIAL=	devel/t1lib
OPTIONS_EXCLUDE=	X11 DOCS
EXTRA_PATCHES=	${.CURDIR}/files/t1lib-5.1.2-format-security.patch:-p1 \
		${.CURDIR}/files/t1lib-5.1.2-CVE-2010-2642_2011-0433_2011-5244.patch:-p1 \
		${.CURDIR}/files/t1lib-5.1.2-CVE-2011-0764.patch:-p1 \
		${.CURDIR}/files/t1lib-5.1.2-CVE-2011-1552_1553_1554.patch:-p1 \
		${.CURDIR}/files/t1lib-5.1.2-c99.patch:-p1

# its libt1.so stripped: the official port installs it as it was linked (no debug in
# our packages, aZ 17.11.2026); defined before the official Makefile, so that
# bsd.port.mk runs it in the stage
post-stage:
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
