<?php
// lib-bench.php - the PHP part of tools/lib-bench.sh: what PHP sites do with the C
// libraries of the package az, the inputs of the benchmarks, and the timing of the
// programs of the libraries (cjpeg, djpeg, xmllint, speedtest1, the drivers of
// tools/lib-bench.c).
//
// Usage (php -n with the modules dom, xml, simplexml, xmlreader, xsl, mbstring,
// sqlite3, pdo, pdo_sqlite, gd and zip loaded; tools/lib-bench.sh gives them):
//   php lib-bench.php --gen <dir> [<cjpeg>]    the inputs into <dir>: catalog.xml,
//                                              catalog-small.xml, catalog.xsl, text.txt,
//                                              photo.ppm, photo.jpg, photo-moz.jpg,
//                                              photo-1280.png (cjpeg: the two JPEG files
//                                              made with it, else with imagejpeg)
//   php lib-bench.php --list                   the benchmarks of this file
//   php lib-bench.php <benchmark> <n> <dir>    one run: the work of <benchmark> done <n>
//                                              times (one more before, not timed)
//   php lib-bench.php --time <n> <out> <program> [<arg>...]
//                                              one run of a program: <n> times in turn;
//                                              <out>: the file it writes (its MD5 is the
//                                              check), - for its standard output, none for
//                                              no check (an output with times in it)
//   php lib-bench.php --maps <name>...         the files of the libraries this process has
//                                              mapped whose names begin with <name>
//                                              (procstat -v on FreeBSD, /proc/self/maps)
// A run prints "time <seconds>" (the timed part, hrtime) and "check <value>" (a digest
// of the result, the same for the same work: the outputs of the variants compare); a
// failure goes to standard error with exit status 1. Every input is made here from a
// fixed seed, nothing is downloaded. Written for PHP 7.4 and later.

declare(strict_types=1);

const SEED = 20261109;
const FONTS = [
    '/usr/local/share/fonts/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/dejavu/DejaVuSans.ttf',
];

function fail(string $msg): void
{
    fwrite(STDERR, "lib-bench.php: $msg\n");
    exit(1);
}

// $f() once, not timed, then $n times: the time of those and the check of the last
function timed(int $n, callable $f): void
{
    $c = $f();
    $t = hrtime(true);
    for ($i = 0; $i < $n; $i++) {
        $c = $f();
    }
    printf("time %.6f\ncheck %s\n", (hrtime(true) - $t) / 1e9, (string) $c);
}

function words(int $count, array $from): string
{
    $out = [];
    $m = count($from) - 1;
    for ($i = 0; $i < $count; $i++) {
        $out[] = $from[mt_rand(0, $m)];
    }
    return implode(' ', $out);
}

const LATIN = ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'video', 'stream', 'player', 'archive',
    'gallery', 'category', 'channel', 'upload', 'quality', 'premium', 'mobile', 'search', 'popular',
    'random', 'latest', 'rating', 'duration', 'favorite', 'comment', 'profile', 'model', 'studio'];
const CYRILLIC = ['привет', 'видео', 'смотреть', 'онлайн', 'бесплатно', 'категория', 'новое',
    'популярное', 'качество', 'загрузка', 'Москва', 'москвичи', 'Петербург', 'рейтинг', 'комментарий',
    'профиль', 'студия', 'длительность', 'избранное', 'поиск', 'ёлка', 'Ёжик', 'съёмка', 'подписка'];

// --- the inputs ----------------------------------------------------------------------

function esc(string $s): string
{
    return htmlspecialchars($s, ENT_XML1 | ENT_QUOTES, 'UTF-8');
}

