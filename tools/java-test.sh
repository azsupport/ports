#!/bin/sh
# java-test.sh - test OpenJDK 17 and JNA of the repository az, installed from it
# (aZ, 11.11.2026: our openjdk17, headless, and jna without X11, for Elasticsearch
# 6): Java programs compiled here with its javac, run with its java:
#   version   java -version is that of the package; no bin/java in /usr/local/bin
#             (no javavmwrapper)
#   headless  java.awt.GraphicsEnvironment.isHeadless(), without DISPLAY and with
#             one (no libawt_xawt: headless all the same)
#   imageio   a BufferedImage written and read back by ImageIO as JPEG (libjavajpeg
#             on the libjpeg of az) and as PNG (Java and zlib)
#   icc       a colour of sRGB in CIE XYZ and an image to grey through Little CMS
#             (liblcms on the liblcms2 of az)
#   font      text drawn with a logical font (the fonts of fontconfig, which OpenJDK
#             loads with dlopen: the official fontconfig when it is installed) and
#             with the file of a TrueType font when there is one (FreeType of az),
#             then the same without fontconfig (USE_J2D_FONTCONFIG=no, as with our
#             packages only): what happens is recorded, Elasticsearch needs no fonts
#   sound     javax.sound.sampled.AudioSystem.getMixerInfo() without an exception
#             (no libjsound, no ALSA: no devices)
#   tls       TLS 1.3 between a server and a client on 127.0.0.1 (a key of keytool,
#             the name checked as HTTPS does); the CA store of the JDK
#   libs      the libraries the process mapped (procstat -v): libjpeg, libfreetype
#             and liblcms2 of /usr/local/az/lib; nothing of X11, ALSA, giflib,
#             libpng and HarfBuzz
#   jna       getpid of libc through JNA (jna.jar of devel/jna, as Elasticsearch
#             loads it: jna.nosys) is the pid of ProcessHandle; its libjnidispatch.so
#             with the libffi of az; then with the libjnidispatch.so of the package
#             (-Djna.boot.library.path=/usr/local/lib/jna -Djna.nosys=false, aZ
#             11.11.2026: Elasticsearch writes nothing at its start): that file
#             loaded (-Djna.debug_load.jna=true logs which jnidispatch, procstat),
#             nothing extracted from the jar (-Djna.debug_load=true logs an
#             extraction; jna.tmpdir stays empty)
#   deps      pkg info -d of openjdk17 and jna: az only; elasticsearch6, when it is
#             installed: bash, jna and openjdk17, and among all the packages it
#             needs none of a desktop
#
# Usage (FreeBSD, as root, the packages installed): sh tools/java-test.sh
# Results: java-results/tests.txt (one line per check, the summary at the end), the
# output of the programs next to it; the same on the standard output, its last lines
# what the fonts gave and the summary; exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/java-results}"
T="${JAVA_TEST_WORK:-/var/tmp/java-test}"
P=/usr/local
J="$P/openjdk17"
jna="$P/share/java/classes/jna.jar"
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T/src" "$T/classes" "$T/jna"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
# val <file> <key>: the value of the line "<key>=..." the program printed
val() { sed -n "s/^$2=//p" "$1" | head -n 1; }
# done_: the summary, tests.txt on the standard output, its last lines what the fonts
# gave and the summary (test-programs.sh shows the last three); the exit status
done_() {
    echo "java-test: $ok ok, $bad failed" >> "$out"
    cat "$out"
    echo "fonts: ${font_sum:-not tried}"
    echo "fonts without fontconfig: ${nofc_sum:-not tried}"
    echo "java-test: $ok ok, $bad failed"
    [ "$bad" = 0 ]; exit $?
}
font_sum=""; nofc_sum=""
unset DISPLAY

for p in openjdk17 jna; do
    pkg info -e "$p" || fail "$p is not installed"
done
[ "$bad" = 0 ] || done_

# version
v="$("$J/bin/java" -version 2>&1)"
printf '%s\n' "$v" > "$res/java-version.txt"
pv="$(pkgv openjdk17)"
case "$v" in
    *"version \"${pv%%+*}\""*) pass "java -version: $(printf '%s\n' "$v" | sed -n 2p) (the package is $pv)" ;;
    *) fail "java -version: $(printf '%s\n' "$v" | tr '\n' ' '), the package is $pv" ;;
