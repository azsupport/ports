#!/bin/sh
# check-php.sh - check the PHP packages of a version in the repository that
# tools/build.sh made: installed together from it, as a server installs them, and
# checked as tools/build-pkg.sh of azsupport/php-src checks its packages.
#
# Usage (as root on FreeBSD, after tools/build.sh):
#   sh tools/check-php.sh [--repo <dir>] <version>          (7.4)
#
#   --repo <dir>  the repository of tools/build.sh (default: work/repo)
#
# - the repository as the repository "azcheck" of pkg (file://, priority 100, so that
#   its packages win over those of the same name of the FreeBSD repository; the
#   signature is the business of tools/pkg-repo-sign.sh); the core php74, mod_php74 and
#   every module php74-<module> of it installed by pkg install -f (php74-openssl-legacy
#   later, in the place of php74-openssl; php74-static not: it has the files of those
#   and is removed first when it is installed); memcached and redis for the checks of
#   memcache, memcached and redis (pkg install when they are not there), on 127.0.0.1
#   during the checks
# - the checks, a line each in results/check-php-<version>/tests.txt ("ok", "FAIL",
#   "--" a note): the libraries of every module and of the core (none of the ports in
#   /usr/local/lib, every one found, the run path $AZ_PREFIX/lib (/usr/local/az/lib)
#   when one of there is linked); php74 -m without a warning; php74 --ini: etc/php74/php.ini and the
#   ini files of etc/php74/conf.d; a check of each module (smoke_lines below, those of
#   build-pkg.sh); a module whose ini is off (openswoole) loaded on its own with the
#   modules its package needs; RC4 not with php74-openssl; php74-openssl-legacy in its
#   place by pkg install (the conflict of their files), RC4 with it, php74 -m without a
#   warning again; php-fpm by its rc.d script php_fpm74 (onestart, the socket
#   /var/run/php-fpm74.sock, onestop); mod_php (libphp74.so) in an httpd of its own on
#   127.0.0.1:8074, a page of it
#
# results/check-php-<version>/summary.txt: what was installed, the counts, its last
# line "result: OK" or "result: FAIL (...)"; the logs next to it.
# Exit status: 0 every check passed, 1 otherwise, 2 a wrong call.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n 's/^# \{0,1\}//; 6,8p' "$0" >&2; exit "${1:-2}"; }
say() { printf '[check-php %s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { say "$*" >&2; exit 2; }

repo=""
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --repo=*) repo="${1#--repo=}"; shift ;;
        -h|--help) usage 0 ;;
        -*) say "unknown option $1" >&2; usage ;;
        *) break ;;
    esac
done
[ $# = 1 ] || usage
t="$1"
case "$t" in
    [5-8].[0-9]) ;;
    *) die "not a version of PHP: $t (7.4)" ;;
esac
short="$(echo "$t" | tr -d .)"
[ "$(uname -s)" = FreeBSD ] || die "FreeBSD only"
[ "$(id -u)" = 0 ] || die "as root (pkg install, php-fpm, httpd)"
repo="${repo:-${AZ_WORK:-$top/work}/repo}"
repo="$(cd "$repo" 2>/dev/null && pwd)"
[ -n "$repo" ] && [ -f "$repo/meta.conf" ] || die "no repository of pkg (meta.conf) in ${repo:-the directory given}: tools/build.sh first"

# the prefix of the package az (the libraries; Mk/bsd.overlay.mk: AZ_PREFIX)
AZ="${AZ_PREFIX:-/usr/local/az}"
php="/usr/local/bin/php$short"
out="$top/results/check-php-$t"
rm -rf "$out"
mkdir -p "$out" || die "cannot make $out"
sum="$out/summary.txt"
tt="$out/tests.txt"
: > "$tt"
nfail=0
export ASSUME_ALWAYS_YES=yes
conf=/usr/local/etc/pkg/repos/azcheck.conf

