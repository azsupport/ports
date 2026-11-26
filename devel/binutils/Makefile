# devel/binutils of azsupport/ports: the official port (Mk/azsupport-official.mk), GNU
# binutils 2.44 (with gold) in the flavor native, the as and ld that lang/gcc16 of this
# tree runs (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»). Its options: INFO off (tools/make.conf.in), ELFU
# and RELRO off (the defaults), no NLS (the official port). zstd (--with-zstd: the
# compressed debug sections) of azsupport, not archivers/zstd: Mk/azsupport-libs.mk
# (libzstd.pc for its configure, the run path /usr/local/azsupport/lib); after the
# official Makefile, which assigns BUILD_DEPENDS and LIB_DEPENDS, libzstd of azsupport to
# build and no archivers/zstd. The builds of this tree take the official package as their
# build tool (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh: USE_BINUTILS of USES=azgcc), so
# this port builds again only lang/gcc16, which runs with it and gets this one.
# post-stage checks what links zstd.

AZSUPPORT_OFFICIAL=	devel/binutils

AZSUPPORT_LIBS=	zstd:libzstd.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# the files that link libzstd (readelf -d): one at least (libbfd), each with the run
# path of azsupport
post-stage:
	@cd ${STAGEDIR}${PREFIX} || exit 1; \
	n=""; bad=""; \
	for f in $$(${FIND} . -type f \( -name '*.so*' -o -perm -u+x \)); do \
		d="$$(/usr/bin/readelf -d "$$f" 2> /dev/null)" || continue; \
		printf '%s\n' "$$d" | ${GREP} -q 'NEEDED.*\[libzstd\.so' || continue; \
		n="$$n $$f"; \
		printf '%s\n' "$$d" | ${GREP} -Eq '(RPATH|RUNPATH).*${AZSUPPORT_PREFIX}/lib' || bad="$$bad $$f"; \
	done; \
	${ECHO_MSG} "===>  libzstd of azsupport linked by:$$n"; \
	[ -n "$$n" ] || { ${ECHO_MSG} "===>  no file links libzstd (--with-zstd)"; exit 1; }; \
	[ -z "$$bad" ] || { ${ECHO_MSG} "===>  libzstd without the run path ${AZSUPPORT_PREFIX}/lib:$$bad"; exit 1; }

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

BUILD_DEPENDS+=	${AZSUPPORT_PREFIX}/lib/libzstd.so:azsupport/azsupport
LIB_DEPENDS:=	${LIB_DEPENDS:Nlibzstd.so\:archivers/zstd}
