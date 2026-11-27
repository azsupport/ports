#!/bin/sh
# SPDX-License-Identifier: BSD-2-Clause
#
# Mk/azsupport-cc-names.sh: the compilers of the build, named in the text files of a
# package, named as those of the base system: cc, c++ and cpp, and ar, nm, ranlib and ld,
# so that what a server builds against a package takes the cc of the base system (the
# extensions of Python, Perl, Ruby and PHP, the modules of Apache by apxs, PGXS of
# PostgreSQL, the loadable builtins of bash, the *-config scripts): clang of
# devel/llvm<N> (Mk/bsd.overlay.mk) and GCC of lang/gcc<G> (Mk/Uses/azgcc.mk) are build
# dependencies only, a server has neither (27.11.2026). Mk/bsd.overlay.mk runs it on the
# stage of every port (azsupport-cc-names), tools/azsupport-build.sh on its trees before
# its checks; tools/cc-path-check.sh (tools/build.sh) fails a run with a package that
# names them still.
#
# The names, as a word (not in a path such as lib/gcc<G>/, not in gcc<G>-libs):
#   <LOCALBASE>/bin/clang<N>, clang++<N>, clang-cpp<N>          cc, c++, cpp
#   <LOCALBASE>/bin/llvm-ar<N>, llvm-nm<N>, llvm-ranlib<N>       ar, nm, ranlib
#   <LOCALBASE>/bin/ld.lld<N>                                    ld
#   <LOCALBASE>/llvm<N>/bin/clang, clang++, clang-cpp, llvm-ar,  cc, c++, cpp, ar,
#     llvm-nm, llvm-ranlib, ld.lld (the prefix of devel/llvm<N>,  nm, ranlib, ld
#     the CC of USES=llvm: databases/postgresql18-server)
#   gcc<G> -static-libgcc, gcc<G>, g++<G>, cpp<G>                cc, cc, c++, cpp
#   gcc-ar<G>, gcc-nm<G>, gcc-ranlib<G>                          ar, nm, ranlib
# (those of GCC bare, as bsd.gcc.mk names them, or under <LOCALBASE>/bin, as
# tools/azsupport-build.sh does). Text files only (grep -I), symbolic links not
# followed; a file is rewritten in place (its inode, mode and links stay), with its
# modification time kept. Each file rewritten is said.
#
# Usage: sh Mk/azsupport-cc-names.sh [--check] <file or directory>...
#   --check: only say the files that name them ("<file>: <names>")
#   --test: its cases ("ok" or "FAIL" a line)
# Environment: AZSUPPORT_CLANG (N; default: the llvm of DEFAULT_VERSIONS of
#   tools/make.conf.in of this tree), AZSUPPORT_GCC (G; default: AZSUPPORT_GCC?= of
#   Mk/Uses/azgcc.mk), LOCALBASE (default /usr/local)
# Exit status: 0 done (--check: no such file), 1 --check found some, a file could not be
#   rewritten or a case of --test failed, 2 a wrong call or no version of either compiler.

set -u
top="$(cd "$(dirname "$0")/.." && pwd)"
lb="${LOCALBASE:-/usr/local}"

ccv="${AZSUPPORT_CLANG:-}"
case "$ccv" in *[!0-9]*) ccv="" ;; esac
[ -n "$ccv" ] || ccv="$(sed -n 's/^DEFAULT_VERSIONS+=.*[[:space:]]llvm=\([0-9][0-9]*\).*/\1/p' "$top/tools/make.conf.in" 2> /dev/null | head -n 1)"
gccv="${AZSUPPORT_GCC:-}"
case "$gccv" in *[!0-9]*) gccv="" ;; esac
[ -n "$gccv" ] || gccv="$(sed -n 's/^AZSUPPORT_GCC?=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$top/Mk/Uses/azgcc.mk" 2> /dev/null | head -n 1)"

