#!/bin/sh
# java-test.sh - test the JDKs of the repository az, JNA and Ant, installed from it
# (aZ, 11.11.2026: our openjdk17, headless, and jna without X11, for Elasticsearch
# 6; 12.11.2026: our openjdk21, made as openjdk17, for OpenSearch 2.19 and 3.x, and
# JNA and Ant built and run on it): each JDK installed of openjdk17 and openjdk21
# (both side by side when both are), with Java programs compiled here with its javac
# and run with its java; each line of the checks of a JDK begins with its name:
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
#   ldd       ldd(1) of every ELF file of the JDK (lib/server/libjvm.so, the
#             libraries of lib/, the programs of bin/; the lib/server and lib of the
#             JDK in LD_LIBRARY_PATH, as its launcher loads libjvm.so by its path):
#             every library they need found, each in the JDK, the base system (/lib,
#             /usr/lib) or /usr/local/az/lib, none of /usr/local/lib; libjpeg,
#             libfreetype and liblcms2 those of /usr/local/az/lib; nothing of X11,
#             ALSA, giflib, libpng, HarfBuzz and fontconfig
#   jna       getpid of libc through JNA (jna.jar of devel/jna, as Elasticsearch
#             loads it: jna.nosys) is the pid of ProcessHandle; its libjnidispatch.so
#             with the libffi of az; then with the libjnidispatch.so of the package
#             (-Djna.boot.library.path=/usr/local/lib/jna -Djna.nosys=false, aZ
#             11.11.2026: Elasticsearch writes nothing at its start): that file
#             loaded (-Djna.debug_load.jna=true logs which jnidispatch, procstat),
#             nothing extracted from the jar (-Djna.debug_load=true logs an
#             extraction; jna.tmpdir stays empty)
#   jdk21     openjdk21 alone: what OpenSearch 2.19 and 3.x take of JDK 21 (Lucene
#             9.12 and 10): a dot product through the Vector API of the module
#             jdk.incubator.vector (--add-modules, as their jvm.options), a file
#             mapped as a MemorySegment (MMapDirectory) and getpid of libc through
#             the Linker (FFM, a preview API in 21: --enable-preview)
#   side by side  both JDKs installed: no file of the one is a file of the other,
#             each java -version its own (the checks of each above, with the other
#             installed)
#   jna.jar   its classes for Java 8 (class file version 52: JNA builds with javac
#             release 8, on openjdk21), so that it runs on 17 and 21 alike
#   ant       bin/ant of apache-ant, when it is installed, on the java of the JDK it
#             needs (openjdk21; no JAVA_HOME, no JAVACMD): a build.xml that compiles
#             a class for Java 8 into a jar, which each JDK runs
#   deps      pkg info -d of each JDK and of jna: az only; of apache-ant: openjdk21
#             only; elasticsearch6, when it is installed: bash, jna and openjdk17,
#             and among all the packages it needs none of a desktop
#
# Usage (FreeBSD, as root, the packages installed): sh tools/java-test.sh
# Results: java-results/tests.txt (one line per check, the summary at the end), the
# output of the programs of each JDK in java-results/<jdk>/; the same on the
# standard output, its last lines what the fonts gave and the summary; exit status
# 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/java-results}"
T0="${JAVA_TEST_WORK:-/var/tmp/java-test}"
P=/usr/local
JDKS_ALL="openjdk17 openjdk21"
jna="$P/share/java/classes/jna.jar"
mkdir -p "$res"
rm -rf "$T0"; mkdir -p "$T0/src"
S="$T0/src"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
# JN: the JDK being tested, the beginning of its lines
JN=""
pass() { echo "ok    ${JN:+$JN: }$*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  ${JN:+$JN: }$*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  ${JN:+$JN: }$*" >> "$out"; }
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
    echo "java-test: $ok ok, $bad failed (${jdks:-no JDK})"
    [ "$bad" = 0 ]; exit $?
}
font_sum=""; nofc_sum=""
unset DISPLAY

jdks=""
for p in $JDKS_ALL; do
    pkg info -e "$p" && jdks="$jdks${jdks:+ }$p"
