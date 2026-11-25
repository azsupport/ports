# sysutils/vm-bhyve of azsupport/ports: the official port (Mk/azsupport-official.mk), the
# manager of the virtual machines of bhyve (aZ, 19.11.2026), with the options of aZ
# (19.11.2026): BHYVE_FIRMWARE (UEFI guests: sysutils/bhyve-firmware, the edk2-bhyve
# of sysutils/edk2), GRUB2_BHYVE (guests booted by grub: sysutils/grub2-bhyve), TMUX
# (the console of a guest in tmux) and EXAMPLES (the templates of guests in
# share/examples/vm-bhyve: vm init copies their default.conf into .templates of
# vm_dir, and vm create without -t takes it; EXAMPLES is off in the make.conf of the
# builds, so it is an OPTIONS_SLAVE here).

AZSUPPORT_OFFICIAL=	sysutils/vm-bhyve
OPTIONS_SLAVE=	BHYVE_FIRMWARE EXAMPLES GRUB2_BHYVE TMUX

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
