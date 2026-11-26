# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/lang.sh: the group lang of tools/prog-bench.sh (sourced by it): the
# interpreters of this tree (Python: the group python), each benchmark a script of its own,
# on the last CPU, its own time (without the start of the interpreter) or the time of the run.
#
# Perl 5.42.3 (lang/perl5.42: the official port, its distinfo): threads, MULTIPLICITY,
# 64-bit integers, the shared libperl, as the official package. Ruby 3.4.13 (lang/ruby34):
# shared libruby, pthread, GMP and YJIT (the Rust of the packages: YJIT is Rust, the same
# for the three), _setjmp; libyaml, libffi and gmp of the packages (ours: azsupport), the
# OpenSSL and zlib of the base system; each benchmark without YJIT and with it (--yjit).
# LuaJIT 2.1-20261107 of OpenResty (lang/luajit-openresty) with the patches of the port: the
# interpreter of LuaJIT is assembler (DynASM), the code it compiles its own; the C of it is
# its runtime (the GC, the string library, the parser, the compiler of traces). Tcl 8.4.20
# (lang/tcl84) with the patches of the port, threads, shared. calc 2.17.0.2 (math/calc):
# its own arbitrary precision. bash 5.3 (shells/bash: the official port, its tarball without
# the 20 patches of the port, which fix bugs), without its malloc, no NLS.
# The benchmarks: regular expressions over log lines, hashes, strings, sorting, function
# and method calls, pack (Perl), JSON (Ruby), bignum (Ruby, calc), the GC; see the scripts.

g_progs="perl ruby luajit tcl84 calc bash"

