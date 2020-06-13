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
typeset -A _git

_git[branch]='branch --verbose'
_git[status]='status --short --branch'
_git[diff]='diff --patch-with-stat'

source $_source/env.sh

if [[ ! -d $_base/$_logs ]]; then
	mkdir -p $_base/$_logs
fi

if [[ "$_type" == "internal" ]]; then
	exec > >(tee -a $_base/$_logs/$_ident.log) 2>&1
fi

git reset --hard

if [[ -f $_base/$_ci/patches/$_project/$_branch.diff ]]; then
	if patch --dry-run --batch --forward --strip=1 --input=$_base/$_ci/patches/$_project/$_branch.diff; then
		patch --batch --forward --strip=1 --input=$_base/$_ci/patches/$_project/$_branch.diff
	elif [[ "$_type" == "internal" ]]; then
		exit 1
	fi
fi

for _file in requirements.txt test-requirements.txt lower-constraints.txt upper-constraints.txt; do
	if [[ -f "$_file" ]]; then
		sed -i '/^tempest[^-]/d' $_file
		if [[ "$_project" != 'cinder' && "$_project" != 'manila' ]]; then
			sed -i \
				-e '/^bandit/d' \
				-e '/^flake8/d' \
				-e '/^hacking/d' \
			$_file
		fi
	fi
done

if [[ -d $_base/$_ci/files/$_project ]]; then
	tar -cf - -C $_base/$_ci/files/$_project . | tar -xpvf -
fi

if [[ "$_type" == "internal" ]]; then
	for item in "${!_git[@]}"; do
		git ${_git[$item]} | tee -a $_base/$_logs/git.$item.$_project.log
	done
fi

if [[ "$_branch" == "master" ]]; then
	for _file in requirements.txt test-requirements.txt lower-constraints.txt upper-constraints.txt; do
		if [[ -f "$_file" ]]; then
			sed -i 's|^setuptools.*|setuptools==45.0.0|' $_file
		fi
	done
fi