done
[ -n "$jdks" ] || fail "no JDK of ours is installed (none of $JDKS_ALL)"
pkg info -e jna || fail "jna is not installed"
[ "$bad" = 0 ] || done_
note "the JDKs installed: $jdks"

# the programs
cat > "$S/AzJavaTest.java" <<'EOF'
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
cat > "$S/AzJnaTest.java" <<'EOF'
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
cat > "$S/AzJdk21Test.java" <<'EOF'
import java.lang.foreign.Arena;
import java.lang.foreign.FunctionDescriptor;
import java.lang.foreign.Linker;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;
import java.lang.invoke.MethodHandle;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import jdk.incubator.vector.FloatVector;
import jdk.incubator.vector.VectorOperators;
import jdk.incubator.vector.VectorSpecies;

// java --enable-preview --enable-native-access=ALL-UNNAMED --add-modules
// jdk.incubator.vector AzJdk21Test <work dir>: what OpenSearch takes of JDK 21 (Lucene
// 9.12 of 2.19, Lucene 10 of 3.x): the Vector API of the incubator module (a dot
// product of floats, as VectorUtil of Lucene), a file mapped as a MemorySegment
// (MMapDirectory), a downcall through the Linker (getpid of libc; Lucene 10 calls
// posix_madvise so); a line "<key>=<result>" each, the result ending in " ok"
public class AzJdk21Test {
    public static void main(String[] a) throws Throwable {
        VectorSpecies<Float> sp = FloatVector.SPECIES_PREFERRED;
        float[] x = new float[1000], y = new float[1000];
        float want = 0;
        for (int i = 0; i < x.length; i++) {
            x[i] = i % 7;
            y[i] = i % 5;
            want += x[i] * y[i];
        }
        FloatVector acc = FloatVector.zero(sp);
        int i = 0;
        for (; i < sp.loopBound(x.length); i += sp.length())
            acc = FloatVector.fromArray(sp, x, i).fma(FloatVector.fromArray(sp, y, i), acc);
        float got = acc.reduceLanes(VectorOperators.ADD);
        for (; i < x.length; i++) got += x[i] * y[i];
        System.out.println("vector=" + sp.vectorBitSize() + " bits, a dot product " + got
            + (got == want ? " ok" : ", not " + want));

        Path f = Path.of(a[0], "segment.bin");
        byte[] b = new byte[1 << 20];
        long sb = 0;
        for (int k = 0; k < b.length; k++) {
            b[k] = (byte) (k * 31);
            sb += b[k];
        }
        Files.write(f, b);
        try (FileChannel ch = FileChannel.open(f, StandardOpenOption.READ); Arena ar = Arena.ofShared()) {
            MemorySegment s = ch.map(FileChannel.MapMode.READ_ONLY, 0, ch.size(), ar);
            long sum = 0;
            for (long k = 0; k < s.byteSize(); k++) sum += s.get(ValueLayout.JAVA_BYTE, k);
            System.out.println("segment=" + s.byteSize() + " bytes mapped, their sum " + sum
                + (sum == sb ? " ok" : ", not " + sb));
        }

        Linker l = Linker.nativeLinker();
        MethodHandle getpid = l.downcallHandle(l.defaultLookup().find("getpid").orElseThrow(),
            FunctionDescriptor.of(ValueLayout.JAVA_INT));
        int pid = (int) getpid.invokeExact();
        long jp = ProcessHandle.current().pid();
        System.out.println("linker=getpid " + pid + (pid == jp ? " ok" : ", not " + jp));
    }
}
EOF

# a font file for the text, when there is one (the official dejavu of
# imagemagick-test.sh --samples on the VM of the build)
ff="$(ls "$P/share/fonts/dejavu/DejaVuSans.ttf" 2>/dev/null || find "$P/share/fonts" -name '*.ttf' 2>/dev/null | head -n 1)"
# the libfontconfig.so.1 dlopen(3) of OpenJDK finds by the ldconfig hints (it
# closes it again once it has read the fonts: procstat at the end no longer sees it)
fc="$(ldconfig -r 2>/dev/null | sed -n 's/^.*=> \(.*\/libfontconfig\.so\.1\)$/\1/p' | head -n 1)"
[ -n "$fc" ] && fc="$fc ($(pkg which -q "$fc" 2>/dev/null || echo 'of no package'))"

