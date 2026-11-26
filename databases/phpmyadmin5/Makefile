# databases/phpmyadmin5 of azsupport/ports: the official port (Mk/azsupport-official.mk),
# phpMyAdmin 5.2.3 for PHP 8.4, the package php84-phpmyadmin (aZ, 19.11.2026: the
# stable line of phpMyAdmin for each PHP of azsupport), and the master of
# databases/phpmyadmin5-php74, -php81, -php82 and -php83 (php74-phpmyadmin ...). The
# line 5.2 is for PHP 7.2.5 and later (5.2.3 of 08.10.2025 with the deprecations of
# PHP 8.4 and 8.5 fixed; with the fixes of vulnerabilities no release has yet, below);
# PHP 5.6 takes databases/phpmyadmin (4.9.11); 6.0 (PHP 8.2 and later) is not released
# yet. The modules of PHP: those the official port requires
# but mysqli (ctype, filter, iconv, session, xml, xmlwriter), those of its default
# options (BZ2, GD, MBSTRING, ZIP, ZLIB), and json for PHP 7.4 (a module there).
# Neither mysqli nor openssl, which 5.2 needs, as a dependency: our phpXY-mysqli and
# phpXY-mysqli-openssl install the same mysqli.so, phpXY-openssl and
# phpXY-openssl-legacy the same openssl.so, one of each two goes with it (as for
# devel/php84-composer). One phpMyAdmin on a server: each package installs into
# www/phpMyAdmin (CONFLICTS_INSTALL of the official port).

AZSUPPORT_OFFICIAL=	databases/phpmyadmin5
PHP_VER?=	84
WITHOUT_PHP_DEPENDS=	yes
USE_PHP=	bz2 ctype filter gd iconv mbstring session xml xmlwriter zip zlib
.if ${PHP_VER} == 74
USE_PHP+=	json
.endif

# The fixes of the vulnerabilities of vuxml e6b90d23-d49d-11f1-bae2-3497f65b111b
# (30.10.2026), which no release of phpMyAdmin has (aZ, 26.11.2026), on the files of
# the tarball; each file says what it fixes and where it comes from. Of the branch
# master (6.0): CVE-2026-119426 (a POST of another site past the token),
# CVE-2026-119427 (SQL injection, the settings of Designer), CVE-2026-119428 (SSRF
# through setup/validate.php), CVE-2026-119429 (the second factor removed through
# /config/set; /config/get gave any setting). Of QA_5_2 (5.2.4, not released): the
# second factor kept when other preferences are saved, CVE-2026-119563 (stored XSS,
# the name of a table in the query history of Designer; js/src and js/dist).
# CVE-2026-119561 (WebAuthn of CustomServer) is not in this package: it has
# web-auth/webauthn-lib, which phpMyAdmin then takes in place of CustomServer. The
# files of this directory, also for the slaves (${.CURDIR:H}/phpmyadmin5).
EXTRA_PATCHES=	${.CURDIR:H}/phpmyadmin5/files/patch-CVE-2026-119426 \
		${.CURDIR:H}/phpmyadmin5/files/patch-CVE-2026-119427 \
		${.CURDIR:H}/phpmyadmin5/files/patch-CVE-2026-119428 \
		${.CURDIR:H}/phpmyadmin5/files/patch-CVE-2026-119429 \
		${.CURDIR:H}/phpmyadmin5/files/patch-2fa-kept-on-save \
		${.CURDIR:H}/phpmyadmin5/files/patch-CVE-2026-119563

# patch(1) keeps each file it changes as <file>.orig: those go before the post-patch
# of the official port lists every file of WRKSRC into the plist, which would install
# them into www/phpMyAdmin beside the patched files (the tarball has no .orig files)
post-patch: azsupport-patch-backups
azsupport-patch-backups:
	@${FIND} ${WRKSRC} -type f -name '*.orig' -delete

# The packages phpXY-phpmyadmin (aZ, 21.11.2026: the name with the version first, as
# php84): PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS), which the
# PKGNAME= of bsd.port.mk does not replace; the conflicts of the official port and
# those of our names (one phpMyAdmin).
PKGBASE=	${PHP_PKGNAMEPREFIX}phpmyadmin
.MAKEFLAGS:	PKGNAME=$${PHP_PKGNAMEPREFIX}phpmyadmin-$${PKGVERSION} \
		CONFLICTS_INSTALL="phpMyAdmin-php[0-9][0-9] phpMyAdmin[0-9]-php[0-9][0-9] php[0-9][0-9]-phpmyadmin"

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