function gen_catalog(int $items): string
{
    $x = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<catalog generated=\"2026-11-09\">\n";
    for ($i = 1; $i <= $items; $i++) {
        $x .= sprintf(" <item id=\"v%d\" cat=\"c%d\" stock=\"%d\">\n", $i, mt_rand(1, 12), mt_rand(0, 500));
        $x .= '  <name>' . esc(ucfirst(words(mt_rand(2, 6), mt_rand(0, 1) ? LATIN : CYRILLIC))) . "</name>\n";
        $x .= sprintf("  <price>%.2f</price>\n", mt_rand(100, 99999) / 100);
        $x .= '  <desc>' . esc(words(mt_rand(10, 40), LATIN) . ' & ' . words(mt_rand(5, 20), CYRILLIC) . " <$i>") . "</desc>\n";
        $x .= '  <tags>';
        for ($t = mt_rand(1, 6); $t > 0; $t--) {
            $x .= '<tag>t' . mt_rand(1, 40) . '</tag>';
        }
        $x .= "</tags>\n";
        $x .= sprintf("  <stats views=\"%d\" likes=\"%d\" duration=\"%d\"/>\n </item>\n",
            mt_rand(0, 1000000), mt_rand(0, 10000), mt_rand(30, 7200));
    }
    return $x . "</catalog>\n";
}

const XSL = <<<'XSL'
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  <xsl:key name="by-cat" match="item" use="@cat"/>
  <xsl:template match="/catalog">
    <html><body>
      <h1>Catalog of <xsl:value-of select="@generated"/>: <xsl:value-of select="count(item)"/> items</h1>
      <xsl:for-each select="item[generate-id() = generate-id(key('by-cat', @cat)[1])]">
        <xsl:sort select="@cat"/>
        <xsl:variable name="c" select="@cat"/>
        <h2><xsl:value-of select="translate($c, 'c', 'C')"/>:
          <xsl:value-of select="count(key('by-cat', $c))"/> items,
          <xsl:value-of select="format-number(sum(key('by-cat', $c)/price), '#,##0.00')"/></h2>
        <table>
          <xsl:for-each select="key('by-cat', $c)">
            <xsl:sort select="price" data-type="number" order="descending"/>
            <xsl:if test="position() &lt;= 50">
              <tr class="{substring('oddeven', 1 + 3 * (position() mod 2), 4)}">
                <td><xsl:value-of select="@id"/></td>
                <td><xsl:value-of select="concat(substring(name, 1, 30), '...')"/></td>
                <td><xsl:value-of select="format-number(price, '0.00')"/></td>
                <td><xsl:value-of select="count(tags/tag)"/></td>
                <td><xsl:apply-templates select="stats"/></td>
              </tr>
            </xsl:if>
          </xsl:for-each>
        </table>
      </xsl:for-each>
    </body></html>
  </xsl:template>
  <xsl:template match="stats">
    <xsl:choose>
      <xsl:when test="@views &gt; 500000">hot</xsl:when>
      <xsl:when test="@likes &gt; 5000">liked</xsl:when>
      <xsl:otherwise><xsl:value-of select="floor(@duration div 60)"/> min</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
XSL;

function gen_text(int $paragraphs): string
{
    $out = [];
    for ($p = 0; $p < $paragraphs; $p++) {
        $s = [];
        for ($k = mt_rand(3, 8); $k > 0; $k--) {
            $w = words(mt_rand(6, 18), mt_rand(0, 2) ? CYRILLIC : LATIN);
            if (mt_rand(0, 4) == 0) {
                $w .= ' user' . mt_rand(1, 999) . '@example' . mt_rand(1, 9) . '.com';
            }
            if (mt_rand(0, 3) == 0) {
                $w .= ' ' . mt_rand(1, 99999) . ' руб.';
            }
            $s[] = mb_strtoupper(mb_substr($w, 0, 1)) . mb_substr($w, 1) . (mt_rand(0, 5) ? '.' : '!');
        }
        $out[] = implode("  ", $s);
    }
    return implode("\n\n\t", $out) . "\n";
}

