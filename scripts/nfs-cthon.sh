#!/usr/bin/env bash

unset PS1 PS2 PS3 PS4

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
typeset _host=$1
typeset _share=$2
typeset -i _rc=0
typeset -i _vers
typeset _mnt

source $_source/env.sh

if [[ -t 1 ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
else
	exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
fi

if (( $# < 2 )); then
	echo "Usage: $_script nfs_host nfs_share"
	exit 1
fi

for _vers in 3 4; do
	figlet "$_ident NFSv$_vers"
	_mnt="$_ident/$_vers"
	sudo mkdir -p $_mnt
	if ! sudo ./server -a -t -o vers=$_vers -N $_retries -m $_mnt -p $_share $_host; then
		(( _rc++ ))
	fi
done

exit $_rc