# the libraries of a desktop, in the paths of the libraries a process maps or ldd
# finds (those the ports check in the NEEDED of their ELF files)
desktop='/lib(X[A-Za-z0-9_-]*|xcb[A-Za-z0-9_-]*|asound|gif|png[0-9]*|harfbuzz[A-Za-z0-9_-]*|fontconfig)\.so'

# test_jdk: the checks of the JDK $JN (/usr/local/$JN), its programs in $T0/$JN,
# its results in $res/$JN
test_jdk() {
J="$P/$JN"
T="$T0/$JN"
r="$res/$JN"
rm -rf "$T" "$r"; mkdir -p "$T/classes" "$T/jna" "$r"

# version
v="$("$J/bin/java" -version 2>&1)"
printf '%s\n' "$v" > "$r/java-version.txt"
pv="$(pkgv "$JN")"
case "$v" in
    *"version \"${pv%%+*}\""*) pass "java -version: $(printf '%s\n' "$v" | sed -n 2p) (the package is $pv)" ;;
    *) fail "java -version: $(printf '%s\n' "$v" | tr '\n' ' '), the package is $pv" ;;
esac
if pkg info -l "$JN" | grep -q "^[[:space:]]*$P/bin/java\$"; then
    fail "$JN installs $P/bin/java"
else
    pass "no $P/bin/java of $JN (no javavmwrapper): Java by JAVA_HOME $J"
fi

if "$J/bin/javac" -d "$T/classes" -cp "$jna" "$S/AzJavaTest.java" "$S/AzJnaTest.java" > "$r/javac.out" 2>&1; then
    pass "javac: the programs of the test"
else
    fail "javac: $(head -n 3 "$r/javac.out" | tr '\n' ' ')"
    return
fi

# the key of the TLS test
"$J/bin/keytool" -genkeypair -alias az -keyalg EC -groupname secp256r1 -dname CN=localhost -validity 2 \
    -ext SAN=ip:127.0.0.1 -storetype PKCS12 -keystore "$T/tls.p12" -storepass azsupport -keypass azsupport \
    > "$r/keytool.out" 2>&1 &&
"$J/bin/keytool" -exportcert -alias az -keystore "$T/tls.p12" -storepass azsupport -file "$T/az.crt" \
    >> "$r/keytool.out" 2>&1 &&
"$J/bin/keytool" -importcert -noprompt -alias az -file "$T/az.crt" -storetype PKCS12 -keystore "$T/trust.p12" \
    -storepass azsupport >> "$r/keytool.out" 2>&1 || fail "keytool: $(tail -n 1 "$r/keytool.out")"

o="$r/java.out"
(cd "$T" && "$J/bin/java" -cp "$T/classes" AzJavaTest "$T" "${ff:--}" "$T/tls.p12" azsupport "$T/trust.p12") > "$o" 2> "$r/java.err"
rc=$?
[ "$rc" = 0 ] || fail "java AzJavaTest: exit $rc, $(tail -n 2 "$r/java.err" | tr '\n' ' ')"
# with a DISPLAY: headless all the same (libawt_headless, no libawt_xawt)
(cd "$T" && DISPLAY=:0 "$J/bin/java" -cp "$T/classes" AzJavaTest "$T" - font) > "$r/java-display.out" 2>&1

