# net/amnezia-kmod of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# the kernel module if_amn of AmneziaWG (WireGuard with its anti-detection) for
# net/amnezia-tools (aZ, 19.11.2026). Built against the sources of the kernel of the
# release of the build (tools/build.sh: gitup of releng/15.1 into /usr/src): one
# module for GENERIC and the kernel az.st of aZ (a module built outside the kernel
# has SMP, MAC and VIMAGE, which az.st has, and needs crypto, which az.st has
# built in); a new release of FreeBSD, a new build.

AZSUPPORT_OFFICIAL=	net/amnezia-kmod

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
