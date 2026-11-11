# lang/perl5.42 of azsupport/ports: the official port (Mk/az-official.mk), Perl 5.42
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
# The default version is that of the pinned tree, as the official packages are built
# (no perl installed): bsd.default-versions.mk takes the version of a perl the build
# machine has installed (/usr/local/bin/perl), and with another one this port would
# make perl5.42 (-Dversiononly, no bin/perl) instead of perl5. DEFAULT_VERSIONS: the
# framework refuses PERL5_DEFAULT set by a port (bsd.default-versions.mk, build.yml
# 43022784709).

AZ_OFFICIAL=	lang/perl5.42

_AZ_PERL5_DEFAULT!=	sed -n 's/^PERL5_DEFAULT?=[[:space:]]*//p' ${PORTSDIR:U/usr/ports}/Mk/bsd.default-versions.mk 2> /dev/null || :
.if !empty(_AZ_PERL5_DEFAULT)
DEFAULT_VERSIONS+=	perl5=${_AZ_PERL5_DEFAULT}
.endif

.include "${.CURDIR:H:H}/Mk/az-official.mk"
