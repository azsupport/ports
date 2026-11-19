# graphics/cairo: Cairo of azsupport/ports in the place of the official graphics/cairo,
# for the libvips of net-im/rocketchat8 (SVG of librsvg and the text of Pango; aZ,
# 18.11.2026 16:02: «да конечно» — the libraries sharp needs that we do not have as
# ports of this tree become ours, shared, with the options of sharp-libvips). As
# sharp-libvips builds it: FreeType and fontconfig (of az), PNG (libpng of az: the
# image and SVG surfaces), pixman (x11/pixman), GLib (devel/glib20: cairo-gobject);
# no zlib (so no PDF, PostScript and script surfaces), X11 (xlib, xcb), Quartz,
# DirectWrite, tee, LZO, spectre, symbol lookup, documents, tests. LTO (aZ, 18.11.2026
# 12:29).
# Five fixes 1.18.6 lacks (aZ, 19.11.2026 02:10: «давай так»), in files/fixes, in order,
# the source at the top of each: CVE-2025-50422, a rectangle at INT32_MAX (and INT32_MIN)
# makes active_edges_to_traps() read past the list of edges (pkgsrc, the merge request
# 632; openSUSE has its first half); three of cairo-image-info.c of upstream after
# 1.18.6 (Debian 1.18.6-1: dd4da532e5, 89f049a35e, 1e5851bdc9 — the JPEG read past the
# data and its fields left unset, the JPEG 2000 box of length 0 that loops forever, the
# JBIG2 reads past the data); CVE-2017-7475, a bitmap without a buffer in
# _get_bitmap_surface() of cairo-ft-font.c (openSUSE, OpenEmbedded).

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
CAIRO_FIXES=	1-CVE-2025-50422 \
		2-image-info-out-of-bounds-read-and-uninitialized-inf \
		3-image-info-infinite-loop-on-jpeg-2000-boxes-with-le \
		4-image-info-out-of-bounds-reads-for-jbig2 5-CVE-2017-7475
EXTRA_PATCHES=	${CAIRO_FIXES:@p@${FILESDIR}/fixes/${p}.patch:-p1@}
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

# no fallback of meson to subprojects/: a library of az it does not find stops the build
# (the package of 18.11.2026 had a libpng16 of its own, which conflicted with the official
# png: build run 44379121576)
post-extract:
	${RM} -r ${WRKSRC}/subprojects

# the plist: what meson installed (headers, the libraries, their .pc files); nothing of
# another library
post-install:
	@if ${FIND} ${STAGEDIR}${PREFIX} -name 'libpng*' | ${GREP} -q .; then \
		${FIND} ${STAGEDIR}${PREFIX} -name 'libpng*'; ${ECHO_MSG} "cairo: libpng in the stage"; exit 1; fi
	@n="$$(/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/libcairo.so.2 | ${GREP} NEEDED)"; \
	for l in libfontconfig libfreetype libpng16 libpixman-1; do \
		echo "$$n" | ${GREP} -q "\[$$l\." || { ${ECHO_MSG} "cairo: no $$l ($$n)"; exit 1; }; \
	done
	cd ${STAGEDIR}${PREFIX} && ${FIND} include lib libdata \( -type f -o -type l \) | \
		${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>
