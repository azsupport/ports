# sysutils/tmux: the tmux of azsupport/ports in the place of the official
# sysutils/tmux (aZ, 18.11.2026: «keychain и tmux … добавь в наши порты»): the
# official port of the pinned commit (tmux 3.8, the newest release) with libevent
# the shared library of azsupport, with the run path /usr/local/azsupport/lib (our ports link each
# other's shared libraries: aZ, 10.11.2026), so that it takes no package but azsupport (the
# official one takes devel/libevent), as databases/memcached. ncurses and utempter
# of the base system. Without UTF8PROC (the widths of the characters from wcwidth() of
# the libc of FreeBSD; the distributions take utf8proc for macOS alone), the static
# libevent of LIBEVENT_STATIC (libevent of azsupport), DOCS and EXAMPLES.

PORTNAME=	tmux
PORTVERSION=	3.8
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	sysutils
MASTER_SITES=	https://github.com/tmux/tmux/releases/download/${DISTVERSION}/

MAINTAINER=	github@azsupport.com
COMMENT=	Terminal Multiplexer (of azsupport/ports)
WWW=		https://tmux.github.io/ \
		https://github.com/azsupport/ports

LICENSE=	ISCL
LICENSE_FILE=	${WRKSRC}/COPYING

# libevent.so of azsupport: its configure takes LIBEVENT_CORE_CFLAGS and LIBEVENT_CORE_LIBS
# as they are (PKG_CHECK_MODULES does not ask pkg-config then)
# The C compiled by GCC 16 of the ports (USES=azgcc, Mk/Uses/azgcc.mk; a build dependency
# only), aZ 27.11.2026 08:43 («окей, следуем инфе с тестов»): prog-bench (a session cats
# 150 MB of text, 200x50) against the base clang 19, run 45944300277: GCC 16 -10.1%, clang
# 23 -0.9%, GCC 16 faster than clang 23 by 10.2% in 5 of 5 rounds; -2.5%, -15.3% and
# -10.2% on three other runs (45938357673, 45941929373, 45943132901).
BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libevent.so:azsupport/azsupport
RUN_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libevent.so:azsupport/azsupport

USES=		cpe ncurses pkgconfig
# GCC of the ports for the C, at build time only (Mk/Uses/azgcc.mk)
USES+=		azgcc
CPE_VENDOR=	tmux_project

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--enable-utempter \
		--sysconfdir=${PREFIX}/etc
CONFIGURE_ENV=	LIBEVENT_CORE_CFLAGS="-I${AZSUPPORT_PREFIX}/include" \
		LIBEVENT_CORE_LIBS="-L${AZSUPPORT_PREFIX}/lib -Wl,-rpath,${AZSUPPORT_PREFIX}/lib -levent"

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
