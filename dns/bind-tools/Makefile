# dns/bind-tools: the BIND tools of azsupport/ports in the place of the official
# dns/bind-tools (aZ, 10.11.2026): delv, dig, host, nslookup, nsupdate, mdig and the
# DNSSEC tools of BIND 9.20. As the official one, a slave of dns/bind920 (its
# BIND_TOOLS_SLAVE part: the options, the libraries of our ports, the version);
# aZ's options there: IDN (libidn2 of az) on, DNSTAP, FIXED_RRSET and LARGE_FILE
# off, no GSSAPI.

MASTERDIR=	${.CURDIR}/../bind920

PLIST=		${.CURDIR}/pkg-plist
DESCR=		${.CURDIR}/pkg-descr

BIND_TOOLS_SLAVE=	yes

PORTSCOUT=	ignore:1

.include "${MASTERDIR}/Makefile"
