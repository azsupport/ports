# devel/pcre of azsupport/ports: the official port (Mk/az-official.mk), PCRE 8.45
# (the last release of PCRE1) as a shared library in /usr/local/lib for the core of
# PHP 5.6 instead of the one the fork bundles, the only user of PCRE1 here (aZ,
# 10.11.2026). Its defaults: JIT, STACK_RECURSION, pcretest without line editing;
# with one fix the release lacks (files/patch-name-table).

AZ_OFFICIAL=	devel/pcre
# the name table of a compiled pattern initialised (Fedora's fix; no release of
# PCRE1 after 8.45). A fix inside the shared library, its headers and ABI as they
# are: not in the hash of the ports that need it (the core of PHP 5.6 takes it at
# run time), as a fix inside a library of az
EXTRA_PATCHES=	${.CURDIR}/files/patch-name-table
AZ_HASH_NOT_FOR_DEPENDENTS=	${.CURDIR}/files/patch-name-table

.include "${.CURDIR:H:H}/Mk/az-official.mk"
