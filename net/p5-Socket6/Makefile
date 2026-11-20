# net/p5-Socket6 of azsupport/ports: the official port (Mk/az-official.mk), Socket6
# 0.29, the IPv6 part of socket.h for Perl (getaddrinfo, inet_pton...), an XS module
# on the perl5 of this tree, for net/p5-IO-Socket-INET6 (aZ, 20.11.2026: the Perl
# modules of net-mgmt/mrtg in our ports, not packages of FreeBSD).

AZ_OFFICIAL=	net/p5-Socket6

# its Socket6.so stripped: MakeMaker installs it as it was linked (no debug in our
# packages, aZ 17.11.2026); defined before the official Makefile, so that
# bsd.port.mk runs it in the stage
post-stage:
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}

.include "${.CURDIR:H:H}/Mk/az-official.mk"
