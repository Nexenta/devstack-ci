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

source $_source/env.sh
exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
cd $_base/tempest

for i in $(seq $_retries); do
	if tox -e ci -- $_regexp; then
		exit 0
	fi
done

exit 1
