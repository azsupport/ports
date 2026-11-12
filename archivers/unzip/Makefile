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
# (COVSCAN) fixes the code of its ICONV patches. In the order of Fedora, with three
# more of its fixes (12.11.2026): close (an error of closing an extracted file was
# ignored: the status 0 for a file left short when close(2) reports a write that
# failed late, as on NFS; a full local disk fails write(2) and was caught already),
# valgrind (an extra field cut short by the end of the archive: the rest of its
# buffer was parsed uninitialised) and zipbomb-part7 (madler/unzip af0d07f: the data
# descriptor of a Zip64 entry with 32-bit lengths, as the zip library of Java writes
# it, refused as a "possible zip bomb", status 12).
AZ_UNZIP_FIXES=	unzip-6.0-close.patch \
		unzip-6.0-attribs-overflow.patch \
		unzip-6.0-format-secure.patch \
		unzip-6.0-valgrind.patch \
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
		unzip-zipbomb-part7.patch \
		unzip-6.0-fix-false-overlap-detection-on-32bit-systems.patch \
		CVE-2021-4217.patch \
		CVE-2022-0529.patch \
		CVE-2022-0530.patch

# Then the fixes of Debian (unzip 6.0-31, 12.11.2026) that neither the official
# port nor Fedora has, in files/debian (each says what, its bug and origin), and
# that of OpenBSD for zipgrep: the heap buffer overflow in memextract() (stored
# extra fields; CAN-2026-2034442) and the stack one in the SmartZip field of
# zipinfo (CAN-2026-2034443), the rest of the fix of CVE-2015-7696 (an encrypted
# stored entry shorter than its 12-byte header), zipgrep and member names with a
# newline (CVE-2022-1271, OpenBSD), and bugs: the symlink flag left uninitialised,
# the PKWare verification bit taken for file attributes, the ZIP64 archives of
# Windows (no disks in the locator: "attempt to seek before beginning"), the times
# of an old Unix extra field dropped by a newer one, the 6th byte of 64-bit sizes,
# the version >= 10 of the program that made an entry (zipinfo), and the patterns
# of zipgrep with "|" or "\" that found nothing (Debian #1054628, 12.11.2026). Not
# taken: CAN-2026-2034440 (EF_IZUNIX3 uid/gid, code this build leaves out) and the
# code page changes of Ubuntu (this port has its own ICONV patches).
AZ_UNZIP_FIXES_DEBIAN=	can-2026-2034442.patch \
			can-2026-2034443.patch \
			fix-integer-underflow-csiz-decrypted.patch \
			zipgrep-cve-2022-1271.patch \
			fix-zipgrep.patch \
			initialize-the-symlink-flag.patch \
			handle-pkware-verification-bit.patch \
			handle-windows-zip64-files.patch \
			restore-unix-timestamps-accurately.patch \
			fix-warning-messages-on-big-files.patch \
			allow-greater-hostver-values.patch

# Then those of OpenBSD (commit 89a66a1), as they are, in files/openbsd: memmove(),
# not memcpy(), for the copies within the sliding window of explode.c and
# inflate.c, whose regions can overlap on a normal archive too (undefined
# behaviour, which the __memcpy_chk of _FORTIFY_SOURCE aborts on). And ours,
# files/cve-2014-8139-pkvms.patch (12.11.2026): the fix of CVE-2014-8139 as
# Info-ZIP corrected it on 30.01.2015 (Fedora and Alpine carry that one), on the
# early one of the official port's files/patch-extract.c, which refused every
# extra block shorter than 4 bytes: unzip -t failed on every jar of jar(1) and
# Java (status 2).
AZ_UNZIP_FIXES_OPENBSD=	patch-explode_c \
			patch-inflate_c

post-patch:
.for p in ${AZ_UNZIP_FIXES}
	@${PATCH} -d ${WRKSRC} -p1 -s -f < ${.CURDIR}/files/fedora/${p}
.endfor
.for p in ${AZ_UNZIP_FIXES_DEBIAN}
	@${PATCH} -d ${WRKSRC} -p1 -s -f < ${.CURDIR}/files/debian/${p}
.endfor
.for p in ${AZ_UNZIP_FIXES_OPENBSD}
	@${PATCH} -d ${WRKSRC} -p0 -s -f < ${.CURDIR}/files/openbsd/${p}
.endfor
	@${PATCH} -d ${WRKSRC} -p1 -s -f < ${.CURDIR}/files/cve-2014-8139-pkvms.patch

.include "${.CURDIR:H:H}/Mk/az-official.mk"
