# x11-fonts/dejavu of azsupport/ports: the DejaVu fonts of the official port, as it is, with
# its USES=fonts: fc-cache of x11-fonts/fontconfig and mkfontscale of x11-fonts/mkfontscale
# (official packages) to run it, fc-cache when it installs (aZ, 18.11.2026 16:35: «добавляй и
# в наши порты значит»; 19:58, on the option "as the official port: USES=fonts, the official
# fontconfig a dependency, fc-cache when it installs": «так делай»):
# with fonts:none no fontconfig came with it, and the fonts of openjdk21 failed without
# libfontconfig (build run 44357987655 of 18.11.2026: NullPointerException). The text of the
# libvips of net-im/rocketchat8 (the letters of its avatars: sans-serif) takes them too.
# No DOCS.

PORTNAME=	dejavu
PORTVERSION=	2.37
DISTVERSIONPREFIX=	fonts-ttf-
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	x11-fonts
MASTER_SITES=	https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_${PORTVERSION:R}_${PORTVERSION:E}/
PATCH_SITES=	https://github.com/dejavu-fonts/dejavu-fonts/commit/
PATCHFILES=	d9ee532b4f0a879372bdb006ac85d7807629ea98.patch:-p1

MAINTAINER=	github@azsupport.com
COMMENT=	Bitstream Vera Fonts clone with a wider range of characters (of azsupport/ports)
WWW=		https://dejavu-fonts.github.io/ \
		https://github.com/azsupport/ports

LICENSE=	AMS AREV BITSTREAM
LICENSE_COMB=	multi
LICENSE_NAME_AMS=	AMSFonts Copyright version 2.2
LICENSE_NAME_AREV=	Arev Fonts Copyright
LICENSE_NAME_BITSTREAM=	Bitstream Vera Fonts Copyright
LICENSE_FILE=	${WRKSRC}/LICENSE
LICENSE_PERMS_AMS=	auto-accept dist-mirror dist-sell pkg-mirror pkg-sell
LICENSE_PERMS_AREV=	auto-accept dist-mirror dist-sell pkg-mirror pkg-sell
LICENSE_PERMS_BITSTREAM=auto-accept dist-mirror dist-sell pkg-mirror pkg-sell

USES=		fonts tar:bzip2
NO_ARCH=	yes
NO_BUILD=	yes

PLIST_SUB=	FCDIR=${FCDIR} FCDIR_LINKS=${FCDIR_LINKS}

FCDIR?=		etc/fonts/conf.avail
FCDIR_LINKS=	${FCDIR:S|conf.avail|conf.d|}

OPTIONS_DEFINE=	LINKS
OPTIONS_DEFAULT=LINKS
OPTIONS_SUB=	yes
LINKS_DESC=	Install links of configuration files in conf.d

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/${FCDIR}/ ${STAGEDIR}${FONTSDIR}/
	${INSTALL_DATA} ${WRKSRC}/fontconfig/*.conf ${STAGEDIR}${PREFIX}/${FCDIR}/
	${INSTALL_DATA} ${WRKSRC}/ttf/*.ttf ${STAGEDIR}${FONTSDIR}/

do-install-LINKS-on:
	${MKDIR} ${STAGEDIR}${PREFIX}/${FCDIR_LINKS}/
	cd ${STAGEDIR}${PREFIX}/${FCDIR_LINKS}/ && ${LN} -fs ../conf.avail/*dejavu*.conf .

.include <bsd.port.mk>
