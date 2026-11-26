# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/web.sh: the group web of tools/prog-bench.sh (sourced by it): the web
# servers of this tree, one worker on the last CPU, wrk (3 threads, 64 keep-alive
# connections, 8 seconds) on the others.
#
# nginx 1.31.10 (www/nginx-devel, the tarballs of its distinfo) with the patches of the port
# (files/patch-*; files/extra-patch-brotli-* and -zstd-* on the modules, as its post-patch),
# brotli (ngx_brotli a71f931) and zstd (nginx-zstd-module 0.1.3 and its static module) built
# in, zstd before brotli as the port; VOD (nginx-vod-module 1.11.2 of dio-az) a dynamic
# module; threads, file AIO, SSL, HTTP/2, realip, gzip_static, stub_status, mp4, flv, slice,
# secure_link, PCRE2; the libraries of the packages (PCRE2, brotli, zstd; the zlib and
# OpenSSL of the base system). A worker (worker_processes 1), the access log to a tmpfs with
# a buffer, sendfile, open_file_cache. The benchmarks (requests/s): a static file of 1 KB,
# one of 100 KB (sendfile), return 200, 100 KB of text compressed by gzip 5, brotli 5 and
# zstd 3 (each by its Accept-Encoding), the mp4 module (?start=30&end=30.5 of an MP4 of
# 120 s: a new moov), the VOD module (a segment of HLS of 4 s, and the playlist).
#
# Apache 2.4.71 (www/apache24, its distinfo): prefork (80 to 150 processes, all on the last
# CPU), the modules it needs here (mime, dir, log_config, headers, deflate, filter, unixd,
# authz_core) shared, APR, APR-util and PCRE2 of the packages, no SSL; the access log
# buffered (BufferedLogs) to a tmpfs. The benchmarks: a static file of 1 KB and one of 100 KB,
# 100 KB of text by mod_deflate 5.

g_progs="nginx apache"
ngv=1.31.10
NGF="$top/www/nginx-devel/files"

g_need() {
    need pcre2 brotli zstd apr expat
    if [ "$mode" = bench ]; then need wrk; fi
}

# web_fetch: the sources, unpacked once (the modules are compiled into the objs of each build)
web_fetch() {
    [ ! -d "$W/src/ngxmod" ] || return 0
    fetch "nginx-$ngv.tar.gz" a9b690957fca84abdae8a9b52d66b1bb459282d7f01fe4b94b498ed8e977bdb3 \
        "https://nginx.org/download/nginx-$ngv.tar.gz"
    fetch google-ngx_brotli-a71f931_GH0.tar.gz b3312a045d5303a40d02beb34711b8ca27f7b72d647e9ee2012a8eddd14d9b22 \
        https://codeload.github.com/google/ngx_brotli/tar.gz/a71f931
    fetch sysadmin-labs-nginx-zstd-module-0.1.3_GH0.tar.gz 9d379dfd10b2d12966930f6f254565ae2cef756a66fd3e0c17b73274827452fa \
        https://codeload.github.com/sysadmin-labs/nginx-zstd-module/tar.gz/0.1.3
    fetch dio-az-nginx-vod-module-v1.11.2_GH0.tar.gz a98bfafa04f631addd311e67bc05487b706af94c83b21b252d6cd32f69c30add \
        https://codeload.github.com/dio-az/nginx-vod-module/tar.gz/v1.11.2
    fetch httpd-2.4.71.tar.bz2 2bc5da5a33c247341de082717d4ebcb5cb49e8b73a05b7fddf7d5d6dc2f8de62 \
        https://archive.apache.org/dist/httpd/httpd-2.4.71.tar.bz2 https://dlcdn.apache.org/httpd/httpd-2.4.71.tar.bz2
    mkdir -p "$W/src/ngxmod"
    unpack google-ngx_brotli-a71f931_GH0.tar.gz "$W/src/ngxmod/brotli"
    unpack sysadmin-labs-nginx-zstd-module-0.1.3_GH0.tar.gz "$W/src/ngxmod/zstd"
    unpack dio-az-nginx-vod-module-v1.11.2_GH0.tar.gz "$W/src/ngxmod/vod"
    {
        for p in filter_config static-vary static-gzip slice-range yield; do
            (cd "$W/src/ngxmod/brotli" && patch -s -p0 < "$NGF/extra-patch-brotli-$p") || echo "FAIL: extra-patch-brotli-$p"
        done
        sed -i '' 's!%%PREFIX%%!/usr/local!g' "$W/src/ngxmod/brotli/filter/config"
        for p in config window accept-encoding header-next static continue slice-range yield; do
            (cd "$W/src/ngxmod/zstd" && patch -s -p0 < "$NGF/extra-patch-zstd-$p") || echo "FAIL: extra-patch-zstd-$p"
        done
    } > "$W/web-patch.log" 2>&1
    if grep -q FAIL "$W/web-patch.log"; then
        echo "the patches of the modules of www/nginx-devel: $(grep FAIL "$W/web-patch.log" | tr '\n' ' ')" >> "$W/fails/$group-notes.md"
    fi
}

