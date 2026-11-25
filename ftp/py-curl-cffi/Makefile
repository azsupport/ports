# ftp/py-curl-cffi of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# the package py312-curl-cffi of our lang/python312 (aZ, 16.11.2026: ours, in the
# repository azsupport, for the impersonation of yt-dlp, --impersonate): curl_cffi 0.17.0,
# whose extension links the libcurl-impersonate.so of our ftp/curl-impersonate
# (files/patch-libs.json of the official port: the shared library of /usr/local/lib,
# nothing downloaded). yt-dlp 2026.10.26 takes curl_cffi 0.5.10 and 0.10.x through
# 0.17.x (yt_dlp/networking/_curlcffi.py; its release builds pin 0.17.0). Its
# dependencies as the official port has them: py312-cffi and py312-certifi official
# packages, py312-wheel ours.

AZSUPPORT_OFFICIAL=	ftp/py-curl-cffi

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
