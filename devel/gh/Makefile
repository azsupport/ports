# devel/gh of azsupport/ports: the official port (Mk/azsupport-official.mk), the command line
# tool of GitHub (aZ, 20.11.2026: the steps of the builds on the runner in a jail of
# FreeBSD, devel/github-act-runner, call gh api), on the git of our devel/git, with its
# telemetry off unless the user turns it on (aZ, 21.11.2026: «ну конечно!»): gh sends
# GitHub a device id and the commands it runs by default since 2.9x.
# - files/extra-patch-telemetry-opt-in: the patch of Fedora (its package gh, commit
#   d679c3d, 24.04.2026): only a true value of GH_TELEMETRY (1, true, yes, enabled, on)
#   or of the config option telemetry turns it on, log prints it instead of sending;
# - files/extra-patch-telemetry-config-default: the default of the option "disabled"
#   (ours): the patch of Fedora takes the default "enabled" of the option for an
#   opt-in, so without this one gh would still send it where nobody chose it.
# Turning it on: gh config set telemetry enabled, or GH_TELEMETRY=1.

AZSUPPORT_OFFICIAL=	devel/gh
EXTRA_PATCHES=	${.CURDIR}/files/extra-patch-telemetry-opt-in:-p1 \
		${.CURDIR}/files/extra-patch-telemetry-config-default:-p1

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