# the expressions of sed -E: before a name the start of the line or a character of no
# name or path, after it the end or such a character (again, for two names one character
# apart: the character between them belongs to the first match)
lbre="$(printf '%s' "$lb" | sed 's/[].[^$*+?(){}|\\]/\\&/g')"
B='(^|[^[:alnum:]_./+-])'
A='([^[:alnum:]_./+-]|$)'
exprs() {
    if [ -n "$ccv" ]; then
        printf '%s\n' "s#$B$lbre/bin/clang$ccv$A#\\1cc\\2#g" "s#$B$lbre/bin/clang\\+\\+$ccv$A#\\1c++\\2#g" \
            "s#$B$lbre/bin/clang-cpp$ccv$A#\\1cpp\\2#g" "s#$B$lbre/bin/llvm-(ar|nm|ranlib)$ccv$A#\\1\\2\\3#g" \
            "s#$B$lbre/bin/ld\\.lld$ccv$A#\\1ld\\2#g" \
            "s#$B$lbre/llvm$ccv/bin/clang$A#\\1cc\\2#g" "s#$B$lbre/llvm$ccv/bin/clang\\+\\+$A#\\1c++\\2#g" \
            "s#$B$lbre/llvm$ccv/bin/clang-cpp$A#\\1cpp\\2#g" "s#$B$lbre/llvm$ccv/bin/llvm-(ar|nm|ranlib)$A#\\1\\2\\3#g" \
            "s#$B$lbre/llvm$ccv/bin/ld\\.lld$A#\\1ld\\2#g"
    fi
    if [ -n "$gccv" ]; then
        printf '%s\n' "s#$B($lbre/bin/)?gcc$gccv -static-libgcc$A#\\1cc\\3#g" "s#$B($lbre/bin/)?gcc$gccv$A#\\1cc\\3#g" \
            "s#$B($lbre/bin/)?g\\+\\+$gccv$A#\\1c++\\3#g" "s#$B($lbre/bin/)?cpp$gccv$A#\\1cpp\\3#g" \
            "s#$B($lbre/bin/)?gcc-(ar|nm|ranlib)$gccv$A#\\1\\3\\4#g"
    fi
}
# one expression of grep -E for all of them
names_re() {
    r=""
    [ -z "$ccv" ] || r="$B$lbre/bin/(clang|clang\\+\\+|clang-cpp|llvm-ar|llvm-nm|llvm-ranlib|ld\\.lld)$ccv$A"
    [ -z "$ccv" ] || r="$r|$B$lbre/llvm$ccv/bin/(clang|clang\\+\\+|clang-cpp|llvm-ar|llvm-nm|llvm-ranlib|ld\\.lld)$A"
    [ -z "$gccv" ] || r="${r:+$r|}$B($lbre/bin/)?(gcc|g\\+\\+|cpp|gcc-ar|gcc-nm|gcc-ranlib)$gccv$A"
    printf '%s\n' "$r"
}

# the text files of the arguments that name them, a line each
files_of() {
    re="$(names_re)"
    for p in "$@"; do
        if [ -d "$p" ]; then
            find "$p" -type f -exec grep -I -l -E -e "$re" {} + 2> /dev/null
        elif [ -f "$p" ] && [ ! -L "$p" ]; then
            grep -I -l -E -e "$re" "$p" 2> /dev/null
        fi
    done
}
# the names in a file, once each
names_in() { grep -I -o -E -e "$(names_re)" "$1" 2> /dev/null | sed -E 's/^[^[:alnum:]/]//; s/[^[:alnum:]+]$//' | sort -u | tr '\n' ' ' | sed 's/ $//'; }

