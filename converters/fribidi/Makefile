# converters/fribidi of azsupport/ports: the official port (Mk/azsupport-official.mk), the
# bidirectional text of x11-toolkits/pango for the libvips of net-im/rocketchat8 (aZ,
# 18.11.2026 16:02: «да конечно» — the libraries sharp needs that we do not have as
# ports of this tree become ours, shared, with the options of sharp-libvips: no tests).
# LTO (aZ, 18.11.2026 12:29). Compiled by GCC 16 (AZSUPPORT_USES=azgcc, Mk/Uses/azgcc.mk:
# the USES= of the official Makefile would drop it; aZ, 27.11.2026 10:07: «да»):
# lib-bench3.sh of 26.11.2026 found it 2.1% faster with it than with clang 23
# (docs/compiler-choice/decision.md of azsupport/azsupport); C alone, no OpenMP. meson hands
# the -pie of LDFLAGS to the link of libfribidi too, which GCC would link as a program:
# Mk/azsupport-gcc-pie.mk leaves it out there (bin/fribidi stays PIE).

AZSUPPORT_OFFICIAL=	converters/fribidi
AZSUPPORT_USES=	azgcc
OPTIONS_EXCLUDE=	TEST
WITH_LTO=	yes

.include "${.CURDIR:H:H}/Mk/azsupport-gcc-pie.mk"
.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
