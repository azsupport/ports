# Mk/az-official.mk: an official port built as it is, as a port of this tree
# (aZ, 10.11.2026: the utilities of the servers in the repository az, without
# building PHP again). The port of this tree has the origin of the official one
# and a Makefile with the origin, the options it changes and this file:
#
#   AZ_OFFICIAL=	archivers/unzip
#   OPTIONS_SLAVE=	ICONV		(on, out of the dialog)
#   OPTIONS_EXCLUDE=	NLS		(off)
#   .include "${.CURDIR:H:H}/Mk/az-official.mk"
#
# The rest is the official port at the pinned commit of tools/build.sh: its
# Makefile (included below), and as MASTERDIR its distinfo, files/ (the patches),
# pkg-plist and pkg-descr; the options are those of the make.conf of the build
# (tools/make.conf.in) with the changes of the port's Makefile. Its revision is
# that of the build (AZ_STAMP), as for every port of this tree (each build an
# upgrade for pkg, also over the official package of the same version): a
# variable of the command line (.MAKEFLAGS), which the PORTREVISION= of the
# official Makefile does not replace.
#
# The az_hash of the port (tools/build.sh): its Makefile and this file, the
# official files by the commit of the official tree. Only these ports read this
# file: a change of it builds them again, nothing else.

MASTERDIR=	${PORTSDIR:U/usr/ports}/${AZ_OFFICIAL}
.MAKEFLAGS:	PORTREVISION=${AZ_STAMP:U0}
.include "${MASTERDIR}/Makefile"
