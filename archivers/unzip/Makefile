# archivers/unzip of azsupport/ports: the official port (Mk/az-official.mk) with
# ICONV: the names of a Windows archive (without the UTF-8 flag) converted by
# iconv(3) of the base system, from CP866 in a UTF-8 locale (Cyrillic names);
# unzip -O <charset> for another one.

AZ_OFFICIAL=	archivers/unzip
OPTIONS_SLAVE=	ICONV

# The fixes of the vulnerabilities of UnZip 6.0 (no release since 2009) that the
# official port lacks; it has those of CVE-2014-8139, CVE-2014-8140, CVE-2014-9636,
# CVE-2015-7696 and CVE-2015-7697 (11.11.2026; Debian, Gentoo, OpenBSD and Fedora
# carry the others): CVE-2014-8141, CVE-2016-9844, CVE-2018-1000035, CVE-2018-18384,
# CVE-2019-13232 (zip bombs of overlapped entries), CVE-2021-4217, CVE-2022-0529,
# CVE-2022-0530 and overflows without an id (zipinfo, list, extract, format strings,
# the charset names of -I and -O). The patches of Fedora
# (https://src.fedoraproject.org/rpms/unzip, as Void Linux srcpkgs/unzip carries them),
# as they are, in files/fedora, after all the patches of the port: one of them
# (COVSCAN) fixes the code of its ICONV patches.
AZ_UNZIP_FIXES=	unzip-6.0-attribs-overflow.patch \
		unzip-6.0-format-secure.patch \
		unzip-6.0-overflow.patch \
		unzip-6.0-cve-2014-8141.patch \
		unzip-6.0-overflow-long-fsize.patch \
		0001-Fix-CVE-2016-9844-rhbz-1404283.patch \
		unzip-6.0-cve-2018-1000035-heap-based-overflow.patch \
		unzip-6.0-cve-2018-18384.patch \
		unzip-6.0-COVSCAN-fix-unterminated-string.patch \
		unzip-zipbomb-part1.patch \
		unzip-zipbomb-part2.patch \
		unzip-zipbomb-part3.patch \
		unzip-zipbomb-part4.patch \
		unzip-zipbomb-part5.patch \
		unzip-zipbomb-part6.patch \
		unzip-6.0-fix-false-overlap-detection-on-32bit-systems.patch \
		CVE-2021-4217.patch \
		CVE-2022-0529.patch \
		CVE-2022-0530.patch

post-patch:
.for p in ${AZ_UNZIP_FIXES}
	@${PATCH} -d ${WRKSRC} -p1 -s -f < ${.CURDIR}/files/fedora/${p}
.endfor

.include "${.CURDIR:H:H}/Mk/az-official.mk"
