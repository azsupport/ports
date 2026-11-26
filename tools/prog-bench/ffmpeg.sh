# SPDX-License-Identifier: BSD-2-Clause
# tools/prog-bench/ffmpeg.sh: the group ffmpeg of tools/prog-bench.sh (sourced by it).
# FFmpeg 9.1 (multimedia/ffmpeg, the tarball of files/ffmpeg.conf) as tools/ffmpeg-build.sh
# builds it: static, --enable-pic, LTO (the ar, ranlib and nm of the compiler: those of the
# base system, of llvm23, gcc-ar16), --disable-everything and the components of
# files/ffmpeg.conf (the decoders h264, hevc, vp9, vp8, libdav1d, aac..., the encoders
# libx264, libsvtav1, aac, mjpeg, png, libwebp, the demuxers mov, matroska, mpegts, image2,
# the muxers mp4, mov, matroska, webm, image2, null, every filter, lavfi), with the encoders
# wrapped_avframe and pcm_s16le of -f null more, without libjpeg (our encoder on mozjpeg:
# the time of a JPEG of it is that of the library) and fdk-aac; x264, dav1d, SVT-AV1 and libwebp
# the packages of FreeBSD (in our package, those of azsupport: the libraries, not ffmpeg).
# The inputs: 1080p of testsrc2 encoded by the ffmpeg of the packages (H.264 by x264; HEVC,
# VP9 and AV1 where it has their encoders). The benchmarks, one thread (-threads 1), timed:
# decoding of H.264, HEVC, VP9 (the decoders of FFmpeg) and AV1 (libdav1d), x264 at 720p
# (decoding, scaling and the encoder of the library), scaling 1080p to 720p (bicubic and
# lanczos, swscale), unsharp, AAC encoding, 10 screenshots (seek, decode, scale, mjpeg: as
# the video sites take them), PNG frames, a remux to MP4 with faststart.

g_progs="ffmpeg"
ffv=9.1

g_need() {
    need nasm x264 dav1d svt-av1 webp
}

g_build() {
    _v="$1"
    set_cc "$_v"
    fetch "ffmpeg-$ffv.tar.xz" 1a4d394ae63d190a526cd052eb4415c156b5c5e2df37efab41a7de0b8fde2433 \
        "https://ffmpeg.org/releases/ffmpeg-$ffv.tar.xz"
    unpack "ffmpeg-$ffv.tar.xz" "$W/src/ffmpeg-$_v"
    case "$_v" in
    clang19)
        if ar --version 2> /dev/null | grep -q LLVM; then _ar=ar _ranlib=ranlib _nm=nm; else _ar=llvm-ar _ranlib=llvm-ranlib _nm=llvm-nm; fi ;;
    clang23) _ar="$LLVM23/llvm-ar" _ranlib="$LLVM23/llvm-ranlib" _nm="$LLVM23/llvm-nm" ;;
    gcc16) _ar=gcc-ar16 _ranlib=gcc-ranlib16 _nm=gcc-nm16 ;;
    esac
    _b="$W/b-ffmpeg-$_v.log"
    # CC and CXX of the variant as --cc and --cxx (its flags with them: configure takes the
    # first word of CC for the compiler), CFLAGS and LDFLAGS of the environment
    # shellcheck disable=SC2086
    if (cd "$W/src/ffmpeg-$_v" && ./configure --prefix="$W/ffmpeg-$_v" --cc="$CC" --cxx="$CXX" \
        --ar="$_ar" --ranlib="$_ranlib" --nm="$_nm -g" --pkg-config=pkgconf \
        --enable-gpl --enable-static --disable-shared --enable-pic --enable-lto \
        --disable-autodetect --enable-pthreads --enable-zlib --disable-iconv --disable-network \
        --disable-doc --disable-ffplay --disable-everything \
        --enable-libx264 --enable-libdav1d --enable-libsvtav1 --enable-libwebp \
        --enable-protocol=file,pipe \
        --enable-demuxer=mov,matroska,concat,mpegts,image2,image_jpeg_pipe,image_png_pipe,image_webp_pipe \
        --enable-indev=lavfi \
        --enable-parser=h264,hevc,av1,vp9,vp8,aac,mpegaudio,opus,vorbis,ac3,mjpeg,png,webp \
        --enable-decoder=h264,hevc,libdav1d,vp9,vp8,aac,mp3float,opus,vorbis,ac3,eac3,mjpeg,png,webp \
        --enable-decoder=pcm_u8,pcm_s16le,pcm_s32le,pcm_f32le,pcm_f64le,wrapped_avframe \
        --enable-bsf=h264_mp4toannexb \
        --enable-encoder=libx264,libsvtav1,aac,mjpeg,png,libwebp,wrapped_avframe,pcm_s16le \
        --enable-muxer=mp4,mov,matroska,webm,avif,image2,mjpeg,webp,null \
        --enable-filters && gmake -j"$ncpu" && gmake install) > "$_b" 2>&1; then
        # the program installed is stripped (no .comment): the compilers of ffmpeg_g
        bok ffmpeg "$_v" "$W/src/ffmpeg-$_v/ffmpeg_g"
    else
        bno ffmpeg "$_v" "$_b"
    fi
    rm -rf "$W/src/ffmpeg-$_v"
}

g_keep() { echo "$W/ffmpeg-$1"; }

