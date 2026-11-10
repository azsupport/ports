# misc/mc: the Midnight Commander of azsupport/ports in the place of the official
# misc/mc (aZ, 10.11.2026), the package mc: the official port of the pinned commit
# (its distfile, distinfo and patches; make patch in the official tree) built by
# tools/mc-build.sh with the configure lines of files/mc.conf (what is on and off,
# and why), and with GLib and libssh2 linked in: devel/glib20 (and devel/libffi for
# its build) of the same commit built static by the script, against PCRE2, libintl
# and libiconv of the static tree of the package az, and libssh2 of that tree (with
# the OpenSSL of the base system). So mc needs no package at run time (the official one needs glib with
# Python, libssh2, gettext-runtime, libiconv, pcre2, libffi, zip, Perl and Python),
# only libraries of the base system (ncursesw, libutil, libz, libcrypto). zip, jar, 7z, rar and
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

# the static tree of az (libssh2, PCRE2, libintl and libiconv for
# GLib: a build dependency only, nothing of az at run time); the tools of the builds
# of GLib (meson, and Python with packaging for its gdbus-codegen, as devel/glib20)
# and mc (gmake, Perl for its help file)
BUILD_DEPENDS=	${AZ_STATIC}/lib/libssh2.a:az/az \
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
