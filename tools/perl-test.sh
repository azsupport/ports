#!/bin/sh
# perl-test.sh - test the Perl of the repository az, installed from it (aZ,
# 11.11.2026): perl5 of lang/perl5.42, the official port without DTrace under the
# name of FreeBSD's, so that the p5-* packages of the FreeBSD repository work with
# it. Their XS modules are built against FreeBSD's perl5, with DTrace; the probes of
# DTrace are compiled into the core of Perl only (mydtrace.h: USE_DTRACE and
# PERL_CORE), so the modules take nothing of DTrace and load with ours. The checks:
#   perl      the version of the package; usedtrace undef; the Config of ours
#             against that of FreeBSD's perl5 (its package fetched, not installed):
#             the same archname, threads, multiplicity, sizes of the types, API and
#             paths (what an XS module is built for), the keys that differ listed
#   libs      perl, libperl and the XS modules of Perl link only libraries of the
#             base system (and libperl)
#   core      every XS module of Perl loads with PERL_DL_NONLAZY=1 (each symbol bound
#             at the load: a missing one fails there), and those of every day work:
#             POSIX, Encode (UTF-8, CP1251, KOI8-R, CP866), Storable, Digest::MD5,
#             Digest::SHA, Socket, List::Util, Data::Dumper, Time::HiRes, MIME::Base64,
#             gzip and bzip2, DB_File, SDBM_File, threads, Unicode::Normalize,
#             Time::Piece, Safe (Opcode), Math::BigInt::FastCalc, PerlIO::encoding
#   symbols   the dynamic symbols of FreeBSD's libperl that ours lacks (those of
#             DTrace): no XS object of the official packages takes one, and every
#             symbol of Perl they take is in our libperl
#   xs        official p5-* packages with XS (the FreeBSD repository, pkg install as
#             on a server: perl5 stays ours), each module loaded with
#             PERL_DL_NONLAZY=1 from the XS object of its package, and a function of
#             it run: JSON::XS, DBI with DBD::SQLite, Digest::SHA1, Text::CSV_XS,
#             YAML::XS, Clone, Class::XSAccessor, HTML::Parser, Sub::Name,
#             Params::Util, Net::SSLeay (on the OpenSSL of the base system), and
#             IO::Socket::SSL: TLS between a server and a client of perl on
#             127.0.0.1; the packages the test installed go again at its end
#   build     an XS module built here against ours (ExtUtils::MakeMaker, make and cc
#             of the base system, the flags of its Config), loaded and run
#
# Usage (FreeBSD, as root, perl5 of the repository az installed, the FreeBSD
# repository reachable): sh tools/perl-test.sh
# Results: perl-results/tests.txt (one line per check, the summary at the end, the
# whole of it on the screen too); exit status 0 when every check passed.

set -u
res="${AZ_RESULTS:-$(pwd)/perl-results}"
T="${PERL_TEST_WORK:-/var/tmp/perl-test}"
P=/usr/local
mkdir -p "$res"
rm -rf "$T"; mkdir -p "$T"
out="$res/tests.txt"
: > "$out"
ok=0; bad=0
pass() { echo "ok    $*" >> "$out"; ok=$((ok + 1)); }
fail() { echo "FAIL  $*" >> "$out"; bad=$((bad + 1)); }
note() { echo "note  $*" >> "$out"; }
export LANG=C.UTF-8 PERL_DL_NONLAZY=1 ASSUME_ALWAYS_YES=yes
unset PERL5LIB PERLLIB PERL5OPT PERL_USE_UNSAFE_INC PERL_MM_OPT PERL_MB_OPT 2> /dev/null || :
perl="$P/bin/perl"
# official packages with XS modules (and IO::Socket::SSL on the XS of Net::SSLeay)
xs_pkgs="p5-JSON-XS p5-DBI p5-DBD-SQLite p5-Digest-SHA1 p5-Text-CSV_XS p5-YAML-LibYAML p5-Clone p5-Class-XSAccessor p5-HTML-Parser p5-Sub-Name p5-Params-Util p5-Net-SSLeay p5-IO-Socket-SSL"
xs_mods=""
dtr=""
dtr_took=""
nobj=0
added=""
tab="$(printf '\t')"

