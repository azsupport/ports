# devel/autoconf of azsupport/ports: the official port as it is (Mk/azsupport-official.mk),
# GNU autoconf 2.73, which the automake of devel/automake runs (aZ, 26.11.2026 13:09:
# «Делаем его самодостаточным — лишние зависимости убираем, нужные собираем у нас.»):
# with autoconf-switch of devel/autoconf-switch, m4 of devel/m4 and our lang/perl5.42;
# INFO off (tools/make.conf.in). The builds of this tree take the official package as
# their build tool (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh: phpize of every PHP
# module, USES=autoreconf), so this port builds again only devel/automake, which runs
# with it and gets this one (and with automake the ports that build with it).

AZSUPPORT_OFFICIAL=	devel/autoconf

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
