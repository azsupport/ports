#!/bin/sh
# az-test.sh - the link tests of the packages az, ImageMagick7 and GraphicsMagick,
# installed (from tools/build-az.sh of https://github.com/azsupport/php-src,
# 08.11.2026): a program and a shared object linked as imagick of the static PHP
# links ImageMagick 7 (MagickWand-config of the static tree AZ_PREFIX/static),
# which has to find HEIC among the formats; a program linked as a PHP module of pkg
# mode links the shared tree AZ_PREFIX (bin/pkg-config, bin/MagickWand-config),
# whose libraries all have to come from AZ_PREFIX/lib or the base system; and the
# same two for GraphicsMagick as gmagick links it (GraphicsMagickWand-config of the
# static tree; GraphicsMagick-config and pkg-config GraphicsMagickWand of the
# shared tree), in programs of their own: without the symbol prefix of
# GraphicsMagick its MagickWand functions have the names of those of ImageMagick.
#
# Usage (FreeBSD, the packages az, ImageMagick7 and GraphicsMagick installed):
# sh tools/az-test.sh
# Results: AZ_RESULTS (default az-test-results/ of the current directory):
# tests.txt (one line per check, the summary at the end), imagick-link.txt,
# shared-link.txt, gmagick-link.txt, gmagick-shared-link.txt; printed at the end.
# Exit status 0 when every check passed.

set -u
A="${AZ_PREFIX:-/usr/local/az}"
work="${AZ_WORK:-/var/tmp/az-work}/az-test"
res="${AZ_RESULTS:-$(pwd)/az-test-results}"
mkdir -p "$res" "$work"
: > "$res/tests.txt"
pok=0; pbad=0
tpass() { echo "ok    $*" >> "$res/tests.txt"; pok=$((pok + 1)); }
tfail() { echo "FAIL  $*" >> "$res/tests.txt"; pbad=$((pbad + 1)); }

# imagick of PHP links the static libraries of ImageMagick 7 in, with the line of
# MagickWand-config of the static tree /usr/local/az/static: a program (and a
# shared object, as libphp.so)
# that does so, run once; it has to find HEIC among the formats (libheif, the policy)
t="$work/imagick-link"
rm -rf "$t"; mkdir -p "$t"
cat > "$t/t.c" <<'EOF'
#include <stdio.h>
#include <string.h>
#include <MagickWand/MagickWand.h>
int main(void)
{
    size_t n = 0, i, heic = 0;
    char **f;
    MagickWandGenesis();
    f = MagickQueryFormats("*", &n);
    for (i = 0; i < n; i++)
        if (strcmp(f[i], "HEIC") == 0)
            heic = 1;
    printf("%s; %zu formats; HEIC %s\n", MagickGetVersion(NULL), n, heic ? "yes" : "no");
    MagickWandTerminus();
    return heic ? 0 : 1;
}
EOF
# environ comes from the program that loads a shared object (crt1.o of httpd, php),
# not from libc.so: for the link of the shared object with --no-undefined, a weak one
printf '%s\n' 'char **environ __attribute__((weak));' > "$t/env.c"
if cf="$("$A/static/bin/MagickWand-config" --cflags)" && lf="$("$A/static/bin/MagickWand-config" --libs)" &&
    {
        echo "MagickWand-config --cflags: $cf"
        echo "MagickWand-config --libs: $lf"
        # shellcheck disable=SC2086
        cc -O2 -fPIC $cf -o "$t/t" "$t/t.c" $lf && "$t/t" &&
            cc -O2 -fPIC -shared $cf -o "$t/t.so" "$t/t.c" "$t/env.c" $lf -Wl,--no-undefined &&
            echo "shared object: linked" &&
            echo "libraries of the program: $(ldd "$t/t" | awk 'NF > 2 && $2 == "=>" { print $3 }' | tr '\n' ' ')"
    } > "$res/imagick-link.txt" 2>&1; then
    tpass "imagick: $(grep -m 1 'formats' "$res/imagick-link.txt"), linked as imagick links it"
else
    tfail "imagick: the static libraries of ImageMagick 7 do not link as imagick links them: $(tail -n 3 "$res/imagick-link.txt" | tr '\n' ' ')"
fi