# headless
h="$(val "$o" headless)"; hd="$(val "$r/java-display.out" headless)"
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
note "fonts: the libfontconfig.so.1 that dlopen finds: ${fc:-none}"
(cd "$T" && USE_J2D_FONTCONFIG=no "$J/bin/java" -cp "$T/classes" AzJavaTest "$T" "${ff:--}" font) > "$r/java-nofc.out" 2>&1
note "without fontconfig (USE_J2D_FONTCONFIG=no, as with our packages only): the families: $(val "$r/java-nofc.out" font_families)"
note "without fontconfig: a logical font: $(val "$r/java-nofc.out" font_logical)"
note "without fontconfig: the font file: $(val "$r/java-nofc.out" font_file)"
font_sum="$font_sum${font_sum:+ | }$JN: dlopen finds ${fc:-no libfontconfig.so.1}; families $(val "$o" font_families | cut -c1-80); SansSerif $(val "$o" font_logical | cut -c1-80); the file $(val "$o" font_file | cut -c1-60)"
nofc_sum="$nofc_sum${nofc_sum:+ | }$JN: families $(val "$r/java-nofc.out" font_families | sed 's/ at [^;]*;/;/' | cut -c1-200); the file $(val "$r/java-nofc.out" font_file | sed 's/ at [^;]*;/;/' | cut -c1-200)"
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
printf '%s\n' "$m" > "$r/java-maps.txt"
for lb in libjpeg libfreetype liblcms2; do
    w="$(printf '%s\n' "$m" | grep "/$lb\.so" | tr '\n' ' ')"
    case "$w" in
        "/usr/local/az/lib/$lb.so."*) [ "$(printf '%s\n' "$w" | wc -w | tr -d ' ')" = 1 ] &&
            pass "the process maps $w" || fail "more than one $lb: $w" ;;
        *) fail "$lb: ${w:-not mapped}, not that of /usr/local/az/lib" ;;
    esac
done
b="$(printf '%s\n' "$m" | grep -E "$desktop" | tr '\n' ' ')"
if [ -z "$b" ]; then pass "the process maps nothing of X11, ALSA, giflib, libpng, HarfBuzz"; else fail "the process maps $b"; fi

# ldd of every ELF file of the JDK, into ldd.txt: a line "<file>:", then a line
# "<library> => <path> (<address>)" for each library it needs ("not found" for the
# path of one not found); that of lib/server/libjvm.so also in ldd-libjvm.txt
l="$r/ldd.txt"
: > "$l"
nf=0
for f in $(find "$J" -type f | LC_ALL=C sort); do
    file -b "$f" | grep -q '^ELF ' || continue
    nf=$((nf + 1))
    LD_LIBRARY_PATH="$J/lib/server:$J/lib" ldd "$f" >> "$l" 2>&1
done
awk -v f="$J/lib/server/libjvm.so:" '$0 == f { p = 1; print; next } p && /^[^ \t]/ { p = 0 } p' "$l" > "$r/ldd-libjvm.txt"
# the libraries found, "<library> <path>"; those not found
found="$(awk '$2 == "=>" && $3 != "not" { print $1, $3 }' "$l" | LC_ALL=C sort -u)"
nfound="$(awk '$2 == "=>" && $3 == "not" { print $1 }' "$l" | LC_ALL=C sort -u | tr '\n' ' ')"
if [ "$nf" -gt 50 ] && [ -s "$r/ldd-libjvm.txt" ] && [ -z "$nfound" ]; then
    pass "ldd of the $nf ELF files: every library found; lib/server/libjvm.so needs $(awk '$2 == "=>" { print $3 }' "$r/ldd-libjvm.txt" | tr '\n' ' ')"
else
    fail "ldd of the $nf ELF files (more than 50, libjvm.so among them): not found: ${nfound:-none}; libjvm.so: $(tr '\n' ' ' < "$r/ldd-libjvm.txt" | cut -c1-200)"
fi
w="$(printf '%s\n' "$found" | awk -v j="$J/" 'NF == 2 && index($2, j) != 1 && $2 !~ /^\/(usr\/)?lib\// && $2 !~ /^\/usr\/local\/az\/lib\// { print $2 }' | LC_ALL=C sort -u | tr '\n' ' ')"
if [ -z "$w" ]; then
    pass "ldd: every library in the JDK, the base system or /usr/local/az/lib, those of az: $(printf '%s\n' "$found" | awk '$2 ~ /^\/usr\/local\/az\/lib\// { print $2 }' | LC_ALL=C sort -u | tr '\n' ' ')"
else
    fail "ldd: libraries of neither the JDK, the base system nor /usr/local/az/lib: $w"
