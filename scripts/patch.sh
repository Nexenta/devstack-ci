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

if [[ ! -d $_base/$_logs ]]; then
	mkdir -p $_base/$_logs
fi

if [[ -t 1 ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
else
	exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
fi

if [[ -f $_base/$_ci/patches/$_project/$_branch.diff ]]; then
	patch -p1 < $_base/$_ci/patches/$_project/$_branch.diff
fi

if [[ -d $_base/$_ci/files/$_project ]]; then
	tar -cf - -C $_base/$_ci/files/$_project . | tar -xpvf -
fi

for item in branch show status diff; do
	git $item | tee -a $_base/$_logs/git.$item.$_project.log
done
