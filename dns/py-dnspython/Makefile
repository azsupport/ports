# dns/py-dnspython of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# the DNS of py-pyspf, on our lang/python312 (aZ, 19.11.2026).
# Without the options DNSSEC, DOH, DOQ, IDNA and TRIO (aZ, 26.11.2026 13:09: «Делаем его
# самодостаточным — лишние зависимости убираем, нужные собираем у нас.»), whose Python
# packages (py-cryptography; py-h2, py-httpcore2 and py-httpx2; py-aioquic; py-idna;
# py-trio) the repository does not have: py-pyspf of mail/py-spf-engine asks
# dns.resolver for its records over UDP and TCP, and dnspython takes each of them only
# when it is there (the IDNA 2003 codec of Python in the place of py-idna).

AZSUPPORT_OFFICIAL=	dns/py-dnspython
OPTIONS_EXCLUDE=	DNSSEC DOH DOQ IDNA TRIO

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
