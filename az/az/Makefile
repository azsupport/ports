# az/az: the libraries of /usr/local/az (the package az).
#
# DESIGN of the ports that take over the builds of tools/build-az.sh of
# https://github.com/azsupport/php-src (08.11.2026, aZ: the development of
# these packages moves into this tree):
#
#   package       origin                 files
#   az            az/az                  /usr/local/az: the static tree
#                                        static/{lib,include,bin} and the shared
#                                        tree lib/ (SONAME, run path
#                                        /usr/local/az/lib, no ldconfig),
#                                        include/, lib/pkgconfig/, bin/pkg-config,
#                                        share/doc/az/VERSIONS, LICENSES/
#   curl          ftp/curl               bin/curl (static), lib/libcurl.so.4
#                                        (only curl_* exported), include/curl...
#   ffmpeg        multimedia/ffmpeg      bin/ffmpeg, bin/ffprobe (static)
#   ImageMagick6  graphics/ImageMagick6  bin/*6, etc/ImageMagick-6 (our policy),
#                                        share/ImageMagick-6, lib/ImageMagick-6.*
#   ImageMagick7  graphics/ImageMagick7  bin/magick and its links,
#                                        etc/ImageMagick-7 (our policy), ...; its
#                                        static libraries in az/static and the
#                                        shared libMagickWand-7.so in az/lib,
#                                        with MagickWand-config
#   GraphicsMagick graphics/GraphicsMagick
#                                        bin/gm, lib/GraphicsMagick,
#                                        share/GraphicsMagick; its static
#                                        libraries in az/static and the shared
#                                        libGraphicsMagick.so and
#                                        libGraphicsMagickWand.so in az/lib, with
#                                        GraphicsMagick-config, for gmagick
#                                        (added 08.11.2026, aZ: GraphicsMagick
#                                        built as our ImageMagick)
#
# The same packages as build-az.sh (the library package named az now, aZ
# 08.11.2026): names, origins, epochs, files, comments, descriptions,
# maintainer, licences and the annotations cputype, freebsd_ports and
# built_by. Version: that of the official port at the commit of
# files/deps.conf (or of its take line: ImageMagick 7.1.2-35 is 7.1.2.35, as the
# ports write it) with the revision of the build as PORTREVISION (YYMMDDHH,
# UTC), so that a new build is an upgrade of the official package; az: the
# date of its libraries (YYYYMMDD). The revision is AZ_STAMP, the time of the
# run, given by the builder, which decides what to rebuild by the annotation
# az_hash (Mk/bsd.overlay.mk).
# PREFIX stays /usr/local (the plist of az names
# az/lib/...): with PREFIX=/usr/local/az the framework would move
# az/lib/pkgconfig/*.pc to libdata/pkgconfig (fixup-lib-pkgconfig).
#
# How (the simplest faithful way): each port runs the tested build script of
# php-src, moved into tools/ of this tree, with its conf and patches in files/
# of the port, rather than ~40 ports of libraries now:
#   az/az                  tools/az-build.sh (build-deps.sh),
#                          tools/az-curl-sources.sh (curl-sources.sh),
#                          tools/az-check-links.py; files/deps.conf,
#                          files/curl.conf, files/curl-deps.conf, files/curl/,
#                          files/deps/
#   ftp/curl               tools/curl-build.sh (build_curl_program of
#                          build-deps.sh), tools/curl-elf-export.py
#   multimedia/ffmpeg      tools/ffmpeg-build.sh, files/ffmpeg.conf,
#                          files/ffmpeg/*.patch
#   graphics/ImageMagick6  tools/imagemagick-build.sh, one ImageMagick per run;
#   graphics/ImageMagick7  ImageMagick7/files/imagemagick.conf and policy.xml
#                          (one copy for both), the patches in files/ of each
#   graphics/GraphicsMagick
#                          tools/graphicsmagick-build.sh, files/graphicsmagick.conf
#                          (the coders it registers: GraphicsMagick has no policy),
#                          files/delegates.mgk (none)
# A library is still the official port of the pinned commit: its distfiles,
# distinfo and patches (make patch in ${PORTSDIR}/<origin>, with our
# WRKDIRPREFIX), then configured and built by the script with its own options.
# The official tree of the build has to be that commit (PORTSDIR); the scripts
# no longer check out a tree of their own.
#
# Staging. az is built with the paths it has on the servers: its ~40 builds
# find each other in /usr/local/az/static and /usr/local/az (their .pc files,
# *-config scripts, run paths and compiled-in paths name them), so the script
# installs into /usr/local/az of the build machine, as build-az.sh did in its
# VM, and do-install copies that tree into ${STAGEDIR}; the plist is made from
# the stage. So this port is built as root (NEED_ROOT: poudriere builds it as
# root even with BUILD_AS_NON_ROOT=yes; make package as root), on a machine or
# in a jail of its own: the script does
# not start while a package or a PHP build has files in /usr/local/az, and
# removes there only what an unfinished build of its own left (marked by the
# file .az-build, which is not packaged). The other four install with DESTDIR
# into a stage in ${WRKDIR}, against the installed package az, and copy it
# into ${STAGEDIR}: they write nothing outside their WRKDIR.
#
# Dependencies on our packages: by a file, never LIB_DEPENDS (no ldconfig
# hints). curl, ffmpeg and ImageMagick6: BUILD_DEPENDS on the static tree only
# (static programs: no RUN_DEPENDS, as in build-az.sh). ImageMagick7 and
# GraphicsMagick: the static and the shared tree to build, the shared tree to
# run (their libMagickWand-7.so and libGraphicsMagickWand.so link the shared
# libraries of az). The PHP ports: az, ImageMagick7 (lib/libMagickWand-7.so, for
# imagick) and GraphicsMagick (lib/libGraphicsMagickWand.so, for gmagick). Build
# order: az; then curl, ffmpeg, ImageMagick6, ImageMagick7, GraphicsMagick (any
# order); then PHP.
#
# Distfiles: all of them in the fetch phase, so that the build needs no network
# (poudriere has none there; the VM of CI reaches GitHub badly, which is why
# php-src fetched the take files on the runner, tools/take-fetch.sh). The release
# files the scripts take themselves (the take lines; the bundled curl and its
# libraries of curl.conf and curl-deps.conf) are DISTFILES of the port, in
# DISTDIR/az under the names the scripts look for, with a distinfo (the SHA-256
# of the confs, the sizes of the distinfo of the official ports); the
# distfiles of the official ports of the libraries are fetched by their own make
# fetch into ${DISTDIR} (post-fetch: az-build.sh --fetch) and checked against
# their own distinfo by their make patch in the build. A file not in DISTDIR
# is still fetched by the script (a build outside the framework).
#
# Tests (tools/*-test.sh of php-src, moved): not part of make package; they
# test the installed packages, with samples made by the official packages
# before ours are installed (the builder runs them, tools/az-test.sh the link
# tests of build-az.sh).

