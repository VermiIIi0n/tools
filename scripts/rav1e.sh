#!/usr/bin/env bash

# Available options: -dry, -cinstall

install_rav1e() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"

    export RUSTFLAGS+=" -C target-cpu=native"

    pkg_install git cmake curl
    cd $ROOTDIR
    git_clone_or_pull https://github.com/xiph/rav1e.git rav1e

    if ! command -v cargo &>/dev/null; then
        echo "Installing Rust..."
        run eval "curl --proto '=https' --tlsv1.3 -sSf https://sh.rustup.rs | sh -s -- -y"
        run rustup default stable
    fi

    cd rav1e
    echo "Building rav1e..."
    run cargo build --release

    run mkdir -p $ROOTDIR/env
    write_env "$ROOTDIR/env/rav1e_env.sh" "export PATH" "\$PATH:$ROOTDIR/rav1e/target/release/"

    if [[ "$@" == *"-cinstall"* ]]; then
        echo "Installing cargo-c..."
        local opts=("$(remove_flags_from_arg "$@")")
        opts=("${opts[@]/-cinstall}")
        run cargo install cargo-c
        run sudo -E $(which cargo) cinstall --release "${opts[@]}"
    fi
}

install_rav1e "$@"
