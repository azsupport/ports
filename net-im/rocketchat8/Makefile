# net-im/rocketchat8 of azsupport/ports (there is no official port of Rocket.Chat): the
# server of Rocket.Chat 8 as Rocket.Chat builds it, the Meteor bundle
# rocket.chat-8.9.1.tgz (aZ, 18.11.2026 13:18: «сделай ещё порт rocketchat8», as he
# installs it on Linux: the bundle, npm install --omit=dev in programs/server), on the
# node24 of this tree (8.9.1 asks for node >=24.15.0 <25), its database MongoDB 8.0 of
# databases/mongodb80 as a replica set, here or on another host (not a dependency).
# What the port does:
# - the npm modules of the bundle at the versions 8.9.1 was built and tested with (aZ,
#   13:40: no npm audit fix --force), all of them checked against the advisory database
#   of npm (azsupport/azsupport rocketchat/2026-11-18-npm-audit-8.9.1.md), but the
#   fixes aZ agreed to (14:10), with the modules they need: RC_NPM_FIX of Makefile.npm;
# - the modules of programs/server from their tarballs: RC_NPM_SERVER of Makefile.npm
#   (npm install --omit=dev would add the node-gyp and node-pre-gyp of its package.json,
#   which only rebuild the native modules: here the port builds them);
# - every native module built here from its source; the bundle has those of Linux,
#   Windows, macOS and Android, all removed: argon2 and bcrypt of accounts-password,
#   bcrypt, isolated-vm (its thread suspension and CPU clock of Linux for FreeBSD too),
#   @kaciras/deasync and sharp by the node-gyp of npm (sharp on a libvips of its own,
#   below),
#   @sematext/gc-stats by its node-pre-gyp, sodium-native by node-gyp
#   (files/sodium-native.gyp.in: its CMake build fetches libsodium from git) on
#   libsodium 1.0.22 built here, @napi-rs/pinyin (Rust, its sources in the bundle; aZ,
#   13:40: «а) Из исходников (Rust, наша сборка)»; its crates in files/pinyin-Cargo.lock)
#   and esbuild 0.28.1 and 0.28.2 (Go; @rocket.chat/apps builds the apps with it) as
#   @esbuild/freebsd-x64; uWebSockets.js of ddp-server has no binary (Meteor loads it
#   for DDP_TRANSPORT=uws only; the default transport is sockjs); post-install fails on
#   any binary left that is not of FreeBSD;
# - sharp 0.35.5 (RC_NPM_FIX) on libvips 8.18.7 built here with the patches of
#   graphics/vips, static in its module, with the formats of sharp-libvips 1.3.4: JPEG,
#   PNG, WebP, GIF, AVIF and HEIF, TIFF, SVG (librsvg), text (Pango, fontconfig), ICC,
#   EXIF, Ultra HDR, the C++ API (aZ, 18.11.2026 15:26: «давай так»); its libraries the
#   shared ones of az and of the ports of this tree (16:02: «да конечно»): expat, lcms2,
#   libheif, mozjpeg, libpng, WebP, fontconfig, FreeType, libxml2, libintl of az (each
#   with its own headers: Mk/az-libs.mk); GLib, cgif, libexif, Highway, libimagequant,
#   libtiff, Cairo, Pango, HarfBuzz, FriBidi, librsvg, libultrahdr of this tree;
#   libarchive and zlib of the base system; graphics/vips of nginx as it is;
# - LTO wherever there is one: ThinLTO for the native modules and libsodium (sharp has
#   -flto upstream for Linux), the LTO of the Cargo.toml of pinyin; the -O3 and -march of
#   the level for the C and C++, the target-cpu for Rust, GOAMD64 for Go;
# - in /usr/local/www/rocketchat8, owned by root; run as the user rocketchat (UID and GID
#   3000: files/UIDs and files/GIDs, as textproc/manticore14) by the rc script
#   rocketchat8 (daemon(8)), with the environment of /usr/local/etc/rocketchat8.conf, the
#   log /var/log/rocketchat8.log (aZ, 13:44: «а) ... ок»).

