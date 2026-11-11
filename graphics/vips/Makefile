# graphics/vips: libvips of azsupport/ports in the place of the official
# graphics/vips (aZ, 11.11.2026: for a Lua script of nginx that converts images on
# the fly). One set of formats, aZ's: JPEG (mozjpeg), PNG (libpng), WebP,
# HEIC/AVIF (libheif of az: both loaded, AVIF saved with SVT-AV1), GIF (load built
# in, save with cgif and libimagequant), with ICC profiles (lcms2), EXIF (libexif)
# and SIMD (Highway; ORC is the other choice, libvips takes it only without Highway).
# Nothing else of the official options: no TIFF, SVG, PDF, JPEG XL, ImageMagick or
# GraphicsMagick (magickload), FFTW, text (pango, fontconfig), libarchive, OpenEXR,
# OpenJPEG, libraw, Ultra HDR, FITS, Matlab; no SPNG (libvips 8.18 takes it only
# without libpng). For images of the web: not the loaders of Analyze, Radiance and
# PPM, not the deprecated vips7 API, the C++ API, the examples, the static
# library, the manual pages and the translations; no bash and python to run. The
# libraries of our ports, as shared ones (aZ, 10.11.2026: our ports link each
# other's shared libraries): mozjpeg, png, webp, libheif, lcms2 and expat of az,
# with the run path /usr/local/az/lib; glib, libexif, cgif, libimagequant and
# highway of the ports of this tree (devel/glib20, graphics/libexif, graphics/cgif,
# graphics/libimagequant, devel/highway: aZ, 11.11.2026); zlib of the base system.
# pkg-message: VIPS_BLOCK_UNTRUSTED for nginx.
# Every library through a .pc of the work with only its own headers (the include
# directories of az and of /usr/local have others: GNU iconv.h, libintl.h ...).

PORTNAME=	vips
PORTVERSION=	8.18.7
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	graphics
MASTER_SITES=	https://github.com/libvips/libvips/releases/download/v${PORTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT=	Free image processing system (of azsupport/ports)
WWW=		https://www.libvips.org/ \
		https://github.com/libvips/libvips \
		https://github.com/azsupport/ports

LICENSE=	LGPL21
LICENSE_FILE=	${WRKSRC}/LICENSE

# the libraries of az, to build and to run (no ldconfig hints for /usr/local/az/lib:
# by a file)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libexpat.so:az/az \
		${AZ_PREFIX}/lib/libintl.so:az/az \
		${AZ_PREFIX}/lib/libjpeg.so:az/az \
		${AZ_PREFIX}/lib/libpng16.so:az/az \
		${AZ_PREFIX}/lib/libwebp.so:az/az \
		${AZ_PREFIX}/lib/libwebpmux.so:az/az \
		${AZ_PREFIX}/lib/libwebpdemux.so:az/az \
		${AZ_PREFIX}/lib/libheif.so:az/az \
		${AZ_PREFIX}/lib/liblcms2.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libexpat.so:az/az \
		${AZ_PREFIX}/lib/libintl.so:az/az \
		${AZ_PREFIX}/lib/libjpeg.so:az/az \
		${AZ_PREFIX}/lib/libpng16.so:az/az \
		${AZ_PREFIX}/lib/libwebp.so:az/az \
		${AZ_PREFIX}/lib/libwebpmux.so:az/az \
		${AZ_PREFIX}/lib/libwebpdemux.so:az/az \
		${AZ_PREFIX}/lib/libheif.so:az/az \
		${AZ_PREFIX}/lib/liblcms2.so:az/az
LIB_DEPENDS=	libcgif.so:graphics/cgif \
		libexif.so:graphics/libexif \
		libhwy.so:devel/highway \
		libimagequant.so:graphics/libimagequant

USES=		compiler:c++14-lang cpe gnome meson pkgconfig python:build tar:xz
USE_GNOME=	glib20
USE_LDCONFIG=	yes

