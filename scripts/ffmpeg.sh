#!/usr/bin/env bash

# Available options: -dry, -source-only, [all options for ffmpeg configure]

install_ffmpeg() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")
    local ENV_PATH="$ROOTDIR/env/ffmpeg_env.sh"
    local opts=($(remove_flags_from_arg "$@"))
    local source_only=false
    opts=(${opts[@]/-source-only})

    if [[ "$@" == *"-source-only"* ]]; then
        source_only=true
    fi

    if [[ -f "$ENV_PATH" ]]; then
        source "$ENV_PATH"
    fi

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"

    run cd "$SRCDIR"
    local SRCDIR="$ROOTDIR/ffmpeg_src"
    local TMPDIR="$ROOTDIR/ffmpeg_tmp"
    local BINDIR="$ROOTDIR/ffmpeg"
    run mkdir -p "$SRCDIR"
    run mkdir -p "$TMPDIR"
    run mkdir -p "$BINDIR"
    export PATH="$BINDIR:$PATH"
    export PKG_CONFIG_PATH="$TMPDIR/lib/pkgconfig"
    export CFLAGS="$CFLAGS -march=native"

    pkg_install \
        autoconf \
        automake \
        build-essential \
        cmake \
        git \
        libass-dev \
        libfreetype6-dev \
        libtool \
        libvorbis-dev \
        meson \
        ninja-build \
        pkg-config \
        texinfo \
        zlib1g-dev \
        libunistring-dev \
        libgnutls28-dev \
        # libmp3lame-dev \
        # yasm \
        # libxcb-xfixes0-dev \
        # libxcb-shm0-dev \
        # libxcb1-dev \
        # libvdpau-dev \
        # libva-dev \
        # libsdl2-dev \

    if [[ "${opts[@]}" != *"--enable-gpl"* ]]; then
        opts+=("--enable-gpl")
    fi

    if [[ "${opts[@]}" != *"--enable-nonfree"* ]]; then
        opts+=("--enable-nonfree")
    fi

    if [[ "${opts[@]}" != *"--enable-version3"* ]]; then
        opts+=("--enable-version3")
    fi

    if [[ $source_only == false ]]; then
        pkg_install nasm
    else
        run cd "$SRCDIR"
        local nasm_opts=(
            --prefix="$TMPDIR"
            --bindir="$BINDIR"
        )
        if [[ $DRY == true ]]; then
            nasm_opts+=(-dry)
        fi
        if [[ $QUIET == true ]]; then
            nasm_opts+=(-quiet)
        fi
        source "$SDIR/nasm.sh" "${nasm_opts[@]}" || exit 1
    fi

    if [[ $source_only == false ]]; then
        pkg_install yasm
    elif [[ -z $(pkg_check yasm) ]]; then
        run cd "$SRCDIR"
        if [[ ! -d "yasm-1.3.0" ]]; then
            run curl -LO https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
            run tar xzf yasm-1.3.0.tar.gz
            run rm yasm-1.3.0.tar.gz
        fi
        run cd yasm-1.3.0
        run ./configure --prefix="$TMPDIR" --bindir="$BINDIR"
        run make -j$(nproc)
        run sudo -E make install
    fi

    if [[ $source_only == false ]]; then
        pkg_install libmp3lame-dev
    else
        run cd "$SRCDIR"
        if [[ ! -d "lame-3.100" ]]; then
            run curl -LO https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
            run tar xzf lame-3.100.tar.gz
            run rm lame-3.100.tar.gz
        fi
        run cd lame-3.100
        run ./configure --prefix="$TMPDIR" --bindir="$BINDIR" --disable-shared --enable-nasm
        run make -j$(nproc)
        run sudo -E make install
    fi

    if [[ "${opts[@]}" == *"--enable-libx264"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libx264-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://code.videolan.org/videolan/x264.git x264
            run cd x264
            run ./configure --prefix="$TMPDIR" --bindir="$BINDIR" --enable-static
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libx265"* ]]; then
        pkg_install libnuma-dev
        if [[ "$source_only" == false ]]; then
            pkg_install libx265-dev
        else
            run cd "$SRCDIR"
            run curl -LO https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2
            run mv master.tar.bz2 x265.tar.bz2
            run tar -xjf x265.tar.bz2
            run rm x265.tar.bz2
            if [[ -d "x265" ]]; then
                run rm -rf x265
            fi
            run mv multicoreware* x265
            local march=
            if [[ $(uname -m) == "arm"* ]]; then
                march="arm-linux"
            else
                march="linux"
            fi
            run cd "x265/build/$march"
            run cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TMPDIR" -DENABLE_SHARED=off ../../source
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libvpx"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libvpx-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://chromium.googlesource.com/webm/libvpx.git libvpx
            run cd libvpx
            run ./configure --prefix="$TMPDIR" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libfdk-aac"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libfdk-aac-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://github.com/mstorsjo/fdk-aac fdk-aac
            run cd fdk-aac
            run autoreconf -fiv
            run ./configure --prefix="$TMPDIR" --disable-shared
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libopus"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libopus-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://github.com/xiph/opus.git opus
            run cd opus
            run ./autogen.sh
            run ./configure --prefix="$TMPDIR" --disable-shared
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libaom"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libaom-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://aomedia.googlesource.com/aom aom
            local aom_tmpdir="$TMPDIR/aom"
            run mkdir -p "$aom_tmpdir"
            run cd "$aom_tmpdir"
            run cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TMPDIR" -DENABLE_SHARED=off -DENABLE_NASM=on "$SRCDIR/aom"
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libsvtav1"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libsvtav1-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://gitlab.com/AOMediaCodec/SVT-AV1.git svt-av1
            local svtav1_tmpdir="$TMPDIR/svt-av1"
            run mkdir -p "$svtav1_tmpdir"
            run cd "$svtav1_tmpdir"
            run cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TMPDIR" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF "$SRCDIR/svt-av1"
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libdav1d"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libdav1d-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://code.videolan.org/videolan/dav1d.git dav1d
            local dav1d_tmpdir="$TMPDIR/dav1d"
            run mkdir -p "$dav1d_tmpdir"
            run cd "$dav1d_tmpdir"
            run meson setup -Denable_tools=false -Denable_tests=false --default-library=static "$SRCDIR/dav1d" --prefix "$TMPDIR" --libdir="$TMPDIR/lib"
            run ninja
            run sudo -E ninja install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libvmaf"* ]]; then
        run cd "$SRCDIR"
        git_clone_or_pull https://github.com/Netflix/vmaf.git vmaf
        local vmaf_tmpdir="$TMPDIR/vmaf"
        run mkdir -p "$vmaf_tmpdir"
        run cd "$vmaf_tmpdir"
        run meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static "$SRCDIR/vmaf/libvmaf" --prefix "$TMPDIR" --bindir="$BINDIR" --libdir="$TMPDIR/lib"
        run ninja
        run sudo -E ninja install
    fi

    if [[ "${opts[@]}" == *"--enable-librav1e"* ]]; then
        run cd "$SRCDIR"
        local rav1e_opts=("--prefix=$TMPDIR")
        if [[ $DRY == true ]]; then
            rav1e_opts+=("-dry")
        fi
        if [[ $QUIET == true ]]; then
            rav1e_opts+=("-quiet")
        fi
        source "$SDIR/rav1e.sh" -cinstall "${rav1e_opts[@]}"  || exit 1
    fi

    if [[ "${opts[@]}" == *"--enable-libbluray"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libbluray-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://code.videolan.org/videolan/libbluray.git libbluray
            run cd libbluray
            run ./bootstrap
            run ./configure --prefix="$TMPDIR" --disable-shared --disable-bdjava-jar --disable-doxygen-doc
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libsrt"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libsrt-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://github.com/Haivision/srt.git srt
            local srt_tmpdir="$TMPDIR/srt"
            run mkdir -p "$srt_tmpdir"
            run cd "$srt_tmpdir"
            run cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$TMPDIR" -DENABLE_C_DEPS=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=ON "$SRCDIR/srt"
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libplacebo"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libplacebo-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://code.videolan.org/videolan/libplacebo.git libplacebo
            local libplacebo_tmpdir="$TMPDIR/libplacebo"
            run mkdir -p "$libplacebo_tmpdir"
            run cd "$libplacebo_tmpdir"
            run meson setup --buildtype=release --default-library=static "$SRCDIR/libplacebo" --prefix "$TMPDIR" --libdir="$TMPDIR/lib"
            run ninja
            run sudo -E ninja install
        fi
    fi

    run cd "$SRCDIR"
    run curl -LO https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
    run tar -xjf ffmpeg-snapshot.tar.bz2
    run rm ffmpeg-snapshot.tar.bz2
    run cd ffmpeg
    run ./configure \
        --prefix="$TMPDIR" \
        --bindir="$BINDIR" \
        --pkg-config-flags="--static" \
        --extra-cflags="-I$TMPDIR/include" \
        --extra-ldflags="-L$TMPDIR/lib" \
        --extra-libs="-lpthread -lm" \
        --ld="g++" \
        --enable-gnutls \
        --enable-libass \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libvorbis \
        "${opts[@]}"
    run make -j$(nproc)
    run sudo -E make install
    run hash -r

    correct_ownership "$TMPDIR" $(who_owns "$(dirname "$TMPDIR")")
    correct_ownership "$BINDIR" $(who_owns "$(dirname "$BINDIR")")
    run rm -rf "$TMPDIR"

    cd $ROOTDIR
    run mkdir -p $ROOTDIR/env
    write_env $ENV_PATH "export PATH" "$ROOTDIR/ffmpeg:\$PATH"
    append_env $ENV_PATH "FFMPEG_VERSION" "$VERSION"
    export PATH="$ROOTDIR/ffmpeg:$PATH"
}

install_ffmpeg "$@"
