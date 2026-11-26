# security/libgcrypt of azsupport/ports: the official port (Mk/azsupport-official.mk),
# Libgcrypt 1.12.4 on the libgpg-error of security/libgpg-error, which net/libvncserver
# links (the option GCRYPT, its default; aZ, 26.11.2026 13:09: «Делаем его
# самодостаточным — лишние зависимости убираем, нужные собираем у нас.»). STATIC on (the
# default), DOCS and INFO off (tools/make.conf.in), AVX512 off (the default).
# The post-install of the official port strips lib/libgcrypt.so, a link: the strip of the
# base system (llvm-strip) writes a stripped copy in the place of the link and leaves the
# library libgcrypt.so.20.<x>.<y> as it was, not stripped (build run 45834704428: the debug
# check of tools/debug-check.sh failed). post-stage: the library stripped, the link again.

AZSUPPORT_OFFICIAL=	security/libgcrypt

post-stage:
	@cd ${STAGEDIR}${PREFIX}/lib && l="$$(readlink libgcrypt.so.20)" && [ -f "$$l" ] && [ ! -L "$$l" ] && \
		${STRIP_CMD} "$$l" && ${RM} libgcrypt.so && ${LN} -s "$$l" libgcrypt.so && \
		${ECHO_MSG} "===>  $$l stripped, libgcrypt.so a link to it again"

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
