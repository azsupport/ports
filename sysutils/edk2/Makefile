# sysutils/edk2 of azsupport/ports: the official port as it is (Mk/az-official.mk),
# its default flavor bhyve (the package edk2-bhyve, the UEFI firmware of bhyve), for
# sysutils/bhyve-firmware and the UEFI guests of sysutils/vm-bhyve (aZ, 19.11.2026).
# Built with the GCC, Python and nasm of the official packages (build tools only).
# files/extra-patch-NetworkPkg_UefiPxeBcDxe-icmp: CVE-2026-97631, an ICMP error packet
# overflowing a buffer of the PXE boot (upstream 560ed9b5b146, after edk2-stable202608;
# the patch as Fedora carries it on 202608, it applies to 202508 as it is).

AZ_OFFICIAL=	sysutils/edk2
EXTRA_PATCHES=	${.CURDIR}/files/extra-patch-NetworkPkg_UefiPxeBcDxe-icmp:-p1

.include "${.CURDIR:H:H}/Mk/az-official.mk"
