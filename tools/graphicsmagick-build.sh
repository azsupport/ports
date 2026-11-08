#!/bin/sh
# graphicsmagick-build.sh - build GraphicsMagick for the video sites and the PHP
# module gmagick (the package GraphicsMagick of the port graphics/GraphicsMagick,
# in the place of the official one): bin/gm, static, with only the formats of
# graphics/GraphicsMagick/files/graphicsmagick.conf (see the head of that file
# for which, why, and how the coders not registered take the place of a policy),
# against the static libraries of the static tree of the package az,
# /usr/local/az/static (installed: the port az/az first). Written after
# tools/imagemagick-build.sh (08.11.2026), which builds ImageMagick 7 the same way.
#
# Usage (FreeBSD; the port graphics/GraphicsMagick runs it in its post-fetch and
# do-build):
#   sh tools/graphicsmagick-build.sh --tools    install the build tools (pkg)
#   sh tools/graphicsmagick-build.sh --fetch    fetch the distfiles of the official
#                                               port into AZ_DISTDIR (its make fetch)
#   sh tools/graphicsmagick-build.sh            build GraphicsMagick
#
# As tools/imagemagick-build.sh: the ports framework fetches the distfiles of the
# official port at the ports commit of az/az/files/deps.conf (the official tree
# PORTSDIR, at that commit), checks them against its distinfo, extracts them and
# applies the port's patches (make patch, with the libtool and autotools fixes of
# its configure stage); then this script narrows the coders (the module lines of
# the conf: the table of magick/static.c; the lowest coder class "primary",
# magick/magick.c) and applies files/graphicsmagick-*.patch, if any. A copy of
# that source is taken for the shared libraries. The static build: configure with
# the prefix /usr/local and the configure lines of the conf, --disable-shared
# --enable-static, against AZ_PREFIX/static (AZ_PREFIX: default /usr/local/az),
# installed into a stage directory first; into the stage of the package
# (AZ_STAGEDIR, default AZ_WORK/stage/GraphicsMagick), as files of /usr/local:
# bin/gm (PIE, RELRO, BIND_NOW, stripped), lib/GraphicsMagick/ (its configuration:
# type*.mgk, and the delegates.mgk of files/: no delegate), share/GraphicsMagick/
# (colors.mgk, log.mgk, modules.mgk), share/licenses/GraphicsMagick/,
# share/doc/GraphicsMagick/VERSIONS; and the static libraries, headers and .pc
# files in the static tree AZ_PREFIX/static (lib/libGraphicsMagick.a,
# lib/libGraphicsMagickWand.a, include/GraphicsMagick, lib/pkgconfig), with
# bin/GraphicsMagick-config and bin/GraphicsMagickWand-config printing the static
# link line, for a static gmagick of PHP (--with-gmagick=AZ_PREFIX/static). Then
# the shared libraries, for gmagick of the PHP packages (--with-gmagick=AZ_PREFIX):
# the copy of the source with the same options, --enable-shared --disable-static,
# against the shared libraries of AZ_PREFIX (run path AZ_PREFIX/lib) and the base
# system, nothing of the static tree; the prefix stays /usr/local (the library
# reads share/GraphicsMagick of the package), the libdir is AZ_PREFIX/lib (so it
# reads AZ_PREFIX/lib/GraphicsMagick/config, which gets the same files). Kept in
# AZ_PREFIX: lib/libGraphicsMagick.so*, lib/libGraphicsMagickWand.so*,
# lib/GraphicsMagick/, lib/pkgconfig/GraphicsMagick.pc and GraphicsMagickWand.pc,
# include/GraphicsMagick, bin/GraphicsMagick-config and bin/GraphicsMagickWand-config
# (--prefix AZ_PREFIX, the link line with the run path). No Magick++, no manual
# pages. The work directory is AZ_WORK/graphicsmagick (default
# /var/tmp/az-work/graphicsmagick). Results go to AZ_RESULTS (default
# graphicsmagick-results/ of the current directory: summary.txt, the log,
# VERSIONS, formats.txt, bins.txt, shared.txt); the summary is printed at the end.
# tools/graphicsmagick-test.sh tests it, once installed.
#
# Compiler flags as for the libraries and ImageMagick: CPUTYPE and CFLAGS of
# /etc/make.conf with -fstack-protector-strong, -fno-strict-aliasing and -fPIC;
# AZ_CPUTYPE and AZ_CFLAGS win over make.conf (MAKE_CONF, default
# /etc/make.conf); without either: x86-64-v3 and -O3 -pipe.
#
# Exit status: 0 built and checked, 1 the build or a check failed, the libraries
# are not there, or this CPU cannot run the level, 2 usage.

set -u
tools="$(cd "$(dirname "$0")" && pwd)"
conf="${AZ_GM_CONF:-$tools/../graphics/GraphicsMagick/files/graphicsmagick.conf}"
files="$(dirname "$conf")"
deps_conf="${AZ_DEPS_CONF:-$tools/../az/az/files/deps.conf}"
A="${AZ_PREFIX:-/usr/local/az}"
# the static tree (gm and the static libraries); the shared libraries are those of $A
S="$A/static"
I=/usr/local
work="${AZ_WORK:-/var/tmp/az-work}/graphicsmagick"
root="${AZ_STAGEDIR:-${AZ_WORK:-/var/tmp/az-work}/stage/GraphicsMagick}"
res="${AZ_RESULTS:-$(pwd)/graphicsmagick-results}"
ports="${PORTSDIR:-/usr/ports}"
distdir="${AZ_DISTDIR:-$work/distfiles}"
takedist="${AZ_TAKE_DISTFILES:-$(pwd)/distfiles}"
ncpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 2)"
major="$(uname -r | cut -d. -f1)"

