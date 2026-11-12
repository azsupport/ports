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
# GraphicsMagick its MagickWand functions have the names of those of ImageMagick;
# libmcrypt: the self-tests of its algorithms and their ciphertexts as before;
# FreeType: the design coordinates of a variable font made by the test (CVE-2026-50811).
#
# Usage (FreeBSD, the packages az, ImageMagick7 and GraphicsMagick installed):
# sh tools/az-test.sh
# Results: AZ_RESULTS (default az-test-results/ of the current directory):
# tests.txt (one line per check, the summary at the end), imagick-link.txt,
# shared-link.txt, gmagick-link.txt, gmagick-shared-link.txt, mcrypt.txt, freetype.txt;
# printed at the end.
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
    printf("libxml2 %s; gd %s; ICU %s; libzip %s; libsodium %s; oniguruma %s; sqlite %s; gmp %s; "
        "libxslt %d; libffi %s; tidy %s; %s\n", LIBXML_DOTTED_VERSION,
        gdVersionString(), us, zip_libzip_version(), sodium_version_string(), onig_version(), sqlite3_libversion(),
        gmp_version, xsltLibxsltVersion, ffi_ok ? "ok" : "FAIL", tidyLibraryVersion(), MagickGetVersion(NULL));
    MagickWandTerminus();
    return ffi_ok ? 0 : 1;
}
EOF
spc="libxml-2.0 gdlib icu-uc libzip libsodium oniguruma sqlite3 gmp libxslt libffi tidy"
# libgd with LIQ: libimagequant of graphics/libimagequant (aZ, 11.11.2026)
if ldd "$A/lib/libgd.so" 2>/dev/null | grep -q 'libimagequant\.so.* => /usr/local/lib/'; then
    tpass "libgd: LIQ, libimagequant of the package libimagequant"
else
    tfail "libgd: no libimagequant: $(ldd "$A/lib/libgd.so" 2>&1 | tr '\n' ' ')"
fi
# one libcurl, that of the package curl (aZ, 10.11.2026): none in the shared tree
if ls "$A"/lib/libcurl.so* > /dev/null 2>&1; then
    tfail "a libcurl in $A/lib: $(ls "$A"/lib/libcurl.so* | tr '\n' ' ')(the libcurl of the packages is that of the package curl)"
else
    tpass "no libcurl in $A/lib: the libcurl of the packages is that of the package curl"
fi
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
            bad="$(awk -v a="$A/lib/" 'NF > 2 && $2 == "=>" && index($3, a) != 1 && $3 !~ /^\/(usr\/)?lib\// && $3 !~ /^\/usr\/local\/lib\/libimagequant\.so/ { print $1 " " $3 }' "$t/ldd.txt" | tr '\n' ' ')" &&
            { [ -z "$bad" ] || { echo "not of $A/lib, the base system or libimagequant (of libgd): $bad"; false; }; }
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

# libmcrypt (mcrypt of PHP; files/deps/libmcrypt-2.5.8.patch): every algorithm passes
# its self-test and gives the ciphertexts it gave before the patch (64 keys each),
# with the shared library and with the static one
t="$work/mcrypt"
rm -rf "$t"; mkdir -p "$t"
cat > "$t/t.c" <<'EOF'
#include <stdio.h>
#include <string.h>
#include <mcrypt.h>
/* each algorithm: its self-test, then 64 keys: a text encrypted (CBC, or as a
   stream) and decrypted back; the FNV-1a of the 64 ciphertexts as libmcrypt 2.5.8
   gives them with and without files/deps/libmcrypt-2.5.8.patch */
static const struct { const char *a; unsigned int h; } t[] = {
    { "cast-256", 0x9704d8dfu }, { "twofish", 0x95696af7u }, { "cast-128", 0x6dc5d313u },
    { "gost", 0xb2abcc94u }, { "rijndael-128", 0x098e0512u }, { "rijndael-192", 0x6402157au },
    { "rijndael-256", 0x6393e72cu }, { "saferplus", 0x31a3913fu }, { "serpent", 0x315383aeu },
    { "loki97", 0x57158a24u }, { "xtea", 0xbcfecff0u }, { "blowfish", 0x4e7d3632u },
    { "des", 0xba24eac0u }, { "tripledes", 0xa4325390u }, { "rc2", 0xc5059350u },
    { "arcfour", 0x3296e259u }, { "wake", 0xfc28dad9u }, { "enigma", 0x66e3265du },
    { "blowfish-compat", 0x3179fc2du }, { NULL, 0 } };