# ff <variant> <bench> <arg>...: the ffmpeg of the variant, one thread, on the last CPU, timed
ff() {
    _fv="$1" _fb="$2"; shift 2
    timed "$_fv" ffmpeg "$_fb" cpuset -l "$last" "$W/ffmpeg-$_fv/bin/ffmpeg" -nostdin -hide_banner -loglevel error -y "$@"
}

g_bench() {
    pbrd
    need ffmpeg
    I=/mnt/pbrd
    src="testsrc2=size=1920x1080:rate=25"
    ffmpeg -nostdin -loglevel error -y -f lavfi -i "$src" -f lavfi -i sine=frequency=440:sample_rate=48000 -t 60 \
        -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart "$I/h264.mp4" > "$W/ffin.log" 2>&1 ||
        die "ffmpeg of the packages: no input H.264 ($(tail -n 3 "$W/ffin.log" | tr '\n' ' '))"
    ins="h264"
    ffmpeg -nostdin -loglevel error -y -f lavfi -i "$src" -t 30 -c:v libx265 -preset fast -crf 26 -pix_fmt yuv420p "$I/hevc.mp4" >> "$W/ffin.log" 2>&1 && ins="$ins hevc"
    ffmpeg -nostdin -loglevel error -y -f lavfi -i "$src" -t 30 -c:v libvpx-vp9 -deadline realtime -cpu-used 8 -b:v 3M -pix_fmt yuv420p "$I/vp9.webm" >> "$W/ffin.log" 2>&1 && ins="$ins vp9"
    { ffmpeg -nostdin -loglevel error -y -f lavfi -i "$src" -t 30 -c:v libsvtav1 -preset 10 -crf 35 -pix_fmt yuv420p "$I/av1.mkv" ||
        ffmpeg -nostdin -loglevel error -y -f lavfi -i "$src" -t 30 -c:v libaom-av1 -cpu-used 8 -crf 35 -pix_fmt yuv420p "$I/av1.mkv"; } >> "$W/ffin.log" 2>&1 && ins="$ins av1"
    say "ffmpeg: the inputs: $ins"
    case " $ins " in *" hevc "*) ;; *) echo "no input HEVC (the ffmpeg of the packages has no libx265?): $(grep -i -m 1 -E 'unknown encoder|libx265' "$W/ffin.log")" >> "$W/fails/$group-notes.md" ;; esac
    for r in $(seq 1 "$rounds"); do
        say "ffmpeg: round $r of $rounds"
        for v in $(order "$r"); do
            have ffmpeg "$v" || continue
            ff "$v" "decode H.264 1080p (60 s)" -threads 1 -i "$I/h264.mp4" -an -f null -
            case " $ins " in *" hevc "*) ff "$v" "decode HEVC 1080p (30 s)" -threads 1 -i "$I/hevc.mp4" -an -f null - ;; esac
            case " $ins " in *" vp9 "*) ff "$v" "decode VP9 1080p (30 s)" -threads 1 -i "$I/vp9.webm" -an -f null - ;; esac
            case " $ins " in *" av1 "*) ff "$v" "decode AV1 1080p, libdav1d (30 s)" -threads 1 -c:v libdav1d -i "$I/av1.mkv" -an -f null - ;; esac
            ff "$v" "x264 medium 720p (10 s: decode, scale, the encoder of x264)" -threads 1 -i "$I/h264.mp4" -t 10 -an \
                -vf scale=1280:720 -c:v libx264 -preset medium -crf 23 -x264-params threads=1 -f null -
            ff "$v" "scale 1080p to 720p, bicubic (testsrc2, 10 s)" -f lavfi -i "$src:duration=10" -vf scale=1280:720:flags=bicubic -f null -
            ff "$v" "scale 1080p to 720p, lanczos (testsrc2, 10 s)" -f lavfi -i "$src:duration=10" -vf scale=1280:720:flags=lanczos -f null -
            ff "$v" "unsharp 5:5:1.0 1080p (testsrc2, 5 s)" -f lavfi -i "$src:duration=5" -vf unsharp=5:5:1.0 -f null -
            ff "$v" "AAC encode, 120 s stereo" -f lavfi -i "aevalsrc=sin(440*2*PI*t)|sin(660*2*PI*t):s=48000:d=120" -c:a aac -b:a 128k -f null -
            timed "$v" ffmpeg "10 screenshots: seek, decode, scale to 320, mjpeg" sh -c '
                for t in 1 3 5 7 9 11 13 15 17 19; do
                    cpuset -l "$1" "$2" -nostdin -loglevel error -y -threads 1 -ss "$t" -i "$3" -frames:v 1 -vf scale=320:-2 -q:v 3 "$4/shot.jpg" || exit 1
                done' sh "$last" "$W/ffmpeg-$v/bin/ffmpeg" "$I/h264.mp4" "$I"
            ff "$v" "PNG frames, 640 wide (2 s)" -threads 1 -i "$I/h264.mp4" -t 2 -an -vf scale=640:-2 -c:v png -f image2 "$I/f%03d.png"
            timed "$v" ffmpeg "remux to MP4 with faststart, 60 s of video, 10 times" sh -c '
                for i in 1 2 3 4 5 6 7 8 9 10; do cpuset -l "$1" "$2" -nostdin -loglevel error -y -i "$3" -c copy -movflags +faststart "$4" || exit 1; done' \
                sh "$last" "$W/ffmpeg-$v/bin/ffmpeg" "$I/h264.mp4" "$I/remux.mp4"
        done
    done
}