if [ "${1:-}" = "--tools" ]; then
    pkgs="git gmake pkgconf"
    # shellcheck disable=SC2086
    env ASSUME_ALWAYS_YES=yes pkg install -y $pkgs
    rc=$?
    for t in $pkgs; do pkg info -e "$t" || echo "graphicsmagick-build: package $t is not installed"; done
    exit $rc
fi
[ -f "$conf" ] || { echo "graphicsmagick-build: no $conf (AZ_GM_CONF: graphicsmagick.conf of graphics/GraphicsMagick/files)" >&2; exit 2; }
[ -f "$deps_conf" ] || { echo "graphicsmagick-build: no $deps_conf (AZ_DEPS_CONF: deps.conf of the port az/az)" >&2; exit 2; }

say() { printf '[graphicsmagick-build %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

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

cputype="${AZ_CPUTYPE:-$(mc_get CPUTYPE)}"
cputype="${cputype:-x86-64-v3}"
opt="${AZ_CFLAGS:-$(mc_get CFLAGS)}"
# shellcheck disable=SC2086
opt="$(printf '%s\n' ${opt:--O3 -pipe} | grep -v -e '^-march=' -e '^-fPIC$' | tr '\n' ' ' | sed 's/ *$//')"
export CC=cc CXX=c++
export CFLAGS="$opt -march=$cputype -fstack-protector-strong -fno-strict-aliasing -fPIC"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="-I$S/include"
export LDFLAGS="-L$S/lib"
# pkg-config with --static (only static libraries): the libraries of the static tree,
# then the base system
mkdir -p "$work/bin"
printf '%s\n' '#!/bin/sh' 'exec pkgconf --static "$@"' > "$work/bin/pkg-config"
chmod +x "$work/bin/pkg-config"
export PKG_CONFIG="$work/bin/pkg-config"
export PKG_CONFIG_LIBDIR="$S/lib/pkgconfig:/usr/libdata/pkgconfig"
unset PKG_CONFIG_PATH
export PATH="$work/bin:$PATH"
# the libraries GraphicsMagick builds with, by their .pc names (as in the trees of az)
pcs="libjpeg libpng16 libwebp libheif freetype2 lcms2"

ports_commit="$(awk '$1 == "ports" { print $2 }' "$deps_conf")"
gm_name="$(awk '$1 == "gm" { print $2; exit }' "$conf")"
gm_port="$(awk '$1 == "gm" { print $3; exit }' "$conf")"
take_of() { awk -v n="$1" '$1 == "take" && $2 == n { print $3, $4, $5, $6 }' "$conf"; }
# conf_opts <key>: the words of the lines with that first word (configure, module, format)
conf_opts() { awk -v k="$1" '$1 == k { for (i = 2; i <= NF; i++) print $i }' "$conf"; }

# The official tree PORTSDIR has to be at the commit of deps.conf (as in
# tools/az-build.sh); it is only read here, never changed.
ports_check() {
    [ -f "$ports/Mk/bsd.port.mk" ] || { echo "graphicsmagick-build: no ports tree in $ports (PORTSDIR)" >&2; return 1; }
    h="$(git -C "$ports" rev-parse HEAD 2>/dev/null)"
    if [ -z "$h" ]; then
        echo "graphicsmagick-build: $ports is not a git checkout: taken for freebsd-ports $ports_commit of deps.conf" >&2
        return 0
    fi
    [ "$h" = "$ports_commit" ] && return 0
    echo "graphicsmagick-build: $ports is at $h, deps.conf has $ports_commit: build with the tree at that commit" >&2
    return 1
}
# The official port in its flavor without X11; JPEG_PORT as in make.conf of the
# servers. A make of its own, as from a shell: nothing of the make of the port
# that runs this script (MAKEFLAGS: its command line, its job server) reaches it.
pmake() {
    p="$1"; shift
    env -u MAKEFLAGS -u MFLAGS -u __MKLVL__ make -C "$ports/$p" BATCH=yes NO_DEPENDS=yes \
        DISABLE_VULNERABILITIES=yes JPEG_PORT=graphics/mozjpeg FLAVOR=nox11 \
        PORTSDIR="$ports" WRKDIRPREFIX="$work/wrk" DISTDIR="$distdir" "$@"
}

fix_guess() {
    find "$1" \( -name config.guess -o -name config.sub \) -type f | while IFS= read -r f; do
        cp "$ports/Templates/${f##*/}" "$f" && chmod a+rx "$f"
    done
}

# pc_add <file.pc> <Libs|Libs.private> <-lname>...: add to that line of a .pc file the
# libraries it does not name yet (as in tools/az-build.sh)
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
# pc_clean <file.pc>: Libs.private of GraphicsMagick.pc has the LDFLAGS of the build
# in it: no -pie, -Wl,-z or -Wl,-rpath there (the link line of a program or module
# that links the libraries is its own)
pc_clean() {
    awk '$1 == "Libs.private:" { l = $1; for (i = 2; i <= NF; i++) if ($i != "-pie" && $i !~ /^-Wl,-(z|rpath)/) l = l " " $i; $0 = l } { print }' \
        "$1" > "$1.new" && mv "$1.new" "$1"
}

# config_wrap <name> <pc module> <tree> <static|shared>: <tree>/bin/<name> in the
# stage, printing the link line from the .pc files of that tree: static, the static
# link line; shared, the libraries with their run path <tree>/lib; --prefix the
# tree (gmagick of PHP takes the lib/ and include/GraphicsMagick of it). The
# scripts of GraphicsMagick print the prefix /usr/local and no run path.
config_wrap() {
    if [ "$4" = static ]; then
        what='static libraries, so --libs gives the static link line'
        libs="exec /usr/local/bin/pkgconf --static --libs $2"
    else
        what="shared libraries, so --libs gives them with the run path $3/lib"
        libs="l=\"\$(/usr/local/bin/pkgconf --libs $2)\" || exit 1; echo \"\$l -Wl,-rpath,$3/lib\""
    fi
    cat > "$root$3/bin/$1" <<EOF
#!/bin/sh
# $1 of GraphicsMagick in $3 (tools/graphicsmagick-build.sh of
# https://github.com/azsupport/ports): $what, from the .pc files of $3.
PKG_CONFIG_LIBDIR='$3/lib/pkgconfig:/usr/libdata/pkgconfig'
export PKG_CONFIG_LIBDIR
unset PKG_CONFIG_PATH
case "\${1:-}" in
    --cflags|--cppflags) exec /usr/local/bin/pkgconf --cflags $2 ;;
    --ldflags) exec /usr/local/bin/pkgconf --libs-only-L $2 ;;
    --libs) $libs ;;
    --prefix|--exec-prefix) echo '$3' ;;
    --version) exec /usr/local/bin/pkgconf --modversion $2 ;;
    *) echo "Usage: $1 [--cflags] [--cppflags] [--exec-prefix] [--ldflags] [--libs] [--prefix] [--version]" >&2; exit 1 ;;
