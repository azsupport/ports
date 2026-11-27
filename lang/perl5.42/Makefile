# lang/perl5.42 of azsupport/ports: the official port (Mk/azsupport-official.mk), Perl 5.42
# under the name of FreeBSD's (aZ, 11.11.2026: our Perl and Python under the package
# names of FreeBSD, so that the p5-* packages of the FreeBSD repository work with
# them). 5.42 is PERL5_DEFAULT of the pinned tree, so the package is perl5 with
# /usr/local/bin/perl, as FreeBSD's.
#
# The official options: threads (always: -Dusethreads), MULTIPLICITY, PERL_64BITINT,
# the shared libperl; GDBM, SITECUSTOMIZE, PERL_MALLOC, DOT_INC and DEBUG off, as
# officially. Without DTRACE, as every build of this tree (OPTIONS_UNSET of
# tools/make.conf.in; aZ, 11.11.2026: faster, not needed in production): the probes
# of DTrace are compiled into the core only (mydtrace.h: USE_DTRACE and PERL_CORE),
# so the XS modules of FreeBSD's packages, built against its perl with DTRACE, load
# and run with this one (tools/perl-test.sh). Optimized with the CFLAGS of the build
# (-O3 and -march of the level: -Doptimize, DEBUG off), which Config gives the XS
# modules built against it too.
#
# The C compiled by GCC 16 of the ports (Mk/Uses/azgcc.mk; a build dependency only; the
# USES of the official Makefile get it by AZSUPPORT_USES of Mk/bsd.overlay.mk), aZ
# 27.11.2026 08:43 («окей, следуем инфе с тестов»): prog-bench (calls, hash, pack, regex,
# sort, string) against the base clang 19, run 45926215732: GCC 16 -8.0%, clang 23 +1.1% by
# the median, GCC 16 faster than clang 23 by 8.7%, clear in 5 of 6; -9.3% and -9.2% on two
# other machines (45913465743, 45918232254). Its Configure takes the compiler of -Dcc of
# the official port, not the CC of the environment: the same with -static-libgcc after the
# official Makefile (the last -Dcc wins; libgcc linked in, no NEEDED libgcc_s.so.1, as
# Mk/Uses/azgcc.mk). Its lddlflags take no LDFLAGS of the framework (no -pie). Config.pm,
# Config_heavy.pl and CORE/config.h name cc (Mk/azsupport-cc-names.sh), as FreeBSD's perl5,
# so that an XS module builds with the cc of a server (perl-test.sh of azsupport/azsupport
# compares cc with FreeBSD's). With GCC 16 its Configure takes Mmap_t for caddr_t and Shmat_t for char *
# (clang 19 and clang 23: void *, as FreeBSD declares them), as in the build measured.
#
# The default version is that of the pinned tree, as the official packages are built
# (no perl installed): bsd.default-versions.mk takes the version of a perl the build
# machine has installed (/usr/local/bin/perl), and with another one this port would
# make perl5.42 (-Dversiononly, no bin/perl) instead of perl5. DEFAULT_VERSIONS: the
# framework refuses PERL5_DEFAULT set by a port (bsd.default-versions.mk, build.yml
# 43022784709).

AZSUPPORT_OFFICIAL=	lang/perl5.42
AZSUPPORT_USES=		azgcc
# the fix of CVE-2026-15534 (the superlinear cache of regexec.c), which 5.42.3 lacks:
# two upstream commits of blead, as Ubuntu carries them
EXTRA_PATCHES=	${.CURDIR}/files/patch-CVE-2026-15534

_AZ_PERL5_DEFAULT!=	sed -n 's/^PERL5_DEFAULT?=[[:space:]]*//p' ${PORTSDIR:U/usr/ports}/Mk/bsd.default-versions.mk 2> /dev/null || :
.if !empty(_AZ_PERL5_DEFAULT)
DEFAULT_VERSIONS+=	perl5=${_AZ_PERL5_DEFAULT}
.endif

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

.if ${AZSUPPORT_GCC:Uno} != no
CONFIGURE_ARGS+=	-Dcc="${CC} -static-libgcc"
.endif
