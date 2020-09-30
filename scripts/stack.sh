#!/usr/bin/env bash

set -o nounset
set -o xtrace
set -o errexit
set -o pipefail
set -o noglob

typeset _pwd=$(pwd)
typeset _project=$(basename $_pwd)
typeset _script=$(readlink -f $0)
typeset _ident=$(basename -s .sh $_script)
typeset _source=$(dirname $_script)
typeset _unit _log

source $_source/env.sh

export UPPER_CONSTRAINTS_FILE="$_base/requirements/upper-constraints.txt"

cd $_base/devstack

exec $_base/devstack/stack.sh
