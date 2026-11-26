# net/libvncserver of azsupport/ports: the official port (Mk/azsupport-official.mk),
# LibVNCServer 0.9.15, the VNC server of the option VNC of emulators/virtualbox-ose-72
# (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости убираем, нужные
# собираем у нас.»): its options GCRYPT, IPV6 and OPENSSL (of the base system) on, GNUTLS
# and SASL off (the defaults); LZO of archivers/lzo2, Libgcrypt and libgpg-error of
# security/libgcrypt and security/libgpg-error, zlib of the base system. libpng and
# libjpeg (mozjpeg) of azsupport, not the packages of graphics/png and graphics/mozjpeg
# the official port takes (LIB_DEPENDS, USES=jpeg): Mk/azsupport-libs.mk (their headers
# alone, the run path /usr/local/azsupport/lib), the paths of CMake where find_package
# of PNG and JPEG finds them first (as graphics/tiff), and LIB_DEPENDS without those two
# after the official Makefile. post-stage checks what it links.

AZSUPPORT_OFFICIAL=	net/libvncserver
CMAKE_ARGS+=	-DCMAKE_PREFIX_PATH=${AZSUPPORT_LIBS_DIR} \
		-DCMAKE_LIBRARY_PATH=${AZSUPPORT_PREFIX}/lib

AZSUPPORT_LIBS=	mozjpeg:libjpeg.so png:libpng16.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"

# libvncserver.so links libpng16 and libjpeg of azsupport, and each library that links
# one of them has the run path of azsupport (readelf -d)
post-stage:
	@cd ${STAGEDIR}${PREFIX}/lib || exit 1; \
	d="$$(/usr/bin/readelf -d libvncserver.so)" || exit 1; \
	for l in libpng16 libjpeg; do \
		printf '%s\n' "$$d" | ${GREP} -q "NEEDED.*\[$$l\.so" || { ${ECHO_MSG} "===>  libvncserver.so does not link $$l"; exit 1; }; \
	done; \
	for f in lib*.so.*; do \
		[ -L "$$f" ] && continue; \
		d="$$(/usr/bin/readelf -d "$$f")" || exit 1; \
		printf '%s\n' "$$d" | ${GREP} -Eq 'NEEDED.*\[(libpng16|libjpeg)\.so' || continue; \
		printf '%s\n' "$$d" | ${GREP} -Eq '(RPATH|RUNPATH).*${AZSUPPORT_PREFIX}/lib' || \
			{ ${ECHO_MSG} "===>  $$f: libpng16 or libjpeg without the run path ${AZSUPPORT_PREFIX}/lib"; exit 1; }; \
	done

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

LIB_DEPENDS:=	${LIB_DEPENDS:Nlibpng.so\:graphics/png:Nlibjpeg.so\:*}
