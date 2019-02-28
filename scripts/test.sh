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

tox -e pep8

case "$_backend" in
ns5_iscsi|ns5_nfs)
	typeset -a _versions
	case "$_branch" in
	master)
		_versions=(py27 py35 py36)
		tox -e cover -- cinder.tests.unit.volume.drivers.nexenta.test_nexenta5 || true
		;;
	rocky)
		_versions=(py27 py35 py36)
		;;
	ocata|pike|queens)
		_versions=(py27 py35)
		;;
	newton)
		_versions=(py27 py34)
		;;
	kilo|liberty|mitaka)
		_versions=(py27)
		;;
	juno)
		_versions=(py26 py27)
		;;
	icehouse)
		_versions=(py26 py27 py33)
		;;
	*)
		echo "Unknown CI branch: $_branch"
		exit 1
		;;
	esac

	for _version in "${_versions[@]}"; do
		tox -e $_version -- cinder.tests.unit.volume.drivers.nexenta.test_nexenta5 || true
	done
	;;
*)
	;;
esac

cd $_base/tempest

for i in $(seq $_retries); do
	if tox -e ci -- $_regexp; then
		exit 0
	fi
done

exit 1