cleanup() {
    for f in /tmp/check-php-memcached.pid /tmp/check-php-redis.pid; do
        if [ -f "$f" ]; then kill "$(cat "$f")" 2>/dev/null || true; rm -f "$f"; fi
    done
    [ -x "/usr/local/etc/rc.d/php_fpm$short" ] && sh "/usr/local/etc/rc.d/php_fpm$short" onestop > /dev/null 2>&1
    rm -f "$conf"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

# check <name> <command...>: its result as a line of tests.txt (ok or FAIL, with the
# first line of its output, or the last ones when it failed)
check() {
    _n="$1"; shift
    if _o="$("$@" 2>&1)"; then
        echo "ok   $_n${_o:+: $(printf '%s\n' "$_o" | head -n 1)}" >> "$tt"
    else
        echo "FAIL $_n: $(printf '%s\n' "$_o" | tail -n 3 | tr '\n' ' ')" >> "$tt"
        nfail=$((nfail + 1))
    fi
}
fail() { echo "FAIL $*" >> "$tt"; nfail=$((nfail + 1)); say "FAIL $*"; }

# no_ports_lib <file>: it loads no library of the ports (/usr/local/lib) and finds
# every library; with one of $AZ/lib its run path is that directory
no_ports_lib() {
    _l="$(ldd "$1" 2>&1)" || { echo "ldd: $_l"; return 1; }
    if printf '%s\n' "$_l" | grep -E '=> /usr/local/lib/|not found'; then return 1; fi
    if printf '%s\n' "$_l" | grep -q "=> $AZ/lib/"; then
        readelf -d "$1" | sed -n 's/.*[Ll]ibrary r[a-z]*path: \[\(.*\)\].*/\1/p' | tr ':' '\n' | grep -qx "$AZ/lib" ||
            { echo "links $AZ/lib without the run path $AZ/lib"; return 1; }
    fi
    printf '%s\n' "$_l" | awk '/=>/ { print $3 }' | sed "s|^$AZ/lib/||" | tr '\n' ' '
}

# The checks of the modules (those of tools/build-pkg.sh of azsupport/php-src): one
# line each, <module><TAB><code of php -r> that exits 0 when the module works (and
# prints what it found)
smoke_lines() {
    cat <<'EOF'
opcache	$s = opcache_get_status(false); exit(is_array($s) && $s["opcache_enabled"] ? 0 : 1);
json	exit(json_decode(json_encode(["a" => 1, "b" => [true, null]]), true) === ["a" => 1, "b" => [true, null]] ? 0 : 1);
bcmath	exit(bcadd("1.5", "2.25", 2) === "3.75" ? 0 : 1);
bz2	$s = str_repeat("az", 100); exit(bzdecompress(bzcompress($s)) === $s ? 0 : 1);
calendar	exit(cal_days_in_month(CAL_GREGORIAN, 2, 2024) === 29 ? 0 : 1);
ctype	exit(ctype_digit("123") && !ctype_digit("1a") ? 0 : 1);
curl	$v = curl_version(); echo $v["version"], " ", $v["ssl_version"]; exit(stripos($v["ssl_version"], "OpenSSL") !== false ? 0 : 1);
dba	echo implode(",", dba_handlers()); $f = tempnam("/tmp", "dba"); $d = dba_open($f, "n", "cdb_make"); dba_insert("k", "v", $d); dba_close($d); $d = dba_open($f, "r", "cdb"); $v = dba_fetch("k", $d); unlink($f); exit($v === "v" ? 0 : 1);
dom	$d = new DOMDocument(); $d->loadXML("<a><b>x</b></a>"); exit($d->getElementsByTagName("b")->item(0)->textContent === "x" ? 0 : 1);
exif	exit(function_exists("exif_read_data") ? 0 : 1);
fileinfo	$f = new finfo(FILEINFO_MIME_TYPE); exit($f->buffer("GIF89a") === "image/gif" ? 0 : 1);
filter	exit(filter_var("a@b.cz", FILTER_VALIDATE_EMAIL) === "a@b.cz" ? 0 : 1);
ftp	exit(function_exists("ftp_ssl_connect") ? 0 : 1);
gd	$i = imagecreatetruecolor(8, 8); ob_start(); imagepng($i); imagejpeg($i); imagewebp($i); $o = ob_get_clean(); $g = gd_info(); echo $g["GD Version"]; exit(strlen($o) > 100 && !empty($g["FreeType Support"]) ? 0 : 1);
gettext	exit(_("x") === "x" ? 0 : 1);
gmp	exit(gmp_strval(gmp_pow(2, 100)) === "1267650600228229401496703205376" ? 0 : 1);
iconv	echo ICONV_IMPL, " ", ICONV_VERSION; exit(iconv("UTF-8", "ISO-8859-2", "\xc5\xa1") === "\xb9" ? 0 : 1);
intl	$f = new NumberFormatter("cs_CZ", NumberFormatter::DECIMAL); echo INTL_ICU_VERSION, " ", $f->format(1234.5); exit($f->format(1234.5) !== false ? 0 : 1);
mbstring	echo MB_ONIGURUMA_VERSION; exit(mb_ereg_replace("[0-9]+", "#", "a1b22") === "a#b#" && mb_strtoupper("\xc5\xbe") === "\xc5\xbd" ? 0 : 1);
mysqlnd	exit(extension_loaded("mysqlnd") ? 0 : 1);
mysqli	exit(class_exists("mysqli") && function_exists("mysqli_fetch_all") ? 0 : 1);
openssl	echo OPENSSL_VERSION_TEXT; exit(openssl_encrypt("x", "aes-128-cbc", "k", 0, str_repeat("i", 16)) !== false ? 0 : 1);
pcntl	exit(function_exists("pcntl_fork") ? 0 : 1);
pdo	exit(class_exists("PDO") ? 0 : 1);
pdo_mysql	exit(in_array("mysql", PDO::getAvailableDrivers()) ? 0 : 1);
sqlite3	$d = new SQLite3(":memory:"); echo SQLite3::version()["versionString"]; exit($d->querySingle("select 2 * 3") == 6 ? 0 : 1);
pdo_sqlite	$p = new PDO("sqlite::memory:"); exit($p->query("select 1 + 1")->fetchColumn() == 2 ? 0 : 1);
phar	exit(class_exists("PharData") ? 0 : 1);
posix	exit(posix_getpid() === getmypid() ? 0 : 1);
readline	echo READLINE_LIB; exit(is_array(readline_info()) ? 0 : 1);
session	exit(session_status() === PHP_SESSION_NONE ? 0 : 1);
shmop	exit(function_exists("shmop_open") ? 0 : 1);
simplexml	exit((string) simplexml_load_string("<a><b>x</b></a>")->b === "x" ? 0 : 1);
soap	exit(class_exists("SoapClient") ? 0 : 1);
sockets	exit(socket_create(AF_INET, SOCK_STREAM, SOL_TCP) !== false ? 0 : 1);
sodium	$k = sodium_crypto_secretbox_keygen(); $n = random_bytes(24); exit(sodium_crypto_secretbox_open(sodium_crypto_secretbox("x", $n, $k), $n, $k) === "x" ? 0 : 1);
sysvmsg	exit(function_exists("msg_get_queue") ? 0 : 1);
sysvsem	exit(function_exists("sem_get") ? 0 : 1);
sysvshm	exit(function_exists("shm_attach") ? 0 : 1);
tidy	$t = tidy_parse_string("<p>x"); $t->cleanRepair(); exit(strpos((string) $t, "</p>") !== false ? 0 : 1);
tokenizer	exit(count(token_get_all("<?php echo 1;")) > 2 ? 0 : 1);
xml	$p = xml_parser_create(); exit(xml_parse($p, "<a/>", true) === 1 ? 0 : 1);
xmlreader	$r = new XMLReader(); $r->XML("<a><b>x</b></a>"); $n = null; while ($r->read()) { if ($r->name === "b") { $n = $r->expand(); break; } } exit($n instanceof DOMNode ? 0 : 1);
xmlrpc	exit(xmlrpc_decode(xmlrpc_encode(5)) === 5 ? 0 : 1);
xmlwriter	$w = new XMLWriter(); $w->openMemory(); $w->writeElement("a", "x"); exit($w->outputMemory() === "<a>x</a>" ? 0 : 1);
xsl	$x = new DOMDocument(); $x->loadXML("<a>x</a>"); $s = new DOMDocument(); $s->loadXML('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="text"/><xsl:template match="/">[<xsl:value-of select="a"/>]</xsl:template></xsl:stylesheet>'); $p = new XSLTProcessor(); $p->importStylesheet($s); exit($p->transformToXML($x) === "[x]" ? 0 : 1);
zip	$f = tempnam("/tmp", "zip"); $z = new ZipArchive(); $z->open($f, ZipArchive::OVERWRITE); $z->addFromString("a", "x"); $z->close(); $z->open($f); $v = $z->getFromName("a"); unlink($f); exit($v === "x" ? 0 : 1);
zlib	exit(gzdecode(gzencode("x")) === "x" ? 0 : 1);
ffi	$c = FFI::cdef("int abs(int);", "libc.so.7"); exit($c->abs(-5) === 5 ? 0 : 1);
igbinary	exit(igbinary_unserialize(igbinary_serialize([1, "a"])) === [1, "a"] ? 0 : 1);
memcache	$m = new Memcache(); $m->addServer("127.0.0.1", 11211); $m->set("k", "v"); exit($m->get("k") === "v" ? 0 : 1);
memcached	$m = new Memcached(); $m->addServer("127.0.0.1", 11211); $m->setOption(Memcached::OPT_SERIALIZER, Memcached::SERIALIZER_IGBINARY); $m->set("k", [1]); exit($m->get("k") === [1] ? 0 : 1);
redis	$r = new Redis(); $r->connect("127.0.0.1", 6379); $r->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_IGBINARY); $r->setOption(Redis::OPT_COMPRESSION, Redis::COMPRESSION_ZSTD); $r->set("k", [1]); exit($r->get("k") === [1] ? 0 : 1);
imagick	$f = Imagick::queryFormats(); echo implode(",", array_values(array_intersect(["HEIC", "WEBP", "JPEG", "PNG"], $f))); exit(in_array("HEIC", $f) ? 0 : 1);
mcrypt	exit(in_array("blowfish", mcrypt_list_algorithms()) ? 0 : 1);
excimer	exit(class_exists("ExcimerProfiler") ? 0 : 1);
swoole	echo SWOOLE_VERSION; exit(class_exists("Swoole\\Coroutine") ? 0 : 1);
openswoole	echo OPENSWOOLE_VERSION; exit(class_exists("OpenSwoole\\Coroutine") || class_exists("Swoole\\Coroutine") ? 0 : 1);
EOF
}

