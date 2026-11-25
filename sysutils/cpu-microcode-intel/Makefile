# sysutils/cpu-microcode-intel of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), the microcode updates of Intel CPUs (aZ,
# 15.11.2026): /boot/firmware/intel-ucode.bin and the split files of cpucontrol(8)
# (SPLIT, its default), with RC: the rc.d script of sysutils/cpu-microcode-rc as a
# dependency, as cpu-microcode-amd has it always (aZ, 15.11.2026: «пусть будет
# зависимостью у обоих интел и амд»).

AZSUPPORT_OFFICIAL=	sysutils/cpu-microcode-intel
OPTIONS_SLAVE=	RC

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
