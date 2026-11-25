# www/mod_fastcgi of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# the FastCGI module of Apache 2.4 for www/apache24 of this tree (aZ, 19.11.2026: the
# PHP of the sites of a server run as FastCGI programs through suexec).

AZSUPPORT_OFFICIAL=	www/mod_fastcgi

# The package apache24-mod_fastcgi (aZ, 21.11.2026: the name with the version first,
# as php84, as apache24-suexec): PKGNAMEPREFIX, which USES=apache sets to ap24- only
# when it is not set; it conflicts with the official ap24-mod_fastcgi (the same
# files).
PKGNAMEPREFIX=	apache24-
CONFLICTS_INSTALL=	ap24-mod_fastcgi

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
