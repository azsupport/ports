# azsupport/azsupport: the static libraries of /usr/local/azsupport/static (the package
# azsupport), and the head of the design of the ports of this tree that build the
# libraries of azsupport and the programs.
#
# DESIGN of the ports that take over the builds of tools/build-az.sh of
# https://github.com/azsupport/php-src (08.11.2026, aZ: the development of
# these packages moves into this tree), every library of the shared tree a port of
# its own since 27.11.2026 (aZ, 26.11.2026: «да», «ну так чего потом уж, делай
# сразу»):
#
#   package       origin                 files
#   azsupport     azsupport/azsupport    /usr/local/azsupport/static: the static tree
#                                        static/{lib,include,bin}, for PHP built on a
#                                        server (tools/azsupport-ports.sh of
#                                        azsupport/php-src), its manifests in
#                                        static/share/azsupport/interface/, its
#                                        licences in static/LICENSES/;
#                                        share/doc/azsupport/VERSIONS (its path and
#                                        first line are those the fork reads)
#   azsupport-<lib>  azsupport/<lib>     a library of the shared tree, one for each lib
#                                        line of the kind shared of files/deps.conf
#                                        (45; tools/azsupport-lib-ports.sh makes them,
#                                        Makefile.lib): its lib/*.so (SONAME, run path
#                                        /usr/local/azsupport/lib, no ldconfig),
#                                        include/, lib/pkgconfig/, *-config scripts,
#                                        LICENSES/<lib>-*, its manifest
#                                        share/azsupport/interface/<lib>.txt,
#                                        share/doc/azsupport-<lib>/VERSIONS
#   azsupport-services  azsupport/services
#                                        the trigger of pkg that names the services
#                                        to restart (share/pkg/triggers/
#                                        azsupport-services.ucl)
#   fontconfig    x11-fonts/fontconfig   the official port at the release of the take
#                                        line of fontconfig, in /usr/local, on the
#                                        shared expat and freetype2 of azsupport, with
#                                        its manifest (prefix /usr/local)
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
# Our ports link each other's shared libraries (aZ, 10.11.2026): those of the library
# ports (with the run path /usr/local/azsupport/lib), of devel/pcre2 and devel/pcre,
# the libcurl.so.4 of ftp/curl; never a static or bundled copy of a library another of
# our ports has. The static tree is for PHP built on a server only
# (tools/azsupport-ports.sh of azsupport/php-src).
#
# The same packages as build-az.sh (the library package named az on 08.11.2026, azsupport
# since 25.11.2026, aZ: «надо бренд продвигать»): names, origins, epochs, files, comments, descriptions,
# maintainer, licences and the annotations cputype, freebsd_ports and
# built_by. Version: that of the official port at the commit of
# files/deps.conf (or of its take line: ImageMagick 7.1.2-35 is 7.1.2.35, as the
# ports write it) with the revision of the build as PORTREVISION (YYMMDDHH,
# UTC), so that a new build is an upgrade of the official package; azsupport: the
# date of its libraries (YYYYMMDD; 20261127 the first build of the static tree alone,
# above 20261108 of the package that had both trees). The revision is AZSUPPORT_STAMP, the time of the
# run, given by the builder, which decides what to rebuild by the annotation
# azsupport_hash (Mk/bsd.overlay.mk).
# PREFIX stays /usr/local (the plists name
# azsupport/lib/...): with PREFIX=/usr/local/azsupport the framework would move
# azsupport/lib/pkgconfig/*.pc to libdata/pkgconfig (fixup-lib-pkgconfig).
#
# How (the simplest faithful way): each port runs the tested build script of
# php-src, moved into tools/ of this tree, with its conf and patches in files/
# of the port:
#   azsupport/azsupport    tools/azsupport-build.sh --static (build-deps.sh),
#                          tools/azsupport-curl-sources.sh (curl-sources.sh),
#                          tools/azsupport-check-links.py; files/deps.conf,
#                          files/curl.conf, files/curl-deps.conf, files/curl/,
#                          files/deps/
#   azsupport/<lib>        tools/azsupport-build.sh --lib <lib> (Makefile.lib), with
#                          its lines of the confs and its files of files/ here, which
#                          its Makefile names and its build checks
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
# Staging. The libraries are built with the paths they have on the servers: their
# builds find each other in /usr/local/azsupport/static and /usr/local/azsupport (their
# .pc files, *-config scripts, run paths and compiled-in paths name them), so the
# script installs into /usr/local/azsupport of the build machine, as build-az.sh did in
# its VM: this port the static tree (every library of the kind static in one build) and
# share/doc/azsupport/VERSIONS, which do-install copies into ${STAGEDIR}; a library
# port its library, against the packages of the libraries of its needs line installed
# there, the files it installed copied into a stage in ${WRKDIR}. The plists are made
# from the stage. So these ports are built as root (NEED_ROOT: poudriere builds them as
# root even with BUILD_AS_NON_ROOT=yes; make package as root), on a machine or in a
# jail of their own: this script does not start while a package or a PHP build has files
# in /usr/local/azsupport, and removes there only what an unfinished build of its own
# left (marked by the file .az-build, which is not packaged); a library port not while
# its library is there. The programs install with DESTDIR into a stage in ${WRKDIR},
# against the installed library ports, and copy it into ${STAGEDIR}: they write nothing
# outside their WRKDIR.
#
# Dependencies on our libraries: on a library port by a file of it, to build and to run
# (${AZSUPPORT_PREFIX}/lib/<library>.so:azsupport/<lib>; Mk/azsupport-libs.mk), never
# LIB_DEPENDS (no ldconfig hints for /usr/local/azsupport/lib); on this port only to
# build against the static tree (a file of ${AZSUPPORT_STATIC}, AZSUPPORT_STATIC_LIBS);
# on pcre2, pcre and curl (in /usr/local/lib) LIB_DEPENDS. The builder folds into the
# hash of a port the interfaces of the libraries it uses (their manifests), not the
# hashes of their ports. Build order: azsupport and the library ports, pcre2, pcre;
# then curl, ffmpeg, ImageMagick6, ImageMagick7, GraphicsMagick (any order); then PHP.
#
# Distfiles: all of them in the fetch phase, so that the build needs no network
# (poudriere has none there; the VM of CI reaches GitHub badly, which is why
# php-src fetched the take files on the runner, tools/take-fetch.sh). The release
# files the scripts take themselves (the take lines of the libraries of the kind
# static; the bundled curl and its libraries of curl.conf and curl-deps.conf) are
# DISTFILES of this port (Makefile.distfiles, made by tools/azsupport-lib-ports.sh), in
# DISTDIR/azsupport under the names the scripts look for, with a distinfo (the SHA-256
# of the confs, the sizes of the distinfo files of this tree); those of a library
# port are its own; the distfiles of the official ports of the libraries are fetched
# by their own make fetch into ${DISTDIR} (post-fetch: azsupport-build.sh --fetch) and
# checked against their own distinfo by their make patch in the build. A file not in
# DISTDIR is still fetched by the script (a build outside the framework).
#
# Tests (tools/*-test.sh of php-src, moved): not part of make package; they
# test the installed packages, with samples made by the official packages
# before ours are installed (the builder runs them, tools/azsupport-test.sh the link
# tests of build-az.sh).

