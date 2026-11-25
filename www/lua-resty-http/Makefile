# www/lua-resty-http of azsupport/ports in the place of the official one (its Makefile,
# distinfo and pkg-descr): the HTTP client of OpenResty on the cosockets of nginx, for
# the resize.lua of aZ in the place of socket.http (aZ, 15.11.2026: «да, сделай порт»),
# with the run dependency on www/lua-resty-string the official port misses: its
# resty/http_connect.lua takes to_hex of resty.string when it loads, and
# require "resty.http" fails without it (servers-test.sh, run 43768809488 of
# 15.11.2026). Without lua-resty-openssl, which only the mTLS of resty.http takes and
# the scripts of aZ do not use: resty.http logs a warning of it (level warn) when a
# worker loads it.

PORTNAME=	lua-resty-http
DISTVERSIONPREFIX=v
DISTVERSION=	0.17.2
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	www

MAINTAINER=	github@azsupport.com
COMMENT=	Lua HTTP client cosocket driver for OpenResty / ngx_lua (of azsupport/ports)
WWW=		https://github.com/ledgetech/lua-resty-http \
		https://github.com/azsupport/ports

LICENSE=	BSD2CLAUSE
LICENSE_FILE=	${WRKSRC}/LICENSE

RUN_DEPENDS=	luajit-openresty>=2.1:lang/luajit-openresty \
		lua-resty-string>0:www/lua-resty-string

USE_GITHUB=	yes
GH_ACCOUNT=	ledgetech

NO_ARCH=	yes
NO_BUILD=	yes

LUA_MODSHAREDIR=${LOCALBASE}/share/lua/5.1

PLIST_FILES+=	${LUA_MODSHAREDIR}/resty/http.lua \
		${LUA_MODSHAREDIR}/resty/http_connect.lua \
		${LUA_MODSHAREDIR}/resty/http_headers.lua

PORTDOCS=	README.md

DOCSDIR=	${PREFIX}/share/doc/lua${LUA_VER_STR}/${PORTNAME}

OPTIONS_DEFINE=	DOCS

do-install:
	@${MKDIR} ${STAGEDIR}${LUA_MODSHAREDIR}
	@(cd ${WRKSRC}/lib && ${COPYTREE_SHARE} . ${STAGEDIR}${LUA_MODSHAREDIR} "-name *\.lua")

do-install-DOCS-on:
	@${MKDIR} ${STAGEDIR}${DOCSDIR}
	@${INSTALL_DATA} ${WRKSRC}/README.md ${STAGEDIR}${DOCSDIR}

.include <bsd.port.mk>
