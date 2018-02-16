#!/usr/bin/env bash

set -o nounset
set -o xtrace
set -o errexit
set -o pipefail
set -o noglob

unset PS4

typeset _pwd=$(pwd)
typeset _project=$(basename $_pwd)
typeset _script=$(readlink -f $0)
typeset _source=$(dirname $_script)

source $_source/env.sh

if [[ -f $_base/patches/$_project/$_branch.diff ]]; then
    patch -p1 < $_base/patches/$_project/$_branch.diff
fi

if [[ -d $_base/files/$_project ]]; then
    (cd $_base/files/$_project && tar cf - .) | tar pxvf -
fi
