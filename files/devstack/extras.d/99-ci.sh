#!/usr/bin/env bash

case "$1" in
override_defaults)
	;;
source)
	source $TOP_DIR/lib/ci
	;;
stack)
	case "$2" in
	pre-install)
		;;
	install)
		ci_install
		;;
	post-config)
		ci_test_config
		;;
	extra)
		ci_extra
		;;
	test-config)
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