fi
for e in libjpeg:libjavajpeg.so libfreetype:libfontmanager.so liblcms2:liblcms.so; do
    lb="${e%%:*}"; by="${e#*:}"
    # the paths of the library, and the one the JDK library that links it gets
    w="$(printf '%s\n' "$found" | awk -v l="$lb" 'index($1, l ".so.") == 1 { print $2 }' | LC_ALL=C sort -u | tr '\n' ' ')"
    u="$(awk -v f="$J/lib/$by:" -v l="$lb" '$0 == f { p = 1; next } p && /^[^ \t]/ { p = 0 } p && index($1, l ".so.") == 1 { print $3 }' "$l")"
    case "$w" in
        "/usr/local/az/lib/$lb.so."*) [ "$(printf '%s\n' "$w" | wc -w | tr -d ' ')" = 1 ] && [ -n "$u" ] &&
            pass "ldd: $lb is $w(lib/$by: $u)" || fail "ldd: $lb: $w(lib/$by: ${u:-does not need it})" ;;
        *) fail "ldd: $lb: ${w:-needed by none}, not that of /usr/local/az/lib" ;;
    esac
done
b="$(printf '%s\n' "$found" | awk '{ print $2 }' | grep -E "$desktop" | LC_ALL=C sort -u | tr '\n' ' ')"
if [ -z "$b" ]; then pass "ldd: nothing of X11, ALSA, giflib, libpng, HarfBuzz, fontconfig"; else fail "ldd: $b"; fi

# jna
o="$r/jna.out"
# jna.nosys as Elasticsearch: libjnidispatch.so out of jna.jar into jna.tmpdir (kept)
(cd "$T" && "$J/bin/java" -Djna.nosys=true -Djna.tmpdir="$T/jna" -Djnidispatch.preserve=true \
    -cp "$T/classes:$jna" AzJnaTest) > "$o" 2> "$r/jna.err"
rc=$?
jp="$(val "$o" jna_pid)"; vp="$(val "$o" java_pid)"
if [ "$rc" = 0 ] && [ -n "$jp" ] && [ "$jp" = "$vp" ]; then
    pass "JNA $(val "$o" jna_version): getpid() of libc $jp = ProcessHandle.current().pid()"
else
    fail "JNA: exit $rc, getpid() ${jp:-not told}, the JVM ${vp:-not told}: $(tail -n 2 "$r/jna.err" | tr '\n' ' ')"
fi
m="$(sed -n 's/^map=//p' "$o" | LC_ALL=C sort -u)"
printf '%s\n' "$m" > "$r/jna-maps.txt"
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
o="$r/jna-boot.out"
lj="$P/lib/jna/libjnidispatch.so"
rm -rf "$T/jna-boot"; mkdir -p "$T/jna-boot"
(cd "$T" && "$J/bin/java" -Djna.boot.library.path="$P/lib/jna" -Djna.nosys=false -Djna.debug_load=true \
    -Djna.debug_load.jna=true -Djna.tmpdir="$T/jna-boot" -cp "$T/classes:$jna" AzJnaTest) > "$o" 2> "$r/jna-boot.err"
rc=$?
jp="$(val "$o" jna_pid)"; vp="$(val "$o" java_pid)"
x="$(ls "$T/jna-boot" 2>/dev/null | tr '\n' ' ')"
if [ "$rc" = 0 ] && [ -n "$jp" ] && [ "$jp" = "$vp" ] && grep -q "Found jnidispatch at $lj\$" "$r/jna-boot.err" &&
    sed -n 's/^map=//p' "$o" | grep -qx "$lj" && ! grep -q -E 'Extracting library|Looking in classpath' "$r/jna-boot.err" &&
    [ -z "$x" ]; then
    pass "JNA with -Djna.boot.library.path=$P/lib/jna -Djna.nosys=false: $lj loaded (getpid() $jp), nothing extracted"
else
    fail "JNA with -Djna.boot.library.path=$P/lib/jna: exit $rc, getpid() ${jp:-not told} (the JVM ${vp:-not told}), $(grep -E 'Found jnidispatch|Extracting' "$r/jna-boot.err" | head -n 2 | tr '\n' ' ')${x:+, in jna.tmpdir: $x}"