esac
EOF
    chmod 755 "$root$3/bin/$1"
}

# narrow <source>: the coders of the conf only (see the head of the conf): the lines
# of the table StaticModules of magick/static.c that are not of a module line go,
# and the lowest coder class is "primary" (magick/magick.c). Both are checked: a
# module of the conf that is not in the table, or the lines not found as they
# were, stop the build (a new release that changed them).
narrow() {
    st="$1/magick/static.c"; mg="$1/magick/magick.c"
    [ -f "$st" ] && [ -f "$mg" ] || { echo "== no magick/static.c or magick/magick.c in $1"; return 1; }
    keep="$(conf_opts module | tr '\n' ' ')"
    [ -n "$keep" ] || { echo "== no module line in $conf"; return 1; }
    awk -v keep=" $keep " '
        /^[ \t]*STATICM\("[A-Z0-9_]+",/ {
            n = $0; sub(/^[ \t]*STATICM\("/, "", n); sub(/".*/, "", n)
            if (index(keep, " " n " ")) { kept = kept " " n; print; next }
            dropped = dropped " " n; next
        }
        { print }
        END { print "kept:" kept > "/dev/stderr"; print "dropped:" dropped > "/dev/stderr" }
    ' "$st" > "$st.az" 2> "$work/narrow.txt" || return 1
    cat "$work/narrow.txt"
    for m in $keep; do
        grep -q "^kept:.* $m\( \|\$\)" "$work/narrow.txt" ||
            { echo "== module $m of the conf is not in the table of magick/static.c"; return 1; }
    done
    grep -q '^dropped: [A-Z]' "$work/narrow.txt" || { echo "== nothing dropped from magick/static.c: not the table this script knows"; return 1; }
    mv "$st.az" "$st" || return 1
    grep -q '^static CoderClass MinimumCoderClass = UnstableCoderClass;' "$mg" ||
        { echo "== no \"static CoderClass MinimumCoderClass = UnstableCoderClass;\" in magick/magick.c"; return 1; }
    sed -i '' 's/^static CoderClass MinimumCoderClass = UnstableCoderClass;/static CoderClass MinimumCoderClass = PrimaryCoderClass;/' "$mg" &&
        grep -q '^static CoderClass MinimumCoderClass = PrimaryCoderClass;' "$mg" || return 1
    echo "== magick/magick.c: the lowest coder class is PrimaryCoderClass"
}

# so_env: the environment of the shared build, nothing of the static tree $S
so_env() {
    PATH="${PATH#"$work/bin:"}"
    PKG_CONFIG=pkgconf
    PKG_CONFIG_LIBDIR="$A/lib/pkgconfig:/usr/libdata/pkgconfig"
    CPPFLAGS="-I$A/include"
    LDFLAGS="-L$A/lib -Wl,-rpath,$A/lib -Wl,-z,relro,-z,now"
    export PATH PKG_CONFIG PKG_CONFIG_LIBDIR CPPFLAGS LDFLAGS
    unset PKG_CONFIG_PATH
}

# b_gm_shared <source>: the shared libraries from the copy of the narrowed source
# (see the head of this file)
b_gm_shared() {
    sst="$work/stage-shared"
    rm -rf "$sst"
    for pc in $pcs; do
        [ -f "$A/lib/pkgconfig/$pc.pc" ] ||
            { echo "== shared: no $A/lib/pkgconfig/$pc.pc of the shared libraries (the package az)"; return 1; }
    done
    echo "== shared libraries: configure, gmake and gmake install-strip in $1"
    (
        cd "$1" || exit 1
        so_env
        # the libraries in every link test of configure (it tries -lfreetype alone)
        # shellcheck disable=SC2086
        ./configure --prefix="$I" --libdir="$A/lib" --includedir="$A/include" \
            LIBS="$(pkgconf --libs-only-l $pcs) -lc++ -lpthread -lm" PTHREAD_LIBS=-lpthread \
            $(conf_opts configure) --enable-shared --disable-static --disable-dependency-tracking \
            ac_cv_lib_ICE_IceConnectionNumber=no &&
            gmake -j"$ncpu" && gmake install-strip DESTDIR="$sst"
    ) || { echo "== shared: configure, gmake or gmake install-strip failed ($(df -h "$work" | awk 'NR == 2 { print $4 " free" }'))"; return 1; }
    cp "$1/config.log" "$res/shared-config.log" 2>/dev/null
    l="$sst$A/lib"
    ls "$l"/libGraphicsMagick.so* "$l"/libGraphicsMagickWand.so* > /dev/null 2>&1 ||
        { echo "== shared: no libGraphicsMagick.so or libGraphicsMagickWand.so in $l: $(ls "$l" 2>/dev/null | tr '\n' ' ')"; return 1; }
    [ -d "$sst$A/include/GraphicsMagick" ] || { echo "== shared: no headers in $sst$A/include/GraphicsMagick"; return 1; }
    pcd=""
    for d in "$sst$I/libdata/pkgconfig" "$l/pkgconfig" "$sst$I/lib/pkgconfig"; do
        if [ -f "$d/GraphicsMagickWand.pc" ]; then pcd="$d"; break; fi
    done
    [ -n "$pcd" ] || { echo "== shared: no GraphicsMagickWand.pc in $sst$I/libdata/pkgconfig, $l/pkgconfig or $sst$I/lib/pkgconfig"; return 1; }
    mkdir -p "$root$A/lib/pkgconfig" "$root$A/include" "$root$A/bin" || return 1
    keep="$(cd "$l" && ls -d libGraphicsMagick.so* libGraphicsMagickWand.so* GraphicsMagick 2>/dev/null)"
    echo "== into $root$A/lib:" $keep
    # shellcheck disable=SC2086
    (cd "$l" && tar -cf - $keep) | (cd "$root$A/lib" && tar -xpf -) || return 1
    # the configuration the shared library reads (its libdir): that of the program
    if [ -d "$root$A/lib/GraphicsMagick/config" ]; then
        cp "$files/delegates.mgk" "$root$A/lib/GraphicsMagick/config/delegates.mgk" || return 1
    else
        echo "== shared: no lib/GraphicsMagick/config in $l"; return 1
    fi
    cp -R "$sst$A/include/GraphicsMagick" "$root$A/include/" || return 1
    for pc in GraphicsMagick GraphicsMagickWand; do
        cp "$pcd/$pc.pc" "$root$A/lib/pkgconfig/$pc.pc" && pc_clean "$root$A/lib/pkgconfig/$pc.pc" || return 1
    done
    ld="$(PKG_CONFIG_LIBDIR="$root$A/lib/pkgconfig" pkgconf --variable=libdir GraphicsMagick)"
    [ "$ld" = "$A/lib" ] || { echo "== shared: libdir of GraphicsMagick.pc is $ld, not $A/lib"; return 1; }
    config_wrap GraphicsMagick-config GraphicsMagick "$A" shared
    config_wrap GraphicsMagickWand-config GraphicsMagickWand "$A" shared
    rm -rf "$sst"
    return 0
}

# b_gm <source>: narrowed, a copy for the shared libraries, the static build (gm,
# the static libraries), then the shared libraries
b_gm() {
    src="$1"
    st="$work/stage-static"
    rm -rf "$st" "$root"
    narrow "$src" || return 1
    for p in "$files"/graphicsmagick-*.patch; do
        [ -f "$p" ] || continue
        echo "== graphics/GraphicsMagick/files/${p##*/}"
        patch -p1 -N -s -d "$src" < "$p" || { echo "== ${p##*/} does not apply"; return 1; }
    done
    fix_guess "$src"
    shsrc="$work/wrk/graphicsmagick-shared"
    rm -rf "$shsrc"
    cp -Rp "$src" "$shsrc" ||
        { echo "== cannot copy $src to $shsrc ($(df -h "$work" | awk 'NR == 2 { print $4 " free" }'))"; return 1; }
    (
        cd "$src" || exit 1
        # the static libraries behind them in every link test of configure (it tries
        # -lfreetype alone, and FreeType needs libbz2 and libz)
        # shellcheck disable=SC2086
        ./configure --prefix="$I" LDFLAGS="$LDFLAGS -pie -Wl,-z,relro,-z,now" \
            LIBS="$(pkgconf --static --libs-only-l $pcs) -lc++ -lpthread -lm" PTHREAD_LIBS=-lpthread \
            $(conf_opts configure) --disable-shared --enable-static --disable-dependency-tracking \
            ac_cv_lib_ICE_IceConnectionNumber=no &&
            gmake -j"$ncpu" && gmake install-strip DESTDIR="$st"
    ) || { echo "== configure, gmake or gmake install-strip failed ($(df -h "$work" | awk 'NR == 2 { print $4 " free" }'))"; return 1; }
    echo "== installed into $st"
    cp "$src/config.log" "$res/config.log" 2>/dev/null
    s="$st$I"
    [ -x "$s/bin/gm" ] || { echo "== no bin/gm in $s"; return 1; }
    keep="$(cd "$s" && ls -d bin/gm lib/GraphicsMagick share/GraphicsMagick 2>/dev/null)"
    echo "== into $root$I:" $keep
    mkdir -p "$root$I" || return 1
    # shellcheck disable=SC2086
    (cd "$s" && tar -cf - $keep) | (cd "$root$I" && tar -xpf -) || return 1
    [ -d "$root$I/lib/GraphicsMagick/config" ] || { echo "== no lib/GraphicsMagick/config in $s"; return 1; }
    cp "$files/delegates.mgk" "$root$I/lib/GraphicsMagick/config/delegates.mgk" || return 1
    # the static libraries, headers and .pc files, for a static gmagick of PHP: in the
    # static tree $S (the configuration they read stays that of /usr/local)
    mkdir -p "$root$S/lib/pkgconfig" "$root$S/include" "$root$S/bin" || return 1
    cp "$s/lib/libGraphicsMagick.a" "$s/lib/libGraphicsMagickWand.a" "$root$S/lib/" &&
        cp -R "$s/include/GraphicsMagick" "$root$S/include/" ||
        { echo "== no static libraries or headers of GraphicsMagick in $s: $(ls "$s/lib" | tr '\n' ' ')"; return 1; }
    pcd="$s/libdata/pkgconfig"; [ -f "$pcd/GraphicsMagick.pc" ] || pcd="$s/lib/pkgconfig"
    for pc in GraphicsMagick GraphicsMagickWand; do
        [ -f "$pcd/$pc.pc" ] || { echo "== no $pc.pc in $s/libdata/pkgconfig or $s/lib/pkgconfig"; return 1; }
        sed -e "s|^prefix=$I\$|prefix=$S|" -e "s|^exec_prefix=$I\$|exec_prefix=$S|" \
            -e "s|=$I/include|=$S/include|g" -e "s|=$I/lib\$|=$S/lib|" \
            "$pcd/$pc.pc" > "$root$S/lib/pkgconfig/$pc.pc" && pc_clean "$root$S/lib/pkgconfig/$pc.pc" || return 1
    done
    # the C++ runtime and the threads of libheif and libde265, for a static link line
    pc_add "$root$S/lib/pkgconfig/GraphicsMagick.pc" Libs.private -lc++ -lpthread -lm
    ld="$(PKG_CONFIG_LIBDIR="$root$S/lib/pkgconfig" pkgconf --variable=libdir GraphicsMagick)"
    [ "$ld" = "$S/lib" ] || { echo "== libdir of the static GraphicsMagick.pc is $ld, not $S/lib"; return 1; }
    config_wrap GraphicsMagick-config GraphicsMagick "$S" static
    config_wrap GraphicsMagickWand-config GraphicsMagickWand "$S" static
    b_gm_shared "$shsrc" || return 1
    mkdir -p "$root$I/share/licenses/GraphicsMagick"
    cp "$src/Copyright.txt" "$root$I/share/licenses/GraphicsMagick/Copyright.txt" ||
        { echo "== no Copyright.txt in $src"; return 1; }
    return 0
}

take_args() {
    take_ver=""
    t="$(take_of "$1")"
    [ -n "$t" ] || return 0
    # shellcheck disable=SC2086
    set -- $t "$2"
    take_ver="$1"
    tf="${2%%,*}"; tf="${tf##*/}"
    mkdir -p "$work/distfiles"
    if [ ! -f "$work/distfiles/$tf" ] || [ "$(sha256 -q "$work/distfiles/$tf")" != "$3" ]; then
        rm -f "$work/distfiles/$tf"
        if [ -f "$takedist/$tf" ] && [ "$(sha256 -q "$takedist/$tf")" = "$3" ]; then
            # a distfile of the port (its fetch phase, checked against its distinfo)
            cp "$takedist/$tf" "$work/distfiles/$tf"
            echo "== $tf: from $takedist" >&2
        else
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
        echo "== $tf: SHA-256 $(sha256 -q "$work/distfiles/$tf"), not $3 as in graphicsmagick.conf" >&2
        return 1
    fi
    printf 'TIMESTAMP = %s\nSHA256 (%s) = %s\nSIZE (%s) = %s\n' "$(date +%s)" "$tf" "$3" "$tf" \
        "$(stat -f %z "$work/distfiles/$tf")" > "$work/distinfo-take-$n"
    wd="$(pmake "$5" -V WRKDIR)"
    printf '%s\n' "DISTDIR=$work/distfiles" "DISTFILES=$tf" "PATCHFILES=" "DISTINFO_FILE=$work/distinfo-take-$n" "WRKSRC=$wd/$4"
}

port_patches() {
    fd="$(pmake "$1" -V FILESDIR 2>/dev/null)"
    np="$(ls "$fd" 2>/dev/null | grep -c '^patch-')"
    ne="$(pmake "$1" -V EXTRA_PATCHES 2>/dev/null | wc -w | tr -d ' ')"
    echo $(( np + ne ))
}

# build_one <name> <port>: fetch, check, extract and patch with the ports framework, then b_gm
build_one() {
    n="$1"; port="$2"
    log="$res/$n.log"
    start=$(date +%s)
    targs="$(take_args "$n" "$port" 2>"$res/$n.take")"
    trc=$?
    take_ver="$(take_of "$n" | awk '{ print $1 }')"
    (
        if [ "$trc" != 0 ]; then cat "$res/$n.take"; echo "== $n: the release of the take line could not be had"; exit 1; fi
        if [ -n "$take_ver" ]; then
            echo "== $n: $port at $ports_commit with the release $take_ver of the take line in graphicsmagick.conf:"
            [ ! -s "$res/$n.take" ] || cat "$res/$n.take"
            printf '   %s\n' $targs
        else
            echo "== $n: $port at $ports_commit"
        fi
        # shellcheck disable=SC2086
        pmake "$port" $targs clean >/dev/null 2>&1
        # shellcheck disable=SC2086
        pmake "$port" $targs patch || { echo "make patch failed"; exit 1; }
        # what the configure stage of the framework fixes in the sources before
        # configure, which make patch does not do (as in tools/az-build.sh): FreeBSD 1x
        # taken for 1.x by old autotools, and the libtool fixes of USES=libtool
        for fx in run-autotools-fixup patch-libtool; do
            # shellcheck disable=SC2086
            pmake "$port" $targs "$fx" 2> /dev/null || true
        done
        # shellcheck disable=SC2086
        src="$(pmake "$port" $targs -V WRKSRC)"
        echo "== source: $src"
        b_gm "$src" || exit 1
    ) > "$log" 2>&1
    rc=$?
    ver="$(pmake "$port" -V PKGVERSION 2>/dev/null)"
    pkgname="$(pmake "$port" -V PKGNAME 2>/dev/null)"
    if [ -n "$take_ver" ]; then
        epoch="$(pmake "$port" -V PORTEPOCH 2>/dev/null)"
        case "$epoch" in ""|0) epoch="" ;; *) epoch=",$epoch" ;; esac
        pkgname="${pkgname%-*}-$take_ver$epoch"
        ver="$take_ver (port: $ver)"
    fi
    if [ "$rc" = 0 ]; then
        printf '%-16s OK    %-20s %-22s %4ss\n' "$n" "$ver" "$port" "$(( $(date +%s) - start ))" >> "$res/summary.txt"
        printf '%s %s %s\n' "$n" "$pkgname" "$port" >> "$res/built.txt"
    else
        printf '%-16s FAIL  %-20s %-22s %4ss (%s.log)\n' "$n" "$ver" "$port" "$(( $(date +%s) - start ))" "$n" >> "$res/summary.txt"
        {
            tail -n 40 "$log"
            echo "== disk: $(df -h "$work" | awk 'NR == 2 { print $4 " free of " $2 }')"
            echo "== errors in the log:"
            grep -n -E '\*\*\*|Error [0-9]+|No space|[Ee]rror:' "$log" | tail -n 20
        } > "$res/$n.tail"
    fi
    say "$n: $(tail -n 1 "$res/summary.txt" | awk '{ print $2 }')"
    return "$rc"
}

