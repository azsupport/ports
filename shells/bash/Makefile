# shells/bash of azsupport/ports: the official port (Mk/azsupport-official.mk) without
# NLS (translations: gettext); with four fixes the official port lacks (12.11.2026;
# each file of files/ says what and where from).
# The C compiled by GCC 16 of the ports (Mk/Uses/azgcc.mk; a build dependency only; the
# USES of the official Makefile get it by AZSUPPORT_USES of Mk/bsd.overlay.mk), aZ
# 27.11.2026 08:43 («окей, следуем инфе с тестов»): prog-bench (arith, array, case, func,
# read, string) against the base clang 19, run 45926215732: GCC 16 -6.3%, clang 23 -1.4% by
# the median, GCC 16 faster than clang 23 by 5.1%, clear in 4 of 6 (array, case, func, read
# 5-6%); faster than clang 23 on three other machines too (45905132701, 45913465743,
# 45918232254). The loadable builtins (lib/bash) without the -pie of the LDFLAGS of the
# framework in their SHOBJ_LDFLAGS (post-configure): GCC takes a -pie after -shared for a
# program and links a shared object as one (Scrt1.o: undefined reference to main; clang
# leaves -pie out with -shared); bash itself stays a PIE. Makefile.inc, bash.pc and bashbug
# name cc (Mk/azsupport-cc-names.sh).

AZSUPPORT_OFFICIAL=	shells/bash
OPTIONS_EXCLUDE=	NLS
AZSUPPORT_USES=		azgcc
# the saved status of an ended background job kept when a foreground child gets its
# pid, and the exported environment made once for a command substitution (both from
# the devel branch of bash, as Gentoo carries them on 5.3.20); the prompt of the
# readline of bash in a single-byte locale (C) after a line that wrapped (Gentoo);
# a byte 0x80-0xFF in ${...} read before the table of legal_variable_starter() of
# bash53-019 (the workaround of bug-bash, as openSUSE carries it)
EXTRA_PATCHES=	${.CURDIR}/files/patch-jobs.c-bgp_delete \
		${.CURDIR}/files/patch-execute_cmd.c-comsub-env \
		${.CURDIR}/files/patch-lib_readline_display.c-single-byte-prompt \
		${.CURDIR}/files/patch-general.h-unsigned-char

post-configure:
	@${REINPLACE_CMD} -E -e '/^SHOBJ_LDFLAGS[[:space:]]*=/s/[[:space:]]-pie([[:space:]]|$$)/\1/' \
		${WRKSRC}/examples/loadables/Makefile ${WRKSRC}/examples/loadables/Makefile.inc
	@if ${GREP} -E -n '^SHOBJ_LDFLAGS.*[[:space:]]-pie([[:space:]]|$$)' ${WRKSRC}/examples/loadables/Makefile \
		${WRKSRC}/examples/loadables/Makefile.inc; then ${ECHO_MSG} "-pie in SHOBJ_LDFLAGS still (above)"; ${FALSE}; fi

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"

