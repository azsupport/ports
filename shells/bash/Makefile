# shells/bash of azsupport/ports: the official port (Mk/az-official.mk) without
# NLS (translations: gettext); with four fixes the official port lacks (12.11.2026;
# each file of files/ says what and where from).

AZ_OFFICIAL=	shells/bash
OPTIONS_EXCLUDE=	NLS
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

.include "${.CURDIR:H:H}/Mk/az-official.mk"
