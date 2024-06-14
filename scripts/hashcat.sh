#!/usr/bin/env bash

# Available options: -dry

install_hashcat() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"
    run cd "$ROOTDIR"
    local opts=($(remove_flags_from_arg "$@"))
    local PREFIX="/usr/local"
    update_var_from_arg PREFIX --prefix "${opts[@]}"
    PREFIX="$(realpath "$PREFIX")"

    pkg_install git cmake
    git_clone_or_pull https://github.com/hashcat/hashcat.git hashcat

    run cd hashcat

    echo "Building hashcat..."
    run make -j$(nproc)
    run sudo -E make install
    run mkdir -p $ROOTDIR/env
    # write_env "$ROOTDIR/env/hashcat_env.sh" "export PATH" "$BINDIR:\$PATH"
    export PATH="$BINDIR:$PATH"
}

install_hashcat "$@"
