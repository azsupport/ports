#!/bin/sh
# az-build.sh - build the libraries of the package az (the port
# az/az) from the FreeBSD ports listed in az/az/files/deps.conf,
# as the kinds of their lib lines say, into two trees:
# static and position independent into the static tree
# /usr/local/az/static (lib/, include/, bin/), shared into the shared tree
# /usr/local/az (lib/*.so with their SONAME and the run path
# /usr/local/az/lib, include/, lib/pkgconfig/, bin/pkg-config without
# --static, the *-config scripts; no ldconfig), for the packages: PHP and its
# modules, Apache and the modules it loads, and the programs (curl, FFmpeg,
# ImageMagick, GraphicsMagick, mc, ...), which link it with that run path: one copy
# of every library for all of them (aZ, 10.11.2026: our ports link each other's
# shared libraries). The shared builds take the patched source of
# the static one (a copy of the work directory of the port, or out of the tree of
# the bundled curl), the same options, the OpenSSL of the base system and the
# other libraries of the shared tree; nothing of the static tree (its headers of
# the OpenSSL of the port, its archives, which the linker would take as they are
# or leave for a .so of the same name) is seen by them. VERSIONS and LICENSES/
# are one for both, at the root. PHP built against the static tree on a server
# (tools/az-menu.sh of azsupport/php-src: php, php-fpm, php-cgi, libphp.so) needs no
# library of /usr/local/lib: a pkg upgrade or packages of another FreeBSD version
# cannot break it, and in Apache the copies of the libraries in PHP do not mix
# with those of other modules (their symbols stay hidden). Moved from
# tools/build-deps.sh of https://github.com/azsupport/php-src (08.11.2026).
#
# Usage (FreeBSD, as root; the port az/az runs it in its do-build, see the
# head of its Makefile):
#   sh tools/az-build.sh --tools     install the build tools (pkg)
#   sh tools/az-build.sh --fetch     fetch the distfiles of the ports of
#                                           deps.conf into AZ_DISTDIR (make fetch
#                                           of each; the port's post-fetch)
#   sh tools/az-build.sh             build everything (into an empty AZ_PREFIX)
#   sh tools/az-build.sh icu curl    rebuild only these (the rest must be there)
#
# For every library the ports framework fetches the distfiles of the port at the
# commit of deps.conf, checks them against its distinfo, extracts them and
# applies the port's patches (make patch, in the official tree PORTSDIR, which
# has to be at that commit); this script then configures and builds
# the source tree that way with its own options. A "take" line of deps.conf (a
# new upstream release the port does not have yet) gives the release file
# instead: taken from AZ_TAKE_DISTFILES (the distfiles of the port az/az),
# else fetched here, checked against the SHA-256 of the line, handed to the
# framework with a distinfo of its own, with the port's patches or those of
# files/deps/<name>-<version>/. curl and the libraries it needs
# ("bundle" in deps.conf) are the ones of --with-curl=bundled instead: the
# release files of files/curl.conf and files/curl-deps.conf
# (tools/az-curl-sources.sh), built by files/curl/build-libcurl.sh, with
# only what PHP needs (curl itself static only: the libcurl.a of PHP built on a
# server); the curl program and libcurl.so.4 of the package curl, the libcurl of
# every package (aZ, 10.11.2026), are a build of their own, with the options of the
# port ftp/curl, against the shared tree (the port ftp/curl, tools/curl-build.sh).
# The static libraries: -fPIC, into AZ_PREFIX/static
# (AZ_PREFIX: default /usr/local/az); the shared ones into AZ_PREFIX; in
# AZ_WORK/deps (default /var/tmp/az-work/deps); the licences go to
# AZ_PREFIX/LICENSES/. AZ_PREFIX is the place the libraries have on the servers
# (their .pc files, *-config scripts and run paths name it): a full build installs
# into it, on a build machine (the port copies it into its stage). It does not
# start while a package has files there, or files are there that are neither of a
# package nor of an unfinished build of this script (AZ_PREFIX/.az-build marks
# one, which is then removed). Results go to AZ_RESULTS (default az-results/
# of the current directory: summary.txt with the status of
# the static and of the shared build of every library, one log per library,
# shared.txt and shared-bad.txt of the checks of the shared tree, see finish_so;
# VERSIONS, also installed as AZ_PREFIX/share/doc/az/VERSIONS); the summary
# is printed at the end.
#
# Compiler flags as on the servers: CPUTYPE and CFLAGS of /etc/make.conf (such as
# CPUTYPE?=x86-64-v3 and CFLAGS=-O3 -pipe) with -fstack-protector-strong and
# -fno-strict-aliasing, and -fPIC. AZ_CPUTYPE and AZ_CFLAGS win over make.conf
# (MAKE_CONF, default /etc/make.conf);
# without either: x86-64-v3 and -O3 -pipe. The build runs what it compiles
# (configure tests, the data tools of ICU), so it stops at once on a CPU that
# cannot run code of that level; PHP built against the bundle needs it too.
#
# Exit status: 0 everything built, 1 a library failed (the others are still
# built where they can be) or this CPU cannot run the level, 2 usage, or
# AZ_PREFIX is not free for a full build.

set -u
# A build as from a shell. The make of the port that runs this script leaves its
# MAKEFLAGS in the environment: its command line and the variables the framework
# hands to sub-makes (.MAKEFLAGS of bsd.port.mk: ARCH=amd64, OPSYS, OSVERSION, ...),
# which every gmake here would take as variables of its own command line, above
# those of the Makefiles: FFmpeg's ARCH=x86 became ARCH=amd64, so no x86 object
# was built (ld: undefined symbol ff_bwdif_init_x86 ..., 08.11.2026).
unset MAKEFLAGS MFLAGS MAKELEVEL __MKLVL__
tools="$(cd "$(dirname "$0")" && pwd)"
# the confs and patches: files/ of the port az/az
files="${AZ_FILESDIR:-$tools/../az/az/files}"
conf="$files/deps.conf"
# A: the root of the package az (VERSIONS, LICENSES/); P: the static tree,
# S: the shared tree (see the head comment)
A="${AZ_PREFIX:-/usr/local/az}"
P="$A/static"
S="$A"
work="${AZ_WORK:-/var/tmp/az-work}/deps"
res="${AZ_RESULTS:-$(pwd)/az-results}"
# the official tree at the commit of deps.conf
ports="${PORTSDIR:-/usr/ports}"
# the distfiles of the ports (their make fetch, make patch) and those of the take lines
distdir="${AZ_DISTDIR:-$work/distfiles}"
takedist="${AZ_TAKE_DISTFILES:-$(pwd)/distfiles}"
ncpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 2)"
major="$(uname -r | cut -d. -f1)"

if [ "${1:-}" = "--tools" ]; then
    # Build tools only; none of their libraries is linked into the bundle (the
    # compiler does not search /usr/local, pkg-config only the bundle and base).
    pkgs="git cmake ninja meson python3 gmake nasm perl5 pkgconf lzip bison autoconf automake libtool gettext-tools m4 gperf tcl86"
    # shellcheck disable=SC2086
    env ASSUME_ALWAYS_YES=yes pkg install -y $pkgs
    rc=$?
    for t in $pkgs; do pkg info -e "$t" || echo "az-build: package $t is not installed"; done
    exit $rc
fi
[ -f "$conf" ] || { echo "az-build: no $conf (AZ_FILESDIR: files/ of the port az/az)" >&2; exit 2; }

