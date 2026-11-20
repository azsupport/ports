# net-mgmt/net-snmp of azsupport/ports: the official port (Mk/az-official.mk; aZ,
# 20.11.2026: the agent and the tools Nagios and MRTG use, «максимум что я юзать буду так
# это в нагиосе и мртг»), net-snmp 5.9.5.2 on the OpenSSL of the base system and the
# libpkg of pkg (the installed software of HOST-RESOURCES-MIB), with:
# - MFD_REWRITES on: if-mib, the ifXTable with the 64-bit counters (ifHCInOctets,
#   ifHCOutOctets) and ifName, which MRTG takes over SNMPv2c: the 32-bit ifInOctets of
#   ifTable wraps in 34 seconds at 1 Gbit/s;
# - PERL and PERL_EMBEDDED off (the SNMP module of Perl and the perl of snmpd.conf: MRTG
#   has SNMP_Session, the Perl checks of Nagios Net::SNMP), DUMMY off (no placeholder
#   values where FreeBSD has none), SMUX off (the SMUX of old routing daemons, a TCP
#   listener on port 199 of every address); NEWSYSLOG on (the rotation of snmpd.log).

AZ_OFFICIAL=	net-mgmt/net-snmp
OPTIONS_SLAVE=	MFD_REWRITES
OPTIONS_EXCLUDE=	DUMMY PERL PERL_EMBEDDED SMUX

.include "${.CURDIR:H:H}/Mk/az-official.mk"