BINARY_ALIAS=	python3=${PYTHON_CMD}
MESON_ARGS=	--default-library=shared \
		-Danalyze=false \
		-Dcplusplus=false \
		-Dcpp-docs=false \
		-Ddeprecated=false \
		-Ddocs=false \
		-Dexamples=false \
		-Dintrospection=disabled \
		-Dmodules=disabled \
		-Dnsgif=true \
		-Dppm=false \
		-Dradiance=false \
		-Dvapi=false \
		-Dcgif=enabled \
		-Dexif=enabled \
		-Dheif=enabled \
		-Dhighway=enabled \
		-Dimagequant=enabled \
		-Djpeg=enabled \
		-Dlcms=enabled \
		-Dpng=enabled \
		-Dwebp=enabled \
		-Dzlib=enabled \
		-Darchive=disabled \
		-Dcfitsio=disabled \
		-Dfftw=disabled \
		-Dfontconfig=disabled \
		-Dheif-module=disabled \
		-Djpeg-xl=disabled \
		-Djpeg-xl-module=disabled \
		-Dmagick=disabled \
		-Dmagick-module=disabled \
		-Dmatio=disabled \
		-Dnifti=disabled \
		-Dopenexr=disabled \
		-Dopenjpeg=disabled \
		-Dopenslide=disabled \
		-Dopenslide-module=disabled \
		-Dorc=disabled \
		-Dpangocairo=disabled \
		-Dpdfium=disabled \
		-Dpoppler=disabled \
		-Dpoppler-module=disabled \
		-Dquantizr=disabled \
		-Draw=disabled \
		-Drsvg=disabled \
		-Dspng=disabled \
		-Dtiff=disabled \
		-Duhdr=disabled
# pkg-config: only the .pc files of the work (pre-configure) and those of the base
# system (zlib)
CONFIGURE_ENV=	PKG_CONFIG_LIBDIR=${WRKDIR}/vips/pc:/usr/libdata/pkgconfig
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

PLIST_SUB=	PATCH_VERSION=${PORTVERSION:E} \
		VERSION=${PORTVERSION:R}

# <name of the .pc>:<the .pc of az it is made from>:<its libraries>
VIPS_AZ_PC=	expat:expat:-lexpat \
		lcms2:lcms2:-llcms2 \
		libheif:libheif:-lheif \
		libjpeg:libjpeg:-ljpeg \
		libpng:libpng16:-lpng16 \
		libwebp:libwebp:-lwebp \
		libwebpdemux:libwebpdemux:-lwebpdemux \
		libwebpmux:libwebpmux:-lwebpmux
# <name of the .pc of the official port>:<its libraries>
VIPS_OFFICIAL_PC=	cgif:-lcgif \
			imagequant:-limagequant \
			libexif:-lexif \
			libhwy:-lhwy

# the headers of each library alone in vips/include, the libraries of the official
# ports alone in vips/lib, a .pc each in vips/pc with the version (and the flags
# other than -I) of its real one: libjpeg, libpng, libwebp, libheif, lcms2 and
# expat of az (-L of az, which has no other library libvips links); cgif,
# libimagequant, libexif and highway of /usr/local (their ports); glib, gobject and gio with
# their own include directories (glib-2.0), and libintl.h and libintl.so of az among
# the headers and the libraries: glib/gi18n-lib.h and glib/gi18n.h of GLib include it
# (the GLib of devel/glib20 is on the libintl of az, so no libintl.h is in
# /usr/local/include), and the tools (vips, vipsedit ...) call gettext of glib/gi18n.h,
# libintl_gettext of GNU libintl.h: glib-2.0 with -lintl (libvips without NLS: the
# strings as they are)
pre-configure:
	@${MKDIR} ${WRKDIR}/vips/include ${WRKDIR}/vips/lib ${WRKDIR}/vips/pc
	@${LN} -sf ${AZ_PREFIX}/include/expat.h ${AZ_PREFIX}/include/expat_external.h \
		${AZ_PREFIX}/include/lcms2.h ${AZ_PREFIX}/include/lcms2_plugin.h \
		${AZ_PREFIX}/include/libheif \
		${AZ_PREFIX}/include/jpeglib.h ${AZ_PREFIX}/include/jconfig.h \
		${AZ_PREFIX}/include/jmorecfg.h ${AZ_PREFIX}/include/jerror.h \
		${AZ_PREFIX}/include/png.h ${AZ_PREFIX}/include/pngconf.h \
		${AZ_PREFIX}/include/pnglibconf.h ${AZ_PREFIX}/include/webp \
		${LOCALBASE}/include/cgif.h ${LOCALBASE}/include/libimagequant.h \
		${LOCALBASE}/include/libexif ${LOCALBASE}/include/hwy \
		${AZ_PREFIX}/include/libintl.h ${WRKDIR}/vips/include/
	@${LN} -sf ${LOCALBASE}/lib/libcgif.so ${LOCALBASE}/lib/libimagequant.so \
		${LOCALBASE}/lib/libexif.so ${LOCALBASE}/lib/libhwy.so \
		${LOCALBASE}/lib/libglib-2.0.so ${LOCALBASE}/lib/libgobject-2.0.so \
		${LOCALBASE}/lib/libgio-2.0.so ${AZ_PREFIX}/lib/libintl.so ${WRKDIR}/vips/lib/