say() { printf '[az-build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

# A variable of make.conf (VAR=, ?=, := and += lines; comments dropped), as in
# tools/config-check.sh.
mk_conf="${MAKE_CONF:-/etc/make.conf}"
mc_get() {
    [ -r "$mk_conf" ] || return 0
    awk -v v="$1" '
        { sub(/#.*/, "") }
        $0 ~ "^[ \t]*" v "[ \t]*[?:]?=" { s = $0; sub("^[ \t]*" v "[ \t]*[?:]?=[ \t]*", "", s); val = s; have = 1; next }
        $0 ~ "^[ \t]*" v "[ \t]*\\+=" { s = $0; sub("^[ \t]*" v "[ \t]*\\+=[ \t]*", "", s); val = val " " s; have = 1 }
        END { if (have) { sub(/[ \t]+$/, "", val); print val } }
    ' "$mk_conf"
}

# The flags of every library: CPUTYPE and CFLAGS of the servers (see above), the
# two protections, position independent so that they can go into libphp.so, and
# nothing from /usr/local: the base compiler does not search it, pkg-config only
# sees the bundle and the base system. A -march in CFLAGS gives way to CPUTYPE.
cputype="${AZ_CPUTYPE:-$(mc_get CPUTYPE)}"
cputype="${cputype:-x86-64-v3}"
opt="${AZ_CFLAGS:-$(mc_get CFLAGS)}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' ${opt:--O3 -pipe} | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
level="${cputype#x86-64-}"
export CC=cc CXX=c++
export CFLAGS="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing -fPIC"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$P/include"
export LDFLAGS="-L$P/lib"
# pkg-config with --static: there are only static libraries, so link tests and
# tools need the libraries behind them too (libidn2: libiconv).
mkdir -p "$work/bin"
printf '%s\n' '#!/bin/sh' 'exec pkgconf --static "$@"' > "$work/bin/pkg-config-static"
chmod +x "$work/bin/pkg-config-static"
export PKG_CONFIG="$work/bin/pkg-config-static"
export PKG_CONFIG_LIBDIR="$P/lib/pkgconfig:$P/libdata/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH
# the PATH without the static tree, for the shared builds (so_env)
path0="$PATH"
# The shared libraries built with GCC of the packages instead of the base clang: those
# that tools/lib-bench.sh found at least 2% faster with it, the whole interval of
# about 95% below zero (aZ, 09.11.2026; lib-bench run 42619158312: expat -12.6%,
# lcms2 -6.7%, sqlite3 -3.7%; the others the same or slower with GCC, so clang).
# Their static builds (b_*, for PHP built on a server) stay with clang: not measured.
# GCC as lib-bench measured it and as the PHP ports have it (Mk/Uses/azgcc.mk):
# -std=gnu17 (the C of clang 19; GCC 15 and later default to C23),
# -fno-semantic-interposition (with -fPIC GCC would not inline or bind the calls of
# a library to its own exported functions), -static-libgcc in CC (libgcc linked into
# each library: no NEEDED libgcc_s.so.1; in CC because libtool passes no
# -static-libgcc of LDFLAGS to the link of a shared library). AZ_GCC_SO="": none.
gcc_so="${AZ_GCC_SO-sqlite3 expat lcms2}"
gcc_bin="${AZ_GCC_BIN:-gcc16}"
gcc_env() {
    g="$(command -v "$gcc_bin")" || { echo "== $1: no $gcc_bin (lang/${gcc_bin}, a BUILD_DEPENDS of az/az)"; return 1; }
    export CC="$g -static-libgcc"
    export CFLAGS="$CFLAGS -std=gnu17 -fno-semantic-interposition"
    echo "== $1: shared build with $("$g" --version | head -n 1) (lib-bench: >= 2% faster than clang), CC=$CC, CFLAGS=$CFLAGS"
}
export PATH="$P/bin:$PATH"
# LTO (x264, as its port) puts LLVM bitcode into static archives: their index
# needs the ar of LLVM, taken by name when ar of the base system is another one.
unset AR RANLIB NM
if ! ar --version 2>/dev/null | grep -q LLVM && command -v llvm-ar >/dev/null 2>&1; then
    export AR=llvm-ar RANLIB=llvm-ranlib NM=llvm-nm
fi

ports_commit="$(awk '$1 == "ports" { print $2 }' "$conf")"
libs_all="$(awk '$1 == "lib" { print $2 }' "$conf")"
port_of() { awk -v n="$1" '$1 == "lib" && $2 == n { print $3 }' "$conf"; }
# has_kind <name> <static|shared>: the kinds of its lib line name it
has_kind() { awk -v n="$1" -v k="$2" '$1 == "lib" && $2 == n { m = split($4, t, ","); for (i = 1; i <= m; i++) if (t[i] == k) f = 1 } END { exit !f }' "$conf"; }
# take_of <name>: "version release-file SHA-256 source-dir" of its take line, if any
take_of() { awk -v n="$1" '$1 == "take" && $2 == n { print $3, $4, $5, $6 }' "$conf"; }

# The official tree PORTSDIR has to be at the commit of deps.conf (the builder
# checks it out there; a tree that is not a git checkout is taken for it, with a
# warning). It is only read here, never changed.
ports_check() {
    [ -f "$ports/Mk/bsd.port.mk" ] || { echo "az-build: no ports tree in $ports (PORTSDIR)" >&2; return 1; }
    h="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    if [ -z "$h" ]; then
        echo "az-build: $ports is not a git checkout: taken for freebsd-ports $ports_commit of deps.conf" >&2
        return 0
    fi
    [ "$h" = "$ports_commit" ] && return 0
    echo "az-build: $ports is at $h, deps.conf has $ports_commit: build with the tree at that commit, or change the ports line of deps.conf" >&2
    return 1
}
# JPEG_PORT as in make.conf of the servers: the ports with USES=jpeg (gd, ImageMagick) take mozjpeg.
# A make of its own, as from a shell: nothing of the make of the port that runs this
# script (MAKEFLAGS: its command line, its job server) reaches the official ports.
pmake() {
    p="$1"; shift
    env -u MAKEFLAGS -u MFLAGS -u __MKLVL__ make -C "$ports/$p" BATCH=yes NO_DEPENDS=yes \
        DISABLE_VULNERABILITIES=yes JPEG_PORT=graphics/mozjpeg \
        PORTSDIR="$ports" WRKDIRPREFIX="$work/wrk" DISTDIR="$distdir" "$@"
}

# Builds: $1 is the source tree after the ports' patches.
# For GNU configure the ports framework puts its own config.guess and config.sub
# into the tree (old ones do not know FreeBSD 15); so does this.
fix_guess() {
    find "$1" \( -name config.guess -o -name config.sub \) -type f | while IFS= read -r f; do
        cp "$ports/Templates/${f##*/}" "$f" && chmod a+rx "$f"
    done
}
at() {
    src="$1"; shift
    fix_guess "$src"
    (cd "$src" && ./configure --prefix="$P" --libdir="$P/lib" --includedir="$P/include" \
        --enable-static --disable-shared --with-pic "$@" && gmake -j"$ncpu" && gmake install)
}
cm() {
    src="$1"; shift
    cmake -S "$src" -B "$src/_az" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$P" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_PREFIX_PATH="$P" \
        -DCMAKE_IGNORE_PREFIX_PATH=/usr/local -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" "$@" &&
        cmake --build "$src/_az" -j "$ncpu" && cmake --install "$src/_az"
}
# meson as USES=meson of the ports (release, the optimization of CFLAGS), static
# and position independent
ms() {
    src="$1"; shift
    (cd "$src" && meson setup _az --prefix="$P" --libdir=lib --buildtype=release -Doptimization=plain \
        --default-library=static -Db_staticpic=true --wrap-mode=nodownload "$@" &&
        ninja -C _az -j "$ncpu" && ninja -C _az install)
}

b_libiconv() {
    # one job, as the port (MAKE_JOBS_UNSAFE); am_cv_func_iconv=no, as the port: not the iconv of libc
    fix_guess "$1"
    (cd "$1" && ./configure --prefix="$P" --libdir="$P/lib" --enable-static --disable-shared --with-pic \
        --disable-nls --enable-extra-encodings am_cv_func_iconv=no && gmake && gmake install)
}
b_lz4() {
    (cd "$1/lib" && gmake -j"$ncpu" liblz4.a liblz4.pc PREFIX="$P" LIBDIR="$P/lib" BUILD_SHARED=no &&
        gmake install PREFIX="$P" LIBDIR="$P/lib" PKGCONFIGDIR="$P/lib/pkgconfig" BUILD_SHARED=no)
}
b_libxml2() { at "$1" --sysconfdir="$P/share" --without-python --with-iconv="$P" --with-zlib --without-icu --without-lzma --without-readline --without-history --with-http; }
b_icu() { at "$1" --with-data-packaging=static --disable-layoutex --disable-tests --disable-samples --disable-extras; }
b_oniguruma() { cm "$1" -DBUILD_TEST=OFF -DENABLE_POSIX_API=ON; }
b_libzip() {
    cm "$1" -DENABLE_OPENSSL=ON -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DENABLE_COMMONCRYPTO=OFF \
        -DENABLE_WINDOWS_CRYPTO=OFF -DENABLE_BZIP2=ON -DENABLE_LZMA=OFF -DENABLE_ZSTD=ON \
        -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_OSSFUZZ=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF \
        -DOPENSSL_ROOT_DIR=/usr
}
b_png() { cm "$1" -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_DEBUG_POSTFIX=""; }
b_mozjpeg() {
    # as the port (JPEG8 API, SIMD), without the tools' PNG input and TurboJPEG, which gd does not use.
    # Absolute install directories: the GNUInstallDirs of mozjpeg takes a relative one as relative to
    # the current directory, so that CMAKE_INSTALL_LIBDIR=lib of cm put libjpeg.a, libjpeg.pc and its
    # cmake files outside the bundle (only the headers and manual pages got in).
    cm "$1" -DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DWITH_JPEG8=ON -DWITH_SIMD=ON -DREQUIRE_SIMD=OFF \
        -DWITH_ARITH_DEC=OFF -DWITH_ARITH_ENC=OFF -DWITH_12BIT=OFF -DWITH_JAVA=OFF -DWITH_JPEG7=OFF \
        -DWITH_TURBOJPEG=OFF -DPNG_SUPPORTED=OFF -DWITH_MEM_SRCDST=ON -DFORCE_INLINE=ON \
        -DCMAKE_INSTALL_LIBDIR="$P/lib" -DCMAKE_INSTALL_INCLUDEDIR="$P/include" \
        -DCMAKE_INSTALL_BINDIR="$P/bin" -DCMAKE_INSTALL_MANDIR="$P/share/man" \
        -DCMAKE_INSTALL_DOCDIR="$P/share/doc/mozjpeg"
}
b_webp() {
    at "$1" --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --disable-gl --disable-sdl \
        --disable-png --disable-jpeg --disable-tiff --disable-gif --disable-wic
}
b_freetype2() {
    cm "$1" -DFT_REQUIRE_ZLIB=ON -DFT_DISABLE_BZIP2=OFF -DFT_DISABLE_PNG=ON -DFT_DISABLE_HARFBUZZ=ON \
        -DFT_DISABLE_BROTLI=ON
}
# gd: the port runs autoreconf (USES=autoreconf); without fontconfig, X, TIFF, AVIF,
# HEIF. LIQ (the palette of imagegif() and imagetruecolortopalette() of PHP; aZ,
# 11.11.2026) with libimagequant of the port graphics/libimagequant, the one library
# of a port of this tree in az, linked, not built here (it is Rust): in the static
# tree its archive and header as links to those of the port and an imagequant.pc of
# its own with the libraries its Rust code needs (the Libs.private of the .pc of the
# port; LIBS for the test of configure), which gdlib.pc requires; for the shared
# build a directory of the work with its header and libimagequant.so (libgd.so takes
# libimagequant.so.0.* of /usr/local/lib, one of ldconfig, by its SONAME)
b_gd() {
    lq=/usr/local/libdata/pkgconfig/imagequant.pc
    for f in /usr/local/include/libimagequant.h /usr/local/lib/libimagequant.a "$lq"; do
        [ -e "$f" ] || { echo "== no $f (the package libimagequant of graphics/libimagequant)"; return 1; }
    done
    ll="$(pkgconf --static --libs-only-l --libs-only-other "$lq" | tr ' ' '\n' | grep -v -x -e -limagequant -e '' | tr '\n' ' ')"
    mkdir -p "$P/include" "$P/lib/pkgconfig" &&
        ln -sf /usr/local/include/libimagequant.h "$P/include/libimagequant.h" &&
        ln -sf /usr/local/lib/libimagequant.a "$P/lib/libimagequant.a" &&
        printf '%s\n' "prefix=$P" 'libdir=${prefix}/lib' 'includedir=${prefix}/include' '' 'Name: imagequant' \
            'Description: libimagequant of graphics/libimagequant' "Version: $(pkgconf --modversion "$lq")" \
            'Libs: -L${libdir} -limagequant' "Libs.private: $ll" 'Cflags: -I${includedir}' \
            > "$P/lib/pkgconfig/imagequant.pc" || return 1
    (cd "$1" && autoreconf -fi) &&
        (LIBS="$ll" && export LIBS &&
            at "$1" --enable-gd-formats --with-zlib --with-png="$P" --with-jpeg="$P" --with-webp="$P" \
                --with-freetype="$P" --without-fontconfig --without-xpm --without-x --without-tiff \
                --without-avif --without-heif --without-raqm --with-liq="$P" --with-libiconv-prefix="$P") &&
        grep -q '^#define HAVE_LIBIMAGEQUANT 1' "$1/src/config.h" ||
        { echo "== gd: configure found no libimagequant (src/config.h)"; return 1; }
    pc_add "$P/lib/pkgconfig/gdlib.pc" Requires.private imagequant
}
b_libmcrypt() { at "$1"; }
b_libevent() { at "$1" --enable-openssl --enable-thread-support --disable-samples --disable-libevent-regress; }
b_libmemcached() {
    # no SASL (cyrus-sasl loads its mechanisms as modules); the hashes of the port
    cm "$1" -DENABLE_SASL=OFF -DBUILD_TESTING=OFF -DBUILD_DOCS=OFF -DBUILD_DOCSONLY=OFF \
        -DENABLE_HASH_FNV64=ON -DENABLE_HASH_HSIEH=ON -DENABLE_HASH_MURMUR=ON -DENABLE_MEMASLAP=OFF
}
b_libsodium() { at "$1"; }
b_argon2() {
    # its Makefile builds static and shared, with -march=$(OPTTARGET) (native by default)
    (cd "$1" && gmake -j"$ncpu" libargon2.a OPTTARGET="$cputype" &&
        mkdir -p "$P/include" "$P/lib/pkgconfig" && cp include/argon2.h "$P/include/" &&
        cp libargon2.a "$P/lib/" &&
        printf '%s\n' "prefix=$P" 'libdir=${prefix}/lib' 'includedir=${prefix}/include' '' \
            'Name: libargon2' 'Description: Argon2 password hashing' 'Version: 20190702' \
            'Libs: -L${libdir} -largon2 -lpthread' 'Cflags: -I${includedir}' > "$P/lib/pkgconfig/libargon2.pc")
}
b_readline() { at "$1" --with-curses --enable-bracketed-paste-default; }
b_gettext() {
    # gettext-runtime (WRKSRC of the port); only libintl is wanted (ext/gettext of 5.6)
    at "$1" --disable-csharp --disable-java --disable-libasprintf --disable-threads --disable-openmp \
        --disable-acl --with-libiconv-prefix="$P" --without-emacs ac_cv_lib_rt_sched_yield=no
}
# For ImageMagick and FFmpeg:
b_expat() { at "$1" --without-docbook --without-examples --without-tests --without-xmlwf; }
# fontconfig with the paths of the port, so that it reads the configuration, fonts
# and cache of the system; installed through a stage directory (nothing into
# /usr/local outside the tree)
b_fontconfig() {
    st="$work/stage-fontconfig"
    rm -rf "$st"
    (cd "$1" && meson setup _az --prefix="$P" --libdir=lib --sysconfdir=/usr/local/etc --localstatedir=/var \
        --buildtype=release -Doptimization=plain --default-library=static -Db_staticpic=true \
        --wrap-mode=nodownload -Ddoc=disabled -Dtests=disabled -Dtools=disabled -Dnls=disabled \
        -Dcache-build=disabled -Dcache-dir=/var/db/fontconfig -Ddefault-fonts-dirs=/usr/local/share/fonts \
        -Dadditional-fonts-dirs=/usr/local/lib/X11/fonts -Dtemplate-dir=/usr/local/etc/fonts/conf.avail \
        -Dxml-dir=/usr/local/etc/fonts &&
        ninja -C _az -j "$ncpu" && DESTDIR="$st" ninja -C _az install) &&
        cp -R "$st$P/." "$P/"
}
# lcms2 as the port (fast float and threaded plugins), without its tools
b_lcms2() { at "$1" --with-fastfloat --with-threaded --without-jpeg --without-tiff; }
# dav1d as the port, without its tools, tests and examples
b_dav1d() { ms "$1" -Denable_tools=false -Denable_tests=false -Denable_examples=false; }
# the HEVC decoder of libheif (HEIC), no encoder, no tools
b_libde265() {
    cm "$1" -DENABLE_ENCODER=OFF -DENABLE_DECODER=OFF -DENABLE_SDL=OFF -DENABLE_INTERNAL_DEVELOPMENT_TOOLS=OFF
}
# SVT-AV1 (the AV1 encoder of libheif and FFmpeg): the library only, without its
# application and tests; no LTO in the static archive (bitcode for its users), no
# git hash (a release tarball)
b_svtav1() { cm "$1" -DBUILD_APPS=OFF -DBUILD_TESTING=OFF -DNATIVE=OFF -DEXCLUDE_HASH=ON -DSVT_AV1_LTO=OFF; }
# libheif: reading HEIC (libde265) and AVIF (dav1d), writing AVIF (SVT-AV1), built in
# (no plugins); no HEVC encoder (x265), JPEG 2000, VVC or uncompressed codecs, no tools
b_libheif() {
    cm "$1" -DBUILD_TESTING=OFF -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON \
        -DBUILD_DOCUMENTATION=OFF -DWITH_EXAMPLES=OFF -DWITH_GDK_PIXBUF=OFF -DENABLE_PLUGIN_LOADING=OFF \
        -DWITH_LIBSHARPYUV=OFF -DWITH_FUZZERS=OFF -DBUILD_DEVELOPMENT_TOOLS=OFF \
        -DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF -DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF \
        -DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF -DWITH_X265=OFF -DWITH_X264=OFF -DWITH_RAV1E=OFF \
        -DWITH_SvtEnc=ON -DWITH_SvtEnc_PLUGIN=OFF -DWITH_FFMPEG_DECODER=OFF -DWITH_OpenH264_DECODER=OFF -DWITH_OpenH264_ENCODER=OFF \
        -DWITH_JPEG_DECODER=OFF -DWITH_JPEG_ENCODER=OFF -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF \
        -DWITH_OPENJPH_DECODER=OFF -DWITH_OPENJPH_ENCODER=OFF -DWITH_KVAZAAR=OFF -DWITH_UVG266=OFF \
        -DWITH_VVDEC=OFF -DWITH_VVENC=OFF -DWITH_UNCOMPRESSED_CODEC=OFF
}

# The shared builds (s_<name>, into S): the patched source of the static build, a
# copy of the work directory (or out of the tree, the libraries of the bundled
# curl), with the options of b_<name>, so that the headers and the behaviour are
# the same; the OpenSSL of the base system and the other libraries of S. so_env
# (in the subshell of the build) leaves nothing of the static tree P to be seen:
# no -I or -L of it, not its pkgconfig, not its bin/. Every library and what links
# it gets the run path S/lib (no ldconfig), RELRO and BIND_NOW.
so_env() {
    export CPPFLAGS="-I$S/include"
    export LDFLAGS="-L$S/lib -Wl,-rpath,$S/lib -Wl,-z,relro,-z,now"
    export PKG_CONFIG=pkgconf
    # libdata/pkgconfig too, as for P: the patches of some ports put their .pc there
    # (freetype2), and finish_so moves them only at the end; without it the shared gd
    # found no freetype2 and was built without FreeType, and gd.so of PHP wanted
    # gdFontCacheShutdown (build.yml 42535396922)
    export PKG_CONFIG_LIBDIR="$S/lib/pkgconfig:$S/libdata/pkgconfig:/usr/libdata/pkgconfig"
    export PATH="$S/bin:$path0"
}
at_so() {
    src="$1"; shift
    fix_guess "$src"
    (cd "$src" && ./configure --prefix="$S" --libdir="$S/lib" --includedir="$S/include" \
        --disable-static --enable-shared --with-pic "$@" && gmake -j"$ncpu" && gmake install)
}
# cm_so_in <build dir> <source> <options>: CMake writes the run path itself
# (CMAKE_INSTALL_RPATH); one in LDFLAGS it would try to rewrite at the install
cm_so_in() {
    bd="$1" src="$2"; shift 2
    LDFLAGS="-L$S/lib -Wl,-z,relro,-z,now" cmake -S "$src" -B "$bd" -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$S" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_PREFIX_PATH="$S" \
        -DCMAKE_IGNORE_PREFIX_PATH="/usr/local;$P" -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_RPATH="$S/lib" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_CXX_FLAGS="$CXXFLAGS" "$@" &&
        cmake --build "$bd" -j "$ncpu" && cmake --install "$bd"
}
cm_so() { s="$1"; shift; cm_so_in "$s/_az" "$s" "$@"; }
ms_so() {
    src="$1"; shift
    (cd "$src" && meson setup _az --prefix="$S" --libdir=lib --buildtype=release -Doptimization=plain \
        --default-library=shared --wrap-mode=nodownload "$@" &&
        ninja -C _az -j "$ncpu" && ninja -C _az install)
}
# The libraries of the bundled curl: out of the tree of tools/az-curl-sources.sh (it
# stays as build-libcurl.sh builds it), in $work/obj-so/<name>, with the options
# of build-libcurl.sh; the make variables of notools there keep the autotools
# from running.
so_notools="ACLOCAL=: AUTOCONF=: AUTOMAKE=: AUTOHEADER=: MAKEINFO=:"
so_conf() {
    o="$work/obj-so/$1" s="$2"; shift 2
    rm -rf "$o" && mkdir -p "$o" &&
        (cd "$o" && LIBS= "$s/configure" --prefix="$S" --libdir="$S/lib" --includedir="$S/include" \
            --disable-static --enable-shared --with-pic --disable-dependency-tracking "$@")
}
# shellcheck disable=SC2086
so_mk() { d="$1"; shift; (cd "$work/obj-so/$d" && gmake $so_notools "$@"); }

s_libiconv() {
    fix_guess "$1"
    (cd "$1" && ./configure --prefix="$S" --libdir="$S/lib" --disable-static --enable-shared \
        --disable-nls --enable-extra-encodings am_cv_func_iconv=no && gmake && gmake install) &&
        rm -f "$S/lib/preloadable_libiconv.so"
}
s_c_ares() {
    so_conf c-ares "$1" --disable-tests && so_mk c-ares -j"$ncpu" -C src/lib && so_mk c-ares -C src/lib install &&
        so_mk c-ares -C include install && so_mk c-ares install-pkgconfigDATA
}
s_nghttp2() { so_conf nghttp2 "$1" --enable-lib-only && so_mk nghttp2 -j"$ncpu" -C lib && so_mk nghttp2 -C lib install; }
s_libidn2() {
    so_conf libidn2 "$1" --disable-nls --with-included-libunistring --with-libiconv-prefix="$S" ac_cv_prog_RONN=true &&
        so_mk libidn2 -j"$ncpu" -C gl && so_mk libidn2 -j"$ncpu" -C unistring && so_mk libidn2 -j"$ncpu" -C lib &&
        so_mk libidn2 -C lib install && so_mk libidn2 install-pkgconfigDATA
}
# brotli and zstd with their CMake (build-libcurl.sh compiles them by hand, static)
s_brotli() {
    rm -rf "$work/obj-so/brotli"
    cm_so_in "$work/obj-so/brotli" "$1" -DBROTLI_BUILD_TOOLS=OFF -DBROTLI_DISABLE_TESTS=ON
}
s_zstd() {
    # legacy formats from v0.5 on, as the static one; multithreaded, as its shared library is
    rm -rf "$work/obj-so/zstd"
    cm_so_in "$work/obj-so/zstd" "$1/build/cmake" -DZSTD_BUILD_SHARED=ON -DZSTD_BUILD_STATIC=OFF \
        -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF -DZSTD_BUILD_CONTRIB=OFF \
        -DZSTD_LEGACY_SUPPORT=ON -DZSTD_LEGACY_LEVEL=5 -DZSTD_MULTITHREAD_SUPPORT=ON
}
s_libpsl() {
    # as lib_libpsl of build-libcurl.sh (the built-in list only); HAVE_VISIBILITY gives
    # PSL_API the visibility default (include/libpsl.h.in), the rest stays hidden
    s="$1" o="$work/obj-so/libpsl"
    rm -rf "$o" && mkdir -p "$o/include" "$S/lib/pkgconfig" "$S/include" || return 1
    v="$(tr -d ' \n' < "$s/version.txt")"
    IFS=. read -r va vb vc <<EOF
$v
EOF
    sed -e "s/@LIBPSL_VERSION@/$v/" -e "s/@LIBPSL_VERSION_MAJOR@/$va/" -e "s/@LIBPSL_VERSION_MINOR@/$vb/" \
        -e "s/@LIBPSL_VERSION_PATCH@/$vc/" -e "s/@LIBPSL_VERSION_NUMBER@/$(printf '0x%02x%02x%02x' "$va" "$vb" "$vc")/" \
        -e "s/@COPYRIGHT_YEAR@/$(date +%Y)/" "$s/include/libpsl.h.in" > "$o/include/libpsl.h" &&
        printf '%s\n' '#define ENABLE_BUILTIN 1' '#define HAVE_NL_LANGINFO 1' '#define HAVE_VISIBILITY 1' \
            "#define PACKAGE_VERSION \"$v\"" > "$o/config.h" || return 1
    for f in psl lookup_string_in_fixed_set; do
        # shellcheck disable=SC2086
        cc $CFLAGS -fvisibility=hidden -DHAVE_CONFIG_H -DBUILDING_PSL "-I$o" "-I$o/include" -c "$s/src/$f.c" -o "$o/$f.o" || return 1
    done
    # shellcheck disable=SC2086
    cc -shared -o "$S/lib/libpsl.so.5" -Wl,-soname,libpsl.so.5 "$o/psl.o" "$o/lookup_string_in_fixed_set.o" $LDFLAGS &&
        ln -sf libpsl.so.5 "$S/lib/libpsl.so" && cp "$o/include/libpsl.h" "$S/include/" &&
        printf '%s\n' "prefix=$S" 'libdir=${prefix}/lib' 'includedir=${prefix}/include' '' 'Name: libpsl' \
            'Description: Public Suffix List C library' "Version: $v" 'Libs: -L${libdir} -lpsl' \
            'Cflags: -I${includedir}' > "$S/lib/pkgconfig/libpsl.pc"
}
# libssh2: the options of the static one (lib_libssh2 of build-libcurl.sh), with the
# OpenSSL and zlib of the base system, as the other shared libraries
s_libssh2() {
    so_conf libssh2 "$1" --with-crypto=openssl --with-libssl-prefix=/usr --with-libz --enable-hidden-symbols \
        --disable-examples-build --disable-docker-tests --disable-sshd-tests &&
        so_mk libssh2 -j"$ncpu" -C src && so_mk libssh2 -C src install &&
        so_mk libssh2 install-includeHEADERS install-pkgconfigDATA
}
s_lz4() {
    (cd "$1/lib" && gmake -j"$ncpu" liblz4 liblz4.pc PREFIX="$S" LIBDIR="$S/lib" BUILD_STATIC=no &&
        gmake install PREFIX="$S" LIBDIR="$S/lib" PKGCONFIGDIR="$S/lib/pkgconfig" BUILD_STATIC=no)
}
s_libxml2() { at_so "$1" --sysconfdir="$S/share" --without-python --with-iconv="$S" --with-zlib --without-icu --without-lzma --without-readline --without-history --with-http; }
s_icu() { at_so "$1" --with-data-packaging=library --disable-layoutex --disable-tests --disable-samples --disable-extras; }
s_oniguruma() { cm_so "$1" -DBUILD_TEST=OFF -DENABLE_POSIX_API=ON; }
s_libzip() {
    cm_so "$1" -DENABLE_OPENSSL=ON -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DENABLE_COMMONCRYPTO=OFF \
        -DENABLE_WINDOWS_CRYPTO=OFF -DENABLE_BZIP2=ON -DENABLE_LZMA=OFF -DENABLE_ZSTD=ON \
        -DBUILD_TOOLS=OFF -DBUILD_REGRESS=OFF -DBUILD_OSSFUZZ=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF \
        -DOPENSSL_ROOT_DIR=/usr
}
s_png() { cm_so "$1" -DPNG_SHARED=ON -DPNG_STATIC=OFF -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_DEBUG_POSTFIX=""; }
s_mozjpeg() {
    cm_so "$1" -DENABLE_SHARED=ON -DENABLE_STATIC=OFF -DWITH_JPEG8=ON -DWITH_SIMD=ON -DREQUIRE_SIMD=OFF \
        -DWITH_ARITH_DEC=OFF -DWITH_ARITH_ENC=OFF -DWITH_12BIT=OFF -DWITH_JAVA=OFF -DWITH_JPEG7=OFF \
        -DWITH_TURBOJPEG=OFF -DPNG_SUPPORTED=OFF -DWITH_MEM_SRCDST=ON -DFORCE_INLINE=ON \
        -DCMAKE_INSTALL_LIBDIR="$S/lib" -DCMAKE_INSTALL_INCLUDEDIR="$S/include" \
        -DCMAKE_INSTALL_BINDIR="$S/bin" -DCMAKE_INSTALL_MANDIR="$S/share/man" \
        -DCMAKE_INSTALL_DOCDIR="$S/share/doc/mozjpeg"
}
s_webp() {
    at_so "$1" --enable-libwebpdecoder --enable-libwebpdemux --enable-libwebpmux --disable-gl --disable-sdl \
        --disable-png --disable-jpeg --disable-tiff --disable-gif --disable-wic
}
s_freetype2() {
    cm_so "$1" -DFT_REQUIRE_ZLIB=ON -DFT_DISABLE_BZIP2=OFF -DFT_DISABLE_PNG=ON -DFT_DISABLE_HARFBUZZ=ON \
        -DFT_DISABLE_BROTLI=ON
}
s_gd() {
    for f in /usr/local/include/libimagequant.h /usr/local/lib/libimagequant.so; do
        [ -e "$f" ] || { echo "== no $f (the package libimagequant of graphics/libimagequant)"; return 1; }
    done
    q="$work/liq-so"
    mkdir -p "$q/include" "$q/lib" &&
        ln -sf /usr/local/include/libimagequant.h "$q/include/libimagequant.h" &&
        ln -sf /usr/local/lib/libimagequant.so "$q/lib/libimagequant.so" || return 1
    (cd "$1" && autoreconf -fi) &&
        at_so "$1" --enable-gd-formats --with-zlib --with-png="$S" --with-jpeg="$S" --with-webp="$S" \
            --with-freetype="$S" --without-fontconfig --without-xpm --without-x --without-tiff \
            --without-avif --without-heif --without-raqm --with-liq="$q" --with-libiconv-prefix="$S" &&
        grep -q '^#define HAVE_LIBIMAGEQUANT 1' "$1/src/config.h" ||
        { echo "== gd: configure found no libimagequant (src/config.h)"; return 1; }
    # the directory of the work out of gdlib.pc (Libs.private: -limagequant)
    for pc in "$S/lib/pkgconfig/gdlib.pc" "$S/libdata/pkgconfig/gdlib.pc"; do
        [ -f "$pc" ] && sed -i '' "s| -L$q/lib||g" "$pc"
    done
    return 0
}
s_libmcrypt() { at_so "$1"; }
s_libmemcached() {
    cm_so "$1" -DENABLE_SASL=OFF -DBUILD_TESTING=OFF -DBUILD_DOCS=OFF -DBUILD_DOCSONLY=OFF \
        -DENABLE_HASH_FNV64=ON -DENABLE_HASH_HSIEH=ON -DENABLE_HASH_MURMUR=ON -DENABLE_MEMASLAP=OFF
}
s_libsodium() { at_so "$1"; }
s_argon2() {
    # the shared library as the port security/libargon2 builds it (SO_LDFLAGS with the
    # soname libargon2.so.0), -march=$cputype as b_argon2
    (cd "$1" && gmake libargon2.so OPTTARGET="$cputype" SO_LDFLAGS="-shared -Wl,-soname=libargon2.so.0 $LDFLAGS" &&
        mkdir -p "$S/include" "$S/lib/pkgconfig" && cp include/argon2.h "$S/include/" &&
        install -m 755 libargon2.so "$S/lib/libargon2.so.0" && ln -sf libargon2.so.0 "$S/lib/libargon2.so" &&
        printf '%s\n' "prefix=$S" 'libdir=${prefix}/lib' 'includedir=${prefix}/include' '' \
            'Name: libargon2' 'Description: Argon2 password hashing' 'Version: 20190702' \
            'Libs: -L${libdir} -largon2' 'Libs.private: -lpthread' 'Cflags: -I${includedir}' > "$S/lib/pkgconfig/libargon2.pc")
}
# SHLIB_LIBS, the libraries that shlib/Makefile of readline links libreadline.so
# with, gets libncursesw of the base system (the curses of b_readline), so that
# libreadline.so names it itself and a module that links only -lreadline loads
s_readline() {
    fix_guess "$1"
    (cd "$1" && ./configure --prefix="$S" --libdir="$S/lib" --includedir="$S/include" \
        --disable-static --enable-shared --with-curses --enable-bracketed-paste-default &&
        gmake -j"$ncpu" SHLIB_LIBS=-lncursesw && gmake install SHLIB_LIBS=-lncursesw)
}
s_gettext() {
    at_so "$1" --disable-csharp --disable-java --disable-libasprintf --disable-threads --disable-openmp \
        --disable-acl --with-libiconv-prefix="$S" --without-emacs ac_cv_lib_rt_sched_yield=no
}
s_expat() { at_so "$1" --without-docbook --without-examples --without-tests --without-xmlwf; }
s_fontconfig() {
    st="$work/stage-fontconfig-so"
    rm -rf "$st"
    (cd "$1" && meson setup _az --prefix="$S" --libdir=lib --sysconfdir=/usr/local/etc --localstatedir=/var \
        --buildtype=release -Doptimization=plain --default-library=shared \
        --wrap-mode=nodownload -Ddoc=disabled -Dtests=disabled -Dtools=disabled -Dnls=disabled \
        -Dcache-build=disabled -Dcache-dir=/var/db/fontconfig -Ddefault-fonts-dirs=/usr/local/share/fonts \
        -Dadditional-fonts-dirs=/usr/local/lib/X11/fonts -Dtemplate-dir=/usr/local/etc/fonts/conf.avail \
        -Dxml-dir=/usr/local/etc/fonts &&
        ninja -C _az -j "$ncpu" && DESTDIR="$st" ninja -C _az install) &&
        cp -R "$st$S/." "$S/"
}
s_lcms2() { at_so "$1" --with-fastfloat --with-threaded --without-jpeg --without-tiff; }
s_dav1d() { ms_so "$1" -Denable_tools=false -Denable_tests=false -Denable_examples=false; }
s_libde265() {
    cm_so "$1" -DENABLE_ENCODER=OFF -DENABLE_DECODER=OFF -DENABLE_SDL=OFF -DENABLE_INTERNAL_DEVELOPMENT_TOOLS=OFF
}
s_svtav1() { cm_so "$1" -DBUILD_APPS=OFF -DBUILD_TESTING=OFF -DNATIVE=OFF -DEXCLUDE_HASH=ON; }
s_libheif() {
    cm_so "$1" -DBUILD_TESTING=OFF -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON \
        -DBUILD_DOCUMENTATION=OFF -DWITH_EXAMPLES=OFF -DWITH_GDK_PIXBUF=OFF -DENABLE_PLUGIN_LOADING=OFF \
        -DWITH_LIBSHARPYUV=OFF -DWITH_FUZZERS=OFF -DBUILD_DEVELOPMENT_TOOLS=OFF \
        -DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF -DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF \
        -DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF -DWITH_X265=OFF -DWITH_X264=OFF -DWITH_RAV1E=OFF \
        -DWITH_SvtEnc=ON -DWITH_SvtEnc_PLUGIN=OFF -DWITH_FFMPEG_DECODER=OFF -DWITH_OpenH264_DECODER=OFF -DWITH_OpenH264_ENCODER=OFF \
        -DWITH_JPEG_DECODER=OFF -DWITH_JPEG_ENCODER=OFF -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF \
        -DWITH_OPENJPH_DECODER=OFF -DWITH_OPENJPH_ENCODER=OFF -DWITH_KVAZAAR=OFF -DWITH_UVG266=OFF \
        -DWITH_VVDEC=OFF -DWITH_VVENC=OFF -DWITH_UNCOMPRESSED_CODEC=OFF
}
# Shared only (deps.conf), for the PHP modules sqlite3 and pdo_sqlite, gmp, xsl, ffi, tidy:
# sqlite3 as the port with its default options (CPPFLAGS and OPTIONS of
# databases/sqlite3), one make job (MAKE_JOBS_UNSAFE); the library, its headers and
# sqlite3.pc only (main.mk: the target so, install-dll, install-headers, install-pc).
# Its code generators run with the tclsh of the port's USES=tcl:build (lang/tcl86
# of --tools), else with the jimsh it builds itself (B.tclsh of main.mk).
s_sqlite3() {
    tclsh=""
    [ -x /usr/local/bin/tclsh8.6 ] && tclsh="--with-tclsh=/usr/local/bin/tclsh8.6"
    (CPPFLAGS="$CPPFLAGS -DHAVE_FCHOWN=1 -DHAVE_FDATASYNC=1 -DHAVE_GMTIME_R=1 -DHAVE_ISNAN=1 \
-DHAVE_LOCALTIME_R=1 -DHAVE_LSTAT=1 -DHAVE_MALLOC_USABLE_SIZE=1 -DHAVE_PREAD=1 -DHAVE_PWRITE=1 \
-DHAVE_READLINK=1 -DHAVE_STRCHRNUL=1 -DHAVE_STRERROR_R=1 -DHAVE_USLEEP=1 -DSQLITE_DEFAULT_FILE_PERMISSIONS=0644 \
-DSQLITE_OS_UNIX=1 -DSQLITE_STRICT_SUBTYPE=1 -DSQLITE_ENABLE_DBPAGE_VTAB=1 -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
-DSQLITE_ENABLE_FTS3_TOKENIZER=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1 -DSQLITE_ENABLE_COLUMN_METADATA=1 \
-DSQLITE_SECURE_DELETE=1 -DSQLITE_ENABLE_UNLOCK_NOTIFY=1 -DSQLITE_USE_URI=1"
        export CPPFLAGS
        cd "$1" && ./configure --prefix="$S" --libdir="$S/lib" --includedir="$S/include" \
            --soname=legacy --linemacros --enable-load-extension --fts3 --fts4 --fts5 --rtree --session \
            --with-tempstore=no --disable-tcl --disable-static OPTIONS='-lm -lpthread' $tclsh &&
            gmake so && gmake install-dll install-headers install-pc)
}
# gmp for the generic host of the ports (config.guess of fix_guess), fat: with the
# code of every x86-64 CPU, it takes the one of the CPU it runs on at run time. On
# a server it is built with CPU_OPTS (code for the CPU of that machine); this one
# is built on the CPU of the CI runner for every server of the level, so fat is
# the safe way to the same speed. No C++.
# the manual is not built (doc/ out of SUBDIRS, as the port with INFO off: OPTIONS_UNSET
# of the servers); with INFO on the port removes doc/gmp.info and needs makeinfo
s_gmp() { sed -i '' -e '/^SUBDIRS/ s|doc||' "$1/Makefile.in" && at_so "$1" --disable-cxx --enable-fat; }
s_libxslt() { at_so "$1" --without-python --without-crypto --without-plugins; }
s_libffi() {
    (LDFLAGS="$LDFLAGS -Wl,--undefined-version"; export LDFLAGS
        at_so "$1" --disable-multi-os-directory --disable-docs)
}
# libevent: as the static one (b_libevent), with the OpenSSL of the base system
# (libevent_openssl), for databases/memcached
s_libevent() { at_so "$1" --enable-openssl --enable-thread-support --disable-samples --disable-libevent-regress; }
# x264 as the port (options ASM, LTO and OPTIMIZED_CFLAGS on), the library only, for
# multimedia/ffmpeg
s_x264() { ms_so "$1" -Dcli=false -Dasm=enabled -Db_lto=true; }
# xxhash: libxxhash.so, its headers and pkg-config file (not xxhsum), for net/rsync
s_xxhash() {
    (cd "$1" && gmake -j"$ncpu" libxxhash libxxhash.pc PREFIX="$S" LIBDIR="$S/lib" PKGCONFIGDIR="$S/lib/pkgconfig" &&
        gmake install_libxxhash install_libxxhash.includes install_libxxhash.pc PREFIX="$S" LIBDIR="$S/lib" \
            PKGCONFIGDIR="$S/lib/pkgconfig")
}
# libmaxminddb, for www/mod_maxminddb (and nginx later); not its tests
s_libmaxminddb() { at_so "$1" --disable-tests; }
# libuv and liburcu (all its flavours), for dns/bind-tools; as their ports
s_libuv() { at_so "$1" --disable-maintainer-mode; }
s_liburcu() { at_so "$1"; }
# fmt, for databases/mariadb1011-server and -client (which take it header-only,
# FMT_HEADER_ONLY): its headers and libfmt.so, as the port (FMT_OS, no tests, docs
# or module; FULL_CACHE_DRAGONBOX, its default option)
s_fmt() {
    (CXXFLAGS="$CXXFLAGS -DFMT_USE_FULL_CACHE_DRAGONBOX=1" && cm_so "$1" -DFMT_OS=ON -DFMT_DOC=OFF -DFMT_TEST=OFF \
        -DFMT_FUZZ=OFF -DFMT_MODULE=OFF -DFMT_PEDANTIC=OFF -DFMT_SYSTEM_HEADERS=OFF -DFMT_WERROR=OFF -DFMT_CUDA_TEST=OFF)
}
# tidy: the library only (no program, no manual page); the static libtidy it builds anyway goes in finish
# lib/libtidy5.so as the port names it (its post-install renames libtidy.so; its patch makes
# tidy.pc say -ltidy5, and ext/tidy of PHP takes libtidy5 first); libtidy.so stays too
# APR and APR-util of devel/apr1 (both in its work directory; $1 is apr), shared
# only, for www/apache24 and the modules Apache loads. apr as the port (its
# APR_CONF_ARGS; IPv6, an option of the port on by default), its build files (the
# libtool and rules apxs and the modules take) in share/apr/build-1 of this tree;
# APR-util as the port without its options (autoreconf for its patch of
# build/dbm.m4, as the port), with the expat of this tree and the DBM of its own
# (SDBM): no Berkeley DB, GDBM or NDBM, no database, LDAP or crypto drivers
s_apr() {
    fix_guess "$1"
    apu="$(ls -d "$1"/../apr-util-* 2> /dev/null | head -n 1)"
    [ -n "$apu" ] || { echo "== no apr-util next to $1"; return 1; }
    (cd "$1" && ./configure --prefix="$S" --libdir="$S/lib" --disable-static --enable-shared \
        --with-installbuilddir="$S/share/apr/build-1" --enable-threads --enable-posix-shm \
        --with-devrandom --enable-ipv6 && gmake -j"$ncpu" && gmake install) &&
        (cd "$apu" && autoreconf -f -i && ./configure --prefix="$S" --libdir="$S/lib" \
            --with-apr="$S/bin/apr-1-config" --with-expat="$S" --without-berkeley-db --without-gdbm \
            --without-ndbm --without-ldap --without-mysql --without-pgsql --without-sqlite3 \
            --without-sqlite2 --without-odbc --without-crypto --without-openssl --without-nss &&
            gmake -j"$ncpu" && gmake install)
}
s_tidy() {
    cm_so "$1" -DBUILD_SHARED_LIB=ON -DSUPPORT_CONSOLE_APP=OFF &&
        ln -sf "$(readlink "$S/lib/libtidy.so")" "$S/lib/libtidy5.so"
}

# lic <name> <source>: the licence files of a library into LICENSES/ (libpng
# 1.6.59 has a directory LICENSES too)
lic() {
    mkdir -p "$A/LICENSES"
    for f in "$2"/COPYING* "$2"/LICENSE* "$2"/LICENCE* "$2"/PATENTS* "$2"/COPYRIGHT*; do
        [ -e "$f" ] && cp -R "$f" "$A/LICENSES/$1-${f##*/}"
    done
    return 0
}

# take_args <name> <port>: the make arguments that build the release of the take
# line of <name> instead of the port's distfiles, after fetching the file into
# DISTDIR and checking its SHA-256; nothing when there is no take line. The
# version goes to $take_ver.
take_args() {
    take_ver=""
    t="$(take_of "$1")"
    [ -n "$t" ] || return 0
    set -- $t "$2"
    take_ver="$1"
    # several addresses of the same file, separated by commas: the first one that works
    tf="${2%%,*}"; tf="${tf##*/}"
    mkdir -p "$work/distfiles"
    if [ ! -f "$work/distfiles/$tf" ] || [ "$(sha256 -q "$work/distfiles/$tf")" != "$3" ]; then
        rm -f "$work/distfiles/$tf"
        if [ -f "$takedist/$tf" ] && [ "$(sha256 -q "$takedist/$tf")" = "$3" ]; then
            # a distfile of the port az/az (its fetch phase, checked against its
            # distinfo), or fetched before the build some other way
            cp "$takedist/$tf" "$work/distfiles/$tf"
            echo "== $tf: from $takedist" >&2
        else
            # every address up to three times: a release file of GitHub sometimes stalls
            echo "== $tf: not in $takedist, fetched here" >&2
            for try in 1 2 3; do
                for u in $(echo "$2" | tr ',' ' '); do
                    fetch -q -T 60 -o "$work/distfiles/$tf" "$u" && break 2
                    echo "== fetch $u failed (try $try of 3)" >&2
                    rm -f "$work/distfiles/$tf"
                done
                [ "$try" = 3 ] || sleep $((try * 15))
            done
        fi
        [ -f "$work/distfiles/$tf" ] || return 1
    fi
    if [ "$(sha256 -q "$work/distfiles/$tf")" != "$3" ]; then
        echo "== $tf: SHA-256 $(sha256 -q "$work/distfiles/$tf"), not $3 as in deps.conf" >&2
        return 1
    fi
    printf 'TIMESTAMP = %s\nSHA256 (%s) = %s\nSIZE (%s) = %s\n' "$(date +%s)" "$tf" "$3" "$tf" \
        "$(stat -f %z "$work/distfiles/$tf")" > "$work/distinfo-take-$n"
    wd="$(pmake "$5" -V WRKDIR)"
    pd="$files/deps/$n-$take_ver"
    # its own DISTDIR: the ports' one (AZ_DISTDIR) may not be writable
    printf '%s\n' "DISTDIR=$work/distfiles" "DISTFILES=$tf" "PATCHFILES=" "DISTINFO_FILE=$work/distinfo-take-$n" "WRKSRC=$wd/$4"
    if [ -d "$pd" ]; then printf '%s\n' "PATCHDIR=$pd"; fi
}

# One library: fetch, check, extract and patch with the ports framework, then build
# it as its kinds in deps.conf say: static into P (b_<name>), shared into S
# (s_<name>, in a copy of the work directory made right after the patches, so that
# both build the same patched source and the static build leaves nothing in it);
# one log for both, one line of the summary with the status of each ("-": not of
# that kind).
build_one() {
    n="$1"
    port="$(port_of "$n")"
    log="$res/$n.log"
    start=$(date +%s)
    if [ "$port" = bundle ]; then build_bundle "$n"; return; fi
    targs="$(take_args "$n" "$port" 2>"$res/$n.take")"
    trc=$?
    take_of "$n" | grep -q . && take_ver="$(take_of "$n" | awk '{ print $1 }')" || take_ver=""
    # shellcheck disable=SC2086
    src="$(pmake "$port" $targs -V WRKSRC 2>/dev/null)"
    # shellcheck disable=SC2086
    wd="$(pmake "$port" $targs -V WRKDIR 2>/dev/null)"
    (
        if [ "$trc" != 0 ]; then cat "$res/$n.take"; echo "== $n: the release of the take line could not be had"; exit 1; fi
        if [ -n "$take_ver" ]; then
            echo "== $n: $port at $ports_commit with the release $take_ver of the take line in deps.conf:"
            # the failed tries before the one that worked
            [ ! -s "$res/$n.take" ] || cat "$res/$n.take"
            printf '   %s\n' $targs
        else
            echo "== $n: $port at $ports_commit"
        fi
        # shellcheck disable=SC2086
        pmake "$port" $targs clean >/dev/null 2>&1
        [ -n "$wd" ] && [ -n "$src" ] || { echo "== no WRKDIR or WRKSRC of $port (make -V)"; exit 1; }
        rm -rf "$wd.so"
        # shellcheck disable=SC2086
        pmake "$port" $targs patch || { echo "make patch failed"; exit 1; }
        # a fix the port lacks (a vulnerability that touches us, or a bug we have; rule
        # of 04.11.2026): files/deps/<name>-<version>.patch, -p0 as those of files/curl,
        # after the patches of the port (or of the take line); one for another version
        # than the one built stops the build, so that it gets reviewed
        # shellcheck disable=SC2086
        xv="${take_ver:-$(pmake "$port" $targs -V DISTVERSION 2>/dev/null)}"
        for xp in "$files/deps/$n"-*.patch; do
            [ -f "$xp" ] || continue
            if [ "$xp" != "$files/deps/$n-$xv.patch" ]; then
                echo "== ${xp##*/}: for another version of $n than $xv: bring it up to $xv or drop it"; exit 1
            fi
            echo "== ${xp##*/} (files/deps)"
            (cd "$src" && patch -p0 -s -f < "$xp") || { echo "== ${xp##*/} does not apply"; exit 1; }
        done
        # what the configure stage of the framework fixes in the sources before configure,
        # which make patch does not do: FreeBSD 1x taken for 1.x by old autotools
        # (run-autotools-fixup) and the libtool fixes of USES=libtool (patch-libtool);
        # without them the old libtool of libmcrypt builds no shared library
        for fx in run-autotools-fixup patch-libtool; do
            # shellcheck disable=SC2086
            pmake "$port" $targs "$fx" 2> /dev/null || true
        done
        echo "== source: $src"
        if has_kind "$n" shared; then
            # the whole work directory: relative paths out of WRKSRC (gettext-runtime/../build-aux, icu/source/..)
            cp -Rp "$wd" "$wd.so" || { echo "== cannot copy $wd to $wd.so"; exit 1; }
            echo "== source of the shared build: $wd.so${src#"$wd"}"
        fi
        lic "$n" "$src"
    ) > "$log" 2>&1
    prc=$?
    st_s=-; st_d=-
    if has_kind "$n" static; then
        st_s=FAIL
        if [ "$prc" = 0 ] && (
            echo "== static build into $P"
            : > "$work/stamp-$n"
            "b_$n" "$src" || exit 1
            # every library leaves a static archive of its own in lib/ (mozjpeg did not)
            if [ -z "$(find "$P/lib" -maxdepth 1 -name '*.a' -newer "$work/stamp-$n" | head -n 1)" ]; then
                echo "== no new static library of $n in $P/lib"; exit 1
            fi
        ) >> "$log" 2>&1; then st_s=OK; fi
    fi
    if has_kind "$n" shared; then
        st_d=FAIL
        if [ "$prc" = 0 ] && (
            echo "== shared build into $S"
            so_env
            case " $gcc_so " in *" $n "*) gcc_env "$n" || exit 1 ;; esac
            : > "$work/stamp-so-$n"
            "s_$n" "$wd.so${src#"$wd"}" || exit 1
            if [ -z "$(find "$S/lib" -maxdepth 1 -name '*.so*' -newer "$work/stamp-so-$n" | head -n 1)" ]; then
                echo "== no new shared library of $n in $S/lib"; exit 1
            fi
        ) >> "$log" 2>&1; then st_d=OK; fi
    fi
    rc=0
    [ "$prc" = 0 ] && [ "$st_s" != FAIL ] && [ "$st_d" != FAIL ] || rc=1
    ver="$(pmake "$port" -V PKGVERSION 2>/dev/null)"
    pkgname="$(pmake "$port" -V PKGNAME 2>/dev/null)"
    if [ -n "$take_ver" ]; then
        # the name pkg audit knows, with the version taken and the epoch of the port
        epoch="$(pmake "$port" -V PORTEPOCH 2>/dev/null)"
        case "$epoch" in ""|0) epoch="" ;; *) epoch=",$epoch" ;; esac
        pkgname="${pkgname%-*}-$take_ver$epoch"
        ver="$take_ver (port: $ver)"
    fi
    summ "$n" "$ver" "$port"
    return "$rc"
}

