# www/py-yt-dlp-ejs: the yt-dlp-ejs of azsupport/ports in the place of the official
# www/py-yt-dlp-ejs, made from tools/ytdlp-ejs/ by tools/ytdlp-update.sh (the workflow
# yt-dlp-update.yml) when the release of yt-dlp that www/yt-dlp takes pins a newer
# yt-dlp-ejs than the official port of the pinned tree (aZ, 12.11.2026: yt-dlp
# follows the releases of GitHub, and what must move with it). yt-dlp takes the
# scripts of yt-dlp-ejs only of the major.minor it pins and with the SHA3-512 of
# that release (yt_dlp/extractor/youtube/jsc/_builtin/ejs.py), so this port installs
# the wheel of the release of github.com/yt-dlp/ejs that yt-dlp pins (EJS_VERSION of
# its Makefile; the SHA-256 of distinfo is its EJS_WHEEL_HASH), as the builds of
# yt-dlp bundle it, in the way of the official misc/py-aistudio-sdk. The official
# port builds the same scripts with npm and rollup from a tarball of node_modules
# fetched on FreeBSD, a distfile a runner of GitHub cannot make. deno, which runs
# the scripts, is the official package, as in the official port.
# A new pin of yt-dlp: DISTVERSION and distinfo by tools/ytdlp-update.sh.

PORTNAME=	yt-dlp-ejs
DISTVERSION=	0.8.0
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://github.com/yt-dlp/ejs/releases/download/${DISTVERSION}/
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
DISTNAME=	${PORTNAME:S/-/_/g}-${DISTVERSION}-py3-none-any
EXTRACT_SUFX=	.whl
DIST_SUBDIR=	${PORTNAME}

MAINTAINER=	github@azsupport.com
COMMENT=	JavaScript challenge solver for yt-dlp (of azsupport/ports)
WWW=		https://github.com/yt-dlp/ejs \
		https://github.com/azsupport/ports

LICENSE=	UNLICENSE

RUN_DEPENDS=	deno:www/deno

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