# the packages the test installed go again (not perl5: it was there before)
cleanup() {
    [ -n "$added" ] || return 0
    # shellcheck disable=SC2086
    pkg delete -y $added > "$res/pkg-p5-delete.log" 2>&1 || note "pkg delete of the packages of the test failed (pkg-p5-delete.log)"
    added=""
}
finish() {
    cleanup
    note "summary: official XS modules loaded and run with our perl: ${xs_mods:-none}"
    note "summary: the symbols of FreeBSD's libperl that ours lacks: ${dtr:-none}; ${dtr_took:-not checked against the XS objects of the official packages}"
    echo "perl-test: $ok ok, $bad failed" >> "$out"
    cat "$out"
    [ "$bad" = 0 ]
    exit $?
}
pkgv() { pkg query '%v' "$1" 2>/dev/null | sed 's/[_,].*//'; }
repo_of() { pkg query '%At %Av' "$1" 2>/dev/null | awk '$1 == "repository" { print $2; exit }'; }
# libs_of <file>: what it loads (ldd) when every library is found and is of the base
# system, of az or libperl, in libs_out; else why in libs_bad
libs_of() {
    libs_bad=""; libs_out=""
    _l="$(ldd "$1" 2>&1)" || { libs_bad="ldd failed: $(printf '%s\n' "$_l" | tail -n 1)"; return 1; }
    case "$_l" in *"not found"*) libs_bad="$(printf '%s\n' "$_l" | grep 'not found' | head -n 2 | tr '\n' ' ')"; return 1 ;; esac
    _all=""
    for _x in $(printf '%s\n' "$_l" | awk 'NF > 2 && $2 == "=>" { print $3 }'); do
        _all="$_all ${_x##*/}"
        case "$_x" in
            /lib/* | /usr/lib/* | /usr/local/az/lib/* | "$arch"/CORE/libperl.so*) continue ;;
        esac
        libs_bad="$libs_bad $_x"
    done
    [ -z "$libs_bad" ] || { libs_bad="not of the base system:$libs_bad"; return 1; }
    libs_out="${_all# }"
}
# the dynamic symbols a file defines, takes (undefined), one a line, sorted
dsyms() { nm -D -P --defined-only "$1" 2> /dev/null | awk 'NF { sub(/@.*/, "", $1); print $1 }' | LC_ALL=C sort -u; }
usyms() { nm -D -P -u "$1" 2> /dev/null | awk 'NF { sub(/@.*/, "", $1); print $1 }' | LC_ALL=C sort -u; }
# the lines of the configuration in a Config_heavy.pl (name='value'), sorted
cfg_lines() { grep -E "^[A-Za-z_][A-Za-z0-9_]*='" "$1" | LC_ALL=C sort -u; }
cfg_val() { awk -v k="$1" -v q="'" 'index($0, k "=" q) == 1 { v = substr($0, length(k) + 3); sub(q "$", "", v); print v; exit }' "$2"; }

# --- perl ------------------------------------------------------------------------------
if ! pkg info -e perl5 || [ ! -x "$perl" ]; then
    fail "perl5 is not installed (the package of the repository az first)"
    finish
fi
pv="$(pkg query '%v' perl5)"
prepo="$(repo_of perl5)"
note "perl5 $pv, origin $(pkg query '%o' perl5), from the repository ${prepo:-unknown}"
v="$("$perl" -e 'printf "%vd", $^V' 2>&1)"
if [ "$v" = "$(pkgv perl5)" ]; then pass "perl: version $v, that of the package perl5 $pv"; else fail "perl: version $v, the package perl5 is $pv"; fi
arch="$("$perl" -MConfig -e 'print $Config{archlib}' 2>/dev/null)"
site="$("$perl" -MConfig -e 'print $Config{sitearch}' 2>/dev/null)"
if [ -z "$arch" ] || [ ! -f "$arch/Config_heavy.pl" ]; then
    fail "perl: no Config_heavy.pl in the archlib '$arch'"
    finish
fi
ours_cfg="$arch/Config_heavy.pl"
# perl -V:<key> prints the value as Configure wrote it ($Config{usedtrace} is undef
# for 'undef', build.yml 43024970605)
for kv in usedtrace=undef usethreads=define useithreads=define usemultiplicity=define useshrplib=true; do
    k="${kv%%=*}"; w="${kv#*=}"
    g="$("$perl" -V:"$k" 2>/dev/null | sed -n "s/^$k='\(.*\)';\$/\1/p")"
    if [ "$g" = "$w" ]; then pass "perl -V:$k: '$g'"; else fail "perl -V:$k: '$g', not '$w'"; fi
done
note "perl -V:archname: '$("$perl" -MConfig -e 'print $Config{archname}')', optimize: '$("$perl" -MConfig -e 'print $Config{optimize}')'"

# FreeBSD's perl5: its package fetched (not installed), for its Config and libperl
offrepo=""
for r in FreeBSD-ports FreeBSD; do
    ov="$(pkg rquery -r "$r" '%v' perl5 2>/dev/null | head -n 1)"
    [ -n "$ov" ] && { offrepo="$r"; break; }
done
off="$T/off"
offok=0
if [ -z "$offrepo" ]; then
    fail "FreeBSD's perl5: no repository FreeBSD-ports or FreeBSD has it (pkg rquery)"
else
    mkdir -p "$T/fetch" "$off"
    if pkg fetch -y -r "$offrepo" -o "$T/fetch" perl5 > "$res/pkg-fetch-perl5.log" 2>&1; then
        f="$(find "$T/fetch" -name 'perl5-[0-9]*.pkg' | head -n 1)"
        if [ -n "$f" ] && tar -xf "$f" -C "$off" 2> "$T/tar.err" && [ -f "$off$arch/Config_heavy.pl" ]; then
            offok=1
            note "FreeBSD's perl5 $ov of $offrepo (${f##*/}), unpacked into $off"
        else
            fail "FreeBSD's perl5 $ov: its package did not unpack (${f:-no file}: $(head -n 1 "$T/tar.err"))"
        fi
    else
        fail "FreeBSD's perl5 $ov: pkg fetch -r $offrepo failed: $(tail -n 1 "$res/pkg-fetch-perl5.log")"
    fi