# summ <name> <version> <port>: the line of the summary (st_s, st_d, rc, start), the
# line of built.txt (pkgname) when it built, the end of the log when not
summ() {
    if [ "$rc" = 0 ]; then
        printf '%-14s static %-4s shared %-4s %-22s %-24s %4ss\n' "$1" "$st_s" "$st_d" "$2" "$3" "$(( $(date +%s) - start ))" >> "$res/summary.txt"
        printf '%s %s %s\n' "$1" "$pkgname" "$3" >> "$res/built.txt"
    else
        printf '%-14s static %-4s shared %-4s %-22s %-24s %4ss (az-results/%s.log)\n' "$1" "$st_s" "$st_d" "$2" "$3" "$(( $(date +%s) - start ))" "$1" >> "$res/summary.txt"
        tail -n 25 "$log" > "$res/$1.tail"
    fi
    say "$1: static $st_s, shared $st_d"
}

# One library of the bundled curl (port "bundle" in deps.conf): the sources of
# tools/az-curl-sources.sh (once per run), built by files/curl/build-libcurl.sh as
# for --with-curl=bundled; curl takes its libraries into libcurl.a with their
# symbols local (swoole carries a copy of nghttp2, libzip links zstd). The shared
# build (s_<name>) runs out of the source tree, which stays as it is.
bundle_ver() {
    if [ "$1" = curl ]; then
        sed -n 's/^#define LIBCURL_VERSION "\(.*\)"$/\1/p' "$work/curl-src/libcurl/include/curl/curlver.h"
    else
        awk -v n="$1" '$1 == n { print $2 }' "$work/curl-src/deps/VERSIONS"
    fi
}
build_bundle() {
    n="$1"
    if [ "$n" = curl ]; then bs="$work/curl-src/libcurl"; else bs="$work/curl-src/deps/$n"; fi
    (
        echo "== $n: the bundled curl (files/curl.conf, files/curl-deps.conf)"
        if [ ! -f "$work/curl-src/deps/VERSIONS" ]; then
            # the release files: distfiles of the port az/az (AZ_TAKE_DISTFILES)
            CURL_DISTFILES="${CURL_DISTFILES:-$takedist}" AZ_FILESDIR="$files" \
                sh "$tools/az-curl-sources.sh" "$work/curl-src" || { echo "tools/az-curl-sources.sh failed"; exit 1; }
        fi
        lic "$n" "$bs"
    ) > "$log" 2>&1
    prc=$?
    st_s=-; st_d=-
    if has_kind "$n" static; then
        st_s=FAIL
        if [ "$prc" = 0 ] && (
            echo "== static build into $P"
            : > "$work/stamp-$n"
            b="$files/curl/build-libcurl.sh"
            case "$n" in
                curl) LIBICONV_PREFIX="$P" OBJDIR="$work/obj-curl" sh "$b" --curl "$bs" "$P" "$P" ;;
                libidn2) LIBICONV_PREFIX="$P" OBJDIR="$work/obj-curl" sh "$b" --lib libidn2 "$bs" "$P" ;;
                *) OBJDIR="$work/obj-curl" sh "$b" --lib "$n" "$bs" "$P" ;;
            esac || exit 1
            if [ -z "$(find "$P/lib" -maxdepth 1 -name '*.a' -newer "$work/stamp-$n" | head -n 1)" ]; then
                echo "== no new static library of $n in $P/lib"; exit 1
            fi
        ) >> "$log" 2>&1; then st_s=OK; fi
    fi
    if has_kind "$n" shared; then
        st_d=FAIL
        if [ "$prc" = 0 ] && (
            echo "== shared build into $S"
            so_env
            : > "$work/stamp-so-$n"
            "s_$(printf '%s' "$n" | tr - _)" "$bs" || exit 1
            if [ -z "$(find "$S/lib" -maxdepth 1 -name '*.so*' -newer "$work/stamp-so-$n" | head -n 1)" ]; then
                echo "== no new shared library of $n in $S/lib"; exit 1
            fi
        ) >> "$log" 2>&1; then st_d=OK; fi
    fi
    rc=0
    [ "$prc" = 0 ] && [ "$st_s" != FAIL ] && [ "$st_d" != FAIL ] || rc=1
    ver="$(bundle_ver "$n")"
    # the names of the ports for pkg audit: libnghttp2, and the epoch of archivers/brotli
    # (PORTEPOCH 1: VuXML has "brotli < 1.2.1,1", and 1.2.1 without it would be older)
    # and that of security/libssh2 (PORTEPOCH 3)
    case "$n" in nghttp2) pkgname="libnghttp2-$ver" ;; brotli) pkgname="brotli-$ver,1" ;; libssh2) pkgname="libssh2-$ver,3" ;; *) pkgname="$n-$ver" ;; esac
    summ "$n" "$ver" bundle
    return "$rc"
}

