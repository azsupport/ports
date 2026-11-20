# shells/bash of azsupport/ports: the official port (Mk/az-official.mk) without
# NLS (translations: gettext), on the GNU readline of az (aZ 20.11.2026 19:59: «зачем ты
# встраивал readline если у нас есть эта библиотка в az?»: the official port builds the
# copy of readline in bash into it, statically, unless PORTS_READLINE, which takes the
# package of devel/readline): libreadline.so and libhistory.so 8.3.6 of az, with the run
# path /usr/local/az/lib (--with-installed-readline: bash 5.3 takes readline 8.3); the
# fix of the prompt of readline in a single-byte locale (C) after a line that wrapped
# (Gentoo) is in that readline (az/az/files/deps/readline-8.3.6.patch). With three fixes
# the official port lacks (12.11.2026; each file of files/ says what and where from).

AZ_OFFICIAL=	shells/bash
OPTIONS_EXCLUDE=	NLS
# the saved status of an ended background job kept when a foreground child gets its
# pid, and the exported environment made once for a command substitution (both from
# the devel branch of bash, as Gentoo carries them on 5.3.20); a byte 0x80-0xFF in
# ${...} read before the table of legal_variable_starter() of
# bash53-019 (the workaround of bug-bash, as openSUSE carries it)
EXTRA_PATCHES=	${.CURDIR}/files/patch-jobs.c-bgp_delete \
		${.CURDIR}/files/patch-execute_cmd.c-comsub-env \
		${.CURDIR}/files/patch-general.h-unsigned-char
# the readline of az: its headers and libraries alone in ${WRKDIR}/az (the include
# directory of az has others, GNU iconv.h among them), its run path
BUILD_DEPENDS+=	${AZ_PREFIX}/lib/libreadline.so:az/az
RUN_DEPENDS+=	${AZ_PREFIX}/lib/libreadline.so:az/az
CONFIGURE_ARGS+=	--with-installed-readline=${WRKDIR}/az
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

pre-configure:
	@${MKDIR} ${WRKDIR}/az/include ${WRKDIR}/az/lib
	${LN} -sf ${AZ_PREFIX}/include/readline ${WRKDIR}/az/include/readline
	${LN} -sf ${AZ_PREFIX}/lib/libreadline.so ${AZ_PREFIX}/lib/libhistory.so \
		${WRKDIR}/az/lib/

.include "${.CURDIR:H:H}/Mk/az-official.mk"
