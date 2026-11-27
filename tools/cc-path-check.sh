#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
#
# tools/cc-path-check.sh <package>...: the packages whose text files name the compilers of
# the build (27.11.2026): clang of devel/llvm<N> (Mk/bsd.overlay.mk: <LOCALBASE>/bin/clang<N>,
# clang++<N>, clang-cpp<N>, and llvm-ar<N>, llvm-nm<N>, llvm-ranlib<N>, ld.lld<N>; the same
# tools without <N> in <LOCALBASE>/llvm<N>/bin, the CC of USES=llvm) and GCC of
# lang/gcc<G> (Mk/Uses/azgcc.mk: gcc<G>, g++<G>, cpp<G>, as a word: not lib/gcc<G>/ nor
# gcc<G>-libs). Both are build dependencies only, and what a server builds against a
# package (the extensions of Python, Perl, Ruby, the modules of apxs, PGXS, the *-config
# scripts) takes the compiler the package names: a server has neither. Mk/azsupport-cc-names.sh
# rewrites them in the stage of every port; this checks the packages after it, and is in the
# hash of no port: tools/build.sh runs it on the packages of each port it builds (a line in
# results/summary.txt for each file, the run fails).
#
# A line per package on the output:
#   OK <package>
#   FAIL <package>: <file>: <names>   (a line for each file; the path in the package)
#   SKIP <package>: <origin>, the compiler itself (devel/llvm*, lang/gcc*)
# The files of a package: tar -xf of it (bsdtar reads the .pkg of pkg), the metadata
# (+MANIFEST, +COMPACT_MANIFEST: the annotation azsupport_cc names GCC) left out; text files
# only (grep -I). Its origin: pkg query -F, else the +COMPACT_MANIFEST or +MANIFEST in it.
# Environment: AZSUPPORT_CLANG (N; default the llvm of DEFAULT_VERSIONS of tools/make.conf.in),
#   AZSUPPORT_GCC (G; default AZSUPPORT_GCC?= of Mk/Uses/azgcc.mk), LOCALBASE (/usr/local).
# Usage: sh tools/cc-path-check.sh <package>...
#        sh tools/cc-path-check.sh --test   its cases ("ok" or "FAIL" a line)
# Exit status: 0 no package names them, 1 one does (or a case of --test failed), 2 a
# package could not be read or a wrong call.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"

versions() {
    lb="${LOCALBASE:-/usr/local}"
    ccv="${AZSUPPORT_CLANG:-}"
    case "$ccv" in *[!0-9]*) ccv="" ;; esac
    [ -n "$ccv" ] || ccv="$(sed -n 's/^DEFAULT_VERSIONS+=.*[[:space:]]llvm=\([0-9][0-9]*\).*/\1/p' "$top/tools/make.conf.in" 2> /dev/null | head -n 1)"
    gccv="${AZSUPPORT_GCC:-}"
    case "$gccv" in *[!0-9]*) gccv="" ;; esac
    [ -n "$gccv" ] || gccv="$(sed -n 's/^AZSUPPORT_GCC?=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$top/Mk/Uses/azgcc.mk" 2> /dev/null | head -n 1)"
    lbre="$(printf '%s' "$lb" | sed 's/[].[^$*+?(){}|\\]/\\&/g')"
    re=""
    [ -z "$ccv" ] || re="$lbre/bin/(clang|clang\\+\\+|clang-cpp|llvm-ar|llvm-nm|llvm-ranlib|ld\\.lld)$ccv([^[:alnum:]_.+-]|\$)"
    [ -z "$ccv" ] || re="$re|$lbre/llvm$ccv/bin/(clang|clang\\+\\+|clang-cpp|llvm-ar|llvm-nm|llvm-ranlib|ld\\.lld)([^[:alnum:]_.+-]|\$)"
    [ -z "$gccv" ] || re="${re:+$re|}(^|[^[:alnum:]_./+-])(gcc|g\\+\\+|cpp)$gccv([^[:alnum:]_./+-]|\$)"
}

