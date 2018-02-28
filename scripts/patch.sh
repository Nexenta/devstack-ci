#!/usr/bin/env bash

unset PS4

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

source $_source/env.sh

exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1

if [[ -f $_base/$_ci/patches/$_project/$_branch.diff ]]; then
    patch -p1 < $_base/$_ci/patches/$_project/$_branch.diff
fi

if [[ -d $_base/$_ci/files/$_project ]]; then
    (cd $_base/$_ci/files/$_project && tar cf - .) | tar pxvf -
fi

for item in branch show status diff; do
	git $item | tee -a $LOGDIR/git.$item.$_project.log
done
