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

if [[ -t 1 ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
else
	exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
fi

if systemctl --version && journalctl --version; then
	for _unit in $(systemctl --no-legend --no-pager list-unit-files devstack@* | awk '{print $1}'); do
		_log="$_base/$_logs/$_unit.log"
		journalctl --all --merge --unit=$_unit >$_log
	done
fi
