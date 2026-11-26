# print/harfbuzz: HarfBuzz of azsupport/ports in the place of the official print/harfbuzz,
# for the libvips of net-im/rocketchat8 (text of SVG and of vips_text through Pango;
# aZ, 18.11.2026 16:02: «да конечно» — the libraries sharp needs that we do not have
# as ports of this tree become ours, shared, with the options of sharp-libvips). The
# library harfbuzz alone, as sharp-libvips builds it: FreeType (of azsupport) and GLib (of
# devel/glib20); no GObject, ICU, Cairo, Graphite, chafa, subset, raster, vector, GPU,
# utilities, benchmark, documents, introspection, tests. LTO (aZ, 18.11.2026 12:29).

PORTNAME=	harfbuzz
DISTVERSION=	15.0.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	print
MASTER_SITES=	https://github.com/${PORTNAME}/${PORTNAME}/releases/download/${DISTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT=	OpenType text shaping engine (of azsupport/ports)
WWW=		https://harfbuzz.github.io/ \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/COPYING

USES=		compiler:c++11-lib cpe gnome meson pkgconfig python:build \
		shebangfix tar:xz
CPE_VENDOR=	harfbuzz_project
SHEBANG_GLOB=	*.py
USE_GNOME=	glib20
USE_LDCONFIG=	yes
WITH_LTO=	yes

MESON_ARGS=	-Dfreetype=enabled \
		-Dglib=enabled \
		-Dbenchmark=disabled \
		-Dcairo=disabled \
		-Dchafa=disabled \
		-Ddocs=disabled \
		-Dfontations=disabled \
		-Dgobject=disabled \
		-Dgpu=disabled \
		-Dgpu_demo=disabled \
		-Dgraphite2=disabled \
		-Dharfrust=disabled \
		-Dicu=disabled \
		-Dintrospection=disabled \
		-Dkbts=disabled \
		-Dpng=disabled \
		-Draster=disabled \
		-Dsubset=disabled \
		-Dtests=disabled \
		-Dutilities=disabled \
		-Dvector=disabled \
		-Dwasm=disabled \
		-Dzlib=disabled

AZSUPPORT_LIBS=	freetype2:libfreetype.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# the plist: what meson installed (headers, the library, its .pc and CMake files)
post-install:
	@/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libharfbuzz.so | ${GREP} -q 'NEEDED.*\[libfreetype\.' || \
		{ ${ECHO_MSG} "harfbuzz: not linked with FreeType"; exit 1; }
	cd ${STAGEDIR}${PREFIX} && ${FIND} include lib libdata \( -type f -o -type l \) | \
		${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>

# No devel/gettext-runtime (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние
# зависимости убираем, нужные собираем у нас.»): USE_GNOME=glib20 adds
# libintl.so:devel/gettext-runtime to LIB_DEPENDS with GLib (glib20_LIB_DEPENDS of
# Mk/Uses/gnome.mk, which bsd.port.mk reads with the USES of the port), and HarfBuzz
# links no libintl (the -lintl of glib-2.0.pc: libintl.so of azsupport by the -L of
# Mk/azsupport-libs.mk, dropped by --as-needed). The targets of bsd.port.mk read
# LIB_DEPENDS when they run, so it goes out here, after them.
LIB_DEPENDS:=	${LIB_DEPENDS:Nlibintl.so\:devel/gettext-runtime}