// a photo-like truecolor image: gradients, shapes with alpha, a texture of noise
function gen_photo(int $w, int $h)
{
    $im = imagecreatetruecolor($w, $h);
    for ($y = 0; $y < $h; $y++) {
        $r = (int) (40 + 160 * $y / $h);
        $g = (int) (90 + 100 * sin($y / 170));
        $b = (int) (200 - 150 * $y / $h);
        imageline($im, 0, $y, $w - 1, $y, imagecolorallocate($im, $r, max(0, $g), max(0, $b)));
    }
    imagealphablending($im, true);
    for ($i = 0; $i < 400; $i++) {
        $c = imagecolorallocatealpha($im, mt_rand(0, 255), mt_rand(0, 255), mt_rand(0, 255), mt_rand(30, 100));
        $cx = mt_rand(0, $w);
        $cy = mt_rand(0, $h);
        $rx = mt_rand(10, 400);
        if ($i % 3) {
            imagefilledellipse($im, $cx, $cy, $rx, mt_rand(10, 400), $c);
        } else {
            imagefilledrectangle($im, $cx, $cy, $cx + $rx, $cy + mt_rand(5, 200), $c);
        }
    }
    $tile = imagecreatetruecolor(256, 256);
    for ($y = 0; $y < 256; $y++) {
        for ($x = 0; $x < 256; $x++) {
            $v = mt_rand(0, 255);
            imagesetpixel($tile, $x, $y, ($v << 16) | ($v << 8) | mt_rand(0, 255));
        }
    }
    for ($y = 0; $y < $h; $y += 256) {
        for ($x = 0; $x < $w; $x += 256) {
            imagecopymerge($im, $tile, $x, $y, 0, 0, 256, 256, 12);
        }
    }
    imagefilter($im, IMG_FILTER_SMOOTH, 6);
    return $im;
}

function write_ppm($im, string $file): void
{
    $w = imagesx($im);
    $h = imagesy($im);
    $f = fopen($file, 'wb');
    fwrite($f, "P6\n$w $h\n255\n");
    for ($y = 0; $y < $h; $y++) {
        $row = '';
        for ($x = 0; $x < $w; $x++) {
            $c = imagecolorat($im, $x, $y);
            $row .= chr(($c >> 16) & 255) . chr(($c >> 8) & 255) . chr($c & 255);
        }
        fwrite($f, $row);
    }
    fclose($f);
}

function run_prog(array $cmd): void
{
    $p = proc_open($cmd, [0 => ['file', '/dev/null', 'r'], 1 => ['file', '/dev/null', 'w'], 2 => ['pipe', 'w']], $pipes);
    if (!is_resource($p)) {
        fail('cannot run ' . implode(' ', $cmd));
    }
    $err = stream_get_contents($pipes[2]);
    fclose($pipes[2]);
    $rc = proc_close($p);
    if ($rc !== 0) {
        fail(implode(' ', $cmd) . ": exit $rc: " . trim($err));
    }
}

function gen(string $d, string $cjpeg): void
{
    if (!is_dir($d) && !mkdir($d, 0755, true)) {
        fail("cannot make $d");
    }
    mt_srand(SEED);
    file_put_contents("$d/catalog.xml", gen_catalog(6000));
    file_put_contents("$d/catalog-small.xml", gen_catalog(1500));
    file_put_contents("$d/catalog.xsl", XSL);
    file_put_contents("$d/text.txt", gen_text(900));
    $im = gen_photo(3000, 2000);
    write_ppm($im, "$d/photo.ppm");
    if ($cjpeg !== '') {
        // an upload of a camera (baseline, the libjpeg defaults), and the mozjpeg
        // default of the sites' own files (progressive, trellis)
        run_prog([$cjpeg, '-revert', '-quality', '92', '-outfile', "$d/photo.jpg", "$d/photo.ppm"]);
        run_prog([$cjpeg, '-quality', '85', '-outfile', "$d/photo-moz.jpg", "$d/photo.ppm"]);
    } else {
        imagejpeg($im, "$d/photo.jpg", 92);
        imagejpeg($im, "$d/photo-moz.jpg", 85);
    }
    $small = imagecreatetruecolor(1280, 853);
    imagecopyresampled($small, $im, 0, 0, 0, 0, 1280, 853, 3000, 2000);
    imagepng($small, "$d/photo-1280.png");
    foreach (['catalog.xml', 'catalog-small.xml', 'text.txt', 'photo.ppm', 'photo.jpg', 'photo-moz.jpg', 'photo-1280.png'] as $f) {
        printf("%s: %d bytes, md5 %s\n", $f, filesize("$d/$f"), md5_file("$d/$f"));
    }
    printf("font for imagettftext: %s\n", font());
}

