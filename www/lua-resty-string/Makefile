# www/lua-resty-string of azsupport/ports (there is no official port): the string
# utilities and hashes of OpenResty for the LuaJIT of nginx (resty.string, resty.md5,
# resty.sha*, resty.aes, resty.random; by the FFI on the OpenSSL nginx links), which
# www/lua-resty-http needs: its resty/http_connect.lua takes to_hex of resty.string
# when it loads, and require "resty.http" fails without it (servers-test.sh, run
# 43768809488 of 15.11.2026).

PORTNAME=	lua-resty-string
DISTVERSIONPREFIX=	v
DISTVERSION=	0.19
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	www

MAINTAINER=	github@azsupport.com
COMMENT=	String utilities and common hash functions for ngx_lua (of azsupport/ports)
WWW=		https://github.com/openresty/lua-resty-string \
		https://github.com/azsupport/ports

LICENSE=	BSD2CLAUSE

RUN_DEPENDS=	luajit-openresty>=2.1:lang/luajit-openresty

USE_GITHUB=	yes
GH_ACCOUNT=	openresty

NO_ARCH=	yes
NO_BUILD=	yes

LUA_MODSHAREDIR=	${LOCALBASE}/share/lua/5.1

PLIST_FILES=	${LUA_MODSHAREDIR}/resty/aes.lua \
		${LUA_MODSHAREDIR}/resty/md5.lua \
		${LUA_MODSHAREDIR}/resty/random.lua \
		${LUA_MODSHAREDIR}/resty/sha.lua \
		${LUA_MODSHAREDIR}/resty/sha1.lua \
		${LUA_MODSHAREDIR}/resty/sha224.lua \
		${LUA_MODSHAREDIR}/resty/sha256.lua \
		${LUA_MODSHAREDIR}/resty/sha384.lua \
		${LUA_MODSHAREDIR}/resty/sha512.lua \
		${LUA_MODSHAREDIR}/resty/string.lua

do-install:
	@${MKDIR} ${STAGEDIR}${LUA_MODSHAREDIR}/resty
	${INSTALL_DATA} ${WRKSRC}/lib/resty/*.lua ${STAGEDIR}${LUA_MODSHAREDIR}/resty

.include <bsd.port.mk>
