# sysutils/tmux: the tmux of azsupport/ports in the place of the official
# sysutils/tmux (aZ, 18.11.2026: «keychain и tmux … добавь в наши порты»): the
# official port of the pinned commit (tmux 3.8, the newest release) with libevent
# the shared library of az, with the run path /usr/local/az/lib (our ports link each
# other's shared libraries: aZ, 10.11.2026), so that it takes no package but az (the
# official one takes devel/libevent), as databases/memcached. ncurses and utempter
# of the base system. Without UTF8PROC (the widths of the characters from wcwidth() of
# the libc of FreeBSD; the distributions take utf8proc for macOS alone), the static
# libevent of LIBEVENT_STATIC (libevent of az), DOCS and EXAMPLES.

PORTNAME=	tmux
PORTVERSION=	3.8
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	sysutils
MASTER_SITES=	https://github.com/tmux/tmux/releases/download/${DISTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT=	Terminal Multiplexer (of azsupport/ports)
WWW=		https://tmux.github.io/ \
		https://github.com/azsupport/ports

LICENSE=	ISCL
LICENSE_FILE=	${WRKSRC}/COPYING

# libevent.so of az: its configure takes LIBEVENT_CORE_CFLAGS and LIBEVENT_CORE_LIBS
# as they are (PKG_CHECK_MODULES does not ask pkg-config then)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libevent.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libevent.so:az/az

USES=		cpe ncurses pkgconfig
CPE_VENDOR=	tmux_project

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--enable-utempter \
		--sysconfdir=${PREFIX}/etc
CONFIGURE_ENV=	LIBEVENT_CORE_CFLAGS="-I${AZ_PREFIX}/include" \
		LIBEVENT_CORE_LIBS="-L${AZ_PREFIX}/lib -Wl,-rpath,${AZ_PREFIX}/lib -levent"

CONFLICTS_INSTALL=	tmux23

PLIST_FILES=	bin/tmux \
		share/man/man1/tmux.1.gz

PORTDOCS=	CHANGES README
PORTEXAMPLES=	*

OPTIONS_DEFINE=	DOCS EXAMPLES

post-patch:
	@${REINPLACE_CMD} -e 's|/etc/tmux.conf|${PREFIX}/etc/tmux.conf|g' \
		${PATCH_WRKSRC}/CHANGES ${PATCH_WRKSRC}/tmux.h
	@${REINPLACE_CMD} -e 's|-O2||g' ${PATCH_WRKSRC}/Makefile.in

post-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	(cd ${WRKSRC} && ${INSTALL_DATA} ${PORTDOCS} ${STAGEDIR}${DOCSDIR})

post-install-EXAMPLES-on:
	@${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	${INSTALL_DATA} ${WRKSRC}/example* ${STAGEDIR}${EXAMPLESDIR}

.include <bsd.port.mk>
