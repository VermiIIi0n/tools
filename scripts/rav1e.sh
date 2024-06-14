#!/usr/bin/env bash

# Available options: -dry, -cinstall

install_rav1e() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"
    run cd "$ROOTDIR"
    local opts=($(remove_flags_from_arg "$@"))
    local PREFIX="/usr/local"
    update_var_from_arg PREFIX --prefix "${opts[@]}"
    PREFIX="$(realpath "$PREFIX")"
    local TGTDIR="$ROOTDIR/rav1e/target"
    update_var_from_arg TGTDIR --target-dir "${opts[@]}"
    local BINDIR="$TGTDIR/release"

    export RUSTFLAGS+=" -C target-cpu=native"

    pkg_install git cmake curl
    git_clone_or_pull https://github.com/xiph/rav1e.git rav1e

    if ! command -v cargo &>/dev/null; then
        echo "Installing Rust..."
        PATH="$HOME/.cargo/bin:$PATH"
        run eval "curl --proto '=https' --tlsv1.3 -sSf https://sh.rustup.rs | sh -s -- -y"
        run rustup default stable
    fi

    # if command nasm is not found, install nasm
    if [[ ! -x "$(command -v nasm)" ]]; then
        run cd "$SRCDIR"
        local nasm_opts=()
        if [[ $DRY == true ]]; then
            nasm_opts+=(-dry)
        fi
        if [[ $QUIET == true ]]; then
            nasm_opts+=(-quiet)
        fi
        source "$SDIR/nasm.sh" "${nasm_opts[@]}" || exit 1
    fi

    run cd rav1e
    if [[ "$@" == *"-cinstall"* ]]; then
        echo "Installing cargo-c..."
        opts=("${opts[@]/-cinstall/}")
        run cargo install cargo-c
        echo "Building rav1e by cinstall..."
        run sudo -E PATH="$PATH" "$(which cargo)" cinstall --release --prefix="$PREFIX" "${opts[@]}"
        correct_ownership "$PREFIX/include" $(who_owns "$PREFIX")
        correct_ownership "$PREFIX/lib" $(who_owns "$PREFIX")
        echo "Installed rav1e library to $PREFIX"
    else
        echo "Building rav1e..."
        run sudo -E PATH="$PATH" "$(which cargo)" build --release --target-dir="$TGTDIR" "${opts[@]}"
        correct_ownership "$TGTDIR" $(who_owns "$(dirname "$TGTDIR")")
        correct_ownership "$BINDIR" $(who_owns "$(dirname "$BINDIR")")
        run mkdir -p $ROOTDIR/env
        write_env "$ROOTDIR/env/rav1e_env.sh" "export PATH" "$BINDIR:\$PATH"
        export PATH="$BINDIR:$PATH"
    fi
}

install_rav1e "$@"
