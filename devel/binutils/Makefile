# devel/binutils of azsupport/ports: the official port (Mk/azsupport-official.mk), GNU
# binutils 2.44 (with gold) in the flavor native, the as and ld that lang/gcc16 of this
# tree runs (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»). Its options: INFO off (tools/make.conf.in), ELFU
# and RELRO off (the defaults), no NLS (the official port).
# Without zstd (the official port: --with-zstd on archivers/zstd, zstd the default
# compression of the debug sections): our builds have no debug information
# (tools/debug-check.sh), and on the zstd of azsupport the binutils would need azsupport to
# run, while azsupport/azsupport builds with lang/gcc16, which runs with the binutils (a
# cycle, since lang/gcc16 is the compiler of azsupport/azsupport: 40a6951); the debug
# sections it compresses with the zlib of the base system (--with-system-zlib of the
# official port). After the official Makefile, which sets them: CONFIGURE_ARGS without
# --with-zstd and --enable-default-compressed-debug-sections-algorithm=zstd and with
# --without-zstd, LIB_DEPENDS without archivers/zstd. post-stage checks that no file links
# libzstd.
# The builds of this tree that need the binutils only to build (USE_BINUTILS of
# USES=azgcc) count the official package in their hashes (AZSUPPORT_TOOLS_OFFICIAL of
# tools/build.sh), so this port builds again only lang/gcc16, which runs with it.

AZSUPPORT_OFFICIAL=	devel/binutils

post-stage:
	@cd ${STAGEDIR}${PREFIX} || exit 1; \
	n=""; \
	for f in $$(${FIND} . -type f \( -name '*.so*' -o -perm -u+x \)); do \
		/usr/bin/readelf -d "$$f" 2> /dev/null | ${GREP} -q 'NEEDED.*\[libzstd\.so' && n="$$n $$f"; \
	done; \
	[ -z "$$n" ] || { ${ECHO_MSG} "===>  libzstd linked by (--without-zstd):$$n"; exit 1; }

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

CONFIGURE_ARGS:=	${CONFIGURE_ARGS:N--with-zstd:N--enable-default-compressed-debug-sections-algorithm=zstd} \
			--without-zstd
LIB_DEPENDS:=	${LIB_DEPENDS:Nlibzstd.so\:archivers/zstd}
