# devel/pcre2 of azsupport/ports: the official port (Mk/az-official.mk), its shared
# libraries in /usr/local/lib for every program of this tree that uses PCRE2 (the
# cores of PHP 7.4 to 8.4 instead of the PCRE2 the fork bundles, Apache, git,
# MariaDB, wget; nginx later), one copy in memory for them all (aZ, 10.11.2026).
# Its defaults: JIT, the static libraries too, pcre2test without line editing; with
# the fix of GHSA-9qww-pwc4-77qq (files/patch-GHSA-9qww-pwc4-77qq).

AZ_OFFICIAL=	devel/pcre2
# GHSA-9qww-pwc4-77qq: the backward scans of pcre2_dfa_match() and of the JIT \X
# bounded by the checked part of a UTF subject, as SUSE carries it (no fix
# upstream). A fix inside the shared library, its headers and ABI as they are: not
# in the hash of the ports that need it (PHP, Apache, git, GLib, MariaDB, wget take
# it at run time), as a fix inside a library of az
EXTRA_PATCHES=	${.CURDIR}/files/patch-GHSA-9qww-pwc4-77qq
AZ_HASH_NOT_FOR_DEPENDENTS=	${.CURDIR}/files/patch-GHSA-9qww-pwc4-77qq

.include "${.CURDIR:H:H}/Mk/az-official.mk"
