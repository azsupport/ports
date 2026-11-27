# math/mpdecimal of azsupport/ports: the official port (Mk/azsupport-official.mk), the
# libmpdec of the module _decimal of our lang/python312 (its option LIBMPDEC, on as
# in the official port; aZ, 11.11.2026), instead of the copy CPython bundles.
# libmpdec (C) compiled by GCC 16 (AZSUPPORT_USES=azgcc, Mk/Uses/azgcc.mk: the USES= of the
# official Makefile would drop it), libmpdec++ (C++) by clang++ of devel/llvm${AZSUPPORT_CLANG},
# with the libc++ of the base system, as the other C++ of the packages (aZ, 27.11.2026 10:07:
# «да»; lib-bench3.sh of 26.11.2026: libmpdec 28.5% faster with GCC 16 than with clang 23,
# docs/compiler-choice/decision.md of azsupport/azsupport): the CXX of configure, and so its
# LDXX (CONFIGURE_ENV comes after the CXX of the framework, g++ of bsd.gcc.mk, in the
# environment of configure: the last one counts). Its Makefiles link libmpdec.so with the -pie
# of LDFLAGS, which GCC would make a program: Mk/azsupport-gcc-pie.mk leaves it out there
# (clang++ leaves it out of libmpdec++.so itself).

AZSUPPORT_OFFICIAL=	math/mpdecimal
AZSUPPORT_USES=	azgcc
BUILD_DEPENDS+=	clang${AZSUPPORT_CLANG}:devel/llvm${AZSUPPORT_CLANG}
CONFIGURE_ENV+=	CXX=${LOCALBASE}/bin/clang++${AZSUPPORT_CLANG}

.include "${.CURDIR:H:H}/Mk/azsupport-gcc-pie.mk"
.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