# pc_add <file.pc> <Libs|Libs.private> <-lname>...: add to that line of a .pc file the
# libraries it does not name yet (the line is added when there is none). Idempotent;
# nothing when the file is not there.
pc_add() {
    pc="$1"; field="$2"; shift 2
    [ -f "$pc" ] || return 0
    awk -v field="$field:" -v libs="$*" '
        function add(line,   n, i, t, have) {
            n = split(line, t, " "); for (i = 2; i <= n; i++) have[t[i]] = 1
            n = split(libs, t, " "); for (i = 1; i <= n; i++) if (!(t[i] in have)) line = line " " t[i]
            return line
        }
        $1 == field { $0 = add($0); found = 1 }
        { print }
        END { if (!found) print add(field) }
    ' "$pc" > "$pc.new" && mv "$pc.new" "$pc"
}

# After the builds: only static libraries, the .pc files in lib/pkgconfig, the
# *-config scripts and headers; every archive position independent.
finish() {
    rm -f "$P"/lib/*.so "$P"/lib/*.so.* "$P"/lib/*.la
    if [ -d "$P/libdata/pkgconfig" ]; then
        mkdir -p "$P/lib/pkgconfig" && mv "$P"/libdata/pkgconfig/*.pc "$P/lib/pkgconfig/" 2>/dev/null
        rm -rf "$P/libdata"
    fi
    if [ -d "$P/bin" ]; then
        find "$P/bin" -type f ! -name '*-config' ! -name '*-config.orig' -delete
    fi
    rm -rf "$P/share/man" "$P/share/doc" "$P/share/info" "$P/share/gtk-doc" "$P/share/locale" "$P/share/emacs"
    # Static link lines that the .pc files, written for shared libraries, leave short
    # (tools/check-deps-links.py below finds them): libmemcached needs libhashkit
    # (libmemcached.so links it itself: every PHP build failed on hashkit_* symbols), the
    # C++ runtime, backtrace() of libexecinfo and the threads; libevent_extra needs
    # libevent_core.
    pc_add "$P/lib/pkgconfig/libmemcached.pc" Libs -lhashkit
    pc_add "$P/lib/pkgconfig/libmemcached.pc" Libs.private -lc++ -lm -lexecinfo -lpthread
    pc_add "$P/lib/pkgconfig/libevent_extra.pc" Libs.private -levent_core
    # curl-config: --libs gives the static link line, as in files/curl/build-libcurl.sh.
    if [ -f "$P/bin/curl-config" ] && [ ! -f "$P/bin/curl-config.orig" ]; then
        libs="$(pkgconf --static --libs libcurl)"
        mv "$P/bin/curl-config" "$P/bin/curl-config.orig"
        printf '%s\n' '#!/bin/sh' "# curl-config of $P: --libs gives the static link line." \
            'case "$1" in' "    --libs|--static-libs) echo \"$libs\" ;;" "    *) exec \"$P/bin/curl-config.orig\" \"\$@\" ;;" \
            'esac' > "$P/bin/curl-config"
        chmod +x "$P/bin/curl-config"
    fi
    # pkg-config for PHP builds against the tree (config-check.sh writes PKG_CONFIG
    # with it): the tree first (with ImageMagick 7 for imagick), then the base system
    # and the packages (for what the tree has not, such as GraphicsMagick), and
    # static link lines.
    mkdir -p "$P/bin"
    printf '%s\n' '#!/bin/sh' "# pkg-config of $P: the bundle first, static link lines." \
        "PKG_CONFIG_LIBDIR='$P/lib/pkgconfig:/usr/libdata/pkgconfig:/usr/local/libdata/pkgconfig:/usr/local/share/pkgconfig'" \
        'export PKG_CONFIG_LIBDIR' 'unset PKG_CONFIG_PATH' 'exec /usr/local/bin/pkgconf --static "$@"' > "$P/bin/pkg-config"
    chmod +x "$P/bin/pkg-config"
    # Position independent: the whole archive links into a shared object. Relocation
    # errors mean it is not (and it could not go into libphp.so); other errors are
    # only noted.
    : > "$res/pic.txt"; : > "$res/pic-notes.txt"
    for a in "$P"/lib/*.a; do
        if ! cc -shared -o "$work/pic-test.so" -Wl,--whole-archive "$a" -Wl,--no-whole-archive \
                -Wl,--unresolved-symbols=ignore-all > "$work/pic-test.log" 2>&1; then
            if grep -q -i 'relocation' "$work/pic-test.log"; then
                echo "${a##*/}: not position independent: $(grep -m 1 -i relocation "$work/pic-test.log")" >> "$res/pic.txt"
            else
                echo "${a##*/}: link test failed: $(grep -m 1 -i error "$work/pic-test.log")" >> "$res/pic-notes.txt"
            fi
        fi
    done
    # Nothing may point to /usr/local outside the tree (the libraries of pkg); the
    # configuration and fonts of the system that fontconfig reads are meant.
    grep -rn '/usr/local/' "$P/lib/pkgconfig" "$P/bin" 2>/dev/null | grep -v "^$P/bin/pkg-config:" | sed "s#$P##g" |
        sed -e 's#/usr/local/etc/fonts##g' -e 's#/usr/local/share/fonts##g' -e 's#/usr/local/lib/X11/fonts##g' \
            -e 's#sysconfdir=/usr/local/etc$##' |
        grep '/usr/local/' > "$res/localbase.txt" || true
    # Every .pc names the archives of the bundle that its archives need (a short one
    # fails the PHP builds at the link only); a finding stops the tarball.
    : > "$res/links.txt"
    if ! python3 -I "$tools/az-check-links.py" "$P" /usr/libdata/pkgconfig > "$res/links.log" 2>&1; then
        cp "$res/links.log" "$res/links.txt"
    fi
}

