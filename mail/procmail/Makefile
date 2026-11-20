# mail/procmail of azsupport/ports: the official port (Mk/az-official.mk), procmail
# 3.22, the local delivery and its filters (aZ, 20.11.2026: «procmail надо»),
# without DOCS and EXAMPLES (tools/make.conf.in), with four fixes of memory errors the
# port lacks (procmail is setuid root, and reads the mail of anyone and the rcfiles of
# the users), as Debian carries them on 3.22 (3.24+really3.22-6) and upstream has
# them in 3.24 (BuGlessRB/procmail, 05.05.2020):
# - files/extra-patch-src_from.c-incomplete-From: a mail that ended inside a long
#   From_ line left a null pointer to the rest of the mail (Debian bug 769938, a
#   crash; upstream 039b8ce);
# - files/extra-patch-src_formail.c-memory: formail copied a header field into a
#   buffer one byte short, and a trailing backslash of an address read past its end
#   (Debian patch 29, upstream d35595a);
# - files/extra-patch-src_cstdio.c-overflow: a long line of an rcfile wrote one byte
#   past the line buffer (Debian patch 28, upstream 6de70f9);
# - files/extra-patch-src_mailfold.c-linkfolder: the names of the extra folders of a
#   delivery copied into a buffer one byte short (Debian bugs 474298 and 484352,
#   upstream 990f9d4).
# After the official Makefile, which sets EXTRA_PATCHES (its getline patch): do-patch
# reads the variable only when it runs.

AZ_OFFICIAL=	mail/procmail

.include "${.CURDIR:H:H}/Mk/az-official.mk"

EXTRA_PATCHES+=	${.CURDIR}/files/extra-patch-src_from.c-incomplete-From:-p1 \
		${.CURDIR}/files/extra-patch-src_formail.c-memory:-p1 \
		${.CURDIR}/files/extra-patch-src_cstdio.c-overflow:-p1 \
		${.CURDIR}/files/extra-patch-src_mailfold.c-linkfolder:-p1
