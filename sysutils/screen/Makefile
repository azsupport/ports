# sysutils/screen of azsupport/ports: the official port (Mk/azsupport-official.mk) with
# ncurses of the base system (NCURSES_BASE: never that of devel/ncurses) and the
# sockets of the sessions in ~/.screen (NOSOCKETDIR: a cleaning of /tmp does not take
# those of running sessions) (aZ, 10.11.2026).
#
# screen 5.0.3 (24.11.2026) ahead of the official port (5.0.2_2 at 0530184620), for
# a vulnerability that touches us (rule of 04.11.2026): FreeWindow() of window.c
# reset only the first canvas of a closed window and left the others pointing into
# the freed window (a use after free when a window shown in more than one region is
# closed or its program exits); SendCreateMsg() of socket.c appended the session name
# to SocketPath unbounded (now a length check). 5.0.3 has the three fixes of Debian
# this port carried since 12.11.2026 (CheckMaxSize() of resize.c, the padding escape
# of winmsg.c, defflow after a reattach in termcap.c: upstream 0934957, 6207d73,
# 3da0786), and the rendition modifiers + - ! = again (bug #67154), the default
# renditions of bell, monitor and silence, the three-digit RGB colours, the units of
# the resize prompt. This port gives the version (a variable of the command line: the
# DISTVERSION= of the official Makefile does not replace it), the distinfo (SHA-256
# the same from ftp.gnu.org, mirrors.kernel.org and ftpmirror.gnu.org, and as
# OpenBSD e15a21e7ab and Homebrew 630681b6ea have it) and the pkg-plist
# (bin/screen-5.0.3); the patches of the official port apply to 5.0.3 as to 5.0.2.
# Back to the official port as it is once it has 5.0.3 or later.

AZSUPPORT_OFFICIAL=	sysutils/screen
OPTIONS_EXCLUDE=	NCURSES_DEFAULT NCURSES_PORT
OPTIONS_SLAVE=	NCURSES_BASE NOSOCKETDIR
DISTINFO_FILE=	${.CURDIR}/distinfo
PLIST=		${.CURDIR}/pkg-plist
.MAKEFLAGS:	DISTVERSION=5.0.3

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