# After the builds, the shared tree: only shared libraries in lib/ (with their .pc
# in lib/pkgconfig, the cmake files), the *-config scripts and bin/pkg-config, the
# headers; no programs, sbin, manual pages, documentation or translations. Then the
# checks (az-results/shared.txt: every library with SONAME, size, DT_NEEDED and run
# path; a finding goes to shared-bad.txt and fails the build): every library has a
# SONAME and RELRO, every DT_NEEDED resolves (ldd) from S/lib or the base system
# (/lib, /usr/lib), never from /usr/local/lib or the static tree, with the run path
# S/lib where it needs a library of S; libcurl and libzip take libssl and libcrypto
# of the base system; the .pc files and *-config scripts name neither /usr/local
# outside S nor the static tree.
finish_so() {
    rm -f "$S"/lib/*.a "$S"/lib/*.la
    if [ -d "$S/libdata/pkgconfig" ]; then
        mkdir -p "$S/lib/pkgconfig" && mv "$S"/libdata/pkgconfig/*.pc "$S/lib/pkgconfig/" 2>/dev/null
        rm -rf "$S/libdata"
    fi
    mkdir -p "$S/bin"
    find "$S/bin" -maxdepth 1 ! -type d ! -name '*-config' -delete
    rm -rf "$S/sbin" "$S/share/man" "$S/share/doc" "$S/share/info" "$S/share/gtk-doc" "$S/share/locale" "$S/share/emacs"
    # pkg-config for the builds against the shared tree (the PHP modules of pkg mode):
    # its libraries and the base system, no static link lines
    printf '%s\n' '#!/bin/sh' "# pkg-config of $S: its shared libraries and the base system." \
        "PKG_CONFIG_LIBDIR='$S/lib/pkgconfig:/usr/libdata/pkgconfig'" \
        'export PKG_CONFIG_LIBDIR' 'unset PKG_CONFIG_PATH' 'exec /usr/local/bin/pkgconf "$@"' > "$S/bin/pkg-config"
    chmod +x "$S/bin/pkg-config"
    : > "$res/shared.txt"; : > "$res/shared-bad.txt"
    for f in "$S"/lib/*.so*; do
        [ -f "$f" ] && [ ! -L "$f" ] || continue
        b="${f##*/}"
        readelf -d "$f" > "$work/so-dyn.txt" 2>&1
        # the value texts, which the readelf of binutils and that of the ELF Tool Chain both print
        sn="$(sed -n 's/.*[Ll]ibrary soname: \[\(.*\)\].*/\1/p' "$work/so-dyn.txt")"
        need="$(sed -n 's/.*[Ss]hared library: \[\(.*\)\].*/\1/p' "$work/so-dyn.txt" | tr '\n' ' ' | sed 's/ *$//')"
        rp="$(sed -n 's/.*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1/p' "$work/so-dyn.txt" | tr '\n' ':' | sed 's/:*$//')"
        # the compiler, by .comment (GCC first: the crt files of the base system in
        # every library carry clang's); a library of GCC leaves no NEEDED libgcc_s
        readelf -p .comment "$f" > "$work/so-cmt.txt" 2>/dev/null
        cmt="$(grep -o 'GCC: ([^)]*) [0-9.]*' "$work/so-cmt.txt" | head -n 1)"
        [ -n "$cmt" ] || cmt="$(grep -o 'clang version [0-9.]*' "$work/so-cmt.txt" | head -n 1)"
        printf '%s: SONAME %s, %s KB, NEEDED %s%s%s\n' "$b" "${sn:-none}" "$(du -Ak "$f" | cut -f1)" "${need:-none}" \
            "${rp:+, run path $rp}" "${cmt:+, $cmt}" >> "$res/shared.txt"
        # (a C++ library of the base clang needs the libgcc_s of the base system, its
        # unwinder: ICU, libheif, libde265, libmemcached; one of GCC would need that of GCC)
        case "$cmt" in GCC:*)
            case " $need " in *" libgcc_s.so"*) echo "$b: of GCC, NEEDED libgcc_s (built without -static-libgcc)" >> "$res/shared-bad.txt" ;; esac ;;
        esac
        [ -n "$sn" ] || echo "$b: no SONAME" >> "$res/shared-bad.txt"
        # every part of the run path is S/lib (libtool adds its own -rpath to ours: twice is fine)
        for part in $(printf '%s\n' "$rp" | tr ':' ' '); do
            [ "$part" = "$S/lib" ] || echo "$b: run path $part (only $S/lib belongs there: $rp)" >> "$res/shared-bad.txt"
        done
        readelf -l "$f" | grep -q GNU_RELRO || echo "$b: no RELRO" >> "$res/shared-bad.txt"
        ldd "$f" > "$work/so-ldd.txt" 2>&1 || echo "$b: ldd failed: $(head -n 1 "$work/so-ldd.txt")" >> "$res/shared-bad.txt"
        awk '$2 == "=>" { print $1, $3 }' "$work/so-ldd.txt" | while read -r l lp; do
            case "$lp" in
                "$P"/*) echo "$b: $l of the static tree ($lp)" ;;
                "$S"/lib/*) [ -n "$rp" ] || echo "$b: $l of $S/lib without the run path $S/lib" ;;
                # libgd takes libimagequant of graphics/libimagequant (LIQ, aZ 11.11.2026)
                /usr/local/lib/libimagequant.so.*) case "$b" in libgd.so*) ;; *) echo "$b: $l of /usr/local ($lp)" ;; esac ;;
                /usr/local/*) echo "$b: $l of /usr/local ($lp)" ;;
                /lib/*|/usr/lib/*) ;;
                *) echo "$b: $l not found in $S/lib or the base system (${lp:-?})" ;;
            esac
        done >> "$res/shared-bad.txt"
        case "$b" in
            libcurl.so.*|libzip.so.*)
                # libzip needs only libcrypto (its AES), curl both
                case "$b" in libzip.so.*) ssl="libcrypto" ;; *) ssl="libssl libcrypto" ;; esac
                for l in $ssl; do
                    lp="$(awk -v l="$l" 'index($1, l ".so") == 1 && $2 == "=>" { print $3 }' "$work/so-ldd.txt")"
                    case "$lp" in /lib/*|/usr/lib/*) ;; *) echo "$b: $l not of the base system (${lp:-not linked})" >> "$res/shared-bad.txt" ;; esac
                done ;;
        esac
    done
    [ -s "$res/shared.txt" ] || echo "no shared library in $S/lib" >> "$res/shared-bad.txt"
    # the libraries of AZ_GCC_SO are those of GCC
    for n in $gcc_so; do
        f="$(ls "$S/lib/lib$n.so."* 2>/dev/null | head -n 1)"
        [ -n "$f" ] || continue
        readelf -p .comment "$f" 2>/dev/null | grep -q 'GCC:' ||
            echo "${f##*/}: of AZ_GCC_SO, but its .comment names no GCC" >> "$res/shared-bad.txt"
    done
    # the .pc files and *-config scripts (not the pkg-config wrapper): nothing of the
    # static tree, nothing of /usr/local outside S but the configuration and fonts of
    # the system that fontconfig reads
    for f in "$S"/lib/pkgconfig/*.pc "$S"/bin/*-config; do
        [ -f "$f" ] && [ "$f" != "$S/bin/pkg-config" ] || continue
        grep -n "$P" "$f" | sed "s#^#${f##*/}: the static tree: #" >> "$res/shared-bad.txt"
        sed -e "s#$S##g" -e 's#/usr/local/etc/fonts##g' -e 's#/usr/local/share/fonts##g' \
            -e 's#/usr/local/lib/X11/fonts##g' -e 's#sysconfdir=/usr/local/etc$##' -e '/Print PREFIX to icu install/d' "$f" |
            grep -n '/usr/local' | sed "s#^#${f##*/}: /usr/local outside $S: #" >> "$res/shared-bad.txt"
    done
}

