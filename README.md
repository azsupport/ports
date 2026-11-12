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
  [`9a69436ea72f`](https://github.com/freebsd/freebsd-ports/tree/9a69436ea72fbfab0e73e3f14d81ed3ef6322251)
  (main of 12.11.2026; `ports_commit` in [`tools/build.sh`](tools/build.sh), moved to the
  latest main before a build: the latest versions of the ports, aZ). The ports
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
| `az` | `az/az` | the libraries of the builds in `/usr/local/az`: `lib` (shared, with the run path `/usr/local/az/lib`, no ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`), which every package links; the static ones in `/usr/local/az/static` only for the special builds of `az-menu.sh`. OpenSSL, zlib and bzip2 are those of the base system |
| `curl` | `ftp/curl` | `bin/curl` and `libcurl.so.4`, in the place of the package of the port, with SCP and SFTP (libssh2); its `libcurl.so.4` is the libcurl of every package (the PHP module curl, git) |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` and `ffprobe` with only the formats the video sites need |
| `ImageMagick6` | `graphics/ImageMagick6` | ImageMagick 6, the programs with 6 at the end (`convert6`, `identify6`, ...); its libraries in `/usr/local/az/lib` |
| `ImageMagick7` | `graphics/ImageMagick7` | ImageMagick 7 (`magick`); its `libMagickCore-7.so` and `libMagickWand-7.so` in `/usr/local/az/lib`, which `magick` and the module imagick link |
| `GraphicsMagick` | `graphics/GraphicsMagick` | GraphicsMagick (`gm`) with the formats of our ImageMagick; its libraries in `/usr/local/az/lib`, which `gm` and the module gmagick link |
| `mc` | `misc/mc` | Midnight Commander: the editor, the subshell, the charsets, SFTP; GLib of `glib`, libssh2 of az, PCRE2 of `pcre2`; zip, 7z, rar and ISO images through `tar` of the base system (the names of a zip of Windows in CP866); fixes of mc after 4.8.33 ([`misc/mc/files/*.patch`](misc/mc/files), each with its source): the overflow of `%cd` with a long name in an archive, Reget spoiling the next files of a copy, the mouse with `TERM=xterm` (Gentoo) and a crash of a drag, the exit of the subshell on FreeBSD (NetBSD), the prompt of tcsh kept, a prompt with bytes not UTF-8, the descriptor of the subshell's pipe (Debian), "ls -l" lines with names of one byte (Alpine), ftp: reconnect after an idle timeout, the password of `~/.netrc`; copies that clone the blocks on ZFS (`copy_file_range`, upstream #5082); ours: none of mc's own lines (its cd, its init, the user menu) in the history of a tcsh subshell |
| `pcre2`, `pcre` | `devel/pcre2`, `devel/pcre` | PCRE2 10.49 and PCRE 8.45, the official ports: the PCRE of every package (PHP, Apache, git, wget, mc, MariaDB; nginx later) |
| `git` | `devel/git` | git without Perl, Python, Tcl/Tk, gettext, the manual pages and git daemon; HTTPS through our `curl`, `git grep -P` with `pcre2` |
| `apache24`, `ap24-mod_maxminddb` | `www/apache24`, `www/mod_maxminddb` | Apache 2.4 with prefork only and the modules of the servers (cgi and env too), no SSL; APR and libmaxminddb of az |
| `memcached`, `memcached-openssl` | `databases/memcached`, `databases/memcached-openssl` | memcached without TLS, SASL and DTrace, libevent of az; the variant with TLS; one of the two |
| `mariadb1011-server`, `mariadb1011-client` | `databases/mariadb1011-server`, `databases/mariadb1011-client` | MariaDB 10.11: of the engines of the options InnoDB only, no GSSAPI; the socket `/tmp/mysql.sock` compiled in and in `my.cnf` |
| `vsftpd-ext`, `vsftpd-ext-openssl` | `ftp/vsftpd-ext`, `ftp/vsftpd-ext-openssl` | vsftpd-ext with its rc.d script, the fix of CVE-2021-3618 (ALPACA) of vsftpd 3.0.5 and ours of CVE-2026-119567, CVE-2026-119568 and `deny_file`; the variant with SSL; one of the two |
| `3proxy`, `3proxy-openssl` | `net/3proxy`, `net/3proxy-openssl` | 3proxy 0.9.9.3 of the LTS line, ahead of the official 0.9.5 for its security fixes, with the names and paths of the official port; PAM, PCRE2 of `pcre2`, no TLS; the variant with TLS; one of the two |
| `bind920`, `bind-tools` | `dns/bind920`, `dns/bind-tools` | BIND 9.20: the DNS server `named` with TCP Fast Open, no GSSAPI, DNSTAP, LMDB and statistics channels; dig, host, nslookup, delv, nsupdate and the DNSSEC tools, with IDN |
| `vips` | `graphics/vips` | libvips 8.18 for the Lua scripts of nginx that convert images on the fly: JPEG (mozjpeg), PNG, WebP, HEIC (load), AVIF (load and save), GIF, with ICC profiles, EXIF and SIMD (Highway); `vips`, `vipsthumbnail`, `vipsheader`, `vipsedit` |
| `glib`, `libexif`, `cgif`, `libimagequant`, `highway` | `devel/glib20`, `graphics/libexif`, `graphics/cgif`, `graphics/libimagequant`, `devel/highway` | the libraries of `vips` (GLib of `mc` too, libimagequant of the libgd of az too: LIQ, the palette of `imagegif()` and `imagetruecolortopalette()` of PHP 5.6 to 8.4; GPLv3 or later): GLib 2.88 shared, without introspection, NLS, documents and manual pages, on libffi, libintl and libiconv of az and PCRE2 of `pcre2`; the others the official ports as they are (libexif without NLS) |
| `qt-faststart` | `multimedia/qt-faststart` | qt-faststart (the moov atom of an MP4 first), back for compatibility: the official port expired on 30.06.2022 |
| `yt-dlp` | `www/yt-dlp` | yt-dlp at the latest release of GitHub, not at the version of the official port (aZ, 12.11.2026): [`yt-dlp-update.yml`](.github/workflows/yt-dlp-update.yml) looks every 6 hours, takes a new release into the port by itself (and its `yt-dlp-ejs`, ours when the official port is behind), builds it and publishes it when nothing else differs from the release ([yt-dlp from GitHub](#yt-dlp-from-github)); with our `ffmpeg` |
| `node24`, `npm-node24`, `yarn-node24`, `corepack-node24` | `www/node24`, `www/npm-node24`, `www/yarn-node24`, `www/corepack-node24` | Node.js 24.22.3 (for yt-dlp and Kibana 6; the security release of 11.11.2026, ahead of the official port at 24.22.2) with npm, Yarn 1 and corepack: `node` on brotli, c-ares, ICU, nghttp2, libuv, zstd and SQLite of az, the OpenSSL (with the CA store of the base system) and zlib of the base system and the libraries below; no DTrace; npm and Yarn the official ports as they are, corepack ours (corepack-node24: 0.36 runs on Node 22 and 24 only, Node 18 gets corepack-node18; one of the two) |
| `node18`, `npm-node18`, `yarn-node18`, `corepack-node18` | `www/node18`, `www/npm-node18`, `www/yarn-node18`, `www/corepack-node18` | Node.js 18.20.8, the last 18.x (end of life since 30.04.2025), for a legacy project, back in the ports (the official port went on 2025-09-03), with npm 10.9.10 and corepack 0.33.0 (the last ones for Node 18) and Yarn 1.22.19 (that of `yarn-node24`): `node` on brotli, c-ares, ICU, nghttp2 and libuv of az, llhttp 9.4.3 of `www/llhttp` and the OpenSSL and zlib of the base system; the fixes of the vulnerabilities after the end of life as SUSE carries them for its nodejs18 18.20.8 (SLE 15 SP4 LTSS; with llhttp 9) and, backported, those of the Node.js 22 and 24 security releases of October and November 2026 (dns, http.Agent, tls.checkServerIdentity, https.Agent, zlib, crypto in startup snapshots; the fixes of the TLS and HTTP/2 code, for servers too; the eMudhra/emSign intermediates of compromised keys refused in every chain), with undici 6.29.1 of Node.js 22.23.4 in the place of 5.29.0 (the list, and what is left out and why, in `www/node18/Makefile`); one of `node18` and `node24`, with their npm, yarn and corepack (`pkg install node18 npm-node18 yarn-node18` takes those of node24 away; not with `kibana6`, which needs node24) |
| `libada`, `llhttp`, `nbytes`, `libnghttp3`, `libngtcp2`, `simdjson`, `uvwasi`, `hdr_histogram` | `devel/libada`, `www/llhttp`, `www/nbytes`, `www/libnghttp3`, `net/libngtcp2`, `devel/simdjson`, `devel/uvwasi`, `graphics/hdr_histogram` | the libraries that Node.js bundles, as ports of this tree (aZ, 11.11.2026): the official ports as they are, `uvwasi` ours on the libuv of az |
| `python312`, `py312-sqlite3`, `mpdecimal`, `python3` | `lang/python312`, `databases/py-sqlite3`, `math/mpdecimal`, `lang/python3` | Python 3.12, the default Python of the ports tree, under the names of the official packages (aZ, 11.11.2026), so that the `py312-*` packages of the FreeBSD repository (those of yt-dlp) install over it and use it: the options of the official package (LTO, PYMALLOC, IPV6, NLS), libffi, expat, readline and libintl of az, OpenSSL, ncurses, zlib, bzip2 and liblzma of the base system, libmpdec of `mpdecimal` (the official port as it is); its module sqlite3, `py312-sqlite3`, on the SQLite of az; no gdbm and tkinter; `python3` the official meta port as it is (`bin/python3` and the other links to Python 3.12) |
| `elasticsearch6` | `textproc/elasticsearch6` | Elasticsearch 6.8.23, the last 6.x, for the legacy sites, back in the ports (the official port went on 2023-01-01, at 6.8.16): its rc script with profiles; on our OpenJDK 21 (`java/openjdk21`; aZ, 12.11.2026: one JDK with OpenSearch; `-Djava.security.manager=allow` in `jvm.options`, without which JDK 18 and later refuse its Security Manager), the four lines of the warning of the JDK about `System::setSecurityManager` and the two about the COMPAT locale provider taken out of its start; without ML; the error files of a crash of the JVM in `/var/log/elasticsearch`; no writes of no use (aZ, 11.11.2026): no heap dump at an OutOfMemoryError, no GC log, nothing in `/tmp` but the one `/tmp/elasticsearch` (no `hsperfdata`; its temporary directory, `elasticsearch_tmpdir` of `rc.conf`, made anew at each start), no archives of old logs (the log files of Elastic's `log4j2.properties` as they are, each rolled at its size alone and the rolled file deleted at once: no dated files, no `.gz`); `xpack.ssl.cipher_suites` without the four suites OpenJDK 17 and 21 no longer have (no `[ERROR]` about unsupported ciphers at start); `jvm.options` for OpenJDK 17 and later, one file for every server (`-XX:UseAVX=2` for JDK 10 alone: on JDK 17 it warned at every start on a CPU without AVX2; `-XX:+ExitOnOutOfMemoryError`; each change with its source in the file); the heap of a server is `elasticsearch_heap="4g"` in `rc.conf` (`-Xms` and `-Xmx`), without it the 31g of `jvm.options` (below the cutoff of compressed oops; for a server with 64 GB of RAM and more: with less set `elasticsearch_heap`, at most half of the RAM); its tools run by hand (`elasticsearch-keystore`, `elasticsearch-plugin` and the others) leave nothing in `/tmp` either; licences: the default distribution with X-Pack, so Apache 2.0 and the Elastic License 1.0 (its `LICENSE.txt`), which allows the use at no charge and no redistribution |
| `kibana6` | `textproc/kibana6` | Kibana 6.8.23, the last 6.x, for the legacy sites with `elasticsearch6`, back in the ports (the official port went on 2022-03-31, at 6.8.16, with Node.js 10): on our `node24`, with what it needs of Node.js 10 put back (`util.is*` and `util.log`, the MD4 of webpack 4 as MD5, a rejected promise nothing handles a warning, the IPv4 address of `localhost` first), the fixes of hapi for Node.js 11 and 16 in its hapi 17, and `re2` (Timelion's labels) as node-re2 1.27.1 built for this Node.js, with the RE2 2025-11-05 and abseil 20260817.0 it vendors compiled in (a node-re2 that vendors others stops the build); its rc script with daemon(8), as the user www, `reload` for the log; without Machine Learning and Reporting (no Chromium or PhantomJS for FreeBSD), the bundles of the browser built in the build for that set of plugins; licences: the default distribution with X-Pack, so Apache 2.0 and the Elastic License 1.0 (its `LICENSE.txt`), which allows the use at no charge and no redistribution |
| `opensearch217` | `textproc/opensearch217` | OpenSearch 2.17.1, the last 2.17.x (2.17.2 was never released), for a legacy project: the bundle of OpenSearch that the official `textproc/opensearch` installed at 2.17.1 (the branch 2025Q1 of freebsd-ports), with its rc script with profiles, on OpenJDK 21 of ours (`java/openjdk21`, the JDK of its bundle and of 3.x; aZ, 12.11.2026) and the JNA of `devel/jna` (its library from `lib/jna`, nothing unpacked at a start); without `opensearch-security` (aZ, 12.11.2026: no TLS and no passwords; the rc script refuses a start with a `plugins.security.*` setting in `opensearch.yml`, such as `plugins.security.disabled: true`, and names its lines) and without the plugins that cannot run on FreeBSD or need one that cannot: k-NN (its engines are native code of Linux), Neural Search, Performance Analyzer (the other 19 plugins of the bundle and every module are in, as on aZ's cluster of 2.17.1, so that a node of this package can take the place of one of his; ML Commons runs its remote models only: its local ones need native code of Linux, and the two jars of that code, ONNX Runtime with CUDA and the tokenizers of DJL, 309 of the 357 MiB of the plugin, are left out: aZ, 12.11.2026); the jars of the bundle as they are; the decisions of `elasticsearch6`: the heap is `opensearch_heap` of `rc.conf`, without it the 31g of `jvm.options`, no heap dump, no GC log, nothing in `/tmp` but `/tmp/opensearch` (`opensearch_tmpdir`, made anew at each start), no archives of old logs, the warnings JDK 21 prints at each start for what OpenSearch sets itself taken out (`System::setSecurityManager`, the incubator module `jdk.incubator.vector`, the COMPAT locale provider); its tools run by hand without `JAVA_HOME` and leave nothing in `/tmp`; the paths of the official port, `/var/db/opensearch` and `/var/log/opensearch` |
| `opensearch219` | `textproc/opensearch219` | OpenSearch 2.19.7, in the place of the official `textproc/opensearch219` and ahead of it (2.19.6 in freebsd-ports, 12.11.2026), for the migration of aZ's cluster of 2.17.1 to 3.x (aZ, 12.11.2026: 3.x upgrades from 2.19 alone): his sites give the text of their visitors to `query_string`, and up to 2.19.6 a `query_string` with deeply nested parentheses overflows the stack of Lucene's parser and halts the node, which 2.19.7 prevents (`search.query.max_query_nesting_depth`, 200; CVE-2025-9624, a `query_string` of nested clauses, is fixed since 2.19.4 by `search.query.max_query_string_length`, 32000), with the other fixes of 2.19.7 listed in the header of its Makefile; on OpenJDK 21 of ours (`java/openjdk21`: the JDK of its bundle and the least of 3.x; 2.x does not run on JDK 24 and later, which refuse its Security Manager) and the JNA of `devel/jna`; every decision of `opensearch217`: without `opensearch-security` (the rc script refuses a `plugins.security.*` setting), k-NN, Neural Search and Performance Analyzer, `opensearch-ml` without its two jars of native code, the other plugins of the bundle and every module in, and Learning to Rank (`opensearch-ltr`, the one plugin of the bundle of 2.19 that 2.17.1 lacks: Java); the jars of the bundle as they are; the heap `opensearch_heap` of `rc.conf` or the 31g of `jvm.options`; nothing written that is of no use, and the warnings JDK 21 prints at each start for what OpenSearch sets itself taken out; the tools without `JAVA_HOME`; the paths `/var/db/opensearch` and `/var/log/opensearch`; the prepackaged rules of Security Analytics, which 2.19 reads from the directory of the configuration, in `/usr/local/etc/opensearch/opensearch-security-analytics` (the official port leaves them out); `pkg install opensearch219` takes the place of `opensearch217` on its data ([`tools/opensearch-upgrade-test.sh`](tools/opensearch-upgrade-test.sh): aZ's node ko44, of the cluster manager alone, and a data node of 2.17.1 come up as 2.19.7 with their indices, documents and objects of the plugins; of his cluster settings the five exporters of query-insights per metric of 2.17, which 2.19 does not have (it has one exporter of all), become `archived.*`, the rest is kept, and on a new cluster of 2.19 they are refused as not recognized; a cluster of a node of each version) |
| `opensearch-dashboards217` | `textproc/opensearch-dashboards217` | OpenSearch Dashboards 2.17.1, the last 2.17.x (2.17.2 was never released), for a legacy project with `opensearch217`: the bundle of the official port of 2.17.1 (branch 2025Q1) on our `node18`, the Node.js line of 2.17.1 (one of `node18` and `node24`: not with `kibana6`), without its Node.js for Linux, the only ELF files of the bundle (no native module: nothing built); 13 plugins, without `securityDashboards` (`opensearch217` has no security plugin: OpenSearch over plain http without credentials), `reportsDashboards` in (no Chromium in 2.17.1: CSV and XLSX made by the server, PDF and PNG by the browser); its rc script with daemon(8), as the user www, refuses a configuration with a setting of a plugin it does not have (`opensearch_security.*`), reads `node.options`, `reload` for the log, which newsyslog rolls at 10 MB without archives; the commits of the 2.17 branch after 2.17.1 that fit a binary build, and the security fixes after 2.17.1 that touch it (the DoS of `/api/core/capabilities`, CVE-2026-75897; redirects off-site; `__proto__` in imports; `@hapi/content`, `@hapi/inert`, js-yaml 3.15.2): the list, and what is not taken and why, in `textproc/opensearch-dashboards217/Makefile` |
| `perl5` | `lang/perl5.42` | Perl 5.42 under the name of FreeBSD's (aZ, 11.11.2026), so that the `p5-*` packages of the FreeBSD repository work with it: the official port as it is (threads, MULTIPLICITY, 64-bit integers, the shared libperl), without DTrace, as every build here (its probes are in the core of Perl only: the XS modules of FreeBSD's packages load and run with it, [`tools/perl-test.sh`](tools/perl-test.sh)) |
| `openjdk21`, `jna`, `apache-ant` | `java/openjdk21`, `devel/jna`, `devel/apache-ant` | the JDK of `elasticsearch6`, `opensearch217` and `opensearch219`, and of OpenSearch 3.x later, ours (aZ, 11.11.2026: so that a server with Elasticsearch gets nothing of a desktop; 12.11.2026: one JDK for them all: OpenSearch 2.x and Elasticsearch 6 do not run on JDK 24 and later, where the Security Manager is disabled for good, and OpenSearch 3.x needs 21 at least): OpenJDK 21 headless in `/usr/local/openjdk21`, without X11, sound, fonts and javavmwrapper (no `/usr/local/bin/java`), on the libjpeg, FreeType and Little CMS of az; JNA without X11 and JAWT, on the libffi of az, its library also as `/usr/local/lib/jna/libjnidispatch.so`, which `elasticsearch6`, `opensearch217` and `opensearch219` load (`-Djna.boot.library.path`, `-Djna.nounpack`: nothing unpacked at a start), built on 21 for Java 8; Ant, the official port, on our JDK 21, to build JNA (aZ, 12.11.2026: JNA and Ant on 21). `openjdk21` and `jna` need `az` only |
| `bash`, `bsddialog`, `bsnmp-ucd`, `portmaster`, `rsync`, `screen`, `sudo`, `unzip`, `wget`, `yamdi`, `zip` | their official origins | the utilities of the servers: the official ports as they are ([`Mk/az-official.mk`](Mk/az-official.mk)) with the options of aZ in each port's Makefile (`unzip` with ICONV: the Cyrillic names of Windows archives, and the fixes of the vulnerabilities the official port lacks, from Fedora: CVE-2014-8141 … CVE-2022-0530, zip bombs, and from Debian 6.0-31 and OpenBSD (`files/debian/`): CAN-2026-2034442 and CAN-2026-2034443 (a heap and a stack overflow), CVE-2022-1271 of zipgrep, the ZIP64 archives of Windows, the times of the Unix extra fields; `screen` with the ncurses of the base system and the sockets in `~/.screen`, NOSOCKETDIR; `sudo` with PAM only: no AUDIT, LOGSRVD, SSL, NLS, with the fix of CVE-2026-96512 (three upstream commits); `bash` without NLS, with three fixes of 5.3 as Gentoo carries them: `wait` of an ended background job, command substitutions with a large environment, the prompt in a single-byte locale; `portmaster` with the completion of bash only), `wget` and `rsync` ours with the shared libraries of az (`wget`: IDN, PSL, the fixes of CVE-2026-15146, CVE-2026-58470, CVE-2026-58471 and CVE-2026-58472 as Ubuntu carries them; `rsync` 3.5.2, ahead of the official 3.5.1 for its security fixes: lz4, zstd, xxhash, no ICONV), PCRE2 of `pcre2` (`wget`) and the OpenSSL of the base system |
| `phpXY` | `lang/phpXY` | the core of PHP X.Y (`XY`: 56, 74, 81, 82, 83, 84): CLI, php-fpm, phpize |
| `mod_phpXY` | `www/mod_phpXY` | the Apache module `libphpXY.so` |
| `phpXY-<module>` | `<category>/phpXY-<module>` | a package per module (`php84-gd`: `graphics/php84-gd`): the modules of the official ports of the commit of the version and the PECL ones the fork bundles, without "pecl": `phpXY-redis`, `phpXY-igbinary`, `phpXY-memcached`, `phpXY-memcache`, `phpXY-imagick`, `phpXY-gmagick`, `phpXY-mcrypt`, `phpXY-ssh2`, from 7.4 on `phpXY-swoole`, `phpXY-openswoole` and `phpXY-excimer`; OPcache is a module too (`phpXY-opcache`), json up to 7.4 (`php74-json`), mysqlnd as well (`phpXY-mysqlnd`: the database modules use it). 70 for 7.4 and 8.1, 68 for 8.2 to 8.4, 65 for 5.6 (with the variants below); the list of one: `pkg search -r az '^php84-'` |

- openssl in two kinds, one of the two: `phpXY-openssl` and `phpXY-openssl-legacy` (the
  legacy provider of OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- ftp, mysqlnd, swoole and openswoole without OpenSSL, and each as a variant with the
  OpenSSL of the base system, one of the two per module (aZ, 10.11.2026):
  `phpXY-ftp-openssl` (FTP over SSL), `phpXY-mysqlnd-openssl`, `phpXY-swoole-openssl`,
  `phpXY-openswoole-openssl`. `phpXY-mysqlnd` makes TLS to the server through the module
  openssl when a site asks for it and has no logins caching_sha2_password and
  sha256_password (MySQL 8 and later; MariaDB has neither): `phpXY-mysqlnd-openssl` has
  them. The modules on mysqlnd go with one of the two: `phpXY-mysqli-openssl`,
  `phpXY-pdo_mysql-openssl` (5.6 also `php56-mysql-openssl`), `phpXY-openswoole-openssl`
  and `php74-swoole-openssl` with `phpXY-mysqlnd-openssl`. Swoole 6.1 and 6.2 (8.1 to
  8.4) need no mysqlnd (aZ, 11.11.2026: its option only made mysqlnd a module to load;
  their hooks of mysqli and PDO MySQL work without it) and go with either; swoole 6.2
  (8.2 to 8.4) has no build without OpenSSL, so `phpXY-swoole` has it and there is no
  `phpXY-swoole-openssl`.
- redis in four packages, one of the four (aZ, 11.11.2026; the same files): `phpXY-redis`
  without compression, `phpXY-redis-lz4`, `phpXY-redis-zstd` and `phpXY-redis-lz4-zstd`
  with the lz4 and zstd of az (`Redis::OPT_COMPRESSION` of a site; 5.6 has only
  `php56-redis`: phpredis 4.3.0 knows neither). All with igbinary and sessions in Redis.
- gd of 5.6 also as `php56-gd-t1lib`, one of the two (aZ, 11.11.2026): with T1lib, the
  PostScript Type 1 fonts of `imagepsloadfont()` and `imagepstext()` (gone from PHP 7.0),
  on libt1 of our `devel/t1lib`: the official port without X11, with the fixes of the
  vulnerabilities of t1lib 5.1.2 it lacks, as Gentoo carries them (CVE-2010-2642,
  CVE-2011-0433, CVE-2011-5244, CVE-2011-0764, CVE-2011-1552, CVE-2011-1553,
  CVE-2011-1554).
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
  ([`az/az/files/deps.conf`](az/az/files/deps.conf)). Two trees: `/usr/local/az`
  (shared, SONAME and run path `/usr/local/az/lib`, no ldconfig), which every package
  links: our ports link each other's shared libraries, never a static or bundled copy
  of a library another of our ports has (aZ, 10.11.2026); and `/usr/local/az/static`
  (static, position independent), only for the static PHP builds of `az-menu.sh`;
  `bin/pkg-config` of each,
  `VERSIONS` in `share/doc/az`, the licences in `LICENSES/`. It builds into
  `/usr/local/az` of its chroot (as root, `NEED_ROOT`) and packages that tree.
  No dependencies.
- **`ftp/curl`**: the package `curl` in the place of the official one: `bin/curl` and
  `lib/libcurl.so.4` (only `curl_*` exported), the libcurl of every package (the PHP
  module curl, git: one libcurl, aZ 10.11.2026), the options of the official port,
  against the shared libraries of az ([`tools/curl-build.sh`](tools/curl-build.sh)).
  Build and run: az.
- **`multimedia/ffmpeg`**: the package `ffmpeg` in the place of the official one:
  `bin/ffmpeg` and `bin/ffprobe` (the libraries of FFmpeg in them) with only what the
  video sites need ([`multimedia/ffmpeg/files/ffmpeg.conf`](multimedia/ffmpeg/files/ffmpeg.conf)),
  linking x264, dav1d, SVT-AV1 (AV1 and AVIF written, aZ 11.11.2026) and libwebp of az.
  With the security fixes of FFmpeg after 9.0.2, until 9.0.3
  ([`files/ffmpeg/fix-*.patch`](multimedia/ffmpeg/files/ffmpeg), each with its upstream
  commit, what and why): those of release/9.0 (H.264, AAC USAC, Matroska, an error at
  the end of a mux) and of master for the CVEs of 2026 that reach what is built here
  (HDR10+ in Matroska, pssh of mp4, HEVC, AFGS1 film grain, EXIF, the Vorbis parser,
  WebP alpha, aac_adtstoasc, Dolby Vision for SVT-AV1) and for the memory errors of
  mov/mp4, IAMF, AAC USAC, multilayer HEVC and Avid MJPEG found in October 2026.
  Build and run: az.
- **`graphics/ImageMagick6`**: `bin/convert6`, `identify6`, `mogrify6`, `composite6`
  and the others, next to ImageMagick 7, linking their libraries in `/usr/local/az/lib`:
  JPEG, PNG, WebP, GIF, HEIC and AVIF only, with our policy; with the fix OpenBSD
  carries for an image with a broken EXIF or 8BIM profile, which 6.9.13-60 did not
  write at all ([`files/imagemagick6-write-profiles.patch`](graphics/ImageMagick6/files/imagemagick6-write-profiles.patch),
  ImageMagick6 issue 427). Build and run: az.
- **`graphics/ImageMagick7`**: the package `ImageMagick7` in the place of the official
  one: `bin/magick` and its names, the same formats and policy, linking its shared
  `libMagickCore-7.so` and `libMagickWand-7.so` in `/usr/local/az/lib`, which imagick of
  PHP links too (`MagickWand-config` there); its static libraries and
  `MagickWand-config` in `/usr/local/az/static`, for the static imagick of `az-menu.sh`.
  Build and run: az.
- **`graphics/GraphicsMagick`**: the package `GraphicsMagick` in the place of the official
  one: `bin/gm`, built as our ImageMagick, with JPEG, PNG, WebP, GIF, BMP, HEIC and
  AVIF only; with no policy file, the coders it registers and an empty `delegates.mgk` take
  its place (`files/graphicsmagick.conf`). `gm` links its shared `libGraphicsMagick` and
  `libGraphicsMagickWand` (symbol prefix `Gm`) in `/usr/local/az`, with
  `GraphicsMagick-config`, which gmagick of PHP links too (`--with-gmagick=/usr/local/az`);
  its static libraries in `/usr/local/az/static`, for a static gmagick of `az-menu.sh`.
  Build and run: az.
- **`misc/mc`**: the package `mc` in the place of the official one: Midnight Commander
  with the editor, the subshell, the charsets and SFTP, without X11, translations and
  Aspell ([`misc/mc/files/mc.conf`](misc/mc/files/mc.conf): what and why), built by
  [`tools/mc-build.sh`](tools/mc-build.sh) on GLib of `devel/glib20` and libssh2 of az,
  shared, with the fixes of `files/*.patch` (taken from upstream after 4.8.33, from
  Gentoo, Debian, NetBSD and Alpine, and two of ours: each patch says where from, what
  and why; tested by [`tools/mc-test.sh`](tools/mc-test.sh) where a terminal in
  script(1) can show them). In a subshell of tcsh the history (Up, `history`,
  `~/.history`) keeps what one types there or at mc's command line and none of mc's own
  lines: the cd that follows a panel runs by a key bound with `bindkey -c`; the
  directories stay in mc's own history (Alt-Shift-H, Alt-Y, Alt-U). A copy (F5, F6
  across directories) clones the blocks where the file system
  can (upstream's file cloning of #5082, [`files/copy-clone-1.patch`](misc/mc/files/copy-clone-1.patch)
  and its fix `copy-clone-2-reget.patch`; mc-build.sh runs autoreconf for its
  `configure.ac` and checks `HAVE_COPY_FILE_RANGE` and `HAVE_FILE_CLONING_BY_RANGE`, and runs
  its unit test): on FreeBSD by `copy_file_range(2)` with `COPY_FILE_RANGE_CLONE`, which ZFS
  does by block cloning when `vfs.zfs.bclone_enabled` is 1 (the default of FreeBSD 15.x):
  the copy takes no new space and no time, its blocks shared until one of the two files
  changes them; elsewhere (another pool or file system, UFS, cloning off) mc copies as
  before. Off: Options, Configuration, "Use COW file cloning", or `file_cloning=false` in
  `~/.config/mc/ini`. zip, jar, 7z, rar and ISO images open as a directory with
  [`files/ubsdtar`](misc/mc/files/ubsdtar), on `tar` of the base system (libarchive),
  without Perl, 7-Zip or unrar; Perl, zip and GNU diff give what they give (writing into
  zip, the deb and rpm helpers, `mcdiff`) once they are installed.
- These seven: the version of the official port at the pinned commit (or of the take
  line of its conf) with the build stamp as `PORTREVISION`; every distfile in the fetch
  phase; tests after the install: [`tools/ffmpeg-test.sh`](tools/ffmpeg-test.sh),
  [`imagemagick-test.sh`](tools/imagemagick-test.sh), [`curl-test.sh`](tools/curl-test.sh),
  [`az-test.sh`](tools/az-test.sh), [`mc-test.sh`](tools/mc-test.sh).
- **`devel/pcre2`** and **`devel/pcre`**: the official ports as they are
  ([`Mk/az-official.mk`](Mk/az-official.mk)), PCRE2 10.49 and PCRE 8.45 (its last
  release): the PCRE of PHP (7.4 to 8.4 `--with-external-pcre`, 5.6
  `--with-pcre-regex`), Apache, git, wget, mc (GLib) and MariaDB, and nginx later (aZ,
  10.11.2026).
- **`devel/git`**: git without Perl (send-email, svn, the cvs scripts), Python, Tcl/Tk,
  gettext, expat (`git http-push`), the manual pages and the user and rc.d script of git
  daemon; HTTPS through our `curl`, PCRE2 (`git grep -P`) of `pcre2`, iconv of libc.
- **`www/apache24`** and **`www/mod_maxminddb`**: Apache 2.4.71 with prefork only (a
  module) and the modules of the servers (cgi and env too; everything else off), no SSL,
  APR and APR-util of az (shared: those of mod_php too), PCRE2 of `pcre2`;
  mod_maxminddb with libmaxminddb of az.
- **`databases/memcached`** and **`databases/memcached-openssl`**: memcached without TLS,
  SASL, DTrace and the docs, libevent of az; the variant with TLS on the OpenSSL of the
  base system; one of the two.
- **`databases/mariadb1011-server`** and **`databases/mariadb1011-client`**: MariaDB 10.11
  with the options of aZ (of the engines of the options InnoDB only; no GSSAPI, wsrep,
  RocksDB, Spider, Mroonga, S3, CONNECT with ODBC and XML, HashiCorp Vault, AWS key
  management), the socket `/tmp/mysql.sock` compiled into the server and the client
  library and in `my.cnf.sample` (`/tmp` is a memory disk on the servers, tmpmfs), the
  PID file in `/var/run/mysql`; PCRE2 of `pcre2`, lz4, zstd and fmt of az, zlib (not the
  copy MariaDB has), OpenSSL and libedit of the base system.
- **`ftp/vsftpd-ext`** and **`ftp/vsftpd-ext-openssl`**: vsftpd-ext with its rc.d script
  (RC_SCRIPT); the variant with SSL (VSFTPD_SSL, the OpenSSL of the base system); one of
  the two. With the fix of CVE-2021-3618 (ALPACA) as vsftpd 3.0.5 has it
  ([`files/patch-CVE-2021-3618`](ftp/vsftpd-ext/files/patch-CVE-2021-3618)): an HTTP
  method or the 11th unknown command before the login closes the connection, a TLS
  client whose ALPN does not offer `ftp` is refused, `ssl_sni_hostname`. And fixes of
  ours, which upstream does not have (each file says what and why):
  [`files/patch-CVE-2026-119567`](ftp/vsftpd-ext/files/patch-CVE-2026-119567):
  `cmds_allowed` and `cmds_denied` take `XMKD`, `XRMD`, `XCWD`, `XCUP`, `XPWD` and
  `P@SW` as `MKD`, `RMD`, `CWD`, `CDUP`, `PWD` and `PASV` (a denied `MKD` was done as
  `XMKD`); [`files/patch-deny_file`](ftp/vsftpd-ext/files/patch-deny_file): `deny_file`
  denies the paths through a denied directory too (with `{*.mp3,*.mov,.private}`,
  `.private/secret` was not denied);
  [`files/patch-CVE-2026-119568`](ftp/vsftpd-ext/files/patch-CVE-2026-119568): a data
  connection over TLS resumes only a session of its own login (no stateless session
  tickets: their key was the same for every login, and `require_ssl_reuse` took the
  session of another one).
- **`net/3proxy`** and **`net/3proxy-openssl`**: 3proxy 0.9.9.3, the LTS line of upstream
  (07.11.2026), for its security fixes: the official port has 0.9.5, which upstream no
  longer supports. With the two fixes of the 0.9 branch after it (a pcre rule without an
  ACL, tlspr and a short ServerHello), built with CMake with the names and paths of the
  official port (`httppr`, `mycrypt`, `/var/log/3proxy`, its sample config and rc.d
  script) and links by the 0.9.5 names of the plugins (`StringsPlugin.so`,
  `TrafficPlugin.so`, `pamauth.so`; PCRE is inside 3proxy since 0.9.7, a
  `pcre_plugin` line is taken as it is); PAM, PCRE2 of `pcre2`; without TLS, as the
  official port, users with NT passwords too (as in 0.9.5); the variant with TLS on the
  OpenSSL of the base system (TLS servers and clients, MITM); one of the two.
- **`dns/bind920`** and **`dns/bind-tools`**: BIND 9.20, as in the official tree the
  tools a slave of the server port, with the options of aZ: TCP_FASTOPEN and IDN, without
  GSSAPI, DNSTAP, LMDB (`rndc addzone` keeps the zones in a `.nzf` file), the statistics
  channels (STATS_JSON, STATS_XML), FIXED_RRSET and LARGE_FILE; no manual pages and no
  headers of the libraries of BIND. `named` with its rc.d script and
  `/usr/local/etc/namedb` as the official port; the tools (dig, host, nslookup, delv,
  nsupdate, the DNSSEC ones) with IDN. libuv, liburcu, nghttp2 (DNS over HTTPS) and
  libidn2 of az, OpenSSL, zlib and libedit of the base system.
- **`graphics/vips`**: libvips 8.18 (aZ, 11.11.2026: for a Lua script of nginx that
  converts images on the fly) with aZ's formats: JPEG (mozjpeg), PNG (libpng), WebP,
  HEIC/AVIF (libheif of az: both loaded, AVIF saved with SVT-AV1), GIF (load built in, save with cgif and
  libimagequant), with ICC profiles (lcms2), EXIF (libexif) and SIMD (Highway; ORC, the
  other choice, only without Highway). No TIFF, SVG, PDF, JPEG XL, ImageMagick or
  GraphicsMagick, text, FFTW and the other official options; not the loaders of
  Analyze, Radiance and PPM, the deprecated vips7 API, the C++ API, the static library,
  the manual pages and the translations. mozjpeg, png, webp, libheif, lcms2 and expat
  of az; glib, libexif, cgif, libimagequant and highway of their ports of this tree; zlib
  of the base system. For images of the web, `VIPS_BLOCK_UNTRUSTED=1` in the environment
  of nginx (`env VIPS_BLOCK_UNTRUSTED=1;` in the main context of nginx.conf; the message
  of the package says so) keeps libvips from its untrusted loaders. With the fixes of
  the 8.18 branch after 8.18.7, until 8.18.8 ([`files/patch-*`](graphics/vips/files),
  each with its commit): the total height of animated GIF, WebP and HEIF (an int
  overflow into a wrong size), the input profile of `icc_import` (used after free),
  LZW codes across sub-blocks of GIF, PNGs of libpng 1.6.0 to 1.6.2, HEIC photos of
  more than 256 items.
- **`multimedia/qt-faststart`**: `bin/qt-faststart`, `tools/qt-faststart.c` of FFmpeg
  9.0.2 (public domain): the official port expired on 30.06.2022 (ffmpeg `-movflags
  +faststart` does the same); kept for compatibility until it is no longer needed (aZ,
  10.11.2026).
- These: tests after the install, [`tools/servers-test.sh`](tools/servers-test.sh) (git
  grep -P, Apache with the modules of the servers on a port of its own, memcached,
  MariaDB on its default socket `/tmp/mysql.sock`, named with a zone of its own asked by
  dig over UDP and TCP and by an IDN name, rndc, vips with JPEG, WebP, PNG and GIF,
  vsftpd-ext and vsftpd-ext-openssl (what the fixes above close refused; curl gets a
  file over FTP and FTPS), the libraries of each).
- **`www/yt-dlp`**: the package `yt-dlp` in the place of the official one: the official
  port as it is, at a newer release of yt-dlp (the grabbers of the video sites need the
  extractors of the latest), depending on our `multimedia/ffmpeg`; its Python packages are
  the official ones, on our `python312` and `py312-sqlite3`. Its release follows those of
  GitHub, not the official port (aZ, 12.11.2026): a new one goes into the port, is built
  and is published by itself ([yt-dlp from GitHub](#yt-dlp-from-github)). Tests after the install:
  [`tools/ytdlp-test.sh`](tools/ytdlp-test.sh) (an HLS stream from a local server, fixed by
  our ffmpeg into MP4, as the grabbers download).
- **`lang/perl5.42`**: the package `perl5` (`/usr/local/bin/perl`) in the place of the
  official one (aZ, 11.11.2026: our Perl and Python under the package names of FreeBSD,
  so that the `p5-*` packages of the FreeBSD repository work with them): the official
  port as it is, Perl 5.42.3, the default version of the pinned tree (with the fix of
  CVE-2026-15534 of blead, which 5.42.3 lacks: `files/patch-CVE-2026-15534`), with its options
  (threads, MULTIPLICITY, 64-bit integers, the shared `libperl`; no GDBM) and the `-O3`
  of the builds, without DTrace (`OPTIONS_UNSET` of every build here): the probes of
  DTrace are compiled into the core of Perl only (`mydtrace.h`: `USE_DTRACE` and
  `PERL_CORE`), so an XS module takes nothing of DTrace, and those of FreeBSD's packages,
  built against its perl with DTrace, load and run with ours. Tests after the install:
  [`tools/perl-test.sh`](tools/perl-test.sh) (the `Config` of ours against that of
  FreeBSD's `perl5`, the libraries, every XS module of Perl; official `p5-*` packages with
  XS installed over it as on a server: JSON::XS, DBI with DBD::SQLite, Text::CSV_XS,
  YAML::XS, Net::SSLeay and IO::Socket::SSL with TLS on 127.0.0.1 and others, their
  symbols against our `libperl`; an XS module built against it).
- **`lang/python312`**, **`databases/py-sqlite3`**, **`math/mpdecimal`** and **`lang/python3`**: Python 3.12,
  the `PYTHON_DEFAULT` of the pinned tree, as the official port with its options (LTO,
  PYMALLOC, IPV6, NLS on; libmpdec of `math/mpdecimal`, the official port as it is) and its
  files, so that the official `py312-*` packages install over our `python312` and use it
  (aZ, 11.11.2026); libffi (`_ctypes`), expat (`pyexpat`), readline and libintl (the
  locale module) of az with the run path `/usr/local/az/lib` instead of their packages,
  OpenSSL, ncurses, zlib, bzip2 and liblzma of the base system; the build sees of
  `/usr/local` only az and libmpdec. `py312-sqlite3`, the official port with its
  flavours, on the SQLite of az. No gdbm and tkinter (as the official package; aZ: not
  needed). Its version is that of the official port (`Mk/Uses/python.mk` reads it there).
  `lang/python3`: the official meta port as it is (aZ, 11.11.2026), `bin/python3`,
  `bin/pydoc3`, `python3.pc` and the like as links to those of Python 3.12, depending on
  our `python312`. The build tools a port needs only to build (Python, Perl, meson: of
  `az/az`, `ftp/curl`, `devel/glib20`, `graphics/vips`, `www/node24`) are the official
  packages, not ours (`tools/build.sh`); a port that runs with Python or is a module of
  it (`www/yt-dlp`, `www/npm-node24`, `databases/py-sqlite3`) takes ours.
  A switch of `PYTHON_DEFAULT` or `PERL5_DEFAULT` in `Mk/bsd.default-versions.mk` of
  freebsd-ports main opens an issue of the
  [upstream check](https://github.com/azsupport/php-src#upstream-check) of
  azsupport/php-src: the `py3XX-*` and `p5-*` packages of FreeBSD built after it need a
  Python or Perl of that version. Tests after the install:
  [`tools/python-test.sh`](tools/python-test.sh) (`python3` and `python3.12`, the
  libraries of each module, TLS with the CA store of the base system, hashlib, ctypes,
  decimal, expat, sqlite3, gettext, readline, the compressions; `py312-six` and
  `py312-markupsafe` of FreeBSD over our `python312`).
- **`java/openjdk21`**, **`devel/jna`** and **`devel/apache-ant`**: the JDK of
  `textproc/elasticsearch6`, `textproc/opensearch217` and `textproc/opensearch219`,
  and of OpenSearch 3.x later, and the JNA of the three, ours (aZ, 11.11.2026: a
  server with Elasticsearch gets nothing of a desktop; the official OpenJDK pulls
  about 50 packages of one, X11, fonts, ALSA, HarfBuzz with GLib and Python, giflib,
  PNG, javavmwrapper, the official `jna` libX11 and libXt; 12.11.2026: one JDK for
  them all: OpenSearch 2.x and Elasticsearch 6 do not run on JDK 24 and later, where
  the Security Manager is disabled for good, and OpenSearch 3.x needs 21 at least),
  with the names, origins, versions and paths of the official packages. `openjdk21`
  takes the version, distinfo and patches of the official port of the pinned commit
  as they are (a new version comes with the pin; of its patches the two that link
  fontconfig are left out, by name and SHA-256) and builds OpenJDK 21 headless
  (`--enable-headless-only`: `libawt_headless`, no `libawt_xawt` and
  `libsplashscreen`, so giflib and libpng stay bundled and unused; without the
  headers of X11 too, with the change of OpenJDK for that backported, JDK-8376684 of
  04.02.2026: 21u needs them headless, to compile and in its configure,
  `NEEDS_LIB_X11` of `make/autoconf/libraries.m4`), without sound (no ALSA and
  `libjsound` on FreeBSD, as on AIX and OpenBSD: `javax.sound` finds no devices) and
  without DTrace, on the libjpeg (mozjpeg), FreeType and Little CMS of az (the run
  path `/usr/local/az/lib` after `$ORIGIN`, in the three libraries that link them),
  the zlib of the base system and the HarfBuzz it bundles (no port of ours has it);
  no fonts and no javavmwrapper (no `/usr/local/bin/java`: Elasticsearch and
  OpenSearch take `JAVA_HOME`); CUPS and the headers of fontconfig (of az) only to
  build. fontconfig is not linked: OpenJDK loads `libfontconfig.so.1` with dlopen by
  its name when it needs the fonts of the system, and the rtld of FreeBSD looks for
  it in `LD_LIBRARY_PATH`, the run path of `bin/java`, the ldconfig hints and `/lib`,
  `/usr/lib`, never in `/usr/local/az/lib`: with our packages only Java has no fonts
  at all (every use of a font throws `java.lang.InternalError` of
  `sun.font.FontManagerFactory`, a font file too; Elasticsearch draws no text), with
  the official `fontconfig` and fonts installed (`pkg install dejavu`) it takes those
  (in [`tools/java-test.sh`](tools/java-test.sh): the families of DejaVu, text
  drawn). `jna`: JNA of the official port the same way,
  without JAWT (`-DNO_JAWT` on FreeBSD, as JNA builds for Android and macOS) and X11,
  its `libjnidispatch.so` on the shared libffi of az instead of the static copy it
  bundles, and installed as a file too, `lib/jna/libjnidispatch.so` (aZ, 11.11.2026:
  with `-Djna.boot.library.path=/usr/local/lib/jna` JNA loads it from there instead of
  extracting it from the jar into a temporary directory at every start;
  `elasticsearch6` does so since 12.11.2026, with `-Djna.nounpack=true` and a
  dependency on that file: its process maps it, and its system call filter, set
  through JNA, is on, [`tools/elastic-test.sh`](tools/elastic-test.sh); `opensearch217` and
  `opensearch219` the same, [`tools/opensearch-test.sh`](tools/opensearch-test.sh)); built with
  our `openjdk21` and `apache-ant` (aZ, 12.11.2026; Ant the official port with
  `JAVA_VERSION` 21, `bin/ant` on the `java` of `openjdk21`): one JDK in the build;
  JNA compiles for Java 8 (`javac --release 8`; the port checks the class file
  version, 52). The ports check
  what they build (every ELF of the JDK without the libraries of X11, ALSA, giflib,
  libpng, HarfBuzz and fontconfig; the libraries of az by their run path; the
  dependencies: az only). Tests after the install:
  [`tools/java-test.sh`](tools/java-test.sh) (`openjdk21`: headless, ImageIO with
  JPEG and PNG, an ICC conversion, text, `AudioSystem`, TLS 1.3 on 127.0.0.1, the
  libraries of az in the process, `ldd` of every ELF file of the JDK (the libraries
  of the JDK, of the base system and of `/usr/local/az/lib` alone, nothing of X11),
  `getpid()` through JNA, from the jar and from `lib/jna`, a dot product through the
  Vector API of `jdk.incubator.vector`, a file mapped as a `MemorySegment` and
  `getpid()` through the `Linker` of FFM, as OpenSearch 2.19 and 3.x use them; the
  classes of `jna.jar` for Java 8; `bin/ant` on `openjdk21`, a jar it builds run on
  the JDK; the dependencies of the packages, those of `elasticsearch6` `bash`, `jna`
  and `openjdk21`).
- **`lang/phpXY`** and **`www/mod_phpXY`** (5.6, 7.4, 8.1, 8.2, 8.3, 8.4): the core
  `phpXY` and the Apache module `libphpXY.so`, each from the official port of the commit
  of its version (the table above); PCRE2 is that of `devel/pcre2` (5.6: PCRE of
  `devel/pcre`), not the one the fork bundles (aZ, 10.11.2026).
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
takes `yt-dlp`, `python312`, `python3` and `py312-sqlite3` of az by `priority: 100`:

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
env AZ_PLAN=1 sh tools/build.sh
env AZ_CONFIGURE_CHECK=1 sh tools/build.sh --force
```

What it does, with the logic of poudriere:

- the official tree at the pinned commit (git, depth 1) in `work/freebsd-ports`, reused
  when it is at that commit (`AZ_PORTSDIR`: a tree taken as it is, with a warning when
  it is at another commit), this tree as `OVERLAYS` over it;
- `work/make.conf` from [`tools/make.conf.in`](tools/make.conf.in), the make.conf of
  aZ's servers (`CPUTYPE` of the level, `CFLAGS=-O3 -pipe -fno-strict-aliasing`, the
  framework adds `-fstack-protector-strong`; `JPEG_PORT=graphics/mozjpeg`;
  `OPTIONS_UNSET` of X11, Wayland, GUI, DBus, CUPS, debug, DTrace, tests,
  documentation and manual pages) with the paths of the run, given to make as
  `__MAKE_CONF`: the `/etc/make.conf` of a build server is neither read nor changed,
  and the options saved by `make config` there do not change a build (`PORT_DBDIR` of
  its own);
- the queue: the ports and the ports of this tree they need (the origins of their
  `*_DEPENDS` that are ours), each after those it needs;
- a port whose origin has a package with the same `az_hash` in the repository is not
  built again (an incremental build; [Versions and rebuilds](#versions-and-rebuilds))
  unless `--force`; a port that fails stops the ports that need it (skipped, with the
  reason);
- each port in a chroot of its own (`work/ch/<key>`, aZ 11.11.2026), made for it in
  seconds and torn down after it, whatever its result: the base system of the machine
  read only (nullfs of `/bin`, `/sbin`, `/lib`, `/libexec`, `/usr/bin`, `/usr/sbin`,
  `/usr/lib`, `/usr/lib32`, `/usr/libexec`, `/usr/include`, `/usr/share`,
  `/usr/libdata`), a copy of its `/etc` (pkg, `resolv.conf`, the users the packages
  add; not `/etc/ssh`), devfs, `/tmp`, an empty `/usr/local` and a pkg database of its
  own; this tree, the official tree, `packages/` and the repository read only at their
  paths; the distfiles, the work directories (`WRKDIRPREFIX`), the packages directory
  of the port and `results/az-results` read-write. The catalogs of pkg are those of the
  run (the machine's, updated once at the start; `pkg -U` in a chroot) and the cache of
  pkg is that of the machine, shared: the official packages of the ports to build are
  fetched at the start, later fetches one chroot at a time. In the chroot the official
  packages of the port's dependencies (and those our packages it gets need to run) come
  by `pkg -c <chroot> install` from the FreeBSD repositories of the machine (never ours,
  `az` or `azbuild`), ours by `pkg -c <chroot> add` of the packages built before or of
  the repository, in the order of the queue (`-f` in the place of an official package
  of the same name); then `make clean package` in it (`chroot`, the environment of a
  login of root with the make.conf of the run and `AZ_CPUTYPE`) with
  `USE_PACKAGE_DEPENDS_ONLY=yes` (nothing is built from source but the port itself);
  its log and its time, with those of its chroot and of its dependencies (a line
  `chroots:` in the summary). No build touches the `/usr/local` of the machine: the
  checks after the run see only what they install;
- the build tools of `AZ_TOOLS_OFFICIAL` in `tools/build.sh` (`lang/python3`,
  `lang/python312`, `lang/perl5.42`, `devel/meson`) come from the official packages of
  FreeBSD also when this tree has the origin (aZ, 11.11.2026: our Python and Perl link
  libraries of az, which needs them to build): a port that needs one only to build it
  (`FETCH_`, `EXTRACT_`, `PATCH_`, `BUILD_` or `PKG_DEPENDS`) gets the official package
  in its chroot, and the hash of our port is not in its `az_hash`; a port that runs
  with it (`LIB_` or `RUN_DEPENDS`) or builds an extension for it (a `FLAVOR` `py*`)
  gets ours (`results/hashes.txt` names the tools a port gets official);
- up to `AZ_JOBS` ports at once (default 4), in waves: the ports whose ports of this
  tree they need are done form a wave, the biggest first, each in its chroot with its
  log and its own packages directory (two packages with the same files, `php84-mysqlnd`
  and `php84-mysqlnd-openssl`, build side by side); the summary in the order of the
  queue; `results/waves.txt`. `AZ_JOBS=1`: one port after another, as before;
  `AZ_DRYRUN=1`: the waves of the run said, nothing built (the ports that need az are
  decided after az is built, when it is to be built);
- `AZ_PLAN=1` (the input `plan` of the workflow), the plan of a run, to check its
  decisions cheaply: `az/az` and the ports it needs are built when they are to be (the
  ports that need az are decided by the interfaces of the new az), every other port only
  decided, kept from the repository or to be built and why (`PLAN` lines of the
  summary, `results/plan.txt`), not built; the repository gets what was built (az, so
  that the next run keeps it); no checks, never published;
- a port that names no file of the static tree of az (`/usr/local/az/static`) in its
  dependencies builds without the archives of az (they go from its chroot): only a port
  that says `AZ_STATIC_LIBS` can link them into its package
  ([Versions and rebuilds](#versions-and-rebuilds));
- a `NEED_ROOT` port (`az/az`: it builds into `/usr/local/az`): into that of its own
  chroot, as any port;
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
  `result: FAIL (...)` at the end), `queue.txt`, `hashes.txt`, `waves.txt`, `logs/`
  (`logs/chroots.log`: the catalogs and the official packages fetched at the start),
  `az-interface.txt` and `abi-check.txt` (az), `plan.txt` (`AZ_PLAN`),
  `configure-check.txt` (`AZ_CONFIGURE_CHECK`).

### Versions and rebuilds

As poudriere: each port that a run builds gets `AZ_STAMP` (the hour of the start of
the run, `yymmddhh` UTC) as its `PORTREVISION`, so that each build is an upgrade for
pkg (`php74-7.4.33_26110817`), and `AZ_HASH`, which goes into the package as the
annotation `az_hash` (`pkg info -A php74`): the SHA-256 of the files of the port (with
those of its `MASTERDIR`, of its `EXTRA_PATCHES` and `AZ_HASH_FILES` in this tree: the
files of the directory of another port its build reads, `graphics/ImageMagick6` the
`imagemagick.conf` and `policy.xml` of `graphics/ImageMagick7`), of the makefiles of
`Mk/` of this tree it reads
(`Mk/bsd.overlay.mk`; `Mk/Uses/php.mk` only for the PHP ports), of the official commit,
the level, `tools/make.conf.in` and the way the builder builds (`builder chroot`: each
port in a chroot of its own; every port was built again once for it, 11.11.2026), and
of the `az_hash` of each port of this tree it needs (not of a build tool it gets
official, `AZ_TOOLS_OFFICIAL`: the official commit is in its hash already). A port
whose package in the repository has the same `az_hash` is not built again; a change of
a port builds it and every port that needs it again (a change of `az/az`: all that
link it). The files a port lists in `AZ_HASH_NOT_FOR_DEPENDENTS` (installed and used
at run time only) count in its own `az_hash` but not in that of the ports that need it
or of its slaves: a change of the php.ini block, the profile script, the rc.d script or
the pkg-message of `lang/php74` builds `php74` again, not the modules and `mod_php74`
(pkg takes a dependency by its name, not its version). No revisions bumped by hand.

`az/az` is built again when anything of it changes; a port that needs it takes into its
`az_hash` not the hash of az but the interfaces of the libraries of az it uses (aZ,
12.11.2026: as FreeBSD and Debian, which do not build again the dependents of a shared
library for a fix inside it). The interface of a library comes out of the build of az:
[`tools/az-build.sh`](tools/az-build.sh) writes a manifest a library into the package
(`/usr/local/az/share/az/interface/<library>.txt`) from what its builds installed (the
files whose inode changed after the start of each of its builds, in both trees): its
headers, `.pc` files, `*-config` scripts, cmake and other files with their SHA-256, the
SONAMEs of its shared libraries, the names of its archives, its version, the hash of its
build functions (`b_`, `s_` of `tools/az-build.sh`, `lib_` of
`files/curl/build-libcurl.sh`: its configure and cmake options) and the libraries of az
it requires (the `NEEDED` of its shared libraries, `Requires` and `-l` of its `.pc`
files, the `#include` lines of its headers); `common.txt` has the files of no library
(`bin/pkg-config`). [`tools/az-interface.sh`](tools/az-interface.sh) makes of a manifest
the interface hash (the hashes of the archives left out) and the content hash, and the
closure of what a library requires. A port takes the interface hash of each library of
the closure of those it uses (those whose manifests have the files of az its
dependencies name, `${AZ_PREFIX}/lib/libxml2.so:az/az`: libxml2, and those its
`AZ_HASH_LIBS` names: a program that links more than its dependencies name, `ftp/curl`,
`multimedia/ffmpeg`, `graphics/ImageMagick*`, `graphics/GraphicsMagick`) and of
`common.txt`. So a fix inside the code of a library (the same headers, `.pc` files,
SONAMEs, version and options) builds again only az; a new version, a changed header or
`.pc` file, a new SONAME or a changed option builds again the ports that use that
library. The hashes of the ports that need az are made once az is done: at once when its
package in the repository has the same `az_hash` (its manifests), after its build when it
is built (az is the first stage); a package of az without manifests is built again.

Static use: no port of this tree links the archives of az (`/usr/local/az/static`) into
its package; `graphics/ImageMagick7` and `graphics/GraphicsMagick` build their own static
libraries against that tree, for PHP built on a server (`AZ_STATIC_LIBS= none`: their
headers and `.pc` files are in the interfaces, both trees). A port that would link them
names them in `AZ_STATIC_LIBS` (the content hash of those libraries, archives too, goes
into its `az_hash`); [`tools/check-tree.sh`](tools/check-tree.sh) asks for
`AZ_STATIC_LIBS` of a port whose dependencies name a file of the static tree, and
`tools/build.sh` builds every other port without the archives of az in its chroot.

The files of the directory of another port that a build reads:
[`tools/check-tree.sh`](tools/check-tree.sh) evaluates with `make` the paths the
makefiles of this tree a port reads name from its directory upward (`${.CURDIR:H}...`,
`${.CURDIR}/..`: the value of the variable of such a line, so that a branch not taken does
not count, or the expression of a line of a target); one outside its directory, `Mk/`
and `tools/`, and not in its hash (its `MASTERDIR`, `FILESDIR`, `PATCHDIR`, `PKGDIR`,
`DISTINFO_FILE`, `EXTRA_PATCHES`, the makefiles it reads, `AZ_HASH_FILES`) is a FAIL: the
port names it in `AZ_HASH_FILES`. Two such reads go into no package and stay out of the
hashes: `az/az/files/deps.conf` (`AZ_DEPS_CONF` of `az/az/Makefile.common`: its line
`ports` only, the official commit, in the base of every hash) and the `pkg-plist` of
`databases/mariadb1011-client`, which the server takes as `@comment` lines. A path a script
of `tools/` makes itself is not seen there (the `policy.xml` next to the conf of
`imagemagick-build.sh`): the port names it too.

Nothing slips by unseen:

- after az is built in a run, before the tests, the ABI check of every package of the
  repository that needs az ([`tools/az-abi-check.sh`](tools/az-abi-check.sh)): each
  SONAME of az its files need (`shlibs_required` of pkg) is in the new az, and each
  undefined dynamic symbol they bind from a library of az is defined there (the symbols
  the new az lost against the az of the repository, `nm -D`; the ELF files only of the
  packages that need a SONAME that lost some, `readelf -d`, `nm -D`); a package that
  fails is built again in the same run, one not built goes from the repository
  (`results/abi-check.txt`);
- the tests of all the programs run in every run (`tools/test-programs.sh`), with the
  packages kept against the new az;
- a package that links a library of az its `az_hash` does not take (its
  `shlibs_required` against the closures of its own libraries and of the ports it
  needs) fails the run: `AZ_HASH_LIBS` of its Makefile is short;
- `results/az-interface.txt` (a section of the report): the interfaces of the libraries
  of az, those that changed against the az of the repository, the ABI check, and the
  ports kept by interface while az was built again (a line `az:` of the summary).

[`tools/install-php.sh`](tools/install-php.sh) `<version>` installs the PHP packages of
a version from that repository, as a server does (the core, `mod_php74` and the
modules, with `php74-openssl`), and [`tools/check-php.sh`](tools/check-php.sh)
`<version>` checks them (`results/check-php-<version>.txt`); `install-php.sh --openssl`
puts the variants with OpenSSL in the places of their modules, for
`CHECK_TAG=openssl check-php.sh` (`check-php-<version>-openssl.txt`).

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
| `plan` | the plan only (`AZ_PLAN`, off by default): `az/az` and the ports it needs built when they are to be, every other port decided, kept or to be built and why (`results/plan.txt`, a section of the report), not built; no checks, never published |
| `publish` | publish the repository when everything built and every check passed (off by default: the repository the servers read is published on aZ's word) |
| `publish_only` | with `publish`: publish only when the repository differs from the release by packages of these ports alone (`category/port`, separated by spaces: the runs of [yt-dlp from GitHub](#yt-dlp-from-github)), else nothing; empty: whatever differs |

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

### The merged branches

[`delete-branches.yml`](.github/workflows/delete-branches.yml), "Delete merged branches":
deletes the branches given (separated by spaces) whose every commit is in main by its patch
(`git cherry`); `force` skips that check, for a branch whose commits went into main changed by
a rebase, compared by hand first. It runs on GitHub with the token of the workflow, because the
sandbox the branches are made in cannot delete a branch of GitHub (aZ, 12.11.2026: the merged
branches are deleted without him).

### yt-dlp from GitHub

[`yt-dlp-update.yml`](.github/workflows/yt-dlp-update.yml), "yt-dlp at the latest release
of GitHub": every 6 hours on main, and by hand at
https://github.com/azsupport/ports/actions/workflows/yt-dlp-update.yml, the button **Run
workflow**. yt-dlp follows the releases of github.com/yt-dlp/yt-dlp, not the version of
the official port (aZ, 12.11.2026); [`tools/ytdlp-update.sh`](tools/ytdlp-update.sh):

- the latest release (not a draft, not a pre-release) against `DISTVERSION` of
  `www/yt-dlp`;
- a newer one: its `yt-dlp.tar.gz` with the SHA-256 the API of GitHub and the
  `SHA2-256SUMS` of the release give; the patches of the port applied to it as the ports
  framework applies them, without fuzz (one that applies only with fuzz is made again,
  as `make makepatch` makes it; one that does not apply stops the update: no commit, the
  report shows why); `DISTVERSION` and `distinfo`;
- `yt-dlp-ejs`: yt-dlp takes its scripts only of the version it pins (the major.minor, and
  their SHA3-512), so a pin newer than `www/py-yt-dlp-ejs` makes that port ours from
  [`tools/ytdlp-ejs/`](tools/ytdlp-ejs) (the wheel of the release of github.com/yt-dlp/ejs,
  whose SHA-256 is the `EJS_WHEEL_HASH` of yt-dlp), or updates ours; deno stays the
  official package (a warning when it is older than the oldest one yt-dlp runs);
- the ports checked with `make -V` ([`tools/check-tree-ci.sh`](tools/check-tree-ci.sh),
  the check of `build.yml`), one commit of aZ pushed to main with the token of the run;
- the build, when the releases do not have that yt-dlp: `build.yml` of main for
  `www/yt-dlp`, both levels, `publish` with `publish_only`; not while a run of `build.yml`
  of main is queued or running (the next check starts it), not again after one it started
  succeeded, nor after three failed.

`publish_only` ([`tools/publish-gate.sh`](tools/publish-gate.sh)): the repository of a run of
main is the release with the cache of the last run, published or not, so it can carry
packages aZ has not published. With `publish_only` the release takes it only when its
packages differ from those of the release (by name and SHA-256) by packages of those ports
alone; else nothing is published, the report says so, and the new yt-dlp goes out with the
next publish of aZ (the cache of the run keeps it).

| Input | |
|---|---|
| `dry_run` | the update with its checks, the diff of its commit and the build it would start: nothing pushed or started (a run of another branch is always one) |
| `pretend` | a test, with `dry_run`: `www/yt-dlp` taken as at this version, so that the latest release is an update |
| `pretend_ejs` | a test, with `dry_run` and `pretend`: the official `www/py-yt-dlp-ejs` taken as at this version, so that ours is made |

The report: the summary of the run, and the branch `runs` of azsupport/azsupport
(`ports-yt-dlp-update/`) when it did something, waits or failed. No secret of its own: the
push and the build with the token of the run.

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
