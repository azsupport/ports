# SPDX-License-Identifier: BSD-2-Clause
#
# Mk/azsupport-gcc-pie.mk: -pie for the programs only, for a port that GCC builds (USES=azgcc,
# Mk/Uses/azgcc.mk; AZSUPPORT_USES=azgcc for a port of Mk/azsupport-official.mk) whose build
# hands the -pie of LDFLAGS (Mk/Features/pie.mk: WITH_PIE of tools/make.conf.in) to the link of
# a shared library too: meson (devel/glib20, graphics/cairo, converters/fribidi) and the
# Makefiles of math/mpdecimal. GCC takes a -pie after -shared and links the library as a
# program ("Scrt1.o: undefined reference to `main'": the shared objects of prog-bench run
# 45892530935); clang leaves -pie out of a link with -shared, and libtool does not hand it to
# the link of a library. Here gcc<N> and g++<N> (AZSUPPORT_GCC of Mk/Uses/azgcc.mk), as the
# PATH of configure and of the build finds them (CC and CXX of bsd.gcc.mk are these names),
# are wrappers in BINARY_LINKDIR (first in that PATH) of those of lang/gcc<N> that leave -pie
# out of a link with -shared, as tools/prog-bench.sh built with GCC: the programs stay PIE,
# without PIE_UNSAFE (aZ, 27.11.2026 10:07: GLib on GCC 16 with this fix, its programs PIE).
# A file of its own, not a knob of Mk/Uses/azgcc.mk: that one is in the azsupport_hash of every
# port GCC builds (the PHP ports), this one in that of the ports that include it.
#
#   USES=	azgcc ...		(Mk/azsupport-official.mk: AZSUPPORT_USES= azgcc)
#   .include "${.CURDIR:H:H}/Mk/azsupport-gcc-pie.mk"
#   .include <bsd.port.mk>	(or "${.CURDIR:H:H}/Mk/azsupport-official.mk")
#
# MAINTAINER: github@azsupport.com

_USES_configure+=	165:azsupport-gcc-pie
azsupport-gcc-pie:
	@${MKDIR} ${BINARY_LINKDIR}
.for _t in gcc g++
	@${PRINTF} '%s\n' '#!/bin/sh' \
		'# ${_t}${AZSUPPORT_GCC} of lang/gcc${AZSUPPORT_GCC}, -pie left out of a link with -shared (Mk/azsupport-gcc-pie.mk)' \
		's=' \
		'for a do [ "$$a" != -shared ] || s=1; done' \
		'if [ -n "$$s" ]; then' \
		'    for a do shift; [ "$$a" = -pie ] || set -- "$$@" "$$a"; done' \
		'fi' \
		'exec ${LOCALBASE}/bin/${_t}${AZSUPPORT_GCC} "$$@"' > ${BINARY_LINKDIR}/${_t}${AZSUPPORT_GCC}
	@${CHMOD} 755 ${BINARY_LINKDIR}/${_t}${AZSUPPORT_GCC}
.endfor
