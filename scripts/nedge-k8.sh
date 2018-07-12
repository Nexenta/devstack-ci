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
	echo "$0 <name|clean>"
	exit 1
fi

typeset _name="$1"
typeset _mkbin='/usr/local/bin/minikube'
typeset _mkurl='https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64'
typeset _nedir='/var/lib/nedge'
typeset _neurl='https://raw.githubusercontent.com/Nexenta/edge-kubernetes/master/nedge-cluster-lfs-solo.yaml'
typeset _kcurl='https://packages.cloud.google.com/apt/doc/apt-key.gpg'

if [[ "$_name" == "clean" ]]; then
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

typeset _ports=''
typeset -i _base=30000
typeset -i _index=$(( RANDOM % 100 ))
typeset -A _port

_port[30080]=$(( _base + _index * 10 + 1 ))
_port[30443]=$(( _base + _index * 10 + 2 ))
_port[31080]=$(( _base + _index * 10 + 3 ))
_port[31443]=$(( _base + _index * 10 + 4 ))
_port[31444]=$(( _base + _index * 10 + 5 ))

for _item in "${!_port[@]}"; do
	_ports+=" -e s|\<$_item\>|${_port[$_item]}|g"
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
	-e 's|/mnt/nedge|'$_nedir'/'$_name'|g' \
	-e '/\//! s|nedge|'$_name'|g' \
	-e 's|\(local-storage\)|'$_name'-\1|g' \
	$_ports >"$_yaml"
	
kubectl create -f "$_yaml"
rm -fv "$_yaml"

set +ex
typeset -i _delay=30
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
	done < <(kubectl get pods -n $_name --no-headers | awk -F '[ /]+' '{print $1,$2,$3,$4}')

	if (( _pods == 2 )); then
		break
	fi

	sleep $_delay
	echo
done
set -ex

kubectl get pods -n $_name -o wide

typeset _mgmt=$(kubectl get pods -n $_name --no-headers | awk '/^'$_name'-mgmt/{print $1}')
typeset _neenv="kubectl exec -it -n $_name $_mgmt -c rest --"
typeset _neadm="$_neenv neadm"
typeset _nelog='/opt/nedge/var/log/nef.log'
typeset _nemsg='ccow-auditd  now running'

while ! $_neenv grep "$_nemsg" $_nelog 2>/dev/null; do
	sleep $_delay
done

$_neenv sed -i \
	-e 's|/mnt|'$_nedir'|g' \
	-e '/\//! s|nedge|'$_name'|g' \
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
typeset _cluster="cluster"
typeset _tenant="${_cluster}/tenant"
typeset _bucket="${_tenant}/bucket"
typeset _service="$_name"

$_neadm cluster create $_cluster
$_neadm tenant create $_tenant
$_neadm bucket create $_bucket
$_neadm service create iscsi $_service
$_neadm service add $_service $_sid
$_neadm service enable $_service
$_neadm service show $_service

minikube service list -n $_name
kubectl get pods -o wide -n $_name
