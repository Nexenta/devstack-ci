#!/usr/bin/env bash

set -o nounset
set -o xtrace
set -o errexit
set -o pipefail
set -o noglob

typeset _pwd=$(pwd)
typeset _project=$(basename $_pwd)
typeset _script=$(readlink -f $0)
typeset _source=$(dirname $_script)
typeset _error

source $_source/env.sh

cd $_base/tempest
set +o errexit
ostestr --serial --regex $_regexp
_error=$?

if [[ ! -d .testrepository ]]; then
	if [[ -d .stestr ]]; then
		ln -s .stestr .testrepository
	else
		echo "Directory .stestr not found"
	fi
fi

testr last --subunit >report.sub
cat report.sub | subunit-1to2 | subunit-trace >report.txt
subunit2html report.sub report.html

df -h >$_base/logs/df.log 2>&1
mount >$_base/logs/mount.log 2>&1

exit $_error