# The PHP modules of pkg mode link the shared libraries of the shared tree
# /usr/local/az: a program that links them as such a module would (the
# .pc files through bin/pkg-config of the tree, libMagickWand of the package
# ImageMagick7 through bin/MagickWand-config), run once; every library it loads
# has to come from /usr/local/az/lib or the base system (the run path).
t="$work/shared-link"
rm -rf "$t"; mkdir -p "$t"
cat > "$t/t.c" <<'EOF'
#include <stdio.h>
#include <libxml/xmlversion.h>
#include <curl/curl.h>
#include <gd.h>
#include <unicode/uversion.h>
#include <zip.h>
#include <sodium.h>
#include <oniguruma.h>
#include <sqlite3.h>
#include <gmp.h>
#include <libxslt/xslt.h>
#include <ffi.h>
#include <tidy.h>
#include <MagickWand/MagickWand.h>
int main(void)
{
    UVersionInfo uv;
    char us[U_MAX_VERSION_STRING_LENGTH];
    ffi_cif cif;
    ffi_type *args[1] = { &ffi_type_sint };
    int ffi_ok;
    u_getVersion(uv);
    u_versionToString(uv, us);
    xmlCheckVersion(LIBXML_VERSION);
    if (sodium_init() < 0)
        return 1;
    ffi_ok = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_sint, args) == FFI_OK;
    MagickWandGenesis();
    printf("libxml2 %s; curl %s; gd %s; ICU %s; libzip %s; libsodium %s; oniguruma %s; sqlite %s; gmp %s; "
        "libxslt %d; libffi %s; tidy %s; %s\n", LIBXML_DOTTED_VERSION, curl_version_info(CURLVERSION_NOW)->version,
        gdVersionString(), us, zip_libzip_version(), sodium_version_string(), onig_version(), sqlite3_libversion(),
        gmp_version, xsltLibxsltVersion, ffi_ok ? "ok" : "FAIL", tidyLibraryVersion(), MagickGetVersion(NULL));
    MagickWandTerminus();
    return ffi_ok ? 0 : 1;
}
EOF
spc="libxml-2.0 libcurl gdlib icu-uc libzip libsodium oniguruma sqlite3 gmp libxslt libffi tidy"
# shellcheck disable=SC2086
if cf="$("$A/bin/pkg-config" --cflags $spc)" && lf="$("$A/bin/pkg-config" --libs $spc)" &&
    mcf="$("$A/bin/MagickWand-config" --cflags)" && mlf="$("$A/bin/MagickWand-config" --libs)" &&
    {
        echo "pkg-config --cflags: $cf"
        echo "pkg-config --libs: $lf"
        echo "MagickWand-config: $mcf $mlf"
        # shellcheck disable=SC2086
        cc -O2 -fPIC $cf $mcf -o "$t/t" "$t/t.c" $lf $mlf -Wl,-rpath,"$A/lib" && "$t/t" &&
            ldd "$t/t" > "$t/ldd.txt" &&
            echo "libraries of the program: $(awk 'NF > 2 && $2 == "=>" { print $3 }' "$t/ldd.txt" | tr '\n' ' ')" &&
            bad="$(awk -v a="$A/lib/" 'NF > 2 && $2 == "=>" && index($3, a) != 1 && $3 !~ /^\/(usr\/)?lib\// { print $1 " " $3 }' "$t/ldd.txt" | tr '\n' ' ')" &&
            { [ -z "$bad" ] || { echo "not of $A/lib or the base system: $bad"; false; }; }
    } > "$res/shared-link.txt" 2>&1; then
    tpass "shared libraries of $A: $(grep -m 1 '^libxml2 ' "$res/shared-link.txt"), from $A/lib and the base system"
else
    # a library the linker cannot find: which .pc names it, what of it is in $A/lib
    why=""
    for l in $(sed -n 's/.*unable to find library -l\([^ ]*\).*/\1/p' "$res/shared-link.txt" | sort -u); do
        why="$why -l$l named by: $(grep -l -w -e "-l$l" "$A"/lib/pkgconfig/*.pc 2> /dev/null | sed 's#.*/##' | tr '\n' ' ')in $A/lib: $(ls "$A/lib" | grep "^lib$l[.]" | tr '\n' ' ');"
    done
    tfail "shared libraries of $A: a program does not link or run as a PHP module of pkg mode would: $(grep -m 1 '^pkg-config --libs:' "$res/shared-link.txt") $(tail -n 3 "$res/shared-link.txt" | tr '\n' ' ')$why"
fi

