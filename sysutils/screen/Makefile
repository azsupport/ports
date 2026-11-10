# sysutils/screen of azsupport/ports: the official port (Mk/az-official.mk) with
# ncurses of the base system (NCURSES_BASE: never that of devel/ncurses) and the
# sockets of the sessions in ~/.screen (NOSOCKETDIR: a cleaning of /tmp does not take
# those of running sessions) (aZ, 10.11.2026).

AZ_OFFICIAL=	sysutils/screen
OPTIONS_EXCLUDE=	NCURSES_DEFAULT NCURSES_PORT
OPTIONS_SLAVE=	NCURSES_BASE NOSOCKETDIR

.include "${.CURDIR:H:H}/Mk/az-official.mk"
