# azsupport/azsupport: the libraries of /usr/local/azsupport (the package azsupport).
#
# DESIGN of the ports that take over the builds of tools/build-az.sh of
# https://github.com/azsupport/php-src (08.11.2026, aZ: the development of
# these packages moves into this tree):
#
#   package       origin                 files
#   azsupport            azsupport/azsupport                  /usr/local/azsupport: the shared tree lib/
#                                        (SONAME, run path /usr/local/azsupport/lib, no
#                                        ldconfig), include/, lib/pkgconfig/,
#                                        bin/pkg-config, which every package
#                                        links, and the static tree
#                                        static/{lib,include,bin}, for PHP built
#                                        on a server; share/doc/azsupport/VERSIONS,
#                                        LICENSES/
#   curl          ftp/curl               bin/curl, lib/libcurl.so.4 (only curl_*
#                                        exported), the libcurl of every package,
#                                        include/curl...
#   ffmpeg        multimedia/ffmpeg      bin/ffmpeg, bin/ffprobe (the libraries of
#                                        FFmpeg in them)
#   ImageMagick6  graphics/ImageMagick6  bin/*6, etc/ImageMagick-6 (our policy),
#                                        share/ImageMagick-6; its shared
#                                        libMagickCore-6.Q16 and libMagickWand-6.Q16
#                                        and lib/ImageMagick-6.* in azsupport/lib
#   ImageMagick7  graphics/ImageMagick7  bin/magick and its links,
#                                        etc/ImageMagick-7 (our policy), ...; its
#                                        shared libMagickCore-7.so and
#                                        libMagickWand-7.so in azsupport/lib, with
#                                        MagickWand-config (imagick links them
#                                        too), and its static libraries in
#                                        azsupport/static
#   GraphicsMagick graphics/GraphicsMagick
#                                        bin/gm, share/GraphicsMagick; its shared
#                                        libGraphicsMagick.so and
#                                        libGraphicsMagickWand.so in azsupport/lib, with
#                                        GraphicsMagick-config (gmagick links them
#                                        too), and its static libraries in
#                                        azsupport/static (lib/GraphicsMagick: the
#                                        configuration they read)
#                                        (added 08.11.2026, aZ: GraphicsMagick
#                                        built as our ImageMagick)
#   mc            misc/mc                bin/mc and its links, etc/mc, libexec/mc,
#                                        share/mc: GLib built static by
#                                        tools/mc-build.sh (only mc links it)
#                                        (added 10.11.2026, aZ)
#
# Our ports link each other's shared libraries (aZ, 10.11.2026): those of azsupport
# (with the run path /usr/local/azsupport/lib), of devel/pcre2 and devel/pcre, the
# libcurl.so.4 of ftp/curl; never a static or bundled copy of a library another of
# our ports has. The static tree is for PHP built on a server only
# (tools/azsupport-menu.sh of azsupport/php-src).
#
# The same packages as build-az.sh (the library package named az on 08.11.2026, azsupport
# since 25.11.2026, aZ: «надо бренд продвигать»): names, origins, epochs, files, comments, descriptions,
# maintainer, licences and the annotations cputype, freebsd_ports and
# built_by. Version: that of the official port at the commit of
# files/deps.conf (or of its take line: ImageMagick 7.1.2-35 is 7.1.2.35, as the
# ports write it) with the revision of the build as PORTREVISION (YYMMDDHH,
# UTC), so that a new build is an upgrade of the official package; azsupport: the
# date of its libraries (YYYYMMDD). The revision is AZSUPPORT_STAMP, the time of the
# run, given by the builder, which decides what to rebuild by the annotation
# azsupport_hash (Mk/bsd.overlay.mk).
# PREFIX stays /usr/local (the plist of azsupport names
# azsupport/lib/...): with PREFIX=/usr/local/azsupport the framework would move
# azsupport/lib/pkgconfig/*.pc to libdata/pkgconfig (fixup-lib-pkgconfig).
#
# How (the simplest faithful way): each port runs the tested build script of
# php-src, moved into tools/ of this tree, with its conf and patches in files/
# of the port, rather than ~40 ports of libraries now:
#   azsupport/azsupport                  tools/azsupport-build.sh (build-deps.sh),
#                          tools/azsupport-curl-sources.sh (curl-sources.sh),
#                          tools/azsupport-check-links.py; files/deps.conf,
#                          files/curl.conf, files/curl-deps.conf, files/curl/,
#                          files/deps/
#   ftp/curl               tools/curl-build.sh (build_curl_program of
#                          build-deps.sh)
#   multimedia/ffmpeg      tools/ffmpeg-build.sh, files/ffmpeg.conf,
#                          files/ffmpeg/*.patch
#   graphics/ImageMagick6  tools/imagemagick-build.sh, one ImageMagick per run;
#   graphics/ImageMagick7  ImageMagick7/files/imagemagick.conf and policy.xml
#                          (one copy for both), the patches in files/ of each
#   graphics/GraphicsMagick
#                          tools/graphicsmagick-build.sh, files/graphicsmagick.conf
#                          (the coders it registers: GraphicsMagick has no policy),
#                          files/delegates.mgk (none)
#   misc/mc                tools/mc-build.sh, files/mc.conf, files/ubsdtar,
#                          files/archives-bsdtar.patch
# A library is still the official port of the pinned commit: its distfiles,
# distinfo and patches (make patch in ${PORTSDIR}/<origin>, with our
# WRKDIRPREFIX), then configured and built by the script with its own options.
# The official tree of the build has to be that commit (PORTSDIR); the scripts
# no longer check out a tree of their own.
#
# Staging. azsupport is built with the paths it has on the servers: its ~40 builds
# find each other in /usr/local/azsupport/static and /usr/local/azsupport (their .pc files,
# *-config scripts, run paths and compiled-in paths name them), so the script
# installs into /usr/local/azsupport of the build machine, as build-az.sh did in its
# VM, and do-install copies that tree into ${STAGEDIR}; the plist is made from
# the stage. So this port is built as root (NEED_ROOT: poudriere builds it as
# root even with BUILD_AS_NON_ROOT=yes; make package as root), on a machine or
# in a jail of its own: the script does
# not start while a package or a PHP build has files in /usr/local/azsupport, and
# removes there only what an unfinished build of its own left (marked by the
# file .az-build, which is not packaged). The other four install with DESTDIR
# into a stage in ${WRKDIR}, against the installed package azsupport, and copy it
# into ${STAGEDIR}: they write nothing outside their WRKDIR.
#
# Dependencies on our packages: on azsupport by a file, never LIB_DEPENDS (no ldconfig
# hints for /usr/local/azsupport/lib); on pcre2, pcre and curl (in /usr/local/lib)
# LIB_DEPENDS. curl, ffmpeg, ImageMagick6 and mc: the shared tree to build and to
# run. ImageMagick7 and GraphicsMagick: the static and the shared tree to build,
# the shared tree to run. The PHP ports: azsupport, ImageMagick7 (lib/libMagickWand-7.so,
# for imagick), GraphicsMagick (lib/libGraphicsMagickWand.so, for gmagick), pcre2
# or pcre (the core) and curl (the module curl). Build order: azsupport, pcre2, pcre;
# then curl, ffmpeg, ImageMagick6, ImageMagick7, GraphicsMagick (any order); then
# PHP.
#
# Distfiles: all of them in the fetch phase, so that the build needs no network
# (poudriere has none there; the VM of CI reaches GitHub badly, which is why
# php-src fetched the take files on the runner, tools/take-fetch.sh). The release
# files the scripts take themselves (the take lines; the bundled curl and its
# libraries of curl.conf and curl-deps.conf) are DISTFILES of the port, in
# DISTDIR/azsupport under the names the scripts look for, with a distinfo (the SHA-256
# of the confs, the sizes of the distinfo of the official ports); the
# distfiles of the official ports of the libraries are fetched by their own make
# fetch into ${DISTDIR} (post-fetch: azsupport-build.sh --fetch) and checked against
# their own distinfo by their make patch in the build. A file not in DISTDIR
# is still fetched by the script (a build outside the framework).
#
# Tests (tools/*-test.sh of php-src, moved): not part of make package; they
# test the installed packages, with samples made by the official packages
# before ours are installed (the builder runs them, tools/azsupport-test.sh the link
# tests of build-az.sh).

