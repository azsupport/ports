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
| `gd-2.3.3.patch` | `IMG_BICUBIC` (`GD_BICUBIC`, `GD_BICUBIC_FIXED`) in `gdImageSetInterpolationMethod()`: `imagesetinterpolation()` and `imagescale()` with it failed in PHP | libgd [`39abd72`](https://github.com/libgd/libgd/commit/39abd7238cea2ba8baa4bcac1d6fc01c6cb8afab) (no release after 2.3.3), as Gentoo carries it |
| `libxslt-1.1.45.patch` | CVE-2026-125350, use-after-free in the cache of direct pattern matches | Chromium (06.11.2026), as Gentoo carries it (bug 986081) |
