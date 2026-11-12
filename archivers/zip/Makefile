# archivers/zip of azsupport/ports: the official port (Mk/az-official.mk), with two
# fixes of openSUSE and RHEL (12.11.2026).

AZ_OFFICIAL=	archivers/zip
# with -j the patterns of -i, -x and -R lost their paths, so -x 'dir/sub/*'
# excluded every file (openSUSE zip-3.0-nomutilation.patch); a strcpy() of
# overlapping strings for each backslash in ZIP or ZIPOPT (RHEL 10, its length
# corrected: memmove()); see the files
EXTRA_PATCHES=	${.CURDIR}/files/patch-zip.c-nomutilation \
		${.CURDIR}/files/patch-util.c-envargs

.include "${.CURDIR:H:H}/Mk/az-official.mk"
