#!/usr/bin/env bash

function ci_install {
	if is_service_enabled cinder; then
		git clone -b $NEXENTA_BRANCH $NEXENTA_REPOSITORY $NEXENTA_DESTINATION

		pushd $NEXENTA_DESTINATION
		$CIDIR/scripts/patch.sh
		cd $CINDER_DIR/cinder/volume/drivers

		if [[ -d "nexenta" ]]; then
			mv nexenta nexenta.orig
		fi

		ln -s $NEXENTA_DESTINATION/cinder/volume/drivers/nexenta
		popd
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
