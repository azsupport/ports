# x11-toolkits/pango: Pango of azsupport/ports in the place of the official
# x11-toolkits/pango, for the libvips of net-im/rocketchat8 (text of SVG and of
# vips_text; aZ, 18.11.2026 16:02: «да конечно» — the libraries sharp needs that we do
# not have as ports of this tree become ours, shared, with the options of
# sharp-libvips). As sharp-libvips builds it: Cairo (graphics/cairo), FreeType and
# fontconfig (of azsupport), HarfBuzz (print/harfbuzz), FriBidi (converters/fribidi), GLib
# (devel/glib20); no Xft, libthai, sysprof, utilities and tools (pango-view,
# pango-list, pango-segmentation), documents, manual pages, examples, introspection,
# tests. LTO (aZ, 18.11.2026 12:29).

PORTNAME=	pango
DISTVERSION=	1.58.2
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	x11-toolkits
MASTER_SITES=	GNOME
DIST_SUBDIR=	gnome

MAINTAINER=	github@azsupport.com
COMMENT=	Layout and rendering of international text (of azsupport/ports)
WWW=		https://www.gtk.org/docs/architecture/pango \
		https://github.com/azsupport/ports

LICENSE=	LGPL21+
LICENSE_FILE=	${WRKSRC}/COPYING

LIB_DEPENDS=	libcairo.so:graphics/cairo \
		libfribidi.so:converters/fribidi \
		libharfbuzz.so:print/harfbuzz

USES=		compiler:c11 cpe gnome meson pkgconfig tar:xz
CPE_VENDOR=	gnome
USE_GNOME=	glib20
USE_LDCONFIG=	yes
WITH_LTO=	yes

MESON_ARGS=	-Dcairo=enabled \
		-Dfontconfig=enabled \
		-Dfreetype=enabled \
		-Dbuild-examples=false \
		-Dbuild-testsuite=false \
		-Ddocumentation=false \
		-Dintrospection=disabled \
		-Dlibthai=disabled \
		-Dman-pages=false \
		-Dsysprof=disabled \
		-Dxft=disabled

# gettext: the libintl.h of azsupport for glib/gi18n-lib.h; png: the .pc Cairo requires
# (Mk/azsupport-libs.mk)
AZSUPPORT_LIBS=	fontconfig:libfontconfig.so \
		freetype2:libfreetype.so \
		gettext:libintl.so \
		png:libpng16.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# without its utilities and tools (sharp-libvips)
post-patch:
	${REINPLACE_CMD} -e "/^subdir('utils')$$/d" -e "/^subdir('tools')$$/d" ${WRKSRC}/meson.build
	@if ${GREP} -q -e "subdir('utils')" -e "subdir('tools')" ${WRKSRC}/meson.build; then \
		${ECHO_MSG} "pango: subdir('utils') or subdir('tools') still in meson.build"; exit 1; fi

# the plist: what meson installed (headers, the libraries, their .pc files)
post-install:
	@n="$$(/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libpangocairo-1.0.so | ${GREP} NEEDED)"; \
	for l in libcairo libharfbuzz libfontconfig libfreetype; do \
		echo "$$n" | ${GREP} -q "\[$$l\." || /usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libpangoft2-1.0.so | ${GREP} -q "NEEDED.*\[$$l\." || \
			{ ${ECHO_MSG} "pango: no $$l"; exit 1; }; \
	done
	cd ${STAGEDIR}${PREFIX} && ${FIND} include lib libdata \( -type f -o -type l \) | \
		${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>

# No devel/gettext-runtime (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние
# зависимости убираем, нужные собираем у нас.»): USE_GNOME=glib20 adds
# libintl.so:devel/gettext-runtime to LIB_DEPENDS with GLib (glib20_LIB_DEPENDS of
# Mk/Uses/gnome.mk, which bsd.port.mk reads with the USES of the port), and Pango links
# no libintl (the -lintl of glib-2.0.pc: libintl.so of azsupport by the -L of
# Mk/azsupport-libs.mk, dropped by --as-needed; its libintl.h is that of azsupport,
# above). The targets of bsd.port.mk read LIB_DEPENDS when they run, so it goes out
# here, after them.
LIB_DEPENDS:=	${LIB_DEPENDS:Nlibintl.so\:devel/gettext-runtime}