fi
if [ "$offok" = 1 ]; then
    off_cfg="$off$arch/Config_heavy.pl"
    w="$(cfg_val usedtrace "$off_cfg")"
    if [ "$w" = define ]; then pass "FreeBSD's perl5 $ov is built with DTrace: usedtrace '$w'"; else note "FreeBSD's perl5 $ov: usedtrace '$w' (not built with DTrace?)"; fi
    # what an XS module is built for: the same in both
    abi="archname osname usethreads useithreads usemultiplicity use64bitint use64bitall uselongdouble usequadmath"
    abi="$abi usemymalloc useshrplib useperlio usedl ivtype ivsize uvtype uvsize nvtype nvsize ptrsize intsize longsize"
    abi="$abi shortsize longlongsize doublesize longdblsize sizesize lseeksize fpossize byteorder alignbytes"
    abi="$abi i8size i16size i32size i64size u8size u16size u32size u64size api_revision api_version api_subversion"
    abi="$abi api_versionstring PERL_API_REVISION PERL_API_VERSION PERL_API_SUBVERSION PERL_REVISION PERL_VERSION"
    abi="$abi dlext dlsrc so archlib privlib sitearch sitelib installsitearch installsitelib d_sitearch cc"
    # the same version: these too
    [ "$ov" = "$pv" ] || [ "${ov%%[_,]*}" = "$v" ] && abi="$abi version PERL_SUBVERSION libperl"
    differ=""; same=0
    for k in $abi; do
        a="$(cfg_val "$k" "$ours_cfg")"; b="$(cfg_val "$k" "$off_cfg")"
        if [ "$a" = "$b" ]; then same=$((same + 1)); else differ="$differ $k (ours '$a', FreeBSD's '$b')"; fi
    done
    if [ -z "$differ" ]; then
        pass "Config: the $same keys of the ABI the same as FreeBSD's perl5 $ov (archname '$(cfg_val archname "$ours_cfg")', usethreads, usemultiplicity, sizes, API, paths)"
    else
        fail "Config: these keys of the ABI differ from FreeBSD's perl5 $ov:$differ"
    fi
    cfg_lines "$ours_cfg" > "$T/cfg.ours"; cfg_lines "$off_cfg" > "$T/cfg.off"
    keys=""
    for k in $(LC_ALL=C comm -3 "$T/cfg.ours" "$T/cfg.off" | sed "s/^$tab//; s/=.*//" | LC_ALL=C sort -u); do
        keys="$keys $k (ours '$(cfg_val "$k" "$ours_cfg" | cut -c1-60)', FreeBSD's '$(cfg_val "$k" "$off_cfg" | cut -c1-60)')"
    done
    note "Config: the keys that differ from FreeBSD's perl5 $ov:${keys:- none}"
    # config.h, the header of every XS module: the macros that differ
    if [ -f "$off$arch/CORE/config.h" ]; then
        hk="$(grep -h -E '^(#define|/\*#define) ' "$arch/CORE/config.h" | LC_ALL=C sort > "$T/h.ours"
              grep -h -E '^(#define|/\*#define) ' "$off$arch/CORE/config.h" | LC_ALL=C sort > "$T/h.off"
              LC_ALL=C comm -3 "$T/h.ours" "$T/h.off" | sed "s/^$tab//" | awk '{ print $2 }' | LC_ALL=C sort -u | tr '\n' ' ')"
        note "CORE/config.h: the macros that differ from FreeBSD's: ${hk:-none}"
    fi
fi

# --- libs ------------------------------------------------------------------------------
lp="$(ls "$arch"/CORE/libperl.so.* 2>/dev/null | head -n 1)"
for f in "$perl" "$lp"; do
    [ -n "$f" ] && [ -f "$f" ] || { fail "libs: no ${f:-libperl.so in $arch/CORE}"; continue; }
    if libs_of "$f"; then pass "libs: ${f##*/}: $libs_out"; else fail "libs: ${f##*/}: $libs_bad"; fi
done
find "$arch/auto" -name '*.so' 2>/dev/null | LC_ALL=C sort > "$T/core.so"
n=0; lb=""
while read -r f; do
    n=$((n + 1))
    libs_of "$f" || lb="$lb ${f#"$arch"/auto/}: $libs_bad;"
done < "$T/core.so"
if [ "$n" = 0 ]; then fail "libs: no XS modules in $arch/auto"
elif [ -z "$lb" ]; then pass "libs: the $n XS modules of Perl ($arch/auto) link only the base system and libperl"
else fail "libs: XS modules of Perl:$lb"
fi

# --- core ------------------------------------------------------------------------------
# threads first: threads::shared warns when it comes before it
mods="$(sed -e "s#^$arch/auto/##" -e 's#/[^/]*$##' -e 's#/#::#g' "$T/core.so" | awk '$0 == "threads" { print; next } { l = l $0 "\n" } END { printf "%s", l }' | tr '\n' ' ')"
# shellcheck disable=SC2086
"$perl" -e 'for my $m (@ARGV) { eval "require $m; 1" or do { (my $e = $@) =~ s/\s+/ /g; print "$m: $e\n" } }' $mods > "$T/core.load" 2> "$T/core.load.err"
if [ -s "$T/core.load" ]; then
    fail "core: XS modules of Perl that do not load: $(head -n 5 "$T/core.load" | cut -c1-200 | tr '\n' ';')"
else
    pass "core: the $n XS modules of Perl load with PERL_DL_NONLAZY=1: $mods"
