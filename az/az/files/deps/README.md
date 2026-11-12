# Patches of a port, brought up to the release of its take line

`az/az/files/deps.conf` can build a library of `/usr/local/az` from a new upstream
release before its FreeBSD port has it (a `take` line). The ports framework applies
the patches of the port to it; when one of them no longer applies,
`az/az/files/deps/<name>-<version>/` holds all the patches of that port, the failing ones
brought up to the release, and the framework takes them from here instead
(`PATCHDIR`). [`tools/deps-take-check.sh`](../../../../tools/deps-take-check.sh) (workflow
[`deps-take-check.yml`](../../../../.github/workflows/deps-take-check.yml), "az take check")
shows which patches apply; [`take-sources.yml`](../../../../.github/workflows/take-sources.yml)
whether the release file of a take line is the same from every source.

| Directory | From | Changed |
|---|---|---|
| `libiconv-1.19.1` | `converters/libiconv/files` at the ports commit of `deps.conf` (libiconv 1.18) | `patch-include-iconv.h.in`: the context line `_LIBICONV_VERSION 0x0113` of 1.19 (it was `0x0112`); the other two as they are |

A directory goes with its take line, once the port has the version.
`libiconv-1.19.1` stays while its take line is commented out in `deps.conf`
(04.11.2026: releases are taken before their port only for a vulnerability that
touches us, or a bug we have): ready for a security release of libiconv 1.19.x.

## Fixes the port lacks

`az/az/files/deps/<name>-<version>.patch` (`-p0`, as the patches of `files/curl`, with
`Description:` and `Origin:` on top) is applied by `tools/az-build.sh` after the patches
of the port (or of the take line) when `<version>` is the version built (`DISTVERSION`
of the port, or that of the take line); a file for another version stops the build, so
that it gets reviewed when the port moves on. Only for a vulnerability that touches us,
or a bug we have (rule of 04.11.2026); it goes when the port has the fix.

| File | What | From |
|---|---|---|
| `gd-2.3.3.patch` | `IMG_BICUBIC` (`GD_BICUBIC`, `GD_BICUBIC_FIXED`) in `gdImageSetInterpolationMethod()`: `imagesetinterpolation()` and `imagescale()` with it failed in PHP; CVE-2026-9672, the LZW decoder of GIF (`imagecreatefromgif()`): a row of its table and its state uninitialised, the data after the end code read on | libgd [`39abd72`](https://github.com/libgd/libgd/commit/39abd7238cea2ba8baa4bcac1d6fc01c6cb8afab) (no release after 2.3.3), as Gentoo carries it; CVE-2026-9672 as [openSUSE](https://github.com/bmwiedemann/openSUSE/blob/master/packages/g/gd/gd-CVE-2026-9672.patch) carries it (bsc#1273101): the code of the libgd bundled in PHP |
| `libxslt-1.1.45.patch` | CVE-2026-125350, use-after-free in the cache of direct pattern matches; CVE-2026-9947, a double free of the whitespace-only text of an `xsl:attribute` under `xml:space="preserve"` | Chromium (06.11.2026), as Gentoo carries it (bug 986081); CVE-2026-9947 Chromium (20.04.2026), as [Alpine](https://github.com/alpinelinux/aports/blob/master/main/libxslt/CVE-2026-9947.patch) carries it |
| `libmcrypt-2.5.8.patch` | undefined behaviour of the rotations (shifts by 32 and more: CAST-256, and CAST-128 on a rotation by 0) and an uninitialised read in Twofish; the ciphertexts of every algorithm as before on amd64 (`tools/az-test.sh`) | [Gentoo](https://github.com/gentoo/gentoo/tree/master/dev-libs/libmcrypt/files) `rotate-mask` and `uninitialized` (Debian since 2.5.8-3), the mask extended to the other shift and to ROL of `cast-128.c` |
| `readline-8.3.6.patch` | the prompt with escape sequences in a single-byte locale after a recalled line that wrapped (readline83-004) | Kerin Millar, as [Gentoo](https://github.com/gentoo/gentoo/blob/master/sys-libs/readline/files/readline-8.3_p6-single-byte-prompt-reprint.patch) carries it (bug 984299); `shells/bash` carries it on its own readline |
| `libde265-1.1.3.patch` | GHSA-gcwv-rhgp-4mpm: the conformance window of the SPS checked with a sum that could wrap, so the window libheif crops HEIC with reached beyond the picture; and the offsets of the window applied as bytes instead of samples to pictures of more than 8 bits | libde265 [`956cd8c`](https://github.com/strukturag/libde265/commit/956cd8c09ba9b368d711d23448588d04df7fb0ba) and [`4fb298e`](https://github.com/strukturag/libde265/commit/4fb298ec1af0686211dc2def73f4f41c2ce19ce5) (30.09.2026, after 1.1.3) |
| `freetype2-2.14.3.patch` | CVE-2026-50811, `FT_Get_Var_Design_Coordinates()` asked for more coordinates than a variable font has axes read past the array of its axes (TrueType GX and Type 1 multiple masters; the extra ones now zeroed); CVE-2026-95512, the overlapping subroutine dictionaries of a CID-keyed font allocated and decrypted again and again (now limited). Only the servers' own fonts are read; patched anyway (aZ, 12.11.2026), not the 2.15.0 take line | FreeType [`8fa928f`](https://gitlab.freedesktop.org/freetype/freetype/-/commit/8fa928f1617aba65f45b00f0dcb109f077b7741e), [`5a280ec`](https://gitlab.freedesktop.org/freetype/freetype/-/commit/5a280ecde6f324de0d226261036e736e0cb49a71) and [`f3ca71c`](https://gitlab.freedesktop.org/freetype/freetype/-/commit/f3ca71c9900fe860849b3163a6e2c1e765b291d9) (in 2.15.0), as Debian carries them on 2.14.3 (2.14.3+dfsg-3) |
