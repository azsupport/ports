# www/fcgi of azsupport/ports: the official port as it is (Mk/azsupport-official.mk), the
# package fcgi-devkit, FastCGI 2.4.7: the libfcgi of www/fcgiwrap (aZ, 20.11.2026:
# the dependencies of our ports in our ports, not packages of FreeBSD).

AZSUPPORT_OFFICIAL=	www/fcgi

# its libraries stripped: the official post-install strips the links libfcgi.so and
# libfcgi++.so, and strip writes a stripped copy in the place of a link, so the
# libraries themselves stayed as linked (results/debug-check.txt of run 44807210093);
# the links back, then the libraries stripped. Defined before the official Makefile,
# so that bsd.port.mk runs it in the stage
post-stage:
	${LN} -sf libfcgi.so.0.0.0 ${STAGEDIR}${PREFIX}/lib/libfcgi.so
	${LN} -sf libfcgi++.so.0.0.0 ${STAGEDIR}${PREFIX}/lib/libfcgi++.so
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
