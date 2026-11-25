# graphics/librsvg2-rust: librsvg of azsupport/ports in the place of the official
# graphics/librsvg2-rust, for the libvips of net-im/rocketchat8 (svgload of sharp: the
# avatars of letters, emoji, logos of Rocket.Chat; aZ, 18.11.2026 16:02: «да конечно» —
# the libraries sharp needs that we do not have as ports of this tree become ours,
# shared, with the options of sharp-libvips). As sharp-libvips builds it: no GIF and
# WebP images inside an SVG (the features gif and webp of image), no PDF and
# PostScript of cairo-rs (graphics/cairo has no such surfaces), no AVIF (dav1d), no
# gdk-pixbuf and its loader, rsvg-convert, Vala, documents, introspection, tests; on
# Cairo and Pango (graphics/cairo, x11-toolkits/pango), HarfBuzz (print/harfbuzz),
# FreeType, fontconfig and libxml2 (of azsupport), GLib (devel/glib20). The crates: those of
# the official port without the four only gif and webp need (color_quant, gif,
# image-webp, weezl; cargo update of cargo-configure takes them out of Cargo.lock).
# LTO (aZ, 18.11.2026 12:29): the release profile of the crates with LTO.

PORTNAME=	librsvg
DISTVERSION=	2.63.4
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	graphics gnome
MASTER_SITES=	GNOME
PKGNAMESUFFIX=	2-rust
# XXX Teach USES=cargo to have proper default
DISTFILES=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	github@azsupport.com
COMMENT=	Library for parsing and rendering SVG files (of azsupport/ports)
WWW=		https://gitlab.gnome.org/GNOME/librsvg \
		https://github.com/azsupport/ports

LICENSE=	LGPL20

BUILD_DEPENDS=	cargo-cbuild:devel/cargo-c
LIB_DEPENDS=	libcairo.so:graphics/cairo \
		libharfbuzz.so:print/harfbuzz \
		libpango-1.0.so:x11-toolkits/pango

USES=		cargo compiler:c11 cpe gnome meson pkgconfig python:build \
		shebangfix tar:xz
CPE_VENDOR=	gnome
SHEBANG_FILES=	meson/*.py
USE_GNOME=	glib20
USE_LDCONFIG=	yes
WITH_LTO=	yes

CONFLICTS_INSTALL=	librsvg2

CARGO_BUILD=	no
CARGO_INSTALL=	no
CARGO_TEST=	no

CONFIGURE_ENV=	${CARGO_ENV}
MAKE_ENV=	${CARGO_ENV}

MESON_ARGS=	-Davif=disabled \
		-Ddocs=disabled \
		-Dintrospection=disabled \
		-Dpixbuf=disabled \
		-Dpixbuf-loader=disabled \
		-Drsvg-convert=disabled \
		-Dtests=false \
		-Dvala=disabled

# gettext: the libintl.h of azsupport for glib/gi18n.h; png: the .pc cairo-png requires
# (Mk/azsupport-libs.mk)
AZSUPPORT_LIBS=	fontconfig:libfontconfig.so \
		freetype2:libfreetype.so \
		gettext:libintl.so \
		libxml2:libxml2.so \
		png:libpng16.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# no GIF and WebP in an SVG, no PDF and PostScript of Cairo (sharp-libvips)
post-patch:
	${REINPLACE_CMD} -e '/image = /s/, "gif", "webp"//' ${WRKSRC}/rsvg/Cargo.toml
	${REINPLACE_CMD} -e '/cairo-rs = /s/, "pdf", "ps"//' ${WRKSRC}/rsvg/Cargo.toml \
		${WRKSRC}/librsvg-c/Cargo.toml
	@if ${GREP} -q -e '"gif"' -e '"webp"' ${WRKSRC}/rsvg/Cargo.toml || \
	    ${GREP} -q -e '"pdf"' -e '"ps"' ${WRKSRC}/rsvg/Cargo.toml ${WRKSRC}/librsvg-c/Cargo.toml; then \
		${ECHO_MSG} "librsvg: gif, webp, pdf or ps still in a Cargo.toml"; exit 1; fi

# the plist: what meson installed (the header, the library, its .pc file); the
# libraries it needs itself (--as-needed: fontconfig and FreeType through Pango and
# Cairo, run 44334196993)
post-install:
	@n="$$(/usr/bin/readelf -d ${STAGEDIR}${PREFIX}/lib/librsvg-2.so | ${GREP} NEEDED)"; \
	for l in libcairo libpango-1.0 libpangocairo-1.0 libxml2 libglib-2.0; do \
		echo "$$n" | ${GREP} -q "\[$$l\." || { ${ECHO_MSG} "librsvg: no $$l ($$n)"; exit 1; }; \
	done
	cd ${STAGEDIR}${PREFIX} && ${FIND} include lib libdata \( -type f -o -type l \) | \
		${SORT} >> ${TMPPLIST}

.include <bsd.port.mk>