esac
w="$(pkg which -q "$P/bin/java" 2>/dev/null)"
if pkg info -l openjdk17 | grep -q "^[[:space:]]*$P/bin/java\$"; then
    fail "openjdk17 installs $P/bin/java"
elif [ -n "$w" ]; then
    note "$P/bin/java is there, of $w (not of openjdk17)"
else
    pass "no $P/bin/java (no javavmwrapper): Java by JAVA_HOME $J"
fi

# the programs
cat > "$T/src/AzJavaTest.java" <<'EOF'
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.color.ColorSpace;
import java.awt.color.ICC_ColorSpace;
import java.awt.image.BufferedImage;
import java.awt.image.ColorConvertOp;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.Iterator;
import java.util.Locale;
import java.util.TreeSet;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriter;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLServerSocket;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Mixer;

// java AzJavaTest <work dir> <font file or -> [font | <keystore> <password>
// <truststore>]: each check a line "<key>=<result>" ("ERROR <exception>" when it
// threw; "font": the fonts only), then "map=<library>" for each library the
// process mapped (procstat -v)
public class AzJavaTest {
    interface Check { String run() throws Throwable; }

    static void check(String key, Check c) {
        String r;
        try {
            r = c.run();
        } catch (Throwable t) {
            r = "ERROR " + t;
            StackTraceElement[] s = t.getStackTrace();
            if (s.length > 0) r += " at " + s[0];
            // the first cause, as an InternalError of FontManagerFactory hides it
            Throwable root = t;
            while (root.getCause() != null && root.getCause() != root) root = root.getCause();
            if (root != t) r += "; cause: " + root;
        }
        System.out.println(key + "=" + r.replace('\n', ' '));
    }

    static BufferedImage picture() {
        BufferedImage img = new BufferedImage(64, 48, BufferedImage.TYPE_INT_RGB);
        for (int y = 0; y < 48; y++)
            for (int x = 0; x < 64; x++)
                img.setRGB(x, y, (x * 4) << 16 | (y * 5) << 8 | 0x80);
        return img;
    }

    // the mean difference of the channels of two pictures of one size
    static double diff(BufferedImage a, BufferedImage b) {
        long d = 0;
        for (int y = 0; y < a.getHeight(); y++)
            for (int x = 0; x < a.getWidth(); x++) {
                int p = a.getRGB(x, y), q = b.getRGB(x, y);
                for (int s = 0; s < 24; s += 8)
                    d += Math.abs(((p >> s) & 0xff) - ((q >> s) & 0xff));
            }
        return (double) d / (a.getWidth() * a.getHeight() * 3);
    }

    // the pixels of text drawn with a font (not white)
    static int text(Font f) {
        BufferedImage t = new BufferedImage(240, 60, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = t.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, 240, 60);
        g.setColor(Color.BLACK);
        g.setFont(f);
        g.drawString("azsupport", 5, 45);
        g.dispose();
        int n = 0;
        for (int y = 0; y < 60; y++)
            for (int x = 0; x < 240; x++)
                if ((t.getRGB(x, y) & 0xffffff) != 0xffffff) n++;
        return n;
    }

