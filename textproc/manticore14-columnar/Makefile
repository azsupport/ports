# textproc/manticore14-columnar of azsupport/ports (aZ, 16.11.2026: Manticore Search 14
# and the current line, 32 since 20.11.2026, with embeddings): the libraries of
# Manticore Columnar 9.0.0 (tag c27-s18-k9, 29.11.2025, the one of Manticore 14.7.6)
# that searchd of textproc/manticore14 loads
# from share/manticore/modules: lib_manticore_columnar (columnar storage),
# lib_manticore_secondary (secondary indexes), lib_manticore_knn (vector search) and
# lib_manticore_knn_embeddings (auto embeddings: models of HuggingFace, Sentence
# Transformers, or of OpenAI, Voyage and Jina over HTTPS; the models of HuggingFace
# downloaded on first use; aZ, 16.11.2026: with embeddings), and their _avx2 builds
# (searchd takes them on a CPU with AVX2), as upstream builds them. The FreeBSD tree
# has no port of it: written for this tree.
# - in the build only, static: FastPFor (simde), streamvbyte, PGM-index and hnswlib of
#   Manticore (distfiles: cmake downloads nothing); the embeddings a Rust library
#   (cargo at configure time: the crates of Cargo.lock as distfiles, offline), with
#   rustls (no OpenSSL) and Oniguruma of az (tokenizers; with the run path
#   /usr/local/az/lib);
# - CMake 4: CMAKE_POLICY_VERSION_MINIMUM=3.5 in the environment;
# - no debug, the flags of the make.conf of the build everywhere (-O3, the -march of the
#   level): the dependencies once, in Release (upstream: RelWithDebInfo and Debug, and
#   the Debug one linked), with those flags (upstream: the -march of the build alone),
#   the plain build with the -march of the level (upstream: x86-64-v2; the builds with
#   AVX keep theirs) — files/patch-cmake_*; the embeddings with opt-level 3 (upstream:
#   "z", for size); the modules stripped.

PORTNAME=	manticore
DISTVERSION?=	9.0.0
PORTREVISION=	${AZ_STAMP:U0}
CATEGORIES=	textproc
PKGNAMESUFFIX?=	14-columnar
DIST_SUBDIR=	manticore

MAINTAINER=	github@azsupport.com
COMMENT=	Columnar, secondary and vector libraries of Manticore Search ${MC_LINE} (of azsupport/ports)
WWW=		https://github.com/manticoresoftware/columnar \
		https://github.com/azsupport/ports

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE

BUILD_DEPENDS=	${AZ_PREFIX}/lib/libonig.so:az/az
RUN_DEPENDS=	${AZ_PREFIX}/lib/libonig.so:az/az \
		${LOCALBASE}/bin/searchd:textproc/manticore${MC_LINE}

USES=		cargo cmake compiler:c++17-lang pkgconfig
USE_GITHUB=	yes
GH_ACCOUNT=	manticoresoftware
GH_PROJECT=	columnar
GH_TAGNAME?=	c27-s18-k9
# the line 14 (textproc/manticore32-columnar sets its own): hnswlib
MC_HNSW?=	manticoresoftware:hnswlib:d7bb3bbd59220f62203012b2f649aa537cc97cdc:hnsw/freebsd-deps/hnswlib
GH_TUPLE=	${MC_HNSW} \
		manticoresoftware:FastPFor:5f6b7df8f0dba402bb616a81ca510bfeb04c42ce:fastpfor/freebsd-deps/fastpfor \
		manticoresoftware:streamvbyte:efdd9dace81a4a8f844267631879b500c6d913cf:svb/freebsd-deps/streamvbyte \
		manticoresoftware:PGM-index:5a5a763c7c07e56f56fd33137dcee9f1b3c3b640:pgm/freebsd-deps/pgm