# The program: PIE, RELRO, BIND_NOW, libraries of the base system only; its formats
# (gm convert -list format) only those of the format lines, with the main ones.
check_bins() {
    f="$root$I/bin/gm"
    [ -x "$f" ] || { echo "gm: missing" >> "$res/bins-bad.txt"; return; }
    type="$(readelf -h "$f" | awk '/Type:/ { print $2 }')"
    relro="$(readelf -l "$f" | grep -c GNU_RELRO)"
    now="$(readelf -d "$f" | grep -c -E 'BIND_NOW|FLAGS_1.*NOW')"
    libs="$(ldd "$f" | awk 'NR > 1 { print $3 }' | tr '\n' ' ' | sed 's/ *$//')"
    printf 'gm: %s KB, ELF type %s, RELRO %s, BIND_NOW %s; libraries: %s\n' \
        "$(du -Ak "$f" | cut -f1)" "$type" "$relro" "$now" "$libs" >> "$res/bins.txt"
    case "$libs" in *"/usr/local/"*) echo "gm: links a library of /usr/local" >> "$res/bins-bad.txt" ;; esac
    [ "$type" = DYN ] || echo "gm: not a PIE (ELF type $type)" >> "$res/bins-bad.txt"
    [ "$relro" -gt 0 ] || echo "gm: no RELRO" >> "$res/bins-bad.txt"
    [ "$now" -gt 0 ] || echo "gm: no BIND_NOW" >> "$res/bins-bad.txt"
    "$f" version > "$res/version.txt" 2>&1
    # the configuration of the stage, not that of /usr/local (not installed yet)
    MAGICK_CONFIGURE_PATH="$root$I/lib/GraphicsMagick/config:$root$I/share/GraphicsMagick/config" \
        "$f" convert -list format > "$res/formats.txt" 2>&1 ||
        { echo "gm convert -list format failed: $(tail -n 1 "$res/formats.txt")" >> "$res/bins-bad.txt"; return; }
    allowed=" $(conf_opts format | tr '\n' ' ') "
    have="$(awk '$2 ~ /^[PSUB]$/ && $3 ~ /^[r-][w-][+-]$/ { print $1 }' "$res/formats.txt" | tr '\n' ' ')"
    other=""
    for x in $have; do
        case "$allowed" in *" $x "*) ;; *) other="$other $x" ;; esac
    done
    [ -z "$other" ] || echo "gm: formats not in the format lines of the conf:$other" >> "$res/bins-bad.txt"
    for x in JPEG PNG GIF WEBP BMP HEIC AVIF XC LABEL; do
        case " $have " in *" $x "*) ;; *) echo "gm: no format $x (gm convert -list format)" >> "$res/bins-bad.txt" ;; esac
    done
    echo "formats: $have" >> "$res/bins.txt"
}

