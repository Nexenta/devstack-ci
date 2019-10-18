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
typeset _unit _index
typeset -a _versions

source $_source/env.sh

if [[ -t 1 ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
else
	exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
fi

if ! openstack --help --debug >$_base/$_logs/openstack.log 2>&1; then
	echo 'Error: openstack command failed:'
	cat $_base/$_logs/openstack.log
	exit 1
fi

if grep -q 'Traceback' $_base/$_logs/openstack.log; then
	echo 'Error: openstack command failed:'
	grep 'Traceback' $_base/$_logs/openstack.log
	exit 1
fi

if grep -q 'which is incompatible' $_base/$_logs/stack.log; then
	echo 'Warning: devstack incompatible packages:'
	grep 'which is incompatible' $_base/$_logs/stack.log
fi

if grep -q 'Uninstalling' $_base/$_logs/stack.log; then
	echo 'Warning: devstack conflicts:'
	grep 'Uninstalling' $_base/$_logs/stack.log
fi

case "$_backend" in 
ns4_manila|ns5_manila)
	cd $_base/manila
	;;
ns4_iscsi|ns4_nfs|ns5_iscsi|ns5_nfs|ned_iscsi)
	cd $_base/cinder
	;;
*)
	echo "Unknown CI backend: $_backend"
	exit 1
	;;
esac

if grep -q genopts tox.ini; then
	tox -e genopts
fi

tox -e pep8 || true

case "$_backend" in
ns5_iscsi|ns5_nfs)
	_unit='nexenta5'
	;;
ns4_iscsi|ns4_nfs)
	_unit=''
	;;
ns5_manila)
	_unit='nexenta.ns5'
	;;
ns4_manila)
	_unit='nexenta.ns4'
	;;
*)
	_unit=''
	;;
esac

case "$_branch" in
master|stein|train|rocky)
	_versions=(py27 py36 py37)
	;;
queens|pike|ocata|newton)
	_versions=(py27)
	;;
*)
	_versions=()
	;;
esac


if [[ -n "$_unit" ]]; then
	tox -e cover -- $_unit || true
	for _index in "${!_versions[@]}"; do
		_version=${_versions[$_index]}
		tox -e $_version -- $_unit || true
	done
fi

cd $_base/tempest

for i in $(seq $_retries); do
	if tox -e ci -- $_regexp; then
		exit 0
	fi
done

exit 1