manifest() {
    {
        echo "az libraries for FreeBSD $major (amd64, $cputype), built $(date '+%Y-%m-%d %H:%M %Z') on $(uname -sr)"
        echo "freebsd-ports $ports_commit; static libraries in $P, shared libraries in $S; CFLAGS: $CFLAGS"
        echo
        while read -r n pkgname port; do
            printf '%-14s %-28s %-24s %s\n' "$n" "$pkgname" "$port" "$(awk -v n="$n" '$1 == "lib" && $2 == n { print $4 }' "$conf")"
            if [ "$port" = bundle ]; then
                if [ "$n" = curl ]; then
                    awk '!/^#/ && NF >= 4 { u = $3; s = $4 } END { n = split(u, p, "/"); print "    " p[n] " sha256 " s }' "$files/curl.conf"
                else
                    awk -v n="$n" '$1 == n { print "    " $4 " sha256 " $3 }' "$work/curl-src/deps/VERSIONS"
                fi
                continue
            fi
            t="$(take_of "$n")"
            if [ -n "$t" ]; then
                # shellcheck disable=SC2086
                set -- $t
                echo "    ${2##*/} sha256 $3 (upstream release $1, ahead of the port: take line of deps.conf)"
                if [ -d "$files/deps/$n-$1" ]; then
                    np="$(ls "$files/deps/$n-$1" | grep -c '^patch-')"
                    [ "$np" -gt 0 ] && echo "    $np patches of the port, brought up to $1 (files/deps/$n-$1)"
                else
                    np="$(ls "$ports/$port/files" 2>/dev/null | grep -c '^patch-')"
                    [ "$np" -gt 0 ] && echo "    $np patches of the port"
                fi
                continue
            fi
            sed -n 's/^SHA256 (\(.*\)) = \(.*\)/    \1 sha256 \2/p' "$ports/$port/distinfo"
            np="$(ls "$ports/$port/files" 2>/dev/null | grep -c '^patch-')"
            [ "$np" -gt 0 ] && echo "    $np patches of the port"
        done < "$res/built.txt"
        echo
        echo "curl above: the static libcurl.a in $P for the builds of PHP, with only what PHP needs. The package"
        echo "curl (the port ftp/curl of azsupport/ports): bin/curl and lib/libcurl.so.4 of /usr/local, a build of its own of the same"
        echo "release with the options of the port ftp/curl, against the static libraries above."
        echo
        echo "The shared tree $S (lib/, include/, lib/pkgconfig/, bin/pkg-config and the *-config"
        echo "scripts), for the PHP modules of pkg mode: the libraries of the kind shared above, built"
        echo "from the same patched sources with the same options, with the run path $S/lib and the"
        echo "OpenSSL of the base system (libcurl, libzip); built with the base clang, but ${gcc_so:-none} with"
        echo "GCC of the packages (tools/lib-bench.sh: at least 2% faster with it); SONAME, DT_NEEDED,"
        echo "run path and compiler of each:"
        sed 's/^/    /' "$res/shared.txt" 2>/dev/null
    } > "$res/VERSIONS"
    mkdir -p "$A/share/doc/az"
    cp "$res/VERSIONS" "$A/share/doc/az/VERSIONS"
}

