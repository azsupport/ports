# Mk/azsupport-libs.mk: the shared libraries of azsupport a port of this tree links (aZ, 10.11.2026:
# our ports link each other's shared libraries), each seen with its own headers and
# .pc files only: the include directory of azsupport has others (GNU iconv.h, libintl.h ...),
# which a port is not to take by -I of the whole directory. graphics/vips does the same
# by hand. The port names the libraries of azsupport (their names in azsupport/static/files/deps.conf)
# with a shared library of each, before it includes this file:
#
#   AZSUPPORT_LIBS=	freetype2:libfreetype.so fontconfig:libfontconfig.so png:libpng16.so
#   .include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"
#
# This file gives the port:
# - BUILD_DEPENDS and RUN_DEPENDS on that file of the port of each library: azsupport/<name>, in
#   ${AZSUPPORT_PREFIX}; fontconfig is x11-fonts/fontconfig, in ${LOCALBASE}
#   (AZSUPPORT_LIB_ORIGIN.<name> and AZSUPPORT_LIB_PREFIX.<name> below; the builder takes the
#   interfaces of these libraries into the azsupport_hash of the port, tools/build.sh);
# - before do-configure (azsupport-libs-prepare): ${AZSUPPORT_LIBS_DIR} in the work, include/ with
#   links to the headers of these libraries and of those they require (the manifests of the
#   library ports, ${AZSUPPORT_PREFIX}/share/azsupport/interface/<name>.txt: the lines file and link
#   under include/, requires, and prefix, the directory of its files when it is not
#   ${AZSUPPORT_PREFIX}), pkgconfig/ with their .pc files (lib/pkgconfig or libdata/pkgconfig of that
#   directory), whose include directory is that include/ (their libraries stay those of their
#   lib/), and the links among them (libpng.pc to libpng16.pc: meson of graphics/cairo asks for
#   libpng, and without it took the libpng of its subprojects/ into its package, build run
#   44379121576);
# - ${AZSUPPORT_LIBS_PKG_CONFIG_LIBDIR}: that pkgconfig/, then those of the framework (the
#   links of PKGCONFIG_BASE), of /usr/local (the ports of this tree) and of the base
#   system, the PKG_CONFIG_LIBDIR of the port (in its CONFIGURE_ENV and MAKE_ENV here,
#   so the framework does not set its own); -I of that include/ (CPPFLAGS: the
#   libintl.h of azsupport for the GLib of devel/glib20, glib/gi18n.h); -L of azsupport (-lintl of
#   the .pc of GLib) and its run path (its directory has no hints of ldconfig).
#
# Only the ports that include it read this file: a change of it builds them again.

AZSUPPORT_LIBS_DIR=		${WRKDIR}/azsupport-libs
AZSUPPORT_LIBS_PKG_CONFIG_LIBDIR=	${AZSUPPORT_LIBS_DIR}/pkgconfig:${WRKDIR}/.pkgconfig:${LOCALBASE}/libdata/pkgconfig:${LOCALBASE}/share/pkgconfig:/usr/libdata/pkgconfig

# the port of a library and the directory of its files, when they are not azsupport/<name>
# and ${AZSUPPORT_PREFIX}
AZSUPPORT_LIB_ORIGIN.fontconfig=	x11-fonts/fontconfig
AZSUPPORT_LIB_PREFIX.fontconfig=	${LOCALBASE}

.for l in ${AZSUPPORT_LIBS}
BUILD_DEPENDS+=	${AZSUPPORT_LIB_PREFIX.${l:C/:.*//}:U${AZSUPPORT_PREFIX}}/lib/${l:C/^[^:]*://}:${AZSUPPORT_LIB_ORIGIN.${l:C/:.*//}:Uazsupport/${l:C/:.*//}}
RUN_DEPENDS+=	${AZSUPPORT_LIB_PREFIX.${l:C/:.*//}:U${AZSUPPORT_PREFIX}}/lib/${l:C/^[^:]*://}:${AZSUPPORT_LIB_ORIGIN.${l:C/:.*//}:Uazsupport/${l:C/:.*//}}
.endfor
CONFIGURE_ENV+=	PKG_CONFIG_LIBDIR=${AZSUPPORT_LIBS_PKG_CONFIG_LIBDIR}
MAKE_ENV+=	PKG_CONFIG_LIBDIR=${AZSUPPORT_LIBS_PKG_CONFIG_LIBDIR}
CPPFLAGS+=	-I${AZSUPPORT_LIBS_DIR}/include
LDFLAGS+=	-L${AZSUPPORT_PREFIX}/lib -Wl,-rpath,${AZSUPPORT_PREFIX}/lib
_USES_configure+=	310:azsupport-libs-prepare

azsupport-libs-prepare:
	@${RM} -r ${AZSUPPORT_LIBS_DIR}
	@${MKDIR} ${AZSUPPORT_LIBS_DIR}/include ${AZSUPPORT_LIBS_DIR}/pkgconfig
	@i=${AZSUPPORT_PREFIX}/share/azsupport/interface; todo="${AZSUPPORT_LIBS:C/:.*//}"; seen=""; \
	while [ -n "$$(echo $$todo)" ]; do \
		set -- $$todo; n=$$1; shift; todo="$$*"; \
		case " $$seen " in *" $$n "*) continue ;; esac; \
		seen="$$seen $$n"; \
		if [ ! -f $$i/$$n.txt ]; then \
			${ECHO_MSG} "azsupport-libs: no manifest of the library $$n ($$i/$$n.txt): its port is not installed"; exit 1; \
		fi; \
		pre=$$(${AWK} '$$1 == "prefix" { print $$2; exit }' $$i/$$n.txt); pre=$${pre:-${AZSUPPORT_PREFIX}}; \
		todo="$$todo $$(${AWK} '$$1 == "requires" { print $$2 }' $$i/$$n.txt)"; \
		for p in $$(${AWK} '($$1 == "file" || $$1 == "link") && $$2 ~ /^include\// { print $$2 }' $$i/$$n.txt); do \
			${MKDIR} ${AZSUPPORT_LIBS_DIR}/$${p%/*} && ${LN} -sf $$pre/$$p ${AZSUPPORT_LIBS_DIR}/$$p || exit 1; \
		done; \
		for p in $$(${AWK} '$$1 == "file" && $$2 ~ /^(lib|libdata)\/pkgconfig\/.*\.pc$$/ { print $$2 }' $$i/$$n.txt); do \
			${SED} -e 's|^includedir=.*|includedir=${AZSUPPORT_LIBS_DIR}/include|' \
				-e 's|-I\$${prefix}/include|-I${AZSUPPORT_LIBS_DIR}/include|g' \
				-e "s|-I$$pre/include|-I${AZSUPPORT_LIBS_DIR}/include|g" \
				$$pre/$$p > ${AZSUPPORT_LIBS_DIR}/pkgconfig/$${p##*/} || exit 1; \
		done; \
		for p in $$(${AWK} '$$1 == "link" && $$2 ~ /^(lib|libdata)\/pkgconfig\/.*\.pc$$/ { print $$2 "=" $$3 }' $$i/$$n.txt); do \
			t=$${p#*=}; l=$${p%%=*}; \
			${LN} -sf $${t##*/} ${AZSUPPORT_LIBS_DIR}/pkgconfig/$${l##*/} || exit 1; \
		done; \
	done; \
	${ECHO_MSG} "===>  The libraries of azsupport, each with its own headers:$$seen"
