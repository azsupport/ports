# www/py-yt-dlp-ejs: the yt-dlp-ejs of azsupport/ports in the place of the official
# www/py-yt-dlp-ejs, which builds the scripts with npm and rollup from a tarball of
# node_modules fetched on FreeBSD and takes www/deno to build them and to run them (deno
# builds V8 from its sources). aZ, 26.11.2026 13:40: the built scripts of the release of
# yt-dlp-ejs on PyPI, no deno; node24 of this tree runs them. The release has two files
# there: the sdist (yt_dlp_ejs-<version>.tar.gz), the TypeScript sources alone, which its
# build bundles with deno, npm or bun, and the wheel (yt_dlp_ejs-<version>-py3-none-any.whl)
# with the scripts built, yt_dlp_ejs/yt/solver/core.min.js and lib.min.js: this port
# installs the wheel as it is (as the official misc/py-aistudio-sdk), from its path on
# PyPI that names the file alone (py3/y/yt_dlp_ejs/, which PyPI sends on to the file).
# yt-dlp takes the scripts of yt-dlp-ejs only of the major.minor it pins and with the
# SHA3-512 of that release (yt_dlp/extractor/youtube/jsc/_builtin/ejs.py), and pins the
# wheel by its SHA-256 (EJS_WHEEL_HASH of its Makefile): that of distinfo, the same file
# as the wheel of the release of github.com/yt-dlp/ejs. A new pin of yt-dlp: DISTVERSION
# and distinfo by tools/ytdlp-update.sh.
# The runtime of the scripts: node of www/node24, the package node24 (yt-dlp runs node
# 22 or newer: NodeJsRuntime of yt_dlp/utils/_jsruntime.py; www/yt-dlp enables node by
# default, its Makefile says how). The licenses (License-Expression of the wheel): The
# Unlicense of yt-dlp-ejs, ISC of meriyah and MIT of astring, which lib.min.js bundles.

PORTNAME=	yt-dlp-ejs
DISTVERSION=	0.8.0
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	PYPI
MASTER_SITE_SUBDIR=	py3/${PORTNAME:C/(.).*/\1/}/${PORTNAME:S/-/_/g}
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
DISTNAME=	${PORTNAME:S/-/_/g}-${DISTVERSION}-py3-none-any
EXTRACT_SUFX=	.whl
DIST_SUBDIR=	${PORTNAME}

MAINTAINER=	github@azsupport.com
COMMENT=	JavaScript challenge solver for yt-dlp (of azsupport/ports)
WWW=		https://github.com/yt-dlp/ejs \
		https://github.com/azsupport/ports

LICENSE=	ISCL MIT UNLICENSE
LICENSE_COMB=	multi

RUN_DEPENDS=	node24>0:www/node24

USES=		python zip
USE_PYTHON=	autoplist pep517

NO_ARCH=	yes
WRKSRC=		${WRKDIR}

# the wheel is installed as it is: no build frontend
PEP517_BUILD_DEPEND=

do-build:
	@${MKDIR} ${BUILD_WRKSRC}/dist
	@${CP} ${_DISTDIR}/${DISTNAME}${EXTRACT_SUFX} ${BUILD_WRKSRC}/dist/

.include <bsd.port.mk>
