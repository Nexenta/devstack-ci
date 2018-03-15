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

function ci_test_config {
	if is_service_enabled manila; then
		iniset $TEMPEST_CONFIG share capability_storage_protocol NFS
		iniset $TEMPEST_CONFIG share capability_snapshot_support True
		iniset $TEMPEST_CONFIG share capability_create_share_from_snapshot_support True
		iniset $TEMPEST_CONFIG share capability_revert_to_snapshot_support True
		iniset $TEMPEST_CONFIG share capability_mount_snapshot_support True
		iniset $TEMPEST_CONFIG share backend_names $MANILA_ENABLED_BACKENDS
		iniset $TEMPEST_CONFIG share multi_backend True
		iniset $TEMPEST_CONFIG share multitenancy_enabled False
		iniset $TEMPEST_CONFIG share enable_protocols nfs
		iniset $TEMPEST_CONFIG share enable_ip_rules_for_protocols nfs
		iniset $TEMPEST_CONFIG share enable_ro_access_level_for_protocols nfs
		iniset $TEMPEST_CONFIG share run_mount_snapshot_tests True
		iniset $TEMPEST_CONFIG share run_quota_tests True
		iniset $TEMPEST_CONFIG share run_extend_tests True
		iniset $TEMPEST_CONFIG share run_revert_to_snapshot_tests True
		iniset $TEMPEST_CONFIG share run_share_group_tests True
		iniset $TEMPEST_CONFIG share run_snapshot_tests True
		iniset $TEMPEST_CONFIG share run_consistency_group_tests False
		iniset $TEMPEST_CONFIG share run_replication_tests False
		iniset $TEMPEST_CONFIG share run_migration_tests False
		iniset $TEMPEST_CONFIG share run_manage_unmanage_tests False
		iniset $TEMPEST_CONFIG share run_manage_unmanage_snapshot_tests False
		case "$NEXENTA_BACKEND_NAME" in
		ns4_manila)
			iniset $TEMPEST_CONFIG share run_shrink_tests False
			;;
		ns5_manila)
			iniset $TEMPEST_CONFIG share run_shrink_tests True
			;;
		esac
	fi
}