# --- the packages of the version, from the repository --------------------------------
mkdir -p "${conf%/*}" || die "cannot make ${conf%/*}"
printf 'azcheck: { url: "file://%s", signature_type: "none", priority: 100, enabled: yes }\n' "$repo" > "$conf"
pkg update -f -r azcheck > "$out/pkg-update.log" 2>&1 || die "pkg update of the repository $repo failed ($out/pkg-update.log)"
pkg rquery -r azcheck '%n' 2> /dev/null | grep -E "^(php$short|mod_php$short|php$short-.+)\$" | LC_ALL=C sort -u > "$out/packages.txt"
grep -qx "php$short" "$out/packages.txt" || die "no package php$short in the repository $repo"
legacy=""
grep -qx "php$short-openssl-legacy" "$out/packages.txt" && legacy="php$short-openssl-legacy"
# php74-static has the files of the core and the modules: one or the other
if pkg info -e "php$short-static"; then
    say "php$short-static is installed: pkg delete (it has the files of php$short and its modules)"
    pkg delete -y "php$short-static" > "$out/pkg-delete.log" 2>&1
fi
[ -n "$legacy" ] && pkg info -e "$legacy" && pkg delete -y "$legacy" >> "$out/pkg-delete.log" 2>&1
want="$(grep -v -x -e "php$short-static" -e "php$short-openssl-legacy" "$out/packages.txt" | tr '\n' ' ')"
say "pkg install -f $want"
# shellcheck disable=SC2086
pkg install -y -f $want > "$out/pkg-install.log" 2>&1 || say "pkg install said it failed (pkg-install.log)"
missing=""
for p in $want; do
    if [ "$(pkg query %R "$p" 2>/dev/null)" = azcheck ]; then continue; fi
    pkg info -e "$p" && fail "$p: installed, but not from the repository ($(pkg query %R "$p"))" && continue
    missing="$missing $p"