fi
# the file of the package is the library of jna.jar (extracted by the run above, kept)
if [ -n "$jd" ]; then
    if cmp -s "$lj" "$jd"; then pass "$lj is the libjnidispatch.so of jna.jar"
    else fail "$lj is not the libjnidispatch.so of jna.jar ($jd)"; fi
fi

# JDK 21: what OpenSearch takes of it (aZ, 12.11.2026: 2.19, then 3.x): the Vector
# API of jdk.incubator.vector (--add-modules of its jvm.options; the JVM warns of the
# incubator module), a file mapped as a MemorySegment and a downcall through the
# Linker (FFM, a preview API in 21: --enable-preview)
[ "$JN" = openjdk21 ] || return 0
mkdir -p "$T/classes21"
if ! "$J/bin/javac" --release 21 --enable-preview --add-modules jdk.incubator.vector -d "$T/classes21" \
    "$S/AzJdk21Test.java" > "$r/javac21.out" 2>&1; then
    fail "javac --enable-preview --add-modules jdk.incubator.vector: $(grep -v -i 'warning\|^Note' "$r/javac21.out" | head -n 3 | tr '\n' ' ')"
    return 0
fi
o="$r/jdk21.out"
(cd "$T" && "$J/bin/java" --enable-preview --enable-native-access=ALL-UNNAMED --add-modules jdk.incubator.vector \
    -cp "$T/classes21" AzJdk21Test "$T") > "$o" 2> "$r/jdk21.err"
rc=$?
w="$(grep -m 1 'Using incubator modules' "$r/jdk21.err")"
for k in vector segment linker; do
    x="$(val "$o" "$k")"
    case "$x" in
        *" ok") pass "$k: $x${w:+ (the JVM: $w)}" ;;
        *) fail "$k: ${x:-not told} (exit $rc: $(grep -v 'Using incubator modules' "$r/jdk21.err" | tail -n 2 | tr '\n' ' '))" ;;
    esac
    w=""
done
}

for JN in $jdks; do
    test_jdk
done
JN=""
[ ! -e "$P/bin/java" ] || note "$P/bin/java is there, of $(pkg which -q "$P/bin/java" 2>/dev/null || echo 'no package') (not of a JDK of ours)"

# side by side: no file of the one JDK is one of the other (pkg would not have
# installed the two), each with its own java (the checks of each above, made with
# the other installed)
if [ "$jdks" = "openjdk17 openjdk21" ]; then
    for p in $jdks; do
        pkg info -l "$p" | sed -n 's/^[[:space:]]*\(\/.*\)/\1/p' | LC_ALL=C sort > "$res/files-$p.txt"
    done
    both="$(LC_ALL=C comm -12 "$res/files-openjdk17.txt" "$res/files-openjdk21.txt" | head -n 5 | tr '\n' ' ')"
    n17="$(wc -l < "$res/files-openjdk17.txt" | tr -d ' ')"; n21="$(wc -l < "$res/files-openjdk21.txt" | tr -d ' ')"
    if [ -z "$both" ] && [ "$n17" -gt 100 ] && [ "$n21" -gt 100 ]; then
        pass "openjdk17 ($n17 files) and openjdk21 ($n21 files) side by side: no file in common"
    else
        fail "openjdk17 ($n17 files) and openjdk21 ($n21 files) side by side: the files in common: ${both:-none}"
    fi
    v17="$(sed -n 1p "$res/openjdk17/java-version.txt")"; v21="$(sed -n 1p "$res/openjdk21/java-version.txt")"
    case "$v17 / $v21" in
        *'version "17.'*' / '*'version "21.'*) pass "each its own java: $P/openjdk17/bin/java $v17; $P/openjdk21/bin/java $v21" ;;
        *) fail "each its own java: $P/openjdk17/bin/java ${v17:-told nothing}; $P/openjdk21/bin/java ${v21:-told nothing}" ;;
    esac
else
    note "one JDK of ours installed ($jdks): the checks of the two side by side are not made"