mkdir -p "$res" "$work"
cpu_model="$(sysctl -n hw.model 2>/dev/null)"

# report: the summary and what went wrong, to the screen (the log of the port)
report() {
    echo "== $res/summary.txt"
    cat "$res/summary.txt"
    for f in "$res"/*.tail "$res/shared-bad.txt" "$res/pic.txt" "$res/links.txt" "$res/bins-bad.txt"; do
        [ -s "$f" ] || continue
        echo "== $f"
        cat "$f"
    done
}

# --fetch: the distfiles of the ports of deps.conf, by their own make fetch into
# AZ_DISTDIR (checked against their distinfo when make patch extracts them), so
# that the build needs no network: the post-fetch of the port az/az. Not those of
# a port with a take line, nor the bundled curl: their release files are
# distfiles of the port az/az itself.
if [ "${1:-}" = "--fetch" ]; then
    ports_check || exit 1
    rc=0
    for n in $libs_all; do
        port="$(port_of "$n")"
        [ "$port" != bundle ] || continue
        if [ -n "$(take_of "$n")" ]; then
            echo "az-build: $n: not fetched from $port: the release of its take line is a distfile of az/az"
            continue
        fi
        say "fetch $n ($port)"
        pmake "$port" fetch || { echo "az-build: $n: make fetch of $port failed" >&2; rc=1; }
    done
    exit "$rc"
fi

if [ $# -eq 0 ]; then
    set -- $libs_all
    # a full build starts from an empty tree; never one with files of a package
    # (az, and ImageMagick7 and the PHP packages put files into it) or the PHP
    # builds of a server (phpXY directories, bin/phpXY); a tree left by an
    # unfinished build of this script (its mark .az-build) is removed
    if [ -n "$(ls -A "$A" 2>/dev/null | head -n 1)" ]; then
        owners="$(pkg query -a '%n %Fp' 2>/dev/null | awk -v a="$A/" 'index($2, a) == 1 { print $1 }' | sort -u | tr '\n' ' ')"
        if [ -n "$owners" ]; then
            echo "az-build: $A has files of the packages $owners: build on a machine or in a jail without them" >&2
            exit 2
        fi
        if [ -n "$(ls -d "$A"/php* "$A"/bin/php* "$A"/etc/php* "$P"/php* "$P"/bin/php* "$P"/etc/php* 2>/dev/null | head -n 1)" ]; then
            echo "az-build: $A has PHP builds in it; build into an empty directory (AZ_PREFIX=...)" >&2
            exit 2
        fi
        if [ ! -f "$A/.az-build" ]; then
            echo "az-build: $A has files of no package and no mark of an unfinished build of this script ($A/.az-build): not removed; remove it yourself if they are not needed" >&2
            exit 2
        fi
        echo "az-build: $A was left by an unfinished build of this script ($(cat "$A/.az-build")): removed"
        rm -rf "$A"
    fi
    mkdir -p "$A" && date '+%Y-%m-%d %H:%M:%S %Z' > "$A/.az-build" || { echo "az-build: cannot write $A" >&2; exit 2; }
    rm -f "$res"/*.tail "$res/bins-bad.txt"
    : > "$res/summary.txt"; : > "$res/built.txt"
    printf 'flags:    %s\ncpu:      %s\n' "$CFLAGS" "${cpu_model:-?}" >> "$res/summary.txt"
fi
# This CPU has to run code of the level (configure tests, the data tools of ICU):
# where it cannot, configure decides wrong without a word and ICU stops.
cpu_feats() {
    cc "-march=$1" -dM -E - < /dev/null 2>/dev/null |
        sed -n -E 's/^#define __(SSE4_2|POPCNT|AVX|AVX2|BMI|BMI2|FMA|F16C|LZCNT|MOVBE|AVX512F|AVX512BW|AVX512CD|AVX512DQ|AVX512VL)__ 1$/\1/p' |
        LC_ALL=C sort -u
}
cpu_feats "$cputype" > "$work/cpu-need"
cpu_feats native > "$work/cpu-have"
lacks="$(LC_ALL=C comm -23 "$work/cpu-need" "$work/cpu-have" | tr '\n' ' ' | sed 's/ *$//')"
if [ ! -s "$work/cpu-need" ] || [ -n "$lacks" ]; then
    why="${lacks:+lacks $lacks of}"
    printf '%-14s FAIL  this CPU (%s) %s -march=%s: code built for it cannot run here\n' \
        cpu "${cpu_model:-?}" "${why:-cannot tell the features of}" "$cputype" >> "$res/summary.txt"
    echo "az-build: this CPU ${why:-cannot tell the features of} -march=$cputype; build on a CPU that has them, or set AZ_CPUTYPE to a lower level" >&2
    exit 1
fi
for n in "$@"; do
    [ -n "$(port_of "$n")" ] || { echo "az-build: $n is not in $conf" >&2; exit 2; }
done
ports_check || { echo "ports tree     FAIL  $ports is not freebsd-ports $ports_commit of deps.conf" >> "$res/summary.txt"; report; exit 1; }
mkdir -p "$P" "$S"
# build_one and build_bundle set rc for the line of their library: the libraries
# that failed are kept apart, so that one built after them does not hide them
failed=""
for n in "$@"; do
    say "$n ($(port_of "$n"))"
    build_one "$n" || failed="$failed $n"
done
rc=0
if [ -n "$failed" ]; then
    rc=1
    say "failed:$failed"
fi
finish
finish_so
if [ -s "$res/shared-bad.txt" ]; then
    printf '%-14s FAIL  %s\n' "shared tree" "$(wc -l < "$res/shared-bad.txt" | tr -d ' ') findings (shared-bad.txt): $(head -n 3 "$res/shared-bad.txt" | tr '\n' ' ')" >> "$res/summary.txt"
    rc=1
fi
manifest
# Known vulnerabilities of these versions (FreeBSD VuXML), for the report (none
# without network: the build of a port has none in poudriere).
pkg audit -F -q $(awk '{ print $2 }' "$res/built.txt") > "$res/audit.txt" 2>&1 || true
if [ "$rc" = 0 ] && [ ! -s "$res/pic.txt" ] && [ ! -s "$res/links.txt" ] && [ ! -s "$res/bins-bad.txt" ]; then
    echo "installed: $A (static tree $P: $(du -Ask "$P" | cut -f1) KB, all: $(du -Ask "$A" | cut -f1) KB)" >> "$res/summary.txt"
    # the work directories of the ports, for the space of what is built after
    rm -rf "$work/wrk"
else
    rc=1
fi
report
exit "$rc"