done
[ -n "$missing" ] && fail "not installed from the repository:$missing (pkg-install.log)"
[ -x "$php" ] || { fail "no $php"; echo "result:   FAIL (no $php)" >> "$sum"; exit 1; }
api="$("/usr/local/bin/php-config$short" --extension-dir 2>/dev/null)"
api="${api##*/}"
[ -n "$api" ] || api="$("$php" -n -r 'echo PHP_EXTENSION_DIR;' 2>/dev/null)" && api="${api##*/}"
{
    echo "version:  $t ($("$php" -n -v 2>/dev/null | head -n 1))"
    echo "repo:     $repo"
    echo "packages: $(wc -w < "$out/packages.txt" | tr -d ' ') in the repository, $(echo $want | wc -w | tr -d ' ') installed${legacy:+, $legacy for the swap}"
    echo "extdir:   /usr/local/lib/php/$api"
} > "$sum"

# the modules installed: package, module (the .so of lib/php/<API>), ini (or -)
: > "$out/modules.txt"
for p in $(pkg query '%n' | grep -E "^php$short-.+\$" | LC_ALL=C sort); do
    for so in $(pkg info -l "$p" 2>/dev/null | sed -n "s#^[[:space:]]*/usr/local/lib/php/$api/\\(.*\\)\\.so\$#\\1#p"); do
        ini="$(pkg info -l "$p" | sed -n "s#^[[:space:]]*\\(/usr/local/etc/php$short/conf.d/ext-[0-9]*-$so\\.ini\\)\\.sample\$#\\1#p" | head -n 1)"
        echo "$p $so ${ini:--}" >> "$out/modules.txt"
    done