# The shared libraries: a SONAME, the run path $A/lib only, RELRO and BIND_NOW, only
# libraries of $A/lib and of the base system, and the symbols with the prefix Gm
# (--enable-symbol-prefix; the names it leaves are listed in shared.txt)
check_shared() {
    l="$root$A/lib"
    bad=""; names=""
    : > "$res/shared.txt"
    for f in "$l"/libGraphicsMagick.so* "$l"/libGraphicsMagickWand.so*; do
        [ -f "$f" ] && [ ! -L "$f" ] || continue
        b="${f##*/}"
        so="$(readelf -d "$f" | sed -n 's/.*[Ll]ibrary soname: \[\(.*\)\].*/\1/p')"
        rp="$(readelf -d "$f" | sed -n 's/.*[Ll]ibrary r\(un\)\{0,1\}path: \[\(.*\)\].*/\2/p')"
        relro="$(readelf -l "$f" | grep -c GNU_RELRO)"
        now="$(readelf -d "$f" | grep -c -E 'BIND_NOW|FLAGS_1.*NOW')"
        libs="$(LD_LIBRARY_PATH="$l" ldd "$f" | awk 'NR > 1 { print ($3 == "not" ? $1 "(not-found)" : $3) }' | tr '\n' ' ' | sed 's/ *$//')"
        gmsyms="$(nm -D --defined-only "$f" | awk '$3 ~ /^Gm/' | wc -l | tr -d ' ')"
        # what the prefix leaves (1.3.42: 30 names, some of them ImageMagick's too)
        nogm="$(nm -D --defined-only "$f" | awk 'NF == 3 && $2 ~ /^[TDBRVW]$/ && $3 !~ /^(Gm|_Gm|_init$|_fini$|_edata$|_end$|__bss_start$)/ { print $3 }' | sort -u | tr '\n' ' ')"
        plain="$(nm -D --defined-only "$f" | awk '$3 == "NewMagickWand" || $3 == "MagickReadImage" || $3 == "ReadImage" || $3 == "InitializeMagick" { print $3 }' | tr '\n' ' ')"
        printf '%s: SONAME %s, run path %s, RELRO %s, BIND_NOW %s, %s symbols Gm*; libraries: %s; without the prefix: %s\n' \
            "$b" "${so:-none}" "${rp:-none}" "$relro" "$now" "$gmsyms" "$libs" "${nogm:-none}" >> "$res/shared.txt"
        names="$names ${so:-?}"
        [ -n "$so" ] || bad="$bad $b: no SONAME;"
        case ":$rp:" in *":$A/lib:"*) ;; *) bad="$bad $b: run path ${rp:-none}, not $A/lib;" ;; esac
        other="$(printf '%s\n' "$rp" | tr ':' '\n' | grep -v -x -F "$A/lib" | tr '\n' ' ')"
        [ -z "$other" ] || bad="$bad $b: run path $rp has more than $A/lib;"
        [ "$relro" -gt 0 ] || bad="$bad $b: no RELRO;"
        [ "$now" -gt 0 ] || bad="$bad $b: no BIND_NOW;"
        [ "$gmsyms" -gt 0 ] || bad="$bad $b: no symbol with the prefix Gm;"
        [ -z "$plain" ] || bad="$bad $b: exports $plain without the prefix Gm;"
        for p in $libs; do
            case "$p" in
                "$A"/lib/*|"$l"/*|/lib/*|/usr/lib/*) ;;
                *) bad="$bad $b: links $p, not of $A/lib or the base system;" ;;
            esac
        done
    done
    [ -n "$names" ] || bad=" no libGraphicsMagick.so or libGraphicsMagickWand.so in $l;"
    if [ -z "$bad" ]; then
        printf '%-16s OK    sonames:%s; run path %s\n' graphicsmagick-so "$names" "$A/lib" >> "$res/summary.txt"
    else
        printf '%-16s FAIL  sonames:%s;%s (shared.txt)\n' graphicsmagick-so "${names:- none}" "$bad" >> "$res/summary.txt"
        echo "shared libraries:$bad" >> "$res/bins-bad.txt"
    fi
}

# VERSIONS: the version, the distfiles, the patches, the coders, the options
manifest() {
    {
        echo "GraphicsMagick for FreeBSD $major (amd64, $cputype), built $(date '+%Y-%m-%d %H:%M %Z') on $(uname -sr)"
        echo "freebsd-ports $ports_commit; CFLAGS: $CFLAGS"
        echo "libraries: the static ones of $S (the package az, the static tree): mozjpeg, libpng, libwebp, libheif"
        echo "(libde265, dav1d), FreeType, lcms2; the shared libraries against those of $A"
        echo
        while read -r n pkgname port; do
            printf '%-16s %-26s %s\n' "$n" "$pkgname" "$port"
            t="$(take_of "$n")"
            if [ -n "$t" ]; then
                # shellcheck disable=SC2086
                set -- $t
                echo "    ${2##*/} sha256 $3 (upstream release $1, ahead of the port: take line of graphicsmagick.conf)"
            else
                di="$(pmake "$port" -V DISTINFO_FILE 2>/dev/null)"
                for d in $(pmake "$port" -V DISTFILES 2>/dev/null); do
                    d="${d%%:*}"
                    awk -v d="$d" '$1 == "SHA256" { f = $2; gsub(/[()]/, "", f); b = f; sub(/.*\//, "", b)
                        if (b == d) print "    " f " sha256 " $4 }' "$di"
                done
            fi
            np="$(port_patches "$port")"
            [ "$np" -gt 0 ] && echo "    $np patches of the port"
            for p in "$files"/graphicsmagick-*.patch; do
                [ -f "$p" ] && echo "    graphics/GraphicsMagick/files/${p##*/}: $(head -n 1 "$p")"
            done
        done < "$res/built.txt"
        echo
        echo "coders (the table of magick/static.c, the module lines of the conf; the lowest coder class primary):"
        sed 's/^/    /' "$work/narrow.txt"
        echo "formats: $(awk '$2 ~ /^[PSUB]$/ && $3 ~ /^[r-][w-][+-]$/ { print $1 }' "$res/formats.txt" 2>/dev/null | tr '\n' ' ')"
        echo "delegates: none (lib/GraphicsMagick/config/delegates.mgk of graphics/GraphicsMagick/files)"
        echo
        echo "configure (after --prefix=$I and the flags):"
        conf_opts configure | sed 's/^/    /'
        echo
        echo "Program: $I/bin/gm. For a static gmagick of PHP: $S/lib/libGraphicsMagick.a, libGraphicsMagickWand.a,"
        echo "$S/include/GraphicsMagick, $S/bin/GraphicsMagick-config and GraphicsMagickWand-config (the static link"
        echo "line). For gmagick of the PHP packages (--with-gmagick=$A): the shared libraries"
        echo "$(for f in "$root$A"/lib/libGraphicsMagick*.so*; do [ -f "$f" ] && [ ! -L "$f" ] && readelf -d "$f" | sed -n 's/.*[Ll]ibrary soname: \[\(.*\)\].*/\1/p'; done | tr '\n' ' ' | sed 's/ *$//') in $A/lib"
        echo "(built again with the options above and --enable-shared --disable-static, against the shared libraries"
        echo "of $A, run path $A/lib, symbols with the prefix Gm), $A/include/GraphicsMagick,"
        echo "$A/lib/pkgconfig/GraphicsMagickWand.pc, $A/bin/GraphicsMagick-config and GraphicsMagickWand-config."
        echo "Licence: $I/share/licenses/GraphicsMagick/Copyright.txt. Sources: the distfiles above (their SHA-256),"
        echo "the patches of the port at the commit above and tools/graphicsmagick-build.sh of"
        echo "https://github.com/azsupport/ports (graphics/GraphicsMagick/files/graphicsmagick.conf)."
        echo
        cat "$res/version.txt" 2>/dev/null
    } > "$res/VERSIONS"
}