CARGO_CRATES?=	addr2line-0.24.2 \
		adler2-2.0.0 \
		aho-corasick-1.1.3 \
		anstream-0.6.18 \
		anstyle-1.0.10 \
		anstyle-parse-0.2.6 \
		anstyle-query-1.1.2 \
		anstyle-wincon-3.0.6 \
		anyhow-1.0.94 \
		approx-0.5.1 \
		arbitrary-1.4.1 \
		atty-0.2.14 \
		autocfg-1.4.0 \
		backtrace-0.3.74 \
		base64-0.13.1 \
		base64-0.22.1 \
		bit-set-0.5.3 \
		bit-vec-0.6.3 \
		bitflags-1.3.2 \
		bitflags-2.6.0 \
		bumpalo-3.16.0 \
		bytemuck-1.20.0 \
		bytemuck_derive-1.8.0 \
		byteorder-1.5.0 \
		bytes-1.9.0 \
		cbindgen-0.26.0 \
		cc-1.2.4 \
		cfg-if-1.0.0 \
		cfg_aliases-0.2.1 \
		clap-3.2.25 \
		clap-4.5.23 \
		clap_builder-4.5.23 \
		clap_derive-4.5.18 \
		clap_lex-0.2.4 \
		clap_lex-0.7.4 \
		colorchoice-1.0.3 \
		console-0.15.10 \
		crc32fast-1.4.2 \
		crossbeam-deque-0.8.6 \
		crossbeam-epoch-0.9.18 \
		crossbeam-utils-0.8.21 \
		crunchy-0.2.2 \
		darling-0.14.4 \
		darling_core-0.14.4 \
		darling_macro-0.14.4 \
		derive_arbitrary-1.4.1 \
		derive_builder-0.12.0 \
		derive_builder_core-0.12.0 \
		derive_builder_macro-0.12.0 \
		dirs-5.0.1 \
		dirs-sys-0.4.1 \
		displaydoc-0.2.5 \
		dyn-stack-0.10.0 \
		either-1.13.0 \
		encode_unicode-1.0.0 \
		enum-as-inner-0.6.1 \
		equivalent-1.0.1 \
		errno-0.3.10 \
		esaxx-rs-0.1.10 \
		fancy-regex-0.13.0 \
		fastrand-2.3.0 \
		flate2-1.0.35 \
		fnv-1.0.7 \
		form_urlencoded-1.2.1 \
		futures-channel-0.3.31 \
		futures-core-0.3.31 \
		futures-io-0.3.31 \
		futures-sink-0.3.31 \
		futures-task-0.3.31 \
		futures-util-0.3.31 \
		gemm-0.17.1 \
		gemm-c32-0.17.1 \
		gemm-c64-0.17.1 \
		gemm-common-0.17.1 \
		gemm-f16-0.17.1 \
		gemm-f32-0.17.1 \
		gemm-f64-0.17.1 \
		getrandom-0.2.15 \
		gimli-0.31.1 \
		half-2.4.1 \
		hashbrown-0.12.3 \
		hashbrown-0.15.2 \
		heck-0.4.1 \
		heck-0.5.0 \
		hermit-abi-0.1.19 \
		hermit-abi-0.3.9 \
		http-1.2.0 \
		http-body-1.0.1 \
		http-body-util-0.1.2 \
		httparse-1.9.5 \
		hyper-1.5.2 \
		hyper-rustls-0.27.3 \
		hyper-util-0.1.10 \
		icu_collections-1.5.0 \
		icu_locid-1.5.0 \
		icu_locid_transform-1.5.0 \
		icu_locid_transform_data-1.5.0 \
		icu_normalizer-1.5.0 \
		icu_normalizer_data-1.5.0 \
		icu_properties-1.5.1 \
		icu_properties_data-1.5.0 \
		icu_provider-1.5.0 \
		icu_provider_macros-1.5.0 \
		ident_case-1.0.1 \
		idna-1.0.3 \
		idna_adapter-1.2.0 \
		indexmap-1.9.3 \
		indexmap-2.7.0 \
		indicatif-0.17.9 \
		ipnet-2.10.1 \
		is_terminal_polyfill-1.70.1 \
		itertools-0.11.0 \
		itertools-0.12.1 \
		itoa-1.0.14 \
		js-sys-0.3.76 \
		lazy_static-1.5.0 \
		libc-0.2.168 \
		libm-0.2.11 \
		libredox-0.1.3 \
		linux-raw-sys-0.4.14 \
		litemap-0.7.4 \
		log-0.4.22 \
		macro_rules_attribute-0.2.0 \
		macro_rules_attribute-proc_macro-0.2.0 \
		memchr-2.7.4 \
		memmap2-0.9.5 \
		mime-0.3.17 \
		minimal-lexical-0.2.1 \
		miniz_oxide-0.8.0 \
		mio-1.0.3 \
		monostate-0.1.13 \
		monostate-impl-0.1.13 \
		nom-7.1.3 \
		num-complex-0.4.6 \
		num-traits-0.2.19 \
		num_cpus-1.16.0 \
		num_enum-0.7.3 \
		num_enum_derive-0.7.3 \
		number_prefix-0.4.0 \
		object-0.36.5 \
		once_cell-1.20.2 \
		onig-6.4.0 \
		onig_sys-69.8.1 \
		option-ext-0.2.0 \
		os_str_bytes-6.6.1 \
		paste-1.0.15 \
		percent-encoding-2.3.1 \
		pin-project-lite-0.2.15 \
		pin-utils-0.1.0 \
		pkg-config-0.3.31 \
		portable-atomic-1.10.0 \
		ppv-lite86-0.2.20 \
		proc-macro-crate-3.2.0 \
		proc-macro2-1.0.92 \
		pulp-0.18.22 \
		quinn-0.11.6 \
		quinn-proto-0.11.9 \
		quinn-udp-0.5.8 \
		quote-1.0.37 \
		rand-0.8.5 \
		rand_chacha-0.3.1 \
		rand_core-0.6.4 \
		rand_distr-0.4.3 \
		raw-cpuid-10.7.0 \
		rayon-1.10.0 \
		rayon-cond-0.3.0 \
		rayon-core-1.12.1 \
		reborrow-0.5.5 \
		redox_users-0.4.6 \
		regex-1.11.1 \
		regex-automata-0.4.9 \
		regex-syntax-0.8.5 \
		reqwest-0.12.9 \
		ring-0.17.8 \
		rustc-demangle-0.1.24 \
		rustc-hash-2.1.0 \
		rustix-0.38.42 \
		rustls-0.23.20 \
		rustls-pemfile-2.2.0 \
		rustls-pki-types-1.10.1 \
		rustls-webpki-0.102.8 \
		ryu-1.0.18 \
		safetensors-0.4.5 \
		same-file-1.0.6 \
		seq-macro-0.3.5 \
		serde-1.0.216 \
		serde_derive-1.0.216 \
		serde_json-1.0.133 \
		serde_plain-1.0.2 \
		serde_urlencoded-0.7.1 \
		shlex-1.3.0 \
		slab-0.4.9 \
		smallvec-1.13.2 \
		socket2-0.5.8 \
		socks-0.3.4 \
		spin-0.9.8 \
		spm_precompiled-0.1.4 \
		stable_deref_trait-1.2.0 \
		strsim-0.10.0 \
		strsim-0.11.1 \
		subtle-2.6.1 \
		syn-1.0.109 \
		syn-2.0.90 \
		sync_wrapper-1.0.2 \
		synstructure-0.13.1 \
		sysctl-0.5.5 \
		tempfile-3.14.0 \
		termcolor-1.4.1 \
		textwrap-0.16.1 \
		thiserror-1.0.69 \
		thiserror-2.0.7 \
		thiserror-impl-1.0.69 \
		thiserror-impl-2.0.7 \
		tinystr-0.7.6 \
		tinyvec-1.8.0 \
		tinyvec_macros-0.1.1 \
		tokenizers-0.15.2 \
		tokio-1.42.0 \
		tokio-rustls-0.26.1 \
		toml-0.5.11 \
		toml_datetime-0.6.8 \
		toml_edit-0.22.22 \
		tower-service-0.3.3 \
		tracing-0.1.41 \
		tracing-attributes-0.1.28 \
		tracing-core-0.1.33 \
		try-lock-0.2.5 \
		unicode-ident-1.0.14 \
		unicode-normalization-alignments-0.1.12 \
		unicode-segmentation-1.12.0 \
		unicode-width-0.2.0 \
		unicode_categories-0.1.1 \
		untrusted-0.9.0 \
		ureq-2.12.1 \
		url-2.5.4 \
		utf16_iter-1.0.5 \
		utf8_iter-1.0.4 \
		utf8parse-0.2.2 \
		walkdir-2.5.0 \
		want-0.3.1 \
		wasi-0.11.0+wasi-snapshot-preview1 \
		wasm-bindgen-0.2.99 \
		wasm-bindgen-backend-0.2.99 \
		wasm-bindgen-futures-0.4.49 \
		wasm-bindgen-macro-0.2.99 \
		wasm-bindgen-macro-support-0.2.99 \
		wasm-bindgen-shared-0.2.99 \
		web-sys-0.3.76 \
		web-time-1.1.0 \
		webpki-roots-0.26.7 \
		winapi-0.3.9 \
		winapi-i686-pc-windows-gnu-0.4.0 \
		winapi-util-0.1.9 \
		winapi-x86_64-pc-windows-gnu-0.4.0 \
		windows-registry-0.2.0 \
		windows-result-0.2.0 \
		windows-strings-0.1.0 \
		windows-sys-0.48.0 \
		windows-sys-0.52.0 \
		windows-sys-0.59.0 \
		windows-targets-0.48.5 \
		windows-targets-0.52.6 \
		windows_aarch64_gnullvm-0.48.5 \
		windows_aarch64_gnullvm-0.52.6 \
		windows_aarch64_msvc-0.48.5 \
		windows_aarch64_msvc-0.52.6 \
		windows_i686_gnu-0.48.5 \
		windows_i686_gnu-0.52.6 \
		windows_i686_gnullvm-0.52.6 \
		windows_i686_msvc-0.48.5 \
		windows_i686_msvc-0.52.6 \
		windows_x86_64_gnu-0.48.5 \
		windows_x86_64_gnu-0.52.6 \
		windows_x86_64_gnullvm-0.48.5 \
		windows_x86_64_gnullvm-0.52.6 \
		windows_x86_64_msvc-0.48.5 \
		windows_x86_64_msvc-0.52.6 \
		winnow-0.6.20 \
		write16-1.0.0 \
		writeable-0.5.5 \
		yoke-0.7.5 \
		yoke-derive-0.7.5 \
		zerocopy-0.7.35 \
		zerocopy-derive-0.7.35 \
		zerofrom-0.1.5 \
		zerofrom-derive-0.1.5 \
		zeroize-1.8.1 \
		zerovec-0.10.4 \
		zerovec-derive-0.10.3 \
		zip-1.1.4 \
		candle-core,candle-nn,candle-transformers@git+https://github.com/huggingface/candle.git?rev=59b18d974ec3cad6963b774aa245e23f8c80414f\#59b18d974ec3cad6963b774aa245e23f8c80414f \
		hf-hub@git+https://github.com/huggingface/hf-hub.git?rev=ac22200ea0b5af4d8c362f699be0340647b19060\#ac22200ea0b5af4d8c362f699be0340647b19060

