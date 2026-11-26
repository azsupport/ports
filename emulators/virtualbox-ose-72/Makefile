# emulators/virtualbox-ose-72 of azsupport/ports: the official port (Mk/azsupport-official.mk),
# VirtualBox 7.2 for a server of aZ (20.11.2026), in the flavor nox11 only (the package
# virtualbox-ose-nox11-72: VBoxManage, VBoxHeadless, VBoxSVC, VBoxBalloonCtrl,
# VBoxAutostart, the rc.d scripts vboxheadless and vboxwatchdog), on the kernel modules
# of emulators/virtualbox-ose-kmod-72. The options of aZ: AIO, TPM, UDPTUNNEL and VNC
# on; PYTHON, R0LOGGING, VBOXIMG, VDE and WEBSERVICE off (the official Makefile sets
# OPTIONS_EXCLUDE by its flavor, so these are those of the architecture, amd64, the
# only one of the port); ALSA, DBUS, DEBUG, DOCS, GUESTADDITIONS, NLS, PULSEAUDIO, QT6
# and X11 are those the flavor nox11 leaves out.
#
# libjpeg (mozjpeg), libpng and libxml2 of azsupport (/usr/local/azsupport/lib, our ports link each
# other's shared libraries: aZ, 10.11.2026), not the packages of graphics/mozjpeg,
# graphics/png and textproc/libxml2 the official port takes (LIB_DEPENDS, USES=jpeg and
# USE_GNOME=libxml2): LIB_DEPENDS is given on the command line of make (.MAKEFLAGS),
# which the assignments of the official Makefile and of its USES do not change, with
# the other libraries of the official port, each of a port of this tree: libcurl of
# ftp/curl; libogg, libvorbis and libvpx (the recording), libtpms (TPM) and libvncserver
# (VNC) of audio/libogg, audio/libvorbis, multimedia/libvpx, sysutils/libtpms and
# net/libvncserver, the official ports as they are (libvncserver on the libpng and
# libjpeg of azsupport, with archivers/lzo2, security/libgcrypt and security/libgpg-error).
# Those five were the official packages of FreeBSD, which the repository does not have,
# until aZ took that back (26.11.2026 13:09: «Делаем его самодостаточным — лишние
# зависимости убираем, нужные собираем у нас.»). For the libraries of azsupport, Mk/azsupport-libs.mk: their
# headers alone and their .pc files (the configure of VirtualBox finds libxml2 and
# libjpeg by pkg-config), its BUILD_DEPENDS and RUN_DEPENDS once more as those of the
# flavor (the official Makefile assigns both; the framework adds these after it). Before
# the configure: libpng of azsupport in it in the place of that of ${LOCALBASE} (it does not
# ask pkg-config for it), the run path of azsupport in its test programs, which it runs; the
# three in LocalConfig.kmk by their paths (kBuild links a library named by a path as it
# is), so that the official ones in the build (libxml2 of the build tool xsltproc of
# textproc/libxslt) are not linked, and
# /usr/local/azsupport/lib in the run path of every program and library of VirtualBox after
# its own directory. post-stage checks what they link.

# The package virtualbox72 (aZ, 21.11.2026: the name with the version, as php84):
# PKGBASE, and PKGNAME on the command line of make (.MAKEFLAGS), as the PKGNAME= of
# bsd.port.mk would replace it; PORTNAME stays virtualbox-ose, so the files are where
# the official port puts them (lib/virtualbox, share/virtualbox-ose) and the origin
# stays emulators/virtualbox-ose-72. The CONFLICTS_INSTALL of the official port names
# its packages (virtualbox-ose, -legacy, -70, -71, -72 and the -nox11 of each).
PKGBASE=	virtualbox72
.MAKEFLAGS:	PKGNAME=virtualbox72-$${PKGVERSION}

FLAVOR=		nox11
AZSUPPORT_OFFICIAL=	emulators/virtualbox-ose-72
OPTIONS_SLAVE=	AIO TPM UDPTUNNEL VNC
OPTIONS_EXCLUDE_amd64=	PYTHON R0LOGGING VBOXIMG VDE WEBSERVICE
.MAKEFLAGS:	LIB_DEPENDS="libcurl.so:ftp/curl libogg.so:audio/libogg \
		libvorbis.so:audio/libvorbis libvorbisenc.so:audio/libvorbis \
		libvpx.so:multimedia/libvpx libtpms.so:sysutils/libtpms \
		libvncserver.so:net/libvncserver"

AZSUPPORT_LIBS=	libxml2:libxml2.so mozjpeg:libjpeg.so png:libpng16.so
.include "${.CURDIR:H:H}/Mk/azsupport-libs.mk"
nox11_BUILD_DEPENDS=	${AZSUPPORT_PREFIX}/lib/libjpeg.so:azsupport/mozjpeg \
			${AZSUPPORT_PREFIX}/lib/libpng16.so:azsupport/png \
			${AZSUPPORT_PREFIX}/lib/libxml2.so:azsupport/libxml2
