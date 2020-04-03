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
typeset _mnt='/mnt'
typeset -i _rc=0
typeset -i _vers
typeset _host _share _name

source $_source/env.sh

if [[ ! -d $_base/$_logs ]]; then
	mkdir -p $_base/$_logs
fi

if [[ -t 1 ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
else
	exec > >(tee -a $_base/$_logs/$_ident.log | logger -t $_ident) 2>&1
fi

if (( $# < 2 )); then
	echo "Usage: $_script nfs_host nfs_share"
	exit 1
fi

_host=$1
_share=$2

figlet 'Connectathon'

for _vers in 3 4; do
	_name="NFSv$_vers"
	figlet "$_name"
	if ! sudo cthon/server -a -t -o vers=$_vers -N $_retries -m $_mnt -p $_share $_host; then
		(( _rc++ ))
	fi
done

figlet 'NFStest'

for _vers in 3 4; do
	_name="NFSv$_vers"
	figlet "$_name"
	if nfstest_posix --server=$_host --export=$_share --mtpoint=$_mnt --nfsversion=$_vers; then
		(( _rc++ ))
	fi
done

exit $_rc
