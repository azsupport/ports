# devel/git: the git of azsupport/ports in the place of the official devel/git
# (aZ, 10.11.2026), cut down for the servers: the official port (its default
# flavor, without the slave ports gui, cvs, p4 and svn) with CURL (clone, fetch
# and push over https through libcurl.so of our ftp/curl), ICONV (the iconv of
# libc) and PCRE2 (git grep -P; the shared library of devel/pcre2 of this tree),
# without PERL (no send-email, svn, gitweb, instaweb, cvs scripts: stubs that
# say so), CONTRIB, GITWEB, SEND_EMAIL, SUBTREE, DOCS and NLS, without expat
# (NO_EXPAT: only git http-push, the push over WebDAV, needs it), the man pages,
# the user git_daemon and the rc.d script of git daemon; so that it takes no
# package but our curl and pcre2.

PORTNAME=	git
DISTVERSION=	2.56.1
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	devel
MASTER_SITES=	KERNEL_ORG/software/scm/git

MAINTAINER=	github@azsupport.com
COMMENT=	Distributed source code management tool (of azsupport/ports)
WWW=		https://git-scm.com/ \
		https://github.com/azsupport/ports

LICENSE=	GPLv2
LICENSE_FILE=	${WRKSRC}/COPYING

LIB_DEPENDS=	libcurl.so:ftp/curl \
		libpcre2-8.so:devel/pcre2

USES=		autoreconf cpe gmake iconv shebangfix ssl tar:xz
CPE_VENDOR=	git-scm

GNU_CONFIGURE=	yes
CPPFLAGS+=	-isystem${LOCALBASE}/include
LDFLAGS+=	-L${LOCALBASE}/lib
MAKE_ARGS=	DEVELOPER= NO_RUST=yes NO_TCLTK=yes NO_PERL=1 NO_GETTEXT=yes \
		NO_EXPAT=1
MAKE_ENV+=	V=1 CURLDIR=${LOCALBASE}
SHEBANG_FILES=	Documentation/*.perl \
		contrib/*/*.perl \
		contrib/*/*.pl \
		contrib/*/*/*.perl \
		contrib/*/*/*.pl \
		contrib/contacts/git-contacts \
		contrib/fast-import/import-zips.py \
		git-p4.py \
		templates/hooks/fsmonitor-watchman.sample
TEST_TARGET=	test

CONFIGURE_ARGS=	--enable-pthreads=-pthread ac_cv_header_libcharset_h=no \
		--with-libpcre \
		--without-perl \
		--without-python

# This is intentionally not exposed as an option.
.if defined(STRIP) && ${STRIP} != ""
ALL_TARGET=	all strip
.endif

post-patch:
	@${REINPLACE_CMD} -e "s,%%SITE_PERL%%,,g" ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e '/git-cvsexportcommit.perl/d; \
		/git-cvsimport.perl/d; \
		/git-cvsserver.perl/d; \
		s/git-cvsserver//' \
		${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e '/^SCRIPT_PYTHON += git-p4.py$$/d' \
		${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e '/git-svn.perl/d' ${WRKSRC}/Makefile

post-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/bash_completion.d
	${INSTALL_SCRIPT} ${WRKSRC}/contrib/completion/git-completion.bash \
		${STAGEDIR}${PREFIX}/etc/bash_completion.d/
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/bin/scalar \
		${STAGEDIR}${PREFIX}/libexec/git-core/scalar

.include <bsd.port.mk>