PORTNAME=	azsupport
PORTVERSION=	20261127
CATEGORIES=	azsupport devel
.include "${.CURDIR}/Makefile.distfiles"

COMMENT=	Static libraries of /usr/local/azsupport/static, for PHP built on a server
WWW=		https://github.com/azsupport/ports

# As build-az.sh: one licence name for the licences of all the libraries
LICENSE=	MULTI
LICENSE_NAME=	The licences of the libraries of /usr/local/azsupport/static
LICENSE_TEXT=	The licences of the libraries are in /usr/local/azsupport/static/LICENSES
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
# this tree in the static tree, linked (it links to its archive), to build and to run.
# GPLv3 or later.
LIB_DEPENDS=	libimagequant.so:graphics/libimagequant

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
		CURL_DISTFILES=${DISTDIR}/${DIST_SUBDIR} ${SH} ${AZSUPPORT_TOOLS}/azsupport-build.sh --static

# what the build left in AZSUPPORT_PREFIX: the static tree and VERSIONS (not the mark of the
# build); its programs and shared libraries stripped (no debug in our packages, aZ
# 17.11.2026; the static libraries keep their symbols)
do-install:
	@${MKDIR} ${STAGEDIR}${AZSUPPORT_PREFIX}
	(cd ${AZSUPPORT_PREFIX} && ${TAR} -cf - static share/doc/azsupport) | (cd ${STAGEDIR}${AZSUPPORT_PREFIX} && ${TAR} -xpf -)
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${AZSUPPORT_TOOLS}/strip-elf.sh ${STAGEDIR}${AZSUPPORT_PREFIX}

post-install:
	@${AZSUPPORT_PLIST}

.include <bsd.port.mk>
