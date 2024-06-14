#!/usr/bin/env bash

# Available options: -dry

install_aria2() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"
    run cd "$ROOTDIR"
    local opts=($(remove_flags_from_arg "$@"))
    local PREFIX="/usr/local"
    update_var_from_arg PREFIX --prefix "${opts[@]}"
    PREFIX="$(realpath "$PREFIX")"

    pkg_install git cmake curl libxml2-dev libcppunit-dev autoconf automake autotools-dev autopoint libtool
    git_clone_or_pull https://github.com/VermiIIi0n/aria2-unlimited.git aria2

    run cd aria2

    echo "Building aria2..."
    run autoreconf -i
    run ./configure --prefix="$PREFIX" "$@"
    run make -j$(nproc)
    run sudo -E make install
    run mkdir -p $ROOTDIR/env
    # write_env "$ROOTDIR/env/aria2_env.sh" "export PATH" "$BINDIR:\$PATH"
    export PATH="$BINDIR:$PATH"
}

install_aria2 "$@"
