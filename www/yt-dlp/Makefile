# www/yt-dlp: the yt-dlp of azsupport/ports in the place of the official
# www/yt-dlp: the official port at the latest release of yt-dlp on GitHub, ahead
# of the official tree (it takes a new release days or weeks later, and the
# grabbers of the sites need the extractors of the latest one), with ffprobe and ffmpeg
# of our multimedia/ffmpeg (FFMPEG, on by default as in the official port). The
# rest is the official port as it is: its patches (no self-update, no pandoc; one
# that a release lets apply only with fuzz made again), its dependencies, pkg-plist
# and pkg-descr. The dependencies are ports of this tree (aZ, 26.11.2026 13:09: «Делаем
# его самодостаточным — лишние зависимости убираем, нужные собираем у нас.»): the
# official ports of the Python packages as they are (Mk/azsupport-official.mk) and
# www/py-yt-dlp-ejs, ours (the scripts of the wheel of PyPI, no deno). IMPERSONATE (aZ,
# 16.11.2026: on by default): the browser impersonation of --impersonate with
# py-curl-cffi of our ftp/py-curl-cffi on our ftp/curl-impersonate; yt-dlp 2026.11.23
# takes curl_cffi 0.5.10 and 0.10 through 0.17 (yt_dlp/networking/_curlcffi.py).
# The JavaScript runtime (the challenges of YouTube, the scripts of yt-dlp-ejs): node
# of www/node24, the package node24, which py-yt-dlp-ejs runs with (aZ, 26.11.2026
# 13:40: no deno, the official port takes it and it builds V8 from its sources). yt-dlp
# enables deno alone by default, so two patches of ours make it node:
# files/patch-yt__dlp_options.py (the command line: the default of --js-runtimes, to
# which --js-runtimes adds another runtime and which --no-js-runtimes clears) and
# files/patch-yt__dlp_YoutubeDL.py (the API: YoutubeDL without js_runtimes); yt-dlp finds
# node in the scripts directory of its Python, /usr/local/bin, whatever the PATH
# (_find_exe of yt_dlp/utils/_jsruntime.py). Not a configuration file: yt-dlp reads that
# of the system only from /etc (/etc/yt-dlp.conf, /etc/yt-dlp/config:
# get_system_config_dirs of yt_dlp/utils/_utils.py), outside the prefix of a package,
# and the portable one next to the program (/usr/local/bin/yt-dlp.conf), and
# --ignore-config drops both. The warning of the YouTube
# extractor when no runtime is there still says that deno alone is enabled by default
# (yt_dlp/extractor/youtube/_video.py, which changes with every release: not patched).
# A new release (aZ, 12.11.2026: the releases of GitHub, not the official port):
# DISTVERSION and distinfo by tools/ytdlp-update.sh, which the workflow
# yt-dlp-update.yml runs every 6 hours (the SHA-256 of yt-dlp.tar.gz that of the
# API of GitHub and of the SHA2-256SUMS of the release), with a commit to main and
# a build of this port.

PORTNAME=	yt-dlp
DISTVERSION=	2026.11.23
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	www
MASTER_SITES=	https://github.com/${PORTNAME}/${PORTNAME}/releases/download/${DISTVERSION}/
DISTNAME=	${PORTNAME}
DIST_SUBDIR=	${PORTNAME}/${DISTVERSION}

MAINTAINER=	github@azsupport.com
COMMENT=	Command-line program for downloading videos from various platforms (of azsupport/ports)
WWW=		https://github.com/yt-dlp/yt-dlp \
		https://github.com/azsupport/ports

LICENSE=	UNLICENSE
LICENSE_FILE=	${WRKSRC}/LICENSE

PY_DEPENDS=	${PYTHON_PKGNAMEPREFIX}brotli>0:archivers/py-brotli@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}certifi>0:security/py-certifi@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}mutagen>0:audio/py-mutagen@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pycryptodomex>0:security/py-pycryptodomex@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}requests>=2.32.2:www/py-requests@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}sqlite3>0:databases/py-sqlite3@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}urllib3>=2.0.2:net/py-urllib3@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}websockets>=13.0:devel/py-websockets@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}yt-dlp-ejs>0:www/py-yt-dlp-ejs@${PY_FLAVOR}
BUILD_DEPENDS=	zip:archivers/zip \
		${PY_DEPENDS}
RUN_DEPENDS=	${PY_DEPENDS}

USES=		gmake python shebangfix

SHEBANG_GLOB=	devscripts/*.py

MAKE_ARGS=	PYTHON=${PYTHON_CMD} \
		MANDIR=${PREFIX}/share/man

NO_ARCH=	yes

OPTIONS_DEFINE=			FFMPEG IMPERSONATE SECRETSTORAGE SYMLINK
OPTIONS_DEFAULT=		FFMPEG IMPERSONATE SYMLINK
OPTIONS_SUB=			yes

FFMPEG_RUN_DEPENDS=		ffprobe:multimedia/ffmpeg

IMPERSONATE_DESC=		Browser impersonation (--impersonate) with ${PYTHON_PKGNAMEPREFIX}curl-cffi
IMPERSONATE_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}curl-cffi>0:ftp/py-curl-cffi@${PY_FLAVOR}

SECRETSTORAGE_DESC=		Build with ${PYTHON_PKGNAMEPREFIX}SecretStorage for secretstorage option
SECRETSTORAGE_BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}SecretStorage>0:security/py-SecretStorage@${PY_FLAVOR}
SECRETSTORAGE_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}SecretStorage>0:security/py-SecretStorage@${PY_FLAVOR}

SYMLINK_DESC=			Install youtube-dl symbolic link for executable
SYMLINK_CONFLICTS=		youtube_dl

post-install-SYMLINK-on:
	@${RLN} ${STAGEDIR}${PREFIX}/bin/yt-dlp ${STAGEDIR}${PREFIX}/bin/youtube-dl

.include <bsd.port.mk>
