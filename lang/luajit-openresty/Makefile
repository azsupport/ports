# lang/luajit-openresty of azsupport/ports in the place of the official one (its
# Makefile, pkg-plist, pkg-descr and patches): the LuaJIT 2.1 of OpenResty, the one Lua
# of the servers of aZ (aZ, 15.11.2026: «Мне не надо зоопарк lua версий», «давай
# luajit»): lua-nginx-module runs on it alone, and the lua51-* modules of this tree.
# v2.1-20261107 ahead of the official v2.1-20250826 (aZ, 16.11.2026): 170 commits, the
# fixes of the JIT on x86 and x64 among them (math.floor()/ceil(), the store
# forwarding of s2l), of FFI string buffers and of the parser. Of the official
# patches the PowerPC ones (src/jit/bcsave.lua, src/vm_ppc.dasc) are out: this
# release has them.

PORTNAME=	luajit
DISTVERSIONPREFIX=	v
DISTVERSION=	2.1-20261107
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	lang
PKGNAMESUFFIX=	-openresty

PATCH_SITES=	https://github.com/openresty/luajit2/commit/

MAINTAINER=	github@azsupport.com
COMMENT=	Just-In-Time Compiler for Lua (OpenResty branch, of azsupport/ports)
WWW=		https://github.com/openresty/luajit2 \
		https://github.com/azsupport/ports

LICENSE=	MIT PD
LICENSE_COMB=	multi
LICENSE_FILE=	${WRKSRC}/COPYRIGHT

IGNORE_riscv64=		fails to compile: lj_arch.h:73:2: No support for this architecture (yet)

USES=		cpe gmake

CONFLICTS_INSTALL=	luajit

USE_LDCONFIG=	yes
MAKE_ARGS=	CC=${CC} Q=

USE_GITHUB=	yes
GH_ACCOUNT=	openresty
GH_PROJECT=	luajit2

LUAJIT_VERSION=	2.1
# the committer time of the tag (its .relver in the archive)
LUAJIT_SOVERSION=	2.1.1793955606

PLIST_SUB+=	VERSION=${LUAJIT_VERSION} SOVERSION=${LUAJIT_SOVERSION}

.include <bsd.port.options.mk>

post-install:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/${PORTNAME}-${LUAJIT_SOVERSION}
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/libluajit-5.1.so.${LUAJIT_SOVERSION}
	${LN} -sf ${PORTNAME}-${LUAJIT_SOVERSION} \
		${STAGEDIR}${PREFIX}/bin/${PORTNAME}
	${INSTALL_MAN} ${WRKSRC}/etc/luajit.1 ${STAGEDIR}${PREFIX}/share/man/man1

.include <bsd.port.mk>