PORTNAME=	azsupport
PORTVERSION=	20261108
CATEGORIES=	azsupport devel
MASTER_SITES=	https://github.com/curl/curl/releases/download/curl-8_23_0/:curl \
		https://github.com/c-ares/c-ares/releases/download/v1.34.9/:cares \
		https://github.com/nghttp2/nghttp2/releases/download/v1.71.0/:nghttp2 \
		https://codeload.github.com/google/brotli/tar.gz/v1.2.1?dummy=/:brotli \
		https://github.com/facebook/zstd/releases/download/v1.6.0/:zstd \
		GNU/libidn:libidn2 \
		https://github.com/rockdaboot/libpsl/releases/download/0.23.3/:libpsl \
		https://github.com/libssh2/libssh2/releases/download/libssh2-1.11.1/:libssh2 \
		https://codeload.github.com/publicsuffix/list/tar.gz/73f8cc7?dummy=/:psllist \
		https://github.com/strukturag/libde265/releases/download/v1.1.3/:libde265 \
		https://github.com/libffi/libffi/releases/download/v3.8.1/:libffi \
		https://github.com/fmtlib/fmt/releases/download/12.2.1/:fmt \
		https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/2.18.4/:fontconfig \
		https://code.videolan.org/videolan/dav1d/-/archive/1.5.5/:dav1d \
		https://download.savannah.gnu.org/releases/freetype/:freetype \
		https://downloads.sourceforge.net/project/freetype/freetype2/2.15.0/:freetype \
		https://dist.libuv.org/dist/v1.53.0/:libuv