    public static void main(String[] a) throws Exception {
        File dir = new File(a[0]);
        String fontFile = a[1];
        check("headless", () -> String.valueOf(GraphicsEnvironment.isHeadless()));
        if (a.length > 2 && a[2].equals("font")) {
            font(fontFile);
            maps();
            return;
        }
        check("jpeg", () -> {
            Iterator<ImageWriter> it = ImageIO.getImageWritersByFormatName("jpeg");
            String w = it.hasNext() ? it.next().getClass().getName() : "none";
            File f = new File(dir, "t.jpg");
            BufferedImage img = picture();
            if (!ImageIO.write(img, "jpeg", f)) return "ERROR no JPEG writer";
            BufferedImage r = ImageIO.read(f);
            return String.format(Locale.ROOT, "%dx%d diff %.2f bytes %d writer %s", r.getWidth(), r.getHeight(),
                diff(img, r), f.length(), w);
        });
        check("png", () -> {
            File f = new File(dir, "t.png");
            BufferedImage img = picture();
            if (!ImageIO.write(img, "png", f)) return "ERROR no PNG writer";
            BufferedImage r = ImageIO.read(f);
            return String.format(Locale.ROOT, "%dx%d diff %.2f bytes %d", r.getWidth(), r.getHeight(), diff(img, r),
                f.length());
        });
        check("icc", () -> {
            ICC_ColorSpace srgb = (ICC_ColorSpace) ColorSpace.getInstance(ColorSpace.CS_sRGB);
            float[] xyz = srgb.toCIEXYZ(new float[] { 1f, 0f, 0f });
            BufferedImage g = new ColorConvertOp(ColorSpace.getInstance(ColorSpace.CS_GRAY), null)
                .filter(picture(), null);
            return String.format(Locale.ROOT, "xyz %.4f %.4f %.4f grey %d", xyz[0], xyz[1], xyz[2],
                g.getRaster().getSample(32, 24, 0));
        });
        font(fontFile);
        check("sound", () -> {
            Mixer.Info[] m = AudioSystem.getMixerInfo();
            StringBuilder s = new StringBuilder(m.length + " mixers");
            for (Mixer.Info i : m) s.append("; ").append(i.getName());
            return s.toString();
        });
        if (a.length > 4) {
            check("tls", () -> tls(a[2], a[3].toCharArray(), a[4]));
            check("cacerts", () -> {
                TrustManagerFactory t = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
                t.init((KeyStore) null);
                for (TrustManager m : t.getTrustManagers())
                    if (m instanceof X509TrustManager)
                        return String.valueOf(((X509TrustManager) m).getAcceptedIssuers().length);
                return "ERROR no X509TrustManager";
            });
        }
        maps();
    }

    static void font(String fontFile) {
        check("font_families", () -> {
            String[] f = GraphicsEnvironment.getLocalGraphicsEnvironment().getAvailableFontFamilyNames();
            return f.length + (f.length > 0 ? " (" + f[0] + (f.length > 1 ? ", " + f[f.length - 1] : "") + ")" : "");
        });
        check("font_logical", () -> {
            Font f = new Font(Font.SANS_SERIF, Font.PLAIN, 32);
            return text(f) + " pixels, " + f.getFontName();
        });
        check("font_file", () -> {
            if (fontFile.equals("-")) return "none";
            Font f = Font.createFont(Font.TRUETYPE_FONT, new File(fontFile)).deriveFont(32f);
            return text(f) + " pixels, " + f.getFontName();
        });
    }

    static KeyStore store(String file, char[] pass) throws Exception {
        KeyStore ks = KeyStore.getInstance("PKCS12");
        try (FileInputStream in = new FileInputStream(file)) {
            ks.load(in, pass);
        }
        return ks;
    }

    // the server with the key, the client trusting its certificate alone
    static String tls(String keys, char[] pass, String trust) throws Exception {
        KeyManagerFactory k = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        k.init(store(keys, pass), pass);
        TrustManagerFactory t = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        t.init(store(trust, pass));
        SSLContext ctx = SSLContext.getInstance("TLSv1.3");
        ctx.init(k.getKeyManagers(), t.getTrustManagers(), null);
        SSLServerSocket ss = (SSLServerSocket) ctx.getServerSocketFactory()
            .createServerSocket(0, 1, InetAddress.getByName("127.0.0.1"));
        String[] err = new String[1];
        Thread th = new Thread(() -> {
            try (SSLSocket s = (SSLSocket) ss.accept()) {
                BufferedReader in = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8));
                PrintWriter o = new PrintWriter(s.getOutputStream(), true, StandardCharsets.UTF_8);
                o.println("pong " + in.readLine());
            } catch (Exception e) {
                err[0] = e.toString();
            }
        });
        th.start();
        String r;
        try (SSLSocket c = (SSLSocket) ctx.getSocketFactory().createSocket("127.0.0.1", ss.getLocalPort())) {
            SSLParameters p = c.getSSLParameters();
            p.setEndpointIdentificationAlgorithm("HTTPS");
            c.setSSLParameters(p);
            c.startHandshake();
            PrintWriter o = new PrintWriter(c.getOutputStream(), true, StandardCharsets.UTF_8);
            BufferedReader in = new BufferedReader(new InputStreamReader(c.getInputStream(), StandardCharsets.UTF_8));
            o.println("ping");
            r = c.getSession().getProtocol() + " " + c.getSession().getCipherSuite() + " " + in.readLine();
        }
        th.join(10000);
        ss.close();
        return err[0] == null ? r : "ERROR the server: " + err[0];
    }

    // the libraries the process mapped
    static void maps() {
        try {
            Process p = new ProcessBuilder("procstat", "-v", Long.toString(ProcessHandle.current().pid()))
                .redirectErrorStream(true).start();
            TreeSet<String> s = new TreeSet<>();
            try (BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                for (String l; (l = r.readLine()) != null; ) {
                    String[] w = l.trim().split("\\s+");
                    String f = w[w.length - 1];
                    if (f.startsWith("/") && f.contains(".so")) s.add(f);
                }
            }
            p.waitFor();
            for (String f : s) System.out.println("map=" + f);
        } catch (Exception e) {
            System.out.println("map=ERROR " + e);
        }
    }
}
EOF
cat > "$T/src/AzJnaTest.java" <<'EOF'
import com.sun.jna.Library;
import com.sun.jna.Native;
import java.io.BufferedReader;
import java.io.InputStreamReader;

