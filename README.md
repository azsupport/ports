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
  which carry the patches of the FreeBSD port, the PECL extensions in `ext/` and the
  PCRE2 the fork bundles: our PHP ports apply no patches of their own. What the fork
  adds to PHP: security fixes for every version the same day (the releases of php-src
  for 8.2 to 8.4, Remi Collet's backports for 7.4 and 8.1, and for 5.6 those and its
  own), the patches with which the old versions build and work with the compilers
  and libraries of FreeBSD 15 (GCC 14+, clang 16+, OpenSSL 3, libxml2 2.12+, bison
  3), a built-in OPcache and no extension loading as options
  ([its README](https://github.com/azsupport/php-src#readme)).
- **Faster PHP**: the cores, the Apache modules and the modules in C are built with
  GCC 16, with which the Zend VM keeps its registers in global register variables
  (the clang of the base system has none), and `-fno-semantic-interposition`:
  `Zend/bench.php` and `micro_bench.php` run 33–44% faster with PHP 7.4 than with clang
  19, 36–38% with 8.3 without OPcache (5–15% with its JIT), and mod_php gets as much
  ([the benchmark](https://github.com/azsupport/php-src#benchmark-of-the-builds));
  sqlite3, expat and lcms2 of az with GCC too ([The libraries with
  GCC](#the-libraries-with-gcc)).
- PHP 5.6, 7.4, 8.1, 8.2, 8.3 and 8.4, for x86-64-v3 and x86-64-v2 (a CPU without
  AVX2: the release `az-fbsd15-amd64-v2`).

## The packages

Names and origins as the ports, files at the paths of the ports:

| Package | Origin | What |
|---|---|---|
| `az` | `az/az` | the libraries of the builds in `/usr/local/az`: `lib` (shared, with the run path `/usr/local/az/lib`, no ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`); the static ones in `/usr/local/az/static` for the programs and the special builds of `az-menu.sh`. OpenSSL, zlib and bzip2 are those of the base system |
| `curl` | `ftp/curl` | `bin/curl` and `libcurl.so.4`, in the place of the package of the port, with SCP and SFTP (libssh2) |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` and `ffprobe` with only the formats the video sites need |
| `ImageMagick6` | `graphics/ImageMagick6` | ImageMagick 6, the programs with 6 at the end (`convert6`, `identify6`, ...) |
| `ImageMagick7` | `graphics/ImageMagick7` | ImageMagick 7 (`magick`); its `libMagickWand-7.so` in `/usr/local/az/lib` for the module imagick |
| `mc` | `misc/mc` | Midnight Commander: the editor, the subshell, the charsets, SFTP; GLib and libssh2 inside, zip, 7z, rar and ISO images through `tar` of the base system: no other package |
| `yt-dlp` | `www/yt-dlp` | yt-dlp of a release newer than the official port, with our `ffmpeg` |
| `bash`, `bsddialog`, `bsnmp-ucd`, `portmaster`, `rsync`, `screen`, `sudo`, `unzip`, `wget`, `yamdi`, `zip`, `3proxy` | their official origins | the official ports as they are ([`Mk/az-official.mk`](Mk/az-official.mk)), with the options of aZ in each port's Makefile: `unzip` with ICONV (the Cyrillic names of Windows archives), `wget`, `sudo` and `bash` without NLS, `wget` without IDN, `sudo` without LOGSRVD and SSL, `rsync` without ICONV, `screen` with the ncurses of the base system; no library outside the base system but lz4, xxhash and zstd of `rsync` (official packages) |
| `phpXY` | `lang/phpXY` | the core of PHP X.Y (`XY`: 56, 74, 81, 82, 83, 84): CLI, php-fpm, phpize |
| `mod_phpXY` | `www/mod_phpXY` | the Apache module `libphpXY.so` |
| `phpXY-<module>` | `<category>/phpXY-<module>` | a package per module (`php84-gd`: `graphics/php84-gd`): the modules of the official ports of the commit of the version and the PECL ones the fork bundles, without "pecl": `phpXY-redis`, `phpXY-igbinary`, `phpXY-memcached`, `phpXY-memcache`, `phpXY-imagick`, `phpXY-gmagick`, `phpXY-mcrypt`, `phpXY-ssh2`, from 7.4 on `phpXY-swoole`, `phpXY-openswoole` and `phpXY-excimer`; OPcache is a module too (`phpXY-opcache`), json up to 7.4 (`php74-json`), mysqlnd as well (`phpXY-mysqlnd`: the database modules use it). 59 per version, 61 for 7.4; the list of one: `pkg search -r az '^php84-'` |

- openssl in two kinds, one of the two: `phpXY-openssl` and `phpXY-openssl-legacy` (the
  legacy provider of OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- `phpXY-swoole` and `phpXY-openswoole` can both be installed; the ini of openswoole is
  off (they define the same classes), its package message says how to switch.
- `phpXY-imagick` and `phpXY-gmagick` can both be installed, but must not be loaded into one
  PHP (GraphicsMagick and ImageMagick have the same function names): the ini of gmagick is
  off, and installing it makes the CLI profile gmagick (`/usr/local/etc/php74-gmagick`:
  gmagick on, imagick off; `php74-profile gmagick script.php`), which stays when the
  package is removed.
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
- **`graphics/GraphicsMagick`**: the package `GraphicsMagick` in the place of the official
  one: `bin/gm`, static, built as our ImageMagick, with JPEG, PNG, WebP, GIF, BMP, HEIC and
  AVIF only; with no policy file, the coders it registers and an empty `delegates.mgk` take
  its place (`files/graphicsmagick.conf`). Its static libraries in `/usr/local/az/static`,
  its shared `libGraphicsMagick` and `libGraphicsMagickWand` (symbol prefix `Gm`) and
  `GraphicsMagick-config` in `/usr/local/az`, for gmagick of PHP
  (`--with-gmagick=/usr/local/az`). Build and run: az.
- **`misc/mc`**: the package `mc` in the place of the official one: Midnight Commander
  with the editor, the subshell, the charsets and SFTP, without X11, translations and
  Aspell ([`misc/mc/files/mc.conf`](misc/mc/files/mc.conf): what and why), GLib built
  static by [`tools/mc-build.sh`](tools/mc-build.sh), libssh2 of the static tree of az:
  no package at run time. zip, jar, 7z, rar and ISO images open as a directory with
  [`files/ubsdtar`](misc/mc/files/ubsdtar), on `tar` of the base system (libarchive),
  without Perl, 7-Zip or unrar; Perl, zip and GNU diff give what they give (writing into
  zip, the deb and rpm helpers, `mcdiff`) once they are installed.
- These seven: the version of the official port at the pinned commit (or of the take
  line of its conf) with the build stamp as `PORTREVISION`; every distfile in the fetch
  phase; tests after the install: [`tools/ffmpeg-test.sh`](tools/ffmpeg-test.sh),
  [`imagemagick-test.sh`](tools/imagemagick-test.sh), [`curl-test.sh`](tools/curl-test.sh),
  [`az-test.sh`](tools/az-test.sh), [`mc-test.sh`](tools/mc-test.sh).
- **`www/yt-dlp`**: the package `yt-dlp` in the place of the official one: the official
  port as it is, at a newer release of yt-dlp (the grabbers of the video sites need the
  extractors of the latest), depending on our `multimedia/ffmpeg`; its Python packages are
  the official ones. A new release: `DISTVERSION` and `distinfo` (the size and SHA-256 of
  `yt-dlp.tar.gz`, compared with the `SHA2-256SUMS` of the release, by
  [`distinfo.yml`](.github/workflows/distinfo.yml) when the sandbox cannot fetch it). Tests
  after the install: [`tools/ytdlp-test.sh`](tools/ytdlp-test.sh) (an HLS stream from a
  local server, fixed by our ffmpeg into MP4, as the grabbers download).
- **`lang/phpXY`** and **`www/mod_phpXY`** (5.6, 7.4, 8.1, 8.2, 8.3, 8.4): the core
  `phpXY` and the Apache module `libphpXY.so`, each from the official port of the commit
  of its version (the table above); PCRE2 10.49 is the one the fork bundles (a port
  `devel/pcre2` later, aZ 08.11.2026).
- **The module ports** `phpXY-<module>` (59 per version, 61 for 7.4): the names without
  "pecl", the origins as the official ports or ours (`graphics/php74-gd`,
  `databases/php74-redis`), the ini `ext-NN-<module>.ini`, those of openswoole and
  gmagick off.
- **The compiler of PHP** (every version, aZ 09.11.2026): GCC 16 of the ports
  (`lang/gcc16`) builds the cores, the Apache modules and the modules, a build dependency
  only: no file needs a library of GCC (`-static-libgcc`, the run path `/usr/local/az/lib`
  only). The Zend VM of PHP 7 and later keeps its registers in global register variables
  with GCC, not with clang: the CLI of 7.4 is 33–44% faster than with the base clang 19,
  that of 8.3 36–38% without OPcache and 5–15% with OPcache and its JIT
  ([bench.sh](https://github.com/azsupport/php-src/blob/master/tools/bench.sh) of php-src).
  The modules with C++ (intl, swoole, openswoole) and imagick and gmagick (they link the
  OpenMP runtime of the compiler) keep the base clang. The annotation `az_cc` of each
  package says which (`pkg info -A php74`); [`Mk/Uses/azgcc.mk`](Mk/Uses/azgcc.mk).

## The layout of PHP on a server

The versions side by side, nothing shared between them; for 7.4 (the others the same
with their own number, and the API of their modules: 5.6 `20131226`, 8.1 `20210902`,
8.2 `20220829`, 8.3 `20230831`, 8.4 `20240924`):

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

On a server, as root, [`az-menu.sh`](https://github.com/azsupport/php-src#az-menush-the-packages-and-what-goes-into-php)
of azsupport/php-src writes the repository: x86-64-v3 when `cc -march=native` has AVX2,
BMI2, FMA, F16C, LZCNT and MOVBE, else x86-64-v2; the public key into
`/usr/local/etc/pkg/keys/az.pub`, the repository into
`/usr/local/etc/pkg/repos/az.conf`, then `pkg update -r az`. It says the level it took
and why, and the SHA-256 of the key (the one above):

```sh
fetch https://github.com/azsupport/php-src/releases/download/az-menu/az-menu.sh
sh az-menu.sh --repo
```

The same by hand, for x86-64-v3 (for x86-64-v2: `amd64-v2` in the address); `sha256`
must print the SHA-256 above:

```sh
mkdir -p /usr/local/etc/pkg/repos /usr/local/etc/pkg/keys
fetch -o /usr/local/etc/pkg/keys/az.pub https://raw.githubusercontent.com/azsupport/ports/main/keys/az.pub
sha256 /usr/local/etc/pkg/keys/az.pub
printf '%s\n' 'az: { url: "https://github.com/azsupport/ports/releases/download/az-fbsd15-amd64-v3", signature_type: "pubkey", pubkey: "/usr/local/etc/pkg/keys/az.pub", priority: 100, enabled: yes }' > /usr/local/etc/pkg/repos/az.conf
pkg update -r az
```

`priority: 100`: for a package both have (`curl`), pkg prefers az to the repository
of FreeBSD. `pkg update -r az` refuses a catalog whose signature does not verify.
`ffmpeg`, `ImageMagick6`, `ImageMagick7` and `GraphicsMagick` of az do not have the
shared libraries of the official packages (`libavcodec.so`, `libMagickWand-7.so` in
`/usr/local/lib`, ...): when another package needs them (`pkg info -r ffmpeg`), keep the
official package.

PHP 7.4 with its modules:

```sh
pkg install -r az php74 mod_php74 php74-opcache php74-gd php74-mbstring php74-openssl-legacy
```

PHP 8.3 with its modules (installs side by side with 7.4: its own `etc/php83`, `lib/php/20230831`, `include/php83`):

```sh
pkg install -r az php83 mod_php83 php83-opcache php83-gd php83-mbstring php83-openssl-legacy
```

PHP 8.1 with its modules (side by side as well: `etc/php81`, `lib/php/20210902`, `include/php81`):

```sh
pkg install -r az php81 mod_php81 php81-opcache php81-gd php81-mbstring php81-openssl-legacy
```

PHP 5.6 with its modules (side by side as well: `etc/php56`, `lib/php/20131226`, `include/php56`):

```sh
pkg install -r az php56 mod_php56 php56-opcache php56-gd php56-mbstring php56-openssl-legacy
```

PHP 8.2 with its modules (side by side as well: `etc/php82`, `lib/php/20220829`, `include/php82`):

```sh
pkg install -r az php82 mod_php82 php82-opcache php82-gd php82-mbstring php82-openssl-legacy
```

PHP 8.4 with its modules (side by side as well: `etc/php84`, `lib/php/20240924`, `include/php84`):

```sh
pkg install -r az php84 mod_php84 php84-opcache php84-gd php84-mbstring php84-openssl-legacy
```

The programs:

```sh
pkg install -r az curl ffmpeg ImageMagick6 ImageMagick7 mc
```

yt-dlp without `-r az`: its Python packages are in the repository of FreeBSD, and pkg
takes `yt-dlp` of az by `priority: 100`:

```sh
pkg install yt-dlp
```

The nonfree FFmpeg: `ffmpeg-nonfree` (multimedia/ffmpeg with the AAC encoder
`libfdk_aac`, for the formats of old sites with `-c:a libfdk_aac`) may not be given to
anyone (FFmpeg with `--enable-nonfree`), so it is never in the release. The workflow
[`ffmpeg-nonfree.yml`](.github/workflows/ffmpeg-nonfree.yml) builds it from
[`nonfree/ffmpeg/Makefile.in`](nonfree/ffmpeg/Makefile.in) and copies it with scp to
`pkg.azsupport.com`, a repository of pkg of its own behind a password (HTTP Basic auth),
signed with the same key. A server reads it next to az (the password of the user `pkg`
in the address; the file only for root):

```sh
printf '%s\n' 'az-nonfree: { url: "https://pkg:PASSWORD@pkg.azsupport.com/az-nonfree/fbsd15-amd64-v3", signature_type: "pubkey", pubkey: "/usr/local/etc/pkg/keys/az.pub", priority: 100, enabled: yes }' > /usr/local/etc/pkg/repos/az-nonfree.conf
chmod 600 /usr/local/etc/pkg/repos/az-nonfree.conf
pkg update -r az-nonfree
pkg install -r az-nonfree ffmpeg-nonfree
```

`ffmpeg-nonfree` takes the place of `ffmpeg` (the same files: pkg removes `ffmpeg`).

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
env AZ_JOBS=1 sh tools/build.sh
env AZ_DRYRUN=1 sh tools/build.sh
env AZ_CONFIGURE_CHECK=1 sh tools/build.sh --force
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
- up to `AZ_JOBS` ports at once (default 4), in waves: the ports whose ports of this
  tree they need are done form a wave; the dependencies of its ports are installed
  first, one port after another (a port whose installation takes away what a port
  before it in the wave got goes to a later wave), then their `make package` run at
  once with no `pkg add`, `pkg install` or `pkg delete` meanwhile, the biggest first,
  each with its log and its own packages directory; the summary in the order of the
  queue; `results/waves.txt`. `AZ_JOBS=1`: one port after another, as before;
  `AZ_DRYRUN=1`: the waves of the run said, nothing built;
- a `NEED_ROOT` port (`az/az`: it builds into the real `/usr/local/az`): alone, its
  installed package is deleted before its build and the new one added after it;
- `AZ_CONFIGURE_CHECK=1`, the configure check: after the build of each PHP port (the
  cores, `mod_phpXY`, every module, the PECL ones and those of clang too), also when
  the build fails after its configure, `make configure` once more in a work directory
  of its own, with the same compiler and the errors of C of GCC 14+ and clang 16+ as
  warnings (`-Wno-error=implicit-function-declaration` and the like, as many as the
  compiler knows, in `CFLAGS_<arch>`, which the framework appends to the `CFLAGS` of
  the port: nothing of `Mk/` or of a hash changes), and
  [`tools/configure-check.sh`](tools/configure-check.sh) compares the two: the result
  of each `checking` of `config.log` (with the error of the compiler of the test in
  the strict one), `main/php_config.h` or the `config.h` of a module, the variables of
  the generated `Makefile`. A difference is a test of configure whose result depends
  on those errors (printf without `<stdio.h>` in the test "if using GNU libiconv" of
  `ext/iconv`: `php74-iconv` without `-liconv` and `ICONV_SUPPORTS_ERRNO`), the
  package has the strict result; `results/configure-check.txt` and a section of the
  report; the ports a run keeps from the repository are not configured (`--force`:
  every PHP port);
- the repository (`--repo <dir>`, default `work/repo`): one package per origin, the new
  ones in the place of the old ones, `pkg repo`, signed with the key of
  `AZ_PKG_KEY_FILE` and checked ([`tools/pkg-repo-sign.sh`](tools/pkg-repo-sign.sh));
- the results in `results/`: `summary.txt` (a line per port, `result: OK` or
  `result: FAIL (...)` at the end), `queue.txt`, `hashes.txt`, `waves.txt`, `logs/`,
  `configure-check.txt` (`AZ_CONFIGURE_CHECK`).

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
link it). The files a port lists in `AZ_HASH_NOT_FOR_DEPENDENTS` (installed and used
at run time only) count in its own `az_hash` but not in that of the ports that need it
or of its slaves: a change of the php.ini block, the profile script, the rc.d script or
the pkg-message of `lang/php74` builds `php74` again, not the modules and `mod_php74`
(pkg takes a dependency by its name, not its version). No revisions bumped by hand.

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
| `cputype` | `x86-64-v3` (default), `x86-64-v2` or `both` (a job each); one job of a level and a branch at a time, the levels side by side (each has its own release and cache) |
| `ports` | the ports to build, separated by spaces; empty: all |
| `force` | build them also when their package with the same `az_hash` is in the release already |
| `jobs` | the ports built at once (`AZ_JOBS`, default 4; `1`: one after another) |
| `configure_check` | the configure check (`AZ_CONFIGURE_CHECK`, off by default): each PHP port built configured once more, permissive, and compared; with `force` every PHP port |
| `publish` | publish the repository when everything built and every check passed (off by default: the repository the servers read is published on aZ's word) |

It takes the repository of the last run (an actions/cache, saved also when a run
fails, so that a run that fails in PHP keeps `az` and the libraries) and the files of
the release `az-fbsd15-amd64-<level>`, checks the ports with `make -V` against a sparse
official tree on the runner ([`tools/check-tree.sh`](tools/check-tree.sh), bmake: a
FAIL stops the run there), compares the curl of az with that of the PHP of
azsupport/php-src ([`tools/curl-sync-check.sh`](tools/curl-sync-check.sh): the data
lines of `az/az/files/curl.conf` and `curl-deps.conf` and the patches of `curl/` against
those of `freebsd/` on its master; a difference stops the run there too), runs
`tools/build.sh` in a FreeBSD VM
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

### The libraries with GCC

[`lib-bench.yml`](.github/workflows/lib-bench.yml), "Libraries of az with the base clang and
with GCC 16": https://github.com/azsupport/ports/actions/workflows/lib-bench.yml, the button
**Run workflow**.

| Input | |
|---|---|
| `repeat` | the rounds, default 9 (a verdict needs at least 7) |
| `libs` | the libraries, separated by spaces; empty: all |

Would the C libraries of `az` make PHP faster built with gcc16 of the packages instead of
the base clang 19? (aZ 09.11.2026: a library goes to GCC 16 when it is at least 2% faster
through what the sites do.) Measured: libxml2, libxslt, oniguruma, sqlite3, gd, freetype2,
png, mozjpeg, expat, libzip and lcms2; not those with assembly or SIMD of their own (zstd,
brotli, lz4, webp, dav1d, x264, OpenSSL, libsodium, gmp), the C++ ones (ICU, libheif,
libde265, libmemcached), ImageMagick and GraphicsMagick (OpenMP). In a FreeBSD 15.1 VM
([`tools/lib-bench.sh`](tools/lib-bench.sh)): PHP 8.3 and its modules from the repository
az, each library built as `tools/az-build.sh` builds it (the source and patches of its
port at the commit of `deps.conf`, its options, the CFLAGS of az) three times: with clang19,
with gcc16 as it would be shipped (`-std=gnu17 -static-libgcc -fno-semantic-interposition`)
and with gcc16-si, the same without `-fno-semantic-interposition` (GCC's default for
`-fPIC`: the exported functions of a library are not inlined in it), then the benchmarks of
[`tools/lib-bench.php`](tools/lib-bench.php) (DOM, SimpleXML, XMLReader, ext/xml, XSL,
`mb_ereg*`, SQLite3 and PDO, GD JPEG, PNG, resampling and TrueType, ZipArchive) and of the
programs (xmllint, speedtest1, cjpeg, djpeg, the drivers of
[`tools/lib-bench.c`](tools/lib-bench.c) for expat and lcms2): each run with one build of
one library in front of that of az (`LD_LIBRARY_PATH`, proved with ldd and the files the
process maps), the library of the release as the control; runs of about 3 seconds, the
variants interleaved, pinned to one CPU. The report (the log of the step Report, the job
summary, the branch `runs` of azsupport/azsupport): per library and benchmark the median
seconds of each variant, the change of gcc16 and of gcc16-si against clang19 with its
interval of about 95%, the spread, and per library the verdict of gcc16 ">= 2% faster". It
publishes nothing.

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