# gmagick of PHP links GraphicsMagick as imagick links ImageMagick 7: statically
# with the line of GraphicsMagickWand-config of the static tree (a program and a
# shared object), and as a module of pkg mode with GraphicsMagick-config of the
# shared tree (its --prefix is the tree whose lib/ and include/GraphicsMagick
# gmagick takes: config.m4 of ext/gmagick) and pkg-config GraphicsMagickWand;
# each has to find HEIC among the formats, the shared one only libraries of
# AZ_PREFIX/lib and the base system
t="$work/gmagick-link"
rm -rf "$t"; mkdir -p "$t"
cat > "$t/t.c" <<'EOF'
#include <stdio.h>
#include <string.h>
#include <wand/wand_api.h>
int main(int argc, char **argv)
{
    unsigned long n = 0, i, heic = 0, v = 0;
    char **f;
    (void) argc;
    InitializeMagick(*argv);
    f = MagickQueryFormats("*", &n);
    for (i = 0; f != NULL && i < n; i++)
        if (strcmp(f[i], "HEIC") == 0)
            heic = 1;
    printf("%s; %lu formats; HEIC %s\n", MagickGetVersion(&v), n, heic ? "yes" : "no");
    DestroyMagick();
    return heic ? 0 : 1;
}
EOF
printf '%s\n' 'char **environ __attribute__((weak));' > "$t/env.c"
if cf="$("$A/static/bin/GraphicsMagickWand-config" --cflags)" && lf="$("$A/static/bin/GraphicsMagickWand-config" --libs)" &&
    {
        echo "GraphicsMagickWand-config --cflags: $cf"
        echo "GraphicsMagickWand-config --libs: $lf"
        # shellcheck disable=SC2086
        cc -O2 -fPIC $cf -o "$t/t" "$t/t.c" $lf && "$t/t" &&
            cc -O2 -fPIC -shared $cf -o "$t/t.so" "$t/t.c" "$t/env.c" $lf -Wl,--no-undefined &&
            echo "shared object: linked" &&
            echo "libraries of the program: $(ldd "$t/t" | awk 'NF > 2 && $2 == "=>" { print $3 }' | tr '\n' ' ')"
    } > "$res/gmagick-link.txt" 2>&1; then
    tpass "gmagick: $(grep -m 1 'formats' "$res/gmagick-link.txt"), linked statically as a static gmagick links it"
else
    tfail "gmagick: the static libraries of GraphicsMagick do not link as a static gmagick links them: $(tail -n 3 "$res/gmagick-link.txt" | tr '\n' ' ')"
fi
t="$work/gmagick-shared-link"
rm -rf "$t"; mkdir -p "$t"
cp "$work/gmagick-link/t.c" "$t/t.c"
# shellcheck disable=SC2086
if gp="$("$A/bin/GraphicsMagick-config" --prefix)" && cf="$("$A/bin/pkg-config" --cflags GraphicsMagickWand)" &&
    lf="$("$A/bin/pkg-config" --libs GraphicsMagickWand)" &&
    {
        echo "GraphicsMagick-config --prefix: $gp"
        echo "pkg-config --cflags GraphicsMagickWand: $cf"
        echo "pkg-config --libs GraphicsMagickWand: $lf"
        [ "$gp" = "$A" ] || { echo "GraphicsMagick-config --prefix is $gp, not $A"; false; } &&
            [ -f "$gp/lib/libGraphicsMagick.so" ] && [ -f "$gp/lib/libGraphicsMagickWand.so" ] &&
            [ -f "$gp/include/GraphicsMagick/wand/wand_api.h" ] &&
            cc -O2 -fPIC $cf -o "$t/t" "$t/t.c" $lf -Wl,-rpath,"$A/lib" && "$t/t" &&
            ldd "$t/t" > "$t/ldd.txt" &&
            echo "libraries of the program: $(awk 'NF > 2 && $2 == "=>" { print $3 }' "$t/ldd.txt" | tr '\n' ' ')" &&
            bad="$(awk -v a="$A/lib/" 'NF > 2 && $2 == "=>" && index($3, a) != 1 && $3 !~ /^\/(usr\/)?lib\// { print $1 " " $3 }' "$t/ldd.txt" | tr '\n' ' ')" &&
            { [ -z "$bad" ] || { echo "not of $A/lib or the base system: $bad"; false; }; }
    } > "$res/gmagick-shared-link.txt" 2>&1; then
    tpass "gmagick of pkg mode: $(grep -m 1 'formats' "$res/gmagick-shared-link.txt"), from $A/lib and the base system"
else
    tfail "gmagick of pkg mode: a program does not link or run as gmagick of pkg mode would: $(tail -n 3 "$res/gmagick-shared-link.txt" | tr '\n' ' ')"
fi

echo "tests: $pok ok, $pbad failed" >> "$res/tests.txt"
cat "$res/tests.txt"
[ "$pbad" = 0 ]