// java -Djna.nosys=true AzJnaTest: getpid of libc through JNA and of the JVM, then
// "map=<library>" for each library the process mapped
public class AzJnaTest {
    public interface CLib extends Library {
        int getpid();
    }

    public static void main(String[] a) throws Exception {
        CLib c = Native.load("c", CLib.class);
        System.out.println("jna_pid=" + c.getpid());
        System.out.println("java_pid=" + ProcessHandle.current().pid());
        System.out.println("jna_version=" + Native.VERSION + " " + Native.VERSION_NATIVE);
        Process p = new ProcessBuilder("procstat", "-v", Long.toString(ProcessHandle.current().pid()))
            .redirectErrorStream(true).start();
        try (BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
            for (String l; (l = r.readLine()) != null; ) {
                String[] w = l.trim().split("\\s+");
                String f = w[w.length - 1];
                if (f.startsWith("/") && f.contains(".so")) System.out.println("map=" + f);
            }
        }
        p.waitFor();
    }
}
EOF
if "$J/bin/javac" -d "$T/classes" -cp "$jna" "$T/src/AzJavaTest.java" "$T/src/AzJnaTest.java" > "$res/javac.out" 2>&1; then
    pass "javac: the programs of the test"
else
    fail "javac: $(head -n 3 "$res/javac.out" | tr '\n' ' ')"
    done_
fi

# a font file for the text, when there is one (the official dejavu of
# imagemagick-test.sh --samples on the VM of the build)
ff="$(ls "$P/share/fonts/dejavu/DejaVuSans.ttf" 2>/dev/null || find "$P/share/fonts" -name '*.ttf' 2>/dev/null | head -n 1)"
# the key of the TLS test
"$J/bin/keytool" -genkeypair -alias az -keyalg EC -groupname secp256r1 -dname CN=localhost -validity 2 \
    -ext SAN=ip:127.0.0.1 -storetype PKCS12 -keystore "$T/tls.p12" -storepass azsupport -keypass azsupport \
    > "$res/keytool.out" 2>&1 &&
"$J/bin/keytool" -exportcert -alias az -keystore "$T/tls.p12" -storepass azsupport -file "$T/az.crt" \
    >> "$res/keytool.out" 2>&1 &&
"$J/bin/keytool" -importcert -noprompt -alias az -file "$T/az.crt" -storetype PKCS12 -keystore "$T/trust.p12" \
    -storepass azsupport >> "$res/keytool.out" 2>&1 || fail "keytool: $(tail -n 1 "$res/keytool.out")"

o="$res/java.out"
(cd "$T" && "$J/bin/java" -cp "$T/classes" AzJavaTest "$T" "${ff:--}" "$T/tls.p12" azsupport "$T/trust.p12") > "$o" 2> "$res/java.err"
r=$?
[ "$r" = 0 ] || fail "java AzJavaTest: exit $r, $(tail -n 2 "$res/java.err" | tr '\n' ' ')"
# with a DISPLAY: headless all the same (libawt_headless, no libawt_xawt)
(cd "$T" && DISPLAY=:0 "$J/bin/java" -cp "$T/classes" AzJavaTest "$T" - font) > "$res/java-display.out" 2>&1

