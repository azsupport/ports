# The C of the port compiled and linked by GCC of the ports instead of the base
# clang, GCC a build dependency only: nothing of it is needed at run time. A
# USES of the overlay azsupport/ports (the official tree has no such file),
# for its PHP ports: the masters lang/php56, lang/php74, lang/php81,
# lang/php82 and lang/php83 have it in their USES, so the cores, www/mod_php*
# and the modules php*-<module> (their slaves) are built with it (aZ,
# 09.11.2026: the most speed there is, for 5.6 and the modules too).
#
# Why: the Zend VM of PHP 7 and later keeps its frame and its instruction
# pointer in global register variables, which GCC has and clang has not
# (configure: "checking for global register variables support... yes" with GCC
# 16, "no" with clang), and the core with it is HYBRID, not CALL. The
# CLI built with GCC 16.1 of the ports was 33-44% faster than with the base
# clang 19.1.7 of FreeBSD 15.1 for PHP 7.4, 36-38% for 8.3 without OPcache and
# 5-15% with OPcache and its JIT, with the same results of run-tests.php on
# Zend/tests, ext/standard/tests/strings and ext/standard/tests/array (php-src
# tools/bench.sh, run 42582372488; PGO, LTO and clang 23 gave about 5% either
# way, and are not used).
#
# Feature:	azgcc
# Usage:	USES=azgcc
# Valid ARGS:	(none)
#
# AZ_GCC: the version of GCC, that of lang/gcc${AZ_GCC}. AZ_GCC=no in the
# Makefile of a port (before bsd.port.pre.mk): the base clang, as without this
# file. The PHP modules with C++ (intl, swoole, openswoole) have AZ_GCC=no:
# they link C++ libraries of az built by clang with libc++ (ICU), and g++ would
# link libstdc++ of the gcc package, a library of the ports, so that one
# process would have two C++ runtimes of different ABIs. imagick and gmagick
# too: their configure links the OpenMP runtime of the compiler, which for GCC
# is libgomp of the gcc package.
# AZ_GCC_CFLAGS: more flags for the C compiled by GCC (lang/php56:
# -Wno-error=incompatible-pointer-types, an error of GCC 14 and later that the
# base clang has as a warning).
#
# What it does:
# - USE_GCC=${AZ_GCC}:build of the framework (Mk/bsd.gcc.mk): CC, CPP and CXX
#   of lang/gcc${AZ_GCC}, the binutils of the ports (USE_BINUTILS, with which
#   GCC assembles and links), both in BUILD_DEPENDS only;
# - not the run path bsd.gcc.mk adds for the libraries of GCC, -Wl,-rpath= and
#   -L ${LOCALBASE}/lib/gcc${AZ_GCC} in CFLAGS, CXXFLAGS and LDFLAGS (removed in
#   the post part, after bsd.gcc.mk): the run path of our files is
#   ${AZ_PREFIX}/lib only (tools/check-php.sh);
# - -static-libgcc: libgcc and its unwinder linked into each file, no NEEDED
#   libgcc_s.so.1 (/lib has that of the base system, older than that of GCC).
#   In the CC that configure gets, not in LDFLAGS: the libtool 1.5 of PHP
#   passes -static-libgcc of LDFLAGS on to the link of a program only, not to
#   that of a shared library (libphpXY.so, the modules), which it links with
#   that CC; with -c GCC ignores it;
# - -std=gnu17 (USE_CSTD, unless the port has one): GCC 15 and later default
#   to C23, which PHP 7.4 does not build with; gnu17 is the default of the base
#   clang, so the C is that of the builds with clang;
# - STRIPBIN: install -s of the framework (INSTALL_LIB, INSTALL_PROGRAM: the
#   modules, libphpXY.so) with the strip of the binutils of the ports, which
#   keeps the section .comment (the compilers of the objects of the file,
#   "GCC: (FreeBSD Ports Collection) 16.1.0"); the strip of the base system
#   removes it. tools/check-php.sh checks the compiler of the files by it;
# - the annotation az_cc of the package: gcc${AZ_GCC}, or clang with
#   AZ_GCC=no (pkg info -A; tools/check-php.sh).
#
# MAINTAINER: github@azsupport.com

.if !defined(_INCLUDE_USES_AZGCC_MK)
_INCLUDE_USES_AZGCC_MK=	yes

.  if !empty(azgcc_ARGS)
IGNORE=	USES=azgcc takes no arguments
.  endif

AZ_GCC?=	16

# the compiler of the package as its annotation az_cc (pkg info -A), which
# tools/check-php.sh compares with the files: gcc16, or clang (the base cc)
PKG_NOTES+=	az_cc
.  if ${AZ_GCC} != no
USE_GCC=	${AZ_GCC}:build
PKG_NOTE_az_cc=	gcc${AZ_GCC}
.  else
PKG_NOTE_az_cc=	clang
.  endif

_USES_POST+=	azgcc
.endif

.if defined(_POSTMKINCLUDED) && !defined(_INCLUDE_USES_AZGCC_POST_MK)
_INCLUDE_USES_AZGCC_POST_MK=	yes

.  if ${AZ_GCC} != no && defined(_GCC_RUNTIME)
CFLAGS:=	${CFLAGS:N-Wl,-rpath=${_GCC_RUNTIME}} ${AZ_GCC_CFLAGS}
CXXFLAGS:=	${CXXFLAGS:N-Wl,-rpath=${_GCC_RUNTIME}}
LDFLAGS:=	${LDFLAGS:N-Wl,-rpath=${_GCC_RUNTIME}:N-L${_GCC_RUNTIME}}
# the CC of configure (the last CC= of its environment), which writes it into
# the Makefile and the libtool of the build; the make variable CC stays that of
# bsd.gcc.mk, which its BUILD_DEPENDS names
CONFIGURE_ENV+=	CC="${CC} -static-libgcc"
USE_CSTD?=	gnu17
STRIPBIN=	${STRIP_CMD}
.export-env STRIPBIN
.  endif
.endif