PORTNAME=	rocketchat
DISTVERSION=	8.9.1
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	net-im www
MASTER_SITES=	https://cdn-download.rocket.chat/build/:bundle \
		https://github.com/jedisct1/libsodium/releases/download/${RC_SODIUM}-RELEASE/:sodium \
		https://github.com/libvips/libvips/releases/download/v${RC_VIPS}/:vips \
		https://registry.npmjs.org/:npm
PKGNAMESUFFIX=	8
DISTFILES=	rocket.chat-${DISTVERSION}.tgz:bundle \
		libsodium-${RC_SODIUM}.tar.bz2:sodium \
		vips-${RC_VIPS}.tar.xz:vips
DIST_SUBDIR=	rocketchat8

MAINTAINER=	github@azsupport.com
COMMENT=	Team chat server (Rocket.Chat 8, of azsupport/ports)
WWW=		https://www.rocket.chat/ \
		https://github.com/RocketChat/Rocket.Chat \
		https://github.com/azsupport/ports

LICENSE=	MIT

ONLY_FOR_ARCHS=	amd64
ONLY_FOR_ARCHS_REASON=	the x86-64 levels of azsupport/ports only

BUILD_DEPENDS=	go:lang/go \
		meson:devel/meson \
		ninja:devel/ninja \
		npm:www/npm-node24
# the libraries of this tree sharp links (its libvips: below); those of az: AZ_LIBS
LIB_DEPENDS=	libcairo.so:graphics/cairo \
		libcgif.so:graphics/cgif \
		libexif.so:graphics/libexif \
		libfribidi.so:converters/fribidi \
		libglib-2.0.so:devel/glib20 \
		libharfbuzz.so:print/harfbuzz \
		libhwy.so:devel/highway \
		libimagequant.so:graphics/libimagequant \
		libpangocairo-1.0.so:x11-toolkits/pango \
		librsvg-2.so:graphics/librsvg2-rust \
		libtiff.so:graphics/tiff \
		libuhdr.so:graphics/libultrahdr
RUN_DEPENDS=	node24>=24.15:www/node24

USES=		cargo compiler:c++20-lang gmake pkgconfig python:build tar:bzip2
USE_GITHUB=	nodefault
GH_TUPLE=	meteor:node-source-map-support:81bce1f99625e62af73338f63afcf2b44c6cfa5e:sms \
		evanw:esbuild:v0.28.1:esb1 \
		evanw:esbuild:v0.28.2:esb2 \
		golang:sys:c0bba94af5f8:sys
USE_RC_SUBR=	rocketchat8

WRKSRC=		${WRKDIR}/bundle

# @napi-rs/pinyin of the bundle by the cargo of the ports, out of the tree it installs
CARGO_SRC_SUBDIR=	programs/server/npm/node_modules/@napi-rs/pinyin
CARGO_VENDOR_DIR=	${WRKDIR}/cargo-crates
CARGO_TARGET_DIR=	${WRKDIR}/cargo-target
CARGO_CRATES=	aho-corasick-1.1.5 \
		bitflags-2.13.2 \
		byteorder-1.5.0 \
		cc-1.11.2 \
		cedarwood-0.4.6 \
		cfg-if-1.0.5 \
		convert_case-0.6.0 \
		crossbeam-deque-0.8.8 \
		crossbeam-epoch-0.9.21 \
		crossbeam-utils-0.8.23 \
		ctor-0.2.9 \
		either-1.19.0 \
		find-msvc-tools-0.1.15 \
		fxhash-0.2.1 \
		hashbrown-0.14.5 \
		jieba-rs-0.6.8 \
		lazy_static-1.5.1 \
		libloading-0.8.9 \
		libmimalloc-sys-0.1.49 \
		memchr-2.8.3 \
		mimalloc-0.1.52 \
		napi-2.16.17 \
		napi-build-1.2.1 \
		napi-derive-2.16.13 \
		napi-derive-backend-1.0.75 \
		napi-sys-2.4.0 \
		once_cell-1.21.4 \
		phf-0.11.3 \
		phf_codegen-0.11.3 \
		phf_generator-0.11.3 \
		phf_shared-0.11.3 \
		pinyin-0.9.0 \
		proc-macro2-1.0.107 \
		quote-1.0.47 \
		rand-0.8.8 \
		rand_core-0.6.4 \
		rayon-1.12.0 \
		rayon-core-1.13.0 \
		regex-1.13.2 \
		regex-automata-0.4.19 \
		regex-syntax-0.8.12 \
		semver-1.0.28 \
		shlex-2.0.1 \
		siphasher-1.0.4 \
		smallvec-1.16.6 \
		syn-2.0.119 \
		unicode-ident-1.0.27 \
		unicode-segmentation-1.13.3 \
		windows-link-0.2.1