# headless
h="$(val "$o" headless)"; hd="$(val "$res/java-display.out" headless)"
if [ "$h" = true ] && [ "$hd" = true ]; then pass "headless: isHeadless() true, with DISPLAY=:0 too"
else fail "headless: isHeadless() ${h:-not told}, with DISPLAY=:0 ${hd:-not told}"; fi
for f in libjsound.so libawt_xawt.so libsplashscreen.so; do
    [ ! -e "$J/lib/$f" ] || fail "$J/lib/$f is there"
done
[ -f "$J/lib/libawt_headless.so" ] && pass "lib/libawt_headless.so; no libjsound, libawt_xawt, libsplashscreen" ||
    fail "no $J/lib/libawt_headless.so"

# imageio: JPEG near (lossy), PNG the same
j="$(val "$o" jpeg)"
case "$j" in
    "64x48 diff "*" writer com.sun.imageio.plugins.jpeg.JPEGImageWriter")
        d="$(printf '%s\n' "$j" | awk '{ print $3 }')"
        if awk -v d="$d" 'BEGIN { exit !(d < 8) }'; then pass "ImageIO JPEG: $j"; else fail "ImageIO JPEG: too far: $j"; fi ;;
    *) fail "ImageIO JPEG: ${j:-not told}" ;;
esac
p="$(val "$o" png)"
case "$p" in "64x48 diff 0.00 "*) pass "ImageIO PNG: $p" ;; *) fail "ImageIO PNG: ${p:-not told}" ;; esac
# icc: sRGB red in XYZ of D50 (0.4361 0.2225 0.0139), a grey of the picture
c="$(val "$o" icc)"
if printf '%s\n' "$c" | awk '$1 == "xyz" && $2 > 0.42 && $2 < 0.45 && $3 > 0.21 && $3 < 0.24 && $4 > 0.005 && $4 < 0.03 && $5 == "grey" && $6 > 0 { f = 1 } END { exit !f }'; then
    pass "ICC (Little CMS): $c"
else
    fail "ICC (Little CMS): ${c:-not told}"
fi
# font: recorded; the file of a font through FreeType must draw when there is one
note "fonts: the families: $(val "$o" font_families)"
note "fonts: a logical font (SansSerif): $(val "$o" font_logical)"
fl="$(val "$o" font_file)"
case "$fl" in
    none) note "fonts: no TrueType font in $P/share/fonts" ;;
    [1-9]*" pixels"*) pass "text with the font file $ff (FreeType of az): $fl" ;;
    *) fail "text with the font file $ff: $fl" ;;
esac
# the libfontconfig.so.1 dlopen(3) of OpenJDK finds by the ldconfig hints (it
# closes it again once it has read the fonts: procstat at the end no longer sees it)
fc="$(ldconfig -r 2>/dev/null | sed -n 's/^.*=> \(.*\/libfontconfig\.so\.1\)$/\1/p' | head -n 1)"
[ -n "$fc" ] && fc="$fc ($(pkg which -q "$fc" 2>/dev/null || echo 'of no package'))"
note "fonts: the libfontconfig.so.1 that dlopen finds: ${fc:-none}"
(cd "$T" && USE_J2D_FONTCONFIG=no "$J/bin/java" -cp "$T/classes" AzJavaTest "$T" "${ff:--}" font) > "$res/java-nofc.out" 2>&1
note "without fontconfig (USE_J2D_FONTCONFIG=no, as with our packages only): the families: $(val "$res/java-nofc.out" font_families)"
note "without fontconfig: a logical font: $(val "$res/java-nofc.out" font_logical)"
note "without fontconfig: the font file: $(val "$res/java-nofc.out" font_file)"
font_sum="dlopen finds ${fc:-no libfontconfig.so.1}; families $(val "$o" font_families | cut -c1-80); SansSerif $(val "$o" font_logical | cut -c1-80); the file $(val "$o" font_file | cut -c1-60)"
nofc_sum="families $(val "$res/java-nofc.out" font_families | sed 's/ at [^;]*;/;/' | cut -c1-200); the file $(val "$res/java-nofc.out" font_file | sed 's/ at [^;]*;/;/' | cut -c1-200)"
# sound
s="$(val "$o" sound)"
case "$s" in [0-9]*" mixers"*) pass "AudioSystem.getMixerInfo(): $s" ;; *) fail "AudioSystem.getMixerInfo(): ${s:-not told}" ;; esac
# tls
t="$(val "$o" tls)"
case "$t" in "TLSv1.3 TLS_"*" pong ping") pass "TLS on 127.0.0.1: $t" ;; *) fail "TLS on 127.0.0.1: ${t:-not told}" ;; esac
n="$(val "$o" cacerts)"
case "$n" in [1-9][0-9]*) pass "the CA store of the JDK: $n certificates" ;; *) fail "the CA store of the JDK: ${n:-not told}" ;; esac

