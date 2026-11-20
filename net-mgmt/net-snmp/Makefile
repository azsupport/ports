# net-mgmt/net-snmp of azsupport/ports: the official port as it is (Mk/az-official.mk;
# aZ, 20.11.2026: with net-mgmt/mrtg, the agent its graphs poll), net-snmp 5.9.5.2 with
# its default options: PERL and PERL_EMBEDDED (the perl5 of this tree), DUMMY, SMUX,
# NEWSYSLOG; on the OpenSSL of the base system and the libpkg of pkg (the installed
# software of HOST-RESOURCES-MIB).

AZ_OFFICIAL=	net-mgmt/net-snmp

# the XS modules of its Perl stripped as well: the official port strips its programs and
# libraries only (no debug in our packages, aZ 17.11.2026); defined before the official
# Makefile, so that bsd.port.mk runs it in the stage
post-stage:
	@${SETENV} STRIP_CMD="${STRIP_CMD}" ${SH} ${.CURDIR:H:H}/tools/strip-elf.sh ${STAGEDIR}${PREFIX}

.include "${.CURDIR:H:H}/Mk/az-official.mk"
