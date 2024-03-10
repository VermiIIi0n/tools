#!/usr/bin/env bash

# Available options: -dry

install_cosmocc() {
    local SDIR="$(realpath "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
    local ROOTDIR=$(dirname "$SDIR")
    local ENV_PATH="$ROOTDIR/env/cosmocc_env.sh"

    if [[ -f "$ENV_PATH" ]]; then
        source "$ENV_PATH"
    fi

    source "$SDIR/utils.sh"

    update_flags_from_arg "$@"

    pkg_install curl unzip

    local URL_PREFIX="https://github.com/jart/cosmopolitan"
    local LATEST_URL="$URL_PREFIX/releases/latest"
    local VERSION=$(curl -sSLI -o /dev/null -w %{url_effective} $LATEST_URL | rev | cut -d'/' -f1 | rev)
    if [[ -z "$VERSION" ]]; then
        error "Failed to get the latest version of cosmocc."
    fi
    echo "cosmocc Latest version: $VERSION"

    if [[ "$COSMOCC_VERSION" == "$VERSION" ]]; then
        echo "cosmocc is already the latest version."
        return 0
    fi

    local DOWNLOAD_URL="$URL_PREFIX/releases/download/$VERSION/cosmocc-$VERSION.zip"

    cd $ROOTDIR
    if [ -d "cosmocc" ]; then
        run rm -rf cosmocc
    fi
    run mkdir -p cosmocc
    run cd cosmocc
    run curl -LO $DOWNLOAD_URL
    run unzip "cosmocc-$VERSION.zip" > /dev/null || error "Failed to unzip cosmocc-$VERSION.zip"
    run rm "cosmocc-$VERSION.zip"

    cd $ROOTDIR
    run mkdir -p $ROOTDIR/env
    write_env $ENV_PATH "export PATH" "$ROOTDIR/cosmocc/bin:\$PATH"
    append_env $ENV_PATH "COSMOCC_VERSION" "$VERSION"
    export PATH="$ROOTDIR/cosmocc/bin:$PATH"
}

install_cosmocc "$@"
