# net-mgmt/net-snmp of azsupport/ports: the official port (Mk/az-official.mk; aZ,
# 20.11.2026: the tools of Nagios and MRTG, «максимум что я юзать буду так это в нагиосе
# и мртг», and snmpd not run: «он же демоном у меня не будет, а только как консольная
# утилита для мртг и нагиоса»), net-snmp 5.9.5.2 on the OpenSSL of the base system and
# the libpkg of pkg: snmpget, snmpwalk and the others with libnetsnmp; snmpd is in the
# package, should it be run one day, with MFD_REWRITES on (aZ 19:58: «включи, хуже же не
# будет, тем более вдруг демона запустить можно»: if-mib, the ifXTable with the 64-bit
# counters ifHCInOctets and ifHCOutOctets and ifName, which MRTG takes over SNMPv2c; the
# 32-bit ifInOctets of ifTable wraps in 34 seconds at 1 Gbit/s), its other options as
# they are, without:
# - PERL and PERL_EMBEDDED (the SNMP module of Perl and the perl of snmpd.conf: MRTG has
#   SNMP_Session, the Perl checks of Nagios Net::SNMP);
# - DUMMY (placeholder values where FreeBSD has none), SMUX (the SMUX of old routing
#   daemons, a TCP listener on port 199 of every address) and NEWSYSLOG (the rotation of
#   the log of snmpd; aZ 19:58: maybe later a port -newsyslog for each port with logs).

AZ_OFFICIAL=	net-mgmt/net-snmp
OPTIONS_SLAVE=	MFD_REWRITES
OPTIONS_EXCLUDE=	DUMMY NEWSYSLOG PERL PERL_EMBEDDED SMUX

.include "${.CURDIR:H:H}/Mk/az-official.mk"