USERS=		rocketchat
GROUPS=		rocketchat
UID_FILES=	${PORTSDIR}/UIDs ${FILESDIR}/UIDs
GID_FILES=	${PORTSDIR}/GIDs ${FILESDIR}/GIDs

SUB_FILES=	pkg-message rocketchat8.conf.sample
SUB_LIST=	USERS=${USERS} \
		GROUPS=${GROUPS} \
		WWWDIR=${WWWDIR}
PLIST_SUB=	USERS=${USERS} \
		GROUPS=${GROUPS}

WWWDIR=		${PREFIX}/www/${PORTNAME}${PKGNAMESUFFIX}
# sed -i without the .bak files, which would go into the package with the bundle
REINPLACE_ARGS=	-i ''

RC_SODIUM=	1.0.22
# libvips of sharp: 8.18.7 (sharp 0.35.5 asks for >= 8.18.7) with the patches of
# graphics/vips (the fixes of the 8.18 branch after 8.18.7), the directory it is
# installed into (static), the .pc of it sharp reads
RC_VIPS=	8.18.7
RC_VIPS_SRC=	${WRKDIR}/vips-${RC_VIPS}
RC_VIPS_PREFIX=	${WRKDIR}/vips-static
RC_VIPS_PATCHES=	${.CURDIR:H:H}/graphics/vips/files/patch-gifload-height \
		${.CURDIR:H:H}/graphics/vips/files/patch-heifload-1-height \
		${.CURDIR:H:H}/graphics/vips/files/patch-heifload-2-max-items \
		${.CURDIR:H:H}/graphics/vips/files/patch-icc-transform-blob \
		${.CURDIR:H:H}/graphics/vips/files/patch-libnsgif-lzw \
		${.CURDIR:H:H}/graphics/vips/files/patch-pngload-cmf \
		${.CURDIR:H:H}/graphics/vips/files/patch-webpload-height
AZ_HASH_FILES=	${RC_VIPS_PATCHES}
# its options: those of sharp-libvips 1.3.4 (build/posix.sh), every feature not named
# here on (auto_features), the static libraries with the C++ API
RC_VIPS_MESON=	--prefix=${RC_VIPS_PREFIX} --libdir=lib --default-library=static \
		--buildtype=release --wrap-mode=nofallback -Dauto_features=enabled \
		-Dcplusplus=true -Ddeprecated=false -Dexamples=false -Dintrospection=disabled \
		-Dmodules=disabled -Dcfitsio=disabled -Dfftw=disabled -Djpeg-xl=disabled \
		-Dorc=disabled -Dmagick=disabled -Dmatio=disabled -Dnifti=disabled \
		-Dopenexr=disabled -Dopenjpeg=disabled -Dopenslide=disabled -Dpdfium=disabled \
		-Dpoppler=disabled -Dquantizr=disabled -Draw=disabled -Dspng=disabled \
		-Dppm=false -Danalyze=false -Dradiance=false