# libs: the libraries of az for JPEG, ICC and FreeType, nothing of a desktop
m="$(sed -n 's/^map=//p' "$o" | LC_ALL=C sort -u)"
printf '%s\n' "$m" > "$res/java-maps.txt"
for l in libjpeg libfreetype liblcms2; do
    w="$(printf '%s\n' "$m" | grep "/$l\.so" | tr '\n' ' ')"
    case "$w" in
        "/usr/local/az/lib/$l.so."*) [ "$(printf '%s\n' "$w" | wc -w | tr -d ' ')" = 1 ] &&
            pass "the process maps $w" || fail "more than one $l: $w" ;;
        *) fail "$l: ${w:-not mapped}, not that of /usr/local/az/lib" ;;
    esac
done
b="$(printf '%s\n' "$m" | grep -E '/lib(X[A-Za-z0-9_-]*|xcb[A-Za-z0-9_-]*|asound|gif|png[0-9]*|harfbuzz[A-Za-z0-9_-]*)\.so' | tr '\n' ' ')"
if [ -z "$b" ]; then pass "the process maps nothing of X11, ALSA, giflib, libpng, HarfBuzz"; else fail "the process maps $b"; fi

# jna
o="$res/jna.out"
# jna.nosys as Elasticsearch: libjnidispatch.so out of jna.jar into jna.tmpdir (kept)
(cd "$T" && "$J/bin/java" -Djna.nosys=true -Djna.tmpdir="$T/jna" -Djnidispatch.preserve=true \
    -cp "$T/classes:$jna" AzJnaTest) > "$o" 2> "$res/jna.err"
r=$?
jp="$(val "$o" jna_pid)"; vp="$(val "$o" java_pid)"
if [ "$r" = 0 ] && [ -n "$jp" ] && [ "$jp" = "$vp" ]; then
    pass "JNA $(val "$o" jna_version): getpid() of libc $jp = ProcessHandle.current().pid()"
else
    fail "JNA: exit $r, getpid() ${jp:-not told}, the JVM ${vp:-not told}: $(tail -n 2 "$res/jna.err" | tr '\n' ' ')"
fi
m="$(sed -n 's/^map=//p' "$o" | LC_ALL=C sort -u)"
printf '%s\n' "$m" > "$res/jna-maps.txt"
jd="$(printf '%s\n' "$m" | grep "^$T/jna/" | head -n 1)"
fi_="$(printf '%s\n' "$m" | grep '/libffi\.so' | tr '\n' ' ')"
case "$fi_" in
    "/usr/local/az/lib/libffi.so."*) pass "JNA: ${jd:-libjnidispatch} with $fi_" ;;
    *) fail "JNA: the libffi of the process: ${fi_:-none} (libjnidispatch: ${jd:-not mapped})" ;;
esac
if [ -n "$jd" ]; then
    b="$(readelf -d "$jd" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p' | grep -E '^lib(X|xcb|jawt)' | tr '\n' ' ')"
    [ -z "$b" ] && pass "JNA: libjnidispatch.so links nothing of X11" || fail "JNA: libjnidispatch.so links $b"