fi
[ -s "$T/core.load.err" ] && note "core: what perl said loading them: $(head -n 3 "$T/core.load.err" | cut -c1-200 | tr '\n' ';')"
cat > "$T/core.pl" <<'EOF'
use strict; use warnings; no warnings qw(once);
my $dir = shift;
sub t {
    my ($n, $c) = @_;
    my $v = eval { $c->() };
    if ($@) { (my $e = $@) =~ s/\s+/ /g; print "FAIL $n: $e\n" }
    elsif (!defined $v || $v =~ /^FAIL/) { $v //= 'undef'; $v =~ s/^FAIL ?//; print "FAIL $n: $v\n" }
    else { print "OK $n: $v\n" }
}
t POSIX => sub { require POSIX;
    my ($f, $d) = (POSIX::floor(2.7), POSIX::strftime('%d.%m.%Y', gmtime(86400 * 365)));
    $f == 2 && $d eq '01.01.1971' ? "floor(2.7) $f, strftime $d, uname " . (POSIX::uname())[0] : "FAIL floor $f, strftime $d" };
t Encode => sub { require Encode;
    my $s = "\x{41f}\x{440}\x{438}\x{432}\x{435}\x{442}";
    my %w = ('UTF-8' => 'd09fd180d0b8d0b2d0b5d182', cp1251 => 'cff0e8e2e5f2', 'koi8-r' => 'f0d2c9d7c5d4', cp866 => '8fe0a8a2a5e2');
    my @bad = grep { unpack('H*', Encode::encode($_, $s)) ne $w{$_} || Encode::decode($_, pack('H*', $w{$_})) ne $s } sort keys %w;
    @bad ? "FAIL @bad" : 'Cyrillic in ' . join(', ', sort keys %w) . " (Encode $Encode::VERSION)" };
t Storable => sub { require Storable;
    my $t = Storable::thaw(Storable::freeze({ a => [1, 2, 3], b => { c => 'd' } }));
    $t->{a}[2] == 3 && $t->{b}{c} eq 'd' ? "freeze and thaw (Storable $Storable::VERSION)" : 'FAIL thaw' };
t 'Digest::MD5' => sub { require Digest::MD5;
    my $h = Digest::MD5::md5_hex('abc'); $h eq '900150983cd24fb0d6963f7d28e17f72' ? "md5 abc $h" : "FAIL md5 $h" };
t 'Digest::SHA' => sub { require Digest::SHA;
    my $h = Digest::SHA::sha256_hex('abc');
    $h eq 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' ? "sha256 abc $h" : "FAIL sha256 $h" };
t Socket => sub { require Socket;
    my $a = Socket::inet_ntoa(Socket::inet_aton('127.0.0.1'));
    my ($e, @r) = Socket::getaddrinfo('127.0.0.1', 80, { socktype => Socket::SOCK_STREAM() });
    $a eq '127.0.0.1' && !$e && @r ? "inet_aton $a, getaddrinfo " . scalar(@r) . ' address' : "FAIL $a, getaddrinfo $e" };
t 'List::Util' => sub { require List::Util; require Scalar::Util;
    my @v = (List::Util::sum(1 .. 10), List::Util::max(3, 9, 2), (List::Util::first(sub { $_ > 3 }, 1 .. 9)), scalar(List::Util::uniq(1, 1, 2)));
    "@v" eq '55 9 4 2' && Scalar::Util::reftype(bless [], 'X') eq 'ARRAY' ? "sum max first uniq: @v" : "FAIL @v" };
t 'Data::Dumper' => sub { require Data::Dumper;
    local ($Data::Dumper::Useperl, $Data::Dumper::Sortkeys, $Data::Dumper::Indent) = (0, 1, 0);
    my $d = Data::Dumper::Dumper({ b => 1, a => [2] });
    $d eq q($VAR1 = {'a' => [2],'b' => 1};) ? "Dumper (XS): $d" : "FAIL $d" };
t 'Time::HiRes' => sub { require Time::HiRes;
    my $t0 = [Time::HiRes::gettimeofday()]; Time::HiRes::usleep(20000); my $e = Time::HiRes::tv_interval($t0);
    $e > 0.01 && $e < 5 ? sprintf('usleep 20 ms: %.3f s', $e) : "FAIL $e" };
t 'MIME::Base64' => sub { require MIME::Base64;
    my $b = MIME::Base64::encode_base64('azsupport', ''); $b eq 'YXpzdXBwb3J0' && MIME::Base64::decode_base64($b) eq 'azsupport' ? "base64 $b" : "FAIL $b" };
t gzip => sub { require IO::Compress::Gzip; require IO::Uncompress::Gunzip; require Compress::Raw::Zlib;
    my ($in, $gz, $o) = ('az ' x 1000);
    IO::Compress::Gzip::gzip(\$in => \$gz) or die $IO::Compress::Gzip::GzipError;
    IO::Uncompress::Gunzip::gunzip(\$gz => \$o) or die $IO::Uncompress::Gunzip::GunzipError;
    $o eq $in ? sprintf('gzip %d to %d bytes and back (zlib %s)', length $in, length $gz, Compress::Raw::Zlib::zlib_version()) : 'FAIL gunzip' };
t bzip2 => sub { require IO::Compress::Bzip2; require IO::Uncompress::Bunzip2;
    my ($in, $bz, $o) = ('az ' x 1000);
    IO::Compress::Bzip2::bzip2(\$in => \$bz) or die $IO::Compress::Bzip2::Bzip2Error;
    IO::Uncompress::Bunzip2::bunzip2(\$bz => \$o) or die $IO::Uncompress::Bunzip2::Bunzip2Error;
    $o eq $in ? sprintf('bzip2 %d to %d bytes and back', length $in, length $bz) : 'FAIL bunzip2' };
t DB_File => sub { require DB_File; require Fcntl;
    my %h; tie %h, 'DB_File', "$dir/db", Fcntl::O_RDWR() | Fcntl::O_CREAT(), 0644, $DB_File::DB_HASH or die "tie: $!";
    $h{az} = 'support'; untie %h;
    my %g; tie %g, 'DB_File', "$dir/db", Fcntl::O_RDONLY(), 0644, $DB_File::DB_HASH or die "tie again: $!";
    my $v = $g{az}; untie %g; ($v // '') eq 'support' ? "a hash in a file and back (DB_File $DB_File::VERSION, db $DB_File::db_version)" : 'FAIL ' . ($v // 'undef') };
t SDBM_File => sub { require SDBM_File; require Fcntl;
    my %h; tie %h, 'SDBM_File', "$dir/sdbm", Fcntl::O_RDWR() | Fcntl::O_CREAT(), 0644 or die "tie: $!";
    $h{a} = 1; my $v = $h{a}; untie %h; $v == 1 ? 'a hash in a file' : "FAIL $v" };
t 'Unicode::Normalize' => sub { require Unicode::Normalize;
    my $d = Unicode::Normalize::NFD("\x{e9}"); $d eq "e\x{301}" && Unicode::Normalize::NFC($d) eq "\x{e9}" ? 'NFD and NFC of U+00E9' : 'FAIL NFD' };
t 'Time::Piece' => sub { require Time::Piece;
    my $s = Time::Piece->strptime('2026-11-11', '%Y-%m-%d')->strftime('%d.%m.%Y'); $s eq '11.11.2026' ? "strptime and strftime: $s" : "FAIL $s" };
t 'Safe (Opcode)' => sub { require Safe;
    my $r = Safe->new->reval('6 * 7'); my $x = Safe->new->reval('system("true")');
    ($r // 0) == 42 && !defined $x ? '6 * 7 in a compartment, system() refused' : 'FAIL ' . ($r // $@) };
t 'Math::BigInt::FastCalc' => sub { require Math::BigInt; Math::BigInt->import(try => 'FastCalc');
    my $n = Math::BigInt->new(2)->bpow(100); my $l = Math::BigInt->config('lib');
    "$n" eq '1267650600228229401496703205376' && $l eq 'Math::BigInt::FastCalc' ? "2**100 with $l" : "FAIL $n with $l" };
t 'PerlIO::encoding' => sub {
    my $b = pack('H*', 'cff0e8e2e5f20a');
    open(my $fh, '<:encoding(cp1251)', \$b) or die "open: $!"; my $l = <$fh>; close $fh;
    $l eq "\x{41f}\x{440}\x{438}\x{432}\x{435}\x{442}\n" ? 'a CP1251 line read through the layer' : 'FAIL ' . unpack('H*', $l) };
t 'Hash::Util' => sub { require Hash::Util;
    my %h = (a => 1); Hash::Util::lock_ref_keys(\%h); eval { $h{b} = 1 }; $@ =~ /disallowed/ ? "lock_ref_keys: a key not allowed refused" : "FAIL $@" };
EOF
"$perl" "$T/core.pl" "$T" > "$T/core.out" 2>&1
while IFS= read -r l; do
    case "$l" in
        "OK "*) pass "core: ${l#OK }" ;;
        "FAIL "*) fail "core: ${l#FAIL }" ;;
        *) fail "core: $l" ;;
    esac
done < "$T/core.out"
# threads (a perl of its own: threads first)
r="$("$perl" -Mthreads -Mthreads::shared -e 'my $x :shared = 0; my @t = map { threads->create(sub { lock $x; $x += $_[0]; $_[0] * 2 }, $_) } 1 .. 4; my $s = 0; $s += $_->join for @t; print $x == 10 && $s == 20 ? "OK 4 threads, a shared sum $x" : "FAIL $x $s"' 2>&1)"
case "$r" in "OK "*) pass "core: threads: ${r#OK }" ;; *) fail "core: threads: ${r#FAIL }" ;; esac

# --- xs: the official packages ------------------------------------------------------------
pkg query '%n' | LC_ALL=C sort > "$T/before"
note "pkg install $xs_pkgs (pkg-p5.log)"
# shellcheck disable=SC2086
pkg install -y $xs_pkgs > "$res/pkg-p5.log" 2>&1 || note "pkg install says it failed (pkg-p5.log): $(tail -n 1 "$res/pkg-p5.log")"
# once more for those it left (a new pkg installed first stops the rest)
miss=""
for p in $xs_pkgs; do pkg info -e "$p" || miss="$miss $p"; done
if [ -n "$miss" ]; then
    note "pkg install once more:$miss"
    # shellcheck disable=SC2086
    pkg install -y $miss >> "$res/pkg-p5.log" 2>&1 || note "pkg install says it failed again (pkg-p5.log)"
fi
pkg query '%n' | LC_ALL=C sort > "$T/after"
added="$(LC_ALL=C comm -13 "$T/before" "$T/after" | tr '\n' ' ')"
if [ "$(pkg query '%v' perl5 2>/dev/null)" = "$pv" ] && [ "$(repo_of perl5)" = "$prepo" ]; then
    pass "pkg install of the p5 packages kept our perl5 ($pv of ${prepo:-unknown})"
else
    fail "pkg install of the p5 packages put perl5 $(pkg query '%v' perl5 2>/dev/null) of $(repo_of perl5) in the place of ours ($pv of $prepo): pkg-p5.log"
    CONSERVATIVE_UPGRADE=no pkg install -y -f -r "${prepo:-azbuild}" perl5 >> "$res/pkg-p5.log" 2>&1 || note "pkg install -f -r ${prepo:-azbuild} perl5 failed"
fi
have=""; miss=""
for p in $xs_pkgs; do
    if pkg info -e "$p"; then have="$have $p-$(pkg query '%v' "$p") ($(repo_of "$p"))"; else miss="$miss $p"; fi
done
[ -z "$miss" ] || fail "xs: not installed:$miss ($(tail -n 1 "$res/pkg-p5.log"))"
[ -z "$have" ] || note "xs: installed:$have"
for p in $xs_pkgs; do
    pkg info -e "$p" || continue
    case "$(repo_of "$p")" in azbuild | "") fail "xs: $p is from the repository '$(repo_of "$p")', not FreeBSD's" ;; esac