int main(void)
{
    int i, bad = 0;
    for (i = 0; t[i].a; i++) {
        unsigned char key[512], iv[512], buf[256], orig[256];
        unsigned int h = 2166136261u;
        int ks, ivs, bs, n, j, k, back = 1;
        const char *mode;
        if (mcrypt_module_self_test((char *)t[i].a, NULL) != 0) {
            printf("%s: self-test FAILED\n", t[i].a); bad++; continue;
        }
        mode = mcrypt_module_is_block_algorithm((char *)t[i].a, NULL) ? "cbc" : "stream";
        for (k = 0; k < 64; k++) {
            MCRYPT td = mcrypt_module_open((char *)t[i].a, NULL, (char *)mode, NULL);
            if (td == MCRYPT_FAILED) { printf("%s: cannot open\n", t[i].a); return 1; }
            ks = mcrypt_enc_get_key_size(td);
            ivs = mcrypt_enc_get_iv_size(td);
            bs = mcrypt_enc_get_block_size(td);
            for (j = 0; j < 512; j++) {
                key[j] = (unsigned char)(j * 7 + 13 + k * 31 + (k * j) % 251);
                iv[j] = (unsigned char)(j * 3 + 1 + k);
            }
            n = 128 - 128 % (bs > 0 ? bs : 1);
            for (j = 0; j < n; j++) orig[j] = buf[j] = (unsigned char)(j * 11 + 5 + k);
            if (mcrypt_generic_init(td, key, ks, ivs > 0 ? iv : NULL) < 0) return 1;
            mcrypt_generic(td, buf, n);
            for (j = 0; j < n; j++) { h ^= buf[j]; h *= 16777619u; }
            mcrypt_generic_deinit(td);
            if (mcrypt_generic_init(td, key, ks, ivs > 0 ? iv : NULL) < 0) return 1;
            mdecrypt_generic(td, buf, n);
            if (memcmp(buf, orig, n) != 0) back = 0;
            mcrypt_generic_deinit(td);
            mcrypt_module_close(td);
        }
        if (h != t[i].h || !back) {
            printf("%s: ciphertexts %08x (not %08x)%s\n", t[i].a, h, t[i].h, back ? "" : ", not decrypted back");
            bad++;
        }
    }
    printf("libmcrypt %s: %d algorithms, %s\n", mcrypt_check_version(NULL), i, bad ? "FAILED" : "the self-tests and the ciphertexts as before");
    return bad != 0;
}
EOF
if {
        cc -O2 -I"$A/include" -o "$t/t" "$t/t.c" -L"$A/lib" -lmcrypt -Wl,-rpath,"$A/lib" && "$t/t" &&
            cc -O2 -I"$A/static/include" -o "$t/ts" "$t/t.c" "$A/static/lib/libmcrypt.a" && "$t/ts"
    } > "$res/mcrypt.txt" 2>&1; then
    tpass "$(tail -n 1 "$res/mcrypt.txt"), shared and static"
else
    tfail "libmcrypt: $(tail -n 3 "$res/mcrypt.txt" | tr '\n' ' ')"
fi

# FreeType (files/deps/freetype2-2.14.3.patch, CVE-2026-50811), with a variable font made
# here, no font from outside: FT_Get_Var_Design_Coordinates() asked for more coordinates
# than the font has axes gives the defaults and zeros, not what lies past the array of the
# axes; with the shared library and with the static one
t="$work/freetype"
rm -rf "$t"; mkdir -p "$t"
cat > "$t/t.c" <<'EOF'
#include <stdio.h>
#include <string.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_MULTIPLE_MASTERS_H
/* a TrueType variable font made here: one empty glyph, two axes (wght 100..400..900,
   wdth 50..100..200) and three named instances; FT_Get_Var_Design_Coordinates() asked
   for 8 coordinates gives the 2 defaults and zeros (files/deps/freetype2-2.14.3.patch,
   CVE-2026-50811; 2.14.3 without it reads past the axis array) */
