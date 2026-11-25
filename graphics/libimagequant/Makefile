# graphics/libimagequant of azsupport/ports: the official port (Mk/azsupport-official.mk),
# the colour quantisation of graphics/vips (GIF and palette PNG) and of the libgd of
# azsupport (LIQ: imagegif() and imagetruecolortopalette() of PHP 7.4 to 8.4; aZ,
# 11.11.2026), linked by azsupport (tools/azsupport-build.sh). GPLv3 or later.

AZSUPPORT_OFFICIAL=	graphics/libimagequant

# its library stripped: cargo cinstall of the official port copies it as cargo
# linked it (no debug in our packages, aZ 17.11.2026); defined before the official
# Makefile, so that bsd.port.mk runs it in the stage
post-stage:
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