done

# symbols: what FreeBSD's libperl has and ours not; what the XS objects of the
# official packages take
if [ "$offok" = 1 ] && [ -n "$lp" ]; then
    olp="$(ls "$off$arch"/CORE/libperl.so.* 2>/dev/null | head -n 1)"
    dsyms "$lp" > "$T/def.ours"
    if [ -n "$olp" ] && dsyms "$olp" > "$T/def.off" && [ -s "$T/def.off" ] && [ -s "$T/def.ours" ]; then
        LC_ALL=C comm -23 "$T/def.off" "$T/def.ours" > "$T/only.off"
        LC_ALL=C comm -13 "$T/def.off" "$T/def.ours" > "$T/only.ours"
        dtr="$(tr '\n' ' ' < "$T/only.off" | sed 's/ $//')"
        nd="$(grep -c -i dtrace "$T/only.off")"
        if [ -s "$T/only.off" ] && [ "$nd" = "$(wc -l < "$T/only.off" | tr -d ' ')" ]; then
            pass "symbols: FreeBSD's libperl exports $(wc -l < "$T/def.off" | tr -d ' '), ours $(wc -l < "$T/def.ours" | tr -d ' '); only FreeBSD's: those of DTrace: $dtr"
        else
            note "symbols: only in FreeBSD's libperl: ${dtr:-none}"
        fi
        [ -s "$T/only.ours" ] && note "symbols: only in our libperl: $(tr '\n' ' ' < "$T/only.ours")"
        : > "$T/xs.so"
        for p in $xs_pkgs; do pkg info -e "$p" && pkg query '%Fp' "$p" | grep '\.so$' >> "$T/xs.so"; done
        took=""; lack=""; nperl=0
        while read -r f; do
            nobj=$((nobj + 1))
            usyms "$f" > "$T/u"
            x="$(LC_ALL=C comm -12 "$T/u" "$T/only.off" | tr '\n' ' ')"
            [ -n "$x" ] && took="$took ${f##*/}: $x;"
            grep -E '^(Perl|PL_|perl_)' "$T/u" > "$T/up"
            nperl=$((nperl + $(wc -l < "$T/up")))
            y="$(LC_ALL=C comm -23 "$T/up" "$T/def.ours" | tr '\n' ' ')"
            [ -n "$y" ] && lack="$lack ${f##*/}: $y;"
            z="$(grep -i dtrace "$T/u" | tr '\n' ' ')"
            [ -n "$z" ] && took="$took ${f##*/}: $z;"
        done < "$T/xs.so"
        if [ "$nobj" = 0 ]; then fail "symbols: no XS objects of the official packages"
        elif [ -z "$took" ]; then
            pass "symbols: none of the $nobj XS objects of the official packages takes a symbol of DTrace or one only FreeBSD's libperl has"
            dtr_took="taken by none of the $nobj XS objects of the official packages"
        else
            fail "symbols: XS objects of the official packages take what ours lacks:$took"
            dtr_took="taken by XS objects of the official packages:$took"
        fi
        if [ "$nobj" != 0 ] && [ -z "$lack" ]; then pass "symbols: the $nperl symbols of Perl the $nobj XS objects take are all in our libperl"
        elif [ -n "$lack" ]; then fail "symbols: not in our libperl:$lack"
        fi
    else
        fail "symbols: nm -D of the libperl of FreeBSD (${olp:-none}) or ours ($lp) gave nothing"
    fi
