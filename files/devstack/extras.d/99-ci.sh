#!/usr/bin/env bash

case "$1" in
source)
	source $TOP_DIR/lib/ci.sh
	;;
stack)
	case "$2" in
	pre-install)
		;;
	install)
		ci_install
		;;
	post-config)
		;;
	extra)
		ci_extra
		;;
	esac
	;;
unstack)
	;;
clean)
	;;
*)
	;;
esac
