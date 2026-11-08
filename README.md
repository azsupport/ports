# azsupport/ports

FreeBSD ports of aZ (azsupport.com): an overlay of the FreeBSD ports tree, from
which the packages of his pkg repository **az** are built for his FreeBSD 15
servers (amd64), so that nothing is built on the servers.
[README.ru.md](README.ru.md): the same in Russian.

- [What it is](#what-it-is)
- [The packages](#the-packages)
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
  which carry the patches of the FreeBSD port, the PECL extensions in `ext/` and the
  PCRE2 the fork bundles: our PHP ports apply no patches of their own.
- Now only PHP 7.4 and x86-64-v3: everything is worked out there first, the other
  versions and x86-64-v2 come after.

## The packages

Names and origins as the ports, files at the paths of the ports:

| Package | Origin | What |
|---|---|---|
| `az` | `az/az` | the libraries of the builds in `/usr/local/az`: `lib` (shared, with the run path `/usr/local/az/lib`, no ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`); the static ones in `/usr/local/az/static` for the static PHP and the programs. OpenSSL, zlib and bzip2 are those of the base system |
| `curl` | `ftp/curl` | `bin/curl` and `libcurl.so.4`, in the place of the package of the port |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` and `ffprobe` with only the formats the video sites need |
| `ImageMagick6` | `graphics/ImageMagick6` | ImageMagick 6, the programs with 6 at the end (`convert6`, `identify6`, ...) |
| `ImageMagick7` | `graphics/ImageMagick7` | ImageMagick 7 (`magick`); its `libMagickWand-7.so` in `/usr/local/az/lib` for the module imagick |
| `php74` | `lang/php74` | the core of PHP 7.4: CLI, php-fpm, phpize |
| `mod_php74` | `www/mod_php74` | the Apache module `libphp74.so` |
| `php74-<module>` | `<category>/php74-<module>` | a package per module (`php74-gd`: `graphics/php74-gd`); the PECL ones without "pecl": `php74-redis`, `php74-swoole`, `php74-igbinary`, `php74-memcached`, `php74-memcache`, `php74-imagick`, `php74-mcrypt`, `php74-excimer`, `php74-openswoole`; OPcache and json are modules too (`php74-opcache`, `php74-json`), mysqlnd as well (`php74-mysqlnd`: the database modules use it) |
| `php74-static` | `lang/php74-static` | the static PHP: the files of `php74`, `mod_php74` and the modules in one build; one or the other per version |

- openssl in two kinds, one of the two: `php74-openssl` and `php74-openssl-legacy` (the
  legacy provider of OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- `php74-swoole` and `php74-openswoole` can both be installed; the ini of openswoole is
  off (they define the same classes), its package message says how to switch.
- Not built: the modules that need a library of the ports (enchant, imap, ldap, odbc,
  pdf, pdo_dblib, pdo_firebird, pdo_odbc, pdo_pgsql, pgsql, pspell, snmp).

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

PHP 7.4 with its modules, or the static one:

```sh
pkg install -r az php74 mod_php74 php74-opcache php74-gd php74-mbstring php74-openssl-legacy
pkg install -r az php74-static
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
sh tools/install-php.sh 7.4 pkg
sh tools/check-php.sh 7.4 pkg
sh tools/install-php.sh 7.4 static
sh tools/check-php.sh 7.4 static
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
  `*_DEPENDS` that are ours), each after those it needs; a port that conflicts with the
  packages of others (`CONFLICTS_INSTALL`: `php74-static`) last;
- a port whose package (`PKGNAME`) is in the repository already is not built again
  (an incremental build) unless `--force` or a port of this tree it needs was built in
  the run; a port that fails stops the ports that need it (skipped, with the reason);
- each port: the official packages of its dependencies by `pkg install` (the FreeBSD
  repository of the machine), ours by `pkg add` of the packages built before, then
  `make clean package` with `USE_PACKAGE_DEPENDS_ONLY=yes` (nothing is built from
  source but the port itself); its log and its time;
- the repository (`--repo <dir>`, default `work/repo`): the new packages in the place
  of the old ones of the same name, `pkg repo`, signed with the key of
  `AZ_PKG_KEY_FILE` and checked ([`tools/pkg-repo-sign.sh`](tools/pkg-repo-sign.sh));
- the results in `results/`: `summary.txt` (a line per port, `result: OK` or
  `result: FAIL (...)` at the end), `queue.txt`, `logs/`.

[`tools/install-php.sh`](tools/install-php.sh) `<version> pkg|static` installs the PHP
packages of a version in one mode from that repository, as a server does (`pkg`: the
core, `mod_php74` and the modules, with `php74-openssl`; `static`: `php74-static`; the
packages of the other mode are deleted first, they have the same files), and
[`tools/check-php.sh`](tools/check-php.sh) `<version> pkg|static` checks the installed
packages of that mode (`results/check-php-<version>-<mode>.txt`).

### The workflow

[`build.yml`](.github/workflows/build.yml), "Build the packages of the repository az":
https://github.com/azsupport/ports/actions/workflows/build.yml, the button
**Run workflow**.

| Input | |
|---|---|
| `release` | the FreeBSD release of the VM, `15.1` |
| `cputype` | `x86-64-v3` (default), `x86-64-v2` or `both` (a job each) |
| `ports` | the ports to build, separated by spaces; empty: all |
| `force` | build them also when their package is in the release already |
| `publish` | publish the repository when everything built and every check passed (off by default: the repository the servers read is published on aZ's word) |

It downloads the files of the release `az-fbsd15-amd64-<level>` (the packages built
before), runs `tools/build.sh` in a FreeBSD VM
([vmactions/freebsd-vm](https://github.com/vmactions/freebsd-vm)), then, for each PHP
version a package of which was built, installs and checks each mode, `pkg` first, then
`static` (`tools/install-php.sh`, `tools/check-php.sh`; a line each in
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
- A new build of a port whose package is in the release: a new `PORTVERSION` or
  `PORTREVISION` (or `force`); the builder does not build a package that is there.
- Packages built with `make package` in a VM now; [poudriere](https://github.com/freebsd/poudriere)
  later, on a FreeBSD build server: it builds an overlay of its own, and the first part
  of `tools/make.conf.in` is its make.conf.
