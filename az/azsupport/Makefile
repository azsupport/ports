# az/azsupport: the libraries of /usr/local/azsupport (the package azsupport).
#
# DESIGN of the five ports that take over the builds of tools/build-az.sh of
# https://github.com/azsupport/php-src (08.11.2026, aZ: the development of
# these packages moves into this tree):
#
#   package       origin                 files
#   azsupport     az/azsupport           /usr/local/azsupport: the static tree
#                                        static/{lib,include,bin} and the shared
#                                        tree lib/ (SONAME, run path
#                                        /usr/local/azsupport/lib, no ldconfig),
#                                        include/, lib/pkgconfig/, bin/pkg-config,
#                                        share/doc/azsupport/VERSIONS, LICENSES/
#   curl          ftp/curl               bin/curl (static), lib/libcurl.so.4
#                                        (only curl_* exported), include/curl...
#   ffmpeg        multimedia/ffmpeg      bin/ffmpeg, bin/ffprobe (static)
#   ImageMagick6  graphics/ImageMagick6  bin/*6, etc/ImageMagick-6 (our policy),
#                                        share/ImageMagick-6, lib/ImageMagick-6.*
#   ImageMagick7  graphics/ImageMagick7  bin/magick and its links,
#                                        etc/ImageMagick-7 (our policy), ...; its
#                                        static libraries in azsupport/static and
#                                        the shared libMagickWand-7.so in
#                                        azsupport/lib, with MagickWand-config
#
# The same packages as build-az.sh: names, origins, epochs, files, comments,
# descriptions, maintainer and the annotations cputype, freebsd_ports and
# built_by. Version: that of the official port at the commit of
# files/deps.conf (or of its take line) with the revision of the build as
# PORTREVISION (YYMMDDHH, UTC), so that a new build is an upgrade of the
# official package; azsupport: the date of its libraries (YYYYMMDD).
# The revision is AZ_STAMP: a value written into the Makefile at each change
# of the port (the time of that change), so that the same tree gives the same
# version and the builder can skip a package it has (as poudriere does); the
# builder may set AZ_STAMP to force a new version. A port built against
# another of ours (all four against azsupport) gets a new revision with it.
#
# How (the simplest faithful way): each port runs the tested build script of
# php-src, moved into tools/ of this tree, with its conf and patches in files/
# of the port, rather than ~40 ports of libraries now:
#   az/azsupport           tools/azsupport-build.sh (build-deps.sh),
#                          tools/azsupport-curl-sources.sh (curl-sources.sh),
#                          tools/azsupport-check-links.py; files/deps.conf,
#                          files/curl.conf, files/curl-deps.conf, files/curl/,
#                          files/deps/
#   ftp/curl               tools/curl-build.sh (build_curl_program of
#                          build-deps.sh), tools/curl-elf-export.py
#   multimedia/ffmpeg      tools/ffmpeg-build.sh, files/ffmpeg.conf,
#                          files/ffmpeg/*.patch
#   graphics/ImageMagick6  tools/imagemagick-build.sh, one ImageMagick per run;
#   graphics/ImageMagick7  ImageMagick7/files/imagemagick.conf, policy.xml and
#                          the patches (one copy for both)
# A library is still the official port of the pinned commit: its distfiles,
# distinfo and patches (make patch in ${PORTSDIR}/<origin>, with our
# WRKDIRPREFIX), then configured and built by the script with its own options.
# The official tree of the build is that commit (PORTSDIR); the scripts do not
# check out a tree of their own any more (and never remove PORTSDIR).
#
# Staging. azsupport is built with the paths it has on the servers: its ~40
# builds find each other in /usr/local/azsupport/static and /usr/local/azsupport
# (their .pc files, *-config scripts, run paths and compiled-in paths name
# them), so the script installs into /usr/local/azsupport of the build machine
# as build-az.sh did in its VM, and do-install copies that tree into
# ${STAGEDIR}; the plist is made from the stage. So this port is built as root
# on a machine or in a jail of its own (NEED_ROOT): it does not start while a
# package has files in /usr/local/azsupport, and removes there only what an
# unfinished build of its own left (marked by the file .az-build). The other
# four install with DESTDIR into a stage in ${WRKDIR}, against the installed
# package azsupport, and copy it into ${STAGEDIR}: they write nothing outside
# their WRKDIR.
#
# Dependencies on our packages: by a file, never LIB_DEPENDS (no ldconfig
# hints). curl, ffmpeg and ImageMagick6: BUILD_DEPENDS on the static tree only
# (static programs: no RUN_DEPENDS, as in build-az.sh). ImageMagick7: the static
# and the shared tree to build, the shared tree to run (its libMagickWand-7.so
# links the shared libraries of azsupport). The PHP ports: azsupport and
# ImageMagick7 (lib/libMagickWand-7.so, for imagick). Build order: azsupport;
# then curl, ffmpeg, ImageMagick6, ImageMagick7 (any order); then PHP.
#
# Distfiles: all of them in the fetch phase, so that the build needs no network
# (poudriere has none there; the VM of CI reaches GitHub badly, which is why
# php-src fetched the take files on the runner, tools/take-fetch.sh). The release
# files the scripts take themselves (the take lines; the bundled curl and its
# libraries of curl.conf and curl-deps.conf) are DISTFILES of the port with a
# distinfo (from the SHA-256 of the confs); the distfiles of the official ports
# of the libraries are fetched by their own make fetch into ${DISTDIR}
# (post-fetch) and checked against their own distinfo by their make patch in
# the build. A file not in ${DISTDIR} is still fetched by the script (a build
# outside the framework).
#
# Tests (tools/<name>-test.sh of php-src, moved): not part of make package;
# they test the installed packages, with samples made by the official
# packages before ours are installed (the builder runs them).

PORTNAME=	azsupport
PORTVERSION=	20261108
CATEGORIES=	az devel

MAINTAINER=	github@azsupport.com
COMMENT=	Static and shared libraries of /usr/local/azsupport, for PHP and the programs

IGNORE=		is being written (p4, 08.11.2026): the design above, the build not wired yet

.include <bsd.port.mk>
