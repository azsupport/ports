# archivers/py-brotli of azsupport/ports: the official port (Mk/azsupport-official.mk), the
# Brotli 1.2.1 of Python, the package py312-brotli of our lang/python312, which www/yt-dlp
# runs with (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»). Its extension on the brotli 1.2.1 of azsupport (the
# version of the module; USE_SYSTEM_BROTLI: setup.py takes it by pkg-config), not the
# package of archivers/brotli: Mk/azsupport-libs.mk (its headers and .pc files alone, the
# run path /usr/local/azsupport/lib). The official Makefile assigns BUILD_DEPENDS,
# LIB_DEPENDS and MAKE_ENV, so after it: libbrotlicommon of azsupport to build, no
# archivers/brotli, and the PKG_CONFIG_LIBDIR of Mk/azsupport-libs.mk in MAKE_ENV (the
# build of the wheel). post-stage checks what the extension links.

AZSUPPORT_OFFICIAL=	archivers/py-brotli

AZSUPPORT_LIBS=	brotli:libbrotlicommon.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# _brotli links libbrotlienc and libbrotlidec of azsupport with its run path (readelf -d)
post-stage:
	@f="$$(${FIND} ${STAGEDIR}${PYTHON_SITELIBDIR} -name '_brotli*.so')"; \
	[ -n "$$f" ] || { ${ECHO_MSG} "===>  no _brotli*.so in the stage"; exit 1; }; \
	d="$$(/usr/bin/readelf -d $$f)" || exit 1; \
	for l in libbrotlienc libbrotlidec; do \
		printf '%s\n' "$$d" | ${GREP} -q "NEEDED.*\[$$l\.so" || { ${ECHO_MSG} "===>  $${f##*/} does not link $$l"; exit 1; }; \
	done; \
	printf '%s\n' "$$d" | ${GREP} -Eq '(RPATH|RUNPATH).*${AZSUPPORT_PREFIX}/lib' || \
		{ ${ECHO_MSG} "===>  $${f##*/} has no run path ${AZSUPPORT_PREFIX}/lib"; exit 1; }

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

BUILD_DEPENDS:=	${BUILD_DEPENDS:N*\:archivers/brotli} \
		${AZSUPPORT_PREFIX}/lib/libbrotlicommon.so:azsupport/brotli
LIB_DEPENDS:=	${LIB_DEPENDS:N*\:archivers/brotli}
MAKE_ENV+=	PKG_CONFIG_LIBDIR=${AZSUPPORT_LIBS_PKG_CONFIG_LIBDIR}