g_build() {
    _v="$1"
    set_cc "$_v"
    web_fetch
    # nginx
    unpack "nginx-$ngv.tar.gz" "$W/src/nginx-$_v"
    _b="$W/b-nginx-$_v.log"
    : > "$_b"
    for p in "$NGF"/patch-*; do
        (cd "$W/src/nginx-$_v" && patch -s -p0 < "$p") >> "$_b" 2>&1 || echo "FAIL: ${p##*/}" >> "$_b"
    done
    if grep -q '^FAIL' "$_b"; then
        say "nginx $_v: patches of the port that do not apply: $(grep '^FAIL' "$_b" | tr '\n' ' ')"
        [ "$_v" != clang19 ] || echo "the patches of www/nginx-devel that do not apply to $ngv: $(grep '^FAIL' "$_b" | tr '\n' ' ')" >> "$W/fails/$group-notes.md"
    fi
    # nginx takes CFLAGS of the environment as they are (no -O of its own, auto/cc/conf) and no
    # LDFLAGS: those of the port in --with-ld-opt
    if (cd "$W/src/nginx-$_v" && ./configure --prefix="$W/nginx-$_v" \
        --with-cc-opt="-DNGX_HTTP_AZ_SERVER=0 -I/usr/local/include" --with-ld-opt="-L/usr/local/lib $LDFLAGS" \
        --with-compat --with-pcre --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module \
        --with-http_realip_module --with-http_gzip_static_module --with-http_stub_status_module \
        --with-http_mp4_module --with-http_flv_module --with-http_slice_module --with-http_secure_link_module \
        --add-module="$W/src/ngxmod/zstd" --add-module="$W/src/ngxmod/brotli" --add-module="$W/src/ngxmod/zstd/static" \
        --add-dynamic-module="$W/src/ngxmod/vod" && gmake -j"$ncpu" && gmake install) >> "$_b" 2>&1 &&
        [ -f "$W/nginx-$_v/modules/ngx_http_vod_module.so" ]; then
        bok nginx "$_v" "$W/nginx-$_v/sbin/nginx"
    else
        bno nginx "$_v" "$_b"
    fi
    # Apache
    unpack httpd-2.4.71.tar.bz2 "$W/src/httpd-$_v"
    _b="$W/b-apache-$_v.log"
    if (cd "$W/src/httpd-$_v" && ./configure --prefix="$W/apache-$_v" --with-mpm=prefork \
        --with-apr=/usr/local/bin/apr-1-config --with-apr-util=/usr/local/bin/apu-1-config \
        --with-pcre=/usr/local/bin/pcre2-config --enable-so --disable-ssl \
        --enable-mods-shared="mime dir log_config headers deflate filter unixd authz_core authz_host" &&
        gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        bok apache "$_v" "$W/apache-$_v/bin/httpd"
    else
        bno apache "$_v" "$_b"
    fi
}

g_keep() { echo "$W/nginx-$1 $W/apache-$1"; }

ngx_conf() {
    cat > "$W/ngx-$1.conf" << EOF
worker_processes 1;
error_log $W/ngx-error.log warn;
pid $W/ngx.pid;
load_module $W/nginx-$1/modules/ngx_http_vod_module.so;
events { worker_connections 4096; }
http {
    include $W/nginx-$1/conf/mime.types;
    default_type application/octet-stream;
    sendfile on;
    tcp_nopush on;
    keepalive_requests 1000000;
    keepalive_timeout 60;
    open_file_cache max=1000 inactive=60s;
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" \$status \$body_bytes_sent "\$http_referer" "\$http_user_agent"';
    access_log /mnt/pbrd/ngx-access.log main buffer=256k;
    gzip on; gzip_comp_level 5; gzip_min_length 256; gzip_types text/plain text/css application/javascript application/json;
    brotli on; brotli_comp_level 5; brotli_min_length 256; brotli_types text/plain text/css application/javascript application/json;
    zstd on; zstd_comp_level 3; zstd_min_length 256; zstd_types text/plain text/html text/css application/javascript application/json;
    vod_metadata_cache metadata_cache 64m;
    vod_segment_duration 4000;
    server {
        listen 127.0.0.1:8080 backlog=4096;
        server_name localhost;
        root $W/www;
        location = /r { return 200 "ok\n"; }
        location /hls/ { vod hls; vod_mode local; alias $W/www/; }
        location ~ \.mp4\$ { mp4; }
    }
}
EOF
}

apache_conf() {
    cat > "$W/httpd-$1.conf" << EOF
ServerRoot "$W/apache-$1"
Listen 127.0.0.1:8090
ServerName 127.0.0.1
LoadModule unixd_module modules/mod_unixd.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule mime_module modules/mod_mime.so
LoadModule dir_module modules/mod_dir.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule headers_module modules/mod_headers.so
LoadModule filter_module modules/mod_filter.so
LoadModule deflate_module modules/mod_deflate.so
User nobody
Group nobody
PidFile $W/httpd.pid
ErrorLog $W/httpd-error.log
LogLevel warn
DocumentRoot "$W/www"
<Directory "$W/www">
    Require all granted
</Directory>
TypesConfig conf/mime.types
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
CustomLog /mnt/pbrd/httpd-access.log combined
BufferedLogs On
EnableSendfile On
KeepAlive On
MaxKeepAliveRequests 0
KeepAliveTimeout 30
StartServers 80
MinSpareServers 80
MaxSpareServers 150
ServerLimit 150
MaxRequestWorkers 150
DeflateCompressionLevel 5
AddOutputFilterByType DEFLATE text/plain text/css application/javascript application/json
EOF
}

g_bench() {
    pbrd
    need ffmpeg
    mkdir -p "$W/www"
    chmod 755 "$W" "$W/www"
    head -c 1024 /etc/services > "$W/www/1k.html"
    head -c 102400 /dev/random > "$W/www/100k.bin"
    # 100 KB of text: C headers of the base system (as a page and its scripts compress)
    cat /usr/include/*.h | head -c 102400 > "$W/www/t100k.txt"
    ffmpeg -nostdin -loglevel error -f lavfi -i testsrc2=size=1280x720:rate=25 -f lavfi -i sine=frequency=440:sample_rate=48000 \
        -t 120 -c:v libx264 -preset veryfast -b:v 2M -g 50 -keyint_min 50 -sc_threshold 0 -pix_fmt yuv420p \
        -c:a aac -b:a 128k -movflags +faststart "$W/www/v.mp4" > "$W/ffmpeg-mp4.log" 2>&1 ||
        say "web: no MP4 ($(tail -n 3 "$W/ffmpeg-mp4.log" | tr '\n' ' '))"
    chmod 644 "$W/www"/*
    for v in $variants; do
        have nginx "$v" && ngx_conf "$v"
        have apache "$v" && apache_conf "$v"
    done
    for r in $(seq 1 "$rounds"); do
        say "web: round $r of $rounds"
        for v in $(order "$r"); do
            if have nginx "$v"; then
                rm -f /mnt/pbrd/ngx-access.log
                cpuset -l "$last" "$W/nginx-$v/sbin/nginx" -c "$W/ngx-$v.conf" > "$W/ngx-start.log" 2>&1
                if waitport 8080; then
                    u=http://127.0.0.1:8080
                    cpuset -l "$others" wrk -t 3 -c 64 -d 2s "$u/1k.html" > /dev/null 2>&1
                    wrkrate "$v" nginx "static 1 KB" "$u/1k.html"
                    wrkrate "$v" nginx "static 100 KB (sendfile)" "$u/100k.bin"
                    wrkrate "$v" nginx "return 200" "$u/r"
                    wrkrate "$v" nginx "gzip 5, 100 KB of text" "$u/t100k.txt" -H 'Accept-Encoding: gzip'
                    wrkrate "$v" nginx "brotli 5, 100 KB of text" "$u/t100k.txt" -H 'Accept-Encoding: br'
                    wrkrate "$v" nginx "zstd 3, 100 KB of text" "$u/t100k.txt" -H 'Accept-Encoding: zstd'
                    if [ -s "$W/www/v.mp4" ]; then
                        wrkrate "$v" nginx "mp4 module: ?start=30&end=30.5" "$u/v.mp4?start=30&end=30.5"
                        wrkrate "$v" nginx "vod: HLS segment of 4 s" "$u/hls/v.mp4/seg-3-v1-a1.ts"
                        wrkrate "$v" nginx "vod: HLS playlist" "$u/hls/v.mp4/index.m3u8"
                    fi
                else
                    say "nginx $v: did not start: $(tail -n 3 "$W/ngx-start.log" "$W/ngx-error.log" 2> /dev/null | tr '\n' ' ')"
                fi
                kill "$(cat "$W/ngx.pid" 2> /dev/null)" 2> /dev/null
                _n=0; while [ -f "$W/ngx.pid" ] && [ "$_n" -lt 100 ]; do sleep 0.1; _n=$((_n + 1)); done
            fi
            if have apache "$v"; then
                rm -f /mnt/pbrd/httpd-access.log
                cpuset -l "$last" "$W/apache-$v/bin/httpd" -f "$W/httpd-$v.conf" -k start > "$W/httpd-start.log" 2>&1
                if waitport 8090; then
                    sleep 2
                    u=http://127.0.0.1:8090
                    cpuset -l "$others" wrk -t 3 -c 64 -d 2s "$u/1k.html" > /dev/null 2>&1
                    wrkrate "$v" apache "static 1 KB" "$u/1k.html"
                    wrkrate "$v" apache "static 100 KB (sendfile)" "$u/100k.bin"
                    wrkrate "$v" apache "mod_deflate 5, 100 KB of text" "$u/t100k.txt" -H 'Accept-Encoding: gzip'
                else
                    say "apache $v: did not start: $(tail -n 3 "$W/httpd-start.log" "$W/httpd-error.log" 2> /dev/null | tr '\n' ' ')"
                fi
                "$W/apache-$v/bin/httpd" -f "$W/httpd-$v.conf" -k stop > /dev/null 2>&1
                _n=0; while [ -f "$W/httpd.pid" ] && [ "$_n" -lt 100 ]; do sleep 0.1; _n=$((_n + 1)); done
                sleep 1
            fi
        done
    done
}