fi

# jna.jar for Java 8 and later (javac.release 8 of JNA, built on 21): it runs on 17
# and 21 alike
cv="$(tar -xOf "$jna" com/sun/jna/Native.class 2>/dev/null | od -An -j 7 -N 1 -t u1 | tr -d ' ')"
if [ "$cv" = 52 ]; then pass "jna.jar: class file version 52 (Java 8), for every JDK of ours"
else fail "jna.jar: class file version ${cv:-none} (com/sun/jna/Native.class), not 52 (Java 8)"; fi

# ant: bin/ant of apache-ant runs the java of the JDK it needs (openjdk21; no
# JAVA_HOME, no JAVACMD), with a build.xml that compiles a class for Java 8 (javac
# release 8, as JNA builds) into a jar, which each JDK runs then
if pkg info -e apache-ant; then
    A="$T0/ant"
    rm -rf "$A"; mkdir -p "$A/src"
    cat > "$A/build.xml" <<'EOF'
<project name="azant" default="jar">
  <target name="jar">
    <echo message="ant_java_home=${java.home}"/>
    <mkdir dir="classes"/>
    <javac srcdir="src" destdir="classes" release="8" includeantruntime="false"/>
    <jar destfile="azant.jar" basedir="classes">
      <manifest>
        <attribute name="Main-Class" value="AzAnt"/>
      </manifest>
    </jar>
  </target>
</project>
EOF
    cat > "$A/src/AzAnt.java" <<'EOF'
public class AzAnt {
    public static void main(String[] a) {
        System.out.println("azant_java=" + System.getProperty("java.specification.version"));
    }
}
EOF
    aj="$(pkg query '%dn' apache-ant | grep -x 'openjdk[0-9]*' | head -n 1)"
    av="$(env -u JAVA_HOME -u JAVACMD "$P/bin/ant" -version 2>&1 | head -n 1)"
    (cd "$A" && env -u JAVA_HOME -u JAVACMD "$P/bin/ant" -noinput -buildfile build.xml jar) > "$res/ant.out" 2>&1
    rc=$?
    ah="$(sed -n 's/.*ant_java_home=//p' "$res/ant.out" | head -n 1)"
    cv="$(od -An -j 7 -N 1 -t u1 "$A/classes/AzAnt.class" 2>/dev/null | tr -d ' ')"
    if [ "$rc" = 0 ] && [ -n "$aj" ] && [ "$ah" = "$P/$aj" ] && [ "$cv" = 52 ] && [ -f "$A/azant.jar" ]; then
        pass "Ant: $av; bin/ant on $ah (the JDK of the package); a class for Java 8 (class file version 52) compiled into a jar"
    else
        fail "Ant: exit $rc, $av; java.home ${ah:-not told}, the JDK of the package ${aj:-none}; class file version ${cv:-none}: $(tail -n 3 "$res/ant.out" | tr '\n' ' ')"
    fi
    for p in $jdks; do
        o="$("$P/$p/bin/java" -jar "$A/azant.jar" 2>&1)"
        case "$o" in
            azant_java=*) pass "the jar of Ant on $p: $o" ;;
            *) fail "the jar of Ant on $p: $o" ;;
        esac
    done
else
    note "apache-ant is not installed: Ant not tried"
fi

# deps
for p in $jdks jna; do
    pkg info -d "$p" > "$res/deps-$p.txt" 2>&1
    d="$(pkg query '%dn' "$p" | LC_ALL=C sort -u | tr '\n' ' ')"
    if [ "$d" = "az " ]; then pass "pkg info -d $p: az only"; else fail "pkg info -d $p: ${d:-nothing}"; fi
done
if pkg info -e apache-ant; then
    pkg info -d apache-ant > "$res/deps-apache-ant.txt" 2>&1
    d="$(pkg query '%dn' apache-ant | LC_ALL=C sort -u | tr '\n' ' ')"
    if [ "$d" = "openjdk21 " ]; then pass "pkg info -d apache-ant: openjdk21 only"; else fail "pkg info -d apache-ant: ${d:-nothing}, not openjdk21"; fi
fi

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