mkdir -p "$res" "$work"
[ -n "$gm_name" ] && [ -n "$gm_port" ] || { echo "graphicsmagick-build: no gm line in $conf" >&2; exit 2; }
# --fetch: the distfiles of the official port, by its own make fetch into AZ_DISTDIR
# (the post-fetch of our port), so that the build needs no network
if [ "${1:-}" = "--fetch" ]; then
    ports_check || exit 1
    if [ -n "$(take_of "$gm_name")" ]; then echo "graphicsmagick-build: $gm_name: the release of its take line is a distfile of the port"; exit 0; fi
    say "fetch $gm_name ($gm_port)"
    pmake "$gm_port" fetch || { echo "graphicsmagick-build: make fetch of $gm_port failed" >&2; exit 1; }
    exit 0
fi
[ $# -eq 0 ] || { echo "usage: sh tools/graphicsmagick-build.sh [--tools | --fetch]" >&2; exit 2; }
report() {
    echo "== $res/summary.txt"
    cat "$res/summary.txt" "$res/bins.txt" "$res/shared.txt" 2>/dev/null
    for f in "$res"/*.tail "$res/bins-bad.txt"; do
        [ -s "$f" ] || continue
        echo "== $f"
        cat "$f"
    done
}
rm -f "$res"/*.tail "$res/bins-bad.txt" "$res/bins.txt"
: > "$res/summary.txt"; : > "$res/built.txt"
cpu_model="$(sysctl -n hw.model 2>/dev/null)"
printf 'flags:    %s\ncpu:      %s\n' "$CFLAGS" "${cpu_model:-?}" >> "$res/summary.txt"
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
    printf '%-16s FAIL  this CPU (%s) %s -march=%s: code built for it cannot run here\n' \
        cpu "${cpu_model:-?}" "${why:-cannot tell the features of}" "$cputype" >> "$res/summary.txt"
    echo "graphicsmagick-build: this CPU ${why:-cannot tell the features of} -march=$cputype" >&2
    report
    exit 1
fi
for pc in $pcs; do
    if [ ! -f "$S/lib/pkgconfig/$pc.pc" ]; then
        printf '%-16s FAIL  no %s of the static libraries in %s/lib/pkgconfig: install the package az first (az/az)\n' libs "$pc" "$S" >> "$res/summary.txt"
        echo "graphicsmagick-build: no $S/lib/pkgconfig/$pc.pc; install the package az first (the port az/az)" >&2
        report
        exit 1
    fi
done
ports_check || { echo "ports            FAIL  $ports is not freebsd-ports $ports_commit of deps.conf" >> "$res/summary.txt"; report; exit 1; }
rc=0
say "$gm_name ($gm_port)"
if build_one "$gm_name" "$gm_port"; then
    check_bins
    check_shared
    manifest
    mkdir -p "$root$I/share/doc/GraphicsMagick" && cp "$res/VERSIONS" "$root$I/share/doc/GraphicsMagick/VERSIONS" || rc=1
    if [ ! -s "$res/bins-bad.txt" ]; then
        echo "installed: $gm_name into the stage $root ($(du -Ask "$root" | cut -f1) KB)" >> "$res/summary.txt"
    else
        rc=1
    fi
else
    rc=1
fi
rm -rf "$work/wrk"
report
exit "$rc"