done
say "$(wc -l < "$out/modules.txt" | tr -d ' ') modules installed"

# memcached and redis for memcache, memcached and redis
if grep -qE ' (memcache|memcached|redis) ' "$out/modules.txt"; then
    for s in memcached redis; do
        command -v "$s" > /dev/null 2>&1 || command -v "$s-server" > /dev/null 2>&1 && continue
        say "pkg install $s (the server for the checks of its module)"
        pkg install -y "$s" >> "$out/pkg-install.log" 2>&1 || say "cannot install $s: its module is checked without it"
    done
    command -v memcached > /dev/null 2>&1 &&
        memcached -d -u nobody -l 127.0.0.1 -p 11211 -P /tmp/check-php-memcached.pid < /dev/null > /dev/null 2>&1
    command -v redis-server > /dev/null 2>&1 &&
        redis-server --daemonize yes --bind 127.0.0.1 --port 6379 --pidfile /tmp/check-php-redis.pid < /dev/null > /dev/null 2>&1
fi

# --- the checks ----------------------------------------------------------------------
say "the checks of php$short and its modules"
for f in "$php" "/usr/local/sbin/php-fpm$short" "/usr/local/libexec/apache24/libphp$short.so"; do
    [ -f "$f" ] && check "links of $f" no_ports_lib "$f"
done
while read -r p m ini; do
    check "links of $p ($m.so)" no_ports_lib "/usr/local/lib/php/$api/$m.so"
