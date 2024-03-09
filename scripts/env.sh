#!/bin/sh

import_envs() {
    local SDIR=
    local SPATH=
    if test -n "$BASH" ; then SPATH="$BASH_SOURCE"
    elif test -n "$TMOUT"; then SPATH="${.sh.file}"
    elif test -n "$ZSH_NAME" ; then SPATH="${(%):-%x}"
    elif test ${0##*/} = dash; then x=$(lsof -p $$ -Fn0 | tail -1); SPATH=${x#n}
    else SPATH="$0"
    fi

    SDIR="$(dirname "$SPATH")"
    local ROOTDIR=$(dirname "$SDIR")

    for f in "$ROOTDIR/env/"*.sh; do
        if [ -f "$f" ]; then
            source "$f"
        fi
    done
}

import_envs "$@" 2>/dev/null
