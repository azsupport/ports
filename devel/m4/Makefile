# devel/m4 of azsupport/ports: the official port as it is (Mk/azsupport-official.mk), GNU
# m4 1.4.21, which the autoconf of devel/autoconf runs (aZ, 26.11.2026 13:09: «Делаем его
# самодостаточным — лишние зависимости убираем, нужные собираем у нас.»: every run
# dependency of a package of the repository is a package of it). INFO, NLS and EXAMPLES
# off (tools/make.conf.in), LIBSIGSEGV off (the default). The builds of this tree take
# the official package as their build tool (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh:
# databases/mongodb80), so this port builds nothing else again; devel/autoconf, which
# runs with it, gets this one.

AZSUPPORT_OFFICIAL=	devel/m4

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