static unsigned char f[1024];
static size_t n;
static void u16(unsigned v) { f[n++] = v >> 8; f[n++] = v; }
static void u32(unsigned long v) { u16(v >> 16); u16(v & 0xffff); }
static void tag(const char *t) { memcpy(f + n, t, 4); n += 4; }
int main(void)
{
    static const char *tags[] = { "fvar", "glyf", "head", "hhea", "hmtx", "loca", "maxp" };
    size_t dir, off[7], len[7];
    int i, nt = 7, bad = 0;
    FT_Library lib; FT_Face face; FT_MM_Var *mm; FT_Fixed c[8];
    u32(0x00010000); u16(nt); u16(64); u16(2); u16(112 - 64);
    dir = n; n += 16 * nt;
    /* fvar */
    off[0] = n;
    u32(0x00010000); u16(16); u16(2); u16(2); u16(20); u16(3); u16(4 + 4 * 2);
    tag("wght"); u32(100 << 16); u32(400 << 16); u32(900 << 16); u16(0); u16(256);
    tag("wdth"); u32(50 << 16); u32(100 << 16); u32(200 << 16); u16(0); u16(257);
    for (i = 0; i < 3; i++) { u16(258 + i); u16(0); u32((300 + 200 * i) << 16); u32((80 + 20 * i) << 16); }
    len[0] = n - off[0];
    /* glyf: nothing (glyph 0 is empty) */
    off[1] = n; u32(0); len[1] = 4;
    /* head */
    off[2] = n;
    u32(0x00010000); u32(0x00010000); u32(0); u32(0x5F0F3CF5); u16(0); u16(1000);
    u32(0); u32(0); u32(0); u32(0); u16(0); u16(0); u16(1000); u16(1000);
    u16(0); u16(8); u16(2); u16(0); u16(0);
    len[2] = n - off[2];
    /* hhea */
    off[3] = n;
    u32(0x00010000); u16(800); u16(-200 & 0xffff); u16(0); u16(500); u16(0); u16(0); u16(500);
    u16(1); u16(0); u16(0); u16(0); u16(0); u16(0); u16(0); u16(0); u16(1);
    len[3] = n - off[3];
    /* hmtx */
    off[4] = n; u16(500); u16(0); len[4] = 4;
    /* loca (short): glyph 0 from 0 to 0 */
    off[5] = n; u16(0); u16(0); len[5] = 4;
    /* maxp 1.0 */
    off[6] = n; u32(0x00010000); u16(1); for (i = 0; i < 13; i++) u16(i < 2 ? 1 : 0); len[6] = n - off[6];
    for (i = 0; i < nt; i++) {
        size_t m = n; n = dir + 16 * i;
        tag(tags[i]); u32(0); u32(off[i]); u32(len[i]); n = m;
        while (n % 4) f[n++] = 0;
    }
    if (FT_Init_FreeType(&lib) || FT_New_Memory_Face(lib, f, (FT_Long)n, 0, &face)) {
        printf("FreeType: the font made here does not load\n"); return 1;
    }
    if (!FT_HAS_MULTIPLE_MASTERS(face) || FT_Get_MM_Var(face, &mm) || mm->num_axis != 2) {
        printf("FreeType: the font made here is no variable font\n"); return 1;
    }
    for (i = 0; i < 8; i++) c[i] = 0x7777;
    if (FT_Get_Var_Design_Coordinates(face, 8, c)) { printf("FT_Get_Var_Design_Coordinates failed\n"); return 1; }
    if (c[0] != (400 << 16) || c[1] != (100 << 16)) bad = 1;
    for (i = 2; i < 8; i++) if (c[i] != 0) bad = 1;
    printf("FreeType %d.%d.%d: 2 axes, 8 design coordinates asked: %ld %ld, then %ld %ld %ld %ld %ld %ld%s\n",
        FREETYPE_MAJOR, FREETYPE_MINOR, FREETYPE_PATCH,
        (long)(c[0] >> 16), (long)(c[1] >> 16), (long)c[2], (long)c[3], (long)c[4], (long)c[5], (long)c[6], (long)c[7],
        bad ? ": read past the axes (CVE-2026-50811)" : " (the defaults, the rest zeroed)");
    FT_Done_MM_Var(lib, mm); FT_Done_Face(face); FT_Done_FreeType(lib);
    return bad;
}
EOF
# shellcheck disable=SC2046
if {
        cc -O2 $("$A/bin/pkg-config" --cflags freetype2) -o "$t/t" "$t/t.c" \
            $("$A/bin/pkg-config" --libs freetype2) -Wl,-rpath,"$A/lib" && "$t/t" &&
            cc -O2 $("$A/static/bin/pkg-config" --cflags freetype2) -o "$t/ts" "$t/t.c" \
                $("$A/static/bin/pkg-config" --libs freetype2) && "$t/ts"
    } > "$res/freetype.txt" 2>&1; then
    tpass "$(tail -n 1 "$res/freetype.txt"), shared and static"
else
    tfail "FreeType: $(tail -n 3 "$res/freetype.txt" | tr '\n' ' ')"
fi

echo "tests: $pok ok, $pbad failed" >> "$res/tests.txt"
cat "$res/tests.txt"
[ "$pbad" = 0 ]
