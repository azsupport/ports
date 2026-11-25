# mail/procmail of azsupport/ports: procmail, the local delivery and its filters (aZ,
# 20.11.2026: «procmail надо»), at the master of upstream in the place of the 3.22 of
# the official port (aZ, 21.11.2026: the snapshot of BuGlessRB/procmail at 8b379c4,
# 12.08.2026: v3.24 and the 13 commits after it, the hardening of its memory safety
# of 2026 among them; no release after 3.24, so the version 3.24.20260812, after 3.22
# and before the 3.30 to come), without DOCS and EXAMPLES (tools/make.conf.in). 3.24
# has the fixes Debian carries on 3.22 and the dropping of the privileges before
# ~/.procmailrc is opened (Ubuntu bug 407459, 9853eec). Of the patches of the official
# port for 3.22, those 3.24 still needs, as they are: files/patch-Makefile (the root
# of the install, LOCKINGTEST without a question, the flags of the ports),
# files/patch-config.h (ETCRC and ETCRCS under /usr/local/etc, LMTP, the trusted ids,
# no fcntl locking), files/patch-initmake (CFLAGS and LDFLAGS of the ports) and
# files/patch-src-autoconf (no read of the terminal, /usr/local/bin in the default
# PATH). The others are in 3.24 (comsat.c, formisc.c, mailfold.c, pipes.c, procmail.c;
# getline is cgetline) or are only text (Makefile.1, procmail.man, manconf.c,
# recommend.c). 3.24 installs the manual page of mailstat too.

PORTNAME=	procmail
DISTVERSION=	3.24.20260812
PORTREVISION=	${AZSUPPORT_STAMP:U0}
CATEGORIES=	mail

MAINTAINER=	github@azsupport.com
COMMENT=	Local mail delivery agent (of azsupport/ports)
WWW=		https://github.com/BuGlessRB/procmail \
		https://github.com/azsupport/ports

LICENSE=	GPLv2

USES=		cpe
CPE_VENDOR=	procmail
USE_GITHUB=	yes
GH_ACCOUNT=	BuGlessRB
GH_TAGNAME=	8b379c4f536320abafd524fd4ccfedaf3f387f54

INSTALL_TARGET=	install.bin install.man

PORTDOCS=	FAQ FEATURES HISTORY KNOWN_BUGS README
PORTEXAMPLES=	1procmailrc 1rmail 2procmailrc 2rmail 3procmailrc 3rmail \
		advanced dirname forward local_procmail_lmtp.m4 mailstat

OPTIONS_DEFINE=	DOCS EXAMPLES

post-patch:
	@${REINPLACE_CMD} -e 's|/usr/local|${PREFIX}|g' ${WRKSRC}/config.h ${WRKSRC}/src/autoconf
# Allow parallel builds (-jX) to work
	@${FIND} ${WRKSRC} -name 'Makefile*' | ${XARGS} ${REINPLACE_CMD} -E -e 's|cd (.+); (\$$\(MAKE\))|\2 -C \1|' -e '/^MANDIR/s|/man|/share/man|'

post-install:
	${MKDIR} ${STAGEDIR}${DOCSDIR}/ ${STAGEDIR}${EXAMPLESDIR}/
	cd ${WRKSRC}/ && ${INSTALL_DATA} ${PORTDOCS} ${STAGEDIR}${DOCSDIR}/
	cd ${WRKSRC}/examples/ && ${INSTALL_DATA} ${PORTEXAMPLES} ${STAGEDIR}${EXAMPLESDIR}/

.include <bsd.port.mk>
