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

if (( $# != 1 )); then
	echo "$0 <[1-9] | clean>"
	exit 1
fi

typeset _index="$1"
typeset _mkbin='/usr/local/bin/minikube'
typeset _mkurl='https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64'
typeset _nedir='/var/lib/nedge'
typeset _neurl='https://raw.githubusercontent.com/Nexenta/edge-kubernetes/master/nedge-cluster-lfs-solo.yaml'
typeset _kcurl='https://packages.cloud.google.com/apt/doc/apt-key.gpg'

if [[ "$_index" == "clean" ]]; then
	set +e

	if which minikube; then
		minikube stop
		minikube delete
	fi

	if which kubeadm; then
		kubeadm reset
	fi

	rm -rfv "$_nedir"
	rm -fv "$_mkbin"

	exit 0
fi

if [[ "$_index" =~ ^[1-9]$ ]]; then
	echo "Create namespace #$_index"
else
	echo "$0 <[1-9] | clean>"
	exit 1
fi

typeset _nodeports=''
typeset _namespace="nedge${_index}"
typeset -i _base=30000
typeset -A _port

_port[30080]=$(( _base + _index * 10 + 1 ))
_port[30443]=$(( _base + _index * 10 + 2 ))
_port[31080]=$(( _base + _index * 10 + 3 ))
_port[31443]=$(( _base + _index * 10 + 4 ))
_port[31444]=$(( _base + _index * 10 + 5 ))

for i in "${!_port[@]}"; do
	r="s|\<$i\>|${_port[$i]}|g"
	nodeports="${_nodeports:+$_nodeports} -e $r"
done

apt install -y docker.io apt-transport-https expect-lite

if ! which kubectl; then
	curl -Ls "$_kcurl" | sudo apt-key add -
	cat >/etc/apt/sources.list.d/kubernetes.list <<-EOF
	deb http://apt.kubernetes.io/ kubernetes-xenial main
	EOF
	apt update
	apt install -y kubectl
fi

if ! which minikube; then
	mkdir -pvm 0755 "$(dirname "$_mkbin")"
	curl -Ls -o "$_mkbin" "$_mkurl"
	chmod 0111 "$_mkbin"
fi

mkdir -pvm 0700 "$_nedir"

if ! minikube status; then
	minikube start --vm-driver=none
fi

typeset _yaml="$(mktemp)"
curl -Ls "$_neurl" | sed \
	-e 's|/mnt/nedge|'$_nedir'/'$_namespace'|g' \
	-e '/\//! s|nedge|'$_namespace'|g' \
	-e 's|\(local-storage\)|'$_namespace'-\1|g' \
	$_nodeports >"$_yaml"
	
kubectl create -f "$_yaml"
rm -fv "$_yaml"

set +ex
typeset -i _retries=50
while true; do
	if (( --_retries == 0 )); then
		exit 1
	fi

	typeset -i _pods=0
	typeset _pod _ready _total _status

	while read _pod _ready _total _status; do
		echo "pod: $_pod status: $_status [$_ready/$_total]"
		if [[ "$_status" == "Running" && "$_ready" == "$_total" ]]; then
			(( _pods++ ))
		fi
	done < <(kubectl get pods -n $_namespace --no-headers | awk -F '[ /]+' '{print $1,$2,$3,$4}')

	if (( _pods == 2 )); then
		break
	fi

	sleep 10
	echo
done
set -ex

kubectl get pods -n $_namespace
typeset _mgmt=$(kubectl get pods -n $_namespace --no-headers | awk '/^'$_namespace'-mgmt/{print $1}')
typeset _neenv="kubectl exec -it -n $_namespace $_mgmt -c rest --"
typeset _neadm="$_neenv neadm"

$_neenv sed -i \
	-e 's|/mnt|'$_nedir'|g' \
	-e '/\//! s|nedge|'$_namespace'|g' \
	nmf/etc/kubernetes/nedge-svc-{iscsi,nfs,s3,s3s,swift}.yaml.tmpl

typeset _expect="$(mktemp)"
cat >"$_expect" <<-EOF
set timeout -1
spawn $_neadm system init
expect {
	"enter to continue" {
		sleep 5
		send "\r"
		exp_continue
	}
	"Do you agree to the EULA" {
		sleep 10
		send "yes\r"
		exp_continue
	}
	"Are the number of devices and servers as expected" {
		sleep 10
		send "yes\r"
		exp_continue
	}
}
EOF

expect "$_expect"
rm -f "$_expect"

$_neadm system status

typeset _sid=$($_neadm system status | awk '/ONLINE/{print $2}')
typeset _cluster="cluster${_index}"
typeset _tenant="${_cluster}/tenant${_index}"
typeset _bucket="${_tenant}/bucket${_index}"
typeset _service="iscsi${_index}"

$_neadm cluster create $_cluster
$_neadm tenant create $_tenant
$_neadm bucket create $_bucket
$_neadm service create iscsi $_service
$_neadm service add $_service $_sid
$_neadm service serve $_service $_cluster
$_neadm service enable $_service
$_neadm service show $_service