function font(): string
{
    foreach (FONTS as $f) {
        if (is_file($f)) {
            return $f;
        }
    }
    return '';
}

function need(string $file): string
{
    if (!is_file($file)) {
        fail("no $file (lib-bench.php --gen)");
    }
    return $file;
}

// --- the benchmarks: name => [function, what] -------------------------------------------

const BENCH = [
    'php-dom' => 'DOMDocument::loadXML (2 MB), DOMXPath queries, saveXML',
    'php-simplexml' => 'simplexml_load_string, iteration, xpath, asXML',
    'php-xmlreader' => 'XMLReader over the document',
    'php-xml' => 'xml_parse with element and text handlers (ext/xml)',
    'php-xsl' => 'XSLTProcessor::transformToXml (grouping, sorting)',
    'php-mb-replace' => 'mb_ereg_replace, mb_eregi_replace on UTF-8 text',
    'php-mb-search' => 'mb_ereg_search_regs, mb_split on UTF-8 text',
    'php-sqlite3' => 'SQLite3: inserts in a transaction, indexed selects, join',
    'php-pdo-sqlite' => 'PDO sqlite: the same',
    'php-gd-jpeg-read' => 'imagecreatefromjpeg (3000x2000, baseline)',
    'php-gd-resize' => 'imagecopyresampled, imagescale (3000x2000 to thumbnails)',
    'php-gd-jpeg' => 'imagejpeg (1280x853, quality 85)',
    'php-gd-png' => 'imagepng (1280x853)',
    'php-gd-png-read' => 'imagecreatefrompng (1280x853)',
    'php-gd-ttf' => 'imagettftext (DejaVu Sans, Latin and Cyrillic)',
    'php-zip' => 'ZipArchive: 600 files added, written, read back',
];

function b_php_dom(int $n, string $d): void
{
    $xml = file_get_contents(need("$d/catalog.xml"));
    timed($n, function () use ($xml) {
        $doc = new DOMDocument();
        if (!$doc->loadXML($xml)) {
            fail('loadXML failed');
        }
        $xp = new DOMXPath($doc);
        $c = $xp->query('//item[@cat="c3"]/name')->length;
        $c += (int) $xp->evaluate('count(//tag[. = "t5"])');
        $c += (int) $xp->evaluate('sum(//item/@stock)');
        foreach ($xp->query('//item[price > 900]') as $e) {
            $c += strlen($e->getAttribute('id'));
        }
        foreach ($doc->getElementsByTagName('stats') as $e) {
            $c += (int) $e->getAttribute('likes') & 7;
        }
        return $c . '-' . strlen($doc->saveXML());
    });
}

function b_php_simplexml(int $n, string $d): void
{
    $xml = file_get_contents(need("$d/catalog.xml"));
    timed($n, function () use ($xml) {
        $sx = simplexml_load_string($xml);
        if ($sx === false) {
            fail('simplexml_load_string failed');
        }
        $c = 0;
        foreach ($sx->item as $it) {
            $c += (int) $it['stock'] + strlen((string) $it->name) + count($it->tags->tag);
        }
        $c += count($sx->xpath('//item[@cat="c5"]'));
        return $c . '-' . strlen($sx->asXML());
    });
}