g_need() {
    # bash: the make of calc runs its scripts with it (SHELL)
    need gmp libyaml rust bash
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch perl-5.42.3.tar.xz c9387e1473a1866935cb047ece7c2e0a80767a3acdecb79d4a375f8a95970ddc \
        https://www.cpan.org/src/5.0/perl-5.42.3.tar.xz https://cpan.metacpan.org/src/5.0/perl-5.42.3.tar.xz
    fetch ruby-3.4.13.tar.xz 6474dff9c02ea685fc44877a4807a27366bf109b176dad182108bb8c96d09589 \
        https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.13.tar.xz
    fetch openresty-luajit2-v2.1-20261107_GH0.tar.gz c79b8f08ddcdcfa06961c416efa1455f9f2b7f4cba6b0fd814239f36e7557f74 \
        https://codeload.github.com/openresty/luajit2/tar.gz/v2.1-20261107
    fetch tcl8.4.20-src.tar.gz fcb317b65c69f1d6962057c5622a80980bc22ffadf25c1cc50b6d02ff6c2cf40 \
        https://downloads.sourceforge.net/project/tcl/Tcl/8.4.20/tcl8.4.20-src.tar.gz https://prdownloads.sourceforge.net/tcl/tcl8.4.20-src.tar.gz
    fetch lcn2-calc-v2.17.0.2_GH0.tar.gz 12471c2c23ae6b8a010be7472ef58e877a94022bd2e8c172cb60bede98b6417f \
        https://codeload.github.com/lcn2/calc/tar.gz/v2.17.0.2
    fetch bash-5.3.tar.gz 0d5cd86965f869a26cf64f4b71be7b96f90a3ba8b3d74e27e8e9d9d5550f31ba \
        https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz https://ftpmirror.gnu.org/gnu/bash/bash-5.3.tar.gz
    # Perl
    unpack perl-5.42.3.tar.xz "$W/src/perl-$_v"
    _b="$W/b-perl-$_v.log"
    # as lang/perl5.42: -Doptimize of the CFLAGS (with -fPIE -fPIC), no -Dldflags (its Configure
    # takes no LDFLAGS: -pie without -fPIC in its tests failed, "recompile with -fPIC")
    if (cd "$W/src/perl-$_v" && sh Configure -des -Dprefix="$W/perl-$_v" -Dcc="$CC" -Doptimize="$CFLAGS" \
        -Duseshrplib -Dusethreads -Dusemultiplicity -Duse64bitint -Uinstallusrbinperl \
        -Dman1dir=none -Dman3dir=none -Dsiteman1dir=none -Dsiteman3dir=none && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok perl "$_v" "$W/perl-$_v/bin/perl"
    else
        bno perl "$_v" "$_b"
    fi
    rm -rf "$W/src/perl-$_v"
    # Ruby
    unpack ruby-3.4.13.tar.xz "$W/src/ruby-$_v"
    _b="$W/b-ruby-$_v.log"
    if (cd "$W/src/ruby-$_v" && ./configure --prefix="$W/ruby-$_v" --enable-shared --enable-pthread --enable-yjit \
        --with-gmp --with-setjmp-type=_setjmp --disable-install-doc --with-opt-dir=/usr/local \
        LDFLAGS="-L/usr/local/lib -Wl,-rpath,$W/ruby-$_v/lib $LDFLAGS" && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1 &&
        "$W/ruby-$_v/bin/ruby" --yjit -e 'exit(RubyVM::YJIT.enabled? ? 0 : 1)' >> "$_b" 2>&1; then
        bok ruby "$_v" "$(ls "$W/ruby-$_v"/lib/libruby.so* | head -n 1)"
    else
        bno ruby "$_v" "$_b"
    fi
    rm -rf "$W/src/ruby-$_v"
    # LuaJIT
    unpack openresty-luajit2-v2.1-20261107_GH0.tar.gz "$W/src/luajit-$_v"
    _b="$W/b-luajit-$_v.log"
    : > "$_b"
    for p in "$top"/lang/luajit-openresty/files/patch-*; do
        (cd "$W/src/luajit-$_v" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    # the directories the stage of the framework has (patch-Makefile of the port makes no bin/)
    if (cd "$W/src/luajit-$_v" && gmake -j"$ncpu" PREFIX="$W/luajit-$_v" CC="$CC" Q= CCDEBUG= &&
        mkdir -p "$W/luajit-$_v/bin" "$W/luajit-$_v/lib" "$W/luajit-$_v/include" "$W/luajit-$_v/share/man/man1" \
            "$W/luajit-$_v/libdata/pkgconfig" && gmake install PREFIX="$W/luajit-$_v") >> "$_b" 2>&1 && _lj="$(ls "$W/luajit-$_v"/bin/luajit* 2> /dev/null | head -n 1)" &&
        [ -n "$_lj" ] && ln -sf "$_lj" "$W/luajit-$_v/bin/lj" && "$W/luajit-$_v/bin/lj" -e 'print(1)' >> "$_b" 2>&1; then
        bok luajit "$_v" "$_lj"
    else
        bno luajit "$_v" "$_b"
    fi
    # Tcl 8.4
    unpack tcl8.4.20-src.tar.gz "$W/src/tcl-$_v"
    _b="$W/b-tcl84-$_v.log"
    : > "$_b"
    # the patches of the sources (those of the Makefile, configure and installManPage name the
    # files as the port installs them: libtcl84.so.1, linked by its post-build)
    for p in "$top"/lang/tcl84/files/patch-*; do
        case "$p" in *patch-test-*|*patch-Makefile.in|*patch-configure|*patch-unix-installManPage) continue ;; esac
        (cd "$W/src/tcl-$_v/unix" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    if (cd "$W/src/tcl-$_v/unix" && ./configure --prefix="$W/tcl84-$_v" --enable-shared --enable-threads --enable-64bit &&
        gmake -j"$ncpu" && gmake install-binaries install-libraries) >> "$_b" 2>&1 && [ -x "$W/tcl84-$_v/bin/tclsh8.4" ]; then
        bok tcl84 "$_v" "$W/tcl84-$_v/lib/libtcl8.4.so"
    else
        bno tcl84 "$_v" "$_b"
    fi
    # calc (its make is not parallel: MAKE_JOBS_UNSAFE of the port)
    unpack lcn2-calc-v2.17.0.2_GH0.tar.gz "$W/src/calc-$_v"
    _b="$W/b-calc-$_v.log"
    printf '%s\n' "CC:= $CC" "LCC:= $CC" "CFLAGS:= $CFLAGS \${ICFLAGS} \${CCOPT}" "USE_READLINE:=" "READLINE_LIBS:=" \
        "READLINE_EXTRAS:=" "LD_SHARE:= $LDFLAGS" "LIBCALC_SHLIB:= -shared \"-Wl,-soname,libcalc\${LIB_EXT_VERSION}\" $LDFLAGS" \
        "LIBCUSTCALC_SHLIB:= -shared \"-Wl,-soname,libcustcalc\${LIB_EXT_VERSION}\" $LDFLAGS" > "$W/src/calc-$_v/Makefile.local"
    if (cd "$W/src/calc-$_v" && gmake && mkdir -p "$W/calc-$_v" &&
        cp -R calc libcalc.so* libcustcalc.so* cal "$W/calc-$_v/") > "$_b" 2>&1 &&
        env LD_LIBRARY_PATH="$W/calc-$_v" CALCPATH="$W/calc-$_v/cal" "$W/calc-$_v/calc" -q -- 'print 6*7;' >> "$_b" 2>&1; then
        bok calc "$_v" "$W/calc-$_v/libcalc.so"
    else
        bno calc "$_v" "$_b"
    fi
    rm -rf "$W/src/calc-$_v"
    # bash
    unpack bash-5.3.tar.gz "$W/src/bash-$_v"
    _b="$W/b-bash-$_v.log"
    if (cd "$W/src/bash-$_v" && ./configure --prefix="$W/bash-$_v" --without-bash-malloc --disable-nls &&
        gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok bash "$_v" "$W/bash-$_v/bin/bash"
    else
        bno bash "$_v" "$_b"
    fi
    rm -rf "$W/src/bash-$_v"
}

g_keep() { echo "$W/perl-$1 $W/ruby-$1 $W/luajit-$1 $W/tcl84-$1 $W/calc-$1 $W/bash-$1"; }

lang_scripts() {
    cat > "$W/pb.pl" << 'EOF'
use strict; use warnings; use Time::HiRes qw(time);
my $n = shift; my $t0 = time; my $sink = 0;
if ($n eq 'regex') {
    my @l = map { "10.@{[$_ % 256]}.@{[($_ >> 8) % 256]}.1 - - [26/Nov/2026:20:00:00 +0100] \"GET /videos/$_/clip_@{[$_ % 1000]}.mp4?start=@{[$_ % 300]} HTTP/1.1\" 200 @{[$_ * 13 % 100000]} \"-\" \"Mozilla/5.0\"" } 1 .. 200000;
    for my $k (1 .. 3) { for (@l) { $sink += length $4 if /^(\d+\.\d+\.\d+\.\d+) - - \[([^\]]+)\] "(GET|POST) ([^ ?]+)(\?\S*)? HTTP\/1\.[01]" (\d{3}) (\d+)/; } }
    for (@l) { (my $x = $_) =~ s/clip_(\d+)/c$1/g; $sink += length $x; }
} elsif ($n eq 'hash') {
    my %h; $h{"key$_"} = $_ for 1 .. 1000000;
    for my $k (1 .. 2) { for (1 .. 1000000) { $sink += $h{"key$_"}; } }
    delete $h{"key$_"} for 1 .. 500000; $sink += scalar keys %h;
} elsif ($n eq 'string') {
    for my $k (1 .. 40) { my $s = ''; $s .= "word" . ($_ % 100) . ' ' for 1 .. 100000;
        my @w = split / /, $s; $sink += length(join ',', map { sprintf '%8s', uc } @w) + index($s, 'word99'); }
} elsif ($n eq 'sort') {
    srand(1); my @a = map { int(rand(1e9)) } 1 .. 1000000; my @s = sort { $a <=> $b } @a; $sink += $s[0];
    my @t = map { "k" . int(rand(1e9)) } 1 .. 500000; my @u = sort @t; $sink += length $u[0];
} elsif ($n eq 'calls') {
    sub fib { my $x = shift; $x < 2 ? $x : fib($x - 1) + fib($x - 2) } $sink += fib(27);
    package Pt; sub new { my ($c, %a) = @_; bless {%a}, $c } sub x { $_[0]{x} } sub y { $_[0]{y} } sub len { my $s = shift; sqrt($s->x ** 2 + $s->y ** 2) }
    package main; for (1 .. 500000) { my $p = Pt->new(x => $_, y => $_ + 1); $sink += $p->len; }
} elsif ($n eq 'pack') {
    for (1 .. 1000000) { my $b = pack('NnC/a*', $_, $_ & 0xffff, "rec$_"); my ($a, $c, $s) = unpack('NnC/a*', $b); $sink += $a + $c + length $s; }
}
printf "%.4f\n", time - $t0; print "$sink\n" if $sink == -1;
EOF
    cat > "$W/pb.rb" << 'EOF'
require 'json'
n = ARGV[0]; t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC); sink = 0
case n
when 'regex'
  l = (1..200000).map { |i| "10.#{i % 256}.#{(i >> 8) % 256}.1 - - [26/Nov/2026:20:00:00 +0100] \"GET /videos/#{i}/clip_#{i % 1000}.mp4?start=#{i % 300} HTTP/1.1\" 200 #{i * 13 % 100000} \"-\" \"Mozilla/5.0\"" }
  re = /^(\d+\.\d+\.\d+\.\d+) - - \[([^\]]+)\] "(GET|POST) ([^ ?]+)(\?\S*)? HTTP\/1\.[01]" (\d{3}) (\d+)/
  3.times { l.each { |s| m = re.match(s); sink += m[4].size if m } }
  l.each { |s| sink += s.gsub(/clip_(\d+)/, 'c\1').size }
when 'hash'
  h = {}; (1..1000000).each { |i| h["key#{i}"] = i }
  2.times { (1..1000000).each { |i| sink += h["key#{i}"] } }
  (1..500000).each { |i| h.delete("key#{i}") }; sink += h.size
when 'string'
  10.times { s = +''; (1..100000).each { |i| s << "word#{i % 100} " }
    w = s.split(' '); sink += w.map { |x| format('%8s', x.upcase) }.join(',').size + s.index('word99') }
when 'sort'
  r = Random.new(1); a = Array.new(1000000) { r.rand(1_000_000_000) }; sink += a.sort[0]
  t = Array.new(500000) { "k#{r.rand(1_000_000_000)}" }; sink += t.sort[0].size + t.sort_by { |x| x.size }[0].size
when 'objects'
  pt = Struct.new(:x, :y) { def len = Math.sqrt(x * x + y * y) }
  (1..5000000).each { |i| sink += pt.new(i, i + 1).len }
when 'calls'
  def fib(x) = x < 2 ? x : fib(x - 1) + fib(x - 2)
  sink += fib(34)
when 'json'
  a = (1..200000).map { |i| { 'id' => i, 'name' => "item #{i}", 'price' => i * 1.25, 'tags' => ["a#{i % 7}", "b#{i % 13}"], 'nested' => { 'x' => i % 100, 'ok' => i.even? } } }
  4.times { s = JSON.generate(a); sink += JSON.parse(s).size + s.size }
when 'bignum'
  x = (1..60000).inject(:*); sink += x.to_s.size + (x % (2**127 - 1)).bit_length
end
printf("%.4f\n", Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0); puts sink if sink == -1
EOF
    cat > "$W/pb.lua" << 'EOF'
local n = arg[1]; local t0 = os.clock(); local sink = 0
if n == 'fib' then
  local function fib(x) if x < 2 then return x end return fib(x - 1) + fib(x - 2) end
  sink = fib(37)
elseif n == 'string' then
  for k = 1, 50 do local t = {} for i = 1, 100000 do t[#t + 1] = string.format('word%d', i % 100) end
    local s = table.concat(t, ' '); local u = s:gsub('word(%d+)', 'w%1'); sink = sink + #u + (s:find('word99', 1, true) or 0) end
elseif n == 'pattern' then
  local t = {} for i = 1, 200000 do t[#t + 1] = ('10.%d.%d.1 - - [26/Nov/2026] "GET /videos/%d/clip_%d.mp4?start=%d HTTP/1.1" 200 %d'):format(i % 256, math.floor(i / 256) % 256, i, i % 1000, i % 300, i * 13 % 100000) end
  local s = table.concat(t, '\n')
  for k = 1, 3 do for ip, path, code in s:gmatch('(%d+%.%d+%.%d+%.%d+) %- %- %[[^%]]+%] "GET ([^ ?]+)[^"]*" (%d+)') do sink = sink + #path end end
elseif n == 'table' then
  local t = {} for i = 1, 2000000 do t[i] = (i * 7919) % 1000003 end
  table.sort(t); sink = t[1]
  local h = {} for i = 1, 500000 do h['k' .. i] = i end for i = 1, 500000 do sink = sink + h['k' .. i] end
elseif n == 'gc' then
  local keep = {} for i = 1, 5000000 do local o = { i, i + 1, x = i } keep[i % 1000 + 1] = o sink = sink + o[2] end
  collectgarbage('collect')
end
io.write(string.format('%.4f\n', os.clock() - t0)); if sink == -1 then print(sink) end
EOF
    cat > "$W/pb.tcl" << 'EOF'
set n [lindex $argv 0]; set t0 [clock clicks -milliseconds]; set sink 0
proc fib {x} { if {$x < 2} { return $x }; return [expr {[fib [expr {$x - 1}]] + [fib [expr {$x - 2}]]}] }
switch -- $n {
    string { for {set k 0} {$k < 15} {incr k} { set s ""; for {set i 0} {$i < 100000} {incr i} { append s "word[expr {$i % 100}] " }
        set u [string map {word w} $s]; regsub -all {w(9[0-9])} $u {x\1} u; incr sink [string length $u]; incr sink [string first word99 $s] } }
    list { set l {}; for {set i 0} {$i < 1500000} {incr i} { lappend l [expr {($i * 7919) % 1000003}] }
        set s [lsort -integer $l]; incr sink [lindex $s 0]; incr sink [lsearch -exact $l 999]; set j [join $s ,]; incr sink [llength [split $j ,]] }
    expr { set x 0.0; for {set i 0} {$i < 2000000} {incr i} { set x [expr {$x + ($i % 7) * 1.5 - $i / 3.0}] }; set sink [expr {int($x) % 1000}]; incr sink [fib 22] }
    array { for {set i 0} {$i < 1500000} {incr i} { set a(k$i) $i }; for {set i 0} {$i < 1500000} {incr i} { incr sink $a(k$i) } }
    regexp { for {set i 0} {$i < 100000} {incr i} { if {[regexp {^(\d+)\.(\d+) GET (/[a-z]+/(\d+))} "10.$i GET /videos/$i/clip.mp4" -> a b c d]} { incr sink [string length $c] } } }
}
puts [format %.4f [expr {([clock clicks -milliseconds] - $t0) / 1000.0}]]
if {$sink == -1} { puts $sink }
EOF
    cat > "$W/pb.bash" << 'EOF'
n="$1"
case "$n" in
arith) i=0; s=0; while (( i < 1000000 )); do (( s += i % 7, i++ )); done ;;
string) s=""; for (( i = 0; i < 30000; i++ )); do s+="word$((i % 100)) "; done; for k in 1 2 3 4 5; do t="${s//word/w}"; t="${t//w9/x9}"; done ;;
array) declare -A a; for (( i = 0; i < 100000; i++ )); do a[k$i]=$i; done; s=0; for k in "${!a[@]}"; do (( s += a[$k] )); done ;;
func) f() { local x=$1; echo $(( x * 2 )) > /dev/null; }; for (( i = 0; i < 200000; i++ )); do f $i; done ;;
case) s=0; for (( i = 0; i < 300000; i++ )); do case "file$i.mp4" in *[05].mp4) (( s++ )) ;; *.jpg|*.png) ;; file*) (( s += 2 )) ;; esac; done ;;
read) s=0; while read -r a b c; do (( s += ${#c} )); done < "$2" ;;
esac
EOF
    i=1; while [ "$i" -le 200000 ]; do echo "$i 10.0.$((i % 256)).1 /videos/$i/clip.mp4"; i=$((i + 1)); done > "$W/lines.txt"
}

# run1 <variant> <program> <bench> <command>...: the time the script prints
run1() {
    _v="$1" _p="$2" _b="$3"; shift 3
    _t="$(cpuset -l "$last" "$@" 2> "$W/cmd.err" | head -n 1)"
    [ -n "$_t" ] || say "$_p $_b $_v: failed: $(tail -n 3 "$W/cmd.err" | tr '\n' ' ' | cut -c1-300)"
    record "$_p" "$_b" s lower "$_v" "$_t"
}

g_bench() {
    lang_scripts
    for r in $(seq 1 "$rounds"); do
        say "lang: round $r of $rounds"
        for v in $(order "$r"); do
            if have perl "$v"; then
                for b in regex hash string sort calls pack; do run1 "$v" perl "$b" "$W/perl-$v/bin/perl" "$W/pb.pl" "$b"; done
            fi
            if have ruby "$v"; then
                for b in regex hash string sort objects calls json bignum; do
                    run1 "$v" ruby "$b" "$W/ruby-$v/bin/ruby" "$W/pb.rb" "$b"
                    run1 "$v" ruby "$b, YJIT" "$W/ruby-$v/bin/ruby" --yjit "$W/pb.rb" "$b"
                done
            fi
            if have luajit "$v"; then
                for b in fib string pattern table gc; do run1 "$v" luajit "$b" "$W/luajit-$v/bin/lj" "$W/pb.lua" "$b"; done
            fi
            if have tcl84 "$v"; then
                for b in string list expr array regexp; do run1 "$v" tcl84 "$b" "$W/tcl84-$v/bin/tclsh8.4" "$W/pb.tcl" "$b"; done
            fi
            if have calc "$v"; then
                c="$W/calc-$v/calc"
                for t in "fact(30000) mod a Mersenne prime|x = fact(30000); print x % (2^127 - 1);" \
                    "the decimal digits of fact(8000)|print strlen(str(fact(8000)));" \
                    "pi to 2000 digits|print pi(1e-2000) > 3;" \
                    "ptest of 100000 numbers near 2^40|c = 0; for (i = 2^40; i < 2^40 + 100000; i++) if (ptest(i, 1)) c++; print c;" \
                    "sin of 20000 numbers|x = 0; for (i = 1; i <= 20000; i++) x += sin(i / 1000); print x > 0;"; do
                    timed "$v" calc "${t%%|*}" env LD_LIBRARY_PATH="$W/calc-$v" CALCPATH="$W/calc-$v/cal" cpuset -l "$last" "$c" -q -- "${t#*|}"
                done
            fi
            if have bash "$v"; then
                for b in arith string array func case read; do
                    timed "$v" bash "$b" cpuset -l "$last" "$W/bash-$v/bin/bash" "$W/pb.bash" "$b" "$W/lines.txt"
                done
            fi
        done
    done
}
