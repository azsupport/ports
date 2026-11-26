# devel/pkgconf of azsupport/ports: the official port (Mk/azsupport-official.mk), pkg-config
# 3.0.9 for the servers (aZ, 20.11.2026): the native extensions of gems find the
# libraries of the system with it there (nokogiri --use-system-libraries: libxml2 and
# libxslt, those of azsupport by PKG_CONFIG_PATH=/usr/local/azsupport/lib/pkgconfig), DOCS off
# (tools/make.conf.in). The builds of this tree take the official package as their
# build tool (AZSUPPORT_TOOLS_OFFICIAL of tools/build.sh), so this port builds nothing else
# again.

AZSUPPORT_OFFICIAL=	devel/pkgconf

# libpkgconf.so stripped too: the official port strips its programs only, and the debug
# check of tools/build.sh failed the package (run 45818202408); in the targets of the
# option DOCS, so that the post-install of the official port stays as it is
post-install-DOCS-on post-install-DOCS-off:
	${STRIP_CMD} ${STAGEDIR}${PREFIX}/lib/libpkgconf.so.[0-9]*.[0-9]*.[0-9]*

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
