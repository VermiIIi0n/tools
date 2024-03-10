#!/usr/bin/env bash

# Available options: -dry, [all options for nasm configure]

install_nasm() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")
    local BINDIR="$ROOTDIR/nasm"
    local ENV_PATH="$ROOTDIR/env/nasm_env.sh"

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"

    run cd "$ROOTDIR"
    update_var_from_arg BINDIR --bindir "$@"
    run mkdir -p "$BINDIR"
    run echo "Installing nasm to $BINDIR"

    pkg_install cmake curl autoconf automake libtool

    local page=$(curl -s https://nasm.us/)
    local re="www\.nasm\.us\/pub\/nasm\/releasebuilds\/([0-9]+\.[0-9]+\.[0-9]+)"
    if [[ $page =~ $re ]]; then
        local version="${BASH_REMATCH[1]}"
    else
        echo "Failed to get the latest version of nasm. Default to 2.16.01" 1>&2
        version="2.16.01"
    fi
    echo "nasm latest version: $version"
    local url="https://www.nasm.us/pub/nasm/releasebuilds/$version/nasm-$version.tar.bz2"

    local SRCDIR="$ROOTDIR/nasm-$version"
    if [[ ! -d "$SRCDIR" ]]; then
        run curl -LO $url
        run tar -xjf "nasm-$version.tar.bz2"
        run rm "nasm-$version.tar.bz2"
    fi
    run cd "$SRCDIR"
    run ./autogen.sh
    run ./configure --bindir="$BINDIR" "$@"
    run make -j$(nproc)
    run sudo -E make install
    run cd "$ROOTDIR"
    run rm -rf "$SRCDIR"
    correct_ownership "$BINDIR" $(who_owns "$(dirname "$BINDIR")")

    run mkdir -p "$(dirname "$ENV_PATH")"
    write_env "$ENV_PATH" "export PATH" "$BINDIR:\$PATH"
    export PATH="$BINDIR:$PATH"
}

install_nasm "$@"
