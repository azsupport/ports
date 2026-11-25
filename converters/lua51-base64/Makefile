# converters/lua51-base64: lbase64 of azsupport/ports (there is no official port): base64
# in pure Lua, the module "base64" the Lua scripts of nginx of aZ take as b64 (aZ,
# 15.11.2026: «мне надо чтобы через lua модуль работали модули которые я сам компилю»),
# in the place of «luarocks54 --lua-version=5.1 install base64 --tree=/usr/local»: its
# file where luarocks put it (share/lua/5.1), for LuaJIT (its bit library).

PORTNAME=	base64
DISTVERSIONPREFIX=	v
DISTVERSION=	1.5.3
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	converters
PKGNAMEPREFIX=	lua51-

MAINTAINER=	github@azsupport.com
COMMENT=	Base64 encoding and decoding in pure Lua (of azsupport/ports)
WWW=		https://github.com/iskolbin/lbase64 \
		https://github.com/azsupport/ports

LICENSE=	MIT PD
LICENSE_COMB=	dual

RUN_DEPENDS=	luajit-openresty>=2.1:lang/luajit-openresty

USE_GITHUB=	yes
GH_ACCOUNT=	iskolbin
GH_PROJECT=	lbase64

NO_ARCH=	yes
NO_BUILD=	yes

LUA_MODSHAREDIR=	${PREFIX}/share/lua/5.1
PLIST_FILES=	share/lua/5.1/base64.lua

do-install:
	${MKDIR} ${STAGEDIR}${LUA_MODSHAREDIR}
	${INSTALL_DATA} ${WRKSRC}/base64.lua ${STAGEDIR}${LUA_MODSHAREDIR}

.include <bsd.port.mk>