fi
# jna with the library of the package as Elasticsearch can load it (aZ, 11.11.2026):
# lib/jna/libjnidispatch.so by jna.boot.library.path, nothing extracted
o="$res/jna-boot.out"
lj="$P/lib/jna/libjnidispatch.so"
rm -rf "$T/jna-boot"; mkdir -p "$T/jna-boot"
(cd "$T" && "$J/bin/java" -Djna.boot.library.path="$P/lib/jna" -Djna.nosys=false -Djna.debug_load=true \
    -Djna.debug_load.jna=true -Djna.tmpdir="$T/jna-boot" -cp "$T/classes:$jna" AzJnaTest) > "$o" 2> "$res/jna-boot.err"
r=$?
jp="$(val "$o" jna_pid)"; vp="$(val "$o" java_pid)"
x="$(ls "$T/jna-boot" 2>/dev/null | tr '\n' ' ')"
if [ "$r" = 0 ] && [ -n "$jp" ] && [ "$jp" = "$vp" ] && grep -q "Found jnidispatch at $lj\$" "$res/jna-boot.err" &&
    sed -n 's/^map=//p' "$o" | grep -qx "$lj" && ! grep -q -E 'Extracting library|Looking in classpath' "$res/jna-boot.err" &&
    [ -z "$x" ]; then
    pass "JNA with -Djna.boot.library.path=$P/lib/jna -Djna.nosys=false: $lj loaded (getpid() $jp), nothing extracted"
else
    fail "JNA with -Djna.boot.library.path=$P/lib/jna: exit $r, getpid() ${jp:-not told} (the JVM ${vp:-not told}), $(grep -E 'Found jnidispatch|Extracting' "$res/jna-boot.err" | head -n 2 | tr '\n' ' ')${x:+, in jna.tmpdir: $x}"
fi
# the file of the package is the library of jna.jar (extracted by the run above, kept)
if [ -n "$jd" ]; then
    if cmp -s "$lj" "$jd"; then pass "$lj is the libjnidispatch.so of jna.jar"
    else fail "$lj is not the libjnidispatch.so of jna.jar ($jd)"; fi
fi

# deps
for p in openjdk17 jna; do
    pkg info -d "$p" > "$res/deps-$p.txt" 2>&1
    d="$(pkg query '%dn' "$p" | LC_ALL=C sort -u | tr '\n' ' ')"
    if [ "$d" = "az " ]; then pass "pkg info -d $p: az only"; else fail "pkg info -d $p: ${d:-nothing}"; fi
done
if pkg info -e elasticsearch6; then
    d="$(pkg query '%dn' elasticsearch6 | LC_ALL=C sort -u | tr '\n' ' ')"
    if [ "$d" = "bash jna openjdk17 " ]; then pass "pkg info -d elasticsearch6: bash, jna, openjdk17"
    else fail "pkg info -d elasticsearch6: ${d:-nothing}, not bash, jna, openjdk17"; fi
    # every package elasticsearch6 needs, also through the others
    have="elasticsearch6"; new="elasticsearch6"
    while [ -n "$new" ]; do
        nx=""
        for p in $new; do
            for d in $(pkg query '%dn' "$p"); do
                case " $have " in *" $d "*) ;; *) have="$have $d"; nx="$nx $d" ;; esac
            done
        done
        new="$nx"
    done
    # shellcheck disable=SC2086
    all="$(printf '%s\n' $have | grep -vx elasticsearch6 | LC_ALL=C sort | tr '\n' ' ')"
    # shellcheck disable=SC2086
    desk="$(printf '%s\n' $have | grep -E '^(lib(X|xcb|ICE|SM|fontenc|drm|GL|EGL).*|xorg.*|.*-fonts?-.*|fontconfig|freetype2|alsa-lib|alsa-plugins|harfbuzz.*|glib|python3.*|giflib|png|jpeg-turbo|lcms2|tiff|javavmwrapper|dejavu|mkfontscale|cups|avahi.*|dbus|gtk.*|cairo|pango)$' | tr '\n' ' ')"
    if [ -z "$desk" ]; then pass "elasticsearch6 needs, in all: $all(nothing of a desktop)"; else fail "elasticsearch6 needs packages of a desktop: $desk(all: $all)"; fi
else
    note "elasticsearch6 is not installed: its packages not counted"
fi

done_
