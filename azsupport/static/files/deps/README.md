# Patches of a port, brought up to the release of its take line

## Which ports take these files

Every library of the kind `shared` in `deps.conf` is a port of its own, `azsupport/<name>`
(the package `azsupport-<name>`; fontconfig: `x11-fonts/fontconfig`), and the libraries of
the kind `static` are built together by `azsupport/static` (the package `azsupport-static`,
the static tree `/usr/local/azsupport/static`). The confs and the patches are here, in
`azsupport/static/files/`, with the port that reads all of them (the package `azsupport`,
`azsupport/azsupport`, has only the `pkg-config` wrapper of the shared tree and the trigger
of the services: a port that needs the wrapper takes none of these into its hash). The
files of a library are those of its port, which
[`tools/azsupport-lib-ports.sh`](../../../../tools/azsupport-lib-ports.sh) makes from them
(`--write <official tree>`):

- its lines of `deps.conf` (`lib`, `take`, `needs`) and of `curl-deps.conf` (with `psl-list`
  for libpsl), as they are, in `AZSUPPORT_LIB_CONF` of its Makefile;
- `deps/<name>-*.patch`, `deps/<name>-<version>/` of its active take line,
  `curl/<name>-<version>.patch` of a library of the bundled curl, `curl/build-libcurl.sh` for
  libssh2 (its `ssh2_algos`), in `AZSUPPORT_LIB_FILES`, which are in its `azsupport_hash`;
- the release file of its take line or of `curl-deps.conf`, a distfile of its own.

`tools/azsupport-build.sh --lib <name>` (its `do-build`) stops while its Makefile has other
lines or files than these: a change here goes with `--write` (`--check` shows what
differs). `azsupport/static` reads all of them (its `AZSUPPORT_HASH_FILES`).

## Releases ahead of the port

`azsupport/static/files/deps.conf` can build a library of `/usr/local/azsupport` from a new upstream
release before its FreeBSD port has it (a `take` line). The ports framework applies
the patches of the port to it; when one of them no longer applies,
`azsupport/static/files/deps/<name>-<version>/` holds all the patches of that port, the failing ones
brought up to the release, and the framework takes them from here instead
(`PATCHDIR`). [`tools/deps-take-check.sh`](../../../../tools/deps-take-check.sh) (workflow
[`deps-take-check.yml`](../../../../.github/workflows/deps-take-check.yml), "azsupport take check")
shows which patches apply; [`take-sources.yml`](../../../../.github/workflows/take-sources.yml)
whether the release file of a take line is the same from every source.

| Directory | From | Changed |
|---|---|---|
| `libiconv-1.19.1` | `converters/libiconv/files` at the ports commit of `deps.conf` (libiconv 1.18) | `patch-include-iconv.h.in`: the context line `_LIBICONV_VERSION 0x0113` of 1.19 (it was `0x0112`); the other two as they are |

A directory goes with its take line, once the port has the version.
`libiconv-1.19.1` stays while its take line is commented out in `deps.conf`
(04.11.2026: releases are taken before their port only for a vulnerability that
touches us, or a bug we have; 22.11.2026: and a release of the major version we
have that fixes a vulnerability): ready for a security release of libiconv 1.19.x.

## Fixes the port lacks

`azsupport/static/files/deps/<name>-<version>.patch` (`-p0`, as the patches of `files/curl`, with
`Description:` and `Origin:` on top) is applied by `tools/azsupport-build.sh` after the patches
of the port (or of the take line) when `<version>` is the version built (`DISTVERSION`
of the port, or that of the take line); a file for another version stops the build, so
that it gets reviewed when the port moves on. Only for a vulnerability that touches us,
or a bug we have (rule of 04.11.2026); it goes when the port has the fix, or when a take
line brings a release with it (`freetype2-2.14.3.patch`: FreeType 2.15.0, 22.11.2026).

