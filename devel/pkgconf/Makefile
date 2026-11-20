# devel/pkgconf of azsupport/ports: the official port (Mk/azsupport-official.mk), pkg-config
# 3.0.9 for the servers (aZ, 20.11.2026): the native extensions of gems find the
# libraries of the system with it there (nokogiri --use-system-libraries: libxml2 and
# libxslt, those of az by PKG_CONFIG_PATH=/usr/local/az/lib/pkgconfig), DOCS off
# (tools/make.conf.in). The builds of this tree take the official package as their
# build tool (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh), so this port builds nothing else
# again.

AZSUPPORT_OFFICIAL=	devel/pkgconf

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
