# archivers/lzo2 of azsupport/ports: the official port (Mk/azsupport-official.mk), LZO
# 2.10, which net/libvncserver links (aZ, 26.11.2026 13:09: «Делаем его самодостаточным —
# лишние зависимости убираем, нужные собираем у нас.»: every run dependency of a package of
# the repository is a package of it). DOCS and EXAMPLES off (tools/make.conf.in).
# The post-install of the official port strips lib/liblzo2.so.2, a link: the strip of the
# base system (llvm-strip) writes a stripped copy in the place of the link and leaves the
# library liblzo2.so.2.0.0 as it was, not stripped (build run 45834704428: the debug check
# of tools/debug-check.sh failed). post-stage: the library stripped, the link again.

AZSUPPORT_OFFICIAL=	archivers/lzo2

post-stage:
	@cd ${STAGEDIR}${PREFIX}/lib && l="$$(readlink liblzo2.so)" && [ -f "$$l" ] && [ ! -L "$$l" ] && \
		${STRIP_CMD} "$$l" && ${RM} liblzo2.so.2 && ${LN} -s "$$l" liblzo2.so.2 && \
		${ECHO_MSG} "===>  $$l stripped, liblzo2.so.2 a link to it again"

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
