# www/py-requests of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# Requests 2.34.2, the package py312-requests of our lang/python312, which www/yt-dlp
# runs with (aZ, 26.11.2026 13:09: «Делаем его самодостаточным — лишние зависимости
# убираем, нужные собираем у нас.»): with SOCKS (the default: py-pysocks), on certifi,
# charset-normalizer, idna, urllib3 and PySocks of security/py-certifi,
# textproc/py-charset-normalizer, dns/py-idna, net/py-urllib3 and net/py-pysocks. The
# builds of this tree take the official package as their build tool
# (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh: databases/mongodb80), so this port builds
# again only www/yt-dlp, which runs with it.

AZSUPPORT_OFFICIAL=	www/py-requests

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