function b_php_xmlreader(int $n, string $d): void
{
    $xml = file_get_contents(need("$d/catalog.xml"));
    timed($n, function () use ($xml) {
        $r = XMLReader::XML($xml);
        $c = 0;
        while ($r->read()) {
            if ($r->nodeType === XMLReader::ELEMENT) {
                $c++;
                if ($r->name === 'item') {
                    $c += strlen((string) $r->getAttribute('id'));
                }
            } elseif ($r->nodeType === XMLReader::TEXT) {
                $c += strlen($r->value);
            }
        }
        $r->close();
        return $c;
    });
}

function b_php_xml(int $n, string $d): void
{
    $xml = file_get_contents(need("$d/catalog.xml"));
    timed($n, function () use ($xml) {
        $c = 0;
        $p = xml_parser_create('UTF-8');
        xml_parser_set_option($p, XML_OPTION_CASE_FOLDING, 0);
        xml_set_element_handler($p, function ($p, $name, $attrs) use (&$c) {
            $c += 1 + count($attrs);
        }, function ($p, $name) {
        });
        xml_set_character_data_handler($p, function ($p, $data) use (&$c) {
            $c += strlen($data);
        });
        if (!xml_parse($p, $xml, true)) {
            fail('xml_parse: ' . xml_error_string(xml_get_error_code($p)));
        }
        xml_parser_free($p);
        return $c;
    });
}

function b_php_xsl(int $n, string $d): void
{
    $xml = file_get_contents(need("$d/catalog-small.xml"));
    $xsl = new DOMDocument();
    $xsl->load(need("$d/catalog.xsl"));
    $proc = new XSLTProcessor();
    $proc->importStylesheet($xsl);
    timed($n, function () use ($xml, $proc) {
        $doc = new DOMDocument();
        $doc->loadXML($xml);
        $out = $proc->transformToXml($doc);
        if (!is_string($out)) {
            fail('transformToXml failed');
        }
        return strlen($out) . '-' . md5($out);
    });
}

function b_php_mb_replace(int $n, string $d): void
{
    $text = file_get_contents(need("$d/text.txt"));
    mb_regex_encoding('UTF-8');
    timed($n, function () use ($text) {
        $r = mb_ereg_replace('[[:space:]]+', ' ', $text);
        $r = mb_ereg_replace('([A-Za-z0-9._-]+)@([A-Za-z0-9.-]+)\.com', '\\1 (at) \\2', $r);
        $r = mb_eregi_replace('москв[а-яё]*', 'Мск', $r);
        $r = mb_ereg_replace('(\d+) руб\.', '\\1 ₽', $r);
        $r = mb_ereg_replace('[^\w\s.,!?()₽-]', '', $r);
        $r = mb_eregi_replace('\b(video|видео)\b', '[\\1]', $r);
        return strlen($r) . '-' . md5($r);
    });
}

function b_php_mb_search(int $n, string $d): void
{
    $text = file_get_contents(need("$d/text.txt"));
    mb_regex_encoding('UTF-8');
    timed($n, function () use ($text) {
        $c = 0;
        foreach (['[а-яё]{8,}', '(\p{Lu}\p{Ll}+)\s+(\p{Ll}+)', 'user\d+@\w+\.com', '\d+'] as $re) {
            mb_ereg_search_init($text, $re, 'i');
            while (($m = mb_ereg_search_regs()) !== false) {
                $c += 1 + strlen($m[0]);
            }
        }
        $c += count(mb_split('[.!?]\s+', $text));
        return $c;
    });
}

