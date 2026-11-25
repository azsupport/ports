# www/fcgiwrap of azsupport/ports: the official port (Mk/azsupport-official.mk; aZ, 20.11.2026),
# fcgiwrap 1.1.0, the FastCGI server that runs CGI scripts for nginx, on the libfcgi of
# fcgi-devkit (www/fcgi of the FreeBSD repository); its rc script fcgiwrap with
# profiles. With two fixes the official port lacks (each file of files/ says what and
# where from): the parent of the preforked children busy in its SIGCHLD handler
# (upstream after 1.1.0), and the CGI child of a failed request not stopped (kill() with
# its arguments swapped; upstream pull request #44, as Gentoo carries it).

AZSUPPORT_OFFICIAL=	www/fcgiwrap
EXTRA_PATCHES=	${.CURDIR}/files/patch-fcgiwrap.c-sigchld \
		${.CURDIR}/files/patch-fcgiwrap.c-kill

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