# The names are those tools/azsupport-curl-sources.sh keeps them under (the distfile of
# curl-deps.conf, / made _) and the take lines of files/deps.conf give.
DISTFILES=	curl-8.23.0.tar.xz:curl \
		c-ares-1.34.9.tar.gz:cares \
		nghttp2-1.71.0.tar.xz:nghttp2 \
		brotli_1.2.1_google-brotli-v1.2.1_GH0.tar.gz:brotli \
		zstd-1.6.0.tar.zst:zstd \
		libidn2-2.3.8.tar.gz:libidn2 \
		libpsl-0.23.3.tar.lz:libpsl \
		libssh2-1.11.1.tar.xz:libssh2 \
		publicsuffix-list-20261031-73f8cc7_GH0.tar.gz:psllist \
		libde265-1.1.3.tar.gz:libde265 \
		libffi-3.8.1.tar.gz:libffi \
		fmt-12.2.1.zip:fmt \
		fontconfig-2.18.4.tar.xz:fontconfig \
		dav1d-1.5.5.tar.bz2:dav1d \
		freetype-2.15.0.tar.xz:freetype \
		libuv-v1.53.0-dist.tar.gz:libuv

COMMENT=	Static and shared libraries of /usr/local/azsupport, for PHP and the programs
WWW=		https://github.com/azsupport/ports

# As build-az.sh: one licence name for the licences of all the libraries
LICENSE=	MULTI
LICENSE_NAME=	The licences of the libraries of /usr/local/azsupport
LICENSE_TEXT=	The licences of the libraries are in /usr/local/azsupport/LICENSES
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# The build tools of tools/azsupport-build.sh --tools (git only checks the commit of
# PORTSDIR, when it is there); libtool for the autoreconf -fi of gd (USES=autoreconf
# brings autoconf and automake, libtoolize only with USES=libtool)
BUILD_DEPENDS=	bison:devel/bison \
		cmake:devel/cmake-core \
		gperf:devel/gperf \
		libtoolize:devel/libtool \
		lzip:archivers/lzip \
		meson:devel/meson \
		msgfmt:devel/gettext-tools \
		nasm:devel/nasm \
		ninja:devel/ninja \
		python3:lang/python3 \
		tclsh8.6:lang/tcl86
# libimagequant of graphics/libimagequant for gd (LIQ: the palette of imagegif() and
# imagetruecolortopalette() of PHP; aZ, 11.11.2026): the one library of a port of
# this tree in azsupport, linked (libgd.so takes libimagequant.so of /usr/local/lib; the
# static tree links to its archive), to build and to run. GPLv3 or later.
LIB_DEPENDS=	libimagequant.so:graphics/libimagequant
# GCC of the packages for the shared libraries of AZSUPPORT_GCC_SO of tools/azsupport-build.sh
# (sqlite3, expat, lcms2: at least 2% faster with it, tools/lib-bench.sh); a build
# dependency only, nothing of it at run time (-static-libgcc)
BUILD_DEPENDS+=	gcc16:lang/gcc16

USES=		autoreconf:build gmake perl5 pkgconfig
USE_PERL5=	build

# The build installs into AZSUPPORT_PREFIX of the build machine (see the head)
NEED_ROOT=	yes

# Nothing is extracted by the framework: tools/azsupport-curl-sources.sh unpacks the
# bundled curl, the official ports extract their own distfiles (make patch).
NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR}/Makefile.common"

post-fetch:
	@${SETENV} ${AZSUPPORT_ENV} AZSUPPORT_FILESDIR=${FILESDIR} ${SH} ${AZSUPPORT_TOOLS}/azsupport-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZSUPPORT_ENV} AZSUPPORT_FILESDIR=${FILESDIR} \
		CURL_DISTFILES=${DISTDIR}/${DIST_SUBDIR} ${SH} ${AZSUPPORT_TOOLS}/azsupport-build.sh

# the tree the build left in AZSUPPORT_PREFIX, without the mark of the build; its programs and
# shared libraries stripped (no debug in our packages, aZ 17.11.2026: the build copies
# them as they were linked; the static libraries keep their symbols)
do-install:
	@${MKDIR} ${STAGEDIR}${AZSUPPORT_PREFIX}
	(cd ${AZSUPPORT_PREFIX} && ${TAR} -cf - .) | (cd ${STAGEDIR}${AZSUPPORT_PREFIX} && ${TAR} -xpf -)
	${RM} ${STAGEDIR}${AZSUPPORT_PREFIX}/.az-build
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${AZSUPPORT_TOOLS}/strip-elf.sh ${STAGEDIR}${AZSUPPORT_PREFIX}

# the trigger of pkg that names the services of the packages of a transaction to restart
# (files/azsupport-services.ucl; Mk/bsd.overlay.mk gives the packages their directories
# share/azsupport/services/<service>)
post-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/pkg/triggers
	${INSTALL_DATA} ${FILESDIR}/azsupport-services.ucl ${STAGEDIR}${PREFIX}/share/pkg/triggers
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
