# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/tools.sh: the group tools of tools/prog-bench.sh (sourced by it).
#
# git 2.56.1 (devel/git, its distinfo) as the port: configure --with-libpcre (PCRE2 of the
# packages), the libcurl of the packages (ours: that of ftp/curl), no Perl, Python, Tcl/Tk,
# gettext, expat, Rust; zlib and OpenSSL of the base system. On a bare clone of nginx/nginx
# (GitHub; its whole history), one thread (pack.threads, grep.threads, index-pack --threads):
# index-pack of its pack (SHA-1 of sha1dc, inflate, the deltas), repack -adf (window 10,
# depth 50: the search of deltas), fsck --full, log -p of the history, blame of a file of
# 4000 lines, grep -E of the work tree (5 times), status (20 times).
#
# rsync 3.5.2 (net/rsync, its distinfo) with the options of the port: the MD5 and the rolling
# checksum in assembler, the rolling checksum in SIMD (C++), the included popt, no iconv and
# IDN; xxHash, zstd and lz4 of the packages (ours: of azsupport), the OpenSSL and zlib of the
# base system. Local copies on a tmpfs, sender and receiver on the last CPU: a tree of
# /usr/include, /usr/share/man, /usr/bin and /usr/sbin copied into an empty directory, the
# same again (nothing to do, 5 times), -c (the checksum of every file of the same tree), the
# delta of a file of 512 MB with 100 blocks of 4 KB changed (--no-whole-file).

g_progs="git rsync"

