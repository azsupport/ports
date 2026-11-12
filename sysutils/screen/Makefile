# sysutils/screen of azsupport/ports: the official port (Mk/az-official.mk) with
# ncurses of the base system (NCURSES_BASE: never that of devel/ncurses) and the
# sockets of the sessions in ~/.screen (NOSOCKETDIR: a cleaning of /tmp does not take
# those of running sessions) (aZ, 10.11.2026); with three fixes of Debian
# (12.11.2026).

AZ_OFFICIAL=	sysutils/screen
OPTIONS_EXCLUDE=	NCURSES_DEFAULT NCURSES_PORT
OPTIONS_SLAVE=	NCURSES_BASE NOSOCKETDIR
# The fixes of screen 5.0.2 that Debian sid carries (5.0.2-1; sent to savannah,
# #68360 and #68263, not taken yet), as they are (see the files): CheckMaxSize()
# of resize.c grew its buffers one entry short when a window became as wide as
# the widest one before (a write past the end of the heap buffer on a resize);
# the last byte of a status line or caption with a padding escape (%10=) left
# uninitialised (winmsg.c); defflow not restored after a reattach (termcap.c).
# screen is not setuid here (MULTIUSER off): a crash and garbage on the screen.
EXTRA_PATCHES=	${.CURDIR}/files/patch-resize.c:-p1 \
		${.CURDIR}/files/patch-winmsg.c:-p1 \
		${.CURDIR}/files/patch-termcap.c:-p1

.include "${.CURDIR:H:H}/Mk/az-official.mk"
