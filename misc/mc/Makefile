# misc/mc: the Midnight Commander of azsupport/ports in the place of the official
# misc/mc (aZ, 10.11.2026), the package mc: the official port of the pinned commit
# (its distfile, distinfo and patches; make patch in the official tree) built by
# tools/mc-build.sh with the configure lines of files/mc.conf (what is on and off,
# and why), against the shared libraries of our ports (aZ, 10.11.2026: our ports
# link each other's shared libraries): GLib of devel/glib20 (mc had a static GLib of
# its own before 11.11.2026) and libssh2 of az (with the OpenSSL of the base
# system), with the run path /usr/local/az/lib. So mc needs the packages az and glib
# (with pcre2) at run time (the official one needs glib with Python, libssh2,
# gettext-runtime, libiconv, pcre2, libffi, zip, Perl and Python) and libraries of
# the base system (ncursesw, libutil, libz, libcrypto). zip, jar, 7z, rar and
# ISO 9660 open with files/ubsdtar (tar of the base system) after
# files/archives-bsdtar.patch, the names of a zip of Windows (not UTF-8) in CP866; Perl, Python, zip and GNU diff are no dependencies
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

# the shared tree of az (libssh2) and GLib of devel/glib20, to build and to run; the
# tools of the build of mc (gmake, Perl for its help file)
RUN_DEPENDS=	${AZ_PREFIX}/lib/libssh2.so:az/az
LIB_DEPENDS=	libglib-2.0.so:devel/glib20
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libssh2.so:az/az

USES=		gmake perl5 pkgconfig
USE_PERL5=	build

CONFLICTS_INSTALL=	mc6

NO_WRKSUBDIR=	yes

# the version of the official port the script builds, which has to be this one
AZ_MC_ENV=	AZ_MC_VERSION=${DISTVERSION}

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