# fix <file> <temporary directory>: the file rewritten, its time kept
fix() {
    f="$1" t="$2"
    set --
    while read -r e; do set -- "$@" -e "$e" -e "$e"; done <<EOF
$(exprs)
EOF
    sed -E "$@" "$f" > "$t/new" || { echo "azsupport-cc-names: $f: sed failed" >&2; return 1; }
    cmp -s "$f" "$t/new" && return 0
    touch -r "$f" "$t/time" || return 1
    w=1
    [ -w "$f" ] || { w=0; chmod u+w "$f" || return 1; }
    cat "$t/new" > "$f" || { echo "azsupport-cc-names: $f: cannot be rewritten" >&2; return 1; }
    [ "$w" = 1 ] || chmod u-w "$f"
    touch -r "$t/time" "$f"
}

run() {
    mode="$1"; shift
    if [ -z "$ccv" ] && [ -z "$gccv" ]; then
        echo "azsupport-cc-names: no version of clang (AZSUPPORT_CLANG, tools/make.conf.in) nor of GCC (AZSUPPORT_GCC, Mk/Uses/azgcc.mk)" >&2
        return 2
    fi
    [ -n "$ccv" ] || echo "azsupport-cc-names: no version of clang (AZSUPPORT_CLANG, tools/make.conf.in): its names not looked for" >&2
    [ -n "$gccv" ] || echo "azsupport-cc-names: no version of GCC (AZSUPPORT_GCC, Mk/Uses/azgcc.mk): its names not looked for" >&2
    t="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-cc-names.XXXXXX")" || return 2
    files_of "$@" > "$t/files"
    rc=0
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        # (none: a link of a file rewritten before)
        n="$(names_in "$f")"
        [ -n "$n" ] || continue
        if [ "$mode" = check ]; then
            echo "$f: $n"
            rc=1
        elif fix "$f" "$t"; then
            left="$(names_in "$f")"
            if [ -n "$left" ]; then
                echo "azsupport-cc-names: $f: $n as those of the base system, but not $left" >&2
                rc=1
            else
                echo "azsupport-cc-names: $f: $n as those of the base system"
            fi
        else
            rc=1
        fi
    done < "$t/files"
    find "$t" -delete
    return "$rc"
}

