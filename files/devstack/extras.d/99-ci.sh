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
		;;
	extra)
		ci_extra
		ci_test_config
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