# check_dir <directory> <name of the package>: the FAIL lines of its text files
check_dir() {
    find "$1" -type f ! -path "$1/+*" -exec grep -I -l -E -e "$re" {} + 2> /dev/null | LC_ALL=C sort |
        while IFS= read -r f; do
            n="$(grep -I -o -E -e "$re" "$f" 2> /dev/null | sed -E 's/^[^[:alnum:]/]//; s/[^[:alnum:]+]$//' | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"
            echo "FAIL $2: /${f#"$1"/}: $n"
        done
}

check() {
    versions
    if [ -z "$re" ]; then
        echo "cc-path-check: no version of clang (AZSUPPORT_CLANG, tools/make.conf.in) nor of GCC (AZSUPPORT_GCC, Mk/Uses/azgcc.mk)" >&2
        return 2
    fi
    t="$(mktemp -d "${TMPDIR:-/tmp}/cc-path-check.XXXXXX")" || return 2
    rc=0
    for p in "$@"; do
        n="${p##*/}"
        # the catalog of a repository (pkg repo), not a package
        case "$n" in data.pkg|packagesite.pkg|digests.pkg|filesite.pkg|meta.pkg) continue ;; esac
        o=""
        command -v pkg > /dev/null 2>&1 && o="$(pkg query -F "$p" '%o' 2> /dev/null)"
        [ -n "$o" ] || o="$( (tar -xOf "$p" +COMPACT_MANIFEST 2> /dev/null || tar -xOf "$p" +MANIFEST 2> /dev/null) |
            sed -n 's/.*"origin" *: *"\([^"]*\)".*/\1/p' | head -n 1)"
        case "$o" in
            devel/llvm[0-9]*|lang/gcc[0-9]*) echo "SKIP $n: $o, the compiler itself"; continue ;;
        esac
        d="$t/x"
        mkdir -p "$d"
        if ! tar -xf "$p" -C "$d" 2> "$t/err"; then
            echo "FAIL $n: cannot be read: $(head -n 1 "$t/err")"
            [ "$rc" = 1 ] || rc=2
            find "$d" -delete 2> /dev/null
            continue
        fi
        check_dir "$d" "$n" > "$t/out"
        if [ -s "$t/out" ]; then
            cat "$t/out"
            rc=1
        else
            echo "OK $n"
        fi
        find "$d" -delete 2> /dev/null
    done
    find "$t" -delete 2> /dev/null
    return "$rc"
}

