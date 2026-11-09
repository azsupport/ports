#!/bin/sh
# configure-check.sh - the configure check of tools/build.sh (AZ_CONFIGURE_CHECK=1):
# a PHP port configured by the build (strict: the flags of the port) is configured
# once more with the same compiler and with the errors of C that GCC 14 and later
# and clang 16 and later make of old code turned back into warnings (permissive),
# and the results are compared, so that a test of configure that fails for its
# own C shows, whatever the build does next (printf without <stdio.h> in the test
# "if using GNU libiconv" of ext/iconv of PHP 5.6-8.2: php74-iconv without
# -liconv and ICONV_SUPPORTS_ERRNO, CI 42600124878). A difference is a test whose
# result depends on those errors; its strict result is the one of the package.
#
# Usage:
#   sh tools/configure-check.sh probe <cc>
#       the permissive flags <cc> accepts (<cc> may have more words: "gcc16
#       -static-libgcc"), on one line: -Wno-error=<w> of each warning of the
#       list below with which <cc> compiles an empty C file and says nothing
#       (GCC fails on a warning it does not know, clang warns of it)
#   sh tools/configure-check.sh save <dir> <wrkdir> <configure dir> <cc> [<flags>]
#       the results of a configure into <dir>: config.log, the header
#       (main/php_config.h of a core, config.h of a module built by phpize) and
#       the generated Makefile of <configure dir> (CONFIGURE_WRKSRC), with
#       <wrkdir> (WRKDIR: the paths of the run), <cc> and <flags>; without a
#       config.log there the file "none" says so (configure did not run)
#   sh tools/configure-check.sh compare <title> <strict dir> <permissive dir>
#       the differences of two saves, a block of text on stdout:
#       - each "checking ..." of config.log with another result (paired with its
#         "result:" line, in the order of config.log), or that one run only made,
#         with the errors of the compiler or the linker between the two lines in
#         the config.log of the strict run (else of the permissive one): the
#         diagnostic that made the test fail;
#       - the end of each configure (its header written, or its error);
#       - each macro of the header with another value (or undefined in one);
#       - each variable of the Makefile with other words (-liconv in LDFLAGS);
#       the paths of each run (its WRKDIR) and the permissive flags left out first.
#       Exit status: 0 the same, 1 differences, 2 not compared (said why).
#
# The permissive flags, those of -fpermissive of GCC 14 for C: -Wno-error= of
# implicit-function-declaration, implicit-int, incompatible-pointer-types,
# int-conversion (GCC 14+ and clang), return-mismatch and
# declaration-missing-parameter-type (GCC 14+), and of
# incompatible-function-pointer-types (clang 16+; GCC has these in
# incompatible-pointer-types), as far as the compiler knows them (probe).

set -u
me=configure-check
CANDIDATES="implicit-function-declaration implicit-int incompatible-pointer-types int-conversion return-mismatch declaration-missing-parameter-type incompatible-function-pointer-types"

usage() { sed -n 's/^# \{0,1\}//; 12,35p' "$0" >&2; exit 2; }
[ $# -ge 1 ] || usage
cmd="$1"; shift

tmp="$(mktemp -d "${TMPDIR:-/tmp}/$me.XXXXXX")" || { echo "$me: no temporary directory" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT
trap 'exit 2' INT TERM

case "$cmd" in
probe)
    [ $# -eq 1 ] || usage
    out=""
    for w in $CANDIDATES; do
        # shellcheck disable=SC2086
        if $1 "-Wno-error=$w" -x c -c -o "$tmp/empty.o" /dev/null > "$tmp/err" 2>&1 && [ ! -s "$tmp/err" ]; then
            out="$out -Wno-error=$w"
        fi
    done
    printf '%s\n' "${out# }"
    exit 0
    ;;
save)
    if [ $# -lt 4 ] || [ $# -gt 5 ]; then usage; fi
    d="$1"; cw="$3"
    rm -rf "$d"
    mkdir -p "$d" || { echo "$me: cannot make $d" >&2; exit 2; }
    printf '%s\n' "$2" > "$d/wrkdir"
    printf '%s\n' "$4" > "$d/cc"
    printf '%s\n' "${5:-}" > "$d/flags"
    if [ ! -f "$cw/config.log" ]; then
        echo "no config.log in $cw" > "$d/none"
        exit 0
    fi
    cp "$cw/config.log" "$d/config.log"
    for h in main/php_config.h config.h; do
        if [ -f "$cw/$h" ]; then cp "$cw/$h" "$d/header"; echo "$h" > "$d/header.name"; break; fi
    done
    if [ -f "$cw/Makefile" ]; then cp "$cw/Makefile" "$d/Makefile"; fi
    exit 0
    ;;
compare) ;;
*) usage ;;
esac

