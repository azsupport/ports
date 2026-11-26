# devel/autoconf-switch of azsupport/ports: the official port as it is
# (Mk/azsupport-official.mk), the scripts autoconf, autoheader, autom4te, autoreconf ...
# that run the autoconf of DEFAULT_AUTOCONF (aZ, 26.11.2026 13:09: «Делаем его
# самодостаточным — лишние зависимости убираем, нужные собираем у нас.»): the autoconf of
# devel/autoconf runs with it. The builds of this tree take the official package as
# their build tool (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh), so this port builds
# nothing else again; devel/autoconf, which runs with it, gets this one.

AZSUPPORT_OFFICIAL=	devel/autoconf-switch

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
