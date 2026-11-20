# net-mgmt/net-snmp of azsupport/ports: the official port (Mk/az-official.mk; aZ,
# 20.11.2026: the tools of Nagios and MRTG, «максимум что я юзать буду так это в нагиосе
# и мртг», and snmpd not run: «он же демоном у меня не будет, а только как консольная
# утилита для мртг и нагиоса»), net-snmp 5.9.5.2 on the OpenSSL of the base system and
# the libpkg of pkg: snmpget, snmpwalk and the others with libnetsnmp; snmpd is in the
# package as the official port builds it, with its other options as they are, without:
# - PERL and PERL_EMBEDDED (the SNMP module of Perl and the perl of snmpd.conf: MRTG has
#   SNMP_Session, the Perl checks of Nagios Net::SNMP);
# - DUMMY (placeholder values where FreeBSD has none), SMUX (the SMUX of old routing
#   daemons, a TCP listener on port 199 of every address) and NEWSYSLOG (the rotation of
#   the log of snmpd): of snmpd only.

AZ_OFFICIAL=	net-mgmt/net-snmp
OPTIONS_EXCLUDE=	DUMMY NEWSYSLOG PERL PERL_EMBEDDED SMUX

.include "${.CURDIR:H:H}/Mk/az-official.mk"
