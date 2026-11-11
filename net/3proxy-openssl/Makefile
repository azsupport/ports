# net/3proxy-openssl: net/3proxy of azsupport/ports with TLS
# (-D3PROXY_USE_OPENSSL=ON, the OpenSSL of the base system): TLS for the clients of
# its servers (ssl_serv, an https:// proxy, client certificates), TLS to upstream
# servers and parent proxies (ssl_cli; tcps, socks5s, connect+s) and the MITM of TLS
# (ssl_mitm); the same files as 3proxy (aZ, 11.11.2026).

PKGNAMESUFFIX=	-openssl
COMMENT=	Proxy servers set (support HTTP(S), FTP, SOCKS, POP3, TCP & UDP), with TLS (of azsupport/ports)

MASTERDIR=	${.CURDIR}/../3proxy

.include "${MASTERDIR}/Makefile"