nox11_RUN_DEPENDS=	${nox11_BUILD_DEPENDS}

pre-configure:
	@${REINPLACE_CMD} -e 's|INCPNG="-I${LOCALBASE}/include"|INCPNG="-I${AZSUPPORT_PREFIX}/include/libpng16"|' \
		-e 's|LIBPNG="-L${LOCALBASE}/lib -lpng"|LIBPNG="-L${AZSUPPORT_PREFIX}/lib -lpng16"|' \
		-e 's|^CXX_FLAGS=""|CXX_FLAGS="-Wl,-rpath,${AZSUPPORT_PREFIX}/lib"|' \
		${WRKSRC}/configure
	@for l in 'INCPNG="-I${AZSUPPORT_PREFIX}/include/libpng16"' 'LIBPNG="-L${AZSUPPORT_PREFIX}/lib -lpng16"' \
	    'CXX_FLAGS="-Wl,-rpath,${AZSUPPORT_PREFIX}/lib"'; do \
		${GREP} -q -F "$$l" ${WRKSRC}/configure && continue; \
		${ECHO_MSG} "===>  configure: no $$l after the replacement (its lines for FreeBSD changed?)"; \
		exit 1; \
	done
	@${ECHO_CMD} 'SDK_VBoxLibXml2_INCS := ${AZSUPPORT_LIBS_DIR}/include/libxml2' >> ${WRKSRC}/LocalConfig.kmk
	@${ECHO_CMD} 'SDK_VBoxLibXml2_LIBS := ${AZSUPPORT_PREFIX}/lib/libxml2.so' >> ${WRKSRC}/LocalConfig.kmk
	@${ECHO_CMD} 'SDK_VBoxLibPng_INCS := ${AZSUPPORT_PREFIX}/include/libpng16' >> ${WRKSRC}/LocalConfig.kmk
	@${ECHO_CMD} 'SDK_VBoxLibPng_LIBS := ${AZSUPPORT_PREFIX}/lib/libpng16.so' >> ${WRKSRC}/LocalConfig.kmk
	@${ECHO_CMD} 'SDK_VBoxLibJpeg_INCS := ${AZSUPPORT_LIBS_DIR}/include' >> ${WRKSRC}/LocalConfig.kmk
	@${ECHO_CMD} 'SDK_VBoxLibJpeg_LIBS := ${AZSUPPORT_PREFIX}/lib/libjpeg.so' >> ${WRKSRC}/LocalConfig.kmk
	@${ECHO_CMD} 'VBOX_WITH_RUNPATH := $$(VBOX_WITH_RUNPATH):${AZSUPPORT_PREFIX}/lib' >> ${WRKSRC}/LocalConfig.kmk

# what the programs and libraries of VirtualBox link (readelf -d): libxml2, libpng16 and
# libjpeg (of azsupport: each that needs one has ${AZSUPPORT_PREFIX}/lib in its run path), libcurl,
# libvpx, libogg, libvorbis, libtpms and libvncserver, each by some file (none built into
# VirtualBox from its own sources, which its configure does when it finds no library)
post-stage:
	@cd ${STAGEDIR}${PREFIX}/lib/virtualbox || exit 1; \
	need=""; bad=""; \
	for f in $$(${FIND} . -type f \( -name '*.so' -o -perm -u+x \)); do \
		d="$$(/usr/bin/readelf -d "$$f" 2> /dev/null)" || continue; \
		n="$$(printf '%s\n' "$$d" | ${SED} -n 's/.*[Ss]hared library: *\[\(.*\)\].*/\1/p' | ${TR} '\n' ' ')"; \
		need="$$need $$n"; \
		case " $$n" in *" libxml2.so."* | *" libpng16.so."* | *" libjpeg.so."*) \
			printf '%s\n' "$$d" | ${SED} -n 's/.*[Ll]ibrary r[a-z]*path: *\[\(.*\)\].*/\1/p' | \
				${TR} ':' '\n' | ${GREP} -qx '${AZSUPPORT_PREFIX}/lib' || bad="$$bad $${f#./}" ;; \
		esac; \
	done; \
	miss=""; \
	for l in libxml2 libpng16 libjpeg libcurl libvpx libogg libvorbis libtpms libvncserver; do \
		case " $$need" in *" $$l.so."*) ;; *) miss="$$miss $$l" ;; esac; \
	done; \
	${ECHO_MSG} "===>  The libraries the programs and libraries of VirtualBox link:$$(printf ' %s\n' $$need | ${GREP} -v '^ VBox' | ${SORT} -u | ${TR} -d '\n')"; \
	[ -z "$$miss" ] || ${ECHO_MSG} "===>  linked by no file (built into VirtualBox from its own sources?):$$miss"; \
	[ -z "$$bad" ] || ${ECHO_MSG} "===>  libxml2, libpng16 or libjpeg without ${AZSUPPORT_PREFIX}/lib in the run path:$$bad"; \
	[ -z "$$miss" ] && [ -z "$$bad" ]

.include "${.CURDIR:H:H}/Mk/azsupport-official.mk"