// the same database work through SQLite3 and PDO
function sql_work(callable $exec, callable $prep, callable $run, callable $rows): string
{
    mt_srand(SEED);
    $exec('CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, email TEXT, city TEXT, age INT)');
    $exec('CREATE TABLE posts(id INTEGER PRIMARY KEY, user_id INT, title TEXT, body TEXT, created INT, views INT)');
    $exec('BEGIN');
    $u = $prep('INSERT INTO users VALUES(?, ?, ?, ?, ?)');
    for ($i = 1; $i <= 4000; $i++) {
        $run($u, [$i, words(2, CYRILLIC), "user$i@example.com", 'city' . mt_rand(1, 60), mt_rand(18, 80)]);
    }
    $p = $prep('INSERT INTO posts VALUES(?, ?, ?, ?, ?, ?)');
    for ($i = 1; $i <= 20000; $i++) {
        $run($p, [$i, mt_rand(1, 4000), words(5, LATIN), words(30, CYRILLIC), 1700000000 + $i * 37, mt_rand(0, 100000)]);
    }
    $exec('COMMIT');
    $exec('CREATE INDEX posts_user ON posts(user_id, created)');
    $exec('CREATE INDEX users_city ON users(city)');
    $c = 0;
    $s = $prep('SELECT title, views FROM posts WHERE user_id = ? ORDER BY created DESC LIMIT 10');
    for ($i = 0; $i < 4000; $i++) {
        foreach ($rows($s, [mt_rand(1, 4000)]) as $r) {
            $c += (int) $r[1] & 15;
        }
    }
    $s = $prep('SELECT name, email, age FROM users WHERE id = ?');
    for ($i = 0; $i < 8000; $i++) {
        foreach ($rows($s, [mt_rand(1, 4000)]) as $r) {
            $c += (int) $r[2];
        }
    }
    $s = $prep('SELECT u.city, count(*), sum(p.views), avg(length(p.body)) FROM users u JOIN posts p ON p.user_id = u.id '
        . 'WHERE u.age BETWEEN ? AND ? GROUP BY u.city ORDER BY 2 DESC, 1');
    foreach ([[18, 30], [31, 50], [51, 80]] as $a) {
        foreach ($rows($s, $a) as $r) {
            $c += (int) $r[1] + (int) $r[2] % 1000;
        }
    }
    $s = $prep("SELECT count(*) FROM posts WHERE title LIKE ? OR body LIKE ?");
    foreach ($rows($s, ['%stream%', '%Москва%']) as $r) {
        $c += (int) $r[0];
    }
    $exec('UPDATE posts SET views = views + 1 WHERE created > 1700400000');
    $exec('DELETE FROM posts WHERE views % 7 = 0');
    return (string) $c;
}

function b_php_sqlite3(int $n, string $d): void
{
    timed($n, function () {
        $db = new SQLite3(':memory:');
        $db->enableExceptions(true);
        $c = sql_work(
            function ($q) use ($db) { $db->exec($q); },
            function ($q) use ($db) { return $db->prepare($q); },
            function ($st, $a) {
                foreach ($a as $k => $v) {
                    $st->bindValue($k + 1, $v);
                }
                $st->execute();
                $st->reset();
            },
            function ($st, $a) {
                foreach ($a as $k => $v) {
                    $st->bindValue($k + 1, $v);
                }
                $res = $st->execute();
                $out = [];
                while (($r = $res->fetchArray(SQLITE3_NUM)) !== false) {
                    $out[] = $r;
                }
                $res->finalize();
                $st->reset();
                return $out;
            }
        );
        $db->close();
        return $c;
    });
}

function b_php_pdo_sqlite(int $n, string $d): void
{
    timed($n, function () {
        $db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        return sql_work(
            function ($q) use ($db) { $db->exec($q); },
            function ($q) use ($db) { return $db->prepare($q); },
            function ($st, $a) { $st->execute($a); },
            function ($st, $a) {
                $st->execute($a);
                return $st->fetchAll(PDO::FETCH_NUM);
            }
        );
    });
}

function pix($im): string
{
    $w = imagesx($im);
    $h = imagesy($im);
    $c = 0;
    for ($i = 1; $i < 64; $i++) {
        $c = ($c * 31 + imagecolorat($im, ($i * 997) % $w, ($i * 613) % $h)) % 1000000007;
    }
    return "{$w}x$h-$c";
}

function photo_1280(string $d)
{
    $im = imagecreatefrompng(need("$d/photo-1280.png"));
    if (!$im) {
        fail('imagecreatefrompng failed');
    }
    return $im;
}

