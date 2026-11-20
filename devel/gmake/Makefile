# devel/gmake of azsupport/ports: the official port (Mk/az-official.mk), GNU make 4.4.1
# for the servers (aZ, 20.11.2026): the native extensions of gems are built with it
# there (MAKE=gmake; the Rust ones of rb_sys build with GNU make only), NLS off
# (tools/make.conf.in). The builds of this tree take the official package as their
# build tool (AZ_TOOLS_OFFICIAL of tools/build.sh), so this port builds nothing else
# again; the ports that run with it (RUN_DEPENDS of www/npm-node18 and www/npm-node24:
# node-gyp) get this one.

AZ_OFFICIAL=	devel/gmake

.include "${.CURDIR:H:H}/Mk/az-official.mk"