done < "$out/modules.txt"
"$php" -m > "$out/php-m.txt" 2> "$out/php-m-stderr.txt"
grep -i -E 'warning|error' "$out/php-m.txt" >> "$out/php-m-stderr.txt"
check "php$short -m prints no warning" test ! -s "$out/php-m-stderr.txt"
[ -s "$out/php-m-stderr.txt" ] && head -n 5 "$out/php-m-stderr.txt" | sed 's/^/     /' >> "$tt"
"$php" --ini > "$out/php-ini.txt" 2>&1
check "php$short --ini loads /usr/local/etc/php$short/php.ini" \
    grep -q "Loaded Configuration File:[[:space:]]*/usr/local/etc/php$short/php.ini" "$out/php-ini.txt"
check "php$short --ini lists $(grep -o "conf.d/ext-[^,]*" "$out/php-ini.txt" | wc -l | tr -d ' ') ini files of conf.d" \
    grep -q "/usr/local/etc/php$short/conf.d/ext-" "$out/php-ini.txt"
smoke_lines > "$out/smoke-lines"
while read -r p m ini; do
    [ "$p" = "php$short-openssl-legacy" ] && continue
    code="$(awk -F '\t' -v m="$m" '$1 == m { print $2; exit }' "$out/smoke-lines")"
    # a module whose ini is off (openswoole): on its own, after the modules its package needs
    if [ "$ini" != - ] && ! grep -qE '^[[:space:]]*(zend_)?extension[[:space:]]*=' "$ini" 2>/dev/null; then
        dl=""
        for d in $(pkg query '%dn' "$p" | grep -E "^php$short-.+\$"); do
            for dm in $(awk -v p="$d" '$1 == p { print $3 "|" $2 }' "$out/modules.txt" | LC_ALL=C sort | sed 's/.*|//'); do
                dl="$dl -d extension=$dm.so"
            done
        done
        # shellcheck disable=SC2086
        check "$m on its own (its ini is off)" "$php" -n -d "extension_dir=/usr/local/lib/php/$api" $dl \
            -d "extension=$m.so" -r "${code:-exit(extension_loaded(\"$m\") ? 0 : 1);}" < /dev/null
        continue
    fi
    # the name php -m prints: OPcache is "Zend OPcache"
    mn="$m"; dopt=""
    [ "$m" = opcache ] && { mn="Zend OPcache"; dopt="-d opcache.enable_cli=1"; }
    grep -qix "$mn" "$out/php-m.txt" || { fail "$m ($p): not in php$short -m"; continue; }
    if [ -z "$code" ]; then echo "--   $m: loaded, no check of its own" >> "$tt"; continue; fi
    # shellcheck disable=SC2086
    check "$m" "$php" $dopt -r "$code" < /dev/null
done < "$out/modules.txt"

# RC4 only with the legacy provider: not with php74-openssl, then with php74-openssl-legacy
if pkg info -e "php$short-openssl"; then
    check "RC4 unavailable with php$short-openssl" "$php" -r 'exit(@openssl_encrypt("x", "rc4", "k") === false ? 0 : 1);'
fi
if [ -n "$legacy" ]; then
    pkg install -y "$legacy" > "$out/openssl-swap.log" 2>&1
    if pkg info -e "$legacy" && ! pkg info -e "php$short-openssl"; then
        echo "ok   pkg install $legacy took the place of php$short-openssl (the conflict of their files)" >> "$tt"
    else
        echo "--   pkg install $legacy did not take the place of php$short-openssl: pkg delete, then pkg install (openssl-swap.log)" >> "$tt"
        pkg delete -y "php$short-openssl" >> "$out/openssl-swap.log" 2>&1
        pkg install -y "$legacy" >> "$out/openssl-swap.log" 2>&1
    fi
    check "$legacy installed" pkg info -e "$legacy"
    check "RC4 with $legacy" "$php" -r 'echo bin2hex(openssl_encrypt("x", "rc4", "k", OPENSSL_RAW_DATA)); exit(openssl_encrypt("x", "rc4", "k") !== false ? 0 : 1);'
    "$php" -m > /dev/null 2> "$out/php-m-legacy-stderr.txt"
    check "php$short -m with $legacy prints no warning" test ! -s "$out/php-m-legacy-stderr.txt"
