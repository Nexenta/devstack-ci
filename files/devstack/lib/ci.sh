#!/usr/bin/env bash
#
# CI library
#

function ci_install {
	if is_service_enabled cinder; then
		local nex_drv=$(mktemp -d)

		pushd $CINDER_DIR/cinder/volume/drivers
		if [[ -d nexenta ]]; then
			mv nexenta nexenta.orig
		fi
		popd

		git clone -b $NEXENTA_BRANCH $NEXENTA_REPO $nex_drv

		pushd $nex_drv
		git show | tee $LOGDIR/nexenta-cinder-git.log
		cp -Rp cinder/volume/drivers/nexenta \
			$CINDER_DIR/cinder/volume/drivers
		popd

		rm -rf $nex_drv
	fi
}

function ci_extra {
	if is_service_enabled nova; then
		case "$VIRT_DRIVER" in
		libvirt)
			if [[ -n "$QEMU_CONF" && -f "$QEMU_CONF" ]]; then
				echo 'security_driver = "none"' | \
					sudo tee -a $QEMU_CONF
				if [[ -n "$LIBVIRT_DAEMON" ]]; then
					restart_service $LIBVIRT_DAEMON
				fi
			fi
			;;
		*)
			;;
		esac
	fi
}
