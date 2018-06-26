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

if [[ -t 1 ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
else
	exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
fi

openstack --help --debug >$_base/$_logs/openstack.log 2>&1

if grep -q Traceback $_base/$_logs/openstack.log; then
	exit 1
fi

if grep -q Uninstalling $_base/$_logs/stack.log; then
	echo 'Warning: devstack conflicts:'
	grep Uninstalling $_base/$_logs/stack.log
fi

cd $_base/cinder

if grep -q genopts tox.ini; then
	tox -e genopts
fi

tox -e pep8

cd $_base/tempest

for i in $(seq $_retries); do
	if tox -e ci -- $_regexp; then
		exit 0
	fi
done

exit 1
