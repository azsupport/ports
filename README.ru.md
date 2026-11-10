# azsupport/ports

Порты FreeBSD от aZ (azsupport.com): оверлей дерева портов FreeBSD, из которого
собираются пакеты его репозитория pkg **az** для его серверов на FreeBSD 15
(amd64), чтобы на серверах ничего не собиралось.
[README.md](README.md): то же по-английски.

- [Что это](#что-это)
- [Пакеты](#пакеты)
- [Порты](#порты)
- [Раскладка PHP на сервере](#раскладка-php-на-сервере)
- [Сервер и репозиторий az](#сервер-и-репозиторий-az)
- [Как собирается](#как-собирается)
- [Правила портов](#правила-портов)

## Что это

- **Оверлей**: только наши порты, поверх официального дерева
  [freebsd-ports](https://github.com/freebsd/freebsd-ports) на закреплённом коммите
  [`6e4a386577aa`](https://github.com/freebsd/freebsd-ports/tree/6e4a386577aaa191a68b11865fcb18e02f98e525)
  (main от 10.11.2026; `ports_commit` в [`tools/build.sh`](tools/build.sh), перед сборкой
  переводится на последний main: последние версии портов, aZ). Фреймворк
  портов берёт его как `OVERLAYS`: `bsd.port.mk` включает
  [`Mk/bsd.overlay.mk`](Mk/bsd.overlay.mk), берёт `Mk/Uses/<имя>.mk` оверлея раньше
  официального, а порт оверлея встаёт на место официального порта с тем же origin.
- **Минимальные хаки официальных портов**: каждый порт начинается с официального порта
  нужного коммита и меняет только то, что нужно; его Makefile говорит, чем он отличается
  и почему.
- **База каждой версии PHP**: порты её собственного коммита (как
  [`freebsd/targets.conf`](https://github.com/azsupport/php-src/blob/master/freebsd/targets.conf)
  в azsupport/php-src); порт, которого на этом коммите нет, берётся из портов ближайшей
  более новой версии, где он есть, или пишется нами:

  | PHP | freebsd-ports |
  |---|---|
  | 5.6 | [`d2c06ef5efae`](https://github.com/freebsd/freebsd-ports/tree/d2c06ef5efae/lang/php56) |
  | 7.4 | [`036685c034ba`](https://github.com/freebsd/freebsd-ports/tree/036685c034ba/lang/php74) |
  | 8.1 | [`6002588334a9`](https://github.com/freebsd/freebsd-ports/tree/6002588334a9/lang/php81) |
  | 8.2 | [`438e512499a9`](https://github.com/freebsd/freebsd-ports/tree/438e512499a9/lang/php82) |
  | 8.3 | [`eb0100f974b6`](https://github.com/freebsd/freebsd-ports/tree/eb0100f974b6/lang/php83) |
  | 8.4 | [`1a235373d266`](https://github.com/freebsd/freebsd-ports/tree/1a235373d266/lang/php84) |

- **Исходники PHP**: релизные тарболы форка
  [azsupport/php-src](https://github.com/azsupport/php-src) (для 7.4:
  [`php-7.4.33-fbsd-20261104-397aa202.tar.xz`](https://github.com/azsupport/php-src/releases/download/freebsd-7.4-20261104-397aa202/php-7.4.33-fbsd-20261104-397aa202.tar.xz)),
  в которых уже есть патчи порта FreeBSD, расширения PECL в `ext/` и PCRE2, которую
  форк вкладывает в себя: наши порты PHP своих патчей не накладывают. Что форк
  добавляет к PHP: исправления безопасности для каждой версии в тот же день (релизы
  php-src для 8.2–8.4, бэкпорты Remi Collet для 7.4 и 8.1, для 5.6 — они и свои),
  патчи, с которыми старые версии собираются и работают с компиляторами и библиотеками
  FreeBSD 15 (GCC 14+, clang 16+, OpenSSL 3, libxml2 2.12+, bison 3), встроенный
  OPcache и запрет загрузки расширений как опции
  ([его README](https://github.com/azsupport/php-src/blob/master/README.ru.md)).
- **Быстрее PHP**: ядра, модули Apache и модули на C собираются GCC 16 — с ним Zend VM
  держит свои регистры в глобальных регистровых переменных (у clang базовой системы их
  нет) — и с `-fno-semantic-interposition`: `Zend/bench.php` и `micro_bench.php` идут на
  33–44% быстрее, чем с clang 19, у PHP 7.4 и на 36–38% у 8.3 без OPcache (5–15% с его
  JIT), и mod_php получает столько же
  ([замер](https://github.com/azsupport/php-src/blob/master/README.ru.md#сравнение-скорости-сборок));
  sqlite3, expat и lcms2 из az — тоже на GCC ([Библиотеки с
  GCC](#библиотеки-с-gcc)).
- PHP 5.6, 7.4, 8.1, 8.2, 8.3 и 8.4, под x86-64-v3 и x86-64-v2 (процессор без AVX2 —
  релиз `az-fbsd15-amd64-v2`).

## Пакеты

Имена и origin как у портов, файлы по путям портов:

| Пакет | Origin | Что |
|---|---|---|
| `az` | `az/az` | библиотеки сборок в `/usr/local/az`: `lib` (разделяемые, с run path `/usr/local/az/lib`, без ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`), с ними линкуется каждый пакет; статические — в `/usr/local/az/static`, только для особых сборок `az-menu.sh`. OpenSSL, zlib и bzip2 — из базовой системы |
| `curl` | `ftp/curl` | `bin/curl` и `libcurl.so.4`, вместо пакета порта, с SCP и SFTP (libssh2); его `libcurl.so.4` — libcurl всех пакетов (модуль curl PHP, git) |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` и `ffprobe` только с теми форматами, что нужны видеосайтам |
| `ImageMagick6` | `graphics/ImageMagick6` | ImageMagick 6, программы с 6 на конце (`convert6`, `identify6`, ...); его библиотеки — в `/usr/local/az/lib` |
| `ImageMagick7` | `graphics/ImageMagick7` | ImageMagick 7 (`magick`); его `libMagickCore-7.so` и `libMagickWand-7.so` в `/usr/local/az/lib`, с ними линкуются `magick` и модуль imagick |
| `GraphicsMagick` | `graphics/GraphicsMagick` | GraphicsMagick (`gm`) с форматами нашего ImageMagick; его библиотеки в `/usr/local/az/lib`, с ними линкуются `gm` и модуль gmagick |
| `mc` | `misc/mc` | Midnight Commander: редактор, subshell, кодировки, SFTP; GLib внутри, libssh2 из az, PCRE2 из `pcre2`; zip, 7z, rar и образы ISO — через `tar` базовой системы |
| `pcre2`, `pcre` | `devel/pcre2`, `devel/pcre` | PCRE2 10.49 и PCRE 8.45, официальные порты: PCRE всех пакетов (PHP, Apache, git, wget, mc, MariaDB; потом nginx) |
| `git` | `devel/git` | git без Perl, Python, Tcl/Tk, gettext, man-страниц и git daemon; HTTPS через наш `curl`, `git grep -P` с `pcre2` |
| `apache24`, `ap24-mod_maxminddb` | `www/apache24`, `www/mod_maxminddb` | Apache 2.4 только с prefork и модулями серверов (и cgi, env), без SSL; APR и libmaxminddb из az |
| `memcached`, `memcached-openssl` | `databases/memcached`, `databases/memcached-openssl` | memcached без TLS, SASL и DTrace, libevent из az; вариант с TLS; ставится один из двух |
| `mariadb1011-server`, `mariadb1011-client` | `databases/mariadb1011-server`, `databases/mariadb1011-client` | MariaDB 10.11: из движков опций только InnoDB, без GSSAPI; сокет `/tmp/mysql.sock` вкомпилирован и прописан в `my.cnf` |
| `vsftpd-ext`, `vsftpd-ext-openssl` | `ftp/vsftpd-ext`, `ftp/vsftpd-ext-openssl` | vsftpd-ext со своим скриптом rc.d; вариант с SSL; ставится один из двух |
| `bind920`, `bind-tools` | `dns/bind920`, `dns/bind-tools` | BIND 9.20: DNS-сервер `named` с TCP Fast Open, без GSSAPI, DNSTAP, LMDB и каналов статистики; dig, host, nslookup, delv, nsupdate и утилиты DNSSEC, с IDN |
| `qt-faststart` | `multimedia/qt-faststart` | qt-faststart (атом moov в начало MP4), возвращён для совместимости: официальный порт удалён 30.06.2022 |
| `yt-dlp` | `www/yt-dlp` | yt-dlp релиза новее официального порта, с нашим `ffmpeg` |
| `bash`, `bsddialog`, `bsnmp-ucd`, `portmaster`, `rsync`, `screen`, `sudo`, `unzip`, `wget`, `yamdi`, `zip`, `3proxy` | их официальные origin | утилиты серверов: официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)) с опциями aZ в Makefile каждого порта (`unzip` с ICONV — кириллические имена архивов Windows; `screen` с ncurses базы и сокетами в `~/.screen`, NOSOCKETDIR; `sudo` только с PAM, без AUDIT, LOGSRVD, SSL, NLS; `bash` без NLS; `portmaster` только с дополнением для bash), `wget` и `rsync` наши, с разделяемыми библиотеками az (`wget`: IDN, PSL; `rsync`: lz4, zstd, xxhash, без ICONV), PCRE2 из `pcre2` (`wget`) и OpenSSL базы |
| `phpXY` | `lang/phpXY` | ядро PHP X.Y (`XY`: 56, 74, 81, 82, 83, 84): CLI, php-fpm, phpize |
| `mod_phpXY` | `www/mod_phpXY` | модуль Apache `libphpXY.so` |
| `phpXY-<модуль>` | `<категория>/phpXY-<модуль>` | по пакету на модуль (`php84-gd`: `graphics/php84-gd`): модули официальных портов коммита версии и PECL, встроенные в исходники форка, без «pecl»: `phpXY-redis`, `phpXY-igbinary`, `phpXY-memcached`, `phpXY-memcache`, `phpXY-imagick`, `phpXY-gmagick`, `phpXY-mcrypt`, `phpXY-ssh2`, с 7.4 — `phpXY-swoole`, `phpXY-openswoole` и `phpXY-excimer`; OPcache — тоже модуль (`phpXY-opcache`), json — до 7.4 (`php74-json`), mysqlnd тоже (`phpXY-mysqlnd`: на нём модули баз данных). 65 на версию, у 7.4 — 67, у 5.6 — 64 (с вариантами с OpenSSL, ниже); список одной версии: `pkg search -r az '^php84-'` |

- openssl в двух видах, один из двух: `phpXY-openssl` и `phpXY-openssl-legacy` (с
  legacy-провайдером OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- ftp, mysqlnd, swoole и openswoole без OpenSSL, и у каждого вариант с OpenSSL базы,
  один из двух на модуль (aZ, 10.11.2026): `phpXY-ftp-openssl` (FTP через SSL),
  `phpXY-mysqlnd-openssl`, `phpXY-swoole-openssl`, `phpXY-openswoole-openssl`.
  `phpXY-mysqlnd` делает TLS к серверу через модуль openssl, когда сайт его просит, и
  без входа caching_sha2_password и sha256_password (MySQL 8 и новее; у MariaDB их нет):
  они есть в `phpXY-mysqlnd-openssl`. Модули на mysqlnd идут с одним из двух:
  `phpXY-mysqli-openssl`, `phpXY-pdo_mysql-openssl` (у 5.6 ещё `php56-mysql-openssl`),
  `phpXY-swoole-openssl` и `phpXY-openswoole-openssl` — с `phpXY-mysqlnd-openssl`.
  Swoole 6.2 (8.2–8.4) без OpenSSL не собирается: там `phpXY-swoole` тоже с ним.
- `phpXY-swoole` и `phpXY-openswoole` ставятся оба; ini у openswoole выключен (у них
  одни и те же классы), его сообщение пакета говорит, как переключить.
- `phpXY-imagick` и `phpXY-gmagick` ставятся оба, но в один PHP их грузить нельзя (у
  GraphicsMagick и ImageMagick одинаковые имена функций): ini у gmagick выключен, а при
  установке создаётся CLI-профиль gmagick (`/usr/local/etc/php74-gmagick`: gmagick включён,
  imagick выключен; `php74-profile gmagick script.php`); при удалении пакета профиль остаётся.
- Не собираются: модули, которым нужна библиотека портов (enchant, imap, ldap, odbc,
  pdf, pdo_dblib, pdo_firebird, pdo_odbc, pdo_pgsql, pgsql, pspell, snmp).
- Особая сборка (статический PHP, опции конкретного сервера) — не порт здесь: её делает
  `az-menu.sh` из [azsupport/php-src](https://github.com/azsupport/php-src).

## Порты

- **`az/az`**: пакет `az`, библиотеки `/usr/local/az`, собранные из примерно 40
  официальных портов закреплённого коммита скриптом [`tools/az-build.sh`](tools/az-build.sh)
  ([`az/az/files/deps.conf`](az/az/files/deps.conf)). Два дерева: `/usr/local/az`
  (разделяемые, SONAME и run path `/usr/local/az/lib`, без ldconfig), с ними линкуется
  каждый пакет: наши порты линкуются с разделяемыми библиотеками друг друга, без
  статических и встроенных копий того, что есть в другом нашем порту (aZ, 10.11.2026);
  и `/usr/local/az/static` (статические, position independent), только для статических
  сборок PHP из `az-menu.sh`; у каждого свой
  `bin/pkg-config`, `VERSIONS` в `share/doc/az`, лицензии в `LICENSES/`. Собирается
  прямо в `/usr/local/az` сборочной машины (от root, `NEED_ROOT`) и пакует это дерево.
  Зависимостей нет.
- **`ftp/curl`**: пакет `curl` вместо официального: `bin/curl` и `lib/libcurl.so.4`
  (наружу только `curl_*`) — libcurl всех пакетов (модуль curl PHP, git: libcurl одна,
  aZ 10.11.2026), опции официального порта, против разделяемых библиотек az
  ([`tools/curl-build.sh`](tools/curl-build.sh)). Сборка и работа: az.
- **`multimedia/ffmpeg`**: пакет `ffmpeg` вместо официального: `bin/ffmpeg` и
  `bin/ffprobe` (библиотеки FFmpeg внутри них), только с тем, что нужно видеосайтам
  ([`multimedia/ffmpeg/files/ffmpeg.conf`](multimedia/ffmpeg/files/ffmpeg.conf)),
  линкуются с x264, dav1d и libwebp из az. Сборка и работа: az.
- **`graphics/ImageMagick6`**: `bin/convert6`, `identify6`, `mogrify6`, `composite6` и
  остальные, рядом с ImageMagick 7, линкуются со своими библиотеками в
  `/usr/local/az/lib`: только JPEG, PNG, WebP, GIF, HEIC и AVIF, с нашей policy. Сборка и
  работа: az.
- **`graphics/ImageMagick7`**: пакет `ImageMagick7` вместо официального: `bin/magick` и
  его имена, те же форматы и policy, линкуются с его разделяемыми `libMagickCore-7.so` и
  `libMagickWand-7.so` в `/usr/local/az/lib`, с ними же линкуется imagick из PHP
  (`MagickWand-config` там же); его статические библиотеки и `MagickWand-config` — в
  `/usr/local/az/static`, для статического imagick из `az-menu.sh`. Сборка и работа: az.
- **`graphics/GraphicsMagick`**: пакет `GraphicsMagick` вместо официального: `bin/gm`,
  собран как наш ImageMagick, только JPEG, PNG, WebP, GIF, BMP, HEIC и AVIF; файла
  политики у него нет — её заменяют зарегистрированные кодеки и пустой `delegates.mgk`
  (`files/graphicsmagick.conf`). `gm` линкуется с его разделяемыми `libGraphicsMagick` и
  `libGraphicsMagickWand` (префикс символов `Gm`) в `/usr/local/az`, с
  `GraphicsMagick-config`, с ними же линкуется gmagick в PHP
  (`--with-gmagick=/usr/local/az`); статические библиотеки — в `/usr/local/az/static`,
  для статического gmagick из `az-menu.sh`. Сборка и работа: az.
- **`misc/mc`**: пакет `mc` вместо официального: Midnight Commander с редактором,
  subshell, кодировками и SFTP, без X11, переводов и Aspell
  ([`misc/mc/files/mc.conf`](misc/mc/files/mc.conf): что и почему), GLib собирает
  статически [`tools/mc-build.sh`](tools/mc-build.sh) (с GLib линкуется только mc),
  libssh2, libintl и libiconv — разделяемые из az, PCRE2 — из `pcre2`. zip, jar, 7z, rar
  и образы ISO открываются как
  каталог через [`files/ubsdtar`](misc/mc/files/ubsdtar) на `tar` базовой системы
  (libarchive), без Perl, 7-Zip и unrar; Perl, zip и GNU diff, если поставлены, дают своё
  (запись в zip, хелперы deb и rpm, `mcdiff`).
- У этих семи: версия официального порта на закреплённом коммите (или из строки take
  его conf) со штампом сборки как `PORTREVISION`; все distfile — в фазе fetch; тесты после
  установки: [`tools/ffmpeg-test.sh`](tools/ffmpeg-test.sh),
  [`imagemagick-test.sh`](tools/imagemagick-test.sh), [`curl-test.sh`](tools/curl-test.sh),
  [`az-test.sh`](tools/az-test.sh), [`mc-test.sh`](tools/mc-test.sh).
- **`devel/pcre2`** и **`devel/pcre`**: официальные порты как есть
  ([`Mk/az-official.mk`](Mk/az-official.mk)), PCRE2 10.49 и PCRE 8.45 (его последний
  релиз): PCRE для PHP (7.4–8.4 `--with-external-pcre`, 5.6 `--with-pcre-regex`), Apache,
  git, wget, mc (GLib) и MariaDB, потом и nginx (aZ, 10.11.2026).
- **`devel/git`**: git без Perl (send-email, svn, скрипты cvs), Python, Tcl/Tk, gettext,
  expat (`git http-push`), man-страниц, пользователя и скрипта rc.d git daemon; HTTPS через
  наш `curl`, PCRE2 (`git grep -P`) из `pcre2`, iconv из libc.
- **`www/apache24`** и **`www/mod_maxminddb`**: Apache 2.4.70 только с prefork (модулем)
  и модулями серверов (и cgi, env; всё остальное выключено), без SSL, APR и APR-util из az
  (разделяемые: те же, что у mod_php), PCRE2 из `pcre2`; mod_maxminddb с libmaxminddb из az.
- **`databases/memcached`** и **`databases/memcached-openssl`**: memcached без TLS, SASL,
  DTrace и документации, libevent из az; вариант с TLS на OpenSSL базы; ставится один из
  двух.
- **`databases/mariadb1011-server`** и **`databases/mariadb1011-client`**: MariaDB 10.11 с
  опциями aZ (из движков опций только InnoDB; без GSSAPI, wsrep, RocksDB, Spider,
  Mroonga, S3, CONNECT с ODBC и XML, HashiCorp Vault, AWS key management), сокет
  `/tmp/mysql.sock` вкомпилирован в сервер и клиентскую библиотеку и прописан в
  `my.cnf.sample` (`/tmp` на серверах — диск в памяти, tmpmfs), PID-файл — в
  `/var/run/mysql`; PCRE2 из `pcre2`, lz4, zstd и fmt из az, zlib (не своя копия
  MariaDB), OpenSSL и libedit базы.
- **`ftp/vsftpd-ext`** и **`ftp/vsftpd-ext-openssl`**: vsftpd-ext со своим скриптом rc.d
  (RC_SCRIPT); вариант с SSL (VSFTPD_SSL, OpenSSL базы); ставится один из двух.
- **`dns/bind920`** и **`dns/bind-tools`**: BIND 9.20, как в официальном дереве утилиты —
  ведомый порт серверного, с опциями aZ: TCP_FASTOPEN и IDN, без GSSAPI, DNSTAP, LMDB
  (`rndc addzone` хранит зоны в файле `.nzf`), каналов статистики (STATS_JSON,
  STATS_XML), FIXED_RRSET и LARGE_FILE; без man-страниц и заголовков библиотек BIND.
  `named` со скриптом rc.d и `/usr/local/etc/namedb`, как в официальном порту; утилиты
  (dig, host, nslookup, delv, nsupdate, утилиты DNSSEC) с IDN. libuv, liburcu, nghttp2
  (DNS over HTTPS) и libidn2 из az, OpenSSL, zlib и libedit базы.
- **`multimedia/qt-faststart`**: `bin/qt-faststart` из `tools/qt-faststart.c` FFmpeg 9.0.2
  (public domain): официальный порт удалён 30.06.2022 (то же делает ffmpeg `-movflags
  +faststart`); оставлен для совместимости, пока нужен (aZ, 10.11.2026).
- У этих: тесты после установки — [`tools/servers-test.sh`](tools/servers-test.sh) (git
  grep -P, Apache с модулями серверов на своём порту, memcached, MariaDB на сокете по
  умолчанию `/tmp/mysql.sock`, named со своей зоной — dig по UDP, TCP и по имени IDN,
  rndc, библиотеки каждого).
- **`lang/phpXY`** и **`www/mod_phpXY`** (5.6, 7.4, 8.1, 8.2, 8.3, 8.4): ядро `phpXY` и
  модуль Apache `libphpXY.so`, каждый — из официального порта коммита своей версии
  (таблица выше); PCRE2 — из `devel/pcre2` (у 5.6 PCRE из `devel/pcre`), а не встроенная
  в исходники форка (aZ, 10.11.2026).
- **Порты модулей** `phpXY-<модуль>` (59 на версию, у 7.4 — 61): имена без «pecl», origin как у официальных
  портов или наши (`graphics/php74-gd`, `databases/php74-redis`), ini
  `ext-NN-<модуль>.ini`, у openswoole и gmagick выключен.
- **Компилятор PHP** (все версии, aZ 09.11.2026): ядра, модули Apache и модули собирает
  GCC 16 из портов (`lang/gcc16`), только как зависимость сборки: ни одному файлу не нужна
  библиотека GCC (`-static-libgcc`, путь поиска библиотек только `/usr/local/az/lib`).
  Zend VM PHP 7 и новее с GCC держит свои регистры в глобальных регистровых переменных,
  с clang — нет: CLI 7.4 быстрее, чем с clang 19 базовой системы, на 33–44%, 8.3 — на
  36–38% без OPcache и на 5–15% с OPcache и его JIT
  ([bench.sh](https://github.com/azsupport/php-src/blob/master/tools/bench.sh) из php-src).
  Модули с C++ (intl, swoole, openswoole), а также imagick и gmagick (они линкуют
  OpenMP-рантайм компилятора) остаются на clang базовой системы. Какой компилятор у
  пакета, говорит его аннотация `az_cc` (`pkg info -A php74`);
  [`Mk/Uses/azgcc.mk`](Mk/Uses/azgcc.mk).

## Раскладка PHP на сервере

Версии рядом, ничего общего между ними; для 7.4 (у остальных так же со своим номером
и API их модулей: 5.6 `20131226`, 8.1 `20210902`, 8.2 `20220829`, 8.3 `20230831`,
8.4 `20240924`):

| | |
|---|---|
| Программы | `bin/php74`, `bin/php-cgi74`, `bin/phpize74`, `bin/php-config74`, `sbin/php-fpm74` |
| Настройки | `etc/php74/`: `php.ini` (из `php.ini-production`, изменённый сохраняется), `php.ini-production`, `php.ini-development`, `php-fpm.conf` (pid `/var/run/php-fpm74.pid`, лог `/var/log/php-fpm74.log`), `php-fpm.d/www.conf` (`listen /var/run/php-fpm74.sock`, владелец и группа `www`, права 0660) |
| Модули | `lib/php/20190902/<модуль>.so`, грузятся из `etc/php74/conf.d/ext-<NN>-<модуль>.ini` (из его `.ini.sample`, изменённый сохраняется; `NN`: 10 OPcache, 18 session, 20 json и модуль, которому не нужен другой, 30 — которому нужен) |
| Заголовки | `include/php74/php/...`; заголовки модуля — в `include/php74/php/ext/<модуль>/` |
| Файлы сборки | `lib/php74/build` |
| php-fpm | `etc/rc.d/php_fpm74` (`php_fpm74_enable`), чтобы php-fpm нескольких версий работали одновременно |
| Apache | `libexec/apache24/libphp74.so`, `etc/apache24/modules.d/280_mod_php74.conf` |
| Данные | `share/php74`, man-страницы с суффиксом в `share/man` |

## Сервер и репозиторий az

Репозиторий — это файлы релиза `az-fbsd15-amd64-v3` этого репозитория
(`az-fbsd15-amd64-v2` для процессора без AVX2). Его каталог подписан ключом aZ;
[`keys/az.pub`](keys/az.pub) — его открытый ключ (тот же ключ, что
[`freebsd/az.pub`](https://github.com/azsupport/php-src/blob/master/freebsd/az.pub) в
azsupport/php-src; SHA-256
`2620217e69f7bf680f4e78d51fd2135bb55dbd8709fa0b78cd217975a801c4e6`).

На сервере от root репозиторий записывает
[`az-menu.sh`](https://github.com/azsupport/php-src/blob/master/README.ru.md#az-menush-пакеты-и-что-войдёт-в-php)
из azsupport/php-src: x86-64-v3, если `cc -march=native` знает у процессора AVX2, BMI2,
FMA, F16C, LZCNT и MOVBE, иначе x86-64-v2; открытый ключ — в
`/usr/local/etc/pkg/keys/az.pub`, репозиторий — в `/usr/local/etc/pkg/repos/az.conf`,
потом `pkg update -r az`. Он пишет, какой уровень взял и почему, и SHA-256 ключа (тот,
что выше):

```sh
fetch https://github.com/azsupport/php-src/releases/download/az-menu/az-menu.sh
sh az-menu.sh --repo
```

То же вручную, для x86-64-v3 (для x86-64-v2 — `amd64-v2` в адресе); `sha256` должен
показать SHA-256 выше:

```sh
mkdir -p /usr/local/etc/pkg/repos /usr/local/etc/pkg/keys
fetch -o /usr/local/etc/pkg/keys/az.pub https://raw.githubusercontent.com/azsupport/ports/main/keys/az.pub
sha256 /usr/local/etc/pkg/keys/az.pub
printf '%s\n' 'az: { url: "https://github.com/azsupport/ports/releases/download/az-fbsd15-amd64-v3", signature_type: "pubkey", pubkey: "/usr/local/etc/pkg/keys/az.pub", priority: 100, enabled: yes }' > /usr/local/etc/pkg/repos/az.conf
pkg update -r az
```

`priority: 100`: для пакета, который есть в обоих (`curl`), pkg предпочитает az
репозиторию FreeBSD. `pkg update -r az` отказывается от каталога, подпись которого не
проверяется. В `ffmpeg`, `ImageMagick6`, `ImageMagick7` и `GraphicsMagick` из az нет
разделяемых библиотек официальных пакетов (`libavcodec.so`, `libMagickWand-7.so` в
`/usr/local/lib`, …): если они нужны другому пакету (`pkg info -r ffmpeg`), оставьте
официальный пакет.

PHP 7.4 с модулями:

```sh
pkg install -r az php74 mod_php74 php74-opcache php74-gd php74-mbstring php74-openssl-legacy
```

PHP 8.3 с модулями (ставится рядом с 7.4: свои `etc/php83`, `lib/php/20230831`, `include/php83`):

```sh
pkg install -r az php83 mod_php83 php83-opcache php83-gd php83-mbstring php83-openssl-legacy
```

PHP 8.1 с модулями (так же рядом: `etc/php81`, `lib/php/20210902`, `include/php81`):

```sh
pkg install -r az php81 mod_php81 php81-opcache php81-gd php81-mbstring php81-openssl-legacy
```

PHP 5.6 с модулями (так же рядом: `etc/php56`, `lib/php/20131226`, `include/php56`):

```sh
pkg install -r az php56 mod_php56 php56-opcache php56-gd php56-mbstring php56-openssl-legacy
```

PHP 8.2 с модулями (так же рядом: `etc/php82`, `lib/php/20220829`, `include/php82`):

```sh
pkg install -r az php82 mod_php82 php82-opcache php82-gd php82-mbstring php82-openssl-legacy
```

PHP 8.4 с модулями (так же рядом: `etc/php84`, `lib/php/20240924`, `include/php84`):

```sh
pkg install -r az php84 mod_php84 php84-opcache php84-gd php84-mbstring php84-openssl-legacy
```

Программы:

```sh
pkg install -r az curl ffmpeg ImageMagick6 ImageMagick7 mc
```

Несвободный FFmpeg: `ffmpeg-nonfree` (multimedia/ffmpeg с кодировщиком AAC `libfdk_aac` —
для форматов старых сайтов с `-c:a libfdk_aac`) никому нельзя передавать (FFmpeg с
`--enable-nonfree`), поэтому в релизе его нет никогда. Workflow
[`ffmpeg-nonfree.yml`](.github/workflows/ffmpeg-nonfree.yml) собирает его из
[`nonfree/ffmpeg/Makefile.in`](nonfree/ffmpeg/Makefile.in) и кладёт по scp на
`pkg.azsupport.com` — отдельный репозиторий pkg под паролем (HTTP Basic auth), подписанный
тем же ключом. Сервер подключает его рядом с az (пароль пользователя `pkg` — в адресе;
файл — только для root):

```sh
printf '%s\n' 'az-nonfree: { url: "https://pkg:PASSWORD@pkg.azsupport.com/az-nonfree/fbsd15-amd64-v3", signature_type: "pubkey", pubkey: "/usr/local/etc/pkg/keys/az.pub", priority: 100, enabled: yes }' > /usr/local/etc/pkg/repos/az-nonfree.conf
chmod 600 /usr/local/etc/pkg/repos/az-nonfree.conf
pkg update -r az-nonfree
pkg install -r az-nonfree ffmpeg-nonfree
```

`ffmpeg-nonfree` встаёт вместо `ffmpeg` (те же файлы: pkg удаляет `ffmpeg`).

php-fpm 7.4:

```sh
sysrc php_fpm74_enable=YES
service php_fpm74 start
```

## Как собирается

### tools/build.sh

[`tools/build.sh`](tools/build.sh) собирает пакеты фреймворком портов той машины, на
которой запущен, от root на FreeBSD: в ВМ FreeBSD 15.1 workflow или на сборочном
сервере FreeBSD.

```sh
git clone https://github.com/azsupport/ports.git
cd ports
sh tools/build.sh
sh tools/install-php.sh 7.4
sh tools/check-php.sh 7.4
```

Только некоторые порты (с портами этого дерева, которые им нужны), заново и тогда,
когда их пакет уже есть, другой уровень, дерево портов сборочного сервера:

```sh
sh tools/build.sh lang/php74 www/mod_php74
sh tools/build.sh --force lang/php74
env AZ_CPUTYPE=x86-64-v2 sh tools/build.sh
env AZ_PORTSDIR=/usr/ports sh tools/build.sh
env AZ_JOBS=1 sh tools/build.sh
env AZ_DRYRUN=1 sh tools/build.sh
env AZ_CONFIGURE_CHECK=1 sh tools/build.sh --force
```

Что он делает, по логике poudriere:

- официальное дерево на закреплённом коммите (git, глубина 1) в `work/freebsd-ports`,
  переиспользуется, когда оно на этом коммите (`AZ_PORTSDIR`: дерево берётся как есть,
  с предупреждением, если оно на другом коммите), это дерево — `OVERLAYS` поверх него;
- `work/make.conf` из [`tools/make.conf.in`](tools/make.conf.in) — make.conf серверов
  aZ (`CPUTYPE` уровня, `CFLAGS=-O3 -pipe -fno-strict-aliasing`, фреймворк добавляет
  `-fstack-protector-strong`; `JPEG_PORT=graphics/mozjpeg`; `OPTIONS_UNSET` для X11,
  Wayland, GUI, DBus, CUPS, отладки, тестов, документации и man-страниц) с путями
  прогона, отдаётся make как `__MAKE_CONF`: `/etc/make.conf` сборочного сервера не
  читается и не меняется, а сохранённые там `make config` опции на сборку не влияют
  (свой `PORT_DBDIR`);
- очередь: порты и порты этого дерева, которые им нужны (origin из их `*_DEPENDS`,
  которые наши), каждый после тех, что ему нужны;
- порт, у origin которого в репозитории есть пакет с тем же `az_hash`, заново не
  собирается (инкрементальная сборка; [Версии и пересборки](#версии-и-пересборки)),
  если нет `--force`; упавший порт останавливает порты, которым он нужен (пропущены, с
  причиной);
- каждый порт: официальные пакеты его зависимостей — `pkg install` (из репозитория
  FreeBSD машины), наши — `pkg add` пакетов, собранных раньше, потом
  `make clean package` с `USE_PACKAGE_DEPENDS_ONLY=yes` (из исходников собирается только
  сам порт); его лог и время;
- до `AZ_JOBS` портов одновременно (по умолчанию 4), волнами: волна — порты, у которых
  все нужные им порты этого дерева готовы; сначала ставятся зависимости портов волны,
  порт за портом (порт, чья установка убрала то, что получил порт волны перед ним,
  уходит в следующую волну), потом их `make package` идут одновременно, и пока они
  идут, нет ни `pkg add`, ни `pkg install`, ни `pkg delete`; первыми — самые большие,
  у каждого свой лог и свой каталог пакетов; сводка — в порядке очереди;
  `results/waves.txt`. `AZ_JOBS=1` — порт за портом, как раньше; `AZ_DRYRUN=1` —
  только показать волны прогона, ничего не собирая;
- порт с `NEED_ROOT` (`az/az`: собирается прямо в `/usr/local/az`): один, его
  установленный пакет удаляется перед сборкой, новый ставится после неё;
- `AZ_CONFIGURE_CHECK=1`, проверка configure: после сборки каждого порта PHP (ядра,
  `mod_phpXY`, все модули, и PECL, и те, что собирает clang), и тогда, когда сборка
  упала после своего configure, — ещё раз `make configure` в своём рабочем каталоге,
  тем же компилятором, с ошибками C из GCC 14+ и clang 16+ как предупреждениями
  (`-Wno-error=implicit-function-declaration` и подобные, сколько их знает компилятор,
  в `CFLAGS_<arch>`, которую фреймворк добавляет к `CFLAGS` порта: ничего в `Mk/` и ни
  один хэш не меняется), и [`tools/configure-check.sh`](tools/configure-check.sh)
  сравнивает оба: результат каждого `checking` в `config.log` (с ошибкой компилятора
  теста в строгом), `main/php_config.h` или `config.h` модуля, переменные
  сгенерированного `Makefile`. Разница — тест configure, результат которого зависит от
  этих ошибок (printf без `<stdio.h>` в тесте «if using GNU libiconv» `ext/iconv`:
  `php74-iconv` без `-liconv` и `ICONV_SUPPORTS_ERRNO`), у пакета — строгий результат;
  `results/configure-check.txt` и раздел отчёта; порты, которые прогон берёт из
  репозитория, не конфигурируются (`--force` — все порты PHP);
- репозиторий (`--repo <каталог>`, по умолчанию `work/repo`): по пакету на origin, новые
  на место старых, `pkg repo`, подпись ключом из `AZ_PKG_KEY_FILE` и проверка
  ([`tools/pkg-repo-sign.sh`](tools/pkg-repo-sign.sh));
- результаты в `results/`: `summary.txt` (строка на порт, в конце `result: OK` или
  `result: FAIL (...)`), `queue.txt`, `hashes.txt`, `waves.txt`, `logs/`,
  `configure-check.txt` (`AZ_CONFIGURE_CHECK`).

### Версии и пересборки

Как у poudriere: каждый порт, который прогон собирает, получает `AZ_STAMP` (час начала
прогона, `yymmddhh` UTC) как `PORTREVISION`, чтобы каждая сборка была для pkg
обновлением (`php74-7.4.33_26110817`), и `AZ_HASH`, который попадает в пакет
аннотацией `az_hash` (`pkg info -A php74`): SHA-256 файлов порта (с файлами его
`MASTERDIR`), makefile из `Mk/` этого дерева, которые он читает (`Mk/bsd.overlay.mk`;
`Mk/Uses/php.mk` — только у портов PHP), официального коммита, уровня и
`tools/make.conf.in`, и `az_hash` каждого порта этого дерева, который ему нужен. Порт, чей пакет в репозитории
с тем же `az_hash`, заново не собирается; изменение порта пересобирает его и все порты,
которым он нужен (изменение `az/az` — всё, что его линкует). Файлы, которые порт
перечисляет в `AZ_HASH_NOT_FOR_DEPENDENTS` (ставятся и нужны только при работе), входят
в его собственный `az_hash`, но не в хеш портов, которым он нужен, и не в хеш его
slave-портов: изменение блока php.ini, скрипта профилей, rc.d-скрипта или pkg-message
`lang/php74` пересобирает `php74`, а не модули и `mod_php74` (pkg берёт зависимость по
имени, не по версии). Ревизии руками не поднимаются.

Порт, который линкует библиотеки `az/az`, берёт в свой `az_hash` не хеш всего az, а хеш
последней из своих библиотек по порядку `az/az/files/deps.conf`
([`tools/az-lib-hashes.sh`](tools/az-lib-hashes.sh)): общая часть az, собственные строки
библиотеки (её строки `lib` и `take`, её функции сборки в `tools/az-build.sh` и
`files/curl/build-libcurl.sh`, её патчи и дистфайлы) и хеши библиотек перед ней. Его
библиотеки — по файлам az в его зависимостях (`${AZ_PREFIX}/lib/libxml2.so:az/az` —
libxml2) и по `AZ_HASH_LIBS` его Makefile (программа, которая линкует больше, чем
называет: `ftp/curl`, `multimedia/ffmpeg`). Комментарии, строки `upstream` и
документация az в этот хеш не входят. Новая библиотека добавляется в конец строк `lib`:
тогда пересобираются только az и порты, которые её линкуют (aZ, 10.11.2026).

[`tools/install-php.sh`](tools/install-php.sh) `<версия>` ставит пакеты PHP версии из
этого репозитория, как сервер (ядро, `mod_php74` и модули, с `php74-openssl`), а
[`tools/check-php.sh`](tools/check-php.sh) `<версия>` их проверяет
(`results/check-php-<версия>.txt`); `install-php.sh --openssl` ставит варианты с OpenSSL
на места их модулей, для `CHECK_TAG=openssl check-php.sh` (`check-php-<версия>-openssl.txt`).

### Workflow

[`build.yml`](.github/workflows/build.yml), «Build the packages of the repository az»:
https://github.com/azsupport/ports/actions/workflows/build.yml, кнопка
**Run workflow**.

| Вход | |
|---|---|
| `release` | релиз FreeBSD для ВМ, `15.1` |
| `cputype` | `x86-64-v3` (по умолчанию), `x86-64-v2` или `both` (по job на каждый); на уровень и ветку — одна job за раз, уровни — параллельно (у каждого свой релиз и кэш) |
| `ports` | порты для сборки через пробел; пусто — все |
| `force` | собирать их и тогда, когда их пакет с тем же `az_hash` уже есть в релизе |
| `jobs` | сколько портов собирать одновременно (`AZ_JOBS`, по умолчанию 4; `1` — порт за портом) |
| `configure_check` | проверка configure (`AZ_CONFIGURE_CHECK`, по умолчанию выключена): каждый собранный порт PHP конфигурируется ещё раз, нестрого, и сравнивается; с `force` — все порты PHP |
| `publish` | опубликовать репозиторий, когда всё собралось и все проверки прошли (по умолчанию выключено: репозиторий, который читают серверы, публикуется по слову aZ) |

Он берёт репозиторий прошлого прогона (actions/cache, сохраняется и тогда, когда прогон
упал, чтобы прогон, упавший на PHP, оставил `az` и библиотеки) и файлы релиза
`az-fbsd15-amd64-<уровень>`, проверяет порты `make -V` против разреженного официального
дерева на раннере ([`tools/check-tree.sh`](tools/check-tree.sh), bmake: FAIL
останавливает прогон там), сверяет curl пакета az с curl PHP из azsupport/php-src
([`tools/curl-sync-check.sh`](tools/curl-sync-check.sh): строки данных
`az/az/files/curl.conf` и `curl-deps.conf` и патчи `curl/` — с теми, что в `freebsd/` на
его master; отличие тоже останавливает прогон там), запускает `tools/build.sh` в ВМ FreeBSD
([vmactions/freebsd-vm](https://github.com/vmactions/freebsd-vm)), потом для каждой
версии PHP, пакет которой собран, ставит её пакеты из нового репозитория и проверяет их
(`tools/install-php.sh`, `tools/check-php.sh`; по строке в `results/checks.txt`),
отчитывается
([`tools/report.sh`](tools/report.sh): сводка прогона, аннотация на каждый упавший порт;
[`tools/runs-report.sh`](tools/runs-report.sh): отчёт в ветку `runs` azsupport/azsupport)
и публикует: сначала пакеты, каталог последним, потом убирает то, чего в репозитории
больше нет. Публикуется только подписанный каталог.

Секреты (https://github.com/azsupport/ports/settings/secrets/actions, кнопка
**New repository secret**):

| Секрет | |
|---|---|
| `PKG_SIGNING_KEY` | закрытый ключ RSA (PEM) к `keys/az.pub`: попадает в ВМ только файлом, используется `pkg repo` и удаляется |
| `RUNS_TOKEN` | fine-grained токен с Contents на чтение и запись в azsupport/azsupport, для отчётов |

### Библиотеки с GCC

[`lib-bench.yml`](.github/workflows/lib-bench.yml), «Libraries of az with the base clang and
with GCC 16»: https://github.com/azsupport/ports/actions/workflows/lib-bench.yml, кнопка
**Run workflow**.

| Вход | |
|---|---|
| `repeat` | раунды, по умолчанию 9 (для вердикта нужно не меньше 7) |
| `libs` | библиотеки через пробел; пусто — все |

Станет ли PHP быстрее, если собрать C-библиотеки `az` компилятором gcc16 из пакетов, а не
базовым clang 19? (aZ 09.11.2026: библиотека переходит на GCC 16, если она быстрее хотя бы
на 2% в том, что делают сайты.) Меряются libxml2, libxslt, oniguruma, sqlite3, gd,
freetype2, png, mozjpeg, expat, libzip и lcms2; не меряются библиотеки со своим ассемблером
или SIMD (zstd, brotli, lz4, webp, dav1d, x264, OpenSSL, libsodium, gmp), библиотеки на C++
(ICU, libheif, libde265, libmemcached), ImageMagick и GraphicsMagick (OpenMP). В ВМ FreeBSD
15.1 ([`tools/lib-bench.sh`](tools/lib-bench.sh)): PHP 8.3 и его модули из репозитория az,
каждая библиотека собирается так, как её собирает `tools/az-build.sh` (исходники и патчи её
порта на коммите `deps.conf`, её опции, CFLAGS az), трижды: clang19, gcc16 так, как он пошёл
бы в сборку (`-std=gnu17 -static-libgcc -fno-semantic-interposition`), и gcc16-si — то же без
`-fno-semantic-interposition` (умолчание GCC при `-fPIC`: экспортируемые функции библиотеки в
ней самой не инлайнятся), потом бенчмарки
[`tools/lib-bench.php`](tools/lib-bench.php) (DOM, SimpleXML, XMLReader, ext/xml, XSL,
`mb_ereg*`, SQLite3 и PDO, GD: JPEG, PNG, ресемплинг и TrueType, ZipArchive) и программ
(xmllint, speedtest1, cjpeg, djpeg, драйверы [`tools/lib-bench.c`](tools/lib-bench.c) для
expat и lcms2): каждый прогон — с одной сборкой одной библиотеки впереди библиотеки az
(`LD_LIBRARY_PATH`, подтверждается ldd и файлами, которые процесс отобразил в память),
библиотека релиза — контроль; прогоны около 3 секунд, варианты вперемешку, на одном
закреплённом CPU. Отчёт (лог шага Report, summary джоба, ветка `runs` azsupport/azsupport):
для каждой библиотеки и бенчмарка медиана секунд каждого варианта, изменение gcc16 и gcc16-si
относительно clang19 с интервалом около 95%, разброс, а для каждой библиотеки — вердикт gcc16
«>= 2% faster». Ничего не публикует.

## Правила портов

- Порт этого дерева начинается с официального порта нужного коммита и меняет только то,
  что нужно; Makefile говорит, чем он отличается от официального и почему.
- Makefile в стиле дерева портов (табы, порядок переменных, как хочет portlint);
  скрипты для FreeBSD `/bin/sh` с утилитами базы.
- Зависимость от пакета `az` — по файлу, никогда не `LIB_DEPENDS` (для
  `/usr/local/az/lib` нет подсказок ldconfig):
  `BUILD_DEPENDS+= ${LOCALBASE}/az/lib/libxml2.so:az/az`, и то же в `RUN_DEPENDS`.
- Наши порты берут `PORTREVISION= ${AZ_STAMP}`: изменение порта само по себе — новая
  сборка ([Версии и пересборки](#версии-и-пересборки)).
- Пакеты сейчас собираются `make package` в ВМ;
  [poudriere](https://github.com/freebsd/poudriere) — потом, на сборочном сервере
  FreeBSD: он собирает оверлей сам, а первая часть `tools/make.conf.in` — его make.conf.
