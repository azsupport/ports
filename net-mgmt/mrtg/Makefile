# net-mgmt/mrtg of azsupport/ports in the place of the official one (aZ, 20.11.2026, with
# net-mgmt/net-snmp): MRTG 2.17.10 of Tobias Oetiker, the official port of the pinned tree
# (its patches, files/mrtg_daemon.in, pkg-install, pkg-deinstall and pkg-message,
# distinfo, pkg-plist) with its default options (DOCS, EXAMPLES, IPV6 and SNMPV3 off),
# but rateup, which draws the graphs, on the libgd and libpng of az (/usr/local/az/lib,
# our ports link each other's shared libraries: aZ, 10.11.2026), not the packages of
# graphics/gd and graphics/png; SNMP_Session of net-mgmt/p5-SNMP_Session of this tree
# (aZ, 20.11.2026: «давай в наши порты»), not Pod::Parser and Module::CoreList, which
# the official port takes: the scripts of MRTG use Pod::Usage, which the perl 5.42 of
# this tree has without Pod::Parser, and Module::CoreList is in its core. With two
# fixes upstream made after 2.17.10, as Debian carries them: files/patch-CVE-2026-72694
# (the pid file of mrtg --daemon, which root created and chowned through a symbolic
# link of the user of the daemon) and files/patch-bin_mrtg-RouterUpTime (the options of
# a target of RouterUpTime dropped); the other fixes of Debian are in the official port
# (cfgmaker: ubiquiti, the counter value 0 of noHC) or are of its documents and builds.

PORTNAME=	mrtg
DISTVERSION=	2.17.10
PORTREVISION=	${AZ_STAMP:U0}
PORTEPOCH=	1
CATEGORIES=	net-mgmt
MASTER_SITES=	https://github.com/oetiker/${PORTNAME}/releases/download/v${DISTVERSION}/ \
		https://oss.oetiker.ch/${PORTNAME}/pub/

MAINTAINER=	github@azsupport.com
COMMENT=	Multi-router traffic grapher (of azsupport/ports)
WWW=		https://oss.oetiker.ch/mrtg/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv2

# libgd.so and libpng.so of az (rateup links -lgd -lpng -lz: its configure)
BUILD_DEPENDS=	${AZ_PREFIX}/lib/libgd.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libgd.so:az/az \
		p5-SNMP_Session>=0:net-mgmt/p5-SNMP_Session

USES=		perl5 shebangfix

# the headers and the libraries of gd and png of az alone (links in ${WRKDIR}/az), not
# the include directory of az with its other headers (iconv.h of GNU libiconv), and
# their run path
CONFIGURE_ARGS=	--with-gd-lib=${WRKDIR}/az/lib \
		--with-gd-inc=${WRKDIR}/az/include
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

USERS=		mrtg
GROUPS=		mrtg

MAKE_ENV+=	PERL=${PERL}
MRTG_RUNDIR?=	/var/run/mrtg
SHEBANG_FILES=	bin/cfgmaker bin/indexmaker bin/mrtg bin/mrtg-traffic-sum
perl_OLD_CMD=	/home/oetiker/.plenv/shims/perl

USE_RC_SUBR=	mrtg_daemon
SUB_FILES=	pkg-deinstall pkg-install pkg-message
SUB_LIST=	PERL=${PERL} \
		MRTG_RUNDIR=${MRTG_RUNDIR} \
		USERS=${USERS} \
		GROUPS=${GROUPS}
PKGINSTALL=	${WRKDIR}/pkg-install
PKGDEINSTALL=	${WRKDIR}/pkg-deinstall

GNU_CONFIGURE=	YES
CONFIGURE_ENV=	PERL=${PERL}

MANPAGE=	cfgmaker.1 indexmaker.1 mrtg-contrib.1 mrtg-faq.1 mrtg-forum.1 \
		mrtg-ipv6.1 mrtg-logfile.1 mrtg-mibhelp.1 mrtg-nt-guide.1 \
		mrtg-nw-guide.1 mrtg-reference.1 mrtg-rrd.1 mrtg-squid.1 \
		mrtg-unix-guide.1 mrtg-webserver.1 mrtg.1
MANPAGE3=	mrtglib.3

