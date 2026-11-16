# sysutils/fcron of azsupport/ports in the place of the official one (its Makefile,
# pkg-plist, pkg-descr, rc.d script and patches): fcron (aZ, 15.11.2026), without the
# docs and the examples (the make.conf of the build), 3.4.1 ahead
# of the official 3.2.1 (aZ, 16.11.2026). Of the official patches those of 3.4.1 as it
# is are kept (fileconf.c, save.c, m4/ax_lib_readline.m4, doc/en/man/fcron.8); what
# the others did is done by post-patch on the texts of 3.4.1, whose lines moved: the
# readline search of configure without libedit, the default paths of /var in
# fcron.conf.5 and fcrontab.1, pam_loginuid (Linux) out of files/fcron.pam.

PORTNAME=	fcron
PORTVERSION=	3.4.1
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	sysutils
MASTER_SITES=	http://fcron.free.fr/archives/ \
		ftp://ftp.seul.org/pub/fcron/
DISTNAME=	${PORTNAME}-${PORTVERSION}.src

MAINTAINER=	github@azsupport.com
COMMENT=	Periodic command scheduler (of azsupport/ports)
WWW=		http://fcron.free.fr/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv2

USES=		perl5 gmake
USE_PERL5=	build
USE_RC_SUBR=	fcron

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--localstatedir=/var \
		--with-cflags="${CFLAGS}" \
		--with-rootname=root --with-rootgroup=wheel \
		--with-docdir=${DOCSDIR} \
		--with-dsssl-dir=no

SUB_FILES=	pkg-message

WRKSRC=		${WRKDIR}/${PORTNAME}-${PORTVERSION}

USERS=		fcron
GROUPS=		fcron

PAMDIR?=	etc/pam.d
PLIST_SUB+=	PAMDIR=etc/pam.d

PORTDOCS=	*

DOCSRC=		${WRKSRC}/doc/en

OPTIONS_DEFINE=	DOCS EXAMPLES

post-patch:
	@${REINPLACE_CMD} -e 's/for readline_lib in readline edit editline/for readline_lib in readline editline/' \
		${WRKSRC}/configure
	@${REINPLACE_CMD} -e 's|/usr/local/var/spool/fcron|/var/spool/fcron|g' \
		-e 's|/usr/local/var/run/|/var/run/|g' \
		${WRKSRC}/doc/en/man/fcron.conf.5 ${WRKSRC}/doc/en/man/fcrontab.1
	@${REINPLACE_CMD} -e 's|^session[[:space:]]*required[[:space:]]*pam_loginuid\.so|#&|' \
		${WRKSRC}/files/fcron.pam

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/fcron ${STAGEDIR}${PREFIX}/sbin
	${INSTALL_PROGRAM} ${WRKSRC}/fcrontab ${STAGEDIR}${PREFIX}/bin
	${INSTALL_PROGRAM} ${WRKSRC}/fcrondyn ${STAGEDIR}${PREFIX}/bin
	${INSTALL_PROGRAM} ${WRKSRC}/fcronsighup ${STAGEDIR}${PREFIX}/bin
	${INSTALL_DATA} ${WRKSRC}/files/fcron.pam ${STAGEDIR}${PREFIX}/${PAMDIR}/fcron
	${INSTALL_DATA} ${WRKSRC}/files/fcrontab.pam ${STAGEDIR}${PREFIX}/${PAMDIR}/fcrontab
.for f in fcron.allow fcron.conf fcron.deny
	${INSTALL_DATA} -m 640 ${WRKSRC}/files/${f} ${STAGEDIR}${PREFIX}/etc/${f}.sample
.endfor
.for n in 1 5 8
	${INSTALL_MAN} ${DOCSRC}/man/*.${n} ${STAGEDIR}${PREFIX}/share/man/man${n}
.endfor
	${MKDIR} -m 770 ${STAGEDIR}/var/spool/fcron

do-install-DOCS-on:
.for d in txt HTML
	${MKDIR} ${STAGEDIR}${DOCSDIR}/${d}
	${INSTALL_DATA} ${DOCSRC}/${d}/* ${STAGEDIR}${DOCSDIR}/${d}
.endfor

do-install-EXAMPLES-on:
	${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	${INSTALL_DATA} ${FILESDIR}/fcrontab-* ${WRKSRC}/files/*.pam ${STAGEDIR}${EXAMPLESDIR}

.include <bsd.port.mk>
