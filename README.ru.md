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
  [`f16b6dd0f7c1`](https://github.com/freebsd/freebsd-ports/tree/f16b6dd0f7c1c3a2e0447e192e39e72f21d85eb0)
  (main от 04.11.2026; `ports_commit` в [`tools/build.sh`](tools/build.sh)). Фреймворк
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
  форк вкладывает в себя: наши порты PHP своих патчей не накладывают.
- Сейчас только PHP 7.4 и x86-64-v3: всё сначала отрабатывается там, остальные версии
  и x86-64-v2 — потом.

## Пакеты

Имена и origin как у портов, файлы по путям портов:

| Пакет | Origin | Что |
|---|---|---|
| `az` | `az/az` | библиотеки сборок в `/usr/local/az`: `lib` (разделяемые, с run path `/usr/local/az/lib`, без ldconfig), `lib/pkgconfig`, `include`, `bin` (`pkg-config`, `*-config`); статические — в `/usr/local/az/static`, для программ и особых сборок `az-menu.sh`. OpenSSL, zlib и bzip2 — из базовой системы |
| `curl` | `ftp/curl` | `bin/curl` и `libcurl.so.4`, вместо пакета порта |
| `ffmpeg` | `multimedia/ffmpeg` | `ffmpeg` и `ffprobe` только с теми форматами, что нужны видеосайтам |
| `ImageMagick6` | `graphics/ImageMagick6` | ImageMagick 6, программы с 6 на конце (`convert6`, `identify6`, ...) |
| `ImageMagick7` | `graphics/ImageMagick7` | ImageMagick 7 (`magick`); его `libMagickWand-7.so` в `/usr/local/az/lib` для модуля imagick |
| `php74` | `lang/php74` | ядро PHP 7.4: CLI, php-fpm, phpize |
| `mod_php74` | `www/mod_php74` | модуль Apache `libphp74.so` |
| `php74-<модуль>` | `<категория>/php74-<модуль>` | по пакету на модуль (`php74-gd`: `graphics/php74-gd`); PECL без «pecl»: `php74-redis`, `php74-swoole`, `php74-igbinary`, `php74-memcached`, `php74-memcache`, `php74-imagick`, `php74-gmagick`, `php74-mcrypt`, `php74-excimer`, `php74-openswoole`; OPcache и json — тоже модули (`php74-opcache`, `php74-json`), mysqlnd тоже (`php74-mysqlnd`: на нём модули баз данных) |

- openssl в двух видах, один из двух: `php74-openssl` и `php74-openssl-legacy` (с
  legacy-провайдером OpenSSL: RC4, Blowfish, DES, CAST5, MD4).
- `php74-swoole` и `php74-openswoole` ставятся оба; ini у openswoole выключен (у них
  одни и те же классы), его сообщение пакета говорит, как переключить.
- `php74-imagick` и `php74-gmagick` ставятся оба, но в один PHP их грузить нельзя (у
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
  ([`az/az/files/deps.conf`](az/az/files/deps.conf)). Два дерева:
  `/usr/local/az/static` (статические, position independent; для программ ниже и
  статических сборок PHP из `az-menu.sh`) и `/usr/local/az` (разделяемые, SONAME и run
  path `/usr/local/az/lib`, без ldconfig; для модулей PHP), у каждого свой
  `bin/pkg-config`, `VERSIONS` в `share/doc/az`, лицензии в `LICENSES/`. Собирается
  прямо в `/usr/local/az` сборочной машины (от root, `NEED_ROOT`) и пакует это дерево.
  Зависимостей нет.
- **`ftp/curl`**: пакет `curl` вместо официального: `bin/curl` (статический) и
  `lib/libcurl.so.4` со своими библиотеками внутри (наружу только `curl_*`), опции
  официального порта, против статического дерева az
  ([`tools/curl-build.sh`](tools/curl-build.sh)).
- **`multimedia/ffmpeg`**: пакет `ffmpeg` вместо официального: `bin/ffmpeg` и
  `bin/ffprobe`, статические, только с тем, что нужно видеосайтам
  ([`multimedia/ffmpeg/files/ffmpeg.conf`](multimedia/ffmpeg/files/ffmpeg.conf)),
  против x264, dav1d и libwebp статического дерева az.
- **`graphics/ImageMagick6`**: `bin/convert6`, `identify6`, `mogrify6`, `composite6` и
  остальные, статические, рядом с ImageMagick 7: только JPEG, PNG, WebP, GIF, HEIC и
  AVIF, с нашей policy.
- **`graphics/ImageMagick7`**: пакет `ImageMagick7` вместо официального: `bin/magick` и
  его имена, статические, те же форматы и policy; его статические библиотеки и
  `MagickWand-config` в `/usr/local/az/static`, разделяемая `libMagickWand-7.so` в
  `/usr/local/az/lib` для imagick из PHP. Сборка и работа: az.
- **`graphics/GraphicsMagick`**: пакет `GraphicsMagick` вместо официального: `bin/gm`,
  статический, собран как наш ImageMagick, только JPEG, PNG, WebP, GIF, BMP, HEIC и AVIF;
  файла политики у него нет — её заменяют зарегистрированные кодеки и пустой
  `delegates.mgk` (`files/graphicsmagick.conf`). Статические библиотеки — в
  `/usr/local/az/static`, общие `libGraphicsMagick` и `libGraphicsMagickWand` (префикс
  символов `Gm`) и `GraphicsMagick-config` — в `/usr/local/az`, для gmagick в PHP
  (`--with-gmagick=/usr/local/az`). Сборка и работа: az.
- У этих шести: версия официального порта на закреплённом коммите (или из строки take
  его conf) со штампом сборки как `PORTREVISION`; все distfile — в фазе fetch; тесты после
  установки: [`tools/ffmpeg-test.sh`](tools/ffmpeg-test.sh),
  [`imagemagick-test.sh`](tools/imagemagick-test.sh), [`curl-test.sh`](tools/curl-test.sh),
  [`az-test.sh`](tools/az-test.sh).
- **`lang/php74`** и **`www/mod_php74`**: ядро `php74` и модуль Apache `libphp74.so`;
  PCRE2 10.49 — встроенная в исходники форка (порт `devel/pcre2` — позже, aZ 08.11.2026).
- **60 портов модулей** `php74-<модуль>`: имена без «pecl», origin как у официальных
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

Версии рядом, ничего общего между ними:

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

```sh
mkdir -p /usr/local/etc/pkg/repos /usr/local/etc/pkg/keys
fetch -o /usr/local/etc/pkg/keys/az.pub https://raw.githubusercontent.com/azsupport/ports/main/keys/az.pub
sha256 /usr/local/etc/pkg/keys/az.pub
printf '%s\n' 'az: { url: "https://github.com/azsupport/ports/releases/download/az-fbsd15-amd64-v3", signature_type: "pubkey", pubkey: "/usr/local/etc/pkg/keys/az.pub", priority: 100, enabled: yes }' > /usr/local/etc/pkg/repos/az.conf
pkg update -r az
```

`priority: 100`: для пакета, который есть в обоих (`curl`), pkg предпочитает az
репозиторию FreeBSD. `pkg update -r az` отказывается от каталога, подпись которого не
проверяется.

PHP 7.4 с модулями:

```sh
pkg install -r az php74 mod_php74 php74-opcache php74-gd php74-mbstring php74-openssl-legacy
```

Программы:

```sh
pkg install -r az curl ffmpeg ImageMagick6 ImageMagick7
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
- репозиторий (`--repo <каталог>`, по умолчанию `work/repo`): по пакету на origin, новые
  на место старых, `pkg repo`, подпись ключом из `AZ_PKG_KEY_FILE` и проверка
  ([`tools/pkg-repo-sign.sh`](tools/pkg-repo-sign.sh));
- результаты в `results/`: `summary.txt` (строка на порт, в конце `result: OK` или
  `result: FAIL (...)`), `queue.txt`, `hashes.txt`, `waves.txt`, `logs/`.

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

[`tools/install-php.sh`](tools/install-php.sh) `<версия>` ставит пакеты PHP версии из
этого репозитория, как сервер (ядро, `mod_php74` и модули, с `php74-openssl`), а
[`tools/check-php.sh`](tools/check-php.sh) `<версия>` их проверяет
(`results/check-php-<версия>.txt`).

### Workflow

[`build.yml`](.github/workflows/build.yml), «Build the packages of the repository az»:
https://github.com/azsupport/ports/actions/workflows/build.yml, кнопка
**Run workflow**.

| Вход | |
|---|---|
| `release` | релиз FreeBSD для ВМ, `15.1` |
| `cputype` | `x86-64-v3` (по умолчанию), `x86-64-v2` или `both` (по job на каждый) |
| `ports` | порты для сборки через пробел; пусто — все |
| `force` | собирать их и тогда, когда их пакет с тем же `az_hash` уже есть в релизе |
| `jobs` | сколько портов собирать одновременно (`AZ_JOBS`, по умолчанию 4; `1` — порт за портом) |
| `publish` | опубликовать репозиторий, когда всё собралось и все проверки прошли (по умолчанию выключено: репозиторий, который читают серверы, публикуется по слову aZ) |

Он берёт репозиторий прошлого прогона (actions/cache, сохраняется и тогда, когда прогон
упал, чтобы прогон, упавший на PHP, оставил `az` и библиотеки) и файлы релиза
`az-fbsd15-amd64-<уровень>`, проверяет порты `make -V` против разреженного официального
дерева на раннере ([`tools/check-tree.sh`](tools/check-tree.sh), bmake: FAIL
останавливает прогон там), запускает `tools/build.sh` в ВМ FreeBSD
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
