# graphics/lua51-vips: lua-vips of azsupport/ports (there is no official port): the
# binding of libvips by the FFI of LuaJIT, for the Lua scripts of nginx of aZ (aZ,
# 15.11.2026: «мне надо чтобы через lua модуль работали модули которые я сам компилю»,
# «давай luajit»), in the place of «luarocks54 --lua-version=5.1 install lua-vips
# --tree=/usr/local»: its files where luarocks put them (share/lua/5.1), on the libvips
# of graphics/vips of this tree, which it opens with ffi.load (a run dependency);
# without luaffi-tkl, which only standard Lua needs (LuaJIT has its FFI).

PORTNAME=	vips
DISTVERSIONPREFIX=	v
DISTVERSION=	1.1-12
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	graphics
PKGNAMEPREFIX=	lua51-

MAINTAINER=	github@azsupport.com
COMMENT=	Lua binding for libvips by the FFI of LuaJIT (of azsupport/ports)
WWW=		https://github.com/libvips/lua-vips \
		https://github.com/azsupport/ports

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

RUN_DEPENDS=	${LOCALBASE}/lib/libvips.so:graphics/vips \
		luajit-openresty>=2.1:lang/luajit-openresty

USE_GITHUB=	yes
GH_ACCOUNT=	libvips
GH_PROJECT=	lua-vips

NO_ARCH=	yes
NO_BUILD=	yes

LUA_MODSHAREDIR=	${PREFIX}/share/lua/5.1

do-install:
	${MKDIR} ${STAGEDIR}${LUA_MODSHAREDIR}/vips
	${INSTALL_DATA} ${WRKSRC}/src/vips.lua ${STAGEDIR}${LUA_MODSHAREDIR}
	${INSTALL_DATA} ${WRKSRC}/src/vips/*.lua ${STAGEDIR}${LUA_MODSHAREDIR}/vips

.include <bsd.port.mk>