DOCS=		CHANGES COPYRIGHT MANIFEST README
EXAMPLES=	cfgmaker.pod indexmaker.pod mrtg-contrib.pod mrtg-faq.pod \
		mrtg-forum.pod mrtg-ipv6.pod mrtg-logfile.pod mrtg-mibhelp.pod \
		mrtg-nt-guide.pod mrtg-nw-guide.pod mrtg-reference.pod \
		mrtg-rrd.pod mrtg-squid.pod mrtg-unix-guide.pod mrtg.pod \
		mrtg-webserver.pod mrtglib.pod cfgmaker.txt indexmaker.txt \
		mrtg-contrib.txt mrtg-faq.txt mrtg-forum.txt mrtg-ipv6.txt \
		mrtg-logfile.txt mrtg-mibhelp.txt mrtg-nt-guide.txt \
		mrtg-nw-guide.txt mrtg-reference.txt mrtg-rrd.txt \
		mrtg-squid.txt mrtg-unix-guide.txt mrtg-webserver.txt \
		mrtg.txt mrtglib.txt
IMAGES=		favicon.ico mrtg-l.gif mrtg-l.png mrtg-m.gif mrtg-m.png \
		mrtg-r.gif mrtg-r.png mrtg-ti.gif mrtg-ti.png
SCRIPTS=	cfgmaker indexmaker mrtg mrtg-traffic-sum

OPTIONS_DEFINE=	DOCS EXAMPLES IPV6 SNMPV3
SNMPV3_DESC=	Build with support for SNMPv3

IPV6_RUN_DEPENDS=	p5-IO-Socket-INET6>=0:net/p5-IO-Socket-INET6
SNMPV3_RUN_DEPENDS=	p5-Net-SNMP>=0:net-mgmt/p5-Net-SNMP

PORTDOCS=	*
PORTEXAMPLES=	*

post-extract:
	@${FIND} ${WRKSRC} -type f -name "*.orig" -delete

post-patch:
	@${RM} ${WRKSRC}/lib/mrtg2/BER.pm ${WRKSRC}/lib/mrtg2/SNMP_*.pm

pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib
	${LN} -sf ${AZ_PREFIX}/include/gd*.h ${WRKDIR}/az/include/
	${LN} -sf ${AZ_PREFIX}/lib/libgd.so ${AZ_PREFIX}/lib/libpng.so ${WRKDIR}/az/lib/

do-install:
	@${MKDIR} ${STAGEDIR}${DOCSDIR} \
		${STAGEDIR}${EXAMPLESDIR}/doc \
		${STAGEDIR}${EXAMPLESDIR}/images \
		${STAGEDIR}${ETCDIR} \
		${STAGEDIR}${PREFIX}/${SITE_PERL_REL}
	${INSTALL_DATA} ${DOCS:S,^,${WRKSRC}/,} ${STAGEDIR}${DOCSDIR}/
	${INSTALL_DATA} ${EXAMPLES:S,^,${WRKSRC}/doc/,} \
		${STAGEDIR}${EXAMPLESDIR}/doc/
	${INSTALL_DATA} ${IMAGES:S,^,${WRKSRC}/images/,} \
		${STAGEDIR}${EXAMPLESDIR}/images/
	${INSTALL_DATA} ${WRKSRC}/contrib/mrtgmk/cfg/mrtg.cfg \
		${STAGEDIR}${ETCDIR}/mrtg.cfg.sample
	${INSTALL_DATA} ${MANPAGE:S,^,${WRKSRC}/doc/,} \
		${STAGEDIR}${PREFIX}/share/man/man1/
	${INSTALL_DATA} ${MANPAGE3:S,^,${WRKSRC}/doc/,} \
		${STAGEDIR}${PREFIX}/share/man/man3/
	cd ${WRKSRC}/lib/mrtg2 && \
		${COPYTREE_SHARE} "*.pm" ${STAGEDIR}${PREFIX}/${SITE_PERL_REL}
	${INSTALL_PROGRAM} ${WRKSRC}/bin/rateup ${STAGEDIR}${PREFIX}/bin/
	${INSTALL_SCRIPT} ${SCRIPTS:S,^,${WRKSRC}/bin/,} \
		${STAGEDIR}${PREFIX}/bin/

.include <bsd.port.mk>
