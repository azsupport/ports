# devel/py-cffi of azsupport/ports: the official port (Mk/azsupport-official.mk), CFFI
# 2.1.1, the package py312-cffi of our lang/python312, which ftp/py-curl-cffi builds and
# runs with (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»), on pycparser of devel/py-pycparser. Its
# _cffi_backend on the libffi of azsupport, as our Python, not the package of
# devel/libffi: Mk/azsupport-libs.mk (ffi.h alone, libffi.pc for its setup.py, the run
# path /usr/local/azsupport/lib). The official Makefile assigns BUILD_DEPENDS,
# LIB_DEPENDS and RUN_DEPENDS, so after it: libffi of azsupport to build and to run, no
# devel/libffi. post-stage checks what the extension links.

AZSUPPORT_OFFICIAL=	devel/py-cffi

AZSUPPORT_LIBS=	libffi:libffi.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# _cffi_backend links libffi of azsupport with its run path (readelf -d)
post-stage:
	@f="$$(${FIND} ${STAGEDIR}${PYTHON_SITELIBDIR} -name '_cffi_backend*.so')"; \
	[ -n "$$f" ] || { ${ECHO_MSG} "===>  no _cffi_backend*.so in the stage"; exit 1; }; \
	d="$$(/usr/bin/readelf -d $$f)" || exit 1; \
	printf '%s\n' "$$d" | ${GREP} -q 'NEEDED.*\[libffi\.so' || { ${ECHO_MSG} "===>  $${f##*/} does not link libffi"; exit 1; }; \
	printf '%s\n' "$$d" | ${GREP} -Eq '(RPATH|RUNPATH).*${AZSUPPORT_PREFIX}/lib' || \
		{ ${ECHO_MSG} "===>  $${f##*/} has no run path ${AZSUPPORT_PREFIX}/lib"; exit 1; }

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

BUILD_DEPENDS+=	${AZSUPPORT_PREFIX}/lib/libffi.so:azsupport/azsupport
RUN_DEPENDS+=	${AZSUPPORT_PREFIX}/lib/libffi.so:azsupport/azsupport
LIB_DEPENDS:=	${LIB_DEPENDS:Nlibffi.so\:devel/libffi}
