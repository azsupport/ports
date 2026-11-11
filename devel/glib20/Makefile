# devel/glib20: GLib 2.88 of azsupport/ports in the place of the official
# devel/glib20 (aZ, 11.11.2026: "как нет glib? ... Делай портами это всё"), the GLib
# of misc/mc and graphics/vips: our ports link each other's shared libraries (aZ,
# 10.11.2026; mc had a static GLib of its own). The official port with its patches
# and triggers, shared only, without introspection (nothing here reads typelibs; no
# gobject-introspection to build it), translations (NLS), the documents and the
# manual pages (USES=meson gives --auto-features=enabled: each feature of GLib named
# below; libelf on, of the base system). libffi, libintl and libiconv (GNU, as the official one takes it:
# USES=iconv:wchar_t) of az, with the run path /usr/local/az/lib, as the GLib of
# tools/mc-build.sh had them; PCRE2 of devel/pcre2, zlib and libelf of the base
# system; the file monitor of GIO the inotify of the base system (FreeBSD 15).
# Python only to build: the scripts of GLib (glib-mkenums, gdbus-codegen ...) need
# it to run, the libraries do not.
# GLib 2.88.4 (08.10.2026) ahead of the official port (2.88.3), for its security
# fixes (rule of 04.11.2026): fourteen backports to glib-2-88 (Unicode normalization,
# corrupted GVariant data, GMarkup error paths, GResource, GIOChannel, the fields of
# the structured log, socket addresses, the mode of a new file), in what mc and vips
# use; the patches of the official port apply to it as they are. Its distfile: the
# SHA-256 of download.gnome.org and of its checksum file (workflow distinfo.yml,
# run 42971518990), the size as Gentoo.

PORTNAME=	glib
DISTVERSION=	2.88.4
PORTREVISION=	${AZ_STAMP:U0}
PORTEPOCH=	2
CATEGORIES=	devel
MASTER_SITES=	GNOME
DIST_SUBDIR=	gnome

MAINTAINER=	github@azsupport.com
COMMENT=	Some useful routines of C programming (of azsupport/ports)
WWW=		https://www.gtk.org/ \
		https://github.com/azsupport/ports

LICENSE=	LGPL20

# the libraries of az, to build and to run (no ldconfig hints for /usr/local/az/lib:
# by a file)
BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}packaging>0:devel/py-packaging@${PY_FLAVOR} \
		${AZ_PREFIX}/lib/libffi.so:az/az \
		${AZ_PREFIX}/lib/libiconv.so:az/az \
		${AZ_PREFIX}/lib/libintl.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libffi.so:az/az \
		${AZ_PREFIX}/lib/libiconv.so:az/az \
		${AZ_PREFIX}/lib/libintl.so:az/az
LIB_DEPENDS=	libpcre2-8.so:devel/pcre2

USES=		compiler:c11 cpe meson perl5 pkgconfig python:build tar:xz trigger
USE_LDCONFIG=	yes
USE_PERL5=	build
TRIGGERS=	gio-modules glib-schemas
MESON_ARGS=	-Db_lundef=false \
		-Ddefault_library=shared \
		-Ddocumentation=false \
		-Ddtrace=disabled \
		-Dinstalled_tests=false \
		-Dintrospection=disabled \
		-Dlibmount=disabled \
		-Dman-pages=disabled \
		-Dnls=disabled \
		-Druntime_dir=/var/run \
		-Dselinux=disabled \
		-Dsysprof=disabled \
		-Dsystemtap=disabled \
		-Dtests=false \
		-Dxattr=false
BINARY_ALIAS=	python3=${PYTHON_CMD}
PORTSCOUT=	limitw:1,even
CPE_VENDOR=	gnome

CONFLICTS_INSTALL=	p5-Giovanni

