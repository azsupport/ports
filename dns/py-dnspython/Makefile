# dns/py-dnspython of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# the DNS of py-pyspf, on our lang/python312 (aZ, 19.11.2026).
# Its options (26.11.2026; aZ, 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»; 15:30, on which options add functions to our Python
# programs): IDNA on (the default: IDNA 2008 for the internationalized domains of the SPF
# checks of py-pyspf, on py-idna of dns/py-idna, ours anyway for www/py-requests);
# DNSSEC, DOH, DOQ and TRIO off: py-pyspf of mail/py-spf-engine asks the resolver of the
# system, which validates DNSSEC itself, over UDP and TCP (dns.resolver), and DNS over
# HTTPS and QUIC and trio are of no use to it, while they would take py-cryptography,
# py-aioquic and the stack of httpx (py-h2, py-httpcore2, py-httpx2) and py-trio.

AZSUPPORT_OFFICIAL=	dns/py-dnspython
OPTIONS_EXCLUDE=	DNSSEC DOH DOQ TRIO

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
