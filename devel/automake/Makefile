# devel/automake of azsupport/ports: the official port as it is (Mk/az-official.mk),
# automake 1.20 of the pinned tree. Mk/Uses/autoreconf.mk of the pin wants
# automake>=1.20 (freebsd-ports ecc7f3b72b, 16.11.2026), while the official packages
# of FreeBSD:15:amd64/latest the builds take their tools from had not caught up with it
# (13Z0 run 44467738766, 19.11.2026: az/az failed, "depends on package:
# automake>=1.20"); a build tool only, no server needs it.

AZ_OFFICIAL=	devel/automake

.include "${.CURDIR:H:H}/Mk/az-official.mk"