RC_VIPS_ENV=	CC="${CC}" \
		CXX="${CXX}" \
		CFLAGS="${CFLAGS} -fPIC -flto=thin" \
		CXXFLAGS="${CXXFLAGS} -fPIC -flto=thin" \
		CPPFLAGS="${CPPFLAGS}" \
		LDFLAGS="${LDFLAGS} -flto=thin" \
		AR=llvm-ar \
		RANLIB=llvm-ranlib \
		NM=llvm-nm \
		PKG_CONFIG_LIBDIR=${AZ_LIBS_PKG_CONFIG_LIBDIR}
RC_SERVER=	${WRKSRC}/programs/server
RC_NM=		${RC_SERVER}/npm/node_modules
RC_NODE=	${LOCALBASE}/bin/node
RC_NODE_GYP=	${LOCALBASE}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js
# the C and C++ of the native modules and of libsodium: the flags of the build with
# ThinLTO (clang and its lld); the headers of the libuv of az last (uv.h: node24 is on
# the shared libuv of az, and node-gyp gives only include/node of the nodedir: build
# run 44313885867, "'uv.h' file not found")
RC_ENV=		HOME=${WRKDIR} \
		CC="${CC}" \
		CXX="${CXX}" \
		CFLAGS="${CFLAGS} -flto=thin -idirafter ${AZ_PREFIX}/include" \
		CXXFLAGS="${CXXFLAGS} -flto=thin -idirafter ${AZ_PREFIX}/include" \
		LDFLAGS="${LDFLAGS} -flto=thin" \
		AR=llvm-ar \
		RANLIB=llvm-ranlib \
		MAKE=${GMAKE} \
		PYTHON=${PYTHON_CMD} \
		PKG_CONFIG_PATH=${LOCALBASE}/libdata/pkgconfig \
		npm_config_nodedir=${LOCALBASE} \
		npm_config_python=${PYTHON_CMD} \
		npm_config_node_gyp=${RC_NODE_GYP} \
		JOBS=${MAKE_JOBS_NUMBER}
RC_GYP=		${RC_NODE} ${RC_NODE_GYP} rebuild --release --nodedir=${LOCALBASE} \
		--python=${PYTHON_CMD} -j ${MAKE_JOBS_NUMBER}
# the native modules node-gyp builds in their directories (under npm/node_modules); sharp
# the last of the build (it needs the C++ API of libvips)
RC_GYP_DIRS=	meteor/accounts-password/node_modules/argon2 \
		meteor/accounts-password/node_modules/bcrypt \
		bcrypt \
		isolated-vm \
		@kaciras/deasync \
		sodium-native
