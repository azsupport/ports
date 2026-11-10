# misc/mc: the Midnight Commander of azsupport/ports in the place of the official
# misc/mc (aZ, 10.11.2026), the package mc: the official port of the pinned commit
# (its distfile, distinfo and patches; make patch in the official tree) built by
# tools/mc-build.sh with the configure lines of files/mc.conf (what is on and off,
# and why), and with GLib linked in: devel/glib20 (and devel/libffi for its build)
# of the same commit built static by the script (only mc links GLib), against the
# shared libraries of our other ports: libintl and libiconv of the package az and
# libpcre2-8.so of devel/pcre2; mc links libssh2 of az too (with the OpenSSL of the
# base system), with the run path /usr/local/az/lib (our ports link each other's
# shared libraries: aZ, 10.11.2026). So mc needs the packages az and pcre2 at run
# time (the official one needs glib with Python, libssh2, gettext-runtime,
# libiconv, pcre2, libffi, zip, Perl and Python) and libraries of the base system
# (ncursesw, libutil, libz, libcrypto). zip, jar, 7z, rar and
# ISO 9660 open with files/ubsdtar (tar of the base system) after
# files/archives-bsdtar.patch; Perl, Python, zip and GNU diff are no dependencies
# (files/mc.conf: what each of them still gives when it is installed).

PORTNAME=	mc
DISTVERSION=	4.8.33
CATEGORIES=	misc shells
# the distfiles are those of the official ports (their make fetch in post-fetch)
DISTFILES=

COMMENT=	Midnight Commander, a free Norton Commander clone (of azsupport/ports)
WWW=		https://midnight-commander.org/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv3+

# the shared tree of az (libssh2; libintl and libiconv for GLib) and PCRE2 of
# devel/pcre2, to build and to run; the tools of the builds of GLib (meson, and
# Python with packaging for its gdbus-codegen, as devel/glib20) and mc (gmake, Perl
# for its help file)
RUN_DEPENDS=	${AZ_PREFIX}/lib/libssh2.so:az/az
LIB_DEPENDS=	libpcre2-8.so:devel/pcre2
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libssh2.so:az/az \
		${PYTHON_PKGNAMEPREFIX}packaging>0:devel/py-packaging@${PY_FLAVOR} \
		meson:devel/meson \
		ninja:devel/ninja

USES=		gmake perl5 pkgconfig python:build
USE_PERL5=	build

CONFLICTS_INSTALL=	mc6

NO_WRKSUBDIR=	yes

# the version of the official port the script builds, which has to be this one; the
# Python of the port for the scripts of GLib that run by #!/usr/bin/env python3
# (devel/glib20: BINARY_ALIAS=python3=${PYTHON_CMD})
AZ_MC_ENV=	AZ_MC_VERSION=${DISTVERSION} AZ_PYTHON=${PYTHON_CMD}

.include "${.CURDIR:H:H}/az/az/Makefile.common"

post-fetch:
	@${SETENV} ${AZ_ENV} ${AZ_MC_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/mc-build.sh --fetch

do-build:
	@cd ${WRKDIR} && ${SETENV} ${AZ_ENV} ${AZ_MC_ENV} AZ_FILESDIR=${FILESDIR} ${SH} ${AZ_TOOLS}/mc-build.sh

do-install:
	@${AZ_COPY_STAGE}

post-install:
	@${AZ_PLIST}

.include <bsd.port.mk>