| File | What | From |
|---|---|---|
| `gd-2.3.3.patch` | `IMG_BICUBIC` (`GD_BICUBIC`, `GD_BICUBIC_FIXED`) in `gdImageSetInterpolationMethod()`: `imagesetinterpolation()` and `imagescale()` with it failed in PHP; CVE-2026-9672, the LZW decoder of GIF (`imagecreatefromgif()`): a row of its table and its state uninitialised, the data after the end code read on; `imagerotate()` of a palette image (GIF, PNG8): by 180 degrees libgd destroyed the image of the caller instead of its truecolor copy and rotated it then (#810: a use-after-free, and a double free when PHP frees it), by another angle with `IMG_NEAREST_NEIGHBOUR` it rotated the palette image itself (#929: a crash) | libgd [`39abd72`](https://github.com/libgd/libgd/commit/39abd7238cea2ba8baa4bcac1d6fc01c6cb8afab) (no release after 2.3.3), as Gentoo carries it; CVE-2026-9672 as [openSUSE](https://github.com/bmwiedemann/openSUSE/blob/master/packages/g/gd/gd-CVE-2026-9672.patch) carries it (bsc#1273101): the code of the libgd bundled in PHP; #810 and #929: libgd [`6cc1e39`](https://github.com/libgd/libgd/commit/6cc1e39e9fddd15ae74adb1a09fcd5740f44923e) and [`a656f5c`](https://github.com/libgd/libgd/commit/a656f5cc5592757996e9e96b0821a0966bfaa3b3), as Debian carries them (libgd2 2.3.3-16) |
| `libxslt-1.1.45.patch` | CVE-2026-125350, use-after-free in the cache of direct pattern matches; CVE-2026-9947, a double free of the whitespace-only text of an `xsl:attribute` under `xml:space="preserve"`; CVE-2025-10911, a use-after-free through the cached result tree fragments, which XPath could reach on the `prev` and `next` of their documents (a list of their own now: fields of `xsltInternals.h` renamed, of the same size; unused by `ext/xsl`); CVE-2026-11196, a DTD in a template taken for elements (a type confusion); CVE-2026-87636, `document('')` with a base URI that does not resolve gave the stylesheet itself to the transformation (a stylesheet loaded from a string that reads itself so gets an empty node-set now: load it from a file, or set `DOMDocument::$documentURI`) | Chromium (06.11.2026), as Gentoo carries it (bug 986081); CVE-2026-9947 Chromium (20.04.2026), as [Alpine](https://github.com/alpinelinux/aports/blob/master/main/libxslt/CVE-2026-9947.patch) carries it; CVE-2025-10911 the fix of libxslt #144 (merge request 77), as Red Hat (RHEL 10) and Chromium [`abf266b`](https://chromium.googlesource.com/chromium/src/+/abf266b28588e4533242ca562ecb4be778d3e246) carry it (the same code on 1.1.45); CVE-2026-11196 Chromium [`f022d55`](https://chromium.googlesource.com/chromium/src/+/f022d55a424e6b5727681af0002b9e185b3b808b); CVE-2026-87636 Chromium [`8005fbd`](https://chromium.googlesource.com/chromium/src/+/8005fbd4ba5355dc88df069fd99bf76e3fd2b525), as [Alpine](https://github.com/alpinelinux/aports/blob/77c6bbe29ea4a9352138b3c974c3926f0ff3635e/main/libxslt/CVE-2026-87636.patch) and [Wolfi](https://github.com/wolfi-dev/os/tree/b05894c521b790b03b8f2dfe1bc573f7e31acb44/libxslt) carry them |
| `libmcrypt-2.5.8.patch` | undefined behaviour of the rotations (shifts by 32 and more: CAST-256, and CAST-128 on a rotation by 0) and an uninitialised read in Twofish; the ciphertexts of every algorithm as before on amd64 (`tools/azsupport-test.sh`) | [Gentoo](https://github.com/gentoo/gentoo/tree/master/dev-libs/libmcrypt/files) `rotate-mask` and `uninitialized` (Debian since 2.5.8-3), the mask extended to the other shift and to ROL of `cast-128.c` |
| `readline-8.3.6.patch` | the prompt with escape sequences in a single-byte locale after a recalled line that wrapped (readline83-004) | Kerin Millar, as [Gentoo](https://github.com/gentoo/gentoo/blob/master/sys-libs/readline/files/readline-8.3_p6-single-byte-prompt-reprint.patch) carries it (bug 984299); `shells/bash` carries it on its own readline |
| `libde265-1.1.3.patch` | GHSA-gcwv-rhgp-4mpm: the conformance window of the SPS checked with a sum that could wrap, so the window libheif crops HEIC with reached beyond the picture; and the offsets of the window applied as bytes instead of samples to pictures of more than 8 bits | libde265 [`956cd8c`](https://github.com/strukturag/libde265/commit/956cd8c09ba9b368d711d23448588d04df7fb0ba) and [`4fb298e`](https://github.com/strukturag/libde265/commit/4fb298ec1af0686211dc2def73f4f41c2ce19ce5) (30.09.2026, after 1.1.3) |
| `tidy-5.8.0.patch` | the attribute `type` of `<ol>` taken for one HTML5 does not allow: warned about by `tidy_parse_string()` and `tidy_repair_string()`, and dropped with `drop-proprietary-attributes` (tidy-html5 #1012) | tidy-html5 [`e411ad0`](https://github.com/htacg/tidy-html5/commit/e411ad0d2582471fe0961900b2789ee8b5b9cc4c) (no release after 5.8.0), as Gentoo carries it (bug 916074) |
| `icu-76_1.patch` | the time zone data of ICU 76.1 is tz 2024b (the port does not update it): the offsets that changed since were wrong in `intl` of PHP and `Intl` of node (Paraguay, British Columbia, Alberta and Manitoba, Cuba, the new `America/Coyhaique`). Brought to tz 2026f as the ICU user guide documents it: `zoneinfo64`, `metaZones`, `timezoneTypes` and `windowsZones` of the time zone update of ICU, compiled by the `genrb` of the build over those it unpacks from the prebuilt data archive (the source tarball has no other data). With the metazones of CLDR 48, `Pacific/Honolulu` is named `GMT-10:00` (its metazone Hawaii has no names in the locale data of 76) | [icu-data](https://github.com/unicode-org/icu-data/tree/6eac2f4d349d9f4a0825103bb41845d8e5ab7add/tzdata/icunew/2026f/44) `tzdata/icunew/2026f/44` (29.10.2026); [Updating the Time Zone Data](https://unicode-org.github.io/icu/userguide/datetime/timezone/#updating-the-time-zone-data) |