[ $# -eq 3 ] || usage
title="$1"; S="$2"; P="$3"
for x in "$S:strict" "$P:permissive"; do
    d="${x%:*}"; w="${x##*:}"
    if [ ! -d "$d" ]; then printf '== %s: not compared: no %s results (%s)\n' "$title" "$w" "$d"; exit 2; fi
    if [ -f "$d/none" ]; then printf '== %s: not compared: the %s configure did not run (%s)\n' "$title" "$w" "$(cat "$d/none")"; exit 2; fi
done

# norm <dir> <file>: a file of a save, its paths of the run as @WRKDIR@, without
# the permissive flags (those of the permissive save, out of both: a port may
# have one of them itself, lang/php56)
flags="$(cat "$P/flags" 2> /dev/null)"
norm() {
    _wd="$(sed 's/[][\.*^$|]/\\&/g' "$1/wrkdir" 2> /dev/null)"
    {
        if [ -n "$_wd" ]; then printf 's|%s|@WRKDIR@|g\n' "$_wd"; fi
        # (PHP keeps the CFLAGS of configure in CONFIGURE_COMMAND, a word quoted each)
        for _f in $flags; do printf "s| '%s'||g\ns| %s||g\ns|%s||g\n" "$_f" "$_f" "$_f"; done
    } > "$tmp/norm.sed"
    if [ -f "$1/$2" ]; then sed -f "$tmp/norm.sed" "$1/$2"; fi
}
norm "$S" config.log > "$tmp/s.log"
norm "$P" config.log > "$tmp/p.log"

# the checks of the two config.log files: each "configure:<n>: checking <what>"
# with the "configure:<n>: result: <result>" that closes it (the last check still
# open: checks may nest), by <what> and its occurrence; the differences in the
# order of the strict config.log, then the checks of the permissive one only; for
# each the errors between the check and its result (three at most), in the strict
# config.log first
awk -v sf="$tmp/s.log" -v pf="$tmp/p.log" '
    function parse(f, w,   l, nr, sp, t, r, k, i, j, x) {
        nr = 0; sp = 0
        while ((getline l < f) > 0) {
            L[w, ++nr] = l
            if (l ~ /^configure:[0-9]+: checking /) {
                sp++; st[sp] = substr(l, index(l, ": checking ") + 11); sn[sp] = nr
            } else if (l ~ /^configure:[0-9]+: result: / && sp > 0) {
                r = substr(l, index(l, ": result: ") + 10); sub(/^\(cached\) /, "", r)
                t = st[sp]; k = t SUBSEP (++cnt[w, t])
                R[w, k] = r; A[w, k] = sn[sp]; B[w, k] = nr; has[w, k] = 1
                sp--
                # in the order of the checking lines (insertion: nesting is rare)
                i = ++no[w]
                while (i > 1 && A[w, ord[w, i - 1]] > A[w, k]) { ord[w, i] = ord[w, i - 1]; i-- }
                ord[w, i] = k
            }
        }
        close(f)
    }
    function diag(w, k,   i, l, n, o) {
        o = ""; n = 0
        if (!((w, k) in has)) return ""
        for (i = A[w, k] + 1; i < B[w, k]; i++) {
            l = L[w, i]
            if (l ~ /error:/ || l ~ /[Uu]ndefined (reference|symbol)/ || l ~ /exited with status/) {
                sub(/^[ \t]+/, "", l)
                o = o "    " (w == "s" ? "strict" : "permissive") " config.log: " substr(l, 1, 220) "\n"
                if (++n == 3) break
            }
        }
        return o
    }
    # a check of both runs without an error says so; one of a run only (the
    # other went another way) just its errors, when it has some
    function out(k, sr, pr,   t, d) {
        t = k; sub(SUBSEP ".*", "", t)
        printf "- checking %s... strict: %s; permissive: %s\n", t, sr, pr
        d = diag("s", k); if (d == "") d = diag("p", k)
        if (d == "" && sr != "(not checked)" && pr != "(not checked)")
            d = "    (no error of the compiler or the linker between the check and its result)\n"
        printf "%s", d
    }
    BEGIN {
        parse(sf, "s"); parse(pf, "p")
        for (i = 1; i <= no["s"]; i++) {
            k = ord["s", i]
            if (!(("p", k) in has)) out(k, R["s", k], "(not checked)")
            else if (R["s", k] != R["p", k]) out(k, R["s", k], R["p", k])
        }
        for (i = 1; i <= no["p"]; i++) {
            k = ord["p", i]
            if (!(("s", k) in has)) out(k, "(not checked)", R["p", k])
        }
    }' > "$tmp/out"
nd="$(grep -c '^- ' "$tmp/out")"

# the end of each configure: its header written (config.status ran), or the error
cfg_end() {
    if [ -f "$1/header" ]; then echo "finished"; return; fi
    _e="$(grep -E '^configure:[0-9]+: error: ' "$2" | tail -n 1 | sed 's/^configure:[0-9]*: //' | cut -c1-200)"
    echo "failed${_e:+: $_e}"
}
se="$(cfg_end "$S" "$tmp/s.log")"; pe="$(cfg_end "$P" "$tmp/p.log")"
if [ "$se" != "$pe" ]; then
    printf '%s\n' "- configure: strict: $se; permissive: $pe" >> "$tmp/out"
fi

# the header: "<name>\t<n>\t<value>" for each #define (its words, "(defined)"
# without a value), #undef and /* #undef */ ("(undefined)"); <n>: its occurrence
cat > "$tmp/hdr.awk" << 'EOF'
{
    l = $0
    if (match(l, /^[ \t]*#[ \t]*define[ \t]+[A-Za-z_][A-Za-z0-9_]*/)) {
        d = substr(l, RSTART, RLENGTH); sub(/^[ \t]*#[ \t]*define[ \t]+/, "", d)
        v = substr(l, RSTART + RLENGTH)
        gsub(/[ \t]+/, " ", v); sub(/^ /, "", v); sub(/ $/, "", v)
        if (v == "") v = "(defined)"
    } else if (match(l, /^[ \t]*(\/\*[ \t]*)?#[ \t]*undef[ \t]+[A-Za-z_][A-Za-z0-9_]*/)) {
        d = substr(l, RSTART, RLENGTH); sub(/^[ \t]*(\/\*[ \t]*)?#[ \t]*undef[ \t]+/, "", d)
        v = "(undefined)"
    } else next
    print d "\t" (++n[d]) "\t" v
}
EOF
hn="$(cat "$S/header.name" 2> /dev/null || cat "$P/header.name" 2> /dev/null || echo header)"
if [ -f "$S/header" ] && [ -f "$P/header" ]; then
    norm "$S" header | awk -f "$tmp/hdr.awk" > "$tmp/s.hdr"
    norm "$P" header | awk -f "$tmp/hdr.awk" > "$tmp/p.hdr"
    awk -F '\t' -v hn="$hn" '
        FILENAME == ARGV[1] { s[$1 "\t" $2] = $3; so[++ns] = $1 "\t" $2; next }
        { p[$1 "\t" $2] = $3; po[++np] = $1 "\t" $2 }
        END {
            for (i = 1; i <= ns; i++) { k = so[i]; split(k, kk, "\t")
                if (!(k in p)) print "- " hn ": " kk[1] ": strict " s[k] "; permissive: (no such line)"
                else if (s[k] != p[k]) print "- " hn ": " kk[1] ": strict " s[k] "; permissive " p[k] }
            for (i = 1; i <= np; i++) { k = po[i]; split(k, kk, "\t")
                if (!(k in s)) print "- " hn ": " kk[1] ": strict: (no such line); permissive " p[k] }
        }' "$tmp/s.hdr" "$tmp/p.hdr" >> "$tmp/out"
fi

# the Makefile: "<name>\t<n>\t<value>" for each assignment (continuation lines
# joined); the words one value has and the other not
cat > "$tmp/mk.awk" << 'EOF'
/^[A-Za-z_][A-Za-z0-9_.]*[ \t]*[+:?!]?=/ {
    l = $0
    while (l ~ /\\$/ && (getline nx) > 0) { sub(/\\$/, " ", l); l = l nx }
    nm = l; sub(/[ \t]*[+:?!]?=.*/, "", nm)
    v = l; sub(/^[^=]*=/, "", v); gsub(/[ \t]+/, " ", v); sub(/^ /, "", v); sub(/ $/, "", v)
    print nm "\t" (++n[nm]) "\t" v
}
EOF
if [ -f "$S/Makefile" ] && [ -f "$P/Makefile" ]; then
    norm "$S" Makefile | awk -f "$tmp/mk.awk" > "$tmp/s.mk"
    norm "$P" Makefile | awk -f "$tmp/mk.awk" > "$tmp/p.mk"
    awk -F '\t' '
        # the words of a that b has not
        function words(a, b,   x, y, h, i, m, o) {
            m = split(b, y, " "); for (i = 1; i <= m; i++) h[y[i]] = 1
            m = split(a, x, " "); o = ""
            for (i = 1; i <= m; i++) if (!(x[i] in h)) o = o " " x[i]
            return substr(o, 2)
        }
        FILENAME == ARGV[1] { s[$1 "\t" $2] = $3; so[++ns] = $1 "\t" $2; next }
        { p[$1 "\t" $2] = $3; po[++np] = $1 "\t" $2 }
        END {
            for (i = 1; i <= ns; i++) { k = so[i]; split(k, kk, "\t")
                if (!(k in p)) { print "- Makefile: " kk[1] ": strict only: " s[k]; continue }
                if (s[k] == p[k]) continue
                a = words(s[k], p[k]); b = words(p[k], s[k])
                if (a == "" && b == "") print "- Makefile: " kk[1] ": the same words, in another order or repeated: strict " s[k] "; permissive " p[k]
                else print "- Makefile: " kk[1] ":" (a != "" ? " strict only: " a : "") (a != "" && b != "" ? ";" : "") (b != "" ? " permissive only: " b : "") }
            for (i = 1; i <= np; i++) { k = po[i]; split(k, kk, "\t")
                if (!(k in s)) print "- Makefile: " kk[1] ": permissive only: " p[k] }
        }' "$tmp/s.mk" "$tmp/p.mk" >> "$tmp/out"
fi

nd="$(grep -c '^- ' "$tmp/out")"
cc="$(cat "$S/cc" 2> /dev/null)"
if [ "$nd" = 0 ]; then
    printf '== %s: the same (%s; permissive: %s)\n' "$title" "${cc:-?}" "${flags:-no flags}"
    exit 0
fi
s=s; [ "$nd" = 1 ] && s=""
printf '== %s: %s difference%s (%s; permissive: %s)\n' "$title" "$nd" "$s" "${cc:-?}" "${flags:-no flags}"
cat "$tmp/out"
exit 1