g_need() {
    need pcre2 xxhash zstd liblz4
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch git-2.56.1.tar.xz f0b0bf89264b9bd2e1c640363e7529643989da76281600473c50745cd34a607f \
        https://www.kernel.org/pub/software/scm/git/git-2.56.1.tar.xz https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.56.1.tar.xz
    fetch rsync-3.5.2.tar.gz a10d591825251e070f74c98df3daad195def4ed81b4a2de16169026aea33f6c8 \
        https://download.samba.org/pub/rsync/src/rsync-3.5.2.tar.gz https://www.mirrorservice.org/sites/rsync.samba.org/src/rsync-3.5.2.tar.gz
    unpack git-2.56.1.tar.xz "$W/src/git-$_v"
    _b="$W/b-git-$_v.log"
    _ga="DEVELOPER= NO_RUST=yes NO_TCLTK=yes NO_PERL=1 NO_GETTEXT=yes NO_EXPAT=1 CURLDIR=/usr/local V=1"
    # shellcheck disable=SC2086
    if (cd "$W/src/git-$_v" && ./configure --prefix="$W/git-$_v" --enable-pthreads=-pthread ac_cv_header_libcharset_h=no \
        --with-libpcre --without-perl --without-python --with-curl CPPFLAGS=-I/usr/local/include \
        LDFLAGS="-L/usr/local/lib $LDFLAGS" && gmake -j"$ncpu" $_ga all && gmake $_ga install) > "$_b" 2>&1; then
        bok git "$_v" "$W/git-$_v/bin/git"
    else
        bno git "$_v" "$_b"
    fi
    unpack rsync-3.5.2.tar.gz "$W/src/rsync-$_v"
    _b="$W/b-rsync-$_v.log"
    if (cd "$W/src/rsync-$_v" && ./configure --prefix="$W/rsync-$_v" --disable-debug --disable-md2man --enable-ipv6 \
        --enable-md5-asm --enable-roll-asm --enable-roll-simd --disable-iconv --disable-iconv-open --disable-idn \
        --with-included-popt --with-included-zlib=no ac_cv_search_libiconv_open=no CPPFLAGS=-I/usr/local/include \
        LDFLAGS="-L/usr/local/lib $LDFLAGS" && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok rsync "$_v" "$W/rsync-$_v/bin/rsync"
        grep -E '^(  *|)(xxhash|zstd|lz4|openssl|SIMD|asm)' "$_b" | head -n 5 >&3
    else
        bno rsync "$_v" "$_b"
    fi
}

g_keep() { echo "$W/git-$1 $W/rsync-$1"; }

g_bench() {
    pbrd
    T=/mnt/pbrd
    mkdir -p "$T/g"
    if "$W/git-clang19/bin/git" clone -q --bare https://github.com/nginx/nginx.git "$T/g/nginx.git" > "$W/git-clone.log" 2>&1 &&
        "$W/git-clang19/bin/git" clone -q "$T/g/nginx.git" "$T/g/wt" >> "$W/git-clone.log" 2>&1; then
        cp "$T"/g/nginx.git/objects/pack/pack-*.pack "$T/g/p.pack"
        say "git: nginx/nginx: $("$W/git-clang19/bin/git" -C "$T/g/wt" rev-list --count HEAD) commits, the pack $(ls -l "$T/g/p.pack" | awk '{ print $5 }') bytes"
    else
        say "git: no clone of nginx/nginx: $(tail -n 3 "$W/git-clone.log" | tr '\n' ' ')"
        echo "git: no clone of nginx/nginx (GitHub): $(tail -n 2 "$W/git-clone.log" | tr '\n' ' ')" >> "$W/fails/$group-notes.md"
    fi
    mkdir -p "$T/r"
    tar -cf - -C / usr/include usr/share/man usr/bin usr/sbin 2> /dev/null | tar -xf - -C "$T/r"
    head -c 536870912 /dev/random > "$T/big"
    cp "$T/big" "$T/big.mod"
    i=1; while [ "$i" -le 100 ]; do
        head -c 4096 /dev/random | dd of="$T/big.mod" bs=4096 seek=$((i * 1300)) conv=notrunc 2> /dev/null; i=$((i + 1)); done
    say "rsync: the tree: $(find "$T/r" -type f | wc -l | tr -d ' ') files, $(du -sm "$T/r" | cut -f 1) MB"
    for r in $(seq 1 "$rounds"); do
        say "tools: round $r of $rounds"
        for v in $(order "$r"); do
            if have git "$v" && [ -f "$T/g/p.pack" ]; then
                g="$W/git-$v/bin/git"
                rm -f "$T/g/x.idx"
                timed "$v" git "index-pack of nginx/nginx (one thread)" cpuset -l "$last" "$g" -C "$T/g/nginx.git" index-pack --threads=1 -o "$T/g/x.idx" "$T/g/p.pack"
                rm -rf "$T/g/rp.git"; cp -R "$T/g/nginx.git" "$T/g/rp.git"
                timed "$v" git "repack -adf, window 10, depth 50 (one thread)" cpuset -l "$last" "$g" -C "$T/g/rp.git" -c pack.threads=1 repack -adfq --window=10 --depth=50
                timed "$v" git "fsck --full" cpuset -l "$last" "$g" -C "$T/g/nginx.git" fsck --full --no-progress
                timed "$v" git "log -p of the history" cpuset -l "$last" "$g" -C "$T/g/wt" log -p --no-color
                timed "$v" git "blame src/http/ngx_http_request.c" cpuset -l "$last" "$g" -C "$T/g/wt" blame src/http/ngx_http_request.c
                timed5 "$v" git "grep -E of the work tree (one thread)" cpuset -l "$last" "$g" -C "$T/g/wt" -c grep.threads=1 grep -E -c 'ngx_[a-z_]+_(init|create)[a-z_]*\('
                timed "$v" git "status, 20 times" sh -c 'for i in $(seq 1 20); do cpuset -l "$1" "$2" -C "$3" status --porcelain || exit 1; done' sh "$last" "$g" "$T/g/wt"
            fi
            if have rsync "$v"; then
                x="$W/rsync-$v/bin/rsync"
                rm -rf "$T/d"
                timed "$v" rsync "a tree into an empty directory" cpuset -l "$last" "$x" -a "$T/r/" "$T/d/"
                timed5 "$v" rsync "the same tree again: nothing to do" cpuset -l "$last" "$x" -a "$T/r/" "$T/d/"
                timed "$v" rsync "-c: the checksums of the same tree" cpuset -l "$last" "$x" -ac "$T/r/" "$T/d/"
                cp "$T/big" "$T/d/big"
                timed "$v" rsync "delta of 512 MB, 100 blocks of 4 KB changed (--no-whole-file)" cpuset -l "$last" "$x" --no-whole-file -I "$T/big.mod" "$T/d/big"
                cmp -s "$T/big.mod" "$T/d/big" || say "rsync $v: the delta is not the file"
                rm -f "$T/d/big"
            fi
        done
    done
}
