# graphics/cairo: Cairo of azsupport/ports in the place of the official graphics/cairo,
# for the libvips of net-im/rocketchat8 (SVG of librsvg and the text of Pango; aZ,
# 18.11.2026 16:02: «да конечно» — the libraries sharp needs that we do not have as
# ports of this tree become ours, shared, with the options of sharp-libvips). As
# sharp-libvips builds it: FreeType and fontconfig (of az), PNG (libpng of az: the
# image and SVG surfaces), pixman (x11/pixman), GLib (devel/glib20: cairo-gobject);
# no zlib (so no PDF, PostScript and script surfaces), X11 (xlib, xcb), Quartz,
# DirectWrite, tee, LZO, spectre, symbol lookup, documents, tests. LTO (aZ, 18.11.2026
# 12:29).

PORTNAME=	cairo
DISTVERSION=	1.18.6
PORTEPOCH=	3
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	graphics
MASTER_SITES=	https://cairographics.org/releases/

MAINTAINER=	github@azsupport.com
COMMENT=	Vector graphics library (of azsupport/ports)
WWW=		https://www.cairographics.org/ \
		https://github.com/azsupport/ports

LICENSE=	LGPL21 MPL11
LICENSE_COMB=	dual
LICENSE_FILE_LGPL21=	${WRKSRC}/COPYING-LGPL-2.1
LICENSE_FILE_MPL11=	${WRKSRC}/COPYING-MPL-1.1

LIB_DEPENDS=	libpixman-1.so:x11/pixman

USES=		cpe gnome meson pkgconfig python:build shebangfix tar:xz
CPE_VENDOR=	cairographics
USE_GNOME=	glib20
USE_LDCONFIG=	yes
SHEBANG_FILES=	version.py
WITH_LTO=	yes

MESON_ARGS=	-Dfontconfig=enabled \
		-Dfreetype=enabled \
		-Dglib=enabled \
		-Dpng=enabled \
		-Ddwrite=disabled \
		-Dgtk2-utils=disabled \
		-Dgtk_doc=false \
		-Dlzo=disabled \
		-Dquartz=disabled \
		-Dspectre=disabled \
		-Dsymbol-lookup=disabled \
		-Dtee=disabled \
		-Dtests=disabled \
		-Dxcb=disabled \
		-Dxlib=disabled \
		-Dxlib-xcb=disabled \
		-Dzlib=disabled

AZ_LIBS=	fontconfig:libfontconfig.so \
		freetype2:libfreetype.so \
		png:libpng16.so
.include "${.CURDIR:H:H}/Mk/az-libs.mk"

# the plist: what meson installed (headers, the libraries, their .pc files)
post-install:
	@n="$$(/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libcairo.so.2 | ${GREP} NEEDED)"; \
	for l in libfontconfig libfreetype libpng16 libpixman-1; do \
		echo "$$n" | ${GREP} -q "\[$$l\." || { ${ECHO_MSG} "cairo: no $$l ($$n)"; exit 1; }; \
	done
	cd ${STAGEDIR}${PREFIX} && ${FIND} include lib libdata \( -type f -o -type l \) | \
		${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>