# Go for esbuild: the level of the build (x86-64-v3 -> v3), offline
RC_GOAMD64=	${CFLAGS:M-march=x86-64-v[234]:S/-march=x86-64-//}
RC_GO_ENV=	HOME=${WRKDIR} \
		GOCACHE=${WRKDIR}/go-cache \
		GOPATH=${WRKDIR}/go \
		GOFLAGS=-mod=vendor \
		GOPROXY=off \
		GOTOOLCHAIN=local \
		CGO_ENABLED=0 \
		${RC_GOAMD64:S/^/GOAMD64=/}

# the libraries of az of the libvips of sharp, each with its own headers (gettext: the
# libintl.h of glib/gi18n.h; libxml2: the .pc librsvg requires)
AZ_LIBS=	expat:libexpat.so \
		fontconfig:libfontconfig.so \
		freetype2:libfreetype.so \
		gettext:libintl.so \
		lcms2:liblcms2.so \
		libheif:libheif.so \
		libxml2:libxml2.so \
		mozjpeg:libjpeg.so \
		png:libpng16.so \
		webp:libwebp.so
.include "${.CURDIR:H:H}/Mk/az-libs.mk"

.include "${.CURDIR}/Makefile.npm"

# the npm tarballs as on the registry (<name>/-/<base>-<version>.tgz), each extracted where
# it goes (post-extract, post-patch), none by the framework
.for p in ${RC_NPM_SERVER}
_RC_NPM_FILES+=	${p:C/:.*//}/-/${p:C/:.*//:T}-${p:C/.*://}.tgz
.endfor
.for f in ${RC_NPM_FIX}
_RC_NPM_FILES+=	${f:C/^[^:]*://:C/:.*//}/-/${f:C/^[^:]*://:C/:.*//:T}-${f:C/.*://}.tgz
.endfor
.for t in ${_RC_NPM_FILES:O:u}
DISTFILES+=	${t}:npm
_RC_NOEXTRACT+=	N${t}
.endfor
EXTRACT_ONLY=	${_DISTFILES:${_RC_NOEXTRACT:ts:}}

.include <bsd.port.pre.mk>

post-extract:
	@${ECHO_MSG} "===>  The binaries of other systems out of the bundle"
	cd ${RC_NM} && ${FIND} . -name '*.node' -type f -delete
	cd ${RC_NM} && ${FIND} . -type d -name prebuilds -prune -exec ${RM} -r {} +
	${RM} -r ${RC_NM}/@img/sharp-* ${RC_NM}/@napi-rs/pinyin-* ${RC_NM}/@esbuild \
		${RC_NM}/@rocket.chat/apps/node_modules/@esbuild
.for d in ${RC_GYP_DIRS} @sematext/gc-stats sharp/src
	${RM} -r ${RC_NM}/${d}/build
.endfor
	@${ECHO_MSG} "===>  The modules of programs/server"
	${MKDIR} ${RC_SERVER}/node_modules
.for p in ${RC_NPM_SERVER}
	${MKDIR} ${RC_SERVER}/node_modules/${p:C/:.*//}
	${TAR} -xf ${_DISTDIR}/${p:C/:.*//}/-/${p:C/:.*//:T}-${p:C/.*://}.tgz \
		-C ${RC_SERVER}/node_modules/${p:C/:.*//} --strip-components 1 \
		--no-same-owner --no-same-permissions
.endfor
	${MKDIR} ${RC_SERVER}/node_modules/source-map-support
	cd ${WRKSRC_sms} && ${COPYTREE_SHARE} . ${RC_SERVER}/node_modules/source-map-support
	@${ECHO_MSG} "===>  The fixes of the advisory database of npm (Makefile.npm)"
.for f in ${RC_NPM_FIX}
	${MKDIR} ${RC_NM}/${f:C/:.*//}
	cd ${RC_NM}/${f:C/:.*//} && ${FIND} . -mindepth 1 -maxdepth 1 ! -name node_modules \
		-exec ${RM} -r {} +
	${TAR} -xf ${_DISTDIR}/${f:C/^[^:]*://:C/:.*//}/-/${f:C/^[^:]*://:C/:.*//:T}-${f:C/.*://}.tgz \
		-C ${RC_NM}/${f:C/:.*//} --strip-components 1 --no-same-owner --no-same-permissions
.endfor
	${CP} ${FILESDIR}/pinyin-Cargo.lock ${RC_NM}/@napi-rs/pinyin/Cargo.lock
.for e in esb1 esb2
	${MKDIR} ${WRKSRC_${e}}/vendor/golang.org/x
	${CP} -R ${WRKSRC_sys} ${WRKSRC_${e}}/vendor/golang.org/x/sys
	(${ECHO_CMD} "# golang.org/x/sys v0.0.0-20220715151400-c0bba94af5f8"; \
	cd ${WRKSRC_${e}}/vendor && ${FIND} golang.org/x/sys -name '*.go' ! -name '*_test.go' | \
		${SED} 's,/[^/]*$$,,' | ${SORT} -u) > ${WRKSRC_${e}}/vendor/modules.txt
.endfor

post-patch:
# libvips of sharp: the patches of graphics/vips; no manual pages, translations, tools,
# tests and fuzzers (sharp-libvips)
.for p in ${RC_VIPS_PATCHES}
	${PATCH} -s -p0 -d ${RC_VIPS_SRC} < ${p}
.endfor
	${REINPLACE_CMD} -e "/^subdir('man')$$/d" -e "/^subdir('po')$$/d" \
		-e "/^subdir('tools')$$/d" -e "/^subdir('test')$$/d" -e "/^subdir('fuzz')$$/d" \
		${RC_VIPS_SRC}/meson.build
	@if ${GREP} -q -e "subdir('man')" -e "subdir('po')" -e "subdir('tools')" \
	    -e "subdir('test')" -e "subdir('fuzz')" ${RC_VIPS_SRC}/meson.build; then \
		${ECHO_MSG} "libvips: man, po, tools, test or fuzz still in meson.build"; exit 1; fi
# isolated-vm: the thread suspension and the CPU time of threads of Linux for FreeBSD,
# which has pthread_kill, SIGRTMIN and CLOCK_THREAD_CPUTIME_ID (else no suspension)
	${REINPLACE_CMD} -e "s|'OS == \"linux\"', { 'defines': \[ 'USE_CLOCK_THREAD_CPUTIME_ID' \] }|'OS == \"linux\" or OS == \"freebsd\"', { 'defines': [ 'USE_CLOCK_THREAD_CPUTIME_ID' ] }|" \
		${RC_NM}/isolated-vm/binding.gyp
	${REINPLACE_CMD} -e 's|^#ifdef __linux__$$|#if defined(__linux__) \|\| defined(__FreeBSD__)|' \
		${RC_NM}/isolated-vm/src/lib/suspend.h
	${GREP} -q 'OS == "freebsd"' ${RC_NM}/isolated-vm/binding.gyp
	${GREP} -q '__FreeBSD__' ${RC_NM}/isolated-vm/src/lib/suspend.h
	${SED} -e 's|%%SODIUM%%|${WRKDIR}/sodium|g' ${FILESDIR}/sodium-native.gyp.in \
		> ${RC_NM}/sodium-native/binding.gyp

do-build:
	@${ECHO_MSG} "===>  libsodium ${RC_SODIUM} (static, PIC)"
	cd ${WRKDIR}/libsodium-${RC_SODIUM} && ${SETENV} ${RC_ENV} ./configure \
		--prefix=${WRKDIR}/sodium --disable-shared --enable-static --with-pic \
		--disable-dependency-tracking
	cd ${WRKDIR}/libsodium-${RC_SODIUM} && ${SETENV} ${RC_ENV} ${GMAKE} -j${MAKE_JOBS_NUMBER} install
.for d in ${RC_GYP_DIRS}
	@${ECHO_MSG} "===>  ${d}: node-gyp"
	cd ${RC_NM}/${d} && ${SETENV} ${RC_ENV} ${RC_GYP}
.endfor
	@${ECHO_MSG} "===>  @sematext/gc-stats: node-pre-gyp"
	cd ${RC_NM}/@sematext/gc-stats && ${SETENV} ${RC_ENV} ${RC_NODE} \
		${RC_NM}/@mapbox/node-pre-gyp/bin/node-pre-gyp rebuild --build-from-source \
		--nodedir=${LOCALBASE} --python=${PYTHON_CMD}
	@${ECHO_MSG} "===>  @napi-rs/pinyin: cargo"
	${CARGO_CARGO_RUN} build --manifest-path ${CARGO_CARGOTOML} ${CARGO_BUILD_ARGS}
	${INSTALL_LIB} ${CARGO_TARGET_DIR}/release/libnapi_pinyin.so \
		${RC_NM}/@napi-rs/pinyin/pinyin.freebsd-x64.node
# the directories under RC_NM: a .for list is expanded when the Makefile is read, before
# WRKDIR is set (run 44319468792: /bundle/...); the binary as esbuild-<version>.bin, as
# esbuild-<version> is the directory of its sources (go build -o put it inside)
.for e v d in esb1 0.28.1 @esbuild/freebsd-x64 esb2 0.28.2 @rocket.chat/apps/node_modules/@esbuild/freebsd-x64
	@${ECHO_MSG} "===>  esbuild ${v}: go"
	cd ${WRKSRC_${e}} && ${SETENV} ${RC_GO_ENV} ${LOCALBASE}/bin/go build -trimpath \
		-ldflags='-s -w' -o ${WRKDIR}/esbuild-${v}.bin ./cmd/esbuild
	${MKDIR} ${RC_NM}/${d}/bin
	${INSTALL_PROGRAM} ${WRKDIR}/esbuild-${v}.bin ${RC_NM}/${d}/bin/esbuild
	${PRINTF} '{\n  "name": "@esbuild/freebsd-x64",\n  "version": "%s",\n  "description": "The FreeBSD 64-bit binary for esbuild, built by net-im/rocketchat8 of azsupport/ports.",\n  "license": "MIT",\n  "preferUnplugged": true,\n  "engines": {\n    "node": ">=18"\n  },\n  "os": [\n    "freebsd"\n  ],\n  "cpu": [\n    "x64"\n  ]\n}\n' ${v} \
		> ${RC_NM}/${d}/package.json
.endfor
	@${ECHO_MSG} "===>  libvips ${RC_VIPS}: static, for sharp"
	cd ${RC_VIPS_SRC} && ${SETENV} ${RC_VIPS_ENV} meson setup _build ${RC_VIPS_MESON}
	cd ${RC_VIPS_SRC} && ${SETENV} ${RC_VIPS_ENV} meson compile -C _build -j ${MAKE_JOBS_NUMBER}
	cd ${RC_VIPS_SRC} && ${SETENV} ${RC_VIPS_ENV} meson install -C _build --no-rebuild --tags devel
# the .pc of it sharp reads (its binding.gyp: pkg-config --libs vips-cpp): libvips and
# libvips-cpp static, the libraries they need shared (pkgconf --static: those of
# Libs.private), the run path of az; the symbols of the archives not exported, the
# module kept loaded (the types of GLib cannot be unloaded)
	@${MKDIR} ${WRKDIR}/vips-sharp-pc
	@l="$$(${SETENV} PKG_CONFIG_LIBDIR=${RC_VIPS_PREFIX}/lib/pkgconfig:${AZ_LIBS_PKG_CONFIG_LIBDIR} pkgconf --static --libs vips-cpp)" && \
	c="$$(${SETENV} PKG_CONFIG_LIBDIR=${RC_VIPS_PREFIX}/lib/pkgconfig:${AZ_LIBS_PKG_CONFIG_LIBDIR} pkgconf --cflags vips-cpp)" && \
	${PRINTF} '%s\n' 'Name: vips-cpp' 'Description: libvips of net-im/rocketchat8, static' \
		'Version: ${RC_VIPS}' \
		"Libs: -L${LOCALBASE}/lib $$l -Wl,-rpath,${AZ_PREFIX}/lib -Wl,-z,nodelete -Wl,--exclude-libs=ALL" \
		"Cflags: $$c" > ${WRKDIR}/vips-sharp-pc/vips-cpp.pc && \
	${CAT} ${WRKDIR}/vips-sharp-pc/vips-cpp.pc
	@${ECHO_MSG} "===>  sharp: node-gyp, on that libvips (pkg-config vips-cpp)"
	cd ${RC_NM}/sharp/src && ${SETENV} ${RC_ENV} \
		PKG_CONFIG_PATH=${WRKDIR}/vips-sharp-pc:${RC_VIPS_PREFIX}/lib/pkgconfig \
		PKG_CONFIG_LIBDIR=${WRKDIR}/vips-sharp-pc:${RC_VIPS_PREFIX}/lib/pkgconfig:${AZ_LIBS_PKG_CONFIG_LIBDIR} \
		SHARP_FORCE_GLOBAL_LIBVIPS=1 ${RC_GYP}
	@m="$$(${FIND} ${RC_NM}/sharp/src/build/Release -maxdepth 1 -name 'sharp-*.node')" && \
	n="$$(/usr/bin/readelf -d $$m | ${GREP} NEEDED)" && \
	if echo "$$n" | ${GREP} -q 'libvips'; then \
		${ECHO_MSG} "sharp: $$m needs a shared libvips: $$n"; exit 1; fi && \
	for l in libglib-2.0 librsvg-2 libpangocairo-1.0 libtiff libheif libjpeg libpng16 libwebp; do \
		echo "$$n" | ${GREP} -q "\[$$l\." || { ${ECHO_MSG} "sharp: $$m without $$l: $$n"; exit 1; }; \
	done && ${ECHO_MSG} "===>  $${m##*/}: libvips static, $$(echo "$$n" | ${WC} -l | ${TR} -d ' ') shared libraries"

post-build:
# of the builds only the modules they make: sodium-native where require-addon finds it,
# the others where their loaders do (build/Release, the module_path of gc-stats)
	${MKDIR} ${RC_NM}/sodium-native/prebuilds/freebsd-x64
	${MV} ${RC_NM}/sodium-native/build/Release/sodium-native.node \
		${RC_NM}/sodium-native/prebuilds/freebsd-x64/sodium-native.node
	${RM} -r ${RC_NM}/sodium-native/build ${RC_NM}/sodium-native/binding.gyp
.for d in ${RC_GYP_DIRS:Nsodium-native} sharp/src
	cd ${RC_NM}/${d}/build && ${FIND} . -mindepth 1 ! -path './Release' \
		! \( -path './Release/*.node' ! -path './Release/*/*' \) -delete
.endfor
	cd ${RC_NM}/@sematext/gc-stats/build && ${FIND} . -type f ! \( -name gcstats.node \
		-path './gcstats/*' \) -delete
	cd ${RC_NM}/@sematext/gc-stats/build && ${FIND} . -mindepth 1 -type d -empty -delete
	${RM} -r ${CARGO_DOT_DIR} ${RC_NM}/@napi-rs/pinyin/Cargo.lock

do-install:
	${MKDIR} ${STAGEDIR}${WWWDIR}
	cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${WWWDIR}
	cd ${STAGEDIR}${WWWDIR} && ${FIND} . -name '*.node' -type f -exec ${STRIP_CMD} {} + && \
		${FIND} . -name '*.node' -type f -exec ${CHMOD} ${BINMODE} {} +
	${CHMOD} ${BINMODE} ${STAGEDIR}${WWWDIR}/programs/server/npm/node_modules/@esbuild/freebsd-x64/bin/esbuild \
		${STAGEDIR}${WWWDIR}/programs/server/npm/node_modules/@rocket.chat/apps/node_modules/@esbuild/freebsd-x64/bin/esbuild
	${INSTALL_DATA} ${WRKDIR}/rocketchat8.conf.sample ${STAGEDIR}${PREFIX}/etc/

post-install:
# no binary of another system (an ELF that is not of FreeBSD, Mach-O, PE)
	@cd ${STAGEDIR}${WWWDIR} && ${FIND} . -type f -size +1k -exec ${FILE} -F '|' {} + | \
		${GREP} -E '\| *(ELF|Mach-O|PE32)' | ${GREP} -v 'FreeBSD' > ${WRKDIR}/foreign.txt || :
	@if [ -s ${WRKDIR}/foreign.txt ]; then ${CAT} ${WRKDIR}/foreign.txt; \
		${ECHO_MSG} "binaries of other systems in the package (above)"; ${FALSE}; fi
	cd ${STAGEDIR}${PREFIX} && ${FIND} ${WWWDIR_REL} \( -type f -o -type l \) | ${SORT} >> ${TMPPLIST}
	cd ${STAGEDIR}${PREFIX} && ${FIND} ${WWWDIR_REL} -type d -empty | ${SORT} | \
		${SED} 's|^|@dir |' >> ${TMPPLIST}

.include <bsd.port.post.mk>