fi

cat > "$T/xs.pl" <<'EOF'
use strict; use warnings; no warnings qw(once);
my $site = shift;
# the XS objects of a module loaded from site_perl (the official package, not a
# pure-Perl fallback)
sub so_of { my $p = shift; join ' ', grep { index($_, "$site/auto/$p/") == 0 } @DynaLoader::dl_shared_objects }
sub t {
    my ($n, $auto, $c) = @_;
    my $v = eval { eval "require $n; 1" or die $@; $c->() };
    if ($@) { (my $e = $@) =~ s/\s+/ /g; print "FAIL $n: $e\n"; return }
    if (!defined $v || $v =~ /^FAIL/) { $v //= 'undef'; $v =~ s/^FAIL ?//; print "FAIL $n: $v\n"; return }
    my $so = so_of($auto);
    if ($so eq '') { print "FAIL $n: $v, but no XS object of $site/auto/$auto loaded\n"; return }
    print "OK $n: $v\tso=$so\n";
}
t 'JSON::XS', 'JSON/XS', sub {
    my $j = JSON::XS->new->utf8->canonical;
    my $s = $j->encode({ b => [1, 2], a => "\x{43f}" }); my $d = $j->decode($s);
    $s eq qq({"a":"\xd0\xbf","b":[1,2]}) && $d->{a} eq "\x{43f}" && $d->{b}[1] == 2 ? "encode and decode, canonical (JSON::XS $JSON::XS::VERSION)" : "FAIL $s" };
t 'DBD::SQLite', 'DBD/SQLite', sub { require DBI;
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 });
    $dbh->do('CREATE TABLE t (a INTEGER, b TEXT)');
    my $st = $dbh->prepare('INSERT INTO t VALUES (?, ?)'); $st->execute($_, "r$_") for 1 .. 3;
    my ($n, $s) = $dbh->selectrow_array('SELECT count(*), sum(a) FROM t');
    my $v = $dbh->{sqlite_version}; $dbh->disconnect;
    $n == 3 && $s == 6 ? "a table in memory: 3 rows, sum $s (DBD::SQLite $DBD::SQLite::VERSION, SQLite $v)" : "FAIL $n rows, sum $s" };