# --test: packages of its own (tar archives with a +COMPACT_MANIFEST), each with what it
# is to say; then Mk/azsupport-cc-names.sh on the files of the failing ones, after which
# they are to pass
selftest() {
    tt="$(mktemp -d "${TMPDIR:-/tmp}/cc-path-check-test.XXXXXX")" || exit 2
    AZSUPPORT_CLANG=23 AZSUPPORT_GCC=16 LOCALBASE=/usr/local
    export AZSUPPORT_CLANG AZSUPPORT_GCC LOCALBASE
    bad=0
    # mkpkg <name> <origin> <path>=<line>...: a package of these files
    mkpkg() {
        n="$1" o="$2"; shift 2
        s="$tt/src/$n"
        mkdir -p "$s"
        printf '{"name":"%s","origin":"%s","annotations":{"azsupport_cc":"gcc16"}}\n' "$n" "$o" > "$s/+COMPACT_MANIFEST"
        for a in "$@"; do
            f="${a%%=*}"
            mkdir -p "$s${f%/*}"
            printf '%s\n' "${a#*=}" >> "$s$f"
        done
        (cd "$s" && tar -cf "$tt/$n.pkg" +COMPACT_MANIFEST usr)
    }
    case_() {
        got="$(sh "$0" "$tt/$2.pkg" 2>&1 | tr '\n' ';')"
        if [ "$got" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1: got [$got], want [$3]"; bad=1; fi
    }
    mkpkg clean lang/clean "/usr/local/bin/x-config=echo cc" "/usr/local/lib/gcc16/note=-L/usr/local/lib/gcc16 gcc16-libs lang/gcc16"
    case_ "the base compiler, a path of GCC" clean "OK clean.pkg;"
    mkpkg py lang/python312 "/usr/local/lib/python3.12/_sysconfigdata__freebsd15_.py='CC': '/usr/local/bin/clang23', 'CXX': '/usr/local/bin/clang++23',"
    case_ "clang of devel/llvm23" py "FAIL py.pkg: /usr/local/lib/python3.12/_sysconfigdata__freebsd15_.py: /usr/local/bin/clang++23 /usr/local/bin/clang23;"
    mkpkg tcl lang/tcl84 "/usr/local/lib/tcl8.4/tclConfig.sh=TCL_CC='gcc16 -static-libgcc'" "/usr/local/lib/tcl8.4/tclConfig.sh=TCL_CPP='cpp16'"
    case_ "GCC of lang/gcc16" tcl "FAIL tcl.pkg: /usr/local/lib/tcl8.4/tclConfig.sh: cpp16 gcc16;"
    mkpkg apr devel/apr "/usr/local/bin/apr-1-config=CPP=\"/usr/local/bin/clang-cpp23\"" "/usr/local/share/apr/libtool=AR=\"/usr/local/bin/llvm-ar23\""
    case_ "two files" apr "FAIL apr.pkg: /usr/local/bin/apr-1-config: /usr/local/bin/clang-cpp23;FAIL apr.pkg: /usr/local/share/apr/libtool: /usr/local/bin/llvm-ar23;"
    mkpkg pg databases/postgresql18-server "/usr/local/include/postgresql/server/pg_config.h=#define CONFIGURE_ARGS \" 'CC=/usr/local/llvm23/bin/clang' 'CXX=/usr/local/llvm23/bin/clang++' 'LLVM_CONFIG=/usr/local/llvm23/bin/llvm-config'\""
    case_ "the prefix of devel/llvm23 (USES=llvm)" pg "FAIL pg.pkg: /usr/local/include/postgresql/server/pg_config.h: /usr/local/llvm23/bin/clang /usr/local/llvm23/bin/clang++;"
    mkpkg llvm23 devel/llvm23 "/usr/local/llvm23/bin/scan=/usr/local/bin/clang23"
    case_ "the compiler itself" llvm23 "SKIP llvm23.pkg: devel/llvm23, the compiler itself;"
    mkpkg gcclibs lang/gcc16-libs "/usr/local/lib/gcc16/x.py=gcc16"
    case_ "the libraries of GCC" gcclibs "SKIP gcclibs.pkg: lang/gcc16-libs, the compiler itself;"
    mkdir -p "$tt/src/bin/usr/local/bin"
    printf '{"origin":"x/bin"}\n' > "$tt/src/bin/+COMPACT_MANIFEST"
    printf 'cc=/usr/local/bin/clang23\000\001\002' > "$tt/src/bin/usr/local/bin/prog"
    (cd "$tt/src/bin" && tar -cf "$tt/bin.pkg" +COMPACT_MANIFEST usr)
    case_ "a binary file" bin "OK bin.pkg;"
    : > "$tt/broken.pkg"
    got="$(sh "$0" "$tt/broken.pkg" 2>&1; echo "rc=$?")"
    case "$got" in *"FAIL broken.pkg: cannot be read"*rc=2) echo "ok    a package that cannot be read" ;; *) echo "FAIL  a package that cannot be read: $got"; bad=1 ;; esac
    if sh "$0" "$tt/clean.pkg" > /dev/null 2>&1; then echo "ok    exit 0"; else echo "FAIL  exit of a clean package"; bad=1; fi
    sh "$0" "$tt/py.pkg" > /dev/null 2>&1
    if [ $? = 1 ]; then echo "ok    exit 1"; else echo "FAIL  exit of a failing package"; bad=1; fi
    # the rewriting of Mk/azsupport-cc-names.sh: the same packages pass after it
    if [ -f "$top/Mk/azsupport-cc-names.sh" ]; then
        for n in py tcl apr pg; do
            sh "$top/Mk/azsupport-cc-names.sh" "$tt/src/$n/usr" > /dev/null 2>&1
            (cd "$tt/src/$n" && tar -cf "$tt/$n.pkg" +COMPACT_MANIFEST usr)
            case_ "$n after Mk/azsupport-cc-names.sh" "$n" "OK $n.pkg;"
        done
    fi
    find "$tt" -delete
    [ "$bad" = 0 ]
}

case "${1:-}" in
    --test) selftest; exit $? ;;
    -*|"") sed -n '/^# Usage/,/^# Exit/s/^# \{0,1\}//p' "$0" >&2; exit 2 ;;
esac
check "$@"
exit $?