function b_php_gd_jpeg_read(int $n, string $d): void
{
    $f = need("$d/photo.jpg");
    timed($n, function () use ($f) {
        $im = imagecreatefromjpeg($f);
        if (!$im) {
            fail('imagecreatefromjpeg failed');
        }
        $c = pix($im);
        imagedestroy($im);
        return $c;
    });
}

function b_php_gd_resize(int $n, string $d): void
{
    $src = imagecreatefromjpeg(need("$d/photo.jpg"));
    timed($n, function () use ($src) {
        $c = '';
        foreach ([[1280, 853], [320, 213]] as $s) {
            $t = imagecreatetruecolor($s[0], $s[1]);
            imagecopyresampled($t, $src, 0, 0, 0, 0, $s[0], $s[1], imagesx($src), imagesy($src));
            $c .= pix($t) . ' ';
            imagedestroy($t);
        }
        $t = imagescale($src, 640, -1, IMG_BILINEAR_FIXED);
        $c .= pix($t);
        imagedestroy($t);
        return $c;
    });
}

function b_php_gd_jpeg(int $n, string $d): void
{
    $im = photo_1280($d);
    timed($n, function () use ($im) {
        ob_start();
        imagejpeg($im, null, 85);
        $s = ob_get_clean();
        return strlen($s) . '-' . md5($s);
    });
}

function b_php_gd_png(int $n, string $d): void
{
    $im = photo_1280($d);
    timed($n, function () use ($im) {
        ob_start();
        imagepng($im);
        $s = ob_get_clean();
        return strlen($s) . '-' . md5($s);
    });
}

function b_php_gd_png_read(int $n, string $d): void
{
    $f = need("$d/photo-1280.png");
    timed($n, function () use ($f) {
        $im = imagecreatefrompng($f);
        if (!$im) {
            fail('imagecreatefrompng failed');
        }
        $c = pix($im);
        imagedestroy($im);
        return $c;
    });
}

function b_php_gd_ttf(int $n, string $d): void
{
    $font = font();
    if ($font === '') {
        fail('no DejaVuSans.ttf (' . implode(', ', FONTS) . ')');
    }
    $texts = ['Popular videos of the week', 'Смотреть онлайн бесплатно', 'Ёжик в тумане, 1975',
        'HD 1080p • 12:34', 'Категория: новое', 'The quick brown fox jumps over the lazy dog 0123456789'];
    timed($n, function () use ($font, $texts) {
        $im = imagecreatetruecolor(1280, 853);
        imagefilledrectangle($im, 0, 0, 1279, 852, 0xffffff);
        $c = 0;
        for ($i = 0; $i < 240; $i++) {
            $size = 8 + ($i * 7) % 41;
            $angle = [0, 0, 0, 15, -30, 90][$i % 6];
            $b = imagettftext($im, $size, $angle, 20 + ($i * 53) % 1100, 40 + ($i * 37) % 780,
                ($i * 2654435761) & 0x7fffff, $font, $texts[$i % count($texts)]);
            if ($b === false) {
                fail('imagettftext failed');
            }
            $c += $b[2] - $b[0] + $b[5];
        }
        $c .= '-' . pix($im);
        imagedestroy($im);
        return $c;
    });
}