# the embeddings: cmake runs cargo (cmake/build_embeddings.cmake), not the framework
CARGO_SRC_SUBDIR=	embeddings
CARGO_BUILD=	no
CARGO_INSTALL=	no
CARGO_TEST=	no

MC_DEPS=	${WRKSRC}/freebsd-deps
CMAKE_ARGS=	-DBUILD_TESTING=OFF -DBUILD_EMBEDDINGS_LOCALLY=ON \
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON \
		-DFETCHCONTENT_SOURCE_DIR_FASTPFOR=${MC_DEPS}/fastpfor \
		-DFETCHCONTENT_SOURCE_DIR_HNSWLIB=${MC_DEPS}/hnswlib \
		-DFETCHCONTENT_SOURCE_DIR_PGM=${MC_DEPS}/pgm \
		-DFETCHCONTENT_SOURCE_DIR_STREAMVBYTE=${MC_DEPS}/streamvbyte \
		${MC_CMAKE_ARGS}
# in the builds cmake runs: cargo (the vendored crates, Oniguruma of az, opt-level 3; at
# configure time in the line 14, at build time in the line 32), the minimum of CMake 4
# for the dependencies, the cache of the built dependencies; CFLAGS and CXXFLAGS for the
# dependencies built at configure time (at build time MAKE_ENV has them)
CONFIGURE_ENV=	${CARGO_ENV} CACHEB=${WRKDIR}/columnar-cache \
		CMAKE_POLICY_VERSION_MINIMUM=3.5 PKG_CONFIG_LIBDIR=${WRKDIR}/az/pc \
		CARGO_PROFILE_RELEASE_OPT_LEVEL=3 \
		CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}"