# libffi, libintl and libiconv of az: its include directory and its libraries (as
# for the GLib of tools/mc-build.sh: GNU iconv.h and libintl.h are those GLib is to
# take there), its .pc files; PCRE2 of devel/pcre2 by pcre2.h, libpcre2-8.so and a
# .pc of its own alone in a directory of the work (pre-configure): nothing else of
# /usr/local is seen
CONFIGURE_ENV=	PKG_CONFIG_LIBDIR=${WRKDIR}/pcre2/pc:${AZ_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig
CPPFLAGS+=	-I${WRKDIR}/pcre2 -I${AZ_PREFIX}/include
LDFLAGS+=	-L${WRKDIR}/pcre2 -L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib

_LIBVERSION=	0.${DISTVERSION:R:E}00.${DISTVERSION:E}
PLIST_SUB=	LIBVERSION=${_LIBVERSION}

.if exists(/usr/include/sys/inotify.h)
MESON_ARGS+=	-Dfile_monitor_backend='inotify'
.else
LIB_DEPENDS+=	libinotify.so:devel/libinotify
MESON_ARGS+=	-Dfile_monitor_backend='libinotify-kqueue'
.endif

post-patch:
	${REINPLACE_CMD} -e 's|@PYTHON@|${PYTHON_CMD}|g' \
		${WRKSRC}/gio/gdbus-2.0/codegen/gdbus-codegen.in \
		${WRKSRC}/glib/gtester-report.in \
		${WRKSRC}/gobject/glib-genmarshal.in \
		${WRKSRC}/gobject/glib-mkenums.in
	${REINPLACE_CMD} -e '/inotify_init1/d' \
		-e '/inotify.h/d' \
		${WRKSRC}/meson.build
	${REINPLACE_CMD} -e 's|%%LOCALBASE%%|${LOCALBASE}|' \
		${WRKSRC}/gio/xdgmime/xdgmime.c \
		${WRKSRC}/glib/gutils.c \
		${WRKSRC}/glib/tests/utils-unisolated.c

pre-configure:
	@${MKDIR} ${WRKDIR}/pcre2/pc
	@${LN} -sf ${LOCALBASE}/include/pcre2.h ${LOCALBASE}/lib/libpcre2-8.so ${WRKDIR}/pcre2/
	@${PRINTF} '%s\n' 'Name: libpcre2-8' 'Description: PCRE2 of devel/pcre2' \
		"Version: $$(PKG_CONFIG_LIBDIR=${LOCALBASE}/libdata/pkgconfig pkgconf --modversion ${LOCALBASE}/libdata/pkgconfig/libpcre2-8.pc)" \
		'Libs: -L${WRKDIR}/pcre2 -lpcre2-8' 'Cflags: -I${WRKDIR}/pcre2' > ${WRKDIR}/pcre2/pc/libpcre2-8.pc

CODEGENDIR=	${PREFIX}/share/glib-2.0/codegen

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/share/GConf/gsettings
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/gio/modules
# the byte code of the codegen modules, as the official port makes it
	${FIND} ${STAGEDIR}${PREFIX} -name \*.pyc -delete
	(cd ${STAGEDIR}${PREFIX} && \
	${PYTHON_CMD} ${PYTHON_LIBDIR}/compileall.py \
		-d ${CODEGENDIR} -f ${CODEGENDIR:S;${PREFIX}/;;} && \
	${PYTHON_CMD} -O ${PYTHON_LIBDIR}/compileall.py \
		-d ${CODEGENDIR} -f ${CODEGENDIR:S;${PREFIX}/;;})
	${MKDIR} ${STAGEDIR}${PREFIX}/share/bash-completion/completions
.for file in gapplication gdbus gio gresource gsettings
	${INSTALL_DATA} ${WRKSRC}/gio/completion/${file} \
		${STAGEDIR}${PREFIX}/share/bash-completion/completions/
.endfor
	${RM} -r ${STAGEDIR}${PREFIX}/libexec/installed-tests

.include <bsd.port.mk>