function b_php_zip(int $n, string $d): void
{
    mt_srand(SEED);
    $files = [];
    for ($i = 0; $i < 600; $i++) {
        $files[] = str_repeat(words(mt_rand(20, 400), $i % 2 ? LATIN : CYRILLIC) . "\n", mt_rand(1, 4));
    }
    $zf = sys_get_temp_dir() . '/lib-bench-' . getmypid() . '.zip';
    timed($n, function () use ($files, $zf) {
        $z = new ZipArchive();
        if ($z->open($zf, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
            fail("cannot write $zf");
        }
        foreach ($files as $i => $s) {
            $z->addFromString('dir' . ($i % 10) . "/file$i.txt", $s);
            if ($i % 4 === 0) {
                $z->setCompressionIndex($i, ZipArchive::CM_STORE);
            }
        }
        $z->close();
        $z = new ZipArchive();
        if ($z->open($zf) !== true) {
            fail("cannot read $zf");
        }
        $c = 0;
        for ($i = 0; $i < $z->numFiles; $i++) {
            $c += strlen($z->getFromIndex($i));
            $c += $z->statIndex($i)['crc'] & 255;
        }
        $z->close();
        unlink($zf);
        return $c;
    });
}

// --- the programs of the libraries ----------------------------------------------------

function time_prog(int $n, string $out, array $cmd): void
{
    $md5 = '-';
    $t = 0;
    for ($i = 0; $i < $n; $i++) {
        $o = $out === '-' ? ['pipe', 'w'] : ['file', '/dev/null', 'w'];
        $t0 = hrtime(true);
        $p = proc_open($cmd, [0 => ['file', '/dev/null', 'r'], 1 => $o, 2 => ['pipe', 'w']], $pipes);
        if (!is_resource($p)) {
            fail('cannot run ' . implode(' ', $cmd));
        }
        $so = $out === '-' ? stream_get_contents($pipes[1]) : '';
        $err = stream_get_contents($pipes[2]);
        foreach ($pipes as $x) {
            fclose($x);
        }
        $rc = proc_close($p);
        $t += hrtime(true) - $t0;
        if ($rc !== 0) {
            fail(implode(' ', $cmd) . ": exit $rc: " . trim(substr($err, 0, 300)));
        }
        if ($out === '-') {
            $md5 = md5($so);
        }
    }
    if ($out !== '-' && $out !== 'none') {
        $md5 = is_file($out) ? md5_file($out) : 'no-output';
    }
    printf("time %.6f\ncheck %s\n", $t / 1e9, $md5);
}

function maps(array $names): void
{
    $lines = [];
    if (is_readable('/proc/self/maps')) {
        foreach (file('/proc/self/maps') as $l) {
            $f = preg_split('/\s+/', trim($l));
            if (count($f) >= 6 && $f[5][0] === '/') {
                $lines[] = $f[5];
            }
        }
    } else {
        // FreeBSD: the PATH column of procstat -v of this process
        foreach (explode("\n", (string) shell_exec('procstat -v ' . getmypid() . ' 2>&1')) as $l) {
            $f = preg_split('/\s+/', trim($l));
            $p = end($f);
            if (is_string($p) && $p !== '' && $p[0] === '/') {
                $lines[] = $p;
            }
        }
    }
    $seen = [];
    foreach (array_unique($lines) as $p) {
        foreach ($names as $n) {
            if (strpos(basename($p), $n) === 0 && !isset($seen[$p])) {
                $seen[$p] = 1;
                echo "map $p\n";
            }
        }
    }
}

$a = $argv;
array_shift($a);
$cmd = $a[0] ?? '';
if ($cmd === '--gen' && isset($a[1])) {
    gen($a[1], $a[2] ?? '');
} elseif ($cmd === '--list') {
    foreach (BENCH as $k => $v) {
        echo "$k\t$v\n";
    }
} elseif ($cmd === '--time' && count($a) >= 4 && preg_match('/^[0-9]+$/', $a[1])) {
    time_prog((int) $a[1], $a[2], array_slice($a, 3));
} elseif ($cmd === '--maps' && count($a) >= 2) {
    maps(array_slice($a, 1));
} elseif (isset(BENCH[$cmd]) && count($a) === 3 && preg_match('/^[0-9]+$/', $a[1])) {
    $f = 'b_' . str_replace('-', '_', $cmd);
    $f((int) $a[1], $a[2]);
} else {
    fail('usage: --gen <dir> [<cjpeg>] | --list | <benchmark> <n> <dir> | --time <n> <out> <program> [<arg>...] | --maps <name>...');
}