PORTNAME=	az
PORTVERSION=	20261108
CATEGORIES=	az devel
MASTER_SITES=	https://github.com/curl/curl/releases/download/curl-8_23_0/:curl \
		https://github.com/c-ares/c-ares/releases/download/v1.34.9/:cares \
		https://github.com/nghttp2/nghttp2/releases/download/v1.70.0/:nghttp2 \
		https://codeload.github.com/google/brotli/tar.gz/v1.2.1?dummy=/:brotli \
		https://github.com/facebook/zstd/releases/download/v1.5.7/:zstd \
		GNU/libidn:libidn2 \
		https://github.com/rockdaboot/libpsl/releases/download/0.23.3/:libpsl \
		https://codeload.github.com/publicsuffix/list/tar.gz/728555a?dummy=/:psllist \
		https://github.com/strukturag/libheif/releases/download/v1.23.7/:libheif \
		https://github.com/strukturag/libde265/releases/download/v1.1.3/:libde265
# The names are those tools/az-curl-sources.sh keeps them under (the distfile of
# curl-deps.conf, / made _) and the take lines of files/deps.conf give.
DISTFILES=	curl-8.23.0.tar.xz:curl \
		c-ares-1.34.9.tar.gz:cares \
		nghttp2-1.70.0.tar.xz:nghttp2 \
		brotli_1.2.1_google-brotli-v1.2.1_GH0.tar.gz:brotli \
		zstd-1.5.7.tar.zst:zstd \
		libidn2-2.3.8.tar.gz:libidn2 \
		libpsl-0.23.3.tar.lz:libpsl \
		publicsuffix-list-20260921-728555a_GH0.tar.gz:psllist \
		libheif-1.23.7.tar.gz:libheif \
		libde265-1.1.3.tar.gz:libde265

COMMENT=	Static and shared libraries of /usr/local/az, for PHP and the programs
WWW=		https://github.com/azsupport/ports

# As build-az.sh: one licence name for the licences of all the libraries
LICENSE=	MULTI
LICENSE_NAME=	The licences of the libraries of /usr/local/az
LICENSE_TEXT=	The licences of the libraries are in /usr/local/az/LICENSES
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

# The build tools of tools/az-build.sh --tools (git only checks the commit of
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

USES=		autoreconf:build gmake perl5 pkgconfig
USE_PERL5=	build

# The build installs into AZ_PREFIX of the build machine (see the head)
NEED_ROOT=	yes

# Nothing is extracted by the framework: tools/az-curl-sources.sh unpacks the
# bundled curl, the official ports extract their own distfiles (make patch).
NO_WRKSUBDIR=	yes
EXTRACT_ONLY=

.include "${.CURDIR}/Makefile.common"

post-fetch:
	@${SETENV} ${AZ_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/az-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} AZ_FILESDIR=${FILESDIR} \
		CURL_DISTFILES=${DISTDIR}/${DIST_SUBDIR} ${SH} ${AZ_TOOLS}/az-build.sh

# the tree the build left in AZ_PREFIX, without the mark of the build
do-install:
	@${MKDIR} ${STAGEDIR}${AZ_PREFIX}
	(cd ${AZ_PREFIX} && ${TAR} -cf - .) | (cd ${STAGEDIR}${AZ_PREFIX} && ${TAR} -xpf -)
	${RM} ${STAGEDIR}${AZ_PREFIX}/.az-build

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
