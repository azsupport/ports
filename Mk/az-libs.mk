# Mk/az-libs.mk: the shared libraries of az a port of this tree links (aZ, 10.11.2026:
# our ports link each other's shared libraries), each seen with its own headers and
# .pc files only: the include directory of az has others (GNU iconv.h, libintl.h ...),
# which a port is not to take by -I of the whole directory. graphics/vips does the same
# by hand. The port names the libraries of az (their names in az/az/files/deps.conf)
# with a shared library of each, before it includes this file:
#
#   AZ_LIBS=	freetype2:libfreetype.so fontconfig:libfontconfig.so png:libpng16.so
#   .include "${.CURDIR:H:H}/Mk/az-libs.mk"
#
# This file gives the port:
# - BUILD_DEPENDS and RUN_DEPENDS on those files of az/az (the builder takes the
#   interfaces of these libraries into the az_hash of the port, tools/build.sh);
# - before do-configure (az-libs-prepare): ${AZ_LIBS_DIR} in the work, include/ with
#   links to the headers of these libraries and of those they require (the manifests of
#   az, ${AZ_PREFIX}/share/az/interface/<name>.txt: the lines file and link under
#   include/, requires), pkgconfig/ with their .pc files, whose include directory is
#   that include/ (their libraries stay those of ${AZ_PREFIX}/lib);
# - ${AZ_LIBS_PKG_CONFIG_LIBDIR}: that pkgconfig/, then those of the framework (the
#   links of PKGCONFIG_BASE), of /usr/local (the ports of this tree) and of the base
#   system, the PKG_CONFIG_LIBDIR of the port (in its CONFIGURE_ENV and MAKE_ENV here,
#   so the framework does not set its own); -I of that include/ (CPPFLAGS: the
#   libintl.h of az for the GLib of devel/glib20, glib/gi18n.h); -L of az (-lintl of
#   the .pc of GLib) and its run path (its directory has no hints of ldconfig).
#
# Only the ports that include it read this file: a change of it builds them again.

AZ_LIBS_DIR=		${WRKDIR}/az-libs
AZ_LIBS_PKG_CONFIG_LIBDIR=	${AZ_LIBS_DIR}/pkgconfig:${WRKDIR}/.pkgconfig:${LOCALBASE}/libdata/pkgconfig:${LOCALBASE}/share/pkgconfig:/usr/libdata/pkgconfig

.for l in ${AZ_LIBS}
BUILD_DEPENDS+=	${AZ_PREFIX}/lib/${l:C/^[^:]*://}:az/az
RUN_DEPENDS+=	${AZ_PREFIX}/lib/${l:C/^[^:]*://}:az/az
.endfor
CONFIGURE_ENV+=	PKG_CONFIG_LIBDIR=${AZ_LIBS_PKG_CONFIG_LIBDIR}
MAKE_ENV+=	PKG_CONFIG_LIBDIR=${AZ_LIBS_PKG_CONFIG_LIBDIR}
CPPFLAGS+=	-I${AZ_LIBS_DIR}/include
LDFLAGS+=	-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib
_USES_configure+=	310:az-libs-prepare

az-libs-prepare:
	@${RM} -r ${AZ_LIBS_DIR}
	@${MKDIR} ${AZ_LIBS_DIR}/include ${AZ_LIBS_DIR}/pkgconfig
	@i=${AZ_PREFIX}/share/az/interface; todo="${AZ_LIBS:C/:.*//}"; seen=""; \
	while [ -n "$$(echo $$todo)" ]; do \
		set -- $$todo; n=$$1; shift; todo="$$*"; \
		case " $$seen " in *" $$n "*) continue ;; esac; \
		seen="$$seen $$n"; \
		if [ ! -f $$i/$$n.txt ]; then \
			${ECHO_MSG} "az-libs: az has no library $$n ($$i/$$n.txt)"; exit 1; \
		fi; \
		todo="$$todo $$(${AWK} '$$1 == "requires" { print $$2 }' $$i/$$n.txt)"; \
		for p in $$(${AWK} '($$1 == "file" || $$1 == "link") && $$2 ~ /^include\// { print $$2 }' $$i/$$n.txt); do \
			${MKDIR} ${AZ_LIBS_DIR}/$${p%/*} && ${LN} -sf ${AZ_PREFIX}/$$p ${AZ_LIBS_DIR}/$$p || exit 1; \
		done; \
		for p in $$(${AWK} '$$1 == "file" && $$2 ~ /^lib\/pkgconfig\/.*\.pc$$/ { print $$2 }' $$i/$$n.txt); do \
			${SED} -e 's|^includedir=.*|includedir=${AZ_LIBS_DIR}/include|' \
				-e 's|-I\$${prefix}/include|-I${AZ_LIBS_DIR}/include|g' \
				-e 's|-I${AZ_PREFIX}/include|-I${AZ_LIBS_DIR}/include|g' \
				${AZ_PREFIX}/$$p > ${AZ_LIBS_DIR}/pkgconfig/$${p##*/} || exit 1; \
		done; \
	done; \
	${ECHO_MSG} "===>  The libraries of az, each with its own headers:$$seen"