else
    echo "--   no php$short-openssl-legacy in the repository: no check of RC4 with it" >> "$tt"
fi

# php-fpm by its rc.d script
rcd="/usr/local/etc/rc.d/php_fpm$short"
if [ ! -f "$rcd" ]; then
    fail "no $rcd"
elif sh "$rcd" onestart > "$out/fpm.log" 2>&1 && sleep 2 && [ -S "/var/run/php-fpm$short.sock" ]; then
    echo "ok   php_fpm$short onestart: /var/run/php-fpm$short.sock" >> "$tt"
else
    fail "php_fpm$short onestart: no /var/run/php-fpm$short.sock (fpm.log)"
fi
[ -f "$rcd" ] && sh "$rcd" onestop >> "$out/fpm.log" 2>&1

# mod_php in an httpd of its own (127.0.0.1:8074 for 7.4)
so="/usr/local/libexec/apache24/libphp$short.so"
if [ ! -f "$so" ]; then
    fail "mod_php: no $so"
elif [ ! -x /usr/local/sbin/httpd ]; then
    fail "mod_php: no /usr/local/sbin/httpd (apache24)"
else
    hd="$top/work/check-php-httpd-$short"; port="80$short"
    rm -rf "$hd"; mkdir -p "$hd/www"
    echo '<?php echo implode(" ", get_loaded_extensions());' > "$hd/www/index.php"
    chmod -R a+rX "$hd"
    case "$t" in 5.*) mn=php5_module ;; 7.*) mn=php7_module ;; *) mn=php_module ;; esac
    cat > "$hd/httpd.conf" <<EOF
ServerRoot "/usr/local"
Listen 127.0.0.1:$port
ServerName 127.0.0.1
LoadModule mpm_prefork_module libexec/apache24/mod_mpm_prefork.so
LoadModule authz_core_module libexec/apache24/mod_authz_core.so
LoadModule dir_module libexec/apache24/mod_dir.so
LoadModule mime_module libexec/apache24/mod_mime.so
LoadModule unixd_module libexec/apache24/mod_unixd.so
LoadModule $mn libexec/apache24/libphp$short.so
User www
Group www
PidFile "$hd/httpd.pid"
ErrorLog "$out/httpd-error.log"
DocumentRoot "$hd/www"
<Directory "$hd/www">
    Require all granted
</Directory>
<FilesMatch "\.php\$">
    SetHandler application/x-httpd-php
</FilesMatch>
DirectoryIndex index.php
EOF
    check "httpd -t with libphp$short.so" /usr/local/sbin/httpd -t -f "$hd/httpd.conf"
    if /usr/local/sbin/httpd -f "$hd/httpd.conf" -k start > "$out/httpd.log" 2>&1 && sleep 2 &&
        fetch -q -o "$out/mod_php-page.txt" "http://127.0.0.1:$port/index.php" 2>> "$out/httpd.log" &&
        grep -q 'Core' "$out/mod_php-page.txt"; then
        echo "ok   mod_php: $(wc -w < "$out/mod_php-page.txt" | tr -d ' ') extensions on the page of 127.0.0.1:$port" >> "$tt"
    else
        fail "mod_php: no page of 127.0.0.1:$port (httpd.log, httpd-error.log)"
    fi
    /usr/local/sbin/httpd -f "$hd/httpd.conf" -k stop >> "$out/httpd.log" 2>&1
fi

nok="$(grep -c '^ok ' "$tt")"
echo "tests:    $nok ok, $nfail failed (tests.txt)" >> "$sum"
if [ "$nfail" = 0 ]; then
    echo "result:   OK" >> "$sum"
    say "PHP $t: OK ($nok checks)"
    exit 0
fi
grep '^FAIL ' "$tt" | head -n 5 | sed 's/^/          /' >> "$sum"
echo "result:   FAIL ($nfail checks failed)" >> "$sum"
say "PHP $t: FAIL ($nfail of $((nok + nfail)) checks failed, $tt)"
exit 1
