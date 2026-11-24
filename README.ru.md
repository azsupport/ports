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
  [`5cfbd76929a9`](https://github.com/freebsd/freebsd-ports/tree/5cfbd76929a928d723da4ae457b836b206d58224)
  (main от 24.11.2026; `ports_commit` в [`tools/build.sh`](tools/build.sh), перед сборкой
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
  sqlite3, expat, lcms2 и xxhash из az, Python 3.12 и Redis 8.2 — тоже на GCC
  ([Библиотеки и программы с GCC](#библиотеки-и-программы-с-gcc)).
- PHP 5.6, 7.4, 8.1, 8.2, 8.3 и 8.4, под x86-64-v3 и x86-64-v2 (процессор без AVX2 —
  релиз `az-fbsd15-amd64-v2`).

## Пакеты

Имена и origin как у портов, файлы по путям портов:

| Пакет | Origin | Что |
|---|---|---|
| `az` | `az/az` | библиотеки сборок в `/usr/local/az`: `lib` (разделяемые, с run path `/usr/local/az/lib`, без ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`), с ними линкуется каждый пакет; статические — в `/usr/local/az/static`, только для особых сборок `az-menu.sh`. OpenSSL, zlib и bzip2 — из базовой системы |
| `curl` | `ftp/curl` | `bin/curl` и `libcurl.so.4`, вместо пакета порта, с SCP и SFTP (libssh2 из az, без старых алгоритмов SSH: MAC на MD5, 3DES, RC4, Blowfish, CAST; так же у `ssh2` PHP и SFTP в `mc`); его `libcurl.so.4` — libcurl всех пакетов (модуль curl PHP, git) |
| `curl-impersonate` | `ftp/curl-impersonate` | curl-impersonate 2.3.2, сборка из исходников: `curl-impersonate` и обёртки `curl_<браузер>` (рукопожатия TLS, HTTP/2 и HTTP/3 Chrome, Edge, Firefox, Safari и Tor Browser), `libcurl-impersonate.so` (для `py-curl-cffi`; не libcurl остальных пакетов); BoringSSL, nghttp2 1.63.0, nghttp3 и ngtcp2 внутри неё (с патчами апстрима под браузеры), c-ares, brotli, zstd, libidn2 (IDN) и libpsl (PSL) из az, zlib базы |
| `py312-curl-cffi` | `ftp/py-curl-cffi` | curl_cffi 0.17.0 для нашего `python312`, на `libcurl-impersonate.so` из `curl-impersonate`: имперсонация `yt-dlp` (`--impersonate`); официальный порт как есть |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` и `ffprobe` только с теми форматами, что нужны видеосайтам |
| `ImageMagick6` | `graphics/ImageMagick6` | программы ImageMagick 6 под обычными именами (`convert`, `identify`, ...); конфликтует с `ImageMagick7` и `ImageMagick67` |
| `ImageMagick7` | `graphics/ImageMagick7` | программы ImageMagick 7 (`magick` и обычные имена ссылками на него); конфликтует с `ImageMagick6` и `ImageMagick67` |
| `ImageMagick67` | `graphics/ImageMagick67` | программы обоих: ImageMagick 7 как в `ImageMagick7` и ImageMagick 6 с 6 на конце (`convert6`, `identify6`, ...); конфликтует с `ImageMagick6` и `ImageMagick7` |
| `libimagemagick6` | `graphics/libimagemagick6` | библиотеки ImageMagick 6 (`libMagickCore-6`, `libMagickWand-6` в `/usr/local/az/lib`), их заголовки, `.pc`, `MagickWand-config` (`/usr/local/az/libexec/ImageMagick-6/bin`) и `etc/ImageMagick-6` с нашей политикой; зависимость `ImageMagick6`, `ImageMagick67` и модуля imagick6 |
| `libimagemagick7` | `graphics/libimagemagick7` | библиотеки ImageMagick 7 (`libMagickCore-7.so`, `libMagickWand-7.so` в `/usr/local/az/lib`), их заголовки, `.pc`, `MagickWand-config` и статическая сборка, и `etc/ImageMagick-7` с нашей политикой; зависимость `ImageMagick7`, `ImageMagick67` и модуля imagick7 |
| `GraphicsMagick` | `graphics/GraphicsMagick` | GraphicsMagick (`gm`) с форматами нашего ImageMagick; его библиотеки в `/usr/local/az/lib`, с ними линкуются `gm` и модуль gmagick |
| `mc` | `misc/mc` | Midnight Commander: редактор, subshell, кодировки, SFTP; экран — S-Lang из az (умолчание mc; без 200 мс ESCDELAY ncurses на каждый Esc), GLib из `glib`, libssh2 из az, PCRE2 из `pcre2`; zip, 7z, rar и образы ISO — через `tar` базовой системы (имена zip из Windows — в CP866); исправления mc после 4.8.33 ([`misc/mc/files/*.patch`](misc/mc/files), у каждого — источник): переполнение `%cd` длинным именем в архиве, Reget, портивший следующие файлы копирования, мышь при `TERM=xterm` (Gentoo) и падение при протаскивании, выход из subshell на FreeBSD (NetBSD), своё приглашение tcsh, приглашение с байтами не UTF-8, дескриптор канала subshell (Debian), строки «ls -l» с именами в один байт (Alpine), ftp: переподключение после простоя, пароль из `~/.netrc`; копии, клонирующие блоки на ZFS (`copy_file_range`, upstream #5082); наши: ни одной своей строки mc (его cd, инициализация, меню пользователя) в истории subshell на tcsh |
| `pcre2`, `pcre` | `devel/pcre2`, `devel/pcre` | PCRE2 10.49 и PCRE 8.45, официальные порты: PCRE всех пакетов (PHP, Apache, git, wget, mc, MariaDB; потом nginx) |
| `git` | `devel/git` | git без Perl, Python, Tcl/Tk, gettext, man-страниц и git daemon; HTTPS через наш `curl`, `git grep -P` с `pcre2` |
| `apache24`, `apache24-mod_maxminddb` | `www/apache24`, `www/mod_maxminddb` | Apache 2.4 только с prefork и модулями серверов (и cgi, env, headers), без SSL; APR и libmaxminddb из az |
| `apache24-mod_fastcgi` | `www/mod_fastcgi` | модуль FastCGI нашего Apache 2.4 (aZ, 19.11.2026): официальный порт как есть ([`Mk/az-official.mk`](Mk/az-official.mk)) |
| `apache24-suexec` | `www/apache24-suexec` | suexec нашего Apache 2.4 отдельным пакетом, для одного сервера, где CGI и FastCGI сайтов работают от их пользователей (aZ, 19.11.2026): `libexec/apache24/mod_suexec.so` и `sbin/suexec` (setuid root, запускать может только `www`) того же Apache, собранного с SUEXEC, к httpd пакета `apache24`; каталог `/var/www`, остальное — умолчания портов |
| `memcached`, `memcached-openssl` | `databases/memcached`, `databases/memcached-openssl` | memcached без TLS, SASL и DTrace, libevent из az; вариант с TLS; ставится один из двух |
| `gearmand`, `gearmand-openssl`, `libgearman` | `devel/gearmand`, `devel/gearmand-openssl`, `devel/libgearman` | Gearman 2.2.0 с исправлениями master после него: сервер очереди задач gearmand (постоянная очередь — в SQLite из az; libevent из az), его вариант с TLS, ставится один из двух; libgearman (клиентская библиотека, с TLS) и утилиты gearman и gearadmin — их берут оба сервера и модули `phpXY-gearman` |
| `mariadb1011-server`, `mariadb1011-client` | `databases/mariadb1011-server`, `databases/mariadb1011-client` | MariaDB 10.11.20 (новее официальной 10.11.19): из движков опций только InnoDB, без GSSAPI; сокет `/tmp/mysql.sock` вкомпилирован и прописан в `my.cnf` |
| `postgresql18-server`, `postgresql18-client`, `postgresql18-contrib` и их `-openssl` | `databases/postgresql18-server`, `-server-openssl`, `-client`, `-client-openssl`, `-contrib`, `-contrib-openssl` | PostgreSQL 18.7 двумя цепочками, ставится одна каждого компонента: без OpenSSL и `-openssl` с OpenSSL базовой системы (pgcrypto и sslinfo — только в `contrib-openssl`); JIT на LLVM (`devel/llvm19`), ICU, LZ4, ZSTD, XML, `-O3 -funroll-loops`; без PAM, LDAP, GSSAPI, pl*, NLS, DTrace; часовые пояса базовой системы; ICU, lz4, zstd, libxml2 и libxslt из az, libedit базовой системы для psql |
| `llvm19` | `devel/llvm19` | LLVM 19.1.7 для JIT PostgreSQL: только бэкенд X86 и clang (без lld, lldb, MLIR, OpenMP, Polly, Flang, compiler-rt, доп. утилит), libLLVM целиком со всей оптимизацией, Release; без zstd |
| `gcc16`, `gcc16-libs` | `lang/gcc16`, `lang/gcc16-libs` | GCC 16.2.0 (в официальном порту 16.1.0), только C и C++, двумя пакетами: `gcc16-libs` — одни библиотеки времени выполнения (`libgcc_s`, `libstdc++`, `libatomic`, `libgomp` в `lib/gcc16`, для `arcconf`), `gcc16` — компилятор (нужны `gcc16-libs` и binutils портов): profiledbootstrap с LTO (bootstrap-lto-lean), Graphite, встроенные gmp, mpfr, mpc и isl; без Fortran, Objective-C, libgccjit, multilib, санитайзеров, libitm, libquadmath, плагинов, NLS; CFLAGS сборки во всех стадиях и библиотеках; порты, собираемые GCC, до ближайшей полной пересборки берут официальный `gcc16` |
| `vsftpd-ext`, `vsftpd-ext-openssl` | `ftp/vsftpd-ext`, `ftp/vsftpd-ext-openssl` | vsftpd-ext со своим скриптом rc.d, исправлением CVE-2021-3618 (ALPACA) из vsftpd 3.0.5, нашими — CVE-2026-119567, CVE-2026-119568 и `deny_file`, и из Debian: `deny_file` по реальному пути (CVE-2015-1419), модули PAM, запускающие процессы, и из openSUSE: stderr сеанса не на соединении FTP; вариант с SSL; ставится один из двух |
| `3proxy`, `3proxy-openssl` | `net/3proxy`, `net/3proxy-openssl` | 3proxy 0.9.9.3 LTS-линии, новее официальной 0.9.5 ради исправлений безопасности, с именами и путями официального порта; PAM, PCRE2 из `pcre2`, без TLS; вариант с TLS; ставится один из двух |
| `postfix`, `postfix-mysql` | `mail/postfix`, `mail/postfix-mysql` | Postfix 3.11.7 с опциями aZ: EAI (SMTPUTF8, ICU из az), PCRE2 из `pcre2`, TLS (OpenSSL базы) и TLSRPT (`libtlsrpt`); без LMDB, CDB, blocklistd, LDAP, Cyrus SASL; вариант с таблицами MySQL (клиент из `mariadb1011-client`); ставится один из двух; пакет ставит `/usr/local/etc/mail/mailer.conf` (Postfix вместо `sendmail`, `mailq` и `newaliases` у mailwrapper), если его нет, а существующий не трогает (aZ, 19.11.2026) |
| `dovecot`, `dovecot-mysql` | `mail/dovecot`, `mail/dovecot-mysql` | Dovecot 2.3.21.1, ветка 2.3, пока её поддерживает апстрим, с опциями aZ: без GSSAPI, LDAP, libwrap, FTS, Lua, LZ4; zstd из az; вариант с драйвером SQL для MySQL; ставится один из двух; исправления безопасности после 2.3.21.1 из Ubuntu noble и RHEL 10 |
| `redis82`, `redis82-openssl` | `databases/redis82`, `databases/redis82-openssl` | Redis 8.2.11 (ветка 8.x с долгой поддержкой апстрима), без модулей: JEMALLOC включён (свой jemalloc: активная дефрагментация), без TLS; вариант с TLS (OpenSSL базы); ставится один из двух; конфиги aZ: `redis.conf.sample` (основной кеш), `redis-session.conf.sample` (сессии PHP), на 127.0.0.1, без снимков |
| `mongodb80` | `databases/mongodb80` | MongoDB 8.0.38 Community (база Rocket.Chat 8): ThinLTO, `-O3` и `-march` уровня, AVX2 SpiderMonkey по уровню (без NOAVX), без отладочных символов; аллокатор системы, без libunwind; OpenSSL базы, curl из `ftp/curl`; сборка, которую остановило время прогона, продолжается в следующем прогоне (дисковый кэш Bazel) |
| `nginx-devel`, `nginx-devel-stream`, `nginx-devel-image-filter`, `nginx-devel-lua`, `nginx-devel-stream-lua`, `nginx-devel-vts`, `nginx-devel-cache-purge`, `nginx-devel-testcookie`, `nginx-devel-dav`, `nginx-devel-dav-ext`, `nginx-devel-vod`, `nginx-devel-passenger` | `www/nginx-devel`, `www/nginx-devel-stream`, `www/nginx-devel-image-filter`, `www/nginx-devel-lua`, `www/nginx-devel-stream-lua`, `www/nginx-devel-vts`, `www/nginx-devel-cache-purge`, `www/nginx-devel-testcookie`, `www/nginx-devel-dav`, `www/nginx-devel-dav-ext`, `www/nginx-devel-vod`, `www/nginx-devel-passenger` | nginx 1.31.9, вкомпилены brotli, headers-more и geoip2 (`--with-compat`); stream, image_filter, Lua (LuaJIT), VTS, cache_purge, testcookie, WebDAV (DAV, dav-ext), VOD (nginx-vod-module 1.11.2, HLS и DASH на лету, без FFmpeg) и Phusion Passenger 6.2.2 (его агент — из `ruby34-passenger-nginx`) — отдельными пакетами (`load_module`) |
| `lua51-vips`, `lua51-base64` | `graphics/lua51-vips`, `converters/lua51-base64` | lua-vips 1.1-12 и lbase64 1.5.3 для LuaJIT nginx (`share/lua/5.1`) |
| `aria2`, `aria2-ssh2` | `www/aria2`, `www/aria2-ssh2` | aria2 1.37.0: Metalink и XML-RPC (libxml2 из az), асинхронный DNS (c-ares из az), BitTorrent, HTTPS (OpenSSL базы), опрос событий kqueue; без libuv, без SQLite (cookies браузеров), без NLS и статической сборки; SFTP (libssh2 из az) — только в `aria2-ssh2`, ставится один из двух |
| `php56-composer` … `php84-composer` | `devel/php56-composer` … `devel/php84-composer` | Composer 2.11.2 (для PHP 5.6 — 2.2.32, его LTS-линия) как `bin/composerXY`, который запускает его через `bin/phpXY`: по одному на каждый PHP, рядом друг с другом |
| `bind920`, `bind-tools` | `dns/bind920`, `dns/bind-tools` | BIND 9.20: DNS-сервер `named` с TCP Fast Open, без GSSAPI, DNSTAP, LMDB и каналов статистики; dig, host, nslookup, delv, nsupdate и утилиты DNSSEC, с IDN |
| `unbound` | `dns/unbound` | Unbound 1.26.2 — валидирующий рекурсивный кеширующий DNS-резолвер, вместо local_unbound базы (aZ, 20.11.2026): резолвер самого сервера, с ECDSA, libevent, потоками и TCP Fast Open; скрипт rc.d unbound |
| `vips` | `graphics/vips` | libvips 8.18 для скриптов Lua в nginx, перекодирующих картинки на лету: JPEG (mozjpeg), PNG, WebP, HEIC (чтение), AVIF (чтение и запись), GIF, с ICC-профилями, EXIF и SIMD (Highway); `vips`, `vipsthumbnail`, `vipsheader`, `vipsedit` |
| `glib`, `libexif`, `cgif`, `libimagequant`, `highway` | `devel/glib20`, `graphics/libexif`, `graphics/cgif`, `graphics/libimagequant`, `devel/highway` | библиотеки `vips` (GLib — и `mc`, libimagequant — и libgd из az: LIQ, палитра `imagegif()` и `imagetruecolortopalette()` PHP 5.6–8.4; GPLv3 или новее): GLib 2.88 разделяемая, без introspection, NLS, документации и man-страниц, на libffi, libintl и libiconv из az и PCRE2 из `pcre2`; остальные — официальные порты как есть (libexif без NLS) |
| `qt-faststart` | `multimedia/qt-faststart` | qt-faststart (атом moov в начало MP4), возвращён для совместимости: официальный порт удалён 30.06.2022 |
| `yt-dlp` | `www/yt-dlp` | yt-dlp последнего релиза GitHub, а не версии официального порта (aZ, 12.11.2026): [`yt-dlp-update.yml`](.github/workflows/yt-dlp-update.yml) смотрит раз в 6 часов, сам берёт новый релиз в порт (и его `yt-dlp-ejs` — нашим, когда официальный порт отстаёт), собирает и публикует, когда больше ничего не отличается от релиза ([yt-dlp из GitHub](#yt-dlp-из-github)); с нашим `ffmpeg` и, опцией IMPERSONATE (включена по умолчанию, aZ, 16.11.2026), нашим `py312-curl-cffi` для `--impersonate` |
| `node24`, `node24-npm`, `node24-yarn`, `node24-corepack` | `www/node24`, `www/npm-node24`, `www/yarn-node24`, `www/corepack-node24` | Node.js 24.22.3 (для yt-dlp и Kibana 6; выпуск безопасности от 11.11.2026, новее официального порта с 24.22.2) с npm, Yarn 1 и corepack: `node` на brotli, c-ares, ICU, nghttp2, libuv, zstd и SQLite из az, OpenSSL (с хранилищем сертификатов базы) и zlib базы и библиотеках ниже; без DTrace; npm и Yarn — официальные порты как есть, corepack — наш (node24-corepack: 0.36 работает только на Node 22 и 24, у Node 18 — node18-corepack; один из двух) |
| `node18`, `node18-npm`, `node18-yarn`, `node18-corepack` | `www/node18`, `www/npm-node18`, `www/yarn-node18`, `www/corepack-node18` | Node.js 18.20.8, последний 18.x (конец поддержки 30.04.2025), для старого проекта, снова в портах (официальный порт удалён 2025-09-03), с npm 10.9.10 и corepack 0.33.0 (последние для Node 18) и Yarn 1.22.19 (тот же, что `node24-yarn`): `node` на brotli, c-ares, ICU, nghttp2 и libuv из az, llhttp 9.4.3 из `www/llhttp`, OpenSSL и zlib базы; исправления уязвимостей после конца поддержки — как их несёт SUSE для своего nodejs18 18.20.8 (SLE 15 SP4 LTSS; с llhttp 9) и, перенесённые на 18, исправления из выпусков безопасности Node.js 22 и 24 за октябрь и ноябрь 2026 (dns, http.Agent, tls.checkServerIdentity, https.Agent, zlib, crypto в снимках запуска; исправления кода TLS и HTTP/2, в том числе серверного; промежуточные сертификаты eMudhra/emSign со скомпрометированными ключами отвергаются в любой цепочке), с undici 6.29.1 из Node.js 22.23.4 вместо 5.29.0 (список, а также что не взято и почему, — в `www/node18/Makefile`); у npm — исправление CVE-2026-9496 (из pacote 21.5.1) в обоих его pacote и brace-expansion 2.1.8, ip-address 10.7.6, picomatch 4.0.7 и postcss-selector-parser 7.1.8 из реестра npm вместо встроенных в него 2.0.2, 10.1.0, 4.0.3 и 7.1.1 (их 17 CVE, а также не взятые CVE glob, minimatch и sigstore, исправленные только в новой основной версии, — в `www/npm-node18/Makefile`); один из `node18` и `node24`, вместе с их npm, yarn и corepack (`pkg install node18 node18-npm node18-yarn` убирает те, что от node24; не вместе с `kibana6`, которому нужен node24) |
| `libada`, `llhttp`, `nbytes`, `libnghttp3`, `libngtcp2`, `simdjson`, `uvwasi`, `hdr_histogram` | `devel/libada`, `www/llhttp`, `www/nbytes`, `www/libnghttp3`, `net/libngtcp2`, `devel/simdjson`, `devel/uvwasi`, `graphics/hdr_histogram` | библиотеки, которые Node.js встраивает, портами этого дерева (aZ, 11.11.2026): официальные порты как есть, `uvwasi` — наш, на libuv из az, `libada` — наш: ada 4.1.1, новее официальной 3.4.4 (aZ, 16.11.2026: 4.0.0, та, что в Node.js 24.22.3; 22.11.2026: 4.1.1, её исправления памяти) |
| `python312`, `py312-sqlite3`, `mpdecimal`, `python3` | `lang/python312`, `databases/py-sqlite3`, `math/mpdecimal`, `lang/python3` | Python 3.12 — версия Python по умолчанию дерева портов — под именами официальных пакетов (aZ, 11.11.2026), чтобы пакеты `py312-*` репозитория FreeBSD (в том числе для yt-dlp) ставились поверх него и работали с ним: опции официального пакета (LTO, PYMALLOC, IPV6), кроме NLS (выключен, как везде: 16.11.2026), libffi, expat и readline из az, OpenSSL, ncurses, zlib, bzip2 и liblzma базы, libmpdec из `mpdecimal` (официальный порт как есть); его модуль sqlite3 — `py312-sqlite3` — на SQLite из az; без gdbm и tkinter; `python3` — официальный метапорт как есть (`bin/python3` и другие ссылки на Python 3.12) |
| `ruby34`, `ruby34-gems`, `ruby34-rake`, `ruby34-etc`, `ruby34-logger`, `ruby34-rack`, `ruby34-rackup`, `ruby34-passenger-nginx` | `lang/ruby34`, `devel/ruby-gems`, `devel/rubygem-rake`, `devel/rubygem-etc`, `devel/rubygem-logger`, `www/rubygem-rack`, `www/rubygem-rackup`, `www/rubygem-passenger` | Ruby 3.4.13 (исправления Regexp и String от 18.11.2026, раньше дерева портов) — версия Ruby по умолчанию дерева портов, под именами официальных пакетов (aZ, 20.11.2026), наш: GMP и YJIT вкл., RDOC выкл., libffi, GMP и libyaml из az, без libunwind; RubyGems 4.0.24 и гемы, нужные Passenger, — официальные порты как есть; Phusion Passenger 6.2.2 для nginx (агент `nginx-devel-passenger`), наш: только вкус nginx, без APR, на libcurl нашего `curl` |
| `erlang-runtime28`, `rabbitmq` | `lang/erlang-runtime28`, `net/rabbitmq` | RabbitMQ 4.4.1 на Erlang/OTP 28.5 (aZ, 20.11.2026): официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)), Erlang с KQUEUE, OPENSSL (crypto базы) и SHARING, без CHUNKS, CORBA, SCTP, DTrace, Java, ODBC и WX |
| `procmail` | `mail/procmail` | procmail с master апстрима (BuGlessRB/procmail на 8b379c4, 12.08.2026: v3.24 и 13 коммитов после него, среди них укрепление работы с памятью 2026 года; 3.24.20260812) — локальная доставка с фильтрами (aZ, 20.11.2026; master — aZ, 21.11.2026), наш: из патчей официального порта для 3.22 — только нужные 3.24 (пути, сборка) |
| `py312-pip`, `py312-wheel`, `py312-packaging`, `py312-supervisor` | `devel/py-pip`, `devel/py-wheel`, `devel/py-packaging`, `sysutils/py-supervisor` | для нашего `python312`: pip 26.3, новее официальной 23.3.2 (CVE-2025-8869: её собственная распаковка tar-архивов не проверяет, куда ведут символические ссылки); wheel, packaging и supervisor — официальные порты как есть |
| `py312-spf-engine`, `py312-pyspf`, `py312-authres`, `py312-pymilter`, `py312-dnspython`, `libmilter` | `mail/py-spf-engine`, `mail/py-pyspf`, `mail/py-authres`, `mail/py-pymilter`, `dns/py-dnspython`, `mail/libmilter` | SPF-сервер политик Postfix (`policyd-spf`) и `pyspf-milter` со всем, что им нужно, на нашем `python312` (aZ, 19.11.2026): официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)), `py312-pymilter` — на libmilter из `mail/libmilter` (его умолчание), а не из базы, которая может быть собрана без sendmail |
| `opendkim` | `mail/opendkim` | DKIM-milter Postfix (aZ, 19.11.2026): официальный порт ([`Mk/az-official.mk`](Mk/az-official.mk)) с FILTER (milter, rc.d `milter-opendkim`) на libmilter из `mail/libmilter`, резолвер базы вместо UNBOUND (без `unbound`), без LUA; остальные опции выключены, как в официальном умолчании |
| `proxychains-ng` | `net/proxychains-ng` | программы через цепочку SOCKS- и HTTP-прокси (`proxychains`; aZ, 19.11.2026): официальный порт как есть |
| `rtorrent`, `libtorrent` | `net-p2p/rtorrent`, `net-p2p/libtorrent` | BitTorrent-клиент в консоли и его библиотека (aZ, 19.11.2026): официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)), XML-RPC на tinyxml2 внутри rtorrent, kqueue, OpenSSL базы, libcurl нашего `curl` |
| `vm-bhyve`, `bhyve-firmware`, `edk2-bhyve`, `grub2-bhyve` | `sysutils/vm-bhyve`, `sysutils/bhyve-firmware`, `sysutils/edk2`, `sysutils/grub2-bhyve` | управление ВМ bhyve, vm-bhyve 1.7.5 (aZ, 19.11.2026): официальные порты ([`Mk/az-official.mk`](Mk/az-official.mk)), vm-bhyve с BHYVE_FIRMWARE (UEFI-гости: edk2-bhyve из `sysutils/edk2`), GRUB2_BHYVE (гости с загрузкой через grub: `grub2-bhyve`), TMUX (консоли гостей в tmux) и EXAMPLES (шаблоны гостей: `vm init` кладёт их `default.conf` в `.templates`) |
| `amnezia-tools`, `amnezia-kmod` | `net/amnezia-tools`, `net/amnezia-kmod` | `awg`, `awg-quick` и rc.d-скрипт `amnezia` AmneziaWG (WireGuard с защитой от распознавания; aZ, 19.11.2026) и его модуль ядра `if_amn`: официальные порты как есть; модуль собирается по исходникам ядра выпуска (gitup `releng/15.1` в сборке), один на GENERIC и ядро aZ; без `amneziawg-go` — `awg-quick` зовёт его только без модуля |
| `virtualbox72`, `virtualbox72-kmod`, `virtualbox72-additions` | `emulators/virtualbox-ose-72` (флейвор nox11), `emulators/virtualbox-ose-kmod-72`, `emulators/virtualbox-ose-additions-72` (флейвор nox11) | VirtualBox 7.2.22 без рабочего стола (aZ, 20.11.2026): официальные порты ([`Mk/az-official.mk`](Mk/az-official.mk)); VirtualBox (`VBoxManage`, `VBoxHeadless`, `VBoxSVC`, rc.d-скрипты `vboxheadless` и `vboxwatchdog`) с AIO, TPM, UDPTUNNEL и VNC (пакет расширения VNC), без PYTHON, R0LOGGING, VBOXIMG, VDE и WEBSERVICE (ALSA, DBUS, DEBUG, DOCS, GUESTADDITIONS, NLS, PULSEAUDIO, QT6 и X11 в флейвор nox11 не входят), на libjpeg (mozjpeg), libpng и libxml2 из az и libcurl нашего `curl`, libvpx, libogg, libvorbis, libtpms и libvncserver — официальные пакеты (поэтому ставится без `-r az`, как `yt-dlp`); модули ядра `vboxdrv`, `vboxnetflt` и `vboxnetadp` (rc.d-скрипт `vboxnet`) с VIMAGE, без DEBUG и INVARIANTS, собираются по исходникам ядра выпуска (gitup `releng/15.1` в сборке), один на GENERIC и ядро aZ; Guest Additions для гостя FreeBSD (`vboxguest`, `vboxvfs`, `VBoxService`, `VBoxControl`), без X11, DBUS и DEBUG |
| `axel`, `dmidecode`, `smartmontools` | `ftp/axel`, `sysutils/dmidecode`, `sysutils/smartmontools` | axel 2.17.14 (загрузка в несколько соединений), dmidecode 3.7 (таблицы SMBIOS), smartmontools 7.5 (`smartctl`, `smartd`; aZ, 19.11.2026): официальные порты как есть, без NLS и DOCS |
| `stunnel` | `security/stunnel` | stunnel 5.82 — TLS-обёртка для сетевых служб без шифрования (aZ, 19.11.2026): официальный порт ([`Mk/az-official.mk`](Mk/az-official.mk)) с IPV6 и моделью потоков PTHREAD, без FIPS, LIBWRAP (TCP wrappers), моделей FORK и UCONTEXT и документации (aZ, 23.11.2026); OpenSSL базы, rc.d-скрипт `stunnel`; без `bin/stunnel3` — обёртки синтаксиса stunnel 3.x на Perl (Perl нужен только для сборки; aZ, 23.11.2026) |
| `github-act-runner`, `gh` | `devel/github-act-runner`, `devel/gh` | self-hosted раннер GitHub Actions на Go, github-act-runner 0.13.0 от ChristopherHX (aZ, 20.11.2026: сборки в jail FreeBSD; у раннера GitHub, actions/runner, сборки под FreeBSD нет), и gh 2.103.3, утилита командной строки GitHub (шаги этих сборок зовут `gh api`): официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)); github-act-runner — статический бинарник (CGO_ENABLED=0), gh — на git из `devel/git`, телеметрия выключена, пока её не включит сам пользователь (патч Fedora и значение `disabled` по умолчанию у её параметра конфигурации; включают `gh config set telemetry enabled` или `GH_TELEMETRY=1`); JavaScript-действия идут на `node` из `node24` |
| `php56-phpmyadmin`, `php74-phpmyadmin` … `php84-phpmyadmin` | `databases/phpmyadmin`, `databases/phpmyadmin5`, `databases/phpmyadmin5-php74` … `-php83` | phpMyAdmin на каждый PHP (aZ, 19.11.2026): 4.9.11 для PHP 5.6 (ветка для 5.5–7.4), 5.2.3 для 7.4 и 8.1–8.4; официальные порты с модулями их опций по умолчанию (bz2, gd, mbstring, zip, zlib) и обязательными, кроме mysqli и openssl: их у нас по два варианта (`phpXY-mysqli` или `-mysqli-openssl`, `phpXY-openssl` или `-openssl-legacy`), ставится один из двух; на сервере один phpMyAdmin (`www/phpMyAdmin`) |
| `elasticsearch6` | `textproc/elasticsearch6` | Elasticsearch 6.8.23, последний 6.x, для легаси-сайтов, снова портом (официальный порт убран 01.01.2023, на 6.8.16): его rc-скрипт с профилями; на нашем OpenJDK 21 (`java/openjdk21`; aZ, 12.11.2026: один JDK с OpenSearch; в `jvm.options` — `-Djava.security.manager=allow`, без которого JDK 18 и новее не даёт включить Security Manager), четыре строки предупреждения JDK о `System::setSecurityManager` и две о провайдере локалей COMPAT из вывода запуска убраны; без ML; файлы ошибок при падении JVM — в `/var/log/elasticsearch`; без лишней записи (aZ, 11.11.2026): нет дампа кучи при OutOfMemoryError, нет журнала GC, в `/tmp` только один `/tmp/elasticsearch` (нет `hsperfdata`; это временный каталог, `elasticsearch_tmpdir` в `rc.conf`, создаётся заново при каждом запуске), нет архивов старых журналов (файлы журналов из `log4j2.properties` Elastic как есть, ротация только по размеру, старый файл сразу удаляется: ни файлов с датой, ни `.gz`); `xpack.ssl.cipher_suites` без четырёх наборов, которых в OpenJDK 17 и 21 больше нет (нет `[ERROR]` о неподдерживаемых шифрах при запуске); `jvm.options` для OpenJDK 17 и новее, один файл на все серверы (`-XX:UseAVX=2` только для JDK 10: на JDK 17 она давала предупреждение при каждом запуске на процессоре без AVX2; `-XX:+ExitOnOutOfMemoryError`; у каждой правки в файле указан источник); куча сервера — `elasticsearch_heap="4g"` в `rc.conf` (`-Xms` и `-Xmx`), без неё — 31g из `jvm.options` (ниже порога сжатых указателей; для сервера с 64 ГБ памяти и больше: при меньшей памяти задать `elasticsearch_heap`, не больше половины памяти); утилиты при ручном запуске (`elasticsearch-keystore`, `elasticsearch-plugin` и другие) тоже ничего не оставляют в `/tmp`; лицензии: дистрибутив по умолчанию, с X-Pack, поэтому Apache 2.0 и Elastic License 1.0 (его `LICENSE.txt`): бесплатное использование, без права распространения |
| `kibana6` | `textproc/kibana6` | Kibana 6.8.23, последний 6.x, для легаси-сайтов вместе с `elasticsearch6`, снова портом (официальный порт убран 31.03.2022, на 6.8.16, с Node.js 10): на нашем `node24`, с возвращённым из Node.js 10 тем, что ему нужно (`util.is*` и `util.log`, MD4 webpack 4 как MD5, необработанный отказ промиса — предупреждение, IPv4-адрес `localhost` первым), с исправлениями hapi для Node.js 11 и 16 в его hapi 17 и с `re2` (метки Timelion) как node-re2 1.27.1, собранным под этот Node.js, со встроенными в него RE2 2025-11-05 и abseil 20260817.0 (node-re2 с другими останавливает сборку); его rc-скрипт с daemon(8), от пользователя www, `reload` для журнала; без Machine Learning и Reporting (Chromium и PhantomJS для FreeBSD нет), бандлы браузера собраны при сборке под этот набор плагинов; лицензии: дистрибутив по умолчанию, с X-Pack, поэтому Apache 2.0 и Elastic License 1.0 (его `LICENSE.txt`): бесплатное использование, без права распространения |
| `perl5` | `lang/perl5.42` | Perl 5.42 под именем пакета FreeBSD (aZ, 11.11.2026), чтобы с ним работали пакеты `p5-*` из репозитория FreeBSD: официальный порт как есть (потоки, MULTIPLICITY, 64-битные целые, разделяемая libperl), без DTrace, как все сборки здесь (его пробы есть только в ядре Perl: XS-модули пакетов FreeBSD с ним загружаются и работают, `tools/perl-test.sh`) |
| `openjdk21`, `jna`, `apache-ant` | `java/openjdk21`, `devel/jna`, `devel/apache-ant` | JDK для `elasticsearch6` (и для `opensearch217` и `opensearch219` до 23.11.2026, когда они ушли из этого дерева), наш (aZ, 11.11.2026: чтобы сервер с Elasticsearch не получал ничего от рабочего стола; 12.11.2026: один JDK для всех: OpenSearch 2.x и Elasticsearch 6 не работают на JDK 24 и новее, где Security Manager отключён насовсем, а OpenSearch 3.x нужен JDK не ниже 21): OpenJDK 21 без графики в `/usr/local/openjdk21`, без X11, звука, шрифтов и javavmwrapper (нет `/usr/local/bin/java`), на libjpeg, FreeType и Little CMS из az; JNA без X11 и JAWT, на libffi из az, его библиотека — ещё и файлом `/usr/local/lib/jna/libjnidispatch.so`, который загружают `elasticsearch6`, `opensearch217` и `opensearch219` (`-Djna.boot.library.path`, `-Djna.nounpack`: при запуске ничего не распаковывается), собран на 21 для Java 8; Ant — официальный порт — на нашем JDK 21, для сборки JNA (aZ, 12.11.2026: JNA и Ant — на 21). `openjdk21` и `jna` зависят только от `az` |
| `bash`, `bsddialog`, `bsnmp-ucd`, `portconfig`, `portmaster`, `rsync`, `screen`, `sudo`, `unzip`, `wget`, `yamdi`, `zip` | их официальные origin | утилиты серверов: официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)) с опциями aZ в Makefile каждого порта (`unzip` с ICONV — кириллические имена архивов Windows, и с исправлениями уязвимостей, которых нет в официальном порту, из Fedora: CVE-2014-8141 … CVE-2022-0530, zip-бомбы, и из Debian 6.0-31 и 6.0-32 и OpenBSD (`files/debian/`): CAN-2026-2034442 и CAN-2026-2034443 (переполнения кучи и стека), поле extra Unicode-пути короче 5 байтов (чтение за его край), CVE-2022-1271 в zipgrep, архивы ZIP64 из Windows, время из Unix-полей extra; а также образцы zipgrep с `\|`, ошибка закрытия распакованного файла, обрезанное поле extra, дескрипторы данных Zip64 из Java (madler `af0d07f`), `memmove()` в скользящем окне (OpenBSD, `files/openbsd/`), исправление CVE-2014-8139 в варианте, исправленном Info-ZIP (`unzip -t` на jar давал ошибку), `memmove()` для `\` в `UNZIP` (Fedora) и справка zipinfo (четыре `%c` патча ICONV официального порта без аргументов); `screen` с ncurses базы и сокетами в `~/.screen`, NOSOCKETDIR, и тремя исправлениями Debian (переполнение кучи при изменении размера, отступ в строке статуса, `defflow` после переподключения); `sudo` только с PAM, без AUDIT, LOGSRVD, SSL, NLS, с исправлениями CVE-2026-96512 (три коммита апстрима), CVE-2026-35535 (почтовая программа от root с группами пользователя) и файла `@includedir` с `:` в имени (коммиты апстрима `3e474c2`, `ff0b6be`, как их несёт Debian); `yamdi` с исправлением Debian для `-c`; `zip` с тремя исправлениями: с `-j` образцы `-i` и `-x` теряли пути (openSUSE), `memmove()` для `\` в `ZIP` (RHEL), смещения после имени с флагом UTF-8 (`zipnote` зависал; Gentoo); `bash` без NLS, с тремя исправлениями 5.3, как их несёт Gentoo: `wait` закончившегося фонового задания, подстановки команд при большом окружении, приглашение в однобайтовой локали, и исправлением openSUSE для байта 0x80–0xFF в `${…}` (bash53-019); `portmaster` только с дополнением для bash), `wget` и `rsync` наши, с разделяемыми библиотеками az (`wget`: IDN, PSL, без OPIE (вход S/KEY по FTP), исправления CVE-2026-15146, CVE-2026-58470, CVE-2026-58471 и CVE-2026-58472, как их несёт Ubuntu, CVE-2026-16599 (вход S/KEY, коммит апстрима `e9697d9`, как его несёт Fedora), CVE-2021-31879 (`Authorization:` и `Cookie:` из `--header` после редиректа уходят только на источник первого URL: патч openSUSE, как это делает curl) и обработчика SIGHUP (коммит апстрима `e1f2559`, как его несёт RHEL); `rsync` 3.5.2, раньше официального 3.5.1 ради исправлений безопасности: lz4, zstd, xxhash, без ICONV), PCRE2 из `pcre2` (`wget`) и OpenSSL базы; `portconfig`: диалог опций `make config` и portmaster (DIALOG4PORTS дерева пина), чтобы они не собирали его на сервере (aZ, 19.11.2026) |
| `tmux`, `keychain` | `sysutils/tmux`, `security/keychain` | tmux 3.8 — официальный порт с libevent из az (без LIBEVENT_STATIC; без UTF8PROC: ширину символов даёт libc FreeBSD, дистрибутивы берут utf8proc только для macOS), ncurses и utempter базы; keychain 2.9.8 — официальный порт как есть (sh перед ssh-agent базы; его 3.x переписан на Python, официальный порт его не берёт) |
| `tcl84` | `lang/tcl84` | Tcl 8.4.20, последний выпуск 8.4 (2013), для старого приложения aZ (19.11.2026): официальный порт freebsd-ports fc3b56ba75eb до его удаления (7fc25c874cfc, 21.11.2017), с его патчами, на фреймворке дерева пина; THREADS вкл, TCLMAN выкл, как в том порту; рядом с `lang/tcl86` (`tclsh8.4`, `libtcl84.so.1`, `lib/tcl8.4`, `include/tcl8.4`) |
| `ipmitool`, `mtr`, `trafshow`, `gitup` | `sysutils/ipmitool`, `net/mtr` (флейвор nox11), `net/trafshow`, `net/gitup` | утилиты старого сервера aZ: официальные порты с опциями aZ (`mtr` и `trafshow` с IPv6, `mtr` без GTK и JSON) и исправлениями, которых в них нет: `ipmitool` (его `shell` — на readline из az, а не на пакете `devel/readline`) — CVE-2011-4339 (PID-файл ipmievd доступен на запись всем), переполнение стека в `tsol` `options=no-timeout` в `chassis bootparam` (Debian) и время в отметках `sel get` (апстрим после 1.8.19, как в Ubuntu), `mtr` (setuid root) — CVE-2026-14461 (переполнение буфера при поиске ASN, как в Debian) и без привилегированного порта источника у UDP-проб (апстрим после 0.96) |
| `calc`, `ipcalc` | `math/calc`, `net-mgmt/ipcalc` | калькуляторы aZ (20.11.2026): calc 2.17.0.2 от Landon Curt Noll, калькулятор произвольной точности, — официальный порт с FULL (libcalc, libcustcalc, заголовки, файлы ресурсов и cscript) и HELP (файлы справки его `help`), без флейвора tiny, его командная строка — на readline из az (а не на пакете `devel/readline`); ipcalc 0.51 от Krischan Jodies, калькулятор адресов IPv4 на Perl, — официальный порт как есть ([`Mk/az-official.mk`](Mk/az-official.mk)) на `perl5` этого дерева |
| `fcgiwrap` | `www/fcgiwrap` | fcgiwrap 1.1.0, FastCGI-сервер, который запускает CGI-скрипты для nginx (aZ, 20.11.2026): официальный порт ([`Mk/az-official.mk`](Mk/az-official.mk)) на libfcgi из `fcgi-devkit` (`www/fcgi` этого дерева, официальный порт как есть), rc-скрипт `fcgiwrap` с профилями, и два исправления, которых в нём нет: родитель предзапущенных процессов крутится в обработчике SIGCHLD (апстрим после 1.1.0), а CGI-процесс неудачного запроса не останавливается (`kill()` с перепутанными аргументами; pull request #44 апстрима, как в Gentoo) |
| `net-snmp`, `mrtg`, `p5-SNMP_Session` | `net-mgmt/net-snmp`, `net-mgmt/mrtg`, `net-mgmt/p5-SNMP_Session` | агент и утилиты SNMP и графики трафика (aZ, 20.11.2026: для Nagios и MRTG): net-snmp 5.9.5.2 — официальный порт ([`Mk/az-official.mk`](Mk/az-official.mk)) на OpenSSL базовой системы и libpkg из `pkg`, его утилиты (snmpget, snmpwalk: Nagios) и libnetsnmp; snmpd на серверах aZ не запускается, но собран с MFD_REWRITES (ifXTable с 64-битными ifHCInOctets и ifHCOutOctets, которые MRTG берёт по SNMPv2c) — на случай запуска; без PERL, PERL_EMBEDDED, DUMMY, SMUX (без TCP-порта 199) и NEWSYSLOG; MRTG 2.17.10 — официальный порт с выключенными DOCS, EXAMPLES и SNMPV3 и без IPV6 (SNMP по IPv6: IO::Socket::INET6 и Socket6, на серверах aZ не нужен), но `rateup`, который рисует графики, — на libgd и libpng из az (а не на пакетах `graphics/gd` и `graphics/png`), и SNMP_Session 1.13 этого дерева (официальный порт как есть), без Pod::Parser и Module::CoreList (Pod::Usage и Module::CoreList — из ядра нашего perl 5.42), с двумя исправлениями апстрима после 2.17.10, как в Debian: CVE-2026-72694 (PID-файл `mrtg --daemon`, который root создавал и отдавал пользователю демона через символическую ссылку) и опции цели RouterUpTime |
| `arcconf` | `sysutils/arcconf` | arcconf 5.12.00 build 28542 Microchip (RAID Adaptec) — бинарник его архива для FreeBSD 15 с periodic-скриптом официального порта; `libstdc++.so.6` — из `gcc16-libs`, а не весь `lang/gcc14`; архив нельзя скачивать автоматически и зеркалировать: сборка берёт его из закрытого репозитория aZ, пакет раздавать можно |
| `fcron` | `sysutils/fcron` | fcron 3.4.1, новее официального 3.2.1 (aZ, 16.11.2026): официальный порт на 3.4.1, без документации и примеров |
| `ca_root_nss`, `cpu-microcode-intel`, `cpu-microcode-rc`, `rclone`, `fusefs-libs`, `fusefs-sshfs`, `fusefs-libs3`, `libtlsrpt` | их официальные origin | официальные порты как есть ([`Mk/az-official.mk`](Mk/az-official.mk)): корневые сертификаты Mozilla (NSS 3.134: официальный порт freebsd-ports b64078572ff3, после закреплённого коммита, скопирован в это дерево как есть, пока пин не сдвинется дальше него; aZ, 19.11.2026), микрокод процессоров Intel с RC и SPLIT (скрипт rc.d `cpu-microcode-rc` и разделённые файлы), rclone с `rclone mount` (libfuse 2 из `fusefs-libs`, с исправлением libfuse #571 для `-o remember`), sshfs 3.7.7 (libfuse 3 из `fusefs-libs3`, GLib из `glib`; с двумя исправлениями master после 3.7.7: скобочные IPv6-источники, цели readlink длиннее буфера FUSE), библиотека TLSRPT для `postfix` |
| `cpu-microcode-amd` | `sysutils/cpu-microcode-amd` | микрокод процессоров AMD: официальный порт с опциями `cpu-microcode-intel`, RC (скрипт rc.d из `cpu-microcode-rc`) и SPLIT (файлы семейств в `share/cpucontrol`), обе включены; `/boot/firmware/amd-ucode.bin` всегда; 20260926 (linux-firmware 9b858e5bb58d: новый `microcode_amd_fam1ah.bin`), новее официального 20251202 |
| `phpXY` | `lang/phpXY` | ядро PHP X.Y (`XY`: 56, 74, 81, 82, 83, 84): CLI, phpize |
| `apache24-phpXY` | `www/mod_phpXY` | модуль Apache `libphpXY.so` |
| `phpXY-fpm` | `www/phpXY-fpm` | FastCGI Process Manager `sbin/phpXY-fpm` с rc.d-скриптом `phpXY_fpm` (aZ, 21.11.2026: php-cgi и php-fpm — отдельными пакетами) |
| `phpXY-cgi` | `www/phpXY-cgi` | CGI `bin/phpXY-cgi` (для suexec и mod_fastcgi Apache) |
| `phpXY-<модуль>` | `<категория>/phpXY-<модуль>` | по пакету на модуль (`php84-gd`: `graphics/php84-gd`): модули официальных портов коммита версии и PECL, встроенные в исходники форка, без «pecl»: `phpXY-redis`, `phpXY-igbinary`, `phpXY-memcached`, `phpXY-memcache`, `phpXY-imagick`, `phpXY-gmagick`, `phpXY-mcrypt`, `phpXY-ssh2`, `phpXY-gearman` (libgearman из `libgearman`), с 7.4 — `phpXY-swoole`, `phpXY-openswoole` и `phpXY-excimer`; OPcache — тоже модуль (`phpXY-opcache`), json — до 7.4 (`php74-json`), mysqlnd тоже (`phpXY-mysqlnd`: на нём модули баз данных). у 7.4 и 8.1 — 71, у 8.2–8.4 — 69, у 5.6 — 66 (с вариантами, ниже); список одной версии: `pkg search -r az '^php84-'` |
| `phpXY-ioncube` | `devel/phpXY-ioncube` | ionCube Loader 15.5.1 для PHP X.Y (с 56 по 84): бинарник ionCube для FreeBSD как есть (`ioncube_loaders_fre_11_x86-64_15.5.1.tar.gz`, собран на FreeBSD 11 — ядру нужен `COMPAT_FREEBSD11`), `lib/php/<API>/ioncube_loader.so`, грузится первым из `etc/phpXY/conf.d/ext-05-ioncube.ini` (раньше `ext-10-opcache.ini`), лицензия ionCube — в `share/licenses/phpXY-ioncube/`; так же его ставят FreeBSD `devel/ioncube`, Remi `php-ioncube-loader` и Arch `php-ioncube_loader` |

- openssl в двух видах, один из двух: `phpXY-openssl` и `phpXY-openssl-legacy` (с
  legacy-провайдером OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- ftp, mysqlnd, swoole и openswoole без OpenSSL, и у каждого вариант с OpenSSL базы,
  один из двух на модуль (aZ, 10.11.2026): `phpXY-ftp-openssl` (FTP через SSL),
  `phpXY-mysqlnd-openssl`, `phpXY-swoole-openssl`, `phpXY-openswoole-openssl`.
  `phpXY-mysqlnd` делает TLS к серверу через модуль openssl, когда сайт его просит, и
  без входа caching_sha2_password и sha256_password (MySQL 8 и новее; у MariaDB их нет):
  они есть в `phpXY-mysqlnd-openssl`. Модули на mysqlnd идут с одним из двух:
  `phpXY-mysqli-openssl`, `phpXY-pdo_mysql-openssl` (у 5.6 ещё `php56-mysql-openssl`),
  `phpXY-openswoole-openssl` и `php74-swoole-openssl` — с `phpXY-mysqlnd-openssl`.
  Swoole 6.1 и 6.2 (8.1–8.4) mysqlnd не нужен (aZ, 11.11.2026: его опция только делала
  mysqlnd обязательным модулем, хуки mysqli и PDO MySQL работают и без неё), они идут с
  любым из двух; swoole 6.2 (8.2–8.4) без OpenSSL не собирается, поэтому `phpXY-swoole`
  с ним, а `phpXY-swoole-openssl` нет.
- redis четырьмя пакетами, один из четырёх (aZ, 11.11.2026; файлы одни и те же):
  `phpXY-redis` без сжатия, `phpXY-redis-lz4`, `phpXY-redis-zstd` и
  `phpXY-redis-lz4-zstd` с lz4 и zstd из az (`Redis::OPT_COMPRESSION` сайта; у 5.6 только
  `php56-redis`: phpredis 4.3.0 не умеет ни того, ни другого). Все — с igbinary и
  сессиями в Redis.
- gd у 5.6 ещё и `php56-gd-t1lib`, один из двух (aZ, 11.11.2026): с T1lib — шрифтами
  PostScript Type 1 у `imagepsloadfont()` и `imagepstext()` (из PHP 7.0 убраны), на libt1
  нашего `devel/t1lib`: официальный порт без X11 с исправлениями уязвимостей t1lib 5.1.2,
  которых в нём нет, как их несёт Gentoo (CVE-2010-2642, CVE-2011-0433, CVE-2011-5244,
  CVE-2011-0764, CVE-2011-1552, CVE-2011-1553, CVE-2011-1554).
- `phpXY-swoole` и `phpXY-openswoole` ставятся оба; ini у openswoole выключен (у них
  одни и те же классы), его сообщение пакета говорит, как переключить.
- `phpXY-imagick7` (или `phpXY-imagick6`) и `phpXY-gmagick` ставятся оба, но в один PHP их грузить нельзя (у
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
  прямо в `/usr/local/az` своего chroot (от root, `NEED_ROOT`) и пакует это дерево.
  Зависимостей нет.
- **`ftp/curl`**: пакет `curl` вместо официального: `bin/curl` и `lib/libcurl.so.4`
  (наружу только `curl_*`) — libcurl всех пакетов (модуль curl PHP, git: libcurl одна,
  aZ 10.11.2026), опции официального порта, против разделяемых библиотек az
  ([`tools/curl-build.sh`](tools/curl-build.sh)). Сборка и работа: az.
- **`ftp/curl-impersonate`** (aZ, 16.11.2026): curl-impersonate 2.3.2 от lexiforest вместо
  официального порта, сборка из исходников, программа и библиотека:
  `bin/curl-impersonate`, 47 обёрток `curl_<браузер>` (POSIX sh, без bash),
  `lib/libcurl-impersonate.so.4` (программа связана с ней) с заголовками в
  `include/curl-impersonate`, `curl-impersonate-config` и её `.pc`: раскладка
  официального порта, чтобы `ftp/py-curl-cffi` (ниже) собирался на ней. c-ares,
  brotli, zstd, libidn2 (IDN) и libpsl (PSL; aZ, 16.11.2026: как в `ftp/curl`) из az и
  zlib базы — разделяемые; библиотека — curl 8.23.0 с патчем
  апстрима, и только в ней, статически, со скрытыми символами: BoringSSL с патчем
  апстрима, nghttp2 1.63.0 (в 1.65 убраны приоритеты, которые шлёт HTTP/2 браузеров),
  nghttp3 1.15.0 и ngtcp2 1.20.0 с патчами апстрима (HTTP/3 браузеров); исправления
  CVE-2026-27135 (nghttp2), CVE-2026-40170 (ngtcp2) и conncache из `ftp/curl`; без
  статических библиотек; сертификаты CA базы. Сборка и работа: az.
- **`ftp/py-curl-cffi`** (aZ, 16.11.2026): пакет `py312-curl-cffi` нашего `python312`,
  официальный порт как есть ([`Mk/az-official.mk`](Mk/az-official.mk)): curl_cffi 0.17.0,
  его расширение — на `libcurl-impersonate.so` из `ftp/curl-impersonate` (ничего не
  скачивает), для `yt-dlp --impersonate` (yt-dlp 2026.10.26 берёт curl_cffi от 0.10.x до
  0.17.x); `py312-cffi` и `py312-certifi` — официальные пакеты. Сборка и работа:
  `curl-impersonate`, `python312`.
- **`multimedia/ffmpeg`**: пакет `ffmpeg` вместо официального: `bin/ffmpeg` и
  `bin/ffprobe` (библиотеки FFmpeg внутри них), только с тем, что нужно видеосайтам
  ([`multimedia/ffmpeg/files/ffmpeg.conf`](multimedia/ffmpeg/files/ffmpeg.conf)),
  линкуются с x264, dav1d, SVT-AV1 (запись AV1 и AVIF, aZ 11.11.2026) и libwebp из az.
  FFmpeg 9.1 раньше его порта (строка take в `ffmpeg.conf`; aZ, 22.11.2026: выпуск той же
  старшей ветки берём, когда в нём есть исправления безопасности): в нём исправления,
  которые патчи 9.0.2 здесь брали из release/9.0 и master (среди них CVE 2026 года,
  которые достают до собранного здесь), и исправления master по 19.11.2026; поверх —
  исправления кодера AAC из master
  ([`files/ffmpeg/fix-aacenc-*.patch`](multimedia/ffmpeg/files/ffmpeg), в каждом — коммит
  апстрима, что и зачем: восстановление коэффициентов раскладки 5.1, допустимая цепочка
  масштабных множителей кодера NMR, который в 9.1 по умолчанию, ограниченное число
  повторных кодирований кадра, который не помещается, вместо бесконечного).
  Сборка и работа: az.
- **`graphics/libimagemagick6`** и **`graphics/libimagemagick7`** (aZ, 14.11.2026):
  библиотеки ImageMagick 6 и 7 отдельными пакетами, чтобы модулю imagick PHP не нужны были
  программы: `libMagickCore-6`, `libMagickWand-6` и `libMagickCore-7.so`,
  `libMagickWand-7.so` в `/usr/local/az/lib`, их заголовки, `.pc` и `MagickWand-config`
  (у ImageMagick 7 в `/usr/local/az/bin`, у ImageMagick 6 в
  `/usr/local/az/libexec/ImageMagick-6/bin`: имена те же), `etc/ImageMagick-6` и
  `etc/ImageMagick-7` с нашей policy, которую читают библиотеки; у ImageMagick 7 ещё его
  статические библиотеки и `MagickWand-config` в `/usr/local/az/static`, для статического
  imagick из `az-menu.sh`. Только JPEG, PNG, WebP, GIF, HEIC и AVIF; ImageMagick 6 с
  исправлением, которое несёт OpenBSD, для картинки с испорченным профилем EXIF или
  8BIM: 6.9.13-60 её вовсе не записывал
  ([`files/imagemagick6-write-profiles.patch`](graphics/ImageMagick6/files/imagemagick6-write-profiles.patch),
  issue 427 ImageMagick6). Сборка и работа: az.
- **`graphics/ImageMagick6`**, **`graphics/ImageMagick7`** и
  **`graphics/ImageMagick67`** (aZ, 14.11.2026): программы, друг с другом они
  конфликтуют: в `ImageMagick6` — `bin/convert`, `identify`, `mogrify`, `composite` и
  остальные программы ImageMagick 6, в `ImageMagick7` — `bin/magick` и обычные имена
  ссылками на него, в `ImageMagick67` — оба, ImageMagick 6 с 6 на конце (`convert6`,
  `identify6`, ...); каждый зависит от библиотек своего ImageMagick (`ImageMagick67` — от
  обеих). Модули `phpXY-imagick7` и `phpXY-imagick6` (одинаковый `imagick.so`, поэтому
  тоже конфликтуют) зависят от `libimagemagick7` и `libimagemagick6`. Сборка и работа: az.
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
  ([`misc/mc/files/mc.conf`](misc/mc/files/mc.conf): что и почему), собирает его
  [`tools/mc-build.sh`](tools/mc-build.sh) на разделяемых GLib из `devel/glib20`,
  libssh2 и S-Lang из az (экранная библиотека — умолчание mc вместо ncurses базы; aZ,
  20.11.2026), с исправлениями `files/*.patch` (из upstream после 4.8.33, из Gentoo,
  Debian, NetBSD и Alpine и два наших: в каждом патче — откуда, что и зачем; проверяет
  `tools/mc-test.sh` — то, что видно в терминале script(1)). В
  subshell на tcsh в истории (стрелка вверх, `history`, `~/.history`) остаётся то, что
  набрано там или в командной строке mc, и нет строк самого mc: cd вслед за панелью идёт
  по клавише, привязанной через `bindkey -c`; каталоги остаются в истории самого mc
  (Alt-Shift-H, Alt-Y, Alt-U). Копирование (F5, F6 между каталогами) клонирует блоки,
  где файловая система умеет
  (клонирование файлов upstream из #5082, [`files/copy-clone-1.patch`](misc/mc/files/copy-clone-1.patch)
  и его исправление `copy-clone-2-reget.patch`; mc-build.sh делает autoreconf для его
  `configure.ac`, проверяет `HAVE_COPY_FILE_RANGE` и `HAVE_FILE_CLONING_BY_RANGE` и запускает
  его unit-тест): на FreeBSD через `copy_file_range(2)` с `COPY_FILE_RANGE_CLONE`, что ZFS
  делает клонированием блоков при `vfs.zfs.bclone_enabled`=1 (по умолчанию в FreeBSD 15.x):
  копия не занимает нового места и времени, блоки общие, пока один из двух файлов их не
  изменит; в остальных случаях (другой пул или файловая система, UFS, клонирование
  выключено) mc копирует как раньше. Выключить: Options, Configuration, «Use COW file
  cloning» или `file_cloning=false` в `~/.config/mc/ini`.
  zip, jar, 7z, rar и образы ISO открываются как
  каталог через [`files/ubsdtar`](misc/mc/files/ubsdtar) на `tar` базовой системы
  (libarchive), без Perl, 7-Zip и unrar (файл из зашифрованного zip сразу даёт ошибку:
  `tar` спрашивал пароль на терминале, и mc ждал); Perl, zip и GNU diff, если поставлены,
  дают своё (запись в zip, хелперы deb и rpm, `mcdiff`).
- У этих семи: версия официального порта на закреплённом коммите (или из строки take
  его conf) со штампом сборки как `PORTREVISION`; все distfile — в фазе fetch; тесты после
  установки: `tools/ffmpeg-test.sh`,
  `imagemagick-test.sh`, `curl-test.sh`,
  `az-test.sh`, `mc-test.sh`.
- **`devel/pcre2`** и **`devel/pcre`**: официальные порты
  ([`Mk/az-official.mk`](Mk/az-official.mk)), PCRE2 10.49 и PCRE 8.45 (его последний
  релиз): PCRE для PHP (7.4–8.4 `--with-external-pcre`, 5.6 `--with-pcre-regex`), Apache,
  git, wget, mc (GLib) и MariaDB, потом и nginx (aZ, 10.11.2026). С исправлением у каждого,
  которого нет в выпусках (в `EXTRA_PATCHES`, не в хэше зависящих портов: исправление
  внутри разделяемой библиотеки, как у az): у PCRE2 обратный проход `pcre2_dfa_match()` и
  `\X` в JIT ограничен проверенной частью строки UTF (GHSA-9qww-pwc4-77qq, патчи SUSE,
  [`files/patch-GHSA-9qww-pwc4-77qq`](devel/pcre2/files/patch-GHSA-9qww-pwc4-77qq)), у PCRE
  таблица имён скомпилированного шаблона инициализируется (Fedora,
  [`files/patch-name-table`](devel/pcre/files/patch-name-table)).
- **`devel/git`**: git без Perl (send-email, svn, скрипты cvs), Python, Tcl/Tk, gettext,
  expat (`git http-push`), man-страниц, пользователя и скрипта rc.d git daemon; HTTPS через
  наш `curl`, PCRE2 (`git grep -P`) из `pcre2`, iconv из libc.
- **`www/apache24`** и **`www/mod_maxminddb`**: Apache 2.4.71 только с prefork (модулем)
  и модулями серверов (и cgi, env, headers; всё остальное выключено), без SSL, APR и APR-util из az
  (разделяемые: те же, что у mod_php), PCRE2 из `pcre2`; mod_maxminddb с libmaxminddb из az.
- **`databases/memcached`** и **`databases/memcached-openssl`**: memcached без TLS, SASL,
  DTrace и документации, libevent из az; вариант с TLS на OpenSSL базы; ставится один из
  двух.
- **`devel/gearmand`** и **`devel/gearmand-openssl`** (aZ, 16.11.2026): Gearman 2.2.0 от
  18.10.2026 — сервер очереди задач gearmand, клиентская библиотека libgearman (её берут
  модули `phpXY-gearman`), утилиты gearman и gearadmin. В дереве FreeBSD его больше нет
  (`devel/gearmand-devel` удалён 20.04.2021, `devel/gearmand`, там 1.0.6 2013 года, —
  04.04.2024): порт этого дерева по последнему официальному. С исправлениями master после
  2.2.0 (фоновые задачи без unique ID терялись в постоянной очереди, клиент зависал на одном
  соединении или слал без TLS, сервер не останавливался, деление на ноль в gearman);
  постоянная очередь — в SQLite (libsqlite3 из az; без MySQL, PostgreSQL, Redis, memcached,
  Tokyo Cabinet); libevent из az; Boost.Program_options и libuuid официальных портов
  вкомпонованы при сборке; `gearmand-openssl` — с TLS на OpenSSL базы; ставится один из
  двух. Скрипт rc.d: на 127.0.0.1:4730, очередь в `/var/db/gearmand/gearmand.sqlite`
  (`gearmand_listen`, `gearmand_port`, `gearmand_queue`; TLS — через `gearmand_flags`).
- **`databases/mariadb1011-server`** и **`databases/mariadb1011-client`**: MariaDB 10.11 с
  опциями aZ (из движков опций только InnoDB; без GSSAPI, wsrep, RocksDB, Spider,
  Mroonga, S3, CONNECT с ODBC и XML, HashiCorp Vault, AWS key management), сокет
  `/tmp/mysql.sock` вкомпилирован в сервер и клиентскую библиотеку и прописан в
  `my.cnf.sample` (`/tmp` на серверах — диск в памяти, tmpmfs), PID-файл — в
  `/var/run/mysql`; PCRE2 из `pcre2`, lz4, zstd и fmt из az, zlib (не своя копия
  MariaDB), OpenSSL и libedit базы. 10.11.20 раньше официальной 10.11.19 (aZ,
  16.11.2026): MDEV-42025 (до аутентификации — имя базы в рукопожатии без предела длины),
  MDEV-41432 (нет проверки прав), MDEV-40374, три падения, исправления движка CONNECT; в
  её Connector/C уже есть исправление регрессии CONC-821 версии 10.11.19 (`ead038d`), его
  патч убран.
- **`ftp/vsftpd-ext`** и **`ftp/vsftpd-ext-openssl`**: vsftpd-ext со своим скриптом rc.d
  (RC_SCRIPT); вариант с SSL (VSFTPD_SSL, OpenSSL базы); ставится один из двух. С
  исправлением CVE-2021-3618 (ALPACA), как в vsftpd 3.0.5
  ([`files/patch-CVE-2021-3618`](ftp/vsftpd-ext/files/patch-CVE-2021-3618)): HTTP-метод
  или 11-я неизвестная команда до входа закрывают соединение, TLS-клиент, чей ALPN не
  предлагает `ftp`, получает отказ, `ssl_sni_hostname`. И наши исправления, которых нет
  в апстриме (что и зачем — в каждом файле):
  [`files/patch-CVE-2026-119567`](ftp/vsftpd-ext/files/patch-CVE-2026-119567):
  `cmds_allowed` и `cmds_denied` считают `XMKD`, `XRMD`, `XCWD`, `XCUP`, `XPWD` и `P@SW`
  командами `MKD`, `RMD`, `CWD`, `CDUP`, `PWD` и `PASV` (запрещённую `MKD` делали как
  `XMKD`); [`files/patch-deny_file`](ftp/vsftpd-ext/files/patch-deny_file): `deny_file`
  запрещает и пути через запрещённый каталог (с `{*.mp3,*.mov,.private}` путь
  `.private/secret` не запрещался);
  [`files/patch-CVE-2026-119568`](ftp/vsftpd-ext/files/patch-CVE-2026-119568):
  TLS-соединение данных возобновляет только сессию своего входа (без stateless session
  tickets: их ключ был общим для всех входов, и `require_ssl_reuse` принимал сессию
  чужого). И из Debian:
  [`files/patch-deny_file-realpath`](ftp/vsftpd-ext/files/patch-deny_file-realpath):
  `deny_file` и по реальному пути — часть исправления CVE-2015-1419, которой в vsftpd-ext
  нет (символическая ссылка на запрещённый каталог или файл, сделанная не по FTP, вела в
  обход; «жадная» `*` в нём уже есть: с `{*.php}` загрузка с именем `a.php.x.php`
  запрещена); [`files/patch-pam-exec-hang`](ftp/vsftpd-ext/files/patch-pam-exec-hang):
  вход зависал, когда модуль PAM запускал и сам дожидался своего процесса (pam_exec).
  И из openSUSE:
  [`files/patch-no-stderr-on-control-connection`](ftp/vsftpd-ext/files/patch-no-stderr-on-control-connection):
  сокет клиента был stderr сеанса, и то, что печатала туда библиотека (NSS, PAM,
  libwrap), уходило клиенту FTP.
- **`net/3proxy`** и **`net/3proxy-openssl`**: 3proxy 0.9.9.3, LTS-линия апстрима
  (07.11.2026), ради исправлений безопасности: в официальном порту 0.9.5, которую апстрим
  больше не поддерживает. С тремя исправлениями ветки 0.9 после неё (pcre-правило без ACL,
  tlspr и короткий ServerHello, учётные данные прошлого запроса keep-alive-соединения,
  взятые для следующего), собран CMake с именами и путями официального порта
  (`httppr`, `mycrypt`, `/var/log/3proxy`, его пример конфига и скрипт rc.d) и ссылками по
  именам плагинов 0.9.5 (`StringsPlugin.so`, `TrafficPlugin.so`, `pamauth.so`; PCRE внутри
  3proxy с 0.9.7, строка `pcre_plugin` принимается как есть); PAM, PCRE2 из `pcre2`; без
  TLS, как официальный порт, и пользователи с паролями NT тоже (как в 0.9.5); вариант с
  TLS на OpenSSL базы (TLS-серверы и клиенты, MITM); ставится один из двух.
- **`mail/postfix`** и **`mail/postfix-mysql`** (aZ, 15.11.2026): Postfix 3.11.7,
  официальный порт с опциями aZ (как на его серверах): EAI, PCRE2, TLS и TLSRPT; без
  Berkeley DB из портов, blocklistd, CDB, LDAP, LMDB, MongoDB, NIS, PostgreSQL, Cyrus
  SASL (Dovecot SASL встроен всегда), SQLite и тестовых программ. ICU из az (только её
  заголовки, в каталоге сборки), PCRE2 из `devel/pcre2`, `libtlsrpt` из
  `mail/libtlsrpt`, OpenSSL базы; `postfix-mysql` (подчинённый порт, не flavor) — с
  таблицами MySQL на клиенте из `databases/mariadb1011-client`. Проверки в
  `servers-test.sh`: STARTTLS, SMTPUTF8, письмо в Maildir, таблица `mysql:` на MariaDB.
- **`mail/dovecot`** и **`mail/dovecot-mysql`** (aZ, 15.11.2026): Dovecot 2.3.21.1, ветка
  2.3, пока её поддерживает апстрим (сейчас только критические исправления
  безопасности), официальный порт с опциями aZ: без GSSAPI, CDB, LDAP, PostgreSQL,
  SQLite, FTS, libsodium, libunwind, Lua, LZ4 и libwrap (на его серверах нет
  `tcpwrap`); zstd из az; `dovecot-mysql` — с драйвером SQL для MySQL. Исправления
  безопасности ветки 2.3 после 2.3.21.1 (aZ, 16.11.2026: патчами на 2.3.21.1): 28 патчей в
  `files/cve` — Ubuntu noble-security (2.3.21+dfsg1-2ubuntu6.5) и RHEL 10
  (dovecot-2.3.21-22.el10_3) в их порядке: CVE-2022-30550 (в ветку 2.3 так и не попал),
  CVE-2026-0394, -27852, -27855, -27856, -27857, -27859, -33263, -33603, -40018, -40020,
  -42006, -42391 и -73208 (три патча RHEL — одним на 2.3.21.1, без его тестов);
  CVE-2025-59031 — `decode2text.sh` не ставится, как его убрал апстрим; исправления
  Pigeonhole — нет (его порта здесь нет). Проверки в `servers-test.sh`: IMAP со STARTTLS
  (письмо от `postfix`), `passdb sql` на MariaDB.
- **`databases/redis82`** и **`databases/redis82-openssl`** (aZ, 15.11.2026): Redis 8.2.11,
  официальный порт с включённым JEMALLOC (jemalloc самого Redis — для `activedefrag`) и
  без TLS; `redis82-openssl` — с TLS на OpenSSL базы, те же файлы. Без модулей (JSON,
  поиск, временные ряды, вероятностные структуры). Конфиги aZ вместо redis.conf Redis:
  `etc/redis.conf.sample` — основной кеш, `etc/redis-session.conf.sample` — сессии PHP
  (профиль `session` rc-скрипта: `redis_profiles="redis session"`); только 127.0.0.1,
  без снимков (варианты снимка закомментированы), ленивое освобождение включено,
  `hide-user-data-from-log`. Проверки в `servers-test.sh`: jemalloc, PING, SET, GET, TLS
  на своём порту, оба конфига как есть: что задают, сокет 777, нет снимка при остановке.
- **`databases/mongodb80`** (aZ, 18.11.2026): MongoDB 8.0.38 Community, `mongod` и
  `mongos`, официальный порт закреплённого дерева (его патчи, distfiles Bazel, rc-скрипт
  `mongod`, пользователь `mongodb`) с флагами aZ и без опций: ThinLTO всегда
  (`--thin_lto=True`; в официальном LTO выключен), `-O3` и `-march` уровня (`--copt`:
  CFLAGS Bazel не берёт, а в официальной сборке нет ни того, ни другого), без отладочных
  символов (`--//bazel/config:debug_symbols=False`); AVX2-вариант `memchr` SpiderMonkey —
  по уровню сборки: на v3 включён, на v2 выключен (наш патч `SIMD.cpp` вместо официального
  NOAVX, который оставляет выбор процессору при запуске). Как в официальном порту:
  аллокатор системы (jemalloc libc), libunwind выключен (трассировки — execinfo базы),
  OpenSSL базы, без enterprise-функций; curl из `ftp/curl`. Дисковый кэш Bazel
  (`AZ_PORT_CACHE`, ниже) переходит из прогона в прогон: сборка, которую остановило время
  прогона, продолжается в следующем с уже сделанных действий.
- **`www/nginx-devel`**, **`www/nginx-devel-stream`** и **`www/nginx-devel-image-filter`**
  (aZ, 15.11.2026): nginx 1.31.9 (18.11.2026; до него 1.31.8) с семью исправлениями freenginx, которых нет в nginx (gzip, mp4, charset, захваты подзапросов; с 22.11.2026 — предел на расширения чанков и трейлеры в теле запроса, блокировка чтения тела запроса после ошибки, запрет переиспользования соединения потока HTTP/3 при его сбросе: из открытого PR nginx 1696), и headers-more 0.42 (19.11.2026, с исправлением `more_set_input_headers -r`: отсутствующий заголовок из нескольких значений писался через неинициализированный указатель), опции — объединение серверов aZ. Вкомпилены: модули
  nginx FILE_AIO, IPV6, THREADS, WWW, HTTP, HTTP_CACHE, HTTP_GZIP_STATIC, HTTP_MP4, HTTP_REALIP,
  HTTP_SECURE_LINK, HTTP_SLICE, HTTP_SSL, HTTP_STATUS (stub_status: его счётчики читает VTS),
  HTTP_SUB, HTTPV2, HTTPV3, а также brotli,
  headers-more и geoip2 (http) — они на всех серверах, и zstd (aZ, 22.11.2026: nginx-zstd-module 0.1.3 форка sysadmin-labs, тот же, что в `www/nginx-module-zstd` FreeBSD: модуль tokers с исправленными зацикливанием воркера на пустом буфере flush, обрезкой ответа на 131072 байтах и потерей последнего буфера; своего zstd нет ни в nginx, ни во freenginx, ни в Angie): в ядре (без `load_module`), в цепочке фильтров раньше brotli (клиент с `zstd, br` получает zstd, с `br, gzip` — br), с длиной ответа, переданной zstd как подсказка, и окном ответа без длины не больше 512 КиБ (на уровне 3 — 1273 КиБ памяти на ответ в 100 КБ вместо 3577; подсказка, а не обещание: поток не обещанной длины zstd обрывает, а `Content-Length` ответа не всегда равен длине тела — gzip и brotli такое тело сжимают целиком), без flush после каждого входного буфера (модуль заканчивал им блок zstd: проксированная страница выходила на 5–9 процентов больше той же страницы с диска, через `sub_filter` — на 20), q-значения Accept-Encoding — как у gzip в nginx (`zstd;q=0` — отказ). Готовые файлы (aZ, 22.11.2026): `gzip_static`, `brotli_static` и `zstd_static`, каждый выключен, пока сервер его не включит, и все ведут себя одинаково: `.zst` раньше `.br` раньше `.gz` среди включённых, принятых клиентом и лежащих рядом с файлом, затем фильтры в том же порядке; `q=0` — отказ; `Vary: Accept-Encoding` (при `gzip_vary`) везде, где лежит готовый файл, и клиенту, который его не берёт; ни один не отнимает фильтр gzip у ответа, который сам не отдал; готовый файл с исходным не сверяется — кто их делает, тот и переделывает при правке. Один `Vary` (aZ, 22.11.2026; патч ядра): строки `Vary` ответа (upstream, `add_header`) и `Accept-Encoding` от `gzip_vary` уходят одной строкой, каждый элемент один раз (nginx дописывал свою строку, не глядя на строки ответа: за upstream со своим `Vary: Accept-Encoding` их было две), переписывается только список имён заголовков (символы token RFC 9110, до 32 элементов и 1024 байт), иначе — как без патча. Два исправления кэша из открытого PR nginx 1948 (CERT Polska): табуляция между элементами `Vary` и `*` среди них. Ответ, который фильтр slice собирает на запрос с `Range`, не сжимается (aZ, 22.11.2026; одинаково gzip nginx, brotli и zstd): сжатым nginx 1.31.9 отдаёт 200 со срезом, в котором начинается диапазон, вместо объекта и тянет ради него все срезы до конца объекта; без сжатия это запрошенный 206. Своей строки `Server` nginx не добавляет (aZ, 22.11.2026; сборка с `-DNGX_HTTP_AZ_SERVER=0`, видно в `nginx -V`): `more_clear_headers 'server'` тогда делать нечего, а `Server` пропущенного backend уходит как раньше. Из открытых PR nginx (aZ, 22.11.2026; каждый прочитан по коду 1.31.9 до взятия): кадры ACK со счётчиками ECN в QUIC обрабатываются (949 и 1005: клиент, который их шлёт, не получал ответа), путь QUIC, снятый во время разбора его пакета, не используется (1634), нет холостого цикла, когда `SSL_write()` ждёт чтения (2004, при `ssl_early_data`), slice сверяет длину ответа среза (1966: от backend, приславшего срез длиннее или короче, лишние или недостающие байты уходили в объект без строки в логе), ответ 101 от backend принимается только при идущем upgrade (1941), длины имён в резолвере (1858); от 23.11.2026 (aZ): контекст подзапроса slice, который `error_page` отправил в именованный location (1611: `$slice_range` там был пуст, и весь объект источника уходил в ответ на месте среза), нет знакового переполнения при `Content-Range` у наибольшего смещения (1942), серия freenginx по телу запроса (1943: что запрос несёт от тела после ошибки его чтения или после того, как тело отброшено; `error_page 413` по HTTP/2 и HTTP/3 и там, где предел действует в её же location; отброшенное тело — это отсутствие тела: проксируемому backend не уходит `Content-Length`, где уходил `Content-Length: 0`, а `$content_length` пуст — `-` в логе — где был заголовок клиента, для каждого запроса, на который nginx отвечает сам через `return`, файлом или страницей ошибки; `r->discard_body` остаётся установленным после отброса, его читает lua-nginx-module: после отброса `ngx.req.set_body_data()`, `set_body_file()`, `init_body()` и `ngx.req.socket()` дают ошибку, а `ngx.req.get_post_args()` — пустую таблицу, как и сказано в его документации). Фильтры сжатия уступают другим соединениям (aZ, 23.11.2026; PR nginx 1808 для gzip, то же в brotli и zstd): за одну итерацию цикла событий сжимается не больше `sendfile_max_chunk` байт ответа (2m, если не задано), а раньше воркер сжимал большой файл целиком и только потом брался за остальные соединения (рядом с файлом в 33 МБ самый медленный малый запрос ждал 258 мс с zstd, 645 с brotli и 938 с gzip, сборка с ASan; с патчами — 41–46, 80–123 и 116–141); выключены: остальные модули nginx
  (в том числе MAIL), NJS, OTEL, Perl, XSLT, GeoIP 1, GSSAPI, VOD и прочие сторонние.
  `--with-compat`: модули, нужные не всем серверам, — отдельные пакеты из того же nginx:
  `nginx-devel-stream` (stream с realip, ssl и ssl_preread, geoip2 для stream) и
  `nginx-devel-image-filter` (image_filter), подключаются через `load_module`. OpenSSL
  базы, PCRE2 из `devel/pcre2`, zlib базы; brotli, libzstd, libmaxminddb и libgd — из az.
  Проверки в `servers-test.sh`: brotli; zstd (после `zstd -d` — те же байты, Vary, HTTP/1.1, HTTP/2 и HTTP/3, проксированный ответ, большой без длины, `zstd, br` — zstd, `br, gzip` — br, `gzip` — gzip, `zstd;q=0` — не zstd); `zstd_static`, `brotli_static`, `gzip_static` во всех 8 сочетаниях с фильтрами выключенными, включёнными и одним gzip, страница с готовыми файлами и без, клиенты со всеми наборами кодировок и с `q=0` (480 запросов); один `Vary` по HTTP/1.1, HTTP/2 и HTTP/3; отсутствие `Server` по HTTP/1.1, HTTP/2 и HTTP/3 (страница, 404, `Server` upstream пропущенный и убранный); zstd проксированной страницы не больше, чем той же страницы с диска, тело не той длины, что в `Content-Length`, — целиком; slice с включёнными zstd, brotli и gzip: с `Range` — 206 без сжатия, без `Range` — весь объект сжатым; gzip_static, headers-more, geoip2, прокси stream,
  image_filter. Патчи Debian (aZ, 16.11.2026): `brotli_static` ставит `Vary` только там,
  где есть `.br`, как `gzip_static`; geoip2 не берёт кэшированный результат базы, которую
  закрыл `auto_reload`. Из Gentoo (aZ, 16.11.2026): `HTTP_PROXY ""` в `fastcgi_params`,
  `scgi_params` и `uwsgi_params` (httpoxy, CVE-2016-5385: заголовок `Proxy` запроса не уходит
  приложению как `HTTP_PROXY`), проверка — в `servers-test.sh`. Из Angie (aZ, 17.11.2026):
  `mp4_limit_rate` и `mp4_limit_rate_after` его модуля mp4, как в NGINX Plus: скорость ответа —
  множитель среднего битрейта файла после заданного времени воспроизведения (`on` — 1,1,
  после 60s), проверка — в `servers-test.sh`. От Intaro (aZ, 17.11.2026): водяной знак их
  image_filter (`image_filter watermark`, `image_filter_watermark`, `_position`, `_width_from`,
  `_height_from`; github.com/intaro/nginx-image-filter-watermark 62d1468) — на image_filter
  nginx 1.31.8, вывод байт в байт их, без падений их файла (знака нет или он не PNG, пустой
  путь, rotate ниже порогов) и чтения освобождённой памяти (знак в левом верхнем углу);
  проверка — в `servers-test.sh`. Пакеты модулей от 17.11.2026 (aZ): `nginx-devel-vts`
  (nginx-module-vts 128ccd2: трафик зон server, upstream и кэшей — JSON, Prometheus и HTML-страница),
  `nginx-devel-cache-purge` (ngx_cache_purge 3.0.4) и `nginx-devel-testcookie`
  (testcookie-nginx-module de7ca88, с исправлениями 14.11.2026 двух переполнений кучи и чтения за
  границей запроса); проверка — в `servers-test.sh`. WebDAV от 18.11.2026 (aZ):
  `nginx-devel-dav` (модуль DAV самого nginx — PUT, DELETE, MKCOL, COPY, MOVE — собран
  динамическим патчем `auto/options` и `auto/modules`: nginx собирает его только в бинарник;
  ядро с `--with-compat` разбирает его заголовки запроса) и `nginx-devel-dav-ext` (PROPFIND,
  OPTIONS, LOCK, UNLOCK: nginx-dav-ext-module 3.0.1 sysadmin-labs, форк, который берёт
  официальный порт, на libxml2 и libxslt из az; с `DAV: 1,2` при настроенном LOCK, как в
  Alpine, и без пустой записи, которую его PROPFIND давал для элемента, к которому нет stat,
  например битой ссылки); проверка — в `servers-test.sh`. От OpenResty (aZ, 18.11.2026):
  SSL-рукопожатие ждёт, когда колбэк сертификата уступает управление (`ssl_cert_cb_yield`,
  как в Debian), — `ssl_certificate_by_lua*` может делать неблокирующий ввод-вывод.
- **`www/nginx-devel-lua`** и **`www/nginx-devel-stream-lua`** (aZ, 15.11.2026): Lua для
  nginx-devel, только на LuaJIT (стандартного Lua у lua-nginx-module нет):
  `nginx-devel-lua` — ndk 0.3.6 и lua-nginx-module 0.10.31; `nginx-devel-stream-lua` —
  stream-lua-nginx-module 0.0.19rc4 с патчем официального порта, на stream из
  `nginx-devel-stream`. Исходники и суммы — официальных `www/nginx-module-ndk`, `-lua` и
  `-lua-stream`. LuaJIT — порт этого дерева: официальный порт на v2.1-20261107 OpenResty,
  новее его v2.1-20250826 (aZ, 16.11.2026); lua-resty-core и lua-resty-lrucache —
  официальные порты как есть (`Mk/az-official.mk`); lua-resty-http — официальный порт с недостающей ему зависимостью
  `www/lua-resty-string` (0.19, порт этого дерева); lua-vips (`graphics/lua51-vips`, на libvips из
  `graphics/vips`) и lbase64 (`converters/lua51-base64`) — порты этого дерева вместо
  luarocks; не собираются: inspect, patch, lua-fs-module, luasocket (скриптам aZ не
  нужны). Проверки в `servers-test.sh`: LuaJIT и resty.core в nginx, base64, resty.http,
  vips с форматами и опциями resize.lua, Lua в сервере stream.
- **`www/aria2`** (aZ, 15.11.2026): aria2 1.37.0, официальный порт с LIBXML2 по
  умолчанию и CARES, без STATIC, NLS и документации, без LIBUV, SQLITE и SSH2 (aZ,
  17.11.2026: опрос событий и так kqueue; cookies браузеров и SFTP не нужны, а каждая
  опция — лишний код с возможными уязвимостями): libxml2 и c-ares из az, OpenSSL и
  zlib базы; с исправлением openSUSE для `IOFile::getLine()` (чтение перед буфером на
  стеке, 16.11.2026).
- **`devel/py-pip`** (aZ, 15.11.2026): pip 26.3 для нашего `python312`, новее
  официальной 23.3.2 (CVE-2025-8869), из исходника PyPI через flit_core; только
  `bin/pip`, как в официальном пакете.
- **`devel/php84-composer`** и его подчинённые `devel/php56-composer` …
  `php83-composer` (aZ, 15.11.2026): Composer 2.11.2 (для 5.6 — 2.2.32) из релизов
  GitHub (тот же файл, что на getcomposer.org) как `bin/composerXY`, который запускает
  `libexec/composerXY.phar` через `bin/phpXY`, для всех PHP рядом; модули официального
  порта (ctype, filter, intl, mbstring, phar, curl; json для 5.6 и 7.4). Проверки в
  `check-php.sh`: версия, автозагрузчик, собранный без сети.

- **`dns/bind920`** и **`dns/bind-tools`**: BIND 9.20, как в официальном дереве утилиты —
  ведомый порт серверного, с опциями aZ: TCP_FASTOPEN и IDN, без GSSAPI, DNSTAP, LMDB
  (`rndc addzone` хранит зоны в файле `.nzf`), каналов статистики (STATS_JSON,
  STATS_XML), FIXED_RRSET и LARGE_FILE; без man-страниц и заголовков библиотек BIND.
  `named` со скриптом rc.d и `/usr/local/etc/namedb`, как в официальном порту; утилиты
  (dig, host, nslookup, delv, nsupdate, утилиты DNSSEC) с IDN. libuv, liburcu, nghttp2
  (DNS over HTTPS) и libidn2 из az, OpenSSL, zlib и libedit базы.
- **`dns/unbound`**: Unbound 1.26.2 вместо local_unbound базы, которую серверы собирают
  WITHOUT_UNBOUND (aZ, 20.11.2026: пакет обновляется как остальные, резолвер базы — только с
  системой, обрезанный и со своими стартовыми скриптами): официальный порт как резолвер
  самого сервера, с ECDSA (алгоритмы DNSSEC 13 и 14), LIBEVENT, THREADS и TCP Fast Open
  (TFOCL, TFOSE, как TCP_FASTOPEN у BIND); без DNSCrypt и DNS over HTTPS для клиентов,
  модулей сторонних библиотек (DYNLIB), событийного API libunbound (EVAPI), GOST (RFC 8624),
  DNSTAP, кеша в Redis, Python, Munin, фильтра AAAA, client subnet, man-страниц и
  документации. expat и libevent из az, OpenSSL базы. `unbound` со скриптом rc.d unbound
  официального порта (unbound_enable, профили, unbound-anchor перед запуском),
  `/usr/local/etc/unbound` с unbound.conf.sample.
- **`graphics/vips`**: libvips 8.18 (aZ, 11.11.2026: для скрипта Lua в nginx,
  перекодирующего картинки на лету) с форматами aZ: JPEG (mozjpeg), PNG (libpng), WebP,
  HEIC/AVIF (libheif из az: оба читаются, AVIF пишется через SVT-AV1), GIF (чтение встроенное, запись через cgif и
  libimagequant), с ICC-профилями (lcms2), EXIF (libexif) и SIMD (Highway; ORC — другой
  вариант, только без Highway). Без TIFF, SVG, PDF, JPEG XL, ImageMagick и
  GraphicsMagick, текста, FFTW и прочих официальных опций; без загрузчиков Analyze,
  Radiance и PPM, устаревшего API vips7, C++-API, статической библиотеки, man-страниц и
  переводов. mozjpeg, png, webp, libheif, lcms2 и expat из az; glib, libexif, cgif,
  libimagequant и highway из их портов этого дерева; zlib базы. Для картинок из веба —
  `VIPS_BLOCK_UNTRUSTED=1` в окружении nginx (`env VIPS_BLOCK_UNTRUSTED=1;` в основном
  контексте nginx.conf; об этом говорит и сообщение пакета): libvips не
  берёт недоверенные загрузчики. С исправлениями ветки 8.18 после 8.18.7, до выхода
  8.18.8 ([`files/patch-*`](graphics/vips/files), в каждом — его коммит): полная высота
  анимированных GIF, WebP и HEIF (переполнение int в неверный размер), входной профиль
  `icc_import` (использование после освобождения), коды LZW через подблоки GIF, PNG из
  libpng 1.6.0–1.6.2, фото HEIC больше чем из 256 элементов.
- **`multimedia/qt-faststart`**: `bin/qt-faststart` из `tools/qt-faststart.c` FFmpeg 9.1
  (public domain): официальный порт удалён 30.06.2022 (то же делает ffmpeg `-movflags
  +faststart`); оставлен для совместимости, пока нужен (aZ, 10.11.2026).
- У этих: тесты после установки — `tools/servers-test.sh` (git
  grep -P, Apache с модулями серверов на своём порту, memcached, MariaDB на сокете по
  умолчанию `/tmp/mysql.sock`, named со своей зоной — dig по UDP, TCP и по имени IDN,
  rndc, vips с JPEG, WebP, PNG и GIF, vsftpd-ext и vsftpd-ext-openssl (отказ в том, что
  закрывают исправления выше, и в загрузке с именем `a.php.x.php` или через ссылку на
  запрещённый каталог; curl получает файл по FTP и FTPS и загружает файл; билеты TLS 1.3
  живут не больше 7 дней), библиотеки каждого).
- **`www/yt-dlp`**: пакет `yt-dlp` вместо официального: официальный порт как есть, на
  более новом релизе yt-dlp (граберам видеосайтов нужны экстракторы последнего), с нашим
  `multimedia/ffmpeg` и, опцией IMPERSONATE (включена по умолчанию, aZ, 16.11.2026), нашим
  `ftp/py-curl-cffi` (`--impersonate`); остальные его пакеты Python — официальные, на наших `python312` и
  `py312-sqlite3`. Его релиз следует релизам GitHub, а не официальному порту (aZ,
  12.11.2026): новый сам попадает в порт, собирается и публикуется ([yt-dlp из
  GitHub](#yt-dlp-из-github)). Тесты после установки:
  `tools/ytdlp-test.sh` (HLS-поток с локального сервера, который
  наш ffmpeg собирает в MP4, как качают граберы).
- **`lang/perl5.42`**: пакет `perl5` (`/usr/local/bin/perl`) вместо официального (aZ,
  11.11.2026: наши Perl и Python под именами пакетов FreeBSD, чтобы с ними работали пакеты
  `p5-*` из репозитория FreeBSD): официальный порт как есть — Perl 5.42.3, версия по
  умолчанию закреплённого дерева (с исправлением CVE-2026-15534 из blead, которого нет в
  5.42.3: `files/patch-CVE-2026-15534`), с его опциями (потоки, MULTIPLICITY, 64-битные целые,
  разделяемая `libperl`; без GDBM) и `-O3` сборок, без DTrace (`OPTIONS_UNSET` всех сборок
  здесь): пробы DTrace компилируются только в ядро Perl (`mydtrace.h`: `USE_DTRACE` и
  `PERL_CORE`), поэтому XS-модуль ничего от DTrace не берёт, и модули пакетов FreeBSD,
  собранные под его perl с DTrace, загружаются и работают с нашим. Тесты после установки —
  `tools/perl-test.sh` (`Config` нашего против `perl5` FreeBSD,
  библиотеки, все XS-модули Perl; официальные пакеты `p5-*` с XS, поставленные поверх него
  как на сервере: JSON::XS, DBI с DBD::SQLite, Text::CSV_XS, YAML::XS, Net::SSLeay и
  IO::Socket::SSL с TLS на 127.0.0.1 и другие, их символы против нашей `libperl`;
  XS-модуль, собранный под него).
- **`lang/python312`**, **`databases/py-sqlite3`**, **`math/mpdecimal`** и **`lang/python3`**: Python 3.12 —
  `PYTHON_DEFAULT` закреплённого дерева — как официальный порт с его опциями (LTO,
  PYMALLOC, IPV6 включены; libmpdec из `math/mpdecimal`, официального порта как есть),
  кроме NLS (выключен, как везде: aZ, 16.11.2026; модуль gettext сам читает файлы `.mo`),
  и файлами, чтобы официальные пакеты `py312-*` ставились поверх нашего `python312`
  и работали с ним (aZ, 11.11.2026); libffi (`_ctypes`), expat (`pyexpat`) и readline
  из az с путём поиска библиотек `/usr/local/az/lib` вместо их
  пакетов, OpenSSL, ncurses, zlib, bzip2 и liblzma базы; сборка видит из `/usr/local`
  только az и libmpdec. `py312-sqlite3` — официальный порт со своими flavor'ами — на
  SQLite из az. Без gdbm и tkinter (как в официальном пакете; aZ: не нужны). Версия — та
  же, что у официального порта (её читает оттуда `Mk/Uses/python.mk`). С gh-115627, как
  его несёт RHEL для своего Python 3.12 (00462, в апстриме только с 3.13):
  `SSL_ERROR_SYSCALL` разбирался по возвращаемому значению `SSL_read_ex()`, и с OpenSSL 3.5
  базы оборванное под нагрузкой соединение приходило как EOF, а не как `OSError` (через
  это идёт HTTPS yt-dlp); и gh-134100, как его несёт Gentoo (use-after-free на пути ошибки
  относительного импорта). `lang/python3` —
  официальный метапорт как есть (aZ, 11.11.2026): `bin/python3`, `bin/pydoc3`,
  `python3.pc` и подобные — ссылки на файлы Python 3.12, зависимость от нашего
  `python312`. Инструменты, которые порту нужны только для сборки (Python, Perl, meson:
  у `az/az`, `ftp/curl`, `devel/glib20`, `graphics/vips`, `www/node24`), — официальные
  пакеты, не наши (`tools/build.sh`); порт, который работает с Python или сам его модуль
  (`www/yt-dlp`, `www/npm-node24`, `databases/py-sqlite3`), берёт наш. Смена
  `PYTHON_DEFAULT` или `PERL5_DEFAULT` в `Mk/bsd.default-versions.mk` main freebsd-ports
  открывает issue [проверки апстрима](https://github.com/azsupport/php-src/blob/master/README.ru.md#проверка-апстрима)
  azsupport/php-src: пакетам `py3XX-*` и `p5-*` FreeBSD, собранным после неё, нужен Python
  или Perl этой версии. Тесты после установки —
  `tools/python-test.sh` (`python3` и `python3.12`, библиотеки
  каждого модуля, TLS с хранилищем сертификатов базы, hashlib, ctypes, decimal, expat,
  sqlite3, gettext, readline, сжатие; `py312-six` и `py312-markupsafe` из FreeBSD поверх
  нашего `python312`).
- **`java/openjdk21`**, **`devel/jna`** и **`devel/apache-ant`**: JDK для
  `textproc/elasticsearch6` (и для `textproc/opensearch217` и `textproc/opensearch219` до
  23.11.2026, когда они ушли из этого дерева), и его JNA, наши (aZ, 11.11.2026: сервер с
  Elasticsearch не получает ничего от рабочего стола; официальный OpenJDK тянет около
  50 его пакетов — X11, шрифты, ALSA, HarfBuzz с GLib и Python, giflib, PNG,
  javavmwrapper, — официальный `jna` — libX11 и libXt; 12.11.2026: один JDK для всех:
  OpenSearch 2.x и Elasticsearch 6 не работают на JDK 24 и новее, где Security Manager
  отключён насовсем, а OpenSearch 3.x нужен JDK не ниже 21), с именами, origin,
  версиями и путями официальных пакетов. `openjdk21` берёт версию, distinfo и патчи
  официального порта закреплённого коммита как есть (новая версия приходит вместе с
  закреплённым коммитом; из его патчей два, которые линкуют fontconfig, не берутся —
  по имени и SHA-256) и собирает OpenJDK 21 без графики (`--enable-headless-only`:
  `libawt_headless`, нет `libawt_xawt` и `libsplashscreen`, поэтому giflib и libpng
  остаются встроенными и не используются; и без заголовков X11 — с перенесённым
  изменением OpenJDK для этого, JDK-8376684 от 04.02.2026: 21u без графики их
  требует и при компиляции, и в configure, `NEEDS_LIB_X11` в
  `make/autoconf/libraries.m4`), без звука (на FreeBSD нет ALSA и `libjsound`, как на
  AIX и OpenBSD: `javax.sound` не находит устройств) и без DTrace, на libjpeg
  (mozjpeg), FreeType и Little CMS из az (путь поиска библиотек `/usr/local/az/lib`
  после `$ORIGIN` — в трёх библиотеках, которые их линкуют), zlib базы и встроенном
  HarfBuzz (его нет ни в одном нашем порту); без шрифтов и javavmwrapper (нет
  `/usr/local/bin/java`: Elasticsearch и OpenSearch берут `JAVA_HOME`); CUPS и
  заголовки fontconfig (из az) — только для сборки. fontconfig не
  линкуется: OpenJDK загружает `libfontconfig.so.1` через dlopen по имени, когда ему
  нужны шрифты системы, а rtld FreeBSD ищет её в `LD_LIBRARY_PATH`, пути поиска
  `bin/java`, подсказках ldconfig и в `/lib`, `/usr/lib`, но не в `/usr/local/az/lib`:
  с одними нашими пакетами у Java нет шрифтов совсем (любое обращение к шрифту
  бросает `java.lang.InternalError` из `sun.font.FontManagerFactory`, и с файлом шрифта
  тоже; Elasticsearch текст не рисует), с установленными официальными `fontconfig` и
  шрифтами (`pkg install dejavu`) берёт их (в `tools/java-test.sh`:
  семейства DejaVu, текст нарисован). `jna`: JNA
  официального порта так же, без JAWT (`-DNO_JAWT` на FreeBSD, как JNA собирается для
  Android и macOS) и X11, его `libjnidispatch.so` — на разделяемой libffi из az вместо
  встроенной статической копии и ставится ещё и файлом `lib/jna/libjnidispatch.so` (aZ,
  11.11.2026: с `-Djna.boot.library.path=/usr/local/lib/jna` JNA загружает её оттуда, а
  не распаковывает из jar во временный каталог при каждом запуске; так делает
  `elasticsearch6` с 12.11.2026 — с `-Djna.nounpack=true` и зависимостью от этого
  файла: его процесс отображает этот файл в память, его фильтр системных вызовов,
  который ставится через JNA, включён, `tools/elastic-test.sh`);
  собран нашими `openjdk21` и `apache-ant` (aZ, 12.11.2026; Ant — официальный порт с
  `JAVA_VERSION` 21, `bin/ant` на `java` из `openjdk21`): в сборке один JDK; JNA
  компилируется для Java 8 (`javac --release 8`; порт проверяет версию class-файлов —
  52). Порты
  проверяют то, что собрали (ни один ELF JDK не линкует библиотеки X11, ALSA, giflib,
  libpng, HarfBuzz и fontconfig; библиотеки az — по пути поиска; зависимости — только
  az). Тесты после установки — `tools/java-test.sh` (`openjdk21`:
  без графики, ImageIO с JPEG и PNG, преобразование ICC, текст, `AudioSystem`, TLS 1.3
  на 127.0.0.1, библиотеки az в процессе, `ldd` каждого ELF-файла JDK (только
  библиотеки самого JDK, базы и `/usr/local/az/lib`, ничего от X11), `getpid()` через
  JNA — из jar и из `lib/jna`, скалярное произведение через Vector API из
  `jdk.incubator.vector`, файл, отображённый как `MemorySegment`, и `getpid()` через
  `Linker` из FFM — так, как их используют OpenSearch 2.19 и 3.x; class-файлы
  `jna.jar` для Java 8; `bin/ant` на `openjdk21`, собранный им jar — на этом JDK;
  зависимости пакетов, у `elasticsearch6` — `bash`, `jna` и `openjdk21`).
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
| Программы | `bin/php74`, `bin/phpize74`, `bin/php-config74`; `sbin/php74-fpm` (`php74-fpm`), `bin/php74-cgi` (`php74-cgi`) |
| Настройки | `etc/php74/`: `php.ini` (из `php.ini-production`, изменённый сохраняется), `php.ini-production`, `php.ini-development`, `php-fpm.conf` из `php74-fpm` (pid `/var/run/php74-fpm.pid`, лог `/var/log/php74-fpm.log`), `php-fpm.d/www.conf` (`listen /var/run/php74-fpm.sock`, владелец и группа `www`, права 0660) |
| Модули | `lib/php/20190902/<модуль>.so`, грузятся из `etc/php74/conf.d/ext-<NN>-<модуль>.ini` (из его `.ini.sample`, изменённый сохраняется; `NN`: 10 OPcache, 18 session, 20 json и модуль, которому не нужен другой, 30 — которому нужен) |
| Заголовки | `include/php74/php/...`; заголовки модуля — в `include/php74/php/ext/<модуль>/` |
| Файлы сборки | `lib/php74/build` |
| php-fpm | `etc/rc.d/php74_fpm` из `php74-fpm` (`php74_fpm_enable`), чтобы php-fpm нескольких версий работали одновременно |
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

Каждая публикация ещё и сохраняет весь репозиторий — каталог и все пакеты — релизом,
который потом не меняется: `az-fbsd15-amd64-v3-<ГГГГММДД>-<ЧЧММ>` (UTC, время публикации;
`-v2-` для x86-64-v2), последние 31 на каждый уровень
([релизы](https://github.com/azsupport/ports/releases),
[`tools/release-snapshot.sh`](tools/release-snapshot.sh)); в самом релизе — только пакеты
его каталога: GitHub держит в релизе не больше 1000 файлов. Сервер возвращается к снимку
по его url (здесь — от 18.11.2026 04:12), а `pkg upgrade -f` ставит пакеты az такими, как
они там, и более старые версии тоже:

```sh
sed -i '' 's#/releases/download/az-fbsd15-amd64-v3[^"]*"#/releases/download/az-fbsd15-amd64-v3-20261118-0412"#' /usr/local/etc/pkg/repos/az.conf
pkg update -f -r az
pkg upgrade -f -r az
```

и обратно к релизу:

```sh
sed -i '' 's#/releases/download/az-fbsd15-amd64-v3[^"]*"#/releases/download/az-fbsd15-amd64-v3"#' /usr/local/etc/pkg/repos/az.conf
pkg update -f -r az
pkg upgrade -r az
```

`priority: 100`: для пакета, который есть в обоих (`curl`), pkg предпочитает az
репозиторию FreeBSD. `pkg update -r az` отказывается от каталога, подпись которого не
проверяется. В `ffmpeg`, `libimagemagick6`, `libimagemagick7` и `GraphicsMagick` из az нет
разделяемых библиотек официальных пакетов (`libavcodec.so`, `libMagickWand-7.so` в
`/usr/local/lib`, …): если они нужны другому пакету (`pkg info -r ffmpeg`), оставьте
официальный пакет.

PHP 7.4 с модулями:

```sh
pkg install -r az php74 apache24-php74 php74-opcache php74-gd php74-mbstring php74-openssl-legacy
```

PHP 8.3 с модулями (ставится рядом с 7.4: свои `etc/php83`, `lib/php/20230831`, `include/php83`):

```sh
pkg install -r az php83 apache24-php83 php83-opcache php83-gd php83-mbstring php83-openssl-legacy
```

PHP 8.1 с модулями (так же рядом: `etc/php81`, `lib/php/20210902`, `include/php81`):

```sh
pkg install -r az php81 apache24-php81 php81-opcache php81-gd php81-mbstring php81-openssl-legacy
```

PHP 5.6 с модулями (так же рядом: `etc/php56`, `lib/php/20131226`, `include/php56`):

```sh
pkg install -r az php56 apache24-php56 php56-opcache php56-gd php56-mbstring php56-openssl-legacy
```

PHP 8.2 с модулями (так же рядом: `etc/php82`, `lib/php/20220829`, `include/php82`):

```sh
pkg install -r az php82 apache24-php82 php82-opcache php82-gd php82-mbstring php82-openssl-legacy
```

PHP 8.4 с модулями (так же рядом: `etc/php84`, `lib/php/20240924`, `include/php84`):

```sh
pkg install -r az php84 apache24-php84 php84-opcache php84-gd php84-mbstring php84-openssl-legacy
```

Программы:

```sh
pkg install -r az curl ffmpeg ImageMagick67 mc
```

yt-dlp — без `-r az`: его пакеты Python есть в репозитории FreeBSD, а `yt-dlp`,
`python312`, `python3` и `py312-sqlite3` pkg берёт из az по `priority: 100`:

```sh
pkg install yt-dlp
```

`ffmpeg` собран с кодировщиком AAC `libfdk_aac` (`--enable-nonfree`, для форматов
старых сайтов с `-c:a libfdk_aac`; [`files/ffmpeg-nonfree.conf`](multimedia/ffmpeg/files/ffmpeg-nonfree.conf)).
FFmpeg называет такую сборку нераспространяемой; пакет лежит в репозитории под
ответственность владельца, пока nonfree-часть не уйдёт (переход на открытые библиотеки).

php-fpm 7.4:

```sh
pkg install -r az php74-fpm
sysrc php74_fpm_enable=YES
service php74_fpm start
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
env AZ_PLAN=1 sh tools/build.sh
env AZ_CONFIGURE_CHECK=1 sh tools/build.sh --force
```

Что он делает, по логике poudriere:

- официальное дерево на закреплённом коммите (git, глубина 1) в `work/freebsd-ports`,
  переиспользуется, когда оно на этом коммите (`AZ_PORTSDIR`: дерево берётся как есть,
  с предупреждением, если оно на другом коммите), это дерево — `OVERLAYS` поверх него;
- `work/make.conf` из [`tools/make.conf.in`](tools/make.conf.in) — make.conf серверов
  aZ в стиле style.Makefile(5) (`CPUTYPE` уровня, `CFLAGS=-O3 -pipe -fno-strict-aliasing`,
  фреймворк добавляет `-fstack-protector-strong`; `COPTFLAGS=-O3 -pipe` и `KERNCONF=az.st`
  — для ядра серверов; `JPEG_PORT=graphics/mozjpeg`; `DEFAULT_VERSIONS+=mysql=10.11m
  perl5=5.42 php=8.3 python=3.12 ruby=3.4 ssl=base` — клиент `mariadb1011-client` для
  портов с `USES=mysql`, а порт не меняют ни умолчания закреплённого дерева, ни то, что
  установлено на машине; `OPTIONS_SET=GSSAPI_NONE` и снятый `GSSAPI_BASE` — без Kerberos
  базы, которого на серверах нет; `OPTIONS_UNSET` для X11, Wayland, GUI, DBus, CUPS,
  отладки, DTrace, тестов, документации, man-страниц и переводов (NLS, с 16.11.2026)) с путями
  прогона, отдаётся make как `__MAKE_CONF`: `/etc/make.conf` сборочного сервера не
  читается и не меняется, а сохранённые там `make config` опции на сборку не влияют
  (свой `PORT_DBDIR`);
- очередь: порты и порты этого дерева, которые им нужны (origin из их `*_DEPENDS`,
  которые наши), каждый после тех, что ему нужны;
- порт, у origin которого в репозитории есть пакет с тем же `az_hash`, заново не
  собирается (инкрементальная сборка; [Версии и пересборки](#версии-и-пересборки)),
  если нет `--force`; упавший порт останавливает порты, которым он нужен (пропущены, с
  причиной);
- каждый порт — в своём chroot (`work/ch/<ключ>`, aZ 11.11.2026), который делается для
  него за секунды и разбирается после него, чем бы сборка ни кончилась: базовая система
  машины только для чтения (nullfs `/bin`, `/sbin`, `/lib`, `/libexec`, `/usr/bin`,
  `/usr/sbin`, `/usr/lib`, `/usr/lib32`, `/usr/libexec`, `/usr/include`, `/usr/share`,
  `/usr/libdata`), копия её `/etc` (pkg, `resolv.conf`, пользователи, которых добавляют
  пакеты; без `/etc/ssh`), devfs, `/tmp`, пустой `/usr/local` и своя база pkg; это
  дерево, официальное дерево, `packages/` и репозиторий — только для чтения, по своим
  путям; дистфайлы, рабочие каталоги (`WRKDIRPREFIX`), каталог пакетов порта и
  `results/az-results` — на запись. Каталоги pkg — прогона (машины, обновлённые один раз
  в начале; в chroot `pkg -U`), кэш pkg — машины, общий: официальные пакеты портов,
  которые надо собрать, скачиваются в начале, потом качает только один chroot за раз. В
  chroot официальные пакеты зависимостей порта (и те, что нужны для работы нашим пакетам,
  которые он получает) ставятся `pkg -c <chroot> install` из репозиториев FreeBSD машины
  (никогда не наших `az` и `azbuild`), наши — `pkg -c <chroot> add` пакетов, собранных
  раньше, или из репозитория, в порядке очереди (`-f` — на место официального пакета с
  тем же именем); потом `make clean package` в нём (`chroot`, окружение входа root с
  make.conf прогона и `AZ_CPUTYPE`) с `USE_PACKAGE_DEPENDS_ONLY=yes` (из исходников
  собирается только сам порт); его лог и время, с временем его chroot и зависимостей
  (строка `chroots:` в сводке). Ни одна сборка не трогает `/usr/local` машины: проверки
  после прогона видят только то, что ставят сами;
- инструменты сборки из `AZ_TOOLS_OFFICIAL` в `tools/build.sh` (`lang/python3`,
  `lang/python312`, `lang/perl5.42`, `devel/meson`) берутся из официальных пакетов
  FreeBSD, даже когда origin есть в этом дереве (aZ, 11.11.2026: наши Python и Perl
  линкуют библиотеки az, а az нужны они для сборки): порт, которому такой нужен только
  для сборки (`FETCH_`, `EXTRACT_`, `PATCH_`, `BUILD_` или `PKG_DEPENDS`), получает в
  chroot официальный пакет, и хеш нашего порта в его `az_hash` не входит; порт, который
  с ним работает (`LIB_` или `RUN_DEPENDS`) или собирает расширение для него (`FLAVOR`
  `py*`), получает наш (`results/hashes.txt` называет инструменты, которые порт получает
  официальными); automake (`devel/automake`) — наш, официальный порт как есть:
  `Mk/Uses/autoreconf.mk` нового пина может требовать automake, которого в официальных
  пакетах ещё нет (19.11.2026: `automake>=1.20`, без него упал az);
- до `AZ_JOBS` портов одновременно (по умолчанию 4), волнами: волна — порты, у которых
  все нужные им порты этого дерева готовы, первыми — самые большие, каждый в своём
  chroot, со своим логом и своим каталогом пакетов (два пакета с одними файлами,
  `php84-mysqlnd` и `php84-mysqlnd-openssl`, собираются рядом); сводка — в порядке
  очереди; `results/waves.txt`. `AZ_JOBS=1` — порт за портом, как раньше; `AZ_DRYRUN=1` —
  только показать волны прогона, ничего не собирая (порты, которым нужен az, решаются
  после сборки az, если его надо собирать);
- `AZ_PLAN=1` (вход `plan` workflow) — план прогона, чтобы дёшево проверить его решения:
  `az/az` и нужные ему порты собираются, если их надо собирать (порты, которым нужен az,
  решаются по интерфейсам нового az), все остальные порты только решаются — взять из
  репозитория или собрать и почему (строки `PLAN` сводки, `results/plan.txt`), не
  собираясь; собранное попадает в репозиторий (az — чтобы следующий прогон его взял);
  без проверок, никогда не публикуется;
- порт, который в зависимостях не называет ни одного файла статического дерева az
  (`/usr/local/az/static`), собирается без архивов az (они убираются из его chroot):
  слинковать их в свой пакет может только порт с `AZ_STATIC_LIBS`
  ([Версии и пересборки](#версии-и-пересборки));
- порт с `NEED_ROOT` (`az/az`: собирается прямо в `/usr/local/az`): в `/usr/local/az`
  своего chroot, как любой порт;
- `AZ_CONFIGURE_CHECK=1`, проверка configure: после сборки каждого порта PHP (ядра,
  `apache24-phpXY`, все модули, и PECL, и те, что собирает clang), и тогда, когда сборка
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
  `result: FAIL (...)`), `queue.txt`, `hashes.txt`, `waves.txt`, `logs/`
  (`logs/chroots.log`: каталоги pkg и официальные пакеты, скачанные в начале),
  `az-interface.txt` и `abi-check.txt` (az), `plan.txt` (`AZ_PLAN`),
  `configure-check.txt` (`AZ_CONFIGURE_CHECK`).

### Версии и пересборки

Как у poudriere: каждый порт, который прогон собирает, получает `AZ_STAMP` (час начала
прогона, `yymmddhh` UTC) как `PORTREVISION`, чтобы каждая сборка была для pkg
обновлением (`php74-7.4.33_26110817`), и `AZ_HASH`, который попадает в пакет
аннотацией `az_hash` (`pkg info -A php74`): SHA-256 файлов порта (с файлами его
`MASTERDIR`, его `EXTRA_PATCHES` и `AZ_HASH_FILES` в этом дереве: файлы каталога другого
порта, которые читает его сборка, — у `graphics/ImageMagick6` это `imagemagick.conf` и
`policy.xml` из `graphics/ImageMagick7`), makefile из `Mk/` этого дерева, которые он
читает (`Mk/bsd.overlay.mk`;
`Mk/Uses/php.mk` — только у портов PHP), официального коммита, уровня,
`tools/make.conf.in` и способа сборки (`builder chroot`: каждый порт в своём chroot; ради
этого все порты один раз пересобраны, 11.11.2026), и `az_hash` каждого порта этого
дерева, который ему нужен (но не инструмента сборки, который он получает официальным,
`AZ_TOOLS_OFFICIAL`: официальный коммит уже в его хеше). Порт, чей пакет в репозитории
с тем же `az_hash`, заново не собирается; изменение порта пересобирает его и все порты,
которым он нужен (изменение `az/az` — всё, что его линкует). Файлы, которые порт
перечисляет в `AZ_HASH_NOT_FOR_DEPENDENTS` (ставятся и нужны только при работе), входят
в его собственный `az_hash`, но не в хеш портов, которым он нужен, и не в хеш его
slave-портов: изменение блока php.ini, скрипта профилей, rc.d-скрипта или pkg-message
`lang/php74` пересобирает `php74`, а не модули и `apache24-php74` (pkg берёт зависимость по
имени, не по версии). Ревизии руками не поднимаются.

`az/az` пересобирается, когда в нём меняется что угодно; порт, которому он нужен, берёт
в свой `az_hash` не хеш az, а интерфейсы библиотек az, которые он использует (aZ,
12.11.2026: как FreeBSD и Debian, которые не пересобирают зависимых от разделяемой
библиотеки ради исправления внутри неё). Интерфейс библиотеки берётся из сборки az:
[`tools/az-build.sh`](tools/az-build.sh) пишет в пакет манифест на каждую библиотеку
(`/usr/local/az/share/az/interface/<библиотека>.txt`) по тому, что поставили её сборки
(файлы, чей inode менялся после начала каждой её сборки, в обоих деревьях): её
заголовки, файлы `.pc`, скрипты `*-config`, файлы cmake и прочие с их SHA-256, SONAME её
разделяемых библиотек, имена её архивов, её версию, хеш её функций сборки (`b_`, `s_`
из `tools/az-build.sh`, `lib_` из `files/curl/build-libcurl.sh`: её опции configure и
cmake) и библиотеки az, которые ей нужны (`NEEDED` её разделяемых библиотек, `Requires`
и `-l` её файлов `.pc`, строки `#include` её заголовков); в `common.txt` — файлы ничьей
библиотеки (`bin/pkg-config`). [`tools/az-interface.sh`](tools/az-interface.sh) делает
из манифеста хеш интерфейса (без хешей архивов) и хеш содержимого, и замыкание того,
что библиотеке нужно. Порт берёт хеш интерфейса каждой библиотеки из замыкания тех,
которые он использует (тех, в чьих манифестах есть файлы az из его зависимостей,
`${AZ_PREFIX}/lib/libxml2.so:az/az` — libxml2, и тех, что названы в его `AZ_HASH_LIBS`:
программа, которая линкует больше, чем называют её зависимости, — `ftp/curl`,
`multimedia/ffmpeg`, `graphics/ImageMagick*`, `graphics/GraphicsMagick`), и
`common.txt`. Поэтому исправление внутри кода библиотеки (те же заголовки, файлы `.pc`,
SONAME, версия и опции) пересобирает только az; новая версия, изменённый заголовок или
`.pc`, новый SONAME или изменённая опция пересобирают порты, которые используют эту
библиотеку. Хеши портов, которым нужен az, считаются, когда az готов: сразу, если его
пакет в репозитории с тем же `az_hash` (по его манифестам), после его сборки, если он
собирается (az — первый этап); пакет az без манифестов собирается заново.

Статическое использование: ни один порт этого дерева не линкует архивы az
(`/usr/local/az/static`) в свой пакет; `graphics/ImageMagick7` и `graphics/GraphicsMagick`
собирают по этому дереву свои статические библиотеки для PHP, собираемого на сервере
(`AZ_STATIC_LIBS= none`: их заголовки и `.pc` — в интерфейсах, оба дерева). Порт, который
бы их линковал, называет их в `AZ_STATIC_LIBS` (в его `az_hash` идёт хеш содержимого этих
библиотек, с архивами); [`tools/check-tree.sh`](tools/check-tree.sh) требует
`AZ_STATIC_LIBS` от порта, чьи зависимости называют файл статического дерева, а
`tools/build.sh` собирает все остальные порты без архивов az в их chroot.

Файлы каталога другого порта, которые читает сборка:
[`tools/check-tree.sh`](tools/check-tree.sh) вычисляет через `make` пути, которые
makefile этого дерева, читаемые портом, называют от его каталога вверх
(`${.CURDIR:H}...`, `${.CURDIR}/..`: значение переменной такой строки, чтобы не считалась
ветка, которая не выполняется, или выражение строки цели); путь вне его каталога, `Mk/` и
`tools/`, которого нет в его хеше (его `MASTERDIR`, `FILESDIR`, `PATCHDIR`, `PKGDIR`,
`DISTINFO_FILE`, `EXTRA_PATCHES`, makefile, которые он читает, `AZ_HASH_FILES`), — FAIL:
порт называет его в `AZ_HASH_FILES`. Два таких чтения не попадают ни в какой пакет и в хеши
не входят: `az/az/files/deps.conf` (`AZ_DEPS_CONF` из `az/az/Makefile.common`: только его
строка `ports`, официальный коммит, — он в основе каждого хеша) и `pkg-plist` порта
`databases/mariadb1011-client`, который сервер берёт строками `@comment`. Путь, который
скрипт из `tools/` строит сам, там не виден (`policy.xml` рядом с конфигом у
`imagemagick-build.sh`): его порт называет тоже.

Ничего не проходит незамеченным:

- после сборки az в прогоне, до тестов — проверка ABI каждого пакета репозитория,
  которому нужен az ([`tools/az-abi-check.sh`](tools/az-abi-check.sh)): каждый SONAME az,
  нужный его файлам (`shlibs_required` pkg), есть в новом az, и каждый неопределённый
  динамический символ, который они берут из библиотеки az, там определён (символы,
  которые новый az потерял против az репозитория, `nm -D`; ELF-файлы — только пакетов,
  которым нужен SONAME, потерявший символы, `readelf -d`, `nm -D`); пакет, не прошедший
  проверку, пересобирается в том же прогоне, а не собранный — убирается из репозитория
  (`results/abi-check.txt`);
- тесты всех программ идут в каждом прогоне (`tools/test-programs.sh`) — с оставленными
  пакетами против нового az;
- пакет, который линкует библиотеку az, не входящую в его `az_hash` (его
  `shlibs_required` против замыканий его библиотек и портов, которые ему нужны), валит
  прогон: в `AZ_HASH_LIBS` его Makefile чего-то не хватает;
- `results/az-interface.txt` (раздел отчёта): интерфейсы библиотек az, какие из них
  изменились против az репозитория, проверка ABI и порты, оставленные по интерфейсу,
  когда az пересобран (строка `az:` сводки).

[`tools/install-php.sh`](tools/install-php.sh) `<версия>` ставит пакеты PHP версии из
этого репозитория, как сервер (ядро, `apache24-php74` и модули, с `php74-openssl`), а
[`tools/check-php.sh`](tools/check-php.sh) `<версия>` их проверяет
(`results/check-php-<версия>.txt`); `install-php.sh --openssl` ставит варианты с OpenSSL
на места их модулей, для `CHECK_TAG=openssl check-php.sh` (`check-php-<версия>-openssl.txt`),
а [`tools/check-variants.sh`](tools/check-variants.sh) `<версия>` ставит по одному другие
пакеты модуля с теми же файлами и проверяет каждый: redis со сжатием, gd 5.6 с T1lib,
`php74-openssl-legacy` (RC4 вместе с ssh2 в одном процессе) (`check-variants-<версия>.txt`).

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
| `plan` | только план (`AZ_PLAN`, по умолчанию выключен): `az/az` и нужные ему порты собираются, если их надо собирать, все остальные порты решаются — взять или собрать и почему (`results/plan.txt`, раздел отчёта), не собираясь; без проверок, никогда не публикуется |
| `fork_ref` | ветка azsupport/php-src, с которой сверяется curl пакета az (`FORK_REF` у `tools/curl-sync-check.sh`, по умолчанию `master`): правка curl и его библиотек сначала идёт в ветку форка, прогон ветки здесь, которая её несёт, называет эту ветку, и обе входят в свои основные ветки в один момент |
| `publish` | опубликовать репозиторий, когда всё собралось и все проверки прошли (по умолчанию выключено: репозиторий, который читают серверы, публикуется по слову aZ) |
| `publish_only` | вместе с `publish`: публиковать, только когда репозиторий отличается от релиза лишь пакетами этих портов (`категория/порт` через пробел: прогоны [yt-dlp из GitHub](#yt-dlp-из-github)), иначе ничего; пусто — что бы ни отличалось |
| `continuation` | ставит прогон, у которого кончилось время, для прогона, который он запускает (его номер подряд; вручную — `0`). У задачи 350 минут: после ~245 новые порты не начинаются, идущие сборки останавливаются на ~285 (`AZ_TIME_SOFT`, `AZ_TIME_HARD` у `tools/build.sh`); собранное остаётся в кэше, как и кэш порта с `AZ_PORT_CACHE`, чья сборка остановлена (MongoDB — дисковый кэш Bazel; черновой релиз `portcache-<уровень>-<ключ>-<прогон>`, его следующий прогон распаковывает в `portcache/`, и сборка продолжается с уже сделанного), проверки и публикация ждут, последний шаг запускает следующий прогон с теми же входами (без `force`), не больше 6 подряд; при `both` `x86-64-v2` начинается только после готового `x86-64-v3` |

Он берёт репозиторий прошлого прогона (actions/cache, сохраняется и тогда, когда прогон
упал, чтобы прогон, упавший на PHP, оставил `az` и библиотеки) и файлы релиза
`az-fbsd15-amd64-<уровень>`, проверяет порты `make -V` против разреженного официального
дерева на раннере ([`tools/check-tree.sh`](tools/check-tree.sh), bmake: FAIL
останавливает прогон там), сверяет curl пакета az с curl PHP из azsupport/php-src
([`tools/curl-sync-check.sh`](tools/curl-sync-check.sh): строки данных
`az/az/files/curl.conf` и `curl-deps.conf` и патчи `curl/` — с теми, что в `freebsd/` на
его master или на ветке форка из входа `fork_ref`; отличие тоже останавливает прогон там), запускает `tools/build.sh` в ВМ FreeBSD
([vmactions/freebsd-vm](https://github.com/vmactions/freebsd-vm)), потом для каждой
версии PHP, пакет которой собран, ставит её пакеты из нового репозитория и проверяет их
(`tools/install-php.sh`, `tools/check-php.sh`; по строке в `results/checks.txt`),
отчитывается
([`tools/report.sh`](tools/report.sh): сводка прогона, аннотация на каждый упавший порт;
[`tools/runs-report.sh`](tools/runs-report.sh): отчёт в ветку `runs` azsupport/azsupport)
и публикует: сначала пакеты, каталог последним, потом убирает то, чего в репозитории
больше нет. Публикуется только подписанный каталог. Перед этим релиз, каким он есть,
становится снимком, если ни у одного снимка ещё нет его каталога, после — только что
опубликованный репозиторий становится снимком `az-fbsd15-amd64-<уровень>-<ГГГГММДД>-<ЧЧММ>`,
хранятся последние 31 на каждый уровень ([`tools/release-snapshot.sh`](tools/release-snapshot.sh);
сервер и репозиторий az — выше). Пакеты, собранные прогоном, сохраняются по мере сборки
в черновик релиза `wip-<уровень>-<ветка>-<прогон>-<попытка>`
([`tools/runs-save.sh`](tools/runs-save.sh)); следующий прогон ветки берёт из этих
черновиков то, чего нет в его кэше, а удаляются они, когда их пакеты есть в публикации
(черновики ветки — вместе с ней, `delete-branches.yml`): один кэш теряется, когда GitHub
вытесняет его сверх 10 ГБ кэшей репозитория.

Секреты (https://github.com/azsupport/ports/settings/secrets/actions, кнопка
**New repository secret**):

| Секрет | |
|---|---|
| `PKG_SIGNING_KEY` | закрытый ключ RSA (PEM) к `keys/az.pub`: попадает в ВМ только файлом, используется `pkg repo` и удаляется |
| `RUNS_TOKEN` | fine-grained токен с Contents на чтение и запись в azsupport/azsupport, для отчётов |

### Слитые ветки

[`delete-branches.yml`](.github/workflows/delete-branches.yml), «Delete merged branches»:
удаляет названные ветки (через пробел), все коммиты которых есть в main по патчу
(`git cherry`); `force` пропускает эту проверку — для ветки, чьи коммиты вошли в main
изменёнными при rebase, сверенной перед этим вручную. Работает на GitHub с токеном workflow,
потому что из песочницы, где делаются ветки, ветку на GitHub удалить нельзя (aZ, 12.11.2026:
слитые ветки удаляются без него).

### yt-dlp из GitHub

[`yt-dlp-update.yml`](.github/workflows/yt-dlp-update.yml), «yt-dlp at the latest release
of GitHub»: раз в 6 часов на main и вручную —
https://github.com/azsupport/ports/actions/workflows/yt-dlp-update.yml, кнопка **Run
workflow**. yt-dlp следует релизам github.com/yt-dlp/yt-dlp, а не версии официального
порта (aZ, 12.11.2026); [`tools/ytdlp-update.sh`](tools/ytdlp-update.sh):

- последний релиз (не черновик и не пре-релиз) против `DISTVERSION` порта `www/yt-dlp`;
- более новый: его `yt-dlp.tar.gz` с SHA-256, которую дают API GitHub и `SHA2-256SUMS`
  релиза; патчи порта накладываются на него, как их накладывает фреймворк портов, без fuzz
  (патч, который ложится только с fuzz, делается заново, как его делает `make makepatch`;
  тот, что не ложится, останавливает обновление: коммита нет, отчёт показывает почему);
  `DISTVERSION` и `distinfo`;
- `yt-dlp-ejs`: yt-dlp берёт его скрипты только той версии, которую закрепил (major.minor
  и их SHA3-512), поэтому закреплённая версия новее `www/py-yt-dlp-ejs` делает этот порт
  нашим из [`tools/ytdlp-ejs/`](tools/ytdlp-ejs) (wheel релиза github.com/yt-dlp/ejs, его
  SHA-256 — `EJS_WHEEL_HASH` yt-dlp) или обновляет наш; deno остаётся официальным пакетом
  (предупреждение, если он старше самого старого, с которым работает yt-dlp);
- порты проверяются `make -V` ([`tools/check-tree-ci.sh`](tools/check-tree-ci.sh), проверка
  `build.yml`), один коммит aZ пушится в main токеном прогона;
- сборка, когда в релизах нет этого yt-dlp: `build.yml` из main для `www/yt-dlp`, оба
  уровня, `publish` с `publish_only`; не пока прогон `build.yml` из main в очереди или
  идёт (запустит следующая проверка), не снова после того, как запущенный ею прогон
  прошёл, и не после трёх упавших.

`publish_only` ([`tools/publish-gate.sh`](tools/publish-gate.sh)): репозиторий прогона из
main — это релиз с кэшем прошлого прогона, опубликованного или нет, поэтому в нём могут быть
пакеты, которые aZ ещё не опубликовал. С `publish_only` релиз берёт его, только когда его
пакеты отличаются от пакетов релиза (по имени и SHA-256) лишь пакетами этих портов; иначе
ничего не публикуется, отчёт говорит об этом, а новый yt-dlp выходит со следующей
публикацией aZ (его хранит кэш прогона).

| Вход | |
|---|---|
| `dry_run` | обновление с его проверками, дифф его коммита и сборка, которую он запустил бы: ничего не пушится и не запускается (прогон другой ветки — всегда такой) |
| `pretend` | тест, с `dry_run`: `www/yt-dlp` считается этой версии, чтобы последний релиз был обновлением |
| `pretend_ejs` | тест, с `dry_run` и `pretend`: официальный `www/py-yt-dlp-ejs` считается этой версии, чтобы появился наш |

Отчёт: сводка прогона и ветка `runs` azsupport/azsupport (`ports-yt-dlp-update/`), когда он
что-то сделал, ждёт или упал. Своих секретов нет: пуш и сборка — токеном прогона.

### Библиотеки и программы с GCC

Какие C-библиотеки `az` собираются GCC 16 вместо базового clang и почему (библиотека
идёт на GCC 16, если она хотя бы на 2% быстрее на том, что делают сайты: aZ,
09.11.2026), записано в начале `tools/az-build.sh`. Бенчмарк, который это измерил,
лежит в приватном репозитории вместе с тестами сборки.

Программы замерены так же, из исходников наших портов, скриптом
[`tools/prog-bench.sh`](tools/prog-bench.sh) ([`prog-bench.yml`](.github/workflows/prog-bench.yml);
медианы пяти раундов, обе сборки на одной машине GitHub Actions); с GCC 16 (aZ,
17.11.2026):

- Python 3.12 (`lang/python312`): pyperformance, 25 тестов — быстрее во всех, на 1,3–22,3%,
  медиана 14,9%; sysconfig называет компиляторы базовой системы, так что pip собирает
  расширения базовым clang;
- Redis 8.2 (`databases/redis82`): redis-benchmark — медиана на 6,3% и 5,9% быстрее на
  двух процессорах; без рантайма C++ (единственному файлу на C++ он не нужен);
- xxhash из az (контрольные суммы rsync): XXH3 и XXH128 примерно на 30% быстрее.

С базовым clang, так как с ним быстрее или так же: ImageMagick 7, vips, zstd, lz4, brotli
и PostgreSQL 18 (не больше 2%); GraphicsMagick и ImageMagick 6 с GCC быстрее на одних
процессорах и не быстрее на других — остаются на clang до замера на процессорах серверов.

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
