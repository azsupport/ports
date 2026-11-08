# azsupport/ports

FreeBSD ports of aZ (azsupport.com): an overlay of the FreeBSD ports tree, from
which the packages of his pkg repository **az** are built for his FreeBSD 15
servers (amd64), so that nothing is built on the servers.
[README.ru.md](README.ru.md): the same in Russian.

- [What it is](#what-it-is)
- [The packages](#the-packages)
- [The ports](#the-ports)
- [The layout of PHP on a server](#the-layout-of-php-on-a-server)
- [A server and the repository az](#a-server-and-the-repository-az)
- [How it is built](#how-it-is-built)
- [The rules of the ports](#the-rules-of-the-ports)

## What it is

- **An overlay**: only our ports, on top of the official tree
  [freebsd-ports](https://github.com/freebsd/freebsd-ports) at a pinned commit,
  [`f16b6dd0f7c1`](https://github.com/freebsd/freebsd-ports/tree/f16b6dd0f7c1c3a2e0447e192e39e72f21d85eb0)
  (main of 04.11.2026; `ports_commit` in [`tools/build.sh`](tools/build.sh)). The ports
  framework takes it as `OVERLAYS`: `bsd.port.mk` includes
  [`Mk/bsd.overlay.mk`](Mk/bsd.overlay.mk), takes `Mk/Uses/<name>.mk` of the overlay
  before the official one, and a port of the overlay takes the place of the official
  port with the same origin.
- **Minimal hacks of the official ports**: each port starts from the official port of
  the right commit and changes only what is needed; its Makefile says why it differs.
- **The base of each PHP version**: the ports of its own commit (as
  [`freebsd/targets.conf`](https://github.com/azsupport/php-src/blob/master/freebsd/targets.conf)
  of azsupport/php-src); a port that is not at that commit comes from the ports of the
  nearest higher version that has it, or is written by us:

  | PHP | freebsd-ports |
  |---|---|
  | 5.6 | [`d2c06ef5efae`](https://github.com/freebsd/freebsd-ports/tree/d2c06ef5efae/lang/php56) |
  | 7.4 | [`036685c034ba`](https://github.com/freebsd/freebsd-ports/tree/036685c034ba/lang/php74) |
  | 8.1 | [`6002588334a9`](https://github.com/freebsd/freebsd-ports/tree/6002588334a9/lang/php81) |
  | 8.2 | [`438e512499a9`](https://github.com/freebsd/freebsd-ports/tree/438e512499a9/lang/php82) |
  | 8.3 | [`eb0100f974b6`](https://github.com/freebsd/freebsd-ports/tree/eb0100f974b6/lang/php83) |
  | 8.4 | [`1a235373d266`](https://github.com/freebsd/freebsd-ports/tree/1a235373d266/lang/php84) |

- **The source of PHP**: the release tarballs of the fork
  [azsupport/php-src](https://github.com/azsupport/php-src) (for 7.4:
  [`php-7.4.33-fbsd-20261104-397aa202.tar.xz`](https://github.com/azsupport/php-src/releases/download/freebsd-7.4-20261104-397aa202/php-7.4.33-fbsd-20261104-397aa202.tar.xz)),
  which carry the patches of the FreeBSD port and the PECL extensions in `ext/`: our
  PHP ports apply no patches of their own.
- Now only PHP 7.4 and x86-64-v3: everything is worked out there first, the other
  versions and x86-64-v2 come after.

## The packages

Names and origins as the ports, files at the paths of the ports:

| Package | Origin | What |
|---|---|---|
| `az` | `az/az` | the libraries of the builds in `/usr/local/az`: `lib` (shared, with the run path `/usr/local/az/lib`, no ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`); the static ones in `/usr/local/az/static` for the programs and the special builds of `az-menu.sh`. OpenSSL, zlib and bzip2 are those of the base system |
| `curl` | `ftp/curl` | `bin/curl` and `libcurl.so.4`, in the place of the package of the port |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` and `ffprobe` with only the formats the video sites need |
| `ImageMagick6` | `graphics/ImageMagick6` | ImageMagick 6, the programs with 6 at the end (`convert6`, `identify6`, ...) |
| `ImageMagick7` | `graphics/ImageMagick7` | ImageMagick 7 (`magick`); its `libMagickWand-7.so` in `/usr/local/az/lib` for the module imagick |
| `php74` | `lang/php74` | the core of PHP 7.4: CLI, php-fpm, phpize |
| `mod_php74` | `www/mod_php74` | the Apache module `libphp74.so` |
| `php74-<module>` | `<category>/php74-<module>` | a package per module (`php74-gd`: `graphics/php74-gd`); the PECL ones without "pecl": `php74-redis`, `php74-swoole`, `php74-igbinary`, `php74-memcached`, `php74-memcache`, `php74-imagick`, `php74-mcrypt`, `php74-excimer`, `php74-openswoole`; OPcache and json are modules too (`php74-opcache`, `php74-json`), mysqlnd as well (`php74-mysqlnd`: the database modules use it) |

- openssl in two kinds, one of the two: `php74-openssl` and `php74-openssl-legacy` (the
  legacy provider of OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- `php74-swoole` and `php74-openswoole` can both be installed; the ini of openswoole is
  off (they define the same classes), its package message says how to switch.
- Not built: the modules that need a library of the ports (enchant, imap, ldap, odbc,
  pdf, pdo_dblib, pdo_firebird, pdo_odbc, pdo_pgsql, pgsql, pspell, snmp).
- A special build (a static PHP, the options of a server of its own) is not a port
  here: `az-menu.sh` of [azsupport/php-src](https://github.com/azsupport/php-src) makes it.

## The ports

- **`az/az`**: the package `az`, the libraries of `/usr/local/az`, built from about 40
  official ports of the pinned commit by [`tools/az-build.sh`](tools/az-build.sh)
  ([`az/az/files/deps.conf`](az/az/files/deps.conf)). Two trees:
  `/usr/local/az/static` (static, position independent; for the programs below and the
  static PHP builds of `az-menu.sh`) and `/usr/local/az` (shared, SONAME and run path
  `/usr/local/az/lib`, no ldconfig; for the PHP modules), `bin/pkg-config` of each,
  `VERSIONS` in `share/doc/az`, the licences in `LICENSES/`. It builds into
  `/usr/local/az` of the build machine (as root, `NEED_ROOT`) and packages that tree.
  No dependencies.
- **`ftp/curl`**: the package `curl` in the place of the official one: `bin/curl`
  (static) and `lib/libcurl.so.4` with its libraries inside (only `curl_*` exported),
  the options of the official port, against the static tree of az
  ([`tools/curl-build.sh`](tools/curl-build.sh)).
- **`multimedia/ffmpeg`**: the package `ffmpeg` in the place of the official one:
  `bin/ffmpeg` and `bin/ffprobe`, static, with only what the video sites need
  ([`multimedia/ffmpeg/files/ffmpeg.conf`](multimedia/ffmpeg/files/ffmpeg.conf)),
  against x264, dav1d and libwebp of the static tree of az.
- **`graphics/ImageMagick6`**: `bin/convert6`, `identify6`, `mogrify6`, `composite6`
  and the others, static, next to ImageMagick 7: JPEG, PNG, WebP, GIF, HEIC and AVIF
  only, with our policy.
- **`graphics/ImageMagick7`**: the package `ImageMagick7` in the place of the official
  one: `bin/magick` and its names, static, the same formats and policy; its static
  libraries and `MagickWand-config` in `/usr/local/az/static`, its shared
  `libMagickWand-7.so` in `/usr/local/az/lib` for imagick of PHP. Build and run: az.
- These five: the version of the official port at the pinned commit (or of the take
  line of its conf) with the build stamp as `PORTREVISION`; every distfile in the fetch
  phase; tests after the install: [`tools/ffmpeg-test.sh`](tools/ffmpeg-test.sh),
  [`imagemagick-test.sh`](tools/imagemagick-test.sh), [`curl-test.sh`](tools/curl-test.sh),
  [`az-test.sh`](tools/az-test.sh).
- **`lang/php74`** and **`www/mod_php74`**: the core `php74` and the Apache module
  `libphp74.so`; the core links PCRE2 of the port `devel/pcre2`.
- **59 module ports** `php74-<module>`: the names without "pecl", the origins as the
  official ports or ours (`graphics/php74-gd`, `databases/php-redis`), the ini
  `ext-NN-<module>.ini`, that of openswoole off.

## The layout of PHP on a server

The versions side by side, nothing shared between them:

| | |
|---|---|
| Programs | `bin/php74`, `bin/php-cgi74`, `bin/phpize74`, `bin/php-config74`, `sbin/php-fpm74` |
| Configuration | `etc/php74/`: `php.ini` (from `php.ini-production`, kept when changed), `php.ini-production`, `php.ini-development`, `php-fpm.conf` (pid `/var/run/php-fpm74.pid`, log `/var/log/php-fpm74.log`), `php-fpm.d/www.conf` (`listen /var/run/php-fpm74.sock`, owner and group `www`, mode 0660) |
| Modules | `lib/php/20190902/<module>.so`, loaded by `etc/php74/conf.d/ext-<NN>-<module>.ini` (from its `.ini.sample`, kept when changed; `NN`: 10 OPcache, 18 session, 20 json and a module that needs no other, 30 one that does) |
| Headers | `include/php74/php/...`; those of a module in `include/php74/php/ext/<module>/` |
| Build files | `lib/php74/build` |
| php-fpm | `etc/rc.d/php_fpm74` (`php_fpm74_enable`), so that the php-fpm of several versions run at once |
| Apache | `libexec/apache24/libphp74.so`, `etc/apache24/modules.d/280_mod_php74.conf` |
| Data | `share/php74`, the manual pages with the suffix in `share/man` |

## A server and the repository az

The repository is the files of the release `az-fbsd15-amd64-v3` of this repository
(`az-fbsd15-amd64-v2` for a CPU without AVX2). Its catalog is signed with the key of
aZ; [`keys/az.pub`](keys/az.pub) is its public key (the same key as
[`freebsd/az.pub`](https://github.com/azsupport/php-src/blob/master/freebsd/az.pub) of
azsupport/php-src; SHA-256
`2620217e69f7bf680f4e78d51fd2135bb55dbd8709fa0b78cd217975a801c4e6`).

```sh
mkdir -p /usr/local/etc/pkg/repos /usr/local/etc/pkg/keys
fetch -o /usr/local/etc/pkg/keys/az.pub https://raw.githubusercontent.com/azsupport/ports/main/keys/az.pub
sha256 /usr/local/etc/pkg/keys/az.pub
printf '%s\n' 'az: { url: "https://github.com/azsupport/ports/releases/download/az-fbsd15-amd64-v3", signature_type: "pubkey", pubkey: "/usr/local/etc/pkg/keys/az.pub", priority: 100, enabled: yes }' > /usr/local/etc/pkg/repos/az.conf
pkg update -r az
```

`priority: 100`: for a package both have (`curl`), pkg prefers az to the repository
of FreeBSD. `pkg update -r az` refuses a catalog whose signature does not verify.

PHP 7.4 with its modules:

```sh
pkg install -r az php74 mod_php74 php74-opcache php74-gd php74-mbstring php74-openssl-legacy
```

The programs:

```sh
pkg install -r az curl ffmpeg ImageMagick6 ImageMagick7
```

php-fpm of 7.4:

```sh
sysrc php_fpm74_enable=YES
service php_fpm74 start
```

## How it is built

### tools/build.sh

[`tools/build.sh`](tools/build.sh) builds the packages with the ports framework of
the machine it runs on, as root on FreeBSD: in the FreeBSD 15.1 VM of the workflow,
or on a FreeBSD build server.

```sh
git clone https://github.com/azsupport/ports.git
cd ports
sh tools/build.sh
sh tools/install-php.sh 7.4
sh tools/check-php.sh 7.4
```

Some ports only (with the ports of this tree they need), again also when their
package is there, another level, the ports tree of the build server:

```sh
sh tools/build.sh lang/php74 www/mod_php74
sh tools/build.sh --force lang/php74
env AZ_CPUTYPE=x86-64-v2 sh tools/build.sh
env AZ_PORTSDIR=/usr/ports sh tools/build.sh
```

What it does, with the logic of poudriere:

- the official tree at the pinned commit (git, depth 1) in `work/freebsd-ports`, reused
  when it is at that commit (`AZ_PORTSDIR`: a tree taken as it is, with a warning when
  it is at another commit), this tree as `OVERLAYS` over it;
- `work/make.conf` from [`tools/make.conf.in`](tools/make.conf.in), the make.conf of
  aZ's servers (`CPUTYPE` of the level, `CFLAGS=-O3 -pipe -fno-strict-aliasing`, the
  framework adds `-fstack-protector-strong`; `JPEG_PORT=graphics/mozjpeg`;
  `OPTIONS_UNSET` of X11, Wayland, GUI, DBus, CUPS, debug, tests, documentation and
  manual pages) with the paths of the run, given to make as `__MAKE_CONF`: the
  `/etc/make.conf` of a build server is neither read nor changed, and the options
  saved by `make config` there do not change a build (`PORT_DBDIR` of its own);
- the queue: the ports and the ports of this tree they need (the origins of their
  `*_DEPENDS` that are ours), each after those it needs;
- a port whose origin has a package with the same `az_hash` in the repository is not
  built again (an incremental build; [Versions and rebuilds](#versions-and-rebuilds))
  unless `--force`; a port that fails stops the ports that need it (skipped, with the
  reason);
- each port: the official packages of its dependencies by `pkg install` (the FreeBSD
  repository of the machine), ours by `pkg add` of the packages built before, then
  `make clean package` with `USE_PACKAGE_DEPENDS_ONLY=yes` (nothing is built from
  source but the port itself); its log and its time;
- a `NEED_ROOT` port (`az/az`: it builds into the real `/usr/local/az`): its installed
  package is deleted before its build and the new one added after it;
- the repository (`--repo <dir>`, default `work/repo`): one package per origin, the new
  ones in the place of the old ones, `pkg repo`, signed with the key of
  `AZ_PKG_KEY_FILE` and checked ([`tools/pkg-repo-sign.sh`](tools/pkg-repo-sign.sh));
- the results in `results/`: `summary.txt` (a line per port, `result: OK` or
  `result: FAIL (...)` at the end), `queue.txt`, `hashes.txt`, `logs/`.

### Versions and rebuilds

As poudriere: each port that a run builds gets `AZ_STAMP` (the hour of the start of
the run, `yymmddhh` UTC) as its `PORTREVISION`, so that each build is an upgrade for
pkg (`php74-7.4.33_26110817`), and `AZ_HASH`, which goes into the package as the
annotation `az_hash` (`pkg info -A php74`): the SHA-256 of the files of the port (with
those of its `MASTERDIR`), of the makefiles of `Mk/` of this tree it reads
(`Mk/bsd.overlay.mk`; `Mk/Uses/php.mk` only for the PHP ports), of the official commit,
the level and `tools/make.conf.in`, and of the `az_hash` of each port of this tree it
needs. A port
whose package in the repository has the same `az_hash` is not built again; a change of
a port builds it and every port that needs it again (a change of `az/az`: all that
link it). No revisions bumped by hand.

[`tools/install-php.sh`](tools/install-php.sh) `<version>` installs the PHP packages of
a version from that repository, as a server does (the core, `mod_php74` and the
modules, with `php74-openssl`), and [`tools/check-php.sh`](tools/check-php.sh)
`<version>` checks them (`results/check-php-<version>.txt`).

### The workflow

[`build.yml`](.github/workflows/build.yml), "Build the packages of the repository az":
https://github.com/azsupport/ports/actions/workflows/build.yml, the button
**Run workflow**.

| Input | |
|---|---|
| `release` | the FreeBSD release of the VM, `15.1` |
| `cputype` | `x86-64-v3` (default), `x86-64-v2` or `both` (a job each) |
| `ports` | the ports to build, separated by spaces; empty: all |
| `force` | build them also when their package with the same `az_hash` is in the release already |
| `publish` | publish the repository when everything built and every check passed (off by default: the repository the servers read is published on aZ's word) |

It takes the repository of the last run (an actions/cache, saved also when a run
fails, so that a run that fails in PHP keeps `az` and the libraries) and the files of
the release `az-fbsd15-amd64-<level>`, checks the ports with `make -V` against a sparse
official tree on the runner ([`tools/check-tree.sh`](tools/check-tree.sh), bmake: a
FAIL stops the run there), runs `tools/build.sh` in a FreeBSD VM
([vmactions/freebsd-vm](https://github.com/vmactions/freebsd-vm)), then, for each PHP
version a package of which was built, installs its packages from the new repository and
checks them (`tools/install-php.sh`, `tools/check-php.sh`; a line each in
`results/checks.txt`), reports
([`tools/report.sh`](tools/report.sh): the summary of the run, an annotation per port
that failed; [`tools/runs-report.sh`](tools/runs-report.sh): the report into the
branch `runs` of azsupport/azsupport) and publishes: the packages first, the catalog
last, then away with what the repository has no more. Only a signed catalog is
published.

The secrets (https://github.com/azsupport/ports/settings/secrets/actions, the button
**New repository secret**):

| Secret | |
|---|---|
| `PKG_SIGNING_KEY` | the RSA private key (PEM) of `keys/az.pub`: it goes into the VM as a file only, is used by `pkg repo` and removed |
| `RUNS_TOKEN` | a fine-grained token with Contents read and write on azsupport/azsupport, for the reports |

## The rules of the ports

- A port of this tree starts from the official port of the right commit and changes only
  what is needed; the Makefile says why it differs from the official one.
- Makefiles in the style of the ports tree (tabs, the order of the variables as portlint
  wants); scripts for FreeBSD `/bin/sh` with the base tools.
- A dependency on the package `az` is by a file, never `LIB_DEPENDS` (there are no
  ldconfig hints for `/usr/local/az/lib`):
  `BUILD_DEPENDS+= ${LOCALBASE}/az/lib/libxml2.so:az/az`, and the same in `RUN_DEPENDS`.
- Our ports take `PORTREVISION= ${AZ_STAMP}`: a change of a port is a new build by
  itself ([Versions and rebuilds](#versions-and-rebuilds)).
- Packages built with `make package` in a VM now; [poudriere](https://github.com/freebsd/poudriere)
  later, on a FreeBSD build server: it builds an overlay of its own, and the first part
  of `tools/make.conf.in` is its make.conf.
