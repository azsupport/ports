# www/apache24-suexec of azsupport/ports: suexec of www/apache24 apart from it, for
# the one server whose sites in /var/www run their CGI and FastCGI programs as their
# users (aZ, 19.11.2026: suexec on one server only, not in every apache24): the same
# Apache (MASTERDIR) built with SUEXEC, of which this package has only
# libexec/apache24/mod_suexec.so and sbin/suexec (setuid root; only the user www may
# run it), on the httpd of the package apache24, which it depends on; the modules of
# that Apache (mod_php, mod_maxminddb, mod_fastcgi) stay on apache24. suexec with the
# docroot /var/www in the place of the default of Mk/Uses/apache.mk
# (${PREFIX}/www/data); its other settings the defaults there: the caller www, the
# least uid and gid 1000, the log /var/log/httpd-suexec.log, the safe path
# ${LOCALBASE}/bin:/usr/bin:/bin, the user directory public_html (for the ~user URLs of
# mod_userdir, which this Apache does not build). The variables of the master that
# would make this package a second Apache (its rc.d scripts, install scripts, plist,
# message and dependencies: this one depends on apache24 alone) are given on the
# command line of make (.MAKEFLAGS), which its assignments do not replace;
# Makefile.options and Makefile.options.desc here include those of the master, which
# its Makefile reads from ${.CURDIR}.

PKGNAMESUFFIX=	-suexec
MASTERDIR=	${.CURDIR}/../apache24
OPTIONS_SLAVE=	SUEXEC
SUEXEC_DOCROOT=	/var/www
.MAKEFLAGS:	USE_RC_SUBR= SUB_FILES= PLIST=${.CURDIR}/pkg-plist \
		PKGMESSAGE=${.CURDIR}/pkg-message RUN_DEPENDS=apache24>0:www/apache24

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/libexec/apache24 ${STAGEDIR}${PREFIX}/sbin
	${INSTALL_LIB} ${WRKSRC}/modules/generators/.libs/mod_suexec.so \
		${STAGEDIR}${PREFIX}/libexec/apache24
	${INSTALL_PROGRAM} ${WRKSRC}/support/suexec ${STAGEDIR}${PREFIX}/sbin

.include "${MASTERDIR}/Makefile"
