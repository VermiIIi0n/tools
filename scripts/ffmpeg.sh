#!/usr/bin/env bash

# Available options: -dry, -source-only, [all options for ffmpeg configure]

install_ffmpeg() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")
    local ENV_PATH="$ROOTDIR/env/ffmpeg_env.sh"
    local opts=("$(remove_flags_from_arg "$@")")
    local source_only=false
    opts=("${opts[@]/-source-only}")

    if [[ "$@" == *"-source-only"* ]]; then
        source_only=true
    fi

    if [[ -f "$ENV_PATH" ]]; then
        source "$ENV_PATH"
    fi

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"

    local SRCDIR="$ROOTDIR/ffmpeg_src"
    local TMPDIR="$ROOTDIR/ffmpeg_tmp"
    local BINDIR="$ROOTDIR/ffmpeg"
    run mkdir -p "$SRCDIR"
    run mkdir -p "$TMPDIR"
    run mkdir -p "$BINDIR"
    run cd "$SRCDIR"
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
        libmp3lame-dev \
        libtool \
        libvorbis-dev \
        meson \
        ninja-build \
        pkg-config \
        texinfo \
        yasm \
        zlib1g-dev \
        libunistring-dev \
        libgnutls28-dev \
        # libxcb-xfixes0-dev \
        # libxcb-shm0-dev \
        # libxcb1-dev \
        # libvdpau-dev \
        # libva-dev \
        # libsdl2-dev \

    if [[ "$source_only" == false ]]; then
        pkg_install nasm
    else
        run cd "$SRCDIR"
        local page=$(curl -s https://nasm.us/)
        local re="www\.nasm\.us\/pub\/nasm\/releasebuilds\/([0-9]+\.[0-9]+\.[0-9]+)"
        if [[ $page =~ $re ]]; then
            local version="${BASH_REMATCH[1]}"
        else
            echo "Failed to get the latest version of nasm. Default to 2.16.01" 1>&2
            version="2.16.01"
            exit 1
        fi
        echo "nasm Latest version: $version"
        local url="https://www.nasm.us/pub/nasm/releasebuilds/$version/nasm-$version.tar.bz2"
        if [[ -d "nasm-$version" ]]; then
            echo "nasm is already the latest version."
        else
            run curl -LO $url
            run tar -xjf "nasm-$version.tar.bz2"
            run rm "nasm-$version.tar.bz2"
            run cd "nasm-$version"
            run ./autogen.sh
            run ./configure --prefix="$TMPDIR" --bindir="$BINDIR"
            run make -j$(nproc)
            run sudo -E make install
        fi
    fi

    if [[ "${opts[@]}" == *"--enable-libx264"* ]]; then
        if [[ "$source_only" == false ]]; then
            pkg_install libx264-dev
        else
            run cd "$SRCDIR"
            git_clone_or_pull https://code.videolan.org/videolan/x264.git x264
            run cd x264
            run ./configure --prefix="$TMPDIR" --bindir="$BINDIR" --enable-static --enable-pic
            run make -j$(nproc)
            run sudo -E make install
        fi
        if [[ "${opts[@]}" != *"--enable-gpl"* ]]; then
            opts+=("--enable-gpl")
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
        if [[ "${opts[@]}" != *"--enable-gpl"* ]]; then
            opts+=("--enable-gpl")
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
        if [[ "${opts[@]}" == *"--enable-gpl"* ]]; then
            if [[ "${opts[@]}" != *"--enable-nonfree"* ]]; then
                opts+=("--enable-nonfree")
            fi
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
        if [[ "${opts[@]}" != *"--ld='g++'"* ]]; then
            opts+=("--ld=g++")
            # https://github.com/Netflix/vmaf/issues/788
        fi
        local vmaf_tmpdir="$TMPDIR/vmaf"
        run mkdir -p "$vmaf_tmpdir"
        run cd "$vmaf_tmpdir"
        run meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static "$SRCDIR/vmaf/libvmaf" --prefix "$TMPDIR" --bindir="$BINDIR" --libdir="$TMPDIR/lib"
        run ninja
        run sudo -E ninja install
    fi

    if [[ "${opts[@]}" == *"--enable-librav1e"* ]]; then
        if [[ $DRY == true ]]; then
            bash "$SDIR/rav1e.sh" -dry -cinstall \
                --prefix=$TMPDIR \
                --libdir=$TMPDIR/lib \
                --includedir=$TMPDIR/include
        else
            bash "$SDIR/rav1e.sh" -cinstall \
                --prefix=$TMPDIR \
                --libdir=$TMPDIR/lib \
                --includedir=$TMPDIR/include
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
        --extra-cflags="-I$TMPDIR/include -march=native" \
        --extra-ldflags="-L$TMPDIR/lib" \
        --extra-libs="-lpthread -lm" \
        --enable-gnutls \
        --enable-libass \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libvorbis \
        "${opts[@]}"
    run make -j$(nproc)
    run sudo -E make install
    run hash -r

    local ownership=$(who_owns "$BINDIR")
    if [[ $(whoami) != $(user_owns "$BINDIR") ]]; then
        run sudo -E chown -R $ownership "$BINDIR"
        run sudo -E chown -R $ownership "$TMPDIR"
    fi

    cd $ROOTDIR
    run mkdir -p $ROOTDIR/env
    write_env $ENV_PATH "export PATH" "\$PATH:$ROOTDIR/ffmpeg"
    append_env $ENV_PATH "FFMPEG_VERSION" "$VERSION"
}

install_ffmpeg "$@"