t 'DBI', 'DBI', sub {
    my $x = DBI::neat('abc'); $x eq q('abc') ? "neat (XS) $x, DBI $DBI::VERSION" : "FAIL neat $x" };
t 'Digest::SHA1', 'Digest/SHA1', sub {
    my $h = Digest::SHA1::sha1_hex('abc'); $h eq 'a9993e364706816aba3e25717850c26c9cd0d89d' ? "sha1 abc $h" : "FAIL $h" };
t 'Text::CSV_XS', 'Text/CSV_XS', sub {
    my $c = Text::CSV_XS->new({ binary => 1 });
    $c->parse(q(a,"b,c",d)) or die 'parse'; my @f = $c->fields;
    $c->combine('x', 'y,z') or die 'combine'; my $s = $c->string;
    @f == 3 && $f[1] eq 'b,c' && $s eq q(x,"y,z") ? "parse 3 fields, combine $s (Text::CSV_XS $Text::CSV_XS::VERSION)" : "FAIL @f / $s" };
t 'YAML::XS', 'YAML/XS/LibYAML', sub {
    my $y = YAML::XS::Dump({ a => [1, 2] }); my $d = YAML::XS::Load($y);
    $y eq "---\na:\n- 1\n- 2\n" && $d->{a}[1] == 2 ? "Dump and Load (YAML::XS $YAML::XS::VERSION)" : "FAIL $y" };
t 'Clone', 'Clone', sub {
    my $x = { a => [1, { b => 2 }] }; my $y = Clone::clone($x);
    $y->{a}[1]{b} == 2 && $y->{a} != $x->{a} && $y->{a}[1] != $x->{a}[1] ? 'a deep copy' : 'FAIL clone' };
t 'Class::XSAccessor', 'Class/XSAccessor', sub {
    Class::XSAccessor->import(class => 'AZ::Obj', constructor => 'new', accessors => { name => 'name' });
    my $o = AZ::Obj->new(name => 'az'); my $a = $o->name; $o->name('aZ');
    $a eq 'az' && $o->name eq 'aZ' ? 'a constructor and an accessor in XS' : "FAIL $a" };
t 'HTML::Parser', 'HTML/Parser', sub {
    my @got;
    my $p = HTML::Parser->new(api_version => 3, start_h => [sub { push @got, "$_[0]:" . ($_[1]{href} // '') }, 'tagname, attr']);
    $p->parse('<p><a href="/x">t</a></p>'); $p->eof;
    "@got" eq 'p: a:/x' ? "start tags @got (HTML::Parser $HTML::Parser::VERSION)" : "FAIL @got" };
t 'Sub::Name', 'Sub/Name', sub {
    my $s = Sub::Name::subname('AZ::named' => sub { (caller(0))[3] }); my $n = $s->();
    $n eq 'AZ::named' ? "subname: $n" : "FAIL $n" };
t 'Params::Util', 'Params/Util', sub {
    Params::Util::_ARRAY([1]) && !defined Params::Util::_ARRAY([]) && Params::Util::_POSINT(5) ? '_ARRAY and _POSINT' : 'FAIL' };
t 'Net::SSLeay', 'Net/SSLeay', sub {
    my $v = Net::SSLeay::SSLeay_version(0); $v =~ /^OpenSSL / ? "$v (Net::SSLeay $Net::SSLeay::VERSION)" : "FAIL $v" };
EOF
"$perl" "$T/xs.pl" "$site" > "$T/xs.out" 2>&1
while IFS= read -r l; do
    case "$l" in
        "OK "*)
            m="${l#OK }"; m="${m%%: *}"
            so="${l##*${tab}so=}"; d="${l#OK }"; d="${d%%${tab}so=*}"
            own=""; wrong=""
            for f in $so; do
                o="$(pkg which -q "$f" 2>/dev/null)"
                own="$own ${o:-none}"
                case " $xs_pkgs " in *" ${o%-*} "*) ;; *) wrong="$wrong ${f##*/} of ${o:-no package}" ;; esac
            done
            if [ -z "$wrong" ]; then pass "xs: $d; XS object of$own"; xs_mods="$xs_mods $m"
            else fail "xs: $m: $d; XS object not of the official packages:$wrong"
            fi
            ;;
        "FAIL "*) fail "xs: ${l#FAIL }" ;;
        *) fail "xs: $l" ;;
    esac