selftest() {
    tt="$(mktemp -d "${TMPDIR:-/tmp}/azsupport-cc-names-test.XXXXXX")" || exit 2
    bad=0
    AZSUPPORT_CLANG=23 AZSUPPORT_GCC=16 LOCALBASE=/usr/local
    ccv=23 gccv=16 lb=/usr/local lbre='/usr/local'
    case_() {
        printf '%s\n' "$2" > "$tt/in"
        run fix "$tt/in" > /dev/null 2>&1
        got="$(cat "$tt/in")"
        if [ "$got" = "$3" ]; then echo "ok    $1"; else echo "FAIL  $1: got [$got], want [$3]"; bad=1; fi
    }
    case_ "python sysconfig" "'CC': '/usr/local/bin/clang23', 'CXX': '/usr/local/bin/clang++23'," "'CC': 'cc', 'CXX': 'c++',"
    case_ "LDSHARED" "LDSHARED=	/usr/local/bin/clang23 -shared" "LDSHARED=	cc -shared"
    case_ "the cpp" "CPP = /usr/local/bin/clang-cpp23" "CPP = cpp"
    case_ "llvm tools" "AR= /usr/local/bin/llvm-ar23 RANLIB=/usr/local/bin/llvm-ranlib23 LD=/usr/local/bin/ld.lld23" "AR= ar RANLIB=ranlib LD=ld"
    case_ "configure args" "'CC=/usr/local/bin/clang23' 'CPP=/usr/local/bin/clang-cpp23'" "'CC=cc' 'CPP=cpp'"
    case_ "gcc with -static-libgcc" "TCL_CC='gcc16 -static-libgcc'" "TCL_CC='cc'"
    case_ "gcc by path" "CC=\"/usr/local/bin/gcc16 -static-libgcc\"" "CC=\"cc\""
    case_ "g++ and cpp" "CXX = g++16; CPP=cpp16" "CXX = c++; CPP=cpp"
    case_ "perl cpprun" "cpprun='gcc16  -E'" "cpprun='cc  -E'"
    case_ "two at once" "gcc16 gcc16 gcc16" "cc cc cc"
    case_ "gcc tools" "AR=gcc-ar16 NM=gcc-nm16" "AR=ar NM=nm"
    case_ "a path of gcc kept" "-L/usr/local/lib/gcc16 lang/gcc16 gcc16-libs x86_64-portbld-freebsd15.1-gcc16" \
        "-L/usr/local/lib/gcc16 lang/gcc16 gcc16-libs x86_64-portbld-freebsd15.1-gcc16"
    case_ "other versions kept" "/usr/local/bin/clang19 /usr/local/bin/clang230 gcc15 gcc161 /opt/bin/clang23" \
        "/usr/local/bin/clang19 /usr/local/bin/clang230 gcc15 gcc161 /opt/bin/clang23"
    case_ "the base kept" "CC=cc CXX=c++ CPP=cpp clang" "CC=cc CXX=c++ CPP=cpp clang"
    case_ "the prefix of llvm" "'CC=/usr/local/llvm23/bin/clang' 'CXX=/usr/local/llvm23/bin/clang++' 'CPP=/usr/local/llvm23/bin/clang-cpp' AR=/usr/local/llvm23/bin/llvm-ar LD=/usr/local/llvm23/bin/ld.lld" \
        "'CC=cc' 'CXX=c++' 'CPP=cpp' AR=ar LD=ld"
    case_ "the rest of the prefix kept" "/usr/local/llvm23/bin/llvm-config /usr/local/llvm23/lib/libLLVM.so /usr/local/llvm19/bin/clang /usr/local/llvm23/bin/clang-23" \
        "/usr/local/llvm23/bin/llvm-config /usr/local/llvm23/lib/libLLVM.so /usr/local/llvm19/bin/clang /usr/local/llvm23/bin/clang-23"
    # a binary file: not rewritten
    printf 'CC=gcc16\000\001' > "$tt/bin"
    run fix "$tt/bin" > /dev/null 2>&1
    if [ "$(od -An -c "$tt/bin" | tr -d ' \n')" = 'CC=gcc16\0001' ]; then echo "ok    binary kept"; else echo "FAIL  binary rewritten"; bad=1; fi
    # mode, time and hard link kept; --check
    printf '%s\n' "cc='gcc16'" > "$tt/ro"; ln "$tt/ro" "$tt/ro-link"; chmod 444 "$tt/ro"; touch -t 202001020304 "$tt/ro"
    if run check "$tt/ro" > "$tt/chk" 2>&1; then echo "FAIL  --check found nothing"; bad=1
    elif grep -q 'gcc16' "$tt/chk"; then echo "ok    --check"; else echo "FAIL  --check: $(cat "$tt/chk")"; bad=1; fi
    run fix "$tt" > /dev/null 2>&1
    if [ "$(cat "$tt/ro-link")" = "cc='cc'" ] && [ -z "$(find "$tt/ro" -perm -u+w)" ] && \
        [ -z "$(find "$tt/ro" -newer "$tt/in")" ] && run check "$tt" > /dev/null 2>&1; then
        echo "ok    a directory, mode, time and link kept"
    else
        echo "FAIL  a directory: $(cat "$tt/ro-link"), $(ls -l "$tt/ro")"; bad=1
    fi
    chmod u+w "$tt/ro"
    find "$tt" -delete
    [ "$bad" = 0 ]
}

case "${1:-}" in
    --test) selftest; exit $? ;;
    --check) shift; [ $# -gt 0 ] || { sed -n '/^# Usage/,/^# Exit/s/^# \{0,1\}//p' "$0" >&2; exit 2; }; run check "$@"; exit $? ;;
    -*|"") sed -n '/^# Usage/,/^# Exit/s/^# \{0,1\}//p' "$0" >&2; exit 2 ;;
esac
run fix "$@"
exit $?