.for e in ${VIPS_AZ_PC}
	@r=${AZ_PREFIX}/lib/pkgconfig/${e:C/^[^:]*://:C/:.*//}.pc; \
	v="$$(PKG_CONFIG_LIBDIR=${AZ_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig pkgconf --modversion $$r)" && \
	o="$$(PKG_CONFIG_LIBDIR=${AZ_PREFIX}/lib/pkgconfig:/usr/libdata/pkgconfig pkgconf --cflags-only-other $$r)" && \
	${PRINTF} '%s\n' 'Name: ${e:C/:.*//}' 'Description: ${e:C/:.*//} of az' "Version: $$v" \
		'Libs: -L${AZ_PREFIX}/lib ${e:C/.*://}' "Cflags: -I${WRKDIR}/vips/include $$o" \
		> ${WRKDIR}/vips/pc/${e:C/:.*//}.pc
.endfor
.for e in ${VIPS_OFFICIAL_PC}
	@r=${LOCALBASE}/libdata/pkgconfig/${e:C/:.*//}.pc; \
	v="$$(PKG_CONFIG_LIBDIR=${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig pkgconf --modversion $$r)" && \
	o="$$(PKG_CONFIG_LIBDIR=${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig pkgconf --cflags-only-other $$r)" && \
	${PRINTF} '%s\n' 'Name: ${e:C/:.*//}' 'Description: ${e:C/:.*//} of the official port' "Version: $$v" \
		'Libs: -L${WRKDIR}/vips/lib ${e:C/.*://}' "Cflags: -I${WRKDIR}/vips/include $$o" \
		> ${WRKDIR}/vips/pc/${e:C/:.*//}.pc
.endfor
	@v="$$(PKG_CONFIG_LIBDIR=${LOCALBASE}/libdata/pkgconfig:/usr/libdata/pkgconfig pkgconf --modversion glib-2.0)" && \
	g='-I${LOCALBASE}/include/glib-2.0 -I${LOCALBASE}/lib/glib-2.0/include' && \
	${PRINTF} '%s\n' 'bindir=${LOCALBASE}/bin' 'glib_genmarshal=$${bindir}/glib-genmarshal' \
		'gobject_query=$${bindir}/gobject-query' 'glib_mkenums=$${bindir}/glib-mkenums' \
		'Name: GLib' 'Description: glib of the official port' "Version: $$v" \
		'Libs: -L${WRKDIR}/vips/lib -lglib-2.0 -lintl' "Cflags: $$g" > ${WRKDIR}/vips/pc/glib-2.0.pc && \
	${PRINTF} '%s\n' 'bindir=${LOCALBASE}/bin' 'glib_genmarshal=$${bindir}/glib-genmarshal' \
		'gobject_query=$${bindir}/gobject-query' 'glib_mkenums=$${bindir}/glib-mkenums' \
		'Name: GObject' 'Description: gobject of the official port' "Version: $$v" 'Requires: glib-2.0' \
		'Libs: -L${WRKDIR}/vips/lib -lgobject-2.0' "Cflags: $$g" > ${WRKDIR}/vips/pc/gobject-2.0.pc && \
	${PRINTF} '%s\n' 'bindir=${LOCALBASE}/bin' 'glib_compile_resources=$${bindir}/glib-compile-resources' \
		'gdbus_codegen=$${bindir}/gdbus-codegen' \
		'Name: GIO' 'Description: gio of the official port' "Version: $$v" 'Requires: glib-2.0 gobject-2.0' \
		'Libs: -L${WRKDIR}/vips/lib -lgio-2.0' "Cflags: $$g" > ${WRKDIR}/vips/pc/gio-2.0.pc

# the manual pages and the translations out (vips without NLS)
post-install:
	@${RM} -r ${STAGEDIR}${PREFIX}/share/man/man1/vips* ${STAGEDIR}${PREFIX}/share/locale

.include <bsd.port.mk>