done < "$T/xs.out"
xs_mods="${xs_mods# }"
# Net::SSLeay on the OpenSSL of the base system
if pkg info -e p5-Net-SSLeay; then
    sv="$("$perl" -MNet::SSLeay -e 'print Net::SSLeay::SSLeay_version(0)' 2>&1)"
    bv="$(/usr/bin/openssl version 2>/dev/null)"
    sso="$(pkg query '%Fp' p5-Net-SSLeay | grep '/SSLeay\.so$' | head -n 1)"
    ssl="$(ldd "$sso" 2>/dev/null | awk '$1 ~ /^lib(ssl|crypto)\.so/ { print $3 }' | tr '\n' ' ')"
    case "$ssl" in
        */usr/local/*|"") fail "xs: Net::SSLeay: libssl and libcrypto '$ssl', not of the base system" ;;
        *) if [ "$(echo "$sv" | awk '{ print $2 }')" = "$(echo "$bv" | awk '{ print $2 }')" ]; then
               pass "xs: Net::SSLeay on the OpenSSL of the base system: $sv ($ssl)"
           else
               fail "xs: Net::SSLeay: $sv, the base system has $bv"
           fi ;;
    esac
fi
# IO::Socket::SSL: TLS between a server and a client of perl on 127.0.0.1
if pkg info -e p5-IO-Socket-SSL; then
    cat > "$T/tls.pl" <<'EOF'
use strict; use warnings; no warnings qw(once);
use IO::Socket::SSL;
my ($cert, $key) = @ARGV;
my $srv = IO::Socket::SSL->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 5, ReuseAddr => 1,
    SSL_server => 1, SSL_cert_file => $cert, SSL_key_file => $key) or die "server: $SSL_ERROR\n";
my $port = $srv->sockport;
my $pid = fork() // die "fork: $!\n";
if ($pid == 0) {
    alarm 30;
    my $c = $srv->accept or exit 1;
    my $l = <$c>;
    print $c "tls of perl: $l";
    close $c;
    exit 0;
}
alarm 30;
my $c = IO::Socket::SSL->new(PeerAddr => '127.0.0.1', PeerPort => $port, SSL_hostname => 'localhost',
    SSL_verifycn_name => 'localhost', SSL_verifycn_scheme => 'http', SSL_ca_file => $cert,
    SSL_verify_mode => SSL_VERIFY_PEER) or do { kill 9, $pid; die "client: $SSL_ERROR\n" };
print $c "hello\n";
my $r = <$c>;
my ($ver, $cipher) = ($c->get_sslversion, $c->get_cipher);
close $c; waitpid $pid, 0;
print +($r // '') eq "tls of perl: hello\n"
    ? "OK $ver $cipher, the certificate verified (IO::Socket::SSL $IO::Socket::SSL::VERSION)\n"
    : 'FAIL got ' . ($r // 'nothing') . "\n";
EOF
    if /usr/bin/openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 1 -subj /CN=localhost \
            -addext subjectAltName=DNS:localhost -keyout "$T/key.pem" -out "$T/cert.pem" > "$T/openssl.log" 2>&1; then
        r="$(timeout 60 "$perl" "$T/tls.pl" "$T/cert.pem" "$T/key.pem" 2>&1 | tail -n 1)"
        case "$r" in
            "OK "*) pass "xs: IO::Socket::SSL: ${r#OK }"; xs_mods="$xs_mods IO::Socket::SSL" ;;
            *) fail "xs: IO::Socket::SSL: ${r#FAIL }" ;;
        esac
    else
        fail "xs: IO::Socket::SSL: no certificate: $(tail -n 1 "$T/openssl.log")"
    fi
fi

# --- build: an XS module against ours ------------------------------------------------------
mkdir -p "$T/xs/AZTest"
cat > "$T/xs/AZTest/Makefile.PL" <<'EOF'
use ExtUtils::MakeMaker;
WriteMakefile(NAME => 'AZTest', VERSION_FROM => 'AZTest.pm');
EOF
cat > "$T/xs/AZTest/AZTest.pm" <<'EOF'
package AZTest;
use strict;
our $VERSION = '1.0';
require XSLoader;
XSLoader::load('AZTest', $VERSION);
1;
EOF
cat > "$T/xs/AZTest/AZTest.xs" <<'EOF'
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = AZTest		PACKAGE = AZTest

IV
add(a, b)
	IV a
	IV b
    CODE:
	RETVAL = a + b;
    OUTPUT:
	RETVAL

SV *
hello(name)
	SV *name
    CODE:
	RETVAL = newSVpvf("hello, %" SVf, SVfARG(name));
    OUTPUT:
	RETVAL
EOF
if (cd "$T/xs/AZTest" && "$perl" Makefile.PL && make) > "$res/xs-build.log" 2>&1; then
    r="$(cd "$T/xs/AZTest" && "$perl" -Mblib -MAZTest -e 'print AZTest::add(40, 2), " ", AZTest::hello("az")' 2>&1)"
    bso="$(find "$T/xs/AZTest/blib" -name 'AZTest.so' | head -n 1)"
    if [ "$r" = "42 hello, az" ]; then
        pass "build: an XS module built against ours ($("$perl" -MConfig -e 'print "$Config{cc} $Config{optimize}"')) loads and runs: $r"
    else
        fail "build: AZTest built, but gives: $r"
    fi
    if [ -n "$bso" ] && libs_of "$bso"; then pass "build: AZTest.so: $libs_out"; else fail "build: AZTest.so: ${libs_bad:-not built}"; fi
else
    fail "build: perl Makefile.PL and make failed: $(tail -n 2 "$res/xs-build.log" | tr '\n' ' ')"
fi

finish
