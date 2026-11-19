# net/amnezia-tools of azsupport/ports: the official port as it is
# (Mk/az-official.mk), awg and awg-quick of AmneziaWG (WireGuard with its
# anti-detection) and its rc.d script amnezia (aZ, 19.11.2026), on the kernel module
# if_amn of net/amnezia-kmod: awg-quick makes the interface with ifconfig amn create,
# and only without the module (or with UserLand = true) runs amneziawg-go, which az
# does not have (aZ, 19.11.2026: with the module it is not needed). awg-quick is a
# script of bash (shells/bash); its bash completion files as in the official port.

AZ_OFFICIAL=	net/amnezia-tools

.include "${.CURDIR:H:H}/Mk/az-official.mk"