MAKE_ENV=	${CARGO_ENV} CACHEB=${WRKDIR}/columnar-cache \
		CMAKE_POLICY_VERSION_MINIMUM=3.5 PKG_CONFIG_LIBDIR=${WRKDIR}/az/pc \
		CARGO_PROFILE_RELEASE_OPT_LEVEL=3
# the builds _avx2 (and _avx512 of the line 32) are ExternalProjects that configure,
# build and install themselves and their dependencies into the build directory at
# build time: USES=ninja puts DESTDIR (the stage) in MAKE_ENV, so the build runs
# without it (with it they install into the stage and find nothing where they look);
# the install runs with it
DO_MAKE_BUILD=	${SETENVI} ${WRK_ENV} ${MAKE_ENV:N${DESTDIRNAME}=*} ${MAKE_CMD} \
		${MAKE_FLAGS} ${MAKEFILE} ${_MAKE_JOBS} ${MAKE_ARGS:N${DESTDIRNAME}=*}
# libonig of az by its run path (cargo.mk gives LDFLAGS to rustc as link-arg)
LDFLAGS+=	-Wl,-rpath,${AZ_PREFIX}/lib

CONFLICTS_INSTALL?=	manticore32-columnar

# the line of Manticore (14, 31), and the builds of the libraries: plain and for AVX2 (the
# line 32: AVX-512 too); searchd takes the one the CPU runs
MC_LINE=	${PKGNAMESUFFIX:S/-columnar//}
MC_BUILDS?=	plain _avx2
PLIST_FILES=	${DATADIR_REL}/modules/lib_manticore_knn_embeddings.so
.for l in columnar knn secondary
.  for b in ${MC_BUILDS:S/plain//}
PLIST_FILES+=	${DATADIR_REL}/modules/lib_manticore_${l}${b}.so
.  endfor
PLIST_FILES+=	${DATADIR_REL}/modules/lib_manticore_${l}.so
.endfor

# the version of the libraries (upstream sets it when it packs them; 0.0.0 in the source)
post-patch:
	@${REINPLACE_CMD} -e 's|^project ( columnar VERSION 0\.0\.0 )|project ( columnar VERSION ${DISTVERSION:C/-.*//} )|' \
		${WRKSRC}/CMakeLists.txt

# the config of cargo (the vendored crates) where cargo of cmake finds it: in its home
# (it runs in the build directory, not in ${WRKSRC}); Oniguruma of az alone in
# ${WRKDIR}/az (a .pc of its own)
pre-configure:
	@${MKDIR} ${WRKDIR}/cargo-home ${WRKDIR}/az/include ${WRKDIR}/az/lib ${WRKDIR}/az/pc
	@${CP} ${CARGO_DOT_DIR}/config.toml ${WRKDIR}/cargo-home/config.toml
	@${LN} -sf ${AZ_PREFIX}/include/oniguruma.h ${WRKDIR}/az/include/
	@${LN} -sf ${AZ_PREFIX}/lib/libonig.so ${WRKDIR}/az/lib/
	@v=$$(${SED} -n 's/^Version: *//p' ${AZ_PREFIX}/lib/pkgconfig/oniguruma.pc); \
	${PRINTF} 'Name: oniguruma\nDescription: oniguruma of az\nVersion: %s\nCflags: -I${WRKDIR}/az/include\nLibs: -L${WRKDIR}/az/lib -Wl,-rpath,${AZ_PREFIX}/lib -lonig\n' \
		"$$v" > ${WRKDIR}/az/pc/oniguruma.pc

# install/strip strips the targets only: the builds with AVX and the embeddings are
# copied files
post-install:
	${STRIP_CMD} ${STAGEDIR}${DATADIR}/modules/*.so

.include <bsd.port.mk>
